'use strict';

/**
 * st-music-bridge — 给 SillyTavern 用的音源服务插件
 *
 * 它做三件事：
 *   1. 第一次启动时，自动下载对应平台的 go-music-api 二进制（约 12MB）
 *   2. 在后台把它跑起来（自动避开被占用的 8080）
 *   3. 把它的接口原样挂到 SillyTavern 自己的域名下：
 *        /api/plugins/st-music-bridge/music/search?q=晴天&type=song&sources=kuwo
 *
 * 因为和酒馆页面同源，播放器里不需要跨域、不需要填地址、也不会有混合内容问题。
 */

const fs = require('fs');
const path = require('path');
const http = require('http');
const net = require('net');
const { spawn, execFileSync } = require('child_process');

const PLUGIN_ID = 'st-music-bridge';
const REPO = 'guohuiyuan/go-music-api';
const BIN_DIR = path.join(__dirname, 'bin');
const LOG_FILE = path.join(BIN_DIR, 'server.log');

let upstreamPort = null;
let child = null;
let starting = null;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const log = (...args) => console.log(`[${PLUGIN_ID}]`, ...args);

/* ------------------------------------------------------------------ */
/* 1. 准备二进制                                                       */
/* ------------------------------------------------------------------ */

function assetName() {
    const p = process.platform;
    const a = process.arch;
    if (p === 'win32') return 'go-music-api_windows_amd64.zip';
    if (p === 'darwin') {
        return a === 'arm64' ? 'go-music-api_darwin_arm64.tar.gz' : 'go-music-api_darwin_amd64.tar.gz';
    }
    if (a === 'arm64') return 'go-music-api_linux_arm64.tar.gz';
    if (a === 'arm') return 'go-music-api_linux_armv7.tar.gz';
    if (a === 'ia32') return 'go-music-api_linux_386.tar.gz';
    return 'go-music-api_linux_amd64.tar.gz';
}

async function ensureBinary() {
    fs.mkdirSync(BIN_DIR, { recursive: true });
    const binName = process.platform === 'win32' ? 'go-music-api.exe' : 'go-music-api';
    const binPath = path.join(BIN_DIR, binName);
    if (fs.existsSync(binPath)) return binPath;

    const name = assetName();
    const tmp = path.join(BIN_DIR, name);
    log(`首次安装，正在下载 ${name} ...`);

    const direct = `https://github.com/${REPO}/releases/latest/download/${name}`;
    // 国内直连 GitHub 经常不通，走加速镜像兜底
    const urls = [direct, `https://gh-proxy.com/${direct}`, `https://ghfast.top/${direct}`, `https://ghproxy.net/${direct}`];

    let buf = null;
    let lastErr = null;
    for (const url of urls) {
        try {
            const ac = new AbortController();
            const timer = setTimeout(() => ac.abort(), 120000);
            const res = await fetch(url, { signal: ac.signal });
            clearTimeout(timer);
            if (!res.ok) throw new Error(`HTTP ${res.status}`);
            buf = Buffer.from(await res.arrayBuffer());
            if (buf.length < 1024 * 1024) throw new Error(`文件太小 ${buf.length}B`);
            log(`下载完成 ${(buf.length / 1048576).toFixed(1)}MB（${new URL(url).host}），正在解压 ...`);
            break;
        } catch (e) {
            lastErr = e;
            log(`下载失败（${new URL(url).host}）：${e.message}，换个源重试 ...`);
        }
    }
    if (!buf) throw new Error(`下载失败：${lastErr && lastErr.message}`);
    fs.writeFileSync(tmp, buf);

    execFileSync('tar', ['-xf', tmp, '-C', BIN_DIR], { stdio: 'ignore' });
    fs.unlinkSync(tmp);

    if (!fs.existsSync(binPath)) {
        const hit = fs
            .readdirSync(BIN_DIR)
            .find((f) => f.startsWith('go-music-api') && f !== 'server.log' && !f.endsWith('.exe'));
        if (hit) fs.renameSync(path.join(BIN_DIR, hit), binPath);
    }
    if (!fs.existsSync(binPath)) throw new Error('解压后没找到可执行文件');
    fs.chmodSync(binPath, 0o755);
    return binPath;
}

/* ------------------------------------------------------------------ */
/* 2. 端口：8080 常被占，用等长字节替换换一个                            */
/* ------------------------------------------------------------------ */

function portFree(port) {
    return new Promise((resolve) => {
        const sock = net.connect({ host: '127.0.0.1', port });
        const done = (v) => {
            sock.removeAllListeners();
            sock.destroy();
            resolve(v);
        };
        sock.on('connect', () => done(false));
        sock.on('error', () => done(true));
        sock.setTimeout(700, () => done(true));
    });
}

function patchPort(binPath, port) {
    if (process.env.MUSIC_BRIDGE_NO_PATCH) {
        throw new Error(
            '8080 被占用，且已设置 MUSIC_BRIDGE_NO_PATCH（禁止改写二进制）。' +
                '请关掉占用 8080 的程序，或让酒馆换个端口。',
        );
    }
    const ext = process.platform === 'win32' ? '.exe' : '';
    const out = binPath.replace(new RegExp(`\\${ext}$`), `-${port}${ext}`);
    const buf = fs.readFileSync(binPath);
    const from = Buffer.from(':8080');
    const to = Buffer.from(':' + port);
    let i = 0;
    let n = 0;
    while ((i = buf.indexOf(from, i)) !== -1) {
        to.copy(buf, i);
        i += from.length;
        n++;
    }
    // 已经有同样的副本就直接复用：不重复写 34MB 文件，也少一次“造新 exe”的动作
    try {
        const old = fs.readFileSync(out);
        if (old.length === buf.length && old.equals(buf)) {
            log(`复用已有副本 ${out}（端口 ${port}）`);
            return out;
        }
    } catch {
        /* 不存在就往下写 */
    }
    fs.writeFileSync(out, buf);
    fs.chmodSync(out, 0o755);
    log(`端口 8080 被占用，改用 ${port}（等长替换 ${n} 处）`);
    return out;
}

/* ------------------------------------------------------------------ */
/* 3. 起服务                                                           */
/* ------------------------------------------------------------------ */

function getJson(url) {
    return new Promise((resolve, reject) => {
        const req = http.get(url, (res) => {
            let body = '';
            res.on('data', (c) => (body += c));
            res.on('end', () => resolve({ status: res.statusCode, body }));
        });
        req.on('error', reject);
        req.setTimeout(4000, () => req.destroy(new Error('timeout')));
    });
}

async function healthy(port) {
    try {
        const r = await getJson(`http://127.0.0.1:${port}/api/v1/music/qualities?source=netease`);
        return r.status === 200;
    } catch {
        return false;
    }
}

/**
 * Android / Termux 上的两个坑（Go 静态二进制特有）：
 *   1. Android 没有 /etc/resolv.conf，Go 的纯 Go 解析器找不到就秒失败（搜索 2ms 返回空）
 *   2. 找不到系统根证书，HTTPS 报 x509 unknown authority
 * proot 可以在不 root 的情况下把一份 resolv.conf 映射进去，证书用 Termux 自带的那份。
 */
function isAndroid() {
    return process.platform === 'android' || process.env.MUSIC_BRIDGE_ASSUME_ANDROID === '1';
}

function termuxPrefix() {
    return process.env.PREFIX || '/data/data/com.termux/files/usr';
}

function which(cmd) {
    try {
        const p = execFileSync('which', [cmd], { encoding: 'utf8', timeout: 3000 }).trim();
        return p || null;
    } catch {
        return null;
    }
}

function ensureResolvConf() {
    const home = process.env.HOME || '/data/data/com.termux/files/home';
    const dir = path.join(home, '.st-music-bridge');
    const file = path.join(dir, 'resolv.conf');
    try {
        if (fs.existsSync(file) && fs.statSync(file).size > 0) return file;
    } catch {
        /* 往下重建 */
    }
    const ns = [];
    try {
        const dns1 = execFileSync('getprop', ['net.dns1'], { encoding: 'utf8', timeout: 3000 }).trim();
        if (/^\d{1,3}(\.\d{1,3}){3}$/.test(dns1)) ns.push(dns1);
    } catch {
        /* getprop 不可用就算了 */
    }
    ns.push('223.5.5.5', '119.29.29.29', '8.8.8.8');
    try {
        fs.mkdirSync(dir, { recursive: true });
        fs.writeFileSync(file, ns.map((s) => `nameserver ${s}`).join('\n') + '\n');
        return file;
    } catch (e) {
        log('写 resolv.conf 失败：' + e.message);
        return null;
    }
}

function certEnv() {
    const p = termuxPrefix();
    const env = {};
    const files = [
        path.join(p, 'etc', 'tls', 'cert.pem'),
        path.join(p, 'etc', 'ssl', 'certs', 'ca-certificates.crt'),
    ];
    for (const f of files) {
        try {
            if (fs.statSync(f).isFile()) {
                env.SSL_CERT_FILE = f;
                break;
            }
        } catch {
            /* 下一个候选 */
        }
    }
    try {
        if (fs.statSync('/system/etc/security/cacerts').isDirectory()) env.SSL_CERT_DIR = '/system/etc/security/cacerts';
    } catch {
        /* 没有就算了 */
    }
    return env;
}

function findProot() {
    // Termux 不一定装了 `which`（它属于 debianutils，不在基础包里），
    // 所以优先按文件系统找，最后才退回 PATH 查询。
    const cands = [
        process.env.MUSIC_BRIDGE_PROOT,
        path.join(termuxPrefix(), 'bin', 'proot'),
        '/data/data/com.termux/files/usr/bin/proot',
        '/usr/bin/proot',
        '/usr/local/bin/proot',
        '/system/bin/proot',
    ].filter(Boolean);
    for (const c of cands) {
        try {
            if (fs.statSync(c).isFile()) return c;
        } catch {
            /* 下一个 */
        }
    }
    return which('proot');
}

/** 决定怎么起这个二进制：普通启动，还是 Android 上套一层 proot */
function planLaunch(exe) {
    if (!isAndroid()) return { cmd: exe, args: [], env: {}, note: '' };

    const env = certEnv();
    const resolv = ensureResolvConf();
    const proot = findProot();

    if (resolv && proot) {
        return {
            cmd: proot,
            args: ['-b', `${resolv}:/etc/resolv.conf`, exe],
            env,
            note: `Android：用 proot 注入 DNS（${resolv}）${env.SSL_CERT_FILE ? '，证书 ' + env.SSL_CERT_FILE : ''}`,
        };
    }
    if (resolv) {
        // 找不到绝对路径也先按 PATH 试一次；真没有 proot 会在 spawn 时报 ENOENT，自动退回普通启动
        return {
            cmd: 'proot',
            args: ['-b', `${resolv}:/etc/resolv.conf`, exe],
            env,
            optimistic: true,
            note: 'Android：按 PATH 尝试 proot（没找到绝对路径）',
        };
    }
    return { cmd: exe, args: [], env, note: '⚠️ Android 上写不了 resolv.conf，DNS 可能失败' };
}

/** 起进程；proc 不存在（ENOENT）时返回 null，交给上层退回普通启动 */
function spawnServer(cmd, args, env) {
    return new Promise((resolve) => {
        const out = fs.openSync(LOG_FILE, 'a');
        const c = spawn(cmd, args, { detached: true, stdio: ['ignore', out, out], cwd: BIN_DIR, env });
        c.once('spawn', () => {
            c.unref();
            resolve(c);
        });
        c.once('error', () => resolve(null));
    });
}

async function startServer() {
    if (upstreamPort && (await healthy(upstreamPort))) return upstreamPort;

    const binPath = await ensureBinary();

    let port = 0;
    for (let p = 8080; p <= 8090; p++) {
        if (await portFree(p)) {
            port = p;
            break;
        }
    }
    if (!port) throw new Error('8080-8090 全被占用');

    const exe = port === 8080 ? binPath : patchPort(binPath, port);
    const plan = planLaunch(exe);
    if (plan.note) log(plan.note);

    const env = { ...process.env, ...plan.env };
    let started = await spawnServer(plan.cmd, plan.args, env);
    if (!started && plan.cmd !== exe) {
        log(`⚠️ 起 ${path.basename(plan.cmd)} 失败（可能没装），退回普通启动 —— 这样 DNS 大概率还是不通`);
        started = await spawnServer(exe, [], env);
    }
    if (!started) throw new Error(`起不来：${exe}`);
    child = started;

    const rounds = isAndroid() ? 125 : 75; // Termux 上 proot 启动慢一些
    for (let i = 0; i < rounds; i++) {
        await sleep(400);
        if (await healthy(port)) {
            upstreamPort = port;
            log(`音源服务已就绪 → http://127.0.0.1:${port}`);
            probeSearch(port);
            return port;
        }
    }
    throw new Error(`音源服务启动超时，看日志：${LOG_FILE}`);
}

/** 起来之后自检一次：能不能真的搜到东西（DNS/证书问题会在这里露馅） */
async function probeSearch(port) {
    const t0 = Date.now();
    try {
        const r = await getJson(
            `http://127.0.0.1:${port}/api/v1/music/search?q=%E6%99%B4%E5%A4%A9&type=song&sources=kuwo`,
        );
        const ms = Date.now() - t0;
        const j = JSON.parse(r.body);
        const n = j && j.data && j.data.songs ? j.data.songs.length : 0;
        if (n > 0) log(`联网自检：搜索正常（${ms}ms，${n} 条）`);
        else log(`⚠️ 联网自检：${ms}ms 返回空结果 —— DNS 或证书没通，见 README「Termux 搜不到歌」`);
    } catch (e) {
        log('⚠️ 联网自检失败：' + e.message);
    }
}

/* ------------------------------------------------------------------ */
/* 4. 反向代理：/api/plugins/st-music-bridge/music/* → 127.0.0.1:port  */
/* ------------------------------------------------------------------ */

function upstreamPath(req) {
    const full = req.originalUrl || req.url || '/';
    const m = full.match(/\/music(\/.*)?$/);
    return '/api/v1/music' + (m && m[1] ? m[1] : '/');
}

function contentFix(h, target) {
    // B站 的流标成 video/mp4 或 application/octet-stream（实际是纯音频 fMP4），
    // 浏览器 <audio> 遇到 video/* 会拒播，统一改成 audio/mp4。
    const ct = String(h['content-type'] || '').toLowerCase();
    if (/source=bilibili/i.test(target)) {
        h['content-type'] = 'audio/mp4';
    } else if (ct.startsWith('application/octet-stream') || !ct) {
        h['content-type'] = 'audio/mpeg';
    } else if (ct.startsWith('audio/x-flac')) {
        h['content-type'] = 'audio/flac';
    }
}

function proxyMusic(req, res) {
    if (!upstreamPort) {
        res.writeHead(503, { 'content-type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ error: '音源服务还在启动，请几秒后重试' }));
    }

    const headers = { ...req.headers, host: `127.0.0.1:${upstreamPort}` };
    delete headers['accept-encoding']; // 避免上游 gzip 后 content-length 对不上

    // 有的源（如网易云）不支持 quality=high，会 404；这时自动退回 auto 再试一次。
    const attempt = (target, allowRetry) => {
        const up = http.request(
            { host: '127.0.0.1', port: upstreamPort, path: target, method: req.method, headers },
            (upRes) => {
                const code = upRes.statusCode || 502;
                if (allowRetry && code >= 400 && /[?&]quality=/.test(target)) {
                    upRes.resume();
                    return attempt(target.replace(/[?&]quality=[^&]*/g, ''), false);
                }
                const h = { ...upRes.headers };
                contentFix(h, target);
                h['access-control-allow-origin'] = '*';
                h['access-control-expose-headers'] = 'content-length, content-range, accept-ranges';
                res.writeHead(code, h);
                upRes.pipe(res);
            },
        );
        up.on('error', (e) => {
            if (res.headersSent) return res.destroy();
            res.writeHead(502, { 'content-type': 'application/json; charset=utf-8' });
            res.end(JSON.stringify({ error: e.message }));
        });
        req.pipe(up);
    };

    attempt(upstreamPath(req), true);
}

/* ------------------------------------------------------------------ */
/* 5. 插件入口                                                         */
/* ------------------------------------------------------------------ */

async function init(router) {
    router.use('/music', proxyMusic);

    router.get('/status', (req, res) => {
        res.json({
            ok: Boolean(upstreamPort),
            port: upstreamPort,
            pid: child ? child.pid : null,
            platform: `${process.platform}-${process.arch}`,
            log: LOG_FILE,
        });
    });

    // 不阻塞酒馆启动：后台慢慢下载/拉起
    starting = startServer().catch((e) => {
        log('启动失败：' + e.message);
    });

    log('插件已加载，音源服务在后台启动中 ...');
}

async function exit() {
    if (starting) await starting.catch(() => {});
    if (child && child.pid) {
        try {
            process.kill(child.pid);
            log('音源服务已停止');
        } catch {
            /* 已经退出了 */
        }
    }
    return Promise.resolve();
}

module.exports = {
    init,
    exit,
    // 供测试与排障用
    _planLaunch: planLaunch,
    _ensureResolvConf: ensureResolvConf,
    _certEnv: certEnv,
    info: {
        id: PLUGIN_ID,
        name: 'Music Source Bridge',
        description: '为小彻云音乐播放器提供 QQ/网易云/B站/酷我 等完整音源（自动下载并后台运行音源服务）',
    },
};

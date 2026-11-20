# SillyTavern 音源插件

给酒馆里的音乐播放器换一套**能播完整歌曲**的音源：QQ音乐 / 网易云 / B站 / 酷我 / 咪咕，
带封面和歌词，手机本地酒馆（Termux）和云酒馆都能用。

原理很简单：这是一个**服务端插件**。酒馆本来就是 Node 服务，插件跑在同一个进程里，
自己起一个音源服务，再把接口挂在酒馆自己的域名下（`/api/plugins/st-music-bridge/music/…`）。
因为和页面**同源**，所以没有跨域、没有混合内容、不用填 IP 和端口。

---

## 一行安装（Termux / 云酒馆终端）

```bash
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/dufenglai0713/st-music/main/install.sh | bash
```

> `gh-proxy.com` 是国内可用的 GitHub 加速；网络能直连 GitHub 的话，去掉前缀也行：
> ```bash
> curl -fsSL https://raw.githubusercontent.com/dufenglai0713/st-music/main/install.sh | bash
> ```

脚本会自己找酒馆目录、写入插件、打开配置开关，最后打印重启提示。
**酒馆目录不在默认位置**时手动指定：

```bash
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/dufenglai0713/st-music/main/install.sh | bash -s /data/data/com.termux/files/home/SillyTavern
```

装完**重启酒馆**：`cd ~/SillyTavern && node server.js`

---

## 装完怎么确认

浏览器打开（端口按你酒馆实际端口改）：

```
http://127.0.0.1:8000/api/plugins/st-music-bridge/status
```

看到这样就算成功：

```json
{"ok":true,"port":8081,"pid":12345,"platform":"linux-arm64","log":"..."}
```

`ok:true` 表示音源服务已经起来了；`port` 是它内部用的端口（8080 被占用会自动换一个，不用管）。
**第一次启动会下载约 11MB 的音源程序**，等 10–30 秒，`ok` 才会变 `true`。

顺手验证一下搜索：

```bash
curl -s "http://127.0.0.1:8000/api/plugins/st-music-bridge/music/search?q=晴天&type=song&sources=kuwo" | head -c 300
```

---

## 前置条件

- 酒馆在 Termux 里**至少启动过一次**（生成过 `config.yaml`）
- Termux 里装了 `curl`：`pkg install -y curl coreutils gzip`
- 酒馆版本支持服务端插件（近两年的版本都支持）

云酒馆：需要有 SSH 或面板里的「终端/Console」，命令完全一样。

---

## 接口（改播放器时用）

所有接口都在 `/api/plugins/st-music-bridge/music/` 下，**相对路径**调用即可。

| 用途 | 请求 | 说明 |
|---|---|---|
| 搜索 | `search?q=晴天&type=song&sources=kuwo` | `sources` 可重复传多个；不传则聚合全部源（噪音多，建议指定） |
| 音频流 | `stream?id=<id>&source=kuwo&quality=high` | 支持 Range，可拖动进度条 |
| 歌词 | `lyric?id=<id>&source=kuwo` | 返回 `{data:{lyric, tlyric}}` |
| 封面 | `cover?url=<encodeURIComponent(封面地址)>` | 服务端代理，解决防盗链 |
| 状态 | `../status` | `ok` / `port` / `pid` |

可用音源：`netease`、`qq`、`bilibili`、`kuwo`、`migu`。

搜索结果长这样（节选）：

```json
{"code":200,"data":{"songs":[{"id":"228908","name":"晴天","artist":"周杰伦","album":"叶惠美","duration":269,"source":"kuwo","cover":"https://..."}]}}
```

播放器侧接法：把上面四个接口套进你原来的 `searchSource / fetchFreshAudioUrl / loadCover / loadLyrics` 即可，
`<audio crossOrigin="anonymous">` **不用改**（同源，频谱分析照常可用）。

---

## 常见问题

**`curl: command not found`**
`pkg install -y curl`

**脚本说找不到酒馆目录**
手动传路径：`... | bash -s /完整/路径/SillyTavern`（判断标准是该目录下有 `server.js`）

**`status` 返回 404**
1. 没重启酒馆；2. `config.yaml` 里 `enableServerPlugins` 不是 `true`；3. 插件目录套了两层（应该是 `plugins/st-music-bridge/index.js`）

**`ok` 一直是 `false`**
首次启动在下载 11MB 音源程序。看日志：
```bash
tail -n 30 ~/SillyTavern/plugins/st-music-bridge/bin/server.log
```

**有的歌能搜到但放不出声音**
多半是 VIP 曲目，未登录只给免费曲库。进阶做法是给音源程序登录：
`http://127.0.0.1:8081/swagger/index.html` → `POST /api/v1/system/qr_login/netease` → 手机扫码。

**B站 的歌没有歌词**
B站 就是没有歌词（视频音轨），换酷我 / 网易云 / 咪咕即可。想点播具体视频，直接把 **BV 号**（大写）或视频链接粘进搜索框。

**锁屏一会儿音乐停了**
系统省电把 Termux 冻结了，`termux-wake-lock` 可缓解。这是 Termux 的已知限制，不是插件的问题。

---

## 更新与卸载

```bash
# 更新：重跑安装命令即可（会覆盖 index.js，配置不动）
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/dufenglai0713/st-music/main/install.sh | bash

# 卸载
rm -rf ~/SillyTavern/plugins/st-music-bridge
# 想彻底关掉服务端插件，再把 config.yaml 里的 enableServerPlugins 改回 false
```

---

## 文件

| 文件 | 说明 |
|---|---|
| `install.sh` | 安装脚本，**插件本体已内嵌**（gzip + base64），运行时不需要再下插件 |
| `index.js` | 插件源码，11546 字节，可以自己看、自己改 |

`install.sh` 只做四件事：找目录 → 解出 `index.js` → 备份并修改 `config.yaml` → 打印提示。
不联网下载任何东西（音源程序由插件在**首次启动**时自己下）。

---

## 说明

- 插件本体随意使用。
- 内置的音源程序 [go-music-api](https://github.com/guohuiyuan/go-music-api) 是 **AGPL-3.0**，对外提供服务时请遵守其许可。
- 仅供个人学习与自用。音乐版权归各平台所有，请不要公开传播受版权保护的内容。

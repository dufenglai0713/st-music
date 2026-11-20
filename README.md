# SillyTavern 音源插件（安装脚本）

给 SillyTavern 用的音源插件：QQ音乐 / 网易云 / B站 / 酷我 / 咪咕 的完整音频、封面、歌词，
挂在酒馆自己域名下，手机（Termux）和云酒馆都能用。

## 文件

| 文件 | 说明 |
|---|---|
| `install.sh` | 安装脚本，**插件本体已内嵌**，运行时不需要联网下插件 |
| `index.js` | 插件源码，可以自己看、自己改 |

## 上传到你自己的仓库（手机也能做）

1. 打开 github.com（或 gitee.com）→ New repository
   - 名字随意，例如 `st-music`
   - 选 **Public**（私有仓库的 raw 链接要 token，麻烦）
   - 勾选 "Add a README file"，创建
2. 进仓库 → **Add file → Upload files** → 把 `install.sh` 和 `index.js` 拖进去 → Commit
3. 点开 `install.sh` → 右上角 **Raw** → 复制地址，形如：
   ```
   https://raw.githubusercontent.com/你的用户名/st-music/main/install.sh
   ```
   Gitee 的话是：
   ```
   https://gitee.com/你的用户名/st-music/raw/main/install.sh
   ```

## 发给别人的一行命令

**GitHub（国内建议套一层加速，直连经常打不开）：**

```bash
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/你的用户名/st-music/main/install.sh | bash
```

**Gitee（国内直连即可）：**

```bash
curl -fsSL https://gitee.com/你的用户名/st-music/raw/main/install.sh | bash
```

粘进 Termux 回车，它自己找酒馆目录、写插件、改配置，最后打印重启提示。

想指定目录也行：

```bash
curl -fsSL <上面的地址> | bash -s /data/data/com.termux/files/home/SillyTavern
```

## 前置条件

- 酒馆在 Termux 里跑过至少一次（生成过 `config.yaml`）
- `pkg install -y curl coreutils gzip`（Termux 一般自带，缺了就装）

## 装完怎么确认

```bash
ls -l ~/SillyTavern/plugins/st-music-bridge/index.js
grep enableServerPlugins ~/SillyTavern/config.yaml
```

重启酒馆后浏览器打开：
`http://127.0.0.1:8000/api/plugins/st-music-bridge/status`
（端口按你酒馆实际端口改；手机上开就是 127.0.0.1）

## 许可

插件本体随意使用。音源程序 [go-music-api](https://github.com/guohuiyuan/go-music-api) 是 AGPL-3.0。

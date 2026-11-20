#!/usr/bin/env bash
# SillyTavern 音源插件 · 安装脚本
# 用法：bash install.sh [酒馆目录]
#   不写参数就自动找 ~/SillyTavern（会多找两层目录）
set -u

ST=""
if [ $# -ge 1 ] && [ -n "${1:-}" ]; then
    ST="$1"
else
    for d in "$HOME/SillyTavern" "$HOME/sillytavern" "$HOME/SillyTavern-"* "$HOME"/*/ "$HOME"/*/*/; do
        if [ -f "$d/server.js" ]; then ST="$d"; break; fi
    done
fi

if [ -z "$ST" ] || [ ! -f "$ST/server.js" ]; then
    echo "❌ 没找到酒馆目录。请手动指定："
    echo "   bash install.sh /data/data/com.termux/files/home/SillyTavern"
    exit 1
fi

echo "📁 酒馆目录：$ST"

PLUGDIR="$ST/plugins/st-music-bridge"
mkdir -p "$PLUGDIR" || { echo "❌ 建不了目录：$PLUGDIR"; exit 1; }

# 解出插件本体（内嵌在脚本里，不联网）
TMP="${TMPDIR:-$HOME}/stmb-install.$$"
mkdir -p "$(dirname "$TMP")" 2>/dev/null || TMP="$HOME/stmb-install.$$"
trap 'rm -f "$TMP"' EXIT

cat > "$TMP" <<'STMB_PAYLOAD_EOF'
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
2XBTtrPpfwDUrAsRFT4AAA==
STMB_PAYLOAD_EOF

if command -v base64 >/dev/null 2>&1 && command -v gunzip >/dev/null 2>&1; then
    base64 -d "$TMP" | gunzip > "$PLUGDIR/index.js" 2>/dev/null
else
    echo "⚠️ 缺 base64/gunzip，先装：pkg install -y coreutils gzip"
    exit 1
fi

if [ ! -s "$PLUGDIR/index.js" ]; then
    echo "❌ 插件写入失败（解压出错）"
    exit 1
fi
echo "✅ 插件已写入 $PLUGDIR/index.js"

# 打开 config.yaml 里的开关
if [ -f "$ST/config.yaml" ]; then
    [ -f "$ST/config.yaml.bak" ] || cp "$ST/config.yaml" "$ST/config.yaml.bak"
    if grep -qE '^[[:space:]]*enableServerPlugins:' "$ST/config.yaml"; then
        sed -i 's/^[[:space:]]*enableServerPlugins:.*/enableServerPlugins: true/' "$ST/config.yaml"
    else
        printf '\nenableServerPlugins: true\n' >> "$ST/config.yaml"
    fi
    echo "✅ 已开启 enableServerPlugins（原文件备份为 config.yaml.bak）"
else
    echo "⚠️ 没找到 $ST/config.yaml —— 先启动一次酒馆再来"
fi

echo ""
echo "🎉 安装完成！"
echo "   1. 重启酒馆：cd \"$ST\" && node server.js"
echo "   2. 打开：http://127.0.0.1:8000/api/plugins/st-music-bridge/status"
echo "      看到 {\"ok\":true,...} 就成功了（首次启动会下载约 11MB 音源程序，等 10~30 秒）"

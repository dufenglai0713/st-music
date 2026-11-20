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
Bd5vb64QRAAA
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

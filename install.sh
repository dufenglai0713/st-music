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
H4sIAAAAAAACCs1a7XPTxtb/nr9imckgOSiSA6H0Ok2ZQmnLHdpyoZ37gfIkQlrbKrJkVqu8NNcz
gRLyQkICDy0lpA1vpdy2kJQW4rwA/0tryfan/At3zq4kS7ZDO/f2PvN4JhNbu3vO2bPn5XfOSnAd
jBxKDI0KfR0dSldXB+pCDu0uuI6hdZ8hhp7D6Nfx66i6eROdNExz9CN1CBMLVa8/rC5erC//7G8s
+Etz3swdf/5aZfNZB2IkvMefe+cXK+Xpyuazysbl7a1FeIpQj4yqP/5YKY/7P97xFla8mYf+jWfb
W7O1ye+9mYeV8uXa8+feyrq3cd1b/9mbX60uXkQ5OxBHLRqosjFbe3nLm3q2vTVV3XiAeva+f2h7
a5pT3ysjb+mht3DFm1/1Z2a8x5/X1q7Wnq75X3+7vTXFedTPv/S2xmt3f/DmbvNNoNfTr6cjGvtk
xJdWFy/6V7715u95V5b922v+7AVvajWhAyC49lN18aK3vOwtzFXKjX2yj6IWDaVoujnDcpQmpSrs
h+JglWj5g+f6/Zu/ePf/uZuOFnG/Y1u53Y7tEg07/WfdYTtU6q3blfKGd222PnGt/uBS/c7T+td3
vYVZf2Nhe2vWv/bIv/7Cu/mwPjlbKc/Vl8ZrD87X1h56y8u/jZ+Pnnh3fvCWVr2vx+Hh+nKlPFfZ
WvSXpv21NW9hyrs04T1er994XL/71W/jFzpQl9LRodmWQ1HWQf2I4HOuQbAoZB0h1ReMFFWaj4/B
78ZontJifBR+N0YtTOODFqaNsTHkFNVhS0J4BGvvGCY+OWppqBSfr+UNUx8oElvDDpMoWHr82Mfv
Hv1g4OjbqB8JTaoXQvonjhz/EMZzrp13jVFXtZS4rUXzDh39YODtoydQP9up/KltWOLAgG4QSy1g
CQlnDKsh9LEP3x145+ixI4nZAQUJCQ4mQ5jIpp1j0pqYIrfoUILVwnGbgC4s1zT72ADbXOKJQ1VC
DSsXPQyYOibGoGSx4KRQ/5vIwsPoOLELhoNFkbBHDqYfGQVsu1QkEio4qUhi0wZ6oizLKsnx9TBg
mxjEFAdPdY5F6iydHpRQOJNFDNT9H3/AyJQuiA3e5CXv/mTk4+jf+3Byf45cHVnX0qhhW0h1HEw/
UAtYTKGxDuATWD+cNDdAuWiqNGuTQl9sXI2Ng7PzMSOLxCLq7+9HwrBh7dsrpBDB1CUWEuI2ODBs
WLo97AyoBf21Xvkzoyi0rNdVMgwWGEgFn4CUyieopPBar4AONpHm6wbYqExVIuc+E1Bmh0mMfTCJ
S1CK5Eiw2WEfpmG5I0lefW0I/O7yoQM7LjfUndXI1+97/bXk6lfxSu641NGhOhB+InvAluMSfMiw
VDIamUTWkQtndYNApGp4/RgiWHOJYwzhDKLExaiUipvIGcMCw2pjSHELaT5AGY/glgMTmuge57G5
TSgKmKYaesw6Mh4xHOow6YPFqUijwYO+jhgHi4sd8404f1ootudtNRizEFN/8CUAgsfTtXsTkMoe
3fOWAjSAOsdgdgmizmAqwVw3CNYgZA5CTnEyipIzaN49I2t2Qekcg/BeUgg2sepgRzFVih2q6Paw
ZdqqrgR0B7kYioK8W8+9SxPVW7/UXn6D3jXoe+4ZVN2c98plSJ7jiwBTnq56M7fr48v1L5a8z+e9
iSVv44uYRC4xIUue4pJJMcHy3UVij4wGovHx0mBiRlZ1qEzt4k7jnICFaWzC6UAhkBzOuNkoL4TP
TNWhRwhJPM/aBImRvMjOMrHj4YOS0divWCjTgBAeRm+dsQk9bFuU2KaJSXjqydnUKGDgHMs8Issu
qiarQEBMSahnbzqdTrddTzDoUh1WDYqymGp50SUmOJNj5CzVzAAd/jVyp4iAiVUSMmVyNE0Ac99F
sCPbZ1OI5ok9zPZ1hBCbiIPvffTRcdQ5BuMOVanrlAab1nNdH3KzWUzkLLELIpcTlqiEqKN8SEy1
4XvGzcomtnI0j95APem9vaiL/WsjiP/lZGXzmXf/e291HnWONVaWDjVLxPwoANCPZ/2pBdQ5Fmel
oJ507+v7D7yWkqn9jjGCdbEnVQLwPNU5Biw/PnEMFJyS87ZDS9tb05Ej1r675125HDpgQg0Eq2cb
j0pIU6mWRyJONdlPww7xzmLf/6n2y7evkmexcwzLBew4ag6XQLy5u5Xy9/7GQn1yrrbyRbOEpaY8
teuMm22j5CT3xc6xUNjdu0O5I6Yh+awjDxOD4hCVirRQlMAqwggVh6yiQFUiSOiU0D2SFSTE5grd
hwUphJanmVlT3bAzSDBylk2wEBl11pFdyzSssyGjkAfb005Bu6H/AIYbECmzTkL7MsGq3pSuUskZ
WcPSRTHLHDcrMwDq/N2geTGZdlKgrSzaBekqhnHh6a6sjC09WMSSVtwrYBN5g6ZgmwRDSGbCtEka
MEsKs1CqGYTsqIjm8xa4OXsLV/wnd/zpF97Uqje/4k9/V7szy/1NaCheyxdsPU5QQmn7wP79qQR+
iDJj6c9FxHtlVP1hxZu/t721CEUq8splXrlub81C8fpouv7FS+/RjdrMBf/WS3/uLvOI8Ur5+/97
fFy0CX2HYCzCl9D+AgUl6xHs2OYQZhbVbKWOrZ1lOYbKmm1ZWKPiGIIAkEFCz94DclpOyz2CxJgl
on6ACGwL4Ig41EQcPkBaJrhgD+G3TPOY4VBsYeI05y42TccOJfZo81gguTgUDzKNr2ypbYlCILog
IZ7wQCwxq5oOjlt+NB2DXSYnA0hsmRtLpAfS6R3ng1pK8YOBmAzFZcOG40fEKokAdmJrSH7/45NH
Dw8cOnH07XePDHzw4cDxtz46/F4CHTQ5VEJFArPTqL2yvTVbKV/31p7UHr+oPn+M2hKHVs6D8/6j
u/71de/SzViLZ/q38QsC2tPRbMFCbWXNm/jZvzLN2bAWDqouXqw+vOxtzENqmPqy9vifvFHC0wT3
JCAoRfQSUYSbEB6hfwCHR9g7gbdtF9YGWpYJLpqqhkXQ1AmcOzJSFAc/+aRzDI/QUudgSkKD3Z1j
cBIl/mwwWRMwhMGCoqpHmSQZ/YLGDLELTWBEyIBChCQYt1smCWgPN4UGYDRQP0o3flqNn8N5w8RI
FGEG4ArD0vHIh1kRaEnISKVY8O/uSZiKLWt2cRRwCEyJRX20p58JHsCTxoi1Z0/8UACXrz2pbs77
S9PQ6rq9Bv226RV/6Udv9afqrV+gR3d/jpnaIuD0yTnv/px36Sba1/v+IcQDOljh+rK3epU3Hn8d
X6qP3/a/XIUs/ev410Bx5mHl+VJHK/gNDpb1YZoPw3ZpUyKzTT3EW2AwMfi1ezcQkfE5VzUd0Eeq
BSIBEuJb8daewHbZLlHnmO0C/pniBowCm9nemh5sCU8s2NoubcFAATBrcFS6UKU85z36Chqmqz95
L8Yr5cugti4lpv0WmGO7NIQ5LRmSjcWzI9tRIHVLWPCvr4PjRruZ4smMpzEo+krIu38xtsv47v7k
PLtPRtAlZm1s9O9//jt5NYfpXx3bYlj497OqhAj+FGu0bXYl+BzqZw1ZOYcpL6dgYZtsyQpKWx+F
/qjQkgVZ2tJVqkLW0thykc3e04+0VKr9fGzpUZILMymgXiiwMqhRbB22dSxx5qU4rXi6J/hcInUG
m05OiOXL3nQjYcJQmOBjsJDyqUKqKY82tX3yWDVpfjSBctqFDBLVruEBslI+oygRjskExs/uCYZ6
gisBiBAGNbBzkF8B9FuYQgdjMLE7ZgAk0BgLNnvTQaBudfZgOkMgYXBt3RnD9icZdhfj4CDRn969
GwWlbqiI+HCq0S2KP050bRpNKU4n2UeL9TOKvB+ejnUt2GPUz6JJHyqiN+DrX+Drnj3xeMq6gox6
A5W2BNyAfvHVJW1zmcHPvaWoAIm6QRbkTTyM4pyQbFjhEdbjY3z7+S7QwUghmR2RWivGyDqyXcQW
i7vhjYOEBDVK+cHVAbtAEfEIltApVmTqmKpaHuu8DymFReepsOqUEAvjtktPS0gb1jPR7UcpTlp2
LYKz0XFFh8PhAzLQG+jA/j5kJI+FHwm7rACPbEqeSbNiG28+sqarkiKzrZYkGr+V9NaeAE7Y/B79
euka2skDd8ikSfpxU2hpIiR4sovN2rMJfrdZXbrs3/jWe3mDNRfC02I8/+Q81isjb37OW7ha2bxX
Xbi0vbX4B64gu5hmGiph5vlfymXR+ak0LxJ8LnmTknVNk1/uyTYxcoalmh8TE/3jH+yRy78KSgJy
A/KFdXIBfEdUPuG7Ej9R5K7UwU4lCR6ERKgF+CsWIKQVTvWcRgf5vwywaCqhNNui2KLvGCNiXkJU
JTkcBX9FQYeqP9yE6sN/et6/PQm9tyFDx7ZSKPYif+pLpBaLpqGpQEqxNYppN1fD9taU9/ib+s0J
/6uV6sZKffnn+t2rKPv+8V7efgvp+0/na99NeTcfojdUVzfsN1H9/CTcRnM2XQiucC9f8689AnPb
XAaYe30d5GDTQQ52mRtpjXXNT1JiWDkxf0oIttcNt8/CaaZlAdqEx+xhTA6rTtTWBzdVgrR0xjAN
+FMMGRrrYqCVuMu2koZbnlCk8B4JYdPBjLRGEw2mndQmpEDEXRr9w7xw7veZsakj3VlT1YQ/ugs2
OZZRGzU39OrfZ5ZI8DnAJ048pe5KJM1Epg4Q93tY1cX96X0Qs5PsMyihmE8d2+pDWl4lDqb9Ls12
vy40QSWOFTCU97r415MffiA77OiN7Kg4hhiEyiAhHsFqL1ldwOIYXHusrHmTt6vfXfMWrvBWq9CA
ZqV4hstjVccE+vZj0I0Fvw0eSUEbZzAefONqKA2GvRQdm5jikNYpQdU0XKTd2NJs3bBywuk+cAp4
kWNirlKe8ctllPvMKCJv4Uroqd1B2eWtrMMbDuWZjsiXlqbBU+GViSnvwYXq86v+V/9b2bi6vTVd
Kc/511f82fOIY7DR/ryRy0PxuLWIetO921u3ai9v+jeeBW+SjI97t75Bqktt5F0CrfDyMulqKqW4
UAR/CzxEQqpp2sMnMCWjbVG6WwxBOrzmAK6VyE079sMyifQosXu3DAqZFjDN23qGhVL+XYpOqyQl
OIhu8UTboiAWQGwdoAybGIPt4Jf703v7Wlax/B5tG0Iuo/BmP+pNp+Gncurg7tOh2pUdI0oSDABz
gh23ce/Y/AkvwvkhBBSjzkyC6an/2X26S8lJEPskjpXbEC3toJB8aPJcqkizfe3mt+aS1ml5bveO
063xe7Zupr9unhl5EOoS/sg6PFK0HdwdiMRXJt1EityGqFYOSyjwOPbLacMkGaY0VrDl22yCK6No
FDErM5MTSi19OL4k2RPFbewQrIk0tHwSWzQVj3M7t28TwXXvfx5cQ7KviqzRldWry1mmJbcYRtUA
WYeW24KcJAbg/3wMuV9G/E0+bwJefvv/0QxpqlQNy6AisV2KSdQSYb9k18GiEKA7KZaFw0IlmAbd
D0HhcUtgPZAwRydsDU4WTEBMmp99NoMO2baJVStZ/Uot9WVTTE6OG3omKNQOBlVV0dBRhl3VN00N
2tAZNNg51tybLnU3nsELRqVBqbkmykSvpUkt9lcKdaMo0BKsf7Xp3fmGN85DALAYvFI5cdefuMuv
SxX/8nTt6RpbGHsrLdFDkFkfQmxxYSjSBE47unUFLB45SrNkbEFglWtPvJnbtefPt7dmEzVX+N4n
p1spP4JgLLRt4eARgyY6HOEGUmGFGvwON8DlL8VAMD82SGPhub36/YnwfM4apik21rQWr0Jz8Xp+
yX90V0i1XrInGShdQZ8cUMnkRmXjUtjJbS5dgzgZNA7lsBPHNVWwddfEMqQMQhmM41u2jMB4QXdS
8CxrZ+I9Fz3TeO2yYWZwo5tBAvNCdJKVDugQfw+zMUnHjkaMIpxOBgnwkuvqvPd8s7Jxtb78c2V9
IXq31Z9fqLy4hf72NyUCbgpUX0p9Ys2fuoqqj6bh7YcvfuFqjN76De74159xI6m9XKjdSdjP9tZ0
IE9J6ij1dfwLHjrutBotAAA=
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

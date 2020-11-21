#!/bin/bash
# FILE="/etc/Caddy"
domain="$1"
psname="$2"
uuid="51be9a06-299f-43b9-b713-1ec5eb76e3d7"
if  [ ! "$3" ] ;then
    uuid=$(uuidgen)
    echo "uuid 将会系统随机生成"
else
    uuid="$3"
fi
cat > /etc/Caddyfile <<'EOF'
domain
{
  log ./caddy.log
  proxy /one :2333 {
    websocket
    header_upstream -Origin
  }
}

EOF
sed -i "s/domain/${domain}/" /etc/Caddyfile

# v2ray
cat > /etc/v2ray/config.json <<'EOF'
{
  "inbounds": [
    {
      "port": 2333,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "uuid",
            "alterId": 64
          }
        ]
      },
      "sniffing": {
        "enabled": true, //一定要开启 sniffing，V2Ray 才能识别 google 的流量
        "destOverride": ["http", "tls"]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
        "path": "/one"
        }
      }
    }
  ],
"outbounds": [
    {
      "tag":"IP4_out",
      "protocol": "freedom",
      "settings": {}
    },
    {
      "tag":"IP6_out",
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIPv6" // 指定使用 IPv6
      }
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "outboundTag": "IP6_out",
        "domain": ["geosite:google"] // google 走 IPv6
      },
      {
        "type": "field",
        "outboundTag": "IP4_out",
        "network": "udp,tcp"// 其余走 IPv4
      }
    ]
  }
}

EOF

sed -i "s/uuid/${uuid}/" /etc/v2ray/config.json

cat > /srv/sebs.js <<'EOF'
 {
    "add":"domain",
    "aid":"0",
    "host":"",
    "id":"uuid",
    "net":"ws",
    "path":"/one",
    "port":"443",
    "ps":"sebsclub",
    "tls":"tls",
    "type":"none",
    "v":"2"
  }
EOF

if [ "$psname" != "" ] && [ "$psname" != "-c" ]; then
  sed -i "s/sebsclub/${psname}/" /srv/sebs.js
  sed -i "s/domain/${domain}/" /srv/sebs.js
  sed -i "s/uuid/${uuid}/" /srv/sebs.js
else
  $*
fi
pwd
cp /etc/Caddyfile .
nohup /bin/parent caddy  --log stdout --agree=false &
echo "配置 JSON 详情"
echo " "
cat /etc/v2ray/config.json
echo " "
node v2ray.js
/usr/bin/v2ray -config /etc/v2ray/config.json

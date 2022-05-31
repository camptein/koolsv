#!/bin/sh
##

# Set ARG
ARCH="64"
DOWNLOAD_PATH="/tmp/v2ray"

mkdir -p ${DOWNLOAD_PATH}
cd ${DOWNLOAD_PATH} || exit

TAG=$(wget --no-check-certificate -qO- https://api.github.com/repos/v2fly/v2ray-core/releases/latest | grep 'tag_name' | cut -d\" -f4)
if [ -z "${TAG}" ]; then
    echo "Error: Get v2ray latest version failed" && exit 1
fi
echo "The v2ray latest version: ${TAG}"

# Download files
V2RAY_FILE="v2ray-linux-${ARCH}.zip"
DGST_FILE="v2ray-linux-${ARCH}.zip.dgst"
echo "Downloading binary file: ${V2RAY_FILE}"
echo "Downloading binary file: ${DGST_FILE}"

# TAG=$(wget -qO- https://raw.githubusercontent.com/v2fly/docker/master/ReleaseTag | head -n1)
wget -O ${DOWNLOAD_PATH}/v2ray.zip https://github.com/v2fly/v2ray-core/releases/download/${TAG}/${V2RAY_FILE} >/dev/null 2>&1
wget -O ${DOWNLOAD_PATH}/v2ray.zip.dgst https://github.com/v2fly/v2ray-core/releases/download/${TAG}/${DGST_FILE} >/dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Error: Failed to download binary file: ${V2RAY_FILE} ${DGST_FILE}" && exit 1
fi
echo "Download binary file: ${V2RAY_FILE} ${DGST_FILE} completed"

# Check SHA512
LOCAL=$(openssl dgst -sha512 v2ray.zip | sed 's/([^)]*)//g')
STR=$(cat < v2ray.zip.dgst | grep 'SHA512' | head -n1)

if [ "${LOCAL}" = "${STR}" ]; then
    echo " Check passed" && rm -fv v2ray.zip.dgst
else
    echo " Check have not passed yet " && exit 1
fi

# Prepare
echo "Prepare to use"
unzip v2ray.zip && chmod +x v2ray v2ctl
mv v2ray v2ctl /usr/bin/
mv geosite.dat geoip.dat /usr/local/share/v2ray/
# mv config.json /etc/v2ray/config.json

cat << EOF > /conf/config.json
{
    "log": {
        "loglevel": "none"
    },
    "inbounds": [
        {   
            "listen": "/etc/caddy/vmess,0644",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "a8fef338-0d8d-4606-a2f9-2c39b90e6e4d"
                    }
                ],
                "disableInsecureEncryption": true
            },
            "streamSettings": {
                "network": "ws",
                "allowInsecure": false,
                "wsSettings": {
                  "path": "/a8fef338-0d8d-4606-a2f9-2c39b90e6e4d-vmess"
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }
        },
        {   
            "listen": "/etc/caddy/vless,0644",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "a8fef338-0d8d-4606-a2f9-2c39b90e6e4d",
                        "level": 0,
                        "email": "love@v2fly.org"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "allowInsecure": false,
                "wsSettings": {
                  "path": "/a8fef338-0d8d-4606-a2f9-2c39b90e6e4d-vless"
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }
        },
        {   
            "listen": "127.0.0.1",
            "port": 4324,
            "protocol": "shadowsocks",
            "settings": {
                "email": "love@v2fly.org",
                "method": "chacha20-ietf-poly1305",
                "password":"$AUUID",
                "network": "tcp,udp",
                "ivCheck": true
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "/a8fef338-0d8d-4606-a2f9-2c39b90e6e4d-ss"
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }
        },
        {   
            "listen": "127.0.0.1",
            "port": 5234,
            "protocol": "socks",
            "settings": {
                "auth": "password",
                "accounts": [
                    {
                        "user": "$AUUID",
                        "pass": "$AUUID"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                  "path": "/a8fef338-0d8d-4606-a2f9-2c39b90e6e4d-socks"
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }
        },
        {   
            "listen": "/etc/caddy/trojan,0644",
            "protocol": "trojan",
            "settings": {
                "clients": [
                    {
                        "password":"$AUUID",
                        "level": 0,
                        "email": "love@v2fly.org"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "allowInsecure": false,
                "wsSettings": {
                  "path": "/a8fef338-0d8d-4606-a2f9-2c39b90e6e4d-trojan"
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }
        }
    ],
    "routing": {
        "domainStrategy": "IPIfNonMatch",
        "domainMatcher": "mph",
        "rules": [
           {
              "type": "field",
              "protocol": [
                 "bittorrent"
              ],
              "domains": [
                  "geosite:cn",
                  "geosite:category-ads-all"
              ],
              "outboundTag": "blocked"
           },
           {
              "type": "field",
              "outboundTag":
                  "sockstor",
                  "domains": [
                      "geosite:tor"
                  ]
           },
           {
              "type": "field",
              "outboundTag": "blocked",
              "domains": [
                  "geosite:category-ads-all"
              ]
           }
        ]
    },
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv4",
                "userLevel": 0
            }
        },
        {
            "protocol": "blackhole",
            "tag": "blocked"
        },
        {
            "protocol": "socks",
            "tag": "sockstor",
            "settings": {
                "servers": [
                    {
                        "address": "127.0.0.1",
                        "port": 9050
                    }
                ]
            }
        }
    ],
    "dns": {
        "servers": [
            {
                "address": "https+local://dns.google/dns-query",
                "address": "https+local://cloudflare-dns.com/dns-query",
                "skipFallback": true
            }
        ],
        "queryStrategy": "UseIPv4",
        "disableCache": true,
        "disableFallbackIfMatch": false
    }
}
EOF
# Clean
cd ~ || return
rm -rf ${DOWNLOAD_PATH:?}/*
# Make configs
mkdir -p /etc/caddy/ /usr/share/caddy/
unzip  -qo /Technology2.zip -d /usr/share/caddy
rm -rf /Technology2.zip
cat > /usr/share/caddy/robots.txt << EOF
User-agent: *
Disallow: /
EOF
sed -e "s/\$AUUID/$AUUID/g" /conf/config.json >/etc/v2ray/config.json
sed -e "1c :$PORT" -e "s/\$AUUID/$AUUID/g" -e "s/\$MYUUID-HASH/$(caddy hash-password --plaintext $AUUID)/g" /conf/Caddyfile >/etc/caddy/Caddyfile
# Remove temporary directory
rm -rf /conf
# Let's get start
tor & /usr/bin/v2ray -config /etc/v2ray/config.json & /usr/bin/caddy run --config /etc/caddy/Caddyfile --adapter caddyfile

#!/bin/sh

# 在后台启动 cron 服务
crond -l 2 -b

# 使用 acme.sh 申请证书
export CF_Email="${CF_EMAIL}"
export CF_Key="${CF_API_KEY}"
/root/.acme.sh/acme.sh --issue --dns dns_cf -d "${HYSTERIA_DOMAIN}" --cert-file /app/cert.pem --key-file /app/key.pem --reloadcmd "pkill -HUP -x hysteria"

# 添加自动更新证书的定时任务
echo "0 0 1 * * /root/.acme.sh/acme.sh --renew --dns dns_cf -d ${HYSTERIA_DOMAIN} --cert-file /app/cert.pem --key-file /app/key.pem --reloadcmd \"pkill -HUP -x hysteria\"" >> /etc/crontabs/root

# 生成服务器端配置文件
cat << EOF > /app/hysteria_config.json
{
  "listen": "${HYSTERIA_LISTEN}",
  "server_name": "${HYSTERIA_DOMAIN}",
  "cert": "${HYSTERIA_CERT}",
  "key": "${HYSTERIA_KEY}",
  "up_mbps": ${HYSTERIA_UP_MBPS},
  "down_mbps": ${HYSTERIA_DOWN_MBPS},
  "server_mode": {
    "auth": {
      "mode": "password",
      "config": {
        "username": "${HYSTERIA_USER}",
        "password": "${HYSTERIA_PASS}"
      }
    }
  }
}
EOF

# 创建客户端配置文件
jq -c '.server_mode.auth.config[]' /app/hysteria_config.json | while read -r client; do
    username=$(echo "$client" | jq -r '.username')
    password=$(echo "$client" | jq -r '.password')

    cat << EOF > /app/client_config_$username.json
{
  "server": "${HYSTERIA_DOMAIN}:${HYSTERIA_PORT}",
  "up_mbps": ${HYSTERIA_UP_MBPS},
  "down_mbps": ${HYSTERIA_DOWN_MBPS},
  "insecure": false,
  "client_mode": {
    "username": "$username",
    "password": "$password"
  }
}
EOF

    echo "Client config for $username created."
done

# 运行 Hysteria 服务器
/usr/bin/hysteria -c /app/hysteria_config.json

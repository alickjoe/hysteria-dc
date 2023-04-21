FROM alpine:latest

# 安装依赖、az 工具、jq 和 cron
RUN apk add --update --no-cache \
    curl \
    tar \
    openssl \
    python3 \
    py3-pip \
    jq \
    dcron \
    socat \
  && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
  && pip3 install --upgrade pip \
  && rm -rf /var/cache/apk/*

# 安装 acme.sh
RUN curl https://get.acme.sh | sh

# 下载 Hysteria
RUN wget https://github.com/HyNetwork/hysteria/releases/download/{version}/hysteria-linux-amd64 -O /usr/bin/hysteria \
  && chmod +x /usr/bin/hysteria

# 创建卷以存储配置文件和脚本
VOLUME /app

# 添加并设置脚本文件权限
COPY update_cf_dns.sh /app/update_cf_dns.sh
RUN chmod +x /app/update_cf_dns.sh

# 添加入口点脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 设置定时任务
RUN echo "*/5 * * * * /app/update_cf_dns.sh" > /etc/crontabs/root

# 设置环境变量的默认值
ENV HYSTERIA_LISTEN :443
ENV HYSTERIA_DOMAIN your.domain.com
ENV HYSTERIA_PORT 443
ENV HYSTERIA_USER username
ENV HYSTERIA_PASS password
ENV HYSTERIA_UP_MBPS 50
ENV HYSTERIA_DOWN_MBPS 150
ENV HYSTERIA_CERT /app/cert.pem
ENV HYSTERIA_KEY /app/key.pem
ENV CF_EMAIL your_cloudflare_email
ENV CF_API_KEY your_cloudflare_api_key

# 暴露其他端口
EXPOSE 80 443 8080 22

# 设置入口点
ENTRYPOINT ["/entrypoint.sh"]

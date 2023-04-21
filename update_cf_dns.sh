#!/bin/bash

# Cloudflare API 令牌
CF_API_TOKEN=""

# Cloudflare Zone ID
CF_ZONE_ID=""

# 需要更新的 A 记录名称
DOMAIN_NAME=""

# Azure 资源组名称
RESOURCE_GROUP=""

# Azure Container Instance 名称
CONTAINER_INSTANCE_NAME=""

# 获取 Azure Container Instance 的公共 IP 地址
aci_ip=$(az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_INSTANCE_NAME --query 'ipAddress.ip' --output tsv)

# 获取当前 Cloudflare A 记录的 IP 地址
cf_record_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?type=A&name=$DOMAIN_NAME" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json")

cf_record_ip=$(echo $cf_record_info | jq -r '.result[0].content')
cf_record_id=$(echo $cf_record_info | jq -r '.result[0].id')

# 检查 IP 地址是否有变化
if [ "$aci_ip" != "$cf_record_ip" ]; then
  echo "IP 地址已更改，正在更新 Cloudflare A 记录..."

  # 更新 Cloudflare A 记录
  curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$cf_record_id" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$DOMAIN_NAME\",\"content\":\"$aci_ip\",\"ttl\":120,\"proxied\":false}"

  echo "Cloudflare A 记录已更新。"
else
  echo "IP 地址未更改，无需更新。"
fi

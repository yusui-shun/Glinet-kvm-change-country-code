#!/bin/bash
#===============================================================================
# 国家码配置脚本
#===============================================================================
# 用途: 快速切换国家码配置
# 使用: setup-country-code.sh [CN|US|EU|GB|JP|KR]
#===============================================================================

set -e

COUNTRY_CODE="${1:-CN}"
USER_CONFIG_DIR="/etc/kvmd/user"
CLOUD_CONFIG="/etc/glinet/gl-cloud.conf"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 验证国家码
if [[ ! "$COUNTRY_CODE" =~ ^(CN|US|EU|GB|JP|KR)$ ]]; then
    echo -e "${RED}错误: 不支持的国家码 '$COUNTRY_CODE'${NC}"
    echo "支持的国家码: CN, US, EU, GB, JP, KR"
    exit 1
fi

# 生成唯一 token
TOKEN=$(uuidgen | tr -d '-')

# 创建用户配置目录
mkdir -p "$USER_CONFIG_DIR"

# 设置国家码
echo "$COUNTRY_CODE" > "$USER_CONFIG_DIR/country_code"

# 根据国家码选择服务器
case "$COUNTRY_CODE" in
    CN)
        SERVER="gslb.gl-inet.cn"
        BINDING_DOMAIN="www.glkvm.cn"
        STUN_SERVER="stun.miwifi.com:3478"
        ;;
    *)
        SERVER="gslb-eu.goodcloud.xyz"
        BINDING_DOMAIN="www.glkvm.com"
        STUN_SERVER="stun.l.google.com:19302"
        ;;
esac

# 配置云服务（自动生成 token）
cat > "$CLOUD_CONFIG" <<EOF
{
  "enable": true,
  "server": "$SERVER",
  "token": "$TOKEN"
}
EOF

# 重启服务
if [ -f /etc/init.d/S99gl-cloud ]; then
    /etc/init.d/S99gl-cloud restart >/dev/null 2>&1
fi

# 重新加载 KVMD
killall -HUP kvmd >/dev/null 2>&1 || true

echo ""
echo "=========================================="
echo -e "${GREEN}配置成功！${NC}"
echo "=========================================="
echo "国家码:        $COUNTRY_CODE"
echo "GSLB 服务器:   $SERVER"
echo "绑定域名:      $BINDING_DOMAIN"
echo "STUN 服务器:   $STUN_SERVER"
echo "Token:         $TOKEN"
echo "=========================================="
echo -e "${YELLOW}⚠️  请保密此 token！${NC}"
echo "=========================================="
echo ""
echo "请访问 Web UI 验证配置:"
echo "  https://192.168.8.107"
echo ""

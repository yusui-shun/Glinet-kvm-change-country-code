#!/bin/bash
#===============================================================================
# GL.iNet RM1 国家码覆盖工具 - 卸载脚本
#===============================================================================
# 功能: 移除国家码覆盖，恢复原始配置
#===============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    print_error "请使用 root 权限运行此脚本"
    exit 1
fi

echo ""
echo "=========================================="
echo "  GL.iNet RM1 国家码覆盖工具 - 卸载"
echo "=========================================="
echo ""

# 确认卸载
read -p "确定要卸载国家码覆盖工具吗？(y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    print_info "取消卸载"
    exit 0
fi

# 恢复原始 KVMD 脚本
if [ -f "/usr/bin/kvmd.bak" ]; then
    print_info "恢复原始 KVMD 脚本..."
    cp /usr/bin/kvmd.bak /usr/bin/kvmd
    chmod +x /usr/bin/kvmd
    print_info "已恢复 /usr/bin/kvmd"
else
    print_warn "未找到备份文件 /usr/bin/kvmd.bak"
fi

# 恢复云服务配置
if [ -f "/etc/glinet/gl-cloud.conf.bak" ]; then
    print_info "恢复原始云服务配置..."
    cp /etc/glinet/gl-cloud.conf.bak /etc/glinet/gl-cloud.conf
    print_info "已恢复 /etc/glinet/gl-cloud.conf"
fi

# 删除用户配置
if [ -d "/etc/kvmd/user" ]; then
    print_info "删除用户配置目录..."
    rm -rf /etc/kvmd/user
    print_info "已删除 /etc/kvmd/user"
fi

# 删除配置脚本
if [ -f "/usr/bin/setup-country-code.sh" ]; then
    print_info "删除配置脚本..."
    rm -f /usr/bin/setup-country-code.sh
fi

# 重启 KVMD 服务
print_info "重启 KVMD 服务..."
if [ -f /etc/init.d/kvmd ]; then
    /etc/init.d/kvmd restart
else
    killall kvmd >/dev/null 2>&1 || true
    sleep 2
fi

# 重启云服务
if [ -f /etc/init.d/S99gl-cloud ]; then
    print_info "重启云服务..."
    /etc/init.d/S99gl-cloud restart
fi

echo ""
echo "=========================================="
echo -e "${GREEN}卸载完成！${NC}"
echo "=========================================="
echo ""
echo "系统已恢复到原始配置。"
echo ""

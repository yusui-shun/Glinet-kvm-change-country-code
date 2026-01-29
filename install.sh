#!/bin/bash
#===============================================================================
# GL.iNet RM1 国家码覆盖工具 - 安装脚本
#===============================================================================
# 作者: 基于 GLKVM 源码分析
# 功能: 自动安装国家码覆盖工具
#===============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 root 权限运行此脚本"
        exit 1
    fi
}

# 检查设备兼容性
check_device() {
    print_info "检查设备兼容性..."

    # 检查是否为 GLKVM 设备
    if [ ! -f "/proc/gl-hw-info/device_mac" ]; then
        print_error "未检测到 GLKVM 设备"
        exit 1
    fi

    # 检查 KVMD 是否安装
    if [ ! -f "/usr/bin/kvmd" ]; then
        print_error "未检测到 KVMD 服务"
        exit 1
    fi

    print_info "设备兼容性检查通过"
}

# 备份原始文件
backup_files() {
    print_info "备份原始文件..."

    # 备份 KVMD 脚本
    if [ ! -f "/usr/bin/kvmd.bak" ]; then
        cp /usr/bin/kvmd /usr/bin/kvmd.bak
        print_info "已备份 /usr/bin/kvmd -> /usr/bin/kvmd.bak"
    else
        print_warn "备份文件已存在，跳过"
    fi

    # 备份云服务配置
    if [ -f "/etc/glinet/gl-cloud.conf" ] && [ ! -f "/etc/glinet/gl-cloud.conf.bak" ]; then
        cp /etc/glinet/gl-cloud.conf /etc/glinet/gl-cloud.conf.bak
        print_info "已备份 /etc/glinet/gl-cloud.conf -> /etc/glinet/gl-cloud.conf.bak"
    fi
}

# 安装 KVMD 覆盖脚本
install_kvmd_override() {
    print_info "安装 KVMD 覆盖脚本..."

    # 创建配置目录
    mkdir -p /etc/kvmd/user

    # 复制覆盖脚本
    cat > /usr/bin/kvmd <<'EOF'
#!/usr/bin/python3
import os
import sys

# 用户国家码配置文件
user_cc_file = '/etc/kvmd/user/country_code'
country_code = ''

# 读取用户配置的国家码
if os.path.exists(user_cc_file):
    with open(user_cc_file) as f:
        country_code = f.read().strip()

# 如果配置了国家码，则应用 Monkey Patching
if country_code:
    import io
    _original_open = open

    def _patched_open(path, *args, **kwargs):
        if 'gl-hw-info' in str(path) and 'country_code' in str(path):
            return io.StringIO(country_code + '\n')
        return _original_open(path, *args, **kwargs)

    import builtins
    builtins.open = _patched_open

# 导入并运行 KVMD 主程序
from kvmd.apps.kvmd import main

if __name__ == '__main__':
    main()
EOF

    chmod +x /usr/bin/kvmd
    print_info "KVMD 覆盖脚本安装完成"
}

# 安装配置脚本
install_config_script() {
    print_info "安装配置脚本..."

    cat > /usr/bin/setup-country-code.sh <<'EOF'
#!/bin/bash
#===============================================================================
# 国家码配置脚本
#===============================================================================

set -e

COUNTRY_CODE="${1:-CN}"
USER_CONFIG_DIR="/etc/kvmd/user"
CLOUD_CONFIG="/etc/glinet/gl-cloud.conf"

# 验证国家码
if [[ ! "$COUNTRY_CODE" =~ ^(CN|US|EU|GB|JP|KR)$ ]]; then
    echo "错误: 不支持的国家码 '$COUNTRY_CODE'"
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
        ;;
    *)
        SERVER="gslb-eu.goodcloud.xyz"
        ;;
esac

# 配置云服务（自动生成 token）
cat > "$CLOUD_CONFIG" <<CONF
{
  "enable": true,
  "server": "$SERVER",
  "token": "$TOKEN"
}
CONF

# 重启服务
if [ -f /etc/init.d/S99gl-cloud ]; then
    /etc/init.d/S99gl-cloud restart >/dev/null 2>&1
fi

# 重新加载 KVMD
killall -HUP kvmd >/dev/null 2>&1 || true

echo "=========================================="
echo "国家码已设置为: $COUNTRY_CODE"
echo "GSLB 服务器: $SERVER"
echo "Token: $TOKEN"
echo "=========================================="
echo "⚠️  请保密此 token！"
echo "=========================================="
EOF

    chmod +x /usr/bin/setup-country-code.sh
    print_info "配置脚本安装完成: /usr/bin/setup-country-code.sh"
}

# 询问用户初始配置
ask_initial_config() {
    echo ""
    echo "=========================================="
    echo "  安装完成！现在配置国家码"
    echo "=========================================="
    echo ""
    echo "请选择服务器区域:"
    echo "  1) 中国 (CN)    - www.glkvm.cn"
    echo "  2) 国际 (US)    - www.glkvm.com"
    echo ""
    read -p "请输入选项 [1-2]: " choice

    case "$choice" in
        1)
            COUNTRY="CN"
            ;;
        2)
            COUNTRY="US"
            ;;
        *)
            print_warn "无效选项，使用默认配置 (CN)"
            COUNTRY="CN"
            ;;
    esac

    print_info "正在配置国家码为: $COUNTRY"
    /usr/bin/setup-country-code.sh "$COUNTRY"
}

# 验证安装
verify_installation() {
    print_info "验证安装..."

    # 检查文件是否存在
    if [ ! -f "/usr/bin/kvmd" ]; then
        print_error "KVMD 脚本不存在"
        exit 1
    fi

    if [ ! -f "/usr/bin/setup-country-code.sh" ]; then
        print_error "配置脚本不存在"
        exit 1
    fi

    # 检查配置目录
    if [ ! -d "/etc/kvmd/user" ]; then
        print_error "配置目录不存在"
        exit 1
    fi

    # 检查 KVMD 语法
    if ! python3 -m py_compile /usr/bin/kvmd 2>/dev/null; then
        print_error "KVMD 脚本语法错误"
        exit 1
    fi

    print_info "安装验证通过"
}

# 显示使用说明
show_usage() {
    echo ""
    echo "=========================================="
    echo "  安装成功！"
    echo "=========================================="
    echo ""
    echo "使用方法:"
    echo ""
    echo "  切换到中国服务器:"
    echo "    setup-country-code.sh CN"
    echo ""
    echo "  切换到国际服务器:"
    echo "    setup-country-code.sh US"
    echo ""
    echo "  查看当前配置:"
    echo "    cat /etc/kvmd/user/country_code"
    echo "    cat /etc/glinet/gl-cloud.conf"
    echo ""
    echo "  重启 KVMD:"
    echo "    /etc/init.d/kvmd restart"
    echo ""
    echo "=========================================="
    echo ""
    echo "卸载方法:"
    echo ""
    echo "  恢复原始配置:"
    echo "    cp /usr/bin/kvmd.bak /usr/bin/kvmd"
    echo "    rm -rf /etc/kvmd/user"
    echo "    /etc/init.d/kvmd restart"
    echo ""
    echo "=========================================="
    echo ""
}

# 主函数
main() {
    echo ""
    echo "=========================================="
    echo "  GL.iNet RM1 国家码覆盖工具 - 安装"
    echo "=========================================="
    echo ""

    check_root
    check_device
    backup_files
    install_kvmd_override
    install_config_script
    verify_installation
    ask_initial_config
    show_usage

    print_info "安装完成！"
}

# 运行主函数
main

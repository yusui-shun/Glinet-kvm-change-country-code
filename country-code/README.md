# GL.iNet 国家码覆盖工具 / GL.iNet Country Code Override Tool

> [中文](#中文文档) | [English](#english)

---

## <a name="中文文档"></a>中文文档

> **适用设备**: GL.iNet GLKVM 设备（RM1、RM10 等）
>
> **功能**: 在不重新编译固件的情况下，修改设备的国家码配置，实现中国/国际服务器的切换

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

---

## 📚 目录

- [功能简介](#功能简介)
- [安全警告](#安全警告)
- [工作原理](#工作原理)
- [安装步骤](#安装步骤)
- [使用方法](#使用方法)
- [故障排查](#故障排查)
- [常见问题](#常见问题)

---

## 🎯 功能简介

本工具允许你在用户空间覆盖 GL.iNet GLKVM 设备的国家码配置，实现以下功能：

### 主要功能

1. **STUN 服务器切换**
   - 中国服务器: `stun.miwifi.com:3478`
   - 其他地区: `stun.l.google.com:19302`

2. **云服务绑定域名切换**
   - 中国服务器: `www.glkvm.cn`
   - 其他地区: `www.glkvm.com`

3. **动态绑定码生成**
   - 根据国家码生成对应地区的 8 位动态绑定码

4. **完全用户空间实现**
   - 无需修改内核模块
   - 无需重新编译固件
   - 不影响原系统文件
   - 可随时恢复

### 应用场景

- **国内用户**: 使用国内云服务，获得更快的连接速度
- **国外用户**: 使用国际云服务，获得更好的访问体验
- **开发者**: 测试不同地区的云服务功能
- **隐私保护**: 不希望连接到特定地区的服务器

---

## ⚠️ 安全警告

### 🔐 Token 说明

**重要**: 每台设备的 `token` 是唯一的身份标识符，请妥善保管！

- 本工具会自动为每台设备生成唯一的随机 token
- 不要分享包含真实 token 的配置文件
- 不要在公开场合发布 token

---

## 🔧 工作原理

### 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                        用户空间                               │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐     ┌──────────────┐                     │
│  │ KVMD 守护进程  │────▶│ STUN 服务器   │                     │
│  │  (Python)    │     │   选择        │                     │
│  └──────▲───────┘     └──────────────┘                     │
│         │                                                      │
│         │ Monkey Patching                                     │
│         │                                                      │
│  ┌──────┴──────┐     ┌──────────────┐                     │
│  │open() 拦截  │     │  云服务绑定   │                     │
│  │             │     │  API         │                     │
│  └──────┬──────┘     └──────▲───────┘                     │
│         │                   │                              │
├─────────┼───────────────────┼──────────────────────────────┤
│         │      内核空间       │                              │
│  ┌──────┴──────┐             │                              │
│  │/proc/gl-    │             │                              │
│  │hw-info/     │             │                              │
│  │country_code │             │                              │
│  └─────────────┘             │                              │
│         │                    │                              │
│  ┌──────┴────────────────────┴──────┐                      │
│  │   gl_hw_info 内核模块              │                      │
│  │   (只读，无法修改)                  │                      │
│  └────────────────────────────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

### 实现机制

**问题**: KVMD 从 `/proc/gl-hw-info/country_code` 读取国家码，但该文件由内核模块提供，无法直接修改。

**解决方案**: 使用 Python Monkey Patching 技术

```python
# 原始代码
country_code = open('/proc/gl-hw-info/country_code').read().strip()

# Monkey Patching 后
import io
_original_open = open

def _patched_open(path, *args, **kwargs):
    if 'gl-hw-info' in str(path) and 'country_code' in str(path):
        return io.StringIO('CN\n')  # 返回用户配置的国家码
    return _original_open(path, *args, **kwargs)

import builtins
builtins.open = _patched_open
```

**效果**: 当 KVMD 尝试读取国家码时，自动返回用户配置的值。

### GSLB 服务器映射

| 国家码 | GSLB 服务器 | 绑定域名 | STUN 服务器 |
|--------|------------|---------|------------|
| CN     | gslb.gl-inet.cn | www.glkvm.cn | stun.miwifi.com:3478 |
| 其他地区 | gslb-eu.goodcloud.xyz | www.glkvm.com | stun.l.google.com:19302 |

---

## 📥 安装步骤

### 系统要求

- GL.iNet GLKVM 设备（RM1、RM10 等）
- Root 权限
- 网络连接
- Python 3.x（系统自带）

### 自动安装（推荐）

```bash
# 1. 下载工具包
git clone https://github.com/yusui-shun/glinet-change-country-code.git
cd glinet-change-country-code/country-code

# 2. 运行安装脚本
chmod +x install.sh
./install.sh

# 3. 配置国家码
./setup-country-code.sh CN   # 中国
# 或
./setup-country-code.sh US   # 其他地区
```

### 快速安装（一键命令）

```bash
curl -fsSL https://raw.githubusercontent.com/yusui-shun/glinet-change-country-code/main/country-code/install.sh | bash
```

### 验证安装

```bash
# 1. 检查配置文件
cat /etc/kvmd/user/country_code
cat /etc/glinet/gl-cloud.conf

# 2. 检查 KVMD 进程
ps aux | grep kvmd

# 3. 测试 STUN API
curl -s http://localhost/api/turn/get_turn | jq
```

---

## 🎮 使用方法

### 快速切换国家码

#### 方法 1: 使用配置脚本（推荐）

```bash
# 切换到中国服务器
./setup-country-code.sh CN

# 切换到其他地区服务器
./setup-country-code.sh US
./setup-country-code.sh EU
./setup-country-code.sh GB
./setup-country-code.sh JP
./setup-country-code.sh KR
```

#### 方法 2: 手动配置

**切换到中国配置**:

```bash
# 1. 设置国家码
echo "CN" > /etc/kvmd/user/country_code

# 2. 设置云服务器
cat > /etc/glinet/gl-cloud.conf <<EOF
{
  "enable": true,
  "server": "gslb.gl-inet.cn",
  "token": "$(uuidgen | tr -d '-')"
}
EOF

# 3. 重启服务
/etc/init.d/S99gl-cloud restart
killall -HUP kvmd
```

**切换到其他地区配置**:

```bash
# 1. 设置国家码
echo "US" > /etc/kvmd/user/country_code

# 2. 设置云服务器
cat > /etc/glinet/gl-cloud.conf <<EOF
{
  "enable": true,
  "server": "gslb-eu.goodcloud.xyz",
  "token": "$(uuidgen | tr -d '-')"
}
EOF

# 3. 重启服务
/etc/init.d/S99gl-cloud restart
killall -HUP kvmd
```

### Web 验证

1. **访问 Web UI**
   ```
   https://<your-device-ip>
   ```
   替换 `<your-device-ip>` 为你的设备 IP 地址，例如：`https://192.168.1.100`

2. **检查动态绑定码**
   - 登录后，在主页查看 "Dynamic Binding Code"
   - 应该能看到 8 位绑定码

3. **检查云绑定链接**
   - 点击 "Cloud Service" 或 "云服务"
   - 中国配置: `https://www.glkvm.cn/#/bindDeviceByFirmware?...`
   - 其他地区配置: `https://www.glkvm.com/#/bindDeviceByFirmware?...`

### ⚠️ Cloud Service 绑定注意事项

**重要**: 在 Web UI 进行 Cloud Service 绑定时，请注意以下事项：

1. **绑定方式选择**
   - 执行完脚本后，在 Web UI 中会看到两个选项：
     - `Bind to KVMD CLOUD` - 绑定到云平台
     - `Bind with Code` - 使用绑定码绑定

2. **手动添加绑定码**
   - 无论选择哪种方式，都需要**手动在对应国家码的服务器平台添加绑定码**
   - 中国配置: 访问 `www.glkvm.cn` 添加绑定码
   - 其他地区配置: 访问 `www.glkvm.com` 添加绑定码

3. **域名匹配检查**
   - 绑定码必须与国家码对应的服务器平台匹配
   - **可能出现不匹配情况**:
     - 配置了中国服务器(CN)，但生成的是 `www.glkvm.com` 的绑定链接
     - 配置了国际服务器，但生成的是 `www.glkvm.cn` 的绑定链接
   - **解决方法**: 检查 `/etc/glinet/gl-cloud.conf` 中的 `server` 字段是否正确配置
     ```bash
     # 检查配置
     cat /etc/glinet/gl-cloud.conf

     # 重新生成绑定链接
     /usr/bin/eco /usr/bin/get_bindlink bindlink
     cat /var/run/cloud/bindlink
     ```

4. **验证绑定域名**
   - 在执行绑定前，请确认生成的绑定链接域名是否正确：
     - 中国配置应显示 `www.glkvm.cn`
     - 国际配置应显示 `www.glkvm.com`
   - 如果域名不匹配，请重新运行配置脚本并重启服务

---

## 🔍 故障排查

### 问题 1: 动态绑定码不显示

**症状**: Web UI 上看不到 "Dynamic Binding Code"

**原因**: KVMD 服务未正常启动

**解决方案**:

```bash
# 1. 检查 KVMD 进程
ps aux | grep kvmd

# 2. 查看 KVMD 日志
journalctl -u kvmd -n 50 --no-pager

# 3. 检查 KVMD 脚本语法
python3 -m py_compile /usr/bin/kvmd

# 4. 如果脚本有问题，恢复备份
cp /usr/bin/kvmd.bak /usr/bin/kvmd
/etc/init.d/kvmd restart
```

### 问题 2: 云绑定链接是错误的域名

**症状**: 设置 CN 配置后，绑定链接仍是 `www.glkvm.com`

**原因**: `/etc/glinet/gl-cloud.conf` 配置错误

**解决方案**:

```bash
# 1. 检查配置
cat /etc/glinet/gl-cloud.conf

# 2. 确认 server 字段正确
# 中国: "server": "gslb.gl-inet.cn"
# 其他地区: "server": "gslb-eu.goodcloud.xyz"

# 3. 重启云服务
/etc/init.d/S99gl-cloud restart

# 4. 重新生成绑定链接
/usr/bin/eco /usr/bin/get_bindlink bindlink
cat /var/run/cloud/bindlink
```

### 问题 3: 恢复原始配置

**完全卸载**:

```bash
# 1. 恢复原始 KVMD 脚本
cp /usr/bin/kvmd.bak /usr/bin/kvmd

# 2. 删除用户配置
rm -rf /etc/kvmd/user

# 3. 重启服务
/etc/init.d/kvmd restart
/etc/init.d/S99gl-cloud restart

# 4. 验证恢复
ps aux | grep kvmd
curl -s http://localhost/api/turn/get_turn | jq
```

---

## ❓ 常见问题

### Q: 这个工具只支持 RM1 吗？

A: 不只是 RM1。本工具适用于所有基于 GLKVM 的设备，包括 RM1、RM10 等。只要是 GLKVM 系统，都可以使用。

### Q: 修改国家码会影响设备保修吗？

A: 本工具完全在用户空间运行，不修改内核或固件，理论上不会影响保修。但请自行承担使用风险。

### Q: token 是什么？可以分享吗？

A: token 是设备的唯一身份标识符，用于云服务认证。每台设备的 token 都不同，**请勿分享**。

### Q: 如何知道当前使用的是哪个服务器？

A: 可以通过以下方式查看：
```bash
# 查看国家码
cat /etc/kvmd/user/country_code

# 查看云服务配置
cat /etc/glinet/gl-cloud.conf

# 查看绑定链接
curl -s http://localhost/api/astrowarp/get_bind_link | jq
```

### Q: 切换服务器后需要重启设备吗？

A: 不需要。脚本会自动重启相关服务（KVMD 和 gl-cloud），无需重启整个设备。

### Q: 支持哪些国家码？

A: 目前支持：CN（中国）、US（美国）、EU（欧洲）、GB（英国）、JP（日本）、KR（韩国）。其中 CN 使用中国服务器，其他所有国家码都使用国际服务器。

---

## 📄 许可证

本项目基于对 GLKVM 和 PiKVM 的研究分析，遵循 **GPL v3 许可证**。

### 免责声明

⚠️ **使用本工具的风险由用户自行承担**：
- 修改系统配置可能导致设备无法正常工作
- 云服务绑定可能违反 GL.iNet 的服务条款
- 请遵守相关法律法规
- 作者不对任何损失负责

---

## 📮 反馈与支持

- **Issues**: [提交问题](https://github.com/yusui-shun/glinet-change-country-code/issues)
- **Discussions**: [加入讨论](https://github.com/yusui-shun/glinet-change-country-code/discussions)

---

## 🙏 致谢

- **PiKVM 项目** - 优秀的 KVM over IP 解决方案
- **GL.iNet** - 硬件设备和开源 GLKVM 项目
- **Rockchip** - RK1126 SoC 和技术支持

---

**如果这个工具对你有帮助，请给个 Star ⭐**

---

## <a name="english"></a>English Documentation

> **Compatible Devices**: GL.iNet GLKVM devices (RM1, RM10, etc.)
>
> **Feature**: Modify device country code configuration without recompiling firmware to switch between CN/International servers

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

---

## 📚 Table of Contents

- [Features](#features)
- [Security Warning](#security-warning)
- [How It Works](#how-it-works)
- [Installation](#installation)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

---

## 🎯 Features

This tool allows you to override the country code configuration of GL.iNet GLKVM devices in user space, implementing the following functions:

### Main Features

1. **STUN Server Switching**
   - Chinese Server: `stun.miwifi.com:3478`
   - Other Regions: `stun.l.google.com:19302`

2. **Cloud Binding Domain Switching**
   - Chinese Server: `www.glkvm.cn`
   - Other Regions: `www.glkvm.com`

3. **Dynamic Binding Code Generation**
   - Generate 8-digit binding codes based on country code

4. **Pure User-Space Implementation**
   - No kernel module modification required
   - No firmware recompilation needed
   - No impact on original system files
   - Fully reversible

### Use Cases

- **Domestic Users**: Use domestic cloud services for faster connection speeds
- **International Users**: Use international cloud services for better access experience
- **Developers**: Test cloud service functionality in different regions
- **Privacy Protection**: Avoid connecting to servers in specific regions

---

## ⚠️ Security Warning

### 🔐 Token Notice

**Important**: Each device's `token` is a unique identifier and must be kept confidential!

- This tool automatically generates a unique random token for each device
- Do not share configuration files containing real tokens
- Do not publish tokens in public places

---

## 🔧 How It Works

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        User Space                             │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐     ┌──────────────┐                     │
│  │ KVMD Daemon  │────▶│ STUN Server  │                     │
│  │  (Python)    │     │   Selector    │                     │
│  └──────▲───────┘     └──────────────┘                     │
│         │                                                      │
│         │ Monkey Patching                                     │
│         │                                                      │
│  ┌──────┴──────┐     ┌──────────────┐                     │
│  │open() Hook  │     │Cloud Binding │                     │
│  │             │     │  API         │                     │
│  └──────┬──────┘     └──────▲───────┘                     │
│         │                   │                              │
├─────────┼───────────────────┼──────────────────────────────┤
│         │      Kernel Space  │                              │
│  ┌──────┴──────┐             │                              │
│  │/proc/gl-    │             │                              │
│  │hw-info/     │             │                              │
│  │country_code │             │                              │
│  └─────────────┘             │                              │
│         │                    │                              │
│  ┌──────┴────────────────────┴──────┐                      │
│  │   gl_hw_info Kernel Module       │                      │
│  │   (Read-only, unmodifiable)       │                      │
│  └────────────────────────────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

### Implementation Mechanism

**Problem**: KVMD reads country code from `/proc/gl-hw-info/country_code`, but this file is provided by kernel module and cannot be modified directly.

**Solution**: Use Python Monkey Patching technology

```python
# Original code
country_code = open('/proc/gl-hw-info/country_code').read().strip()

# After Monkey Patching
import io
_original_open = open

def _patched_open(path, *args, **kwargs):
    if 'gl-hw-info' in str(path) and 'country_code' in str(path):
        return io.StringIO('CN\n')  # Return user-configured country code
    return _original_open(path, *args, **kwargs)

import builtins
builtins.open = _patched_open
```

**Effect**: When KVMD tries to read country code, it automatically returns the user-configured value.

### GSLB Server Mapping

| Country Code | GSLB Server | Binding Domain | STUN Server |
|-------------|------------|---------|------------|
| CN     | gslb.gl-inet.cn | www.glkvm.cn | stun.miwifi.com:3478 |
| Other Regions | gslb-eu.goodcloud.xyz | www.glkvm.com | stun.l.google.com:19302 |

---

## 📥 Installation

### System Requirements

- GL.iNet GLKVM device (RM1, RM10, etc.)
- Root permissions
- Network connection
- Python 3.x (included in system)

### Automatic Installation (Recommended)

```bash
# 1. Download tool archive
git clone https://github.com/yusui-shun/glinet-change-country-code.git
cd glinet-change-country-code/country-code

# 2. Run installation script
chmod +x install.sh
./install.sh

# 3. Configure country code
./setup-country-code.sh CN   # China
# or
./setup-country-code.sh US   # Other regions
```

### Quick Install (One-line)

```bash
curl -fsSL https://raw.githubusercontent.com/yusui-shun/glinet-change-country-code/main/country-code/install.sh | bash
```

### Verify Installation

```bash
# 1. Check configuration files
cat /etc/kvmd/user/country_code
cat /etc/glinet/gl-cloud.conf

# 2. Check KVMD process
ps aux | grep kvmd

# 3. Test STUN API
curl -s http://localhost/api/turn/get_turn | jq
```

---

## 🎮 Usage

### Quick Country Code Switch

#### Method 1: Using Configuration Script (Recommended)

```bash
# Switch to Chinese server
./setup-country-code.sh CN

# Switch to other region servers
./setup-country-code.sh US
./setup-country-code.sh EU
./setup-country-code.sh GB
./setup-country-code.sh JP
./setup-country-code.sh KR
```

#### Method 2: Manual Configuration

**Switch to Chinese Configuration**:

```bash
# 1. Set country code
echo "CN" > /etc/kvmd/user/country_code

# 2. Configure cloud server
cat > /etc/glinet/gl-cloud.conf <<EOF
{
  "enable": true,
  "server": "gslb.gl-inet.cn",
  "token": "$(uuidgen | tr -d '-')"
}
EOF

# 3. Restart services
/etc/init.d/S99gl-cloud restart
killall -HUP kvmd
```

**Switch to Other Region Configuration**:

```bash
# 1. Set country code
echo "US" > /etc/kvmd/user/country_code

# 2. Configure cloud server
cat > /etc/glinet/gl-cloud.conf <<EOF
{
  "enable": true,
  "server": "gslb-eu.goodcloud.xyz",
  "token": "$(uuidgen | tr -d '-')"
}
EOF

# 3. Restart services
/etc/init.d/S99gl-cloud restart
killall -HUP kvmd
```

### Web Verification

1. **Access Web UI**
   ```
   https://<your-device-ip>
   ```
   Replace `<your-device-ip>` with your device's IP address, e.g.: `https://192.168.1.100`

2. **Check Dynamic Binding Code**
   - Login and check "Dynamic Binding Code" on homepage
   - Should see 8-digit binding code

3. **Check Cloud Binding Link**
   - Click "Cloud Service"
   - Chinese config: `https://www.glkvm.cn/#/bindDeviceByFirmware?...`
   - Other region config: `https://www.glkvm.com/#/bindDeviceByFirmware?...`

### ⚠️ Cloud Service Binding Notes

**Important**: When binding Cloud Service in Web UI, please note:

1. **Binding Method Selection**
   - After running the script, you will see two options in Web UI:
     - `Bind to KVMD CLOUD` - Bind to cloud platform
     - `Bind with Code` - Use binding code to bind

2. **Manually Add Binding Code**
   - Regardless of which method you choose, you need to **manually add the binding code on the corresponding country code's server platform**
   - Chinese config: Visit `www.glkvm.cn` to add binding code
   - Other region config: Visit `www.glkvm.com` to add binding code

3. **Domain Matching Check**
   - The binding code must match the server platform corresponding to the country code
   - **Mismatch may occur**:
     - Configured for Chinese server (CN), but generates binding link for `www.glkvm.com`
     - Configured for International server, but generates binding link for `www.glkvm.cn`
   - **Solution**: Check if the `server` field in `/etc/glinet/gl-cloud.conf` is correctly configured
     ```bash
     # Check configuration
     cat /etc/glinet/gl-cloud.conf

     # Regenerate binding link
     /usr/bin/eco /usr/bin/get_bindlink bindlink
     cat /var/run/cloud/bindlink
     ```

4. **Verify Binding Domain**
   - Before binding, confirm the generated binding link domain is correct:
     - Chinese config should show `www.glkvm.cn`
     - International config should show `www.glkvm.com`
   - If domain doesn't match, re-run configuration script and restart services

---

## 🔍 Troubleshooting

### Problem 1: Dynamic Binding Code Not Displayed

**Symptom**: Web UI doesn't show "Dynamic Binding Code"

**Cause**: KVMD service not started properly

**Solution**:

```bash
# 1. Check KVMD process
ps aux | grep kvmd

# 2. View KVMD logs
journalctl -u kvmd -n 50 --no-pager

# 3. Check KVMD script syntax
python3 -m py_compile /usr/bin/kvmd

# 4. If script has problems, restore backup
cp /usr/bin/kvmd.bak /usr/bin/kvmd
/etc/init.d/kvmd restart
```

### Problem 2: Wrong Binding Domain

**Symptom**: Binding link shows `www.glkvm.com` even with CN config

**Cause**: `/etc/glinet/gl-cloud.conf` misconfigured

**Solution**:

```bash
# 1. Check configuration
cat /etc/glinet/gl-cloud.conf

# 2. Ensure server field is correct
# China: "server": "gslb.gl-inet.cn"
# Other regions: "server": "gslb-eu.goodcloud.xyz"

# 3. Restart cloud service
/etc/init.d/S99gl-cloud restart

# 4. Regenerate binding link
/usr/bin/eco /usr/bin/get_bindlink bindlink
cat /var/run/cloud/bindlink
```

### Problem 3: Restore Original Configuration

**Complete Uninstallation**:

```bash
# 1. Restore original KVMD script
cp /usr/bin/kvmd.bak /usr/bin/kvmd

# 2. Remove user configuration
rm -rf /etc/kvmd/user

# 3. Restart services
/etc/init.d/kvmd restart
/etc/init.d/S99gl-cloud restart

# 4. Verify restoration
ps aux | grep kvmd
curl -s http://localhost/api/turn/get_turn | jq
```

---

## ❓ FAQ

### Q: Does this tool only support RM1?

A: Not just RM1. This tool works with all GLKVM-based devices, including RM1, RM10, etc. As long as it's a GLKVM system, it can be used.

### Q: Will modifying country code affect device warranty?

A: This tool runs entirely in user space and doesn't modify the kernel or firmware. Theoretically, it shouldn't affect warranty, but use at your own risk.

### Q: What is the token? Can I share it?

A: The token is a unique identifier for the device, used for cloud service authentication. Each device has a different token. **Do not share it**.

### Q: How do I know which server I'm using?

A: You can check with:
```bash
# View country code
cat /etc/kvmd/user/country_code

# View cloud service configuration
cat /etc/glinet/gl-cloud.conf

# View binding link
curl -s http://localhost/api/astrowarp/get_bind_link | jq
```

### Q: Do I need to reboot the device after switching servers?

A: No. The script automatically restarts related services (KVMD and gl-cloud), no need to reboot the entire device.

### Q: Which country codes are supported?

A: Currently supported: CN (China), US (USA), EU (Europe), GB (UK), JP (Japan), KR (South Korea). CN uses Chinese servers, while all other country codes use international servers.

---

## 📄 License

This project is based on analysis of GLKVM and PiKVM, licensed under **GPL v3 License**.

### Disclaimer

⚠️ **Use this tool at your own risk**：
- Modifying system configuration may cause device malfunction
- Cloud service binding may violate GL.iNet's terms of service
- Please comply with relevant laws and regulations
- Authors are not responsible for any losses

---

## 📮 Feedback & Support

- **Issues**: [Submit Issue](https://github.com/yusui-shun/glinet-change-country-code/issues)
- **Discussions**: [Join Discussion](https://github.com/yusui-shun/glinet-change-country-code/discussions)

---

## 🙏 Acknowledgments

- **PiKVM Project** - Excellent KVM over IP solution
- **GL.iNet** - Hardware devices and open source GLKVM project
- **Rockchip** - RK1126 SoC and technical support

---

**If this tool helps you, please give it a Star ⭐**

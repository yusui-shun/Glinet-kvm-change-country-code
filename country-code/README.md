# GL.iNet RM1 国家码覆盖工具 / GL.iNet RM1 Country Code Override Tool

> **作者**: 基于 GLKVM 源码深度分析
> **Author**: Based on deep analysis of GLKVM source code
>
> **适用设备**: GL.iNet RM1 (以及其他基于 RK1126 的 GLKVM 设备)
> **Compatible Devices**: GL.iNet RM1 (and other RK1126-based GLKVM devices)
>
> **功能**: 在不重新编译固件的情况下，修改设备的国家码配置，实现中国/国际服务器的切换
> **Feature**: Modify device country code configuration without recompiling firmware to switch between CN/International servers

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform](https://img.shields.io/badge/platform-GL.iNet%20RM1-orange.svg)](https://www.gl-inet.com/products/gl-kvm)

---

## 📚 目录 / Table of Contents

- [功能简介 / Features](#功能简介--features)
- [安全警告 / Security Warning](#安全警告--security-warning)
- [工作原理 / How It Works](#工作原理--how-it-works)
- [安装步骤 / Installation](#安装步骤--installation)
- [使用方法 / Usage](#使用方法--usage)
- [故障排查 / Troubleshooting](#故障排查--troubleshooting)
- [技术细节 / Technical Details](#技术细节--technical-details)
- [参考资料 / References](#参考资料--references)

---

## 🎯 功能简介 / Features

### 主要功能 / Main Features

This tool allows you to override the country code configuration of GL.iNet RM1 devices in user space, implementing the following functions:
本工具允许你在用户空间覆盖 GL.iNet RM1 设备的国家码配置，实现以下功能：

1. **STUN 服务器切换 / STUN Server Switching**
   - 中国服务器 / Chinese Server: `stun.miwifi.com:3478`
   - 国际服务器 / International Server: `stun.l.google.com:19302`

2. **云服务绑定域名切换 / Cloud Binding Domain Switching**
   - 中国服务器 / Chinese Server: `www.glkvm.cn`
   - 国际服务器 / International Server: `www.glkvm.com`

3. **动态绑定码生成 / Dynamic Binding Code Generation**
   - Generate 8-digit binding codes based on country code
   - 根据国家码生成对应地区的 8 位动态绑定码

4. **完全用户空间实现 / Pure User-Space Implementation**
   - No kernel module modification required / 无需修改内核模块
   - No firmware recompilation needed / 无需重新编译固件
   - No impact on original system files / 不影响原系统文件
   - Fully reversible / 可随时恢复

### 应用场景 / Use Cases

- **国内用户 / Domestic Users**: Use domestic cloud services for faster connection speeds / 使用国内云服务，获得更快的连接速度
- **国外用户 / International Users**: Use international cloud services for better access experience / 使用国际云服务，获得更好的访问体验
- **开发者 / Developers**: Test cloud service functionality in different regions / 测试不同地区的云服务功能
- **隐私保护 / Privacy Protection**: Avoid connecting to servers in specific regions / 不希望连接到特定地区的服务器

---

## ⚠️ 安全警告 / Security Warning

### 🔐 Token 安全性 / Token Security

**重要 / Important**: Each device's `token` is a unique identifier and must be kept confidential!
每台设备的 `token` 是唯一的身份标识符，必须保密！

#### Token 的作用 / Token Purpose

- Authentication credential between device and GL.iNet cloud service
- 设备与 GL.iNet 云服务之间的身份验证凭证
- Unique identifier for device when binding to cloud service
- 绑定云服务时识别设备的唯一标识
- **Leaking token may allow device impersonation**
- **泄露 token 可能导致设备被冒充**

#### 安全措施 / Security Measures

1. **不要分享你的 token / Do Not Share Your Token**
   - ❌ Do not publish configuration files containing real tokens to GitHub
   - ❌ 不要将包含真实 token 的配置文件发布到 GitHub
   - ❌ Do not share tokens in public forums
   - ❌ 不要在公开论坛分享 token
   - ❌ Do not send tokens to others
   - ❌ 不要将 token 发送给他人

2. **每个设备生成唯一 token / Generate Unique Token for Each Device**
   - ✅ This tool automatically generates a unique random token for each device
   - ✅ 本工具会自动为每个设备生成唯一的随机 token
   - ✅ Use `uuidgen` to generate 32-character random string
   - ✅ 使用 `uuidgen` 生成 32 位随机字符串
   - ✅ Token format: `aa34bdb91ad5479d869d9976a92ded09`

3. **GitHub 发布时的正确做法 / Proper Practice for GitHub Publishing**
   ```json
   {
     "enable": true,
     "server": "gslb.gl-inet.cn",
     "token": "YOUR_DEVICE_TOKEN_HERE"
   }
   ```

---

## 🔧 工作原理 / How It Works

### 系统架构 / System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        用户空间 / User Space                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐     ┌──────────────┐                     │
│  │ KVMD 守护进程  │────▶│ STUN 服务器   │                     │
│  │ KVMD Daemon  │     │ STUN Server  │                     │
│  │  (Python)    │     │   Selector    │                     │
│  └──────▲───────┘     └──────────────┘                     │
│         │                                                      │
│         │ Monkey Patching                                     │
│         │                                                      │
│  ┌──────┴──────┐     ┌──────────────┐                     │
│  │open() 拦截  │     │  云服务绑定   │                     │
│  │open() Hook  │     │ Cloud Binding│                     │
│  │             │     │  API         │                     │
│  └──────┬──────┘     └──────▲───────┘                     │
│         │                   │                              │
├─────────┼───────────────────┼──────────────────────────────┤
│         │      内核空间 / Kernel Space                       │
│  ┌──────┴──────┐             │                              │
│  │/proc/gl-    │             │                              │
│  │hw-info/     │             │                              │
│  │country_code │             │                              │
│  └─────────────┘             │                              │
│         │                    │                              │
│  ┌──────┴────────────────────┴──────┐                      │
│  │   gl_hw_info 内核模块              │                      │
│  │   gl_hw_info Kernel Module        │                      │
│  │   (只读，无法修改 / Read-only)     │                      │
│  └────────────────────────────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

### 实现机制 / Implementation Mechanism

#### 1. KVMD 国家码覆盖 / KVMD Country Code Override

**问题 / Problem**: KVMD reads country code from `/proc/gl-hw-info/country_code`, but this file is provided by kernel module and cannot be modified directly.
KVMD 从 `/proc/gl-hw-info/country_code` 读取国家码，但该文件由内核模块提供，无法直接修改。

**解决方案 / Solution**: Use Python Monkey Patching technology / 使用 Python Monkey Patching 技术

```python
# Original code / 原始代码
country_code = open('/proc/gl-hw-info/country_code').read().strip()

# After Monkey Patching / Monkey Patching 后
import io
_original_open = open

def _patched_open(path, *args, **kwargs):
    if 'gl-hw-info' in str(path) and 'country_code' in str(path):
        # Return user-configured country code / 返回用户配置的国家码
        return io.StringIO('CN\n')
    return _original_open(path, *args, **kwargs)

import builtins
builtins.open = _patched_open
```

**效果 / Effect**: When KVMD tries to read country code, it automatically returns the user-configured value.
当 KVMD 尝试读取国家码时，自动返回用户配置的值。

#### 2. 云服务绑定配置 / Cloud Service Binding Configuration

Cloud service binding uses a separate configuration file `/etc/glinet/gl-cloud.conf`:
云服务绑定使用独立的配置文件 `/etc/glinet/gl-cloud.conf`：

```json
{
  "enable": true,
  "server": "gslb.gl-inet.cn",  // GSLB 服务器 / Server
  "token": "设备唯一标识 / Device Unique ID"
}
```

**绑定流程 / Binding Process**:

```
用户点击"Cloud Service" / User clicks "Cloud Service"
       ↓
前端调用: /api/astrowarp/get_bind_link
Frontend calls: /api/astrowarp/get_bind_link
       ↓
KVMD 执行: /usr/bin/eco /usr/bin/get_bindlink bindlink
KVMD executes: /usr/bin/eco /usr/bin/get_bindlink bindlink
       ↓
Lua 脚本读取 / Lua script reads:
  - /proc/gl-hw-info/device_mac
  /proc/gl-hw-info/device_sn
  /etc/glinet/gl-cloud.conf (server, token)
       ↓
调用 GSLB API / Call GSLB API:
  - gslb.gl-inet.cn (China / 中国)
  - gslb-eu.goodcloud.xyz (International / 国际)
       ↓
生成绑定链接 / Generate binding link:
  - https://www.glkvm.cn/... (China / 中国)
  - https://www.glkvm.com/... (International / 国际)
```

#### 3. GSLB 服务器映射 / GSLB Server Mapping

| 国家码 / Country Code | GSLB 服务器 / Server | 绑定域名 / Binding Domain | STUN 服务器 / STUN Server |
|--------|------------|---------|------------|
| CN     | gslb.gl-inet.cn | www.glkvm.cn | stun.miwifi.com:3478 |
| US/EU  | gslb-eu.goodcloud.xyz | www.glkvm.com | stun.l.google.com:19302 |

---

## 📥 安装步骤 / Installation

### 系统要求 / System Requirements

- GL.iNet RM1 (or other GLKVM devices) / GL.iNet RM1（或其他 GLKVM 设备）
- Root permissions / Root 权限
- Network connection / 网络连接
- Python 3.x (included in system) / Python 3.x（系统自带）

### 自动安装（推荐）/ Automatic Installation (Recommended)

```bash
# 1. Download tool archive / 下载工具包
git clone https://github.com/yusui-shun/glinet-change-country-code.git
cd glinet-change-country-code/country-code

# 2. Run installation script / 运行安装脚本
chmod +x install.sh
sudo ./install.sh

# 3. Configure country code / 配置国家码
./setup-country-code.sh CN   # China / 中国
# 或 / or
./setup-country-code.sh US   # International / 国际
```

### 快速安装 / Quick Install (One-line)

```bash
curl -fsSL https://raw.githubusercontent.com/yusui-shun/glinet-change-country-code/main/country-code/install.sh | bash
```

### 验证安装 / Verify Installation

```bash
# 1. Check configuration files / 检查配置文件
cat /etc/kvmd/user/country_code
cat /etc/glinet/gl-cloud.conf

# 2. Check KVMD process / 检查 KVMD 进程
ps aux | grep kvmd

# 3. Test STUN API / 测试 STUN API
curl -s http://localhost/api/turn/get_turn | jq

# 4. Test cloud binding API / 测试云绑定 API
curl -s http://localhost/api/astrowarp/get_bind_link | jq
```

---

## 🎮 使用方法 / Usage

### 快速切换国家码 / Quick Country Code Switch

#### 方法 1: 使用配置脚本（推荐）/ Method 1: Using Configuration Script (Recommended)

```bash
# Switch to Chinese server / 切换到中国服务器
./setup-country-code.sh CN

# Switch to International server / 切换到国际服务器
./setup-country-code.sh US

# Switch to European server / 切换到欧洲服务器
./setup-country-code.sh EU
```

#### 方法 2: 手动配置 / Method 2: Manual Configuration

**切换到中国配置 / Switch to Chinese Configuration**:

```bash
# 1. Set country code / 设置国家码
echo "CN" > /etc/kvmd/user/country_code

# 2. Configure cloud server / 设置云服务器
cat > /etc/glinet/gl-cloud.conf <<EOF
{
  "enable": true,
  "server": "gslb.gl-inet.cn",
  "token": "$(uuidgen | tr -d '-')"
}
EOF

# 3. Restart services / 重启服务
/etc/init.d/S99gl-cloud restart
killall -HUP kvmd
```

**切换到国际配置 / Switch to International Configuration**:

```bash
# 1. Set country code / 设置国家码
echo "US" > /etc/kvmd/user/country_code

# 2. Configure cloud server / 设置云服务器
cat > /etc/glinet/gl-cloud.conf <<EOF
{
  "enable": true,
  "server": "gslb-eu.goodcloud.xyz",
  "token": "$(uuidgen | tr -d '-')"
}
EOF

# 3. Restart services / 重启服务
/etc/init.d/S99gl-cloud restart
killall -HUP kvmd
```

### Web 验证 / Web Verification

1. **访问 Web UI / Access Web UI**
   ```
   https://192.168.8.107
   ```

2. **检查动态绑定码 / Check Dynamic Binding Code**
   - Login and check "Dynamic Binding Code" on homepage
   - 登录后，在主页查看 "Dynamic Binding Code"
   - Should see 8-digit binding code / 应该能看到 8 位绑定码

3. **检查云绑定链接 / Check Cloud Binding Link**
   - Click "Cloud Service" or "云服务"
   - 点击 "Cloud Service" 或 "云服务"
   - Chinese config: `https://www.glkvm.cn/#/bindDeviceByFirmware?...`
   - 中国配置: `https://www.glkvm.cn/#/bindDeviceByFirmware?...`
   - International config: `https://www.glkvm.com/#/bindDeviceByFirmware?...`
   - 国际配置: `https://www.glkvm.com/#/bindDeviceByFirmware?...`

---

## 🔍 故障排查 / Troubleshooting

### 问题 1: 动态绑定码不显示 / Problem 1: Dynamic Binding Code Not Displayed

**症状 / Symptom**: Web UI doesn't show "Dynamic Binding Code"
Web UI 上看不到 "Dynamic Binding Code"

**原因 / Cause**: KVMD service not started properly / KVMD 服务未正常启动

**解决方案 / Solution**:

```bash
# 1. Check KVMD process / 检查 KVMD 进程
ps aux | grep kvmd

# 2. View KVMD logs / 查看 KVMD 日志
journalctl -u kvmd -n 50 --no-pager

# 3. Check KVMD script syntax / 检查 KVMD 脚本语法
python3 -m py_compile /usr/bin/kvmd

# 4. If script has problems, restore backup / 如果脚本有问题，恢复备份
cp /usr/bin/kvmd.bak /usr/bin/kvmd
/etc/init.d/kvmd restart
```

### 问题 2: 云绑定链接是错误的域名 / Problem 2: Wrong Binding Domain

**症状 / Symptom**: Binding link shows `www.glkvm.com` even with CN config
设置 CN 配置后，绑定链接仍是 `www.glkvm.com`

**原因 / Cause**: `/etc/glinet/gl-cloud.conf` misconfigured
`/etc/glinet/gl-cloud.conf` 配置错误

**解决方案 / Solution**:

```bash
# 1. Check configuration / 检查配置
cat /etc/glinet/gl-cloud.conf

# 2. Ensure server field is correct / 确认 server 字段正确
# Chinese: "server": "gslb.gl-inet.cn" / 中国: "server": "gslb.gl-inet.cn"
# International: "server": "gslb-eu.goodcloud.xyz" / 国际: "server": "gslb-eu.goodcloud.xyz"

# 3. Restart cloud service / 重启云服务
/etc/init.d/S99gl-cloud restart

# 4. Regenerate binding link / 重新生成绑定链接
/usr/bin/eco /usr/bin/get_bindlink bindlink
cat /var/run/cloud/bindlink
```

### 问题 3: Token 冲突 / Problem 3: Token Conflict

**症状 / Symptom**: Multiple devices using same token, binding fails
多台设备使用相同 token，导致绑定失败

**解决方案 / Solution**:

```bash
# Generate unique token for each device / 为每个设备生成唯一 token
TOKEN=$(uuidgen | tr -d '-')
sed -i "s/\"token\": \".*\"/\"token\": \"$TOKEN\"/" /etc/glinet/gl-cloud.conf

# Restart service / 重启服务
/etc/init.d/S99gl-cloud restart
```

### 问题 4: 恢复原始配置 / Problem 4: Restore Original Configuration

**完全卸载 / Complete Uninstallation**:

```bash
# 1. Restore original KVMD script / 恢复原始 KVMD 脚本
cp /usr/bin/kvmd.bak /usr/bin/kvmd

# 2. Remove user configuration / 删除用户配置
rm -rf /etc/kvmd/user

# 3. Restart services / 重启服务
/etc/init.d/kvmd restart
/etc/init.d/S99gl-cloud restart

# 4. Verify restoration / 验证恢复
ps aux | grep kvmd
curl -s http://localhost/api/turn/get_turn | jq
```

---

## 🔬 技术细节 / Technical Details

### 文件清单 / File List

| 文件路径 / File Path | 说明 / Description | 是否必需 / Required |
|---------|------|---------|
| `/usr/bin/kvmd` | KVMD startup script (modified) / KVMD 启动脚本（已修改） | 必需 / Required |
| `/usr/bin/kvmd.bak` | Original KVMD script backup / 原始 KVMD 脚本备份 | 必需（恢复用）/ Required (for recovery) |
| `/etc/kvmd/user/country_code` | User country code config / 用户国家码配置 | 必需 / Required |
| `/etc/glinet/gl-cloud.conf` | Cloud service config / 云服务配置 | 必需 / Required |
| `/proc/gl-hw-info/country_code` | Kernel country code (read-only) / 内核国家码（只读） | 系统文件 / System file |
| `/proc/gl-hw-info/device_mac` | Device MAC address / 设备 MAC 地址 | 系统文件 / System file |
| `/proc/gl-hw-info/device_sn` | Device serial number / 设备序列号 | 系统文件 / System file |

### 配置文件格式 / Configuration File Format

#### `/etc/kvmd/user/country_code`

```
CN
```

or / 或

```
US
```

**说明 / Note**: Plain text file containing only country code, no quotes, no spaces
纯文本文件，只包含国家码，无引号，无空格

#### `/etc/glinet/gl-cloud.conf`

```json
{
  "enable": true,
  "server": "gslb.gl-inet.cn",
  "token": "aa34bdb91ad5479d869d9976a92ded09"
}
```

**字段说明 / Field Description**:
- `enable`: Enable cloud service / 是否启用云服务 (true/false)
- `server`: GSLB server domain / GSLB 服务器域名
- `token`: Device unique identifier / 设备唯一标识符（32位十六进制字符串 / 32-char hex string）

---

## 📖 参考资料 / References

### 相关文档 / Related Documentation

- [01_architecture_overview.md](../../analysis/01_architecture_overview.md) - RM1 架构全面分析 / RM1 Architecture Analysis
- [06_glkvm_source_analysis.md](../../analysis/06_glkvm_source_analysis.md) - GLKVM 源码深度分析 / GLKVM Source Code Analysis
- [07_country_code_override.md](../../analysis/07_country_code_override.md) - 国家码覆盖详细分析 / Country Code Override Detailed Analysis

### GLKVM 源码 / GLKVM Source Code

- **KVMD Main Program**: `/ai/pikvm-glinet/glkvm-main/kvmd/apps/kvmd/`
- **TURN API**: `/ai/pikvm-glinet/glkvm-main/kvmd/apps/kvmd/api/turn.py`
- **Astrowarp API**: `/ai/pikvm-glinet/glkvm-main/kvmd/apps/kvmd/api/astrowarp.py`
- **Janus WebRTC**: `/ai/pikvm-glinet/glkvm-main/kvmd/apps/janus/`

### 外部资源 / External Resources

- [PiKVM 官网 / PiKVM Website](https://pikvm.org/)
- [PiKVM GitHub](https://github.com/pikvm/pikvm)
- [GL.iNet 官网 / GL.iNet Website](https://www.gl-inet.com/)
- [GLKVM GitHub](https://github.com/gl-inet/glkvm)
- [STUN 协议 RFC 5389 / STUN Protocol RFC 5389](https://tools.ietf.org/html/rfc5389)
- [TURN 协议 RFC 5766 / TURN Protocol RFC 5766](https://tools.ietf.org/html/rfc5766)

---

## 🤝 贡献 / Contributing

Contributions are welcome! Welcome to submit Issues and Pull Requests!
欢迎贡献！欢迎提交 Issue 和 Pull Request！

### 如何贡献 / How to Contribute

1. Fork this repository / Fork 本仓库
2. Create feature branch / 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. Commit changes / 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch / 推送到分支 (`git push origin feature/AmazingFeature`)
5. Open Pull Request / 开启 Pull Request

### 报告问题 / Reporting Issues

When submitting issues, please provide / 提交 Issue 时，请提供：

1. Device model and firmware version / 设备型号和固件版本
2. Detailed error description / 详细的错误描述
3. Steps to reproduce / 复现步骤
4. Related logs (remove sensitive info like token) / 相关日志（移除敏感信息如 token）
5. Configuration file content (remove sensitive info) / 配置文件内容（移除敏感信息）

---

## 📄 许可证 / License

This project is based on analysis of GLKVM and PiKVM, licensed under **GPL v3 License**.
本项目基于对 GLKVM 和 PiKVM 的研究分析，遵循 **GPL v3 许可证**。

- GLKVM follows GPL v3 License / GLKVM 遵循 GPL v3 许可证
- PiKVM follows GPL v3 License / PiKVM 遵循 GPL v3 许可证
- This tool also follows GPL v3 License / 本工具同样遵循 GPL v3 许可证

See [LICENSE](../LICENSE) file for details.
详见 [LICENSE](../LICENSE) 文件。

### 免责声明 / Disclaimer

⚠️ **使用本工具的风险由用户自行承担 / Use this tool at your own risk**：
- Modifying system configuration may cause device malfunction / 修改系统配置可能导致设备无法正常工作
- Cloud service binding may violate GL.iNet's terms of service / 云服务绑定可能违反 GL.iNet 的服务条款
- Please comply with relevant laws and regulations / 请遵守相关法律法规
- Authors are not responsible for any losses / 作者不对任何损失负责

---

## 📮 联系方式 / Contact

- **Issues**: [GitHub Issues](https://github.com/yusui-shun/glinet-change-country-code/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yusui-shun/glinet-change-country-code/discussions)

---

## ⭐ Star History

If this tool helps you, please give it a Star ⭐
如果这个工具对你有帮助，请给个 Star ⭐

[![Star History Chart](https://api.star-history.com/svg?repos=yusui-shun/glinet-change-country-code&type=Date)](https://star-history.com/#yusui-shun/glinet-change-country-code&Date)

---

## 🙏 致谢 / Acknowledgments

- **PiKVM Project** - Thanks to the PiKVM team for the excellent KVM over IP solution / 感谢 PiKVM 团队开发的优秀 KVM over IP 解决方案
- **GL.iNet** - Thanks to GL.iNet for providing hardware devices and open source GLKVM project / 感谢 GL.iNet 提供的硬件设备和开源 GLKVM 项目
- **Rockchip** - Thanks to Rockchip for RK1126 SoC and technical support / 感谢 Rockchip 提供的 RK1126 SoC 和技术支持
- **Open Source Community** - Thanks to all contributors and users for feedback / 感谢所有贡献者和用户的反馈

---

**祝使用愉快！** 🎉 / **Enjoy using it!** 🎉

If you have questions or suggestions, please submit an Issue or Pull Request.
如有问题或建议，欢迎提交 Issue 或 Pull Request。

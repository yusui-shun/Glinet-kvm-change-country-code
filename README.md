# GL.iNet 国家码覆盖工具

> [中文](#中文文档) | [English](#english)

---

## <a name="中文文档"></a>中文文档

### 项目简介

本项目提供了针对 GL.iNet GLKVM 设备的国家码覆盖工具，允许在用户空间修改设备的国家码配置，实现中国/国际服务器的切换。

### 主要功能

- ✅ 一键切换中国/国际云服务器
- ✅ STUN 服务器自动切换
- ✅ 自动生成唯一设备 token
- ✅ 完全用户空间实现，无需修改内核
- ✅ 可随时恢复原始配置

### 适用设备

- GL.iNet RM1
- GL.iNet RM10
- 其他基于 GLKVM 的设备

### 快速开始

#### 系统要求

- GL.iNet GLKVM 设备
- Root 权限
- Python 3.x（系统自带）

#### 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/yusui-shun/glinet-change-country-code/main/country-code/install.sh | bash
```

#### 配置使用

```bash
# 切换到中国服务器
setup-country-code.sh CN

# 切换到国际服务器
setup-country-code.sh US
```

### 完整文档

详细使用说明请查看：[country-code/README.md](country-code/README.md)

**注意**: 请将示例中的 IP 地址替换为你设备的实际 IP 地址。

### 许可证

本项目遵循 **GPL v3 许可证**。详见 [LICENSE](LICENSE) 文件。

⚠️ **免责声明**：使用本工具的风险由用户自行承担。

### 反馈与支持

- **Issues**: [提交问题](https://github.com/yusui-shun/glinet-change-country-code/issues)
- **Discussions**: [加入讨论](https://github.com/yusui-shun/glinet-change-country-code/discussions)

---

## <a name="english"></a>English Documentation

### Introduction

This tool provides country code override functionality for GL.iNet GLKVM devices, allowing you to switch between Chinese and International cloud servers without recompiling the firmware.

### Features

- ✅ One-click switch between CN/International cloud servers
- ✅ Automatic STUN server switching
- ✅ Auto-generate unique device tokens
- ✅ Pure user-space implementation, no kernel modification
- ✅ Fully reversible

### Supported Devices

- GL.iNet RM1
- GL.iNet RM10
- Other GLKVM-based devices

### Quick Start

#### Requirements

- GL.iNet GLKVM device
- Root permissions
- Python 3.x (included in system)

#### One-line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/yusui-shun/glinet-change-country-code/main/country-code/install.sh | bash
```

#### Configuration

```bash
# Switch to Chinese server
setup-country-code.sh CN

# Switch to International server
setup-country-code.sh US
```

### Full Documentation

For detailed usage instructions, see: [country-code/README.md](country-code/README.md)

**Note**: Please replace the example IP address with your device's actual IP address.

### License

This project is licensed under **GPL v3 License**. See [LICENSE](LICENSE) file for details.

⚠️ **Disclaimer**: Use this tool at your own risk.

### Feedback & Support

- **Issues**: [Submit Issue](https://github.com/yusui-shun/glinet-change-country-code/issues)
- **Discussions**: [Join Discussion](https://github.com/yusui-shun/glinet-change-country-code/discussions)

---

## 🙏 致谢 / Acknowledgments

- **PiKVM Project** - Excellent KVM over IP solution
- **GL.iNet** - Hardware devices and open source GLKVM project
- **Rockchip** - RK1126 SoC and technical support

---

**如果这个工具对你有帮助，请给个 Star ⭐ / If this tool helps you, please give it a Star ⭐**

# GL.iNet RM1 工具集

> 为 GL.iNet RM1 KVM over IP 设备提供的实用工具集合

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform](https://img.shields.io/badge/platform-GL.iNet%20RM1-orange.svg)](https://www.gl-inet.com/products/gl-kvm)

---

## 📚 目录

- [项目简介](#项目简介)
- [工具列表](#工具列表)
- [快速开始](#快速开始)
- [系统要求](#系统要求)
- [贡献指南](#贡献指南)
- [许可证](#许可证)
- [免责声明](#免责声明)

---

## 🎯 项目简介

本项目提供了一系列针对 GL.iNet RM1 设备的实用工具，基于对 GLKVM 源码的深度分析开发。GLKVM 是 GL.iNet 基于 PiKVM 开源项目定制的 KVM over IP 解决方案。

### 项目背景

GL.iNet RM1 是一款基于 Rockchip RK1126 SoC 的 KVM over IP 设备，允许通过网络远程控制计算机。通过深入分析 GLKVM 源码，我们发现了一些可以优化的地方，并开发了相应的工具。

### 技术架构

```
GLKVM = PiKVM (95%) + GL.iNet 定制 (5%)

核心组件:
├── KVMD (Python) - KVM 守护进程
├── Web 界面 - 基于 PiKVM
├── Janus WebRTC - 流媒体服务
└── GL.iNet 定制
    ├── Rockchip gadget 适配
    ├── Pico HID 桥接
    ├── glatx.py ATX 插件
    └── 设备型号支持 (rm1/rm10)
```

---

## 🛠️ 工具列表

### 1. 国家码覆盖工具 ⭐

**目录**: [country-code/](country-code/)

**功能**:
- 在用户空间覆盖设备国家码配置
- 无需修改内核或重新编译固件
- 支持中国/国际服务器切换
- 自动生成唯一设备 token

**主要特性**:
- ✅ 切换 STUN 服务器（中国/国际）
- ✅ 切换云服务绑定域名
- ✅ 生成动态绑定码
- ✅ Python Monkey Patching 技术
- ✅ 完全可逆，不破坏原系统

**使用场景**:
- 国内用户使用国内云服务，获得更快连接速度
- 开发者测试不同地区云服务功能
- 隐私保护，选择特定地区服务器

**快速安装**:
```bash
cd country-code
chmod +x install.sh
sudo ./install.sh
```

**详细文档**: [country-code/README.md](country-code/README.md)

---

## 🚀 快速开始

### 系统要求

- **设备**: GL.iNet RM1 (或基于 RK1126 的 GLKVM 设备)
- **权限**: Root 访问权限
- **网络**: 互联网连接
- **Python**: Python 3.x (系统自带)

### 安装步骤

#### 方法 1: 使用安装脚本（推荐）

```bash
# 1. 克隆仓库
git clone https://github.com/your-username/rm1-tools.git
cd rm1-tools

# 2. 进入工具目录
cd country-code

# 3. 运行安装脚本
chmod +x install.sh
sudo ./install.sh
```

#### 方法 2: 手动安装

```bash
# 1. 备份原始文件
sudo cp /usr/bin/kvmd /usr/bin/kvmd.bak

# 2. 创建配置目录
sudo mkdir -p /etc/kvmd/user

# 3. 复制覆盖脚本
sudo cp country-code/override-kvmd.py /usr/bin/kvmd
sudo chmod +x /usr/bin/kvmd

# 4. 配置国家码
sudo ./setup-country-code.sh CN
```

### 基本使用

```bash
# 切换到中国服务器
sudo setup-country-code.sh CN

# 切换到国际服务器
sudo setup-country-code.sh US

# 查看当前配置
cat /etc/kvmd/user/country_code
cat /etc/glinet/gl-cloud.conf

# 重启 KVMD 服务
sudo /etc/init.d/kvmd restart
```

### 卸载

```bash
# 使用卸载脚本
cd country-code
chmod +x uninstall.sh
sudo ./uninstall.sh

# 或手动恢复
sudo cp /usr/bin/kvmd.bak /usr/bin/kvmd
sudo rm -rf /etc/kvmd/user
sudo /etc/init.d/kvmd restart
```

---

## 📖 完整文档

### 分析文档

在 [analysis/](../analysis/) 目录下，有完整的 GL.iNet RM1 固件分析文档：

1. [01_architecture_overview.md](../analysis/01_architecture_overview.md) - 架构全面分析
2. [02_kernel_adaptation.md](../analysis/02_kernel_adaptation.md) - Kernel 适配分析
3. [03_glinet_modifications.md](../analysis/03_glinet_modifications.md) - GL.iNet 关键修改
4. [04_build_and_flash.md](../analysis/04_build_and_flash.md) - 构建和烧录流程
5. [05_comparison_and_references.md](../analysis/05_comparison_and_references.md) - 对比和参考资料
6. [06_glkvm_source_analysis.md](../analysis/06_glkvm_source_analysis.md) - GLKVM 源码深度分析 ⭐
7. [07_country_code_override.md](../analysis/07_country_code_override.md) - 国家码覆盖详细分析

### 工具文档

- [国家码覆盖工具完整文档](country-code/README.md)
  - 工作原理
  - 安装步骤
  - 使用方法
  - 故障排查
  - 技术细节

---

## 🤝 贡献指南

欢迎贡献代码、报告问题或提出建议！

### 如何贡献

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 报告问题

提交 Issue 时请提供：

1. 设备型号和固件版本
2. 详细的错误描述
3. 复现步骤
4. 相关日志（移除敏感信息如 token）
5. 配置文件内容（移除敏感信息）

### 代码规范

- 遵循 GPL v3 许可证
- 添加适当的注释和文档
- 测试您的更改
- 不要包含敏感信息（token、密码等）

---

## 🔗 相关资源

### 官方资源

- [PiKVM 官网](https://pikvm.org/)
- [PiKVM GitHub](https://github.com/pikvm/pikvm)
- [GL.iNet 官网](https://www.gl-inet.com/)
- [GLKVM GitHub](https://github.com/gl-inet/glkvm)

### 技术文档

- [STUN 协议 RFC 5389](https://tools.ietf.org/html/rfc5389)
- [TURN 协议 RFC 5766](https://tools.ietf.org/html/rfc5766)
- [WebRTC 协议](https://webrtc.org/)
- [Buildroot 文档](https://buildroot.org/docs.html)

### 学习资源

- [RK1126 数据手册](../RV1126%20Brief%20Datasheet.pdf)
- [Rockchip 开发者资源](https://www.rockchip.com/)
- [Python Monkey Patching](https://en.wikipedia.org/wiki/Monkey_patch)

---

## 📄 许可证

本项目基于对 GLKVM 和 PiKVM 的研究分析，遵循 **GPL v3 许可证**。

- GLKVM 遵循 GPL v3 许可证
- PiKVM 遵循 GPL v3 许可证
- 本工具同样遵循 GPL v3 许可证

详见 [LICENSE](LICENSE) 文件。

---

## ⚠️ 免责声明

⚠️ **重要提示**：

1. **使用风险**: 使用本工具的风险由用户自行承担。修改系统配置可能导致设备无法正常工作。

2. **不保证**: 本工具按"原样"提供，不提供任何明示或暗示的保证。

3. **服务条款**: 云服务绑定可能违反 GL.iNet 的服务条款，请自行判断使用。

4. **法律责任**: 请遵守相关法律法规。作者不对任何损失或法律责任负责。

5. **备份**: 使用前请务必备份重要数据和配置文件。

6. **测试**: 建议先在测试环境中验证，再在生产环境使用。

---

## 📮 联系方式

- **Issues**: [GitHub Issues](https://github.com/your-username/rm1-tools/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/rm1-tools/discussions)
- **Pull Requests**: [GitHub PRs](https://github.com/your-username/rm1-tools/pulls)

---

## ⭐ Star History

如果这个项目对你有帮助，请给个 Star ⭐

[![Star History Chart](https://api.star-history.com/svg?repos=your-username/rm1-tools&type=Date)](https://star-history.com/#your-username/rm1-tools&Date)

---

## 🙏 致谢

- **PiKVM 项目** - 感谢 PiKVM 团队开发的优秀 KVM over IP 解决方案
- **GL.iNet** - 感谢 GL.iNet 提供的硬件设备和开源 GLKVM 项目
- **Rockchip** - 感谢 Rockchip 提供的 RK1126 SoC 和技术支持
- **开源社区** - 感谢所有贡献者和用户的反馈

---

**祝使用愉快！** 🎉

如有问题或建议，欢迎提交 Issue 或 Pull Request。

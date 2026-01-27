# Android 15 UTM Build Suite for iPad Pro M1

> 一套完整的 Android 15 编译、优化和部署解决方案，专为 iPad Pro M1 上的 UTM 虚拟机设计

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-iPad%20Pro%20M1-brightgreen.svg)
![Android Version](https://img.shields.io/badge/Android-15-green.svg)
![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)

## ⚠️ 重要更新 (v1.2.0 - 2026-01-27)

**🔴 如果您遇到编译错误，请立即查看：**

- ⚡ **[快速修复指南](QUICKFIX.md)** - 1 分钟解决问题
- 🔧 **[完整修复说明](CRITICAL_FIX_GUIDE.md)** - 详细技术文档

**核心修复内容：**

| 问题 | 修复 |
|------|------|
| ✅ `virtio_arm64` 设备配置错误 | 使用 `breakfast` 命令 |
| ✅ `lunch` 命令格式错误 | 移除 `ap3a` release 标识符 |
| ✅ 编译命令错误 | 使用 `m lineage-install` |
| ✅ 产物验证失败 | 检查 `lineage-*.img` 文件 |

**快速修复命令：**

```bash
cd ~/android15-utm-ipad-builder
git pull
bash scripts/03-build-android.sh
```

---

## 📋 项目概述

本项目提供了一套完整的工具链和文档，用于在 **Debian 12** 虚拟机环境中编译 **Android 15/LineageOS 23.0**，并将其部署到 **iPad Pro M1** 上的 **UTM 虚拟机**中。

### 核心特性

- ✅ 完整的编译环境配置指南
- ✅ 自动化编译和优化脚本
- ✅ 3D 加速和图形驱动配置
- ✅ 虚拟机存储空间优化
- ✅ 详细的部署和导入步骤
- ✅ 故障排查和性能测试工具
- ✅ 开发日志和思维逻辑文档

## 🚀 快速开始

### 前置要求

- **主机**: iPad Pro M1（运行 iPadOS 16.0+）
- **虚拟机**: UTM 4.7.5+ 版本
- **编译环境**: Debian 12 x86_64（在 UTM 中运行）
- **存储空间**: 至少 300GB（编译所需）
- **内存**: 至少 16GB（推荐 32GB）

### 一键式自动化编译

```bash
# 1. 克隆仓库
git clone https://github.com/umut0301/android15-utm-ipad-builder.git
cd android15-utm-ipad-builder

# 2. 一键运行（完全自动化）
sudo bash scripts/00-auto-build-all.sh
```

**就这么简单！** 脚本会自动完成从环境准备到编译完成的所有步骤。

### 分步执行（可选）

```bash
# 步骤 1: 环境准备
sudo bash scripts/01-setup-build-env.sh

# 步骤 2: 源代码同步
bash scripts/02-sync-source.sh

# 步骤 3: 编译
bash scripts/03-build-android.sh

# 步骤 4: 优化
bash scripts/04-optimize-output.sh

# 步骤 5: 传输
bash scripts/05-transfer-to-ipad.sh
```

## 📁 项目结构

```
android15-utm-build/
├── README.md                          # 项目主文档
├── DEVELOPMENT_LOG.md                 # 开发日志
├── ARCHITECTURE.md                    # 架构和思维逻辑
├── docs/                              # 详细文档
│   ├── QUICKSTART.md                 # 快速开始指南
│   ├── SETUP_GUIDE.md                # 详细设置指南
│   ├── BUILD_GUIDE.md                # 编译指南
│   ├── OPTIMIZATION_GUIDE.md         # 优化指南
│   ├── IMPORT_GUIDE.md               # 导入指南
│   ├── TROUBLESHOOTING.md            # 故障排查
│   └── FAQ.md                        # 常见问题
├── scripts/                           # 自动化脚本
│   ├── 01-setup-build-env.sh        # 环境设置
│   ├── 02-build-android.sh          # 编译脚本
│   ├── 03-optimize-output.sh        # 产物优化
│   ├── 04-transfer-to-ipad.sh       # 文件传输
│   ├── 05-manage-storage.sh         # 存储管理
│   ├── 06-benchmark-vm.sh           # 性能测试
│   └── utils/                        # 工具函数库
│       └── common.sh                # 通用函数
├── configs/                           # 配置文件
│   ├── build.config                 # 编译配置
│   ├── utm-vm-config.json           # UTM 虚拟机配置
│   └── device-config.mk             # 设备配置
├── examples/                          # 示例和模板
│   ├── build-config-example.sh      # 编译配置示例
│   ├── utm-setup-example.md         # UTM 设置示例
│   └── custom-device-example.md     # 自定义设备示例
├── logs/                              # 编译日志存储
│   └── .gitkeep
└── .github/                           # GitHub 配置
    └── workflows/                    # CI/CD 工作流（可选）
```

## 📖 文档导航

| 文档 | 说明 |
|------|------|
| [QUICKSTART.md](docs/QUICKSTART.md) | 5 分钟快速开始指南 |
| [SETUP_GUIDE.md](docs/SETUP_GUIDE.md) | 详细的环境配置步骤 |
| [BUILD_GUIDE.md](docs/BUILD_GUIDE.md) | 完整的编译流程 |
| [OPTIMIZATION_GUIDE.md](docs/OPTIMIZATION_GUIDE.md) | 3D 加速和存储优化 |
| [IMPORT_GUIDE.md](docs/IMPORT_GUIDE.md) | 虚拟机导入和配置 |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | 故障排查和解决方案 |
| [FAQ.md](docs/FAQ.md) | 常见问题解答 |
| [SCRIPTS_USAGE.md](docs/SCRIPTS_USAGE.md) | 自动化脚本使用指南 |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 系统架构和思维逻辑 |
| [DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md) | 开发日志和研究记录 |

## 🛠️ 自动化脚本

| 脚本 | 功能 | 预计时间 | 需要 sudo |
|------|------|---------|----------|
| `00-auto-build-all.sh` | 一键式全自动编译 | 4-15 小时 | ✓ |
| `01-setup-build-env.sh` | 环境准备和依赖安装 | 10-20 分钟 | ✓ |
| `02-sync-source.sh` | 同步 LineageOS 源代码 | 2-8 小时 | ✗ |
| `03-build-android.sh` | 编译 Android 15 | 1-6 小时 | ✗ |
| `04-optimize-output.sh` | 优化编译产物 | 10-20 分钟 | ✗ |
| `05-transfer-to-ipad.sh` | 传输文件到 iPad | 按需 | ✗ |

详细使用方法请参考 [**脚本使用指南**](docs/SCRIPTS_USAGE.md)。

## 🎯 核心工作流程

```
┌─────────────────────────────────────────────────────────┐
│ 1. 环境准备                                              │
│    └─ 安装依赖 → 配置工具 → 初始化目录                   │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 2. 源代码获取                                            │
│    └─ 初始化 repo → 同步源代码 → 验证完整性              │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 3. 编译构建                                              │
│    └─ 选择目标 → 配置环境 → 执行编译 → 生成镜像          │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 4. 产物优化                                              │
│    └─ 清理中间文件 → 压缩镜像 → 验证完整性              │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 5. 文件传输                                              │
│    └─ 生成校验和 → 传输到 iPad → 解压文件               │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 6. UTM 导入配置                                          │
│    └─ 导入虚拟机 → 配置资源 → 设置图形 → 启动虚拟机     │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 7. 系统运行                                              │
│    └─ 完成初始化 → 测试功能 → 性能调优                  │
└─────────────────────────────────────────────────────────┘
```

## 📊 关键配置参数

### Debian 12 虚拟机配置（编译环境）

| 参数 | 推荐值 | 说明 |
|------|--------|------|
| CPU 核心 | 8 | 编译速度关键 |
| 内存 | 16-32GB | 越多越快 |
| 存储 | 300GB+ | SSD 推荐 |
| 网络 | 稳定连接 | 源代码下载 |

### iPad Pro M1 上的 UTM 虚拟机配置

| 参数 | 推荐值 | 说明 |
|------|--------|------|
| CPU 核心 | 6-8 | 平衡性能 |
| 内存 | 4-6GB | iPad 总内存 8GB |
| 系统磁盘 | 30-50GB | qcow2 格式 |
| 显示设备 | virtio-gpu-gl-pci | GPU 加速 |
| 渲染器 | ANGLE (Metal) | 最优性能 |

## 🔧 3D 加速配置

### 最优配置（iPad Pro M1）

```
显示设备: virtio-gpu-gl-pci (GPU Supported)
渲染器: ANGLE (Metal)
VGA RAM: 16-32MB
Retina 模式: 禁用
虚拟化: 启用
```

### 备选配置（如遇问题）

```
显示设备: virtio-gpu-pci (无 GL)
渲染器: ANGLE (OpenGL)
虚拟化: 禁用
```

## 💾 存储优化技巧

### 编译时优化

```bash
# 选择 user 版本（更小）
lunch virtio_arm64-user

# 启用编译缓存
export USE_CACHE=1
export CCACHE_EXEC=/usr/bin/ccache
ccache -M 50G
```

### 产物优化

```bash
# 清理中间文件
make clean

# 压缩镜像
qemu-img convert -O qcow2 -c system.img system-compressed.img
```

## 📱 导入流程

### 简化版本

1. 编译完成后获得 `VirtuaMachine-utm-*.zip`
2. 传输到 iPad 并解压
3. 在 UTM 中选择"浏览"导入 `.utm` 文件夹
4. 配置资源和图形设置
5. 启动虚拟机

### 详细步骤

请参考 [IMPORT_GUIDE.md](docs/IMPORT_GUIDE.md)

## 🐛 故障排查

### 常见问题

| 问题 | 解决方案 |
|------|--------|
| 虚拟机无法启动 | 禁用虚拟化模式，降低资源分配 |
| 图形显示异常 | 更换渲染器（Metal → OpenGL → 软件） |
| 内存泄漏崩溃 | 更新 UTM 到 4.7.5+，禁用 GPU 加速 |
| 存储空间不足 | 扩展虚拟磁盘，清理缓存 |
| 编译失败 | 检查依赖，查看编译日志 |

详见 [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## 📈 性能预期

### 编译时间

| 硬件配置 | 首次编译 | 增量编译 |
|--------|--------|--------|
| 4 核 8GB RAM | 6-8h | 30-60m |
| 8 核 16GB RAM | 2-4h | 15-30m |
| 16 核 32GB RAM | 1-2h | 5-15m |

### 虚拟机性能

| 操作 | 预期时间 |
|------|--------|
| 启动 | 30-60s |
| 应用启动 | 2-5s |
| 系统响应 | 流畅 |

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📝 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 🔗 相关资源

- [LineageOS Wiki - UTM on Apple Silicon](https://wiki.lineageos.org/utm-vm-on-apple-silicon-mac)
- [UTM 官方文档](https://docs.getutm.app/)
- [AOSP 编译指南](https://source.android.com/docs/setup/build/building)
- [Android 15 发布说明](https://developer.android.com/about/versions/15)

## 📧 联系方式

- 提交 Issue: [GitHub Issues](https://github.com/yourusername/android15-utm-build/issues)
- 讨论: [GitHub Discussions](https://github.com/yourusername/android15-utm-build/discussions)

## 🙏 致谢

感谢以下项目和社区的支持：

- LineageOS 项目
- UTM 虚拟机项目
- AOSP 项目
- 所有贡献者和用户

---

**最后更新**: 2026 年 1 月 27 日  
**项目版本**: 1.0.0  
**维护者**: Manus AI

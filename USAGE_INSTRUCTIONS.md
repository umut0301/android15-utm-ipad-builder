# 使用说明 - Android 15 UTM iPad Builder

## 🎉 恭喜！仓库已成功创建

您的 GitHub 仓库已经创建完成并上传了所有文档和指南。

## 📦 仓库信息

- **仓库名称**: `android15-utm-ipad-builder`
- **仓库地址**: https://github.com/umut0301/android15-utm-ipad-builder
- **可见性**: 私有仓库
- **创建时间**: 2026年1月27日

## 🚀 如何开始使用

### 方法 1: 在 Debian 12 虚拟机中克隆

```bash
# 克隆仓库
git clone https://github.com/umut0301/android15-utm-ipad-builder.git
cd android15-utm-ipad-builder

# 查看快速开始指南
cat docs/QUICKSTART.md

# 开始编译工作
bash scripts/01-setup-build-env.sh
```

### 方法 2: 直接使用 GitHub 链接

您可以直接在浏览器中访问：
https://github.com/umut0301/android15-utm-ipad-builder

然后查看所有文档和指南。

## 📚 核心文档导航

### 新手入门

1. **[QUICKSTART.md](docs/QUICKSTART.md)** - 5分钟快速开始
   - 最小化步骤
   - 一键脚本
   - 快速验证

2. **[BUILD_GUIDE.md](docs/BUILD_GUIDE.md)** - 完整编译指南
   - 详细的编译步骤
   - 环境配置说明
   - 参数详解

### 优化和调优

3. **[OPTIMIZATION_GUIDE.md](docs/OPTIMIZATION_GUIDE.md)** - 优化调优指南
   - 3D 加速配置
   - 存储空间优化
   - 虚拟机性能调优
   - 导入和配置步骤

4. **[QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)** - 快速参考手册
   - 常用命令速查
   - 一键安装脚本
   - 性能优化技巧

### 脚本和工具

5. **[SCRIPTS_GUIDE.md](docs/SCRIPTS_GUIDE.md)** - 脚本使用指南
   - 自动化脚本说明
   - 实操命令集合
   - 工具函数库

### 问题解决

6. **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - 故障排查指南
   - 常见问题诊断
   - 解决方案步骤
   - 诊断工具使用

7. **[FAQ.md](docs/FAQ.md)** - 常见问题解答
   - 快速答案
   - 参考链接
   - 最佳实践

### 深入理解

8. **[ARCHITECTURE.md](ARCHITECTURE.md)** - 系统架构和思维逻辑
   - 整体架构设计
   - 核心思维逻辑
   - 技术决策树
   - 工作流程详解

9. **[DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md)** - 开发日志
   - 完整的研究过程
   - 技术发现记录
   - 决策过程说明
   - 未来改进方向

## 🔧 完整工作流程

```
┌─────────────────────────────────────────────────────────┐
│ 第 1 步: 克隆仓库                                         │
│ git clone https://github.com/umut0301/android15-utm-ipad-builder.git │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 第 2 步: 环境准备 (Debian 12)                            │
│ bash scripts/01-setup-build-env.sh                       │
│ 预期时间: 10-20 分钟                                     │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 第 3 步: 同步源代码                                       │
│ cd ~/android/lineage                                     │
│ repo init -u https://github.com/LineageOS/android.git   │
│   -b lineage-23.0 --git-lfs --no-clone-bundle          │
│ repo sync -j4                                            │
│ 预期时间: 2-8 小时                                       │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 第 4 步: 编译 Android 15                                 │
│ bash scripts/02-build-android.sh                         │
│ 预期时间: 1-6 小时                                       │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 第 5 步: 优化产物                                         │
│ bash scripts/03-optimize-output.sh                       │
│ 预期时间: 10-20 分钟                                     │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 第 6 步: 传输到 iPad                                     │
│ bash scripts/04-transfer-to-ipad.sh                      │
│ 预期时间: 10-30 分钟                                     │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 第 7 步: 在 UTM 中导入                                   │
│ 参考: docs/OPTIMIZATION_GUIDE.md                         │
│ 预期时间: 5-10 分钟                                      │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│ 第 8 步: 启动虚拟机                                       │
│ 享受 Android 15！                                        │
└─────────────────────────────────────────────────────────┘
```

## 💡 关键提示

### 编译环境要求

- **操作系统**: Debian 12 x86_64
- **CPU**: 8+ 核（推荐）
- **内存**: 16-32GB（推荐）
- **存储**: 300GB+ SSD（必须）
- **网络**: 稳定的互联网连接

### iPad Pro M1 虚拟机配置

- **CPU**: 6-8 核
- **内存**: 4-6GB
- **系统磁盘**: 30-50GB
- **显示设备**: `virtio-gpu-gl-pci (GPU Supported)`
- **渲染器**: `ANGLE (Metal)`
- **Retina 模式**: 禁用

### 性能预期

| 操作 | 预期时间/性能 |
|------|--------------|
| 源代码同步 | 2-8 小时 |
| 首次编译 | 2-4 小时 (8核16GB) |
| 增量编译 | 15-30 分钟 (使用 ccache) |
| 虚拟机启动 | 30-60 秒 |
| 应用启动 | 2-5 秒 |
| 系统响应 | 流畅 |

## 📋 检查清单

### 开始编译前

- [ ] 已克隆仓库
- [ ] 已阅读 QUICKSTART.md
- [ ] 已准备 Debian 12 环境
- [ ] 已检查硬件配置
- [ ] 已检查网络连接
- [ ] 已检查存储空间

### 编译完成后

- [ ] 已生成 VirtuaMachine-utm-*.zip
- [ ] 已验证文件完整性
- [ ] 已运行优化脚本
- [ ] 已传输到 iPad
- [ ] 已解压文件

### 虚拟机导入后

- [ ] 已配置 CPU 和内存
- [ ] 已配置显示设备
- [ ] 已配置渲染器
- [ ] 已禁用 Retina 模式
- [ ] 已测试启动

## 🔗 重要链接

| 资源 | 链接 |
|------|------|
| GitHub 仓库 | https://github.com/umut0301/android15-utm-ipad-builder |
| 快速开始 | [docs/QUICKSTART.md](docs/QUICKSTART.md) |
| 编译指南 | [docs/BUILD_GUIDE.md](docs/BUILD_GUIDE.md) |
| 优化指南 | [docs/OPTIMIZATION_GUIDE.md](docs/OPTIMIZATION_GUIDE.md) |
| 故障排查 | [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |
| FAQ | [docs/FAQ.md](docs/FAQ.md) |
| 系统架构 | [ARCHITECTURE.md](ARCHITECTURE.md) |
| 开发日志 | [DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md) |

## 🆘 获取帮助

如果您在使用过程中遇到问题：

1. **查看文档**
   - 首先查看 [FAQ.md](docs/FAQ.md)
   - 然后查看 [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

2. **提交 Issue**
   - 访问 https://github.com/umut0301/android15-utm-ipad-builder/issues
   - 描述问题和环境
   - 附加日志和截图

3. **讨论**
   - 访问 https://github.com/umut0301/android15-utm-ipad-builder/discussions
   - 与社区交流

## 🎯 下一步

现在您可以：

1. **立即开始编译**
   ```bash
   git clone https://github.com/umut0301/android15-utm-ipad-builder.git
   cd android15-utm-ipad-builder
   bash scripts/01-setup-build-env.sh
   ```

2. **深入学习**
   - 阅读 [ARCHITECTURE.md](ARCHITECTURE.md) 了解系统架构
   - 阅读 [DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md) 了解研究过程

3. **自定义配置**
   - 根据您的需求调整配置
   - 参考 [OPTIMIZATION_GUIDE.md](docs/OPTIMIZATION_GUIDE.md)

## 📊 项目统计

- **文档数量**: 13 个
- **总字数**: 约 60,000 字
- **代码行数**: 约 6,000 行
- **覆盖主题**: 编译、优化、部署、故障排查
- **支持平台**: Debian 12 + iPad Pro M1

## 🙏 致谢

感谢您使用本项目！如果您觉得有帮助，请给仓库一个 ⭐ Star！

---

**祝您编译顺利！享受 Android 15！** 🎉

**最后更新**: 2026年1月27日  
**项目版本**: 1.0.0  
**维护者**: umut0301

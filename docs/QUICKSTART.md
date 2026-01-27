# 快速开始指南 - 5 分钟入门

> 如果您只有 5 分钟，这就是您需要的全部内容

## 前置要求

- ✅ iPad Pro M1（运行 iPadOS 16.0+）
- ✅ UTM 4.7.5+ 版本
- ✅ Debian 12 虚拟机（在 UTM 中运行）
- ✅ 至少 300GB 存储空间
- ✅ 至少 16GB 内存

## 一键开始

### 步骤 1: 克隆仓库

```bash
git clone https://github.com/yourusername/android15-utm-build.git
cd android15-utm-build
```

### 步骤 2: 运行初始化脚本

```bash
# 安装所有依赖（需要 sudo 权限）
bash scripts/01-setup-build-env.sh
```

**预期输出**：
```
========================================
Android 15 编译环境安装 - Debian 12
========================================
[1/5] 更新系统包...
[2/5] 安装编译依赖...
[3/5] 创建编译目录...
[4/5] 安装 Android SDK tools...
[5/5] 安装 repo 工具...
========================================
安装完成！
```

### 步骤 3: 开始编译

```bash
# 交互式编译脚本
bash scripts/02-build-android.sh
```

**脚本会询问**：
- 编译版本选择（user 或 userdebug）
- 编译目标确认
- 并行编译线程数

**预期时间**：
- 首次编译：2-8 小时（取决于硬件）
- 增量编译：15-60 分钟

### 步骤 4: 优化产物

```bash
# 自动优化编译产物
bash scripts/03-optimize-output.sh
```

**优化效果**：
- 镜像大小：从 10GB 降低到 3-5GB
- 清理空间：释放 50-100GB

### 步骤 5: 传输到 iPad

```bash
# 启动 HTTP 服务器
bash scripts/04-transfer-to-ipad.sh
```

**在 iPad 上**：
1. 打开 Safari 浏览器
2. 访问 `http://<vm-ip>:8000/`
3. 下载 `VirtuaMachine-utm-*.zip` 文件
4. 打开 Files 应用，解压文件

### 步骤 6: 在 UTM 中导入

1. 打开 UTM 应用
2. 点击 **+** 创建新虚拟机
3. 选择 **Browse** 导入现有虚拟机
4. 选择解压后的 `.utm` 文件夹
5. 点击 **Open** 导入

### 步骤 7: 配置虚拟机

**系统资源**：
- CPU 核心：8
- 内存：6GB
- 虚拟化：启用
- UEFI：启用

**显示配置**：
- 显示设备：`virtio-gpu-gl-pci (GPU Supported)`
- 渲染器：`ANGLE (Metal)`
- Retina 模式：禁用

**存储配置**：
- 系统磁盘：50GB
- 数据磁盘：20GB

### 步骤 8: 启动虚拟机

1. 点击虚拟机的 **Play** 按钮
2. 等待 Android 启动（30-60 秒）
3. 完成初始设置向导
4. 享受 Android 15！

## 常见问题

### Q: 编译需要多长时间？

**A**: 取决于您的硬件：
- 4 核 8GB：6-8 小时
- 8 核 16GB：2-4 小时
- 16 核 32GB：1-2 小时

使用 ccache 可以将增量编译时间降低到 15-60 分钟。

### Q: 虚拟机无法启动怎么办？

**A**: 尝试以下步骤：
1. 禁用虚拟化模式
2. 降低 CPU 和内存分配
3. 更改渲染器（Metal → OpenGL → 软件）
4. 更新 UTM 到最新版本

详见 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### Q: 图形显示异常？

**A**: 这通常是渲染器问题：
1. 尝试 ANGLE (OpenGL)
2. 尝试软件渲染
3. 禁用 Retina 模式
4. 降低分辨率

### Q: 编译失败了？

**A**: 检查以下内容：
1. 依赖是否完整：`bash scripts/01-setup-build-env.sh`
2. 磁盘空间是否充足：`df -h`
3. 网络连接是否正常：`ping google.com`
4. 查看编译日志：`tail -f build.log`

详见 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 下一步

- 📖 阅读 [BUILD_GUIDE.md](BUILD_GUIDE.md) 了解详细的编译过程
- 🚀 阅读 [OPTIMIZATION_GUIDE.md](OPTIMIZATION_GUIDE.md) 了解性能优化
- 🔧 阅读 [ARCHITECTURE.md](../ARCHITECTURE.md) 了解系统架构
- 📝 查看 [DEVELOPMENT_LOG.md](../DEVELOPMENT_LOG.md) 了解开发日志

## 获取帮助

- 📋 查看 [FAQ.md](FAQ.md) 常见问题
- 🐛 提交 Issue：[GitHub Issues](https://github.com/yourusername/android15-utm-build/issues)
- 💬 讨论：[GitHub Discussions](https://github.com/yourusername/android15-utm-build/discussions)

## 关键命令速查

```bash
# 环境设置
bash scripts/01-setup-build-env.sh

# 编译
bash scripts/02-build-android.sh

# 优化
bash scripts/03-optimize-output.sh

# 传输
bash scripts/04-transfer-to-ipad.sh

# 存储管理
bash scripts/05-manage-storage.sh

# 性能测试
bash scripts/06-benchmark-vm.sh
```

## 预期结果

✅ 编译完成后，您将获得：
- `system.img` - 系统分区
- `vendor.img` - 供应商分区
- `boot.img` - 启动分区
- `VirtuaMachine-utm-*.zip` - 完整虚拟机包

✅ 虚拟机启动后，您将获得：
- 完整的 Android 15 系统
- 流畅的图形性能
- 稳定的系统运行

## 时间表

| 步骤 | 预期时间 |
|------|--------|
| 环境设置 | 10-20 分钟 |
| 源代码同步 | 2-8 小时 |
| 编译构建 | 1-6 小时 |
| 产物优化 | 10-20 分钟 |
| 文件传输 | 10-30 分钟 |
| UTM 导入 | 5-10 分钟 |
| **总计** | **6-24 小时** |

---

**需要更多帮助？** 查看完整文档或提交 Issue。

**祝您编译顺利！** 🎉

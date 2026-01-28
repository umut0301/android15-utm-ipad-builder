# 🚀 快速开始指南 - Android 15 UTM iPad Builder

**适用于**: 首次使用本项目的用户  
**目标**: 在 30 分钟内完成从源代码编译到 iPad 部署的完整流程

---

## 📋 前置要求

在开始之前，请确保您有：

- ✅ 一台运行 **Debian 12** 的服务器（推荐配置：32GB+ RAM, 200GB+ 存储, 16+ CPU 核心）
- ✅ 一台 **iPad Pro M1**（或更新型号，安装了 UTM 应用）
- ✅ 稳定的网络连接（用于下载约 100GB 的源代码）
- ✅ 基本的 Linux 命令行知识

---

## 🎯 三步走战略

### 第一步：在 Debian 服务器上编译 Android 15

#### 1.1 克隆项目仓库

```bash
git clone https://github.com/umut0301/android15-utm-ipad-builder.git
cd android15-utm-ipad-builder
```

#### 1.2 运行自动化编译脚本

```bash
# 一键编译（推荐）
sudo bash scripts/00-auto-build-all.sh
```

这个脚本会自动完成以下所有步骤：
- 安装所有必需的依赖（包括 Mesa 3D、Python 模块等）
- 同步 LineageOS 23.0 源代码（约 100GB）
- 编译 Android 15 for virtio_arm64
- 生成 UTM 虚拟机包

**预计耗时**: 2-4 小时（取决于您的服务器性能和网络速度）

#### 1.3 等待编译完成

编译过程会在终端显示进度。您可以：
- 保持终端打开，实时查看进度
- 或者使用 `tmux` 在后台运行，避免 SSH 断开

```bash
# 使用 tmux（推荐）
tmux new -s android-build
sudo bash scripts/00-auto-build-all.sh
# 按 Ctrl+B, 然后按 D 来分离会话
# 稍后使用 tmux attach -t android-build 重新连接
```

#### 1.4 编译完成后的输出

成功编译后，您会在以下位置找到最终产物：

```
~/android/lineage/out/target/product/virtio_arm64/VirtualMachine/UTM/
└── UTM-VM-lineage-23.0-YYYYMMDD-UNOFFICIAL-virtio_arm64.zip
```

---

### 第二步：传输文件到 iPad Pro

#### 2.1 使用 SMB 文件共享（最简单）

**在 Debian 服务器上**:

```bash
# 运行传输脚本（会自动设置 SMB 共享）
bash scripts/05-transfer-to-ipad.sh
```

脚本会显示您的服务器 IP 地址（例如 `192.168.1.100`）。

**在 iPad 上**:

1. 打开 **"文件"** 应用
2. 点击右上角 **"..."** -> **"连接服务器"**
3. 输入 `smb://您的服务器IP`
4. 连接后，找到 `.zip` 文件并拷贝到 iPad 本地存储

#### 2.2 其他方法

如果 SMB 不可用，您也可以使用：
- **iCloud Drive**: 上传到 iCloud，然后在 iPad 上下载
- **HTTP 服务器**: 在服务器上运行 `python3 -m http.server 8080`，然后在 iPad 浏览器中下载

详细步骤请参考 [iPad 部署指南](./IPAD_DEPLOYMENT_GUIDE.md)。

---

### 第三步：在 UTM 中导入和运行

#### 3.1 导入虚拟机

1. 打开 iPad 上的 **UTM** 应用
2. 点击右上角 **"+"** -> **"导入"**
3. 选择您刚刚传输的 `.zip` 文件
4. 等待导入完成（约 2-5 分钟）

#### 3.2 配置存储空间

**重要**: 在首次启动前，请调整存储空间！

1. 长按虚拟机 -> **"编辑"**
2. 选择 **"驱动器"** -> 点击 `disk-vda.img`
3. 将 **"大小"** 从 12GB 调整为您期望的值：
   - **64 GB**: 轻度使用
   - **128 GB**: 推荐（日常使用）
   - **256 GB**: 重度使用
4. 保存更改

#### 3.3 首次启动

1. 点击虚拟机 -> **"启动"**
2. 等待 3-5 分钟（首次启动需要初始化）
3. 按照屏幕提示完成 Android 设置向导
4. 进入系统后，验证存储空间是否正确（设置 -> 存储）

---

## ✅ 验证清单

完成上述步骤后，请验证以下功能：

- [ ] 系统能正常启动并进入主屏幕
- [ ] 存储空间显示正确（接近您设置的值）
- [ ] Wi-Fi 连接正常
- [ ] 能安装和运行应用
- [ ] 3D 应用（如游戏）运行流畅（验证 3D 加速）

---

## 🎉 完成！

恭喜！您已经成功在 iPad Pro 上运行了 Android 15！

---

## 📚 进阶阅读

想要深入了解或自定义您的构建？请查看：

- [完整构建指南](./BUILD_GUIDE.md) - 详细的编译步骤和选项
- [存储管理指南](./STORAGE_MANAGEMENT_GUIDE.md) - 如何自定义存储配置
- [优化指南](./OPTIMIZATION_GUIDE.md) - 性能调优技巧
- [故障排除指南](./TROUBLESHOOTING_GUIDE.md) - 常见问题解决方案
- [架构文档](./ARCHITECTURE.md) - 技术架构和设计决策

---

## 🆘 需要帮助？

如果您遇到问题：

1. 查看 [常见问题解答 (FAQ)](./FAQ.md)
2. 查看 [故障排除指南](./TROUBLESHOOTING_GUIDE.md)
3. 在 GitHub 提交 Issue: https://github.com/umut0301/android15-utm-ipad-builder/issues

---

**祝您使用愉快！** 🚀

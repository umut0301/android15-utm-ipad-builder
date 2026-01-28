# UTM 虚拟机存储扩展工具 - 使用文档

**版本**: 1.0  
**日期**: 2026-01-28  
**适用于**: Android 15 (LineageOS 23.0) for virtio_arm64

---

## 📋 功能概述

这是一个**全新的独立脚本**，专门用于修改已编译好的 UTM 虚拟机包的存储配置。它可以：

✅ **自动识别** UTM 虚拟机包（.zip 或 .utm 目录）  
✅ **检测当前存储空间**  
✅ **扩展虚拟磁盘镜像**（disk-vda.img 和 disk-vdb.img）  
✅ **更新 GPT 分区表**  
✅ **修改 UTM 配置文件**（config.plist）  
✅ **保障 LineageOS 稳定运行**  
✅ **支持 64GB/128GB/256GB** 预设或自定义大小

---

## 🎯 核心特性

### 1. 智能识别

脚本会自动搜索当前目录及子目录中的所有 UTM 虚拟机包：
- `.utm` 目录
- 包含 `.utm` 的 `.zip` 文件

如果找到多个包，会显示列表让您选择。

### 2. 安全操作

- ✅ 操作前会创建备份（`.backup` 后缀）
- ✅ 显示详细的操作计划并要求确认
- ✅ 检测当前大小，避免不必要的操作
- ✅ 完整的错误处理和日志输出

### 3. 完整处理

对于虚拟磁盘镜像：
- 使用 `qemu-img resize` 扩展虚拟磁盘
- 使用 `sgdisk` 扩展 GPT 分区表
- 自动扩展最后一个分区（通常是 userdata）

对于 UTM 配置：
- 自动更新 `config.plist` 中的 `SizeMib` 值
- 支持 XML 格式的配置文件
- 保持其他配置不变

---

## 🚀 快速开始

### 前置要求

- **操作系统**: Linux（Debian/Ubuntu 推荐）
- **权限**: root（sudo）
- **依赖工具**: qemu-utils, parted, gdisk, xmlstarlet, zip, unzip

脚本会自动检查并安装缺失的工具。

### 基本用法

#### 方式 1: 交互式（推荐）

```bash
# 进入包含 UTM 虚拟机包的目录
cd ~/Downloads

# 运行脚本（会自动搜索并让您选择）
sudo bash utm-storage-resizer.sh
```

脚本会：
1. 搜索并列出所有 UTM 包
2. 让您选择要修改的包
3. 让您选择目标大小（64/128/256 GB 或自定义）
4. 显示操作计划并要求确认
5. 执行扩展操作

#### 方式 2: 命令行参数

```bash
# 指定 UTM 包和目标大小
sudo bash utm-storage-resizer.sh ./LineageOS.utm 128

# 或者处理 ZIP 文件
sudo bash utm-storage-resizer.sh ./UTM-VM-lineage-23.0-*.zip 256
```

---

## 📖 详细使用示例

### 示例 1: 扩展 .utm 目录到 128GB

```bash
# 假设您有一个 LineageOS_on_arm64.utm 目录
cd ~/android-vms

# 运行脚本
sudo bash utm-storage-resizer.sh LineageOS_on_arm64.utm 128
```

**输出示例**:
```
╔════════════════════════════════════════════════════════════╗
║        UTM 虚拟机存储扩展工具 v1.0                        ║
║        适用于 Android 15 (LineageOS 23.0)                 ║
╚════════════════════════════════════════════════════════════╝

[INFO] 检查必需的工具...
[SUCCESS] 所有必需工具已安装
[INFO] 选择的包: LineageOS_on_arm64.utm
[INFO] 目标大小: 128 GB
[INFO] UTM 目录: LineageOS_on_arm64.utm
[INFO] 当前磁盘大小: 12 GB

[WARNING] 即将执行以下操作：
  - 扩展 disk-vda.img 从 12 GB 到 128 GB
  - 扩展 GPT 分区表
  - 更新 UTM 配置文件

确认继续? [y/N]: y

[INFO] 开始处理...

[INFO] 扩展磁盘镜像: LineageOS_on_arm64.utm/Images/disk-vda.img
[INFO] 目标大小: 128 GB
[INFO] 创建备份...
[INFO] 扩展虚拟磁盘...
[SUCCESS] 磁盘镜像已扩展到 128 GB
[INFO] 扩展 GPT 分区表...
[INFO] 检测到最后一个分区: 7
[INFO] 重新创建分区 7，起始扇区: 25432064
[SUCCESS] 分区表已扩展
[INFO] 更新 UTM 配置文件...
[INFO] 检测到 XML 格式的配置文件
[SUCCESS] 配置文件已更新: SizeMib = 131072 MiB (128 GB)

[SUCCESS] 处理完成！
[INFO] UTM 目录: LineageOS_on_arm64.utm
[INFO] 磁盘备份: LineageOS_on_arm64.utm/Images/disk-vda.img.backup

[INFO] 下一步操作：
  1. 将修改后的 UTM 包传输到 iPad
  2. 在 UTM 中导入虚拟机
  3. 首次启动时，Android 会自动扩展文件系统（需要 3-5 分钟）
  4. 进入系统后，检查 '设置' -> '存储' 确认空间

[SUCCESS] 所有操作完成！
```

### 示例 2: 扩展 .zip 文件到 256GB

```bash
cd ~/Downloads

# 运行脚本处理 ZIP 文件
sudo bash utm-storage-resizer.sh UTM-VM-lineage-23.0-20260128-UNOFFICIAL-virtio_arm64.zip 256
```

脚本会：
1. 自动解压 ZIP 文件到临时目录
2. 扩展虚拟磁盘和分区
3. 更新配置文件
4. 重新打包为新的 ZIP 文件（文件名会包含 `-256GB` 后缀）
5. 清理临时文件

**输出文件**: `UTM-VM-lineage-23.0-20260128-UNOFFICIAL-virtio_arm64-256GB.zip`

### 示例 3: 交互式选择

```bash
cd ~/Downloads

# 不带任何参数运行
sudo bash utm-storage-resizer.sh
```

**交互流程**:
```
[INFO] 搜索当前目录中的 UTM 虚拟机包...

[INFO] 找到以下 UTM 虚拟机包：

  [1] ./LineageOS_on_arm64.utm
  [2] ./UTM-VM-lineage-23.0-20260128-UNOFFICIAL-virtio_arm64.zip

请选择要修改的包 [1-2]: 2

[INFO] 选择目标存储大小：

  [1] 64 GB  - 轻度使用
  [2] 128 GB - 推荐（日常使用）
  [3] 256 GB - 重度使用
  [4] 自定义大小

请选择 [1-4, 默认=2]: 2

[INFO] 选择的包: ./UTM-VM-lineage-23.0-20260128-UNOFFICIAL-virtio_arm64.zip
[INFO] 目标大小: 128 GB
...
```

---

## 🔧 技术细节

### 处理流程

1. **识别和验证**
   - 搜索 UTM 包（.utm 目录或 .zip 文件）
   - 验证包结构（检查 config.plist 和 Images 目录）
   - 检测当前磁盘大小

2. **磁盘扩展**
   - 备份原始磁盘镜像
   - 使用 `qemu-img resize` 扩展虚拟磁盘
   - 验证扩展结果

3. **分区表更新**
   - 使用 `parted` 修复 GPT 备份表
   - 使用 `sgdisk` 扩展最后一个分区（userdata）
   - 保持其他分区不变

4. **配置文件更新**
   - 备份 config.plist
   - 使用 `xmlstarlet` 或 `sed` 更新 SizeMib 值
   - 验证更新结果

5. **重新打包（如果是 ZIP）**
   - 使用 `zip` 重新打包 .utm 目录
   - 生成新的 ZIP 文件（带大小后缀）
   - 清理临时文件

### 磁盘和分区结构

#### disk-vda.img（主系统磁盘）

```
GPT 分区表:
┌─────────────────────────────────────┐
│ EFI 分区 (128 MB)                   │  ← 启动分区
├─────────────────────────────────────┤
│ super 分区 (12 GB)                  │  ← 动态分区容器
│   ├─ system                         │     (system/vendor/product)
│   ├─ vendor                         │
│   └─ product                        │
├─────────────────────────────────────┤
│ persist 分区 (16 MB)                │  ← 持久化数据
├─────────────────────────────────────┤
│ boot_a/boot_b (84 MB each)          │  ← 内核和 ramdisk
├─────────────────────────────────────┤
│ vendor_boot_a/vendor_boot_b         │  ← Vendor 启动镜像
├─────────────────────────────────────┤
│ userdata 分区 (剩余空间)            │  ← 用户数据 ★ 扩展目标
└─────────────────────────────────────┘
```

**扩展策略**: 脚本会扩展 `userdata` 分区到磁盘末尾，这是用户可用的存储空间。

#### disk-vdb.img（用户数据磁盘）

- 通常不存在或很小
- 如果存在，脚本会保持不变
- 可以手动扩展（使用相同的方法）

---

## ⚠️ 重要注意事项

### 1. 备份

虽然脚本会自动创建备份，但**强烈建议**在操作前手动备份整个 UTM 包：

```bash
# 备份 .utm 目录
cp -r LineageOS_on_arm64.utm LineageOS_on_arm64.utm.backup

# 或备份 .zip 文件
cp UTM-VM-lineage-*.zip UTM-VM-lineage-backup.zip
```

### 2. 磁盘空间

扩展操作需要足够的磁盘空间：
- 原始磁盘: 12 GB
- 扩展到 128 GB: 需要额外 116 GB
- 加上备份: 总共约 140 GB

确保您的服务器有足够的可用空间。

### 3. 首次启动

扩展后的虚拟机在首次启动时：
- 需要 **3-5 分钟** 来扩展文件系统
- 可能会看到 "正在优化存储" 的提示
- 不要在此期间强制关闭虚拟机

### 4. 验证存储

进入 Android 系统后：
1. 打开 **"设置"** -> **"存储"**
2. 检查 **"内部共享存储空间"** 的总容量
3. 如果设置了 128 GB，应显示约 **115 GB** 可用（系统占用约 12 GB）

---

## 🛠️ 故障排除

### 问题 1: "qemu-img: command not found"

**原因**: 缺少 qemu-utils 包

**解决方案**:
```bash
sudo apt update
sudo apt install -y qemu-utils
```

### 问题 2: "sgdisk: command not found"

**原因**: 缺少 gdisk 包

**解决方案**:
```bash
sudo apt install -y gdisk
```

### 问题 3: 扩展后 Android 中存储空间未增加

**原因**: 文件系统扩展未完成

**解决方案**:
1. 完全关闭虚拟机
2. 重新启动虚拟机
3. 等待 5-10 分钟
4. 再次检查存储空间

如果仍然没有变化，可能需要手动扩展文件系统（需要 adb 访问）。

### 问题 4: "无法识别配置文件格式"

**原因**: config.plist 格式不是标准 XML

**解决方案**:
- 脚本会跳过配置文件更新
- 您需要在 iPad 的 UTM 中手动调整磁盘大小
- 虚拟磁盘本身已经扩展，只是配置文件未更新

### 问题 5: ZIP 重新打包失败

**原因**: 磁盘空间不足或权限问题

**解决方案**:
1. 检查磁盘空间: `df -h`
2. 确保有足够的空间（至少是目标大小的 2 倍）
3. 手动打包:
   ```bash
   cd /path/to/utm/parent/directory
   zip -r output.zip LineageOS_on_arm64.utm
   ```

---

## 📊 存储大小推荐

| 使用场景 | 推荐大小 | 说明 |
|---|---|---|
| **轻度测试** | 64 GB | 适合只安装少量应用，主要用于测试系统功能 |
| **日常使用** | 128 GB | **推荐配置**，可以安装大量应用、游戏，存储照片和文件 |
| **重度使用** | 256 GB | 适合安装大型游戏、存储大量媒体文件，或作为主要 Android 环境 |
| **自定义** | 16-512 GB | 根据您的 iPad 存储空间和需求自定义 |

---

## 🔗 相关资源

- **GitHub 仓库**: https://github.com/umut0301/android15-utm-ipad-builder
- **问题反馈**: https://github.com/umut0301/android15-utm-ipad-builder/issues

---

## 📝 版本历史

### v1.0 (2026-01-28)
- ✅ 初始版本
- ✅ 支持 .utm 目录和 .zip 文件
- ✅ 自动识别和选择
- ✅ 磁盘扩展和分区表更新
- ✅ 配置文件自动更新
- ✅ 完整的错误处理和日志

---

**作者**: Manus AI  
**许可证**: MIT  
**最后更新**: 2026-01-28

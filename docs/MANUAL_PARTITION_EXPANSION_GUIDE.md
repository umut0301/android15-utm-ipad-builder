# 手动扩展 UTM 虚拟机磁盘分区指南

**作者**: Manus AI  
**最后更新**: 2026-01-28

---

## 1. 概述

本指南提供了在 **Debian 服务器**上手动扩展已有 UTM 虚拟机包的磁盘分区的详细步骤。这适用于以下场景：

-   您已经将 UTM 包传输到 iPad 并发现存储空间不足。
-   您不想重新编译或重新运行整个扩展脚本。
-   您需要对现有的虚拟机进行紧急扩容。

**核心思路**: 将 qcow2 格式转换为 raw 格式，扩展磁盘和分区，然后转换回 qcow2。

---

## 2. 前置要求

### 软件依赖

在您的 Debian 服务器上，确保已安装以下工具：

```bash
sudo apt update
sudo apt install -y qemu-utils gdisk parted
```

### 磁盘空间

扩展到 256GB 需要：
-   原始 qcow2 文件: ~12 GB
-   临时 raw 文件: ~256 GB
-   **总计**: 至少 **300 GB** 可用空间

检查可用空间：
```bash
df -h ~/android/lineage/out
```

---

## 3. 操作步骤

### 第 1 步：准备工作目录

```bash
# 进入 UTM 输出目录
cd ~/android/lineage/out/target/product/virtio_arm64/VirtualMachine/UTM

# 创建工作目录
mkdir -p ~/utm-expansion-work
cd ~/utm-expansion-work
```

### 第 2 步：解压 ZIP 包

```bash
# 解压您的 UTM 包（替换为实际文件名）
unzip ~/android/lineage/out/target/product/virtio_arm64/VirtualMachine/UTM/UTM-VM-lineage-22.2-virtio_arm64only-256GB.zip

# 进入解压后的目录
cd LineageOS.utm/Data  # 或 LineageOS.utm/Images，取决于您的包结构
```

### 第 3 步：备份原始文件

```bash
# 备份 qcow2 文件（非常重要！）
cp vda.qcow2 vda.qcow2.backup
```

### 第 4 步：转换 qcow2 到 raw

```bash
# 转换为 raw 格式
qemu-img convert -f qcow2 -O raw vda.qcow2 vda.raw

# 验证转换
qemu-img info vda.raw
```

**预期输出**:
```
file format: raw
virtual size: 32 GiB (34359738368 bytes)
```

### 第 5 步：扩展 raw 磁盘

```bash
# 扩展到 256GB
qemu-img resize vda.raw 256G

# 验证扩展
qemu-img info vda.raw
```

**预期输出**:
```
file format: raw
virtual size: 256 GiB (274877906944 bytes)
```

### 第 6 步：扩展 GPT 分区表

```bash
# 查看当前分区
sgdisk -p vda.raw

# 找到最后一个分区（通常是 8，即 userdata）
# 记下起始扇区

# 删除最后一个分区
sgdisk -d 8 vda.raw

# 重新创建分区，使用所有剩余空间
sgdisk -n 8:0:0 vda.raw

# 设置分区名称
sgdisk -c 8:userdata vda.raw

# 验证分区表
sgdisk -p vda.raw
```

**预期输出**（最后一个分区）:
```
Number  Start (sector)    End (sector)  Size       Code  Name
   8            xxxxx       536870878   ~256.0 GiB  8300  userdata
```

### 第 7 步：转换回 qcow2

```bash
# 转换回 qcow2 格式
qemu-img convert -f raw -O qcow2 vda.raw vda-256gb.qcow2

# 验证转换
qemu-img info vda-256gb.qcow2
```

**预期输出**:
```
file format: qcow2
virtual size: 256 GiB (274877906944 bytes)
```

### 第 8 步：替换原文件

```bash
# 备份原始 qcow2（如果还没有）
mv vda.qcow2 vda.qcow2.old

# 使用新文件
mv vda-256gb.qcow2 vda.qcow2

# 清理临时文件
rm vda.raw
```

### 第 9 步：更新 UTM 配置文件

```bash
# 返回 UTM 目录
cd ..

# 编辑 config.plist
nano config.plist
```

找到 `SizeMib` 相关的条目，将其更新为 `262144` (256GB * 1024):

```xml
<key>SizeMib</key>
<integer>262144</integer>
```

保存并退出 (Ctrl+O, Enter, Ctrl+X)。

### 第 10 步：重新打包

```bash
# 返回工作目录
cd ~/utm-expansion-work

# 重新打包为 ZIP
zip -r UTM-VM-lineage-22.2-virtio_arm64only-256GB-fixed.zip LineageOS.utm

# 移动到输出目录
mv UTM-VM-lineage-22.2-virtio_arm64only-256GB-fixed.zip ~/android/lineage/out/target/product/virtio_arm64/VirtualMachine/UTM/
```

---

## 4. 验证和部署

### 在 Debian 服务器上验证

```bash
# 检查新 ZIP 文件
ls -lh ~/android/lineage/out/target/product/virtio_arm64/VirtualMachine/UTM/*-fixed.zip

# 解压并验证分区
unzip -q *-fixed.zip
cd LineageOS.utm/Data
qemu-img info vda.qcow2
```

### 传输到 iPad

```bash
# 使用您喜欢的方法传输新的 ZIP 文件到 iPad
# 例如：SMB、iCloud、USB 等
```

### 在 iPad 上导入

1.  在 iPad 上解压 ZIP 文件。
2.  在 UTM 中导入 `.utm` 目录。
3.  **首次启动**时，Android 会自动扩展文件系统（需要 3-5 分钟）。
4.  进入系统后，检查 "设置" -> "存储"，应显示约 **235 GB** 可用。

---

## 5. 故障排除

### 问题 1: `sgdisk: command not found`

**解决**:
```bash
sudo apt install -y gdisk
```

### 问题 2: 转换过程中磁盘空间不足

**解决**:
-   清理不必要的文件：`sudo apt clean && sudo apt autoremove`
-   使用外部存储或网络存储作为工作目录。

### 问题 3: 分区扩展后 Android 仍显示旧大小

**原因**: 文件系统还没有扩展。

**解决**: 在 Android 的 root shell 中执行：
```bash
adb shell
su
resize2fs /dev/block/dm-48  # 或您的实际 userdata 设备
```

---

## 6. 完整命令清单（复制粘贴）

```bash
# ===== 第 1 步：准备 =====
cd ~/android/lineage/out/target/product/virtio_arm64/VirtualMachine/UTM
mkdir -p ~/utm-expansion-work
cd ~/utm-expansion-work

# ===== 第 2 步：解压 =====
unzip ~/android/lineage/out/target/product/virtio_arm64/VirtualMachine/UTM/UTM-VM-lineage-22.2-virtio_arm64only-256GB.zip
cd LineageOS.utm/Data  # 或 Images

# ===== 第 3 步：备份 =====
cp vda.qcow2 vda.qcow2.backup

# ===== 第 4 步：转换到 raw =====
qemu-img convert -f qcow2 -O raw vda.qcow2 vda.raw
qemu-img info vda.raw

# ===== 第 5 步：扩展磁盘 =====
qemu-img resize vda.raw 256G
qemu-img info vda.raw

# ===== 第 6 步：扩展分区 =====
sgdisk -p vda.raw
sgdisk -d 8 vda.raw
sgdisk -n 8:0:0 vda.raw
sgdisk -c 8:userdata vda.raw
sgdisk -p vda.raw

# ===== 第 7 步：转换回 qcow2 =====
qemu-img convert -f raw -O qcow2 vda.raw vda-256gb.qcow2
qemu-img info vda-256gb.qcow2

# ===== 第 8 步：替换文件 =====
mv vda.qcow2 vda.qcow2.old
mv vda-256gb.qcow2 vda.qcow2
rm vda.raw

# ===== 第 9 步：更新配置 =====
cd ..
nano config.plist  # 手动编辑 SizeMib 为 262144

# ===== 第 10 步：重新打包 =====
cd ~/utm-expansion-work
zip -r UTM-VM-lineage-22.2-virtio_arm64only-256GB-fixed.zip LineageOS.utm
mv *-fixed.zip ~/android/lineage/out/target/product/virtio_arm64/VirtualMachine/UTM/
```

---

## 7. 预计时间

| 步骤 | 时间 |
|---|---|
| 解压 | 1-2 分钟 |
| 转换 qcow2 -> raw | 5-10 分钟 |
| 扩展磁盘 | 即时 |
| 扩展分区 | 1 分钟 |
| 转换 raw -> qcow2 | 10-20 分钟 |
| 重新打包 | 2-5 分钟 |
| **总计** | **20-40 分钟** |

---

## 8. 总结

通过这个手动流程，您可以在不重新运行整个编译或扩展脚本的情况下，立即解决当前虚拟机的存储空间问题。

**关键要点**:
-   qcow2 格式需要转换为 raw 才能使用 `sgdisk` 进行分区操作。
-   分区扩展后，Android 会在首次启动时自动扩展文件系统。
-   如果自动扩展失败，可以手动执行 `resize2fs`。

---

**祝您扩展成功！** 🚀

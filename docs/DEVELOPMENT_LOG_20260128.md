# 开发日志: 2026-01-28 - 修复 GPT 分区扩展问题

**作者**: Manus AI

---

## 1. 问题背景

用户报告，在使用 `utm-storage-resizer.sh` 脚本将一个 256GB 的 UTM 包扩展后，进入 Android 系统仍然只显示 15GB 的存储空间。

**初步诊断**:
-   虚拟磁盘文件 (`.qcow2`) 本身已经扩展到了 256GB。
-   但 Android 内部的文件系统没有扩展。

---

## 2. 深入分析

通过让用户在 Android 的 root shell 中执行 `cat /proc/partitions` 和 `blockdev --getsize64`，我们获得了关键信息：

-   **整个虚拟磁盘 (vda)**: `268,435,456 KB` (256 GB) - ✅ **磁盘已扩展**
-   **userdata 分区 (vda8)**: `131,072 KB` (128 MB) - ❌ **分区未扩展**
-   **逻辑卷 (dm-48)**: `17,179,869,184 bytes` (16 GB) - ❌ **逻辑卷未扩展**

**结论**: 问题的根源在于脚本中的 `expand_partition` 函数**未能成功扩展 GPT 分区表**。

---

## 3. 定位 Bug

1.  **检查 `expand_partition` 函数**: 该函数依赖 `sgdisk` 工具来删除并重新创建最后一个分区，以使用所有可用空间。

2.  **测试 `sgdisk` 对 qcow2 的支持**: 
    通过在沙盒中创建一个 qcow2 文件并尝试用 `sgdisk` 读取，发现 `sgdisk` 无法正确识别 qcow2 文件的几何结构。
    ```bash
    qemu-img create -f qcow2 test.qcow2 1G
    sgdisk -p test.qcow2
    ```
    **输出**: `Warning: File size is not a multiple of 512 bytes!`，并将 1GB 的文件识别为 192KB。

3.  **确认 Bug**: `sgdisk` 无法直接操作 qcow2 格式的磁盘镜像，导致分区扩展步骤静默失败。

---

## 4. 修复方案

为了让 `sgdisk` 能正确工作，我们需要一个中间步骤：

1.  **检测磁盘格式**: 在 `expand_partition` 函数开始时，使用 `qemu-img info` 检测磁盘格式。
2.  **格式转换 (qcow2 -> raw)**: 如果检测到是 `qcow2` 格式，则：
    -   使用 `qemu-img convert -f qcow2 -O raw` 将其转换为一个临时的 `.raw` 文件。
3.  **操作 Raw 文件**: 对这个临时的 `.raw` 文件执行 `sgdisk` 分区扩展操作。`sgdisk` 可以完美处理 raw 格式。
4.  **格式转换 (raw -> qcow2)**: 分区操作完成后，再使用 `qemu-img convert -f raw -O qcow2` 将修改后的 raw 文件转换回原始的 qcow2 文件名。
5.  **清理**: 删除临时的 `.raw` 文件和备份。

### 实施细节

-   在 `expand_partition` 函数中增加了 `need_convert` 标志位来跟踪是否需要转换。
-   添加了转换过程中的错误处理和备份恢复机制，确保操作的原子性和安全性。
-   修改了 `sgdisk` 命令，过滤掉不必要的警告信息，使日志更清晰。

---

## 5. 创建手动扩展指南

考虑到用户可能需要立即解决当前虚拟机的问题，而不是重新运行整个脚本，我创建了一个在 Debian 服务器上手动扩展分区的指南。

这个指南的核心步骤与脚本修复的逻辑一致：

1.  **解压** `.zip` 包。
2.  **转换** `vda.qcow2` 到 `vda.raw`。
3.  **扩展** `vda.raw` 文件大小。
4.  **扩展** `vda.raw` 内部的 GPT 分区。
5.  **转换**回 `vda.qcow2`。
6.  **重新打包** `.zip`。

---

## 6. 最终交付

-   **修复后的脚本**: `utm-storage-resizer.sh` (v1.2)，现在能正确处理 qcow2 格式的分区扩展。
-   **开发日志**: 本文档，记录了问题的发现、分析和修复过程。
-   **手动扩展指南**: `MANUAL_PARTITION_EXPANSION_GUIDE.md`，为用户提供立即解决问题的备用方案。
-   **更新的 README**: 在主 README 中加入了新文档的链接和说明。

---

## 7. 总结

这次修复的核心是解决了 `sgdisk` 与 `qcow2` 格式不兼容的问题。通过引入 `qcow2 <-> raw` 的转换步骤，我们利用了 `sgdisk` 在 raw 格式上的强大功能，同时保留了 qcow2 格式的优势（如快照、动态扩展等）。

这个修复大大增强了脚本的健壮性和兼容性。

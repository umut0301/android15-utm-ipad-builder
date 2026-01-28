# 🚀 UTM 存储扩展工具 - 快速使用指南

**5 分钟快速上手**

---

## 📥 下载脚本

```bash
# 下载脚本（假设您已经有编译好的 UTM 包）
wget https://raw.githubusercontent.com/umut0301/android15-utm-ipad-builder/master/utm-storage-resizer.sh

# 或者从本地复制
# 脚本文件: utm-storage-resizer.sh
```

---

## ⚡ 三步使用

### 第一步：准备

```bash
# 将脚本和 UTM 包放在同一目录
cd ~/Downloads

# 确保脚本可执行
chmod +x utm-storage-resizer.sh

# 查看您的 UTM 包
ls -lh *.utm *.zip
```

### 第二步：运行脚本

```bash
# 交互式运行（推荐）
sudo bash utm-storage-resizer.sh
```

**或者直接指定参数**:
```bash
# 扩展到 128GB（推荐）
sudo bash utm-storage-resizer.sh ./LineageOS.utm 128

# 扩展 ZIP 文件到 256GB
sudo bash utm-storage-resizer.sh ./UTM-VM-lineage-*.zip 256
```

### 第三步：传输到 iPad

```bash
# 如果是 .utm 目录，先打包
zip -r LineageOS-128GB.zip LineageOS_on_arm64.utm

# 使用任何方式传输到 iPad:
# - SMB 文件共享
# - iCloud Drive
# - HTTP 服务器
# - 其他云存储
```

---

## 📋 交互式选择示例

运行 `sudo bash utm-storage-resizer.sh` 后：

```
╔════════════════════════════════════════════════════════════╗
║        UTM 虚拟机存储扩展工具 v1.0                        ║
║        适用于 Android 15 (LineageOS 23.0)                 ║
╚════════════════════════════════════════════════════════════╝

[INFO] 搜索当前目录中的 UTM 虚拟机包...

[INFO] 找到以下 UTM 虚拟机包：

  [1] ./LineageOS_on_arm64.utm
  [2] ./UTM-VM-lineage-23.0-20260128.zip

请选择要修改的包 [1-2]: 2

[INFO] 选择目标存储大小：

  [1] 64 GB  - 轻度使用
  [2] 128 GB - 推荐（日常使用）
  [3] 256 GB - 重度使用
  [4] 自定义大小

请选择 [1-4, 默认=2]: 2

[INFO] 选择的包: ./UTM-VM-lineage-23.0-20260128.zip
[INFO] 目标大小: 128 GB
[INFO] 当前磁盘大小: 12 GB

[WARNING] 即将执行以下操作：
  - 扩展 disk-vda.img 从 12 GB 到 128 GB
  - 扩展 GPT 分区表
  - 更新 UTM 配置文件
  - 重新打包为 ZIP

确认继续? [y/N]: y

[INFO] 开始处理...
...
[SUCCESS] 处理完成！
[INFO] 新的 ZIP 包: ./UTM-VM-lineage-23.0-20260128-128GB.zip
```

---

## ✅ 验证清单

扩展完成后：

- [ ] 检查生成的文件大小（应该接近目标大小）
- [ ] 确认备份文件已创建（`.backup` 后缀）
- [ ] 传输到 iPad
- [ ] 在 UTM 中导入
- [ ] 首次启动（等待 3-5 分钟）
- [ ] 检查 "设置" -> "存储"（应显示约 115 GB for 128 GB）

---

## 🆘 常见问题

### Q: 需要多少磁盘空间？

**A**: 至少是目标大小的 2 倍。例如扩展到 128 GB，需要约 256 GB 可用空间（包括备份）。

### Q: 扩展需要多长时间？

**A**: 
- 磁盘扩展: 几秒钟
- 分区表更新: 几秒钟
- ZIP 重新打包: 1-5 分钟（取决于大小）
- **总计**: 通常 2-10 分钟

### Q: 会影响 Android 系统吗？

**A**: 不会。脚本只扩展磁盘和分区，不修改系统文件。Android 会在首次启动时自动适应新的存储空间。

### Q: 可以缩小磁盘吗？

**A**: 不建议。缩小磁盘可能导致数据丢失。如果必须缩小，请手动操作并确保新大小大于已使用空间。

---

## 📞 获取帮助

- **详细文档**: 查看 `UTM_STORAGE_RESIZER_README.md`
- **GitHub Issues**: https://github.com/umut0301/android15-utm-ipad-builder/issues
- **脚本帮助**: `bash utm-storage-resizer.sh --help`

---

**祝您使用愉快！** 🎉

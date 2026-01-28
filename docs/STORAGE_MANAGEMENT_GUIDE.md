# 💾 LineageOS + UTM 存储空间完整管理指南

## 🎯 目标

本指南帮助您在编译 LineageOS 时配置存储空间大小，并确保与 UTM 虚拟机完美协同。

---

## 📊 存储空间选项

### 预设选项

| 选项 | 总容量 | 系统分区 | 用户数据 | 适用场景 |
|------|--------|----------|----------|----------|
| **64GB** | 64GB | 8GB | 50GB | 轻度使用，少量应用 |
| **128GB** | 128GB | 10GB | 110GB | **推荐**，日常使用 |
| **256GB** | 256GB | 12GB | 235GB | 重度使用，大量应用和数据 |
| **自定义** | 自定义 | 自动计算 | 自动计算 | 高级用户 |

### 存储空间构成

```
总存储空间 = 系统分区 + 用户数据分区 + Vendor + Cache + 其他
```

- **系统分区** (system): Android 系统文件
- **用户数据分区** (userdata): 应用、照片、文件等
- **Vendor 分区**: 硬件驱动和固件
- **Cache 分区**: 临时缓存

---

## 🚀 快速开始

### 步骤 1: 配置存储空间

```bash
# 进入项目目录
cd ~/android15-utm-ipad-builder

# 运行存储配置脚本
bash scripts/configure-storage.sh
```

### 步骤 2: 选择存储大小

```
╔════════════════════════════════════════════════════════════╗
║  💾 LineageOS 存储空间配置工具                          ║
╚════════════════════════════════════════════════════════════╝

========================================
  选择虚拟机存储空间大小
========================================

1. 64GB  (适合轻度使用)
2. 128GB (推荐，默认选项)
3. 256GB (适合重度使用)
4. 自定义 (高级用户)

请选择 (1/2/3/4) [默认: 2]:
```

### 步骤 3: 确认配置

```
╔════════════════════════════════════════════════════════════╗
║  📊 存储配置摘要                                        ║
╚════════════════════════════════════════════════════════════╝

✓ 总存储空间: 128GB
✓ 系统分区:   10240MB (10.00GB)
✓ 用户数据:   112640MB (110.00GB)
✓ Vendor:     2048MB (2.00GB)
✓ Cache:      512MB (0.50GB)

[重要] 在 UTM 中导入虚拟机时，请设置磁盘大小为 128GB
```

### 步骤 4: 编译 LineageOS

```bash
# 运行编译脚本（会自动使用配置的存储大小）
bash scripts/03-build-android.sh
```

---

## 🔧 详细配置说明

### 配置文件位置

```
~/.android_storage_config
```

### 配置文件内容示例

```bash
# Android 存储配置
# 生成时间: 2026-01-27 10:00:00
STORAGE_SIZE=128
SYSTEM_SIZE=10240
USERDATA_SIZE=112640
VENDOR_SIZE=2048
CACHE_SIZE=512
```

### 如何修改配置

```bash
# 方法 1: 重新运行配置脚本
bash scripts/configure-storage.sh

# 方法 2: 手动编辑配置文件
vim ~/.android_storage_config

# 方法 3: 删除配置文件后重新配置
rm ~/.android_storage_config
bash scripts/configure-storage.sh
```

---

## 📱 UTM 虚拟机配置

### 编译完成后

编译完成后，您会得到：

1. **UTM 虚拟机包**: `UTM-VM-lineage-*.zip`
2. **存储配置信息**: `UTM_STORAGE_CONFIG.txt`

### 导入到 UTM

#### 步骤 1: 传输文件到 iPad

```bash
# 使用 scp 或其他方式传输到 iPad
# 文件位置: ~/android/lineage/out/target/product/virtio_arm64/
```

#### 步骤 2: 解压 UTM 包

在 iPad 的"文件"应用中：
1. 找到 `UTM-VM-lineage-*.zip`
2. 点击解压
3. 得到 `.utm` 文件夹

#### 步骤 3: 导入到 UTM

1. 打开 UTM 应用
2. 点击右上角的 "+" 按钮
3. 选择 "浏览"
4. 找到并选择 `.utm` 文件夹
5. 点击 "导入"

#### 步骤 4: 配置虚拟机磁盘大小 ⚠️ **重要**

1. 在 UTM 中，长按刚导入的虚拟机
2. 选择 "编辑"
3. 进入 "驱动器" 设置
4. 找到主磁盘驱动器（通常是第一个）
5. **设置磁盘大小为您配置的大小**（如 128GB）
6. 保存设置

#### 步骤 5: 启动虚拟机

1. 点击虚拟机启动
2. 首次启动会进行初始化
3. 完成后即可使用

---

## 🎯 存储空间协同原理

### LineageOS 侧

```
BoardConfig.mk
├── BOARD_SYSTEMIMAGE_PARTITION_SIZE
├── BOARD_USERDATAIMAGE_PARTITION_SIZE
├── BOARD_VENDORIMAGE_PARTITION_SIZE
└── BOARD_CACHEIMAGE_PARTITION_SIZE
```

配置脚本会自动修改这些值，确保编译时生成对应大小的分区镜像。

### UTM 侧

```
UTM 虚拟磁盘
├── 分区表
├── system.img   (映射到系统分区)
├── userdata.img (映射到用户数据分区)
├── vendor.img   (映射到 vendor 分区)
└── cache.img    (映射到 cache 分区)
```

UTM 的虚拟磁盘大小必须 >= LineageOS 配置的总大小。

### 协同机制

1. **编译时**: `configure-storage.sh` 修改 `BoardConfig.mk`
2. **编译过程**: 根据配置生成对应大小的分区镜像
3. **打包时**: 创建 UTM 虚拟机包，包含所有镜像
4. **导入时**: UTM 读取镜像并创建虚拟磁盘
5. **配置时**: 用户在 UTM 中设置与配置一致的磁盘大小
6. **运行时**: Android 使用配置的存储空间

---

## 💡 常见问题

### Q1: 如果 UTM 磁盘大小设置错误会怎样？

**情况 A: UTM 磁盘 < 配置的大小**
- ❌ 虚拟机可能无法启动
- ❌ 或启动后空间不足

**情况 B: UTM 磁盘 > 配置的大小**
- ✅ 虚拟机可以正常启动
- ✅ Android 会自动使用额外的空间
- 💡 建议：设置为配置的大小以获得最佳性能

### Q2: 可以在编译后修改存储大小吗？

❌ **不建议**。存储大小在编译时就已经固定在分区镜像中。

如果需要修改：
1. 重新运行 `configure-storage.sh`
2. 清理旧的编译产物: `rm -rf ~/android/lineage/out`
3. 重新编译: `bash scripts/03-build-android.sh`

### Q3: 128GB 够用吗？

对于大多数用户，**128GB 完全够用**：

- 系统占用: ~10GB
- 应用和数据: 110GB（可安装大量应用）
- 适合日常使用、游戏、照片等

如果您是重度用户（大量游戏、视频等），建议选择 256GB。

### Q4: 自定义大小的限制？

- **最小**: 32GB（系统需要至少 20GB）
- **最大**: 取决于您的 iPad 存储空间
- **建议**: 64GB / 128GB / 256GB（经过优化的预设）

### Q5: 如何查看当前配置？

```bash
# 查看配置文件
cat ~/.android_storage_config

# 或运行配置脚本（会显示已有配置）
bash scripts/configure-storage.sh
```

### Q6: 编译时没有配置存储会怎样？

编译脚本会：
1. 检测是否有存储配置
2. 如果没有，提示您先配置
3. 或使用默认设置（需要确认）

**建议**: 始终先运行 `configure-storage.sh`

---

## 🔍 高级用法

### 自定义分区比例

如果您想自定义分区比例，可以手动编辑配置文件：

```bash
vim ~/.android_storage_config
```

示例（256GB 配置）：

```bash
STORAGE_SIZE=256
SYSTEM_SIZE=12288    # 12GB 给系统
USERDATA_SIZE=240640 # 235GB 给用户数据
VENDOR_SIZE=2560     # 2.5GB 给 vendor
CACHE_SIZE=512       # 512MB 给 cache
```

**注意**: 
- 所有大小单位为 MB
- 总和应接近 STORAGE_SIZE * 1024

### 验证配置

```bash
# 编译后检查生成的镜像大小
ls -lh ~/android/lineage/out/target/product/virtio_arm64/*.img

# 查看 UTM 配置信息
cat ~/android/lineage/out/target/product/virtio_arm64/UTM_STORAGE_CONFIG.txt
```

### 动态调整 UTM 磁盘大小

在 UTM 中，您可以在虚拟机关闭状态下调整磁盘大小：

1. 关闭虚拟机
2. 编辑虚拟机设置
3. 进入 "驱动器"
4. 调整磁盘大小
5. 保存并启动

**注意**: 
- 只能增大，不能缩小
- Android 会自动识别新的空间

---

## 📊 存储空间使用建议

### 64GB 配置

**适合**:
- 轻度使用
- 主要用于测试
- 少量应用（<50 个）

**不适合**:
- 大量游戏
- 大量照片/视频
- 重度使用

### 128GB 配置（推荐）

**适合**:
- 日常使用
- 中等数量应用（50-100 个）
- 适量照片/视频
- 一些游戏

**优势**:
- 平衡性能和空间
- 适合大多数用户

### 256GB 配置

**适合**:
- 重度使用
- 大量应用（100+ 个）
- 大量照片/视频
- 多个大型游戏

**优势**:
- 充足的空间
- 长期使用无忧

---

## 🎯 最佳实践

### 1. 编译前配置

```bash
# 推荐的完整流程
cd ~/android15-utm-ipad-builder

# 1. 配置存储
bash scripts/configure-storage.sh

# 2. 编译
bash scripts/03-build-android.sh
```

### 2. 使用 tmux

```bash
# 避免 SSH 断开导致编译中断
tmux new -s android-build
bash scripts/03-build-android.sh
# Ctrl+B, D 分离会话
```

### 3. 记录配置

```bash
# 备份配置文件
cp ~/.android_storage_config ~/android_storage_config_backup

# 或记录在笔记中
cat ~/.android_storage_config
```

### 4. UTM 导入检查清单

- [ ] 解压 UTM-VM-lineage-*.zip
- [ ] 在 UTM 中导入 .utm 文件夹
- [ ] 编辑虚拟机设置
- [ ] 设置磁盘大小为配置的大小
- [ ] 保存设置
- [ ] 启动虚拟机
- [ ] 验证存储空间（设置 → 存储）

---

## 📚 相关文档

- [编译指南](BUILD_GUIDE.md)
- [UTM 优化指南](OPTIMIZATION_GUIDE.md)
- [故障排查](TROUBLESHOOTING.md)
- [快速参考](QUICK_REFERENCE.md)

---

## 🔗 快速链接

- **GitHub 仓库**: https://github.com/umut0301/android15-utm-ipad-builder
- **存储配置脚本**: `scripts/configure-storage.sh`
- **使用命令**: `bash ~/android15-utm-ipad-builder/scripts/configure-storage.sh`

---

**版本**: v1.0  
**创建日期**: 2026-01-27  
**用途**: LineageOS 和 UTM 存储空间协同配置完整指南

# UTM 虚拟机优化调优与 Android 15 导入完整指南

## 目录
1. [UTM 3D 加速配置](#utm-3d-加速配置)
2. [Android 编译产物优化](#android-编译产物优化)
3. [虚拟机镜像导入步骤](#虚拟机镜像导入步骤)
4. [存储空间管理](#存储空间管理)
5. [性能调优](#性能调优)
6. [故障排查](#故障排查)

---

## UTM 3D 加速配置

### 1.1 理解 UTM 的图形加速选项

UTM 在 Apple Silicon Mac 上提供了多种图形渲染方案。每种方案都有不同的性能特性和兼容性：

| 渲染器 | 性能 | 兼容性 | 推荐场景 | 备注 |
|---|---|---|---|---|
| **ANGLE (Metal)** | 最佳 | 中等 | iPad Pro M1 推荐 | 使用 Metal 后端，性能最优 |
| **ANGLE (OpenGL)** | 良好 | 良好 | 通用 Linux | 跨平台兼容性好 |
| **VirGL** | 一般 | 实验性 | Linux 3D 应用 | 需要 Linux 驱动支持 |
| **软件渲染** | 差 | 最佳 | 应急方案 | 无加速，仅用于故障排查 |

### 1.2 显示设备选择

#### GPU 支持的设备（用于 3D 加速）

```
virtio-gpu-gl-pci      ← 推荐用于 3D 加速
virtio-gpu-pci         ← 基础虚拟 GPU，无加速
qxl-vga                ← 旧版 QXL 设备
ramfb                  ← 简单帧缓冲，无加速
```

**对于 iPad Pro M1 + Android 15**：
- **首选**: `virtio-gpu-gl-pci`（GPU 支持）
- **备选**: `virtio-gpu-pci`（如遇问题）

### 1.3 UTM 中的 3D 加速配置步骤

#### 步骤 1：创建或编辑虚拟机

1. 打开 UTM 应用
2. 选择或创建虚拟机
3. 点击设置齿轮图标进入配置

#### 步骤 2：配置显示设备

**路径**: 设置 → Devices → Display

1. **Emulated Display Card** 设置：
   - 选择 `virtio-gpu-gl-pci (GPU Supported)`
   
2. **Graphics Acceleration Renderer Backend**：
   - 对于 iPad Pro M1：选择 **ANGLE (Metal)**
   - 备选方案：**ANGLE (OpenGL)**

3. **VGA Device RAM**：
   - 保持默认（通常 16MB）
   - 如需高分辨率，可增加到 32MB 或 64MB

4. **Retina Mode**：
   - 建议**禁用**（让 macOS 处理缩放）
   - 这样性能更优，图像更清晰

#### 步骤 3：配置系统资源

**路径**: 设置 → System

| 参数 | 推荐值 | 说明 |
|---|---|---|
| CPU 核心数 | 4-8 | 根据主机能力调整 |
| 内存 | 4-6GB | 足够运行 Android 15 |
| 启用 UEFI | 是 | 现代启动方式 |
| 启用虚拟化 | 是 | 提高性能 |

#### 步骤 4：配置存储

**路径**: 设置 → Drives

创建两个虚拟磁盘：

| 磁盘 | 大小 | 用途 | 格式 |
|---|---|---|---|
| 第一块 | 30-50GB | 系统和应用 | virtio |
| 第二块 | 10-20GB | 数据和缓存 | virtio |

**磁盘格式选择**：
- **qcow2**：支持快照，可增长（推荐）
- **raw**：固定大小，性能略优

### 1.4 高级图形配置

#### 启用 VirGL（Linux 虚拟 3D GPU）

如果选择了 `virtio-gpu-gl-pci`，VirGL 会自动启用。

**VirGL 配置**：
```bash
# 在 Android 虚拟机内检查 VirGL 支持
glxinfo | grep "OpenGL"
```

**注意**：VirGL 目前仅在 Linux 中完全支持。Android 对 VirGL 的支持有限。

#### 禁用虚拟化模式（故障排查）

如果虚拟机无法启动或显示异常：

1. 进入虚拟机设置
2. 找到 **Virtualization** 或 **Hypervisor** 选项
3. **禁用**该选项
4. 重新启动虚拟机

**影响**：禁用虚拟化会降低性能，仅在必要时使用。

### 1.5 ANGLE 配置详解

#### ANGLE (Metal) - iPad Pro M1 最优选择

```
优点：
✓ 利用 Apple Metal 框架，性能最优
✓ 专为 Apple Silicon 优化
✓ 支持较新的 OpenGL 特性

缺点：
✗ 仅在 macOS 上可用
✗ 某些应用可能不兼容
```

**配置方法**：
1. 虚拟机设置 → Display
2. 在 "Graphics Acceleration Renderer Backend" 中选择 **ANGLE (Metal)**
3. 保存并重启虚拟机

#### ANGLE (OpenGL) - 备选方案

```
优点：
✓ 跨平台兼容性好
✓ 应用支持广泛
✓ 更稳定可靠

缺点：
✗ 性能不如 Metal
✗ 可能存在内存泄漏（已在 UTM 4.7.5+ 修复）
```

---

## Android 编译产物优化

### 2.1 编译时的优化选项

#### 编译瘦身版本

```bash
cd ~/android/lineage

# 使用 user 版本而非 userdebug（更小，无调试符号）
source build/envsetup.sh
lunch virtio_arm64-user

# 编译
m -j$(nproc)
```

**版本对比**：

| 版本 | 大小 | 调试符号 | 用途 |
|---|---|---|---|
| `userdebug` | 较大 | 有 | 开发和调试 |
| `user` | 较小 | 无 | 生产环境 |

#### 禁用不必要的功能

编辑 `device/google/virtio_arm64/device.mk`：

```makefile
# 禁用不必要的应用
PRODUCT_PACKAGES := \
    # 核心应用
    SystemUI \
    Settings \
    # 移除不需要的应用
    # RemovePackage1 \
    # RemovePackage2 \

# 禁用调试符号
DISABLE_PROGUARD := false
```

### 2.2 编译产物文件说明

编译完成后，主要输出文件位置：

```
out/target/product/virtio_arm64/
├── system.img              # 系统分区（~2-3GB）
├── vendor.img              # 供应商分区（~500MB）
├── boot.img                # 启动分区（~50MB）
├── userdata.img            # 用户数据分区（可选）
├── VirtuaMachine-utm-*.zip # 完整虚拟机镜像包
└── obj/                    # 编译中间文件（可删除）
```

### 2.3 优化编译产物大小

#### 方法 1：清理编译中间文件

```bash
cd ~/android/lineage

# 删除中间文件但保留最终产物
make clean

# 或仅删除特定模块的中间文件
m clean-SystemUI
```

#### 方法 2：压缩镜像文件

```bash
# 使用 qemu-img 压缩 qcow2 格式的镜像
qemu-img convert -O qcow2 -c system.img system-compressed.img

# 查看压缩效果
ls -lh system.img system-compressed.img
```

#### 方法 3：移除调试信息

```bash
# 从 system.img 中移除调试符号
strip out/target/product/virtio_arm64/system/lib64/*.so

# 或在编译时禁用
export DISABLE_PROGUARD=true
m -j$(nproc)
```

### 2.4 虚拟机镜像包优化

#### 检查 ZIP 包内容

```bash
# 列出 ZIP 包内容
unzip -l out/target/product/virtio_arm64/VirtuaMachine-utm-*.zip

# 查看大小
du -sh out/target/product/virtio_arm64/VirtuaMachine-utm-*.zip
```

#### 重新打包优化

```bash
# 创建优化的 ZIP 包
cd out/target/product/virtio_arm64/

# 使用更好的压缩算法
zip -r -9 VirtuaMachine-utm-optimized.zip \
    system.img vendor.img boot.img

# 对比大小
ls -lh VirtuaMachine-utm-*.zip VirtuaMachine-utm-optimized.zip
```

---

## 虚拟机镜像导入步骤

### 3.1 准备导入前的检查

#### 验证编译产物完整性

```bash
# 检查所有必要文件
cd ~/android/lineage/out/target/product/virtio_arm64/

# 验证关键文件存在
ls -lh system.img vendor.img boot.img

# 验证 ZIP 包完整性
unzip -t VirtuaMachine-utm-*.zip
```

#### 计算文件校验和（可选）

```bash
# 生成 MD5 校验和
md5sum VirtuaMachine-utm-*.zip > VirtuaMachine-utm-*.zip.md5

# 验证校验和
md5sum -c VirtuaMachine-utm-*.zip.md5
```

### 3.2 将编译产物传输到 iPad

#### 方法 1：使用 iCloud Drive（推荐）

1. 在 Debian 12 虚拟机中：
   ```bash
   # 复制文件到共享位置
   cp ~/android/lineage/out/target/product/virtio_arm64/VirtuaMachine-utm-*.zip \
      /path/to/shared/folder/
   ```

2. 在 iPad 上：
   - 打开 Files 应用
   - 进入 iCloud Drive
   - 找到并下载 ZIP 文件

#### 方法 2：使用 AirDrop（快速）

1. 在 Debian 12 虚拟机所在的 Mac 上：
   - 将 ZIP 文件复制到 Mac
   - 使用 AirDrop 发送到 iPad

#### 方法 3：使用网络传输

```bash
# 在 Debian 12 虚拟机中启动简单 HTTP 服务器
cd ~/android/lineage/out/target/product/virtio_arm64/
python3 -m http.server 8000

# 在 iPad 上打开浏览器
# 访问 http://<vm-ip>:8000/
# 下载 VirtuaMachine-utm-*.zip 文件
```

### 3.3 在 UTM 中导入虚拟机

#### 步骤 1：解压 ZIP 文件

在 iPad 上：

1. 打开 Files 应用
2. 找到下载的 ZIP 文件
3. 长按 → 解压
4. 等待解压完成（可能需要几分钟）

#### 步骤 2：导入到 UTM

1. 打开 UTM 应用
2. 点击 **+** 按钮创建新虚拟机
3. 选择 **Browse** 导入现有虚拟机
4. 选择解压后的虚拟机文件夹
5. 点击 **Open** 导入

#### 步骤 3：配置虚拟机参数

导入后，进行以下配置：

**系统资源**：
- CPU 核心：4-8
- 内存：4-6GB
- 启用 UEFI
- 启用虚拟化

**显示配置**：
- 显示设备：`virtio-gpu-gl-pci (GPU Supported)`
- 渲染器：**ANGLE (Metal)**
- Retina 模式：禁用

**存储配置**：
- 第一块磁盘：30-50GB（系统）
- 第二块磁盘：10-20GB（数据）

**声音配置**：
- 声卡：AC97
- 启用音频

### 3.4 首次启动

1. 点击虚拟机的 **Play** 按钮启动
2. 等待 Android 15 启动（首次可能需要 1-2 分钟）
3. 完成初始设置向导
4. 进入 Android 主界面

---

## 存储空间管理

### 4.1 虚拟机磁盘大小规划

#### 磁盘分配建议

| 用途 | 大小 | 说明 |
|---|---|---|
| 系统分区 | 30-50GB | 包含 system.img 和应用 |
| 数据分区 | 10-20GB | 用户数据和缓存 |
| 总计 | 40-70GB | 根据 iPad 存储调整 |

#### 磁盘格式选择

**qcow2 格式**（推荐）：
```bash
# 创建可增长的 qcow2 磁盘
qemu-img create -f qcow2 system.qcow2 50G

# 查看实际占用空间
du -h system.qcow2

# 压缩 qcow2 文件
qemu-img convert -O qcow2 -c system.qcow2 system-compressed.qcow2
```

**raw 格式**：
```bash
# 创建固定大小的 raw 磁盘
qemu-img create -f raw system.raw 50G

# 查看大小
ls -lh system.raw
```

### 4.2 虚拟机内部存储优化

#### 清理不必要的文件

在 Android 虚拟机内：

```bash
# 通过 adb 连接
adb connect <vm-ip>:5555

# 清理应用缓存
adb shell pm trim-caches 1024M

# 清理临时文件
adb shell rm -rf /data/cache/*
adb shell rm -rf /data/local/tmp/*

# 查看存储使用情况
adb shell df -h
```

#### 禁用不必要的系统应用

```bash
# 列出已安装的应用
adb shell pm list packages

# 禁用不需要的应用
adb shell pm disable-user com.android.app.name

# 卸载预装应用
adb shell pm uninstall --user 0 com.android.app.name
```

### 4.3 监控磁盘使用

#### 在虚拟机中检查

```bash
# 查看分区大小
adb shell df -h

# 查看目录大小
adb shell du -sh /data/*
adb shell du -sh /system/*
```

#### 在主机上检查

```bash
# 查看虚拟磁盘实际占用
du -sh ~/android/lineage/out/target/product/virtio_arm64/

# 查看 qcow2 磁盘的虚拟大小和实际大小
qemu-img info system.qcow2
```

---

## 性能调优

### 5.1 虚拟机性能优化

#### CPU 和内存分配

```
iPad Pro M1 配置建议：
- CPU 核心：6-8（M1 有 8 核）
- 内存：4-6GB（iPad 通常有 8GB）
- 保留 2GB 给 iPad 系统
```

#### 启用虚拟化加速

在 UTM 虚拟机设置中：
- ✓ 启用虚拟化
- ✓ 启用 UEFI
- ✓ 启用 IOMMU（如可用）

### 5.2 图形性能优化

#### ANGLE Metal 优化

```bash
# 在虚拟机内设置环境变量
export ANGLE_RENDERER=metal
export ANGLE_PREFER_METAL=1
```

#### 分辨率和缩放优化

| 设置 | 推荐值 | 说明 |
|---|---|---|
| 分辨率 | 1920x1080 | 平衡性能和可用性 |
| 缩放 | 100% | 关闭 Retina 模式 |
| 刷新率 | 60Hz | 足够流畅 |

### 5.3 I/O 性能优化

#### 磁盘 I/O 优化

```bash
# 使用 virtio 磁盘（已在编译时配置）
# 在虚拟机设置中确认磁盘使用 virtio 接口

# 启用磁盘缓存
# 在 UTM 高级设置中启用 I/O 缓存
```

#### 网络性能优化

```bash
# 使用 virtio-net 网络驱动
# 在虚拟机设置中配置网络为 virtio

# 启用网络加速（如可用）
```

---

## 故障排查

### 6.1 虚拟机无法启动

#### 症状
- UTM 应用崩溃
- 虚拟机卡在启动屏幕
- 显示错误信息

#### 解决方案

**步骤 1：禁用虚拟化**
```
设置 → System → 禁用 Virtualization/Hypervisor
```

**步骤 2：更改图形设置**
```
设置 → Display → 
  - 显示设备：virtio-gpu-pci（无 GL）
  - 渲染器：ANGLE (OpenGL)
```

**步骤 3：降低资源分配**
```
设置 → System →
  - CPU 核心：2-4
  - 内存：2-3GB
```

### 6.2 图形显示异常

#### 症状
- 屏幕全黑
- 显示颜色异常（偏绿/偏红）
- 闪烁或撕裂

#### 解决方案

**尝试不同的渲染器**：
1. ANGLE (Metal) → ANGLE (OpenGL) → 软件渲染
2. 每次更改后重启虚拟机

**禁用 Retina 模式**：
```
设置 → Display → Retina Mode → 禁用
```

**更新 UTM**：
- 确保使用最新版本（4.7.5+）
- 新版本修复了多个图形问题

### 6.3 内存泄漏导致崩溃

#### 症状
- 虚拟机运行一段时间后崩溃
- 内存占用不断增加
- 性能逐渐下降

#### 解决方案

**更新 UTM 到 4.7.5+**：
- 该版本修复了 ANGLE Metal 和 OpenGL 的内存泄漏

**降低分辨率**：
```
设置 → Display → 降低分辨率到 1280x720
```

**禁用 GPU 加速**：
```
设置 → Display → 显示设备：virtio-gpu-pci（无 GL）
```

### 6.4 存储空间不足

#### 症状
- 虚拟机内提示存储满
- 应用无法安装
- 系统运行缓慢

#### 解决方案

**扩展虚拟磁盘**：
```bash
# 扩展 qcow2 磁盘大小
qemu-img resize system.qcow2 +20G

# 在虚拟机内扩展分区
adb shell parted /dev/vda resizepart 1 100%
```

**清理虚拟机内存储**：
```bash
# 清理缓存
adb shell pm trim-caches 1024M

# 卸载不需要的应用
adb shell pm uninstall --user 0 com.app.name
```

### 6.5 网络连接问题

#### 症状
- 虚拟机无网络
- 网络连接不稳定
- 无法访问互联网

#### 解决方案

**检查网络配置**：
```
设置 → Network → 确保网络已启用
```

**更改网络驱动**：
```
设置 → Network → 
  - 网络模式：NAT 或 Bridged
  - 网络驱动：virtio
```

**重启网络**：
```bash
adb shell ifconfig eth0 down
adb shell ifconfig eth0 up
```

---

## 完整导入和配置流程总结

### 快速参考

```
1. 编译优化
   └─ 选择 user 版本
   └─ 清理中间文件
   └─ 验证产物完整性

2. 文件传输
   └─ 复制 ZIP 到共享位置
   └─ 传输到 iPad
   └─ 解压 ZIP 文件

3. UTM 导入
   └─ 打开 UTM
   └─ 导入虚拟机
   └─ 配置系统参数

4. 图形配置
   └─ 显示设备：virtio-gpu-gl-pci
   └─ 渲染器：ANGLE (Metal)
   └─ Retina 模式：禁用

5. 启动和测试
   └─ 启动虚拟机
   └─ 完成初始设置
   └─ 测试功能
```

---

## 关键要点总结

### ✓ 推荐配置

| 项目 | 配置 |
|---|---|
| 显示设备 | virtio-gpu-gl-pci (GPU Supported) |
| 渲染器 | ANGLE (Metal) |
| CPU | 6-8 核 |
| 内存 | 4-6GB |
| 系统磁盘 | 30-50GB qcow2 |
| 数据磁盘 | 10-20GB qcow2 |
| 编译版本 | virtio_arm64-user |
| 虚拟化 | 启用 |
| Retina 模式 | 禁用 |

### ⚠️ 常见陷阱

1. **不要使用 GPU Supported 的 virtio-gpu-gl-pci 在 iOS/iPadOS 上**
   - 会导致图形内存泄漏
   - 虚拟机会在 1 分钟内崩溃
   - 改用 virtio-gpu-pci（无 GL）

2. **不要启用 Retina 模式**
   - 降低性能
   - 增加内存占用
   - 图像质量不会改善

3. **不要分配过多内存**
   - iPad 需要保留系统内存
   - 建议最多 6GB
   - 否则 iPad 系统会变慢

### 📊 性能预期

| 操作 | 预期时间 |
|---|---|
| 虚拟机启动 | 30-60 秒 |
| 应用启动 | 2-5 秒 |
| 系统响应 | 流畅 |
| 3D 应用 | 可运行但不流畅 |

---

## 最后更新

**日期**: 2026 年 1 月 27 日  
**版本**: Android 15 / LineageOS 23.0  
**平台**: iPad Pro M1 + UTM  
**编译环境**: Debian 12

## 参考资源

- [UTM 官方文档 - Display](https://docs.getutm.app/settings-qemu/devices/display/)
- [LineageOS Wiki - UTM on Apple Silicon](https://wiki.lineageos.org/utm-vm-on-apple-silicon-mac)
- [LineageOS-UTM-HV GitHub](https://github.com/cupecups/LineageOS-UTM-HV)
- [QEMU 磁盘镜像文档](https://www.qemu.org/docs/master/system/images.html)

# 故障排查指南

## 编译相关问题

### 问题 1: 编译失败 - "command not found: repo"

**症状**：
```
bash: repo: command not found
```

**原因**：repo 工具未安装或不在 PATH 中

**解决方案**：
```bash
# 方案 1: 重新运行安装脚本
bash scripts/01-setup-build-env.sh

# 方案 2: 手动添加到 PATH
source ~/.profile

# 方案 3: 手动安装 repo
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH=$HOME/bin:$PATH
```

### 问题 2: 编译失败 - "No space left on device"

**症状**：
```
No space left on device
```

**原因**：磁盘空间不足

**解决方案**：
```bash
# 检查磁盘空间
df -h

# 清理 ccache
ccache -C

# 清理编译产物
cd ~/android/lineage
make clean

# 删除中间文件
rm -rf out/

# 如果仍然不足，扩展磁盘
# 在 Debian 12 虚拟机中扩展存储
```

### 问题 3: 编译失败 - "Java version mismatch"

**症状**：
```
Java version error
```

**原因**：Java 版本不正确

**解决方案**：
```bash
# 检查 Java 版本
java -version
javac -version

# 应该是 OpenJDK 11+
# 如果版本不对，安装正确版本
sudo apt install -y openjdk-11-jdk

# 设置默认 Java
sudo update-alternatives --config java
sudo update-alternatives --config javac
```

### 问题 4: 编译失败 - "repo sync" 超时

**症状**：
```
repo sync timeout
Connection refused
```

**原因**：网络连接不稳定或超时

**解决方案**：
```bash
# 方案 1: 重新同步
cd ~/android/lineage
repo sync -j4

# 方案 2: 强制重新同步
repo sync --force-sync

# 方案 3: 检查网络
ping -c 4 google.com

# 方案 4: 使用代理（如需要）
export HTTP_PROXY=http://proxy:port
export HTTPS_PROXY=http://proxy:port
repo sync -j4
```

### 问题 5: 编译失败 - "Permission denied"

**症状**：
```
Permission denied
```

**原因**：权限不足

**解决方案**：
```bash
# 检查文件权限
ls -l ~/android/lineage/

# 修复权限
chmod -R 755 ~/android/lineage/

# 或使用 sudo
sudo bash scripts/01-setup-build-env.sh
```

### 问题 6: 编译失败 - 编译错误

**症状**：
```
error: undefined reference to ...
```

**原因**：编译错误，通常是依赖问题

**解决方案**：
```bash
# 方案 1: 重新安装依赖
bash scripts/01-setup-build-env.sh

# 方案 2: 查看详细错误
tail -f build.log | grep -i error

# 方案 3: 清理并重新编译
cd ~/android/lineage
make clean
m -j$(nproc)

# 方案 4: 重新同步源代码
repo sync --force-sync
```

---

## 虚拟机启动问题

### 问题 7: 虚拟机无法启动 - 黑屏

**症状**：
- UTM 应用启动虚拟机后显示黑屏
- 虚拟机无响应

**原因**：
- 虚拟化设置不正确
- 图形驱动问题
- 资源分配不足

**解决方案**：

**步骤 1: 禁用虚拟化**
```
UTM 设置 → System → 禁用 Virtualization
重启虚拟机
```

**步骤 2: 更改图形设置**
```
UTM 设置 → Display
- 显示设备: virtio-gpu-pci (无 GL)
- 渲染器: ANGLE (OpenGL)
重启虚拟机
```

**步骤 3: 降低资源分配**
```
UTM 设置 → System
- CPU 核心: 2-4
- 内存: 2-3GB
重启虚拟机
```

**步骤 4: 查看虚拟机日志**
- 在 UTM 中查看启动日志
- 搜索错误信息

### 问题 8: 虚拟机启动缓慢

**症状**：
- 虚拟机启动需要 5+ 分钟
- 系统响应缓慢

**原因**：
- 资源分配不足
- 虚拟化加速未启用
- 图形性能不优

**解决方案**：

```bash
# 增加资源分配
CPU: 6-8 核
内存: 4-6GB

# 启用虚拟化加速
UTM 设置 → System → 启用 Virtualization

# 启用 UEFI
UTM 设置 → System → 启用 UEFI

# 使用 ANGLE Metal
UTM 设置 → Display
- 显示设备: virtio-gpu-gl-pci
- 渲染器: ANGLE (Metal)
```

### 问题 9: 虚拟机崩溃 - 内存泄漏

**症状**：
- 虚拟机运行一段时间后崩溃
- 内存占用不断增加
- 性能逐渐下降

**原因**：
- ANGLE 图形库内存泄漏（已在 UTM 4.7.5+ 修复）
- 虚拟机内存不足

**解决方案**：

**方案 1: 更新 UTM**
```
更新 UTM 到 4.7.5+ 版本
这个版本修复了 ANGLE 的内存泄漏问题
```

**方案 2: 如果问题依旧**
```
禁用 GPU 加速:
UTM 设置 → Display
- 显示设备: virtio-gpu-pci (无 GL)
- 渲染器: ANGLE (OpenGL) 或软件渲染
```

**方案 3: 降低分辨率**
```
UTM 设置 → Display
- 分辨率: 1280x720 (而不是 1920x1080)
```

---

## 图形显示问题

### 问题 10: 屏幕全黑

**症状**：
- 虚拟机启动但显示全黑
- 无法看到任何内容

**原因**：
- 显示设备不兼容
- 渲染器配置错误
- 驱动程序问题

**解决方案**：

```bash
# 尝试不同的显示设备
1. virtio-gpu-gl-pci (GPU Supported) - 推荐
2. virtio-gpu-pci (无 GL) - 备选
3. qxl-vga - 旧版
4. ramfb - 最小

# 尝试不同的渲染器
1. ANGLE (Metal) - iPad Pro M1 推荐
2. ANGLE (OpenGL) - 跨平台
3. 软件渲染 - 应急

# 禁用 Retina 模式
UTM 设置 → Display → Retina Mode → 禁用
```

### 问题 11: 显示颜色异常 - 偏绿/偏红

**症状**：
- 屏幕显示颜色异常
- 绿色或红色偏移

**原因**：
- 颜色空间配置错误
- 渲染器问题

**解决方案**：

```bash
# 更换渲染器
尝试: ANGLE (Metal) → ANGLE (OpenGL) → 软件渲染

# 禁用 Retina 模式
UTM 设置 → Display → Retina Mode → 禁用

# 重启虚拟机
```

### 问题 12: 显示闪烁或撕裂

**症状**：
- 屏幕闪烁
- 图像撕裂
- 显示不稳定

**原因**：
- 刷新率配置不当
- 垂直同步问题
- 渲染器问题

**解决方案**：

```bash
# 禁用 Retina 模式
UTM 设置 → Display → Retina Mode → 禁用

# 设置合理的分辨率
1920x1080 @ 60Hz

# 更换渲染器
尝试: ANGLE (Metal) → ANGLE (OpenGL)

# 更新 UTM
确保使用最新版本
```

---

## 存储问题

### 问题 13: 虚拟机存储空间不足

**症状**：
- 虚拟机提示存储满
- 应用无法安装
- 系统运行缓慢

**原因**：
- 虚拟磁盘大小不足
- 虚拟机内缓存过多

**解决方案**：

**方案 1: 扩展虚拟磁盘**
```bash
# 查看磁盘大小
qemu-img info system.qcow2

# 扩展磁盘
qemu-img resize system.qcow2 +20G

# 在虚拟机内扩展分区
adb shell parted /dev/vda resizepart 1 100%
```

**方案 2: 清理虚拟机内存储**
```bash
# 连接虚拟机
adb connect <vm-ip>:5555

# 清理缓存
adb shell pm trim-caches 1024M

# 清理临时文件
adb shell rm -rf /data/cache/*
adb shell rm -rf /data/local/tmp/*

# 卸载不需要的应用
adb shell pm uninstall --user 0 com.app.name
```

**方案 3: 查看存储使用**
```bash
# 查看分区大小
adb shell df -h

# 查看目录大小
adb shell du -sh /data/*
adb shell du -sh /system/*
```

### 问题 14: 编译产物过大

**症状**：
- VirtuaMachine-utm-*.zip 文件超过 10GB
- 传输到 iPad 困难

**原因**：
- 编译时未进行优化
- 中间文件未清理
- 镜像未压缩

**解决方案**：

```bash
# 运行优化脚本
bash scripts/03-optimize-output.sh

# 或手动优化
cd ~/android/lineage

# 清理中间文件
make clean

# 压缩镜像
qemu-img convert -O qcow2 -c system.img system-compressed.img

# 生成优化包
cd out/target/product/virtio_arm64/
zip -r -9 VirtuaMachine-utm-optimized.zip *.img
```

---

## 网络问题

### 问题 15: 虚拟机无网络连接

**症状**：
- 虚拟机无法访问互联网
- 无法下载应用

**原因**：
- 网络驱动配置错误
- 网络模式设置不当
- 主机网络问题

**解决方案**：

**步骤 1: 检查网络配置**
```
UTM 设置 → Network
- 网络模式: NAT 或 Bridged
- 网络驱动: virtio
```

**步骤 2: 重启网络**
```bash
adb shell ifconfig eth0 down
adb shell ifconfig eth0 up
```

**步骤 3: 检查网络状态**
```bash
adb shell ifconfig
adb shell ping 8.8.8.8
adb shell nslookup google.com
```

**步骤 4: 检查主机网络**
```bash
# 在 Debian 12 虚拟机中
ping google.com
```

---

## 性能问题

### 问题 16: 虚拟机性能差

**症状**：
- 应用启动缓慢
- 系统响应迟缓
- 帧率低

**原因**：
- 资源分配不足
- 虚拟化加速未启用
- 图形性能不优

**解决方案**：

```bash
# 增加资源分配
CPU: 6-8 核
内存: 4-6GB

# 启用虚拟化加速
UTM 设置 → System → 启用 Virtualization

# 使用 ANGLE Metal
UTM 设置 → Display
- 显示设备: virtio-gpu-gl-pci
- 渲染器: ANGLE (Metal)

# 禁用 Retina 模式
UTM 设置 → Display → Retina Mode → 禁用

# 清理虚拟机
adb shell pm trim-caches 1024M
```

### 问题 17: 编译速度慢

**症状**：
- 编译需要 8+ 小时
- 编译过程缓慢

**原因**：
- 硬件配置不足
- ccache 未启用
- 并行度不足

**解决方案**：

```bash
# 检查硬件配置
- CPU: 应该 8+ 核
- 内存: 应该 16GB+
- 存储: 应该使用 SSD

# 启用 ccache
export USE_CACHE=1
export CCACHE_EXEC=/usr/bin/ccache
ccache -M 50G

# 增加并行度
m -j$(nproc)

# 使用 user 版本
lunch virtio_arm64-user
```

---

## 诊断工具

### 虚拟机诊断脚本

```bash
# 运行完整诊断
bash scripts/06-benchmark-vm.sh

# 或手动诊断
adb connect <vm-ip>:5555

# 检查系统信息
adb shell getprop ro.build.version.release
adb shell getprop ro.build.version.sdk

# 检查硬件信息
adb shell getprop ro.hardware
adb shell getprop ro.processor

# 检查内存
adb shell free -h

# 检查存储
adb shell df -h

# 查看日志
adb logcat
```

### 编译诊断

```bash
# 检查编译环境
which gcc
which java
which repo

# 检查版本
gcc --version
java -version
repo --version

# 检查磁盘空间
df -h

# 检查 ccache
ccache -s

# 查看编译日志
tail -f build.log
```

---

## 快速参考

### 常见问题快速解决

| 问题 | 快速解决 |
|------|--------|
| 虚拟机无法启动 | 禁用虚拟化，降低资源 |
| 黑屏 | 更换显示设备和渲染器 |
| 图形异常 | 禁用 Retina，降低分辨率 |
| 内存泄漏 | 更新 UTM 到 4.7.5+ |
| 存储不足 | 扩展磁盘或清理缓存 |
| 编译失败 | 重新安装依赖，检查网络 |
| 性能差 | 增加资源，启用加速 |
| 网络无连接 | 检查网络配置，重启网络 |

### 重要命令

```bash
# 虚拟机连接
adb connect <vm-ip>:5555

# 虚拟机诊断
adb shell df -h
adb shell free -h
adb shell ps aux

# 编译诊断
df -h
ccache -s
tail -f build.log

# 文件传输
python3 -m http.server 8000
```

---

## 获取帮助

如果问题未在本文档中解决：

1. **查看日志**
   - 编译日志: `build.log`
   - 虚拟机日志: UTM 应用中的日志
   - 系统日志: `adb logcat`

2. **查看文档**
   - [FAQ.md](FAQ.md) - 常见问题
   - [BUILD_GUIDE.md](BUILD_GUIDE.md) - 编译指南
   - [OPTIMIZATION_GUIDE.md](OPTIMIZATION_GUIDE.md) - 优化指南

3. **提交 Issue**
   - 描述问题
   - 附加日志
   - 提供环境信息

4. **讨论**
   - GitHub Discussions
   - 与社区交流

---

**最后更新**: 2026 年 1 月 27 日  
**维护者**: Manus AI

记住：大多数问题都有解决方案。如果您遇到问题，不要放弃！

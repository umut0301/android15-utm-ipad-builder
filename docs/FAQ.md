# 常见问题解答 (FAQ)

## 编译相关

### Q1: 编译需要多长时间？

**A**: 编译时间取决于您的硬件配置：

| 硬件配置 | 首次编译 | 增量编译 |
|--------|--------|--------|
| 4 核 8GB RAM | 6-8 小时 | 30-60 分钟 |
| 8 核 16GB RAM | 2-4 小时 | 15-30 分钟 |
| 16 核 32GB RAM | 1-2 小时 | 5-15 分钟 |

**优化建议**：
- 使用 ccache 加速增量编译
- 使用 SSD 存储而不是 HDD
- 分配充足的 RAM（16GB+）
- 使用 user 版本而非 userdebug

### Q2: 编译失败了怎么办？

**A**: 按照以下步骤排查：

1. **检查依赖**
   ```bash
   bash scripts/01-setup-build-env.sh
   ```

2. **检查磁盘空间**
   ```bash
   df -h
   ```
   需要至少 300GB 空闲空间

3. **检查网络连接**
   ```bash
   ping google.com
   ```

4. **查看编译日志**
   ```bash
   tail -f build.log
   ```

5. **重新同步源代码**
   ```bash
   cd ~/android/lineage
   repo sync --force-sync
   ```

6. **清理并重新编译**
   ```bash
   make clean
   m -j$(nproc)
   ```

### Q3: ccache 如何工作？

**A**: ccache 是编译缓存工具：

- **首次编译**：编译所有文件，缓存结果
- **增量编译**：使用缓存，跳过未改变的文件
- **加速效果**：2-10 倍加速

**配置 ccache**：
```bash
# 设置缓存大小
ccache -M 50G

# 启用压缩
ccache -o compression=true

# 查看统计
ccache -s

# 清空缓存
ccache -C
```

### Q4: 如何选择编译版本？

**A**: 有两个主要版本：

| 版本 | 大小 | 调试符号 | 推荐用途 |
|------|------|--------|--------|
| `user` | 较小 | 无 | 生产环境 |
| `userdebug` | 较大 | 有 | 开发调试 |

**推荐**：使用 `user` 版本，体积更小，性能更优。

### Q5: 如何加速编译？

**A**: 多个方面可以加速编译：

1. **硬件优化**
   - 使用 8+ 核 CPU
   - 分配 16-32GB 内存
   - 使用 SSD 存储

2. **软件优化**
   ```bash
   # 启用 ccache
   export USE_CACHE=1
   export CCACHE_EXEC=/usr/bin/ccache
   
   # 增加并行度
   m -j$(nproc)
   ```

3. **工作流优化**
   - 使用增量编译
   - 只编译需要的模块
   - 预下载源代码

---

## 虚拟机相关

### Q6: 虚拟机无法启动？

**A**: 按照以下步骤排查：

1. **检查 UTM 版本**
   - 需要 UTM 4.7.5+ 版本
   - 更新到最新版本

2. **禁用虚拟化**
   ```
   设置 → System → 禁用 Virtualization
   ```

3. **降低资源分配**
   ```
   CPU: 2-4 核
   内存: 2-3GB
   ```

4. **更改图形设置**
   ```
   显示设备: virtio-gpu-pci (无 GL)
   渲染器: ANGLE (OpenGL)
   ```

5. **查看虚拟机日志**
   - 在 UTM 中查看启动日志
   - 搜索错误信息

### Q7: 图形显示异常？

**A**: 尝试以下解决方案：

1. **更换渲染器**
   ```
   ANGLE (Metal) → ANGLE (OpenGL) → 软件渲染
   ```

2. **禁用 Retina 模式**
   ```
   设置 → Display → Retina Mode → 禁用
   ```

3. **降低分辨率**
   ```
   从 1920x1080 降低到 1280x720
   ```

4. **增加 VGA RAM**
   ```
   从 16MB 增加到 32MB 或 64MB
   ```

5. **更新 UTM**
   - 确保使用最新版本
   - 新版本修复了多个图形问题

### Q8: 虚拟机运行缓慢？

**A**: 尝试以下优化：

1. **增加资源分配**
   ```
   CPU: 6-8 核
   内存: 4-6GB
   ```

2. **启用虚拟化加速**
   ```
   设置 → System → 启用 Virtualization
   ```

3. **使用 ANGLE Metal**
   ```
   显示设备: virtio-gpu-gl-pci
   渲染器: ANGLE (Metal)
   ```

4. **禁用不必要的功能**
   - 关闭后台应用
   - 清理缓存
   - 卸载不需要的应用

### Q9: 内存泄漏导致虚拟机崩溃？

**A**: 这是已知问题，已在 UTM 4.7.5+ 中修复：

1. **更新 UTM**
   - 升级到 4.7.5+ 版本
   - 这个版本修复了 ANGLE 的内存泄漏

2. **如果问题依旧**
   - 禁用 GPU 加速
   - 使用软件渲染
   - 降低分辨率

### Q10: 如何连接虚拟机？

**A**: 使用 ADB 连接：

```bash
# 获取虚拟机 IP
adb shell ifconfig

# 连接虚拟机
adb connect <vm-ip>:5555

# 查看连接状态
adb devices

# 执行命令
adb shell "command"
```

---

## 存储相关

### Q11: 虚拟机存储空间不足？

**A**: 按照以下步骤解决：

1. **扩展虚拟磁盘**
   ```bash
   qemu-img resize system.qcow2 +20G
   ```

2. **清理虚拟机内存储**
   ```bash
   adb shell pm trim-caches 1024M
   adb shell rm -rf /data/cache/*
   ```

3. **卸载不需要的应用**
   ```bash
   adb shell pm uninstall --user 0 com.app.name
   ```

4. **查看存储使用**
   ```bash
   adb shell df -h
   adb shell du -sh /data/*
   ```

### Q12: 如何优化镜像大小？

**A**: 多个方面可以优化：

1. **编译时优化**
   - 选择 user 版本：减小 30-40%
   - 启用代码混淆：减小 10-20%
   - 移除调试符号：减小 20-30%

2. **编译后优化**
   - 清理中间文件：释放 50-100GB
   - 压缩镜像：减小 40-50%
   - 使用 qcow2 格式：动态增长

3. **虚拟机优化**
   - 清理缓存
   - 卸载预装应用
   - 定期维护

### Q13: qcow2 和 raw 格式的区别？

**A**: 两种格式的对比：

| 特性 | qcow2 | raw |
|------|-------|-----|
| 动态增长 | ✓ | ✗ |
| 快照支持 | ✓ | ✗ |
| 压缩支持 | ✓ | ✗ |
| 性能 | 良好 | 最优 |
| 兼容性 | 广泛 | 通用 |

**推荐**：使用 qcow2 格式，支持更多功能。

---

## 性能相关

### Q14: 如何测试虚拟机性能？

**A**: 使用提供的性能测试脚本：

```bash
# 运行性能测试
bash scripts/06-benchmark-vm.sh

# 或手动测试
adb connect <vm-ip>:5555

# CPU 性能
adb shell "time dd if=/dev/zero of=/data/test.bin bs=1M count=100"

# 内存检查
adb shell "free -h"

# 存储性能
adb shell "time dd if=/dev/zero of=/data/test2.bin bs=1M count=50"
```

### Q15: 如何优化虚拟机性能？

**A**: 多个方面可以优化：

1. **资源分配**
   ```
   CPU: 6-8 核（最优）
   内存: 4-6GB（平衡）
   磁盘: 30-50GB（充足）
   ```

2. **图形加速**
   ```
   显示设备: virtio-gpu-gl-pci
   渲染器: ANGLE (Metal)
   Retina 模式: 禁用
   ```

3. **虚拟化加速**
   ```
   虚拟化: 启用
   UEFI: 启用
   IOMMU: 启用（如可用）
   ```

4. **系统优化**
   ```bash
   # 清理缓存
   adb shell pm trim-caches 1024M
   
   # 查看进程
   adb shell ps aux
   
   # 查看内存
   adb shell free -h
   ```

---

## 文件传输相关

### Q16: 如何将编译产物传输到 iPad？

**A**: 有多种方式：

1. **HTTP 服务器（推荐）**
   ```bash
   cd ~/android/lineage/out/target/product/virtio_arm64/
   python3 -m http.server 8000
   ```
   在 iPad 上访问 `http://<vm-ip>:8000/`

2. **共享文件夹**
   ```bash
   cp VirtuaMachine-utm-*.zip /mnt/shared/
   ```

3. **AirDrop**
   - 将文件复制到 Mac
   - 使用 AirDrop 发送到 iPad

### Q17: 如何验证文件完整性？

**A**: 使用校验和验证：

```bash
# 生成校验和
md5sum VirtuaMachine-utm-*.zip > VirtuaMachine-utm-*.zip.md5

# 验证校验和
md5sum -c VirtuaMachine-utm-*.zip.md5

# 验证 ZIP 完整性
unzip -t VirtuaMachine-utm-*.zip
```

---

## 导入相关

### Q18: 如何在 UTM 中导入虚拟机？

**A**: 按照以下步骤：

1. **解压 ZIP 文件**
   - 打开 Files 应用
   - 找到下载的 ZIP 文件
   - 长按 → 解压

2. **导入虚拟机**
   - 打开 UTM
   - 点击 **+** 创建新虚拟机
   - 选择 **Browse**
   - 选择解压后的 `.utm` 文件夹
   - 点击 **Open**

3. **配置虚拟机**
   - 设置 CPU、内存、磁盘
   - 配置图形设置
   - 配置网络和声卡

4. **启动虚拟机**
   - 点击 **Play** 按钮
   - 等待系统启动
   - 完成初始设置

### Q19: 导入后虚拟机无法启动？

**A**: 查看 [Q6: 虚拟机无法启动？](#q6-虚拟机无法启动)

### Q20: 如何手动创建虚拟机？

**A**: 如果不想导入 `.utm` 包，可以手动创建：

1. **在 UTM 中创建新虚拟机**
   - 选择 Linux 系统
   - 选择 ARM 64-bit 架构
   - 分配资源

2. **挂载镜像文件**
   - 添加虚拟磁盘
   - 挂载 system.img, vendor.img, boot.img

3. **配置启动**
   - 设置 UEFI 启动
   - 配置启动顺序

4. **启动虚拟机**
   - 启动虚拟机
   - 完成初始化

---

## 其他问题

### Q21: 如何获取帮助？

**A**: 有多种方式获取帮助：

1. **查看文档**
   - [README.md](../README.md) - 项目概述
   - [QUICKSTART.md](QUICKSTART.md) - 快速开始
   - [BUILD_GUIDE.md](BUILD_GUIDE.md) - 编译指南
   - [OPTIMIZATION_GUIDE.md](OPTIMIZATION_GUIDE.md) - 优化指南
   - [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 故障排查

2. **查看开发文档**
   - [DEVELOPMENT_LOG.md](../DEVELOPMENT_LOG.md) - 开发日志
   - [ARCHITECTURE.md](../ARCHITECTURE.md) - 系统架构

3. **提交 Issue**
   - GitHub Issues
   - 描述问题和环境
   - 附加日志和截图

4. **讨论**
   - GitHub Discussions
   - 与社区交流

### Q22: 如何贡献代码？

**A**: 欢迎贡献！

1. **Fork 仓库**
2. **创建特性分支**
   ```bash
   git checkout -b feature/your-feature
   ```
3. **提交更改**
   ```bash
   git commit -m "Add your feature"
   ```
4. **推送分支**
   ```bash
   git push origin feature/your-feature
   ```
5. **开启 Pull Request**

### Q23: 项目许可证是什么？

**A**: 本项目采用 **MIT 许可证**。

您可以自由使用、修改和分发本项目，但需要保留许可证声明。

详见 [LICENSE](../LICENSE) 文件。

### Q24: 如何报告 Bug？

**A**: 提交 Issue 时请包含：

1. **环境信息**
   - iPad 型号和 iOS 版本
   - UTM 版本
   - Debian 版本

2. **问题描述**
   - 问题现象
   - 重现步骤
   - 预期结果

3. **日志信息**
   - 编译日志
   - 虚拟机日志
   - 错误信息

4. **截图**
   - 错误界面
   - 配置设置

### Q25: 项目的未来计划是什么？

**A**: 短期和中期计划：

**短期（1-3 个月）**：
- 添加 CI/CD 工作流
- 创建视频教程
- 支持更多设备

**中期（3-6 个月）**：
- 支持 Android 16
- 支持 x86_64 架构
- 创建预编译镜像

**长期（6-12 个月）**：
- 云编译支持
- 社区镜像库
- 自动化测试框架

---

## 快速链接

| 资源 | 链接 |
|------|------|
| 快速开始 | [QUICKSTART.md](QUICKSTART.md) |
| 编译指南 | [BUILD_GUIDE.md](BUILD_GUIDE.md) |
| 优化指南 | [OPTIMIZATION_GUIDE.md](OPTIMIZATION_GUIDE.md) |
| 故障排查 | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| 快速参考 | [QUICK_REFERENCE.md](QUICK_REFERENCE.md) |
| 脚本指南 | [SCRIPTS_GUIDE.md](SCRIPTS_GUIDE.md) |
| 系统架构 | [ARCHITECTURE.md](../ARCHITECTURE.md) |
| 开发日志 | [DEVELOPMENT_LOG.md](../DEVELOPMENT_LOG.md) |

---

**最后更新**: 2026 年 1 月 27 日  
**维护者**: Manus AI

如果您有其他问题，欢迎提交 Issue 或 Discussion！

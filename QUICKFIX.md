# ⚡ 快速修复指南 v1.2.1

## 🚨 如果您遇到编译错误

### 错误信息
```
FAILED: ninja: unknown target 'lineage-install'
```

或

```
error: Cannot locate config makefile for product "virtio_arm64"
```

### 立即修复

```bash
# 1. 拉取最新修复
cd ~/android15-utm-ipad-builder
git pull

# 2. 重新运行编译
bash scripts/03-build-android.sh
```

---

## ✅ 修复内容 (v1.2.1)

### 主要变更

1. **使用 `breakfast` 代替 `lunch`**
   ```bash
   # 旧方式 ❌
   lunch "virtio_arm64-ap3a-user"
   
   # 新方式 ✅
   breakfast virtio_arm64
   ```

2. **使用 `m vm-utm-zip` 代替 `m lineage-install`**
   ```bash
   # 旧方式 ❌
   m lineage-install
   
   # 新方式 ✅
   m vm-utm-zip
   ```

3. **修复错误检测逻辑**
   - 现在能正确检测编译失败
   - 使用 `PIPESTATUS` 捕获真实的退出码

4. **修复产物验证逻辑**
   - 检查 `UTM-VM-lineage-*.zip` 文件
   - 而不是 `system.img` 等传统镜像

---

## 📝 手动编译（如果自动脚本失败）

```bash
# 1. 进入源代码目录
cd ~/android/lineage

# 2. 设置环境
source build/envsetup.sh

# 3. 选择目标
breakfast virtio_arm64

# 4. 开始编译
m vm-utm-zip
```

---

## 🎯 预期结果

编译完成后，您会看到：

```
#### build completed successfully (XX:XX (mm:ss)) ####
```

镜像文件位于：
```
~/android/lineage/out/target/product/virtio_arm64/UTM/UTM-VM-lineage-23.0-YYYYMMDD-UNOFFICIAL-virtio_arm64.zip
```

---

## 📚 详细文档

- 完整修复说明: [CRITICAL_FIX_GUIDE.md](CRITICAL_FIX_GUIDE.md)
- 故障排查: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- 编译指南: [docs/BUILD_GUIDE.md](docs/BUILD_GUIDE.md)

---

**版本**: v1.2.1  
**日期**: 2026-01-27  
**修复**: 正确的编译命令和错误检测

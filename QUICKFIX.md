# ⚡ 快速修复指南

## 🚨 如果您遇到编译错误

### 错误信息
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

## ✅ 修复内容

### 主要变更

1. **使用 `breakfast` 代替 `lunch`**
   ```bash
   # 旧方式 ❌
   lunch "virtio_arm64-ap3a-user"
   
   # 新方式 ✅
   breakfast virtio_arm64
   ```

2. **使用 `m lineage-install` 代替 `m -j`**
   ```bash
   # 旧方式 ❌
   m -j$(nproc)
   
   # 新方式 ✅
   m lineage-install
   ```

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
m lineage-install
```

---

## 🎯 预期结果

编译完成后，您会看到：

```
#### build completed successfully (XX:XX (mm:ss)) ####
```

镜像文件位于：
```
~/android/lineage/out/target/product/virtio_arm64/lineage-23.0-YYYYMMDD-UNOFFICIAL-virtio_arm64.img
```

---

## 📚 详细文档

- 完整修复说明: [CRITICAL_FIX_GUIDE.md](CRITICAL_FIX_GUIDE.md)
- 故障排查: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- 编译指南: [docs/BUILD_GUIDE.md](docs/BUILD_GUIDE.md)

---

**版本**: v1.2.0  
**日期**: 2026-01-27

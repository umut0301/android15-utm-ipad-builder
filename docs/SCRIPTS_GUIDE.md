# UTM 优化调优实操脚本和命令集合

## 目录
1. [编译产物优化脚本](#编译产物优化脚本)
2. [虚拟机导入脚本](#虚拟机导入脚本)
3. [存储管理脚本](#存储管理脚本)
4. [性能测试脚本](#性能测试脚本)
5. [故障诊断脚本](#故障诊断脚本)

---

## 编译产物优化脚本

### 脚本 1：编译产物瘦身脚本

```bash
#!/bin/bash
# 文件名: optimize_build_output.sh
# 功能: 优化 Android 编译产物，减少大小

set -e

LINEAGE_DIR="${HOME}/android/lineage"
PRODUCT_DIR="${LINEAGE_DIR}/out/target/product/virtio_arm64"
BACKUP_DIR="${PRODUCT_DIR}/backup_$(date +%Y%m%d_%H%M%S)"

echo "=========================================="
echo "Android 编译产物优化脚本"
echo "=========================================="

# 1. 备份原始文件
echo "[1/5] 备份原始文件..."
mkdir -p "${BACKUP_DIR}"
cp "${PRODUCT_DIR}"/*.img "${BACKUP_DIR}/" 2>/dev/null || true
echo "✓ 备份完成: ${BACKUP_DIR}"

# 2. 清理编译中间文件
echo "[2/5] 清理编译中间文件..."
cd "${LINEAGE_DIR}"
make clean
echo "✓ 中间文件已清理"

# 3. 压缩 system.img
echo "[3/5] 压缩 system.img..."
if [ -f "${PRODUCT_DIR}/system.img" ]; then
    ORIGINAL_SIZE=$(du -h "${PRODUCT_DIR}/system.img" | cut -f1)
    echo "  原始大小: ${ORIGINAL_SIZE}"
    
    # 转换为 qcow2 格式并压缩
    qemu-img convert -O qcow2 -c \
        "${PRODUCT_DIR}/system.img" \
        "${PRODUCT_DIR}/system-compressed.qcow2"
    
    COMPRESSED_SIZE=$(du -h "${PRODUCT_DIR}/system-compressed.qcow2" | cut -f1)
    echo "  压缩后大小: ${COMPRESSED_SIZE}"
    
    # 替换原文件
    mv "${PRODUCT_DIR}/system.img" "${PRODUCT_DIR}/system.img.bak"
    mv "${PRODUCT_DIR}/system-compressed.qcow2" "${PRODUCT_DIR}/system.img"
    echo "✓ system.img 已压缩"
fi

# 4. 压缩 vendor.img
echo "[4/5] 压缩 vendor.img..."
if [ -f "${PRODUCT_DIR}/vendor.img" ]; then
    ORIGINAL_SIZE=$(du -h "${PRODUCT_DIR}/vendor.img" | cut -f1)
    echo "  原始大小: ${ORIGINAL_SIZE}"
    
    qemu-img convert -O qcow2 -c \
        "${PRODUCT_DIR}/vendor.img" \
        "${PRODUCT_DIR}/vendor-compressed.qcow2"
    
    COMPRESSED_SIZE=$(du -h "${PRODUCT_DIR}/vendor-compressed.qcow2" | cut -f1)
    echo "  压缩后大小: ${COMPRESSED_SIZE}"
    
    mv "${PRODUCT_DIR}/vendor.img" "${PRODUCT_DIR}/vendor.img.bak"
    mv "${PRODUCT_DIR}/vendor-compressed.qcow2" "${PRODUCT_DIR}/vendor.img"
    echo "✓ vendor.img 已压缩"
fi

# 5. 生成优化后的 ZIP 包
echo "[5/5] 生成优化后的 ZIP 包..."
cd "${PRODUCT_DIR}"

# 创建新的 ZIP 包
ZIP_NAME="VirtuaMachine-utm-lineage-optimized-$(date +%Y%m%d).zip"
zip -r -9 "${ZIP_NAME}" \
    system.img vendor.img boot.img \
    2>/dev/null || true

echo "✓ 优化完成"
echo ""
echo "=========================================="
echo "优化结果:"
echo "=========================================="
echo "原始 ZIP 大小: $(du -h VirtuaMachine-utm-*.zip | head -1 | cut -f1)"
echo "优化 ZIP 大小: $(du -h ${ZIP_NAME} | cut -f1)"
echo "优化文件位置: ${PRODUCT_DIR}/${ZIP_NAME}"
echo ""
echo "备份位置: ${BACKUP_DIR}"
echo "=========================================="
```

**使用方法**：
```bash
chmod +x optimize_build_output.sh
./optimize_build_output.sh
```

### 脚本 2：编译版本选择和优化

```bash
#!/bin/bash
# 文件名: build_optimized_android.sh
# 功能: 编译优化版本的 Android 15

set -e

LINEAGE_DIR="${HOME}/android/lineage"

echo "=========================================="
echo "Android 15 优化编译脚本"
echo "=========================================="

cd "${LINEAGE_DIR}"

# 选择编译版本
echo ""
echo "选择编译版本:"
echo "1) user      - 优化版本（推荐，更小）"
echo "2) userdebug - 调试版本（更大，包含符号）"
read -p "请选择 [1-2]: " BUILD_TYPE

case ${BUILD_TYPE} in
    1)
        BUILD_VARIANT="user"
        echo "✓ 选择: user 版本"
        ;;
    2)
        BUILD_VARIANT="userdebug"
        echo "✓ 选择: userdebug 版本"
        ;;
    *)
        echo "✗ 无效选择，使用默认 user 版本"
        BUILD_VARIANT="user"
        ;;
esac

# 设置编译环境
echo ""
echo "[1/4] 设置编译环境..."
source build/envsetup.sh
lunch virtio_arm64-${BUILD_VARIANT}

# 启用优化
echo "[2/4] 启用编译优化..."
export USE_CACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export DISABLE_PROGUARD=false  # 启用代码混淆和优化

# 清理旧编译
echo "[3/4] 清理旧编译..."
make clean

# 开始编译
echo "[4/4] 开始编译..."
START_TIME=$(date +%s)

m -j$(nproc) 2>&1 | tee build_$(date +%Y%m%d_%H%M%S).log

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
HOURS=$((DURATION / 3600))
MINUTES=$(((DURATION % 3600) / 60))

echo ""
echo "=========================================="
echo "编译完成!"
echo "=========================================="
echo "编译版本: ${BUILD_VARIANT}"
echo "编译耗时: ${HOURS}h ${MINUTES}m"
echo "产物位置: ${LINEAGE_DIR}/out/target/product/virtio_arm64/"
echo ""
echo "产物文件:"
ls -lh out/target/product/virtio_arm64/*.{img,zip} 2>/dev/null | tail -5
echo "=========================================="
```

**使用方法**：
```bash
chmod +x build_optimized_android.sh
./build_optimized_android.sh
```

---

## 虚拟机导入脚本

### 脚本 3：虚拟机镜像传输脚本

```bash
#!/bin/bash
# 文件名: transfer_to_ipad.sh
# 功能: 将编译产物传输到 iPad

set -e

LINEAGE_DIR="${HOME}/android/lineage"
PRODUCT_DIR="${LINEAGE_DIR}/out/target/product/virtio_arm64"

echo "=========================================="
echo "虚拟机镜像传输脚本"
echo "=========================================="

# 检查文件
echo "[1/3] 检查编译产物..."
if [ ! -f "${PRODUCT_DIR}/VirtuaMachine-utm-"*.zip ]; then
    echo "✗ 错误: 未找到虚拟机镜像文件"
    exit 1
fi

ZIP_FILE=$(ls -t "${PRODUCT_DIR}"/VirtuaMachine-utm-*.zip | head -1)
ZIP_SIZE=$(du -h "${ZIP_FILE}" | cut -f1)

echo "✓ 找到镜像文件: $(basename ${ZIP_FILE})"
echo "  文件大小: ${ZIP_SIZE}"

# 选择传输方式
echo ""
echo "[2/3] 选择传输方式:"
echo "1) HTTP 服务器（推荐）"
echo "2) 复制到共享文件夹"
echo "3) 生成校验和并显示路径"
read -p "请选择 [1-3]: " TRANSFER_METHOD

case ${TRANSFER_METHOD} in
    1)
        echo "✓ 启动 HTTP 服务器..."
        cd "${PRODUCT_DIR}"
        echo ""
        echo "=========================================="
        echo "HTTP 服务器已启动"
        echo "=========================================="
        echo "在 iPad 浏览器中访问:"
        
        # 获取本机 IP
        IP=$(hostname -I | awk '{print $1}')
        echo "http://${IP}:8000/"
        echo ""
        echo "按 Ctrl+C 停止服务器"
        echo "=========================================="
        
        python3 -m http.server 8000
        ;;
    2)
        echo "✓ 复制到共享文件夹..."
        SHARED_DIR="/mnt/shared"
        if [ -d "${SHARED_DIR}" ]; then
            cp "${ZIP_FILE}" "${SHARED_DIR}/"
            echo "✓ 文件已复制到: ${SHARED_DIR}"
        else
            echo "✗ 错误: 共享文件夹不存在"
            exit 1
        fi
        ;;
    3)
        echo "✓ 生成校验和..."
        cd "${PRODUCT_DIR}"
        md5sum "$(basename ${ZIP_FILE})" > "$(basename ${ZIP_FILE}).md5"
        echo "✓ 校验和已生成"
        echo ""
        echo "文件路径: ${ZIP_FILE}"
        echo "校验和文件: ${ZIP_FILE}.md5"
        echo ""
        cat "$(basename ${ZIP_FILE}).md5"
        ;;
    *)
        echo "✗ 无效选择"
        exit 1
        ;;
esac

echo ""
echo "[3/3] 传输完成"
echo "=========================================="
```

**使用方法**：
```bash
chmod +x transfer_to_ipad.sh
./transfer_to_ipad.sh
```

### 脚本 4：虚拟机配置检查脚本

```bash
#!/bin/bash
# 文件名: check_utm_config.sh
# 功能: 检查 UTM 虚拟机配置是否符合最优设置

echo "=========================================="
echo "UTM 虚拟机配置检查脚本"
echo "=========================================="

# 检查 UTM 配置文件（macOS 上）
UTM_CONFIG_DIR="${HOME}/Library/Containers/com.utmapp.UTM/Data/Documents"

if [ ! -d "${UTM_CONFIG_DIR}" ]; then
    echo "✗ 未找到 UTM 配置目录"
    echo "  请确保已安装 UTM 并创建了虚拟机"
    exit 1
fi

echo "✓ 找到 UTM 配置目录"
echo ""

# 列出所有虚拟机
echo "已安装的虚拟机:"
ls -1 "${UTM_CONFIG_DIR}" | grep -E "\.utm$" | while read vm; do
    echo "  - ${vm%.*}"
done

echo ""
echo "=========================================="
echo "推荐配置检查清单:"
echo "=========================================="
echo ""
echo "□ 显示设备: virtio-gpu-gl-pci (GPU Supported)"
echo "□ 渲染器: ANGLE (Metal)"
echo "□ CPU 核心: 6-8"
echo "□ 内存: 4-6GB"
echo "□ 系统磁盘: 30-50GB"
echo "□ 虚拟化: 启用"
echo "□ UEFI: 启用"
echo "□ Retina 模式: 禁用"
echo ""
echo "=========================================="
echo "提示: 在 UTM 应用中手动检查上述配置"
echo "=========================================="
```

**使用方法**：
```bash
chmod +x check_utm_config.sh
./check_utm_config.sh
```

---

## 存储管理脚本

### 脚本 5：虚拟机磁盘管理脚本

```bash
#!/bin/bash
# 文件名: manage_vm_storage.sh
# 功能: 管理虚拟机磁盘大小和格式

set -e

echo "=========================================="
echo "虚拟机磁盘管理脚本"
echo "=========================================="

echo ""
echo "选择操作:"
echo "1) 创建新的 qcow2 磁盘"
echo "2) 扩展现有磁盘"
echo "3) 压缩 qcow2 磁盘"
echo "4) 转换磁盘格式"
echo "5) 查看磁盘信息"
read -p "请选择 [1-5]: " OPERATION

case ${OPERATION} in
    1)
        echo ""
        read -p "输入磁盘文件名: " DISK_NAME
        read -p "输入磁盘大小 (GB): " DISK_SIZE
        
        echo "创建 ${DISK_SIZE}GB qcow2 磁盘: ${DISK_NAME}"
        qemu-img create -f qcow2 "${DISK_NAME}" "${DISK_SIZE}G"
        
        echo "✓ 磁盘已创建"
        qemu-img info "${DISK_NAME}"
        ;;
    2)
        echo ""
        read -p "输入磁盘文件路径: " DISK_PATH
        read -p "输入增加的大小 (GB): " ADD_SIZE
        
        if [ ! -f "${DISK_PATH}" ]; then
            echo "✗ 文件不存在: ${DISK_PATH}"
            exit 1
        fi
        
        echo "扩展磁盘 +${ADD_SIZE}GB..."
        qemu-img resize "${DISK_PATH}" "+${ADD_SIZE}G"
        
        echo "✓ 磁盘已扩展"
        qemu-img info "${DISK_PATH}"
        ;;
    3)
        echo ""
        read -p "输入 qcow2 磁盘文件路径: " DISK_PATH
        
        if [ ! -f "${DISK_PATH}" ]; then
            echo "✗ 文件不存在: ${DISK_PATH}"
            exit 1
        fi
        
        ORIGINAL_SIZE=$(du -h "${DISK_PATH}" | cut -f1)
        COMPRESSED_PATH="${DISK_PATH}.compressed"
        
        echo "压缩磁盘..."
        echo "原始大小: ${ORIGINAL_SIZE}"
        
        qemu-img convert -O qcow2 -c "${DISK_PATH}" "${COMPRESSED_PATH}"
        
        COMPRESSED_SIZE=$(du -h "${COMPRESSED_PATH}" | cut -f1)
        echo "压缩后大小: ${COMPRESSED_SIZE}"
        
        read -p "是否替换原文件? (y/n): " REPLACE
        if [ "${REPLACE}" = "y" ]; then
            mv "${DISK_PATH}" "${DISK_PATH}.bak"
            mv "${COMPRESSED_PATH}" "${DISK_PATH}"
            echo "✓ 磁盘已压缩并替换"
        fi
        ;;
    4)
        echo ""
        read -p "输入源磁盘文件路径: " SOURCE_DISK
        read -p "输入目标格式 (qcow2/raw/vmdk): " TARGET_FORMAT
        read -p "输入目标文件名: " TARGET_DISK
        
        if [ ! -f "${SOURCE_DISK}" ]; then
            echo "✗ 文件不存在: ${SOURCE_DISK}"
            exit 1
        fi
        
        echo "转换磁盘格式..."
        qemu-img convert -O "${TARGET_FORMAT}" "${SOURCE_DISK}" "${TARGET_DISK}"
        
        echo "✓ 转换完成"
        qemu-img info "${TARGET_DISK}"
        ;;
    5)
        echo ""
        read -p "输入磁盘文件路径: " DISK_PATH
        
        if [ ! -f "${DISK_PATH}" ]; then
            echo "✗ 文件不存在: ${DISK_PATH}"
            exit 1
        fi
        
        echo "磁盘信息:"
        qemu-img info "${DISK_PATH}"
        
        echo ""
        echo "磁盘占用空间:"
        du -h "${DISK_PATH}"
        ;;
    *)
        echo "✗ 无效选择"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
```

**使用方法**：
```bash
chmod +x manage_vm_storage.sh
./manage_vm_storage.sh
```

---

## 性能测试脚本

### 脚本 6：虚拟机性能测试脚本

```bash
#!/bin/bash
# 文件名: benchmark_vm.sh
# 功能: 测试虚拟机性能

echo "=========================================="
echo "虚拟机性能测试脚本"
echo "=========================================="

# 检查 adb 连接
echo "[1/5] 检查 ADB 连接..."
if ! adb devices | grep -q "device"; then
    echo "✗ 未找到连接的设备"
    echo "请先连接虚拟机: adb connect <vm-ip>:5555"
    exit 1
fi

echo "✓ 已连接设备"

# CPU 性能测试
echo ""
echo "[2/5] CPU 性能测试..."
adb shell "time dd if=/dev/zero of=/data/test.bin bs=1M count=100"

# 内存测试
echo ""
echo "[3/5] 内存信息..."
adb shell "free -h"

# 存储测试
echo ""
echo "[4/5] 存储性能测试..."
adb shell "time dd if=/dev/zero of=/data/test2.bin bs=1M count=50"

# 清理测试文件
echo ""
echo "[5/5] 清理测试文件..."
adb shell "rm -f /data/test*.bin"

echo ""
echo "=========================================="
echo "性能测试完成"
echo "=========================================="
```

**使用方法**：
```bash
chmod +x benchmark_vm.sh
./benchmark_vm.sh
```

---

## 故障诊断脚本

### 脚本 7：虚拟机故障诊断脚本

```bash
#!/bin/bash
# 文件名: diagnose_vm_issues.sh
# 功能: 诊断虚拟机常见问题

echo "=========================================="
echo "虚拟机故障诊断脚本"
echo "=========================================="

echo ""
echo "诊断项目:"
echo "1) 检查 ADB 连接"
echo "2) 检查存储空间"
echo "3) 检查内存使用"
echo "4) 检查网络连接"
echo "5) 查看系统日志"
echo "6) 完整诊断"
read -p "请选择 [1-6]: " DIAGNOSTIC

case ${DIAGNOSTIC} in
    1)
        echo ""
        echo "检查 ADB 连接..."
        adb devices
        ;;
    2)
        echo ""
        echo "检查存储空间..."
        adb shell "df -h"
        
        echo ""
        echo "检查目录大小..."
        adb shell "du -sh /data/* /system/* 2>/dev/null | sort -h"
        ;;
    3)
        echo ""
        echo "检查内存使用..."
        adb shell "free -h"
        
        echo ""
        echo "检查进程内存..."
        adb shell "ps aux | head -20"
        ;;
    4)
        echo ""
        echo "检查网络连接..."
        adb shell "ifconfig"
        
        echo ""
        echo "测试网络..."
        adb shell "ping -c 4 8.8.8.8"
        ;;
    5)
        echo ""
        echo "查看系统日志（最后 100 行）..."
        adb logcat -d | tail -100
        ;;
    6)
        echo ""
        echo "========== 完整诊断 =========="
        
        echo ""
        echo "1. ADB 连接状态:"
        adb devices
        
        echo ""
        echo "2. 存储空间:"
        adb shell "df -h"
        
        echo ""
        echo "3. 内存使用:"
        adb shell "free -h"
        
        echo ""
        echo "4. 网络连接:"
        adb shell "ifconfig"
        
        echo ""
        echo "5. 系统属性:"
        adb shell "getprop ro.build.version.release"
        adb shell "getprop ro.build.version.sdk"
        
        echo ""
        echo "6. 最近错误:"
        adb logcat -d | grep -i "error" | tail -10
        ;;
    *)
        echo "✗ 无效选择"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
```

**使用方法**：
```bash
chmod +x diagnose_vm_issues.sh
./diagnose_vm_issues.sh
```

---

## 快速命令参考

### 编译相关

```bash
# 编译优化版本
cd ~/android/lineage
source build/envsetup.sh
lunch virtio_arm64-user
m -j$(nproc)

# 编译特定模块
m SystemUI

# 清理编译
make clean
make distclean
```

### 文件传输

```bash
# 启动 HTTP 服务器
cd ~/android/lineage/out/target/product/virtio_arm64/
python3 -m http.server 8000

# 使用 scp 传输
scp ~/android/lineage/out/target/product/virtio_arm64/VirtuaMachine-utm-*.zip user@host:/path/

# 生成校验和
md5sum VirtuaMachine-utm-*.zip > VirtuaMachine-utm-*.zip.md5
```

### 磁盘管理

```bash
# 创建 qcow2 磁盘
qemu-img create -f qcow2 disk.qcow2 50G

# 扩展磁盘
qemu-img resize disk.qcow2 +20G

# 压缩 qcow2
qemu-img convert -O qcow2 -c disk.qcow2 disk-compressed.qcow2

# 查看磁盘信息
qemu-img info disk.qcow2
```

### 虚拟机管理

```bash
# 连接虚拟机
adb connect <vm-ip>:5555

# 查看设备
adb devices

# 查看存储
adb shell df -h

# 清理缓存
adb shell pm trim-caches 1024M

# 查看日志
adb logcat
```

---

## 最后更新

**日期**: 2026 年 1 月 27 日  
**脚本版本**: 1.0  
**兼容平台**: macOS + Debian 12 + iPad Pro M1  

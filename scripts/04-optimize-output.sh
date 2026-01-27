#!/bin/bash

################################################################################
# 编译产物优化脚本
# 功能: 压缩镜像、清理中间文件、生成优化包
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
WORK_DIR="$HOME/android/lineage"
BUILD_TARGET="virtio_arm64"
OUTPUT_DIR="$WORK_DIR/out/target/product/$BUILD_TARGET"
OPTIMIZED_DIR="$HOME/android/optimized_$(date +%Y%m%d_%H%M%S)"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查编译产物
check_build_output() {
    log_info "检查编译产物..."
    
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        log_error "编译产物目录不存在: $OUTPUT_DIR"
        log_error "请先运行: bash scripts/03-build-android.sh"
        exit 1
    fi
    
    if [[ ! -f "$OUTPUT_DIR/system.img" ]]; then
        log_error "未找到 system.img"
        log_error "请先完成编译"
        exit 1
    fi
    
    log_success "编译产物检查通过"
}

# 检查磁盘空间
check_disk_space() {
    log_info "检查磁盘空间..."
    
    AVAILABLE_SPACE=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    REQUIRED_SPACE=50
    
    if [[ $AVAILABLE_SPACE -lt $REQUIRED_SPACE ]]; then
        log_error "磁盘空间不足！"
        log_error "需要: ${REQUIRED_SPACE}GB, 可用: ${AVAILABLE_SPACE}GB"
        exit 1
    fi
    
    log_success "磁盘空间充足: ${AVAILABLE_SPACE}GB 可用"
}

# 创建优化目录
create_optimized_dir() {
    log_info "创建优化目录..."
    
    mkdir -p "$OPTIMIZED_DIR"
    
    log_success "优化目录: $OPTIMIZED_DIR"
}

# 压缩镜像文件
compress_images() {
    log_info "压缩镜像文件..."
    log_warning "这可能需要 10-20 分钟..."
    
    cd "$OUTPUT_DIR"
    
    # 压缩 system.img
    if [[ -f "system.img" ]]; then
        log_info "压缩 system.img..."
        qemu-img convert -O qcow2 -c system.img "$OPTIMIZED_DIR/system.qcow2"
        
        ORIGINAL_SIZE=$(du -h system.img | cut -f1)
        COMPRESSED_SIZE=$(du -h "$OPTIMIZED_DIR/system.qcow2" | cut -f1)
        log_success "system.img: $ORIGINAL_SIZE -> $COMPRESSED_SIZE"
    fi
    
    # 复制其他关键文件（不压缩）
    for file in vendor.img boot.img ramdisk.img; do
        if [[ -f "$file" ]]; then
            log_info "复制 $file..."
            cp "$file" "$OPTIMIZED_DIR/"
            FILE_SIZE=$(du -h "$OPTIMIZED_DIR/$file" | cut -f1)
            log_success "$file: $FILE_SIZE"
        fi
    done
}

# 查找并复制 UTM 虚拟机包
copy_utm_package() {
    log_info "查找 UTM 虚拟机包..."
    
    cd "$OUTPUT_DIR"
    
    UTM_PACKAGE=$(find . -name "VirtuaMachine-utm-*.zip" | head -n 1)
    
    if [[ -n "$UTM_PACKAGE" ]]; then
        log_info "复制 UTM 虚拟机包..."
        cp "$UTM_PACKAGE" "$OPTIMIZED_DIR/"
        
        UTM_SIZE=$(du -h "$OPTIMIZED_DIR/$(basename "$UTM_PACKAGE")" | cut -f1)
        log_success "UTM 包: $UTM_SIZE"
    else
        log_warning "未找到 UTM 虚拟机包"
    fi
}

# 生成校验和
generate_checksums() {
    log_info "生成校验和..."
    
    cd "$OPTIMIZED_DIR"
    
    # 生成 MD5
    md5sum * > checksums.md5 2>/dev/null || true
    
    # 生成 SHA256
    sha256sum * > checksums.sha256 2>/dev/null || true
    
    log_success "校验和文件已生成"
}

# 创建优化包
create_optimized_package() {
    log_info "创建优化包..."
    log_warning "这可能需要几分钟..."
    
    PACKAGE_NAME="android15-utm-optimized-$(date +%Y%m%d_%H%M%S).tar.gz"
    
    cd "$HOME/android"
    
    tar -czf "$PACKAGE_NAME" -C "$(dirname "$OPTIMIZED_DIR")" "$(basename "$OPTIMIZED_DIR")"
    
    PACKAGE_SIZE=$(du -h "$PACKAGE_NAME" | cut -f1)
    log_success "优化包已创建: $PACKAGE_NAME ($PACKAGE_SIZE)"
    
    echo "$HOME/android/$PACKAGE_NAME"
}

# 清理中间文件（可选）
clean_intermediate_files() {
    log_info "是否清理编译中间文件？"
    log_warning "这将释放 50-100GB 空间，但会导致下次完整重新编译"
    read -p "是否清理? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "清理中间文件..."
        
        cd "$WORK_DIR"
        
        # 清理 obj 目录
        if [[ -d "out/target/product/$BUILD_TARGET/obj" ]]; then
            rm -rf "out/target/product/$BUILD_TARGET/obj"
            log_success "已清理 obj 目录"
        fi
        
        # 清理符号文件
        if [[ -d "out/target/product/$BUILD_TARGET/symbols" ]]; then
            rm -rf "out/target/product/$BUILD_TARGET/symbols"
            log_success "已清理 symbols 目录"
        fi
        
        # 清理 ccache（可选）
        read -p "是否清理 ccache 缓存? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ccache -C
            log_success "已清理 ccache"
        fi
        
        log_success "中间文件清理完成"
    else
        log_info "跳过清理"
    fi
}

# 显示优化统计
show_optimization_stats() {
    log_info "优化统计..."
    
    # 原始大小
    ORIGINAL_SIZE=$(du -sh "$OUTPUT_DIR" | cut -f1)
    
    # 优化后大小
    OPTIMIZED_SIZE=$(du -sh "$OPTIMIZED_DIR" | cut -f1)
    
    echo ""
    echo "========================================"
    echo "  优化统计"
    echo "========================================"
    echo "  原始编译产物: $ORIGINAL_SIZE"
    echo "  优化后大小: $OPTIMIZED_SIZE"
    echo ""
    echo "  优化目录: $OPTIMIZED_DIR"
    echo ""
    
    # 列出优化后的文件
    echo "  优化后的文件:"
    cd "$OPTIMIZED_DIR"
    ls -lh | grep -v "^total" | awk '{print "    " $9 ": " $5}'
    
    echo "========================================"
    echo ""
}

# 显示摘要
show_summary() {
    echo ""
    echo "========================================"
    echo "  编译产物优化完成"
    echo "========================================"
    echo ""
    echo "优化目录:"
    echo "  $OPTIMIZED_DIR"
    echo ""
    echo "包含文件:"
    echo "  - system.qcow2 (压缩后的系统镜像)"
    echo "  - vendor.img, boot.img, ramdisk.img"
    echo "  - VirtuaMachine-utm-*.zip (如果存在)"
    echo "  - checksums.md5, checksums.sha256"
    echo ""
    echo "下一步:"
    echo "  1. 传输到 iPad:"
    echo "     bash scripts/05-transfer-to-ipad.sh"
    echo ""
    echo "  2. 或手动传输:"
    echo "     cd $OPTIMIZED_DIR"
    echo "     python3 -m http.server 8000"
    echo ""
    echo "========================================"
}

# 主函数
main() {
    echo ""
    echo "========================================"
    echo "  编译产物优化"
    echo "========================================"
    echo ""
    
    check_build_output
    check_disk_space
    
    echo ""
    log_info "开始优化..."
    echo ""
    
    create_optimized_dir
    compress_images
    copy_utm_package
    generate_checksums
    
    echo ""
    
    show_optimization_stats
    
    echo ""
    
    clean_intermediate_files
    
    show_summary
}

# 运行主函数
main

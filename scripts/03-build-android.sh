#!/bin/bash

################################################################################
# Android 15 自动化编译脚本
# 功能: 编译 virtio_arm64-user 版本的 Android 15
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
BUILD_VARIANT="user"
LOG_FILE="$HOME/android/build_$(date +%Y%m%d_%H%M%S).log"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# 检查源代码
check_source() {
    log_info "检查源代码..."
    
    if [[ ! -d "$WORK_DIR" ]]; then
        log_error "源代码目录不存在: $WORK_DIR"
        log_error "请先运行: bash scripts/02-sync-source.sh"
        exit 1
    fi
    
    if [[ ! -d "$WORK_DIR/.repo" ]]; then
        log_error "源代码未初始化"
        log_error "请先运行: bash scripts/02-sync-source.sh"
        exit 1
    fi
    
    log_success "源代码检查通过"
}

# 检查磁盘空间
check_disk_space() {
    log_info "检查磁盘空间..."
    
    AVAILABLE_SPACE=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    REQUIRED_SPACE=100
    
    if [[ $AVAILABLE_SPACE -lt $REQUIRED_SPACE ]]; then
        log_error "磁盘空间不足！"
        log_error "需要: ${REQUIRED_SPACE}GB, 可用: ${AVAILABLE_SPACE}GB"
        exit 1
    fi
    
    log_success "磁盘空间充足: ${AVAILABLE_SPACE}GB 可用"
}

# 检查内存
check_memory() {
    log_info "检查内存..."
    
    TOTAL_MEM=$(free -g | awk 'NR==2 {print $2}')
    REQUIRED_MEM=8
    
    if [[ $TOTAL_MEM -lt $REQUIRED_MEM ]]; then
        log_warning "内存不足！建议至少 16GB"
        log_warning "当前内存: ${TOTAL_MEM}GB"
        log_warning "编译可能会很慢或失败"
    else
        log_success "内存充足: ${TOTAL_MEM}GB"
    fi
}

# 清理旧的编译产物（可选）
clean_old_build() {
    log_info "是否清理旧的编译产物？"
    read -p "清理将释放空间但会导致完整重新编译 (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "清理编译产物..."
        cd "$WORK_DIR"
        # Android 编译系统不支持 'make clean'
        # 正确做法是删除 out 目录
        if [[ -d "$WORK_DIR/out" ]]; then
            rm -rf "$WORK_DIR/out"
            log_success "清理完成"
        else
            log_info "没有找到编译产物，跳过清理"
        fi
    else
        log_info "跳过清理，将进行增量编译"
    fi
}

# 设置编译环境
setup_build_env() {
    log_info "设置编译环境..."
    
    cd "$WORK_DIR"
    
    # 加载编译环境
    source build/envsetup.sh
    
    # 启用 ccache
    export USE_CCACHE=1
    export CCACHE_EXEC=/usr/bin/ccache
    export CCACHE_DIR=$HOME/.ccache
    
    log_success "编译环境设置完成"
}

# 选择编译目标
select_build_target() {
    log_info "选择编译目标..."
    
    cd "$WORK_DIR"
    
    # 显示可用目标
    log_info "可用的编译目标:"
    echo "  1. virtio_arm64-ap3a-user (推荐，体积小)"
    echo "  2. virtio_arm64-ap3a-userdebug (调试版本，体积大)"
    echo ""
    
    read -p "请选择 (1/2) [默认: 1]: " -n 1 -r
    echo
    
    if [[ $REPLY == "2" ]]; then
        BUILD_VARIANT="userdebug"
        log_info "选择: virtio_arm64-ap3a-userdebug"
    else
        BUILD_VARIANT="user"
        log_info "选择: virtio_arm64-ap3a-user"
    fi
    
    # 执行 lunch
    # Android 15 要求格式: <product>-<release>-<variant>
    # LineageOS 23.0 的 release 是 "ap3a"
    lunch "${BUILD_TARGET}-ap3a-${BUILD_VARIANT}"
    
    log_success "编译目标设置完成"
}

# 计算编译线程数
calculate_jobs() {
    CORES=$(nproc)
    TOTAL_MEM=$(free -g | awk 'NR==2 {print $2}')
    
    # 根据内存和 CPU 核心数计算最优线程数
    # 每个线程大约需要 2GB 内存
    MEM_JOBS=$((TOTAL_MEM / 2))
    
    if [[ $MEM_JOBS -lt $CORES ]]; then
        JOBS=$MEM_JOBS
    else
        JOBS=$CORES
    fi
    
    # 至少使用 2 个线程
    if [[ $JOBS -lt 2 ]]; then
        JOBS=2
    fi
    
    log_info "将使用 $JOBS 个并行编译线程"
    echo $JOBS
}

# 开始编译
start_build() {
    log_info "开始编译 Android 15..."
    log_warning "这可能需要 1-6 小时，取决于硬件配置"
    log_info "编译日志: $LOG_FILE"
    
    cd "$WORK_DIR"
    
    # 计算线程数
    JOBS=$(calculate_jobs)
    
    # 记录开始时间
    START_TIME=$(date +%s)
    
    # 开始编译
    log_info "执行: m -j$JOBS"
    
    if m -j$JOBS 2>&1 | tee -a "$LOG_FILE"; then
        # 计算耗时
        END_TIME=$(date +%s)
        ELAPSED=$((END_TIME - START_TIME))
        HOURS=$((ELAPSED / 3600))
        MINUTES=$(((ELAPSED % 3600) / 60))
        
        log_success "编译完成！"
        log_info "耗时: ${HOURS}小时 ${MINUTES}分钟"
    else
        log_error "编译失败！"
        log_error "请查看日志: $LOG_FILE"
        exit 1
    fi
}

# 验证编译产物
verify_build() {
    log_info "验证编译产物..."
    
    cd "$WORK_DIR"
    
    OUTPUT_DIR="out/target/product/${BUILD_TARGET}"
    
    # 检查关键文件
    CRITICAL_FILES=(
        "system.img"
        "vendor.img"
        "boot.img"
        "ramdisk.img"
    )
    
    ERRORS=0
    for file in "${CRITICAL_FILES[@]}"; do
        if [[ ! -f "$OUTPUT_DIR/$file" ]]; then
            log_error "缺少关键文件: $file"
            ERRORS=$((ERRORS + 1))
        else
            FILE_SIZE=$(du -h "$OUTPUT_DIR/$file" | cut -f1)
            log_success "$file ($FILE_SIZE)"
        fi
    done
    
    if [[ $ERRORS -gt 0 ]]; then
        log_error "编译产物验证失败，发现 $ERRORS 个错误"
        exit 1
    fi
    
    log_success "编译产物验证通过"
}

# 显示编译产物信息
show_build_info() {
    log_info "编译产物信息..."
    
    cd "$WORK_DIR"
    
    OUTPUT_DIR="out/target/product/${BUILD_TARGET}"
    
    # 统计总大小
    TOTAL_SIZE=$(du -sh "$OUTPUT_DIR" | cut -f1)
    
    # 查找 UTM 虚拟机包
    UTM_PACKAGE=$(find "$OUTPUT_DIR" -name "VirtuaMachine-utm-*.zip" | head -n 1)
    
    echo ""
    echo "========================================"
    echo "  编译产物信息"
    echo "========================================"
    echo "  输出目录: $OUTPUT_DIR"
    echo "  总大小: $TOTAL_SIZE"
    echo ""
    
    if [[ -n "$UTM_PACKAGE" ]]; then
        UTM_SIZE=$(du -h "$UTM_PACKAGE" | cut -f1)
        echo "  UTM 虚拟机包:"
        echo "    $(basename "$UTM_PACKAGE")"
        echo "    大小: $UTM_SIZE"
        echo ""
    fi
    
    echo "  关键镜像文件:"
    for img in system.img vendor.img boot.img; do
        if [[ -f "$OUTPUT_DIR/$img" ]]; then
            IMG_SIZE=$(du -h "$OUTPUT_DIR/$img" | cut -f1)
            echo "    $img: $IMG_SIZE"
        fi
    done
    echo "========================================"
    echo ""
}

# 显示摘要
show_summary() {
    echo ""
    echo "========================================"
    echo "  Android 15 编译完成"
    echo "========================================"
    echo ""
    echo "编译目标: ${BUILD_TARGET}-${BUILD_VARIANT}"
    echo "编译日志: $LOG_FILE"
    echo ""
    echo "编译产物位置:"
    echo "  $WORK_DIR/out/target/product/${BUILD_TARGET}/"
    echo ""
    echo "下一步:"
    echo "  1. 优化编译产物:"
    echo "     bash scripts/04-optimize-output.sh"
    echo ""
    echo "  2. 或手动打包:"
    echo "     cd $WORK_DIR/out/target/product/${BUILD_TARGET}/"
    echo "     ls -lh *.img"
    echo ""
    echo "========================================"
}

# 主函数
main() {
    echo ""
    echo "========================================"
    echo "  Android 15 自动化编译"
    echo "  目标: ${BUILD_TARGET}-${BUILD_VARIANT}"
    echo "========================================"
    echo ""
    
    # 创建日志文件
    touch "$LOG_FILE"
    log_info "编译日志: $LOG_FILE"
    
    check_source
    check_disk_space
    check_memory
    
    echo ""
    
    # 询问是否清理
    clean_old_build
    
    echo ""
    log_info "开始编译流程..."
    echo ""
    
    setup_build_env
    select_build_target
    start_build
    verify_build
    show_build_info
    
    show_summary
}

# 运行主函数
main

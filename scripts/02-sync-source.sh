#!/bin/bash

################################################################################
# LineageOS 23.0 源代码同步脚本
# 功能: 初始化 repo 并同步完整的 Android 15 源代码
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
LINEAGE_BRANCH="lineage-23.0"
WORK_DIR="$HOME/android/lineage"
REPO_URL="https://github.com/LineageOS/android.git"

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

# 检查 repo 工具
check_repo() {
    log_info "检查 repo 工具..."
    
    if ! command -v repo &> /dev/null; then
        log_error "repo 工具未找到"
        log_error "请先运行: sudo bash scripts/01-setup-build-env.sh"
        exit 1
    fi
    
    log_success "repo 工具已安装"
}

# 检查网络连接
check_network() {
    log_info "检查网络连接..."
    
    if ! ping -c 1 github.com &> /dev/null; then
        log_error "无法连接到 GitHub"
        log_error "请检查网络连接"
        exit 1
    fi
    
    log_success "网络连接正常"
}

# 检查磁盘空间
check_disk_space() {
    log_info "检查磁盘空间..."
    
    AVAILABLE_SPACE=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    REQUIRED_SPACE=200
    
    if [[ $AVAILABLE_SPACE -lt $REQUIRED_SPACE ]]; then
        log_error "磁盘空间不足！"
        log_error "需要: ${REQUIRED_SPACE}GB, 可用: ${AVAILABLE_SPACE}GB"
        exit 1
    fi
    
    log_success "磁盘空间充足: ${AVAILABLE_SPACE}GB 可用"
}

# 创建工作目录
create_work_dir() {
    log_info "创建工作目录..."
    
    if [[ ! -d "$WORK_DIR" ]]; then
        mkdir -p "$WORK_DIR"
        log_success "工作目录创建完成: $WORK_DIR"
    else
        log_info "工作目录已存在: $WORK_DIR"
    fi
}

# 初始化 repo
init_repo() {
    log_info "初始化 repo..."
    
    cd "$WORK_DIR"
    
    if [[ -d ".repo" ]]; then
        log_warning ".repo 目录已存在，跳过初始化"
        return
    fi
    
    log_info "这可能需要几分钟..."
    
    repo init \
        -u "$REPO_URL" \
        -b "$LINEAGE_BRANCH" \
        --git-lfs \
        --no-clone-bundle \
        --depth=1
    
    log_success "repo 初始化完成"
}

# 同步源代码
sync_source() {
    log_info "开始同步源代码..."
    log_warning "这可能需要 2-8 小时，取决于网络速度"
    
    cd "$WORK_DIR"
    
    # 获取 CPU 核心数
    CORES=$(nproc)
    JOBS=$((CORES < 4 ? CORES : 4))
    
    log_info "使用 $JOBS 个并行任务"
    
    # 记录开始时间
    START_TIME=$(date +%s)
    
    # 同步源代码
    repo sync -c -j$JOBS --force-sync --no-clone-bundle --no-tags
    
    # 计算耗时
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    HOURS=$((ELAPSED / 3600))
    MINUTES=$(((ELAPSED % 3600) / 60))
    
    log_success "源代码同步完成"
    log_info "耗时: ${HOURS}小时 ${MINUTES}分钟"
}

# 验证源代码
verify_source() {
    log_info "验证源代码..."
    
    cd "$WORK_DIR"
    
    # 检查关键目录
    CRITICAL_DIRS=(
        "build"
        "device"
        "kernel"
        "system"
        "vendor"
        "frameworks"
    )
    
    ERRORS=0
    for dir in "${CRITICAL_DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_error "缺少关键目录: $dir"
            ERRORS=$((ERRORS + 1))
        fi
    done
    
    if [[ $ERRORS -gt 0 ]]; then
        log_error "源代码验证失败，发现 $ERRORS 个错误"
        exit 1
    fi
    
    log_success "源代码验证通过"
}

# 显示统计信息
show_statistics() {
    log_info "统计源代码信息..."
    
    cd "$WORK_DIR"
    
    # 统计文件数量
    FILE_COUNT=$(find . -type f | wc -l)
    
    # 统计目录大小
    DIR_SIZE=$(du -sh . | cut -f1)
    
    # 统计 Git 仓库数量
    REPO_COUNT=$(find .repo/projects -name "*.git" | wc -l)
    
    echo ""
    echo "========================================"
    echo "  源代码统计信息"
    echo "========================================"
    echo "  文件数量: $FILE_COUNT"
    echo "  目录大小: $DIR_SIZE"
    echo "  Git 仓库: $REPO_COUNT"
    echo "========================================"
    echo ""
}

# 显示摘要
show_summary() {
    echo ""
    echo "========================================"
    echo "  LineageOS 23.0 源代码同步完成"
    echo "========================================"
    echo ""
    echo "源代码位置:"
    echo "  $WORK_DIR"
    echo ""
    echo "下一步:"
    echo "  1. 运行: bash scripts/03-build-android.sh"
    echo "  2. 或手动编译:"
    echo "     cd $WORK_DIR"
    echo "     source build/envsetup.sh"
    echo "     lunch virtio_arm64-user"
    echo "     m -j\$(nproc)"
    echo ""
    echo "========================================"
}

# 主函数
main() {
    echo ""
    echo "========================================"
    echo "  LineageOS 23.0 源代码同步"
    echo "  分支: $LINEAGE_BRANCH"
    echo "========================================"
    echo ""
    
    check_repo
    check_network
    check_disk_space
    create_work_dir
    
    echo ""
    log_info "开始同步..."
    echo ""
    
    init_repo
    sync_source
    verify_source
    show_statistics
    
    show_summary
}

# 运行主函数
main

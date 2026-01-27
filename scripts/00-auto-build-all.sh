#!/bin/bash

################################################################################
# Android 15 一键式自动化编译脚本
# 功能: 从零开始到编译完成的全自动化流程
# 包括: 环境准备 → 源代码同步 → 编译 → 优化 → 传输
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 日志文件
LOG_DIR="$HOME/android/logs"
mkdir -p "$LOG_DIR"
MASTER_LOG="$LOG_DIR/auto_build_$(date +%Y%m%d_%H%M%S).log"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$MASTER_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$MASTER_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$MASTER_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$MASTER_LOG"
}

log_step() {
    echo -e "${MAGENTA}[STEP]${NC} $1" | tee -a "$MASTER_LOG"
}

# 显示横幅
show_banner() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║        Android 15 一键式自动化编译系统                     ║"
    echo "║                                                            ║"
    echo "║        适用于: Debian 12 x86_64                           ║"
    echo "║        目标: iPad Pro M1 + UTM                            ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# 显示系统信息
show_system_info() {
    log_info "系统信息:"
    echo ""
    echo "  操作系统: $(lsb_release -d | cut -f2)"
    echo "  内核版本: $(uname -r)"
    echo "  CPU 核心: $(nproc)"
    echo "  总内存: $(free -h | awk 'NR==2 {print $2}')"
    echo "  可用空间: $(df -h ~ | awk 'NR==2 {print $4}')"
    echo ""
}

# 显示预计时间
show_estimated_time() {
    echo ""
    echo "========================================"
    echo "  预计时间（取决于硬件和网络）"
    echo "========================================"
    echo "  1. 环境准备:     10-20 分钟"
    echo "  2. 源代码同步:   2-8 小时"
    echo "  3. 编译构建:     1-6 小时"
    echo "  4. 产物优化:     10-20 分钟"
    echo "  5. 文件传输:     按需执行"
    echo "----------------------------------------"
    echo "  总计:           约 4-15 小时"
    echo "========================================"
    echo ""
}

# 确认开始
confirm_start() {
    log_warning "此脚本将执行以下操作:"
    echo ""
    echo "  1. 安装所有编译依赖（需要 sudo 权限）"
    echo "  2. 克隆 LineageOS 23.0 源代码（约 50GB）"
    echo "  3. 编译 Android 15 系统（约 100GB 临时空间）"
    echo "  4. 优化和打包编译产物"
    echo ""
    echo "  需要磁盘空间: 至少 300GB"
    echo "  推荐内存: 16GB+"
    echo "  推荐 CPU: 8 核+"
    echo ""
    
    read -p "是否继续? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "已取消"
        exit 0
    fi
}

# 检查 root 权限
check_sudo() {
    log_info "检查 sudo 权限..."
    
    if ! sudo -v; then
        log_error "需要 sudo 权限"
        exit 1
    fi
    
    log_success "sudo 权限检查通过"
}

# 执行步骤
execute_step() {
    STEP_NUM=$1
    STEP_NAME=$2
    SCRIPT_NAME=$3
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    log_step "步骤 $STEP_NUM: $STEP_NAME"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    # 记录开始时间
    START_TIME=$(date +%s)
    
    # 执行脚本
    if [[ "$SCRIPT_NAME" == "01-setup-build-env.sh" ]]; then
        # 需要 sudo 权限
        sudo bash "$SCRIPT_DIR/$SCRIPT_NAME" | tee -a "$MASTER_LOG"
    else
        bash "$SCRIPT_DIR/$SCRIPT_NAME" | tee -a "$MASTER_LOG"
    fi
    
    # 计算耗时
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    HOURS=$((ELAPSED / 3600))
    MINUTES=$(((ELAPSED % 3600) / 60))
    
    log_success "步骤 $STEP_NUM 完成 (耗时: ${HOURS}h ${MINUTES}m)"
    
    # 询问是否继续
    if [[ $STEP_NUM -lt 4 ]]; then
        echo ""
        read -p "按 Enter 键继续下一步，或 Ctrl+C 退出..."
    fi
}

# 显示最终摘要
show_final_summary() {
    # 计算总耗时
    TOTAL_ELAPSED=$(($(date +%s) - SCRIPT_START_TIME))
    TOTAL_HOURS=$((TOTAL_ELAPSED / 3600))
    TOTAL_MINUTES=$(((TOTAL_ELAPSED % 3600) / 60))
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║              🎉 编译流程全部完成！                         ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  总耗时: ${TOTAL_HOURS} 小时 ${TOTAL_MINUTES} 分钟"
    echo "  主日志: $MASTER_LOG"
    echo ""
    echo "========================================"
    echo "  编译产物位置"
    echo "========================================"
    echo "  原始编译产物:"
    echo "    $HOME/android/lineage/out/target/product/virtio_arm64/"
    echo ""
    echo "  优化后的产物:"
    OPTIMIZED_DIR=$(find "$HOME/android" -maxdepth 1 -type d -name "optimized_*" | sort -r | head -n 1)
    if [[ -n "$OPTIMIZED_DIR" ]]; then
        echo "    $OPTIMIZED_DIR"
    fi
    echo ""
    echo "========================================"
    echo "  下一步"
    echo "========================================"
    echo "  1. 传输到 iPad:"
    echo "     bash scripts/05-transfer-to-ipad.sh"
    echo ""
    echo "  2. 在 UTM 中导入和配置"
    echo "     详见: docs/OPTIMIZATION_GUIDE.md"
    echo ""
    echo "  3. 启动虚拟机并享受 Android 15！"
    echo ""
    echo "========================================"
    echo "  获取帮助"
    echo "========================================"
    echo "  - 查看文档: docs/"
    echo "  - 故障排查: docs/TROUBLESHOOTING.md"
    echo "  - 常见问题: docs/FAQ.md"
    echo ""
    echo "========================================"
}

# 错误处理
handle_error() {
    log_error "脚本执行失败！"
    log_error "错误发生在: $1"
    log_error "查看日志: $MASTER_LOG"
    exit 1
}

# 设置错误陷阱
trap 'handle_error "第 $LINENO 行"' ERR

# 主函数
main() {
    # 记录脚本开始时间
    SCRIPT_START_TIME=$(date +%s)
    
    # 显示横幅
    show_banner
    
    # 显示系统信息
    show_system_info
    
    # 显示预计时间
    show_estimated_time
    
    # 确认开始
    confirm_start
    
    # 检查 sudo 权限
    check_sudo
    
    echo ""
    log_info "开始自动化编译流程..."
    log_info "主日志: $MASTER_LOG"
    
    # 步骤 1: 环境准备
    execute_step 1 "环境准备" "01-setup-build-env.sh"
    
    # 重新加载环境变量
    export PATH=$HOME/bin:$PATH
    export USE_CCACHE=1
    export CCACHE_EXEC=/usr/bin/ccache
    
    # 步骤 2: 源代码同步
    execute_step 2 "源代码同步" "02-sync-source.sh"
    
    # 步骤 3: 编译构建
    execute_step 3 "编译构建" "03-build-android.sh"
    
    # 步骤 4: 产物优化
    execute_step 4 "产物优化" "04-optimize-output.sh"
    
    # 显示最终摘要
    show_final_summary
    
    # 询问是否传输
    echo ""
    read -p "是否现在传输文件到 iPad? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        bash "$SCRIPT_DIR/05-transfer-to-ipad.sh"
    else
        log_info "稍后可运行: bash scripts/05-transfer-to-ipad.sh"
    fi
}

# 运行主函数
main

#!/bin/bash

################################################################################
# Android 15 智能自动化编译脚本 v2.0
# 功能: 智能检测、断点续传、避免重复工作
# 包括: 环境准备 → 源代码同步 → 编译 → 优化 → 传输
################################################################################

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

# 状态文件
STATE_DIR="$HOME/android/.build_state"
mkdir -p "$STATE_DIR"
STATE_FILE="$STATE_DIR/progress.state"
TIMESTAMP_FILE="$STATE_DIR/timestamps.state"

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

log_detect() {
    echo -e "${CYAN}[DETECT]${NC} $1" | tee -a "$MASTER_LOG"
}

################################################################################
# 智能检测系统
################################################################################

# 检测步骤 1: 环境准备
detect_step1() {
    log_detect "检测步骤 1: 环境准备..."
    
    local score=0
    local total=6
    
    # 检查 Java
    if command -v java &> /dev/null; then
        score=$((score + 1))
        log_info "  ✓ Java 已安装"
    else
        log_warning "  ✗ Java 未安装"
    fi
    
    # 检查 Python
    if command -v python3 &> /dev/null; then
        score=$((score + 1))
        log_info "  ✓ Python 已安装"
    else
        log_warning "  ✗ Python 未安装"
    fi
    
    # 检查 repo
    if [[ -f "$HOME/bin/repo" ]]; then
        score=$((score + 1))
        log_info "  ✓ repo 工具已安装"
    else
        log_warning "  ✗ repo 工具未安装"
    fi
    
    # 检查 Git 配置
    if git config --global user.email &> /dev/null; then
        score=$((score + 1))
        log_info "  ✓ Git 已配置"
    else
        log_warning "  ✗ Git 未配置"
    fi
    
    # 检查 ccache
    if command -v ccache &> /dev/null; then
        score=$((score + 1))
        log_info "  ✓ ccache 已安装"
    else
        log_warning "  ✗ ccache 未安装"
    fi
    
    # 检查工作目录
    if [[ -d "$HOME/android" ]]; then
        score=$((score + 1))
        log_info "  ✓ 工作目录已创建"
    else
        log_warning "  ✗ 工作目录未创建"
    fi
    
    local percentage=$((score * 100 / total))
    log_info "步骤 1 完成度: $score/$total ($percentage%)"
    
    if [[ $score -eq $total ]]; then
        return 0  # 完成
    else
        return 1  # 未完成
    fi
}

# 检测步骤 2: 源代码同步
detect_step2() {
    log_detect "检测步骤 2: 源代码同步..."
    
    local work_dir="$HOME/android/lineage"
    
    # 检查源代码目录
    if [[ ! -d "$work_dir" ]]; then
        log_warning "  ✗ 源代码目录不存在"
        return 1
    fi
    
    # 检查 .repo 目录
    if [[ ! -d "$work_dir/.repo" ]]; then
        log_warning "  ✗ .repo 目录不存在"
        return 1
    fi
    
    # 检查关键文件
    if [[ ! -f "$work_dir/build/envsetup.sh" ]]; then
        log_warning "  ✗ 源代码不完整"
        return 1
    fi
    
    # 统计文件数量
    local file_count=$(find "$work_dir" -type f 2>/dev/null | wc -l)
    log_info "  ✓ 源代码目录存在"
    log_info "  ✓ 文件数量: $file_count"
    
    # 检查是否有足够的文件（完整的源代码应该有 100 万+文件）
    if [[ $file_count -gt 500000 ]]; then
        log_success "  ✓ 源代码同步完成"
        return 0
    else
        log_warning "  ⚠ 源代码可能不完整（文件数: $file_count）"
        return 1
    fi
}

# 检测步骤 3: 编译构建
detect_step3() {
    log_detect "检测步骤 3: 编译构建..."
    
    local out_dir="$HOME/android/lineage/out/target/product/virtio_arm64"
    
    # 检查编译输出目录
    if [[ ! -d "$out_dir" ]]; then
        log_warning "  ✗ 编译输出目录不存在"
        return 1
    fi
    
    # 检查关键编译产物
    local score=0
    local total=5
    
    if [[ -f "$out_dir/system.img" ]]; then
        score=$((score + 1))
        log_info "  ✓ system.img 存在"
    else
        log_warning "  ✗ system.img 不存在"
    fi
    
    if [[ -f "$out_dir/vendor.img" ]]; then
        score=$((score + 1))
        log_info "  ✓ vendor.img 存在"
    else
        log_warning "  ✗ vendor.img 不存在"
    fi
    
    if [[ -f "$out_dir/boot.img" ]]; then
        score=$((score + 1))
        log_info "  ✓ boot.img 存在"
    else
        log_warning "  ✗ boot.img 不存在"
    fi
    
    if [[ -f "$out_dir/userdata.img" ]]; then
        score=$((score + 1))
        log_info "  ✓ userdata.img 存在"
    else
        log_warning "  ✗ userdata.img 不存在"
    fi
    
    if [[ -f "$out_dir/ramdisk.img" ]]; then
        score=$((score + 1))
        log_info "  ✓ ramdisk.img 存在"
    else
        log_warning "  ✗ ramdisk.img 不存在"
    fi
    
    local percentage=$((score * 100 / total))
    log_info "步骤 3 完成度: $score/$total ($percentage%)"
    
    if [[ $score -ge 3 ]]; then
        log_success "  ✓ 编译基本完成"
        return 0
    else
        log_warning "  ⚠ 编译未完成或失败"
        return 1
    fi
}

# 检测步骤 4: 产物优化
detect_step4() {
    log_detect "检测步骤 4: 产物优化..."
    
    local out_dir="$HOME/android/lineage/out/target/product/virtio_arm64"
    
    # 检查是否有 UTM 包
    if ls "$out_dir"/*.utm 2>/dev/null | grep -q .; then
        log_success "  ✓ UTM 虚拟机包已创建"
        return 0
    fi
    
    # 检查是否有压缩包
    if ls "$out_dir"/*.zip 2>/dev/null | grep -q .; then
        log_info "  ✓ 压缩包已创建"
        return 0
    fi
    
    # 如果编译完成但没有优化，返回未完成
    if detect_step3 &>/dev/null; then
        log_warning "  ⚠ 编译完成但未优化"
        return 1
    fi
    
    log_warning "  ✗ 产物优化未完成"
    return 1
}

################################################################################
# 状态管理
################################################################################

# 保存进度
save_progress() {
    local step=$1
    echo "$step" > "$STATE_FILE"
    date +%s > "$TIMESTAMP_FILE"
    log_info "进度已保存: 步骤 $step"
}

# 读取进度
load_progress() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "0"
    fi
}

# 获取上次运行时间
get_last_run_time() {
    if [[ -f "$TIMESTAMP_FILE" ]]; then
        local last_timestamp=$(cat "$TIMESTAMP_FILE")
        local current_timestamp=$(date +%s)
        local diff=$((current_timestamp - last_timestamp))
        
        # 转换为可读格式
        local hours=$((diff / 3600))
        local minutes=$(((diff % 3600) / 60))
        
        if [[ $hours -gt 0 ]]; then
            echo "${hours}小时${minutes}分钟前"
        else
            echo "${minutes}分钟前"
        fi
    else
        echo "从未运行"
    fi
}

# 清除进度
clear_progress() {
    rm -f "$STATE_FILE" "$TIMESTAMP_FILE"
    log_info "进度已清除"
}

################################################################################
# 智能决策系统
################################################################################

# 自动检测并决定从哪一步开始
auto_detect_start_step() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              🔍 智能检测系统                               ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "正在检测系统状态..."
    echo ""
    
    # 检测每个步骤
    local step1_done=false
    local step2_done=false
    local step3_done=false
    local step4_done=false
    
    if detect_step1; then
        step1_done=true
    fi
    echo ""
    
    if detect_step2; then
        step2_done=true
    fi
    echo ""
    
    if detect_step3; then
        step3_done=true
    fi
    echo ""
    
    if detect_step4; then
        step4_done=true
    fi
    echo ""
    
    # 决定起始步骤
    local start_step=1
    
    if $step4_done; then
        start_step=5
        log_success "✅ 所有步骤已完成！"
    elif $step3_done; then
        start_step=4
        log_info "📍 建议从步骤 4 开始（产物优化）"
    elif $step2_done; then
        start_step=3
        log_info "📍 建议从步骤 3 开始（编译构建）"
    elif $step1_done; then
        start_step=2
        log_info "📍 建议从步骤 2 开始（源代码同步）"
    else
        start_step=1
        log_info "📍 建议从步骤 1 开始（环境准备）"
    fi
    
    echo ""
    
    # 显示上次运行时间
    local last_run=$(get_last_run_time)
    log_info "上次运行: $last_run"
    
    echo ""
    
    return $start_step
}

# 询问用户确认起始步骤
confirm_start_step() {
    local suggested_step=$1
    
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              📋 执行计划                                   ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    if [[ $suggested_step -eq 5 ]]; then
        log_success "所有步骤已完成！"
        echo ""
        echo "可选操作:"
        echo "  1. 退出（默认）"
        echo "  2. 重新编译（清理并从步骤 3 开始）"
        echo "  3. 完全重新开始（从步骤 1 开始）"
        echo ""
        read -p "请选择 (1/2/3) [默认: 1]: " -n 1 -r
        echo ""
        
        case $REPLY in
            2)
                log_info "将清理编译产物并重新编译"
                rm -rf "$HOME/android/lineage/out"
                return 3
                ;;
            3)
                log_warning "将完全重新开始"
                clear_progress
                return 1
                ;;
            *)
                log_info "退出"
                exit 0
                ;;
        esac
    fi
    
    echo "建议执行的步骤:"
    echo ""
    
    for i in $(seq $suggested_step 4); do
        case $i in
            1) echo "  [$i] 环境准备" ;;
            2) echo "  [$i] 源代码同步" ;;
            3) echo "  [$i] 编译构建" ;;
            4) echo "  [$i] 产物优化" ;;
        esac
    done
    
    echo ""
    echo "选项:"
    echo "  1. 按建议执行（从步骤 $suggested_step 开始）"
    echo "  2. 从步骤 1 开始（完全重新开始）"
    echo "  3. 自定义起始步骤"
    echo "  4. 退出"
    echo ""
    
    read -p "请选择 (1/2/3/4) [默认: 1]: " -n 1 -r
    echo ""
    
    case $REPLY in
        2)
            log_warning "将完全重新开始"
            clear_progress
            return 1
            ;;
        3)
            echo ""
            read -p "请输入起始步骤 (1-4): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[1-4]$ ]]; then
                log_info "将从步骤 $REPLY 开始"
                return $REPLY
            else
                log_error "无效输入，使用建议步骤"
                return $suggested_step
            fi
            ;;
        4)
            log_info "退出"
            exit 0
            ;;
        *)
            log_info "按建议执行"
            return $suggested_step
            ;;
    esac
}

################################################################################
# 执行步骤
################################################################################

# 执行单个步骤
execute_step() {
    local STEP_NUM=$1
    local STEP_NAME=$2
    local SCRIPT_NAME=$3
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    log_step "步骤 $STEP_NUM: $STEP_NAME"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    local START_TIME=$(date +%s)
    
    # 执行脚本并捕获退出状态
    bash "$SCRIPT_DIR/$SCRIPT_NAME" | tee -a "$MASTER_LOG"
    SCRIPT_EXIT_CODE=${PIPESTATUS[0]}
    
    local END_TIME=$(date +%s)
    local DURATION=$((END_TIME - START_TIME))
    local HOURS=$((DURATION / 3600))
    local MINUTES=$(((DURATION % 3600) / 60))
    
    # 检查脚本退出状态
    if [[ $SCRIPT_EXIT_CODE -ne 0 ]]; then
        log_error "步骤 $STEP_NUM 失败 (退出码: $SCRIPT_EXIT_CODE)"
        log_error "查看日志: $MASTER_LOG"
        exit 1
    fi
    
    log_success "步骤 $STEP_NUM 完成 (耗时: ${HOURS}h ${MINUTES}m)"
    
    # 保存进度
    save_progress $STEP_NUM
    
    echo ""
    read -p "按 Enter 键继续下一步，或 Ctrl+C 退出..."
}

################################################################################
# 主函数
################################################################################

main() {
    # 显示横幅
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║        Android 15 智能自动化编译系统 v2.0                  ║"
    echo "║                                                            ║"
    echo "║        ✨ 新功能: 智能检测 + 断点续传                      ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    # 检查 sudo 权限
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        log_info "检查 sudo 权限..."
        sudo -v
    fi
    
    log_success "sudo 权限检查通过"
    echo ""
    
    log_info "主日志: $MASTER_LOG"
    
    # 智能检测
    auto_detect_start_step
    local suggested_step=$?
    
    # 确认起始步骤
    confirm_start_step $suggested_step
    local start_step=$?
    
    echo ""
    log_info "开始执行..."
    echo ""
    
    # 执行步骤
    if [[ $start_step -le 1 ]]; then
        execute_step 1 "环境准备" "01-setup-build-env.sh"
    fi
    
    if [[ $start_step -le 2 ]]; then
        execute_step 2 "源代码同步" "02-sync-source.sh"
    fi
    
    if [[ $start_step -le 3 ]]; then
        execute_step 3 "编译构建" "03-build-android.sh"
    fi
    
    if [[ $start_step -le 4 ]]; then
        execute_step 4 "产物优化" "04-optimize-output.sh"
    fi
    
    # 显示最终摘要
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              🎉 编译流程全部完成！                         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    log_success "所有步骤已完成"
    log_info "编译产物位置: $HOME/android/lineage/out/target/product/virtio_arm64"
    log_info "主日志文件: $MASTER_LOG"
    
    # 保存最终状态
    save_progress 4
    
    echo ""
    echo "下一步:"
    echo "  1. 查看编译产物: ls -lh ~/android/lineage/out/target/product/virtio_arm64/"
    echo "  2. 传输到 iPad: bash scripts/05-transfer-to-ipad.sh"
    echo ""
}

# 运行主函数
main "$@"

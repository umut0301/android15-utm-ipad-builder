#!/bin/bash

################################################################################
# 文件传输脚本
# 功能: 启动 HTTP 服务器，方便传输编译产物到 iPad
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 查找最新的优化目录
find_optimized_dir() {
    log_info "查找优化目录..."
    
    OPTIMIZED_DIR=$(find "$HOME/android" -maxdepth 1 -type d -name "optimized_*" | sort -r | head -n 1)
    
    if [[ -z "$OPTIMIZED_DIR" ]]; then
        log_error "未找到优化目录"
        log_error "请先运行: bash scripts/04-optimize-output.sh"
        exit 1
    fi
    
    log_success "找到优化目录: $OPTIMIZED_DIR"
    echo "$OPTIMIZED_DIR"
}

# 获取本机 IP 地址
get_local_ip() {
    log_info "获取本机 IP 地址..."
    
    # 尝试多种方法获取 IP
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    
    if [[ -z "$LOCAL_IP" ]]; then
        LOCAL_IP=$(ip route get 1 | awk '{print $7}' | head -n 1)
    fi
    
    if [[ -z "$LOCAL_IP" ]]; then
        log_error "无法获取本机 IP 地址"
        exit 1
    fi
    
    log_success "本机 IP: $LOCAL_IP"
    echo "$LOCAL_IP"
}

# 检查端口是否可用
check_port() {
    PORT=$1
    
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# 查找可用端口
find_available_port() {
    log_info "查找可用端口..."
    
    PORTS=(8000 8080 8888 9000)
    
    for PORT in "${PORTS[@]}"; do
        if check_port $PORT; then
            log_success "找到可用端口: $PORT"
            echo "$PORT"
            return
        fi
    done
    
    log_error "所有常用端口都被占用"
    exit 1
}

# 显示文件列表
show_file_list() {
    OPTIMIZED_DIR=$1
    
    log_info "可传输的文件:"
    echo ""
    
    cd "$OPTIMIZED_DIR"
    
    ls -lh | grep -v "^total" | awk '{
        if ($9 != "") {
            printf "  %-40s %10s\n", $9, $5
        }
    }'
    
    echo ""
}

# 启动 HTTP 服务器
start_http_server() {
    OPTIMIZED_DIR=$1
    PORT=$2
    LOCAL_IP=$3
    
    log_info "启动 HTTP 服务器..."
    
    cd "$OPTIMIZED_DIR"
    
    echo ""
    echo "========================================"
    echo "  HTTP 文件服务器已启动"
    echo "========================================"
    echo ""
    echo "  服务器地址:"
    echo "    http://$LOCAL_IP:$PORT/"
    echo ""
    echo "  在 iPad 上:"
    echo "    1. 打开 Safari 浏览器"
    echo "    2. 访问: http://$LOCAL_IP:$PORT/"
    echo "    3. 下载需要的文件"
    echo ""
    echo "  按 Ctrl+C 停止服务器"
    echo "========================================"
    echo ""
    
    # 启动 Python HTTP 服务器
    python3 -m http.server $PORT
}

# 显示传输后步骤
show_next_steps() {
    echo ""
    echo "========================================"
    echo "  文件传输完成后的步骤"
    echo "========================================"
    echo ""
    echo "在 iPad 上:"
    echo ""
    echo "1. 打开 Files 应用"
    echo "   找到下载的文件"
    echo ""
    echo "2. 如果下载的是 ZIP 文件:"
    echo "   长按 ZIP 文件 → 解压"
    echo ""
    echo "3. 打开 UTM 应用"
    echo "   点击 + → Browse"
    echo "   选择解压后的 .utm 文件夹"
    echo ""
    echo "4. 配置虚拟机:"
    echo "   - CPU: 6-8 核"
    echo "   - 内存: 4-6GB"
    echo "   - 显示设备: virtio-gpu-gl-pci"
    echo "   - 渲染器: ANGLE (Metal)"
    echo "   - Retina 模式: 禁用"
    echo ""
    echo "5. 启动虚拟机"
    echo "   点击 Play 按钮"
    echo ""
    echo "详细配置请参考:"
    echo "  docs/OPTIMIZATION_GUIDE.md"
    echo ""
    echo "========================================"
}

# 主函数
main() {
    echo ""
    echo "========================================"
    echo "  文件传输到 iPad"
    echo "========================================"
    echo ""
    
    # 查找优化目录
    OPTIMIZED_DIR=$(find_optimized_dir)
    
    # 获取本机 IP
    LOCAL_IP=$(get_local_ip)
    
    # 查找可用端口
    PORT=$(find_available_port)
    
    echo ""
    
    # 显示文件列表
    show_file_list "$OPTIMIZED_DIR"
    
    # 显示后续步骤
    show_next_steps
    
    echo ""
    log_info "准备启动 HTTP 服务器..."
    read -p "按 Enter 键继续..."
    
    # 启动 HTTP 服务器
    start_http_server "$OPTIMIZED_DIR" "$PORT" "$LOCAL_IP"
}

# 运行主函数
main

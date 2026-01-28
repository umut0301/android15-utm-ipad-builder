#!/bin/bash

################################################################################
# Android 15 UTM 虚拟机首次配置脚本
# 
# 功能：
#   1. 固定 ADB 端口到 5555（永久生效）
#   2. 从 F-Droid 下载并安装 Termux
#   3. 配置系统优化设置
# 
# 使用方法：
#   在 Windows/Mac/Linux 上运行：
#   bash first-boot-setup.sh <虚拟机IP地址>
#   
# 示例：
#   bash first-boot-setup.sh 192.168.167.36
#
# 作者：Manus AI
# 日期：2026-01-28
################################################################################

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 显示横幅
show_banner() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     Android 15 UTM 虚拟机首次配置脚本 v1.0                ║"
    echo "║     一键完成所有配置，开箱即用                             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# 检查 ADB
check_adb() {
    log_info "检查 ADB 工具..."
    
    if ! command -v adb &> /dev/null; then
        log_error "未找到 ADB 工具！"
        log_info "请先安装 Android SDK Platform Tools："
        log_info "  Windows: https://developer.android.com/tools/releases/platform-tools"
        log_info "  Mac: brew install android-platform-tools"
        log_info "  Linux: sudo apt install adb"
        exit 1
    fi
    
    log_success "ADB 工具已安装"
}

# 连接虚拟机
connect_vm() {
    local vm_ip=$1
    local adb_port=5555
    
    log_info "连接到虚拟机: $vm_ip:$adb_port"
    
    # 尝试连接
    adb connect $vm_ip:$adb_port &> /dev/null || true
    
    # 等待连接
    sleep 2
    
    # 检查连接状态
    if adb devices | grep -q "$vm_ip:$adb_port.*device"; then
        log_success "已连接到虚拟机"
        return 0
    else
        log_warning "无法连接到 $vm_ip:$adb_port"
        log_info "尝试查找其他端口..."
        
        # 尝试常见端口
        for port in 5554 5556 5558; do
            log_info "尝试端口 $port..."
            adb connect $vm_ip:$port &> /dev/null || true
            sleep 2
            
            if adb devices | grep -q "$vm_ip:$port.*device"; then
                log_success "已连接到虚拟机（端口 $port）"
                return 0
            fi
        done
        
        log_error "无法连接到虚拟机"
        log_info "请确保："
        log_info "  1. 虚拟机已启动"
        log_info "  2. 虚拟机已开启 ADB 调试"
        log_info "  3. 网络连接正常"
        exit 1
    fi
}

# 获取 root 权限
get_root() {
    log_info "获取 root 权限..."
    
    # 尝试 adb root
    if adb root &> /dev/null; then
        log_success "已获取 root 权限（adb root）"
        sleep 2
        return 0
    fi
    
    # 尝试 su
    log_info "adb root 失败，尝试使用 su..."
    if adb shell "su -c 'id'" &> /dev/null; then
        log_success "已获取 root 权限（su）"
        return 0
    fi
    
    log_error "无法获取 root 权限"
    log_info "请在虚拟机中："
    log_info "  1. 打开 Magisk 应用"
    log_info "  2. 授予 Shell 的 root 权限"
    log_info "  或者："
    log_info "  1. 进入 设置 -> 系统 -> 开发者选项"
    log_info "  2. 启用 'Root 访问' -> 'ADB 和应用'"
    exit 1
}

# 固定 ADB 端口
fix_adb_port() {
    log_info "固定 ADB 端口到 5555..."
    
    # 检查是否已配置
    if adb shell "su -c 'grep -q \"setprop service.adb.tcp.port 5555\" /system/etc/init/hw/init.rc'" 2>/dev/null; then
        log_success "ADB 端口已经固定在 5555"
        return 0
    fi
    
    # 重新挂载系统分区
    log_info "重新挂载系统分区..."
    adb shell "su -c 'mount -o rw,remount /'" || {
        log_error "无法重新挂载系统分区"
        return 1
    }
    
    # 添加配置
    log_info "添加 ADB 端口配置..."
    adb shell "su -c 'echo \"\" >> /system/etc/init/hw/init.rc'"
    adb shell "su -c 'echo \"# Set fixed ADB port on boot\" >> /system/etc/init/hw/init.rc'"
    adb shell "su -c 'echo \"setprop service.adb.tcp.port 5555\" >> /system/etc/init/hw/init.rc'"
    
    # 恢复只读
    log_info "恢复系统分区只读保护..."
    adb shell "su -c 'mount -o ro,remount /'" || true
    
    log_success "ADB 端口已固定到 5555（重启后生效）"
}

# 下载并安装 Termux
install_termux() {
    log_info "下载并安装 Termux..."
    
    # 检查是否已安装
    if adb shell "pm list packages | grep -q com.termux"; then
        log_success "Termux 已安装"
        return 0
    fi
    
    # F-Droid Termux 下载链接
    local termux_url="https://f-droid.org/repo/com.termux_1020.apk"
    local termux_apk="/tmp/termux.apk"
    
    # 下载 Termux
    log_info "从 F-Droid 下载 Termux..."
    if command -v wget &> /dev/null; then
        wget -q -O "$termux_apk" "$termux_url" || {
            log_error "下载失败"
            return 1
        }
    elif command -v curl &> /dev/null; then
        curl -s -L -o "$termux_apk" "$termux_url" || {
            log_error "下载失败"
            return 1
        }
    else
        log_error "未找到 wget 或 curl"
        return 1
    fi
    
    log_success "Termux 下载完成"
    
    # 安装 Termux
    log_info "安装 Termux..."
    adb install -r "$termux_apk" || {
        log_error "安装失败"
        rm -f "$termux_apk"
        return 1
    }
    
    # 清理
    rm -f "$termux_apk"
    
    log_success "Termux 安装完成"
}

# 配置系统优化
optimize_system() {
    log_info "配置系统优化..."
    
    # 禁用 SELinux（可选，提高兼容性）
    log_info "设置 SELinux 为宽容模式..."
    adb shell "su -c 'setenforce 0'" 2>/dev/null || log_warning "无法修改 SELinux 模式"
    
    # 启用 USB 调试持久化
    log_info "启用 USB 调试持久化..."
    adb shell "su -c 'setprop persist.sys.usb.config adb'" || true
    
    log_success "系统优化完成"
}

# 显示完成信息
show_completion() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                   🎉 配置完成！🎉                          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_success "所有配置已完成！"
    echo ""
    log_info "已完成的配置："
    echo "  ✅ ADB 端口固定在 5555"
    echo "  ✅ Termux 已安装"
    echo "  ✅ 系统优化已应用"
    echo ""
    log_warning "请重启虚拟机以使所有配置生效："
    echo "  adb reboot"
    echo ""
    log_info "重启后，您可以随时使用以下命令连接："
    echo "  adb connect $1:5555"
    echo ""
}

# 主函数
main() {
    show_banner
    
    # 检查参数
    if [ $# -eq 0 ]; then
        log_error "缺少虚拟机 IP 地址"
        echo ""
        echo "使用方法："
        echo "  bash $0 <虚拟机IP地址>"
        echo ""
        echo "示例："
        echo "  bash $0 192.168.167.36"
        echo ""
        exit 1
    fi
    
    local vm_ip=$1
    
    # 执行配置步骤
    check_adb
    connect_vm "$vm_ip"
    get_root
    fix_adb_port
    install_termux
    optimize_system
    show_completion "$vm_ip"
    
    # 提示重启
    echo ""
    read -p "是否立即重启虚拟机？(y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "正在重启虚拟机..."
        adb reboot
        log_success "虚拟机正在重启..."
        log_info "请等待约 1-2 分钟后重新连接"
    else
        log_info "请手动重启虚拟机以使配置生效"
    fi
}

# 运行主函数
main "$@"

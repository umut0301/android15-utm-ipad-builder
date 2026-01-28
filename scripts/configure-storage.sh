#!/bin/bash

################################################################################
# LineageOS UTM 虚拟机存储配置向导
# 功能: 帮助用户选择合适的存储大小，并生成 UTM 配置指南
# 注意: 此脚本不修改编译配置，只生成 UTM 导入时的配置指南
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# 配置
CONFIG_FILE="$HOME/.android_utm_storage_config"
OUTPUT_DIR="$HOME/android/utm_config"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${MAGENTA}💾 UTM 虚拟机存储配置向导${NC}                         ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 显示重要说明
show_important_notice() {
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC}  ${MAGENTA}⚠️  重要说明${NC}                                          ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}此工具的作用:${NC}"
    echo -e "  • 帮助您选择合适的虚拟机存储大小"
    echo -e "  • 生成 UTM 导入时的配置指南"
    echo -e "  • 提供存储空间使用建议"
    echo ""
    echo -e "${CYAN}此工具不会:${NC}"
    echo -e "  • 修改 LineageOS 编译配置"
    echo -e "  • 改变编译产物的大小"
    echo -e "  • 影响编译过程"
    echo ""
    echo -e "${CYAN}工作原理:${NC}"
    echo -e "  1. LineageOS 使用${GREEN}动态分区${NC}，会自动使用所有可用空间"
    echo -e "  2. 存储大小由 ${GREEN}UTM 虚拟磁盘${NC}决定，不是编译时设置"
    echo -e "  3. 您在 UTM 中设置多大的磁盘，Android 就能使用多大空间"
    echo ""
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# 显示存储选项
show_storage_options() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${MAGENTA}选择虚拟机存储空间大小${NC}                            ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} ${MAGENTA}64GB${NC}  ${CYAN}(适合轻度使用)${NC}"
    echo -e "   • 适合: 日常使用、测试、开发"
    echo -e "   • 可安装: 约 40-50 个常规应用"
    echo -e "   • 媒体存储: 约 30-40GB 可用空间"
    echo ""
    echo -e "${GREEN}2.${NC} ${MAGENTA}128GB${NC} ${CYAN}(推荐，默认选项)${NC} ${GREEN}⭐${NC}"
    echo -e "   • 适合: 日常使用 + 游戏 + 媒体"
    echo -e "   • 可安装: 约 100+ 个应用和游戏"
    echo -e "   • 媒体存储: 约 100GB 可用空间"
    echo ""
    echo -e "${GREEN}3.${NC} ${MAGENTA}256GB${NC} ${CYAN}(适合重度使用)${NC}"
    echo -e "   • 适合: 大量应用 + 大型游戏 + 视频"
    echo -e "   • 可安装: 200+ 个应用和大型游戏"
    echo -e "   • 媒体存储: 约 230GB 可用空间"
    echo ""
    echo -e "${GREEN}4.${NC} ${MAGENTA}自定义${NC} ${CYAN}(高级用户)${NC}"
    echo -e "   • 自定义任意大小 (最小 32GB)"
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}💡 提示:${NC} 您的 iPad Pro M1 有 1TB 存储，建议选择 128GB"
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    echo ""
}

# 获取用户选择
get_user_choice() {
    local choice
    
    # 检查是否已有配置
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        log_info "检测到已有配置: ${STORAGE_SIZE}GB"
        echo -n "是否使用已有配置？(Y/n): "
        read -r use_existing
        
        if [[ "$use_existing" =~ ^[Nn]$ ]]; then
            rm -f "$CONFIG_FILE"
        else
            log_success "使用已有配置: ${STORAGE_SIZE}GB"
            return 0
        fi
    fi
    
    show_storage_options
    
    echo -n "请选择 (1/2/3/4) [默认: 2]: "
    read -r choice
    
    case "$choice" in
        1)
            STORAGE_SIZE=64
            DESCRIPTION="轻度使用"
            ;;
        3)
            STORAGE_SIZE=256
            DESCRIPTION="重度使用"
            ;;
        4)
            echo -n "请输入总存储空间大小 (GB): "
            read -r custom_size
            
            if ! [[ "$custom_size" =~ ^[0-9]+$ ]] || [[ $custom_size -lt 32 ]]; then
                log_error "无效的存储大小，最小为 32GB"
                exit 1
            fi
            
            STORAGE_SIZE=$custom_size
            DESCRIPTION="自定义"
            ;;
        2|"")
            STORAGE_SIZE=128
            DESCRIPTION="推荐配置"
            ;;
        *)
            log_error "无效的选择"
            exit 1
            ;;
    esac
    
    log_success "已选择: ${STORAGE_SIZE}GB (${DESCRIPTION})"
    
    # 保存配置
    cat > "$CONFIG_FILE" << EOF
# UTM 虚拟机存储配置
# 生成时间: $(date)
STORAGE_SIZE=$STORAGE_SIZE
DESCRIPTION="$DESCRIPTION"
EOF
    
    log_success "配置已保存到: $CONFIG_FILE"
}

# 创建 UTM 配置指南
create_utm_guide() {
    log_info "生成 UTM 配置指南..."
    
    mkdir -p "$OUTPUT_DIR"
    
    local guide_file="$OUTPUT_DIR/UTM_IMPORT_GUIDE_${STORAGE_SIZE}GB.txt"
    
    cat > "$guide_file" << EOF
╔════════════════════════════════════════════════════════════╗
║  UTM 虚拟机导入和配置指南                                ║
║  存储大小: ${STORAGE_SIZE}GB                                     ║
╚════════════════════════════════════════════════════════════╝

📋 配置信息
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  虚拟机存储: ${STORAGE_SIZE}GB
  配置类型:   ${DESCRIPTION}
  生成时间:   $(date)

═══════════════════════════════════════════════════════════

📱 导入步骤
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

步骤 1: 传输文件到 iPad
────────────────────────────────────────────────────────────
  1. 编译完成后，找到以下文件:
     ~/android/lineage/out/target/product/virtio_arm64/
     └── UTM-VM-lineage-*.zip

  2. 通过以下方式传输到 iPad:
     • AirDrop
     • iCloud Drive
     • USB 连接
     • 其他文件传输工具

步骤 2: 解压 ZIP 文件
────────────────────────────────────────────────────────────
  1. 在 iPad 上打开 "文件" 应用
  2. 找到 UTM-VM-lineage-*.zip
  3. 长按文件 → 选择 "解压缩"
  4. 得到 .utm 文件夹

步骤 3: 导入到 UTM
────────────────────────────────────────────────────────────
  1. 打开 UTM 应用
  2. 点击右上角 "+" 按钮
  3. 选择 "浏览"
  4. 找到并选择 .utm 文件夹
  5. 等待导入完成

步骤 4: 配置虚拟机存储 ⚠️ 关键步骤
────────────────────────────────────────────────────────────
  1. 在 UTM 中，长按虚拟机
  2. 选择 "编辑"
  3. 进入 "驱动器" 设置
  4. 找到主磁盘驱动器 (通常是第一个)
  5. 设置 "磁盘大小" 为: ${STORAGE_SIZE}GB
     
     ⚠️ 重要: 必须设置为 ${STORAGE_SIZE}GB 或更大
     
  6. 点击 "保存"

步骤 5: 启动虚拟机
────────────────────────────────────────────────────────────
  1. 点击虚拟机启动
  2. 首次启动会进行初始化 (约 2-5 分钟)
  3. 等待进入 LineageOS 设置向导
  4. 完成初始设置
  5. 享受 Android 15！

═══════════════════════════════════════════════════════════

💡 存储空间说明
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

动态分区技术:
  • LineageOS 使用动态分区，会自动使用所有可用空间
  • 您在 UTM 中设置多大的磁盘，Android 就能使用多大空间
  • 系统会根据需要自动分配空间给应用和数据

实际可用空间:
  • ${STORAGE_SIZE}GB 虚拟磁盘
  • 系统占用: 约 5-8GB
  • 可用空间: 约 $((STORAGE_SIZE - 8))GB

空间分配:
  • 应用和数据: 自动分配
  • 媒体文件: 自动分配
  • 缓存: 自动分配
  • 不需要手动分区

═══════════════════════════════════════════════════════════

⚙️ 高级配置 (可选)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3D 图形加速:
  • 显示设备: virtio-gpu-gl-pci (GPU Supported)
  • 渲染器: ANGLE (Metal)

网络配置:
  • 网络模式: 共享网络 (推荐)
  • 或桥接模式 (高级)

内存配置:
  • 推荐: 4GB-8GB
  • 最小: 2GB

CPU 配置:
  • 推荐: 4-6 核心
  • 最小: 2 核心

═══════════════════════════════════════════════════════════

🔧 故障排查
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

问题: 虚拟机无法启动
  • 检查磁盘大小是否设置正确
  • 确保至少设置为 ${STORAGE_SIZE}GB
  • 检查 iPad 存储空间是否充足

问题: 存储空间不足
  • 在 UTM 中增加磁盘大小
  • Android 会自动识别并使用新空间
  • 无需重新编译

问题: 性能问题
  • 增加分配的内存 (4GB+)
  • 增加 CPU 核心数 (4+)
  • 启用 3D 加速

═══════════════════════════════════════════════════════════

📞 获取帮助
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

文档:
  • 完整指南: docs/STORAGE_MANAGEMENT_GUIDE.md
  • 故障排查: docs/TROUBLESHOOTING.md
  • FAQ: docs/FAQ.md

GitHub:
  • https://github.com/umut0301/android15-utm-ipad-builder

═══════════════════════════════════════════════════════════

祝您使用愉快！🎉

EOF
    
    log_success "UTM 配置指南已创建: $guide_file"
    
    # 同时创建一个副本到编译输出目录（如果存在）
    local compile_output_dir="$HOME/android/lineage/out/target/product/virtio_arm64"
    if [[ -d "$compile_output_dir" ]]; then
        cp "$guide_file" "$compile_output_dir/UTM_IMPORT_GUIDE.txt"
        log_success "配置指南已复制到编译输出目录"
    fi
}

# 创建快速参考卡片
create_quick_reference() {
    log_info "生成快速参考卡片..."
    
    local quick_ref="$OUTPUT_DIR/QUICK_REFERENCE_${STORAGE_SIZE}GB.txt"
    
    cat > "$quick_ref" << EOF
╔════════════════════════════════════════════════════════════╗
║  UTM 配置快速参考                                        ║
╚════════════════════════════════════════════════════════════╝

存储大小: ${STORAGE_SIZE}GB

关键步骤:
  1. 解压 UTM-VM-lineage-*.zip
  2. 在 UTM 中导入 .utm 文件夹
  3. 编辑虚拟机 → 驱动器 → 设置磁盘大小为 ${STORAGE_SIZE}GB
  4. 启动虚拟机

重要提示:
  • 磁盘大小必须 >= ${STORAGE_SIZE}GB
  • Android 会自动使用所有可用空间
  • 无需手动分区

详细指南: UTM_IMPORT_GUIDE_${STORAGE_SIZE}GB.txt

EOF
    
    log_success "快速参考卡片已创建: $quick_ref"
}

# 显示配置摘要
show_summary() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${MAGENTA}📊 配置完成摘要${NC}                                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✓${NC} 存储大小: ${MAGENTA}${STORAGE_SIZE}GB${NC}"
    echo -e "${GREEN}✓${NC} 配置类型: ${CYAN}${DESCRIPTION}${NC}"
    echo -e "${GREEN}✓${NC} 配置文件: ${CYAN}$CONFIG_FILE${NC}"
    echo -e "${GREEN}✓${NC} 指南目录: ${CYAN}$OUTPUT_DIR${NC}"
    echo ""
    echo -e "${CYAN}生成的文件:${NC}"
    echo -e "  • ${GREEN}UTM_IMPORT_GUIDE_${STORAGE_SIZE}GB.txt${NC} - 详细导入指南"
    echo -e "  • ${GREEN}QUICK_REFERENCE_${STORAGE_SIZE}GB.txt${NC} - 快速参考"
    echo ""
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}⚠️  下一步操作${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} 运行编译脚本:"
    echo -e "   ${GREEN}bash scripts/03-build-android.sh${NC}"
    echo ""
    echo -e "${CYAN}2.${NC} 编译完成后，查看导入指南:"
    echo -e "   ${GREEN}cat $OUTPUT_DIR/UTM_IMPORT_GUIDE_${STORAGE_SIZE}GB.txt${NC}"
    echo ""
    echo -e "${CYAN}3.${NC} 在 UTM 中导入时，设置磁盘大小为 ${MAGENTA}${STORAGE_SIZE}GB${NC}"
    echo ""
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# 主函数
main() {
    show_important_notice
    get_user_choice
    create_utm_guide
    create_quick_reference
    show_summary
    
    log_success "配置向导完成！"
    log_info "现在可以运行编译脚本: bash scripts/03-build-android.sh"
}

# 运行主函数
main

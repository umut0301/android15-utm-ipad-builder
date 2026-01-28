#!/bin/bash

################################################################################
# LineageOS 存储空间配置脚本
# 功能: 配置编译时的存储空间大小，确保与 UTM 虚拟机协同一致
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
WORK_DIR="$HOME/android/lineage"
DEVICE_DIR="$WORK_DIR/device/generic/virtio_arm64"
BOARD_CONFIG="$DEVICE_DIR/BoardConfig.mk"
CONFIG_FILE="$HOME/.android_storage_config"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${MAGENTA}💾 LineageOS 存储空间配置工具${NC}                      ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 检查源代码目录
check_source_dir() {
    if [[ ! -d "$WORK_DIR" ]]; then
        log_error "源代码目录不存在: $WORK_DIR"
        log_error "请先运行: bash scripts/02-sync-source.sh"
        exit 1
    fi
    
    if [[ ! -d "$DEVICE_DIR" ]]; then
        log_error "设备目录不存在: $DEVICE_DIR"
        log_error "请确保源代码同步完整"
        exit 1
    fi
}

# 显示存储选项
show_storage_options() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "  ${MAGENTA}选择虚拟机存储空间大小${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} 64GB  ${CYAN}(适合轻度使用)${NC}"
    echo -e "   - 系统分区: 8GB"
    echo -e "   - 用户数据: 50GB"
    echo -e "   - 其他分区: 6GB"
    echo ""
    echo -e "${GREEN}2.${NC} 128GB ${CYAN}(推荐，默认选项)${NC}"
    echo -e "   - 系统分区: 10GB"
    echo -e "   - 用户数据: 110GB"
    echo -e "   - 其他分区: 8GB"
    echo ""
    echo -e "${GREEN}3.${NC} 256GB ${CYAN}(适合重度使用)${NC}"
    echo -e "   - 系统分区: 12GB"
    echo -e "   - 用户数据: 235GB"
    echo -e "   - 其他分区: 9GB"
    echo ""
    echo -e "${GREEN}4.${NC} 自定义 ${CYAN}(高级用户)${NC}"
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
            SYSTEM_SIZE=8192
            USERDATA_SIZE=51200
            VENDOR_SIZE=2048
            CACHE_SIZE=512
            ;;
        3)
            STORAGE_SIZE=256
            SYSTEM_SIZE=12288
            USERDATA_SIZE=240640
            VENDOR_SIZE=2560
            CACHE_SIZE=512
            ;;
        4)
            echo -n "请输入总存储空间大小 (GB): "
            read -r custom_size
            
            if ! [[ "$custom_size" =~ ^[0-9]+$ ]] || [[ $custom_size -lt 32 ]]; then
                log_error "无效的存储大小，最小为 32GB"
                exit 1
            fi
            
            STORAGE_SIZE=$custom_size
            # 自动计算分区大小
            SYSTEM_SIZE=$((custom_size * 80))  # 约 8% 给系统
            USERDATA_SIZE=$((custom_size * 900))  # 约 90% 给用户数据
            VENDOR_SIZE=2048
            CACHE_SIZE=512
            ;;
        2|"")
            STORAGE_SIZE=128
            SYSTEM_SIZE=10240
            USERDATA_SIZE=112640
            VENDOR_SIZE=2048
            CACHE_SIZE=512
            ;;
        *)
            log_error "无效的选择"
            exit 1
            ;;
    esac
    
    log_success "已选择: ${STORAGE_SIZE}GB"
    
    # 保存配置
    cat > "$CONFIG_FILE" << EOF
# Android 存储配置
# 生成时间: $(date)
STORAGE_SIZE=$STORAGE_SIZE
SYSTEM_SIZE=$SYSTEM_SIZE
USERDATA_SIZE=$USERDATA_SIZE
VENDOR_SIZE=$VENDOR_SIZE
CACHE_SIZE=$CACHE_SIZE
EOF
    
    log_success "配置已保存到: $CONFIG_FILE"
}

# 配置 BoardConfig.mk
configure_board_config() {
    log_info "配置设备分区大小..."
    
    # 备份原始文件
    if [[ ! -f "$BOARD_CONFIG.backup" ]]; then
        cp "$BOARD_CONFIG" "$BOARD_CONFIG.backup"
        log_info "已备份原始配置: $BOARD_CONFIG.backup"
    fi
    
    # 创建临时文件
    local temp_file=$(mktemp)
    
    # 读取原始文件并修改
    while IFS= read -r line; do
        # 修改系统分区大小
        if [[ "$line" =~ ^BOARD_SYSTEMIMAGE_PARTITION_SIZE ]]; then
            echo "BOARD_SYSTEMIMAGE_PARTITION_SIZE := $((SYSTEM_SIZE * 1024 * 1024))"
        # 修改用户数据分区大小
        elif [[ "$line" =~ ^BOARD_USERDATAIMAGE_PARTITION_SIZE ]]; then
            echo "BOARD_USERDATAIMAGE_PARTITION_SIZE := $((USERDATA_SIZE * 1024 * 1024))"
        # 修改 vendor 分区大小
        elif [[ "$line" =~ ^BOARD_VENDORIMAGE_PARTITION_SIZE ]]; then
            echo "BOARD_VENDORIMAGE_PARTITION_SIZE := $((VENDOR_SIZE * 1024 * 1024))"
        # 修改 cache 分区大小
        elif [[ "$line" =~ ^BOARD_CACHEIMAGE_PARTITION_SIZE ]]; then
            echo "BOARD_CACHEIMAGE_PARTITION_SIZE := $((CACHE_SIZE * 1024 * 1024))"
        else
            echo "$line"
        fi
    done < "$BOARD_CONFIG" > "$temp_file"
    
    # 如果原文件中没有这些配置，添加它们
    if ! grep -q "BOARD_SYSTEMIMAGE_PARTITION_SIZE" "$BOARD_CONFIG"; then
        cat >> "$temp_file" << EOF

# 存储分区配置 (由 configure-storage.sh 自动生成)
BOARD_SYSTEMIMAGE_PARTITION_SIZE := $((SYSTEM_SIZE * 1024 * 1024))
BOARD_USERDATAIMAGE_PARTITION_SIZE := $((USERDATA_SIZE * 1024 * 1024))
BOARD_VENDORIMAGE_PARTITION_SIZE := $((VENDOR_SIZE * 1024 * 1024))
BOARD_CACHEIMAGE_PARTITION_SIZE := $((CACHE_SIZE * 1024 * 1024))
EOF
    fi
    
    # 替换原文件
    mv "$temp_file" "$BOARD_CONFIG"
    
    log_success "BoardConfig.mk 配置完成"
}

# 创建 UTM 配置文件
create_utm_config() {
    log_info "创建 UTM 配置信息..."
    
    local utm_config_file="$WORK_DIR/out/target/product/virtio_arm64/UTM_STORAGE_CONFIG.txt"
    mkdir -p "$(dirname "$utm_config_file")"
    
    cat > "$utm_config_file" << EOF
╔════════════════════════════════════════════════════════════╗
║  UTM 虚拟机存储配置信息                                  ║
╚════════════════════════════════════════════════════════════╝

此 LineageOS 镜像已配置为使用 ${STORAGE_SIZE}GB 存储空间

分区详情:
  - 系统分区:   ${SYSTEM_SIZE}MB ($(awk "BEGIN {printf \"%.2f\", $SYSTEM_SIZE/1024}")GB)
  - 用户数据:   ${USERDATA_SIZE}MB ($(awk "BEGIN {printf \"%.2f\", $USERDATA_SIZE/1024}")GB)
  - Vendor:     ${VENDOR_SIZE}MB ($(awk "BEGIN {printf \"%.2f\", $VENDOR_SIZE/1024}")GB)
  - Cache:      ${CACHE_SIZE}MB ($(awk "BEGIN {printf \"%.2f\", $CACHE_SIZE/1024}")GB)

═══════════════════════════════════════════════════════════

在 UTM 中导入此虚拟机时的配置步骤:

1. 解压 UTM-VM-lineage-*.zip 文件

2. 在 UTM 中导入 .utm 文件夹

3. 编辑虚拟机设置:
   - 进入 "驱动器" 设置
   - 找到主磁盘驱动器
   - 设置磁盘大小为: ${STORAGE_SIZE}GB 或更大

4. 启动虚拟机

注意事项:
  - UTM 磁盘大小必须 >= ${STORAGE_SIZE}GB
  - 建议设置为 ${STORAGE_SIZE}GB 以获得最佳性能
  - 如果设置更大的磁盘，Android 会自动使用额外空间

═══════════════════════════════════════════════════════════

配置生成时间: $(date)
配置文件位置: ~/.android_storage_config

EOF
    
    log_success "UTM 配置信息已创建: $utm_config_file"
}

# 显示配置摘要
show_summary() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${MAGENTA}📊 存储配置摘要${NC}                                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✓${NC} 总存储空间: ${MAGENTA}${STORAGE_SIZE}GB${NC}"
    echo -e "${GREEN}✓${NC} 系统分区:   ${CYAN}${SYSTEM_SIZE}MB${NC} ($(awk "BEGIN {printf \"%.2f\", $SYSTEM_SIZE/1024}")GB)"
    echo -e "${GREEN}✓${NC} 用户数据:   ${CYAN}${USERDATA_SIZE}MB${NC} ($(awk "BEGIN {printf \"%.2f\", $USERDATA_SIZE/1024}")GB)"
    echo -e "${GREEN}✓${NC} Vendor:     ${CYAN}${VENDOR_SIZE}MB${NC} ($(awk "BEGIN {printf \"%.2f\", $VENDOR_SIZE/1024}")GB)"
    echo -e "${GREEN}✓${NC} Cache:      ${CYAN}${CACHE_SIZE}MB${NC} ($(awk "BEGIN {printf \"%.2f\", $CACHE_SIZE/1024}")GB)"
    echo ""
    echo -e "${YELLOW}[重要]${NC} 在 UTM 中导入虚拟机时，请设置磁盘大小为 ${MAGENTA}${STORAGE_SIZE}GB${NC}"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# 主函数
main() {
    check_source_dir
    get_user_choice
    configure_board_config
    create_utm_config
    show_summary
    
    log_success "存储配置完成！"
    log_info "现在可以运行编译脚本: bash scripts/03-build-android.sh"
}

# 运行主函数
main

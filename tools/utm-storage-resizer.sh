#!/bin/bash

################################################################################
# UTM 虚拟机存储扩展工具
# 
# 功能：自动扩展 UTM 虚拟机包中的虚拟磁盘大小
# 适用于：Android 15 (LineageOS 23.0) for virtio_arm64
# 
# 使用方法：
#   sudo bash utm-storage-resizer.sh [UTM包路径] [目标大小]
#   
# 示例：
#   sudo bash utm-storage-resizer.sh ./LineageOS.utm 128
#   sudo bash utm-storage-resizer.sh ./UTM-VM-lineage.zip 256
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
    echo -e "${BLUE}[INFO]${NC} $1" >&2
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
    echo "║        UTM 虚拟机存储扩展工具 v1.0                        ║"
    echo "║        适用于 Android 15 (LineageOS 23.0)                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
}

# 检查依赖
check_dependencies() {
    log_info "检查必需的工具..."
    
    local missing_tools=()
    
    # 检查必需工具
    for tool in qemu-img parted gdisk xmlstarlet unzip zip; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "缺少必需的工具: ${missing_tools[*]}"
        log_info "正在安装缺失的工具..."
        
        # 安装缺失的工具
        apt update -qq
        apt install -y qemu-utils parted gdisk xmlstarlet zip unzip
        
        log_success "工具安装完成"
    else
        log_success "所有必需工具已安装"
    fi
}

# 查找 UTM 包
find_utm_packages() {
    echo "搜索当前目录中的 UTM 虚拟机包..." >&2
    
    # 查找 .utm 目录
    find . -maxdepth 2 -type d -name "*.utm" -print0 2>/dev/null
    
    # 查找 .zip 文件并检查是否包含 .utm
    while IFS= read -r -d '' zip_file; do
        if unzip -l "$zip_file" 2>/dev/null | grep -q "\.utm/"; then
            printf '%s\0' "$zip_file"
        fi
    done < <(find . -maxdepth 2 -type f -name "*.zip" -print0 2>/dev/null)
}

# 显示包列表并让用户选择
select_utm_package() {
    local packages=($@)
    
    if [ ${#packages[@]} -eq 0 ]; then
        echo "" >&2
        log_error "未找到任何 UTM 虚拟机包"
        log_info "请确保 .utm 目录或 .zip 文件在当前目录或子目录中"
        exit 1
    fi
    
    echo "" >&2
    log_info "找到以下 UTM 虚拟机包："
    echo "" >&2
    
    for i in "${!packages[@]}"; do
        echo "  [$((i+1))] ${packages[$i]}" >&2
    done
    
    echo "" >&2
    read -p "请选择要修改的包 [1-${#packages[@]}]: " selection >&2
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#packages[@]} ]; then
        log_error "无效的选择"
        exit 1
    fi
    
    echo "${packages[$((selection-1))]}"
}

# 选择目标大小
select_target_size() {
    echo "" >&2
    log_info "选择目标存储大小："
    echo "" >&2
    echo "  [1] 64 GB  - 轻度使用" >&2
    echo "  [2] 128 GB - 推荐（日常使用）" >&2
    echo "  [3] 256 GB - 重度使用" >&2
    echo "  [4] 自定义大小" >&2
    echo "" >&2
    read -p "请选择 [1-4, 默认=2]: " size_choice >&2
    
    case "${size_choice:-2}" in
        1)
            echo "64"
            ;;
        2)
            echo "128"
            ;;
        3)
            echo "256"
            ;;
        4)
            read -p "请输入自定义大小 (GB): " custom_size >&2
            if [[ ! "$custom_size" =~ ^[0-9]+$ ]] || [ "$custom_size" -lt 16 ]; then
                log_error "无效的大小，必须至少为 16 GB"
                exit 1
            fi
            echo "$custom_size"
            ;;
        *)
            log_error "无效的选择"
            exit 1
            ;;
    esac
}

# 解压 ZIP 包
extract_zip_package() {
    local zip_file="$1"
    local extract_dir="$2"
    
    log_info "解压 ZIP 包: $zip_file"
    
    mkdir -p "$extract_dir"
    unzip -q "$zip_file" -d "$extract_dir"
    
    # 查找 .utm 目录
    local utm_dir=$(find "$extract_dir" -type d -name "*.utm" | head -n 1)
    
    if [ -z "$utm_dir" ]; then
        log_error "ZIP 包中未找到 .utm 目录"
        exit 1
    fi
    
    echo "$utm_dir"
}

# 检测当前磁盘大小
detect_disk_size() {
    local disk_image="$1"
    
    if [ ! -f "$disk_image" ]; then
        log_error "磁盘镜像不存在: $disk_image"
        exit 1
    fi
    
    # 使用 qemu-img info 获取虚拟大小
    local size_bytes=$(qemu-img info "$disk_image" | grep "virtual size" | awk '{print $3}' | sed 's/[^0-9]//g')
    
    if [ -z "$size_bytes" ]; then
        # 备用方法：使用文件大小
        size_bytes=$(stat -c%s "$disk_image")
    fi
    
    # 转换为 GB
    local size_gb=$((size_bytes / 1024 / 1024 / 1024))
    
    echo "$size_gb"
}

# 扩展虚拟磁盘
resize_disk_image() {
    local disk_image="$1"
    local target_size_gb="$2"
    
    log_info "扩展磁盘镜像: $disk_image"
    log_info "目标大小: ${target_size_gb} GB"
    
    # 备份原始磁盘
    log_info "创建备份..."
    cp "$disk_image" "${disk_image}.backup"
    
    # 使用 qemu-img resize 扩展磁盘
    log_info "扩展虚拟磁盘..."
    qemu-img resize "$disk_image" "${target_size_gb}G"
    
    log_success "磁盘镜像已扩展到 ${target_size_gb} GB"
}

# 扩展 GPT 分区表
expand_partition() {
    local disk_image="$1"
    
    if [ ! -f "$disk_image" ]; then
        log_warning "磁盘镜像不存在: $disk_image"
        return
    fi
    
    log_info "扩展 GPT 分区表..."
    
    # 检测磁盘格式
    local disk_format=$(qemu-img info "$disk_image" | grep "file format" | awk '{print $3}')
    log_info "检测到磁盘格式: $disk_format"
    
    local working_disk="$disk_image"
    local need_convert=false
    
    # 如果是 qcow2 格式，需要先转换为 raw
    if [ "$disk_format" = "qcow2" ]; then
        log_info "qcow2 格式需要转换为 raw 以进行分区操作..."
        working_disk="${disk_image}.raw"
        need_convert=true
        
        qemu-img convert -f qcow2 -O raw "$disk_image" "$working_disk"
        if [ $? -ne 0 ]; then
            log_error "转换 qcow2 到 raw 失败"
            return 1
        fi
        log_success "已转换为 raw 格式"
    fi
    
    # 检查是否有分区表
    if ! parted -s "$working_disk" print &> /dev/null; then
        log_warning "无法读取分区表，跳过分区扩展"
        [ "$need_convert" = true ] && rm -f "$working_disk"
        return
    fi
    
    # 获取最后一个分区的信息
    local last_partition=$(parted -s "$working_disk" print | grep "^ " | tail -n 1 | awk '{print $1}')
    
    if [ -z "$last_partition" ]; then
        log_warning "无法检测到分区，跳过分区扩展"
        [ "$need_convert" = true ] && rm -f "$working_disk"
        return
    fi
    
    log_info "检测到最后一个分区: $last_partition"
    
    # 扩展最后一个分区到磁盘末尾（通常是 userdata 分区）
    log_info "扩展分区 $last_partition 到磁盘末尾..."
    
    # 使用 sgdisk 扩展分区
    if command -v sgdisk &> /dev/null; then
        # 删除并重新创建最后一个分区，使用所有剩余空间
        local start_sector=$(sgdisk -i "$last_partition" "$working_disk" 2>/dev/null | grep "First sector" | awk '{print $3}')
        
        if [ -n "$start_sector" ]; then
            log_info "重新创建分区 $last_partition，起始扇区: $start_sector"
            sgdisk -d "$last_partition" "$working_disk" 2>&1 | grep -v "Warning:"
            sgdisk -n "${last_partition}:${start_sector}:0" "$working_disk" 2>&1 | grep -v "Warning:"
            sgdisk -c "${last_partition}:userdata" "$working_disk" 2>&1 | grep -v "Warning:"
            
            log_success "分区表已扩展"
        else
            log_warning "无法获取分区起始扇区，跳过分区扩展"
        fi
    else
        log_warning "sgdisk 不可用，跳过分区扩展"
        log_info "Android 系统会在首次启动时自动扩展文件系统"
    fi
    
    # 如果转换了格式，需要转回 qcow2
    if [ "$need_convert" = true ]; then
        log_info "转换回 qcow2 格式..."
        mv "$disk_image" "${disk_image}.backup-qcow2"
        qemu-img convert -f raw -O qcow2 "$working_disk" "$disk_image"
        if [ $? -eq 0 ]; then
            rm -f "$working_disk"
            rm -f "${disk_image}.backup-qcow2"
            log_success "已转换回 qcow2 格式"
        else
            log_error "转换回 qcow2 失败，恢复原文件"
            mv "${disk_image}.backup-qcow2" "$disk_image"
            rm -f "$working_disk"
            return 1
        fi
    fi
}

# 更新 config.plist
update_config_plist() {
    local utm_dir="$1"
    local disk_name="$2"
    local target_size_gb="$3"
    
    local config_file="$utm_dir/config.plist"
    
    if [ ! -f "$config_file" ]; then
        log_error "配置文件不存在: $config_file"
        exit 1
    fi
    
    log_info "更新 UTM 配置文件..."
    log_info "磁盘文件名: $disk_name"
    
    # 转换为 MiB
    local size_mib=$((target_size_gb * 1024))
    
    # 备份配置文件
    cp "$config_file" "${config_file}.backup"
    
    # 检查配置文件格式
    if file "$config_file" | grep -q "XML"; then
        # XML/plist 格式
        log_info "检测到 XML 格式的配置文件"
        
        # 先检查配置文件中是否包含该磁盘
        if grep -q "<string>$disk_name</string>" "$config_file"; then
            log_info "在配置中找到磁盘: $disk_name"
        else
            log_warning "配置中未找到磁盘 $disk_name，将更新所有 SizeMib 条目"
        fi
        
        # 使用 xmlstarlet 更新
        if command -v xmlstarlet &> /dev/null; then
            # 尝试查找并更新包含指定磁盘名称的 Drive 条目
            local xpath_updated=false
            
            # 尝试多种 XPath 表达式
            for xpath in \
                "//dict[key='ImageName'][string='$disk_name']/key[.='SizeMib']/following-sibling::integer[1]" \
                "//array/dict[key='ImageName'][string='$disk_name']//key[.='SizeMib']/following-sibling::integer[1]" \
                "//key[.='Drive']/following-sibling::array[1]/dict[key='ImageName'][string='$disk_name']//key[.='SizeMib']/following-sibling::integer[1]"
            do
                if xmlstarlet ed -L -u "$xpath" -v "$size_mib" "$config_file" 2>/dev/null; then
                    xpath_updated=true
                    log_info "使用 XPath 成功更新"
                    break
                fi
            done
            
            # 如果所有 XPath 都失败，使用 sed 备用方法
            if [ "$xpath_updated" = false ]; then
                log_warning "使用 xmlstarlet 更新失败，尝试使用 sed..."
                # 更新第一个 SizeMib 条目（通常是 vda 磁盘）
                sed -i "0,/<key>SizeMib<\/key>/{n;s/<integer>[0-9]*<\/integer>/<integer>$size_mib<\/integer>/;}" "$config_file"
            fi
        else
            # 使用 sed 作为备用方法
            log_info "使用 sed 更新配置文件..."
            # 更新第一个 SizeMib 条目
            sed -i "0,/<key>SizeMib<\/key>/{n;s/<integer>[0-9]*<\/integer>/<integer>$size_mib<\/integer>/;}" "$config_file"
        fi
        
        # 验证更新
        if grep -q "<integer>$size_mib</integer>" "$config_file"; then
            log_success "配置文件已更新: SizeMib = $size_mib MiB (${target_size_gb} GB)"
        else
            log_warning "无法验证配置更新，请手动检查"
        fi
    else
        log_warning "无法识别配置文件格式，跳过配置更新"
        log_info "您可能需要手动在 UTM 中调整磁盘大小"
    fi
}

# 重新打包为 ZIP
repack_zip() {
    local utm_dir="$1"
    local output_zip="$2"
    
    log_info "重新打包为 ZIP..."
    
    local parent_dir=$(dirname "$utm_dir")
    local utm_name=$(basename "$utm_dir")
    
    cd "$parent_dir"
    zip -r -q "$output_zip" "$utm_name"
    cd - > /dev/null
    
    log_success "已创建新的 ZIP 包: $output_zip"
}

# 清理临时文件
cleanup() {
    local temp_dir="$1"
    
    if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
        log_info "清理临时文件..."
        rm -rf "$temp_dir"
    fi
}

# 主函数
main() {
    show_banner
    
    # 检查是否以 root 运行
    if [ "$EUID" -ne 0 ]; then
        log_error "此脚本需要 root 权限运行"
        log_info "请使用: sudo bash $0"
        exit 1
    fi
    
    # 检查依赖
    check_dependencies
    
    # 解析参数
    local utm_package="$1"
    local target_size="$2"
    
    # 如果没有提供参数，自动搜索并让用户选择
    if [ -z "$utm_package" ]; then
        local packages=()
        while IFS= read -r -d '' pkg; do
            packages+=("$pkg")
        done < <(find_utm_packages)
        utm_package=$(select_utm_package "${packages[@]}")
    fi
    
    if [ ! -e "$utm_package" ]; then
        log_error "UTM 包不存在: $utm_package"
        exit 1
    fi
    
    # 如果没有提供目标大小，让用户选择
    if [ -z "$target_size" ]; then
        target_size=$(select_target_size)
    fi
    
    log_info "选择的包: $utm_package"
    log_info "目标大小: ${target_size} GB"
    
    # 创建临时工作目录
    local temp_dir=$(mktemp -d -t utm-resize-XXXXXX)
    trap "cleanup '$temp_dir'" EXIT
    
    local utm_dir=""
    local is_zip=false
    
    # 判断是 ZIP 还是 .utm 目录
    if [[ "$utm_package" == *.zip ]]; then
        is_zip=true
        utm_dir=$(extract_zip_package "$utm_package" "$temp_dir")
    else
        utm_dir="$utm_package"
    fi
    
    log_info "UTM 目录: $utm_dir"
    
    # 自动检测磁盘目录（支持 Images 和 Data 两种结构）
    local images_dir=""
    if [ -d "$utm_dir/Images" ]; then
        images_dir="$utm_dir/Images"
        log_info "检测到 Images 目录结构"
    elif [ -d "$utm_dir/Data" ]; then
        images_dir="$utm_dir/Data"
        log_info "检测到 Data 目录结构"
    else
        log_error "未找到磁盘目录（Images 或 Data）: $utm_dir"
        exit 1
    fi
    
    # 自动检测磁盘文件名和格式
    local disk_vda=""
    local disk_vdb=""
    local disk_name_vda=""
    local disk_name_vdb=""
    
    # 尝试查找 vda 磁盘（支持多种命名和格式）
    for name in "disk-vda.img" "vda.qcow2" "vda.img" "disk-vda.qcow2"; do
        if [ -f "$images_dir/$name" ]; then
            disk_vda="$images_dir/$name"
            disk_name_vda="$name"
            log_info "找到主磁盘: $name"
            break
        fi
    done
    
    if [ -z "$disk_vda" ]; then
        log_error "未找到主磁盘文件（尝试了 disk-vda.img, vda.qcow2, vda.img, disk-vda.qcow2）"
        log_info "目录内容: $(ls -la $images_dir)"
        exit 1
    fi
    
    # 尝试查找 vdb 磁盘（可选）
    for name in "disk-vdb.img" "vdb.qcow2" "vdb.img" "disk-vdb.qcow2"; do
        if [ -f "$images_dir/$name" ]; then
            disk_vdb="$images_dir/$name"
            disk_name_vdb="$name"
            log_info "找到数据磁盘: $name"
            break
        fi
    done
    
    # 检测当前大小
    local current_size=$(detect_disk_size "$disk_vda")
    log_info "当前磁盘大小: ${current_size} GB"
    
    if [ "$current_size" -ge "$target_size" ]; then
        log_warning "当前大小 (${current_size} GB) 已经大于或等于目标大小 (${target_size} GB)"
        read -p "是否仍要继续? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "操作已取消"
            exit 0
        fi
    fi
    
    echo ""
    log_warning "即将执行以下操作："
    echo "  - 扩展 $disk_name_vda 从 ${current_size} GB 到 ${target_size} GB"
    echo "  - 扩展 GPT 分区表"
    echo "  - 更新 UTM 配置文件"
    if [ "$is_zip" = true ]; then
        echo "  - 重新打包为 ZIP"
    fi
    echo ""
    read -p "确认继续? [y/N]: " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "操作已取消"
        exit 0
    fi
    
    echo ""
    log_info "开始处理..."
    echo ""
    
    # 扩展主磁盘
    resize_disk_image "$disk_vda" "$target_size"
    
    # 扩展分区表
    expand_partition_table "$disk_vda" "$target_size"
    
    # 更新配置文件
    update_config_plist "$utm_dir" "$disk_name_vda" "$target_size"
    
    # 处理 vdb（如果存在）
    if [ -f "$disk_vdb" ]; then
        log_info "检测到 disk-vdb.img，保持不变"
    fi
    
    # 如果是 ZIP，重新打包
    if [ "$is_zip" = true ]; then
        # 获取原始 ZIP 的绝对路径和目录
        local original_zip_abs=$(realpath "$utm_package")
        local original_dir=$(dirname "$original_zip_abs")
        local original_name=$(basename "$utm_package" .zip)
        
        # 在临时目录中创建新 ZIP
        local temp_output_zip="$temp_dir/${original_name}-${target_size}GB.zip"
        repack_zip "$utm_dir" "$temp_output_zip"
        
        # 将新 ZIP 移动到原始目录
        local final_output_zip="$original_dir/${original_name}-${target_size}GB.zip"
        log_info "移动 ZIP 包到原始目录..."
        mv "$temp_output_zip" "$final_output_zip"
        
        echo ""
        log_success "处理完成！"
        log_info "新的 ZIP 包: $final_output_zip"
        log_info "原始备份: ${disk_vda}.backup (在临时目录中，将被清理)"
    else
        echo ""
        log_success "处理完成！"
        log_info "UTM 目录: $utm_dir"
        log_info "磁盘备份: ${disk_vda}.backup"
    fi
    
    echo ""
    log_info "下一步操作："
    echo "  1. 将修改后的 UTM 包传输到 iPad"
    echo "  2. 在 UTM 中导入虚拟机"
    echo "  3. 首次启动时，Android 会自动扩展文件系统（需要 3-5 分钟）"
    echo "  4. 进入系统后，检查 '设置' -> '存储' 确认空间"
    echo ""
    
    log_success "所有操作完成！"
}

# 运行主函数
main "$@"

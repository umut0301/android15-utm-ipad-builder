#!/bin/bash

################################################################################
# 编译状态检查工具
# 功能: 检查当前编译进度和状态
################################################################################

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
BUILD_TARGET="virtio_arm64"
STATE_DIR="$HOME/.build_state"
STATE_FILE="$STATE_DIR/build_progress.state"

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${MAGENTA}📊 Android 15 编译状态检查工具${NC}                      ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 检查编译进程
check_build_process() {
    echo -e "${BLUE}[检查]${NC} 编译进程..."
    
    # 检查是否有 ninja 进程
    NINJA_PID=$(pgrep -f "ninja.*lineage" | head -n 1)
    
    if [[ -n "$NINJA_PID" ]]; then
        echo -e "${GREEN}✓${NC} 发现编译进程 (PID: $NINJA_PID)"
        
        # 获取进程信息
        NINJA_INFO=$(ps -p $NINJA_PID -o pid,etime,cmd --no-headers)
        echo -e "${CYAN}  进程信息:${NC} $NINJA_INFO"
        
        # 检查 CPU 使用率
        CPU_USAGE=$(ps -p $NINJA_PID -o %cpu --no-headers | tr -d ' ')
        echo -e "${CYAN}  CPU 使用率:${NC} ${CPU_USAGE}%"
        
        return 0
    else
        echo -e "${YELLOW}✗${NC} 未发现编译进程"
        return 1
    fi
}

# 检查编译日志
check_build_log() {
    echo ""
    echo -e "${BLUE}[检查]${NC} 编译日志..."
    
    # 查找最新的编译日志
    LATEST_LOG=$(ls -t $HOME/android/build_*.log 2>/dev/null | head -n 1)
    
    if [[ -z "$LATEST_LOG" ]]; then
        echo -e "${YELLOW}✗${NC} 未找到编译日志"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} 最新日志: $(basename $LATEST_LOG)"
    
    # 获取日志修改时间
    LOG_TIME=$(stat -c %y "$LATEST_LOG" | cut -d'.' -f1)
    echo -e "${CYAN}  最后更新:${NC} $LOG_TIME"
    
    # 获取日志大小
    LOG_SIZE=$(du -h "$LATEST_LOG" | cut -f1)
    echo -e "${CYAN}  日志大小:${NC} $LOG_SIZE"
    
    # 检查最后几行
    echo ""
    echo -e "${BLUE}[日志]${NC} 最后 10 行:"
    echo -e "${CYAN}----------------------------------------${NC}"
    tail -n 10 "$LATEST_LOG" | sed 's/^/  /'
    echo -e "${CYAN}----------------------------------------${NC}"
    
    # 检查是否有错误
    if grep -q "failed to build some targets" "$LATEST_LOG"; then
        echo -e "${RED}✗${NC} 检测到编译失败"
        
        # 提取错误信息
        echo ""
        echo -e "${BLUE}[错误]${NC} 最后的错误信息:"
        echo -e "${CYAN}----------------------------------------${NC}"
        grep -i "error" "$LATEST_LOG" | tail -n 5 | sed 's/^/  /'
        echo -e "${CYAN}----------------------------------------${NC}"
        
        return 2
    elif grep -q "build completed successfully" "$LATEST_LOG"; then
        echo -e "${GREEN}✓${NC} 检测到编译成功"
        return 0
    else
        echo -e "${YELLOW}?${NC} 编译状态未知"
        return 3
    fi
}

# 检查编译产物
check_build_output() {
    echo ""
    echo -e "${BLUE}[检查]${NC} 编译产物..."
    
    if [[ ! -d "$WORK_DIR" ]]; then
        echo -e "${YELLOW}✗${NC} 源代码目录不存在"
        return 1
    fi
    
    OUTPUT_DIR="$WORK_DIR/out/target/product/$BUILD_TARGET"
    
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        echo -e "${YELLOW}✗${NC} 编译输出目录不存在"
        return 1
    fi
    
    # 检查 UTM 虚拟机包
    UTM_ZIP=$(find "$OUTPUT_DIR" -name "UTM-VM-lineage-*.zip" 2>/dev/null | head -n 1)
    
    if [[ -n "$UTM_ZIP" ]]; then
        echo -e "${GREEN}✓${NC} 找到 UTM 虚拟机包"
        echo -e "${CYAN}  文件:${NC} $(basename $UTM_ZIP)"
        
        FILE_SIZE=$(du -h "$UTM_ZIP" | cut -f1)
        echo -e "${CYAN}  大小:${NC} $FILE_SIZE"
        
        FILE_TIME=$(stat -c %y "$UTM_ZIP" | cut -d'.' -f1)
        echo -e "${CYAN}  创建时间:${NC} $FILE_TIME"
        
        return 0
    fi
    
    # 检查 LineageOS 镜像
    LINEAGE_IMG=$(find "$OUTPUT_DIR" -name "lineage-*.img" -o -name "lineage-*.iso" 2>/dev/null | head -n 1)
    
    if [[ -n "$LINEAGE_IMG" ]]; then
        echo -e "${GREEN}✓${NC} 找到 LineageOS 镜像"
        echo -e "${CYAN}  文件:${NC} $(basename $LINEAGE_IMG)"
        
        FILE_SIZE=$(du -h "$LINEAGE_IMG" | cut -f1)
        echo -e "${CYAN}  大小:${NC} $FILE_SIZE"
        
        return 0
    fi
    
    # 检查部分编译产物
    if [[ -d "$OUTPUT_DIR" ]]; then
        FILE_COUNT=$(find "$OUTPUT_DIR" -type f 2>/dev/null | wc -l)
        DIR_SIZE=$(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1)
        
        if [[ $FILE_COUNT -gt 0 ]]; then
            echo -e "${YELLOW}?${NC} 找到部分编译产物"
            echo -e "${CYAN}  文件数量:${NC} $FILE_COUNT"
            echo -e "${CYAN}  目录大小:${NC} $DIR_SIZE"
            return 2
        fi
    fi
    
    echo -e "${YELLOW}✗${NC} 未找到编译产物"
    return 1
}

# 检查保存的状态
check_saved_state() {
    echo ""
    echo -e "${BLUE}[检查]${NC} 保存的进度状态..."
    
    if [[ ! -f "$STATE_FILE" ]]; then
        echo -e "${YELLOW}✗${NC} 未找到保存的状态"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} 找到保存的状态"
    
    # 读取状态
    source "$STATE_FILE"
    
    echo -e "${CYAN}  最后完成的步骤:${NC} $LAST_COMPLETED_STEP"
    echo -e "${CYAN}  上次运行时间:${NC} $LAST_RUN_TIME"
    
    return 0
}

# 检查 ccache 状态
check_ccache() {
    echo ""
    echo -e "${BLUE}[检查]${NC} ccache 状态..."
    
    if ! command -v ccache &> /dev/null; then
        echo -e "${YELLOW}✗${NC} ccache 未安装"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} ccache 已安装"
    
    # 检查 ccache 目录
    if [[ ! -d "$HOME/.ccache" ]]; then
        echo -e "${RED}✗${NC} ccache 目录不存在"
        echo -e "${YELLOW}  建议运行:${NC} mkdir -p $HOME/.ccache && ccache -M 50G"
        return 2
    fi
    
    # 检查 ccache 统计
    echo ""
    echo -e "${CYAN}  ccache 统计:${NC}"
    ccache -s | grep -E "cache size|cache hit|cache miss" | sed 's/^/    /'
    
    return 0
}

# 提供建议
provide_suggestions() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${MAGENTA}💡 建议操作${NC}                                          ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 根据检查结果提供建议
    if [[ $BUILD_PROCESS_RUNNING -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} 编译正在进行中"
        echo -e "  ${CYAN}建议:${NC} 等待编译完成，或使用 ${YELLOW}tmux attach${NC} 查看进度"
        echo ""
        echo -e "  ${CYAN}监控命令:${NC}"
        echo -e "    ${YELLOW}watch -n 5 'tail -n 20 $LATEST_LOG'${NC}"
        echo ""
    elif [[ $BUILD_LOG_STATUS -eq 2 ]]; then
        echo -e "${RED}✗${NC} 上次编译失败"
        echo -e "  ${CYAN}建议:${NC}"
        echo -e "    1. 查看错误日志: ${YELLOW}tail -n 50 $LATEST_LOG${NC}"
        echo -e "    2. 修复 ccache: ${YELLOW}rm -rf ~/.ccache && mkdir -p ~/.ccache && ccache -M 50G${NC}"
        echo -e "    3. 重新编译: ${YELLOW}bash ~/android15-utm-ipad-builder/scripts/03-build-android.sh${NC}"
        echo ""
    elif [[ $BUILD_OUTPUT_STATUS -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} 编译已完成"
        echo -e "  ${CYAN}产物位置:${NC} $UTM_ZIP"
        echo -e "  ${CYAN}下一步:${NC}"
        echo -e "    1. 优化产物: ${YELLOW}bash ~/android15-utm-ipad-builder/scripts/04-optimize-output.sh${NC}"
        echo -e "    2. 传输到 iPad: ${YELLOW}bash ~/android15-utm-ipad-builder/scripts/05-transfer-to-ipad.sh${NC}"
        echo ""
    else
        echo -e "${YELLOW}?${NC} 编译状态未知"
        echo -e "  ${CYAN}建议:${NC}"
        echo -e "    1. 检查源代码: ${YELLOW}ls -lh ~/android/lineage${NC}"
        echo -e "    2. 运行智能脚本: ${YELLOW}bash ~/android15-utm-ipad-builder/scripts/00-auto-build-all.sh${NC}"
        echo ""
    fi
}

# 主函数
main() {
    # 执行检查
    check_build_process
    BUILD_PROCESS_RUNNING=$?
    
    check_build_log
    BUILD_LOG_STATUS=$?
    
    check_build_output
    BUILD_OUTPUT_STATUS=$?
    
    check_saved_state
    SAVED_STATE_STATUS=$?
    
    check_ccache
    CCACHE_STATUS=$?
    
    # 提供建议
    provide_suggestions
    
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# 运行主函数
main

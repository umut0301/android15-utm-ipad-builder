#!/bin/bash

################################################################################
# Android 15 编译环境自动化安装脚本
# 适用于: Debian 12 x86_64
# 功能: 安装所有编译依赖、配置工具链、设置 ccache
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

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限运行"
        log_info "请使用: sudo bash $0"
        exit 1
    fi
}

# 检查操作系统
check_os() {
    log_info "检查操作系统..."
    
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法检测操作系统"
        exit 1
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "debian" ]]; then
        log_warning "此脚本专为 Debian 12 设计，您的系统是: $ID"
        read -p "是否继续? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log_success "操作系统检查通过: $PRETTY_NAME"
}

# 检查磁盘空间
check_disk_space() {
    log_info "检查磁盘空间..."
    
    AVAILABLE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    REQUIRED_SPACE=200  # 降低从 300GB，实际 200GB 就足够
    
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
    else
        log_success "内存充足: ${TOTAL_MEM}GB"
    fi
}

# 更新系统包
update_system() {
    log_info "更新系统包列表..."
    
    apt update -qq
    
    log_info "升级已安装的包..."
    apt upgrade -y -qq
    
    log_success "系统更新完成"
}

# 安装基础依赖
install_base_dependencies() {
    log_info "安装基础依赖包..."
    
    apt install -y \
        bc \
        bison \
        build-essential \
        ccache \
        curl \
        flex \
        g++-multilib \
        gcc-multilib \
        git \
        gnupg \
        gperf \
        imagemagick \
        lib32ncurses5-dev \
        lib32readline-dev \
        lib32z1-dev \
        liblz4-tool \
        libncurses5 \
        libncurses5-dev \
        libsdl1.2-dev \
        libssl-dev \
        libxml2 \
        libxml2-utils \
        lzop \
        pngcrush \
        rsync \
        schedtool \
        squashfs-tools \
        xsltproc \
        zip \
        zlib1g-dev \
        > /dev/null 2>&1
    
    log_success "基础依赖安装完成"
}

# 安装 Python 和相关工具
install_python() {
    log_info "安装 Python 和相关工具..."
    
    apt install -y \
        python3 \
        python3-pip \
        python3-dev \
        python-is-python3 \
        > /dev/null 2>&1
    
    log_success "Python 安装完成"
}

# 安装 Java
install_java() {
    log_info "安装 OpenJDK..."
    
    # Debian 12 默认使用 OpenJDK 17
    # Android 15 支持 JDK 11-17
    apt install -y openjdk-17-jdk > /dev/null 2>&1
    
    # 设置默认 Java 版本（允许失败）
    update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java > /dev/null 2>&1 || true
    update-alternatives --set javac /usr/lib/jvm/java-17-openjdk-amd64/bin/javac > /dev/null 2>&1 || true
    
    # 验证 Java 安装
    if ! command -v java &> /dev/null; then
        log_error "Java 安装失败"
        exit 1
    fi
    
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    log_success "Java 安装完成: $JAVA_VERSION"
}

# 安装 Git LFS
install_git_lfs() {
    log_info "安装 Git LFS..."
    
    # 安装 Git LFS 仓库（允许失败）
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash > /dev/null 2>&1 || true
    
    # 安装 Git LFS
    apt install -y git-lfs > /dev/null 2>&1
    
    # 初始化 Git LFS（允许失败）
    git lfs install > /dev/null 2>&1 || true
    
    # 验证安装
    if ! command -v git-lfs &> /dev/null; then
        log_warning "Git LFS 安装失败，但不是必须的"
    else
        log_success "Git LFS 安装完成"
    fi
}

# 安装 repo 工具
install_repo() {
    log_info "安装 repo 工具..."
    
    # 获取实际用户（即使使用 sudo）
    REAL_USER=${SUDO_USER:-$USER}
    REAL_HOME=$(eval echo ~$REAL_USER)
    
    # 创建 bin 目录
    mkdir -p $REAL_HOME/bin
    
    # 下载 repo
    curl https://storage.googleapis.com/git-repo-downloads/repo > $REAL_HOME/bin/repo
    chmod a+x $REAL_HOME/bin/repo
    
    # 设置所有者
    chown $REAL_USER:$REAL_USER $REAL_HOME/bin/repo
    
    # 添加到 PATH（如果还没有）
    if ! grep -q "$REAL_HOME/bin" $REAL_HOME/.bashrc; then
        echo "export PATH=\$HOME/bin:\$PATH" >> $REAL_HOME/.bashrc
        chown $REAL_USER:$REAL_USER $REAL_HOME/.bashrc
    fi
    
    log_success "repo 工具安装完成"
}

# 配置 Git
configure_git() {
    log_info "配置 Git..."
    
    REAL_USER=${SUDO_USER:-$USER}
    
    # 检查是否已配置
    if sudo -u $REAL_USER git config --global user.email > /dev/null 2>&1; then
        log_info "Git 已配置，跳过"
        return
    fi
    
    # 配置 Git
    sudo -u $REAL_USER git config --global user.email "builder@android15.local"
    sudo -u $REAL_USER git config --global user.name "Android Builder"
    sudo -u $REAL_USER git config --global color.ui auto
    
    log_success "Git 配置完成"
}

# 配置 ccache
configure_ccache() {
    log_info "配置 ccache..."
    
    REAL_USER=${SUDO_USER:-$USER}
    REAL_HOME=$(eval echo ~$REAL_USER)
    
    # 设置 ccache 大小为 50GB（允许失败）
    sudo -u $REAL_USER ccache -M 50G > /dev/null 2>&1 || true
    
    # 启用压缩（允许失败）
    sudo -u $REAL_USER ccache -o compression=true > /dev/null 2>&1 || true
    
    # 添加环境变量到 .bashrc
    if ! grep -q "USE_CCACHE" $REAL_HOME/.bashrc; then
        cat >> $REAL_HOME/.bashrc << 'EOF'

# Android 编译优化
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR=$HOME/.ccache
EOF
        chown $REAL_USER:$REAL_USER $REAL_HOME/.bashrc
    fi
    
    log_success "ccache 配置完成 (50GB)"
}

# 创建工作目录
create_work_directories() {
    log_info "创建工作目录..."
    
    REAL_USER=${SUDO_USER:-$USER}
    REAL_HOME=$(eval echo ~$REAL_USER)
    
    # 创建 Android 编译目录
    mkdir -p $REAL_HOME/android/lineage
    chown -R $REAL_USER:$REAL_USER $REAL_HOME/android
    
    log_success "工作目录创建完成: $REAL_HOME/android/lineage"
}

# 安装额外工具
install_extra_tools() {
    log_info "安装额外工具..."
    
    apt install -y \
        vim \
        tmux \
        htop \
        tree \
        wget \
        unzip \
        p7zip-full \
        qemu-utils \
        > /dev/null 2>&1
    
    log_success "额外工具安装完成"
}

# 验证安装
verify_installation() {
    log_info "验证安装..."
    
    ERRORS=0
    
    # 检查 GCC
    if ! command -v gcc &> /dev/null; then
        log_error "GCC 未安装"
        ERRORS=$((ERRORS + 1))
    else
        GCC_VERSION=$(gcc --version | head -n 1)
        log_success "GCC: $GCC_VERSION"
    fi
    
    # 检查 Java
    if ! command -v java &> /dev/null; then
        log_error "Java 未安装"
        ERRORS=$((ERRORS + 1))
    else
        JAVA_VERSION=$(java -version 2>&1 | head -n 1)
        log_success "Java: $JAVA_VERSION"
    fi
    
    # 检查 Python
    if ! command -v python3 &> /dev/null; then
        log_error "Python 未安装"
        ERRORS=$((ERRORS + 1))
    else
        PYTHON_VERSION=$(python3 --version)
        log_success "Python: $PYTHON_VERSION"
    fi
    
    # 检查 repo
    REAL_USER=${SUDO_USER:-$USER}
    REAL_HOME=$(eval echo ~$REAL_USER)
    if [[ ! -f $REAL_HOME/bin/repo ]]; then
        log_error "repo 工具未安装"
        ERRORS=$((ERRORS + 1))
    else
        log_success "repo 工具已安装"
    fi
    
    # 检查 ccache
    if ! command -v ccache &> /dev/null; then
        log_error "ccache 未安装"
        ERRORS=$((ERRORS + 1))
    else
        log_success "ccache 已安装"
    fi
    
    if [[ $ERRORS -gt 0 ]]; then
        log_error "验证失败，发现 $ERRORS 个错误"
        exit 1
    fi
    
    log_success "所有组件验证通过"
}

# 显示摘要
show_summary() {
    echo ""
    echo "========================================"
    echo "  Android 15 编译环境安装完成"
    echo "========================================"
    echo ""
    echo "已安装的组件:"
    echo "  ✓ 基础编译工具 (GCC, Make, etc.)"
    echo "  ✓ Python 3"
    echo "  ✓ OpenJDK 17"
    echo "  ✓ Git + Git LFS"
    echo "  ✓ repo 工具"
    echo "  ✓ ccache (50GB)"
    echo "  ✓ 额外工具"
    echo ""
    echo "工作目录:"
    REAL_USER=${SUDO_USER:-$USER}
    REAL_HOME=$(eval echo ~$REAL_USER)
    echo "  $REAL_HOME/android/lineage"
    echo ""
    echo "下一步:"
    echo "  1. 重新登录或运行: source ~/.bashrc"
    echo "  2. 运行: bash scripts/02-sync-source.sh"
    echo ""
    echo "========================================"
}

# 主函数
main() {
    echo ""
    echo "========================================"
    echo "  Android 15 编译环境自动化安装"
    echo "  适用于: Debian 12 x86_64"
    echo "========================================"
    echo ""
    
    check_root
    check_os
    check_disk_space
    check_memory
    
    echo ""
    log_info "开始安装..."
    echo ""
    
    update_system
    install_base_dependencies
    install_python
    install_java
    install_git_lfs
    install_repo
    configure_git
    configure_ccache
    create_work_directories
    install_extra_tools
    
    echo ""
    verify_installation
    echo ""
    
    show_summary
}

# 运行主函数
main

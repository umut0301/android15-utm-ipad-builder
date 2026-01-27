# Android 15 编译快速参考 - Debian 12 + UTM

## 一键安装脚本

### 完整依赖安装脚本

```bash
#!/bin/bash
# Android 15 编译环境一键安装脚本（Debian 12）

set -e

echo "=========================================="
echo "Android 15 编译环境安装 - Debian 12"
echo "=========================================="

# 更新系统
echo "[1/5] 更新系统包..."
sudo apt update
sudo apt upgrade -y

# 安装编译依赖
echo "[2/5] 安装编译依赖..."
sudo apt install -y \
  bc bison build-essential ccache curl flex g++-multilib \
  gcc-multilib git git-lfs gnupg gperf imagemagick \
  protobuf-compiler python3-protobuf lib32readline-dev \
  lib32z1-dev libdw-dev libelf-dev libgnutls28-dev lz4 \
  libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop \
  pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev \
  lib32ncurses5-dev libncurses5 libncurses5-dev libwxgtk3.0-dev \
  meson glslang-tools python3-mako openjdk-11-jdk

# 创建目录
echo "[3/5] 创建编译目录..."
mkdir -p ~/bin
mkdir -p ~/android/lineage

# 安装 Android SDK tools
echo "[4/5] 安装 Android SDK tools..."
cd ~
wget -q https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip -q platform-tools-latest-linux.zip
rm platform-tools-latest-linux.zip

# 安装 repo 工具
echo "[5/5] 安装 repo 工具..."
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

# 配置环境
echo ""
echo "=========================================="
echo "配置环境变量..."
echo "=========================================="

# 添加到 ~/.profile
cat >> ~/.profile << 'EOF'

# Android SDK tools
if [ -d "$HOME/platform-tools" ] ; then
 PATH="$HOME/platform-tools:$PATH"
fi

# User private bin
if [ -d "$HOME/bin" ] ; then
 PATH="$HOME/bin:$PATH"
fi

# ccache 配置
export USE_CACHE=1
export CCACHE_EXEC=/usr/bin/ccache
EOF

source ~/.profile

# 配置 Git
echo "配置 Git..."
git config --global user.email "builder@example.com"
git config --global user.name "Android Builder"

# 配置 ccache
echo "配置 ccache..."
ccache -M 50G
ccache -o compression=true

echo ""
echo "=========================================="
echo "安装完成！"
echo "=========================================="
echo ""
echo "验证安装："
echo "  - adb version"
echo "  - fastboot --version"
echo "  - repo --version"
echo "  - ccache -s"
echo ""
echo "下一步："
echo "  1. cd ~/android/lineage"
echo "  2. repo init -u https://github.com/LineageOS/android.git -b lineage-23.0 --git-lfs --no-clone-bundle"
echo "  3. repo sync -j4"
echo "  4. source build/envsetup.sh"
echo "  5. lunch virtio_arm64-userdebug"
echo "  6. m -j\$(nproc)"
```

保存为 `install_android_build_env.sh` 并运行：

```bash
chmod +x install_android_build_env.sh
./install_android_build_env.sh
```

---

## 常用命令速查表

### 初始化和同步

```bash
# 初始化 LineageOS 23.0
cd ~/android/lineage
repo init -u https://github.com/LineageOS/android.git -b lineage-23.0 --git-lfs --no-clone-bundle

# 初始化 LineageOS 22.2
repo init -u https://github.com/LineageOS/android.git -b lineage-22.2 --git-lfs --no-clone-bundle

# 同步源代码
repo sync

# 并行同步（4 个线程）
repo sync -j4

# 强制重新同步
repo sync --force-sync

# 检查同步状态
repo status
```

### 编译命令

```bash
# 进入编译目录
cd ~/android/lineage

# 设置编译环境
source build/envsetup.sh

# 列出可用目标
lunch

# 选择特定目标
lunch virtio_arm64-userdebug

# 编译（使用所有 CPU 核心）
m -j$(nproc)

# 编译（指定核心数）
m -j4

# 编译特定模块
m SystemUI
m Settings

# 清理编译输出
make clean

# 完全清理
make distclean

# 编译并输出日志
m -j4 2>&1 | tee build.log
```

### 编译目标选择

```bash
# ARM 64 位（推荐用于 iPad Pro M1）
lunch virtio_arm64-userdebug
lunch virtio_arm64-user

# x86 64 位
lunch virtio_x86_64-userdebug
lunch virtio_x86_64-user

# x86 32 位
lunch virtio_x86-userdebug
lunch virtio_x86-user
```

### 编译产物位置

```bash
# 查看编译输出
cd ~/android/lineage/out/target/product/virtio_arm64/

# 虚拟机镜像
ls -lh VirtuaMachine-utm-*.zip

# 系统镜像
ls -lh system.img
ls -lh vendor.img
ls -lh boot.img

# 验证 ZIP 完整性
unzip -t VirtuaMachine-utm-*.zip
```

### ccache 管理

```bash
# 查看 ccache 统计
ccache -s

# 清空 ccache
ccache -C

# 设置缓存大小（50GB）
ccache -M 50G

# 启用压缩
ccache -o compression=true

# 禁用 ccache
export CCACHE_DISABLE=1
```

### 环境变量

```bash
# 启用缓存
export USE_CACHE=1
export CCACHE_EXEC=/usr/bin/ccache

# 并行编译线程数
export MAKEFLAGS=-j8

# 禁用某些优化（用于调试）
export DISABLE_PROGUARD=true

# 输出详细日志
export VERBOSE=1
```

---

## 编译流程速查

### 快速编译流程（5 分钟设置）

```bash
# 1. 进入目录
cd ~/android/lineage

# 2. 初始化（首次只需一次）
repo init -u https://github.com/LineageOS/android.git -b lineage-23.0 --git-lfs --no-clone-bundle

# 3. 同步源代码（需要 2-8 小时）
repo sync -j4

# 4. 设置编译环境
source build/envsetup.sh

# 5. 选择编译目标
lunch virtio_arm64-userdebug

# 6. 开始编译（需要 1-6 小时）
m -j$(nproc)

# 7. 获取产物
ls -lh out/target/product/virtio_arm64/VirtuaMachine-utm-*.zip
```

### 增量编译（修改代码后）

```bash
cd ~/android/lineage

# 重新编译（使用 ccache 加速）
m -j$(nproc)

# 或清理后重新编译
make clean
m -j$(nproc)
```

---

## 性能调优命令

### 监控编译进度

```bash
# 在另一个终端实时查看
watch -n 5 'ps aux | grep -E "cc1|clang|ld"'

# 查看磁盘使用
watch -n 5 'df -h'

# 查看内存使用
watch -n 5 'free -h'

# 查看 ccache 统计
watch -n 5 'ccache -s'
```

### 优化编译速度

```bash
# 使用最大并行度
m -j$(nproc)

# 启用 ccache 压缩
ccache -o compression=true

# 增加 ccache 大小
ccache -M 100G

# 使用 RAM 磁盘（需要足够内存）
sudo mount -t tmpfs -o size=8G tmpfs /mnt/ramdisk
export OUT_DIR=/mnt/ramdisk/out
```

---

## 故障排查命令

### 诊断编译问题

```bash
# 检查依赖
which adb
which fastboot
which repo
which ccache

# 验证 Java 版本
java -version
javac -version

# 检查 Python
python --version
python3 --version

# 查看编译日志
tail -f ~/android/lineage/build.log

# 搜索编译错误
grep -i "error" ~/android/lineage/build.log

# 检查磁盘空间
df -h
du -sh ~/android/lineage/

# 检查内存
free -h
```

### 清理和重置

```bash
# 清理编译输出
cd ~/android/lineage
make clean

# 完全清理（包括 ccache）
make distclean
ccache -C

# 重新初始化 repo
rm -rf ~/android/lineage/.repo
repo init -u https://github.com/LineageOS/android.git -b lineage-23.0 --git-lfs --no-clone-bundle
repo sync -j4
```

---

## 文件传输命令

### 从虚拟机到主机

```bash
# 使用 scp 传输编译产物
scp ~/android/lineage/out/target/product/virtio_arm64/VirtuaMachine-utm-*.zip user@host:/path/to/destination/

# 使用 rsync 同步
rsync -avz ~/android/lineage/out/target/product/virtio_arm64/ user@host:/path/to/backup/
```

### 共享文件夹（如果配置了）

```bash
# 复制到共享文件夹
cp ~/android/lineage/out/target/product/virtio_arm64/VirtuaMachine-utm-*.zip /mnt/shared/

# 或创建符号链接
ln -s ~/android/lineage/out/target/product/virtio_arm64/VirtuaMachine-utm-*.zip /mnt/shared/
```

---

## 版本选择参考

### LineageOS 版本对应

| LineageOS 版本 | Android 版本 | 状态 | 推荐 |
|---|---|---|---|
| 23.0 | 15 | 最新 | ✅ |
| 22.2 | 14 | 稳定 | ✅ |
| 22.1 | 14 | 稳定 | ✅ |
| 22.0 | 14 | 稳定 | ✅ |
| 21.0 | 13 | 旧版 | - |

### 编译目标选择

| 目标 | 架构 | 推荐场景 | 性能 |
|---|---|---|---|
| virtio_arm64 | ARM 64-bit | iPad Pro M1 (推荐) | 好 |
| virtio_x86_64 | x86 64-bit | x86 主机 | 一般 |
| virtio_x86 | x86 32-bit | 旧系统 | 差 |

---

## 调试命令

### 连接虚拟机设备

```bash
# 列出连接的设备
adb devices

# 连接到虚拟机（需要虚拟机启动 adb）
adb connect <vm-ip>:5555

# 推送文件到虚拟机
adb push local_file /data/

# 从虚拟机拉取文件
adb pull /data/file local_file

# 执行 shell 命令
adb shell "command"

# 查看日志
adb logcat

# 重启虚拟机
adb reboot
```

### 编译调试

```bash
# 启用详细输出
export VERBOSE=1
m -j4

# 编译特定模块并显示详细信息
m -B SystemUI VERBOSE=1

# 查看编译命令
m -n  # 仅显示命令，不执行

# 编译并保存详细日志
m -j4 V=1 2>&1 | tee detailed_build.log
```

---

## 时间估计

### 首次编译

| 硬件配置 | 编译时间 | 备注 |
|---|---|---|
| 4 核, 8GB RAM | 6-8 小时 | 最小配置 |
| 8 核, 16GB RAM | 2-4 小时 | 推荐配置 |
| 16 核, 32GB RAM | 1-2 小时 | 高端配置 |

### 增量编译

| 修改范围 | 编译时间 | 备注 |
|---|---|---|
| 单个文件 | 5-15 分钟 | 使用 ccache |
| 单个模块 | 15-30 分钟 | 使用 ccache |
| 系统镜像 | 30-60 分钟 | 使用 ccache |
| 完整编译 | 1-4 小时 | 首次或清理后 |

---

## 常见错误和解决方案

### 错误 1: `command not found: repo`

```bash
# 解决方案
source ~/.profile
# 或
export PATH=$HOME/bin:$PATH
```

### 错误 2: `No space left on device`

```bash
# 解决方案
ccache -C  # 清空 ccache
make clean  # 清理编译输出
df -h  # 检查磁盘
```

### 错误 3: `Java version mismatch`

```bash
# 解决方案
java -version
update-alternatives --config java
```

### 错误 4: `repo sync` 超时

```bash
# 解决方案
repo sync -j4 --force-sync
# 或重新初始化
repo init -u https://github.com/LineageOS/android.git -b lineage-23.0 --git-lfs --no-clone-bundle
```

---

## 有用的别名

添加到 `~/.bashrc`：

```bash
# Android 编译相关别名
alias android-build-env='source ~/android/lineage/build/envsetup.sh'
alias android-lunch='lunch'
alias android-build='m -j$(nproc)'
alias android-clean='make clean'
alias android-distclean='make distclean'
alias android-ccache-stats='ccache -s'
alias android-ccache-clear='ccache -C'
alias android-sync='repo sync -j4'
alias android-status='repo status'

# 快速导航
alias android-cd='cd ~/android/lineage'
alias android-out='cd ~/android/lineage/out/target/product/virtio_arm64'
```

使用：

```bash
source ~/.bashrc
android-cd
android-build-env
android-lunch
android-build
```

---

## 最后更新

**日期**: 2026 年 1 月 27 日  
**版本**: Android 15 / LineageOS 23.0  
**平台**: Debian 12 on iPad Pro M1 UTM  

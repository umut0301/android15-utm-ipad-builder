# Debian 12 上编译 Android 15 用于 iPad Pro M1 UTM 虚拟机 - 完整指南

## 场景分析

### 用户环境
- **主机**: iPad Pro M1（Apple Silicon）
- **虚拟机平台**: UTM（QEMU 基础）
- **编译环境**: Debian 12（x86_64）
- **目标**: 编译 Android 15 用于 UTM 虚拟机

### 关键架构说明
- iPad Pro M1 运行 UTM 虚拟机
- UTM 虚拟机内运行 Debian 12（x86_64 Linux）
- 在 Debian 12 中编译 Android 15
- 编译产物在 UTM 虚拟机中运行

---

## 第一步：Debian 12 系统准备

### 1.1 系统基础配置

```bash
# 更新系统包
sudo apt update
sudo apt upgrade -y

# 安装基础工具
sudo apt install -y curl wget git build-essential
```

### 1.2 安装 Android 编译必需的包

#### 基础编译工具包
```bash
sudo apt install -y \
  bc bison build-essential ccache curl flex g++-multilib \
  gcc-multilib git git-lfs gnupg gperf imagemagick \
  protobuf-compiler python3-protobuf lib32readline-dev \
  lib32z1-dev libdw-dev libelf-dev libgnutls28-dev lz4 \
  libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop \
  pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev
```

#### Debian 12 特定依赖
```bash
# Debian 12 的 ncurses 库
sudo apt install -y lib32ncurses5-dev libncurses5 libncurses5-dev

# 额外的开发工具
sudo apt install -y libwxgtk3.0-dev
```

#### Android 15 编译额外要求（LineageOS 22.0+）
```bash
sudo apt install -y meson glslang-tools python3-mako
```

### 1.3 安装 Java 开发工具包

Android 15 使用 OpenJDK 11（包含在源代码中），但建议预装：

```bash
# 检查是否已安装
java -version

# 如需安装（可选）
sudo apt install -y openjdk-11-jdk
```

### 1.4 配置 Python 环境

Android 15 需要 Python 3：

```bash
# 检查 Python 3
python3 --version

# 确保 python-is-python3 已安装
sudo apt install -y python-is-python3

# 验证
python --version  # 应该显示 Python 3.x
```

### 1.5 创建编译目录结构

```bash
# 创建必要的目录
mkdir -p ~/bin
mkdir -p ~/android/lineage

# 验证目录
ls -la ~/bin
ls -la ~/android/lineage
```

---

## 第二步：Android SDK 工具链配置

### 2.1 安装 Android SDK Platform Tools

```bash
# 下载最新的 platform-tools
cd ~
wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip

# 解压
unzip platform-tools-latest-linux.zip

# 验证
ls -la ~/platform-tools/
```

### 2.2 配置 PATH 环境变量

编辑 `~/.profile`：

```bash
# 使用编辑器打开
nano ~/.profile

# 添加以下内容（如果不存在）：
# add Android SDK platform tools to path
if [ -d "$HOME/platform-tools" ] ; then
 PATH="$HOME/platform-tools:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
 PATH="$HOME/bin:$PATH"
fi
```

保存并更新环境：

```bash
source ~/.profile

# 验证
echo $PATH | grep platform-tools
echo $PATH | grep ~/bin
```

### 2.3 验证 adb 和 fastboot

```bash
adb version
fastboot --version
```

---

## 第三步：安装 repo 工具

### 3.1 下载 repo 二进制文件

```bash
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

# 验证
repo --version
```

### 3.2 配置 Git

```bash
git config --global user.email "your.email@example.com"
git config --global user.name "Your Name"

# 可选：配置 Change-Id（用于 AOSP/LineageOS 提交）
git config --global trailers.changeid.key "Change-Id"

# 验证配置
git config --global --list
```

---

## 第四步：编译缓存优化

### 4.1 启用 ccache

```bash
# 检查 ccache 是否已安装
ccache --version

# 如未安装
sudo apt install -y ccache

# 配置缓存大小（根据可用磁盘调整）
ccache -M 50G

# 启用压缩以节省空间
ccache -o compression=true

# 验证配置
ccache -s
```

### 4.2 配置环境变量

编辑 `~/.bashrc` 或 `~/.profile`：

```bash
# 添加以下行
export USE_CACHE=1
export CCACHE_EXEC=/usr/bin/ccache

# 应用配置
source ~/.bashrc
```

---

## 第五步：初始化 LineageOS 源代码库

### 5.1 初始化 repo

```bash
cd ~/android/lineage

# 初始化 LineageOS 23.0（最新稳定版本）
repo init -u https://github.com/LineageOS/android.git -b lineage-23.0 --git-lfs --no-clone-bundle

# 或者选择其他版本：
# LineageOS 22.2: repo init -u https://github.com/LineageOS/android.git -b lineage-22.2 --git-lfs --no-clone-bundle
# LineageOS 22.1: repo init -u https://github.com/LineageOS/android.git -b lineage-22.1 --git-lfs --no-clone-bundle
```

### 5.2 同步源代码

```bash
# 基础同步（可能需要数小时）
repo sync

# 或使用并行下载加快速度（例如 4 个并行任务）
repo sync -j4

# 如果中断，可以继续同步
repo sync --force-sync
```

**预计时间**: 取决于网络速度，通常需要 2-8 小时

---

## 第六步：选择编译目标

### 6.1 理解 virtio_* 目标

对于 UTM 虚拟机，需要使用 `virtio_*` 目标：

- **virtio_arm64**: ARM 64 位架构（推荐用于 iPad Pro M1 上的 UTM）
- **virtio_x86**: x86 32 位架构
- **virtio_x86_64**: x86 64 位架构

### 6.2 选择目标

```bash
cd ~/android/lineage

# 列出可用的编译目标
source build/envsetup.sh

# 选择目标（以 virtio_arm64 为例）
lunch virtio_arm64-userdebug

# 或者使用 virtio_arm64-user 用于生产版本
# lunch virtio_arm64-user
```

**目标说明**:
- `userdebug`: 包含调试符号，用于开发和测试
- `user`: 优化版本，用于生产

---

## 第七步：开始编译

### 7.1 编译命令

```bash
# 从 ~/android/lineage 目录开始编译
cd ~/android/lineage

# 基础编译（使用所有可用 CPU 核心）
m -j$(nproc)

# 或指定并行任务数（例如 4 个）
m -j4

# 带详细输出
m -j4 2>&1 | tee build.log
```

### 7.2 编译时间预期

| 配置 | 编译时间 |
|------|--------|
| 4 核 CPU, 8GB RAM | 4-6 小时 |
| 8 核 CPU, 16GB RAM | 2-3 小时 |
| 16 核 CPU, 32GB RAM | 1-2 小时 |

### 7.3 监控编译进度

```bash
# 在另一个终端监控
tail -f ~/android/lineage/build.log

# 或查看 ccache 统计
ccache -s
```

---

## 第八步：获取编译产物

### 8.1 编译完成后

编译成功后，产物位置：

```bash
# 主要输出文件
out/target/product/virtio_arm64/

# 虚拟机镜像文件
out/target/product/virtio_arm64/VirtuaMachine-utm-lineage-*-UNOFFICIAL-virtio_arm64.zip

# 其他重要文件
out/target/product/virtio_arm64/system.img
out/target/product/virtio_arm64/vendor.img
out/target/product/virtio_arm64/boot.img
```

### 8.2 验证编译产物

```bash
# 检查 ZIP 文件
ls -lh out/target/product/virtio_arm64/*.zip

# 验证文件完整性
unzip -t out/target/product/virtio_arm64/VirtuaMachine-utm-*.zip
```

---

## 第九步：在 UTM 中安装和运行

### 9.1 传输编译产物到 iPad

```bash
# 从 Debian 12 虚拟机中复制文件到共享位置
# 或通过网络传输
scp out/target/product/virtio_arm64/VirtuaMachine-utm-*.zip user@host:/path/to/share/
```

### 9.2 在 UTM 中安装虚拟机

1. 在 iPad 上打开 UTM 应用
2. 创建新虚拟机
3. 选择 Linux 系统
4. 导入编译的虚拟机镜像
5. 配置虚拟机参数：
   - CPU 核心数：4-8
   - 内存：2-4GB
   - 存储：20-50GB

### 9.3 虚拟机配置

**渲染器设置**:
- 使用 ANGLE (Metal) 以获得最佳性能
- 或使用 ANGLE (OpenGL)

**虚拟化设置**:
- 如遇问题，禁用 Hypervisor 选项

### 9.4 启动虚拟机

1. 在 UTM 中选择虚拟机
2. 点击启动按钮
3. 等待 Android 15 启动

---

## 故障排查

### 问题 1：编译失败 - 缺少依赖

**症状**: `command not found` 或 `package not found`

**解决方案**:
```bash
# 重新检查所有依赖
sudo apt install -y bc bison build-essential ccache curl flex \
  g++-multilib gcc-multilib git git-lfs gnupg gperf imagemagick \
  protobuf-compiler python3-protobuf lib32readline-dev lib32z1-dev \
  libdw-dev libelf-dev libgnutls28-dev lz4 libsdl1.2-dev libssl-dev \
  libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools \
  xsltproc zip zlib1g-dev lib32ncurses5-dev libncurses5 libncurses5-dev \
  meson glslang-tools python3-mako
```

### 问题 2：源代码同步超时

**症状**: `repo sync` 中断或超时

**解决方案**:
```bash
# 使用并行下载
repo sync -j4 --force-sync

# 或重新初始化
repo init -u https://github.com/LineageOS/android.git -b lineage-23.0 --git-lfs --no-clone-bundle
repo sync --force-sync
```

### 问题 3：磁盘空间不足

**症状**: `No space left on device`

**解决方案**:
```bash
# 清理 ccache
ccache -C

# 清理编译输出
cd ~/android/lineage
make clean

# 检查磁盘使用
df -h
du -sh ~/android/lineage/
```

### 问题 4：虚拟机无法启动

**症状**: UTM 虚拟机启动失败或黑屏

**解决方案**:
1. 检查虚拟机配置（CPU、内存、存储）
2. 尝试不同的渲染器（ANGLE Metal vs OpenGL）
3. 禁用虚拟化模式
4. 检查 UTM 日志

### 问题 5：编译很慢

**症状**: 编译进度缓慢

**优化方案**:
```bash
# 增加并行任务数
m -j8  # 或更高，根据 CPU 核心数

# 启用 ccache 压缩
ccache -o compression=true

# 使用 RAM 磁盘加快编译
sudo mount -t tmpfs -o size=4G tmpfs /mnt/ramdisk
export OUT_DIR=/mnt/ramdisk/out
```

---

## 性能优化建议

### 1. 虚拟机配置优化

```bash
# 在 Debian 12 虚拟机中
# 分配足够的资源给编译任务
# 推荐：8 核 CPU, 16GB RAM, SSD 存储
```

### 2. 编译优化

```bash
# 使用最大并行度
m -j$(nproc)

# 启用 ccache
export USE_CACHE=1
export CCACHE_EXEC=/usr/bin/ccache

# 增加 ccache 大小
ccache -M 100G
```

### 3. 网络优化

```bash
# 使用国内镜像源（如适用）
# 或配置 Git 代理以加快源代码下载
```

---

## 完整编译流程总结

```bash
# 1. 系统准备
sudo apt update && sudo apt upgrade -y
sudo apt install -y [所有依赖包]

# 2. 目录创建
mkdir -p ~/bin ~/android/lineage

# 3. 工具安装
wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip platform-tools-latest-linux.zip
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

# 4. 环境配置
source ~/.profile
git config --global user.email "your@email.com"
git config --global user.name "Your Name"

# 5. 源代码初始化
cd ~/android/lineage
repo init -u https://github.com/LineageOS/android.git -b lineage-23.0 --git-lfs --no-clone-bundle

# 6. 源代码同步
repo sync -j4

# 7. 编译环境设置
source build/envsetup.sh
lunch virtio_arm64-userdebug

# 8. 开始编译
m -j$(nproc)

# 9. 获取产物
ls -lh out/target/product/virtio_arm64/VirtuaMachine-utm-*.zip
```

---

## 重要注意事项

### ⚠️ 非官方支持
- virtio_* 目标由 LineageOS 维护者维护，不提供官方保证
- 不会推送 OTA 更新，需要手动更新

### ⚠️ 编译时间长
- 首次编译可能需要 2-8 小时
- 后续编译会更快（使用 ccache）

### ⚠️ 存储空间大
- 源代码 + 编译输出需要 300GB+ 空间
- 建议使用 SSD 以获得最佳性能

### ⚠️ 网络要求
- 需要稳定的网络连接
- 源代码下载可能需要数小时

---

## 参考资源

- LineageOS Wiki: https://wiki.lineageos.org/
- AOSP 编译指南: https://source.android.com/docs/setup/build/building
- UTM 文档: https://docs.getutm.app/
- Android 15 发布说明: https://developer.android.com/about/versions/15

---

## 许可证和致谢

本指南基于 LineageOS 官方文档和 AOSP 编译指南，遵循相应的开源许可证。

**最后更新**: 2026 年 1 月 27 日
**适用版本**: Android 15 / LineageOS 23.0
**目标平台**: iPad Pro M1 + UTM + Debian 12

<div align="center">

# 🛠️ apt-helper.sh

**Debian / Ubuntu 系系统的交互式 APT 包管理助手**

![Bash](https://img.shields.io/badge/Bash-4.0%2B-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Debian%20%7C%20Ubuntu-E95420?style=flat-square&logo=ubuntu&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

一行命令完成安装、卸载、升级，全程彩色日志，版本信息一目了然。

</div>

---

## ✨ 功能亮点

| 功能 | 说明 |
|------|------|
| 📦 **安装** | 自动刷新软件源，安装完成后显示实际版本号 |
| 🗑️ **卸载** | `purge` + `autoremove` 双重清理，不留残留配置 |
| ⬆️ **升级** | 对比当前版本与候选版本，有新版才执行，避免无效操作 |
| 🎨 **彩色日志** | 成功 / 信息 / 警告 / 失败四色分级，输出清晰 |
| 🖥️ **交互模式** | 无参数运行自动进入菜单引导，手动操作零门槛 |
| 🔒 **安全退出** | `set -euo pipefail` 任意步骤失败立即终止，不留脏状态 |

---

## 🚀 快速开始

```bash
# 赋予执行权限
chmod +x apt-helper.sh

# 安装一个包
sudo bash apt-helper.sh install nginx

# 或者直接进入交互菜单
sudo bash apt-helper.sh
```

---

## 📖 用法

### 命令行模式

```
sudo bash apt-helper.sh <操作> [包名]
```

| 操作 | 简写 | 说明 |
|------|------|------|
| `install` | `i` | 安装指定包 |
| `uninstall` | `u` | 卸载并清理指定包 |
| `update` | `up` | 检查并升级指定包 |

**示例：**

```bash
sudo bash apt-helper.sh install curl        # 安装 curl
sudo bash apt-helper.sh i htop              # 简写安装 htop
sudo bash apt-helper.sh uninstall vim       # 卸载 vim
sudo bash apt-helper.sh update git          # 升级 git
```

### 交互模式

不带参数运行，跟着菜单操作即可：

```
$ sudo bash apt-helper.sh

请选择操作类型:
1) 安装(install)
2) 卸载(uninstall)
3) 升级(update)
输入数字或指令: 1
请输入软件包名(例如 nginx): curl

[信息] 正在准备安装: curl
[信息] 安装成功: curl，当前版本: 7.88.1-10
```

---

## 🔍 操作详解

### 📦 install — 安装

```bash
sudo bash apt-helper.sh install <包名>
```

1. 静默执行 `apt-get update -qq` 刷新软件源
2. 执行 `apt-get install -y` 安装
3. 通过 `dpkg-query` 查询并展示已安装版本
4. 包名错误或网络异常时打印 `[失败]` 并以状态码 `1` 退出

### 🗑️ uninstall — 卸载

```bash
sudo bash apt-helper.sh uninstall <包名>
```

1. 通过 `dpkg-query` 精确检查安装状态
2. 未安装则打印 `[警告]` 并跳过，不报错
3. `apt-get purge -y` — 删除程序及其配置文件
4. `apt-get autoremove -y` — 清理孤立依赖
5. 任意步骤失败立即报错退出，不继续执行

> ⚠️ **注意**：`purge` 会**同时删除配置文件**，与 `remove` 不同。如需保留配置，请手动执行 `apt-get remove`。

### ⬆️ update — 升级

```bash
sudo bash apt-helper.sh update <包名>
```

1. 静默刷新软件源
2. `apt-cache policy` 对比 `Installed` 与 `Candidate` 版本
3. 版本相同 → 提示已是最新，退出
4. 检测到新版本 → 显示版本差异，执行 `apt-get install --only-upgrade`

---

## 🎨 日志格式

```
[成功]   操作成功完成          —— 绿色
[信息]   一般过程提示          —— 默认色
[警告]   非致命警告（会继续）  —— 黄色
[失败]   致命错误（脚本退出）  —— 红色
```

---

## ⚙️ 环境要求

- **系统**：Debian / Ubuntu 及其衍生发行版（任何使用 `apt` 的系统）
- **Shell**：Bash 4.0+
- **权限**：需要 `sudo` 或 root 权限
- **依赖**：`apt-get` · `apt-cache` · `dpkg-query`（系统自带，无需额外安装）

---

## ⚠️ 注意事项

**`set -euo pipefail` 严格模式**：任何命令失败、未定义变量或管道错误都会导致脚本立即终止，防止错误被忽略后继续执行产生意外后果。

**`uninstall` 使用 `purge` 而非 `remove`**：会同时删除软件的配置文件。如果你需要保留配置，请直接使用 `apt-get remove`。

**`update` 仅升级单个指定包**：不会触发全局系统升级，安全可控。

**已知缺陷**：脚本 `uninstall` 函数中调用了 `log_error`，但该函数未定义，卸载失败时会提示 `command not found`。可在脚本中补充：

```bash
log_error(){ echo -e "${RED}[错误]${NC} $1"; }
```

---

## 📁 脚本结构

```
apt-helper.sh
├── 常量定义        # 终端颜色码（RED / GREEN / YELLOW / NC）
├── 权限检查        # UID 检测，必须 root/sudo 运行
├── log_success()   # 绿色成功日志
├── log_info()      # 默认信息日志
├── log_warn()      # 黄色警告日志
├── install_pkg()   # 刷新源 → 安装 → 展示版本
├── uninstall_pkg() # 状态检查 → purge → autoremove
├── update_pkg()    # 刷新源 → 版本对比 → 条件升级
└── main()          # 参数解析 + 交互菜单入口
```

---

<div align="center">

Made with ❤️ for the Linux command line

</div>


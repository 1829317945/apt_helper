#!/bin/bash

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# 检查root权限
if [[ "$UID" -ne 0 ]];then
  echo -e "${RED}[错误]${NC}此脚本必须以sudo权限运行"
  exit 1
fi
log_success(){ echo -e "${GREEN}[成功]${NC} $1";}
log_info(){ echo -e "${NC}[信息]${NC} $1";}
log_warn(){ echo -e "${YELLOW}[警告]${NC} $1";}
install_pkg(){
  local pkg=$1
  log_info "正在准备安装: $pkg"
# 更新软件源(静默模式)
  apt-get update -qq
  if apt-get install -y "$pkg";then
      local version 
      version=$(dpkg-query -W -f="${Version}" "$pkg" 2>/dev/null || echo "未知")
      log_info "安装成功: $pkg,当前版本: $version"
  else
      echo -e "${RED}[失败]${NC} 无法安装 $pkg,请检查包名是否正确或网络连接."
      exit 1
  fi
}
uninstall_pkg() {
  local pkg=$1
  log_info "正在准备卸载: $pkg"

  # 用 dpkg-query 检查安装状态，避免正则特殊字符问题
  if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
    log_warn "包 $pkg 未安装，跳过卸载."
    return 0
  fi

  log_info "--- 正在彻底移除: $pkg ---"

  # 检查每步返回值，失败立即报错退出
  apt-get purge -y "$pkg"  || { log_error "purge $pkg 失败"; return 1; }
  apt-get autoremove -y    || { log_error "autoremove 失败"; return 1; }

  log_success "$pkg 及其相关残留已彻底清理."
}

update_pkg(){
   local pkg=$1
   log_info "正在检查 $pkg 的版本信息"
   apt-get update -qq
   local installed_ver
   local candidate_ver
   installed_ver=$(apt-cache policy "$pkg" | grep "Installed:" | awk '{print $2}')
   candidate_ver=$(apt-cache policy "$pkg" | grep "Candidate:" | awk '{print $2}')
   log_info "当前版本: $installed_ver"
   log_info "最新版本: $candidate_ver"
   if [[ "$installed_ver" == "$candidate_ver" ]];then
     echo "$pkg 已经是最新版本,无需更新"
   else
     echo "$pkg 检测到新版本!准备从 $installed_ver 升级到 $candidate_ver..."
     if apt-get install -y --only-upgrade "$pkg";then
       log_success "$pkg 已成功升级至 $candidate_ver"
     else
        echo -e "${RED}[失败]${NC} $pkg 升级过程中出现错误"
        exit 1
     fi
   fi
}
main(){
  local action=${1:-""}
  local name=${2:-""}
  if [[ -z "$action" ]];then
    echo -e "${YELLOW}请选择操作类型:${NC}"
    echo "1) 安装(install)"
    echo "2) 卸载(uninstall)"
    echo "3) 升级(update)"
    read -p "输入数字或指令: " input_action
    case "$input_action" in
      1|install) action="install";;
      2|uninstall) action="uninstall";;
      3|update) action="update";;
      *) echo"无效选择"; exit 1;;
    esac
  fi
  if [[ -z "$name" ]];then
    read -p "请输入软件包名(例如 nginx): " name
  fi
  case "$action" in
    install|i) install_pkg "$name";;
    uninstall|u) uninstall_pkg "$name";;
    update|up) update_pkg "$name";;
    *) echo "用法: sudo $0 {install|uninstall|update} [包名]"; exit 1;;
  esac
}
main "$@"
    




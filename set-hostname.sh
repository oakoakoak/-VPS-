bash <(cat <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
if [[ $EUID -ne 0 ]]; then
  echo "请以 root 身份运行本脚本。"
  exit 1
fi
echo "===================================="
echo "      Oakley 一键修改主机名"
echo "===================================="
read -rp "请输入新的主机名（直接回车可取消）: " NEW_HOSTNAME
if [[ -z "$NEW_HOSTNAME" ]]; then
  echo "已取消：未输入主机名。"
  exit 0
fi
echo "设置主机名为：$NEW_HOSTNAME"
# 备份当前 hosts 和 /etc/hostname
cp -a /etc/hosts /etc/hosts.bak.$(date +%s) 2>/dev/null || true
cp -a /etc/hostname /etc/hostname.bak.$(date +%s) 2>/dev/null || true

# 设置 hostname
hostnamectl set-hostname "$NEW_HOSTNAME"
# 写入 /etc/hostname（兼容不使用 systemd 的场景）
echo "$NEW_HOSTNAME" > /etc/hostname

# 修改 /etc/hosts 中的 127.0.1.1 条目，若无则追加
if grep -q '^127\.0\.1\.1' /etc/hosts; then
  # 保留可能的其它字段（如域名），替换主机名字段为新主机名
  sed -i "s/^127\.0\.1\.1.*/127.0.1.1 $NEW_HOSTNAME/" /etc/hosts
else
  # 若系统只有 127.0.0.1 localhost，则添加 127.0.1.1 条
  echo "127.0.1.1 $NEW_HOSTNAME" >> /etc/hosts
fi

echo
echo "✅ 主机名已设置为：$(hostname)"
echo
echo "已更新："
echo " - /etc/hostname (写入新主机名)"
echo " - /etc/hosts (已替换或新增 127.0.1.1 行)"
echo
echo "备份文件（如需回滚）："
ls -1 /etc/hosts.bak.* 2>/dev/null || true
ls -1 /etc/hostname.bak.* 2>/dev/null || true
echo
echo "提示：无需重启即可在新 shell/新会话中看到主机名。若某些服务仍显示旧名，重启或重新登录即可。"
echo
echo "如需回滚到备份（举例）:"
echo "  sudo cp /etc/hosts.bak.<timestamp> /etc/hosts && sudo cp /etc/hostname.bak.<timestamp> /etc/hostname && hostnamectl set-hostname \$(cat /etc/hostname)"
echo
echo "完成。"
SCRIPT
)

#!/usr/bin/env bash
# ============================================================
#  customize_airootfs.sh — выполняется mkarchiso внутри chroot
#  Здесь настраивается LIVE-среда (не установленная система).
# ============================================================
set -e -u

echo "[farchios] настройка live-среды"

## ---------- Локаль ----------
locale-gen

## ---------- Скелет домашней папки ----------
# ВАЖНО: пишем skel ДО useradd — useradd копирует его в момент создания.
mkdir -p /etc/skel/.config
cat > /etc/skel/.config/kdeglobals <<'EOF'
[General]
ColorScheme=BreezeDark
Name=Breeze Dark

[Icons]
Theme=breeze-dark
EOF

install -Dm644 /usr/local/share/farchios/fastfetch.jsonc \
    /etc/skel/.config/fastfetch/config.jsonc

## ---------- Live-пользователь ----------
if ! id farchios &>/dev/null; then
    useradd -m -G wheel,video,audio,optical,storage,input,render,lp,network,power,gamemode \
        -s /bin/bash -c "FarchiOs Live" farchios
fi
passwd -d farchios

# Пароль не нужен, sudo без пароля — это live-среда.
echo 'farchios ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/10-farchios-live
chmod 440 /etc/sudoers.d/10-farchios-live

# root без пароля в live (стандартная практика live-ISO)
passwd -d root 2>/dev/null || true

## ---------- Автологин в SDDM ----------
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/10-farchios.conf <<'EOF'
[Autologin]
User=farchios
Session=plasma
Relogin=false
EOF

## ---------- Сервисы ----------
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable fstrim.timer
systemctl enable systemd-timesyncd.service
systemctl enable sddm.service
# В live firstboot не нужен
systemctl disable farchios-firstboot.service 2>/dev/null || true

## ---------- multilib внутри образа ----------
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    sed -i 's/^#\[multilib\]/[multilib]/; s/^#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/' /etc/pacman.conf
fi

## ---------- Зеркала ----------
if command -v reflector >/dev/null 2>&1; then
    reflector --latest 12 --sort rate --protocol https \
        --save /etc/pacman.d/mirrorlist 2>/dev/null || true
fi

## ---------- MOTD ----------
cat > /etc/motd <<'EOF'

  FarchiOs (live) — игровая система на базе Arch Linux
  ────────────────────────────────────────────────────
  sudo farchios install   установить на диск
  sudo farchios gpu       драйверы GPU
  sudo farchios tune      тюнинг производительности
  farchios doctor         диагностика

EOF

## ---------- Права ----------
chown -R farchios:farchios /home/farchios
chmod 700 /root

echo "[farchios] live-среда готова"

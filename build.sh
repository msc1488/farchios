#!/usr/bin/env bash
# ============================================================
#  FarchiOs — сборка ISO
#  Запускать на Arch Linux (или в контейнере/WSL) от root:
#      sudo ./build.sh
#  Флаги:
#      --no-validate   не проверять имена пакетов
#      --clean         удалить work/ перед сборкой
#      --quick         без сжатия xz (быстрая тестовая сборка)
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="$ROOT/iso/farchios"
WORK="$ROOT/work"
OUT="$ROOT/out"

VALIDATE=1
CLEAN=0
QUICK=0

for arg in "$@"; do
    case "$arg" in
        --no-validate) VALIDATE=0 ;;
        --clean)       CLEAN=1 ;;
        --quick)       QUICK=1 ;;
        -h|--help)     sed -n '2,14p' "$0"; exit 0 ;;
        *) echo "Неизвестный флаг: $arg" >&2; exit 1 ;;
    esac
done

c_ok()   { printf '\e[32m✓\e[0m %s\n' "$*"; }
c_warn() { printf '\e[33m!\e[0m %s\n' "$*"; }
c_err()  { printf '\e[31m✗\e[0m %s\n' "$*" >&2; }
c_step() { printf '\n\e[1m==> %s\e[0m\n' "$*"; }

# ---------------------------------------------------------------- проверки
[[ ${EUID} -eq 0 ]] || { c_err "Запусти от root: sudo ./build.sh"; exit 1; }
[[ -f "$PROFILE/profiledef.sh" ]] || { c_err "Профиль не найден: $PROFILE"; exit 1; }

if ! command -v mkarchiso >/dev/null 2>&1; then
    c_warn "archiso не установлен — устанавливаю"
    pacman -Sy --needed --noconfirm archiso
fi

# ВАЖНО: mkarchiso берёт репозитории из профиля (iso/farchios/pacman.conf),
# а не из /etc/pacman.conf. Проверяем именно профиль.
if ! grep -q '^\[multilib\]' "$PROFILE/pacman.conf"; then
    c_err "В профиле нет [multilib] — Steam и lib32-* не встанут."
    exit 1
fi

c_step "Синхронизация баз данных пакетов"
pacman -Sy --noconfirm >/dev/null

# ---------------------------------------------------------------- валидация
if (( VALIDATE )); then
    c_step "Проверка имён пакетов"
    # Валидируем через pacman.conf ПРОФИЛЯ: только там гарантированно
    # включён multilib, даже если на хосте он выключен.
    VCONF="$PROFILE/pacman.conf"
    pacman -Sy --config "$VCONF" --noconfirm >/dev/null 2>&1 || true

    mapfile -t PKGS < <(grep -vE '^[[:space:]]*(#|$)' "$PROFILE/packages.x86_64")
    missing=()
    for p in "${PKGS[@]}"; do
        pacman -Si --config "$VCONF" "$p" >/dev/null 2>&1 || missing+=("$p")
    done
    if (( ${#missing[@]} > 0 )); then
        c_err "Не найдены в репозиториях: ${missing[*]}"
        c_err "Убери их из iso/farchios/packages.x86_64 или добавь репозиторий."
        exit 1
    fi
    c_ok "Все ${#PKGS[@]} пакетов найдены"
fi

# ---------------------------------------------------------------- сборка
if (( CLEAN )); then
    c_step "Очистка work/"
    rm -rf "$WORK"
fi
mkdir -p "$WORK" "$OUT"

if (( QUICK )); then
    c_warn "Быстрый режим: zstd-12 вместо xz — сборка в 3–5 раз быстрее, ISO больше"
    cp -a "$PROFILE/profiledef.sh" "$PROFILE/profiledef.sh.farchios-backup"
    # Всегда восстанавливаем исходник, даже если сборка упала (set -e).
    trap 'mv -f "$PROFILE/profiledef.sh.farchios-backup" "$PROFILE/profiledef.sh" 2>/dev/null || true' EXIT
    sed -i "s/^airootfs_image_tool_options=.*/airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '12')/" \
        "$PROFILE/profiledef.sh"
fi

c_step "Сборка ISO (это долго: 15–40 минут в зависимости от железа)"
mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"

# ---------------------------------------------------------------- итог
ISO=$(find "$OUT" -maxdepth 1 -name '*.iso' -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
if [[ -z "$ISO" ]]; then
    c_err "ISO не создан — смотри лог выше"
    exit 1
fi

c_step "Готово"
sha256sum "$ISO" | tee "${ISO}.sha256"
c_ok "Образ: $ISO"
c_ok "Размер: $(du -h "$ISO" | cut -f1)"

# Отдаём файлы пользователю, который вызвал sudo
if [[ -n "${SUDO_USER:-}" ]]; then
    chown -R "$SUDO_USER":"$(id -gn "$SUDO_USER")" "$OUT" "$WORK" 2>/dev/null || true
fi

cat <<EOF

Записать на флешку (Linux):
  sudo dd if=$ISO of=/dev/sdX bs=4M status=progress oflag=sync

Записать на флешку (Windows, Rufus):
  Режим: DD image mode, раздел GPT + UEFI

Проверить в виртуалке:
  qemu-system-x86_64 -enable-kvm -m 8G -smp 4 -cdrom "$ISO" \\
                     -drive file=disk.qcow2,format=qcow2
EOF

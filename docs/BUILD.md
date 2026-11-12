# Сборка FarchiOs: подробно

## Окружения

| Окружение | Годится | Комментарий |
|---|---|---|
| Arch Linux | ✅ | идеально |
| Docker (любая ОС) | ✅ | нужен `--privileged` |
| WSL2 + Arch | ✅ | медленно в `/mnt/c` |
| WSL2 + Ubuntu | ⚠️ | можно, но нужно ставить `pacman`/`archiso` вручную — не рекомендую |
| Windows напрямую | ❌ | нет `mount`/`chroot`/loop |
| macOS | ❌ | нет loop-устройств |

## Первая сборка

```bash
# 1. Проверить синтаксис скриптов
make lint

# 2. Проверить, что все пакеты существуют
make validate

# 3. Собрать
sudo ./build.sh --clean
```

Ожидаемое время: 15–40 минут на 8 ядрах. Первая сборка дольше (скачивание
~2000 пакетов, ~1.5 ГБ).

## Где смотреть ошибки

| Этап | Лог |
|---|---|
| Пакеты | вывод `pacstrap` в консоли |
| chroot-скрипты | `work/x86_64/airootfs/var/log/` + консоль |
| initramfs | консоль, ищи `mkinitcpio` |
| squashfs | консоль, ищи `mksquashfs` |
| загрузчик | консоль, ищи `systemd-boot` / `syslinux` |

Частичное дерево сборки остаётся в `work/` — можно войти и посмотреть:

```bash
sudo arch-chroot work/x86_64/airootfs
```

## Частые ошибки

### `failed to install packages`
Пакет переименован или удалён из Arch. Проверь:

```bash
pacman -Si <имя>
```

Если пакет переехал в AUR — убери его из `packages.x86_64` и добавь установку
в `farchios-postinstall`.

### `losetup: cannot find an unused loop device`
Контейнер без `--privileged`. Или в системе закончились loop-устройства:

```bash
sudo modprobe -r loop && sudo modprobe loop max_loop=64
```

### `Not enough space`
Нужно ~12 ГБ в `work/` и ~4 ГБ в `out/`.

### Сборка падает на `grub-mkrescue`
Не установлен `libisoburn`/`mtools`. В Docker-образе они есть.

### ISO грузится, но нет графики
В меню загрузчика выбери `failsafe`. Если помогло — проблема в драйвере GPU;
загружайся так и запусти `sudo farchios gpu`.

## Тестирование ISO

### QEMU (быстро, без флешки)

```bash
qemu-system-x86_64 \
  -enable-kvm -cpu host -smp 4 -m 8192 \
  -drive file=farchios.qcow2,format=qcow2,if=virtio \
  -cdrom out/farchios-*.iso \
  -boot d -vga virtio -display gtk
```

Создать диск заранее:

```bash
qemu-img create -f qcow2 farchios.qcow2 40G
```

### UEFI-тест

```bash
qemu-system-x86_64 -enable-kvm -m 8192 -smp 4 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \
  -cdrom out/farchios-*.iso -boot d
```

### VirtualBox / VMware
Просто подключи ISO как DVD. Для VirtualBox включи EFI в настройках системы.

## Воспроизводимость

`mkarchiso` поддерживает `SOURCE_DATE_EPOCH`:

```bash
SOURCE_DATE_EPOCH=$(git log -1 --format=%ct) sudo -E ./build.sh
```

Это фиксирует версию ISO в `profiledef.sh` и делает сборки сравнимыми.

## Обновление профиля

Когда Arch меняет `releng`-профиль (новый хук, параметры ядра), полезно
свериться:

```bash
pacman -Ql archiso | grep releng
diff -r /usr/share/archiso/configs/releng iso/farchios
```

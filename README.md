# FarchiOs

**Игровой дистрибутив Linux на базе Arch. «Arch, но из коробки готов к играм».**

FarchiOs — это archiso-профиль, который собирает загрузочный ISO с KDE Plasma,
Steam, Lutris, Wine, GameMode, Gamescope, MangoHud и включённым тюнингом
производительности. Плюс утилита `farchios`, которая ставит драйверы GPU по
факту железа и объясняет, что делать дальше.

```
   ____                 _     _    ___
  / __/__ _ _ __ ___| |__ (_)  / _ \  ___
 / _// _` | '__/ __| '_ \| | | | | |/ __|
/ /_| (_| | | | (__| | | | | | |_| |\__ \
\____\__,_|_|  \___|_| |_|_|  \___/ |___/
```

---

## Что уже есть

| Слой | Что внутри |
|---|---|
| База | Arch Linux (rolling), ядро `linux` + `linux-firmware`, `mkinitcpio` |
| Рабочий стол | KDE Plasma 6 (Wayland), SDDM с автологином в live-режиме |
| Графика | Mesa, Vulkan (AMD/Intel/NVIDIA), VA-API, 32-битные библиотеки |
| Игры | Steam, Lutris, Wine + Mono, vkd3d, GameMode, Gamescope, MangoHud, OBS |
| Звук | PipeWire + WirePlumber, поддержка JACK |
| Тюнинг | sysctl-профиль, zram-swap, `ananicy-cpp`, `irqbalance`, `earlyoom`, udev-правила для NVMe |
| Установка | `archinstall` с готовым списком пакетов + `farchios-postinstall` |
| Брендинг | `os-release`, логотип, обои, конфиг fastfetch (SVG-исходники) |

## Чего пока нет

Честно, чтобы не было сюрпризов:

- **Калибровка и собственное ядро.** Сейчас используется штатное `linux`. Патчи
  BORE/CachyOS подключаются опцией в `iso/farchios/pacman.conf` и описаны в
  [docs/ROADMAP.md](docs/ROADMAP.md).
- **Графический установщик (Calamares).** Используется `archinstall` —
  надёжнее и не требует AUR на этапе сборки.
- **Подписанные образы и свой репозиторий.** Пока сборка локальная.
- **Готовый ISO в репозитории.** Собрать нужно один раз самому: см. ниже.

---

## Сборка

> **Важно:** собрать ISO можно **только в Linux-окружении**.
> `archiso` использует `mount`, loop-устройства и `chroot` — на самом Windows
> это невозможно. Все три способа ниже дают одинаковый результат.

### Способ 1 — Docker (рекомендую на Windows)

```powershell
cd C:\Users\SystemX\Desktop\FarchiOs
.\build.ps1                  # сам определит Docker или WSL
.\build.ps1 -Mode docker -Clean
```

Или вручную:

```powershell
docker build -t farchios-builder .\docker
docker run --rm --privileged -v "${PWD}:/build" farchios-builder
```

Флаг `--privileged` обязателен: без него `mkarchiso` не создаст loop-устройства.

### Способ 2 — WSL2 с Arch

```powershell
wsl --install -d Arch            # или установи "Arch Linux" из Microsoft Store
.\build.ps1 -Mode wsl -Distro Arch
```

Или внутри WSL:

```bash
sudo pacman -Sy --needed archiso
cd /mnt/c/Users/SystemX/Desktop/FarchiOs
sudo ./build.sh
```

> Сборка внутри `/mnt/c` (drvfs) работает, но медленно. Если время важно —
> скопируй проект в `~/farchios` внутри WSL.

### Способ 3 — на реальном Arch

```bash
sudo pacman -Sy --needed archiso
sudo ./build.sh
```

Полезные флаги:

| Флаг | Что делает |
|---|---|
| `--clean` | удалить `work/` перед сборкой |
| `--quick` | zstd-12 вместо xz — в 3–5 раз быстрее, ISO больше |
| `--no-validate` | не проверять имена пакетов |

Результат: `out/farchios-YYYY.MM.DD-x86_64.iso` + `.sha256`.

### Запись на флешку

- **Windows:** Rufus → выбери ISO → **DD image mode** (не ISO mode).
- **Linux:** `sudo dd if=out/farchios-*.iso of=/dev/sdX bs=4M status=progress oflag=sync`

---

## Использование

Live-режим — полноценная система, можно играть прямо с флешки (медленно) или
проверить железо.

```bash
farchios welcome        # что делать дальше
farchios info           # версия, ядро, GPU, состояние тюнинга
farchios doctor         # диагностика игрового стека
sudo farchios doctor --fix
sudo farchios gpu       # поставить драйверы под твою видеокарту
sudo farchios tune      # применить профиль производительности
sudo farchios install   # установка на диск (archinstall)
```

После установки:

```bash
sudo farchios-postinstall   # доводит систему до состояния «как с завода»
```

### Игровые параметры запуска

```bash
# Steam → Свойства игры → Параметры запуска:
gamemoderun mangohud %command%

# С Gamescope (фиксированное разрешение/частота):
gamemoderun gamescope -W 2560 -H 1440 -r 144 -f -- %command%
```

---

## Структура проекта

```
FarchiOs/
├── build.sh                  сборка ISO (Arch / Docker / WSL)
├── build.ps1                 обёртка для Windows
├── Makefile                  make iso | quick | validate | lint
├── docker/
│   ├── Dockerfile            образ с archiso
│   └── build-in-container.sh
├── iso/farchios/             ← сам дистрибутив
│   ├── profiledef.sh         имя, версия, режимы загрузки
│   ├── packages.x86_64       список пакетов
│   ├── pacman.conf           репозитории на этапе сборки
│   ├── grub/ syslinux/ efiboot/   загрузчики
│   └── airootfs/             файловая система образа
│       ├── etc/              os-release, sysctl, udev, systemd, sddm
│       ├── root/customize_airootfs.sh
│       └── usr/local/
│           ├── bin/          farchios, farchios-gpu-setup, ...
│           └── share/farchios/   брендинг, fastfetch, sysctl
├── docs/
│   ├── BUILD.md              подробно про сборку и отладку
│   ├── ARCHITECTURE.md       как устроен дистрибутив
│   ├── GAMING.md             настройка игр, Proton, античит
│   └── ROADMAP.md            что дальше
└── .github/workflows/        сборка ISO в CI
```

Подробности: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Требования

- 20 ГБ свободного места (сборка ~12 ГБ в `work/`)
- 8 ГБ RAM (минимум 4 ГБ)
- x86_64 (64-бит)
- Интернет на время сборки (~2000 пакетов)

## Известные проблемы

| Симптом | Причина / решение |
|---|---|
| `mkarchiso: loop device` | Контейнер запущен без `--privileged` |
| `package not found: X` | Пакет переименован/удалён из Arch. Проверь `pacman -Si X` |
| Чёрный экран при загрузке | В меню загрузчика выбери `failsafe / nomodeset` |
| NVIDIA + Wayland артефакты | `sudo farchios gpu`, затем добавь `nvidia_drm.modeset=1` |
| Steam не стартует | Нет multilib/32-бит: `farchios doctor` покажет |

---

## Лицензия

MIT. Arch Linux — торговая марка Arch Linux; FarchiOs не аффилирован с Arch
Linux, Valve или CachyOS.

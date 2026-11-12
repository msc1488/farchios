# Игры в FarchiOs

## Быстрый старт

```bash
sudo farchios gpu        # драйверы под твою карту
sudo farchios tune       # тюнинг
farchios doctor          # проверить, что всё на месте
```

Steam → Настройки → Совместимость → **включить Steam Play для всех игр**.

## Steam: параметры запуска

Базовый набор, который стоит попробовать на любой игре:

```bash
gamemoderun mangohud %command%
```

С Gamescope (HDR, фиксированный режим, апскейл):

```bash
gamemoderun gamescope -W 2560 -H 1440 -r 165 -f -- %command%
```

Только MangoHud (посмотреть FPS/GPU/CPU):

```bash
mangohud %command%
```

MangoHud можно настроить интерактивно: `Shift+F12` показывает редактор,
конфиг лежит в `~/.config/MangoHud/MangoHud.conf`.

## Proton

| Вариант | Когда использовать |
|---|---|
| Steam Linux Runtime / Proton (Valve) | по умолчанию |
| Proton Experimental | новые игры, свежие фиксы |
| GE-Proton | игры с видео-катсценами, античит-обходы, «не запускается» |

Установка GE-Proton:

```bash
paru -S protonup-qt        # GUI
# или
paru -S proton-ge-custom-bin
```

В ProtonUp-Qt: *Add version → GE-Proton → Download*. Дальше в Steam выбирается
в свойствах игры.

## Игры вне Steam

| Лаунчер | Что это |
|---|---|
| **Lutris** | универсальный: GOG, Epic, Battle.net, эмуляторы |
| **Heroic** | Epic + GOG + Amazon, самый удобный |
| **Bottles** | отдельные Wine-префиксы для Windows-софта |

```bash
paru -S heroic-games-launcher-bin
```

## Античит: что работает

| Античит | Статус |
|---|---|
| VAC, EAC (с включённой поддержкой) | ✅ работает |
| BattlEye (с поддержкой Proton) | ⚠️ зависит от игры |
| EAC/BattlEye **без** поддержки разработчиком | ❌ не работает |
| Riot Vanguard | ❌ не работает (уровень ядра) |
| Faceit AC | ❌ не работает |

Список: [areweanticheatyet.com](https://areweanticheatyet.com/)

Важно: **не пытайся обходить блокировку античита**. Это бан аккаунта, а не
«настройка».

## Производительность: с чего начать, если FPS мало

1. `farchios doctor` — нет ли софтверного рендера (`llvmpipe` вместо GPU).
2. Проверь, что игра запускается через Vulkan (DXVK), а не OpenGL.
3. Включи `gamemoderun` — он поднимает governor CPU в performance.
4. Для AMD: `RADV_PERFTEST=gpl` уже прописан в `/etc/environment`.
5. Ограничь FPS через MangoHud (`fps_limit=144`) — стабильнее, чем «сколько
   получится», и меньше нагрузка на GPU.
6. Проверь охлаждение: `sensors` / `btop`. Троттлинг выглядит как «игра
   тормозит через 10 минут».

## NVIDIA: отдельные грабли

```bash
# Wayland + KMS (нужно для игр без тиринга)
# добавь в параметры ядра:
nvidia_drm.modeset=1 nvidia_drm.fbdev=1
```

Для старых карт (до Turing) используй `nvidia-dkms`, для RTX 20xx+ лучше
`nvidia-open-dkms`. `farchios gpu` ставит `nvidia-dkms` — универсальный вариант.

VRAM и suspend: `NVreg_PreserveVideoMemoryAllocations=1` уже прописан
`farchios gpu`, иначе после сна игры падают.

## 32-бит (Steam)

Если Steam пишет про отсутствующие библиотеки:

```bash
grep -q '^\[multilib\]' /etc/pacman.conf || echo "multilib выключен"
sudo pacman -S --needed lib32-mesa lib32-vulkan-icd-loader lib32-gamemode
```

## Логи и отладка

```bash
# почему игра не стартует в Steam
PROTON_LOG=1 %command%          # в параметрах запуска → ~/steam-*.log

# проверить Vulkan
vulkaninfo --summary

# проверить, что GPU реально используется
mangohud --dlsym glxgears
```

## Ноутбуки

- Ставь `power-profiles-daemon` (уже в ISO): `balanced` в играх от батареи,
  `performance` от сети.
- Гибридная графика: на Wayland работает через `switcheroo-control`;
  при проблемах запускай игру с `DRI_PRIME=1`.
- Не ставь `tlp` вместе с `power-profiles-daemon` — конфликтуют.

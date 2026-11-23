<#
.SYNOPSIS
    Сборка ISO FarchiOs из Windows через Docker или WSL2.

.EXAMPLE
    .\build.ps1
    .\build.ps1 -Mode docker -Clean
    .\build.ps1 -Mode wsl -Distro Arch
#>
[CmdletBinding()]
param(
    [ValidateSet('auto','docker','wsl')]
    [string]$Mode = 'auto',

    [string]$Distro = 'Arch',

    [switch]$Clean,

    [switch]$Quick,

    [switch]$SkipValidate
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Info($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "[ok] $m" -ForegroundColor Green }
function Fail($m) { Write-Host "[!!] $m" -ForegroundColor Red }

function Test-Cmd($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

# ---------------------------------------------------------------- выбор режима
if ($Mode -eq 'auto') {
    if ((Test-Cmd 'docker') -and ((docker info 2>$null) -match 'Server Version')) {
        $Mode = 'docker'
    } elseif (Test-Cmd 'wsl') {
        $Mode = 'wsl'
    } else {
        Fail "Ни Docker, ни WSL2 не готовы к работе."
        Write-Host @"

Варианты:
  1) Docker Desktop        https://www.docker.com/products/docker-desktop/
  2) Arch в WSL2:
       wsl --install -d Arch     (или из Microsoft Store: "Arch Linux")
       затем:  .\build.ps1 -Mode wsl

  Собирать ISO можно только в Linux-окружении: archiso использует
  mount, loop-устройства и chroot — на самом Windows это невозможно.

"@ -ForegroundColor Yellow
        exit 1
    }
}
Info "Режим сборки: $Mode"

$BuildArgs = @()
if ($Clean)        { $BuildArgs += '--clean' }
if ($Quick)        { $BuildArgs += '--quick' }
if ($SkipValidate) { $BuildArgs += '--no-validate' }

# ---------------------------------------------------------------- docker
if ($Mode -eq 'docker') {
    Info "Сборка образа farchios-builder (первый раз ~2 минуты)"
    docker build -t farchios-builder "$Root\docker"
    if ($LASTEXITCODE -ne 0) { Fail "docker build упал"; exit 1 }

    Info "Запуск сборки ISO (15-40 минут)"
    $dockerArgs = @(
        'run', '--rm', '--privileged',
        '-v', "${Root}:/build",
        'farchios-builder'
    ) + $BuildArgs

    & docker @dockerArgs
    if ($LASTEXITCODE -ne 0) { Fail "Сборка ISO упала. Лог выше."; exit 1 }
}

# ---------------------------------------------------------------- wsl
elseif ($Mode -eq 'wsl') {
    $dists = (wsl -l -q) -replace "`0", ''
    if ($dists -notcontains $Distro) {
        Fail "Дистрибутив '$Distro' не найден в WSL."
        Write-Host "Установи: wsl --install -d $Distro" -ForegroundColor Yellow
        Write-Host "Доступные: $($dists -join ', ')" -ForegroundColor Yellow
        exit 1
    }

    Info "Проверка archiso в WSL ($Distro)"
    wsl -d $Distro -- bash -lc "command -v mkarchiso >/dev/null || sudo pacman -Syu --needed --noconfirm archiso"

    $wslPath = (wsl -d $Distro -- wslpath -a "$Root").Trim()
    $argStr  = ($BuildArgs -join ' ')

    Info "Запуск сборки ISO в WSL"
    wsl -d $Distro -- bash -lc "cd '$wslPath' && sudo ./build.sh $argStr"
    if ($LASTEXITCODE -ne 0) { Fail "Сборка ISO упала."; exit 1 }
}

# ---------------------------------------------------------------- итог
$iso = Get-ChildItem -Path "$Root\out" -Filter *.iso -ErrorAction SilentlyContinue |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($iso) {
    Ok "ISO готов: $($iso.FullName)"
    Ok "Размер: $([math]::Round($iso.Length / 1GB, 2)) GB"
    Write-Host @"

Записать на флешку:
  • Rufus (Windows)  — выбери ISO, режим "DD image mode"
  • balenaEtcher     — просто выбери ISO и флешку

Проверить без флешки:
  • VirtualBox / VMware: создай VM, подключи ISO как DVD

"@ -ForegroundColor Yellow
} else {
    Fail "ISO не найден в $Root\out"
    exit 1
}

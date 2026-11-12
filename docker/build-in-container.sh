#!/usr/bin/env bash
# ============================================================
#  build-in-container.sh — точка входа Docker-образа
# ============================================================
set -euo pipefail

cd /build

# В контейнере нет loop-устройств в /dev, а mkarchiso они нужны.
# Контейнер запускается с --privileged, поэтому просто убеждаемся,
# что /dev/loop-control существует.
if [[ ! -e /dev/loop-control ]]; then
    echo "! /dev/loop-control отсутствует. Запусти контейнер с --privileged."
    echo "  docker run --privileged --rm -v \"\$PWD\":/build farchios-builder"
    exit 1
fi

exec bash ./build.sh "$@"

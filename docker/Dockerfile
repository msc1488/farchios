# ============================================================
#  FarchiOs build image
#  Контейнер с полным набором инструментов archiso.
# ============================================================
FROM archlinux:latest

ENV LANG=C.UTF-8

# multilib нужен и для сборки, и для проверки lib32-пакетов
RUN sed -i 's/^#\[multilib\]/[multilib]/' /etc/pacman.conf \
    && sed -i '/^\[multilib\]/{n;s/^#Include/Include/}' /etc/pacman.conf

RUN pacman -Syu --noconfirm --needed \
        archiso \
        squashfs-tools \
        libisoburn \
        mtools \
        dosfstools \
        e2fsprogs \
        erofs-utils \
        jq \
        python \
        git \
        rsync \
        which \
        util-linux \
        syslinux \
        zstd \
        xz \
    && pacman -Scc --noconfirm

WORKDIR /build

# Скрипт сборки монтируется из репозитория
ENTRYPOINT ["/bin/bash", "/build/docker/build-in-container.sh"]

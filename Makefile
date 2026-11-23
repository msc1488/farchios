# ============================================================
#  FarchiOs — Makefile
#  make iso      полная сборка
#  make quick    быстрая тестовая сборка
#  make validate проверить имена пакетов
#  make clean    удалить артефакты
# ============================================================

SHELL := /usr/bin/bash
ROOT  := $(shell pwd)
PROFILE := $(ROOT)/iso/farchios

.PHONY: all iso quick validate clean distclean lint shellcheck docker

all: iso

iso:
	sudo ./build.sh --clean

quick:
	sudo ./build.sh --quick

validate:
	sudo ./build.sh --validate-only

lint:
	bash -n build.sh
	bash -n docker/build-in-container.sh
	bash -n $(PROFILE)/profiledef.sh
	bash -n $(PROFILE)/airootfs/root/customize_airootfs.sh
	bash -n $(PROFILE)/airootfs/usr/local/bin/farchios
	bash -n $(PROFILE)/airootfs/usr/local/bin/farchios-gpu-setup
	bash -n $(PROFILE)/airootfs/usr/local/bin/farchios-firstboot
	bash -n $(PROFILE)/airootfs/usr/local/bin/farchios-postinstall
	@echo "==> Синтаксис в порядке"

shellcheck:
	shellcheck build.sh docker/build-in-container.sh $(PROFILE)/profiledef.sh \
		$(PROFILE)/airootfs/root/customize_airootfs.sh \
		$(PROFILE)/airootfs/usr/local/bin/farchios*

docker:
	docker build -t farchios-builder ./docker
	docker run --rm --privileged -v "$(ROOT):/build" farchios-builder

clean:
	rm -rf work
	@echo "==> work/ удалён"

distclean: clean
	rm -rf out
	@echo "==> work/ и out/ удалены"

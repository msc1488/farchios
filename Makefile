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
	@echo "==> Проверка пакетов (по конфигу профиля, с multilib)"
	@pacman -Sy --config "$(PROFILE)/pacman.conf" --noconfirm >/dev/null 2>&1 || true
	@grep -vE '^[[:space:]]*(#|$$)' $(PROFILE)/packages.x86_64 | while read -r p; do \
		pacman -Si --config "$(PROFILE)/pacman.conf" "$$p" >/dev/null 2>&1 || echo "  ОТСУТСТВУЕТ: $$p"; \
	done; echo "==> Готово"

lint:
	bash -n build.sh
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

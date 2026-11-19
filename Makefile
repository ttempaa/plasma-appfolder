QMLLINT ?= /usr/lib/qt6/bin/qmllint
QMLDIR  ?= /usr/lib/qt6/qml
MSGFMT  ?= msgfmt
KP      ?= kpackagetool6

VERSION   := $(shell grep -m1 '"Version"' metadata.json | cut -d'"' -f4)
QML_FILES := $(wildcard contents/ui/*.qml contents/config/*.qml)
MO_DIR    := contents/locale/ru/LC_MESSAGES
MO        := $(MO_DIR)/plasma_applet_com.github.ttempaa.plasma.appfolder.mo
DIST      := dist/plasma-appfolder-$(VERSION).plasmoid

.DEFAULT_GOAL := check
.PHONY: lint check syntax i18n dist install upgrade restart clean

lint:
	$(QMLLINT) -I $(QMLDIR) $(QML_FILES)

check: syntax
	$(MSGFMT) --check -o /dev/null po/ru.po
	jq empty metadata.json
	$(MAKE) dist

# CI runners have no KDE QML modules, so this skips import resolution
syntax:
	$(QMLLINT) --only-explicit-categories --syntax error --syntax.duplicate-ids error $(QML_FILES)

i18n:
	@mkdir -p $(MO_DIR)
	$(MSGFMT) -o $(MO) po/ru.po

# kpackagetool6 expects metadata.json and contents/ at the archive root
dist: i18n
	@test -n "$(VERSION)" || (echo "Version not found in metadata.json"; exit 1)
	@mkdir -p dist
	@if command -v zip >/dev/null; then \
		zip -qr9 $(DIST) metadata.json contents; \
	else \
		bsdtar -a -cf $(DIST) --format zip metadata.json contents; \
	fi
	@echo "built $(DIST)"

install: dist
	$(KP) --type Plasma/Applet --install $(DIST)

upgrade:
	$(KP) --type Plasma/Applet --upgrade .

restart:
	systemctl --user restart plasma-plasmashell.service
	@echo "log: journalctl --user -u plasma-plasmashell.service --since '-2 min' --output=cat | grep -i appfolder"

clean:
	rm -rf dist

PREFIX ?= /usr
CURSOR_THEMES ?= $(patsubst %/index.theme,%,$(wildcard ./usr/*/index.theme))

all: clean build

build:
	bash build.sh -t 0

clean:
	-rm -rf _build usr *.tar.gz log

install:
	mkdir -p $(DESTDIR)$(PREFIX)/share/icons
	@echo $(CURSOR_THEMES)
	# cp -R $(CURSOR_THEMES) $(DESTDIR)$(PREFIX)/share/icons

uninstall:
	-rm -rf $(foreach cursor_theme,$(CURSOR_THEMES),$(DESTDIR)$(PREFIX)/share/icons/$(cursor_theme))

dist: _get_version $(CURSOR_THEMES)

_get_version:
	$(eval VERSION := $(shell git show -s --format=%cd --date=format:%Y%m%d HEAD))
	@echo $(VERSION)

release: _get_version
	git tag -f $(VERSION)
	git push origin --tags
	git push origin

undo_release: _get_version
	-git tag -d $(VERSION)
	-git push --delete origin $(VERSION)

$(CURSOR_THEMES):
	cp -f AUTHORS LICENSE $@
	tar -C $(dir $@) -czf $(notdir $@)_$(VERSION).tar.gz $(notdir $@)

.PHONY: all build clean dist install uninstall _get_version release undo_release $(CURSOR_THEMES)

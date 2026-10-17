PREFIX ?= $(HOME)/.local
ID = io.github.crian.GWeatherAddLoc
BIN = gweather-add-loc
BINPATH ?= target/release/$(BIN)

all:
	cargo build --release

install: all install-files

install-files:
	install -Dm755 $(BINPATH) $(DESTDIR)$(PREFIX)/bin/$(BIN)
	install -Dm644 data/$(ID).desktop $(DESTDIR)$(PREFIX)/share/applications/$(ID).desktop
	install -Dm644 data/$(ID).metainfo.xml $(DESTDIR)$(PREFIX)/share/metainfo/$(ID).metainfo.xml
	install -Dm644 data/icons/hicolor/scalable/apps/$(ID).svg $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/$(ID).svg
	install -Dm644 data/icons/hicolor/symbolic/apps/$(ID)-symbolic.svg $(DESTDIR)$(PREFIX)/share/icons/hicolor/symbolic/apps/$(ID)-symbolic.svg

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(BIN)
	rm -f $(DESTDIR)$(PREFIX)/share/applications/$(ID).desktop
	rm -f $(DESTDIR)$(PREFIX)/share/metainfo/$(ID).metainfo.xml
	rm -f $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/$(ID).svg
	rm -f $(DESTDIR)$(PREFIX)/share/icons/hicolor/symbolic/apps/$(ID)-symbolic.svg

.PHONY: all install install-files uninstall

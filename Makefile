PHONY = install uninstall test deb

ifeq ($(PREFIX), )
	PREFIX = /usr
endif

all:

clean:

test:

install:
	chown -R root.root include
	find include -type d -exec chmod 755 {} \;
	find include -type f -exec chmod 644 {} \;
	mkdir -p $(DESTDIR)$(PREFIX)/share/toolbox/include
	cp -a include/* $(DESTDIR)$(PREFIX)/share/toolbox/include/.

uninstall:
	rm $(DESTDIR)$(PREFIX)/share/toolbox/include/iruca.sh
	rm $(DESTDIR)$(PREFIX)/share/toolbox/include/gitlab.sh

.PHONY: $(PHONY)

CFLAGS+=$(shell pkg-config --cflags cairo-xlib xinerama glib-2.0 xext x11 xtst 2> /dev/null || echo -I/usr/X11R6/include -I/usr/local/include)
LDFLAGS+=$(shell pkg-config --libs cairo-xlib xinerama glib-2.0 xext x11 xtst 2> /dev/null || echo -L/usr/X11R6/lib -L/usr/local/lib -lX11 -lXtst -lXinerama -lXext -lglib)
LDFLAGS+=$(shell pkg-config --libs glib-2.0)

PREFIX=/usr

OTHERFILES=README CHANGELIST COPYRIGHT \
           keynavrc Makefile version.sh VERSION
#CFLAGS+=-DPROFILE_THINGS
#LDFLAGS+=-lrt

VERSION=$(shell sh version.sh)

#CFLAGS+=-pg -g
#LDFLAGS+=-pg -g
#LDFLAGS+=-L/usr/lib/debug/usr/lib/ -lcairo -lX11 -lXinerama -LXtst -lXext
#CFLAGS+=-O2

#CFLAGS+=-DPROFILE_THINGS
#LDFLAGS+=-lrt

.PHONY: all uninstall

all: keynav

clean:
	rm -f *.o keynav keynav_version.h keynav.1.gz

keynav.o: keynav_version.h
keynav_version.h: version.sh

keynav: LDFLAGS+=-Xlinker -rpath=/usr/local/lib
keynav: keynav.o
	$(CC) keynav.o -o $@ $(LDFLAGS) -lxdo; \

keynav_version.h:
	sh version.sh --header > $@

VERSION:
	sh version.sh --shell > $@

pre-create-package:
	rm -f keynav_version.h VERSION
	$(MAKE) VERSION keynav_version.h

create-package: clean pre-create-package keynav_version.h
	NAME=keynav-$(VERSION); \
	mkdir $${NAME}; \
	rsync --exclude '.*' -av *.c $(OTHERFILES) $${NAME}/; \
	tar -zcf $${NAME}.tar.gz $${NAME}/; \
	rm -rf $${NAME}/

package: create-package test-package-build

test-package-build: create-package
	@NAME=keynav-$(VERSION); \
	tmp=$$(mktemp -d); \
	echo "Testing package $$NAME"; \
	tar -C $${tmp} -zxf $${NAME}.tar.gz; \
	make -C $${tmp}/$${NAME} keynav; \
	(cd $${tmp}/$${NAME}; ./keynav version); \
	rm -rf $${NAME}/
	rm -f $${NAME}.tar.gz

keynav.1: keynav.pod
	pod2man -c "" -r "" $< > $@

install: keynav keynav.1
	install ./keynav $(PREFIX)/bin/keynav
	rm -f keynav.1.gz
	gzip keynav.1
	mkdir -p $(PREFIX)/share/man/man1
	install ./keynav.1.gz $(PREFIX)/share/man/man1/

uninstall:
	rm -f $(PREFIX)/bin/keynav
	rm -f $(PREFIX)/share/man/man1/keynav.1.gz

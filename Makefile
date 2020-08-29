DESTDIR =
PREFIX = $(HOME)
IMAGES = sbcl-rb

all: $(IMAGES)

clean:
	rm -f $(IMAGES)

install: all
	$(foreach image,$(IMAGES),\
	  install -D -m 755 $(image) $(DESTDIR)$(PREFIX)/bin/$(image))

%: %.lisp
	sbcl --no-userinit --no-sysinit --load $<

.PHONY: all clean install

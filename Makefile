PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
SHAREDIR ?= $(PREFIX)/share/darktable-nas
SYSCONFDIR ?= /etc/darktable-nas

.PHONY: all install uninstall clean

all:
	@echo "darktable-nas - Run 'make install' to install"

install:
	@echo "Installing darktable-nas..."
	install -Dm755 bin/darktable-nas $(DESTDIR)$(BINDIR)/darktable-nas
	install -Dm644 config/darktablerc.template $(DESTDIR)$(SHAREDIR)/darktablerc.template
	install -Dm644 config/darktable-nas.conf.example $(DESTDIR)$(SYSCONFDIR)/darktable-nas.conf.example
	@echo ""
	@echo "Installation complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Copy config: cp $(SYSCONFDIR)/darktable-nas.conf.example ~/.config/darktable-nas/darktable-nas.conf"
	@echo "  2. Edit config with your NAS details"
	@echo "  3. Set up CIFS credentials (see README.md)"
	@echo "  4. Run: darktable-nas"

uninstall:
	@echo "Uninstalling darktable-nas..."
	rm -f $(DESTDIR)$(BINDIR)/darktable-nas
	rm -rf $(DESTDIR)$(SHAREDIR)
	rm -rf $(DESTDIR)$(SYSCONFDIR)
	@echo "Uninstall complete. User config in ~/.config/darktable-nas/ was preserved."

clean:
	@echo "Nothing to clean"

# Development helpers
.PHONY: lint test dev-install

lint:
	shellcheck bin/darktable-nas

test:
	@echo "Running basic syntax check..."
	bash -n bin/darktable-nas
	@echo "Syntax OK"

dev-install:
	@echo "Creating symlink for development..."
	mkdir -p ~/.local/bin
	ln -sf $(shell pwd)/bin/darktable-nas ~/.local/bin/darktable-nas
	@echo "Symlink created at ~/.local/bin/darktable-nas"

# Platform detection
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

# Set default PREFIX based on platform
ifeq ($(UNAME_S),Darwin)
    ifeq ($(UNAME_M),arm64)
        PREFIX ?= /opt/homebrew
    else
        PREFIX ?= /usr/local
    endif
else
    PREFIX ?= /usr/local
endif

BINDIR ?= $(PREFIX)/bin
SHAREDIR ?= $(PREFIX)/share/darktable-nas
SYSCONFDIR ?= /etc/darktable-nas

.PHONY: all install uninstall clean install-macos

all:
	@echo "darktable-nas - Run 'make install' to install"

install:
	@echo "Installing darktable-nas..."
	install -Dm755 bin/darktable-nas $(DESTDIR)$(BINDIR)/darktable-nas
	install -Dm755 bin/darktable-nas-progress $(DESTDIR)$(BINDIR)/darktable-nas-progress
	install -Dm644 config/darktablerc.template $(DESTDIR)$(SHAREDIR)/darktablerc.template
	install -Dm644 config/darktable-nas.conf.example $(DESTDIR)$(SYSCONFDIR)/darktable-nas.conf.example
	@echo ""
	@echo "Installation complete!"
ifeq ($(UNAME_S),Darwin)
	@echo ""
	@echo "macOS setup:"
	@echo "  1. Run: darktable-nas --setup-keychain"
	@echo "  2. Copy config: mkdir -p ~/.config/darktable-nas && cp $(SYSCONFDIR)/darktable-nas.conf.example ~/.config/darktable-nas/darktable-nas.conf"
	@echo "  3. Edit config with your NAS details"
	@echo "  4. Run: darktable-nas"
else
	@echo ""
	@echo "Next steps:"
	@echo "  1. Copy config: mkdir -p ~/.config/darktable-nas && cp $(SYSCONFDIR)/darktable-nas.conf.example ~/.config/darktable-nas/darktable-nas.conf"
	@echo "  2. Edit config with your NAS details"
	@echo "  3. Set up CIFS credentials (see README.md)"
	@echo "  4. Run: darktable-nas"
endif

uninstall:
	@echo "Uninstalling darktable-nas..."
	rm -f $(DESTDIR)$(BINDIR)/darktable-nas
	rm -f $(DESTDIR)$(BINDIR)/darktable-nas-progress
	rm -rf $(DESTDIR)$(SHAREDIR)
	rm -rf $(DESTDIR)$(SYSCONFDIR)
	@echo "Uninstall complete. User config in ~/.config/darktable-nas/ was preserved."

clean:
	@echo "Nothing to clean"

# Development helpers
.PHONY: lint test dev-install

lint:
	shellcheck bin/darktable-nas bin/darktable-nas-progress

test:
	@echo "Running basic syntax check..."
	bash -n bin/darktable-nas
	bash -n bin/darktable-nas-progress
	@echo "Syntax OK"

dev-install:
	@echo "Creating symlink for development..."
	mkdir -p ~/.local/bin
	ln -sf $(shell pwd)/bin/darktable-nas ~/.local/bin/darktable-nas
	ln -sf $(shell pwd)/bin/darktable-nas-progress ~/.local/bin/darktable-nas-progress
	@echo "Symlinks created at ~/.local/bin/"

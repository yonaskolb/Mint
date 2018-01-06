TOOL_NAME = mint
VERSION = 0.7.0

PREFIX = /usr/local
INSTALL_PATH = $(PREFIX)/bin/$(TOOL_NAME)
BUILD_PATH = .build/release/$(TOOL_NAME)
CURRENT_PATH = $(PWD)
REPO = https://github.com/yonaskolb/$(TOOL_NAME)
RELEASE_TAR = $(REPO)/archive/$(VERSION).tar.gz
SHA = $(shell curl -L -s $(RELEASE_TAR) | shasum -a 256 | sed 's/ .*//')

.PHONY: install build uninstall format_code update_brew release

install: build
	mkdir -p $(PREFIX)/bin
	cp -f $(BUILD_PATH) $(INSTALL_PATH)

build:
	swift build --disable-sandbox -c release -Xswiftc -static-stdlib

uninstall:
	rm -f $(INSTALL_PATH)

format_code:
	swiftformat Tests --stripunusedargs closure-only --header strip
	swiftformat Sources --stripunusedargs closure-only --header strip

update_brew:
	sed -i '' 's|\(url ".*/archive/\)\(.*\)\(.tar\)|\1$(VERSION)\3|' Formula/mint.rb
	sed -i '' 's|\(sha256 "\)\(.*\)\("\)|\1$(SHA)\3|' Formula/mint.rb

	git add .
	git commit -m "Update brew to $(VERSION)"

release: format_code
	sed -i '' 's|\(static let version = "\)\(.*\)\("\)|\1$(VERSION)\3|' Sources/MintKit/Mint.swift

	git add .
	git commit -m "Update to $(VERSION)"
	git tag $(VERSION)

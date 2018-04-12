TOOL_NAME = mint
VERSION = 0.9.0

PREFIX = /usr/local
INSTALL_PATH = $(PREFIX)/bin/$(TOOL_NAME)
BUILD_PATH = .build/release/$(TOOL_NAME)
CURRENT_PATH = $(PWD)
REPO = https://github.com/yonaskolb/$(TOOL_NAME)
RELEASE_TAR = $(REPO)/archive/$(VERSION).tar.gz

.PHONY: install build uninstall format_code publish release

install: build
	mkdir -p $(PREFIX)/bin
	cp -f $(BUILD_PATH) $(INSTALL_PATH)

build:
	swift build --disable-sandbox -c release -Xswiftc -static-stdlib

uninstall:
	rm -f $(INSTALL_PATH)

format_code:
	swiftformat Tests --stripunusedargs closure-only --header strip --disable blankLinesAtStartOfScope
	swiftformat Sources --stripunusedargs closure-only --header strip --disable blankLinesAtStartOfScope

publish:
	# bump homebrew version
	brew bump-formula-pr --url=$(RELEASE_TAR) Mint

release: format_code
	sed -i '' 's|\(static let version = "\)\(.*\)\("\)|\1$(VERSION)\3|' Sources/MintKit/Mint.swift

	git add .
	git commit -m "Update to $(VERSION)"
	git tag $(VERSION)

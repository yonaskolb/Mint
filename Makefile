EXECUTABLE_NAME = mint
REPO = https://github.com/yonaskolb/Mint
VERSION = 0.17.3

PREFIX = /usr/local
INSTALL_PATH = $(PREFIX)/bin/$(EXECUTABLE_NAME)
SWIFT_BUILD_FLAGS = --disable-sandbox -c release --arch arm64 --arch x86_64
EXECUTABLE_PATH = $(shell swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/$(EXECUTABLE_NAME)
CURRENT_PATH = $(PWD)
RELEASE_TAR = $(REPO)/archive/$(VERSION).tar.gz

.PHONY: install build uninstall format_code publish release

install: build
	mkdir -p $(PREFIX)/bin
	cp -f $(EXECUTABLE_PATH) $(INSTALL_PATH)

build:
	swift build $(SWIFT_BUILD_FLAGS)

uninstall:
	rm -f $(INSTALL_PATH)

format_code:
	swiftformat Tests --stripunusedargs closure-only --header strip --disable blankLinesAtStartOfScope
	swiftformat Sources --stripunusedargs closure-only --header strip --disable blankLinesAtStartOfScope

publish: zip_binary bump_brew
	echo "published $(VERSION)"

bump_brew:
	brew update
	brew bump-formula-pr --url=$(RELEASE_TAR) Mint

zip_binary: build
	zip -jr $(EXECUTABLE_NAME).zip $(EXECUTABLE_PATH)

release:
	sed -i '' 's|\(let version = "\)\(.*\)\("\)|\1$(VERSION)\3|' Sources/MintCLI/MintCLI.swift

	git add .
	git commit -m "Update to $(VERSION)"
	git tag $(VERSION)

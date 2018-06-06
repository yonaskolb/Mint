# Change Log

## Master

## 0.10.0

#### Added
- Added `mint bootstrap` command for installing all the packages in your `Mintfile` #79 @yonaskolb
- Added `--mintfile` argument for custom `Mintfile` path #79 @yonaskolb
- Added `stdin` support to `mint run` #78 @yonaskolb

#### Changed
- Improved error output #78 @yonaskolb
- Customizable `standardOut` and `standardError` in `Mint` #78 @yonaskolb
- As global installs are now the default, replaced `--global` with `--prevent-global` flag

#### Fixed
- Fixed output in run not being silenced when using a Mintfile #77 @yutailang0119
- Removed dotfiles from `mint list` output @yonaskolb
- Print errors to stderr #78 @yonaskolb

##### Internal
- Replaced `ShellOut` with `SwiftCLI` #78 @yonaskolb
- Replaced `SPM` with `SwiftCLI` #78 @yonaskolb

[Commits](https://github.com/yonaskolb/Mint/compare/0.9.1...0.10.0)

## 0.9.1

- made `Mintfile` package lookup case insensitive @yonaskolb
- fixed `Minfile` lookup by simple name on `install`

[Commits](https://github.com/yonaskolb/Mint/compare/0.9.0...0.9.1)

## 0.9.0

- added `Mintfile` for adding a list versioned dependencies #72 @Lutzifer
- added `MINT_PATH` and `MINT_INSTALL_PATH` environment variables #65 @yonaskolb
- fixed build errors not being logged #71 @yonaskolb

[Commits](https://github.com/yonaskolb/Mint/compare/0.8.0...0.9.0)

## 0.8.0

- add ssh support #60 @Lutzifer
- add `--silent` argument #64 @yonaskolb
- build packages using the current version of macOS #61 @LinusU
- bundle Swift with installations, so they don't fail with Swift updates #70 @yonaskolb
- show globally installed packages with a `*` in `mint list` #56 @yutailang0119
- move homebrew formula from this repo to official homebrew repo (no more custom tap required) #63 yonaskolb
- help output changes #55 @pixyzehn

[Commits](https://github.com/yonaskolb/Mint/compare/0.7.1...0.8.0)

## 0.7.1

- add backwards compatibility for `mint run` calls still using quotes
- don't log error message from mint if run executable fails

[Commits](https://github.com/yonaskolb/Mint/compare/0.7.0...0.7.1)

## 0.7.0

- `install` and `update` now link the executable to `usr/local/bin` by default, for global usage. Disable this with `--global:false` #41 #44 #45
- arguments to an executable no longer have to be surrounded in quotes. `mint run yonaskolb/xcodegen xcodegen --spec myspec.yml`
- added streaming of run command output #36
- added `--verbose` flag for cloning and building output #36
- add `MINT` and `RESOURCE_PATH` envs #36
- fixed ANSI color issue #36
- replaced ShellOut with SwiftShell #36
- added a whole bunch of tests

[Commits](https://github.com/yonaskolb/Mint/compare/0.6.1...0.7.0)

## 0.6.1

- Fixed calculation of latest version #30
- Integrated SwiftPM for versioning, more integrations will follow #30

[Commits](https://github.com/yonaskolb/Mint/compare/0.6.0...0.6.1)

## 0.6.0

- Fixed issues on case‐sensitive file systems #19 @SDGGiesbrecht
- Fixed updating branches and packages without checked in `Package.resolved` files #24
- Package repos are now checked out fresh on each install #24
- If not passing a version, tags are now fetched remotely #24
- Clones are now shallow #28
- Added `mint list` command for listing all installed package versions #25
- Added `mint --version` #27

[Commits](https://github.com/yonaskolb/Mint/compare/0.5.0...0.6.0)

## 0.5.0

- BREAKING: Changed version from the second argument to an @ suffix on the repo

[Commits](https://github.com/yonaskolb/Mint/compare/0.4.1...0.5.0)

## 0.4.1

- Fixed installing a package without tags when version isn't specified #7 by @orta

[Commits](https://github.com/yonaskolb/Mint/compare/0.4.0...0.4.1)

## 0.4.0

- Fixed permission issues in High Sierra

[Commits](https://github.com/yonaskolb/Mint/compare/0.3.0...0.4.0)

## 0.3.0

- Made version optional (defaults to newest tagged release)
- Made command name optional (defaults to trailing path in repo path)
- Added `update` command

[Commits](https://github.com/yonaskolb/Mint/compare/0.3.0...0.4.0)

## 0.2.0

- Made CLI commands more robust, including help

[Commits](https://github.com/yonaskolb/Mint/compare/0.1.0...0.2.0)

## 0.1.0
- First official release

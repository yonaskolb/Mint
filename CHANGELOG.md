# Change Log

## Master

## 0.14.2

#### Changed
- Changeed `list` output to show what executables are installed if they differ from package name, and also disambiguate packages with the same name and different sources [#170](https://github.com/yonaskolb/Mint/pull/170) @acecilia

#### Fixed
- Fixed the `run` to support when a package with the same name is installed from different origins (for example: yonaskolb/xcodegen and acecilia/xcodegen). [#170](https://github.com/yonaskolb/Mint/pull/170) @acecilia
- Fix the `uninstall` option: previously, the name for the symlink to remove was calculated using the package name passed from command line, which could be partial (for example `simple` instead of `simplepackage`), resulting on the symlink not being removed. [#170](https://github.com/yonaskolb/Mint/pull/170) @acecilia
- Fixed installing versions that reference a git sha [#172](https://github.com/yonaskolb/Mint/pull/172) @yonaskolb
- Added escaping of paths when linking. Avoids an error, when MINT_LINK_PATH contains spaces. @lutzifer

[Commits](https://github.com/yonaskolb/Mint/compare/0.14.1...0.14.2)

## 0.14.1

#### Fixed
- Fixed some verbose output being shown in non verbose states

[Commits](https://github.com/yonaskolb/Mint/compare/0.14.0...0.14.1)

## 0.14.0

#### Added
- Added `--no-install` option to `mint run` [#160](https://github.com/yonaskolb/Mint/pull/160) @yonaskolb
- Added `mint which` command for printing the path of an executable [#162](https://github.com/yonaskolb/Mint/pull/162) @yonaskolb
- The executable no longer needs to be provided in `mint run` when passing arguments if there is only a single executable in the package eg: `mint run realm/SwiftLint autocorrect` [#159](https://github.com/yonaskolb/Mint/pull/159) @yonaskolb

#### Changed
- Moved output of some commands to `--verbose` and tweaked output [#154](https://github.com/yonaskolb/Mint/pull/154) @yonaskolb

#### Fixed
- Fixed a bug that prevented the `Mintfile` from resolving a GitHub repository where the name contains a period [#153](https://github.com/yonaskolb/Mint/pull/153) @liamnichols

#### Internal
- Updated to SwiftCLI 6.0 [#157](https://github.com/yonaskolb/Mint/pull/157) @yonaskolb
- Replace CircleCI with Github actions [#158](https://github.com/yonaskolb/Mint/pull/158) @yonaskolb

[Commits](https://github.com/yonaskolb/Mint/compare/0.13.0...0.14.0)

## 0.13.0

#### Added
- Added the `--link` (or `-l`) flag to the `bootstrap` option, to optionally link the packages of a `Mintfile` globally [#137](https://github.com/yonaskolb/Mint/pull/137) @acecilia

#### Fixed
- Fixed list of executables not showing when asking for to disambiguate between them [#149](https://github.com/yonaskolb/Mint/pull/149) @yonaskolb

#### Internal
- Updated dependencies and removed SwiftPM dependency

[Commits](https://github.com/yonaskolb/Mint/compare/0.12.0...0.13.0)

## 0.12.0

#### Fixed
- Fixed building packages when running in Swift 5 #130 #131 @stefanomondino @yonaskolb

#### Changed
- Updated to Swift 5 and dropped Swift 4.2 #131 @yonaskolb

[Commits](https://github.com/yonaskolb/Mint/compare/0.11.4...0.12.0)

## 0.11.4

#### Added
- SSH packages not stored in Github are supported

[Commits](https://github.com/yonaskolb/Mint/compare/0.11.3...0.11.4)

## 0.11.3

#### Changed
- Improved output #116 @yonaskolb

[Commits](https://github.com/yonaskolb/Mint/compare/0.11.2...0.11.3)

## 0.11.2

#### Added
- Packages can now be referenced by name in `mint install` when already installed #100 @yonaskolb

#### Fixed
- Fixed packages from Mintfile not being read on `mint run` when specified by name #100 @yonaskolb

[Commits](https://github.com/yonaskolb/Mint/compare/0.11.1...0.11.2)

## 0.11.1

#### Fixed
- Fixed not being able to pass arguments to `mint run` @yonaskolb

[Commits](https://github.com/yonaskolb/Mint/compare/0.11.0...0.11.1)

## 0.11.0

#### Added
- Added Linux support #82 @yonaskolb
- Executable names are now automatically read from `Package.swift` #95 @yonaskolb
- All executables in `Package.swift` are now installed #95 @yonaskolb
- If multiple executables exist and one is not provided in `mint run` it will ask you which one to run #95 @yonaskolb

#### Changed
- **Breaking:** changed `MINT_INSTALL_PATH` env to `MINT_LINK_PATH` #97 @yonaskolb
- **Breaking:** changed `--prevent-global` to `--no-link` #97 @yonaskolb
- **Breaking:** replaced `mint update` with `mint install --force` #96 @yonaskolb
- `--silent` now applies to `mint install` in addition to `mint run` @yonaskolb

#### Removed
- **Breaking**: Swift packages without executable products are no longer supported
- **Breaking**: Older style quoted command invocations are no longer supported. eg `mint run realm/SwiftLint "swiftlint autocorrect"`

#### Fixed
- Fixed `Mintfile` output not adhering to `--silent` #85 @yutailang0119
- Fixed installing nested resourcs in `Package.resources` #93 @toshi0383

[Commits](https://github.com/yonaskolb/Mint/compare/0.10.2...0.11.0)

## 0.10.2

#### Fixed
- Don't overwrite install path of already installed version until after successful build @yonaskolb
- Fixed version number output @yonaskolb

#### Changed
- Updated SwiftCLI 5.2.1 to allow nested help commands like `mint help install` @yonaskolb

[Commits](https://github.com/yonaskolb/Mint/compare/0.10.1...0.10.2)

## 0.10.1

#### Fixed
- Fixed environment variables not being passed via `mint run` @yonaskolb
- Fixed `mint bootstrap` output referring to the wrong path for `Mintfile` @yonaskolb

[Commits](https://github.com/yonaskolb/Mint/compare/0.10.0...0.10.1)

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

# Mint 🌱

[![SPM](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
[![Git Version](https://img.shields.io/github/release/yonaskolb/Mint.svg)](https://github.com/yonaskolb/Mint/releases)
[![Build Status](https://img.shields.io/travis/yonaskolb/Mint/master.svg?style=flat)](https://travis-ci.org/yonaskolb/Mint)
[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/yonaskolb/Mint/blob/master/LICENSE)

A package manager that installs and runs Swift command line tool packages.

```sh
$ mint run realm/SwiftLint@0.22.0 swiftlint
```
This would install and run [SwiftLint](https://github.com/realm/SwiftLint) version 0.22.0

Mint is designed to be used with Swift command line tools that build with the Swift Package Manager. It makes installing, running and distributing these tools much easier.

- ✅ builds are **cached** globally by version
- ✅ easily run a specific **version** of a tool
- ✅ use **different versions** of a tool side by side
- ✅ easily run the **latest** version of a tool
- ✅ distribute your own tools **without recipes and formulas**

Homebrew is a popular method of distributing Swift executables, but that requires creating a formula and then maintaining that formula. Running specific versions of homebrew installations can also be tricky as only one global version is installed at any one time. Mint installs your tool via SPM and lets you run multiple versions of that tool, which are globally installed and cached on demand.

If your Swift executable package builds with SPM, then it can be run with Mint! See [Support](#support) for details.


## Why is it called Mint?
Swift Packager Manager Tools -> SPMT -> Spearmint -> Mint! 🌱😄
> Mint: a place where something is produced or manufactured

## Installing
Make sure Xcode 9 is installed first.

### Homebrew

```sh
$ brew tap yonaskolb/Mint https://github.com/yonaskolb/Mint.git
$ brew install mint
```

### Make

```sh
$ git clone https://github.com/yonaskolb/Mint.git
$ cd Mint
$ make
```

### Swift Package Manager

**Use CLI**

```sh
$ git clone https://github.com/yonaskolb/Mint.git
$ cd Mint
$ swift run mint
```

**Use as dependency**

Add the following to your Package.swift file's dependencies:

```swift
.package(url: "https://github.com/yonaskolb/Mint.git", from: "0.1.0"),
```

And then import wherever needed: `import MintKit`

## Usage

Run `mint` to see usage instructions.

```
$ mint
Usage:
  mint [command]

Available Commands:
  install  Install a package
  run      Run a package
  update   Update a package
  list     List all installed packages

Use "mint [command] --help" for more information about a command.
```

- **Install**: Installs a package. If it is already installed this won't do anything
- **Run**: Runs a package. This will install if first if it doesn't exist
- **Update**: Installs a package while enforcing an update and rebuild. Shouldn't be required unless you are pointing at a branch and want to update.

These commands all have 1 or 2 arguments:

- **repo (required)**: This can be a shorthand for a github repo `install realm/SwiftLint` or a fully qualified git path `install https://github.com/realm/SwiftLint.git`. In the case of `run` you can also just pass the name of the repo if it is already installed `run swiftlint`. This will do a lookup of all installed packages. An optional version can be specified by appending `@version`, otherwise the newest tag or master will be used. Note that if you don't specify a version, the current tags must be loaded remotely each time.
- **command (optional)**: The command to install or run. This defaults to the the last path in the repo (so for `realm/swiftlint` it will be `swiftlint`). In the case of `run` you can also pass any arguments to the command but make sure the whole thing is surrounded by quotes eg `mint run realm/swiftlint "swiftlint --path source"`


#### Examples
```sh
$ mint install yonaskolb/XcodeGen@1.2.4 "XcodeGen --spec spec.yml" # pass some arguments
$ mint install yonaskolb/XcodeGen@1.2.4 # use version 1.2.4
$ mint install yonaskolb/XcodeGen # use newest tag
$ mint run yonaskolb/XcodeGen@1.2.4 # run 1.2.4
$ mint run XcodeGen # use newest tag and find XcodeGen in installed tools
```

## Support
If your Swift command line tool builds with the Swift Package Manager than it will automatically install and run with mint! You can add this to your `Installing` section in the readme:

````
### [Mint](https://github.com/yonaskolb/mint)
```
$ mint run github_name/repo_name
```
````

### Executable
If your executable name is different from your repo name then you will need to append the name to the above command

### Resources
The Swift Package Manager doesn't yet have a way of specifying resources directories. If your tool requires access to resources from the repo you require a custom `Package.resources` file. This is a plain text file that lists the resources directories on different lines:

```
MyFiles
MyOtherFiles
```
If this file is found in you repo, then all those directories will be copied into the same path as the executable.


## A list of popular Mint compatible tools 🌱
Just run `mint run` or `mint install` with the following:

- $ mint run [realm/SwiftLint](https://github.com/realm/SwiftLint) swiftlint
- $ mint run [JohnSundell/Marathon](https://github.com/JohnSundell/Marathon)
- $ mint run [yonaskolb/XcodeGen](https://github.com/yonaskolb/XcodeGen)
- $ mint run [yonaskolb/SwagGen](https://github.com/yonaskolb/SwagGen)
- $ mint run [Carthage/Carthage](https://github.com/Carthage/Carthage)
- $ mint run [krzysztofzablocki/Sourcery](https://github.com/krzysztofzablocki/Sourcery)
- $ mint run [toshi0383/cmdshelf](https://github.com/toshi0383/cmdshelf)

Feel free to add your own!

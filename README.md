# Mint 🌱

[![SPM](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=for-the-badge)](https://swift.org/package-manager)
![Platforms](https://img.shields.io/badge/Platforms-macOS_Linux-blue.svg?style=for-the-badge)
[![Git Version](https://img.shields.io/github/release/yonaskolb/Mint.svg?style=for-the-badge)](https://github.com/yonaskolb/Mint/releases)
[![Build Status](https://img.shields.io/circleci/project/github/yonaskolb/Mint.svg?style=for-the-badge)](https://circleci.com/gh/yonaskolb/Mint)
[![license](https://img.shields.io/github/license/yonaskolb/Mint.svg?style=for-the-badge)](https://github.com/yonaskolb/Mint/blob/master/LICENSE)

A package manager that installs and runs Swift command line tool packages.

```sh
$ mint run realm/SwiftLint@0.22.0 swiftlint
```
This would install and run [SwiftLint](https://github.com/realm/SwiftLint) version 0.22.0

Mint is designed to be used with Swift command line tools that build with the Swift Package Manager. It makes installing, running and distributing these tools much easier.

- ✅ easily run a specific **version** of a package
- ✅ install a package **globally**
- ✅ builds are **cached** by version
- ✅ use **different versions** of a package side by side
- ✅ easily run the **latest** version of a package
- ✅ distribute your own packages **without recipes and formulas**
- ✅ specify a list of versioned packages in a **Mintfile** for easy use

Homebrew is a popular method of distributing Swift executables, but that requires creating a formula and then maintaining that formula. Running specific versions of homebrew installations can also be tricky as only one global version is installed at any one time. Mint installs your package via SPM and lets you run multiple versions of that package, which are globally installed and cached on demand.

If your Swift executable package builds with SPM, then it can be run with Mint! See [Support](#support) for details.


## Why is it called Mint?
Swift Packager Manager Tools -> SPMT -> Spearmint -> Mint! 🌱😄
> Mint: a place where something is produced or manufactured

## Installing
Make sure Xcode 9.2 is installed first.

### Homebrew

```sh
$ brew install mint
```

### Make

```sh
$ git clone https://github.com/yonaskolb/Mint.git
$ cd Mint
$ make
```

### Using Mint itself!

##### Install
```sh
$ git clone https://github.com/yonaskolb/Mint.git
$ cd Mint
$ swift run mint install yonaskolb/mint
```

##### Update
```sh
$ mint install yonaskolb/mint
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

Run `mint --help` to see usage instructions.

- **install**: Installs a package, so it can be run with `run` later, and also links that version globally
- **run**: Runs a package. This will install it first if it isn't already installed, though won't link it globally. It's useful for running a certain version.
- **update**: Installs a package while enforcing an update and rebuild. Shouldn't be required unless you are pointing at a branch and want to update it.
- **list**: Lists all currently installed packages and versions.
- **uninstall**: Uninstalls a package by name.
- **bootstrap**: Installs all the packages in your [Mintfile](#mintfile) without linking them globally

Run, install and update commands have 1 or 2 arguments:

- **package (required)**: This can be a shorthand for a github repo `install realm/SwiftLint` or a fully qualified git path `install https://github.com/realm/SwiftLint.git`. In the case of `run` you can also just pass the name of the repo if it is already installed `run swiftlint`. This will do a lookup of all installed packages. An optional version can be specified by appending `@version`, otherwise the newest tag or master will be used. Note that if you don't specify a version, the current tags must be loaded remotely each time.
- **command (optional)**: The command to install or run. This defaults to the the last path in the repo (so for `realm/swiftlint` it will be `swiftlint`). In the case of `run` you can also pass any arguments to the command eg `mint run realm/swiftlint swiftlint --path source`


#### Examples
```sh
$ mint run yonaskolb/XcodeGen@1.2.4 xcodegen --spec spec.yml # pass some arguments
$ mint install yonaskolb/XcodeGen@1.2.4 --prevent-global # installs a certain version but not globally
$ mint install yonaskolb/XcodeGen # install newest tag
$ mint run yonaskolb/XcodeGen@1.2.4 # run 1.2.4
$ mint run XcodeGen # use newest tag and find XcodeGen in installed packages
```

### Global installs
By default Mint symlinks your installs into `usr/local/bin` when `install` or `update` are used, unless `--prevent-global` is passed. This means a package will be accessible from anywhere, and you don't have to prepend commands with `mint run package`. Note that only one global version can be installed at a time though. If you need to run a specific older version use `mint run`.

### Mintfile
A `Mintfile` can specify a list of versioned packages. It makes installing and running these packages easy, as the specific repos and versions are centralized.

Simply place this file in the directory you're running Mint in. The format of the `Mintfile` is simply a list of packages in the same form as the usual package parameter:

```
yonaskolb/xcodegen@0.9.0
yonaskolb/genesis@0.2.0
```

Then you can simply run a package with:

```sh
mint run xcodegen
```

Or install all the packages in one go with:

```sh
mint bootstrap
```

### Advanced
- You can use `--silent` in `mint run` to silence any output from mint itself. Useful if forwarding output somewhere else.
- You can set `MINT_PATH` and `MINT_INSTALL_PATH` envs to configure where mint caches builds, and where it symlinks global installs. These default to `/usr/local/lib/mint` and `/usr/local/bin` respectively

### Linux
Mint works on Linux but has some limitations:
- linux doesn't support building with a statically linked version of Swift. This means when a new version of swift comes out the old installs won't work on linux. A stable ABI in Swift 5 will remove the need for this.
- Linux is case sensitive so you must specify the correct case for repo urls as well as executables. As the `Mintfile` currently has no support for specifying the executable some packages may not work.

## Support
If your Swift command line tool builds with the Swift Package Manager than it will automatically install and run with mint! You can add this to the `Installing` section in your readme:

````
### [Mint](https://github.com/yonaskolb/mint)
```
$ mint install github_name/repo_name
```
````

### Executable
If your executable name is different from your repo name then you will need to append the name to the above command.

### Resources
The Swift Package Manager doesn't yet have a way of specifying resources directories. If your tool requires access to resources from the repo you require a custom `Package.resources` file. This is a plain text file that lists the resources directories on different lines:

```
MyFiles
MyOtherFiles
```
If this file is found in you repo, then all those directories will be copied into the same path as the executable.


## A list of popular Mint compatible packages 🌱

- mint install [realm/SwiftLint](https://github.com/realm/SwiftLint)
- mint install [JohnSundell/Marathon](https://github.com/JohnSundell/Marathon)
- mint install [yonaskolb/XcodeGen](https://github.com/yonaskolb/XcodeGen)
- mint install [yonaskolb/SwagGen](https://github.com/yonaskolb/SwagGen)
- mint install [Carthage/Carthage](https://github.com/Carthage/Carthage)
- mint install [krzysztofzablocki/Sourcery](https://github.com/krzysztofzablocki/Sourcery)
- mint install [toshi0383/cmdshelf](https://github.com/toshi0383/cmdshelf)
- mint install [LinusU/RasterizeXCAssets](https://github.com/LinusU/RasterizeXCAssets)
- mint install [jkmathew/Assetizer](https://github.com/jkmathew/Assetizer) assetize

Feel free to add your own!

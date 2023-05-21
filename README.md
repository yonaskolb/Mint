# Mint 🌱

[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fyonaskolb%2FMint%2Fbadge%3Ftype%3Dswift-versions&style=for-the-badge)](https://swiftpackageindex.com/yonaskolb/Mint)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fyonaskolb%2FMint%2Fbadge%3Ftype%3Dplatforms&style=for-the-badge)](https://swiftpackageindex.com/yonaskolb/Mint)
[![Git Version](https://img.shields.io/github/release/yonaskolb/Mint.svg?style=for-the-badge)](https://github.com/yonaskolb/Mint/releases)
[![License](https://img.shields.io/github/license/yonaskolb/Mint.svg?style=for-the-badge)](https://github.com/yonaskolb/Mint/blob/master/LICENSE)

A package manager that installs and runs Swift command line tool packages.

```sh
mint run realm/SwiftLint@0.40.3
```
This would install and run [SwiftLint](https://github.com/realm/SwiftLint) version 0.40.3

Mint is designed to be used with Swift command line tools that build with the Swift Package Manager. It makes installing, running and distributing these tools much easier.

- ✅ easily run a specific **version** of a package
- ✅ **link** a package **globally**
- ✅ builds are **cached** by version
- ✅ use **different versions** of a package side by side
- ✅ easily run the **latest** version of a package
- ✅ distribute your own packages **without recipes and formulas**
- ✅ specify a list of versioned packages in a **Mintfile** for easy use

Homebrew is a popular method of distributing Swift executables, but that requires creating a formula and then maintaining that formula. Running specific versions of homebrew installations can also be tricky as only one global version is installed at any one time. Mint installs your package via SPM and lets you run multiple versions of that package, which are installed and cached in a central place.

If your Swift executable package builds with SPM, then it can be run with Mint! See [Support](#support) for details.

## Why is it called Mint?
Swift Package Manager Tools -> SPMT -> Spearmint -> Mint! 🌱😄
> Mint: a place where something is produced or manufactured

## Installing
Make sure Xcode 10.2 is installed first.

### Homebrew

```sh
brew install mint
```

### Make

```sh
git clone https://github.com/yonaskolb/Mint.git
cd Mint
make
```

### Using Mint itself!

##### Install
```sh
git clone https://github.com/yonaskolb/Mint.git
cd Mint
swift run mint install yonaskolb/mint
```

##### Update
```sh
mint install yonaskolb/mint
```

### Swift Package Manager

**Use CLI**

```sh
git clone https://github.com/yonaskolb/Mint.git
cd Mint
swift run mint
```

**Use as dependency**

Add the following to your Package.swift file's dependencies:

```swift
.package(url: "https://github.com/yonaskolb/Mint.git", from: "0.15.0"),
```

And then import wherever needed: `import MintKit`

## Road to 1.0
Until 1.0 is reached, minor versions will be breaking.

## Usage

Run `mint help` to see usage instructions.

- **install**: Installs a package, so it can be run with `run` later, and also links that version globally
- **run**: Runs a package. This will install it first if it isn't already installed, though won't link it globally. It's useful for running a certain version.
- **list**: Lists all currently installed packages and versions.
- **which**: Print the path to an installed package executable.
- **uninstall**: Uninstalls a package by name.
- **bootstrap**: Installs all the packages in your [Mintfile](#mintfile), by default, without linking them globally

**Package reference**

`run` and `install` commands require a package reference parameter. This can be a shorthand for a github repo (`mint install realm/SwiftLint`) or a fully qualified git path (`mint install https://github.com/realm/SwiftLint.git`). In the case of `run` you can also just pass the name of the repo if it is already installed (`run swiftlint`) or in the Mintfile.
An optional version can be specified by appending `@version`, otherwise the newest tag or master will be used. Note that if you don't specify a version, the current tags must be loaded remotely each time.

#### Examples
```sh
$ mint run yonaskolb/XcodeGen@2.18.0 # run the only executable
$ mint run yonaskolb/XcodeGen@2.18.0 --spec spec.yml # pass some arguments
$ mint run yonaskolb/XcodeGen@2.18.0 xcodegen --spec spec.yml # specify a specific executable
$ mint run --executable xcodegen yonaskolb/XcodeGen@2.18.0 --spec spec.yml # specify a specific executable in case the first argument is the same name as the executable
$ mint install yonaskolb/XcodeGen@2.18.0 --no-link # installs a certain version but doesn't link it globally
$ mint install yonaskolb/XcodeGen # install newest tag
$ mint install yonaskolb/XcodeGen@master --force #reinstall the master branch
$ mint run yonaskolb/XcodeGen@2.18.0 # run 2.18.0
$ mint run XcodeGen # use newest tag and find XcodeGen in installed packages
```

### Linking
By default Mint symlinks your installs into `~/.mint/bin` on `mint install`, unless `--no-link` is passed. This means a package will be accessible from anywhere, and you don't have to prepend commands with `mint run package`, as long as you add `~/.mint/bin` to your `$PATH`. Note that only one linked version can be used at a time. If you need to run a specific older version use `mint run`.

### Mintfile
A `Mintfile` can specify a list of versioned packages. It makes installing and running these packages easy, as the specific repos and versions are centralized.

Simply place this file in the directory you're running Mint in. The format of the `Mintfile` is simply a list of packages in the same form as the usual package parameter:

```
yonaskolb/xcodegen@2.18.0
yonaskolb/genesis@0.4.0
```

Then you can simply run a package using:

```sh
mint run xcodegen
```

Note that mint will find the version declared in your Mintfile and run that version, even if you have multiple versions installed.

Or install all the packages (without linking them globally) in one go with:

```sh
mint bootstrap
```

If you prefer to link them globally, do such with:

```sh
mint bootstrap --link
```

### Advanced
- You can use `--silent` in `mint run` to silence any output from mint itself. Useful if forwarding output somewhere else.
- You can set `MINT_PATH` and `MINT_LINK_PATH` envs to configure where mint caches builds, and where it symlinks global installs. These default to `~/.mint` and `~/.mint/bin` respectively
- You can use `mint install --force` to reinstall a package even if it's already installed. This shouldn't be required unless you are pointing at a branch and want to update it.

### Linux
Mint works on Linux but has some limitations:
- linux doesn't support building with a statically linked version of Swift. This means when a new version of swift comes out the old installs won't work on linux.
- Linux is case sensitive so you must specify the correct case for repo urls as well as executables.

## Support
If your Swift command line tool builds with the Swift Package Manager than it will automatically install and run with mint! 

Make sure you have defined an `executable` product type in the `products` list within your `Package.swift`.

```swift
let package = Package(
    name: "Foo",
    products: [
        .executable(name: "foo", targets: ["Foo"]),
    ],
    targets: [
      .target(name: "Foo"),
      ...
    ]
)
```

You can then add this to the `Installing` section in your readme:
````
### [Mint](https://github.com/yonaskolb/mint)
```
mint run github_name/repo_name
```
````

### Resources
> Since Swift 5.3 resources are now built into the Swift Package manager, so if you're targetting that version or above the `Package.resources` file is no longer necessary https://github.com/apple/swift-evolution/blob/master/proposals/0271-package-manager-resources.md

The Swift Package Manager doesn't yet have a way of specifying resources directories. If your tool requires access to resources from the repo you require a custom `Package.resources` file. This is a plain text file that lists the resources directories on different lines:

```
MyFiles
MyOtherFiles
```
If this file is found in you repo, then all those directories will be copied into the same path as the executable.



## A list of popular Mint compatible packages 🌱

- mint install [jkmathew/Assetizer](https://github.com/jkmathew/Assetizer)
- mint install [Carthage/Carthage](https://github.com/Carthage/Carthage)
- mint install [JohnSundell/Marathon](https://github.com/JohnSundell/Marathon)
- mint install [LinusU/RasterizeXCAssets](https://github.com/LinusU/RasterizeXCAssets)
- mint install [krzysztofzablocki/Sourcery](https://github.com/krzysztofzablocki/Sourcery)
- mint install [yonaskolb/SwagGen](https://github.com/yonaskolb/SwagGen)
- mint install [nicklockwood/SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
- mint install [SwiftGen/SwiftGen](https://github.com/SwiftGen/SwiftGen)
- mint install [realm/SwiftLint](https://github.com/realm/SwiftLint)
- mint install [yonaskolb/XcodeGen](https://github.com/yonaskolb/XcodeGen)
- mint install [artemnovichkov/Carting](https://github.com/artemnovichkov/Carting)
- mint install [num42/icon-resizer-swift](https://github.com/num42/icon-resizer-swift)
- mint install [MakeAWishFoundation/SwiftyMocky](https://github.com/MakeAWishFoundation/SwiftyMocky)
- mint install [thii/xcbeautify](https://github.com/thii/xcbeautify)
- mint install [mono0926/LicensePlist](https://github.com/mono0926/LicensePlist)
- mint install [ChargePoint/xcparse](https://github.com/ChargePoint/xcparse)
- mint install [scribd/Weaver](https://github.com/scribd/Weaver)
- mint install [arthurpalves/coherent-swift](https://github.com/arthurpalves/coherent-swift)
- mint install [rsrbk/GoSwifty](https://github.com/rsrbk/GoSwifty)

Feel free to add your own!

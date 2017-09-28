# Mint 🌱

A dependency manager that installs and runs Swift command line tool packages.

```sh
$ mint run realm/swiftlint 0.22.0
```
This would install and run [SwiftLint](https://github.com/realm/SwiftLint) version 0.22.0

Mint is designed to be used with Swift command line tools that build with the Swift Package Manager.

- ✅ run tools **without build files** like homebrew formulas
- ✅ builds are **cached** globally by version
- ✅ easily run a specific **version** of a tool
- ✅ use **different versions** of a tool side by side
- ✅ easily run the **latest** version of a tool

Builds are installed to and run from `/usr/local/mint`

## Why is it called Mint?
Swift Packager Manager Tools -> SPMT -> Spearmint -> Mint! 🌱😄

## Installing
Make sure Xcode 9 is installed first.

### Homebrew

```sh
$ brew tap yonaskolb/mint https://github.com/yonaskolb/mint.git
$ brew install mint
```

### Make

```sh
$ git clone https://github.com/yonaskolb/mint.git
$ cd mint
$ make
```

### Swift Package Manager

**Use CLI**

```sh
$ git clone https://github.com/yonaskolb/mint.git
$ cd mint
$ ./build/release/mint
```

**Use as dependency**

Add the following to your Package.swift file's dependencies:

```swift
.package(url: "https://github.com/yonaskolb/mint.git", from: "0.1.0"),
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
  
Use "mint [command] --help" for more information about a command.
```

- **Install**: Installs a package. If it is already installed this won't do anything
- **Run**: Runs a package. This will install if first if it doesn't exist
- **Update**: Installs a package while enforcing an update and rebuild. Shouldn't be required unless you are pointing at a branch and want to update.

These commands all have 1 to 3 arguments:

- **repo (required)**: This can be a shorthand for a github repo `install realm/SwiftLint` or a fully qualified git path `install https://github.com/realm/SwiftLint.git`. In the case of `run` you can also just pass the name of the repo if it is already installed `run swiftlint`. This will do a lookup of all installed packages.
- **version (optional)**: The git version of the packge. It is usually a tag but can also be a branch. If this is left out the version will default to the latest tag, or if there are no tags then master.
- **command (optional)**: The command to install or run. This defaults to the the last path in the repo (so for `realm/swiftlint` it will be `swiftlint`). In the case of `run` you can also pass any arguments to the command but make sure the whole thing is surrounded by quotes eg `mint run realm/swiftlint 0.22.0 "swiftlint --path source"`

#### Examples
```sh
$ mint install yonaskolb/xcodegen 1.2.0 "xcodegen --spec spec.yml" # pass some arguments
$ mint install yonaskolb/xcodegen 1.2.0 # use version 1.2.0
$ mint install yonaskolb/xcodegen # use newest tag
$ mint run yonaskolb/xcodegen 1.2.0 # run 1.2.0
$ mint run xcodegen # use newest tag and find xcodegen in installed tools 
```

## Support
If your Swift command line tool builds with the Swift Package Manager than it will automatically install and run with mint! You can add this to your `Installing` section in the readme:

> ### [Mint](https://github.com/yonaskolb/mint) 🌱
> ```sh
> $ mint run github-name/repo-name
> ```

### Executable
If your executable name is different from your repo name then you will need to append the name to the above command

### Resources
The Swift Package Manager doesn't yet have a way of specifying resources directories. If your tool requires access to resources from the repo you require a custom `Package.resources` file. This is a plain text file that lists the resources directories on different lines:

```
MyFiles
MyOtherFiles
```
If this file is found in you repo, then all those directories will be copied into the same path as the executable.

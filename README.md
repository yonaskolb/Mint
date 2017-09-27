# Mint 🌱

A dependency manager that installs and runs Swift command line tool packages.

```
$ mint run realm/swiftlint 0.22.0
```

Mint is designed to be used with command line tools that use the Swift Package Manager.

- ✅ run tools **without build files** like homebrew formulas
- ✅ builds are **cached** globally by version
- ✅ easily run a specific **version** of a tool
- ✅ use **different versions** of a tool side by side

Builds are installed to and run from `/usr/local/mint`

## Why is it called Mint?
Swift Packager Manager Tools -> SPMT -> Spearmint -> Mint! 🌱😄

## Installing
Make sure Xcode 9 is installed first.

### Make

```
$ git clone https://github.com/yonaskolb/mint.git
$ cd mint
$ make
```

### Homebrew

```
$ brew tap yonaskolb/mint https://github.com/yonaskolb/mint.git
$ brew install mint
```

### Swift Package Manager

**Use CLI**

```
$ git clone https://github.com/yonaskolb/mint.git
$ cd mint
$ ./build/release/mint
```

**Use as dependency**

Add the following to your Package.swift file's dependencies:

```
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
```
$ mint install yonaskolb/xcodegen 1.2.0 "xcodegen --spec my_spec.yml"
$ mint install yonaskolb/xcodegen 1.2.0 xcodegen
$ mint install yonaskolb/xcodegen 1.2.0
$ mint install yonaskolb/xcodegen
$ mint run xcodegen
```

## Package.resources
As the Swift Packager doesn't yet have a way of specifying resources directories, Mint looks for a custom `Package.resources` file in the repo. This is a plain text file that lists the resources directories on different lines:

```
MyFiles
MyOtherFiles
```
If a file such as this is found, then all those directories will be copied into the same path as the executable.

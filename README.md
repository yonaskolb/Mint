# Mint 🌱

A dependency manager that installs and runs Swift command line tool packages.

```
$ mint run yonaskolb/xcodegen 1.2.0 xcodegen
```

Mint is designed to be used with command line tools that use the Swift Package Manager.

- ✅ run tools **without build files** like homebrew formulas
- ✅ builds are **cached** globally by version
- ✅ easily run a specific **version** of a tool
- ✅ use **different versions** of a tool side by side


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

Mint has 2 commands, `run` and `install`.

#### Install
This will checkout, build and copy a specific build by git tag

#### Run
Run will run a certain tool from the package. If it's not installed, it will install it first

#### Options

Each command is followed by git path, version and tool name. Anything after that in `run` will be passed to the command line tool. 

Git path can take the form:

- `yonaskolb/xcodegen` (github repo name)
- `github.com/yonaskolb/xcodegen` (github repo)
- `http://github.com/yonaskolb/xcodegen.git` (any full git path)

The first 2 examples would be transformed into the last

```
$ mint run yonaskolb/xcodegen 1.2.0 xcodegen
```


## Package.resources
As the Swift Packager doesn't yet have a way of specifying resources directories, Mint looks for a custom `Package.resources` file in the repo. This is a plain text file that lists the resources directories on different lines:

```
MyFiles
MyOtherFiles
```
If a file such as this is found, then all those directories will be copied into the same path as the executable.

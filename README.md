# SmartGameFormat

_Julia package for reading and writing the SGF File Format; a
text based format that is commonly used to store game records of
popular board games, such as Go, Backgammon, or Hex._

| **Package Status** | **Package Evaluator** | **Build Status** |
|:------------------:|:---------------------:|:-----------------:|
| [![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://evizero.github.io/SmartGameFormat.jl/latest) | [![Pkg Eval 0.6](http://pkg.julialang.org/badges/SmartGameFormat_0.6.svg)](http://pkg.julialang.org/?pkg=SmartGameFormat) [![Pkg Eval 0.7](http://pkg.julialang.org/badges/SmartGameFormat_0.7.svg)](http://pkg.julialang.org/?pkg=SmartGameFormat) | [![Build Status](https://travis-ci.org/Evizero/SmartGameFormat.jl.svg?branch=master)](https://travis-ci.org/Evizero/SmartGameFormat.jl) [![AppVeyor status](https://ci.appveyor.com/api/projects/status/rl1x7319t851nvu4?svg=true)](https://ci.appveyor.com/project/Evizero/smartgameformat-jl) [![Coveralls Status](https://coveralls.io/repos/Evizero/SmartGameFormat.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/Evizero/SmartGameFormat.jl?branch=master)

Description from the [official website](http://www.red-bean.com/sgf/index.html):

> SGF is the abbreviation of 'Smart Game Format'. The file format
> is designed to store game records of board games for two players.
> It's a text only, tree based format. Therefore games stored in
> this format can easily be emailed, posted or processed with
> text-based tools. The main purposes of SGF are to store records
> of played games and to provide features for storing annotated and
> analyzed games (e.g. board markup, variations).

## Usage

TODO

## Documentation

Check out the **[latest
documentation](https://evizero.github.io/SmartGameFormat.jl/latest)**

Additionally, you can make use of Julia's native docsystem.
The following example shows how to get additional information
on `load_sgf` within Julia's REPL:

```julia
?load_sgf
```

## Installation

Until this package is registered in `METADATA.jl` it can be
cloned using `Pkg` as usual.

```julia
Pkg.clone("https://github.com/Evizero/SmartGameFormat.jl.git")
```

## Limitations

Currently the character encoding is hardcoded to `UTF-8`. In case
any other encoding is specified in an `CA` property, a warning is
raised. Pull requests to improve this situation are welcome. A
potential solution could be build on top of
[StringEncodings.jl](https://github.com/nalimilan/StringEncodings.jl).

## License

This code is free to use under the terms of the MIT license.

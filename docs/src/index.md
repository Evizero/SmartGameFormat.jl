# SmartGameFormat.jl Documentation

SmartGameFormat.jl is a Julia package to read/write from/to SGF
files. More specifically does this package aim to implement the
specification of the SGF FF[4] standard.

Description from the [official
website](http://www.red-bean.com/sgf/index.html):

> SGF is the abbreviation of 'Smart Game Format'. The file format
> is designed to store game records of board games for two players.
> It's a text only, tree based format. Therefore games stored in
> this format can easily be emailed, posted or processed with
> text-based tools. The main purposes of SGF are to store records
> of played games and to provide features for storing annotated and
> analyzed games (e.g. board markup, variations).

## Exported Types

```@docs
SGFNode
SGFGameTree
```

## Public Functions

```@docs
load_sgf
save_sgf
parse_sgf
print_sgf
```

## Index

```@index
Pages = ["index.md", "lexer.md", "parser.md"]
```

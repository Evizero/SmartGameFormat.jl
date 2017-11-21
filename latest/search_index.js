var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#SmartGameFormat.jl-Documentation-1",
    "page": "Home",
    "title": "SmartGameFormat.jl Documentation",
    "category": "section",
    "text": "SmartGameFormat.jl is a Julia package to read/write from/to SGF files. More specifically does this package aim to implement the specification of the SGF FF[4] standard.Description from the official website:SGF is the abbreviation of 'Smart Game Format'. The file format is designed to store game records of board games for two players. It's a text only, tree based format. Therefore games stored in this format can easily be emailed, posted or processed with text-based tools. The main purposes of SGF are to store records of played games and to provide features for storing annotated and analyzed games (e.g. board markup, variations)."
},

{
    "location": "#SmartGameFormat.SGFNode",
    "page": "Home",
    "title": "SmartGameFormat.SGFNode",
    "category": "Type",
    "text": "SGFNode(properties::Pair{Symbol,Any}...)\n\nCreate an SGF node with the given properties. The parameter properties is optional, which means that its possible to create empty nodes.\n\nAdditional properties can be added at any time using the function setindex! or push!. Note how the property values are stored in a Vector{Any}. This is on purpose in order to support multi-value properties.\n\njulia> using SmartGameFormat\n\njulia> node = SGFNode()\nSmartGameFormat.SGFNode with 0 properties\n\njulia> node[:KM] = 6.5; # set komi property\n\njulia> node\nSmartGameFormat.SGFNode with 1 property:\n  :KM => Any[6.5]\n\nWhile setindex! will always overwrite existing values, the function push! will instead try to append the given value to an existing property.\n\njulia> push!(node, :AB => \"aa\")\nSmartGameFormat.SGFNode with 2 properties:\n  :AB => Any[\"aa\"]\n  :KM => Any[6.5]\n\njulia> push!(node, :AB => \"bb\")\nSmartGameFormat.SGFNode with 2 properties:\n  :AB => Any[\"aa\", \"bb\"]\n  :KM => Any[6.5]\n\n\n\n"
},

{
    "location": "#SmartGameFormat.SGFGameTree",
    "page": "Home",
    "title": "SmartGameFormat.SGFGameTree",
    "category": "Type",
    "text": "SGFGameTree([sequence::Vector{SGFNode}], [variations::Vector{SGFGameTree}])\n\nCreate a game tree with the given sequence and variations. Both parameters are optional, which means that its possible to create empty game trees.\n\nTo edit a SGFGameTree simply manipulate the two member variables directly. Note that SGFGameTree is a subtype of AbstractVector{SGFNode}, where getindex and setindex! correspond to the appropriate node in the main game path. This means that if there are any variations, then the first variation must denote the continuation of the main game path.\n\njulia> using SmartGameFormat\n\njulia> t = SGFGameTree()\n0-node SmartGameFormat.SGFGameTree with 0 variation(s)\n\njulia> push!(t.sequence, SGFNode(:KM => 6.5)); t\n1-node SmartGameFormat.SGFGameTree with 0 variation(s):\n KM[6.5]\n\njulia> t.variations = [SGFGameTree(SGFNode(:C=>\"first\")), SGFGameTree(SGFNode(:C=>\"second\"))]; t\n2-node SmartGameFormat.SGFGameTree with 2 variation(s):\n KM[6.5]\n C[…]\n\njulia> t[1]\nSmartGameFormat.SGFNode with 1 property:\n  :KM => Any[6.5]\n\njulia> t[2]\nSmartGameFormat.SGFNode with 1 property:\n  :C => Any[\"first\"]\n\n\n\n"
},

{
    "location": "#Exported-Types-1",
    "page": "Home",
    "title": "Exported Types",
    "category": "section",
    "text": "SGFNode\nSGFGameTree"
},

{
    "location": "#SmartGameFormat.load_sgf",
    "page": "Home",
    "title": "SmartGameFormat.load_sgf",
    "category": "Function",
    "text": "load_sgf(path::String) -> Vector{SGFGameTree}\n\nRead the content from the file at path, and call parse_sgf to convert it to a collection of SGFGameTree (i.e. a Vector{SGFGameTree}).\n\njulia> using SmartGameFormat\n\njulia> path = joinpath(Pkg.dir(\"SmartGameFormat\"), \"examples\", \"sample.sgf\");\n\njulia> col = load_sgf(path)\n1-element Array{SmartGameFormat.SGFGameTree,1}:\n SmartGameFormat.SGFNode[FF[4] GM[1] SZ[19], B[aa], W[bb], B[cc]]\n\njulia> col[1]\n4-node SmartGameFormat.SGFGameTree with 2 variation(s):\n FF[4] GM[1] SZ[19]\n B[aa]\n W[bb]\n B[cc]\n\n\n\n"
},

{
    "location": "#SmartGameFormat.save_sgf",
    "page": "Home",
    "title": "SmartGameFormat.save_sgf",
    "category": "Function",
    "text": "save_sgf(path::String, sgf)\n\nWrite the given sgf object (e.g. SGFNode, or SGFGameTree) into the given file at path. Note that it is a current limitation that the character encoding is hardcoded to UTF8 (no matter what any property specifies).\n\njulia> using SmartGameFormat\n\njulia> save_sgf(\"/tmp/example.sgf\", SGFGameTree(SGFNode(:KM => 6.5)))\n\njulia> readstring(\"/tmp/example.sgf\") # take a look at file content\n\"(; KM[6.5])\"\n\n\n\n"
},

{
    "location": "#SmartGameFormat.parse_sgf",
    "page": "Home",
    "title": "SmartGameFormat.parse_sgf",
    "category": "Function",
    "text": "parse_sgf(io::IO) -> Vector{SGFGameTree}\nparse_sgf(str::String) -> Vector{SGFGameTree}\n\nRead the content from io (or str), and attempt to parse it as an SGF collection. If successful, the collection is returned as a vector of SGFGameTree. In most cases this collection will just have a single tree.\n\njulia> using SmartGameFormat\n\njulia> col = parse_sgf(\"(; FF[4] KM[6.5]; B[aa])\")\n1-element Array{SmartGameFormat.SGFGameTree,1}:\n SmartGameFormat.SGFNode[KM[6.5] FF[4], B[aa]]\n\njulia> tree = col[1]\n2-node SmartGameFormat.SGFGameTree with 0 variation(s):\n KM[6.5] FF[4]\n B[aa]\n\njulia> node = tree[1]\nSmartGameFormat.SGFNode with 2 properties:\n  :KM => Any[6.5]\n  :FF => Any[\"4\"]\n\nDepending on the content an exception may be thrown to signal that it is not a legal SGF specification.\n\nBase.EOFError: Premature end-of-file encountered during tokenisation.\nLexer.LexicalError: illegal characters used outside property values. For example lower case letters for identifier.\nParser.ParseError: content is not a valid SGF specification (while considering the given the FF version).\n\nInternally, the function simply calls Parser.parse. Take a look at the corresponding documentation for more details.\n\n\n\n"
},

{
    "location": "#SmartGameFormat.print_sgf",
    "page": "Home",
    "title": "SmartGameFormat.print_sgf",
    "category": "Function",
    "text": "print_sgf([io], sgf; [color = true])\n\nWrites the given parsed sfg to io (defaults to STDOUT). If the keyword parameter color = true then an ANSI based syntax highlighting will be used.\n\n\n\n"
},

{
    "location": "#Public-Functions-1",
    "page": "Home",
    "title": "Public Functions",
    "category": "section",
    "text": "load_sgf\nsave_sgf\nparse_sgf\nprint_sgf"
},

{
    "location": "#Index-1",
    "page": "Home",
    "title": "Index",
    "category": "section",
    "text": "Pages = [\"index.md\", \"lexer.md\", \"parser.md\"]"
},

{
    "location": "lexer/#",
    "page": "Lexer Submodule",
    "title": "Lexer Submodule",
    "category": "page",
    "text": ""
},

{
    "location": "lexer/#SmartGameFormat.Lexer",
    "page": "Lexer Submodule",
    "title": "SmartGameFormat.Lexer",
    "category": "Module",
    "text": "The Lexer sub-module is concerned with transcribing a given stream of characters into a sequence of domain specific lexical units called \"token\".\n\nBasic usage:\n\nWrap a plain IO object into a Lexer.TokenStream.\nCall Lexer.next_token to collect another [Lexer.Token].\nGoto 2. unless end of file is reached.\n\n\n\n"
},

{
    "location": "lexer/#Lexer-Submodule-1",
    "page": "Lexer Submodule",
    "title": "Lexer Submodule",
    "category": "section",
    "text": "CurrentModule = SmartGameFormat.LexerLexer"
},

{
    "location": "lexer/#SmartGameFormat.Lexer.Token",
    "page": "Lexer Submodule",
    "title": "SmartGameFormat.Lexer.Token",
    "category": "Type",
    "text": "Token(name::Char, [value::String])\n\nA SGF specific lexical token. It can be either for the following:\n\nToken('\\0'): Empty token to denote trailing whitespaces.\nToken(';'): Separator for nodes.\nToken('(') and Token(')'): Delimiter for game trees.\nToken('[') and Token(']'): Delimiter for property values.\nToken('I', \"AB1\"): Identifier for properties. In general these are made up of one or more uppercase letters. However, with the exception of the first position, digits are also allowed to occur in order to supported older FF versions.\nToken('S', \"abc 23(\\)\"): Any property value between '[' and ']'. This includes moves, numbers, simple text, and text.\n\n\n\n"
},

{
    "location": "lexer/#SmartGameFormat.Lexer.TokenStream",
    "page": "Lexer Submodule",
    "title": "SmartGameFormat.Lexer.TokenStream",
    "category": "Type",
    "text": "TokenStream(io::IO)\n\nStateful decorator around an io to create Token from using next_token.\n\n\n\n"
},

{
    "location": "lexer/#Types-1",
    "page": "Lexer Submodule",
    "title": "Types",
    "category": "section",
    "text": "Token\nTokenStream"
},

{
    "location": "lexer/#SmartGameFormat.Lexer.next_token",
    "page": "Lexer Submodule",
    "title": "SmartGameFormat.Lexer.next_token",
    "category": "Function",
    "text": "next_token(ts::TokenStream) -> Token\n\nReads and returns the next Token from the given token stream ts. If no more token are available, then a EOFError will be thrown.\n\nNote that the lexer should support FF[1]-FF[4] versions. In case any unambiguously illegal character sequence is encountered, the function will throw a LexicalError.\n\n\n\n"
},

{
    "location": "lexer/#Functions-1",
    "page": "Lexer Submodule",
    "title": "Functions",
    "category": "section",
    "text": "next_token"
},

{
    "location": "lexer/#SmartGameFormat.Lexer.LexicalError",
    "page": "Lexer Submodule",
    "title": "SmartGameFormat.Lexer.LexicalError",
    "category": "Type",
    "text": "LexicalError(msg)\n\nThe string or stream passed to Lexer.next_token was not a valid sequence of characters according to the smart game format.\n\n\n\n"
},

{
    "location": "lexer/#Exceptions-1",
    "page": "Lexer Submodule",
    "title": "Exceptions",
    "category": "section",
    "text": "LexicalError"
},

{
    "location": "parser/#",
    "page": "Parser Submodule",
    "title": "Parser Submodule",
    "category": "page",
    "text": ""
},

{
    "location": "parser/#SmartGameFormat.Parser",
    "page": "Parser Submodule",
    "title": "SmartGameFormat.Parser",
    "category": "Module",
    "text": "The Parser sub-module is concerned with converting a sequence of Lexer.Token into a collection (i.e. a vector) of SGFGameTree.\n\nTo that end it provides the following functionality:\n\nParser.parse\nParser.tryparse\nParser.ParseError\n\n\n\n"
},

{
    "location": "parser/#Parser-Submodule-1",
    "page": "Parser Submodule",
    "title": "Parser Submodule",
    "category": "section",
    "text": "CurrentModule = SmartGameFormat.ParserParser"
},

{
    "location": "parser/#SmartGameFormat.Parser.parse",
    "page": "Parser Submodule",
    "title": "SmartGameFormat.Parser.parse",
    "category": "Function",
    "text": "parse(ts::Lexer.TokenStream) -> Vector{SGFGameTree}\n\nRead the lexial token from the stream ts, and attempt to parse it as an SGF collection. If successful, the collection is returned as a vector of SGFGameTree.\n\nDepending on the content an exception may be thrown to signal that it is not a legal SGF specification.\n\nBase.EOFError: Premature end-of-file encountered during tokenisation.\nLexer.LexicalError: illegal characters used outside property values. For example lower case letters for identifier.\nParser.ParseError: content is not a valid SGF specification (while considering the given the FF version).\n\n\n\n"
},

{
    "location": "parser/#SmartGameFormat.Parser.tryparse",
    "page": "Parser Submodule",
    "title": "SmartGameFormat.Parser.tryparse",
    "category": "Function",
    "text": "tryparse(::Type{SGFNode}, seq::Deque{Token}) -> Nullable{SGFNode}\n\nTry to parse the next N token in seq into a SGFNode, which means that the immediate next element in seq is expected to be Token(';') followed by zero or more properties. Each property must have a unique identifier, or a ParseError will be thrown.\n\n\n\ntryparse(::Type{Pair}, seq::Deque{Token}) -> Nullable{Pair{Symbol,Vector{Any}}}\n\nTry to parse the next N token in seq into a Pair denoting a single property of a SGFNode. Note that individual properties are parsed as Pair, because each SGFNode stores all its properties as a single Dict.\n\nFor a property to occur in seq, the immediate next element in seq must be a Token('I', \"<ID>\"), where <ID> is some sequence of uppercase letters denoting the identifier of the token. After the identifier there can be one or more property values. There must be at least one property value.\n\nEach property value must be delimited by a Token('[') at the beginning and a Token(']') at the end. The value itself is contained within those two delimiter token as a single Token('S', \"<val>\") where <val> denotes the value. Note that this \"S\" token is optional and its absence means that the property value is the empty value.\n\n\n\ntryparse(::Type{SGFGameTree}, seq::Deque{Token}) -> Nullable{SGFGameTree}\n\nTry to parse the next N token in seq into a SGFGameTree.\n\nA game tree must start with a Token('('), followed by one or more SGFNode, followed by zero or more sub-SGFGameTree, and finally end with a Token(')').\n\n\n\ntryparse(::Type{Vector{SGFGameTree}}, seq::Deque{Token}) -> Nullable{Vector{SGFGameTree}}\n\nTry to parse the next N token in seq as a Vector of SGFGameTree. Such a vector is called a \"collection\". For a collection to occur there must be at least one parse-able SGFGameTree in seq.\n\n\n\n"
},

{
    "location": "parser/#Functions-1",
    "page": "Parser Submodule",
    "title": "Functions",
    "category": "section",
    "text": "parse\ntryparse"
},

{
    "location": "parser/#SmartGameFormat.Parser.ParseError",
    "page": "Parser Submodule",
    "title": "SmartGameFormat.Parser.ParseError",
    "category": "Type",
    "text": "ParseError(msg)\n\nThe expression passed to Parser.parse could not be interpreted as a valid SGF specification (in accordance with the specified FF version).\n\n\n\n"
},

{
    "location": "parser/#Exceptions-1",
    "page": "Parser Submodule",
    "title": "Exceptions",
    "category": "section",
    "text": "ParseError"
},

]}

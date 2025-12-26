///|
/// Tests for MoonBit tokenizer and highlighter

// =============================================================================
// Tokenizer Tests
// =============================================================================

test "MbtTokenizer tokenizes simple function" {
  let tokenizer = MbtTokenizer::new("fn foo() -> Int { 42 }")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Keyword) // fn
  assert_eq(tokens[1].token_type, Identifier) // foo
  assert_eq(tokens[2].token_type, ParenOpen) // (
  assert_eq(tokens[3].token_type, ParenClose) // )
  assert_eq(tokens[4].token_type, Arrow) // ->
  assert_eq(tokens[5].token_type, TypeName) // Int
  assert_eq(tokens[6].token_type, BraceOpen) // {
  assert_eq(tokens[7].token_type, Number) // 42
  assert_eq(tokens[8].token_type, BraceClose) // }
}

///|
test "MbtTokenizer tokenizes variable declaration" {
  let tokenizer = MbtTokenizer::new("let x = 42")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 4)
  assert_eq(tokens[0].token_type, Keyword) // let
  assert_eq(tokens[1].token_type, Identifier) // x
  assert_eq(tokens[2].token_type, Operator) // =
  assert_eq(tokens[3].token_type, Number) // 42
}

///|
test "MbtTokenizer tokenizes mutable variable" {
  let tokenizer = MbtTokenizer::new("let mut x = 0")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Keyword) // let
  assert_eq(tokens[1].token_type, Keyword) // mut
  assert_eq(tokens[2].token_type, Identifier) // x
}

///|
test "MbtTokenizer tokenizes strings" {
  let tokenizer = MbtTokenizer::new("\"hello\" 'x' b\"bytes\" b'\\n'")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 4)
  assert_eq(tokens[0].token_type, String) // "hello"
  assert_eq(tokens[1].token_type, Char) // 'x'
  assert_eq(tokens[2].token_type, ByteString) // b"bytes"
  assert_eq(tokens[3].token_type, Byte) // b'\n'
}

///|
test "MbtTokenizer tokenizes numbers" {
  let tokenizer = MbtTokenizer::new("123 0xFF 0b101 1.5e10 42L")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 5)
  for token in tokens {
    assert_eq(token.token_type, Number)
  }
}

///|
test "MbtTokenizer tokenizes keywords" {
  let tokenizer = MbtTokenizer::new("fn let if else match while for in")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 8)
  for token in tokens {
    assert_eq(token.token_type, Keyword)
  }
}

///|
test "MbtTokenizer tokenizes boolean" {
  let tokenizer = MbtTokenizer::new("true false")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 2)
  assert_eq(tokens[0].token_type, True)
  assert_eq(tokens[1].token_type, False)
}

///|
test "MbtTokenizer tokenizes type names" {
  let tokenizer = MbtTokenizer::new("Int String Array Option")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 4)
  for token in tokens {
    assert_eq(token.token_type, TypeName)
  }
}

///|
test "MbtTokenizer tokenizes custom type names" {
  let tokenizer = MbtTokenizer::new("MyType FooBar")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 2)
  for token in tokens {
    assert_eq(token.token_type, TypeName)
  }
}

///|
test "MbtTokenizer tokenizes operators" {
  let tokenizer = MbtTokenizer::new("+ - * / == != <= >=")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 8)
  for token in tokens {
    assert_eq(token.token_type, Operator)
  }
}

///|
test "MbtTokenizer tokenizes arrow operators" {
  let tokenizer = MbtTokenizer::new("-> =>")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 2)
  assert_eq(tokens[0].token_type, Arrow)
  assert_eq(tokens[1].token_type, Arrow)
}

///|
test "MbtTokenizer tokenizes range operator" {
  let tokenizer = MbtTokenizer::new("0..10")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0].token_type, Number) // 0
  assert_eq(tokens[1].token_type, Range) // ..
  assert_eq(tokens[2].token_type, Number) // 10
}

///|
test "MbtTokenizer tokenizes pipe operator" {
  let tokenizer = MbtTokenizer::new("x |> f")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0].token_type, Identifier) // x
  assert_eq(tokens[1].token_type, Pipe) // |>
  assert_eq(tokens[2].token_type, Identifier) // f
}

///|
test "MbtTokenizer tokenizes double colon" {
  let tokenizer = MbtTokenizer::new("Foo::bar")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0].token_type, TypeName) // Foo
  assert_eq(tokens[1].token_type, DoubleColon) // ::
  assert_eq(tokens[2].token_type, Identifier) // bar
}

///|
test "MbtTokenizer tokenizes line comment" {
  let tokenizer = MbtTokenizer::new("x // comment\ny")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0].token_type, Identifier) // x
  assert_eq(tokens[1].token_type, LineComment) // // comment
  assert_eq(tokens[2].token_type, Identifier) // y
}

///|
test "MbtTokenizer tokenizes doc comment" {
  let tokenizer = MbtTokenizer::new("///| Documentation\nfn foo() {}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, DocComment) // ///| Documentation
  assert_eq(tokens[1].token_type, Keyword) // fn
}

///|
test "MbtTokenizer tokenizes raw string" {
  let tokenizer = MbtTokenizer::new("#|raw string content")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, RawString)
}

///|
test "MbtTokenizer tokenizes label" {
  let tokenizer = MbtTokenizer::new("foo(~label=value)")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Identifier) // foo
  assert_eq(tokens[1].token_type, ParenOpen) // (
  assert_eq(tokens[2].token_type, Label) // ~label
  assert_eq(tokens[3].token_type, Operator) // =
  assert_eq(tokens[4].token_type, Identifier) // value
}

///|
test "MbtTokenizer tokenizes at symbol" {
  let tokenizer = MbtTokenizer::new("@json.parse")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, At) // @
  assert_eq(tokens[1].token_type, Identifier) // json
  assert_eq(tokens[2].token_type, Dot) // .
  assert_eq(tokens[3].token_type, Identifier) // parse
}

///|
test "MbtTokenizer tokenizes underscore" {
  let tokenizer = MbtTokenizer::new("match x { _ => 0 }")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Keyword) // match
  assert_eq(tokens[1].token_type, Identifier) // x
  assert_eq(tokens[2].token_type, BraceOpen) // {
  assert_eq(tokens[3].token_type, Underscore) // _
  assert_eq(tokens[4].token_type, Arrow) // =>
  assert_eq(tokens[5].token_type, Number) // 0
}

///|
test "MbtTokenizer tokenizes question mark" {
  let tokenizer = MbtTokenizer::new("x?")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 2)
  assert_eq(tokens[0].token_type, Identifier) // x
  assert_eq(tokens[1].token_type, Question) // ?
}

///|
test "MbtTokenizer tokenizes struct definition" {
  let tokenizer = MbtTokenizer::new("struct Point { x : Int, y : Int }")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Keyword) // struct
  assert_eq(tokens[1].token_type, TypeName) // Point
  assert_eq(tokens[2].token_type, BraceOpen) // {
  assert_eq(tokens[3].token_type, Identifier) // x
  assert_eq(tokens[4].token_type, Colon) // :
  assert_eq(tokens[5].token_type, TypeName) // Int
}

///|
test "MbtTokenizer tokenizes enum definition" {
  let tokenizer = MbtTokenizer::new("enum Color { Red, Green, Blue }")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Keyword) // enum
  assert_eq(tokens[1].token_type, TypeName) // Color
  assert_eq(tokens[2].token_type, BraceOpen) // {
  assert_eq(tokens[3].token_type, TypeName) // Red
}

///|
test "MbtTokenizer tokenizes trait definition" {
  let tokenizer = MbtTokenizer::new("trait Show { fn show(self) -> String }")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Keyword) // trait
  assert_eq(tokens[1].token_type, TypeName) // Show
}

///|
test "MbtTokenizer tokenizes test block" {
  let tokenizer = MbtTokenizer::new("test \"name\" { assert_eq(1, 1) }")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Keyword) // test
  assert_eq(tokens[1].token_type, String) // "name"
}

// =============================================================================
// Position Tests
// =============================================================================

///|
test "tokens have correct positions" {
  let source = "let x = 42"
  let tokenizer = MbtTokenizer::new(source)
  let tokens = tokenizer.tokenize_all()

  // let at 0-3
  assert_eq(tokens[0].from, 0)
  assert_eq(tokens[0].to, 3)

  // x at 4-5
  assert_eq(tokens[1].from, 4)
  assert_eq(tokens[1].to, 5)

  // = at 6-7
  assert_eq(tokens[2].from, 6)
  assert_eq(tokens[2].to, 7)

  // 42 at 8-10
  assert_eq(tokens[3].from, 8)
  assert_eq(tokens[3].to, 10)
}

// =============================================================================
// Complex Code Tests
// =============================================================================

///|
test "MbtTokenizer handles real code" {
  let code =
    #|fn fibonacci(n : Int) -> Int {
    #|  if n <= 1 {
    #|    n
    #|  } else {
    #|    fibonacci(n - 1) + fibonacci(n - 2)
    #|  }
    #|}
  let tokenizer = MbtTokenizer::new(code)
  let tokens = tokenizer.tokenize_all()

  // Should have many tokens
  assert_true(tokens.length() > 20)

  // Check some specific tokens exist
  let has_fn = tokens
    .iter()
    .any(fn(t) {
      t.token_type == Keyword &&
      code.unsafe_substring(start=t.from, end=t.to) == "fn"
    })
  let has_if = tokens
    .iter()
    .any(fn(t) {
      t.token_type == Keyword &&
      code.unsafe_substring(start=t.from, end=t.to) == "if"
    })
  let has_else = tokens
    .iter()
    .any(fn(t) {
      t.token_type == Keyword &&
      code.unsafe_substring(start=t.from, end=t.to) == "else"
    })
  assert_true(has_fn)
  assert_true(has_if)
  assert_true(has_else)
}

// =============================================================================
// Highlighter Tests
// =============================================================================

///|
test "highlight_moonbit returns tokens" {
  let tokens = highlight_moonbit("let x = 42")
  assert_true(tokens.length() > 0)
}

///|
test "highlight_moonbit_to_html generates HTML" {
  let html = highlight_moonbit_to_html("fn main { println(\"hello\") }")
  assert_true(html.contains("span"))
  assert_true(html.contains("hl-keyword"))
}

///|
test "highlight_moonbit_to_html escapes HTML" {
  let html = highlight_moonbit_to_html("let x = \"<script>\"")
  assert_true(html.contains("&lt;script&gt;"))
}

///|
test "highlight_moonbit handles type names" {
  let tokens = highlight_moonbit("let x : Int = 42")
  let tags = tokens.map(fn(t) { t.tag })
  assert_true(tags.contains(@lezer.HighlightTag::TypeName))
}

///|
test "highlight_moonbit handles doc comments" {
  let tokens = highlight_moonbit("///| doc\nfn foo() {}")
  let tags = tokens.map(fn(t) { t.tag })
  assert_true(tags.contains(@lezer.HighlightTag::DocComment))
}

// =============================================================================
// Numeric Separator Tests
// =============================================================================

///|
test "MbtTokenizer tokenizes numeric separator in decimal" {
  let tokenizer = MbtTokenizer::new("1_000_000")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, Number)
}

///|
test "MbtTokenizer tokenizes numeric separator in hex" {
  let tokenizer = MbtTokenizer::new("0xFF_FF_FF")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, Number)
}

///|
test "MbtTokenizer tokenizes numeric separator in binary" {
  let tokenizer = MbtTokenizer::new("0b1010_1010")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, Number)
}

// =============================================================================
// String Interpolation Tests
// =============================================================================

///|
test "MbtTokenizer tokenizes simple string without interpolation" {
  let tokenizer = MbtTokenizer::new("\"hello world\"")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, String)
}

///|
test "MbtTokenizer tokenizes string with single interpolation" {
  let tokenizer = MbtTokenizer::new("\"hello \\{name}!\"")
  let tokens = tokenizer.tokenize_all()

  // "hello \{ , name, }!"
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0].token_type, StringHead) // "hello \{
  assert_eq(tokens[1].token_type, Identifier) // name
  assert_eq(tokens[2].token_type, StringTail) // }!"
}

///|
test "MbtTokenizer tokenizes string with multiple interpolations" {
  let tokenizer = MbtTokenizer::new("\"\\{a} + \\{b} = \\{c}\"")
  let tokens = tokenizer.tokenize_all()

  // "\{ , a, } + \{ , b, } = \{ , c, }"
  assert_eq(tokens.length(), 7)
  assert_eq(tokens[0].token_type, StringHead) // "\{
  assert_eq(tokens[1].token_type, Identifier) // a
  assert_eq(tokens[2].token_type, StringMiddle) // } + \{
  assert_eq(tokens[3].token_type, Identifier) // b
  assert_eq(tokens[4].token_type, StringMiddle) // } = \{
  assert_eq(tokens[5].token_type, Identifier) // c
  assert_eq(tokens[6].token_type, StringTail) // }"
}

///|
test "MbtTokenizer tokenizes interpolation with expression" {
  let tokenizer = MbtTokenizer::new("\"result: \\{x + 1}\"")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, StringHead) // "result: \{
  assert_eq(tokens[1].token_type, Identifier) // x
  assert_eq(tokens[2].token_type, Operator) // +
  assert_eq(tokens[3].token_type, Number) // 1
  assert_eq(tokens[4].token_type, StringTail) // }"
}

///|
test "MbtTokenizer tokenizes interpolation with method call" {
  let tokenizer = MbtTokenizer::new("\"value: \\{x.to_string()}\"")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, StringHead) // "value: \{
  assert_eq(tokens[1].token_type, Identifier) // x
  assert_eq(tokens[2].token_type, Dot) // .
  assert_eq(tokens[3].token_type, Identifier) // to_string
  assert_eq(tokens[4].token_type, ParenOpen) // (
  assert_eq(tokens[5].token_type, ParenClose) // )
  assert_eq(tokens[6].token_type, StringTail) // }"
}

///|
test "MbtTokenizer handles escape sequences in interpolated string" {
  let tokenizer = MbtTokenizer::new("\"line1\\nline2: \\{x}\"")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, StringHead) // "line1\nline2: \{
  assert_eq(tokens[1].token_type, Identifier) // x
  assert_eq(tokens[2].token_type, StringTail) // }"
}

///|
test "highlight_moonbit handles string interpolation" {
  let tokens = highlight_moonbit("println(\"Hello \\{name}!\")")
  let tags = tokens.map(fn(t) { t.tag })
  // Should have string tags for the interpolated parts
  assert_true(tags.contains(@lezer.HighlightTag::String))
}

// =============================================================================
// Multi-line Raw String Tests
// =============================================================================

///|
test "MbtTokenizer tokenizes multi-line raw strings" {
  let code =
    #|#|line one
    #|#|line two
    #|#|line three
  let tokenizer = MbtTokenizer::new(code)
  let tokens = tokenizer.tokenize_all()

  // Each #| line should be a separate RawString token
  let raw_count = tokens
    .iter()
    .filter(fn(t) { t.token_type == RawString })
    .count()
  assert_eq(raw_count, 3)
}

///|
test "MbtTokenizer handles raw string in real code" {
  let code =
    #|let s =
    #|  #|Hello
    #|  #|World
  let tokenizer = MbtTokenizer::new(code)
  let tokens = tokenizer.tokenize_all()

  // Should have: let, s, =, #|Hello, #|World
  let has_let = tokens.iter().any(fn(t) { t.token_type == Keyword })
  let has_raw = tokens.iter().any(fn(t) { t.token_type == RawString })
  assert_true(has_let)
  assert_true(has_raw)
}

// =============================================================================
// Interpolated Multi-line String Tests ($|)
// =============================================================================

///|
test "MbtTokenizer tokenizes simple $| string" {
  let tokenizer = MbtTokenizer::new("$|hello world")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, InterpString)
}

///|
test "MbtTokenizer tokenizes $| with interpolation" {
  let tokenizer = MbtTokenizer::new("$|hello \\{name}!")
  let tokens = tokenizer.tokenize_all()

  // $|hello \{ , name, }!
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0].token_type, InterpStringHead) // $|hello \{
  assert_eq(tokens[1].token_type, Identifier) // name
  assert_eq(tokens[2].token_type, InterpStringTail) // }!
}

///|
test "MbtTokenizer tokenizes $| with multiple interpolations" {
  let tokenizer = MbtTokenizer::new("$|\\{a} + \\{b}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 5)
  assert_eq(tokens[0].token_type, InterpStringHead) // $|\{
  assert_eq(tokens[1].token_type, Identifier) // a
  assert_eq(tokens[2].token_type, InterpStringMiddle) // } + \{
  assert_eq(tokens[3].token_type, Identifier) // b
  assert_eq(tokens[4].token_type, InterpStringTail) // }
}

///|
test "MbtTokenizer tokenizes multiple $| lines" {
  let code =
    #|$|line one
    #|$|line two \{x}
  let tokenizer = MbtTokenizer::new(code)
  let tokens = tokenizer.tokenize_all()
  let interp_count = tokens
    .iter()
    .filter(fn(t) {
      match t.token_type {
        InterpString
        | InterpStringHead
        | InterpStringMiddle
        | InterpStringTail => true
        _ => false
      }
    })
    .count()
  assert_true(interp_count >= 2)
}

///|
test "highlight_moonbit handles $| strings" {
  let tokens = highlight_moonbit("$|value: \\{x}")
  let tags = tokens.map(fn(t) { t.tag })
  assert_true(tags.contains(@lezer.HighlightTag::String))
}

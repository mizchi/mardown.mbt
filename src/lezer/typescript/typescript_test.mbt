///|
/// Tests for TypeScript/JavaScript tokenizer and highlighter

// =============================================================================
// Tokenizer Tests
// =============================================================================

test "TsTokenizer tokenizes simple function" {
  let tokenizer = TsTokenizer::new("function foo() {}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 6)
  assert_eq(tokens[0].token_type, Keyword) // function
  assert_eq(tokens[1].token_type, Identifier) // foo
  assert_eq(tokens[2].token_type, ParenOpen) // (
  assert_eq(tokens[3].token_type, ParenClose) // )
  assert_eq(tokens[4].token_type, BraceOpen) // {
  assert_eq(tokens[5].token_type, BraceClose) // }
}

///|
test "TsTokenizer tokenizes variable declaration" {
  let tokenizer = TsTokenizer::new("const x = 42;")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 5)
  assert_eq(tokens[0].token_type, Keyword) // const
  assert_eq(tokens[1].token_type, Identifier) // x
  assert_eq(tokens[2].token_type, Operator) // =
  assert_eq(tokens[3].token_type, Number) // 42
  assert_eq(tokens[4].token_type, Semicolon) // ;
}

///|
test "TsTokenizer tokenizes strings" {
  let tokenizer = TsTokenizer::new("\"hello\" 'world' `template`")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0].token_type, String)
  assert_eq(tokens[1].token_type, String)
  assert_eq(tokens[2].token_type, TemplateString) // Template without interpolation
}

///|
test "TsTokenizer tokenizes numbers" {
  let tokenizer = TsTokenizer::new("123 0xFF 0b101 1.5e10 42n")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 5)
  for token in tokens {
    assert_eq(token.token_type, Number)
  }
}

///|
test "TsTokenizer tokenizes keywords" {
  let tokenizer = TsTokenizer::new(
    "if else function class const let async await",
  )
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 8)
  for token in tokens {
    assert_eq(token.token_type, Keyword)
  }
}

///|
test "TsTokenizer tokenizes boolean and null" {
  let tokenizer = TsTokenizer::new("true false null undefined")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 4)
  assert_eq(tokens[0].token_type, True)
  assert_eq(tokens[1].token_type, False)
  assert_eq(tokens[2].token_type, Null)
  assert_eq(tokens[3].token_type, Undefined)
}

///|
test "TsTokenizer tokenizes operators" {
  // Test operators in realistic contexts
  let tokenizer = TsTokenizer::new("+ - * === !== => ?? ?.")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 8)
  for token in tokens {
    assert_eq(token.token_type, Operator)
  }
}

///|
test "TsTokenizer tokenizes division operator" {
  // Division needs an operand before it (otherwise it's regex)
  let tokenizer = TsTokenizer::new("a / b")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0].token_type, Identifier) // a
  assert_eq(tokens[1].token_type, Operator) // /
  assert_eq(tokens[2].token_type, Identifier) // b
}

///|
test "TsTokenizer tokenizes line comment" {
  let tokenizer = TsTokenizer::new("x // comment\ny")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0].token_type, Identifier) // x
  assert_eq(tokens[1].token_type, LineComment) // // comment
  assert_eq(tokens[2].token_type, Identifier) // y
}

///|
test "TsTokenizer tokenizes block comment" {
  let tokenizer = TsTokenizer::new("x /* comment */ y")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0].token_type, Identifier) // x
  assert_eq(tokens[1].token_type, BlockComment) // /* comment */
  assert_eq(tokens[2].token_type, Identifier) // y
}

///|
test "TsTokenizer tokenizes arrow function" {
  let tokenizer = TsTokenizer::new("(x) => x + 1")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 7)
  assert_eq(tokens[0].token_type, ParenOpen) // (
  assert_eq(tokens[1].token_type, Identifier) // x
  assert_eq(tokens[2].token_type, ParenClose) // )
  assert_eq(tokens[3].token_type, Operator) // =>
  assert_eq(tokens[4].token_type, Identifier) // x
  assert_eq(tokens[5].token_type, Operator) // +
  assert_eq(tokens[6].token_type, Number) // 1
}

///|
test "TsTokenizer tokenizes TypeScript interface" {
  let tokenizer = TsTokenizer::new("interface Foo { name: string }")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Keyword) // interface
  assert_eq(tokens[1].token_type, Identifier) // Foo
  assert_eq(tokens[2].token_type, BraceOpen) // {
  assert_eq(tokens[3].token_type, Identifier) // name
  assert_eq(tokens[4].token_type, Colon) // :
  assert_eq(tokens[5].token_type, TypeName) // string (built-in type)
  assert_eq(tokens[6].token_type, BraceClose) // }
}

///|
test "TsTokenizer tokenizes template literal with interpolation" {
  let tokenizer = TsTokenizer::new("`Hello ${name}!`")
  let tokens = tokenizer.tokenize_all()

  // Template literal with interpolation: TemplateHead, Identifier, TemplateTail
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0].token_type, TemplateHead) // `Hello ${
  assert_eq(tokens[1].token_type, Identifier) // name
  assert_eq(tokens[2].token_type, TemplateTail) // }!`
}

///|
test "TsTokenizer handles escaped strings" {
  let tokenizer = TsTokenizer::new("\"hello\\\"world\"")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, String)
  assert_eq(tokens[0].from, 0)
  assert_eq(tokens[0].to, 14)
}

// =============================================================================
// Highlighter Tests
// =============================================================================

///|
test "highlight_typescript returns tokens for simple code" {
  let tokens = highlight_typescript("const x = 1;")
  assert_true(tokens.length() > 0)
  let tags = tokens.map(fn(t) { t.tag })
  assert_true(tags.contains(@lezer.HighlightTag::Keyword)) // const
  assert_true(tags.contains(@lezer.HighlightTag::VariableName)) // x
  assert_true(tags.contains(@lezer.HighlightTag::Operator)) // =
  assert_true(tags.contains(@lezer.HighlightTag::Number)) // 1
}

///|
test "highlight_typescript handles comments" {
  let tokens = highlight_typescript("x // comment")
  let tags = tokens.map(fn(t) { t.tag })
  assert_true(tags.contains(@lezer.HighlightTag::VariableName)) // x
  assert_true(tags.contains(@lezer.HighlightTag::Comment)) // // comment
}

///|
test "highlight_typescript handles boolean" {
  let tokens = highlight_typescript("true false")
  let tags = tokens.map(fn(t) { t.tag })
  assert_true(tags.contains(@lezer.HighlightTag::Bool))
}

///|
test "highlight_typescript_to_html generates correct HTML" {
  let html = highlight_typescript_to_html("const x = 1;")
  assert_true(html.contains("<span class=\"hl-keyword\">const</span>"))
  assert_true(html.contains("<span class=\"hl-variable\">x</span>"))
  assert_true(html.contains("<span class=\"hl-number\">1</span>"))
}

///|
test "highlight_typescript_to_html escapes HTML" {
  let html = highlight_typescript_to_html("const x = \"<script>\";")
  assert_true(html.contains("&lt;script&gt;"))
}

///|
test "highlight_javascript is alias for highlight_typescript" {
  let ts_tokens = highlight_typescript("const x = 1;")
  let js_tokens = highlight_javascript("const x = 1;")
  assert_eq(ts_tokens.length(), js_tokens.length())
}

// =============================================================================
// Position Tests
// =============================================================================

///|
test "tokens have correct positions" {
  let source = "const x = 42;"
  let tokenizer = TsTokenizer::new(source)
  let tokens = tokenizer.tokenize_all()

  // const at 0-5
  assert_eq(tokens[0].from, 0)
  assert_eq(tokens[0].to, 5)

  // x at 6-7
  assert_eq(tokens[1].from, 6)
  assert_eq(tokens[1].to, 7)

  // = at 8-9
  assert_eq(tokens[2].from, 8)
  assert_eq(tokens[2].to, 9)

  // 42 at 10-12
  assert_eq(tokens[3].from, 10)
  assert_eq(tokens[3].to, 12)

  // ; at 12-13
  assert_eq(tokens[4].from, 12)
  assert_eq(tokens[4].to, 13)
}

// =============================================================================
// Complex Code Tests
// =============================================================================

///|
test "TsTokenizer handles real code" {
  let code =
    #|async function fetchData(url: string): Promise<Data> {
    #|  const response = await fetch(url);
    #|  return response.json();
    #|}
  let tokenizer = TsTokenizer::new(code)
  let tokens = tokenizer.tokenize_all()

  // Should have many tokens
  assert_true(tokens.length() > 20)

  // Check some specific tokens exist
  let has_async = tokens
    .iter()
    .any(fn(t) {
      t.token_type == Keyword &&
      code.unsafe_substring(start=t.from, end=t.to) == "async"
    })
  let has_function = tokens
    .iter()
    .any(fn(t) {
      t.token_type == Keyword &&
      code.unsafe_substring(start=t.from, end=t.to) == "function"
    })
  let has_await = tokens
    .iter()
    .any(fn(t) {
      t.token_type == Keyword &&
      code.unsafe_substring(start=t.from, end=t.to) == "await"
    })
  assert_true(has_async)
  assert_true(has_function)
  assert_true(has_await)
}

// =============================================================================
// JSX/TSX Tests
// =============================================================================

///|
test "TsTokenizer tokenizes simple JSX element" {
  let tokenizer = TsTokenizer::new("const x = <div>hello</div>")
  let tokens = tokenizer.tokenize_all()

  // Should have: const, x, =, <, div, >, hello, </, div, >
  assert_true(tokens.length() >= 8)

  // Check for JSX-specific tokens
  let has_jsx_tag_open = tokens.iter().any(fn(t) { t.token_type == JsxTagOpen })
  let has_jsx_tag_name = tokens.iter().any(fn(t) { t.token_type == JsxTagName })
  let has_jsx_tag_close = tokens
    .iter()
    .any(fn(t) { t.token_type == JsxTagClose })
  let has_jsx_close_tag = tokens
    .iter()
    .any(fn(t) { t.token_type == JsxCloseTag })
  assert_true(has_jsx_tag_open)
  assert_true(has_jsx_tag_name)
  assert_true(has_jsx_tag_close)
  assert_true(has_jsx_close_tag)
}

///|
test "TsTokenizer tokenizes self-closing JSX" {
  let tokenizer = TsTokenizer::new("return <br/>")
  let tokens = tokenizer.tokenize_all()
  let has_jsx_tag_open = tokens.iter().any(fn(t) { t.token_type == JsxTagOpen })
  let has_jsx_tag_name = tokens.iter().any(fn(t) { t.token_type == JsxTagName })
  let has_jsx_tag_close = tokens
    .iter()
    .any(fn(t) { t.token_type == JsxTagClose })
  assert_true(has_jsx_tag_open)
  assert_true(has_jsx_tag_name)
  assert_true(has_jsx_tag_close)
}

///|
test "TsTokenizer tokenizes JSX with attributes" {
  let tokenizer = TsTokenizer::new("return <div className=\"foo\">text</div>")
  let tokens = tokenizer.tokenize_all()
  let has_jsx_attribute = tokens
    .iter()
    .any(fn(t) { t.token_type == JsxAttribute })
  let has_jsx_equals = tokens.iter().any(fn(t) { t.token_type == JsxEquals })
  let has_string = tokens.iter().any(fn(t) { t.token_type == String })
  assert_true(has_jsx_attribute)
  assert_true(has_jsx_equals)
  assert_true(has_string)
}

///|
test "TsTokenizer tokenizes JSX expression" {
  let tokenizer = TsTokenizer::new("return <div>{value}</div>")
  let tokens = tokenizer.tokenize_all()
  let has_jsx_expr_start = tokens
    .iter()
    .any(fn(t) { t.token_type == JsxExprStart })
  let has_jsx_expr_end = tokens.iter().any(fn(t) { t.token_type == JsxExprEnd })
  let has_identifier = tokens.iter().any(fn(t) { t.token_type == Identifier })
  assert_true(has_jsx_expr_start)
  assert_true(has_jsx_expr_end)
  assert_true(has_identifier)
}

///|
test "TsTokenizer tokenizes JSX text content" {
  let tokenizer = TsTokenizer::new("return <p>Hello World</p>")
  let tokens = tokenizer.tokenize_all()
  let has_jsx_text = tokens.iter().any(fn(t) { t.token_type == JsxText })
  assert_true(has_jsx_text)
}

///|
test "TsTokenizer handles nested JSX" {
  let tokenizer = TsTokenizer::new("return <div><span>nested</span></div>")
  let tokens = tokenizer.tokenize_all()

  // Count JSX tag opens (should be at least 2: div, span)
  let jsx_opens = tokens
    .iter()
    .filter(fn(t) { t.token_type == JsxTagOpen })
    .count()
  assert_true(jsx_opens >= 2)
}

///|
test "TsTokenizer distinguishes JSX from comparison" {
  // This should NOT be JSX - it's a comparison
  let tokenizer = TsTokenizer::new("if (x < 10) {}")
  let tokens = tokenizer.tokenize_all()

  // Should have Operator for <, not JsxTagOpen
  let has_operator = tokens.iter().any(fn(t) { t.token_type == Operator })
  let has_jsx = tokens.iter().any(fn(t) { t.token_type == JsxTagOpen })
  assert_true(has_operator)
  assert_false(has_jsx)
}

///|
test "highlight_typescript handles JSX" {
  let tokens = highlight_typescript("const x = <div>hello</div>")
  let tags = tokens.map(fn(t) { t.tag })
  assert_true(tags.contains(@lezer.HighlightTag::Keyword)) // const
  assert_true(tags.contains(@lezer.HighlightTag::TagBracket)) // < > </
  assert_true(tags.contains(@lezer.HighlightTag::TagName)) // div
}

///|
test "highlight_typescript_to_html generates correct JSX HTML" {
  let html = highlight_typescript_to_html("return <div>text</div>")
  assert_true(html.contains("<span class=\"hl-keyword\">return</span>"))
  assert_true(html.contains("<span class=\"hl-tag-bracket\">"))
  assert_true(html.contains("<span class=\"hl-tag\">div</span>"))
}

// =============================================================================
// Decorator Tests
// =============================================================================

///|
test "TsTokenizer tokenizes simple decorator" {
  let tokenizer = TsTokenizer::new("@Component")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, Decorator)
}

///|
test "TsTokenizer tokenizes decorator with dot notation" {
  let tokenizer = TsTokenizer::new("@angular.Component")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, Decorator)
  assert_eq(
    "@angular.Component".unsafe_substring(
      start=tokens[0].from,
      end=tokens[0].to,
    ),
    "@angular.Component",
  )
}

///|
test "TsTokenizer tokenizes decorator on class" {
  let tokenizer = TsTokenizer::new("@Injectable() class Service {}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Decorator) // @Injectable
  assert_eq(tokens[1].token_type, ParenOpen) // (
  assert_eq(tokens[2].token_type, ParenClose) // )
  assert_eq(tokens[3].token_type, Keyword) // class
}

// =============================================================================
// Private Field Tests
// =============================================================================

///|
test "TsTokenizer tokenizes private field" {
  let tokenizer = TsTokenizer::new("#privateField")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, PrivateId)
}

///|
test "TsTokenizer tokenizes private field in class" {
  let tokenizer = TsTokenizer::new("class Foo { #secret = 42 }")
  let tokens = tokenizer.tokenize_all()
  let has_private = tokens.iter().any(fn(t) { t.token_type == PrivateId })
  assert_true(has_private)
}

///|
test "TsTokenizer tokenizes private method call" {
  let tokenizer = TsTokenizer::new("this.#method()")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Keyword) // this
  assert_eq(tokens[1].token_type, Dot) // .
  assert_eq(tokens[2].token_type, PrivateId) // #method
}

// =============================================================================
// Template Literal Tests
// =============================================================================

///|
test "TsTokenizer tokenizes simple template literal" {
  let tokenizer = TsTokenizer::new("`hello world`")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, TemplateString)
}

///|
test "TsTokenizer tokenizes template with multiple interpolations" {
  let tokenizer = TsTokenizer::new("`${a} + ${b} = ${c}`")
  let tokens = tokenizer.tokenize_all()

  // TemplateHead ${, a, TemplateMiddle ${, b, TemplateMiddle ${, c, TemplateTail
  assert_eq(tokens.length(), 7)
  assert_eq(tokens[0].token_type, TemplateHead)
  assert_eq(tokens[1].token_type, Identifier)
  assert_eq(tokens[2].token_type, TemplateMiddle)
  assert_eq(tokens[3].token_type, Identifier)
  assert_eq(tokens[4].token_type, TemplateMiddle)
  assert_eq(tokens[5].token_type, Identifier)
  assert_eq(tokens[6].token_type, TemplateTail)
}

///|
test "TsTokenizer tokenizes template with expression" {
  let tokenizer = TsTokenizer::new("`result: ${x + 1}`")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, TemplateHead) // `result: ${
  assert_eq(tokens[1].token_type, Identifier) // x
  assert_eq(tokens[2].token_type, Operator) // +
  assert_eq(tokens[3].token_type, Number) // 1
  assert_eq(tokens[4].token_type, TemplateTail) // }`
}

///|
test "highlight_typescript handles decorators" {
  let tokens = highlight_typescript("@Component class Foo {}")
  let tags = tokens.map(fn(t) { t.tag })
  assert_true(tags.contains(@lezer.HighlightTag::Meta))
}

///|
test "highlight_typescript handles private fields" {
  let tokens = highlight_typescript("this.#field")
  let tags = tokens.map(fn(t) { t.tag })
  assert_true(tags.contains(@lezer.HighlightTag::PrivateName))
}

// =============================================================================
// Regex Tests
// =============================================================================

///|
test "TsTokenizer tokenizes simple regex" {
  let tokenizer = TsTokenizer::new("const re = /abc/g")
  let tokens = tokenizer.tokenize_all()
  let has_regex = tokens.iter().any(fn(t) { t.token_type == Regex })
  assert_true(has_regex)

  // Find the regex token
  let regex_token = tokens.iter().find_first(fn(t) { t.token_type == Regex })
  assert_true(regex_token is Some(_))
  let re = regex_token.unwrap()
  assert_eq(
    "const re = /abc/g".unsafe_substring(start=re.from, end=re.to),
    "/abc/g",
  )
}

///|
test "TsTokenizer tokenizes regex with multiple flags" {
  let tokenizer = TsTokenizer::new("const re = /pattern/gim")
  let tokens = tokenizer.tokenize_all()
  let regex_token = tokens.iter().find_first(fn(t) { t.token_type == Regex })
  assert_true(regex_token is Some(_))
  let re = regex_token.unwrap()
  assert_eq(
    "const re = /pattern/gim".unsafe_substring(start=re.from, end=re.to),
    "/pattern/gim",
  )
}

///|
test "TsTokenizer tokenizes regex with escapes" {
  let tokenizer = TsTokenizer::new("const re = /a\\/b/")
  let tokens = tokenizer.tokenize_all()
  let has_regex = tokens.iter().any(fn(t) { t.token_type == Regex })
  assert_true(has_regex)
}

///|
test "TsTokenizer tokenizes regex with character class" {
  let tokenizer = TsTokenizer::new("const re = /[a-z]/")
  let tokens = tokenizer.tokenize_all()
  let regex_token = tokens.iter().find_first(fn(t) { t.token_type == Regex })
  assert_true(regex_token is Some(_))
}

///|
test "TsTokenizer tokenizes regex with slash in character class" {
  // /[/]/ should work - the / inside [] doesn't end the regex
  let tokenizer = TsTokenizer::new("const re = /[/]/")
  let tokens = tokenizer.tokenize_all()
  let regex_token = tokens.iter().find_first(fn(t) { t.token_type == Regex })
  assert_true(regex_token is Some(_))
  let re = regex_token.unwrap()
  assert_eq(
    "const re = /[/]/".unsafe_substring(start=re.from, end=re.to),
    "/[/]/",
  )
}

///|
test "TsTokenizer distinguishes regex from division" {
  // a / b should be division, not regex
  let tokenizer = TsTokenizer::new("x / y")
  let tokens = tokenizer.tokenize_all()
  let has_regex = tokens.iter().any(fn(t) { t.token_type == Regex })
  let has_operator = tokens.iter().any(fn(t) { t.token_type == Operator })
  assert_false(has_regex)
  assert_true(has_operator)
}

///|
test "TsTokenizer handles regex after return" {
  let tokenizer = TsTokenizer::new("return /test/")
  let tokens = tokenizer.tokenize_all()
  let has_regex = tokens.iter().any(fn(t) { t.token_type == Regex })
  assert_true(has_regex)
}

///|
test "TsTokenizer handles regex after assignment" {
  let tokenizer = TsTokenizer::new("x = /test/")
  let tokens = tokenizer.tokenize_all()
  let has_regex = tokens.iter().any(fn(t) { t.token_type == Regex })
  assert_true(has_regex)
}

///|
test "TsTokenizer handles regex in function call" {
  let tokenizer = TsTokenizer::new("match(/test/g)")
  let tokens = tokenizer.tokenize_all()
  let has_regex = tokens.iter().any(fn(t) { t.token_type == Regex })
  assert_true(has_regex)
}

///|
test "highlight_typescript handles regex" {
  let tokens = highlight_typescript("const re = /test/gi")
  let tags = tokens.map(fn(t) { t.tag })
  assert_true(tags.contains(@lezer.HighlightTag::Regexp))
}

// =============================================================================
// Incremental Tokenization Tests
// =============================================================================

///|
test "TsTokenizer::save_state and from_state work correctly" {
  let source = "const x = 1; const y = 2;"
  let tokenizer = TsTokenizer::new(source)

  // Tokenize first part
  let _ = tokenizer.next_token() // const
  let _ = tokenizer.next_token() // x
  let _ = tokenizer.next_token() // =
  let _ = tokenizer.next_token() // 1
  let _ = tokenizer.next_token() // ;

  // Save state
  let state = tokenizer.save_state()

  // Create new tokenizer from state
  let tokenizer2 = TsTokenizer::from_state(source, state)
  let token = tokenizer2.next_token()
  assert_true(token is Some(_))
  assert_eq(token.unwrap().token_type, Keyword) // const
}

///|
test "TokenCache creates tokens for all lines" {
  let source = "const x = 1;\nconst y = 2;"
  let cache = TokenCache::new(source)

  // Should have tokens
  let all_tokens = cache.all_tokens()
  assert_true(all_tokens.length() > 0)

  // Line count should be at least 1
  assert_true(cache.line_count() >= 1)
}

///|
test "TokenCache::get_line_tokens returns correct tokens" {
  let source = "const x = 1;"
  let cache = TokenCache::new(source)
  let line0_tokens = cache.get_line_tokens(0)
  assert_true(line0_tokens.length() > 0)

  // First token should be const (keyword)
  assert_eq(line0_tokens[0].token_type, Keyword)
}

///|
test "TokenCache::update re-tokenizes from edit point" {
  let source1 = "const x = 1;\nconst y = 2;"
  let cache = TokenCache::new(source1)
  let initial_count = cache.all_tokens().length()

  // Modify second line
  let source2 = "const x = 1;\nconst y = 3;"
  let (start, _) = cache.update(source2, 1)

  // Should have re-tokenized at least line 1
  assert_true(start <= 1)

  // Token count should be the same
  assert_eq(cache.all_tokens().length(), initial_count)
}

// =============================================================================
// Spread Operator Tests
// =============================================================================

///|
test "TsTokenizer tokenizes spread operator" {
  let tokenizer = TsTokenizer::new("...args")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 2)
  assert_eq(tokens[0].token_type, Spread)
  assert_eq(tokens[1].token_type, Identifier)
}

///|
test "TsTokenizer tokenizes spread in array" {
  let tokenizer = TsTokenizer::new("[...arr, 1]")
  let tokens = tokenizer.tokenize_all()
  let has_spread = tokens.iter().any(fn(t) { t.token_type == Spread })
  assert_true(has_spread)
}

///|
test "TsTokenizer tokenizes spread in object" {
  let tokenizer = TsTokenizer::new("{...obj}")
  let tokens = tokenizer.tokenize_all()
  let has_spread = tokens.iter().any(fn(t) { t.token_type == Spread })
  assert_true(has_spread)
}

///|
test "TsTokenizer tokenizes spread in function call" {
  let tokenizer = TsTokenizer::new("fn(...items)")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Identifier) // fn
  assert_eq(tokens[1].token_type, ParenOpen) // (
  assert_eq(tokens[2].token_type, Spread) // ...
  assert_eq(tokens[3].token_type, Identifier) // items
}

///|
test "TsTokenizer distinguishes spread from dots" {
  let tokenizer = TsTokenizer::new("a.b..c")
  let tokens = tokenizer.tokenize_all()

  // a, ., b, ., ., c (no spread - only 2 dots)
  let spread_count = tokens
    .iter()
    .filter(fn(t) { t.token_type == Spread })
    .count()
  let dot_count = tokens.iter().filter(fn(t) { t.token_type == Dot }).count()
  assert_eq(spread_count, 0)
  assert_eq(dot_count, 3)
}

///|
test "highlight_typescript handles spread operator" {
  let tokens = highlight_typescript("[...arr]")
  let tags = tokens.map(fn(t) { t.tag })
  assert_true(tags.contains(@lezer.HighlightTag::Operator))
}

// =============================================================================
// Numeric Separator Tests
// =============================================================================

///|
test "TsTokenizer tokenizes numeric separator in decimal" {
  let tokenizer = TsTokenizer::new("const x = 1_000_000")
  let tokens = tokenizer.tokenize_all()
  let num_token = tokens.iter().find_first(fn(t) { t.token_type == Number })
  assert_true(num_token is Some(_))
  let num = num_token.unwrap()
  assert_eq(
    "const x = 1_000_000".unsafe_substring(start=num.from, end=num.to),
    "1_000_000",
  )
}

///|
test "TsTokenizer tokenizes numeric separator in hex" {
  let tokenizer = TsTokenizer::new("0xFF_FF_FF")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, Number)
}

///|
test "TsTokenizer tokenizes numeric separator in binary" {
  let tokenizer = TsTokenizer::new("0b1010_1010")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, Number)
}

///|
test "TsTokenizer tokenizes numeric separator in octal" {
  let tokenizer = TsTokenizer::new("0o777_777")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, Number)
}

///|
test "TsTokenizer tokenizes numeric separator in float" {
  let tokenizer = TsTokenizer::new("1_000.123_456")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, Number)
}

///|
test "TsTokenizer tokenizes numeric separator in exponent" {
  let tokenizer = TsTokenizer::new("1e1_000")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, Number)
}

// =============================================================================
// Type Name Tests
// =============================================================================

///|
test "TsTokenizer tokenizes primitive type names" {
  let tokenizer = TsTokenizer::new("string number boolean bigint symbol")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 5)
  for token in tokens {
    assert_eq(token.token_type, TypeName)
  }
}

///|
test "TsTokenizer tokenizes special type names" {
  // void is a keyword (void 0), so we test the others
  let tokenizer = TsTokenizer::new("any unknown never object")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 4)
  for token in tokens {
    assert_eq(token.token_type, TypeName)
  }
}

///|
test "TsTokenizer tokenizes utility type names" {
  let tokenizer = TsTokenizer::new("Array Map Set Promise Record")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 5)
  for token in tokens {
    assert_eq(token.token_type, TypeName)
  }
}

///|
test "TsTokenizer tokenizes type annotation" {
  let tokenizer = TsTokenizer::new("const x: number = 42")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Keyword) // const
  assert_eq(tokens[1].token_type, Identifier) // x
  assert_eq(tokens[2].token_type, Colon) // :
  assert_eq(tokens[3].token_type, TypeName) // number
  assert_eq(tokens[4].token_type, Operator) // =
  assert_eq(tokens[5].token_type, Number) // 42
}

///|
test "TsTokenizer tokenizes function with typed params" {
  let tokenizer = TsTokenizer::new("function foo(x: string): number")
  let tokens = tokenizer.tokenize_all()
  let has_string = tokens.iter().any(fn(t) { t.token_type == TypeName })
  let has_number = tokens.iter().any(fn(t) { t.token_type == TypeName })
  assert_true(has_string)
  assert_true(has_number)
}

///|
test "TsTokenizer tokenizes generic types" {
  let tokenizer = TsTokenizer::new("Array<string>")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, TypeName) // Array
  assert_eq(tokens[1].token_type, Operator) // <
  assert_eq(tokens[2].token_type, TypeName) // string
  assert_eq(tokens[3].token_type, Operator) // >
}

///|
test "highlight_typescript handles type names" {
  let tokens = highlight_typescript("const x: string = 'hello'")
  let tags = tokens.map(fn(t) { t.tag })
  assert_true(tags.contains(@lezer.HighlightTag::TypeName))
}

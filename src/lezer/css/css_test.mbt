///|
/// CSS tokenizer and highlighter tests

// =============================================================================
// Selector Tests
// =============================================================================

test "tokenize: tag selector" {
  let tokenizer = CssTokenizer::new("div {}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, TagSelector)
  assert_eq(tokens[1].token_type, BraceOpen)
  assert_eq(tokens[2].token_type, BraceClose)
}

///|
test "tokenize: class selector" {
  let tokenizer = CssTokenizer::new(".container {}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, ClassSelector)
}

///|
test "tokenize: id selector" {
  let tokenizer = CssTokenizer::new("#main {}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, IdSelector)
}

///|
test "tokenize: universal selector" {
  let tokenizer = CssTokenizer::new("* {}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, UniversalSelector)
}

///|
test "tokenize: pseudo-class" {
  let tokenizer = CssTokenizer::new("a:hover {}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, TagSelector)
  assert_eq(tokens[1].token_type, PseudoClass)
}

///|
test "tokenize: pseudo-element" {
  let tokenizer = CssTokenizer::new("p::before {}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, TagSelector)
  assert_eq(tokens[1].token_type, PseudoElement)
}

///|
test "tokenize: multiple selectors" {
  let tokenizer = CssTokenizer::new("div, span, p {}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, TagSelector)
  assert_eq(tokens[1].token_type, Comma)
  assert_eq(tokens[2].token_type, TagSelector)
}

///|
test "tokenize: child combinator" {
  let tokenizer = CssTokenizer::new("div > span {}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, TagSelector)
  assert_eq(tokens[1].token_type, Combinator)
  assert_eq(tokens[2].token_type, TagSelector)
}

// =============================================================================
// Property Tests
// =============================================================================

///|
test "tokenize: simple property" {
  let tokenizer = CssTokenizer::new(".foo { color: red; }")
  let tokens = tokenizer.tokenize_all()

  // .foo, {, color, :, red, ;, }
  assert_eq(tokens[0].token_type, ClassSelector)
  assert_eq(tokens[1].token_type, BraceOpen)
  assert_eq(tokens[2].token_type, PropertyName)
  assert_eq(tokens[3].token_type, Colon)
  assert_eq(tokens[4].token_type, PropertyValue)
  assert_eq(tokens[5].token_type, Semicolon)
}

///|
test "tokenize: number with unit" {
  let tokenizer = CssTokenizer::new(".foo { width: 100px; }")
  let tokens = tokenizer.tokenize_all()

  // Find number and unit
  let mut found_number = false
  let mut found_unit = false
  for token in tokens {
    if token.token_type == Number {
      found_number = true
    }
    if token.token_type == Unit {
      found_unit = true
    }
  }
  assert_true(found_number)
  assert_true(found_unit)
}

///|
test "tokenize: hex color" {
  let tokenizer = CssTokenizer::new(".foo { color: #ff0000; }")
  let tokens = tokenizer.tokenize_all()
  let mut found_color = false
  for token in tokens {
    if token.token_type == Color {
      found_color = true
      break
    }
  }
  assert_true(found_color)
}

///|
test "tokenize: short hex color" {
  let tokenizer = CssTokenizer::new(".foo { color: #fff; }")
  let tokens = tokenizer.tokenize_all()
  let mut found_color = false
  for token in tokens {
    if token.token_type == Color {
      found_color = true
      break
    }
  }
  assert_true(found_color)
}

///|
test "tokenize: string value" {
  let tokenizer = CssTokenizer::new(".foo { content: \"hello\"; }")
  let tokens = tokenizer.tokenize_all()
  let mut found_string = false
  for token in tokens {
    if token.token_type == String {
      found_string = true
      break
    }
  }
  assert_true(found_string)
}

///|
test "tokenize: url value" {
  let tokenizer = CssTokenizer::new(".foo { background: url(image.png); }")
  let tokens = tokenizer.tokenize_all()
  let mut found_url = false
  for token in tokens {
    if token.token_type == Url {
      found_url = true
      break
    }
  }
  assert_true(found_url)
}

///|
test "tokenize: function value" {
  let tokenizer = CssTokenizer::new(".foo { color: rgb(255, 0, 0); }")
  let tokens = tokenizer.tokenize_all()
  let mut found_function = false
  for token in tokens {
    if token.token_type == Function {
      found_function = true
      break
    }
  }
  assert_true(found_function)
}

///|
test "tokenize: important" {
  let tokenizer = CssTokenizer::new(".foo { color: red !important; }")
  let tokens = tokenizer.tokenize_all()
  let mut found_important = false
  for token in tokens {
    if token.token_type == Important {
      found_important = true
      break
    }
  }
  assert_true(found_important)
}

// =============================================================================
// At-rule Tests
// =============================================================================

///|
test "tokenize: media query" {
  let tokenizer = CssTokenizer::new("@media screen {}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, AtKeyword)
}

///|
test "tokenize: keyframes" {
  let tokenizer = CssTokenizer::new("@keyframes fade {}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, AtKeyword)
}

///|
test "tokenize: import" {
  let tokenizer = CssTokenizer::new("@import \"styles.css\";")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, AtKeyword)
  assert_eq(tokens[1].token_type, String)
}

// =============================================================================
// Comment Tests
// =============================================================================

///|
test "tokenize: single line comment" {
  let tokenizer = CssTokenizer::new("/* comment */ .foo {}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Comment)
}

///|
test "tokenize: multi-line comment" {
  let source =
    #|/* This is
    #|   a multi-line
    #|   comment */
    #|.foo {}
  let tokenizer = CssTokenizer::new(source)
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Comment)
}

// =============================================================================
// Complex Cases
// =============================================================================

///|
test "tokenize: multiple properties" {
  let source =
    #|.container {
    #|  width: 100%;
    #|  padding: 10px 20px;
    #|  background-color: #f0f0f0;
    #|}
  let tokenizer = CssTokenizer::new(source)
  let tokens = tokenizer.tokenize_all()
  assert_true(tokens.length() >= 10)
}

///|
test "tokenize: nested media query" {
  let source =
    #|@media (max-width: 768px) {
    #|  .container {
    #|    width: 100%;
    #|  }
    #|}
  let tokenizer = CssTokenizer::new(source)
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, AtKeyword)
}

// =============================================================================
// Highlight Tests
// =============================================================================

///|
test "highlight: produces tokens" {
  let tokens = highlight_css(".foo { color: red; }")
  assert_true(tokens.length() >= 4)
}

///|
test "highlight: class selector highlighted" {
  let tokens = highlight_css(".container {}")
  assert_true(tokens.length() >= 1)
}

///|
test "highlight: comment highlighted" {
  let tokens = highlight_css("/* comment */")
  assert_eq(tokens.length(), 1)
}

// =============================================================================
// HTML Output Tests
// =============================================================================

///|
test "html_output: contains spans" {
  let html = highlight_css_to_html(".foo { color: red; }")
  assert_true(html.contains("<span"))
}

///|
test "html_output: handles empty input" {
  let html = highlight_css_to_html("")
  assert_eq(html, "")
}

// =============================================================================
// Edge Cases
// =============================================================================

///|
test "edge: unclosed comment" {
  let tokenizer = CssTokenizer::new("/* unclosed")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Comment)
}

///|
test "edge: empty rule" {
  let tokenizer = CssTokenizer::new(".foo {}")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, ClassSelector)
  assert_eq(tokens[1].token_type, BraceOpen)
  assert_eq(tokens[2].token_type, BraceClose)
}

///|
test "edge: decimal number" {
  let tokenizer = CssTokenizer::new(".foo { opacity: 0.5; }")
  let tokens = tokenizer.tokenize_all()
  let mut found_number = false
  for token in tokens {
    if token.token_type == Number {
      found_number = true
      break
    }
  }
  assert_true(found_number)
}

///|
test "edge: percent unit" {
  let tokenizer = CssTokenizer::new(".foo { width: 50%; }")
  let tokens = tokenizer.tokenize_all()
  let mut found_unit = false
  for token in tokens {
    if token.token_type == Unit {
      found_unit = true
      break
    }
  }
  assert_true(found_unit)
}

///|
test "edge: vendor prefix" {
  let tokenizer = CssTokenizer::new(".foo { -webkit-transform: none; }")
  let tokens = tokenizer.tokenize_all()

  // -webkit-transform should be a property name
  let mut found = false
  for token in tokens {
    if token.token_type == PropertyName {
      found = true
      break
    }
  }
  assert_true(found)
}

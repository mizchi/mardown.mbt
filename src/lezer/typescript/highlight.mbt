///| TypeScript/JavaScript syntax highlighting

// =============================================================================
// TypeScript Highlighter
// =============================================================================

///|
/// Create a highlighter configured for TypeScript/JavaScript/TSX/JSX
pub fn ts_highlighter() -> @lezer.Highlighter {
  let h = @lezer.Highlighter::new()

  // Keywords
  h.add_rule("Keyword", Keyword)

  // Literals
  h.add_rule("String", String)
  h.add_rule("Number", Number)
  h.add_rule("Regex", Regexp)
  h.add_rule("TemplateString", String)
  h.add_rule("TemplateHead", String)
  h.add_rule("TemplateMiddle", String)
  h.add_rule("TemplateTail", String)
  h.add_rule("True", Bool)
  h.add_rule("False", Bool)
  h.add_rule("Null", Null)
  h.add_rule("Undefined", Null)

  // Names
  h.add_rule("Identifier", VariableName)
  h.add_rule("PrivateId", PrivateName)
  h.add_rule("TypeName", TypeName)

  // Decorators
  h.add_rule("Decorator", Meta)

  // Operators
  h.add_rule("Operator", Operator)
  h.add_rule("Spread", Operator)

  // Punctuation
  h.add_rule("BraceOpen", Brace)
  h.add_rule("BraceClose", Brace)
  h.add_rule("BracketOpen", Bracket)
  h.add_rule("BracketClose", Bracket)
  h.add_rule("ParenOpen", Paren)
  h.add_rule("ParenClose", Paren)
  h.add_rule("Semicolon", Punctuation)
  h.add_rule("Comma", Punctuation)
  h.add_rule("Dot", Punctuation)
  h.add_rule("Colon", Punctuation)

  // Comments
  h.add_rule("LineComment", Comment)
  h.add_rule("BlockComment", Comment)

  // JSX
  h.add_rule("JsxTagOpen", TagBracket) // <
  h.add_rule("JsxTagClose", TagBracket) // > or />
  h.add_rule("JsxCloseTag", TagBracket) // </
  h.add_rule("JsxTagName", TagName) // div, MyComponent
  h.add_rule("JsxAttribute", PropertyName) // className, onClick
  h.add_rule("JsxEquals", Operator) // = in attr=
  h.add_rule("JsxText", None) // plain text, no highlight
  h.add_rule("JsxExprStart", Brace) // { in JSX
  h.add_rule("JsxExprEnd", Brace) // } in JSX
  h
}

///|
/// Convert token type to string for highlighter lookup
fn token_type_name(t : TsTokenType) -> String {
  match t {
    Keyword => "Keyword"
    String => "String"
    Number => "Number"
    Regex => "Regex"
    TemplateString => "TemplateString"
    TemplateHead => "TemplateHead"
    TemplateMiddle => "TemplateMiddle"
    TemplateTail => "TemplateTail"
    True => "True"
    False => "False"
    Null => "Null"
    Undefined => "Undefined"
    Identifier => "Identifier"
    PrivateId => "PrivateId"
    TypeName => "TypeName"
    Decorator => "Decorator"
    Operator => "Operator"
    Spread => "Spread"
    BraceOpen => "BraceOpen"
    BraceClose => "BraceClose"
    BracketOpen => "BracketOpen"
    BracketClose => "BracketClose"
    ParenOpen => "ParenOpen"
    ParenClose => "ParenClose"
    Semicolon => "Semicolon"
    Comma => "Comma"
    Dot => "Dot"
    Colon => "Colon"
    LineComment => "LineComment"
    BlockComment => "BlockComment"
    // JSX
    JsxTagOpen => "JsxTagOpen"
    JsxTagClose => "JsxTagClose"
    JsxCloseTag => "JsxCloseTag"
    JsxTagName => "JsxTagName"
    JsxAttribute => "JsxAttribute"
    JsxEquals => "JsxEquals"
    JsxText => "JsxText"
    JsxExprStart => "JsxExprStart"
    JsxExprEnd => "JsxExprEnd"
    Error => "Error"
  }
}

///|
/// Highlight TypeScript/JavaScript source code
pub fn highlight_typescript(source : String) -> Array[@lezer.HighlightToken] {
  let tokenizer = TsTokenizer::new(source)
  let tokens = tokenizer.tokenize_all()
  let highlighter = ts_highlighter()
  let result : Array[@lezer.HighlightToken] = []
  for token in tokens {
    let name = token_type_name(token.token_type)
    let tag = highlighter.get_tag(name)
    if tag != @lezer.HighlightTag::None {
      result.push(@lezer.HighlightToken::new(token.from, token.to, tag))
    }
  }
  result
}

///|
/// Convenience: highlight TypeScript and generate HTML
pub fn highlight_typescript_to_html(source : String) -> String {
  let tokens = highlight_typescript(source)
  @lezer.tokens_to_html(source, tokens)
}

///|
/// Alias for JavaScript (same tokenizer)
pub fn highlight_javascript(source : String) -> Array[@lezer.HighlightToken] {
  highlight_typescript(source)
}

///|
/// Alias for JavaScript HTML output
pub fn highlight_javascript_to_html(source : String) -> String {
  highlight_typescript_to_html(source)
}

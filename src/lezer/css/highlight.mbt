///| CSS syntax highlighting

// =============================================================================
// CSS Highlighter
// =============================================================================

///|
/// Create a highlighter configured for CSS
pub fn css_highlighter() -> @lezer.Highlighter {
  let h = @lezer.Highlighter::new()

  // Selectors
  h.add_rule("TagSelector", TagName)
  h.add_rule("ClassSelector", ClassName)
  h.add_rule("IdSelector", ClassName)
  h.add_rule("PseudoClass", Keyword)
  h.add_rule("PseudoElement", Keyword)
  h.add_rule("AttrSelector", PropertyName)
  h.add_rule("UniversalSelector", Operator)
  h.add_rule("Combinator", Operator)

  // At-rules
  h.add_rule("AtKeyword", Meta)

  // Properties and values
  h.add_rule("PropertyName", PropertyName)
  h.add_rule("PropertyValue", VariableName)
  h.add_rule("Number", Number)
  h.add_rule("Unit", Keyword)
  h.add_rule("Color", String)
  h.add_rule("String", String)
  h.add_rule("Url", String)
  h.add_rule("Function", FunctionName)
  h.add_rule("Important", Keyword)

  // Punctuation
  h.add_rule("BraceOpen", Brace)
  h.add_rule("BraceClose", Brace)
  h.add_rule("ParenOpen", Paren)
  h.add_rule("ParenClose", Paren)
  h.add_rule("BracketOpen", Bracket)
  h.add_rule("BracketClose", Bracket)
  h.add_rule("Colon", Punctuation)
  h.add_rule("Semicolon", Punctuation)
  h.add_rule("Comma", Punctuation)

  // Comments
  h.add_rule("Comment", Comment)
  h
}

///|
/// Convert token type to string for highlighter lookup
fn token_type_name(t : CssTokenType) -> String {
  match t {
    TagSelector => "TagSelector"
    ClassSelector => "ClassSelector"
    IdSelector => "IdSelector"
    PseudoClass => "PseudoClass"
    PseudoElement => "PseudoElement"
    AttrSelector => "AttrSelector"
    UniversalSelector => "UniversalSelector"
    Combinator => "Combinator"
    AtKeyword => "AtKeyword"
    PropertyName => "PropertyName"
    PropertyValue => "PropertyValue"
    Number => "Number"
    Unit => "Unit"
    Color => "Color"
    String => "String"
    Url => "Url"
    Function => "Function"
    Important => "Important"
    BraceOpen => "BraceOpen"
    BraceClose => "BraceClose"
    ParenOpen => "ParenOpen"
    ParenClose => "ParenClose"
    BracketOpen => "BracketOpen"
    BracketClose => "BracketClose"
    Colon => "Colon"
    Semicolon => "Semicolon"
    Comma => "Comma"
    Comment => "Comment"
    Error => "Error"
  }
}

///|
/// Highlight CSS source code
pub fn highlight_css(source : String) -> Array[@lezer.HighlightToken] {
  let tokenizer = CssTokenizer::new(source)
  let tokens = tokenizer.tokenize_all()
  let highlighter = css_highlighter()
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
/// Convenience: highlight CSS and generate simple HTML output
pub fn highlight_css_to_html(source : String) -> String {
  let tokens = highlight_css(source)
  @lezer.tokens_to_html(source, tokens)
}

///| MoonBit syntax highlighting

// =============================================================================
// MoonBit Highlighter
// =============================================================================

///|
/// Create a highlighter configured for MoonBit
pub fn mbt_highlighter() -> @lezer.Highlighter {
  let h = @lezer.Highlighter::new()

  // Keywords
  h.add_rule("Keyword", Keyword)

  // Literals
  h.add_rule("String", String)
  h.add_rule("Char", String)
  h.add_rule("Byte", String)
  h.add_rule("ByteString", String)
  h.add_rule("RawString", String)
  h.add_rule("Number", Number)
  h.add_rule("True", Bool)
  h.add_rule("False", Bool)

  // Names
  h.add_rule("Identifier", VariableName)
  h.add_rule("TypeName", TypeName)
  h.add_rule("Label", PropertyName)

  // Operators
  h.add_rule("Operator", Operator)
  h.add_rule("Arrow", Operator)
  h.add_rule("Range", Operator)
  h.add_rule("Pipe", Operator)
  h.add_rule("Question", Operator)

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
  h.add_rule("DoubleColon", Punctuation)
  h.add_rule("At", Meta)
  h.add_rule("Tilde", Operator)
  h.add_rule("Underscore", Keyword)

  // Comments
  h.add_rule("LineComment", Comment)
  h.add_rule("DocComment", DocComment)

  h
}

///|
/// Convert token type to string for highlighter lookup
fn token_type_name(t : MbtTokenType) -> String {
  match t {
    Keyword => "Keyword"
    String => "String"
    Char => "Char"
    Byte => "Byte"
    ByteString => "ByteString"
    RawString => "RawString"
    Number => "Number"
    True => "True"
    False => "False"
    Identifier => "Identifier"
    TypeName => "TypeName"
    Label => "Label"
    Operator => "Operator"
    Arrow => "Arrow"
    Range => "Range"
    Pipe => "Pipe"
    Question => "Question"
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
    DoubleColon => "DoubleColon"
    At => "At"
    Tilde => "Tilde"
    Underscore => "Underscore"
    LineComment => "LineComment"
    DocComment => "DocComment"
    Error => "Error"
  }
}

///|
/// Highlight MoonBit source code
pub fn highlight_moonbit(source : String) -> Array[@lezer.HighlightToken] {
  let tokenizer = MbtTokenizer::new(source)
  let tokens = tokenizer.tokenize_all()
  let highlighter = mbt_highlighter()
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
/// Convenience: highlight MoonBit and generate HTML
pub fn highlight_moonbit_to_html(source : String) -> String {
  let tokens = highlight_moonbit(source)
  @lezer.tokens_to_html(source, tokens)
}

///| Bash syntax highlighting

// =============================================================================
// Bash Highlighter
// =============================================================================

///|
/// Create a highlighter configured for Bash
pub fn bash_highlighter() -> @lezer.Highlighter {
  let h = @lezer.Highlighter::new()

  // Keywords
  h.add_rule("Keyword", Keyword)

  // Commands
  h.add_rule("Command", FunctionName)
  h.add_rule("Argument", VariableName)
  h.add_rule("Option", PropertyName)

  // Variables
  h.add_rule("Variable", VariableName)
  h.add_rule("SpecialVar", VariableName)

  // Strings
  h.add_rule("DoubleString", String)
  h.add_rule("SingleString", String)
  h.add_rule("RawString", String)
  h.add_rule("HereDoc", String)

  // Operators
  h.add_rule("Pipe", Operator)
  h.add_rule("PipeAnd", Operator)
  h.add_rule("And", Operator)
  h.add_rule("Or", Operator)
  h.add_rule("Redirect", Operator)
  h.add_rule("Background", Operator)
  h.add_rule("Semicolon", Punctuation)
  h.add_rule("DoubleSemicolon", Punctuation)

  // Substitution
  h.add_rule("CommandSub", String)
  h.add_rule("ProcessSub", String)
  h.add_rule("ArithmeticExp", Number)

  // Brackets
  h.add_rule("ParenOpen", Paren)
  h.add_rule("ParenClose", Paren)
  h.add_rule("BraceOpen", Brace)
  h.add_rule("BraceClose", Brace)
  h.add_rule("BracketOpen", Bracket)
  h.add_rule("BracketClose", Bracket)
  h.add_rule("DoubleBracket", Bracket)

  // Special
  h.add_rule("Comment", Comment)
  h.add_rule("Shebang", Meta)
  h.add_rule("Glob", Operator)
  h.add_rule("Equals", Operator)
  h.add_rule("Number", Number)
  h
}

///|
/// Convert token type to string for highlighter lookup
fn token_type_name(t : BashTokenType) -> String {
  match t {
    Keyword => "Keyword"
    Command => "Command"
    Argument => "Argument"
    Option => "Option"
    Variable => "Variable"
    SpecialVar => "SpecialVar"
    DoubleString => "DoubleString"
    SingleString => "SingleString"
    RawString => "RawString"
    HereDoc => "HereDoc"
    Pipe => "Pipe"
    PipeAnd => "PipeAnd"
    And => "And"
    Or => "Or"
    Redirect => "Redirect"
    Background => "Background"
    Semicolon => "Semicolon"
    DoubleSemicolon => "DoubleSemicolon"
    CommandSub => "CommandSub"
    ProcessSub => "ProcessSub"
    ArithmeticExp => "ArithmeticExp"
    ParenOpen => "ParenOpen"
    ParenClose => "ParenClose"
    BraceOpen => "BraceOpen"
    BraceClose => "BraceClose"
    BracketOpen => "BracketOpen"
    BracketClose => "BracketClose"
    DoubleBracket => "DoubleBracket"
    Comment => "Comment"
    Shebang => "Shebang"
    Glob => "Glob"
    Equals => "Equals"
    Number => "Number"
    Error => "Error"
  }
}

///|
/// Highlight Bash source code
pub fn highlight_bash(source : String) -> Array[@lezer.HighlightToken] {
  let tokenizer = BashTokenizer::new(source)
  let tokens = tokenizer.tokenize_all()
  let highlighter = bash_highlighter()
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
/// Convenience: highlight Bash and generate simple HTML output
pub fn highlight_bash_to_html(source : String) -> String {
  let tokens = highlight_bash(source)
  @lezer.tokens_to_html(source, tokens)
}

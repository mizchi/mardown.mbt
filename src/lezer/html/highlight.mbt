///| HTML syntax highlighting

// =============================================================================
// HTML Highlighter
// =============================================================================

///|
/// Create a highlighter configured for HTML
pub fn html_highlighter() -> @lezer.Highlighter {
  let h = @lezer.Highlighter::new()

  // Tags
  h.add_rule("TagOpen", TagBracket)
  h.add_rule("TagClose", TagBracket)
  h.add_rule("TagSlashClose", TagBracket)
  h.add_rule("TagOpenEnd", TagBracket)
  h.add_rule("TagName", TagName)

  // Attributes
  h.add_rule("AttrName", PropertyName)
  h.add_rule("AttrEquals", Punctuation)
  h.add_rule("AttrValue", String)

  // Special
  h.add_rule("Comment", Comment)
  h.add_rule("Doctype", Meta)
  h.add_rule("CData", String)
  h
}

///|
/// Convert token type to string for highlighter lookup
fn token_type_name(t : HtmlTokenType) -> String {
  match t {
    TagOpen => "TagOpen"
    TagClose => "TagClose"
    TagSlashClose => "TagSlashClose"
    TagOpenEnd => "TagOpenEnd"
    TagName => "TagName"
    AttrName => "AttrName"
    AttrEquals => "AttrEquals"
    AttrValue => "AttrValue"
    Text => "Text"
    Comment => "Comment"
    Doctype => "Doctype"
    CData => "CData"
    Error => "Error"
  }
}

///|
/// Highlight HTML source code
pub fn highlight_html(source : String) -> Array[@lezer.HighlightToken] {
  let tokenizer = HtmlTokenizer::new(source)
  let tokens = tokenizer.tokenize_all()
  let highlighter = html_highlighter()
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
/// Convenience: highlight HTML and generate simple HTML output
pub fn highlight_html_to_html(source : String) -> String {
  let tokens = highlight_html(source)
  @lezer.tokens_to_html(source, tokens)
}

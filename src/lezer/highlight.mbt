///| Syntax Highlighting support for Lezer-style trees

///|

///| Provides highlight token generation from parsed syntax trees.

// =============================================================================
// Highlight Tags (inspired by Lezer's @lezer/highlight)
// =============================================================================

///|
/// Standard highlight tags for syntax highlighting
pub(all) enum HighlightTag {
  // Keywords & Operators
  Keyword
  Operator
  Punctuation
  // Literals
  String
  Number
  Regexp // Regular expression literals
  Bool
  Null
  // Names
  PropertyName
  VariableName
  FunctionName
  TypeName
  ClassName
  PrivateName // #privateField
  // Meta
  Meta // @decorator
  // Structure
  Bracket
  Brace
  Paren
  // Comments & Documentation
  Comment
  DocComment
  // JSX/XML
  TagName // JSX/HTML tag name: div, span, MyComponent
  TagBracket // JSX/XML delimiters: < > /> </
  // Errors
  Invalid
  // No highlighting
  None
} derive(Eq, Show)

///|
/// Convert HighlightTag to CSS class name
pub fn HighlightTag::to_class(self : HighlightTag) -> String {
  match self {
    Keyword => "hl-keyword"
    Operator => "hl-operator"
    Punctuation => "hl-punctuation"
    String => "hl-string"
    Number => "hl-number"
    Regexp => "hl-regexp"
    Bool => "hl-bool"
    Null => "hl-null"
    PropertyName => "hl-property"
    VariableName => "hl-variable"
    FunctionName => "hl-function"
    TypeName => "hl-type"
    ClassName => "hl-class"
    PrivateName => "hl-private"
    Meta => "hl-meta"
    Bracket => "hl-bracket"
    Brace => "hl-brace"
    Paren => "hl-paren"
    Comment => "hl-comment"
    DocComment => "hl-doc-comment"
    TagName => "hl-tag"
    TagBracket => "hl-tag-bracket"
    Invalid => "hl-invalid"
    None => ""
  }
}

// =============================================================================
// Highlight Token
// =============================================================================

///|
/// A highlighted span of text
pub(all) struct HighlightToken {
  from : Int
  to : Int
  tag : HighlightTag
} derive(Eq, Show)

///|
/// Create a highlight token
pub fn HighlightToken::new(
  from : Int,
  to : Int,
  tag : HighlightTag,
) -> HighlightToken {
  { from, to, tag }
}

// =============================================================================
// Highlighter
// =============================================================================

///|
/// Highlighter configuration - maps node types to highlight tags
pub(all) struct Highlighter {
  /// Map from node type name to highlight tag
  rules : Map[String, HighlightTag]
}

///|
/// Create a new highlighter
pub fn Highlighter::new() -> Highlighter {
  { rules: {} }
}

///|
/// Add a highlighting rule
pub fn Highlighter::add_rule(
  self : Highlighter,
  node_name : String,
  tag : HighlightTag,
) -> Unit {
  self.rules[node_name] = tag
}

///|
/// Get highlight tag for a node type
pub fn Highlighter::get_tag(
  self : Highlighter,
  node_name : String,
) -> HighlightTag {
  match self.rules.get(node_name) {
    Some(tag) => tag
    _ => HighlightTag::None
  }
}

///|
/// Generate highlight tokens from a tree
pub fn Highlighter::highlight(
  self : Highlighter,
  tree : Tree,
) -> Array[HighlightToken] {
  let tokens : Array[HighlightToken] = []
  for node in tree.iter() {
    match node.node_type() {
      Some(nt) => {
        let tag = self.get_tag(nt.name)
        // Only add tokens for leaf nodes with a highlight tag
        match (tag, node) {
          (HighlightTag::None, _) => ()
          (_, Leaf(..)) =>
            tokens.push(HighlightToken::new(node.from(), node.to(), tag))
          (_, _) => ()
        }
      }
      _ => ()
    }
  }
  tokens
}

// =============================================================================
// HTML Generation
// =============================================================================

///|
/// Escape HTML special characters
pub fn escape_html(s : String) -> String {
  let result = StringBuilder::new()
  escape_html_to(s, result)
  result.to_string()
}

///|
/// Escape HTML special characters directly to StringBuilder (zero-alloc)
fn escape_html_to(s : String, buf : StringBuilder) -> Unit {
  for c in s {
    match c {
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '&' => buf.write_string("&amp;")
      '"' => buf.write_string("&quot;")
      _ => buf.write_char(c)
    }
  }
}

///|
/// Escape HTML from char slice directly to StringBuilder (zero-alloc)
pub fn escape_html_slice_to(
  chars : Array[Char],
  from : Int,
  to : Int,
  buf : StringBuilder,
) -> Unit {
  for i = from; i < to; i = i + 1 {
    match chars[i] {
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '&' => buf.write_string("&amp;")
      '"' => buf.write_string("&quot;")
      c => buf.write_char(c)
    }
  }
}

///|
/// Generate highlighted HTML from source and tokens
/// Note: tokens are assumed to be already sorted by position (as produced by tokenizers)
pub fn tokens_to_html(
  source : String,
  tokens : Array[HighlightToken],
) -> String {
  let result = StringBuilder::new()
  let chars = source.to_array()
  let len = chars.length()
  let mut pos = 0

  // Tokens are already sorted by position from tokenizers, no need to copy/sort
  for token in tokens {
    // Add unhighlighted text before this token
    if token.from > pos {
      escape_html_slice_to(chars, pos, token.from, result)
    }

    // Add highlighted token
    let class_name = token.tag.to_class()
    if class_name != "" {
      result.write_string("<span class=\"")
      result.write_string(class_name)
      result.write_string("\">")
      escape_html_slice_to(chars, token.from, token.to, result)
      result.write_string("</span>")
    } else {
      escape_html_slice_to(chars, token.from, token.to, result)
    }
    pos = token.to
  }

  // Add remaining text
  if pos < len {
    escape_html_slice_to(chars, pos, len, result)
  }
  result.to_string()
}

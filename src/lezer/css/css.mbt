///| CSS Tokenizer for syntax highlighting

// =============================================================================
// CSS Token Types
// =============================================================================

///|
/// CSS token types
pub(all) enum CssTokenType {
  // Selectors
  TagSelector // div, span, body
  ClassSelector // .classname
  IdSelector // #idname
  PseudoClass // :hover, :first-child
  PseudoElement // ::before, ::after
  AttrSelector // [attr], [attr="value"]
  UniversalSelector // *
  Combinator // >, +, ~, space

  // At-rules
  AtKeyword // @media, @keyframes, @import

  // Properties and values
  PropertyName // color, background-color
  PropertyValue // red, 10px, #fff
  Number // 10, 3.14
  Unit // px, em, %, rem
  Color // #fff, #ffffff
  String // "string" or 'string'
  Url // url(...)
  Function // rgb(), calc()
  Important // !important

  // Punctuation
  BraceOpen // {
  BraceClose // }
  ParenOpen // (
  ParenClose // )
  BracketOpen // [
  BracketClose // ]
  Colon // :
  Semicolon // ;
  Comma // ,

  // Comments
  Comment // /* ... */

  // Error
  Error
} derive(Eq, Show)

// =============================================================================
// CSS Token
// =============================================================================

///|
/// A token produced by the CSS tokenizer
pub(all) struct CssToken {
  token_type : CssTokenType
  from : Int
  to : Int
} derive(Eq, Show)

// =============================================================================
// CSS Tokenizer
// =============================================================================

///|
/// CSS Tokenizer state
pub(all) struct CssTokenizer {
  input : String
  priv chars : Array[Char]
  priv len : Int
  priv mut pos : Int
  // Track context: are we in a selector or declaration block?
  priv mut in_block : Bool
  priv mut after_colon : Bool
}

///|
/// Create a new CSS tokenizer
pub fn CssTokenizer::new(input : String) -> CssTokenizer {
  let chars = input.to_array()
  {
    input,
    chars,
    len: chars.length(),
    pos: 0,
    in_block: false,
    after_colon: false,
  }
}

///|
/// Check if at end of input
pub fn CssTokenizer::at_end(self : CssTokenizer) -> Bool {
  self.pos >= self.len
}

///|
/// Peek current character
fn CssTokenizer::_peek(self : CssTokenizer) -> Char? {
  if self.pos < self.len {
    Some(self.chars[self.pos])
  } else {
    None
  }
}

///|
/// Peek character at offset
fn CssTokenizer::peek_at(self : CssTokenizer, offset : Int) -> Char? {
  let idx = self.pos + offset
  if idx >= 0 && idx < self.len {
    Some(self.chars[idx])
  } else {
    None
  }
}

///|
/// Check if character is whitespace
fn is_whitespace(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

///|
/// Check if character is valid for identifiers
fn is_ident_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '-' ||
  c == '_'
}

///|
/// Check if character starts an identifier
fn is_ident_start(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' || c == '-'
}

///|
/// Check if character is a digit
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
/// Check if character is hex digit
fn is_hex_digit(c : Char) -> Bool {
  (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

///|
/// Skip whitespace
fn CssTokenizer::skip_whitespace(self : CssTokenizer) -> Unit {
  while self.pos < self.len && is_whitespace(self.chars[self.pos]) {
    self.pos += 1
  }
}

///|
/// Read a comment: /* ... */
fn CssTokenizer::read_comment(self : CssTokenizer) -> CssToken {
  let start = self.pos
  self.pos += 2 // skip /*
  while self.pos + 1 < self.len {
    if self.chars[self.pos] == '*' && self.chars[self.pos + 1] == '/' {
      self.pos += 2
      break
    }
    self.pos += 1
  }
  { token_type: Comment, from: start, to: self.pos }
}

///|
/// Read an identifier
fn CssTokenizer::read_ident(self : CssTokenizer) -> (Int, Int) {
  let start = self.pos
  while self.pos < self.len && is_ident_char(self.chars[self.pos]) {
    self.pos += 1
  }
  (start, self.pos)
}

///|
/// Read a string (single or double quoted)
fn CssTokenizer::read_string(self : CssTokenizer) -> CssToken {
  let start = self.pos
  let quote = self.chars[self.pos]
  self.pos += 1
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == quote {
      self.pos += 1
      break
    } else if c == '\\' && self.pos + 1 < self.len {
      self.pos += 2 // skip escape
    } else {
      self.pos += 1
    }
  }
  { token_type: String, from: start, to: self.pos }
}

///|
/// Read a number (including decimals)
fn CssTokenizer::read_number(self : CssTokenizer) -> CssToken {
  let start = self.pos

  // Integer part
  while self.pos < self.len && is_digit(self.chars[self.pos]) {
    self.pos += 1
  }

  // Decimal part
  if self.pos < self.len && self.chars[self.pos] == '.' {
    if self.pos + 1 < self.len && is_digit(self.chars[self.pos + 1]) {
      self.pos += 1
      while self.pos < self.len && is_digit(self.chars[self.pos]) {
        self.pos += 1
      }
    }
  }
  { token_type: Number, from: start, to: self.pos }
}

///|
/// Read a hex color: #fff or #ffffff
fn CssTokenizer::read_color(self : CssTokenizer) -> CssToken {
  let start = self.pos
  self.pos += 1 // skip #
  while self.pos < self.len && is_hex_digit(self.chars[self.pos]) {
    self.pos += 1
  }
  { token_type: Color, from: start, to: self.pos }
}

///|
/// Read a unit: px, em, %, rem, etc.
fn CssTokenizer::read_unit(self : CssTokenizer) -> CssToken {
  let start = self.pos

  // % is a single-char unit
  if self.pos < self.len && self.chars[self.pos] == '%' {
    self.pos += 1
    return { token_type: Unit, from: start, to: self.pos }
  }

  // Read identifier-like unit
  while self.pos < self.len && is_ident_char(self.chars[self.pos]) {
    self.pos += 1
  }
  { token_type: Unit, from: start, to: self.pos }
}

///|
/// Read url(...)
fn CssTokenizer::read_url(self : CssTokenizer) -> CssToken {
  let start = self.pos
  self.pos += 4 // skip "url("

  // Skip whitespace
  while self.pos < self.len && is_whitespace(self.chars[self.pos]) {
    self.pos += 1
  }

  // Read content (quoted or unquoted)
  if self.pos < self.len {
    let c = self.chars[self.pos]
    if c == '"' || c == '\'' {
      // Quoted URL
      let quote = c
      self.pos += 1
      while self.pos < self.len && self.chars[self.pos] != quote {
        if self.chars[self.pos] == '\\' && self.pos + 1 < self.len {
          self.pos += 2
        } else {
          self.pos += 1
        }
      }
      if self.pos < self.len {
        self.pos += 1 // skip closing quote
      }
    } else {
      // Unquoted URL
      while self.pos < self.len {
        let c = self.chars[self.pos]
        if c == ')' || is_whitespace(c) {
          break
        }
        self.pos += 1
      }
    }
  }

  // Skip whitespace and closing paren
  while self.pos < self.len && is_whitespace(self.chars[self.pos]) {
    self.pos += 1
  }
  if self.pos < self.len && self.chars[self.pos] == ')' {
    self.pos += 1
  }
  { token_type: Url, from: start, to: self.pos }
}

///|
/// Check if we're looking at "url("
fn CssTokenizer::is_url(self : CssTokenizer) -> Bool {
  if self.pos + 4 > self.len {
    return false
  }
  self.chars[self.pos] == 'u' &&
  self.chars[self.pos + 1] == 'r' &&
  self.chars[self.pos + 2] == 'l' &&
  self.chars[self.pos + 3] == '('
}

///|
/// Tokenize the entire input
pub fn CssTokenizer::tokenize_all(self : CssTokenizer) -> Array[CssToken] {
  let tokens : Array[CssToken] = []
  while self.pos < self.len {
    self.skip_whitespace()
    if self.pos >= self.len {
      break
    }
    let c = self.chars[self.pos]

    // Comment
    if c == '/' && self.peek_at(1) == Some('*') {
      tokens.push(self.read_comment())
      continue
    }

    // Punctuation
    match c {
      '{' => {
        let start = self.pos
        self.pos += 1
        tokens.push({ token_type: BraceOpen, from: start, to: self.pos })
        self.in_block = true
        self.after_colon = false
        continue
      }
      '}' => {
        let start = self.pos
        self.pos += 1
        tokens.push({ token_type: BraceClose, from: start, to: self.pos })
        self.in_block = false
        self.after_colon = false
        continue
      }
      '(' => {
        let start = self.pos
        self.pos += 1
        tokens.push({ token_type: ParenOpen, from: start, to: self.pos })
        continue
      }
      ')' => {
        let start = self.pos
        self.pos += 1
        tokens.push({ token_type: ParenClose, from: start, to: self.pos })
        continue
      }
      '[' => {
        let start = self.pos
        self.pos += 1
        tokens.push({ token_type: BracketOpen, from: start, to: self.pos })
        continue
      }
      ']' => {
        let start = self.pos
        self.pos += 1
        tokens.push({ token_type: BracketClose, from: start, to: self.pos })
        continue
      }
      ':' => {
        // Check for :: (pseudo-element)
        if self.peek_at(1) == Some(':') {
          let start = self.pos
          self.pos += 2
          // Read pseudo-element name
          if self.pos < self.len && is_ident_start(self.chars[self.pos]) {
            let (_, end) = self.read_ident()
            tokens.push({ token_type: PseudoElement, from: start, to: end })
          } else {
            tokens.push({ token_type: PseudoElement, from: start, to: self.pos })
          }
        } else if self.in_block && not(self.after_colon) {
          // Property-value separator
          let start = self.pos
          self.pos += 1
          tokens.push({ token_type: Colon, from: start, to: self.pos })
          self.after_colon = true
        } else {
          // Pseudo-class
          let start = self.pos
          self.pos += 1
          if self.pos < self.len && is_ident_start(self.chars[self.pos]) {
            let (_, end) = self.read_ident()
            tokens.push({ token_type: PseudoClass, from: start, to: end })
          } else {
            tokens.push({ token_type: Colon, from: start, to: self.pos })
          }
        }
        continue
      }
      ';' => {
        let start = self.pos
        self.pos += 1
        tokens.push({ token_type: Semicolon, from: start, to: self.pos })
        self.after_colon = false
        continue
      }
      ',' => {
        let start = self.pos
        self.pos += 1
        tokens.push({ token_type: Comma, from: start, to: self.pos })
        continue
      }
      _ => ()
    }

    // Combinators
    if c == '>' || c == '+' || c == '~' {
      let start = self.pos
      self.pos += 1
      tokens.push({ token_type: Combinator, from: start, to: self.pos })
      continue
    }

    // At-keyword
    if c == '@' {
      let start = self.pos
      self.pos += 1
      if self.pos < self.len && is_ident_start(self.chars[self.pos]) {
        let (_, end) = self.read_ident()
        tokens.push({ token_type: AtKeyword, from: start, to: end })
      } else {
        tokens.push({ token_type: AtKeyword, from: start, to: self.pos })
      }
      continue
    }

    // Class selector
    if c == '.' && not(self.after_colon) {
      let start = self.pos
      self.pos += 1
      if self.pos < self.len && is_ident_start(self.chars[self.pos]) {
        let (_, end) = self.read_ident()
        tokens.push({ token_type: ClassSelector, from: start, to: end })
      }
      continue
    }

    // ID selector or color
    if c == '#' {
      let start = self.pos
      self.pos += 1
      if self.pos < self.len {
        if self.after_colon && is_hex_digit(self.chars[self.pos]) {
          // Color in value context
          self.pos = start
          tokens.push(self.read_color())
        } else if is_ident_start(self.chars[self.pos]) {
          // ID selector
          let (_, end) = self.read_ident()
          tokens.push({ token_type: IdSelector, from: start, to: end })
        } else if is_hex_digit(self.chars[self.pos]) {
          // Color
          self.pos = start
          tokens.push(self.read_color())
        }
      }
      continue
    }

    // Universal selector
    if c == '*' {
      let start = self.pos
      self.pos += 1
      tokens.push({ token_type: UniversalSelector, from: start, to: self.pos })
      continue
    }

    // String
    if c == '"' || c == '\'' {
      tokens.push(self.read_string())
      continue
    }

    // Number
    if is_digit(c) ||
      (c == '.' && self.peek_at(1).map(is_digit).unwrap_or(false)) {
      tokens.push(self.read_number())
      // Check for unit
      if self.pos < self.len {
        let next = self.chars[self.pos]
        if next == '%' || is_ident_start(next) {
          tokens.push(self.read_unit())
        }
      }
      continue
    }

    // !important
    if c == '!' {
      let start = self.pos
      self.pos += 1
      self.skip_whitespace()
      // Check for "important"
      if self.pos + 9 <= self.len {
        let word_start = self.pos
        let (_, word_end) = self.read_ident()
        // Simple check
        if word_end - word_start == 9 {
          tokens.push({ token_type: Important, from: start, to: word_end })
        } else {
          tokens.push({ token_type: Error, from: start, to: word_end })
        }
      }
      continue
    }

    // Identifier (property name, tag selector, or value)
    if is_ident_start(c) {
      // Check for url(
      if self.is_url() {
        tokens.push(self.read_url())
        continue
      }
      let (start, end) = self.read_ident()

      // Check if followed by ( for function
      if self.pos < self.len && self.chars[self.pos] == '(' {
        tokens.push({ token_type: Function, from: start, to: end })
        continue
      }
      if self.in_block {
        if self.after_colon {
          tokens.push({ token_type: PropertyValue, from: start, to: end })
        } else {
          tokens.push({ token_type: PropertyName, from: start, to: end })
        }
      } else {
        tokens.push({ token_type: TagSelector, from: start, to: end })
      }
      continue
    }

    // Unknown character
    let start = self.pos
    self.pos += 1
    tokens.push({ token_type: Error, from: start, to: self.pos })
  }
  tokens
}

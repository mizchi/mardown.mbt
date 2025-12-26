///| HTML Tokenizer for syntax highlighting

// =============================================================================
// HTML Token Types
// =============================================================================

///|
/// HTML token types
pub(all) enum HtmlTokenType {
  // Tags
  TagOpen // <
  TagClose // >
  TagSlashClose // />
  TagOpenEnd // </
  TagName // div, span, etc.

  // Attributes
  AttrName // class, id, etc.
  AttrEquals // =
  AttrValue // "value" or 'value'

  // Content
  Text // Text content between tags

  // Special
  Comment // <!-- ... -->
  Doctype // <!DOCTYPE ...>
  CData // <![CDATA[ ... ]]>

  // Error
  Error
} derive(Eq, Show)

// =============================================================================
// HTML Token
// =============================================================================

///|
/// A token produced by the HTML tokenizer
pub(all) struct HtmlToken {
  token_type : HtmlTokenType
  from : Int
  to : Int
} derive(Eq, Show)

// =============================================================================
// HTML Tokenizer
// =============================================================================

///|
/// HTML Tokenizer state
pub(all) struct HtmlTokenizer {
  input : String
  priv chars : Array[Char]
  priv len : Int
  priv mut pos : Int
}

///|
/// Create a new HTML tokenizer
pub fn HtmlTokenizer::new(input : String) -> HtmlTokenizer {
  let chars = input.to_array()
  { input, chars, len: chars.length(), pos: 0 }
}

///|
/// Check if at end of input
pub fn HtmlTokenizer::at_end(self : HtmlTokenizer) -> Bool {
  self.pos >= self.len
}

///|
/// Peek current character
fn HtmlTokenizer::_peek(self : HtmlTokenizer) -> Char? {
  if self.pos < self.len {
    Some(self.chars[self.pos])
  } else {
    None
  }
}

///|
/// Peek character at offset
fn HtmlTokenizer::peek_at(self : HtmlTokenizer, offset : Int) -> Char? {
  let idx = self.pos + offset
  if idx >= 0 && idx < self.len {
    Some(self.chars[idx])
  } else {
    None
  }
}

///|
/// Advance position
fn HtmlTokenizer::_advance(self : HtmlTokenizer) -> Unit {
  self.pos += 1
}

///|
/// Check if character is valid for tag/attribute names
fn is_name_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '-' ||
  c == '_' ||
  c == ':' ||
  c == '.'
}

///|
/// Check if character is whitespace
fn is_whitespace(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

///|
/// Skip whitespace
fn HtmlTokenizer::skip_whitespace(self : HtmlTokenizer) -> Unit {
  while self.pos < self.len && is_whitespace(self.chars[self.pos]) {
    self.pos += 1
  }
}

///|
/// Check if string matches at current position
fn HtmlTokenizer::matches(self : HtmlTokenizer, s : String) -> Bool {
  let s_chars = s.to_array()
  let s_len = s_chars.length()
  if self.pos + s_len > self.len {
    return false
  }
  for i = 0; i < s_len; i = i + 1 {
    if self.chars[self.pos + i] != s_chars[i] {
      return false
    }
  }
  true
}

///|
/// Check if string matches case-insensitively at current position
fn HtmlTokenizer::matches_ignore_case(self : HtmlTokenizer, s : String) -> Bool {
  let s_chars = s.to_array()
  let s_len = s_chars.length()
  if self.pos + s_len > self.len {
    return false
  }
  for i = 0; i < s_len; i = i + 1 {
    let c1 = self.chars[self.pos + i]
    let c2 = s_chars[i]
    let c1_lower = if c1 >= 'A' && c1 <= 'Z' {
      (c1.to_int() + 32).unsafe_to_char()
    } else {
      c1
    }
    let c2_lower = if c2 >= 'A' && c2 <= 'Z' {
      (c2.to_int() + 32).unsafe_to_char()
    } else {
      c2
    }
    if c1_lower != c2_lower {
      return false
    }
  }
  true
}

///|
/// Read a comment: <!-- ... -->
fn HtmlTokenizer::read_comment(self : HtmlTokenizer) -> HtmlToken {
  let start = self.pos
  // Skip <!--
  self.pos += 4

  // Find -->
  while self.pos < self.len {
    if self.matches("-->") {
      self.pos += 3
      break
    }
    self.pos += 1
  }
  { token_type: Comment, from: start, to: self.pos }
}

///|
/// Read a DOCTYPE: <!DOCTYPE ...>
fn HtmlTokenizer::read_doctype(self : HtmlTokenizer) -> HtmlToken {
  let start = self.pos
  // Skip <!DOCTYPE
  self.pos += 9

  // Find >
  while self.pos < self.len && self.chars[self.pos] != '>' {
    self.pos += 1
  }
  if self.pos < self.len {
    self.pos += 1 // skip >
  }
  { token_type: Doctype, from: start, to: self.pos }
}

///|
/// Read a CDATA section: <![CDATA[ ... ]]>
fn HtmlTokenizer::read_cdata(self : HtmlTokenizer) -> HtmlToken {
  let start = self.pos
  // Skip <![CDATA[
  self.pos += 9

  // Find ]]>
  while self.pos < self.len {
    if self.matches("]]>") {
      self.pos += 3
      break
    }
    self.pos += 1
  }
  { token_type: CData, from: start, to: self.pos }
}

///|
/// Read a tag name
fn HtmlTokenizer::read_tag_name(self : HtmlTokenizer) -> HtmlToken {
  let start = self.pos
  while self.pos < self.len && is_name_char(self.chars[self.pos]) {
    self.pos += 1
  }
  { token_type: TagName, from: start, to: self.pos }
}

///|
/// Read an attribute name
fn HtmlTokenizer::read_attr_name(self : HtmlTokenizer) -> HtmlToken {
  let start = self.pos
  while self.pos < self.len && is_name_char(self.chars[self.pos]) {
    self.pos += 1
  }
  { token_type: AttrName, from: start, to: self.pos }
}

///|
/// Read an attribute value (quoted or unquoted)
fn HtmlTokenizer::read_attr_value(self : HtmlTokenizer) -> HtmlToken {
  let start = self.pos
  if self.pos < self.len {
    let quote = self.chars[self.pos]
    if quote == '"' || quote == '\'' {
      // Quoted value
      self.pos += 1
      while self.pos < self.len && self.chars[self.pos] != quote {
        self.pos += 1
      }
      if self.pos < self.len {
        self.pos += 1 // skip closing quote
      }
    } else {
      // Unquoted value (until whitespace or >)
      while self.pos < self.len {
        let c = self.chars[self.pos]
        if is_whitespace(c) || c == '>' || c == '/' {
          break
        }
        self.pos += 1
      }
    }
  }
  { token_type: AttrValue, from: start, to: self.pos }
}

///|
/// Read text content until <
fn HtmlTokenizer::read_text(self : HtmlTokenizer) -> HtmlToken {
  let start = self.pos
  while self.pos < self.len && self.chars[self.pos] != '<' {
    self.pos += 1
  }
  { token_type: Text, from: start, to: self.pos }
}

///|
/// Tokenize the entire input
pub fn HtmlTokenizer::tokenize_all(self : HtmlTokenizer) -> Array[HtmlToken] {
  let tokens : Array[HtmlToken] = []
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == '<' {
      // Check for special constructs
      if self.matches("<!--") {
        tokens.push(self.read_comment())
      } else if self.matches_ignore_case("<!DOCTYPE") {
        tokens.push(self.read_doctype())
      } else if self.matches("<![CDATA[") {
        tokens.push(self.read_cdata())
      } else if self.peek_at(1) == Some('/') {
        // Closing tag: </
        let start = self.pos
        self.pos += 2
        tokens.push({ token_type: TagOpenEnd, from: start, to: self.pos })

        // Tag name
        self.skip_whitespace()
        if self.pos < self.len && is_name_char(self.chars[self.pos]) {
          tokens.push(self.read_tag_name())
        }

        // Skip to >
        self.skip_whitespace()
        if self.pos < self.len && self.chars[self.pos] == '>' {
          let start = self.pos
          self.pos += 1
          tokens.push({ token_type: TagClose, from: start, to: self.pos })
        }
      } else {
        // Opening tag: <
        let start = self.pos
        self.pos += 1
        tokens.push({ token_type: TagOpen, from: start, to: self.pos })

        // Tag name
        if self.pos < self.len && is_name_char(self.chars[self.pos]) {
          tokens.push(self.read_tag_name())
        }

        // Attributes
        while self.pos < self.len {
          self.skip_whitespace()
          if self.pos >= self.len {
            break
          }
          let c = self.chars[self.pos]
          if c == '>' {
            let start = self.pos
            self.pos += 1
            tokens.push({ token_type: TagClose, from: start, to: self.pos })
            break
          } else if c == '/' && self.peek_at(1) == Some('>') {
            let start = self.pos
            self.pos += 2
            tokens.push({ token_type: TagSlashClose, from: start, to: self.pos })
            break
          } else if is_name_char(c) {
            // Attribute name
            tokens.push(self.read_attr_name())
            self.skip_whitespace()

            // Check for =
            if self.pos < self.len && self.chars[self.pos] == '=' {
              let start = self.pos
              self.pos += 1
              tokens.push({ token_type: AttrEquals, from: start, to: self.pos })
              self.skip_whitespace()

              // Attribute value
              if self.pos < self.len {
                let c = self.chars[self.pos]
                if c != '>' && c != '/' {
                  tokens.push(self.read_attr_value())
                }
              }
            }
          } else {
            // Unknown character, skip
            self.pos += 1
          }
        }
      }
    } else {
      // Text content
      let token = self.read_text()
      if token.to > token.from {
        tokens.push(token)
      }
    }
  }
  tokens
}

///| MoonBit Tokenizer

///|

///| A tokenizer for MoonBit language for syntax highlighting.

// =============================================================================
// Token Types
// =============================================================================

///|
/// MoonBit token types
pub(all) enum MbtTokenType {
  // Keywords
  Keyword // fn, let, if, else, match, etc.
  // Literals
  String // "..." (no interpolation)
  StringHead // "...\{  (start of interpolated string)
  StringMiddle // }...\{  (middle part)
  StringTail // }..."   (end part)
  Char // 'x'
  Byte // b'x'
  ByteString // b"..."
  Number // 123, 0xFF, 0b101, 1.5e10
  True // true
  False // false
  // Names
  Identifier // variable names, function names
  TypeName // PascalCase type names
  Label // ~label
  // Operators
  Operator // +, -, *, /, =, ==, etc.
  Arrow // -> or =>
  Range // ..
  Pipe // |>
  Question // ?
  // Punctuation
  BraceOpen // {
  BraceClose // }
  BracketOpen // [
  BracketClose // ]
  ParenOpen // (
  ParenClose // )
  Semicolon // ;
  Comma // ,
  Dot // .
  Colon // :
  DoubleColon // ::
  At // @
  Tilde // ~
  Underscore // _ (wildcard)
  // Comments
  LineComment // // ...
  DocComment // ///| ...
  // Raw string
  RawString // #|... (no interpolation)
  InterpString // $|... (simple, no interpolation in this line)
  InterpStringHead // $|...\{ (start of interpolation)
  InterpStringMiddle // }...\{ (middle of interpolation)
  InterpStringTail // }...  (end of interpolation)
  // Error
  Error
} derive(Eq, Show)

// =============================================================================
// Keywords
// =============================================================================

///|
/// Check if a word is a MoonBit keyword
fn is_keyword(word : String) -> Bool {
  match word {
    // Control flow
    "if"
    | "else"
    | "match"
    | "while"
    | "loop"
    | "for"
    | "in"
    | "break"
    | "continue"
    | "return" => true
    // Declarations
    "fn"
    | "let"
    | "const"
    | "type"
    | "struct"
    | "enum"
    | "trait"
    | "impl"
    | "derive"
    | "test"
    | "init"
    | "extern" => true
    // Modifiers
    "pub" | "priv" | "mut" | "readonly" | "async" => true
    // Error handling
    "try" | "catch" | "throw" | "raise" | "guard" => true
    // Other keywords
    "as" | "is" | "with" | "import" | "and" | "or" | "not" => true
    // Type-related
    "typealias" | "traitalias" | "fnalias" | "using" => true
    // Special
    "defer" | "suberror" | "noraise" | "letrec" => true
    _ => false
  }
}

///|
/// Check if a word is a MoonBit built-in type
fn is_builtin_type(word : String) -> Bool {
  match word {
    // Primitive types
    "Int"
    | "Int64"
    | "UInt"
    | "UInt64"
    | "Double"
    | "Float"
    | "Bool"
    | "String"
    | "Char"
    | "Byte"
    | "Bytes"
    | "Unit" => true
    // Common types
    "Array" | "Map" | "Set" | "Option" | "Result" | "Iter" | "FixedArray" =>
      true
    // Special
    "Self" | "Error" => true
    _ => false
  }
}

// =============================================================================
// Token
// =============================================================================

///|
/// A token with position information
pub(all) struct MbtToken {
  token_type : MbtTokenType
  from : Int
  to : Int
} derive(Eq, Show)

// =============================================================================
// Context
// =============================================================================

///|
/// Parser context for string interpolation
enum MbtContext {
  Normal // Regular code
  StringInterp // Inside \{...} in "..." string
  InterpStringInterp // Inside \{...} in $|... string
} derive(Eq, Show)

// =============================================================================
// Tokenizer
// =============================================================================

///|
/// MoonBit tokenizer
pub(all) struct MbtTokenizer {
  input : String
  priv chars : Array[Char]
  priv len : Int
  priv mut pos : Int
  priv context_stack : Array[MbtContext]
}

///|
/// Create a new tokenizer
pub fn MbtTokenizer::new(input : String) -> MbtTokenizer {
  let chars = input.to_array()
  { input, chars, len: chars.length(), pos: 0, context_stack: [Normal] }
}

///|
/// Get current context
fn MbtTokenizer::context(self : MbtTokenizer) -> MbtContext {
  if self.context_stack.length() > 0 {
    self.context_stack[self.context_stack.length() - 1]
  } else {
    Normal
  }
}

///|
/// Push context
fn MbtTokenizer::push_context(self : MbtTokenizer, ctx : MbtContext) -> Unit {
  self.context_stack.push(ctx)
}

///|
/// Pop context
fn MbtTokenizer::pop_context(self : MbtTokenizer) -> Unit {
  if self.context_stack.length() > 1 {
    let _ = self.context_stack.pop()

  }
}

// =============================================================================
// Character Classification
// =============================================================================

///|
fn is_whitespace(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

///|
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn is_hex_digit(c : Char) -> Bool {
  (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

///|
fn is_ident_start(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

///|
fn is_ident_part(c : Char) -> Bool {
  is_ident_start(c) || is_digit(c)
}

///|
fn is_uppercase(c : Char) -> Bool {
  c >= 'A' && c <= 'Z'
}

// =============================================================================
// Tokenizer Methods
// =============================================================================

///|
/// Skip whitespace
fn MbtTokenizer::skip_whitespace(self : MbtTokenizer) -> Unit {
  while self.pos < self.len && is_whitespace(self.chars[self.pos]) {
    self.pos += 1
  }
}

///|
/// Read a string literal (with interpolation support)
fn MbtTokenizer::read_string(self : MbtTokenizer) -> MbtToken {
  let start = self.pos
  self.pos += 1 // Skip opening "
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == '"' {
      self.pos += 1
      return { token_type: String, from: start, to: self.pos }
    } else if c == '\\' && self.pos + 1 < self.len {
      let next = self.chars[self.pos + 1]
      if next == '{' {
        // String interpolation starts: "...\{
        self.pos += 2 // Skip \{
        self.push_context(StringInterp)
        return { token_type: StringHead, from: start, to: self.pos }
      } else {
        self.pos += 2 // Skip escape sequence
      }
    } else {
      self.pos += 1
    }
  }
  { token_type: String, from: start, to: self.pos }
}

///|
/// Continue reading string after interpolation (after })
fn MbtTokenizer::read_string_continuation(self : MbtTokenizer) -> MbtToken {
  let start = self.pos
  self.pos += 1 // Skip }
  self.pop_context()
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == '"' {
      self.pos += 1
      return { token_type: StringTail, from: start, to: self.pos }
    } else if c == '\\' && self.pos + 1 < self.len {
      let next = self.chars[self.pos + 1]
      if next == '{' {
        // Another interpolation: }...\{
        self.pos += 2
        self.push_context(StringInterp)
        return { token_type: StringMiddle, from: start, to: self.pos }
      } else {
        self.pos += 2
      }
    } else {
      self.pos += 1
    }
  }
  { token_type: StringTail, from: start, to: self.pos }
}

///|
/// Read a character literal
fn MbtTokenizer::read_char(self : MbtTokenizer) -> MbtToken {
  let start = self.pos
  self.pos += 1 // Skip '
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == '\'' {
      self.pos += 1
      break
    } else if c == '\\' && self.pos + 1 < self.len {
      self.pos += 2
    } else {
      self.pos += 1
    }
  }
  { token_type: Char, from: start, to: self.pos }
}

///|
/// Read a byte string (b"...")
fn MbtTokenizer::read_byte_string(self : MbtTokenizer) -> MbtToken {
  let start = self.pos
  self.pos += 1 // Skip 'b'
  self.pos += 1 // Skip '"'
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == '"' {
      self.pos += 1
      break
    } else if c == '\\' && self.pos + 1 < self.len {
      self.pos += 2
    } else {
      self.pos += 1
    }
  }
  { token_type: ByteString, from: start, to: self.pos }
}

///|
/// Read a byte literal (b'x')
fn MbtTokenizer::read_byte(self : MbtTokenizer) -> MbtToken {
  let start = self.pos
  self.pos += 1 // Skip 'b'
  self.pos += 1 // Skip '\''
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == '\'' {
      self.pos += 1
      break
    } else if c == '\\' && self.pos + 1 < self.len {
      self.pos += 2
    } else {
      self.pos += 1
    }
  }
  { token_type: Byte, from: start, to: self.pos }
}

///|
/// Read a number literal
fn MbtTokenizer::read_number(self : MbtTokenizer) -> MbtToken {
  let start = self.pos

  // Check for hex, binary, octal
  if self.pos < self.len && self.chars[self.pos] == '0' {
    if self.pos + 1 < self.len {
      let next = self.chars[self.pos + 1]
      if next == 'x' || next == 'X' {
        // Hexadecimal
        self.pos += 2
        while self.pos < self.len {
          let c = self.chars[self.pos]
          if is_hex_digit(c) || c == '_' {
            self.pos += 1
          } else {
            break
          }
        }
        return { token_type: Number, from: start, to: self.pos }
      } else if next == 'b' || next == 'B' {
        // Binary
        self.pos += 2
        while self.pos < self.len {
          let c = self.chars[self.pos]
          if c == '0' || c == '1' || c == '_' {
            self.pos += 1
          } else {
            break
          }
        }
        return { token_type: Number, from: start, to: self.pos }
      } else if next == 'o' || next == 'O' {
        // Octal
        self.pos += 2
        while self.pos < self.len {
          let c = self.chars[self.pos]
          if (c >= '0' && c <= '7') || c == '_' {
            self.pos += 1
          } else {
            break
          }
        }
        return { token_type: Number, from: start, to: self.pos }
      }
    }
  }

  // Integer part
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if is_digit(c) || c == '_' {
      self.pos += 1
    } else {
      break
    }
  }

  // Decimal part
  if self.pos < self.len && self.chars[self.pos] == '.' {
    if self.pos + 1 < self.len && is_digit(self.chars[self.pos + 1]) {
      self.pos += 1
      while self.pos < self.len {
        let c = self.chars[self.pos]
        if is_digit(c) || c == '_' {
          self.pos += 1
        } else {
          break
        }
      }
    }
  }

  // Exponent part
  if self.pos < self.len {
    let c = self.chars[self.pos]
    if c == 'e' || c == 'E' {
      self.pos += 1
      if self.pos < self.len {
        let sign = self.chars[self.pos]
        if sign == '+' || sign == '-' {
          self.pos += 1
        }
      }
      while self.pos < self.len {
        let c = self.chars[self.pos]
        if is_digit(c) || c == '_' {
          self.pos += 1
        } else {
          break
        }
      }
    }
  }

  // Type suffix (Int64, UInt64, etc.)
  if self.pos < self.len {
    let c = self.chars[self.pos]
    if c == 'L' || c == 'U' {
      self.pos += 1
      // UL or LU
      if self.pos < self.len {
        let c2 = self.chars[self.pos]
        if c2 == 'L' || c2 == 'U' {
          self.pos += 1
        }
      }
    }
  }
  { token_type: Number, from: start, to: self.pos }
}

///|
/// Read an identifier or keyword
fn MbtTokenizer::read_identifier(self : MbtTokenizer) -> MbtToken {
  let start = self.pos
  let first_char = self.chars[self.pos]
  while self.pos < self.len && is_ident_part(self.chars[self.pos]) {
    self.pos += 1
  }
  let word = self.input.unsafe_substring(start~, end=self.pos)
  let token_type = match word {
    "true" => True
    "false" => False
    "_" => Underscore
    _ if is_keyword(word) => Keyword
    _ if is_uppercase(first_char) && is_builtin_type(word) => TypeName
    _ if is_uppercase(first_char) => TypeName // PascalCase = type name
    _ => Identifier
  }
  { token_type, from: start, to: self.pos }
}

///|
/// Read a line comment
fn MbtTokenizer::read_line_comment(self : MbtTokenizer) -> MbtToken {
  let start = self.pos

  // Check for doc comment ///|
  if self.pos + 3 < self.len &&
    self.chars[self.pos + 2] == '/' &&
    self.chars[self.pos + 3] == '|' {
    self.pos += 4
    while self.pos < self.len && self.chars[self.pos] != '\n' {
      self.pos += 1
    }
    return { token_type: DocComment, from: start, to: self.pos }
  }

  // Regular line comment
  self.pos += 2
  while self.pos < self.len && self.chars[self.pos] != '\n' {
    self.pos += 1
  }
  { token_type: LineComment, from: start, to: self.pos }
}

///|
/// Read a raw string line (#|...)
fn MbtTokenizer::read_raw_string(self : MbtTokenizer) -> MbtToken {
  let start = self.pos
  self.pos += 2 // Skip #|
  while self.pos < self.len && self.chars[self.pos] != '\n' {
    self.pos += 1
  }
  { token_type: RawString, from: start, to: self.pos }
}

///|
/// Read an interpolated string line ($|... with \{} support)
fn MbtTokenizer::read_interp_string(self : MbtTokenizer) -> MbtToken {
  let start = self.pos
  self.pos += 2 // Skip $|
  while self.pos < self.len && self.chars[self.pos] != '\n' {
    let c = self.chars[self.pos]
    if c == '\\' && self.pos + 1 < self.len && self.chars[self.pos + 1] == '{' {
      // Found \{ - interpolation starts
      self.pos += 2 // Skip \{
      self.push_context(InterpStringInterp)
      return { token_type: InterpStringHead, from: start, to: self.pos }
    }
    self.pos += 1
  }
  { token_type: InterpString, from: start, to: self.pos }
}

///|
/// Continue reading interpolated string after } in $|... context
fn MbtTokenizer::read_interp_string_continuation(
  self : MbtTokenizer,
) -> MbtToken {
  let start = self.pos
  self.pos += 1 // Skip }
  self.pop_context()
  while self.pos < self.len && self.chars[self.pos] != '\n' {
    let c = self.chars[self.pos]
    if c == '\\' && self.pos + 1 < self.len && self.chars[self.pos + 1] == '{' {
      // Another interpolation
      self.pos += 2
      self.push_context(InterpStringInterp)
      return { token_type: InterpStringMiddle, from: start, to: self.pos }
    }
    self.pos += 1
  }
  { token_type: InterpStringTail, from: start, to: self.pos }
}

///|
/// Read an operator
fn MbtTokenizer::read_operator(self : MbtTokenizer) -> MbtToken {
  let start = self.pos
  let c = self.chars[self.pos]

  // Two-character operators
  if self.pos + 1 < self.len {
    let next = self.chars[self.pos + 1]
    match (c, next) {
      ('-', '>') | ('=', '>') => {
        self.pos += 2
        return { token_type: Arrow, from: start, to: self.pos }
      }
      ('.', '.') => {
        self.pos += 2
        return { token_type: Range, from: start, to: self.pos }
      }
      ('|', '>') => {
        self.pos += 2
        return { token_type: Pipe, from: start, to: self.pos }
      }
      (':', ':') => {
        self.pos += 2
        return { token_type: DoubleColon, from: start, to: self.pos }
      }
      ('=', '=')
      | ('!', '=')
      | ('<', '=')
      | ('>', '=')
      | ('&', '&')
      | ('|', '|')
      | ('<', '<')
      | ('>', '>')
      | ('+', '=')
      | ('-', '=')
      | ('*', '=')
      | ('/', '=') => {
        self.pos += 2
        return { token_type: Operator, from: start, to: self.pos }
      }
      _ => ()
    }
  }

  // Single-character operators
  self.pos += 1
  { token_type: Operator, from: start, to: self.pos }
}

///|
/// Read a label (~label)
fn MbtTokenizer::read_label(self : MbtTokenizer) -> MbtToken {
  let start = self.pos
  self.pos += 1 // Skip ~

  // Read the identifier part
  while self.pos < self.len && is_ident_part(self.chars[self.pos]) {
    self.pos += 1
  }
  { token_type: Label, from: start, to: self.pos }
}

///|
/// Get next token
pub fn MbtTokenizer::next_token(self : MbtTokenizer) -> MbtToken? {
  self.skip_whitespace()
  if self.pos >= self.len {
    return None
  }
  let start = self.pos
  let c = self.chars[self.pos]
  let token : MbtToken = match c {
    // String literal
    '"' => self.read_string()

    // Character literal or byte
    '\'' => self.read_char()

    // Byte string or identifier starting with 'b'
    'b' =>
      if self.pos + 1 < self.len {
        let next = self.chars[self.pos + 1]
        if next == '"' {
          self.read_byte_string()
        } else if next == '\'' {
          self.read_byte()
        } else {
          self.read_identifier()
        }
      } else {
        self.read_identifier()
      }

    // Comment or operator
    '/' =>
      if self.pos + 1 < self.len && self.chars[self.pos + 1] == '/' {
        self.read_line_comment()
      } else {
        self.read_operator()
      }

    // Raw string or operator
    '#' =>
      if self.pos + 1 < self.len && self.chars[self.pos + 1] == '|' {
        self.read_raw_string()
      } else {
        self.pos += 1
        { token_type: Operator, from: start, to: self.pos }
      }

    // Interpolated multiline string ($|...)
    '$' =>
      if self.pos + 1 < self.len && self.chars[self.pos + 1] == '|' {
        self.read_interp_string()
      } else {
        self.pos += 1
        { token_type: Operator, from: start, to: self.pos }
      }

    // Braces
    '{' => {
      self.pos += 1
      { token_type: BraceOpen, from: start, to: self.pos }
    }
    '}' => {
      // Check if we're inside string interpolation
      let ctx = self.context()
      if ctx == StringInterp {
        self.read_string_continuation()
      } else if ctx == InterpStringInterp {
        self.read_interp_string_continuation()
      } else {
        self.pos += 1
        { token_type: BraceClose, from: start, to: self.pos }
      }
    }
    '[' => {
      self.pos += 1
      { token_type: BracketOpen, from: start, to: self.pos }
    }
    ']' => {
      self.pos += 1
      { token_type: BracketClose, from: start, to: self.pos }
    }
    '(' => {
      self.pos += 1
      { token_type: ParenOpen, from: start, to: self.pos }
    }
    ')' => {
      self.pos += 1
      { token_type: ParenClose, from: start, to: self.pos }
    }

    // Punctuation
    ';' => {
      self.pos += 1
      { token_type: Semicolon, from: start, to: self.pos }
    }
    ',' => {
      self.pos += 1
      { token_type: Comma, from: start, to: self.pos }
    }
    ':' =>
      if self.pos + 1 < self.len && self.chars[self.pos + 1] == ':' {
        self.pos += 2
        { token_type: DoubleColon, from: start, to: self.pos }
      } else {
        self.pos += 1
        { token_type: Colon, from: start, to: self.pos }
      }
    '@' => {
      self.pos += 1
      { token_type: At, from: start, to: self.pos }
    }
    '?' => {
      self.pos += 1
      { token_type: Question, from: start, to: self.pos }
    }
    '~' =>
      // Label or tilde operator
      if self.pos + 1 < self.len && is_ident_start(self.chars[self.pos + 1]) {
        self.read_label()
      } else {
        self.pos += 1
        { token_type: Tilde, from: start, to: self.pos }
      }

    // Dot or range
    '.' =>
      if self.pos + 1 < self.len && self.chars[self.pos + 1] == '.' {
        self.pos += 2
        { token_type: Range, from: start, to: self.pos }
      } else if self.pos + 1 < self.len && is_digit(self.chars[self.pos + 1]) {
        self.read_number()
      } else {
        self.pos += 1
        { token_type: Dot, from: start, to: self.pos }
      }

    // Numbers
    '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' =>
      self.read_number()

    // Identifiers
    _ if is_ident_start(c) => self.read_identifier()

    // Operators
    '+' | '-' | '*' | '%' | '=' | '!' | '<' | '>' | '&' | '|' | '^' =>
      self.read_operator()

    // Error
    _ => {
      self.pos += 1
      { token_type: Error, from: start, to: self.pos }
    }
  }
  Some(token)
}

///|
/// Tokenize entire input
pub fn MbtTokenizer::tokenize_all(self : MbtTokenizer) -> Array[MbtToken] {
  let tokens : Array[MbtToken] = []
  while true {
    match self.next_token() {
      Some(token) => tokens.push(token)
      None => break
    }
  }
  tokens
}

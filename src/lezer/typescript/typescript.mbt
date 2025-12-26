///| TypeScript/JavaScript/TSX/JSX Tokenizer

///|

///| A tokenizer for TypeScript/JavaScript with JSX support for syntax highlighting.

// =============================================================================
// Token Types
// =============================================================================

///|
/// TypeScript token types
pub(all) enum TsTokenType {
  // Keywords
  Keyword // function, const, let, var, if, else, etc.
  // Literals
  String // "...", '...'
  Number // 123, 0x1F, 0b101, 1.5e10
  Regex // /pattern/flags
  True // true
  False // false
  Null // null
  Undefined // undefined
  // Template literals
  TemplateHead // `...${
  TemplateMiddle // }...${
  TemplateTail // }...`
  TemplateString // `...` (no interpolation)
  // Names
  Identifier // variable names, function names
  PrivateId // #privateField
  TypeName // string, number, boolean, etc.
  // Decorators
  Decorator // @decorator
  // Operators
  Operator // +, -, *, /, =, ==, ===, etc.
  Spread // ...
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
  // Comments
  LineComment // // ...
  BlockComment // /* ... */
  // JSX
  JsxTagOpen // < in <div
  JsxTagClose // > in <div> or />
  JsxCloseTag // </
  JsxTagName // div, MyComponent
  JsxAttribute // className, onClick
  JsxEquals // = in attr=
  JsxText // text content between tags
  JsxExprStart // { in JSX
  JsxExprEnd // } in JSX
  // Error
  Error
} derive(Eq, Show)

// =============================================================================
// Keywords
// =============================================================================

///|
/// Check if a word is a JavaScript/TypeScript keyword
fn is_keyword(word : String) -> Bool {
  match word {
    // Control flow
    "if"
    | "else"
    | "switch"
    | "case"
    | "for"
    | "while"
    | "do"
    | "break"
    | "continue"
    | "return"
    | "throw"
    | "try"
    | "catch"
    | "finally" => true
    // Declarations
    "function"
    | "class"
    | "const"
    | "let"
    | "var"
    | "import"
    | "export"
    | "from"
    | "as" => true
    // TypeScript specific
    "interface"
    | "type"
    | "enum"
    | "namespace"
    | "module"
    | "declare"
    | "abstract"
    | "implements"
    | "extends"
    | "public"
    | "private"
    | "protected"
    | "readonly"
    | "static"
    | "override"
    | "keyof"
    | "infer" => true
    // Async
    "async" | "await" | "yield" => true
    // Other
    "new"
    | "this"
    | "super"
    | "typeof"
    | "instanceof"
    | "in"
    | "of"
    | "void"
    | "delete"
    | "with"
    | "debugger"
    | "default" => true
    _ => false
  }
}

///|
/// Check if a word is a TypeScript built-in type name
fn is_builtin_type(word : String) -> Bool {
  match word {
    // Primitive types
    "string" | "number" | "boolean" | "bigint" | "symbol" => true
    // Special types (void is a keyword, not listed here)
    "any" | "unknown" | "never" | "object" => true
    // Utility types (commonly used)
    "Array"
    | "Map"
    | "Set"
    | "WeakMap"
    | "WeakSet"
    | "Promise"
    | "Record"
    | "Partial"
    | "Required"
    | "Readonly"
    | "Pick"
    | "Omit"
    | "Exclude"
    | "Extract"
    | "NonNullable"
    | "ReturnType"
    | "InstanceType"
    | "Parameters"
    | "ConstructorParameters"
    | "ThisType"
    | "Awaited" => true
    _ => false
  }
}

// =============================================================================
// Token
// =============================================================================

///|
/// A token with position information
pub(all) struct TsToken {
  token_type : TsTokenType
  from : Int
  to : Int
} derive(Eq, Show)

// =============================================================================
// Tokenizer
// =============================================================================

///|
/// Parser context for JSX detection and template literals
enum TsContext {
  Normal // Regular JS/TS code
  JsxTagStart // Just after < (need to read tag name)
  JsxElement // Inside a JSX element (after tag name, reading attrs)
  JsxChildren // Inside JSX children (between tags)
  JsxClosingTag // Inside closing tag </xxx>
  JsxExpression // Inside {expr} in JSX
  TemplateExpr // Inside ${...} in template literal
} derive(Eq, Show)

///|
/// TypeScript tokenizer with JSX support
pub(all) struct TsTokenizer {
  input : String
  priv chars : Array[Char]
  priv len : Int
  priv mut pos : Int
  priv context_stack : Array[TsContext]
  priv mut last_token : TsTokenType?
}

///|
/// Create a new tokenizer
pub fn TsTokenizer::new(input : String) -> TsTokenizer {
  let chars = input.to_array()
  {
    input,
    chars,
    len: chars.length(),
    pos: 0,
    context_stack: [Normal],
    last_token: None,
  }
}

///|
/// Get current context
fn TsTokenizer::context(self : TsTokenizer) -> TsContext {
  if self.context_stack.length() > 0 {
    self.context_stack[self.context_stack.length() - 1]
  } else {
    Normal
  }
}

///|
/// Push context
fn TsTokenizer::push_context(self : TsTokenizer, ctx : TsContext) -> Unit {
  self.context_stack.push(ctx)
}

///|
/// Pop context
fn TsTokenizer::pop_context(self : TsTokenizer) -> Unit {
  if self.context_stack.length() > 1 {
    let _ = self.context_stack.pop()

  }
}

///|
/// Skip whitespace
fn TsTokenizer::skip_whitespace(self : TsTokenizer) -> Unit {
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
      self.pos += 1
    } else {
      break
    }
  }
}

///|
/// Check if char is digit
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
/// Check if char is hex digit
fn is_hex_digit(c : Char) -> Bool {
  is_digit(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

///|
/// Check if char is identifier start
fn is_ident_start(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' || c == '$'
}

///|
/// Check if char is identifier part
fn is_ident_part(c : Char) -> Bool {
  is_ident_start(c) || is_digit(c)
}

///|
/// Check if char is valid in JSX tag name (includes - for custom elements)
fn is_jsx_name_part(c : Char) -> Bool {
  is_ident_part(c) || c == '-' || c == '.'
}

///|
/// Read a string literal
fn TsTokenizer::read_string(self : TsTokenizer, quote : Char) -> TsToken {
  let start = self.pos
  self.pos += 1 // skip opening quote
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == quote {
      self.pos += 1
      break
    } else if c == '\\' && self.pos + 1 < self.len {
      self.pos += 2 // skip escape sequence
    } else if c == '\n' && quote != '`' {
      break
    } else {
      self.pos += 1
    }
  }
  { token_type: String, from: start, to: self.pos }
}

///|
/// Read a template literal (starting with `)
fn TsTokenizer::read_template_literal(self : TsTokenizer) -> TsToken {
  let start = self.pos
  self.pos += 1 // Skip opening `
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == '`' {
      // End of template - no interpolation
      self.pos += 1
      return { token_type: TemplateString, from: start, to: self.pos }
    } else if c == '\\' && self.pos + 1 < self.len {
      // Escape sequence
      self.pos += 2
    } else if c == '$' &&
      self.pos + 1 < self.len &&
      self.chars[self.pos + 1] == '{' {
      // Start of interpolation - return TemplateHead
      self.pos += 2 // Include ${
      self.push_context(TemplateExpr)
      return { token_type: TemplateHead, from: start, to: self.pos }
    } else {
      self.pos += 1
    }
  }
  // Unterminated template
  { token_type: TemplateString, from: start, to: self.pos }
}

///|
/// Read template continuation (after } in template)
fn TsTokenizer::read_template_continuation(self : TsTokenizer) -> TsToken {
  let start = self.pos
  // We're at the } that ends the expression

  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == '`' {
      // End of template
      self.pos += 1
      return { token_type: TemplateTail, from: start, to: self.pos }
    } else if c == '\\' && self.pos + 1 < self.len {
      self.pos += 2
    } else if c == '$' &&
      self.pos + 1 < self.len &&
      self.chars[self.pos + 1] == '{' {
      // Another interpolation
      self.pos += 2
      self.push_context(TemplateExpr)
      return { token_type: TemplateMiddle, from: start, to: self.pos }
    } else {
      self.pos += 1
    }
  }
  { token_type: TemplateTail, from: start, to: self.pos }
}

///|
/// Read a decorator (@name)
fn TsTokenizer::read_decorator(self : TsTokenizer) -> TsToken {
  let start = self.pos
  self.pos += 1 // Skip @

  // Read the decorator name (can include dots for @module.decorator)
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if is_ident_part(c) || c == '.' {
      self.pos += 1
    } else {
      break
    }
  }
  { token_type: Decorator, from: start, to: self.pos }
}

///|
/// Read a private field (#name)
fn TsTokenizer::read_private_field(self : TsTokenizer) -> TsToken {
  let start = self.pos
  self.pos += 1 // Skip #

  // Read the field name
  while self.pos < self.len && is_ident_part(self.chars[self.pos]) {
    self.pos += 1
  }
  { token_type: PrivateId, from: start, to: self.pos }
}

///|
/// Check if char is digit or numeric separator
fn is_digit_or_sep(c : Char) -> Bool {
  is_digit(c) || c == '_'
}

///|
/// Read a number (supports numeric separators like 1_000_000)
fn TsTokenizer::read_number(self : TsTokenizer) -> TsToken {
  let start = self.pos
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

  // Integer part (with optional separators)
  while self.pos < self.len && is_digit_or_sep(self.chars[self.pos]) {
    self.pos += 1
  }

  // Decimal part
  if self.pos < self.len && self.chars[self.pos] == '.' {
    if self.pos + 1 < self.len && is_digit(self.chars[self.pos + 1]) {
      self.pos += 1
      while self.pos < self.len && is_digit_or_sep(self.chars[self.pos]) {
        self.pos += 1
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
      while self.pos < self.len && is_digit_or_sep(self.chars[self.pos]) {
        self.pos += 1
      }
    }
  }
  if self.pos < self.len && self.chars[self.pos] == 'n' {
    self.pos += 1
  }
  { token_type: Number, from: start, to: self.pos }
}

///|
/// Read an identifier or keyword
fn TsTokenizer::read_identifier(self : TsTokenizer) -> TsToken {
  let start = self.pos
  while self.pos < self.len && is_ident_part(self.chars[self.pos]) {
    self.pos += 1
  }
  let word = self.input.unsafe_substring(start~, end=self.pos)
  let token_type = match word {
    "true" => True
    "false" => False
    "null" => Null
    "undefined" => Undefined
    _ if is_keyword(word) => Keyword
    _ if is_builtin_type(word) => TypeName
    _ => Identifier
  }
  { token_type, from: start, to: self.pos }
}

///|
/// Read a line comment
fn TsTokenizer::read_line_comment(self : TsTokenizer) -> TsToken {
  let start = self.pos
  self.pos += 2
  while self.pos < self.len && self.chars[self.pos] != '\n' {
    self.pos += 1
  }
  { token_type: LineComment, from: start, to: self.pos }
}

///|
/// Read a block comment
fn TsTokenizer::read_block_comment(self : TsTokenizer) -> TsToken {
  let start = self.pos
  self.pos += 2
  while self.pos + 1 < self.len {
    if self.chars[self.pos] == '*' && self.chars[self.pos + 1] == '/' {
      self.pos += 2
      break
    }
    self.pos += 1
  }
  { token_type: BlockComment, from: start, to: self.pos }
}

///|
/// Check if current context expects a regex (not division)
fn TsTokenizer::expects_regex(self : TsTokenizer) -> Bool {
  match self.last_token {
    None => true // Start of file
    Some(t) =>
      match t {
        // After these tokens, / is likely regex
        ParenOpen | BracketOpen | BraceOpen => true
        Comma | Semicolon | Colon => true
        Operator => true // =, ==, !=, &&, ||, etc.
        Keyword => true // return /regex/, if (/regex/)
        JsxExprStart => true
        // After these, / is likely division
        Identifier | Number | String | Regex => false
        ParenClose | BracketClose => false
        True | False | Null | Undefined => false
        // Default to regex for safety
        _ => true
      }
  }
}

///|
/// Read a regex literal /pattern/flags
fn TsTokenizer::read_regex(self : TsTokenizer) -> TsToken {
  let start = self.pos
  self.pos += 1 // Skip opening /

  // Read pattern (handle escapes and character classes)
  let mut in_class = false
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == '\\' && self.pos + 1 < self.len {
      // Escape sequence - skip next char
      self.pos += 2
    } else if c == '[' && not(in_class) {
      in_class = true
      self.pos += 1
    } else if c == ']' && in_class {
      in_class = false
      self.pos += 1
    } else if c == '/' && not(in_class) {
      // End of pattern
      self.pos += 1
      break
    } else if c == '\n' {
      // Invalid regex (newline without escape)
      break
    } else {
      self.pos += 1
    }
  }

  // Read flags (g, i, m, s, u, y, d)
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == 'g' ||
      c == 'i' ||
      c == 'm' ||
      c == 's' ||
      c == 'u' ||
      c == 'y' ||
      c == 'd' {
      self.pos += 1
    } else {
      break
    }
  }
  { token_type: Regex, from: start, to: self.pos }
}

///|
/// Read an operator
fn TsTokenizer::read_operator(self : TsTokenizer) -> TsToken {
  let start = self.pos
  let c = self.chars[self.pos]
  if self.pos + 2 < self.len {
    let c2 = self.chars[self.pos + 1]
    let c3 = self.chars[self.pos + 2]
    if (c == '=' && c2 == '=' && c3 == '=') ||
      (c == '!' && c2 == '=' && c3 == '=') ||
      (c == '.' && c2 == '.' && c3 == '.') ||
      (c == '<' && c2 == '<' && c3 == '=') ||
      (c == '>' && c2 == '>' && c3 == '=') ||
      (c == '>' && c2 == '>' && c3 == '>') ||
      (c == '?' && c2 == '?' && c3 == '=') ||
      (c == '&' && c2 == '&' && c3 == '=') ||
      (c == '|' && c2 == '|' && c3 == '=') {
      self.pos += 3
      return { token_type: Operator, from: start, to: self.pos }
    }
  }
  if self.pos + 1 < self.len {
    let c2 = self.chars[self.pos + 1]
    if (c == '=' && c2 == '=') ||
      (c == '!' && c2 == '=') ||
      (c == '<' && c2 == '=') ||
      (c == '>' && c2 == '=') ||
      (c == '+' && c2 == '+') ||
      (c == '-' && c2 == '-') ||
      (c == '+' && c2 == '=') ||
      (c == '-' && c2 == '=') ||
      (c == '*' && c2 == '=') ||
      (c == '/' && c2 == '=') ||
      (c == '%' && c2 == '=') ||
      (c == '&' && c2 == '&') ||
      (c == '|' && c2 == '|') ||
      (c == '?' && c2 == '?') ||
      (c == '?' && c2 == '.') ||
      (c == '=' && c2 == '>') ||
      (c == '<' && c2 == '<') ||
      (c == '>' && c2 == '>') ||
      (c == '*' && c2 == '*') ||
      (c == '&' && c2 == '=') ||
      (c == '|' && c2 == '=') ||
      (c == '^' && c2 == '=') {
      self.pos += 2
      return { token_type: Operator, from: start, to: self.pos }
    }
  }
  self.pos += 1
  { token_type: Operator, from: start, to: self.pos }
}

///|
/// Check if `<` should be treated as JSX based on last token
fn TsTokenizer::is_jsx_context(self : TsTokenizer) -> Bool {
  match self.last_token {
    // After these tokens, < is likely JSX
    Some(ParenOpen) => true // ( <div>
    Some(BraceOpen) => true // { <div>
    Some(BracketOpen) => true // [ <div>
    Some(Comma) => true // , <div>
    Some(Colon) => true // : <div>
    Some(Semicolon) => true // ; <div>
    Some(Operator) => true // = <div>, && <div>, etc.
    Some(Keyword) => true // return <div>
    Some(JsxTagClose) => true // > <child>
    Some(JsxExprEnd) => true // } <sibling>
    None => true // Start of file
    _ => false
  }
}

///|
/// Read JSX tag name
fn TsTokenizer::read_jsx_tag_name(self : TsTokenizer) -> TsToken {
  let start = self.pos
  while self.pos < self.len && is_jsx_name_part(self.chars[self.pos]) {
    self.pos += 1
  }
  { token_type: JsxTagName, from: start, to: self.pos }
}

///|
/// Read JSX attribute name
fn TsTokenizer::read_jsx_attribute(self : TsTokenizer) -> TsToken {
  let start = self.pos
  while self.pos < self.len && is_jsx_name_part(self.chars[self.pos]) {
    self.pos += 1
  }
  { token_type: JsxAttribute, from: start, to: self.pos }
}

///|
/// Read JSX text content
fn TsTokenizer::read_jsx_text(self : TsTokenizer) -> TsToken {
  let start = self.pos
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == '<' || c == '{' {
      break
    }
    self.pos += 1
  }
  { token_type: JsxText, from: start, to: self.pos }
}

///|
/// Tokenize in JsxElement context (inside opening tag)
fn TsTokenizer::next_jsx_element_token(self : TsTokenizer) -> TsToken? {
  self.skip_whitespace()
  if self.pos >= self.len {
    return None
  }
  let start = self.pos
  let c = self.chars[self.pos]
  match c {
    '/' =>
      if self.pos + 1 < self.len && self.chars[self.pos + 1] == '>' {
        // Self-closing />
        self.pos += 2
        self.pop_context() // Exit JsxElement
        Some({ token_type: JsxTagClose, from: start, to: self.pos })
      } else {
        self.pos += 1
        Some({ token_type: Operator, from: start, to: self.pos })
      }
    '>' => {
      // End of opening tag, switch to JsxChildren
      self.pos += 1
      self.pop_context()
      self.push_context(JsxChildren)
      Some({ token_type: JsxTagClose, from: start, to: self.pos })
    }
    '=' => {
      self.pos += 1
      Some({ token_type: JsxEquals, from: start, to: self.pos })
    }
    '"' | '\'' => Some(self.read_string(c))
    '{' => {
      self.pos += 1
      self.push_context(JsxExpression)
      Some({ token_type: JsxExprStart, from: start, to: self.pos })
    }
    _ if is_ident_start(c) => Some(self.read_jsx_attribute())
    _ => {
      self.pos += 1
      Some({ token_type: Error, from: start, to: self.pos })
    }
  }
}

///|
/// Tokenize in JsxChildren context
fn TsTokenizer::next_jsx_children_token(self : TsTokenizer) -> TsToken? {
  if self.pos >= self.len {
    return None
  }
  let start = self.pos
  let c = self.chars[self.pos]
  match c {
    '<' =>
      if self.pos + 1 < self.len && self.chars[self.pos + 1] == '/' {
        // Closing tag </
        self.pos += 2
        self.pop_context() // Exit JsxChildren
        self.push_context(JsxClosingTag)
        Some({ token_type: JsxCloseTag, from: start, to: self.pos })
      } else {
        // Nested JSX element
        self.pos += 1
        self.push_context(JsxTagStart)
        Some({ token_type: JsxTagOpen, from: start, to: self.pos })
      }
    '{' => {
      self.pos += 1
      self.push_context(JsxExpression)
      Some({ token_type: JsxExprStart, from: start, to: self.pos })
    }
    _ =>
      // Read text content
      Some(self.read_jsx_text())
  }
}

///|
/// Get next token
pub fn TsTokenizer::next_token(self : TsTokenizer) -> TsToken? {
  // Handle JSX contexts
  match self.context() {
    JsxTagStart => {
      // Just after <, read the tag name
      self.skip_whitespace()
      if self.pos >= self.len {
        return None
      }
      if is_ident_start(self.chars[self.pos]) {
        let token = self.read_jsx_tag_name()
        self.pop_context()
        self.push_context(JsxElement)
        self.last_token = Some(token.token_type)
        return Some(token)
      }
      // Invalid JSX, return to normal
      self.pop_context()
      ()
    }
    JsxElement => {
      let token = self.next_jsx_element_token()
      match token {
        Some(t) => self.last_token = Some(t.token_type)
        None => ()
      }
      return token
    }
    JsxChildren => {
      let token = self.next_jsx_children_token()
      match token {
        Some(t) => self.last_token = Some(t.token_type)
        None => ()
      }
      return token
    }
    JsxClosingTag => {
      // Inside </xxx>, read tag name or >
      self.skip_whitespace()
      if self.pos >= self.len {
        return None
      }
      let c = self.chars[self.pos]
      if is_ident_start(c) {
        let token = self.read_jsx_tag_name()
        self.last_token = Some(token.token_type)
        return Some(token)
      } else if c == '>' {
        let start = self.pos
        self.pos += 1
        self.pop_context()
        self.last_token = Some(JsxTagClose)
        return Some({ token_type: JsxTagClose, from: start, to: self.pos })
      }
      // Invalid, pop and continue
      self.pop_context()
      ()
    }
    JsxExpression => {
      // In expression, look for closing }
      self.skip_whitespace()
      if self.pos >= self.len {
        return None
      }
      if self.chars[self.pos] == '}' {
        let start = self.pos
        self.pos += 1
        self.pop_context()
        self.last_token = Some(JsxExprEnd)
        return Some({ token_type: JsxExprEnd, from: start, to: self.pos })
      }
      // Otherwise, parse normal token
      ()
    }
    TemplateExpr => {
      // In template expression ${...}, look for closing }
      self.skip_whitespace()
      if self.pos >= self.len {
        return None
      }
      if self.chars[self.pos] == '}' {
        // End of expression, continue with template
        self.pop_context()
        let token = self.read_template_continuation()
        self.last_token = Some(token.token_type)
        return Some(token)
      }
      // Otherwise, parse normal token
      ()
    }
    Normal => ()
  }
  self.skip_whitespace()
  if self.pos >= self.len {
    return None
  }
  let start = self.pos
  let c = self.chars[self.pos]

  // Check for comments and regex
  if c == '/' && self.pos + 1 < self.len {
    let next = self.chars[self.pos + 1]
    if next == '/' {
      let token = self.read_line_comment()
      self.last_token = Some(token.token_type)
      return Some(token)
    } else if next == '*' {
      let token = self.read_block_comment()
      self.last_token = Some(token.token_type)
      return Some(token)
    } else if self.expects_regex() {
      // It's a regex literal
      let token = self.read_regex()
      self.last_token = Some(token.token_type)
      return Some(token)
    }
  } else if c == '/' && self.expects_regex() {
    // Single / at end of input or followed by something else
    let token = self.read_regex()
    self.last_token = Some(token.token_type)
    return Some(token)
  }

  // Check for JSX
  if c == '<' {
    // Check if this is a closing tag in expression context
    if self.pos + 1 < self.len && self.chars[self.pos + 1] == '/' {
      // This is a closing tag </
      self.pos += 2
      self.push_context(JsxClosingTag)
      self.last_token = Some(JsxCloseTag)
      return Some({ token_type: JsxCloseTag, from: start, to: self.pos })
    }

    // Check if this looks like JSX (< followed by identifier or >)
    if self.is_jsx_context() && self.pos + 1 < self.len {
      let next = self.chars[self.pos + 1]
      if is_ident_start(next) || next == '>' {
        // It's JSX!
        self.pos += 1
        self.push_context(JsxTagStart)
        self.last_token = Some(JsxTagOpen)
        return Some({ token_type: JsxTagOpen, from: start, to: self.pos })
      }
    }
    // Fall through to operator handling
  }

  // Check for decorator (@)
  if c == '@' {
    let token = self.read_decorator()
    self.last_token = Some(token.token_type)
    return Some(token)
  }

  // Check for private field (#)
  if c == '#' {
    let token = self.read_private_field()
    self.last_token = Some(token.token_type)
    return Some(token)
  }
  let token = match c {
    '"' | '\'' => self.read_string(c)
    '`' => self.read_template_literal()
    '{' => {
      self.pos += 1
      { token_type: BraceOpen, from: start, to: self.pos }
    }
    '}' => {
      self.pos += 1
      // Check if we're exiting a JSX expression
      if self.context() == JsxExpression {
        self.pop_context()
        { token_type: JsxExprEnd, from: start, to: self.pos }
      } else {
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
    ';' => {
      self.pos += 1
      { token_type: Semicolon, from: start, to: self.pos }
    }
    ',' => {
      self.pos += 1
      { token_type: Comma, from: start, to: self.pos }
    }
    ':' => {
      self.pos += 1
      { token_type: Colon, from: start, to: self.pos }
    }
    '.' =>
      // Check for spread operator ...
      if self.pos + 2 < self.len &&
        self.chars[self.pos + 1] == '.' &&
        self.chars[self.pos + 2] == '.' {
        self.pos += 3
        { token_type: Spread, from: start, to: self.pos }
      } else if self.pos + 1 < self.len && is_digit(self.chars[self.pos + 1]) {
        self.read_number()
      } else {
        self.pos += 1
        { token_type: Dot, from: start, to: self.pos }
      }
    '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' =>
      self.read_number()
    _ if is_ident_start(c) => self.read_identifier()
    '+'
    | '-'
    | '*'
    | '/'
    | '%'
    | '='
    | '!'
    | '<'
    | '>'
    | '&'
    | '|'
    | '^'
    | '~'
    | '?' => self.read_operator()
    _ => {
      self.pos += 1
      { token_type: Error, from: start, to: self.pos }
    }
  }
  self.last_token = Some(token.token_type)
  Some(token)
}

///|
/// Tokenize entire input
pub fn TsTokenizer::tokenize_all(self : TsTokenizer) -> Array[TsToken] {
  let tokens : Array[TsToken] = []
  while true {
    match self.next_token() {
      Some(token) => tokens.push(token)
      None => break
    }
  }
  tokens
}

// =============================================================================
// Incremental Tokenization API
// =============================================================================

///|
/// Tokenizer state for incremental tokenization
/// Can be saved and restored to resume tokenization from a checkpoint
pub(all) struct TokenizerState {
  pos : Int
  context_stack : Array[TsContext]
  last_token : TsTokenType?
} derive(Eq, Show)

///|
/// Save current tokenizer state
pub fn TsTokenizer::save_state(self : TsTokenizer) -> TokenizerState {
  {
    pos: self.pos,
    context_stack: self.context_stack.copy(),
    last_token: self.last_token,
  }
}

///|
/// Get current position
pub fn TsTokenizer::position(self : TsTokenizer) -> Int {
  self.pos
}

///|
/// Create tokenizer from saved state
pub fn TsTokenizer::from_state(
  input : String,
  state : TokenizerState,
) -> TsTokenizer {
  let chars = input.to_array()
  {
    input,
    chars,
    len: chars.length(),
    pos: state.pos,
    context_stack: state.context_stack.copy(),
    last_token: state.last_token,
  }
}

///|
/// Line-based token cache for incremental updates
/// Stores tokens per line with their starting state
pub(all) struct TokenCache {
  /// Tokens grouped by line
  lines : Array[Array[TsToken]]
  /// Tokenizer state at the start of each line
  line_states : Array[TokenizerState]
  /// Source text
  mut source : String
}

///|
/// Create a new token cache from source
pub fn TokenCache::new(source : String) -> TokenCache {
  let cache : TokenCache = { lines: [], line_states: [], source }
  cache.tokenize_full()
  cache
}

///|
/// Full tokenization, populating all lines
fn TokenCache::tokenize_full(self : TokenCache) -> Unit {
  self.lines.clear()
  self.line_states.clear()
  let tokenizer = TsTokenizer::new(self.source)

  // Track line boundaries
  let mut current_line_tokens : Array[TsToken] = []
  let mut current_line_start = 0

  // Save initial state
  self.line_states.push(tokenizer.save_state())
  while true {
    let start_pos = tokenizer.position()
    match tokenizer.next_token() {
      Some(token) => {
        // Check if we crossed a line boundary
        let token_text = self.source.unsafe_substring(
          start=token.from,
          end=token.to,
        )
        if token_text.contains("\n") ||
          (
            start_pos > current_line_start &&
            self.has_newline_between(current_line_start, token.from)
          ) {
          // Save current line and start new one
          self.lines.push(current_line_tokens)
          current_line_tokens = []
          current_line_start = token.from
          self.line_states.push({
            pos: token.from,
            context_stack: tokenizer.save_state().context_stack,
            last_token: tokenizer.save_state().last_token,
          })
        }
        current_line_tokens.push(token)
      }
      None => break
    }
  }

  // Don't forget the last line
  if current_line_tokens.length() > 0 || self.lines.length() == 0 {
    self.lines.push(current_line_tokens)
  }
}

///|
/// Check if there's a newline between two positions
fn TokenCache::has_newline_between(
  self : TokenCache,
  from : Int,
  to : Int,
) -> Bool {
  let chars = self.source.to_array()
  for i = from; i < to && i < chars.length(); i = i + 1 {
    if chars[i] == '\n' {
      return true
    }
  }
  false
}

///|
/// Get all tokens flattened
pub fn TokenCache::all_tokens(self : TokenCache) -> Array[TsToken] {
  let result : Array[TsToken] = []
  for line in self.lines {
    for token in line {
      result.push(token)
    }
  }
  result
}

///|
/// Get number of lines
pub fn TokenCache::line_count(self : TokenCache) -> Int {
  self.lines.length()
}

///|
/// Get tokens for a specific line
pub fn TokenCache::get_line_tokens(
  self : TokenCache,
  line : Int,
) -> Array[TsToken] {
  if line >= 0 && line < self.lines.length() {
    self.lines[line]
  } else {
    []
  }
}

///|
/// Update cache when source changes
/// Returns the range of lines that were re-tokenized
pub fn TokenCache::update(
  self : TokenCache,
  new_source : String,
  edit_line : Int,
) -> (Int, Int) {
  self.source = new_source

  // Find the line to start re-tokenizing from
  let start_line = if edit_line > 0 { edit_line - 1 } else { 0 }

  // Get the state at the start of that line
  let start_state = if start_line < self.line_states.length() {
    self.line_states[start_line]
  } else {
    { pos: 0, context_stack: [Normal], last_token: None }
  }

  // Re-tokenize from this point
  let tokenizer = TsTokenizer::from_state(new_source, start_state)

  // Track new lines
  let new_lines : Array[Array[TsToken]] = []
  let new_states : Array[TokenizerState] = []
  let mut current_line_tokens : Array[TsToken] = []
  new_states.push(start_state)
  while true {
    match tokenizer.next_token() {
      Some(token) => {
        let end_pos = if token.to > new_source.length() {
          new_source.length()
        } else {
          token.to
        }
        let token_text = new_source.unsafe_substring(
          start=token.from,
          end=end_pos,
        )
        if token_text.contains("\n") {
          new_lines.push(current_line_tokens)
          current_line_tokens = []
          new_states.push(tokenizer.save_state())
        }
        current_line_tokens.push(token)
      }
      None => break
    }
  }
  if current_line_tokens.length() > 0 {
    new_lines.push(current_line_tokens)
  }

  // Replace affected lines
  // Truncate old data from start_line
  while self.lines.length() > start_line {
    let _ = self.lines.pop()

  }
  while self.line_states.length() > start_line {
    let _ = self.line_states.pop()

  }

  // Add new lines
  for state in new_states {
    self.line_states.push(state)
  }
  for line in new_lines {
    self.lines.push(line)
  }
  (start_line, start_line + new_lines.length())
}

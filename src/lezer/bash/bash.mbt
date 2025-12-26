///| Bash/Shell Tokenizer for syntax highlighting

// =============================================================================
// Bash Token Types
// =============================================================================

///|
/// Bash token types
pub(all) enum BashTokenType {
  // Keywords
  Keyword // if, then, else, fi, for, while, do, done, case, esac, etc.

  // Commands and arguments
  Command // First word (command name)
  Argument // Command arguments
  Option // -f, --flag

  // Variables
  Variable // $VAR, ${VAR}
  SpecialVar // $?, $!, $$, $@, $*, $#, $0-$9

  // Strings
  DoubleString // "..."
  SingleString // '...'
  RawString // $'...'
  HereDoc // <<EOF ... EOF

  // Operators
  Pipe // |
  PipeAnd // |&
  And // &&
  Or // ||
  Redirect // >, >>, <, <<, 2>, &>, etc.
  Background // &
  Semicolon // ;
  DoubleSemicolon // ;;

  // Substitution
  CommandSub // $(...)
  ProcessSub // <(...) or >(...)
  ArithmeticExp // $((...))

  // Brackets
  ParenOpen // (
  ParenClose // )
  BraceOpen // {
  BraceClose // }
  BracketOpen // [
  BracketClose // ]
  DoubleBracket // [[ or ]]

  // Special
  Comment // # ...
  Shebang // #!/bin/bash
  Glob // *, ?, [...]
  Equals // =
  Number // 123

  // Error
  Error
} derive(Eq, Show)

// =============================================================================
// Bash Token
// =============================================================================

///|
/// A token produced by the Bash tokenizer
pub(all) struct BashToken {
  token_type : BashTokenType
  from : Int
  to : Int
} derive(Eq, Show)

// =============================================================================
// Bash Keywords
// =============================================================================

///|
fn is_keyword(word : String) -> Bool {
  match word {
    "if" | "then" | "else" | "elif" | "fi" => true
    "for" | "while" | "until" | "do" | "done" => true
    "case" | "esac" | "in" => true
    "function" | "return" | "exit" => true
    "local" | "export" | "readonly" | "declare" | "typeset" => true
    "source" | "eval" | "exec" => true
    "break" | "continue" => true
    "select" | "time" | "coproc" => true
    "true" | "false" => true
    _ => false
  }
}

// =============================================================================
// Bash Tokenizer
// =============================================================================

///|
/// Bash Tokenizer state
pub(all) struct BashTokenizer {
  input : String
  priv chars : Array[Char]
  priv len : Int
  priv mut pos : Int
  priv mut at_line_start : Bool
  priv mut after_command : Bool
}

///|
/// Create a new Bash tokenizer
pub fn BashTokenizer::new(input : String) -> BashTokenizer {
  let chars = input.to_array()
  {
    input,
    chars,
    len: chars.length(),
    pos: 0,
    at_line_start: true,
    after_command: false,
  }
}

///|
/// Check if at end of input
pub fn BashTokenizer::at_end(self : BashTokenizer) -> Bool {
  self.pos >= self.len
}

///|
/// Peek character at offset
fn BashTokenizer::peek_at(self : BashTokenizer, offset : Int) -> Char? {
  let idx = self.pos + offset
  if idx >= 0 && idx < self.len {
    Some(self.chars[idx])
  } else {
    None
  }
}

///|
/// Check if character is whitespace (not newline)
fn is_whitespace(c : Char) -> Bool {
  c == ' ' || c == '\t'
}

///|
/// Check if character is valid for identifiers/words
fn is_word_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_' ||
  c == '-' ||
  c == '.' ||
  c == '/' ||
  c == ':' ||
  c == '@' ||
  c == '~'
}

///|
/// Check if character is a digit
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
/// Skip whitespace (not newlines)
fn BashTokenizer::skip_whitespace(self : BashTokenizer) -> Unit {
  while self.pos < self.len && is_whitespace(self.chars[self.pos]) {
    self.pos += 1
  }
}

///|
/// Read a comment: # ... (to end of line)
fn BashTokenizer::read_comment(self : BashTokenizer) -> BashToken {
  let start = self.pos

  // Check for shebang
  if start == 0 && self.peek_at(1) == Some('!') {
    while self.pos < self.len && self.chars[self.pos] != '\n' {
      self.pos += 1
    }
    return { token_type: Shebang, from: start, to: self.pos }
  }

  // Regular comment
  while self.pos < self.len && self.chars[self.pos] != '\n' {
    self.pos += 1
  }
  { token_type: Comment, from: start, to: self.pos }
}

///|
/// Read a double-quoted string
fn BashTokenizer::read_double_string(self : BashTokenizer) -> BashToken {
  let start = self.pos
  self.pos += 1 // skip opening "
  while self.pos < self.len {
    let c = self.chars[self.pos]
    if c == '"' {
      self.pos += 1
      break
    } else if c == '\\' && self.pos + 1 < self.len {
      self.pos += 2 // skip escape
    } else {
      self.pos += 1
    }
  }
  { token_type: DoubleString, from: start, to: self.pos }
}

///|
/// Read a single-quoted string
fn BashTokenizer::read_single_string(self : BashTokenizer) -> BashToken {
  let start = self.pos
  self.pos += 1 // skip opening '
  while self.pos < self.len && self.chars[self.pos] != '\'' {
    self.pos += 1
  }
  if self.pos < self.len {
    self.pos += 1 // skip closing '
  }
  { token_type: SingleString, from: start, to: self.pos }
}

///|
/// Read a $'...' string (ANSI-C quoting)
fn BashTokenizer::read_raw_string(self : BashTokenizer) -> BashToken {
  let start = self.pos
  self.pos += 2 // skip $'
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
  { token_type: RawString, from: start, to: self.pos }
}

///|
/// Read a variable: $VAR or ${VAR}
fn BashTokenizer::read_variable(self : BashTokenizer) -> BashToken {
  let start = self.pos
  self.pos += 1 // skip $
  if self.pos >= self.len {
    return { token_type: Variable, from: start, to: self.pos }
  }
  let c = self.chars[self.pos]

  // Special variables: $?, $!, $$, $@, $*, $#, $0-$9
  match c {
    '?' | '!' | '$' | '@' | '*' | '#' | '-' | '_' => {
      self.pos += 1
      return { token_type: SpecialVar, from: start, to: self.pos }
    }
    '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' => {
      self.pos += 1
      return { token_type: SpecialVar, from: start, to: self.pos }
    }
    _ => ()
  }

  // ${...} form
  if c == '{' {
    self.pos += 1
    while self.pos < self.len && self.chars[self.pos] != '}' {
      self.pos += 1
    }
    if self.pos < self.len {
      self.pos += 1 // skip }
    }
    return { token_type: Variable, from: start, to: self.pos }
  }

  // $(...) command substitution
  if c == '(' {
    // Check for $((...)) arithmetic
    if self.peek_at(1) == Some('(') {
      self.pos += 2
      let mut depth = 2
      while self.pos < self.len && depth > 0 {
        if self.chars[self.pos] == '(' {
          depth += 1
        } else if self.chars[self.pos] == ')' {
          depth -= 1
        }
        self.pos += 1
      }
      return { token_type: ArithmeticExp, from: start, to: self.pos }
    }

    // Regular command substitution
    self.pos += 1
    let mut depth = 1
    while self.pos < self.len && depth > 0 {
      let ch = self.chars[self.pos]
      if ch == '(' {
        depth += 1
      } else if ch == ')' {
        depth -= 1
      }
      self.pos += 1
    }
    return { token_type: CommandSub, from: start, to: self.pos }
  }

  // Regular variable name
  while self.pos < self.len {
    let ch = self.chars[self.pos]
    if (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '_' {
      self.pos += 1
    } else {
      break
    }
  }
  { token_type: Variable, from: start, to: self.pos }
}

///|
/// Read a word (command, argument, or keyword)
fn BashTokenizer::read_word(self : BashTokenizer) -> BashToken {
  let start = self.pos

  // Check for option
  if self.chars[self.pos] == '-' {
    self.pos += 1
    if self.pos < self.len && self.chars[self.pos] == '-' {
      self.pos += 1 // --long-option
    }
    while self.pos < self.len && is_word_char(self.chars[self.pos]) {
      self.pos += 1
    }
    return { token_type: Option, from: start, to: self.pos }
  }
  while self.pos < self.len && is_word_char(self.chars[self.pos]) {
    self.pos += 1
  }

  // Check if it's a keyword
  let word = String::from_array(self.chars[start:self.pos])
  if is_keyword(word) {
    return { token_type: Keyword, from: start, to: self.pos }
  }

  // First word after newline/semicolon is a command
  if self.at_line_start && not(self.after_command) {
    self.after_command = true
    return { token_type: Command, from: start, to: self.pos }
  }
  { token_type: Argument, from: start, to: self.pos }
}

///|
/// Tokenize the entire input
pub fn BashTokenizer::tokenize_all(self : BashTokenizer) -> Array[BashToken] {
  let tokens : Array[BashToken] = []
  while self.pos < self.len {
    self.skip_whitespace()
    if self.pos >= self.len {
      break
    }
    let c = self.chars[self.pos]

    // Newline
    if c == '\n' {
      self.pos += 1
      self.at_line_start = true
      self.after_command = false
      continue
    }

    // Comment
    if c == '#' {
      tokens.push(self.read_comment())
      continue
    }

    // Strings
    if c == '"' {
      tokens.push(self.read_double_string())
      continue
    }
    if c == '\'' {
      tokens.push(self.read_single_string())
      continue
    }
    if c == '$' && self.peek_at(1) == Some('\'') {
      tokens.push(self.read_raw_string())
      continue
    }

    // Variables and substitutions
    if c == '$' {
      tokens.push(self.read_variable())
      continue
    }

    // Process substitution
    if (c == '<' || c == '>') && self.peek_at(1) == Some('(') {
      let start = self.pos
      self.pos += 2
      let mut depth = 1
      while self.pos < self.len && depth > 0 {
        if self.chars[self.pos] == '(' {
          depth += 1
        } else if self.chars[self.pos] == ')' {
          depth -= 1
        }
        self.pos += 1
      }
      tokens.push({ token_type: ProcessSub, from: start, to: self.pos })
      continue
    }

    // Operators
    match c {
      '|' =>
        if self.peek_at(1) == Some('|') {
          let start = self.pos
          self.pos += 2
          tokens.push({ token_type: Or, from: start, to: self.pos })
        } else if self.peek_at(1) == Some('&') {
          let start = self.pos
          self.pos += 2
          tokens.push({ token_type: PipeAnd, from: start, to: self.pos })
        } else {
          let start = self.pos
          self.pos += 1
          tokens.push({ token_type: Pipe, from: start, to: self.pos })
          self.at_line_start = true
          self.after_command = false
        }
      '&' =>
        if self.peek_at(1) == Some('&') {
          let start = self.pos
          self.pos += 2
          tokens.push({ token_type: And, from: start, to: self.pos })
          self.at_line_start = true
          self.after_command = false
        } else if self.peek_at(1) == Some('>') {
          let start = self.pos
          self.pos += 2
          tokens.push({ token_type: Redirect, from: start, to: self.pos })
        } else {
          let start = self.pos
          self.pos += 1
          tokens.push({ token_type: Background, from: start, to: self.pos })
        }
      ';' =>
        if self.peek_at(1) == Some(';') {
          let start = self.pos
          self.pos += 2
          tokens.push({ token_type: DoubleSemicolon, from: start, to: self.pos })
        } else {
          let start = self.pos
          self.pos += 1
          tokens.push({ token_type: Semicolon, from: start, to: self.pos })
          self.at_line_start = true
          self.after_command = false
        }
      '>' => {
        let start = self.pos
        self.pos += 1
        if self.pos < self.len && self.chars[self.pos] == '>' {
          self.pos += 1
        }
        tokens.push({ token_type: Redirect, from: start, to: self.pos })
      }
      '<' => {
        let start = self.pos
        self.pos += 1
        if self.pos < self.len && self.chars[self.pos] == '<' {
          self.pos += 1
          // Here-doc marker (simplified)
          if self.pos < self.len && self.chars[self.pos] == '<' {
            self.pos += 1
          }
        }
        tokens.push({ token_type: Redirect, from: start, to: self.pos })
      }
      '(' => {
        let start = self.pos
        self.pos += 1
        tokens.push({ token_type: ParenOpen, from: start, to: self.pos })
      }
      ')' => {
        let start = self.pos
        self.pos += 1
        tokens.push({ token_type: ParenClose, from: start, to: self.pos })
      }
      '{' => {
        let start = self.pos
        self.pos += 1
        tokens.push({ token_type: BraceOpen, from: start, to: self.pos })
      }
      '}' => {
        let start = self.pos
        self.pos += 1
        tokens.push({ token_type: BraceClose, from: start, to: self.pos })
      }
      '[' =>
        if self.peek_at(1) == Some('[') {
          let start = self.pos
          self.pos += 2
          tokens.push({ token_type: DoubleBracket, from: start, to: self.pos })
        } else {
          let start = self.pos
          self.pos += 1
          tokens.push({ token_type: BracketOpen, from: start, to: self.pos })
        }
      ']' =>
        if self.peek_at(1) == Some(']') {
          let start = self.pos
          self.pos += 2
          tokens.push({ token_type: DoubleBracket, from: start, to: self.pos })
        } else {
          let start = self.pos
          self.pos += 1
          tokens.push({ token_type: BracketClose, from: start, to: self.pos })
        }
      '=' => {
        let start = self.pos
        self.pos += 1
        tokens.push({ token_type: Equals, from: start, to: self.pos })
      }
      '*' | '?' => {
        let start = self.pos
        self.pos += 1
        tokens.push({ token_type: Glob, from: start, to: self.pos })
      }
      _ =>
        // Number
        if is_digit(c) {
          let start = self.pos
          while self.pos < self.len && is_digit(self.chars[self.pos]) {
            self.pos += 1
          }
          // Check for redirection like 2>
          if self.pos < self.len &&
            (self.chars[self.pos] == '>' || self.chars[self.pos] == '<') {
            if self.chars[self.pos] == '>' {
              self.pos += 1
              if self.pos < self.len && self.chars[self.pos] == '>' {
                self.pos += 1
              }
            } else {
              self.pos += 1
            }
            tokens.push({ token_type: Redirect, from: start, to: self.pos })
          } else {
            tokens.push({ token_type: Number, from: start, to: self.pos })
          }
        } else if is_word_char(c) || c == '-' {
          // Word (command, argument, keyword)
          tokens.push(self.read_word())
          self.at_line_start = false
        } else {
          // Unknown
          let start = self.pos
          self.pos += 1
          tokens.push({ token_type: Error, from: start, to: self.pos })
        }
    }
  }
  tokens
}

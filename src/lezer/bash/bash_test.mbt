///|
/// Bash tokenizer and highlighter tests

// =============================================================================
// Basic Command Tests
// =============================================================================

test "tokenize: simple command" {
  let tokenizer = BashTokenizer::new("echo hello")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Command)
  assert_eq(tokens[1].token_type, Argument)
}

///|
test "tokenize: command with options" {
  let tokenizer = BashTokenizer::new("ls -la")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Command)
  assert_eq(tokens[1].token_type, Option)
}

///|
test "tokenize: command with long option" {
  let tokenizer = BashTokenizer::new("grep --color=auto")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Command)
  assert_eq(tokens[1].token_type, Option)
}

// =============================================================================
// Keyword Tests
// =============================================================================

///|
test "tokenize: if statement" {
  let tokenizer = BashTokenizer::new("if true; then echo yes; fi")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Keyword) // if
}

///|
test "tokenize: for loop" {
  let tokenizer = BashTokenizer::new("for i in 1 2 3; do echo $i; done")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Keyword) // for
}

///|
test "tokenize: while loop" {
  let tokenizer = BashTokenizer::new("while true; do sleep 1; done")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Keyword) // while
}

///|
test "tokenize: function keyword" {
  let tokenizer = BashTokenizer::new("function foo { echo bar; }")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Keyword) // function
}

// =============================================================================
// Variable Tests
// =============================================================================

///|
test "tokenize: simple variable" {
  let tokenizer = BashTokenizer::new("echo $HOME")
  let tokens = tokenizer.tokenize_all()
  let mut found_var = false
  for token in tokens {
    if token.token_type == Variable {
      found_var = true
      break
    }
  }
  assert_true(found_var)
}

///|
test "tokenize: braced variable" {
  let tokenizer = BashTokenizer::new("echo ${PATH}")
  let tokens = tokenizer.tokenize_all()
  let mut found_var = false
  for token in tokens {
    if token.token_type == Variable {
      found_var = true
      break
    }
  }
  assert_true(found_var)
}

///|
test "tokenize: special variables" {
  let tokenizer = BashTokenizer::new("echo $? $! $$ $@")
  let tokens = tokenizer.tokenize_all()
  let mut count = 0
  for token in tokens {
    if token.token_type == SpecialVar {
      count += 1
    }
  }
  assert_true(count >= 4)
}

///|
test "tokenize: positional parameters" {
  let tokenizer = BashTokenizer::new("echo $1 $2 $0")
  let tokens = tokenizer.tokenize_all()
  let mut count = 0
  for token in tokens {
    if token.token_type == SpecialVar {
      count += 1
    }
  }
  assert_true(count >= 3)
}

// =============================================================================
// String Tests
// =============================================================================

///|
test "tokenize: double quoted string" {
  let tokenizer = BashTokenizer::new("echo \"hello world\"")
  let tokens = tokenizer.tokenize_all()
  let mut found_string = false
  for token in tokens {
    if token.token_type == DoubleString {
      found_string = true
      break
    }
  }
  assert_true(found_string)
}

///|
test "tokenize: single quoted string" {
  let tokenizer = BashTokenizer::new("echo 'hello world'")
  let tokens = tokenizer.tokenize_all()
  let mut found_string = false
  for token in tokens {
    if token.token_type == SingleString {
      found_string = true
      break
    }
  }
  assert_true(found_string)
}

///|
test "tokenize: escaped characters in double quotes" {
  let tokenizer = BashTokenizer::new("echo \"hello\\nworld\"")
  let tokens = tokenizer.tokenize_all()
  let mut found_string = false
  for token in tokens {
    if token.token_type == DoubleString {
      found_string = true
      break
    }
  }
  assert_true(found_string)
}

// =============================================================================
// Operator Tests
// =============================================================================

///|
test "tokenize: pipe" {
  let tokenizer = BashTokenizer::new("cat file | grep pattern")
  let tokens = tokenizer.tokenize_all()
  let mut found_pipe = false
  for token in tokens {
    if token.token_type == Pipe {
      found_pipe = true
      break
    }
  }
  assert_true(found_pipe)
}

///|
test "tokenize: and operator" {
  let tokenizer = BashTokenizer::new("cmd1 && cmd2")
  let tokens = tokenizer.tokenize_all()
  let mut found_and = false
  for token in tokens {
    if token.token_type == And {
      found_and = true
      break
    }
  }
  assert_true(found_and)
}

///|
test "tokenize: or operator" {
  let tokenizer = BashTokenizer::new("cmd1 || cmd2")
  let tokens = tokenizer.tokenize_all()
  let mut found_or = false
  for token in tokens {
    if token.token_type == Or {
      found_or = true
      break
    }
  }
  assert_true(found_or)
}

///|
test "tokenize: redirect" {
  let tokenizer = BashTokenizer::new("echo hello > output.txt")
  let tokens = tokenizer.tokenize_all()
  let mut found_redirect = false
  for token in tokens {
    if token.token_type == Redirect {
      found_redirect = true
      break
    }
  }
  assert_true(found_redirect)
}

///|
test "tokenize: append redirect" {
  let tokenizer = BashTokenizer::new("echo hello >> output.txt")
  let tokens = tokenizer.tokenize_all()
  let mut found_redirect = false
  for token in tokens {
    if token.token_type == Redirect {
      found_redirect = true
      break
    }
  }
  assert_true(found_redirect)
}

///|
test "tokenize: stderr redirect" {
  let tokenizer = BashTokenizer::new("cmd 2>&1")
  let tokens = tokenizer.tokenize_all()
  let mut found_redirect = false
  for token in tokens {
    if token.token_type == Redirect {
      found_redirect = true
      break
    }
  }
  assert_true(found_redirect)
}

///|
test "tokenize: background" {
  let tokenizer = BashTokenizer::new("sleep 10 &")
  let tokens = tokenizer.tokenize_all()
  let mut found_bg = false
  for token in tokens {
    if token.token_type == Background {
      found_bg = true
      break
    }
  }
  assert_true(found_bg)
}

// =============================================================================
// Substitution Tests
// =============================================================================

///|
test "tokenize: command substitution" {
  let tokenizer = BashTokenizer::new("echo $(pwd)")
  let tokens = tokenizer.tokenize_all()
  let mut found_sub = false
  for token in tokens {
    if token.token_type == CommandSub {
      found_sub = true
      break
    }
  }
  assert_true(found_sub)
}

///|
test "tokenize: arithmetic expansion" {
  let tokenizer = BashTokenizer::new("echo $((1 + 2))")
  let tokens = tokenizer.tokenize_all()
  let mut found_arith = false
  for token in tokens {
    if token.token_type == ArithmeticExp {
      found_arith = true
      break
    }
  }
  assert_true(found_arith)
}

// =============================================================================
// Comment Tests
// =============================================================================

///|
test "tokenize: comment" {
  let tokenizer = BashTokenizer::new("# this is a comment")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Comment)
}

///|
test "tokenize: shebang" {
  let tokenizer = BashTokenizer::new("#!/bin/bash\necho hello")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Shebang)
}

///|
test "tokenize: inline comment" {
  let tokenizer = BashTokenizer::new("echo hello # comment")
  let tokens = tokenizer.tokenize_all()
  let mut found_comment = false
  for token in tokens {
    if token.token_type == Comment {
      found_comment = true
      break
    }
  }
  assert_true(found_comment)
}

// =============================================================================
// Complex Cases
// =============================================================================

///|
test "tokenize: pipeline" {
  let tokenizer = BashTokenizer::new("cat file | grep pattern | wc -l")
  let tokens = tokenizer.tokenize_all()
  let mut pipe_count = 0
  for token in tokens {
    if token.token_type == Pipe {
      pipe_count += 1
    }
  }
  assert_true(pipe_count >= 2)
}

///|
test "tokenize: variable assignment" {
  let tokenizer = BashTokenizer::new("NAME=value")
  let tokens = tokenizer.tokenize_all()
  let mut found_eq = false
  for token in tokens {
    if token.token_type == Equals {
      found_eq = true
      break
    }
  }
  assert_true(found_eq)
}

///|
test "tokenize: test brackets" {
  let tokenizer = BashTokenizer::new("[[ -f file ]]")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, DoubleBracket)
}

// =============================================================================
// Highlight Tests
// =============================================================================

///|
test "highlight: produces tokens" {
  let tokens = highlight_bash("echo hello")
  assert_true(tokens.length() >= 2)
}

///|
test "highlight: shebang highlighted" {
  let tokens = highlight_bash("#!/bin/bash")
  assert_eq(tokens.length(), 1)
}

///|
test "highlight: comment highlighted" {
  let tokens = highlight_bash("# comment")
  assert_eq(tokens.length(), 1)
}

// =============================================================================
// HTML Output Tests
// =============================================================================

///|
test "html_output: contains spans" {
  let html = highlight_bash_to_html("echo $HOME")
  assert_true(html.contains("<span"))
}

///|
test "html_output: handles empty input" {
  let html = highlight_bash_to_html("")
  assert_eq(html, "")
}

// =============================================================================
// Edge Cases
// =============================================================================

///|
test "edge: empty command" {
  let tokenizer = BashTokenizer::new("")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 0)
}

///|
test "edge: only whitespace" {
  let tokenizer = BashTokenizer::new("   \t  ")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 0)
}

///|
test "edge: unclosed double quote" {
  let tokenizer = BashTokenizer::new("echo \"unclosed")
  let tokens = tokenizer.tokenize_all()
  assert_true(tokens.length() >= 1)
}

///|
test "edge: unclosed single quote" {
  let tokenizer = BashTokenizer::new("echo 'unclosed")
  let tokens = tokenizer.tokenize_all()
  assert_true(tokens.length() >= 1)
}

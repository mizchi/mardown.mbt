///|
/// HTML tokenizer and highlighter tests

// =============================================================================
// Tokenizer Tests
// =============================================================================

test "tokenize: simple tag" {
  let tokenizer = HtmlTokenizer::new("<div>")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0].token_type, TagOpen)
  assert_eq(tokens[1].token_type, TagName)
  assert_eq(tokens[2].token_type, TagClose)
}

///|
test "tokenize: closing tag" {
  let tokenizer = HtmlTokenizer::new("</div>")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0].token_type, TagOpenEnd)
  assert_eq(tokens[1].token_type, TagName)
  assert_eq(tokens[2].token_type, TagClose)
}

///|
test "tokenize: self-closing tag" {
  let tokenizer = HtmlTokenizer::new("<br/>")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 3)
  assert_eq(tokens[0].token_type, TagOpen)
  assert_eq(tokens[1].token_type, TagName)
  assert_eq(tokens[2].token_type, TagSlashClose)
}

///|
test "tokenize: tag with attribute" {
  let tokenizer = HtmlTokenizer::new("<div class=\"container\">")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 6)
  assert_eq(tokens[0].token_type, TagOpen)
  assert_eq(tokens[1].token_type, TagName)
  assert_eq(tokens[2].token_type, AttrName)
  assert_eq(tokens[3].token_type, AttrEquals)
  assert_eq(tokens[4].token_type, AttrValue)
  assert_eq(tokens[5].token_type, TagClose)
}

///|
test "tokenize: multiple attributes" {
  let tokenizer = HtmlTokenizer::new(
    "<input type=\"text\" id=\"name\" disabled>",
  )
  let tokens = tokenizer.tokenize_all()

  // <input type="text" id="name" disabled>
  // TagOpen, TagName, AttrName, AttrEquals, AttrValue, AttrName, AttrEquals, AttrValue, AttrName, TagClose
  assert_eq(tokens[0].token_type, TagOpen)
  assert_eq(tokens[1].token_type, TagName)
  assert_eq(tokens[2].token_type, AttrName) // type
  assert_eq(tokens[3].token_type, AttrEquals)
  assert_eq(tokens[4].token_type, AttrValue) // "text"
  assert_eq(tokens[5].token_type, AttrName) // id
  assert_eq(tokens[6].token_type, AttrEquals)
  assert_eq(tokens[7].token_type, AttrValue) // "name"
  assert_eq(tokens[8].token_type, AttrName) // disabled (boolean attr)
}

///|
test "tokenize: single quoted attribute" {
  let tokenizer = HtmlTokenizer::new("<div class='container'>")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[4].token_type, AttrValue)
}

///|
test "tokenize: text content" {
  let tokenizer = HtmlTokenizer::new("<p>Hello World</p>")
  let tokens = tokenizer.tokenize_all()

  // <p>, p, >, Hello World, </p>, p, >
  assert_true(tokens.length() >= 4)

  // Find text token
  let mut found_text = false
  for token in tokens {
    if token.token_type == Text {
      found_text = true
      break
    }
  }
  assert_true(found_text)
}

///|
test "tokenize: comment" {
  let tokenizer = HtmlTokenizer::new("<!-- this is a comment -->")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, Comment)
}

///|
test "tokenize: doctype" {
  let tokenizer = HtmlTokenizer::new("<!DOCTYPE html>")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, Doctype)
}

///|
test "tokenize: cdata" {
  let tokenizer = HtmlTokenizer::new("<![CDATA[some content]]>")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, CData)
}

///|
test "tokenize: nested tags" {
  let tokenizer = HtmlTokenizer::new("<div><span>text</span></div>")
  let tokens = tokenizer.tokenize_all()
  assert_true(tokens.length() >= 10)
}

///|
test "tokenize: attribute without quotes" {
  let tokenizer = HtmlTokenizer::new("<input type=text>")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[4].token_type, AttrValue)
}

///|
test "tokenize: data attributes" {
  let tokenizer = HtmlTokenizer::new("<div data-id=\"123\" data-name=\"test\">")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[2].token_type, AttrName) // data-id
  assert_eq(tokens[5].token_type, AttrName) // data-name
}

///|
test "tokenize: empty tag" {
  let tokenizer = HtmlTokenizer::new("<>")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, TagOpen)
  assert_eq(tokens[1].token_type, TagClose)
}

///|
test "tokenize: tag with newlines" {
  let source =
    #|<div
    #|  class="foo"
    #|  id="bar"
    #|>
  let tokenizer = HtmlTokenizer::new(source)
  let tokens = tokenizer.tokenize_all()
  assert_true(tokens.length() >= 6)
}

// =============================================================================
// Highlight Tests
// =============================================================================

///|
test "highlight: simple div" {
  let tokens = highlight_html("<div>")
  assert_true(tokens.length() >= 2)
}

///|
test "highlight: with attributes" {
  let tokens = highlight_html("<div class=\"container\">")
  assert_true(tokens.length() >= 4)
}

///|
test "highlight: comment produces token" {
  let tokens = highlight_html("<!-- comment -->")
  assert_eq(tokens.length(), 1)
}

///|
test "highlight: doctype produces token" {
  let tokens = highlight_html("<!DOCTYPE html>")
  assert_eq(tokens.length(), 1)
}

// =============================================================================
// HTML Output Tests
// =============================================================================

///|
test "html_output: contains spans" {
  let html = highlight_html_to_html("<div class=\"test\">Hello</div>")
  assert_true(html.contains("<span"))
}

///|
test "html_output: escapes angle brackets" {
  let html = highlight_html_to_html("<div>")

  // The < and > in the source should be escaped
  assert_true(html.contains("&lt;") || html.contains("&gt;"))
}

///|
test "html_output: handles empty input" {
  let html = highlight_html_to_html("")
  assert_eq(html, "")
}

// =============================================================================
// Edge Cases
// =============================================================================

///|
test "edge: unclosed tag" {
  let tokenizer = HtmlTokenizer::new("<div")
  let tokens = tokenizer.tokenize_all()
  assert_true(tokens.length() >= 1)
}

///|
test "edge: unclosed comment" {
  let tokenizer = HtmlTokenizer::new("<!-- unclosed")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens.length(), 1)
  assert_eq(tokens[0].token_type, Comment)
}

///|
test "edge: unclosed attribute value" {
  let tokenizer = HtmlTokenizer::new("<div class=\"unclosed>")
  let tokens = tokenizer.tokenize_all()
  assert_true(tokens.length() >= 1)
}

///|
test "edge: script tag content" {
  let tokenizer = HtmlTokenizer::new("<script>const x = 1;</script>")
  let tokens = tokenizer.tokenize_all()
  assert_true(tokens.length() >= 1)
}

///|
test "edge: style tag content" {
  let tokenizer = HtmlTokenizer::new("<style>.foo { color: red; }</style>")
  let tokens = tokenizer.tokenize_all()
  assert_true(tokens.length() >= 1)
}

///|
test "edge: namespaced tag" {
  let tokenizer = HtmlTokenizer::new("<svg:rect/>")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[1].token_type, TagName)
}

///|
test "edge: uppercase tag" {
  let tokenizer = HtmlTokenizer::new("<DIV></DIV>")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[1].token_type, TagName)
  assert_eq(tokens[4].token_type, TagName)
}

///|
test "edge: mixed case doctype" {
  let tokenizer = HtmlTokenizer::new("<!doctype html>")
  let tokens = tokenizer.tokenize_all()
  assert_eq(tokens[0].token_type, Doctype)
}

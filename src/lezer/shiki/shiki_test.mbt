///| Shiki HTML generation tests

// =============================================================================
// Theme Tests
// =============================================================================

test "theme: github_dark has correct name" {
  let theme = github_dark()
  assert_eq!(theme.name, "github-dark")
}

test "theme: github_light has correct name" {
  let theme = github_light()
  assert_eq!(theme.name, "github-light")
}

test "theme: one_dark_pro has correct name" {
  let theme = one_dark_pro()
  assert_eq!(theme.name, "one-dark-pro")
}

test "theme: vitesse_dark has correct name" {
  let theme = vitesse_dark()
  assert_eq!(theme.name, "vitesse-dark")
}

test "theme: get_color returns correct color for keyword" {
  let theme = github_dark()
  let color = theme.get_color(@lezer.Keyword)
  assert_eq!(color, "#ff7b72")
}

test "theme: get_color returns correct color for string" {
  let theme = github_dark()
  let color = theme.get_color(@lezer.String)
  assert_eq!(color, "#a5d6ff")
}

test "theme: get_color returns correct color for number" {
  let theme = github_dark()
  let color = theme.get_color(@lezer.Number)
  assert_eq!(color, "#79c0ff")
}

test "theme: get_color returns correct color for comment" {
  let theme = github_dark()
  let color = theme.get_color(@lezer.Comment)
  assert_eq!(color, "#8b949e")
}

test "theme: get_color returns correct color for type" {
  let theme = github_dark()
  let color = theme.get_color(@lezer.TypeName)
  assert_eq!(color, "#ffa657")
}

test "theme: get_color returns correct color for function" {
  let theme = github_dark()
  let color = theme.get_color(@lezer.FunctionName)
  assert_eq!(color, "#d2a8ff")
}

test "theme: get_color returns foreground for None tag" {
  let theme = github_dark()
  let color = theme.get_color(@lezer.None)
  assert_eq!(color, "#c9d1d9")
}

test "theme: github_light has white background" {
  let theme = github_light()
  assert_eq!(theme.background, "#ffffff")
}

test "theme: one_dark_pro has correct background" {
  let theme = one_dark_pro()
  assert_eq!(theme.background, "#282c34")
}

test "theme: vitesse_dark has correct background" {
  let theme = vitesse_dark()
  assert_eq!(theme.background, "#121212")
}

// =============================================================================
// HTML Output Tests
// =============================================================================

test "shiki: simple JavaScript produces valid HTML" {
  let source = "const x = 42;"
  let html = highlight_typescript_shiki(source, github_dark())

  // Check for shiki class
  assert_true!(html.contains("<pre class=\"shiki github-dark\""))

  // Check for background color
  assert_true!(html.contains("background-color: #0d1117"))

  // Check for code tag
  assert_true!(html.contains("<code>"))
  assert_true!(html.contains("</code></pre>"))

  // Check for line span
  assert_true!(html.contains("<span class=\"line\">"))
}

test "shiki: multiline code produces multiple lines" {
  let source =
    #|const a = 1;
    #|const b = 2;
  let html = highlight_typescript_shiki(source, github_dark())

  // Should have multiple line spans
  let line_count = count_occurrences(html, "<span class=\"line\">")
  assert_true!(line_count >= 2)
}

test "shiki: MoonBit code highlights correctly" {
  let source = "fn main() -> Int { 42 }"
  let html = highlight_moonbit_shiki(source, github_dark())

  // Check for shiki structure
  assert_true!(html.contains("<pre class=\"shiki"))
  assert_true!(html.contains("<code>"))
  assert_true!(html.contains("<span class=\"line\">"))
}

test "shiki: JSON highlights correctly" {
  let source = "{\"key\": 123}"
  let html = highlight_json_shiki(source, github_dark())

  // Check for shiki structure
  assert_true!(html.contains("<pre class=\"shiki"))
  assert_true!(html.contains("<code>"))
}

test "shiki: different themes produce different colors" {
  let source = "const x = 42;"
  let dark = highlight_typescript_shiki(source, github_dark())
  let light = highlight_typescript_shiki(source, github_light())

  // Background colors should be different
  assert_true!(dark.contains("#0d1117"))
  assert_true!(light.contains("#ffffff"))
}

test "shiki: HTML special chars are escaped" {
  let source = "const x = '<div>';"
  let html = highlight_typescript_shiki(source, github_dark())

  // < and > should be escaped
  assert_true!(html.contains("&lt;"))
  assert_true!(html.contains("&gt;"))

  // Raw < and > should not appear in the token content
  assert_false!(html.contains(">'<"))
}

test "shiki: empty source produces valid HTML" {
  let source = ""
  let html = highlight_typescript_shiki(source, github_dark())

  // Should still have valid structure
  assert_true!(html.contains("<pre class=\"shiki"))
  assert_true!(html.contains("</code></pre>"))
}

test "shiki: token colors are applied" {
  let source = "const x = 42;"
  let html = highlight_typescript_shiki(source, github_dark())

  // Should have colored spans
  assert_true!(html.contains("style=\"color:"))
}

// =============================================================================
// TypeScript-specific Tests
// =============================================================================

test "shiki/ts: function declaration" {
  let source = "function greet(name: string): void {}"
  let html = highlight_typescript_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
  assert_true!(html.contains("<span class=\"line\">"))
}

test "shiki/ts: arrow function" {
  let source = "const add = (a: number, b: number) => a + b;"
  let html = highlight_typescript_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
}

test "shiki/ts: class declaration" {
  let source =
    #|class Person {
    #|  name: string;
    #|  constructor(name: string) {
    #|    this.name = name;
    #|  }
    #|}
  let html = highlight_typescript_shiki(source, github_dark())

  let line_count = count_occurrences(html, "<span class=\"line\">")
  assert_true!(line_count >= 5)
}

test "shiki/ts: template literal" {
  let source = "const msg = `Hello, ${name}!`;"
  let html = highlight_typescript_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
}

test "shiki/ts: JSX element" {
  let source = "const el = <div className=\"container\">Hello</div>;"
  let html = highlight_typescript_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
  // < should be escaped in the output
  assert_true!(html.contains("&lt;"))
}

test "shiki/ts: import statement" {
  let source = "import { useState } from 'react';"
  let html = highlight_typescript_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
}

test "shiki/ts: async/await" {
  let source = "async function fetch() { await getData(); }"
  let html = highlight_typescript_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
}

// =============================================================================
// MoonBit-specific Tests
// =============================================================================

test "shiki/mbt: function definition" {
  let source = "fn add(a : Int, b : Int) -> Int { a + b }"
  let html = highlight_moonbit_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
  assert_true!(html.contains("<span class=\"line\">"))
}

test "shiki/mbt: struct definition" {
  let source =
    #|struct Point {
    #|  x : Int
    #|  y : Int
    #|}
  let html = highlight_moonbit_shiki(source, github_dark())

  let line_count = count_occurrences(html, "<span class=\"line\">")
  assert_true!(line_count >= 4)
}

test "shiki/mbt: enum definition" {
  let source =
    #|enum Option[T] {
    #|  Some(T)
    #|  None
    #|}
  let html = highlight_moonbit_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
}

test "shiki/mbt: pattern matching" {
  let source =
    #|match x {
    #|  Some(v) => v
    #|  None => 0
    #|}
  let html = highlight_moonbit_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
}

test "shiki/mbt: string interpolation" {
  let source = "let msg = \"value: \\{x}\""
  let html = highlight_moonbit_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
}

test "shiki/mbt: raw string" {
  let source =
    #|let code =
    #|  #|fn main() {
    #|  #|  println("Hello")
    #|  #|}
  let html = highlight_moonbit_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
}

test "shiki/mbt: doc comment" {
  let source =
    #|///| This is a doc comment
    #|fn documented() -> Unit {}
  let html = highlight_moonbit_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
}

test "shiki/mbt: type annotation" {
  let source = "let x : Array[Int] = []"
  let html = highlight_moonbit_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
}

// =============================================================================
// JSON-specific Tests
// =============================================================================

test "shiki/json: simple object" {
  let source = "{\"name\": \"Alice\", \"age\": 30}"
  let html = highlight_json_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
}

test "shiki/json: nested object" {
  let source =
    #|{
    #|  "person": {
    #|    "name": "Bob",
    #|    "address": {
    #|      "city": "Tokyo"
    #|    }
    #|  }
    #|}
  let html = highlight_json_shiki(source, github_dark())

  let line_count = count_occurrences(html, "<span class=\"line\">")
  assert_true!(line_count >= 7)
}

test "shiki/json: array" {
  let source = "[1, 2, 3, \"four\", true, null]"
  let html = highlight_json_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
}

test "shiki/json: boolean and null" {
  let source = "{\"active\": true, \"deleted\": false, \"data\": null}"
  let html = highlight_json_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
}

// =============================================================================
// Edge Cases
// =============================================================================

test "shiki: single character" {
  let source = "x"
  let html = highlight_typescript_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
  assert_true!(html.contains("</code></pre>"))
}

test "shiki: only whitespace" {
  let source = "   "
  let html = highlight_typescript_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
}

test "shiki: only newlines" {
  let source = "\n\n\n"
  let html = highlight_typescript_shiki(source, github_dark())

  let line_count = count_occurrences(html, "<span class=\"line\">")
  assert_true!(line_count >= 3)
}

test "shiki: ampersand escaping" {
  let source = "const x = 'a & b';"
  let html = highlight_typescript_shiki(source, github_dark())

  assert_true!(html.contains("&amp;"))
}

test "shiki: quote escaping" {
  let source = "const x = \"he said \\\"hello\\\"\";"
  let html = highlight_typescript_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
}

test "shiki: very long line" {
  let mut source = "const x = \""
  for i = 0; i < 100; i = i + 1 {
    source = source + "a"
  }
  source = source + "\";"
  let html = highlight_typescript_shiki(source, github_dark())

  assert_true!(html.contains("<pre class=\"shiki"))
  assert_true!(html.contains("</code></pre>"))
}

test "shiki: unicode characters" {
  let source = "const greeting = \"こんにちは世界\";"
  let html = highlight_typescript_shiki(source, github_dark())

  assert_true!(html.contains("こんにちは世界"))
}

test "shiki: emoji" {
  let source = "const emoji = \"🎉🚀\";"
  let html = highlight_typescript_shiki(source, github_dark())

  assert_true!(html.contains("🎉🚀"))
}

// =============================================================================
// Theme Comparison Tests
// =============================================================================

test "shiki: all themes produce valid HTML" {
  let source = "const x = 42;"

  let themes = [github_dark(), github_light(), one_dark_pro(), vitesse_dark()]

  for theme in themes {
    let html = highlight_typescript_shiki(source, theme)
    assert_true!(html.contains("<pre class=\"shiki"))
    assert_true!(html.contains("</code></pre>"))
  }
}

test "shiki: theme name appears in class" {
  let source = "let x = 1"

  assert_true!(
    highlight_moonbit_shiki(source, github_dark()).contains("github-dark"),
  )
  assert_true!(
    highlight_moonbit_shiki(source, github_light()).contains("github-light"),
  )
  assert_true!(
    highlight_moonbit_shiki(source, one_dark_pro()).contains("one-dark-pro"),
  )
  assert_true!(
    highlight_moonbit_shiki(source, vitesse_dark()).contains("vitesse-dark"),
  )
}

// =============================================================================
// Helper Functions
// =============================================================================

fn count_occurrences(s : String, pattern : String) -> Int {
  let mut count = 0
  let mut pos = 0
  let chars = s.to_array()
  let pattern_chars = pattern.to_array()
  let len = chars.length()
  let pattern_len = pattern_chars.length()

  while pos + pattern_len <= len {
    let mut matches = true
    for i = 0; i < pattern_len; i = i + 1 {
      if chars[pos + i] != pattern_chars[i] {
        matches = false
        break
      }
    }
    if matches {
      count = count + 1
      pos = pos + pattern_len
    } else {
      pos = pos + 1
    }
  }
  count
}

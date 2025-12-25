///| Lezer parser benchmarks
///|
///| Run with: moon bench --target js -p mizchi/markdown/lezer

// =============================================================================
// Test Data Generation
// =============================================================================

///| Generate a simple JSON object
fn generate_simple_json() -> String {
  "{\"name\": \"test\", \"value\": 42}"
}

///| Generate a nested JSON object
fn generate_nested_json(depth : Int) -> String {
  let buf = StringBuilder::new()
  for _i = 0; _i < depth; _i = _i + 1 {
    buf.write_string("{\"nested\": ")
  }
  buf.write_string("1")
  for _i = 0; _i < depth; _i = _i + 1 {
    buf.write_string("}")
  }
  buf.to_string()
}

///| Generate a JSON array with numbers
fn generate_json_array(size : Int) -> String {
  let buf = StringBuilder::new()
  buf.write_string("[")
  for i = 0; i < size; i = i + 1 {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string(i.to_string())
  }
  buf.write_string("]")
  buf.to_string()
}

///| Generate a JSON object with many properties
fn generate_json_object(props : Int) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{")
  for i = 0; i < props; i = i + 1 {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string("\"prop")
    buf.write_string(i.to_string())
    buf.write_string("\": ")
    buf.write_string(i.to_string())
  }
  buf.write_string("}")
  buf.to_string()
}

///| Generate a complex JSON document
fn generate_complex_json(size : Int) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\"items\": [")
  for i = 0; i < size; i = i + 1 {
    if i > 0 {
      buf.write_string(", ")
    }
    buf.write_string("{\"id\": ")
    buf.write_string(i.to_string())
    buf.write_string(", \"name\": \"item")
    buf.write_string(i.to_string())
    buf.write_string("\", \"active\": ")
    buf.write_string(if i % 2 == 0 { "true" } else { "false" })
    buf.write_string(", \"tags\": [\"a\", \"b\", \"c\"]}")
  }
  buf.write_string("]}")
  buf.to_string()
}

// Pre-generate test data

///|
let json_simple : String = generate_simple_json()

///|
let json_nested_5 : String = generate_nested_json(5)

///|
let json_nested_10 : String = generate_nested_json(10)

///|
let json_nested_20 : String = generate_nested_json(20)

///|
let json_array_10 : String = generate_json_array(10)

///|
let json_array_100 : String = generate_json_array(100)

///|
let json_array_1000 : String = generate_json_array(1000)

///|
let json_object_10 : String = generate_json_object(10)

///|
let json_object_50 : String = generate_json_object(50)

///|
let json_object_100 : String = generate_json_object(100)

///|
let json_complex_10 : String = generate_complex_json(10)

///|
let json_complex_50 : String = generate_complex_json(50)

///|
let json_complex_100 : String = generate_complex_json(100)

// =============================================================================
// Tokenizer Benchmarks
// =============================================================================

///|
test "tokenize: simple object" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = JsonTokenizer::new(json_simple)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

///|
test "tokenize: array 100 elements" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = JsonTokenizer::new(json_array_100)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

///|
test "tokenize: array 1000 elements" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = JsonTokenizer::new(json_array_1000)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

///|
test "tokenize: object 50 properties" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = JsonTokenizer::new(json_object_50)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

///|
test "tokenize: complex 50 items" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = JsonTokenizer::new(json_complex_50)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

// =============================================================================
// Parser Benchmarks
// =============================================================================

///|
test "parse: simple object" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_json(json_simple)
    b.keep(result)
  })
}

///|
test "parse: nested depth 5" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_json(json_nested_5)
    b.keep(result)
  })
}

///|
test "parse: nested depth 10" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_json(json_nested_10)
    b.keep(result)
  })
}

///|
test "parse: nested depth 20" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_json(json_nested_20)
    b.keep(result)
  })
}

///|
test "parse: array 10 elements" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_json(json_array_10)
    b.keep(result)
  })
}

///|
test "parse: array 100 elements" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_json(json_array_100)
    b.keep(result)
  })
}

///|
test "parse: array 1000 elements" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_json(json_array_1000)
    b.keep(result)
  })
}

///|
test "parse: object 10 properties" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_json(json_object_10)
    b.keep(result)
  })
}

///|
test "parse: object 50 properties" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_json(json_object_50)
    b.keep(result)
  })
}

///|
test "parse: object 100 properties" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_json(json_object_100)
    b.keep(result)
  })
}

///|
test "parse: complex 10 items" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_json(json_complex_10)
    b.keep(result)
  })
}

///|
test "parse: complex 50 items" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_json(json_complex_50)
    b.keep(result)
  })
}

///|
test "parse: complex 100 items" (b : @bench.T) {
  b.bench(fn() {
    let result = parse_json(json_complex_100)
    b.keep(result)
  })
}

// =============================================================================
// Tree Operations Benchmarks
// =============================================================================

// Pre-parse trees for tree operation benchmarks

///|
let tree_complex_50 : Tree? = parse_json(json_complex_50)

///|
let tree_complex_100 : Tree? = parse_json(json_complex_100)

///|
test "tree: iterate 50 items" (b : @bench.T) {
  let tree = tree_complex_50.unwrap()
  b.bench(fn() {
    let mut count = 0
    for _node in tree.iter() {
      count += 1
    }
    b.keep(count)
  })
}

///|
test "tree: iterate 100 items" (b : @bench.T) {
  let tree = tree_complex_100.unwrap()
  b.bench(fn() {
    let mut count = 0
    for _node in tree.iter() {
      count += 1
    }
    b.keep(count)
  })
}

///|
test "tree: resolve 100 positions" (b : @bench.T) {
  let tree = tree_complex_50.unwrap()
  let len = tree.to()
  b.bench(fn() {
    let mut found = 0
    for i = 0; i < 100; i = i + 1 {
      let pos = (i * len) / 100
      match tree.resolve(pos) {
        Some(_) => found += 1
        None => ()
      }
    }
    b.keep(found)
  })
}

///|
test "tree: cursor traversal 50 items" (b : @bench.T) {
  let tree = tree_complex_50.unwrap()
  b.bench(fn() {
    let cursor = TreeCursor::new(tree)
    let mut count = 0
    fn traverse(c : TreeCursor) -> Int {
      let mut n = 1
      if c.first_child() {
        n += traverse(c)
        while c.next_sibling() {
          n += traverse(c)
        }
        let _ = c.parent()
      }
      n
    }
    count = traverse(cursor)
    b.keep(count)
  })
}

// =============================================================================
// Highlight Benchmarks
// =============================================================================

///|
test "highlight: simple object" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_json(json_simple)
    b.keep(result)
  })
}

///|
test "highlight: object 50 properties" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_json(json_object_50)
    b.keep(result)
  })
}

///|
test "highlight: complex 50 items" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_json(json_complex_50)
    b.keep(result)
  })
}

///|
test "highlight: complex 100 items" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_json(json_complex_100)
    b.keep(result)
  })
}

// =============================================================================
// HTML Generation Benchmarks
// =============================================================================

// Pre-generate highlight tokens for HTML benchmarks

///|
let tokens_simple : Array[HighlightToken] = highlight_json(json_simple)

///|
let tokens_object_50 : Array[HighlightToken] = highlight_json(json_object_50)

///|
let tokens_complex_50 : Array[HighlightToken] = highlight_json(json_complex_50)

///|
test "html: simple object" (b : @bench.T) {
  b.bench(fn() {
    let result = tokens_to_html(json_simple, tokens_simple)
    b.keep(result)
  })
}

///|
test "html: object 50 properties" (b : @bench.T) {
  b.bench(fn() {
    let result = tokens_to_html(json_object_50, tokens_object_50)
    b.keep(result)
  })
}

///|
test "html: complex 50 items" (b : @bench.T) {
  b.bench(fn() {
    let result = tokens_to_html(json_complex_50, tokens_complex_50)
    b.keep(result)
  })
}

// =============================================================================
// End-to-end Benchmarks (parse + highlight + html)
// =============================================================================

///|
test "e2e: simple object" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_json_to_html(json_simple)
    b.keep(result)
  })
}

///|
test "e2e: object 50 properties" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_json_to_html(json_object_50)
    b.keep(result)
  })
}

///|
test "e2e: complex 50 items" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_json_to_html(json_complex_50)
    b.keep(result)
  })
}

///|
test "e2e: complex 100 items" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_json_to_html(json_complex_100)
    b.keep(result)
  })
}

// =============================================================================
// TreeBuffer Benchmarks
// =============================================================================

///|
test "treebuffer: push 100 leaves" (b : @bench.T) {
  let types = [NodeType::new(1, "A"), NodeType::new(2, "B")]
  b.bench(fn() {
    let buffer = TreeBuffer::new(types)
    for i = 0; i < 100; i = i + 1 {
      buffer.push_leaf((i % 2) + 1, i * 10, (i + 1) * 10)
    }
    b.keep(buffer)
  })
}

///|
test "treebuffer: push 1000 leaves" (b : @bench.T) {
  let types = [NodeType::new(1, "A"), NodeType::new(2, "B")]
  b.bench(fn() {
    let buffer = TreeBuffer::new(types)
    for i = 0; i < 1000; i = i + 1 {
      buffer.push_leaf((i % 2) + 1, i * 10, (i + 1) * 10)
    }
    b.keep(buffer)
  })
}

///|
test "treebuffer: lookup 100x" (b : @bench.T) {
  let types = [NodeType::new(1, "A"), NodeType::new(2, "B")]
  let buffer = TreeBuffer::new(types)
  for i = 0; i < 100; i = i + 1 {
    buffer.push_leaf((i % 2) + 1, i * 10, (i + 1) * 10)
  }
  b.bench(fn() {
    let mut found = 0
    for i = 0; i < 100; i = i + 1 {
      match buffer.get_node(i) {
        Some(_) => found += 1
        None => ()
      }
    }
    b.keep(found)
  })
}

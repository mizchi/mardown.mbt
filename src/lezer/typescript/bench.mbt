///| TypeScript tokenizer benchmarks

// =============================================================================
// Test Data Generation
// =============================================================================

///| Generate simple TypeScript code
fn generate_simple_ts() -> String {
  "const x = 42;"
}

///| Generate function with body
fn generate_function_ts() -> String {
  #|function fibonacci(n: number): number {
  #|  if (n <= 1) return n;
  #|  return fibonacci(n - 1) + fibonacci(n - 2);
  #|}
}

///| Generate class with methods
fn generate_class_ts(methods : Int) -> String {
  let buf = StringBuilder::new()
  buf.write_string("class MyClass {\n")
  for i = 0; i < methods; i = i + 1 {
    buf.write_string("  method")
    buf.write_string(i.to_string())
    buf.write_string("(x: number): string {\n")
    buf.write_string("    return `value: ${x}`;\n")
    buf.write_string("  }\n")
  }
  buf.write_string("}")
  buf.to_string()
}

///| Generate JSX component
fn generate_jsx_ts(elements : Int) -> String {
  let buf = StringBuilder::new()
  buf.write_string("const App = () => {\n")
  buf.write_string("  return (\n")
  buf.write_string("    <div>\n")
  for i = 0; i < elements; i = i + 1 {
    buf.write_string("      <span className=\"item-")
    buf.write_string(i.to_string())
    buf.write_string("\">Item ")
    buf.write_string(i.to_string())
    buf.write_string("</span>\n")
  }
  buf.write_string("    </div>\n")
  buf.write_string("  );\n")
  buf.write_string("};")
  buf.to_string()
}

///| Generate imports
fn generate_imports_ts(count : Int) -> String {
  let buf = StringBuilder::new()
  for i = 0; i < count; i = i + 1 {
    buf.write_string("import { Module")
    buf.write_string(i.to_string())
    buf.write_string(" } from 'package")
    buf.write_string(i.to_string())
    buf.write_string("';\n")
  }
  buf.to_string()
}

// Pre-generate test data
let ts_simple : String = generate_simple_ts()
let ts_function : String = generate_function_ts()
let ts_class_10 : String = generate_class_ts(10)
let ts_class_50 : String = generate_class_ts(50)
let ts_jsx_10 : String = generate_jsx_ts(10)
let ts_jsx_50 : String = generate_jsx_ts(50)
let ts_imports_20 : String = generate_imports_ts(20)
let ts_imports_100 : String = generate_imports_ts(100)

// =============================================================================
// Tokenizer Benchmarks
// =============================================================================

test "tokenize: simple" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = TsTokenizer::new(ts_simple)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

test "tokenize: function" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = TsTokenizer::new(ts_function)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

test "tokenize: class 10 methods" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = TsTokenizer::new(ts_class_10)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

test "tokenize: class 50 methods" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = TsTokenizer::new(ts_class_50)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

test "tokenize: jsx 10 elements" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = TsTokenizer::new(ts_jsx_10)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

test "tokenize: jsx 50 elements" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = TsTokenizer::new(ts_jsx_50)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

test "tokenize: imports 20" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = TsTokenizer::new(ts_imports_20)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

test "tokenize: imports 100" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = TsTokenizer::new(ts_imports_100)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

// =============================================================================
// Highlight Benchmarks
// =============================================================================

test "highlight: simple" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_typescript(ts_simple)
    b.keep(result)
  })
}

test "highlight: function" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_typescript(ts_function)
    b.keep(result)
  })
}

test "highlight: class 10 methods" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_typescript(ts_class_10)
    b.keep(result)
  })
}

test "highlight: class 50 methods" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_typescript(ts_class_50)
    b.keep(result)
  })
}

test "highlight: jsx 10 elements" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_typescript(ts_jsx_10)
    b.keep(result)
  })
}

test "highlight: jsx 50 elements" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_typescript(ts_jsx_50)
    b.keep(result)
  })
}

// =============================================================================
// End-to-end Benchmarks
// =============================================================================

test "e2e: simple" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_typescript_to_html(ts_simple)
    b.keep(result)
  })
}

test "e2e: function" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_typescript_to_html(ts_function)
    b.keep(result)
  })
}

test "e2e: class 50 methods" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_typescript_to_html(ts_class_50)
    b.keep(result)
  })
}

test "e2e: jsx 50 elements" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_typescript_to_html(ts_jsx_50)
    b.keep(result)
  })
}

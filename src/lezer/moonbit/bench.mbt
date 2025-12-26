///| MoonBit tokenizer benchmarks

// =============================================================================
// Test Data Generation
// =============================================================================

///|
/// Generate simple MoonBit code
fn generate_simple_mbt() -> String {
  "let x = 42"
}

///|
/// Generate function with body
fn generate_function_mbt() -> String {
  let s =
    #|fn fibonacci(n : Int) -> Int {
    #|  if n <= 1 {
    #|    n
    #|  } else {
    #|    fibonacci(n - 1) + fibonacci(n - 2)
    #|  }
    #|}
  s
}

///|
/// Generate struct with fields
fn generate_struct_mbt(fields : Int) -> String {
  let buf = StringBuilder::new()
  buf.write_string("struct MyStruct {\n")
  for i = 0; i < fields; i = i + 1 {
    buf.write_string("  field")
    buf.write_string(i.to_string())
    buf.write_string(" : Int\n")
  }
  buf.write_string("}")
  buf.to_string()
}

///|
/// Generate enum with variants
fn generate_enum_mbt(variants : Int) -> String {
  let buf = StringBuilder::new()
  buf.write_string("enum MyEnum {\n")
  for i = 0; i < variants; i = i + 1 {
    buf.write_string("  Variant")
    buf.write_string(i.to_string())
    buf.write_string("(Int, String)\n")
  }
  buf.write_string("}")
  buf.to_string()
}

///|
/// Generate functions with string interpolation
fn generate_interp_mbt(count : Int) -> String {
  let buf = StringBuilder::new()
  for i = 0; i < count; i = i + 1 {
    buf.write_string("let s")
    buf.write_string(i.to_string())
    buf.write_string(" = \"value: \\{x")
    buf.write_string(i.to_string())
    buf.write_string("}\"\n")
  }
  buf.to_string()
}

///|
/// Generate imports
fn generate_imports_mbt(count : Int) -> String {
  let buf = StringBuilder::new()
  for i = 0; i < count; i = i + 1 {
    buf.write_string("///| Doc comment ")
    buf.write_string(i.to_string())
    buf.write_string("\n")
    buf.write_string("fn func")
    buf.write_string(i.to_string())
    buf.write_string("(x : Int) -> Int { x + 1 }\n")
  }
  buf.to_string()
}

///|
/// Generate raw strings
fn generate_raw_strings_mbt(lines : Int) -> String {
  let buf = StringBuilder::new()
  buf.write_string("let code =\n")
  for i = 0; i < lines; i = i + 1 {
    buf.write_string("  #|line ")
    buf.write_string(i.to_string())
    buf.write_string(" content here\n")
  }
  buf.to_string()
}

// Pre-generate test data

///|
let mbt_simple : String = generate_simple_mbt()

///|
let mbt_function : String = generate_function_mbt()

///|
let mbt_struct_10 : String = generate_struct_mbt(10)

///|
let mbt_struct_50 : String = generate_struct_mbt(50)

///|
let mbt_enum_10 : String = generate_enum_mbt(10)

///|
let mbt_enum_50 : String = generate_enum_mbt(50)

///|
let mbt_interp_10 : String = generate_interp_mbt(10)

///|
let mbt_interp_50 : String = generate_interp_mbt(50)

///|
let mbt_funcs_20 : String = generate_imports_mbt(20)

///|
let mbt_funcs_100 : String = generate_imports_mbt(100)

///|
let mbt_raw_20 : String = generate_raw_strings_mbt(20)

///|
let mbt_raw_100 : String = generate_raw_strings_mbt(100)

// =============================================================================
// Tokenizer Benchmarks
// =============================================================================

///|
test "tokenize: simple" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = MbtTokenizer::new(mbt_simple)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

///|
test "tokenize: function" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = MbtTokenizer::new(mbt_function)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

///|
test "tokenize: struct 10 fields" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = MbtTokenizer::new(mbt_struct_10)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

///|
test "tokenize: struct 50 fields" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = MbtTokenizer::new(mbt_struct_50)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

///|
test "tokenize: enum 10 variants" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = MbtTokenizer::new(mbt_enum_10)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

///|
test "tokenize: enum 50 variants" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = MbtTokenizer::new(mbt_enum_50)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

///|
test "tokenize: interp 10 strings" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = MbtTokenizer::new(mbt_interp_10)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

///|
test "tokenize: interp 50 strings" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = MbtTokenizer::new(mbt_interp_50)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

///|
test "tokenize: funcs 20" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = MbtTokenizer::new(mbt_funcs_20)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

///|
test "tokenize: funcs 100" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = MbtTokenizer::new(mbt_funcs_100)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

///|
test "tokenize: raw 20 lines" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = MbtTokenizer::new(mbt_raw_20)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

///|
test "tokenize: raw 100 lines" (b : @bench.T) {
  b.bench(fn() {
    let tokenizer = MbtTokenizer::new(mbt_raw_100)
    let result = tokenizer.tokenize_all()
    b.keep(result)
  })
}

// =============================================================================
// Highlight Benchmarks
// =============================================================================

///|
test "highlight: simple" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_moonbit(mbt_simple)
    b.keep(result)
  })
}

///|
test "highlight: function" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_moonbit(mbt_function)
    b.keep(result)
  })
}

///|
test "highlight: struct 50 fields" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_moonbit(mbt_struct_50)
    b.keep(result)
  })
}

///|
test "highlight: enum 50 variants" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_moonbit(mbt_enum_50)
    b.keep(result)
  })
}

///|
test "highlight: interp 50 strings" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_moonbit(mbt_interp_50)
    b.keep(result)
  })
}

///|
test "highlight: funcs 100" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_moonbit(mbt_funcs_100)
    b.keep(result)
  })
}

// =============================================================================
// End-to-end Benchmarks
// =============================================================================

///|
test "e2e: simple" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_moonbit_to_html(mbt_simple)
    b.keep(result)
  })
}

///|
test "e2e: function" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_moonbit_to_html(mbt_function)
    b.keep(result)
  })
}

///|
test "e2e: struct 50 fields" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_moonbit_to_html(mbt_struct_50)
    b.keep(result)
  })
}

///|
test "e2e: funcs 100" (b : @bench.T) {
  b.bench(fn() {
    let result = highlight_moonbit_to_html(mbt_funcs_100)
    b.keep(result)
  })
}

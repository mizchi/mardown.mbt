///|
test "generate_heading_id: basic" {
  inspect(generate_heading_id("Hello World"), content="hello-world")
}

///|
test "generate_heading_id: with numbers" {
  inspect(generate_heading_id("Section 1"), content="section-1")
}

///|
test "generate_heading_id: multiple spaces" {
  inspect(generate_heading_id("Hello   World"), content="hello-world")
}

///|
test "generate_heading_id: special characters" {
  inspect(generate_heading_id("Hello! World?"), content="hello-world")
}

///|
test "generate_heading_id: japanese" {
  inspect(
    generate_heading_id("日本語タイトル"),
    content="日本語タイトル",
  )
}

///|
test "generate_heading_id: mixed" {
  inspect(
    generate_heading_id("API リファレンス"),
    content="api-リファレンス",
  )
}

///|
test "generate_heading_id: trailing space" {
  inspect(generate_heading_id("Hello "), content="hello")
}

///|
test "generate_heading_id: underscore" {
  inspect(generate_heading_id("hello_world"), content="hello-world")
}

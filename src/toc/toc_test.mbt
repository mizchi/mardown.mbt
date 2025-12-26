///|
fn make_heading(level : Int, text : String) -> @md.Block {
  @md.Block::Heading(
    level~,
    style=@md.HeadingStyle::Atx,
    children=[@md.Inline::Text(content=text, span=@md.Span::empty())],
    closing_hashes=0,
    span=@md.Span::empty(),
    leading_trivia=@md.Trivia::empty(),
    trailing_trivia=@md.Trivia::empty(),
  )
}

///|
fn make_paragraph(text : String) -> @md.Block {
  @md.Block::Paragraph(
    children=[@md.Inline::Text(content=text, span=@md.Span::empty())],
    span=@md.Span::empty(),
    leading_trivia=@md.Trivia::empty(),
    trailing_trivia=@md.Trivia::empty(),
  )
}

///|
test "extract_from_blocks: basic headings" {
  let blocks = [
    make_heading(1, "Title"),
    make_heading(2, "Section 1"),
    make_heading(3, "Subsection"),
    make_heading(2, "Section 2"),
  ]
  let toc = extract_from_blocks(blocks)
  // h1 is skipped, only h2-h4 included
  inspect(toc.length(), content="3")
  inspect(toc[0].level, content="2")
  inspect(toc[0].text, content="Section 1")
  inspect(toc[0].id, content="section-1")
  inspect(toc[1].level, content="3")
  inspect(toc[2].level, content="2")
}

///|
test "extract_description_from_blocks: first paragraph" {
  let blocks = [
    make_heading(1, "Title"),
    make_paragraph("This is the description."),
  ]
  let desc = extract_description_from_blocks(blocks)
  inspect(desc, content="Some(\"This is the description.\")")
}

///|
test "extract_description_from_blocks: truncation" {
  let long_text = "This is a very long description that exceeds the maximum length and should be truncated with an ellipsis at the end."
  let blocks = [make_paragraph(long_text)]
  let desc = extract_description_from_blocks(blocks, max_length=50)
  match desc {
    Some(s) => inspect(s.has_suffix("..."), content="true")
    None => fail("Expected Some")
  }
}

///|
test "extract_text_from_inlines: basic text" {
  let inlines = [
    @md.Inline::Text(content="Hello ", span=@md.Span::empty()),
    @md.Inline::Strong(
      marker=@md.EmphasisMarker::Asterisk,
      children=[@md.Inline::Text(content="World", span=@md.Span::empty())],
      span=@md.Span::empty(),
    ),
  ]
  let text = extract_text_from_inlines(inlines)
  inspect(text, content="Hello World")
}

// Table of Contents Extraction
// Extract TOC from Block CST

///|
/// Extract table of contents from Document
pub fn extract_from_document(doc : @md.Document) -> Array[TocItem] {
  extract_from_blocks(doc.children)
}

///|
/// Extract table of contents from Block array
pub fn extract_from_blocks(blocks : Array[@md.Block]) -> Array[TocItem] {
  let toc : Array[TocItem] = []
  extract_recursive(blocks, toc)
  toc
}

///|
/// Extract headings recursively
fn extract_recursive(blocks : Array[@md.Block], toc : Array[TocItem]) -> Unit {
  for block in blocks {
    match block {
      @md.Block::Heading(level~, children~, ..) =>
        // Only include h2-h4 in TOC (skip h1 which is usually the title)
        if level >= 2 && level <= 4 {
          let text = extract_text_from_inlines(children)
          let id = @slug.generate_heading_id(text)
          toc.push(TocItem::{ level, text, id })
        }
      @md.Block::Blockquote(children~, ..) => extract_recursive(children, toc)
      @md.Block::BulletList(items~, ..) =>
        for item in items {
          extract_recursive(item.children, toc)
        }
      @md.Block::OrderedList(items~, ..) =>
        for item in items {
          extract_recursive(item.children, toc)
        }
      _ => ()
    }
  }
}

// =============================================================================
// Text Extraction from Inline CST
// =============================================================================

///|
/// Extract plain text from Inline array
pub fn extract_text_from_inlines(inlines : Array[@md.Inline]) -> String {
  let buf = StringBuilder::new()
  for inline in inlines {
    extract_text_recursive(inline, buf)
  }
  buf.to_string()
}

///|
/// Extract text recursively
fn extract_text_recursive(inline : @md.Inline, buf : StringBuilder) -> Unit {
  match inline {
    @md.Inline::Text(content~, ..) => buf.write_string(content)
    @md.Inline::SoftBreak(..) => buf.write_string(" ")
    @md.Inline::HardBreak(..) => buf.write_string("\n")
    @md.Inline::Emphasis(children~, ..) | @md.Inline::Strong(children~, ..) =>
      for child in children {
        extract_text_recursive(child, buf)
      }
    @md.Inline::Strikethrough(children~, ..) =>
      for child in children {
        extract_text_recursive(child, buf)
      }
    @md.Inline::Code(content~, ..) => buf.write_string(content)
    @md.Inline::Link(children~, ..) =>
      for child in children {
        extract_text_recursive(child, buf)
      }
    @md.Inline::RefLink(children~, ..) =>
      for child in children {
        extract_text_recursive(child, buf)
      }
    @md.Inline::Autolink(url~, ..) => buf.write_string(url)
    @md.Inline::Image(alt~, ..) => buf.write_string(alt)
    @md.Inline::RefImage(alt~, ..) => buf.write_string(alt)
    @md.Inline::HtmlInline(..) => () // Skip HTML
    @md.Inline::FootnoteReference(label~, ..) => buf.write_string("[^\{label}]")
  }
}

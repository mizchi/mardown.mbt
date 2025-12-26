// Description Extraction
// Extract description from markdown for meta tags

///|
/// Extract description from Document
/// Returns the first paragraph's text, truncated to max_length
pub fn extract_description_from_document(
  doc : @md.Document,
  max_length? : Int = 160,
) -> String? {
  extract_description_from_blocks(doc.children, max_length~)
}

///|
/// Extract description from Block array
pub fn extract_description_from_blocks(
  blocks : Array[@md.Block],
  max_length? : Int = 160,
) -> String? {
  for block in blocks {
    match block {
      @md.Block::Paragraph(children~, ..) => {
        let text = extract_text_from_inlines(children)
        if not(text.is_empty()) {
          return Some(truncate_text(text, max_length))
        }
      }
      _ => continue
    }
  }
  None
}

///|
/// Truncate text to max_length, adding ellipsis if needed
fn truncate_text(text : String, max_length : Int) -> String {
  let chars = text.to_array()
  if chars.length() <= max_length {
    return text
  }
  // Find last space before max_length to avoid cutting words
  let mut cut_point = max_length
  for i = max_length - 1; i >= max_length - 30 && i >= 0; i = i - 1 {
    if chars[i] == ' ' {
      cut_point = i
      break
    }
  }
  // Build truncated string
  let result : Array[Char] = []
  for i = 0; i < cut_point; i = i + 1 {
    result.push(chars[i])
  }
  String::from_array(result) + "..."
}

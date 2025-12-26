// Code Block Info String Parsing
// Parse code block info string (e.g., "js:app.js {highlight=[1,3]}")

///|
/// Parsed info string from code block fence
/// Format: "lang:filename {meta}"
/// Examples:
///   "javascript" → (lang="javascript", filename="", meta="")
///   "js:app.js" → (lang="js", filename="app.js", meta="")
///   "ts:index.ts {highlight=[1,3]}" → (lang="ts", filename="index.ts", meta="{highlight=[1,3]}")
pub(all) struct CodeBlockInfo {
  lang : String
  filename : String
  meta : String
}

///|
/// Parse code block info string into components
pub fn parse(info : String) -> CodeBlockInfo {
  let trimmed = info.trim(chars=" \t\n\r").to_string()
  if trimmed.is_empty() {
    return { lang: "", filename: "", meta: "" }
  }

  // Find meta section (starts with space + {)
  let (main_part, meta) = match trimmed.find(" {") {
    Some(idx) => {
      let main = trimmed.unsafe_substring(start=0, end=idx)
      let meta_str = trimmed
        .unsafe_substring(start=idx + 1, end=trimmed.length())
        .trim(chars=" \t\n\r")
        .to_string()
      (main, meta_str)
    }
    None => (trimmed, "")
  }

  // Split lang:filename
  match main_part.find(":") {
    Some(idx) => {
      let lang = main_part.unsafe_substring(start=0, end=idx)
      let filename = main_part.unsafe_substring(
        start=idx + 1,
        end=main_part.length(),
      )
      { lang, filename, meta }
    }
    None => { lang: main_part, filename: "", meta }
  }
}

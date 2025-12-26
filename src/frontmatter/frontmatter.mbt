// Frontmatter Utilities
// Extract and work with YAML frontmatter from markdown documents

///|
/// Get a string value from frontmatter entries
pub fn get_string(fm : @md.Frontmatter, key : String) -> String? {
  for entry in fm.entries {
    let (k, v) = entry
    if k == key {
      return Some(v)
    }
  }
  None
}

///|
/// Get a boolean value from frontmatter entries
/// Returns true if value is "true", false if "false", None otherwise
pub fn get_bool(fm : @md.Frontmatter, key : String) -> Bool? {
  match get_string(fm, key) {
    Some("true") => Some(true)
    Some("false") => Some(false)
    _ => None
  }
}

///|
/// Get an integer value from frontmatter entries
pub fn get_int(fm : @md.Frontmatter, key : String) -> Int? {
  match get_string(fm, key) {
    Some(s) => {
      try {
        Some(@strconv.parse_int(s))
      } catch {
        _ => None
      }
    }
    None => None
  }
}

///|
/// Get a comma-separated list from frontmatter entries
pub fn get_list(fm : @md.Frontmatter, key : String) -> Array[String] {
  match get_string(fm, key) {
    Some(s) => {
      let result : Array[String] = []
      let parts = s.split(",")
      for part in parts {
        let trimmed = part.to_string().trim(chars=" \t\n\r").to_string()
        if not(trimmed.is_empty()) {
          result.push(trimmed)
        }
      }
      result
    }
    None => []
  }
}

///|
/// Check if a key exists in frontmatter
pub fn has_key(fm : @md.Frontmatter, key : String) -> Bool {
  for entry in fm.entries {
    let (k, _) = entry
    if k == key {
      return true
    }
  }
  false
}

///|
/// Get all keys from frontmatter
pub fn keys(fm : @md.Frontmatter) -> Array[String] {
  fm.entries.map(fn(entry) {
    let (k, _) = entry
    k
  })
}

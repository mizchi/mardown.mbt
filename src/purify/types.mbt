///| HTML Sanitizer Types
///|
///| Configuration and result types for XSS sanitization

// =============================================================================
// Configuration
// =============================================================================

///|
/// Sanitizer configuration
pub(all) struct SanitizeConfig {
  /// Allow HTML tags (if false, strip all HTML)
  allow_html : Bool
  /// Allow SVG tags
  allow_svg : Bool
  /// Allow MathML tags
  allow_math : Bool
  /// Allow data-* attributes
  allow_data_attr : Bool
  /// Allow aria-* attributes
  allow_aria_attr : Bool
  /// Allow target attribute on links
  allow_link_target : Bool
  /// Additional allowed tags (lowercase)
  additional_tags : Array[String]
  /// Additional forbidden tags (lowercase)
  forbidden_tags : Array[String]
  /// Additional allowed attributes (lowercase)
  additional_attrs : Array[String]
  /// Additional forbidden attributes (lowercase)
  forbidden_attrs : Array[String]
  /// Allowed URL schemes for links/images
  allowed_schemes : Array[String]
}

///|
/// Create default sanitizer config (safe defaults)
pub fn SanitizeConfig::default() -> SanitizeConfig {
  {
    allow_html: true,
    allow_svg: false,  // SVG is risky, disabled by default
    allow_math: false, // MathML disabled by default
    allow_data_attr: true,
    allow_aria_attr: true,
    allow_link_target: false, // Prevent target="_blank" without rel="noopener"
    additional_tags: [],
    forbidden_tags: [],
    additional_attrs: [],
    forbidden_attrs: [],
    allowed_schemes: ["http", "https", "mailto", "tel"],
  }
}

///|
/// Create strict config (text only, no HTML)
pub fn SanitizeConfig::strict() -> SanitizeConfig {
  {
    allow_html: false,
    allow_svg: false,
    allow_math: false,
    allow_data_attr: false,
    allow_aria_attr: false,
    allow_link_target: false,
    additional_tags: [],
    forbidden_tags: [],
    additional_attrs: [],
    forbidden_attrs: [],
    allowed_schemes: ["http", "https", "mailto"],
  }
}

///|
/// Create permissive config (more tags allowed, still safe)
pub fn SanitizeConfig::permissive() -> SanitizeConfig {
  {
    allow_html: true,
    allow_svg: true,
    allow_math: true,
    allow_data_attr: true,
    allow_aria_attr: true,
    allow_link_target: true,
    additional_tags: [],
    forbidden_tags: [],
    additional_attrs: [],
    forbidden_attrs: [],
    allowed_schemes: ["http", "https", "mailto", "tel", "ftp"],
  }
}

// =============================================================================
// Sanitization Result
// =============================================================================

///|
/// Result of sanitization with warnings
pub(all) struct SanitizeResult {
  /// Sanitized content
  content : String
  /// List of removed dangerous elements
  removed : Array[RemovedItem]
  /// Whether any content was modified
  was_modified : Bool
}

///|
/// Information about a removed dangerous item
pub(all) struct RemovedItem {
  /// Type of item removed
  kind : RemovedKind
  /// Original content that was removed
  original : String
  /// Reason for removal
  reason : String
}

///|
/// Kind of removed item
pub(all) enum RemovedKind {
  Tag
  Attribute
  Url
  Protocol
} derive(Eq, Show)


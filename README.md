# mizchi/markdown

CST-based incremental Markdown parser for MoonBit.

## Features

- **Lossless CST**: Preserves all whitespace, markers, and formatting
- **Incremental parsing**: Re-parses only changed blocks
- **GFM compatible**: GitHub Flavored Markdown support
- **Cross-platform**: Works on JS, WASM-GC, and native targets

## Installation

```bash
moon add mizchi/markdown
```

## Usage

```moonbit
// Parse markdown
let doc = @markdown.parse("# Hello\n\nWorld")

// Serialize back (lossless)
let output = @markdown.serialize(doc)

// Incremental update
let edit = @markdown.EditInfo::new(start, end, new_length)
let new_doc = @markdown.parse_incremental(doc, new_text, edit)
```

## Documentation

See [docs/markdown.md](./docs/markdown.md) for detailed architecture and design.

## License

MIT

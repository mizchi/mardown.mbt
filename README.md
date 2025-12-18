# mizchi/markdown

CST-based incremental Markdown parser for MoonBit.

JS/WASM/native のクロスターゲットな MoonBit の Markdown コンパイラです。主にリアルタイム編集時のインクリメンタルパースに最適化されています。

## CommonMark Compatibility

CommonMark サブセットの実装で、207/542 のテストをパスしています。未対応のものは入れ子のエッジケースが多く、実用上の問題は少ないです。

完全な CommonMark 準拠が必要な場合は [cmark.mbt](https://github.com/moonbit-community/cmark.mbt) を推奨します。

## Features

- **Lossless CST**: Preserves all whitespace, markers, and formatting
- **Incremental parsing**: Re-parses only changed blocks (up to 42x faster)
- **GFM compatible**: GitHub Flavored Markdown support (tables, task lists, strikethrough)
- **Cross-platform**: Works on JS, WASM-GC, and native targets
- **HTML rendering**: Built-in HTML renderer with remark-html compatible output
- **Plugin system**: Custom code block highlighters

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

## HTML Rendering

```moonbit
// Direct conversion
let html = @markdown.md_to_html("# Hello\n\nWorld")

// Or with handle for incremental updates
let handle = @markdown.md_parse(source)
let html = @markdown.md_render_to_html(handle)
@markdown.md_free(handle)
```

## Playground

```bash
pnpm install
moon build --target js
pnpm exec vite
```

## Documentation

See [docs/markdown.md](./docs/markdown.md) for detailed architecture and design.

## License

MIT

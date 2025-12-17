# MoonBit Markdown Parser

CST-based incremental Markdown parser implemented in MoonBit.

## プロジェクト構成

```
src/
├── types.mbt              # CST型定義 (Span, Block, Inline)
├── scanner.mbt            # O(1)文字アクセス (Array[Char])
├── block_parser.mbt       # ブロックパーサー
├── inline_parser.mbt      # インラインパーサー
├── incremental.mbt        # インクリメンタルパース (EditInfo)
├── serializer.mbt         # ロスレスシリアライザ
├── crdt_experiment.mbt    # CRDT実験コード
└── bench.mbt              # ベンチマーク
```

## 設計思想

- **CST（Concrete Syntax Tree）が真実**: Markdownテキストは CSTの直列化結果
- **損失なし（Lossless）**: Trivia（空白・改行）とMarker（`*` vs `_`）を保持
- **インクリメンタル**: 変更ブロックのみ再パース、前後は再利用

## 開発コマンド

```bash
moon check           # 型チェック
moon test            # 全テスト実行
moon test --target js    # JSターゲットでテスト
moon test --target wasm-gc  # WASM-GCターゲットでテスト
moon bench           # ベンチマーク実行
moon fmt             # コードフォーマット
```

## 主要な型

### Block (ブロック要素)

```moonbit
pub(all) enum Block {
  Paragraph(span~, children~)           # 段落
  Heading(span~, level~, children~)     # 見出し (h1-h6)
  FencedCode(span~, fence_char~, fence_length~, info~, code~)
  ThematicBreak(span~, marker_char~)    # ---
  BlockQuote(span~, children~)          # > 引用
  List(span~, ordered~, start~, tight~, marker_char~, items~)
  HtmlBlock(span~, content~)
  LinkRefDef(span~, label~, dest~, title~)
}
```

### Inline (インライン要素)

```moonbit
pub(all) enum Inline {
  Text(span~, content~)                 # テキスト
  Code(span~, content~)                 # `code`
  Emphasis(span~, marker~, children~)   # *em* or _em_
  Strong(span~, marker~, children~)     # **strong** or __strong__
  Link(span~, children~, dest~, title~)
  Image(span~, alt~, dest~, title~)
  SoftBreak(span~)                      # 改行
  HardBreak(span~)                      # 行末空白2つ
  HtmlInline(span~, content~)
}
```

## API

```moonbit
// パース
let doc = @markdown.parse(markdown_string)

// シリアライズ（損失なし）
let output = @markdown.serialize(doc)
assert_eq!(output, markdown_string)

// インクリメンタルパース
let edit = EditInfo::new(change_start, change_end, new_length)
let new_doc = @markdown.parse_incremental(old_doc, new_text, edit)
```

## パフォーマンス特性

| ドキュメント | フルパース | インクリメンタル | 高速化 |
|-------------|-----------|-----------------|--------|
| 10段落 | 68.89µs | 7.36µs | 9.4x |
| 50段落 | 327.99µs | 8.67µs | 37.8x |
| 100段落 | 651.14µs | 15.25µs | 42.7x |

## 参照ドキュメント

- [Architecture](./docs/markdown.md) - 詳細設計ドキュメント

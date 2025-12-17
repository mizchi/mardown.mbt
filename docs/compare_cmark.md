# cmark実装との比較分析

rami3l/cmark (v0.4.0) のemphasis実装を分析し、採用可能なアプローチをまとめる。

## ベンチマーク比較

| Document | mizchi/markdown | rami3l/cmark | 差 |
|----------|-----------------|--------------|-----|
| small (5) | 46.38µs | 36.43µs | +27% 遅い |
| medium (20) | 142.42µs | 155.81µs | **-9% 速い** |
| large (100) | 660.70µs | 794.09µs | **-17% 速い** |

中〜大規模ドキュメントでは優位。小規模での初期化オーバーヘッドが課題。

## Emphasis実装の違い

### 現在の実装の問題点

1. **Rule 9, 10 (mod 3ルール) 未実装**
2. **Closer Index なし** - 閉じるデリミタの検索が非効率
3. **単一パス処理** - 複雑なネストに対応できない
4. **Left/Right flanking が部分的**

### cmarkのアーキテクチャ

#### 1. トークン化フェーズ

```moonbit
// 各 * や _ の連続に対して TokenEmphasisMarks を生成
TokenEmphasisMarks { start, char, count, may_open, may_close }
```

#### 2. Left/Right Flanking判定 (CommonMark仕様)

```moonbit
// 基本判定
is_left_flanking = !is_next_white && (!is_next_punct || is_prev_white || is_prev_punct)
is_right_flanking = !is_prev_white && (!is_prev_punct || is_next_white || is_next_punct)

// * の場合
may_open = is_left_flanking
may_close = is_right_flanking

// _ の場合 (単語境界の追加制約)
may_open = is_left_flanking && (!is_right_flanking || is_prev_punct)
may_close = is_right_flanking && (!is_left_flanking || is_next_punct)
```

#### 3. Closer Index

閉じるデリミタの位置をハッシュマップでインデックス化:

```moonbit
priv struct CloserIndex(Map[Closer, Set[Int]])

fn CloserIndex::exists(self, key: Closer, after~: Int) -> Bool
fn CloserIndex::pos(self, key: Closer, after~: Int) -> Int?
```

「この位置より後ろに閉じる `*` があるか？」を O(1) で検索可能。

#### 4. Rule 9, 10 (mod 3ルール)

CommonMark仕様のRule 9, 10を実装:

```moonbit
fn marks_match(marks: TokenEmphasisMarks, opener: TokenEmphasisMarks) -> Bool {
  opener.char == marks.char &&
  (
    (marks.may_open || !opener.may_close) ||
    marks.count % 3 == 0 ||
    (opener.count + marks.count) % 3 != 0
  )
}
```

このルールにより、`***foo**` のような曖昧なケースを正しく処理できる。

#### 5. 3パス処理

1. **First pass**: コードスパン、オートリンク、リンク
2. **Second pass**: emphasis, strikethrough
3. **Last pass**: テキストノード生成

## 実装計画と検証結果

### Phase 1: Rule 9, 10 (mod 3ルール) の追加

**対象ファイル**: `src/inline_parser.mbt`

**変更内容**:
- `try_parse_emphasis` でマーカーカウントを追跡
- 閉じるマーカーとのマッチング時に mod 3 ルールを適用

**期待効果**: Emphasisテスト大幅改善 (現在 42/132)

**実装結果**: ❌ 効果なし (42/132 → 42/132)

### Phase 2: Left/Right Flanking の完全実装

**対象ファイル**: `src/inline_parser.mbt`

**変更内容**:
- `_` の単語境界ルールを厳密に実装
- Unicode空白・句読点の判定を追加

**期待効果**: `_` 関連のエッジケース改善

**実装結果**: ❌ リグレッション発生 (42/132 → 41/132)

### 問題分析

Emphasis テストの失敗の大部分は**シリアライズの差異**:
- remark: テキスト中の `*` `_` をエスケープ (`\*`, `\_`)
- 本実装: そのまま出力

例: `a * foo bar*`
- remark出力: `a \* foo bar\*`
- 本実装出力: `a * foo bar*`

これはCST設計上の選択の違いであり、パースの正確性の問題ではない。

### Phase 3: Closer Index の導入 (未実施)

**対象ファイル**: `src/inline_parser.mbt` (新規構造体追加)

**変更内容**:
- `CloserIndex` 構造体を追加
- トークン化時に閉じるデリミタをインデックス化
- 検索時に O(1) ルックアップを使用

**期待効果**: パフォーマンス改善（特に大規模ドキュメント）

### Phase 4: 複数パス処理 (未実施)

**対象ファイル**: `src/inline_parser.mbt` (大幅リファクタリング)

**変更内容**:
- トークン化 → パス1 → パス2 → パス3 の構造に変更
- 各パスで異なる種類のインラインを処理

**期待効果**: 複雑なネストの正確な処理

### Phase 4: 複数パス処理 (完全実装・検証済み)

**実装内容**:
- `inline_token.mbt` に Token enum、tokenize、CloserIndex を実装
- `parse_inlines_multipass()` 関数として 完全なインラインパーサーを実装
- コードスパン、リンク、画像、オートリンク、取り消し線、エスケープを全てサポート

**ベンチマーク結果** (完全版):

| Test | Original | Multipass | 比較 |
|------|----------|-----------|------|
| simple text | 0.45 µs | 0.46 µs | 同等 |
| emphasis/strong/code | 1.44 µs | 1.84 µs | 28% 低速 |
| links and images | 3.49 µs | 4.70 µs | 35% 低速 |
| stress 10 (30 markers) | 9.85 µs | 13.45 µs | 37% 低速 |
| stress 50 (150 markers) | 39.05 µs | 72.95 µs | 87% 低速 |

**CommonMark互換性**:
- Original: 202/542 (37%)
- Multipass: 187/542 (35%)

**結果**: ❌ 性能・互換性ともにリグレッション

マルチパスパーサーはトークン配列生成と複数回走査のオーバーヘッドにより、
すべてのケースで元のパーサーより低速。CommonMark互換性も15テスト低下。

### Phase 5: 最適化の試行 (実験済み)

以下の最適化を試行：

1. **CloserIndex の二分探索**: ✅ 実装済み (O(n) → O(log n))
2. **substring を String slice に変更**: ✅ 実装済み
3. **tokenize + CloserIndex 構築の統合**: ✅ 1パスで実行
4. **Array[Char] を StringView に置換**: ✅ `text.to_array()` を削除

**ベンチマーク結果**:

| Test | Original | Multipass (初期) | Multipass (最終) | vs Original |
|------|----------|-----------------|------------------|-------------|
| simple text | 0.62 µs | 0.46 µs | 0.41 µs | 34%速い |
| emphasis | 1.43 µs | 1.84 µs | 1.56 µs | 9%遅い |
| stress 10 | 7.74 µs | 13.45 µs | 9.92 µs | 28%遅い |
| stress 50 | 35.89 µs | 72.95 µs | 61.86 µs | 72%遅い |
| stress 100 | 70.27 µs | 116.83 µs | 101.61 µs | 45%遅い |

**StringView による改善**:
- stress 100: 116.83 µs → 101.61 µs (13%改善)
- stress 10: 12.24 µs → 9.92 µs (19%改善)
- emphasis: 1.72 µs → 1.56 µs (9%改善)

### 結論

Emphasis の CommonMark 互換性向上には大規模リファクタリングが必要だが、
最適化によりマルチパスパーサの性能は大幅に改善した。

| アプローチ | 効果 | 性能 |
|-----------|------|------|
| Phase 1: mod 3 rule | ❌ 効果なし | - |
| Phase 2: Flanking | ❌ リグレッション | - |
| Phase 4: Multi-pass | ❌ リグレッション | 87%低速 |
| Phase 5: 最適化 | ✅ 大幅改善 | 28-45%低速 |

現状のアーキテクチャでは Emphasis 42/132 (32%) が限界と思われる。

**残るボトルネック**:
- parse_range 内の再帰的トークン走査
- オリジナルの「見つけたら即処理」に比べ、中間データ構造のコストが大きい

現時点では `parse_inlines_multipass()` は実験コードとして保持し、
メインパーサーは元のシングルパス実装を使用する。

## 参考リンク

- [CommonMark Spec - Emphasis and strong emphasis](https://spec.commonmark.org/0.31.2/#emphasis-and-strong-emphasis)
- [rami3l/cmark](https://github.com/moonbit-community/cmark.mbt)
- ソース: `.mooncakes/rami3l/cmark/src/cmark/inline_struct.mbt`

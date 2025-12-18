///| AST type definitions for markdown.mbt

export interface Span {
  from: number;
  to: number;
}

// Block types
export type Block =
  | ParagraphBlock
  | HeadingBlock
  | CodeBlockBlock
  | BlockquoteBlock
  | BulletListBlock
  | OrderedListBlock
  | ThematicBreakBlock
  | HtmlBlockBlock
  | TableBlock
  | BlankLinesBlock
  | FootnoteDefinitionBlock;

export interface ParagraphBlock {
  type: "paragraph";
  children: Inline[];
  span: Span;
}

export interface HeadingBlock {
  type: "heading";
  level: number;
  children: Inline[];
  span: Span;
}

export interface CodeBlockBlock {
  type: "code_block";
  info: string | null;
  code: string;
  span: Span;
}

export interface BlockquoteBlock {
  type: "blockquote";
  children: Block[];
  span: Span;
}

export interface BulletListBlock {
  type: "bullet_list";
  tight: boolean;
  items: ListItem[];
  span: Span;
}

export interface OrderedListBlock {
  type: "ordered_list";
  start: number;
  tight: boolean;
  items: ListItem[];
  span: Span;
}

export interface ThematicBreakBlock {
  type: "thematic_break";
  span: Span;
}

export interface HtmlBlockBlock {
  type: "html_block";
  html: string;
  span: Span;
}

export interface TableBlock {
  type: "table";
  header: TableCell[];
  alignments: (TableAlign | null)[];
  rows: TableCell[][];
  span: Span;
}

export interface BlankLinesBlock {
  type: "blank_lines";
  count: number;
  span: Span;
}

export interface FootnoteDefinitionBlock {
  type: "footnote_definition";
  label: string;
  children: Block[];
  span: Span;
}

export interface ListItem {
  type: "list_item";
  children: Block[];
  checked: boolean | null;
  span: Span;
}

export interface TableCell {
  type: "table_cell";
  children: Inline[];
  span: Span;
}

export type TableAlign = "left" | "center" | "right";

// Inline types
export type Inline =
  | TextInline
  | SoftBreakInline
  | HardBreakInline
  | EmphasisInline
  | StrongInline
  | StrikethroughInline
  | CodeInline
  | LinkInline
  | RefLinkInline
  | AutolinkInline
  | ImageInline
  | RefImageInline
  | HtmlInlineInline
  | FootnoteReferenceInline;

export interface TextInline {
  type: "text";
  content: string;
  span: Span;
}

export interface SoftBreakInline {
  type: "soft_break";
  span: Span;
}

export interface HardBreakInline {
  type: "hard_break";
  span: Span;
}

export interface EmphasisInline {
  type: "emphasis";
  children: Inline[];
  span: Span;
}

export interface StrongInline {
  type: "strong";
  children: Inline[];
  span: Span;
}

export interface StrikethroughInline {
  type: "strikethrough";
  children: Inline[];
  span: Span;
}

export interface CodeInline {
  type: "code";
  content: string;
  span: Span;
}

export interface LinkInline {
  type: "link";
  children: Inline[];
  url: string;
  title: string;
  span: Span;
}

export interface RefLinkInline {
  type: "ref_link";
  children: Inline[];
  label: string;
  span: Span;
}

export interface AutolinkInline {
  type: "autolink";
  url: string;
  is_email: boolean;
  span: Span;
}

export interface ImageInline {
  type: "image";
  alt: string;
  url: string;
  title: string;
  span: Span;
}

export interface RefImageInline {
  type: "ref_image";
  alt: string;
  label: string;
  span: Span;
}

export interface HtmlInlineInline {
  type: "html_inline";
  html: string;
  span: Span;
}

export interface FootnoteReferenceInline {
  type: "footnote_reference";
  label: string;
  span: Span;
}

// Document
export interface Document {
  type: "document";
  children: Block[];
  span: Span;
}

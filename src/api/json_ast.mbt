///| AST to JSON serialization for JS interop

///| Convert Document to JSON string
pub fn document_to_json(doc : @markdown.Document) -> String {
  let json = document_to_json_value(doc)
  json.stringify()
}

///| Convert Document to JSON Value
fn document_to_json_value(doc : @markdown.Document) -> Json {
  let children : Array[Json] = []
  for block in doc.children {
    children.push(block_to_json(block))
  }
  {
    "type": "document",
    "children": Json::array(children),
    "span": span_to_json(doc.span),
  }
}

///| Convert Span to JSON
fn span_to_json(span : @markdown.Span) -> Json {
  { "from": span.from.to_json(), "to": span.to.to_json() }
}

///| Convert Block to JSON
fn block_to_json(block : @markdown.Block) -> Json {
  match block {
    @markdown.Block::Paragraph(children~, span~, ..) => {
      let inlines : Array[Json] = []
      for inline in children {
        inlines.push(inline_to_json(inline))
      }
      {
        "type": "paragraph",
        "children": Json::array(inlines),
        "span": span_to_json(span),
      }
    }
    @markdown.Block::Heading(level~, children~, span~, ..) => {
      let inlines : Array[Json] = []
      for inline in children {
        inlines.push(inline_to_json(inline))
      }
      {
        "type": "heading",
        "level": level.to_json(),
        "children": Json::array(inlines),
        "span": span_to_json(span),
      }
    }
    @markdown.Block::FencedCode(info~, code~, span~, ..) => {
      {
        "type": "code_block",
        "info": info.to_json(),
        "code": code.to_json(),
        "span": span_to_json(span),
      }
    }
    @markdown.Block::IndentedCode(code~, span~, ..) => {
      {
        "type": "code_block",
        "info": Json::null(),
        "code": code.to_json(),
        "span": span_to_json(span),
      }
    }
    @markdown.Block::Blockquote(children~, span~, ..) => {
      let blocks : Array[Json] = []
      for child in children {
        blocks.push(block_to_json(child))
      }
      {
        "type": "blockquote",
        "children": Json::array(blocks),
        "span": span_to_json(span),
      }
    }
    @markdown.Block::BulletList(items~, tight~, span~, ..) => {
      let list_items : Array[Json] = []
      for item in items {
        list_items.push(list_item_to_json(item))
      }
      {
        "type": "bullet_list",
        "tight": tight.to_json(),
        "items": Json::array(list_items),
        "span": span_to_json(span),
      }
    }
    @markdown.Block::OrderedList(start~, items~, tight~, span~, ..) => {
      let list_items : Array[Json] = []
      for item in items {
        list_items.push(list_item_to_json(item))
      }
      {
        "type": "ordered_list",
        "start": start.to_json(),
        "tight": tight.to_json(),
        "items": Json::array(list_items),
        "span": span_to_json(span),
      }
    }
    @markdown.Block::ThematicBreak(span~, ..) => {
      { "type": "thematic_break", "span": span_to_json(span) }
    }
    @markdown.Block::HtmlBlock(html~, span~, ..) => {
      {
        "type": "html_block",
        "html": html.to_json(),
        "span": span_to_json(span),
      }
    }
    @markdown.Block::Table(header~, alignments~, rows~, span~, ..) => {
      let header_cells : Array[Json] = []
      for cell in header {
        header_cells.push(table_cell_to_json(cell))
      }
      let align_strs : Array[Json] = []
      for align in alignments {
        align_strs.push(table_align_to_json(align))
      }
      let row_data : Array[Json] = []
      for row in rows {
        let cells : Array[Json] = []
        for cell in row {
          cells.push(table_cell_to_json(cell))
        }
        row_data.push(Json::array(cells))
      }
      {
        "type": "table",
        "header": Json::array(header_cells),
        "alignments": Json::array(align_strs),
        "rows": Json::array(row_data),
        "span": span_to_json(span),
      }
    }
    @markdown.Block::BlankLines(count~, span~) => {
      {
        "type": "blank_lines",
        "count": count.to_json(),
        "span": span_to_json(span),
      }
    }
    @markdown.Block::FootnoteDefinition(label~, children~, span~, ..) => {
      let blocks : Array[Json] = []
      for child in children {
        blocks.push(block_to_json(child))
      }
      {
        "type": "footnote_definition",
        "label": label.to_json(),
        "children": Json::array(blocks),
        "span": span_to_json(span),
      }
    }
  }
}

///| Convert ListItem to JSON
fn list_item_to_json(item : @markdown.ListItem) -> Json {
  let blocks : Array[Json] = []
  for child in item.children {
    blocks.push(block_to_json(child))
  }
  let checked : Json = match item.checked {
    Some(v) => v.to_json()
    None => Json::null()
  }
  {
    "type": "list_item",
    "children": Json::array(blocks),
    "checked": checked,
    "span": span_to_json(item.span),
  }
}

///| Convert TableCell to JSON
fn table_cell_to_json(cell : @markdown.TableCell) -> Json {
  let inlines : Array[Json] = []
  for inline in cell.children {
    inlines.push(inline_to_json(inline))
  }
  {
    "type": "table_cell",
    "children": Json::array(inlines),
    "span": span_to_json(cell.span),
  }
}

///| Convert TableAlign to JSON
fn table_align_to_json(align : @markdown.TableAlign) -> Json {
  match align {
    @markdown.TableAlign::Left => "left".to_json()
    @markdown.TableAlign::Center => "center".to_json()
    @markdown.TableAlign::Right => "right".to_json()
    @markdown.TableAlign::None => Json::null()
  }
}

///| Convert Inline to JSON
fn inline_to_json(inline : @markdown.Inline) -> Json {
  match inline {
    @markdown.Inline::Text(content~, span~) => {
      {
        "type": "text",
        "content": content.to_json(),
        "span": span_to_json(span),
      }
    }
    @markdown.Inline::SoftBreak(span~) => {
      { "type": "soft_break", "span": span_to_json(span) }
    }
    @markdown.Inline::HardBreak(span~, ..) => {
      { "type": "hard_break", "span": span_to_json(span) }
    }
    @markdown.Inline::Emphasis(children~, span~, ..) => {
      let inlines : Array[Json] = []
      for child in children {
        inlines.push(inline_to_json(child))
      }
      {
        "type": "emphasis",
        "children": Json::array(inlines),
        "span": span_to_json(span),
      }
    }
    @markdown.Inline::Strong(children~, span~, ..) => {
      let inlines : Array[Json] = []
      for child in children {
        inlines.push(inline_to_json(child))
      }
      {
        "type": "strong",
        "children": Json::array(inlines),
        "span": span_to_json(span),
      }
    }
    @markdown.Inline::Strikethrough(children~, span~) => {
      let inlines : Array[Json] = []
      for child in children {
        inlines.push(inline_to_json(child))
      }
      {
        "type": "strikethrough",
        "children": Json::array(inlines),
        "span": span_to_json(span),
      }
    }
    @markdown.Inline::Code(content~, span~, ..) => {
      {
        "type": "code",
        "content": content.to_json(),
        "span": span_to_json(span),
      }
    }
    @markdown.Inline::Link(children~, url~, title~, span~) => {
      let inlines : Array[Json] = []
      for child in children {
        inlines.push(inline_to_json(child))
      }
      {
        "type": "link",
        "children": Json::array(inlines),
        "url": url.to_json(),
        "title": title.to_json(),
        "span": span_to_json(span),
      }
    }
    @markdown.Inline::RefLink(children~, label~, span~) => {
      let inlines : Array[Json] = []
      for child in children {
        inlines.push(inline_to_json(child))
      }
      {
        "type": "ref_link",
        "children": Json::array(inlines),
        "label": label.to_json(),
        "span": span_to_json(span),
      }
    }
    @markdown.Inline::Autolink(url~, is_email~, span~) => {
      {
        "type": "autolink",
        "url": url.to_json(),
        "is_email": is_email.to_json(),
        "span": span_to_json(span),
      }
    }
    @markdown.Inline::Image(alt~, url~, title~, span~) => {
      {
        "type": "image",
        "alt": alt.to_json(),
        "url": url.to_json(),
        "title": title.to_json(),
        "span": span_to_json(span),
      }
    }
    @markdown.Inline::RefImage(alt~, label~, span~) => {
      {
        "type": "ref_image",
        "alt": alt.to_json(),
        "label": label.to_json(),
        "span": span_to_json(span),
      }
    }
    @markdown.Inline::HtmlInline(html~, span~) => {
      {
        "type": "html_inline",
        "html": html.to_json(),
        "span": span_to_json(span),
      }
    }
    @markdown.Inline::FootnoteReference(label~, span~) => {
      {
        "type": "footnote_reference",
        "label": label.to_json(),
        "span": span_to_json(span),
      }
    }
  }
}

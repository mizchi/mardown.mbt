import { render } from "preact";
import { useState, useCallback } from "preact/hooks";
import { md_parse_to_ast, md_get_ast, md_free_ast } from "../target/js/release/build/api/api.js";
import type { Document } from "./ast-types";
import { MarkdownRenderer } from "./ast-renderer";

const initialMarkdown = `# Hello

This is a **bold** and *italic* text.

## Features

- Bullet point 1
- Bullet point 2
- Bullet point 3

### Task List

- [ ] Todo item
- [x] Completed item

### Code Block

\`\`\`javascript
const x = 1;
console.log(x);
\`\`\`

> Blockquote example

| Name | Age |
|------|-----|
| Alice | 30 |
| Bob | 25 |

Visit [example](https://example.com) for more.
`;

function parseToAst(source: string): Document {
  const handle = md_parse_to_ast(source);
  const json = md_get_ast(handle);
  md_free_ast(handle);
  return JSON.parse(json) as Document;
}

function App() {
  const [source, setSource] = useState(initialMarkdown);
  const [ast, setAst] = useState<Document>(() => parseToAst(initialMarkdown));

  const handleInput = useCallback((e: Event) => {
    const target = e.target as HTMLTextAreaElement;
    const newSource = target.value;
    setSource(newSource);
    setAst(parseToAst(newSource));
  }, []);

  return (
    <div class="container">
      <div class="editor">
        <textarea value={source} onInput={handleInput} />
      </div>
      <div class="preview">
        <MarkdownRenderer ast={ast} />
      </div>
    </div>
  );
}

render(<App />, document.getElementById("app")!);

import { render } from "preact";
import { useState, useCallback, useEffect, useRef } from "preact/hooks";
import { parse } from "../js/api.js";
import type { Root } from "mdast";
import { MarkdownRenderer } from "./ast-renderer";
import { SyntaxHighlightEditor } from "./SyntaxHighlightEditor";

const STORAGE_KEY = "markdown-editor-content";
const IDB_NAME = "markdown-editor";
const IDB_STORE = "documents";
const IDB_KEY = "current";
const DEBOUNCE_DELAY = 1000;

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

// IndexedDB helpers
function openDB(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(IDB_NAME, 1);
    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(IDB_STORE)) {
        db.createObjectStore(IDB_STORE);
      }
    };
  });
}

async function saveToIDB(content: string): Promise<void> {
  const db = await openDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(IDB_STORE, "readwrite");
    const store = tx.objectStore(IDB_STORE);
    const request = store.put({ content, timestamp: Date.now() }, IDB_KEY);
    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve();
    tx.oncomplete = () => db.close();
  });
}

async function loadFromIDB(): Promise<{ content: string; timestamp: number } | null> {
  try {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(IDB_STORE, "readonly");
      const store = tx.objectStore(IDB_STORE);
      const request = store.get(IDB_KEY);
      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result || null);
      tx.oncomplete = () => db.close();
    });
  } catch {
    return null;
  }
}

// Debounce hook
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);

  return debouncedValue;
}

// Dark mode hook
function useDarkMode(): [boolean, () => void] {
  const [isDark, setIsDark] = useState(() => {
    const saved = localStorage.getItem("theme");
    if (saved) return saved === "dark";
    return window.matchMedia("(prefers-color-scheme: dark)").matches;
  });

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", isDark ? "dark" : "light");
    localStorage.setItem("theme", isDark ? "dark" : "light");
  }, [isDark]);

  const toggle = useCallback(() => setIsDark((v) => !v), []);

  return [isDark, toggle];
}


// Find block element at cursor position
function findBlockAtPosition(ast: Root, position: number): number | null {
  for (let i = 0; i < ast.children.length; i++) {
    const block = ast.children[i]!;
    const start = block.position?.start?.offset ?? 0;
    const end = block.position?.end?.offset ?? 0;
    if (position >= start && position <= end) {
      return i;
    }
  }
  // If position is beyond all blocks, return the last block
  const lastBlock = ast.children[ast.children.length - 1];
  const lastEnd = lastBlock?.position?.end?.offset ?? 0;
  if (ast.children.length > 0 && lastBlock && position >= lastEnd) {
    return ast.children.length - 1;
  }
  return null;
}

type ViewMode = "split" | "editor" | "preview";

// SVG Icons for view modes
const SplitIcon = () => (
  <svg viewBox="0 0 20 20" width="18" height="18" fill="currentColor">
    <rect x="1" y="2" width="8" height="16" rx="1" stroke="currentColor" strokeWidth="1.5" fill="none" />
    <rect x="11" y="2" width="8" height="16" rx="1" stroke="currentColor" strokeWidth="1.5" fill="none" />
  </svg>
);

const EditorIcon = () => (
  <svg viewBox="0 0 20 20" width="18" height="18" fill="currentColor">
    <rect x="2" y="2" width="16" height="16" rx="1" stroke="currentColor" strokeWidth="1.5" fill="none" />
    <line x1="5" y1="6" x2="15" y2="6" stroke="currentColor" strokeWidth="1.5" />
    <line x1="5" y1="10" x2="12" y2="10" stroke="currentColor" strokeWidth="1.5" />
    <line x1="5" y1="14" x2="14" y2="14" stroke="currentColor" strokeWidth="1.5" />
  </svg>
);

const PreviewIcon = () => (
  <svg viewBox="0 0 20 20" width="18" height="18" fill="currentColor">
    <rect x="2" y="2" width="16" height="16" rx="1" stroke="currentColor" strokeWidth="1.5" fill="none" />
    <circle cx="10" cy="10" r="3" stroke="currentColor" strokeWidth="1.5" fill="none" />
    <path d="M4 10 Q7 5, 10 5 Q13 5, 16 10 Q13 15, 10 15 Q7 15, 4 10" stroke="currentColor" strokeWidth="1.5" fill="none" />
  </svg>
);

function App() {
  const [source, setSource] = useState(initialMarkdown);
  const [ast, setAst] = useState<Root>(() => parse(initialMarkdown));
  const [cursorPosition, setCursorPosition] = useState(0);
  const [isInitialized, setIsInitialized] = useState(false);
  const [isDark, toggleDark] = useDarkMode();
  const [saveStatus, setSaveStatus] = useState<"saved" | "saving" | "idle">("idle");
  const [viewMode, setViewMode] = useState<ViewMode>("split");

  const previewRef = useRef<HTMLDivElement>(null);
  const debouncedSource = useDebounce(source, DEBOUNCE_DELAY);

  // Keyboard shortcuts for view mode
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.ctrlKey || e.metaKey) {
        if (e.key === "1") {
          e.preventDefault();
          setViewMode("split");
        } else if (e.key === "2") {
          e.preventDefault();
          setViewMode("editor");
        } else if (e.key === "3") {
          e.preventDefault();
          setViewMode("preview");
        }
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  // Load initial content from localStorage or IndexedDB
  useEffect(() => {
    async function loadInitialContent() {
      // First, try localStorage for quick load
      const localContent = localStorage.getItem(STORAGE_KEY);

      // Then check IndexedDB for potentially newer content
      const idbData = await loadFromIDB();

      if (idbData && idbData.content) {
        // Compare timestamps if both exist
        const localTimestamp = parseInt(localStorage.getItem(`${STORAGE_KEY}-timestamp`) || "0", 10);
        if (idbData.timestamp >= localTimestamp) {
          setSource(idbData.content);
          setAst(parse(idbData.content));
        } else if (localContent) {
          setSource(localContent);
          setAst(parse(localContent));
        }
      } else if (localContent) {
        setSource(localContent);
        setAst(parse(localContent));
      }

      setIsInitialized(true);
    }

    loadInitialContent();
  }, []);

  // Handle visibility change for tab sync
  useEffect(() => {
    async function handleVisibilityChange() {
      if (document.visibilityState === "visible") {
        const idbData = await loadFromIDB();
        if (idbData) {
          const currentTimestamp = parseInt(localStorage.getItem(`${STORAGE_KEY}-timestamp`) || "0", 10);
          // If IDB has newer content, update
          if (idbData.timestamp > currentTimestamp) {
            setSource(idbData.content);
            setAst(parse(idbData.content));
            localStorage.setItem(STORAGE_KEY, idbData.content);
            localStorage.setItem(`${STORAGE_KEY}-timestamp`, idbData.timestamp.toString());
          }
        }
      }
    }

    document.addEventListener("visibilitychange", handleVisibilityChange);
    return () => document.removeEventListener("visibilitychange", handleVisibilityChange);
  }, []);

  // Save to localStorage with debounce
  useEffect(() => {
    if (!isInitialized) return;

    setSaveStatus("saving");
    const timestamp = Date.now();
    localStorage.setItem(STORAGE_KEY, debouncedSource);
    localStorage.setItem(`${STORAGE_KEY}-timestamp`, timestamp.toString());

    // Also save to IndexedDB
    saveToIDB(debouncedSource).then(() => {
      setSaveStatus("saved");
      setTimeout(() => setSaveStatus("idle"), 1000);
    });
  }, [debouncedSource, isInitialized]);

  // Sync preview scroll with cursor position
  useEffect(() => {
    if (!previewRef.current) return;

    const blockIndex = findBlockAtPosition(ast, cursorPosition);
    if (blockIndex === null) return;

    const block = ast.children[blockIndex]!;
    const start = block.position?.start?.offset ?? 0;
    const end = block.position?.end?.offset ?? 0;
    const selector = `[data-span="${start}-${end}"]`;
    const element = previewRef.current.querySelector(selector);

    if (element) {
      element.scrollIntoView({ behavior: "smooth", block: "center" });
    }
  }, [cursorPosition, ast]);

  const handleChange = useCallback((newSource: string) => {
    setSource(newSource);
    setAst(parse(newSource));
  }, []);

  const handleCursorChange = useCallback((position: number) => {
    setCursorPosition(position);
  }, []);

  return (
    <div class="app-container">
      <header class="toolbar">
        <div class="view-mode-buttons">
          <button
            class={`view-mode-btn ${viewMode === "split" ? "active" : ""}`}
            onClick={() => setViewMode("split")}
            title="Split view (Ctrl+1)"
          >
            <SplitIcon />
          </button>
          <button
            class={`view-mode-btn ${viewMode === "editor" ? "active" : ""}`}
            onClick={() => setViewMode("editor")}
            title="Editor only (Ctrl+2)"
          >
            <EditorIcon />
          </button>
          <button
            class={`view-mode-btn ${viewMode === "preview" ? "active" : ""}`}
            onClick={() => setViewMode("preview")}
            title="Preview only (Ctrl+3)"
          >
            <PreviewIcon />
          </button>
        </div>
        <div class="toolbar-actions">
          <span class={`save-status ${saveStatus}`}>
            {saveStatus === "saving" && "Saving..."}
            {saveStatus === "saved" && "Saved"}
          </span>
          <button onClick={toggleDark} class="theme-toggle" title="Toggle dark mode">
            {isDark ? "☀️" : "🌙"}
          </button>
          <a
            href="https://github.com/mizchi/markdown.mbt"
            target="_blank"
            rel="noopener noreferrer"
            class="github-link"
            title="View on GitHub"
          >
            <svg viewBox="0 0 16 16" width="20" height="20" fill="currentColor">
              <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"/>
            </svg>
          </a>
        </div>
      </header>
      <div class={`container view-${viewMode}`}>
        {(viewMode === "split" || viewMode === "editor") && (
          <div class="editor">
            <SyntaxHighlightEditor
              value={source}
              onChange={handleChange}
              onCursorChange={handleCursorChange}
            />
          </div>
        )}
        {(viewMode === "split" || viewMode === "preview") && (
          <div class="preview" ref={previewRef}>
            <MarkdownRenderer ast={ast} />
          </div>
        )}
      </div>
    </div>
  );
}

render(<App />, document.getElementById("app")!);

import { render } from "preact";
import { useState, useCallback, useEffect, useRef } from "preact/hooks";
import { parse } from "../js/api.js";
import type { Root } from "mdast";
import { MarkdownRenderer } from "./ast-renderer";
import { SyntaxHighlightEditor, type SyntaxHighlightEditorHandle } from "./SyntaxHighlightEditor";

// IndexedDB for content (reliable async storage)
const IDB_NAME = "markdown-editor";
const IDB_STORE = "documents";
const IDB_KEY = "current";

// localStorage for UI state (sync access for initial render)
const UI_STATE_KEY = "markdown-editor-ui";
const DEBOUNCE_DELAY = 300;

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

async function saveToIDB(content: string): Promise<number> {
  const db = await openDB();
  const timestamp = Date.now();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(IDB_STORE, "readwrite");
    const store = tx.objectStore(IDB_STORE);
    const request = store.put({ content, timestamp }, IDB_KEY);
    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(timestamp);
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

// UI State helpers (localStorage for sync access)
interface UIState {
  viewMode: "split" | "editor" | "preview";
  editorMode: "highlight" | "simple";
  cursorPosition: number;
}

function loadUIState(): UIState {
  try {
    const saved = localStorage.getItem(UI_STATE_KEY);
    if (saved) {
      const parsed = JSON.parse(saved);
      return {
        viewMode: parsed.viewMode || "split",
        editorMode: parsed.editorMode || "highlight",
        cursorPosition: parsed.cursorPosition || 0,
      };
    }
  } catch {
    // ignore parse errors
  }
  return { viewMode: "split", editorMode: "highlight", cursorPosition: 0 };
}

function saveUIState(state: Partial<UIState>): void {
  try {
    const current = loadUIState();
    const updated = { ...current, ...state };
    localStorage.setItem(UI_STATE_KEY, JSON.stringify(updated));
  } catch {
    // ignore storage errors
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
type EditorMode = "highlight" | "simple";

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

// Syntax highlight editor icon (colorful brackets)
const HighlightIcon = () => (
  <svg viewBox="0 0 20 20" width="18" height="18" fill="none">
    <text x="2" y="14" fontSize="12" fill="#d73a49" fontFamily="monospace" fontWeight="bold">&lt;</text>
    <text x="8" y="14" fontSize="12" fill="#22863a" fontFamily="monospace">/</text>
    <text x="12" y="14" fontSize="12" fill="#0366d6" fontFamily="monospace" fontWeight="bold">&gt;</text>
  </svg>
);

// Simple textarea icon (plain text)
const SimpleIcon = () => (
  <svg viewBox="0 0 20 20" width="18" height="18" fill="currentColor">
    <rect x="2" y="2" width="16" height="16" rx="1" stroke="currentColor" strokeWidth="1.5" fill="none" />
    <line x1="5" y1="6" x2="15" y2="6" stroke="currentColor" strokeWidth="1" opacity="0.5" />
    <line x1="5" y1="9" x2="13" y2="9" stroke="currentColor" strokeWidth="1" opacity="0.5" />
    <line x1="5" y1="12" x2="14" y2="12" stroke="currentColor" strokeWidth="1" opacity="0.5" />
    <line x1="5" y1="15" x2="10" y2="15" stroke="currentColor" strokeWidth="1" opacity="0.5" />
  </svg>
);

function App() {
  // Load UI state synchronously for initial render
  const initialUIState = loadUIState();

  const [source, setSource] = useState("");
  const [ast, setAst] = useState<Root | null>(null);
  const [cursorPosition, setCursorPosition] = useState(initialUIState.cursorPosition);
  const [isInitialized, setIsInitialized] = useState(false);
  const editorRef = useRef<SyntaxHighlightEditorHandle>(null);
  const [isDark, toggleDark] = useDarkMode();
  const [saveStatus, setSaveStatus] = useState<"saved" | "saving" | "idle">("idle");
  const [viewMode, setViewMode] = useState<ViewMode>(initialUIState.viewMode);
  const [editorMode, setEditorMode] = useState<EditorMode>(initialUIState.editorMode);
  const simpleEditorRef = useRef<HTMLTextAreaElement>(null);

  // Track if content has been modified since load (to avoid saving on initial load)
  const hasModified = useRef(false);
  // Track last synced timestamp for tab sync
  const lastSyncedTimestamp = useRef(0);
  // Track if currently saving (to avoid sync during save)
  const isSaving = useRef(false);

  const previewRef = useRef<HTMLDivElement>(null);
  const debouncedSource = useDebounce(source, DEBOUNCE_DELAY);

  const handleViewModeChange = useCallback((mode: ViewMode) => {
    setViewMode(mode);
    saveUIState({ viewMode: mode });
  }, []);

  const handleEditorModeChange = useCallback((mode: EditorMode) => {
    setEditorMode(mode);
    saveUIState({ editorMode: mode });
  }, []);

  // Keyboard shortcuts for view mode
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.ctrlKey || e.metaKey) {
        if (e.key === "1") {
          e.preventDefault();
          handleViewModeChange("split");
        } else if (e.key === "2") {
          e.preventDefault();
          handleViewModeChange("editor");
        } else if (e.key === "3") {
          e.preventDefault();
          handleViewModeChange("preview");
        }
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [handleViewModeChange]);

  // Load initial content from IndexedDB, fallback to default for first visit
  useEffect(() => {
    async function loadInitialContent() {
      let content = initialMarkdown;
      let timestamp = 0;

      try {
        const idbData = await loadFromIDB();
        if (idbData && idbData.content) {
          content = idbData.content;
          timestamp = idbData.timestamp;
        }
      } catch (e) {
        console.error("Failed to load from IndexedDB:", e);
      }

      setSource(content);
      setAst(parse(content));
      lastSyncedTimestamp.current = timestamp;
      setIsInitialized(true);

      // Focus editor after initialization
      requestAnimationFrame(() => {
        editorRef.current?.focus();
      });
    }

    loadInitialContent();
  }, []);

  // Handle visibility change for tab sync
  useEffect(() => {
    async function handleVisibilityChange() {
      // Only sync when becoming visible
      if (document.visibilityState !== "visible") return;
      // Don't sync while saving or if there are unsaved local changes
      if (isSaving.current || hasModified.current) return;

      try {
        const idbData = await loadFromIDB();
        if (!idbData) return;

        // If IDB has newer content from another tab, sync it
        if (idbData.timestamp > lastSyncedTimestamp.current) {
          setSource(idbData.content);
          setAst(parse(idbData.content));
          lastSyncedTimestamp.current = idbData.timestamp;
        }
      } catch (e) {
        console.error("Failed to sync from IndexedDB:", e);
      }
    }

    document.addEventListener("visibilitychange", handleVisibilityChange);
    return () => document.removeEventListener("visibilitychange", handleVisibilityChange);
  }, []);

  // Save content to IndexedDB with debounce
  useEffect(() => {
    if (!isInitialized) return;
    if (!hasModified.current) return; // Don't save on initial load

    isSaving.current = true;
    setSaveStatus("saving");
    saveToIDB(debouncedSource)
      .then((timestamp) => {
        lastSyncedTimestamp.current = timestamp;
        hasModified.current = false;
        isSaving.current = false;
        setSaveStatus("saved");
        setTimeout(() => setSaveStatus("idle"), 1000);
      })
      .catch((e) => {
        console.error("Failed to save to IndexedDB:", e);
        isSaving.current = false;
        setSaveStatus("idle");
      });
  }, [debouncedSource, isInitialized]);

  // Sync preview scroll with cursor position
  useEffect(() => {
    if (!previewRef.current || !ast) return;

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
    hasModified.current = true;
    setSource(newSource);
    setAst(parse(newSource));
  }, []);

  const handleCursorChange = useCallback((position: number) => {
    setCursorPosition(position);
    saveUIState({ cursorPosition: position });
  }, []);

  // Don't render until initialized to prevent flash of default content
  if (!isInitialized || ast === null) {
    return null;
  }

  return (
    <div class="app-container">
      <header class="toolbar">
        <div class="toolbar-left">
          <div class="view-mode-buttons">
            <button
              class={`view-mode-btn ${viewMode === "split" ? "active" : ""}`}
              onClick={() => handleViewModeChange("split")}
              title="Split view (Ctrl+1)"
            >
              <SplitIcon />
            </button>
            <button
              class={`view-mode-btn ${viewMode === "editor" ? "active" : ""}`}
              onClick={() => handleViewModeChange("editor")}
              title="Editor only (Ctrl+2)"
            >
              <EditorIcon />
            </button>
            <button
              class={`view-mode-btn ${viewMode === "preview" ? "active" : ""}`}
              onClick={() => handleViewModeChange("preview")}
              title="Preview only (Ctrl+3)"
            >
              <PreviewIcon />
            </button>
          </div>
          <div class="editor-mode-buttons">
            <button
              class={`view-mode-btn ${editorMode === "highlight" ? "active" : ""}`}
              onClick={() => handleEditorModeChange("highlight")}
              title="Syntax highlight editor"
            >
              <HighlightIcon />
            </button>
            <button
              class={`view-mode-btn ${editorMode === "simple" ? "active" : ""}`}
              onClick={() => handleEditorModeChange("simple")}
              title="Simple text editor"
            >
              <SimpleIcon />
            </button>
          </div>
          <span class={`save-status ${saveStatus}`}>
            {saveStatus === "saving" && "Saving..."}
            {saveStatus === "saved" && "Saved"}
          </span>
        </div>
        <div class="toolbar-actions">
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
            {editorMode === "highlight" ? (
              <SyntaxHighlightEditor
                ref={editorRef}
                value={source}
                onChange={handleChange}
                onCursorChange={handleCursorChange}
                initialCursorPosition={initialUIState.cursorPosition}
              />
            ) : (
              <textarea
                ref={simpleEditorRef}
                class="simple-editor"
                value={source}
                onInput={(e) => handleChange((e.target as HTMLTextAreaElement).value)}
                spellcheck={false}
              />
            )}
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

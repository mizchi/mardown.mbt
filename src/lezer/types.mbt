///| Lezer-inspired incremental parser types for MoonBit

///|

///| This module provides core data structures compatible with Lezer's design,

///| optimized for MoonBit and integration with markdown.mbt.

///|

///| Key design principles:

///| - Compact memory representation (inspired by Lezer's 64-bit/node)

///| - Efficient tree traversal via TreeCursor

///| - Compatible with markdown.mbt's Span type

// =============================================================================
// Node Types
// =============================================================================

///|
/// Node type identifier with metadata
pub(all) struct NodeType {
  /// Unique identifier for this node type
  id : Int
  /// Human-readable name (e.g., "FunctionDeclaration", "String")
  name : String
  /// Whether this is an error node
  is_error : Bool
} derive(Eq, Show)

///|
/// Create a new node type
pub fn NodeType::new(id : Int, name : String) -> NodeType {
  { id, name, is_error: false }
}

///|
/// Create an error node type
pub fn NodeType::error(id : Int) -> NodeType {
  { id, name: "Error", is_error: true }
}

// =============================================================================
// Tree Buffer (Compact Storage)
// =============================================================================

///| Compact storage for syntax tree nodes

///|

///| Each node is stored as 4 integers: [type_id, from, to, size]

///| where size is the total number of integers used by this node and its children.

///|

///|
/// This is inspired by Lezer's TreeBuffer which uses Uint16Array.
pub(all) struct TreeBuffer {
  /// Raw data: [type_id, from, to, size, ...]
  data : Array[Int]
  /// Node type registry
  node_types : Array[NodeType]
}

///|
/// Create an empty TreeBuffer
pub fn TreeBuffer::new(node_types : Array[NodeType]) -> TreeBuffer {
  { data: [], node_types }
}

///|
/// Number of nodes in the buffer
pub fn TreeBuffer::node_count(self : TreeBuffer) -> Int {
  // Each node takes 4 integers
  self.data.length() / 4
}

///|
/// Append a leaf node (no children)
pub fn TreeBuffer::push_leaf(
  self : TreeBuffer,
  type_id : Int,
  from : Int,
  to : Int,
) -> Unit {
  self.data.push(type_id)
  self.data.push(from)
  self.data.push(to)
  self.data.push(4) // size = 4 (just this node)
}

///|
/// Get node info at index
pub fn TreeBuffer::get_node(
  self : TreeBuffer,
  index : Int,
) -> (Int, Int, Int, Int)? {
  let offset = index * 4
  if offset + 4 > self.data.length() {
    return None
  }
  Some(
    (
      self.data[offset],
      self.data[offset + 1],
      self.data[offset + 2],
      self.data[offset + 3],
    ),
  )
}

// =============================================================================
// Tree (Main Syntax Tree)
// =============================================================================

///| Syntax tree node

///|

///| Trees can be either:

///| - Regular nodes with child Trees

///|
/// - Buffer-backed subtrees for compact storage of many small nodes
pub(all) enum Tree {
  /// Regular node with explicit children
  Node(node_type~ : NodeType, from~ : Int, to~ : Int, children~ : Array[Tree])
  /// Leaf node (no children)
  Leaf(node_type~ : NodeType, from~ : Int, to~ : Int)
  /// Buffer-backed subtree (for memory efficiency)
  Buffered(buffer~ : TreeBuffer, from~ : Int, to~ : Int)
}

///|
/// Get the start position of a tree
pub fn Tree::from(self : Tree) -> Int {
  match self {
    Node(from~, ..) => from
    Leaf(from~, ..) => from
    Buffered(from~, ..) => from
  }
}

///|
/// Get the end position of a tree
pub fn Tree::to(self : Tree) -> Int {
  match self {
    Node(to~, ..) => to
    Leaf(to~, ..) => to
    Buffered(to~, ..) => to
  }
}

///|
/// Get the node type (returns None for Buffered trees)
pub fn Tree::node_type(self : Tree) -> NodeType? {
  match self {
    Node(node_type~, ..) => Some(node_type)
    Leaf(node_type~, ..) => Some(node_type)
    Buffered(..) => None
  }
}

///|
/// Get the length of the tree
pub fn Tree::length(self : Tree) -> Int {
  self.to() - self.from()
}

///|
/// Create a leaf node
pub fn Tree::leaf(node_type : NodeType, from : Int, to : Int) -> Tree {
  Leaf(node_type~, from~, to~)
}

///|
/// Create a node with children
pub fn Tree::node(
  node_type : NodeType,
  from : Int,
  to : Int,
  children : Array[Tree],
) -> Tree {
  Node(node_type~, from~, to~, children~)
}

///|
/// Get children (empty for Leaf and Buffered)
pub fn Tree::children(self : Tree) -> Array[Tree] {
  match self {
    Node(children~, ..) => children
    Leaf(..) => []
    Buffered(..) => [] // TODO: expand buffer to children
  }
}

// =============================================================================
// Tree Cursor (Efficient Traversal)
// =============================================================================

///|
/// Stack frame for tree traversal
struct CursorFrame {
  tree : Tree
  child_index : Int
}

///| Efficient tree traversal cursor

///|

///|
/// Allows walking the tree without allocating new node objects.
pub(all) struct TreeCursor {
  /// Root tree
  root : Tree
  /// Navigation stack: (tree, current_child_index)
  priv stack : Array[CursorFrame]
  /// Current node
  priv mut current : Tree
}

///|
/// Create a cursor at the root of a tree
pub fn TreeCursor::new(tree : Tree) -> TreeCursor {
  { root: tree, stack: [], current: tree }
}

///|
/// Get current node's start position
pub fn TreeCursor::from(self : TreeCursor) -> Int {
  self.current.from()
}

///|
/// Get current node's end position
pub fn TreeCursor::to(self : TreeCursor) -> Int {
  self.current.to()
}

///|
/// Get current node's type
pub fn TreeCursor::node_type(self : TreeCursor) -> NodeType? {
  self.current.node_type()
}

///|
/// Get current node's name
pub fn TreeCursor::name(self : TreeCursor) -> String {
  match self.current.node_type() {
    Some(t) => t.name
    None => "<buffered>"
  }
}

///|
/// Move to first child, returns false if no children
pub fn TreeCursor::first_child(self : TreeCursor) -> Bool {
  let children = self.current.children()
  if children.is_empty() {
    return false
  }
  self.stack.push({ tree: self.current, child_index: 0 })
  self.current = children[0]
  true
}

///|
/// Move to next sibling, returns false if no more siblings
pub fn TreeCursor::next_sibling(self : TreeCursor) -> Bool {
  if self.stack.is_empty() {
    return false
  }
  let frame = self.stack[self.stack.length() - 1]
  let parent_children = frame.tree.children()
  let next_index = frame.child_index + 1
  if next_index >= parent_children.length() {
    return false
  }
  // Update the frame's child_index
  self.stack[self.stack.length() - 1] = {
    tree: frame.tree,
    child_index: next_index,
  }
  self.current = parent_children[next_index]
  true
}

///|
/// Move to parent, returns false if at root
pub fn TreeCursor::parent(self : TreeCursor) -> Bool {
  if self.stack.is_empty() {
    return false
  }
  let frame = self.stack.pop()
  self.current = frame.unwrap().tree
  true
}

///|
/// Reset cursor to root
pub fn TreeCursor::reset(self : TreeCursor) -> Unit {
  self.stack.clear()
  self.current = self.root
}

///|
/// Check if cursor is at root
pub fn TreeCursor::at_root(self : TreeCursor) -> Bool {
  self.stack.is_empty()
}

///|
/// Get depth in tree (0 = root)
pub fn TreeCursor::depth(self : TreeCursor) -> Int {
  self.stack.length()
}

// =============================================================================
// Tree Iteration
// =============================================================================

///|
/// Collect all nodes in depth-first order
fn Tree::collect_nodes(self : Tree, nodes : Array[Tree]) -> Unit {
  nodes.push(self)
  for child in self.children() {
    child.collect_nodes(nodes)
  }
}

///|
/// Iterate over all nodes in depth-first order
pub fn Tree::iter(self : Tree) -> Iter[Tree] {
  let nodes : Array[Tree] = []
  self.collect_nodes(nodes)
  nodes.iter()
}

///|
/// Find the deepest node containing a position
pub fn Tree::resolve(self : Tree, pos : Int) -> Tree? {
  if pos < self.from() || pos > self.to() {
    return None
  }
  // Try to find a child that contains the position
  for child in self.children() {
    if pos >= child.from() && pos <= child.to() {
      return child.resolve(pos)
    }
  }
  // No child contains it, return self
  Some(self)
}

///|
/// Tests for Lezer-inspired tree types

// =============================================================================
// NodeType Tests
// =============================================================================

test "NodeType::new creates regular node type" {
  let nt = NodeType::new(1, "Identifier")
  assert_eq(nt.id, 1)
  assert_eq(nt.name, "Identifier")
  assert_eq(nt.is_error, false)
}

///|
test "NodeType::error creates error node type" {
  let nt = NodeType::error(0)
  assert_eq(nt.id, 0)
  assert_eq(nt.name, "Error")
  assert_eq(nt.is_error, true)
}

// =============================================================================
// Tree Tests
// =============================================================================

///|
test "Tree::leaf creates leaf node" {
  let nt = NodeType::new(1, "Number")
  let tree = Tree::leaf(nt, 0, 5)
  assert_eq(tree.from(), 0)
  assert_eq(tree.to(), 5)
  assert_eq(tree.length(), 5)
  assert_eq(tree.node_type(), Some(nt))
  assert_eq(tree.children().length(), 0)
}

///|
test "Tree::node creates node with children" {
  let num_type = NodeType::new(1, "Number")
  let expr_type = NodeType::new(2, "BinaryExpression")
  let left = Tree::leaf(num_type, 0, 1)
  let right = Tree::leaf(num_type, 4, 5)
  let tree = Tree::node(expr_type, 0, 5, [left, right])
  assert_eq(tree.from(), 0)
  assert_eq(tree.to(), 5)
  assert_eq(tree.children().length(), 2)
}

///|
test "Tree::resolve finds deepest node at position" {
  // Build tree: BinaryExpr(Num(0-1), Num(4-5))
  let num_type = NodeType::new(1, "Number")
  let expr_type = NodeType::new(2, "BinaryExpression")
  let left = Tree::leaf(num_type, 0, 1)
  let right = Tree::leaf(num_type, 4, 5)
  let tree = Tree::node(expr_type, 0, 5, [left, right])

  // Position 0 should resolve to left child
  let resolved = tree.resolve(0)
  assert_true(resolved is Some(_))
  assert_eq(resolved.unwrap().from(), 0)
  assert_eq(resolved.unwrap().to(), 1)

  // Position 4 should resolve to right child
  let resolved2 = tree.resolve(4)
  assert_true(resolved2 is Some(_))
  assert_eq(resolved2.unwrap().from(), 4)
  assert_eq(resolved2.unwrap().to(), 5)

  // Position 2 (between children) should resolve to parent
  let resolved3 = tree.resolve(2)
  assert_true(resolved3 is Some(_))
  assert_eq(resolved3.unwrap().from(), 0)
  assert_eq(resolved3.unwrap().to(), 5)

  // Position outside should return None
  let resolved4 = tree.resolve(10)
  assert_true(resolved4 is None)
}

// =============================================================================
// TreeCursor Tests
// =============================================================================

///|
test "TreeCursor navigates tree" {
  let num_type = NodeType::new(1, "Number")
  let expr_type = NodeType::new(2, "BinaryExpression")
  let left = Tree::leaf(num_type, 0, 1)
  let right = Tree::leaf(num_type, 4, 5)
  let tree = Tree::node(expr_type, 0, 5, [left, right])
  let cursor = TreeCursor::new(tree)

  // Start at root
  assert_true(cursor.at_root())
  assert_eq(cursor.depth(), 0)
  assert_eq(cursor.name(), "BinaryExpression")

  // Move to first child
  assert_true(cursor.first_child())
  assert_eq(cursor.depth(), 1)
  assert_eq(cursor.name(), "Number")
  assert_eq(cursor.from(), 0)

  // Move to sibling
  assert_true(cursor.next_sibling())
  assert_eq(cursor.name(), "Number")
  assert_eq(cursor.from(), 4)

  // No more siblings
  assert_false(cursor.next_sibling())

  // Go back to parent
  assert_true(cursor.parent())
  assert_true(cursor.at_root())
  assert_eq(cursor.name(), "BinaryExpression")

  // Can't go above root
  assert_false(cursor.parent())
}

///|
test "TreeCursor::reset returns to root" {
  let num_type = NodeType::new(1, "Number")
  let expr_type = NodeType::new(2, "Expr")
  let child = Tree::leaf(num_type, 0, 1)
  let tree = Tree::node(expr_type, 0, 1, [child])
  let cursor = TreeCursor::new(tree)
  assert_true(cursor.first_child())
  assert_eq(cursor.depth(), 1)
  cursor.reset()
  assert_true(cursor.at_root())
  assert_eq(cursor.depth(), 0)
}

// =============================================================================
// Tree Iteration Tests
// =============================================================================

///|
test "Tree::iter visits all nodes depth-first" {
  let a_type = NodeType::new(1, "A")
  let b_type = NodeType::new(2, "B")
  let c_type = NodeType::new(3, "C")

  // Tree: A(B, C)
  let b = Tree::leaf(b_type, 0, 1)
  let c = Tree::leaf(c_type, 1, 2)
  let a = Tree::node(a_type, 0, 2, [b, c])
  let names : Array[String] = []
  for node in a.iter() {
    match node.node_type() {
      Some(t) => names.push(t.name)
      None => ()
    }
  }
  assert_eq(names.length(), 3)
  assert_eq(names[0], "A")
  assert_eq(names[1], "B")
  assert_eq(names[2], "C")
}

// =============================================================================
// TreeBuffer Tests
// =============================================================================

///|
test "TreeBuffer stores nodes compactly" {
  let types = [NodeType::new(1, "Num"), NodeType::new(2, "Op")]
  let buffer = TreeBuffer::new(types)
  assert_eq(buffer.node_count(), 0)
  buffer.push_leaf(1, 0, 3)
  assert_eq(buffer.node_count(), 1)
  let node = buffer.get_node(0)
  assert_true(node is Some(_))
  let (type_id, from, to, size) = node.unwrap()
  assert_eq(type_id, 1)
  assert_eq(from, 0)
  assert_eq(to, 3)
  assert_eq(size, 4)
}

// =============================================================================
// Additional TreeBuffer Tests
// =============================================================================

///|
test "TreeBuffer stores multiple nodes" {
  let types = [NodeType::new(1, "A"), NodeType::new(2, "B")]
  let buffer = TreeBuffer::new(types)
  buffer.push_leaf(1, 0, 5)
  buffer.push_leaf(2, 5, 10)
  buffer.push_leaf(1, 10, 15)
  assert_eq(buffer.node_count(), 3)
  let node0 = buffer.get_node(0).unwrap()
  assert_eq(node0.0, 1) // type_id
  assert_eq(node0.1, 0) // from
  assert_eq(node0.2, 5) // to
  let node1 = buffer.get_node(1).unwrap()
  assert_eq(node1.0, 2)
  assert_eq(node1.1, 5)
  assert_eq(node1.2, 10)
  let node2 = buffer.get_node(2).unwrap()
  assert_eq(node2.0, 1)
  assert_eq(node2.1, 10)
  assert_eq(node2.2, 15)
}

///|
test "TreeBuffer::get_node returns None for invalid index" {
  let types = [NodeType::new(1, "A")]
  let buffer = TreeBuffer::new(types)
  buffer.push_leaf(1, 0, 5)
  assert_true(buffer.get_node(0) is Some(_))
  assert_true(buffer.get_node(1) is None)
  assert_true(buffer.get_node(100) is None)
}

// =============================================================================
// Additional Tree Tests
// =============================================================================

///|
test "Tree::length returns correct length" {
  let nt = NodeType::new(1, "Test")
  let tree = Tree::leaf(nt, 10, 25)
  assert_eq(tree.length(), 15)
}

///|
test "Tree::node with empty children" {
  let nt = NodeType::new(1, "Empty")
  let tree = Tree::node(nt, 0, 10, [])
  assert_eq(tree.children().length(), 0)
  assert_eq(tree.from(), 0)
  assert_eq(tree.to(), 10)
}

///|
test "Tree::node_type returns None for Buffered" {
  let types = [NodeType::new(1, "A")]
  let buffer = TreeBuffer::new(types)
  buffer.push_leaf(1, 0, 5)
  let tree = Tree::Buffered(buffer~, from=0, to=5)
  assert_true(tree.node_type() is None)
}

///|
test "Tree::children returns empty for Buffered" {
  let types = [NodeType::new(1, "A")]
  let buffer = TreeBuffer::new(types)
  buffer.push_leaf(1, 0, 5)
  let tree = Tree::Buffered(buffer~, from=0, to=5)
  assert_eq(tree.children().length(), 0)
}

// =============================================================================
// Additional TreeCursor Tests
// =============================================================================

///|
test "TreeCursor on leaf node" {
  let nt = NodeType::new(1, "Leaf")
  let tree = Tree::leaf(nt, 0, 5)
  let cursor = TreeCursor::new(tree)
  assert_eq(cursor.name(), "Leaf")
  assert_false(cursor.first_child())
  assert_false(cursor.next_sibling())
  assert_false(cursor.parent())
}

///|
test "TreeCursor handles single-level tree" {
  let root_type = NodeType::new(1, "Root")
  let child_type = NodeType::new(2, "Child")
  let c1 = Tree::leaf(child_type, 0, 1)
  let c2 = Tree::leaf(child_type, 1, 2)
  let c3 = Tree::leaf(child_type, 2, 3)
  let root = Tree::node(root_type, 0, 3, [c1, c2, c3])
  let cursor = TreeCursor::new(root)

  // Go to first child
  assert_true(cursor.first_child())
  assert_eq(cursor.from(), 0)

  // Go through siblings
  assert_true(cursor.next_sibling())
  assert_eq(cursor.from(), 1)
  assert_true(cursor.next_sibling())
  assert_eq(cursor.from(), 2)

  // No more siblings
  assert_false(cursor.next_sibling())

  // Back to parent
  assert_true(cursor.parent())
  assert_eq(cursor.name(), "Root")
}

// =============================================================================
// Tree::resolve Edge Cases
// =============================================================================

///|
test "Tree::resolve at boundary positions" {
  let num_type = NodeType::new(1, "Number")
  let expr_type = NodeType::new(2, "Expr")

  // Tree: Expr(0-10) contains Number(2-5)
  let num = Tree::leaf(num_type, 2, 5)
  let expr = Tree::node(expr_type, 0, 10, [num])

  // Position 0 - at start of expr but before num
  let r0 = expr.resolve(0)
  assert_true(r0 is Some(_))
  assert_eq(r0.unwrap().node_type().unwrap().name, "Expr")

  // Position 2 - at start of num
  let r2 = expr.resolve(2)
  assert_true(r2 is Some(_))
  assert_eq(r2.unwrap().node_type().unwrap().name, "Number")

  // Position 5 - at end of num
  let r5 = expr.resolve(5)
  assert_true(r5 is Some(_))
  assert_eq(r5.unwrap().node_type().unwrap().name, "Number")

  // Position 6 - after num but still in expr
  let r6 = expr.resolve(6)
  assert_true(r6 is Some(_))
  assert_eq(r6.unwrap().node_type().unwrap().name, "Expr")

  // Position 10 - at end of expr (inclusive)
  let r10 = expr.resolve(10)
  assert_true(r10 is Some(_))
  assert_eq(r10.unwrap().node_type().unwrap().name, "Expr")

  // Position 11 - outside tree
  let r11 = expr.resolve(11)
  assert_true(r11 is None)
}

///|
test "Tree::resolve with multiple children" {
  let num_type = NodeType::new(1, "Num")
  let op_type = NodeType::new(2, "Op")
  let expr_type = NodeType::new(3, "BinExpr")

  // BinExpr(0-9): Num(0-2), Op(3-4), Num(5-8)
  // Using non-overlapping ranges to avoid boundary ambiguity
  let left = Tree::leaf(num_type, 0, 2)
  let op = Tree::leaf(op_type, 3, 4)
  let right = Tree::leaf(num_type, 5, 8)
  let expr = Tree::node(expr_type, 0, 9, [left, op, right])

  // Position in left
  let r1 = expr.resolve(1)
  assert_eq(r1.unwrap().node_type().unwrap().name, "Num")
  assert_eq(r1.unwrap().from(), 0)

  // Position in op
  let r3 = expr.resolve(3)
  assert_eq(r3.unwrap().node_type().unwrap().name, "Op")

  // Position in gap (between left and op) - resolves to parent
  let r_gap = expr.resolve(2)
  // Position 2 is at boundary of left(0-2), so it's still in left
  assert_eq(r_gap.unwrap().node_type().unwrap().name, "Num")

  // Position in right
  let r6 = expr.resolve(6)
  assert_eq(r6.unwrap().node_type().unwrap().name, "Num")
  assert_eq(r6.unwrap().from(), 5)
}

// =============================================================================
// Tree Iteration Edge Cases
// =============================================================================

///|
test "Tree::iter on empty tree" {
  let nt = NodeType::new(1, "Empty")
  let tree = Tree::node(nt, 0, 0, [])
  let count = tree.iter().count()
  assert_eq(count, 1) // Just the root
}

///|
test "Tree::iter visits in correct order" {
  // Build a specific tree structure
  let a = NodeType::new(1, "A")
  let b = NodeType::new(2, "B")
  let c = NodeType::new(3, "C")
  let d = NodeType::new(4, "D")

  // Structure: A(B(D), C)
  let d_node = Tree::leaf(d, 0, 1)
  let b_node = Tree::node(b, 0, 2, [d_node])
  let c_node = Tree::leaf(c, 2, 3)
  let a_node = Tree::node(a, 0, 3, [b_node, c_node])
  let names : Array[String] = []
  for node in a_node.iter() {
    match node.node_type() {
      Some(t) => names.push(t.name)
      None => ()
    }
  }

  // Depth-first: A, B, D, C
  assert_eq(names.length(), 4)
  assert_eq(names[0], "A")
  assert_eq(names[1], "B")
  assert_eq(names[2], "D")
  assert_eq(names[3], "C")
}

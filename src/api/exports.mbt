///| FFI exports for AST access

///| Global document storage for AST access
let ast_documents : Map[Int, @markdown.Document] = {}

///| Next available handle ID
let ast_next_handle : Ref[Int] = Ref::new(1)

///| Parse markdown and return handle for AST access
pub fn md_parse_to_ast(source : String) -> Int {
  let result = @markdown.parse(source)
  let handle = ast_next_handle.val
  ast_next_handle.val = handle + 1
  ast_documents[handle] = result.document
  handle
}

///| Get AST as JSON string from handle
///| Returns empty string if handle is invalid
pub fn md_get_ast(handle : Int) -> String {
  match ast_documents.get(handle) {
    Some(doc) => document_to_json(doc)
    None => ""
  }
}

///| Free AST handle
pub fn md_free_ast(handle : Int) -> Unit {
  ast_documents.remove(handle)
}

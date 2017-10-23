open Core

(* a simple table *)
type symbol_table = { previous: symbol_table option; symbols: declaration String.Table.t; }
and declaration =
| VariableDeclaration of int
| GlobalVariableDeclaration of int
| FunctionDeclaration of {
  index: int;
  parameters: symbol_table;
  locals: symbol_table;
}

exception Error of string

let rec count_symbols test_symbol table =
  let num_symbols = ref 0 in
  Hashtbl.iter_vals table.symbols ~f:(
    fun a -> if test_symbol a then num_symbols := !num_symbols + 1
  );
  match table.previous with
  (* not tail-recursive *)
  | Some prev -> !num_symbols + (count_symbols test_symbol prev)
  | None -> !num_symbols

let number_of_globals table =
  count_symbols (fun dec -> (
    match dec with
    | GlobalVariableDeclaration dec -> true
    | _ -> false
  )) table

let number_of_functions table =
  count_symbols (fun dec -> (
    match dec with
    | FunctionDeclaration dec -> true
    | _ -> false
  )) table

let rec print_table ?level:(l=0) table =
  Hashtbl.iter_keys table.symbols ~f:(
    fun a ->
      match Hashtbl.find table.symbols a with
      | None -> ()
      | Some dec -> (
        match dec with
        | FunctionDeclaration dec ->
          print_string (Ast.print_level l);
          Printf.printf "Function: %s : %d\n%!" a dec.index;          
          print_table ~level:(l+1) dec.parameters;
          print_table ~level:(l+1) dec.locals;
        | GlobalVariableDeclaration dec ->
          print_string (Ast.print_level l);
          Printf.printf "Global: %s : %d\n%!" a dec;
        | VariableDeclaration dec ->
          print_string (Ast.print_level l);
          Printf.printf "Local: %s : %d\n%!" a dec          
      )
  )

let number_of_variables table =
  count_symbols (fun dec -> (
    match dec with
    | VariableDeclaration dec -> true
    | _ -> false
  )) table

let rec find_symbol symbol table =
  let search = Hashtbl.find table.symbols symbol in
  if search == None then (
    match table.previous with
    | None -> None
    | Some t -> find_symbol symbol t
  ) else search

let rec add_symbol (symbol:Ast.node) table =
  let symbol_string, declaration = (match symbol with
  | Ast.FunctionDeclaration s ->
    let parameters = populate_symbol_table s.parameters ~s:({
      previous = Some table;
      symbols = String.Table.create();
    }) in (
    s.id,
    FunctionDeclaration({
      index = number_of_functions table;
      parameters;
      locals = populate_symbol_table s.code ~s:({
        previous = Some parameters;
        symbols = String.Table.create();
      });
    }))
  | Ast.ParamDeclaration s ->
    (s, VariableDeclaration(number_of_variables table))
  | Ast.VariableDeclaration s ->
    (match table.previous with
      | None ->
        (s.id, GlobalVariableDeclaration(number_of_globals table))
      | Some p ->
        (s.id, VariableDeclaration(number_of_variables table))    
    )
  ) in
  if IsItScary.its_scary symbol_string then
      Hashtbl.set table.symbols ~key:symbol_string ~data:declaration
  else raise (Error (Printf.sprintf "Look, if you want to program here, you're going to have to use spooky variable names. Names like: %s just aren't going to cut it.%!" symbol_string))

and populate_symbol_table ?s:(symbols={
  previous=None;
  symbols=String.Table.create();
}) (ast:Ast.node) : symbol_table =
  let rec visit_ast (curr_node:Ast.node) =
    match curr_node with
    | Ast.FunctionDeclaration syntax -> add_symbol curr_node symbols
    | Ast.VariableDeclaration syntax -> add_symbol curr_node symbols
    | Ast.ParamDeclaration syntax -> add_symbol curr_node symbols
    | Ast.Program syntax -> List.iter ~f:visit_ast syntax.children  
    | Ast.StatementList syntax -> List.iter ~f:visit_ast syntax.children
    | Ast.ParameterList syntax -> List.iter ~f:visit_ast syntax.children
    | Ast.Statement syntax -> List.iter ~f:visit_ast syntax.children
    | Ast.Reference syntax ->
    if find_symbol syntax symbols == None then
      raise (Error "Ah! You used a variable before you declared it! I'm so scared!")
    | Ast.VariableAssignment syntax ->
    if find_symbol syntax.id symbols == None then
      raise (Error "Ah the terror, the variable you thought was defined was actually a ghost.")
    (* QUESTION: the catchall saves a lot of space, but exhaustiveness would make the code
    more rigorous. Perhaps this is where type refactoring comes into play? at the very least
    the distinction between nonterminals and terminals seems important *)
    | _ -> ()
  in
  visit_ast ast;
  symbols
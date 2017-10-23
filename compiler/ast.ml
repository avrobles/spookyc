open Core

(* TODO: not all of these nodes need a children field. Rename the edges for
nonterminal nodes to something more semantically informative. *)
(* TODO: perhaps these types could be factored into nonterminal nodes, and
terminal nodes *)
type node =
  | Program of { children: node list; }
  | Spookyval of spookyval
  | Reference of string  
  | Expression of { children: node list; }
  | FunctionDeclaration of { id:string; parameters: node; code: node; }
  | FunctionCall of { id:string; children: node list; }
  | ArgumentList of { children: node list; }  
  | StatementList of { children: node list; }
  | ParameterList of { children: node list; }
  | ParamDeclaration of string  
  | VariableDeclaration of { id: string; children: node list; }
  | VariableAssignment of { id: string; children: node list; }
  | ReturnStatement of { children: node list; }
  | IfStatement of { test: node; statements: node list }
  | IfElseStatement of { test: node; if_statements: node list; else_statements: node list }
  | LoopStatement of { test: node; statements: node list }
  | Statement of { children: node list; }
  | Accessor of { store: node; key: node }
  | AssignmentStatement of { id: string; accessors: node list; key: node; value: node }
  | Operator of operator
and operator = 
  | Multiplication of { children: node list; }
  | Addition of { children: node list; }
  | Division of { children: node list; }
  | Subtraction of { children: node list; }
  | Negation of { children: node list; }
  | Not of { inverted: node; }
  | Equal of { a: node; b: node; }
  | Gequal of { a: node; b: node; }
  | Nequal of { a: node; b: node; }
  | Lequal of { a: node; b: node; }
  | Less of { a: node; b: node; }
  | Greater of { a: node; b: node; }
and key_value = string * node
and spookyval =
| Numeric of float
| Spookystring of string
| True
| False
| Void
| Array of node list
| Object of key_value list

let serialize_operator n =
  match n with
  | Multiplication n -> "Multiplication!\n"
  | Addition n -> "Addition!\n"
  | Division n -> "Division!\n"
  | Subtraction n -> "Subtraction!\n"
  | Not n -> "Not!\n"
  | Negation n -> "Negation!\n"
  | Equal n -> "Equal!\n"
  | Gequal n -> "Gequal!\n"
  | Lequal n -> "Lequal!\n"
  | Less n -> "Less!\n"
  | Greater n -> "Greater!\n"
  | Nequal n -> "Nequal!\n"

let rec serialize_node (n: node) =
  match n with
    | Program n -> "Program!"  
    | Spookyval n -> Printf.sprintf "Spookyval!: %s%!" (serialize_spookyval n)
    | Expression n -> "Expression!"
    | Reference n -> Printf.sprintf "Reference!: %s%!" n
    | Statement n -> "Statement!"
    | ReturnStatement n -> "ReturnStatement!"    
    | FunctionDeclaration n -> Printf.sprintf "FunctionDeclaration!: %s%!" n.id
    | ParamDeclaration n -> Printf.sprintf "ParamDeclaration!: %s%!" n   
    | FunctionCall n -> Printf.sprintf "FunctionCall!: %s%!" n.id
    | ArgumentList n -> "ArgumentList!"    
    | StatementList n -> "StatementList!"
    | ParameterList n -> "ParameterList!"
    | VariableDeclaration n -> Printf.sprintf "VariableDeclaration!: %s%!" n.id
    | VariableAssignment n -> "VariableAssignment!"
    | IfStatement n -> "IfStatement!"
    | IfElseStatement n -> "IfElseStatement!"
    | LoopStatement n -> "WhileStatement!"
    | Accessor n -> "Accessor!";
    | AssignmentStatement n -> "AssignmentStatement!";
    | Operator n -> serialize_operator n

and serialize_spookyval n =
      match n with
      | Numeric num -> string_of_float num
      | Spookystring st -> st
      | True -> "True"
      | False -> "False"  
      | Void -> "Void"
      | Array a ->
        " 🍫 " ^
        (List.fold_right a ~init:"" ~f:(fun spval acc -> acc ^ (serialize_node spval) ^ " 🍬 ")) ^
        " 🍭 "
      | Object o ->
        " 🍫 " ^ (List.fold_right o ~init:"" ~f:(fun spval acc ->
          let k, sval = spval in
          acc ^ k ^ " 😱 " ^ (serialize_node sval) ^ " 🍬 ")
        ) ^ " 🍭 "

(* TODO: make tail-call recursive *)
let rec print_level l = 
  match l with
  | 0 -> ""
  | _ -> "    " ^ print_level (l - 1)

let rec print_ast ?level:(l=0) (syntax:node) =
  print_string (print_level l);
  print_endline (serialize_node syntax);
  match syntax with
  | Program syntax -> List.iter ~f:(print_ast ~level:(l + 1)) syntax.children  
  | Spookyval syntax -> ()
  | Expression syntax -> List.iter ~f:(print_ast ~level:(l + 1)) syntax.children
  | Reference syntax -> ()
  | FunctionDeclaration syntax ->
    print_ast ~level:(l + 1) syntax.parameters;
    print_ast ~level:(l + 1) syntax.code
  | FunctionCall syntax -> List.iter ~f:(print_ast ~level:(l + 1)) syntax.children
  | ArgumentList syntax -> List.iter ~f:(print_ast ~level:(l + 1)) syntax.children  
  | StatementList syntax -> List.iter ~f:(print_ast ~level:(l + 1)) syntax.children
  | ParameterList syntax -> List.iter ~f:(print_ast ~level:(l + 1)) syntax.children
  | VariableDeclaration syntax -> List.iter ~f:(print_ast ~level:(l + 1)) syntax.children
  | ParamDeclaration syntax -> ()  
  | VariableAssignment syntax -> List.iter ~f:(print_ast ~level:(l + 1)) syntax.children
  | ReturnStatement syntax -> List.iter ~f:(print_ast ~level:(l + 1)) syntax.children
  | IfStatement syntax ->
    print_string (print_level l);
    print_endline "Test code:";  
    print_ast ~level:(l + 1) syntax.test;
    print_string (print_level l);    
    print_endline "Statements:";
    List.iter ~f:(print_ast ~level:(l + 1)) syntax.statements
  | IfElseStatement syntax ->
    print_string (print_level l);  
    print_endline "Test code:";
    print_ast ~level:(l + 1) syntax.test;
    print_string (print_level l);    
    print_endline "If statements:";
    List.iter ~f:(print_ast ~level:(l + 1)) syntax.if_statements;
    print_string (print_level l);   
    print_endline "Else statements:";
    List.iter ~f:(print_ast ~level:(l + 1)) syntax.else_statements
  | LoopStatement syntax ->
    print_string (print_level l);
    print_endline "Test code:";  
    print_ast ~level:(l + 1) syntax.test;
    print_string (print_level l);    
    print_endline "Statements:";
    List.iter ~f:(print_ast ~level:(l + 1)) syntax.statements
  | Statement syntax -> List.iter ~f:(print_ast ~level:(l + 1)) syntax.children
  | Accessor syntax ->
    print_string (print_level (l + 1));  
    print_endline "Store:";
    print_ast ~level:(l + 2) syntax.store;
    print_string (print_level (l + 1));    
    print_endline "Key:";
    print_ast ~level:(l + 2) syntax.key;
  | AssignmentStatement syntax ->
    print_string (print_level (l + 1));   
    print_endline "Accessors:";
    List.iter ~f:(print_ast ~level:(l + 2)) syntax.accessors;
    print_string (print_level (l + 1)); 
    print_endline "Key:";
    print_ast ~level:(l+ 2) syntax.key;
    print_string (print_level (l + 1));    
    print_endline "Value:";
    print_ast ~level:(l+ 2) syntax.value
  | Operator syntax -> 
    match syntax with
    | Multiplication syntax -> List.iter ~f:(print_ast ~level:(l + 1)) syntax.children 
    | Addition syntax -> List.iter ~f:(print_ast ~level:(l + 1)) syntax.children 
    | Division syntax -> List.iter ~f:(print_ast ~level:(l + 1)) syntax.children 
    | Subtraction syntax -> List.iter ~f:(print_ast ~level:(l + 1)) syntax.children
    | Negation syntax -> List.iter ~f:(print_ast ~level:(l + 1)) syntax.children
    | Equal syntax ->
      print_ast ~level:(l + 1) syntax.a;
      print_ast ~level:(l + 1) syntax.b
    | Gequal syntax ->
      print_ast ~level:(l + 1) syntax.a;
      print_ast ~level:(l + 1) syntax.b
    | Lequal syntax ->
      print_ast ~level:(l + 1) syntax.a;
      print_ast ~level:(l + 1) syntax.b
    | Less syntax ->
      print_ast ~level:(l + 1) syntax.a;
      print_ast ~level:(l + 1) syntax.b
    | Greater syntax ->
      print_ast ~level:(l + 1) syntax.a;
      print_ast ~level:(l + 1) syntax.b
    | Nequal syntax ->
      print_ast ~level:(l + 1) syntax.a;
      print_ast ~level:(l + 1) syntax.b

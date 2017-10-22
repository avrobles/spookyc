open Core

exception CompileError of string

let add_main_call symbol_table opcodes =
  let main_func_index = (
    match SymbolTable.find_symbol "boo!" symbol_table with
    | None -> raise (CompileError "You need to have a function called boo! in your program. That's the point of entry. Sorry, but that's the meme.")
    | Some dec -> (
      match dec with
        | SymbolTable.GlobalVariableDeclaration m -> raise (CompileError "I'm very scared of your variable that's declared over this language's point of entry. Ahh! If only it were a function. Then I wouldn't be too scared to compile this program.")      
        | SymbolTable.VariableDeclaration m -> raise (CompileError "I'm very scared of your variable that's declared over this language's point of entry. Ahh! If only it were a function. Then I wouldn't be too scared to compile this program.")
        | SymbolTable.FunctionDeclaration m -> m.index
    )
  ) in
  let main_call = [Int32.of_int_exn 10; Int32.of_int_exn main_func_index] in
  List.append opcodes main_call

let call_builtin function_name =
  match function_name with
  | "print_and_then_scream" -> [Int32.of_int_exn 15; Int32.of_int_exn 0]
  | "spooky_input" -> [Int32.of_int_exn 15; Int32.of_int_exn 1]
  | "scary_length" -> [Int32.of_int_exn 15; Int32.of_int_exn 2]
  | _ -> raise (CompileError "Ahhhh! That variable you thought existed actually didn't.")

let rec print_ops ops =
  match ops with
  | [] -> ()
  | a :: tl ->
    print_int (Int32.to_int_exn a);
    print_newline();
    print_ops tl
  
(* TODO: change hardcoded bytecode numbers to constants *)
let rec compile_ast symbol_table syntax =
    match syntax with
    | Ast.Program syntax -> List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node))
    | Ast.Spookyval syntax -> push_spookyval syntax symbol_table
    | Ast.Expression syntax -> List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node))
    | Ast.Reference syntax ->
        let declaration = SymbolTable.find_symbol syntax symbol_table in
        (match declaration with
        | None -> raise (CompileError (Printf.sprintf "You referenced this alien, strange variable outside the domain of my understanding: %s. That makes me scared! When I get scared I don't compile things. Sorry!" syntax))
        | Some declaration -> (
          match declaration with
          | SymbolTable.VariableDeclaration declaration -> [Int32.of_int_exn 6; Int32.of_int_exn declaration]
          | SymbolTable.GlobalVariableDeclaration declaration -> [Int32.of_int_exn 16; Int32.of_int_exn declaration]            
          | SymbolTable.FunctionDeclaration declaration -> raise (CompileError "Too scary for this compiler - you used a function reference in an expression! You lunatic! No compiling.")
          ))
    | Ast.FunctionDeclaration syntax ->
        let declaration = SymbolTable.find_symbol syntax.id symbol_table in
        (match declaration with
        | None -> raise (CompileError (Printf.sprintf "I'm one hundered percent honestly spooked by the fact that you declared a function and it didn't exist in the symbol table. It was this one: %s. Please tweet your program to @FelixTripier, even though it's gonna scare him." syntax.id))
        | Some declaration -> (
            match declaration with
            | SymbolTable.VariableDeclaration declaration -> raise (CompileError "this is actually pretty creepy because this should never ever happen but I guess we thought this function was a variable I don't know what to tell you man")
            | SymbolTable.GlobalVariableDeclaration declaration -> raise (CompileError "this is actually pretty creepy because this should never ever happen but I guess we thought this function was a variable I don't know what to tell you man")            
            | SymbolTable.FunctionDeclaration declaration ->
              let declarations = [
                Int32.of_int_exn 8;
                Int32.of_int_exn declaration.index;
                Int32.of_int_exn (Hashtbl.length declaration.parameters.symbols);
                Int32.of_int_exn (Hashtbl.length declaration.locals.symbols)
              ] in
              let code = compile_ast declaration.locals syntax.code in
              List.append (List.append declarations code) [Int32.of_int_exn 9]
        ))
    | Ast.FunctionCall syntax ->
        let declaration = SymbolTable.find_symbol syntax.id symbol_table in
        (match declaration with
        | None -> List.append
          (List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node)))
          (call_builtin syntax.id)
        | Some declaration -> (
            match declaration with
            | SymbolTable.VariableDeclaration declaration -> raise (CompileError "The variable you thought was a function, you remorseless psychopath, was only a variable. You can't invoke it! No compiling.")
            | SymbolTable.GlobalVariableDeclaration declaration -> raise (CompileError "The variable you thought was a function, you remorseless psychopath, was only a variable. You can't invoke it! No compiling.") 
            | SymbolTable.FunctionDeclaration declaration -> List.append
                (List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node)))
                [Int32.of_int_exn 10; Int32.of_int_exn declaration.index]
        ))
    | Ast.ArgumentList syntax -> List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node))
    | Ast.StatementList syntax -> List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node))
    | Ast.ParameterList syntax -> List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node))
    | Ast.VariableDeclaration syntax -> []
    | Ast.ParamDeclaration syntax -> []
    | Ast.VariableAssignment syntax ->
        let declaration = SymbolTable.find_symbol syntax.id symbol_table in
        (match declaration with
        | None -> raise (CompileError (Printf.sprintf "The variable %s that you assigned a value to... Has never exited! Ah, that's scary!" syntax.id))
        | Some declaration -> (
            match declaration with
            | SymbolTable.VariableDeclaration declaration -> List.append
              (List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node)))
              [Int32.of_int_exn 7; Int32.of_int_exn declaration]
            | SymbolTable.GlobalVariableDeclaration declaration -> List.append
              (List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node)))
              [Int32.of_int_exn 17; Int32.of_int_exn declaration]             
            | SymbolTable.FunctionDeclaration declaration -> raise (CompileError "You can't just reassign function bindings, we live in a society. Barbaric disrespect scares me, and then I get too busy fear-puking to compile programs. Whoops!")
        ))
    | Ast.ReturnStatement syntax -> List.append
        (List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node)))
        [Int32.of_int_exn 11]
    | Ast.Statement syntax -> List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node))
    | Ast.IfStatement syntax -> compile_if_statement syntax.test syntax.statements symbol_table
    | Ast.IfElseStatement syntax -> compile_if_else_statement syntax.test syntax.if_statements syntax.else_statements symbol_table
    | Ast.LoopStatement syntax -> compile_loop_statement syntax.test syntax.statements symbol_table
    | Ast.Accessor syntax -> compile_accessor syntax.store syntax.key symbol_table
    | Ast.AssignmentStatement syntax -> compile_assignment_statement syntax.id syntax.accessors syntax.value syntax.key symbol_table
    | Ast.Operator syntax -> 
      match syntax with
      | Ast.Multiplication syntax -> List.append
        (List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node)))
        [Int32.of_int_exn 4]
      | Ast.Addition syntax -> List.append
        (List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node)))
        [Int32.of_int_exn 2] 
      | Ast.Division syntax -> List.append
        (List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node)))
        [Int32.of_int_exn 5]
      | Ast.Subtraction syntax -> List.append
        (List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node)))
        [Int32.of_int_exn 3]
      | Ast.Negation syntax -> List.append
        (List.fold_left syntax.children ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node)))
        [Int32.of_int_exn 12]
      | Ast.Equal syntax ->
        List.append (List.append (compile_ast symbol_table syntax.a) (compile_ast symbol_table syntax.b))
        [ Int32.of_int_exn 20]
      | Ast.Less syntax ->
        List.append (List.append (compile_ast symbol_table syntax.a) (compile_ast symbol_table syntax.b))
        [ Int32.of_int_exn 21]
      | Ast.Greater syntax ->
        List.append (List.append (compile_ast symbol_table syntax.a) (compile_ast symbol_table syntax.b))
        [ Int32.of_int_exn 22]
      | Ast.Gequal syntax ->
        List.append (List.append (compile_ast symbol_table syntax.a) (compile_ast symbol_table syntax.b))
        [ Int32.of_int_exn 23]
      | Ast.Lequal syntax ->
        List.append (List.append (compile_ast symbol_table syntax.a) (compile_ast symbol_table syntax.b))
        [ Int32.of_int_exn 24]
      | Ast.Nequal syntax ->
        List.append (List.append (compile_ast symbol_table syntax.a) (compile_ast symbol_table syntax.b))
        [ Int32.of_int_exn 28]
      | Ast.Not syntax ->
        List.append (compile_ast symbol_table syntax.inverted) [ Int32.of_int_exn 29 ]

and compile_statements statements symbol_table=
  List.fold_left statements ~init:([]: int32 list) ~f:(fun acc node -> List.append acc (compile_ast symbol_table node))

and compile_if_statement test_code execution_code symbol_table =
    let test = List.append (compile_ast symbol_table test_code) [Int32.of_int_exn 9] in
    let statements = List.append (compile_statements execution_code symbol_table) [Int32.of_int_exn 9] in
    let conditional = List.append test statements in
    List.append [Int32.of_int_exn 25] conditional
        
and compile_if_else_statement test_code true_code false_code symbol_table =
  let test = List.append (compile_ast symbol_table test_code) [Int32.of_int_exn 9] in
  let if_statements = List.append (compile_statements true_code symbol_table) [Int32.of_int_exn 9] in
  let else_statements = List.append (compile_statements false_code symbol_table) [Int32.of_int_exn 9] in
  let conditional = List.append (List.append test if_statements) else_statements in
  List.append [Int32.of_int_exn 26] conditional

and compile_loop_statement test_code execution_code symbol_table =
  let test = List.append (compile_ast symbol_table test_code) [Int32.of_int_exn 9] in
  let statements = List.append (compile_statements execution_code symbol_table) [Int32.of_int_exn 9] in
  let conditional = List.append test statements in
  List.append [Int32.of_int_exn 27] conditional

and compile_accessor store_code key_code symbol_table =
  let store = List.append (compile_ast symbol_table store_code) [Int32.of_int_exn 9] in
  let key = List.append (compile_ast symbol_table key_code) [Int32.of_int_exn 9] in
  let store_key = List.append store key in
  List.append [Int32.of_int_exn 30] store_key

and compile_assignment_statement id accessors value key symbol_table =
  let symbol_index = match SymbolTable.find_symbol id symbol_table with
    | None -> raise (CompileError (Printf.sprintf "AHHH! A program with assignment statements that point to undefined variables! Spooky! Please define: %s%!" id))
    | Some dec -> (
      match dec with
      | SymbolTable.GlobalVariableDeclaration var -> var
      | SymbolTable.VariableDeclaration var -> var
      | _ -> raise (CompileError (Printf.sprintf "Officer please help! Someone's trying to compile a program with and assignment statement that points to non-variable identifier %s! Send help!%!" id))
    ) in
  let assign_to = [(Int32.of_int_exn 34); (Int32.of_int_exn symbol_index)] in
  let accessor_code =
    List.fold_left accessors ~init:([]: int32 list) ~f:(
      fun acc node ->
        let assignment_accessor_opcode = [Int32.of_int_exn 35] in
        let accessor_code = List.append (compile_ast symbol_table node) [Int32.of_int_exn 9] in
        let accessor_stmt = List.append assignment_accessor_opcode accessor_code in
        List.append acc accessor_stmt
    ) in
  let key_code = List.append (compile_ast symbol_table key) [Int32.of_int_exn 9] in
  let value_code = List.append (compile_ast symbol_table value) [Int32.of_int_exn 9] in
  let key_val = List.append key_code value_code in
  let code = List.append accessor_code key_val in
  List.append assign_to code

and push_spookyval spookyval symbol_table =
  match spookyval with
  | Ast.Numeric syntax ->
    let bits = Int64.bits_of_float syntax in
    let top_bits = Int64.to_int32_exn (Int64.shift_right_logical bits 32) in
    let bottom_bits = Int64.to_int32_exn (Int64.bit_and bits (Int64.shift_right_logical Int64.max_value 32)) in
    [(Int32.of_int_exn 1); top_bits; bottom_bits]
  | Ast.Spookystring syntax ->
    let instruction = [(Int32.of_int_exn 13); (Int32.of_int_exn (String.length syntax))] in
    let contents = List.map (List.rev (String.to_list_rev syntax)) ~f:(fun char -> Int32.of_int_exn (Char.to_int char)) in
    List.append instruction contents
  | Ast.True ->
    [(Int32.of_int_exn 18)]
  | Ast.False ->
    [(Int32.of_int_exn 19)]
  | Ast.Void -> [(Int32.of_int_exn 14)]
  | Ast.Array arr ->
    let length = List.length arr in
    let array_start = [(Int32.of_int_exn 31); (Int32.of_int_exn length)] in
    let rec add_key_value_assignments ar index = (
      match ar with
      | [] -> []
      | a :: tl ->
        let key_val_code = compile_key_value_assignment (Ast.Spookyval(Ast.Numeric(Int.to_float index)), a)  symbol_table in
        List.append key_val_code (add_key_value_assignments tl (index + 1))
    ) in
    let contents = add_key_value_assignments arr 0 in
    let arr_code = List.append array_start contents in
    List.append arr_code [(Int32.of_int_exn 9)]
  | Ast.Object obj ->
    let obj_decl = [(Int32.of_int_exn 32)] in
    let rec add_key_value_assignments o =
      (match o with
      | [] -> []
      | a :: tl ->
        let key, spval = a in
        let str_key = (Ast.Spookyval(Ast.Spookystring(key))) in
        List.append (compile_key_value_assignment (str_key, spval) symbol_table)  (add_key_value_assignments tl)
    ) in
    let contents = add_key_value_assignments obj in
    let obj_code = List.append obj_decl contents in
    List.append obj_code [(Int32.of_int_exn 9)]

and compile_key_value_assignment key_val symbol_table =
    let key, spval = key_val in
    let key_opcode = [(Int32.of_int_exn 33)] in
    let key_expression = List.append (compile_ast symbol_table key) [Int32.of_int_exn 9] in
    let value_expression = List.append (compile_ast symbol_table spval) [Int32.of_int_exn 9] in
    let key_val_expr = List.append key_expression value_expression in
    List.append key_opcode key_val_expr

let compile debug filename =
  let input = open_in filename in
  let filebuf = Lexing.from_channel input in
  try
    let ast = Parser.main Lexer.token filebuf in
    let st = (SymbolTable.populate_symbol_table ast) in
    if debug then (
      print_endline "🐛  🐞  🐜  🦋  🕷️  🐝  🐛  🦋  🐞  🐛  🐞  🐜  🐝  🦋  🕷️  🐛  🐝  🦋  🐞  🕷️  🐛  🦋  🐝  🐞  🐛  🐞  🐜  🦋  🐞  🐝  🕷️  🐛  🦋  🐞";
      print_endline "AST: ";
      print_newline();      
      Ast.print_ast ast;
      print_newline();
      print_endline "Symbol Table: ";
      print_newline();
      SymbolTable.print_table st;
      print_newline();
      print_newline();      
    );
    BytecodeInterpreter.interpret ~d:debug (Stream.of_list (add_main_call st (compile_ast st ast)));
    if debug then print_endline "🐛  🐞  🐜  🦋  🕷️  🐝  🐛  🦋  🐞  🐛  🐞  🐜  🐝  🦋  🕷️  🐛  🐝  🦋  🐞  🕷️  🐛  🦋  🐝  🐞  🐛  🐞  🐜  🦋  🐞  🐝  🕷️  🐛  🦋  🐞"    
  with
  | Scarerrors.Error msg ->
    Printf.eprintf "%s\n%!" msg
  | Parser.Error ->
    Printf.eprintf "%s AAAAAAAAAAAAAAAAAAAAA AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA AA!\n%!" (Scarerrors.position filebuf)
  | SymbolTable.Error msg ->
    Printf.eprintf "%s %s\n%!" (Scarerrors.position filebuf) msg
  (* left out bytecode interpreter errors for debugging *)
  | CompileError msg ->
    Printf.eprintf "%s\n%!" msg
  ;
  close_in input

let spec =
  let open Command.Spec in
  empty
  +> flag "-d" no_arg ~doc:"run with scary de'bug'ging output"
  +> anon("filename" %: file)
  
let command =
  Command.basic
  ~summary:"The Spooky language compiler"
  ~readme:(fun () -> "The world's first scary-complete language.")
  spec
  (fun debug filename () -> compile debug filename)

let () =
  Command.run ~version:"0.10" ~build_info:"RWO" command

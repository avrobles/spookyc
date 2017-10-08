open Core

exception Arithmetic_Error of string
exception Unrecognized_Opcode of string
exception Not_enough_op_args of string
exception What_r_u_doing_lol of string

type binary_operation =
  | Add
  | DivideNumeric
  | MultiplyNumeric
  | SubtractNumeric

type spookyval =
  | Numeric of float
  | Spookystring of string

type unary_operation =
  | Negation

type opcode =
  | PushSpookyvalue of spookyval
  | BinaryOperation of binary_operation
  | LoadLocal of int
  | StoreLocal of int
  | UnaryOperation of unary_operation
  | FunctionDeclaration of function_declaration
  | EndFunctionDeclaration
  | FunctionCall of int
  | Return
and function_declaration = {
  symbol: int;
  num_parameters: int;
  num_locals: int;
  op_codes: opcode list;
}

let print_spookyval spval =
  match spval with
  | Numeric sp -> print_float sp
  | Spookystring sp -> print_string sp

let apply_unary_op a op =
  match a with
  | Numeric anum -> (
    match op with
    | Negation -> (Numeric(~-. anum))
  )
  | Spookystring anum -> raise (What_r_u_doing_lol "Negating strings makes me fear puke!")

let apply_binary_op a b op =
  match a, b with
  | Numeric a, Numeric b -> (
    match op with
    | Add -> (Numeric(a +. b))
    | DivideNumeric -> (Numeric(a /. b))
    | MultiplyNumeric -> (Numeric(a *. b))
    | SubtractNumeric -> (Numeric(a -. b))
  )
  | Numeric a, Spookystring b -> (
    match op with
    | Add -> (Spookystring ((string_of_float a) ^ b))
    | _ -> raise (What_r_u_doing_lol "AHHHHHHhhhhHHHHHHHhhhHHHHH! You can't use that operator on a string!!!")
  )
  | Spookystring a, Numeric b -> (
    match op with
    | Add -> (Spookystring (a ^ (string_of_float b)))
    | _ -> raise (What_r_u_doing_lol "AHHHHHHhhhhHHHHHHHhhhHHHHH! You can't use that operator on a string!!!")
  )
  | Spookystring a, Spookystring b -> (
    match op with
    | Add -> (Spookystring (a ^ b))
    | _ -> raise (What_r_u_doing_lol "AHHHHHHhhhhHHHHHHHhhhHHHHH! You can't use that operator on a string!!!")
  )

let apply_constant_unary_op a op =
  [PushSpookyvalue (apply_unary_op a op)]

let apply_constant_binary_op a b op =
  [PushSpookyvalue (apply_binary_op a b op)]

let constant_folding op_codes =
  let constant_folded = List.fold_left op_codes ~f:(fun optimized op -> 
    match optimized, op with
    | [], op -> [op]
    | a :: [], op -> (
      match op, a with
      | UnaryOperation unop, PushSpookyvalue vala -> apply_constant_unary_op vala unop
      | _, _ -> (op :: optimized)
    )
    | a :: b :: tl, op -> (
      match op, a, b with
      | UnaryOperation unop, PushSpookyvalue vala, _ ->
        List.append (apply_constant_unary_op vala unop) (b :: tl)
      | BinaryOperation binop, PushSpookyvalue vala, PushSpookyvalue valb ->
        List.append (apply_constant_binary_op vala valb binop) tl
      | _, _, _ -> (op :: optimized)
    )
  ) ~init:([]:opcode list) in List.rev constant_folded

let optimize_ops op_codes =
  constant_folding op_codes

class virtual_machine = object(self)
  val mutable functions = Int.Table.create()
  val mutable registers = ((Array.create ~len:0 (Numeric(0.0))): spookyval array)
  val mutable op_stack = ([] : spookyval list)

  method set_function function_dec =
    Hashtbl.set functions ~key:function_dec.symbol ~data:function_dec

  method binary_op op =
    match op_stack with
    | [] -> raise (Not_enough_op_args "not enough operator arguments")
    | one_op :: [] -> raise (Not_enough_op_args "not enough operator arguments")
    | a :: b :: tl -> let result = (apply_binary_op a b op) in (result :: tl)
  
  method unary_op op =
    match op_stack with
    | [] -> raise (Not_enough_op_args "not enough operator arguments. You just needed one man, come on.")
    | a :: tl -> let result = (apply_unary_op a op) in (result :: tl)
  
  method push_arguments num_args num_locals =
    print_int num_args;
    print_newline();
    let arguments = Array.create ~len:(num_args + num_locals) (Numeric 0.0) in
    let rec pop args_left =
      let index = num_args - args_left in 
      if args_left == 0 then () else (
      match op_stack with
      | [] -> raise (Not_enough_op_args "Just one operand oh my god it's not that hard.")
      | a :: tl ->
        op_stack <- tl;
        Array.set arguments index a;
        pop (args_left - 1)
      ) in
    pop num_args;
    registers <- arguments

  method interpret_opcodes opcodes = 
    match Stream.peek opcodes, op_stack with
    | None, [] -> None
    | None, result :: tl -> Some result
    | Some op, _ -> (
      match op with
      | BinaryOperation op ->
        print_endline "BinOp";
        Stream.junk opcodes;
        op_stack <- (self#binary_op op);
        self#interpret_opcodes opcodes
      | UnaryOperation op ->
        print_endline "UnOp";      
        Stream.junk opcodes;
        op_stack <- (self#unary_op op);
        self#interpret_opcodes opcodes
      | PushSpookyvalue op ->
        print_string "PushSpookyval: ";
        print_spookyval op;
        print_newline();
        Stream.junk opcodes;
        op_stack <- (op :: op_stack);
        self#interpret_opcodes opcodes
      | LoadLocal op ->
        Printf.printf "LoadLocal: %d\n%!" op;      
        Stream.junk opcodes;
        op_stack <- (Array.get registers op) :: op_stack;
        self#interpret_opcodes opcodes
      | StoreLocal op ->
        Printf.printf "StoreLocal: %d\n%!" op;
        Stream.junk opcodes;
        (match op_stack with
          | [] -> raise (Not_enough_op_args "Oh no! A fairy thief stole the only argument you were supposed to pass to the storeLocal op!")
          | a :: tl ->
            Array.set registers op a;
            self#interpret_opcodes opcodes
        )
      | Return ->
        print_endline "Return";
        Stream.junk opcodes;
        (match op_stack with
        | [] -> None
        | a :: tl -> Some a
      )
      | FunctionDeclaration op ->
        print_endline "FunctionDec";
        Stream.junk opcodes;      
        self#set_function op;
        self#interpret_opcodes opcodes
      | EndFunctionDeclaration ->
        print_endline "EndFunctionDec";
        Stream.junk opcodes;      
        self#interpret_opcodes opcodes
      | FunctionCall op ->
        Printf.printf "FunctionCall: %d\n%!" op;
        Stream.junk opcodes;      
        let called = Hashtbl.find functions op in
        match called with
        | None -> raise (What_r_u_doing_lol "can't call a function before you define it")
        | Some called ->
        let old_registers = registers in
        let old_op_stack = op_stack in
        registers <- (Array.create ~len:0 (Numeric 0.0));
        self#push_arguments called.num_parameters called.num_locals;
        let call_result = self#interpret_opcodes (Stream.of_list called.op_codes) in
        op_stack <- old_op_stack;
        registers <- old_registers;
        call_result
    )
end

let int32_to_char i =
  Char.of_int_exn (Int32.to_int_exn i)

let consume_operand bytes =
  match Stream.peek bytes with
  | None -> raise (Not_enough_op_args "not enough operator arguments")
  | Some a ->
    Stream.junk bytes;
    a

let consume_float bytes =
  let top_bits = Int64.shift_left (Int64.of_int32 (consume_operand bytes)) 32 in
  let bottom_bits = Int64.of_int32 (consume_operand bytes) in
  Int64.float_of_bits (Int64.bit_or top_bits bottom_bits)

let consume_string bytes =
  let length = Int32.to_int_exn (consume_operand bytes) in
  let buffer = Buffer.create 100 in
  let rec read_string n =
    match n with
    | 0 -> Buffer.contents buffer
    | n ->
      Buffer.add_char buffer (int32_to_char (consume_operand bytes));
      read_string (n - 1)
  in read_string length

let consume_operand_pair bytes =
  let a = consume_operand bytes in (a, consume_operand bytes)

let rec buffer_opcodes ?b:(buffered=[]) ops =
  match Stream.peek ops with
  | None -> List.rev buffered
  | Some a ->
    Stream.junk ops;
    buffer_opcodes ~b:(a :: buffered) ops

let rec opcodes bytes =
  let next_opcode i =
    match Stream.peek bytes with
    | None -> None
    | Some num -> (
      match Int32.to_int_exn num with
        | 1 -> Stream.junk bytes; Some (PushSpookyvalue (Numeric (consume_float bytes)))
        | 2 -> Stream.junk bytes; Some (BinaryOperation(Add))
        | 3 -> Stream.junk bytes; Some (BinaryOperation(SubtractNumeric))
        | 4 -> Stream.junk bytes; Some (BinaryOperation(MultiplyNumeric))
        | 5 -> Stream.junk bytes; Some (BinaryOperation(DivideNumeric))
        | 6 -> Stream.junk bytes; Some (LoadLocal (Int32.to_int_exn (consume_operand bytes)))
        | 7 -> Stream.junk bytes; Some (StoreLocal (Int32.to_int_exn (consume_operand bytes)))
        | 8 ->
          Stream.junk bytes;
          let symbol = Int32.to_int_exn (consume_operand bytes) in
          let num_parameters = Int32.to_int_exn (consume_operand bytes) in
          let num_locals = Int32.to_int_exn (consume_operand bytes) in
          let op_codes = optimize_ops (buffer_opcodes (opcodes bytes)) in
          Some (FunctionDeclaration {
            symbol;
            num_parameters;
            num_locals;
            op_codes;
          })
        | 9 -> Stream.junk bytes; None
        | 10 -> Stream.junk bytes; Some (FunctionCall (Int32.to_int_exn (consume_operand bytes)))
        | 11 -> Stream.junk bytes; Some (Return)
        | 12 -> Stream.junk bytes; Some (UnaryOperation(Negation))
        | 13 -> Stream.junk bytes; Some (PushSpookyvalue (Spookystring (consume_string bytes)))
        | op -> raise (Unrecognized_Opcode (Printf.sprintf "couldn't recognize op: %i%!" op))
    )
  in Stream.from(next_opcode)

let interpret bytestream =
  let vm = new virtual_machine in
  let res = vm#interpret_opcodes (opcodes bytestream) in
  match res with
  | None -> print_endline "No result!"
  | Some res ->
    print_spookyval res;
    print_newline()

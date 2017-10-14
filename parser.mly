%token <float> NUMBER
%token PLUS MINUS TIMES DIV
%token LPAREN RPAREN
%token LBRACE RBRACE
%token COMMA
%token SEMICOLON
%token EOF
%token FUNC
%token VOID
%token VAR_DEC
%token <string> STR
%token RETURN
%token <string> ID
%token ASSIGN

%left PLUS MINUS        /* lowest precedence */
%left TIMES DIV         /* medium precedence */
%nonassoc UMINUS        /* highest precedence */

%start <Ast.node> main
%{

  open Ast

%}
%%

main: statements = declarations { Ast.Program { children = statements } }

declarations:
| dec = EOF { [] }
| dec = function_declaration decs = declarations { dec :: decs }
| dec = variable_declaration decs = declarations { dec :: decs }

function_declaration: FUNC id = ID LPAREN plist = parameter_list LBRACE statements = statementseq RBRACE {
    Ast.FunctionDeclaration {
        id;
        code = Ast.StatementList { children = statements; };
        parameters = Ast.ParameterList { children = plist; };
    }
}

statementseq:
| stmt = statement { [stmt] }
| stmt = statement m = statementseq {  stmt :: m }

statement:
| stmt = variable_declaration { stmt }
| stmt = variable_assignment { stmt }
| stmt = return_statement { stmt }
| stmt = void_expr { stmt }

variable_declaration: VAR_DEC id = ID SEMICOLON { Ast.VariableDeclaration { id; children=[]; } }
variable_assignment: id = ID ASSIGN e = expr SEMICOLON { Ast.VariableAssignment { id; children = [e]; } }
return_statement: RETURN ret = expr SEMICOLON { Ast.ReturnStatement { children = [ret]; } }
void_expr: e = expr SEMICOLON { Ast.Expression { children = [e]; } }

parameter_list:
| RPAREN { [] }
| param = ID RPAREN { [ Ast.ParamDeclaration param ] }
| param = ID COMMA p = parameter_list {  (Ast.ParamDeclaration param) :: p }

argument_list:
| RPAREN { [] }
| param = expr RPAREN { [param] }
| param = expr COMMA p = argument_list {  param :: p }

expr:
| v = VOID
    { Ast.Spookyval(Ast.Void) }
| i = NUMBER
    { Ast.Spookyval(Ast.Numeric i) }
| s = STR
    { Ast.Spookyval(Ast.Spookystring s) }
| id = ID
    { Ast.Reference id }
| id = ID LPAREN args = argument_list {
    Ast.FunctionCall {
        id;
        children=[
            Ast.ArgumentList { children = args; };
        ];
    }
}
| LPAREN e = expr RPAREN
    {  Ast.Expression { children = [e]; } }
| e1 = expr PLUS e2 = expr
    {  Ast.Operator(Ast.Addition { children = [e1; e2]; }) }
| e1 = expr MINUS e2 = expr
    {  Ast.Operator(Ast.Subtraction { children = [e1; e2]; }) }
| e1 = expr TIMES e2 = expr
    {  Ast.Operator(Ast.Multiplication { children = [e1; e2]; }) }
| e1 = expr DIV e2 = expr
    {  Ast.Operator(Ast.Division { children = [e1; e2]; }) }
| MINUS e = expr %prec UMINUS
    {  Ast.Operator(Ast.Negation { children = [e]; }) }
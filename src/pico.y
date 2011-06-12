%{
  /* Aqui, pode-se inserir qualquer codigo C necessario ah compilacao
   * final do parser. Sera copiado tal como esta no inicio do y.tab.c
   * gerado por Yacc.
   */
  #include <stdio.h>
  #include <stdlib.h>
  #include "node.h"


%}

%union {
  char* cadeia;
  struct _node * no;
}


%token IDF
%token INT
%token DOUBLE
%token FLOAT
%token CHAR
%token QUOTE
%token DQUOTE
%token LE
%token GE
%token EQ
%token NE
%token AND
%token OR
%token NOT
%token IF
%token THEN
%token ELSE
%token WHILE
%token<cadeia> INT_LIT
%token<cadeia> F_LIT
%token END
%token TRUE
%token FALSE
%token REAL
%token FOR
%token NEXT
%token REPEAT
%token UNTIL
%token CASE
%token CONST

%type<no> code 
%type<no> acoes
%type<no> comando
%type<no> enunciado
%type<no> expr


%start code

 /* A completar com seus tokens - compilar com 'yacc -d' */

%%
code: declaracoes acoes
    | acoes { $$ = $1; syntax_tree = $$;  }
    ;

declaracoes: declaracao ';'
           | declaracoes declaracao ';'
           ;

declaracao: listadeclaracao ':' tipo

listadeclaracao: IDF
               | IDF ',' listadeclaracao
               ;

tipo: tipounico 
    | tipolista
    ;

tipounico: INT
         | DOUBLE
         | FLOAT
         | CHAR
         ;

tipolista: INT '[' listadupla ']'
         | DOUBLE '[' listadupla ']'
         | FLOAT '[' listadupla ']'
         | CHAR '[' listadupla ']'
         ;

listadupla: INT_LIT ':' INT_LIT
          | INT_LIT ':' INT_LIT ',' listadupla
          ;

acoes: comando ';'  { $$ = $1; }
    | comando ';' acoes
    ;

comando: lvalue '=' expr
       | enunciado { $$ = $1;}
       ;

lvalue: IDF
      | IDF '[' listaexpr ']'
      ;

listaexpr: expr
	   | expr ',' listaexpr
	   ;

expr: expr '+' expr {	Node **children;
						pack_nodes(&children,0,$1);
						pack_nodes(&children,1,$3);
						$$ = create_node(0, plus_node, "+", NULL, 2, children);
					}
    | expr '-' expr {	Node **children;
						pack_nodes(&children,0,$1);
						pack_nodes(&children,1,$3);
						$$ = create_node(0, minus_node, "-", NULL, 2, children);
					}
    | expr '*' expr {	Node **children;
						pack_nodes(&children,0,$1);
						pack_nodes(&children,1,$3);
						$$ = create_node(0, mult_node, "*", NULL, 2, children);
					}
    | expr '/' expr {	Node **children;
						pack_nodes(&children,0,$1);
						pack_nodes(&children,1,$3);
						$$ = create_node(0, div_node, "/", NULL, 2, children);
					}
    | '(' expr ')' { $$ = $2; }
    | INT_LIT	{ $$ = create_leaf(0, int_node, $1, NULL); } 
    | F_LIT		{ $$ = create_leaf(0, float_node, $1, NULL); } 
    | lvalue
    | chamaproc
    ;

chamaproc: IDF '(' listaexpr ')'
         ;

enunciado: expr { $$ = $1 ;}
         | IF '(' expbool ')' THEN acoes fiminstcontrole
         | WHILE '(' expbool ')' '{' acoes '}'
         ;

fiminstcontrole: END
               | ELSE acoes END
               ;

expbool: TRUE 
       | FALSE
       | '(' expbool ')'
       | expbool AND expbool
       | expbool OR expbool
       | NOT expbool
       | expr '>' expr
       | expr '<' expr
       | expr LE expr
       | expr GE expr
       | expr EQ expr
       | expr NE expr
       ;
%%
 /* A partir daqui, insere-se qlqer codigo C necessario.
  */

char* progname;
int lineno;
extern FILE* yyin;

int main(int argc, char* argv[]) 
{
   if (argc != 2) {
     printf("uso: %s <input_file>. Try again!\n", argv[0]);
     exit(-1);
   }
   yyin = fopen(argv[1], "r");
   if (!yyin) {
     printf("Uso: %s <input_file>. Could not find %s. Try again!\n", 
         argv[0], argv[1]);
     exit(-1);
   }

   progname = argv[0];

   if (!yyparse()) 
      printf("OKAY.\n");
   else 
      printf("ERROR.\n");
      
   switch(syntax_tree->type) {
	case int_node: 
		printf("A AST se limita a uma folha rotulada por: %s\n", syntax_tree->lexeme);
		break;
	case plus_node:
		printf("Soma de %s com %s.\n", syntax_tree->children[0]->lexeme, syntax_tree->children[1]->lexeme);
		break;
	case minus_node:
		printf("Subtracao de %s com %s.\n", syntax_tree->children[0]->lexeme, syntax_tree->children[1]->lexeme);
		break;
   }
   
   printf("Altura da arvore final: %i.\n", height(syntax_tree));
}

yyerror(char* s) {
  fprintf(stderr, "%s: %s", progname, s);
  fprintf(stderr, "line %d\n", lineno);
}

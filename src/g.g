grammar g;

options {
  output=AST;
  ASTLabelType=Tree;
  tokenVocab=gTokens;
}

@header { 
	package src;
}

@lexer::header {
	package src;
}

		
idTipo 		: ('int' -> ^(DInt))
			;
	
tipo 		: (INT -> ^(Int INT))
			;

prog 		: pre* 'begin' programa* postn* poste* EOF -> ^(SeqInstrucao pre? programa* postn? poste?)
			;

pre 		: 'pre' anotacao+ -> ^(Pre ^(ListaAnot anotacao*))
    		;

postn 		: 'postn' anotacao+ -> ^(Postn ^(ListaAnot anotacao*))
    		;

poste 		: 'poste' anotacao+ -> ^(Poste ^(ListaAnot anotacao*))
    		;

inv 		: '{' anotacao '}' -> ^(Inv ^(ListaAnot anotacao*))
    		;

anotacao 	: (atribuicao ';' -> ^(Atr atribuicao)
			| condicao ';' -> ^(Cond condicao))
			;

programa 	: blocoCodigo -> ^(Cod blocoCodigo)
			;
	
instrucao 	: (if_st -> if_st | while_st -> while_st)
			;

if_st 		: 'if' condicao 'then' blocoCodigo ( else_st -> ^(If condicao blocoCodigo else_st)
			| -> ^(If condicao blocoCodigo ^(SeqInstrucao) ))
			;

else_st 	: 'else' (blocoCodigo -> blocoCodigo | if_st -> if_st )
			;
	
while_st 	: 'while' condicao 'do' blocoCodigo -> ^(While condicao blocoCodigo)
			;
	
blocoCodigo : ':' inv? codigo* 'end' -> ^(SeqInstrucao inv? codigo*)
			;

codigo 		: (atribuicao ';' -> atribuicao
			| instrucao -> instrucao)
			;
	
condicao  	: condicao_ou ('?' expr ':' condicao -> ^(Condicional condicao_ou expr condicao)
			| -> condicao_ou)
			;
	
condicao_ou : (condicao_e -> condicao_e) ('||' c=condicao_e -> ^(Ou $condicao_ou $c))*
			;
	
condicao_e 	: (condicao_comp -> condicao_comp) ('&&' c=condicao_comp -> ^(E $condicao_e $c))*
			;
	
condicao_comp 	: (condicao_ig -> condicao_ig) (('>' c=condicao_ig -> ^(Comp $condicao_comp ^(Maior) $c)
				| '<' c=condicao_ig -> ^(Comp $condicao_comp ^(Menor) $c)
				| '>=' c=condicao_ig -> ^(Comp $condicao_comp ^(MaiorQ) $c)
				| '<=' c=condicao_ig -> ^(Comp $condicao_comp ^(MenorQ) $c)))*
				;

condicao_ig : (expr -> expr) (('!=' e=expr -> ^(Comp $condicao_ig ^(Dif) $e)
			| '==' e=expr -> ^(Comp $condicao_ig ^(Igual) $e)))*
			;

atribuicao 	: ID '=' condicao -> ^(Atribuicao ID condicao)
			;
	
expr 		: (exprNum -> exprNum) (('+' e=exprNum -> ^(ExpNum $expr ^(Mais) $e)
			| '-' e=exprNum -> ^(ExpNum $expr ^(Menos) $e)))*
			;

exprNum		: (op -> op) (('*' o=op -> ^(ExpNum $exprNum ^(Vezes) $o)
			| '/' o=op -> ^(ExpNum $exprNum ^(Divide) $o)
			| '%'  o=op -> ^(ExpNum $exprNum ^(Mod) $o)))*
			;
	
op 			: (opU ID -> ^(opU ^(Id ID))
			| opU tipo -> ^(opU tipo)
			| tipo -> tipo 
			| ID -> ^(Id ID))
			;
	
opU			: ( '+' -> ^(Pos)
			| '-' -> ^(Neg)
			| '!' -> ^(Nao))
			;


CHAR 
@after {
    setText(getText().substring(1, getText().length()-1));
} 	
	: '\'' ( '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\') | ~('\''|'\\') ) '\''
	;

fragment
DIGITO
 	: ('0'..'9')+
	;
	
INT	
	: ('0' | '1'..'9' DIGITO*)
	;
	
ID
	: LETRA ( LETRA | '0'..'9' )*
	;
	
fragment
LETRA	
	: 'a'..'z' | 'A'..'Z' | '_'
	;
	
WS
	: (' '|'\r'|'\t'|'\u000C'|'\n') {$channel=HIDDEN;}
    ;

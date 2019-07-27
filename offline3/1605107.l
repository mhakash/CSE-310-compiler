%option noyywrap

%{
#include"1605107_symbolTable.h"
#include "y.tab.h"




int line_count = 1;
int error_count = 0;


int findLines(string s){
    int oc = 0;
    int nPos = s.find("\n",0);
   
    while(nPos != string::npos){
        oc++;
        nPos = s.find("\n", nPos+1);
    }  

    return oc;
}

%}

DIGIT [0-9]
LETTER [a-zA-Z]
DELIM [ \t\r\f\v]
NEWLINE \n
WHITESPACE [DELIM]+
ID (_|{LETTER})(_|{LETTER}|{DIGIT})*
INTEGER {DIGIT}+
NUMBER {DIGIT}*(\.{DIGIT}+)?(E[+-]?{DIGIT}+)?
ADDOP [+-]
MULOP [*/%]
COMMENT "//"((.*\\\n.*)|(.*))*

%%

{DELIM}+	{}
{NEWLINE} {line_count++;}

"if"        {return IF;}
"for"       {return FOR;}
"do"        {return DO;}
"int"       {return INT;}
"float"     {return FLOAT;}
"void"      {return VOID;}
"switch"    {return SWITCH;}
"default"   {return DEFAULT;}
"else"      {return ELSE;}
"while"     {return WHILE;}
"break"     {return BREAK;}
"char"      {return CHAR;}
"double"    {return DOUBLE;}
"return"    {return RETURN;}
"case"      {return CASE;}
"continue"  {return CONTINUE;}
"println"	{return PRINTLN;}

{INTEGER}   {
                SymbolInfo *s= new  SymbolInfo(yytext, "CONST_INT");
				yylval.symbol = s;
				return CONST_INT;
            }
{NUMBER}    {
                SymbolInfo *s= new  SymbolInfo(yytext, "CONST_FLOAT");
				yylval.symbol = s;
				return CONST_FLOAT;
            }

{ADDOP}     {
                SymbolInfo *s= new  SymbolInfo(yytext, "ADDOP");
			    yylval.symbol = s;
			    return ADDOP;
            }
{MULOP}     {
                SymbolInfo *s= new  SymbolInfo(yytext, "MULOP");
			    yylval.symbol = s;
			    return MULOP;
            }
{ID}        {
                //SymbolInfo *s= table.lookUp(yytext);
              	SymbolInfo*  s = NULL;
				if(s==NULL)
				{
					s= new SymbolInfo(yytext, "ID");
				}
				yylval.symbol = s;;

				return ID;
            }
{COMMENT}	{
				line_count += findLines(yytext);
			}

"++" |
"--"        {return INCOP;}

"<"  |
"<=" |
">"  |
">=" |
"==" |
"!="        {
                SymbolInfo *s= new  SymbolInfo(yytext, "RELOP");
		        yylval.symbol = s;
		        return RELOP;
            }

"="         {return ASSIGNOP;}

"&&" |
"||"        {
                SymbolInfo *s= new  SymbolInfo(yytext, "LOGICOP");
			    yylval.symbol = s;
			    return LOGICOP;
		    }

"&"  |
"|"  |
"^"  |
"<<" |
">>"        {return BITOP;}

"!"         {return NOT;}

"("         {return LPAREN;}

")"         {return RPAREN;}

"{"         {return LCURL;}

"}"         {return RCURL;}

"["         {return LTHIRD;}

"]"         {return RTHIRD;}

","         {return COMMA;}

";"         {return SEMICOLON;}

%%

// int yywrap(void){
//     return 1;
// }

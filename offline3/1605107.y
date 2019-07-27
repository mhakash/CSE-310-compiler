%{
#include<iostream>
#include<fstream>
#include<queue>
#include"1605107_symbolTable.h"
#define log cout

using namespace std;
SymbolTable *table;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
ofstream error;


extern int line_count;
extern int error_count;

queue<SymbolInfo*> dec_list;
queue<SymbolInfo*> param_list;

void yyerror(const char *s){}

%}

%union{
    SymbolInfo* symbol;
}

%token IF ELSE FOR WHILE DO BREAK
%token INT FLOAT CHAR DOUBLE VOID
%token RETURN SWITCH CASE DEFAULT CONTINUE
%token INCOP ASSIGNOP BITOP NOT DECOP
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON
%token STRING PRINTLN

%token <symbol> ID CONST_INT CONST_FLOAT ADDOP MULOP RELOP LOGICOP

%type <symbol> type_specifier expression logic_expression rel_expression simple_expression declaration_list variable factor
%type <symbol> var_declaration unit program func_declaration parameter_list func_definition unary_expression term
%type <symbol> statement statements compound_statement expression_statement arguments argument_list
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start               : program {
                        log << "At line no: "<< line_count << " start: program\n\n";
                        log << $1->getName() <<endl;;
                    }
                    ;

program             : program unit {
                        $$ = new SymbolInfo($1->getName() + $2->getName(), "program");
                        log << "At line no: " << line_count << " program: program unit\n\n";
                        log << $$->getName() << endl;

                    }

                    | unit {
                        $$ = new SymbolInfo($1->getName(), "program");
                        log << "At line no: " << line_count << " program: unit\n\n";
                        log << $$->getName() << endl;
                    }
                    ;

unit                : var_declaration {
                        $$ = new SymbolInfo($1->getName(), "unit");
                        log << "At line no: " << line_count << " unit: var_declaration\n\n";
                        log << $$->getName() << endl;
                    }

                    | func_declaration {
                        $$ = new SymbolInfo($1->getName(), "unit");
                        log << "At line no: " << line_count << " unit: func_declaration\n\n";
                        log << $$->getName() << endl;
                    }

                    | func_definition {
                        $$ = new SymbolInfo($1->getName(), "unit");
                        log << "At line no: " << line_count << " unit: func_definition\n\n";
                        log << $$->getName() << endl;
                    }
                    ;

func_declaration    : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
                        $$ = new SymbolInfo($1->getName() +" "+ $2->getName() +"("+$4->getName()+");\n","func_declaration");
                        log << "At line no: " << line_count << " func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON \n\n";
                        log << $$->getName() << endl;

                        while(!param_list.empty()){
                            param_list.pop();
                        }

                        SymbolInfo* temp = table->lookUp($2->getName());
                        //if(temp)temp->print();
                        if(temp == 0){
                          SymbolInfo* func = new SymbolInfo($2->getName(),"func_declaration");
                          func->setFunction(true);
                          func->setParameter($4->getParameter());
                          func->setReturnType($1->getType());
                          //func->print();
                          table->insert(func);

                        }
                        else{
                          if(temp->isFunction()){
                              if((temp->getParameter()).compare($4->getParameter())){
                                //error << $4->getParameter()<<endl;
                                //error << temp->getParameter()<<endl;
                                error << "Error at line no " << line_count <<" : ";
                                error << "mismatch parameter\n\n";
                                error_count++;
                              }
                          }
                          else{
                            error << "Error at line no " << line_count <<" : ";
                            error << $2->getName()+" is already declared as a variable\n\n";
                            error_count++;
                          }
                          
                        }
                    }

                    | type_specifier ID LPAREN RPAREN SEMICOLON {
                        $$ = new SymbolInfo($1->getName() +" "+ $2->getName()+"();\n", "func_declaration");
                        log << "At line no: " << line_count << " func_declaration: type_specifier ID LPAREN RPAREN SEMICOLON\n\n";
                        log << $$->getName() << endl;

                        SymbolInfo* temp = table->lookUp($2->getName());
                        //if(temp)temp->print();
                        if(temp == 0){
                          SymbolInfo* func = new SymbolInfo($2->getName(),"func_declaration");
                          func->setFunction(true);
                          func->setParameter("VOID");
                          func->setReturnType($1->getType());
                          //func->print();
                          table->insert(func);

                        }
                        else{
                          if(temp->isFunction()){
                              if((temp->getParameter()).compare("VOID")){
                                error << "Error at line no " << line_count <<" : ";
                                error << "mismatch parameter\n\n";
                                error_count++;
                              }
                          }
                          else{
                            error << "Error at line no " << line_count <<" : ";
                            error << $2->getName()+" is already declared as a variable\n\n";
                            error_count++;
                          }
                          
                        }
                    }
                    ;

func_definition     : type_specifier ID LPAREN parameter_list RPAREN compound_statement {
                        $$ = new SymbolInfo($1->getName()+" "+$2->getName()+"("+$4->getName()+")"+$6->getName(),"func_definition");
                        log << "At line no: " << line_count << " func_definition: type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n";
                        log << $$->getName() << endl;
                        
                        SymbolInfo* temp = table->lookUp($2->getName());
                        SymbolInfo* func = new SymbolInfo($2->getName(),"func_definition");
                        func->setFunction(true);
                        func->setParameter($4->getParameter());
                        func->setReturnType($1->getType());

                        if(temp == 0){
                          table->insert(func);
                        }
                        else{
                          if(temp->isFunction()){
                            if((temp->getType()).compare("func_definition") == 0){
                            error << "Error at line no " << line_count <<" : ";
                            error << "function already defined\n\n";
                            error_count++;
                            }
                            else if((temp->getType()).compare("func_declaration") == 0){
                                if($4->getParameter().compare(temp->getParameter()) ){
                        
                                    error << "Error at line no " << line_count <<" : ";
                                    error << "function parameter mismatch\n\n";
                                    error_count++;
                                }
                                if($1->getType().compare(temp->getReturnType()) ){
                                    error << "Error at line no " << line_count <<" : ";
                                    error << "function return type mismatch\n\n";
                                    error_count++;
                                }
                                if($4->getParameter().compare(temp->getParameter()) == 0 && $1->getType().compare(temp->getReturnType())==0){
                                    table->remove($2->getName());
                                    table->insert(func);
                                }
                            }
                          }
                          else{
                            error << "Error at line no " << line_count <<" : ";
                            error << $2->getName()+" is already declared as a variable\n\n";
                            error_count++;
                          }
                          
                        }
                    }
                    | type_specifier ID LPAREN RPAREN compound_statement {
                        $$ = new SymbolInfo($1->getName()+" "+$2->getName()+"()"+$5->getName(),"func_definition");
                        log << "At line no: " << line_count << " func_definition: type_specifier ID LPAREN RPAREN compound_statement\n\n";
                        log << $$->getName() << endl;
                        // if(table->lookUp($2->getName())==0){
                        //   table->insert($2->getName(),"FUNCTION");
                        // }
                        SymbolInfo* temp = table->lookUp($2->getName());
                        SymbolInfo* func = new SymbolInfo($2->getName(),"func_definition");
                        func->setFunction(true);
                        func->setParameter("VOID");
                        func->setReturnType($1->getType());

                        if(temp == 0){
                          table->insert(func);
                        }
                        else{
                          if(temp->isFunction()){
                            if((temp->getType()).compare("func_definition") == 0){
                            error << "Error at line no " << line_count <<" : ";
                            error << "function already defined\n\n";
                            error_count++;
                            }
                            else if((temp->getType()).compare("func_declaration") == 0){
                                if(temp->getParameter().compare("VOID")){
                        
                                    error << "Error at line no " << line_count <<" : ";
                                    error << "function parameter mismatch\n\n";
                                    error_count++;
                                }
                                if($1->getType().compare(temp->getReturnType()) ){
                                    error << "Error at line no " << line_count <<" : ";
                                    error << "function return type mismatch\n\n";
                                    error_count++;
                                }
                                if(temp->getParameter().compare("VOID") == 0 && $1->getType().compare(temp->getReturnType())==0){
                                    table->remove($2->getName());
                                    table->insert(func);
                                }
                            }
                          }
                          else{
                            error << "Error at line no " << line_count <<" : ";
                            error << $2->getName()+" is already declared as a variable\n\n";
                            error_count++;
                          }
                          
                        }
                        //table->printAll();
                    }
                    ;

parameter_list      : parameter_list COMMA type_specifier ID {
                        $$ = new SymbolInfo($1->getName()+ ","+$3->getName()+" "+$4->getName(),"type_specifier");
                        $$->setParameter($1->getParameter()+","+$3->getType());
                        log << "At line no: " << line_count << " parameter_list: parameter_list COMMA type_specifier ID\n";
                        log << endl;
                        log << $$->getName() << endl;
                        log << endl;
                        SymbolInfo* temp = new SymbolInfo($4->getName(),$4->getType());
                        temp->setReturnType($3->getType());
                        param_list.push(temp);
                    }
                    | parameter_list COMMA type_specifier {
                        $$ = new SymbolInfo($1->getName()+ ","+$3->getName(),"type_specifier");
                        $$->setParameter($1->getParameter()+","+$3->getType());
                        log << "At line no: " << line_count << " parameter_list: parameter_list COMMA type_specifier\n"<<endl;
                        log << $$->getName() << endl;
                        log << endl;
                    }
                    | type_specifier ID {
                        $$ = new SymbolInfo($1->getName()+ " "+$2->getName(),"type_specifier");
                        $$->setParameter($1->getType());
                        log << "At line no: " << line_count << " parameter_list: type_specifier ID\n"<<endl;
                        log << $$->getName() << endl;
                        log << endl;
                        SymbolInfo* temp = new SymbolInfo($2->getName(),$2->getType());
                        temp->setReturnType($1->getType());
                        param_list.push(temp);
                    }
                    | type_specifier {
                        $$ = new SymbolInfo($1->getName(),"type_specifier");
                        $$->setParameter($1->getType());
                        log << "At line no: " << line_count << " parameter_list: type_specifier\n";
                        log << endl;
                        log << $$->getName() << endl;
                        log << endl;
                    }
                    ;

compound_statement  : LCURL     {
                            //table->printAll();
                            table->enterScope();
                            //table->printAll();
                            SymbolInfo *temp = 0;
                            while(!param_list.empty()){
                                temp = param_list.front();
                                param_list.pop();
                                if(table->lookUpCurrent(temp->getName()) == 0){
                                    table->insert(temp->getName(), temp->getType());
                                }
                                else{
                                    error << "Error at line no " << line_count <<" : ";
                                    error << temp->getName()+" is already declared in this scope\n\n";
                                    error_count++;
                                }
                            }

                        } statements RCURL {
                        $$ = new SymbolInfo("{\n"+$3->getName()+"}", "statements");
                        log << "At line no: " << line_count << " compound_statement: LCURL statements RCURL\n\n";
                        log << $$->getName() << endl;
                        
                        table->printAll();
                        table->exitScope();
                        $$->setReturnType($3->getReturnType());
                    }
                    | LCURL{
                        table->enterScope();
                        //table->printAll();
                            SymbolInfo *temp = 0;
                            while(!param_list.empty()){
                                temp = param_list.front();
                                param_list.pop();
                                if(table->lookUpCurrent(temp->getName()) == 0){
                                    table->insert(temp->getName(), temp->getType());
                                }
                                else{
                                    error << "Error at line no " << line_count <<" : ";
                                    error << temp->getName()+" is already declared in this scope\n\n";
                                    error_count++;
                                }
                            }
                        } RCURL {
                        $$ = new SymbolInfo("{\n}", "statements");
                        log << "At line no: " << line_count << " compound_statement: LCURL RCURL\n\n";
                        log << $$->getName() << endl;

                        
                        //table->printAll();
                        $$->setReturnType("VOID");
                        table->exitScope();
                    }
                    ;

var_declaration     : type_specifier declaration_list SEMICOLON {
                        $$ = new SymbolInfo($1->getName()+" "+$2->getName()+";\n","var_declaration");

                        log << "At line no: " << line_count << " var_declaration: type_specifier declaration_list SEMICOLON\n\n";

                        while(!dec_list.empty()){
                            SymbolInfo* temp = dec_list.front();
                            dec_list.pop();
                            temp->setReturnType($1->getType());
                            if(table->lookUpCurrent(temp->getName()) == 0){
                                //temp->setType($1->getType());
                                table->insert(temp);
                            }
                            else{
                                error << "Error at line no " << line_count <<" : ";
                                error <<"multiple declaration of "+ temp->getName() << endl<<endl;
                                error_count++;
                            }
                        }
                        log << $$->getName() << endl ;
                      }
                    ;

type_specifier      : INT {
                        $$ = new SymbolInfo("int", "INT");
                        log << "At line no: "<< line_count<< " type_specifier : INT\n\n";
                        log << $$->getName() << endl;
                        log << endl;

                      }
                    | FLOAT {
                        $$ = new SymbolInfo("float", "FLOAT");
                        log << "At line no: "<< line_count<< " type_specifier : FLOAT\n\n";
                        log << $$->getName() << endl;
                        log << endl;
                    }
                    | VOID {
                        $$ = new SymbolInfo("int", "VOID");
                        log << "At line no: "<< line_count<< " type_specifier : VOID\n\n";
                        log << $$->getName() << endl;
                        log << endl;
                    }
                    ;

declaration_list    : declaration_list COMMA ID {
                        $$ = new SymbolInfo($1->getName() +"," +$3->getName(),"declaration_list");
                        log << "At line no: "<< line_count<< " declaration_list : declaration_list COMMA ID\n\n";
                        log << $$->getName() << endl <<endl;
                        dec_list.push($3);
                    }

                    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
                        $$ = new SymbolInfo($1->getName()+","+ $3->getName()+"[" +$5->getName()+"]", "declaration_list");
                        log << "At line no: "<< line_count<< " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n";
                        log << $$->getName() << endl <<endl;
                        $3->setParameter("ARRAY");
                        dec_list.push($3);
                    }

                    | ID {
                        $$ = new SymbolInfo($1->getName(), "declaration_list");
                        log << "At line no: "<< line_count<< " declaration_list : ID\n\n";
                        log << $$->getName() << endl <<endl;
                        dec_list.push($1);
                    }

                    | ID LTHIRD CONST_INT RTHIRD {
                        $$ = new SymbolInfo($1->getName()+ "[" +$3->getName()+"]", "declaration_list");
                        log << "At line no: "<< line_count<< " declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n";
                        log << $$->getName() << endl << endl;
                        $1->setParameter("ARRAY");
                        dec_list.push($1);
                    }
                    ;

statements          : statement {
                        $$ = new SymbolInfo($1->getName(), "statements");
                        log << "At line no: "<< line_count<< " statements : statement\n\n";
                        log << $$->getName() << endl;
                    }
                    | statements statement {
                        $$ = new SymbolInfo($1->getName()+$2->getName(), "statements");
                        log << "At line no: "<< line_count<< " statements : statements statement\n\n";
                        log << $$->getName() << endl;
                    }
                    ;

statement           : var_declaration {
                        $$ = new SymbolInfo($1->getName(),"statement");
                        log << "At line no: "<< line_count<< " statement : var_declaration\n\n";
                        log << $$->getName() << endl;
                    }
                    | expression_statement {
                        $$ = new SymbolInfo($1->getName(),"statement");
                        log << "At line no: "<< line_count<< " statement : expression_statement\n\n";
                        log << $$->getName() << endl;
                    }
                    | compound_statement {
                        $$ = new SymbolInfo($1->getName(), "statement");
                        log << "At line no: "<< line_count<< " statement : compound_statement\n\n";
                        log << $$->getName() << endl;
                    }
                    | FOR LPAREN expression_statement expression_statement expression RPAREN statement {
                        string s = "for";
                        $$ = new SymbolInfo(s + "(" + $3->getName() + $4->getName() + $5->getName()+ ")"+$7->getName(),"statement");
                        log << "At line no: "<< line_count<< " statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n";
                        log << $$->getName() << endl;
                    }
                    | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE {
                        string s = "if";
                        $$ = new SymbolInfo(s+"("+$3->getName()+")"+$5->getName(),"statement");
                        log << "At line no: "<< line_count<< " statement : IF LPAREN expression RPAREN statement\n\n";
                        log << $$->getName() << endl;
                    }
                    | IF LPAREN expression RPAREN statement ELSE statement {
                        string s = "if";
                        $$ = new SymbolInfo(s+"("+$3->getName()+")"+$5->getName()+"else"+$7->getName(),"statement");
                        log << "At line no:"<< line_count<< " statement : IF LPAREN expression RPAREN statement ELSE statement\n\n";
                        log << $$->getName() << endl;
                    }
                    | WHILE LPAREN expression RPAREN statement {
                        string s = "while";
                        $$ = new SymbolInfo(s+"("+$3->getName()+")"+$5->getName(),"statement");
                        log << "At line no:"<< line_count<< " statement : WHILE LPAREN expression RPAREN statement\n\n";
                        log << $$->getName() << endl;
                    }
                    | PRINTLN LPAREN ID RPAREN SEMICOLON {
                        string s = "println";
                        $$ = new SymbolInfo(s+"("+$3->getName()+");","statement");
                        log << "At line no:"<< line_count<< " statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n";
                        log << $$->getName() << endl;
                    }
                    | RETURN expression SEMICOLON {
                        $$ = new SymbolInfo("return "+ $2->getName()+ ";\n","statement");
                        log << "At line no:"<< line_count<< " statement : RETURN expression SEMICOLON\n\n";
                        log << $$->getName() << endl;
                    }
                    ;

expression_statement : SEMICOLON {
                        $$ = new SymbolInfo(";\n","expression_statement");
                        log << "At line no:"<< line_count<< " expression_statement: SEMICOLON\n\n";
                        log << $$->getName() << endl;
                    }
                    | expression SEMICOLON {
                        $$ = new SymbolInfo($1->getName()+ ";\n","expression_statement");
                        log << "At line no:"<< line_count<< " expression_statement: expression SEMICOLON\n\n";
                        log << $$->getName() << endl;
                    }
                    ;

variable            : ID {
                        $$ = new SymbolInfo($1->getName(),"variable");
                        log << "At line no:"<< line_count<< " variable: ID\n\n";
                        log << $$->getName() << endl;

                        //table->printAll();
                        
                        SymbolInfo *temp = table->lookUp($1->getName());
                        if(temp==0){
                            error << "Error at line no " << line_count <<" : ";
                            error << $1->getName()+" is not declared \n\n";
                            error_count++;
                            $$->setReturnType("UNDEFINED");
                        }
                        else if(temp->isFunction()){
                            error << "Error at line no " << line_count <<" : ";
                            error << $1->getName()+" is not declared as a variable\n\n";
                            error_count++;
                        }
                        else{
                            $$->setReturnType(temp->getReturnType());
                            if((temp->getParameter()).compare("ARRAY")==0){
                                $$->setReturnType("ADDRESS");
                            }
                        }

                    }
                    | ID LTHIRD expression RTHIRD {
                        $$ = new SymbolInfo($1->getName()+"["+$3->getName()+"]","variable");
                        log << "At line no:"<< line_count<< " variable: ID LTHIRD expression RTHIRD\n";
                        log << $$->getName() << endl;

                        if(($3->getReturnType()).compare("INT")){
                            error << "Error at line no " << line_count <<" : ";
                            error << "Non integer array index\n\n";
                            error_count++;
                        }

                        SymbolInfo *temp = table->lookUp($1->getName());
                        if(temp==0){
                            error << "Error at line no " << line_count <<" : ";
                            error << $1->getName()+" is not declared \n\n";
                            error_count++;
                            $$->setReturnType("UNDEFINED");
                        }
                        else if(temp->isFunction()){
                            error << "Error at line no " << line_count <<" : ";
                            error << $1->getName()+" is not declared as a variable\n\n";
                            error_count++;
                        }
                        else{
                            $$->setReturnType(temp->getReturnType());
                        }
                    }
                    ;

expression          : logic_expression {
                        $$ = new SymbolInfo($1->getName(), "expression");
                        log << "At line no:"<< line_count<< " expression: logic_expression\n";
                        log << $$->getName() << endl;
                        $$->setReturnType($1->getReturnType());
                    }
                    | variable ASSIGNOP logic_expression {
                        $$ = new SymbolInfo($1->getName()+"="+$3->getName(), "expression");
                        log << "At line no:"<< line_count<< " expression: variable ASSIGNOP logic_expression\n\n";
                        log << $$->getName() << endl;

                        if(($1->getReturnType()).compare($3->getReturnType())){
                            error << "Error at line no " << line_count <<" : ";
                            error << "cannot assign "+$3->getReturnType()+ " to a "+$1->getReturnType()+ "\n\n";
                            error_count++;
                        }
                    }
                    ;


logic_expression    : rel_expression {
                        $$ = new SymbolInfo($1->getName(), "logic_expression");
                        log << "At line no:"<< line_count<< " logic_expression: rel_expression\n\n";
                        log << $$->getName() << endl;
                        $$->setReturnType($1->getReturnType());
                    }
                    | rel_expression LOGICOP rel_expression {
                        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), "logic_expression");
                        log << "At line no:"<< line_count<< " logic_expression: el_expression LOGICOP rel_expression\n\n";
                        log << $$->getName() << endl;
                        $$->setReturnType("INT");
                    }
                    ;

rel_expression      : simple_expression {
                        $$ = new SymbolInfo($1->getName(), "rel_expression");
                        log << "At line no:"<< line_count<< " rel_expression: simple_expression\n\n";
                        log << $$->getName() << endl;
                        $$->setReturnType($1->getReturnType());
                    }
                    | simple_expression RELOP simple_expression {
                        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), "rel_expression");
                        log << "At line no:"<< line_count<< " rel_expression: simple_expression RELOP simple_expression\n\n";
                        $$->setReturnType("INT");
                        log << $$->getName() << endl;
                    }
                    ;

simple_expression   : term {
                        $$ = new SymbolInfo($1->getName(), "simple_expression");
                        log << "At line no:"<< line_count<< " simple_expression: term\n\n";
                        log << $$->getName() << endl;
                        $$->setReturnType($1->getReturnType());
                    }
                    | simple_expression ADDOP term {
                        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), "simple_expression");
                        log << "At line no:"<< line_count<< " simple_expression: simple_expression ADDOP term\n\n";
                        log << $$->getName() << endl;
                        
                        string t1 = $1->getReturnType();
                        string t2 = $3->getReturnType();

                        if(t1.compare("INT")==0 && t2.compare("INT")==0){
                            $$->setReturnType("INT");
                        }
                        else if(t1.compare("INT")==0 && t2.compare("FLOAT")==0){
                            $$->setReturnType("FLOAT");
                        }
                        else if(t1.compare("FLOAT")==0 && t2.compare("INT")==0){
                            $$->setReturnType("FLOAT");
                        }
                        else if(t1.compare("FLOAT")==0 && t2.compare("FLOAT")==0){
                            $$->setReturnType("FLOAT");
                        }
                        else{
                            $$->setReturnType("UNDEFINED");
                        }
                    }
                    ;

term                : unary_expression {
                        $$ = new SymbolInfo($1->getName(), "term");
                        log << "At line no:"<< line_count<< " term: unary_expression\n\n";
                        log << $$->getName() << endl;
                        $$->setReturnType($1->getReturnType());
                    }
                    | term MULOP unary_expression {
                        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), "term");
                        log << "At line no:"<< line_count<< " term: term MULOP unary_expression\n\n";
                        log << $$->getName() << endl;

                        string t1 = $1->getReturnType();
                        string t2 = $3->getReturnType();
                        
                        if(t1.compare("INT")==0 && t2.compare("INT")==0){
                            $$->setReturnType("INT");
                        }
                        else if(t1.compare("INT")==0 && t2.compare("FLOAT")==0){
                            $$->setReturnType("FLOAT");
                        }
                        else if(t1.compare("FLOAT")==0 && t2.compare("INT")==0){
                            $$->setReturnType("FLOAT");
                        }
                        else if(t1.compare("FLOAT")==0 && t2.compare("FLOAT")==0){
                            $$->setReturnType("FLOAT");
                        }
                        else{
                            $$->setReturnType("UNDEFINED");
                        }

                        if(($2->getName()).compare("%")==0 ){
                            if(t1.compare("FLOAT")==0 || t2.compare("FLOAT")==0){
                                error << "Error at line no " << line_count <<" : ";
                                error << "Integer operand on modulus operator \n\n";
                                error_count++;
                                $$->setReturnType("UNDEFINED");
                            }
                        }
                        
                    }
                    ;

unary_expression    : ADDOP unary_expression {
                        $$ = new SymbolInfo($1->getName()+$2->getName(), "factor");
                        log << "At line no:"<< line_count<< " unary_expression: ADDOP unary_expression\n\n";
                        log << $$->getName() << endl;
                        $$->setReturnType($2->getReturnType());
                    }
                    | NOT unary_expression {
                        $$ = new SymbolInfo("!"+$2->getName(), "factor");
                        log << "At line no:"<< line_count<< " unary_expression: NOT unary_expression\n\n";
                        log << $$->getName() << endl;
                        $$->setReturnType($2->getReturnType());
                    }
                    | factor {
                        $$ = new SymbolInfo($1->getName(), "factor");
                        log << "At line no:"<< line_count<< " unary_expression: factor\n\n";
                        log << $$->getName() << endl;
                        $$->setReturnType($1->getReturnType());
                    }
                    ;

factor              : variable {
                        $$ = new SymbolInfo($1->getName(), "factor");
                        log << "At line no:"<< line_count<< " factor: variable\n\n";
                        log << $$->getName() << endl;
                        $$->setReturnType($1->getReturnType());
                    }
                    | ID LPAREN argument_list RPAREN {
                        $$ = new SymbolInfo($1->getName()+"("+$3->getName()+")", "factor");
                        log << "At line no:"<< line_count<< " factor: ID LPAREN argument_list RPAREN\n\n";
                        log << $$->getName() << endl;
                        //todo
                        SymbolInfo *temp = table->lookUp($1->getName());
                        if(temp==0){
                            error << "Error at line no " << line_count <<" : ";
                            error << "function "+$1->getName()+" is not declared\n\n";
                            error_count++;
                        }
                        else if(!temp->isFunction()){
                            error << "Error at line no " << line_count <<" : ";
                            error << $1->getName()+" is not declared as function\n\n";
                            error_count++;
                        }
                        else if((temp->getType()).compare("func_declaration")==0){
                            error << "Error at line no " << line_count <<" : ";
                            error << "function "+$1->getName()+" is not defined\n\n";
                            error_count++;
                        }
                        else if((temp->getParameter()).compare($3->getReturnType())){
                            error << "Error at line no " << line_count <<" : ";
                            error << "function parameter mismatch\n\n";
                            error_count++;
                        }
                        else{
                            $$->setReturnType(temp->getReturnType());
                        }

                    }
                    | LPAREN expression RPAREN {
                        $$ = new SymbolInfo("("+$2->getName()+")", "factor");
                        log << "At line no:"<< line_count<< " factor: LPAREN expression RPAREN\n";
                        log << $$->getName() << endl;
                        $$->setReturnType($2->getReturnType());
                    }
                    | CONST_INT {
                        $$ = new SymbolInfo($1->getName(),"CONST_INT");
                        log << "At line no:"<< line_count<< " factor: CONST_INT\n";
                        log << $$->getName() << endl;
                        $$->setReturnType("INT");
                    }
                    | CONST_FLOAT {
                        $$ = new SymbolInfo($1->getName(),"CONST_FLOAT");
                        log << "At line no:"<< line_count<< " factor: CONST_FLOAT\n";
                        log << $$->getName() << endl;
                        $$->setReturnType("FLOAT");
                    }
                    | variable INCOP {
                        $$ = new SymbolInfo($1->getName(),"INCOP");
                        log << "At line no:"<< line_count<< " factor: variable INCOP\n";
                        log << $$->getName() << endl;
                        $$->setReturnType($1->getReturnType());
                    }
                    | variable DECOP {
                        $$ = new SymbolInfo($1->getName(),"DECOP");
                        log << "At line no:"<< line_count<< " factor: variable DECOP\n";
                        log << $$->getName() << endl;
                        $$->setReturnType($1->getReturnType());
                    }
                    ;

argument_list       : arguments {
                        $$ = new SymbolInfo($1->getName(),"argument_list");
                        log << "At line no:"<< line_count<< " argument_list: arguments\n";
                        log << $$->getName()<<endl;
                        $$->setReturnType($1->getReturnType());
                    }
                    ;

arguments           : arguments COMMA logic_expression {
                        $$ = new SymbolInfo($1->getName()+","+$3->getName(),"arguments");
                        log << "At line no:"<< line_count<< " arguments: arguments COMMA logic_expression\n";
                        log << $$->getName() << endl;
                        $$->setReturnType($1->getReturnType()+","+$3->getReturnType());
                    }
                    | logic_expression {
                        $$ = new SymbolInfo($1->getName(),"arguments");
                        log << "At line no:"<< line_count<< " arguments: logic_expression\n";
                        log << $$->getName() << endl;
                        $$->setReturnType($1->getReturnType());
                    }
                    |{
                        $$ = new SymbolInfo("","EMPTY");
                        $$->setReturnType("VOID");
                    }
                    ;

%%



int main(int argc, char* argv[]){

    freopen("log.txt", "w", stdout);

    if((yyin=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

    //log.open("log.txt");
    error.open("error.txt");
    //error << "nice";
    table = new SymbolTable(20);
    yyparse();
    cout << "\n\tSymbol Table:\n";
    table->printAll();
    //log.close();
    error << "Total Errors: "<< error_count << endl;
    error.close();

    cout << "Lines: "<< line_count << endl;
    cout << "Total Errors: "<< error_count << endl;
    
    return 0;
}

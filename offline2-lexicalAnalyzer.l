%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <iostream>
#include <string>

FILE *logOut;
FILE *tokenOut;


int lines = 1;
int errors = 0;

using namespace std;

char* stringToChar(string s){
    char* temp = new char [s.length()+1];
    strcpy(temp, s.c_str());
    return temp;    
}


class SymbolInfo
{
private:
    string name;
    string type;
public:
    SymbolInfo(string name, string type);
    SymbolInfo(){};
    SymbolInfo* next;
    void setName(string name);
    void setType(string type); 
    string getName();
    string getType();
    void print();
    ~SymbolInfo(){delete next;}
};
void SymbolInfo::print(){
    //cout << " < "<< name <<" : "<< type <<" > ";
    fprintf(logOut," < %s:%s > ", stringToChar(name), stringToChar(type));
}
SymbolInfo::SymbolInfo(string name, string type){
    this->name = name;
    this->type = type;
    next = 0;
}
void SymbolInfo::setName(string name){
    this->name = name;
}
void SymbolInfo::setType(string type){
    this->type = type;
}
string SymbolInfo::getName(){
    return name;
}
string SymbolInfo::getType(){
    return type;
}

//--------------------- ScopeTable --------------------------------------


class ScopeTable{
private:
    int id, n; 
    SymbolInfo** symbol;
public:
    ScopeTable* parentScope;
    ScopeTable(int n);
    int getId();
    void setId(int id);
    int hash(string s);
    bool insert(SymbolInfo s);
    SymbolInfo* lookUp(string s);
    bool delet(string s);
    void print();
    ~ScopeTable(){}
};

ScopeTable::ScopeTable(int n){
    this->n = n;
    symbol = new SymbolInfo*[n];
    for(int i=0; i<n; i++){
        symbol[i] = 0;
    }
}

int ScopeTable::getId(){
    return id;
}

void ScopeTable::setId(int id){
    this->id = id;
}

int ScopeTable::hash(string s){
    unsigned long h = 5381;
    int  l = s.size();
    for(int i=0; i<l; i++){
        h = (h << 5) + h + s[i];
    }
    return h%n;
}

SymbolInfo* ScopeTable::lookUp(string s){
    int h = hash(s);
    SymbolInfo* temp = symbol[h];
    while(temp!=0){
        if(temp->getName() == s) {
            //cout <<" found in scopetable#"<< id << " at position "<< h <<'\n';
            return temp;
        }
        temp = temp->next;
    }
    //cout << " Not Found in scope#"<<id<<'\n';
    return 0;
};

bool ScopeTable::insert(SymbolInfo s){
    if(lookUp(s.getName()) != 0) {
        s.print();
        //cout << "already Exists in current scope\n";
        fprintf(logOut, "already Exists in current scope\n");
        return false;
    }

    int h = hash(s.getName());
    SymbolInfo* temp = symbol[h];
    SymbolInfo* t = new SymbolInfo(s.getName(), s.getType());
    t->next = 0;

    if(temp == 0){
        symbol[h] = t;
        //cout << " inserted in scopetable#"<< id <<" at position "<< h <<'\n';
        return true;
    }

    while(temp->next){
        temp = temp->next;
    }
    temp->next = t;
    //cout << " inserted in scopetable#"<< id <<" at position "<< h <<'\n';

    return true;
    
}

bool ScopeTable::delet(string s){
    if(lookUp(s) == 0) {
        //cout <<" not found\n";
        return false;
    }
    int h = hash(s);
    SymbolInfo* temp = symbol[h];

    if(temp->getName() == s) {       
        symbol[h] = (temp==0)? 0 : temp->next;
        delete temp;
        //cout <<" deleted from scopetable#"<< id <<'\n';
        return true;
    }

    while(true){
        if(temp->next->getName() == s){
            SymbolInfo* a = temp->next;
            temp->next = (a==0)? 0 : a->next;
            delete a;
            break;
        }
        temp = temp->next;
    }
    //cout <<" deleted from scopetable#"<< id <<'\n';
    return true;
}

void ScopeTable::print(){
    //cout << " scopetable # "<< id <<'\n';
    fprintf(logOut, " scopetable # %d:",id);
    for(int i=0; i<n; i++){
        SymbolInfo* temp = symbol[i];
        //cout <<' '<< i<<" --> ";
        if(temp)fprintf(logOut, "\n %d--> ",i);
        while(temp){
            temp->print();
            temp = temp->next;
        }
        //cout <<'\n';
        //fprintf(logOut, "\n");
    }
    fprintf(logOut, "\n");
}


//--------------------------- Symbol Table--------------------------
class SymbolTable{
private:
    ScopeTable* current;
    //ScopeTable* parent;
    int n;
public:
    SymbolTable(int n);
    void enterScope();
    void exitScope();
    bool insert(string name, string type);
    bool remove(string name);
    SymbolInfo* lookUp(string name);
    void printCurrent();
    void printAll();
    ~SymbolTable(){}
};

SymbolTable::SymbolTable(int n){
    this->n = n;
    current = new ScopeTable(n);
    current->setId(1);
    current->parentScope = 0;
}

void SymbolTable::enterScope(){
    ScopeTable* newTable = new ScopeTable(n);
    newTable->setId(current->getId()+1);
    newTable->parentScope = current;
    current = newTable;
    //cout <<" new scopetable created with id "<<current->getId()<<'\n';
} 

void SymbolTable::exitScope(){
    ScopeTable* temp = current;
    //cout <<" removed scopetable with id "<<current->getId()<<'\n';
    current = current->parentScope;
    delete temp;
}

bool SymbolTable::insert(string name, string type){
    SymbolInfo newSymbol(name,type);
    return current->insert(newSymbol);
}

bool SymbolTable::remove(string name){
    return current->delet(name);
}

SymbolInfo* SymbolTable::lookUp(string name){
    ScopeTable* temp = current;
    SymbolInfo* info = 0;
    while(temp){
        info = temp->lookUp(name);
        if(info != 0){
            //cout <<" found in scopetable# "<< temp->getId() <<'\n';
            return info;
        }
        temp = temp->parentScope;
    }
    //cout <<" Not found\n";
    return 0;
}

void SymbolTable::printCurrent(){
    current->print();
}

void SymbolTable::printAll(){
   ScopeTable* temp = current;

   while(temp){
       temp->print();
       cout << '\n';
       temp = temp->parentScope;
   } 
}

SymbolTable symbolTable(10);

char* upperCase(char* str){
    char *temp;
    // temp = (char*) malloc((strlen(str)+5) * sizeof(char));
    temp = new char[strlen(str)+5];
    int i=0;
    while(str[i]){
        temp[i] = toupper(str[i]);
        i++;
    }
    temp[i]=0;
    return temp;
}

void processWithSymbolTable(string symbol,string id){
    fprintf(tokenOut, "<%s,%s>", stringToChar(id), stringToChar(symbol));
    fprintf(logOut,"Line no %d: TOKEN <%s> Lexeme %s found\n",lines, stringToChar(id), stringToChar(symbol));
    symbolTable.insert(yytext,id);
}

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

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z]
DIGIT [0-9]
CHAR [ -~]{-}['\\]


%%
\n         { lines++; }
{WHITESPACE} {}
"if"        |
"for"       |
"do"        |
"int"       |
"float"     |
"void"      |
"switch"    |
"default"   |
"else"      |
"while"     |
"break"     |
"char"      |
"double"    |
"return"    |
"case"      |
"continue"  {
               //cerr << "yytext: " << yytext << "\n";
                fprintf(tokenOut, "<%s>",upperCase(yytext));
                //cerr << "Tis is me!\n";
                fprintf(logOut,"Line no %d: TOKEN <%s> Lexeme %s found\n",lines,upperCase(yytext),yytext);
                //cerr << "Comes this far\n";
            }

{DIGIT}+    {
                processWithSymbolTable(yytext, "CONST_INT");
                symbolTable.printCurrent();
            }

{DIGIT}*[.]{DIGIT}+([E][+-]?{DIGIT}+)?   |
{DIGIT}+[E][+-]?{DIGIT}+  {
                processWithSymbolTable(yytext, "CONST_FLOAT");
                symbolTable.printCurrent();
            }

\'({CHAR}|\\['"?\\abfnrtv])\'         {
                processWithSymbolTable(yytext, "CONST_CHAR");
                symbolTable.printCurrent();
            }


[+-]        {
                processWithSymbolTable(yytext, "ADDOP");
            }

"*"    |
"/"    | 
"%"         {
                processWithSymbolTable(yytext, "MULOP");
            }

"++"|"--"   {
                processWithSymbolTable(yytext, "INCOP");
            }

"<"|"<="|">"|">="|"=="|"!=" {
                processWithSymbolTable(yytext, "RELOP");
            }

[=]         {
                processWithSymbolTable(yytext, "ASSIGNMENT");
            }

"&&"|"||"         {
                processWithSymbolTable(yytext, "LOGICOP");
            }
            
"&"|"|"|"^"|"<<"|">>"         {
                processWithSymbolTable(yytext, "BITOP");
            }
            
[!]         {
                processWithSymbolTable(yytext, "NOT");
            }
            
[(]         {
                processWithSymbolTable(yytext, "LPAREN");
            }
            
[)]         {
                processWithSymbolTable(yytext, "RPAREN");
            }
            
[{]         {
                processWithSymbolTable(yytext, "LCURL");
            }
            
[}]         {
                processWithSymbolTable(yytext, "RCURL");
            }
            
"["         {
                processWithSymbolTable(yytext, "LTHIRD");
            }
            
"]"         {
                processWithSymbolTable(yytext, "RTHIRD");
            }
            
[,]         {
                processWithSymbolTable(yytext, "COMMA");
            }
            
[;]         {
                processWithSymbolTable(yytext, "SEMICOLON");
            }

({LETTER}|_)({LETTER}|{DIGIT}|_)*   {
                processWithSymbolTable(yytext, "ID");
                symbolTable.printCurrent();
            }

["][^\n]*([\\][\n][^\n]*)*["] {
                fprintf(tokenOut, "<STRING, %s>",yytext);
                fprintf(logOut,"Line no %d: TOKEN <STRING> Lexeme %s found\n",lines,yytext);
                lines += findLines(yytext);
            }

[/][/][^\n]*([\\][\n][^\n]*)*   {
                fprintf(logOut,"Line no %d:  <COMMENT>  first type comment found\n",lines);
                lines += findLines(yytext);
            }

"/*"(.|"\n")*"*/"   {
				fprintf(logOut,"Line no %d:  <COMMENT>  second type comment found\n",lines);
				lines += findLines(yytext);
            }
    
{DIGIT}*([.]+{DIGIT}*)+(E[.]*[+-]?[.]*{DIGIT}*)?[.]*{DIGIT}*    {
                errors++;
                fprintf(logOut, "Error at line %d : Too many decimal point error\n",lines);
                
            }

{DIGIT}+([.]{DIGIT}*)?[E]{DIGIT}+[.]{DIGIT}*   {
                errors++;
                fprintf(logOut, "Error at line %d : Ill formed number error\n",lines);
            }
[\'][^\\\t\n\"\a\f\r\b\v\0]{CHAR}+[\']   {
                errors++;
                fprintf(logOut, "Error at line %d : multi character constant\n",lines);
            }

\'({CHAR}|[\\])*[^'\n]? {
                errors++;
                fprintf(logOut, "Error at line %d : unfinished character error\n",lines);
            }
{DIGIT}+{LETTER}+ {
                errors++;
                fprintf(logOut, "Error at line %d : invalid suffix on numeric constant\n",lines);
            }

      
\"([^\"\n]|(\\[\n]))*  {
                errors++;
                fprintf(logOut, "Error at line %d :unfinished string\n",lines);
                lines += findLines(yytext);
            }
"/*".*[^"*/"]      {
                errors++;
                fprintf(logOut, "Error at line %d :unfinished comment\n",lines);
                lines += findLines(yytext);
            }


.           {  
                errors++;
                fprintf(logOut, "Error at line %d : unrecognized character\n",lines);
                lines += findLines(yytext);
            }
%%

int main(int argc, char **argv){
    freopen("input.txt", "r", stdin); 
    logOut = fopen("log.txt", "w");
    tokenOut = fopen("token.txt", "w");
    
    yylex();

    printf("lines%8d\terrors%8d\n", lines, errors);
    fprintf(logOut, "lines%8d\terrors%8d\n", lines, errors);
    fclose(stdin);
    fclose(logOut);
    fclose(tokenOut);
    return 0;
}

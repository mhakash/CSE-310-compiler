#include <iostream>
#include<fstream>
using namespace std;

class SymbolInfo
{
private:
    string name;
    string type;
    string returnType;
    bool function;
    string parameter;
public:
    SymbolInfo(string name, string type){
        this->name = name;
        this->type = type;
        next = 0;
        returnType = "";
        function = false;
        parameter = "";
    }

    SymbolInfo(){type = ""; name = "";}

    SymbolInfo* next;

    void setName(string name){
        this->name = name;
    }
    void setType(string type){
        this->type = type;
    }
    void setReturnType(string returnType){
        this->returnType = returnType;
    }
    void setFunction(bool isF){
        function = isF;
    }
    void setParameter(string parameter){
        this->parameter = parameter;
    }
    bool isFunction(){
        return function;
    }
    string getName(){return name;}
    string getType(){return type;}
    string getReturnType(){return returnType;}
    string getParameter(){return parameter;}
    void print(){
        cout << " < "<< name <<" : "<< type<<" > ";
    }
    ~SymbolInfo(){delete next;}
};


//--------------------- ScopeTable --------------------------------------


class ScopeTable{
private:
    int id, n;
    SymbolInfo** symbol;
public:
    ScopeTable* parentScope;string returnType;
    bool function;
    string parameter;

    ScopeTable(int n){
        this->n = n;
        symbol = new SymbolInfo*[n];
        for(int i=0; i<n; i++){
            symbol[i] = 0;
        }
    }

    int getId(){return id;}

    void setId(int id){this->id = id;}

    int hash(string s){
        unsigned long h = 5381;
        int  l = s.size();
        for(int i=0; i<l; i++){
            h = (h << 5) + h + s[i];
        }
        return h%n;
    }

    bool insert(SymbolInfo s){
        if(lookUp(s.getName()) != 0) {
            s.print();
            cout << "already Exists in current scope\n";
            //fprintf(logOut, "already Exists in current scope\n");
            return false;
        }

        int h = hash(s.getName());
        SymbolInfo* temp = symbol[h];
        
        SymbolInfo* t = new SymbolInfo(s.getName(), s.getType());
        t->setFunction(s.isFunction());
        t->setReturnType(s.getReturnType());
        t->setParameter(s.getParameter());
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

    SymbolInfo* lookUp(string s){
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
    }

    bool delet(string s){
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

    void print(){
        cout << " scopetable # "<< id <<'\n';
        //fprintf(logOut, " scopetable # %d:",id);
        
        for(int i=0; i<n; i++){
            SymbolInfo* temp = symbol[i];
            //cout <<' '<< i<<" --> ";
            //if(temp)fprintf(logOut, "\n %d--> ",i);
            if(temp) cout << "\n "<<i<<"-->";
            while(temp){
                temp->print();
                temp = temp->next;
            }
            //cout <<'\n';
            //fprintf(logOut, "\n");
        }
        //fprintf(logOut, "\n");
        cout << endl;
    }
    ~ScopeTable(){}
};





//--------------------------- Symbol Table--------------------------
class SymbolTable{
private:
    ScopeTable* current;
    //ScopeTable* parent;
    int n;
public:
    SymbolTable(int n){
        this->n = n;
        current = new ScopeTable(n);
        current->setId(1);
        current->parentScope = 0;
        
    }

    void enterScope(){
        ScopeTable* newTable = new ScopeTable(n);
        newTable->setId(current->getId()+1);
        newTable->parentScope = current;
        current = newTable;
        cout <<" new scopetable created with id "<<current->getId()<<'\n';
        //fprintf(logOut, "\n")
        //log << "entering new scope"<<endl;
    }

    void exitScope(){
        ScopeTable* temp = current;
        //cout <<" removed scopetable with id "<<current->getId()<<'\n';
        current = current->parentScope;
        delete temp;
    }

    bool insert(string name, string type){
        SymbolInfo newSymbol(name,type);
        return current->insert(newSymbol);
    }

    bool insert(SymbolInfo *symbol){
        //symbol->print();
        return current->insert(*symbol);
    }


    bool remove(string name){
        return current->delet(name);
    }

    SymbolInfo* lookUp(string name){
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

    SymbolInfo* lookUpCurrent(string name){
        return current->lookUp(name);
        /* SymbolInfo* info = 0;
        while(temp){
            info = temp->lookUp(name);
            if(info != 0){
                //cout <<" found in scopetable# "<< temp->getId() <<'\n';
                return info;
            }
            temp = temp->parentScope;
        }
        //cout <<" Not found\n";
        return 0;*/
    }



    void printCurrent(){
        current->print();
    }
    void printAll(){
        ScopeTable* temp = current;

        while(temp){
            temp->print();
            cout << '\n';
            temp = temp->parentScope;
        }
    }
    ~SymbolTable(){}
};

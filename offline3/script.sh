
bison -d -y -v 1605107.y    
echo 'completed part 1'

g++ -std=c++11 -w -c -o y.o y.tab.c   
echo 'completed part 2'

flex 1605107.l              
echo 'completed part 3'

g++ -std=c++11 -fpermissive -w -c -o l.o lex.yy.c
echo 'completed part 4'

g++ -std=c++11 -o a.out y.o l.o -lfl -ly
echo 'completed part 5'
./a.out input.c      
~

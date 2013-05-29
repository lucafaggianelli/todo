#! /bin/sh

# call as:
# ./test-big-list.sh 1000
#
# then test it with:
# time todo.sh ls

# Backup your list!
mv todo todo.bak

echo -e "Ciao TODO\n=========" > todo

for i in {0..$1}; do
  echo "$i [ ] (!) Compra il latte" >> todo
done

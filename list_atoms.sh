echo "1. Configuration file, 2.  Total number of atoms 3. Atom type"

file_name=$1
no_atom=$2
a=$3
head_line=`echo $no_atom+9|bc` 
echo $head_line
echo "atom type" $a
head -n $head_line $1 > temp.dat
tail  -n $no_atom  temp.dat > temp2.dat
awk '{if ($3=='$a') print $1}' temp2.dat >>  list_file.dat

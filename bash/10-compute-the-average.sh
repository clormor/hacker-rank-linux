read n
sum=0
counter=$n
while [[ $counter > 0 ]]
do
    read x
    sum=$((sum + x))
    counter=$((counter - 1))
done
average=$(bc <<< "scale=6;$sum/$n")
printf '%.3f' $average

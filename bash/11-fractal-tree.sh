max_n=5
height=$(((2 ** (max_n + 1)) - 1))
width=100
empty_char="_"
tree_char="1"
sum_heights_array=(32 48 56 60 62)
branch_height_arr=(16 40 52 58 61)

# Given a row number {x:1..height}, returns an integer {1..max_n} according to which level of the tree this row is in
# e.g if max_n=5:
#     row 1 is in the 6th level of the tree (n_level_for 1 == 6)
#     row 2 is in the 5th level of the tree (n_level_for 2 == 5)
#     row 63 is in the 1st level of the tree (n_level_for 63 == 1)
n_level_for() {
    local row=$1
    local result=1
    for sum_height in ${sum_heights_array[@]}
    do
        if [[ $row -gt $((height - sum_height)) ]]
        then
            echo $result
            return
        else
            result=$((result + 1))
        fi
    done
    echo $result
}

# Stores the result of xs_for() (see below)
xs_array=()

# Given a tree level {1..max_n} returns an array of integers {1..width} describing the
# x-coordinates of the vertical segments.
# e.g if width=100:
#     the vertical segment for tree level 1 will be at 50 (xs_for 1 == [50])
#     the vertical segment for tree level 2 will be at 34 and 66 (xs_for 2 == [34,66])
#     the vertical segment for tree level 3 will be at 26, 42, 58 and 74 (xs_for 3 == [26,42,58,74])
# The result is captured in a global array (xs_array), since returning arrays is not really a thing in bash
xs_for_level() {
    local level=$1
    if [[ level -eq 1 ]]
    then
        xs_array=(50)
    else
        local new_xs_array=()
        local power=$((2 ** (max_n - level + 1)))
        xs_for_level $((level - 1))
        for x in ${xs_array[@]}
        do
            new_xs_array+=($(($x - $power)))
            new_xs_array+=($(($x + $power)))
        done
        xs_array=${new_xs_array[@]}
    fi
}

# Given a row / tree level, determine the branching factor
branching_factor() {
    local row=$1
    local current_level=$2
    local branch_height=${branch_height_arr[$((current_level - 1))]}
    local row_to_branch=$((height - branch_height))
    if [[ $row -gt $row_to_branch ]]
    then
        echo 0
    else
        echo $(($row_to_branch - $row + 1))
    fi
}

# Given a row {1..height} returns the x-coordinates of all the cells in the row which form the fractal tree
# e.g for width=100, max_n=5:
#    row 63 only has one cell in the tree, at position 50 (the trunk) (xs_for_row 63 == [50])
#    row (63-16 = 47) has two cells in the tree as this is where the trunk begins to branch (xs_for_row 47 == [49,51])
# The result is captured in a global array (xs_array), since returning arrays is not really a thing in bash
xs_for_row() {
    local row=$1
    local n=$2
    
    # figure out which level we're in, and determine the relevant cells
    local n_level=$(n_level_for $row)
    if [[ $n_level -gt $n ]]
    then
        xs_array=()
        return
    fi
    xs_for_level $n_level

    # now figure out where we are in the level (e.g. branching or otherwise) and if branching to what degree
    local branching_factor=$(branching_factor $row $n_level)
    if [[ $branching_factor -gt 0 ]]
    then
        # for every x-coordinate, create two new co-cordinates (x - branching factor), (x + branching_factor)
        # these new co-ordinates are the ones we return for printing
        local new_xs_array=()
        for x in ${xs_array[@]}
        do
            new_xs_array+=($(($x - $branching_factor)))
            new_xs_array+=($(($x + $branching_factor)))
        done
        xs_array=${new_xs_array[@]}
    fi
}

print_row() {
   local current_position=1
   for x in ${xs_array[@]}
   do
       for i in $(seq $current_position $((x - 1)))
       do
           printf $empty_char
       done
       printf $tree_char
       current_position=$((x + 1))
   done

   for i in $(seq $current_position $width)
   do
       printf $empty_char
   done
   printf '\n'
}

read n
for row in $(seq 1 $height)
do
    xs_for_row $row $n
    print_row
done

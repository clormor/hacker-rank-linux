max_n=5
height=$(((2 ** (max_n + 1)) - 1))
width=100
empty="_"
thing="1"

# Given a tree level {x:1..max_n} returns the number of rows (height) required to draw the {x}th iteration
# of the fractal tree. The height of the 1st iteration is set at 2*max_n.
# e.g. if max_n=5:
#    the 1st iteration of the fractal tree has height 32
#    the 2nd iteration of the fractal tree has height 16
#    ... and so on
n_height() {
    local n_level=$1
    local result=$((2 ** max_n))
    while [[ $n_level -gt 1 ]]
    do
        local result=$((result / 2))
        local n_level=$((n_level - 1))
    done
    echo $result
}

# Given a row number {x:1..height}, returns an integer {1..max_n} according to which level of the tree this row is in
# e.g if max_n=5:
#     row 1 is in the 6th level of the tree (n_level_for 1 == 6)
#     row 2 is in the 5th level of the tree (n_level_for 2 == 5)
#     row 63 is in the 1st level of the tree (n_level_for 63 == 1)
n_level_for() {
    local row=$1
    local sum_heights=0
    for i in $(seq 1 $max_n)
    do
        local n_height=$(n_height $i)
        local sum_heights=$((sum_heights + n_height))
        if [[ $row -gt $((height - sum_heights)) ]]
        then
            echo $i
            return
        fi
    done
    echo $((max_n + 1))
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

# Determine the branching height of the current tree level
branch_height() {
    local level=$1
    local preceeding_level=$((level - 1))
    local result=0

    # add up the heights of the preceeding levels
    for i in $(seq 1 $preceeding_level)
    do
        local n_height=$(n_height $i)
        result=$((result + n_height))
    done

    # add half the height of this level (we branch half way up)
    local n_height=$(n_height $level)
    result=$((result + (n_height / 2)))
    echo $result
}

# Given a row determine the branching factor
branching_factor() {
    local row=$1
    local current_level=$(n_level_for $row)
    local branch_height=$(branch_height $current_level)
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
    
    # figure out which level we're in, and determine the relevant cells
    local n_level=$(n_level_for $row)
    xs_for_level $n_level

    # now figure out where we are in the level (e.g. branching or otherwise) and if branching to what degree
    local branching_factor=$(branching_factor $row)
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

print_line() {
   local current_position=1
   for x in ${xs_array[@]}
   do
       for i in $(seq $current_position $((x - 1)))
       do
           printf $empty
       done
       printf $thing
       current_position=$((x + 1))
   done

   for i in $(seq $current_position $width)
   do
       printf $empty
   done
   printf '\n'
}

print_blank_line() {
    for i in $(seq 1 $width)
    do
        printf $empty
    done
    printf '\n'
}

print_something() {
    local n_level=$1
}

print_xs_array() {
    echo "${xs_array[@]}"
}

read n
for row in $(seq 1 $height)
do
    n_level=$(n_level_for $row)
    if [[ $n_level > $n ]]
    then
        print_blank_line
    else
        xs_for_row $row
        print_line $n_level
    fi
done

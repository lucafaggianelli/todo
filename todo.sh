#! /bin/sh

TODO_LIST=./todo
_DEBUG=1

# == PROCESS OPTIONS ==
while getopts ":fhpcnNaAtTvVx+@Pd:" Option
do
  case $Option in
    '@' )
        ## HIDE_CONTEXT_NAMES starts at zero (false); increment it to one
        ##   (true) the first time this flag is seen. Each time the flag
        ##   is seen after that, increment it again so that an even
        ##   number shows context names and an odd number hides context
        ##   names.
        : $(( HIDE_CONTEXT_NAMES++ ))
        if [ $(( $HIDE_CONTEXT_NAMES % 2 )) -eq 0 ]
        then
            ## Zero or even value -- show context names
            unset HIDE_CONTEXTS_SUBSTITUTION
        else
            ## One or odd value -- hide context names
            export HIDE_CONTEXTS_SUBSTITUTION='[[:space:]]@[[:graph:]]\{1,\}'
        fi
        ;;
    '+' )
        ## HIDE_PROJECT_NAMES starts at zero (false); increment it to one
        ##   (true) the first time this flag is seen. Each time the flag
        ##   is seen after that, increment it again so that an even
        ##   number shows project names and an odd number hides project
        ##   names.
        : $(( HIDE_PROJECT_NAMES++ ))
        if [ $(( $HIDE_PROJECT_NAMES % 2 )) -eq 0 ]
        then
            ## Zero or even value -- show project names
            unset HIDE_PROJECTS_SUBSTITUTION
        else
            ## One or odd value -- hide project names
            export HIDE_PROJECTS_SUBSTITUTION='[[:space:]][+][[:graph:]]\{1,\}'
        fi
        ;;
    a )
        OVR_TODOTXT_AUTO_ARCHIVE=0
        ;;
    A )
        OVR_TODOTXT_AUTO_ARCHIVE=1
        ;;
    c )
        OVR_TODOTXT_PLAIN=0
        ;;
    d )
        TODOTXT_CFG_FILE=$OPTARG
        ;;
    f )
        OVR_TODOTXT_FORCE=1
        ;;
    h )
        # Short-circuit option parsing and forward to the action.
        # Cannot just invoke shorthelp() because we need the configuration
        # processed to locate the add-on actions directory.
        set -- '-h' 'shorthelp'
        OPTIND=2
        ;;
    n )
        OVR_TODOTXT_PRESERVE_LINE_NUMBERS=0
        ;;
    N )
        OVR_TODOTXT_PRESERVE_LINE_NUMBERS=1
        ;;
    p )
        OVR_TODOTXT_PLAIN=1
        ;;
    P )
        ## HIDE_PRIORITY_LABELS starts at zero (false); increment it to one
        ##   (true) the first time this flag is seen. Each time the flag
        ##   is seen after that, increment it again so that an even
        ##   number shows priority labels and an odd number hides priority
        ##   labels.
        : $(( HIDE_PRIORITY_LABELS++ ))
        if [ $(( $HIDE_PRIORITY_LABELS % 2 )) -eq 0 ]
        then
            ## Zero or even value -- show priority labels
            unset HIDE_PRIORITY_SUBSTITUTION
        else
            ## One or odd value -- hide priority labels
            export HIDE_PRIORITY_SUBSTITUTION="([A-Z])[[:space:]]"
        fi
        ;;
    t )
        OVR_TODOTXT_DATE_ON_ADD=1
        ;;
    T )
        OVR_TODOTXT_DATE_ON_ADD=0
        ;;
    v )
        : $(( TODOTXT_VERBOSE++ ))
        ;;
    V )
        version
        ;;
    x )
        OVR_TODOTXT_DISABLE_FILTER=1
        ;;
  esac
done

# Shift the params to delete options
shift $(($OPTIND - 1))

# defaults if not yet defined
TODOTXT_VERBOSE=${TODOTXT_VERBOSE:-1}
TODOTXT_PLAIN=${TODOTXT_PLAIN:-0}
TODOTXT_CFG_FILE=${TODOTXT_CFG_FILE:-$HOME/.todo/config}
TODOTXT_FORCE=${TODOTXT_FORCE:-0}
TODOTXT_PRESERVE_LINE_NUMBERS=${TODOTXT_PRESERVE_LINE_NUMBERS:-1}
TODOTXT_AUTO_ARCHIVE=${TODOTXT_AUTO_ARCHIVE:-1}
TODOTXT_DATE_ON_ADD=${TODOTXT_DATE_ON_ADD:-0}
TODOTXT_DEFAULT_ACTION=${TODOTXT_DEFAULT_ACTION:-}
TODOTXT_SORT_COMMAND=${TODOTXT_SORT_COMMAND:-env LC_COLLATE=C sort -f -k2}
TODOTXT_DISABLE_FILTER=${TODOTXT_DISABLE_FILTER:-}
TODOTXT_FINAL_FILTER=${TODOTXT_FINAL_FILTER:-cat}

# Colors
BLACK=30
RED=31
GREEN=32
YELLOW=33
BLUE=34
MAGENTA=35
CYAN=36
WHITE=37

# Style
BOLD=1
NORMAL=0

TODO_COL_NO=`echo -e "\e[0m"`

TODO_COL_CAT=`echo -e "\e[$BOLD;${BLUE}m"`

TODO_COL_NEW=`echo -e "\e[$NORMAL;$(( $GREEN+10 ))m"`
TODO_COL_DEL=`echo -e "\e[$NORMAL;$(( $RED+10 ))m"`

TODO_COL_DONE=`echo -e "\e[$BOLD;${RED}m"`
TODO_COL_PEND=`echo -e "\e[$BOLD;${YELLOW}m"`

TODO_COL_BUG=`echo -e "\e[$BOLD;${RED}m"`
TODO_COL_H=`echo -e "\e[$BOLD;${YELLOW}m"`
TODO_COL_L=`echo -e "\e[$BOLD;${GREEN}m"`


######## Options parsing end

DEBUG() {
    [ $_DEBUG -ne 0 ] && $@
}

_countTodo() {
    TODO_COUNT=`sed -n -e '/^[0-9]* \[/p' $TODO_LIST | sed -n '$='`
}

_lastTodoID() {
    TODO_LAST_ID=`sed -n -e "/^[0-9]/p" $TODO_LIST |
                  sort -n |
                  sed -n -e '$p' |
                  sed "s/^\([0-9][0-9]*\).*/\1/"`
}

add() {
    # Create a TODO on a given category

    # Get category
    cat=$1; shift

    if [ $# -eq 0 ]; then
        echo "Cant create an empty TODO in category $cat"
        exit 1;
    fi

    found_cat=`lsCategories | sed -n -e "/^$cat$/p"`
    if [ "$found_cat" != "$cat" ]; then
        echo "Category $cat doesn't exist, creating..."
        createCategory $cat
    fi

    # Default values
    mark=' '
    priority=' '

    # Search mark and prio at the beginning of the sentence
    for i in "$@"; do
        case $i in
            '?' | "x" | "o") mark=$i; shift ;;
            '!' | "L" | "H" | "0") priority=$i; shift ;;

            # Out when you find the first letter, otherwise treat chars in
            # the TODO as priority and mark
            * ) break ;;
        esac
    done

    # Count all the TODOs
    _lastTodoID
    id=$(( $TODO_LAST_ID+1 ))

    # Line number of the '=' below category name
    line=$(( `sed -n -e "/^$cat$/=" $TODO_LIST`+1 ))
    if [ -z $line ]; then exit 1; fi

    # Write the TODO
    todo="$id [$mark] ($priority) $@"
    sed -i "${line}a $todo" $TODO_LIST

    lsTodoCategories $cat | highlightTodo $id $TODO_COL_NEW
    echo "Created TODO in $cat"
}

delete() {
    # Delete a todo
    #
    # $*: ids

    for id in $*; do
        sed -i "/^$id/d" $TODO_LIST
    done

    lsTodoAll | highlightTodo $id $TODO_COL_DEL
}

mark() {
    # Mark as done, pending or todo
    #
    # $1: ? pending, x done, 'o' todo
    # $2: id

    # Set the mark
    if [ $1 = "o" ]; then
        mark=' '
    else
        mark=$1
    fi

    # TODO: put ids in or so dont iterate
    shift;
    for id in $*; do
        sed -i "s/\($id \)\[.\]/\1[$mark]/" $TODO_LIST
    done

    lsTodoAll
    echo "TODOs $* marked as $mark"
}

setPriority() {
    # Set priority
    #
    # $1: ! bug/critical, H high, L low, 0 unset
    # $2: id

    # Set the priority
    if [ $1 = "0" ]; then
        priority=' '
    else
        priority=$1
    fi

    # TODO: put ids in or so dont iterate
    shift;
    for id in $*; do
        sed -i "s/\($id \[.\] \)(.)/\1($priority)/" $TODO_LIST
    done

    lsTodoAll
    echo "TODOs $* now has priority $priority"
}


createCategory() {
    # Create a new category
    #
    # $1: cat name

    cat=$1

    # Find string length and print N '='
    equals=`printf "%${#cat}s" | tr " " "="`

    if [ `stat -c %s $TODO_LIST` -eq 0 ]; then
        echo -e "$cat\n$equals" > $TODO_LIST
    else
        sed -i '$a'"\\\n$cat\n$equals" $TODO_LIST
    fi
}

lsCategories() {
    # List categories
    sed -n -e '/^[A-Za-z]/p' $TODO_LIST
}

lsTodoCategories() {
    # List all todo in category
    #
    # $1: category

    for category in "$@"; do
        #sed -n -e "/^$category/,/^[a-zA-Z][.]*/p" $TODO_LIST | sed -n -e "/^[0-9]* \[/p" | prettify
        sed -n -e "/^$category/,/^$/p" $TODO_LIST | sed '$d' | prettify
    done
}

lsTodoAll() {
    _lastTodoID
    if [ $TODO_LAST_ID -le 9 ]; then
        TODO_ID_DIGITS=1
    elif [ $TODO_LAST_ID -ge 10 ] && [ $TODO_LAST_ID -le 99 ]; then
        TODO_ID_DIGITS=2
        #cat $TODO_LIST | sed "s/^\([0-9]\) \[/ \1 [/" | prettify

    elif [ $TODO_LAST_ID -ge 100 ] && [ $TODO_LAST_ID -le 999 ]; then
        TODO_ID_DIGITS=3
        #cat $TODO_LIST | sed "s/^\([0-9]\) \[/  \1 [/" |
        #    sed "s/^\([0-9]\{2\}\) \[/ \1 [/" | prettify

    else
        TODO_ID_DIGITS=4 # greater than 1000!!!
    fi

    cat $TODO_LIST | prettify
}

filter() {
    # Filter by params


    # Default
    status='.'
    priority='.'

    # Search status and priority
    for i in "$@"; do
        case $i in
            '?' | "x" | "o") status=$i; shift ;;
            '!' | "L" | "H") priority=$i; shift ;;

            # Out when you find the first letter, may be the category or
            # free text
            * ) break ;;
        esac
    done

    cat $TODO_LIST | sed -n -e "/^[0-9][0-9]* \[$status\] ($priority)/p" |
        prettify
}

highlightTodo() {
    id=$1
    sed "s/^$id.*/$2&$TODO_COL_NO/"
}

prettify() {

    _lastTodoID
    if [ $TODO_LAST_ID -le 9 ]; then
        TODO_ID_DIGITS=1
        colorify
    elif [ $TODO_LAST_ID -ge 10 ] && [ $TODO_LAST_ID -le 99 ]; then
        TODO_ID_DIGITS=2
        sed "s/^\([0-9]\) \[/ \1 [/" | colorify

    elif [ $TODO_LAST_ID -ge 100 ] && [ $TODO_LAST_ID -le 999 ]; then
        #TODO_ID_DIGITS=3
        sed "s/^\([0-9]\) \[/  \1 [/" |
        sed "s/^\([0-9]\{2\}\) \[/ \1 [/" | colorify
    else
        TODO_ID_DIGITS=4 # greater than 1000!!!
    fi
}

colorify() {
    sed "s/^[a-zA-Z].*/$TODO_COL_CAT&$TODO_COL_NO/" |
    sed "s/\([0-9][0-9]* \[\)\(x\)\]\|\(?\)\]/\1$TODO_COL_DONE\2$TODO_COL_PEND\3$TODO_COL_NO]/"|
    sed "s/\((\)\(!\))\|\(H\))\|\(L\))/\1$TODO_COL_BUG\2$TODO_COL_H\3$TODO_COL_L\4$TODO_COL_NO)/"
}

clean() {
    rm $TODO_LIST
    touch $TODO_LIST
}


# Main, execute the command
# $0 is still the script name
# $1 is the command

# Reset any color
echo $TODO_COL_NO

if [ $# -eq 0 ]; then
  lsTodoAll
  exit 1
fi

action=$1;shift

case $action in


"a" | "add" ) add "$@" ;;
"d" | "del" ) delete $* ;;

# List TODOs by category
"ls" )
    if [ $# -eq 0 ]; then
        # No category, list all
        lsTodoAll
    else
        lsTodoCategories "$@"
    fi
;;

# Filter, find, order...
"/" | "f" ) filter "$@" ;;

# List categories
"lscat" ) lsCategories ;;


# Mark as done, pending or todo
"x" | "?" | "o" ) mark $action $* ;;
"m" | "mark" )
    marker=$1
    shift;
    mark $marker $*
;;


# Set priority
"!" | "H" | "L" | "0" ) setPriority $action $* ;;
"p" | "priority" )
    priority=$1
    shift;
    setPriority $priority $*
;;


* )
    echo 'Any help?'
;;
esac

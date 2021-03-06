#! /bin/sh

_DEBUG=1

# == PROCESS OPTIONS ==
while getopts ":fhpcnNaAtTvVx+@Pd:" Option
do
  case $Option in


    h )
        # Short-circuit option parsing and forward to the action.
        # Cannot just invoke shorthelp() because we need the configuration
        # processed to locate the add-on actions directory.
        set -- '-h' 'shorthelp'
        OPTIND=2
        ;;
    v )
        : $(( TODO_VERBOSE++ ))
        ;;
    V )
        version
        ;;
  esac
done

# Shift the params to delete options
shift $(($OPTIND - 1))

# Defaults if not defined
TODO_LIST=${TODO_LIST:-./todo}
TODO_LIST_DEPTH=${TODO_LIST_DEPTH:-3}
TODO_VERBOSE=${TODO_VERBOSE:-1}
TODO_CFG_FILE=${TODO_CFG_FILE:-$HOME/.todo/config}

TODO_CLEAR_TERM=${TODO_CLEAR_TERM:-1}

TODO_FILTER_BYPASS=1
TODO_FILTER_STATUS='.'
TODO_FILTER_PRIORITY='.'
TODO_HIDE_DONE=${TODO_HIDE_DONE:-1}

TODO_HL_ID=0
TODO_HL_COL=0


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
TODO_COL_UPD=`echo -e "\e[$NORMAL;$(( $YELLOW+10 ))m"`

TODO_COL_DONE=`echo -e "\e[$BOLD;${RED}m"`
TODO_COL_PEND=`echo -e "\e[$BOLD;${YELLOW}m"`

TODO_COL_BUG=`echo -e "\e[$BOLD;${RED}m"`
TODO_COL_H=`echo -e "\e[$BOLD;${YELLOW}m"`
TODO_COL_L=`echo -e "\e[$BOLD;${GREEN}m"`


######## Options parsing end


# REGEX

TODO_RE_TODO_LINE='^[0-9][0-9]*'

# REGEX END

DEBUG() {
    [ $_DEBUG -ne 0 ] && $@
}

_countTodo() {
    TODO_COUNT=`sed -n -e "/$TODO_RE_TODO_LINE \[/p" $TODO_LIST | sed -n '$='`
}

_lastTodoID() {
    TODO_LAST_ID=`sed -n -e "/$TODO_RE_TODO_LINE/p" $TODO_LIST |
                  sort -n |
                  sed -n -e '$p' |
                  sed "s/\($TODO_RE_TODO_LINE\).*/\1/"`

    # When there are not TODOs
    [ -z "$TODO_LAST_ID" ] && TODO_LAST_ID=0
}

add() {
    # Create a TODO on a given category

    # Get category
    cat=$1; shift

    if [ $# -eq 0 ]; then
        echo "Can't create an empty TODO in category $cat"
        exit 1;
    fi

    found_cat=`lsCategories | sed -n -e "/^$cat$/p"`
    if [ "$found_cat" != "$cat" ]; then
        createCategory $cat
        echo -e "Created category $TODO_COL_CAT$cat"
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

    # Check for non empty body
    body="$@"
    [ -z "$body" ] && exit 1

    # Find the last TODO ID (which may be not the count!)
    _lastTodoID
    id=$(( $TODO_LAST_ID+1 ))

    # Line number of the '=' below category name
    line=$(( `sed -n -e "/^$cat$/=" $TODO_LIST`+1 ))
    if [ -z "$line" ]; then exit 1; fi

    # Write the TODO
    todo="$id [$mark] ($priority) $body"
    sed -i "${line}a $todo" $TODO_LIST

    _setHighlighter $id $TODO_COL_NEW

    lsTodoCategories $cat | draw
    echo -e "\nCreated ${TODO_COL_NEW}TODO #${id}${TODO_COL_NO} in '$cat'"
}

delete() {
    # Delete a todo
    #
    # $*: ids

    for id in $*; do
        sed -i "/^$id /d" $TODO_LIST
    done

    _setHighlighter $id $TODO_COL_DEL

    lsTodoAll | draw
    echo -e "\nDeleted ${TODO_COL_DEL}TODO #${id}${TODO_COL_NO} from '...'"
}

edit() {
    # Edit a TODO
    #
    # $1: ID

    id=$1

    body=`sed -n "/^$id /s/^$id \[.\] (.) \(.*\)/\1/p" $TODO_LIST`

    read -e -p "Edit> " -i "$body" body_new

    _setHighlighter $id $TODO_COL_UPD

    sed "s/\(^$id \[.\] (.) \).*/\1$body_new/" $TODO_LIST | draw

    echo -e "\nUpdated body of ${TODO_COL_UPD}TODO #$id${TODO_COL_NO}. Old: ${TODO_COL_UPD}${body}${TODO_COL_NO}"
}


setStatus() {
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
        sed -i "s/\(^$id \)\[.\]/\1[$mark]/" $TODO_LIST
    done

    # Bypass filter otherwise may hide the todo with the new status
    TODO_FILTER_BYPASS=1
    _setHighlighter $id $TODO_COL_UPD

    lsTodoAll
    echo -e "\nMarked ${TODO_COL_UPD}TODO #${id}${TODO_COL_NO} as ${TODO_COL_UPD}$mark${TODO_COL_NO}"
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
        sed -i "s/\(^$id \[.\] \)(.)/\1($priority)/" $TODO_LIST
    done

    # Bypass filter otherwise may hide the todo with the new priority
    TODO_FILTER_BYPASS=1
    _setHighlighter $id $TODO_COL_UPD

    lsTodoAll
    echo -e "\nSet priority for ${TODO_COL_UPD}TODO #${id}${TODO_COL_NO} to ${TODO_COL_UPD}$priority${TODO_COL_NO}"
}


createCategory() {
    # Create a new category
    #
    # $1: cat name

    cat=$1

    # Find string length and print N '='
    underline=`printf "%${#cat}s" | tr " " "="`

    if [ `stat -c %s $TODO_LIST` -eq 0 ]; then
        echo -e "$cat\n$underline" > $TODO_LIST
    else
        sed -i '$a'"\\\n$cat\n$underline" $TODO_LIST
    fi
}

## List actions ##

showTodo() {
    sed -n -e "/^$1 /p" $TODO_LIST | draw
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
        # Delete the last line only if it is blank
        sed -n -e "/^$category/,/^$/p" $TODO_LIST | sed '${/^$/d;}' | draw
    done
}

lsTodoAll() {
    cat $TODO_LIST | draw
}



### Core functions ###

_setFilter() {
    # Filter by params

    TODO_FILTER_STATUS=''
    TODO_FILTER_PRIORITY=''

    # Search status and priority
    for i in "$@"; do

        # Use the == "$i" for enhanced reliability due to strange chars
        if [[ `echo $i | sed -n '/^^*[x?]/p'` == "$i" ]]; then

                #if [ "$i" == "o" ]; then i=' '; fi
                TODO_FILTER_STATUS="${TODO_FILTER_STATUS}[$i]\|";
                TODO_FILTER_BYPASS=0
                shift

        elif [[ `echo $i | sed -n '/^^*[!HL]/p'` == "$i" ]]; then

                #if [ "$i" == "0" ]; then i=' '; fi
                TODO_FILTER_PRIORITY="${TODO_FILTER_PRIORITY}[$i]\|";
                TODO_FILTER_BYPASS=0
                shift

        elif [[ $i == '*' || $i == '.' ]]; then
            TODO_FILTER_STATUS="."
            TODO_FILTER_PRIORITY="."
            TODO_FILTER_BYPASS=0
        else
            # Out when you find the first letter, may be the category or
            # free text
            break
        fi
    done

    # The filter has been emptied at the beginning of the function
    if [ -n "$TODO_FILTER_STATUS" ]; then
        TODO_FILTER_STATUS="\($TODO_FILTER_STATUS\)"
    else
        TODO_FILTER_STATUS='.'
    fi

    if [ -n "$TODO_FILTER_PRIORITY" ]; then
        TODO_FILTER_PRIORITY="\($TODO_FILTER_PRIORITY\)"
    else
        TODO_FILTER_PRIORITY='.'
    fi

}

_setHighlighter() {
    # Setup highlighter
    #
    # $1: ID
    # $2: Highlight color

    TODO_HL_ID=$1
    TODO_HL_COL=$2
}

highlightify() {
    # Highlight an entire TODO
    #
    # $TODO_HL_ID: ID
    # $TODO_HL_COL: Highlight color

    id=$TODO_HL_ID
    color=$TODO_HL_COL

    sed "s/^[ ]*$id .*/$color&$TODO_COL_NO/"
}

columnify() {

    _lastTodoID
    if [ $TODO_LAST_ID -le 9 ]; then
        #TODO_ID_DIGITS=1
        colorify
    elif [ $TODO_LAST_ID -ge 10 ] && [ $TODO_LAST_ID -le 99 ]; then
        #TODO_ID_DIGITS=2
        sed "s/^\(^[0-9]\) \[/ \1 [/"

    elif [ $TODO_LAST_ID -ge 100 ] && [ $TODO_LAST_ID -le 999 ]; then
        #TODO_ID_DIGITS=3
        sed "s/^\([0-9]\) \[/  \1 [/" |
        sed "s/^\([0-9]\{2\}\) \[/ \1 [/"
    else
        #TODO_ID_DIGITS=4
        sed "s/^\([0-9]\) \[/   \1 [/" |
        sed "s/^\([0-9]\{2\}\) \[/  \1 [/" |
        sed "s/^\([0-9]\{3\}\) \[/ \1 [/"
    fi
}

colorify() {
    sed "s/^[a-zA-Z].*/$TODO_COL_CAT&$TODO_COL_NO/" |

    if [ $TODO_HL_ID -ne 0 ]; then
        highlightify
    else
        sed "s/\([0-9][0-9]* \[\)\(x\)\]\|\(?\)\]/\1$TODO_COL_DONE\2$TODO_COL_PEND\3$TODO_COL_NO]/"|
        sed "s/\((\)\(!\))\|\(H\))\|\(L\))/\1$TODO_COL_BUG\2$TODO_COL_H\3$TODO_COL_L\4$TODO_COL_NO)/"
    fi
}

filter() {

    status=${TODO_FILTER_STATUS:-'.'}
    priority=${TODO_FILTER_PRIORITY:-'.'}

    sed -n -e "/\(^[0-9][0-9]* \[$status\] ($priority)\)\|\(^[^0-9]\)\|\(^$\)/p"
}

comments() {
    # To remove blank lines before content, use:
    # sed '/./,$!d'

    # Remove comments
    sed "/^[#]/d"
}

draw() {
    # Always pipe to this function to print!

    if [ $TODO_FILTER_BYPASS -eq 0 ]; then
        comments | filter | columnify | colorify
    else
        comments          | columnify | colorify
    fi
}

_createListFile() {

new_list=`cat <<HERE
# To do list managed with: TODO http://github.com/lucafaggianelli/todo
#
# You can edit it by hand following the format:
#
# 28  = Unique id in entire list!
# [ ] = Status. [x] done, [?] pending, [ ] to do
# ( ) = Priority. (!) critical, (H) high, (L) low
# text= TODO body on 1 line!
# #   = 1 line comment
#
# Note: No spaces at the beginning of the line! 1 space to separate elements!
#
# Category
# ========
# 28 [x] (!) TODO body on one line
HERE`

    # Check again that file doesn't exist, you don't want to mess up the user list
    # also use append (>>) as a triple check!
    if [ ! -e "$TODO_LIST" ]; then
        touch "$TODO_LIST"
        echo "$new_list" >> "$TODO_LIST"
    fi
}


_findTodoListFile() {
    for (( i=0; i<=TODO_LIST_DEPTH; i++ )); do
        depth=''
        for (( j=0; j<i; j++ )); do
            depth="$depth../"
        done

        if [[ -e "${depth}${TODO_LIST}" && ! -d "${depth}${TODO_LIST}" ]]; then
            if [ ! -r "${depth}${TODO_LIST}" ];then
                echo "File "${depth}${TODO_LIST}" not readable"
                exit 1
            fi

            if [ ! -w "${depth}${TODO_LIST}" ];then
                echo "File "${depth}${TODO_LIST}" not writable"
                exit 1
            fi

            TODO_LIST="${depth}${TODO_LIST}"
            return
        fi
    done

    echo "File $TODO_LIST doesn't exist here, till $TODO_LIST_DEPTH levels up."
    read -e -p "Create the file $TODO_LIST? (y/n)> " decision
    [ "$decision" == 'y' ] && _createListFile
    exit 1
}

clean() {
    rm $TODO_LIST
    touch $TODO_LIST
}

##########################################################################
#                                   MAIN
# $0 is still the script name
# $1 is the command

_findTodoListFile

# Clear terminal
[ $TODO_CLEAR_TERM -eq 1 ] && clear

# Set filter for user preferences
[ $TODO_HIDE_DONE -eq 1 ] && _setFilter '^x'

# Default action
if [ $# -eq 0 ]; then
    lsTodoAll
    exit 1
fi

# Fetch the command
action=$1;shift


# Smart CLI
# Workaround for / command
TODO_ID=`echo $action | sed -n '/^[0-9][0-9]*$/p'`
[ `echo $action | sed -n '/^[a-zA-Z][a-zA-Z]*$/p'` ] &&
    TODO_CAT=`lsCategories | sed -n "/^$action$/p"` || TODO_CAT=''


# You selected a TODO what next?
if [ -n "$TODO_ID" ]; then

    # If no command, show the todo
    # e.g.: t 14
    if [ "$#" == "0" ]; then
        showTodo $TODO_ID
        exit 1

    # Set status
    # e.g.: t 14 x
    elif [[ $1 == 'x' || $1 == '?' || $1 == 'o' ]]; then
        setStatus $1 $TODO_ID
        exit 1

    # Set priority
    # e.g.: t 14 !
    elif [[ $1 == '!' || $1 == 'H' || $1 == 'L' || $1 == '0' ]]; then
        setPriority $1 $TODO_ID
        exit 1

    # Edit
    # e.g.: t 14 edit
    elif [[ "$1" == 'edit' || "$1" == 'e' ]]; then
        edit $TODO_ID
        exit 1

    # Remove
    # e.g.: t 14 rm
    elif [[ "$1" == 'remove' || "$1" == 'rm' ]]; then
        delete $TODO_ID
    fi

# You selected a Category what next?
elif [ -n "$TODO_CAT" ]; then

    # Category as first arg and nothing => lscat
    # e.g.: t Core
    if [ "$#" == "0" ];then
        lsTodoCategories "$TODO_CAT"
        exit 1

    # If there is something more than the cat, you want to add a TODO into it
    # t Core ! Great todo
    else
        add "$TODO_CAT" "$@"
    fi
fi


### RETROCOMPATIBILITY ###

# Execute a command
case $action in


"a" | "add" ) add "$@" ;; # Done

"r" | "rm" ) delete $* ;; # Done

# List TODOs by category
"ls" )
    # If you are typing ls, maybe you want to see everything...
    _setFilter '.'

    if [ "$#" == "0" ]; then
        # No category, list all
        lsTodoAll
    else
        lsTodoCategories "$@"
    fi
;;

# List categories
"lscat" ) lsCategories ;;

# Edit TODO
"e" | "edit" ) edit $1 ;; # Done

# Filter, find, order...
"/" | "f" )
    _setFilter "$@"
    lsTodoAll
;;


# Mark as done, pending or todo
"x" | "?" | "o" ) setStatus $action $* ;; #Done
"m" | "mark" )
    marker=$1
    shift;
    setStatus $marker $*
;;


# Set priority
"!" | "H" | "L" | "0" ) setPriority $action $* ;; # Done
"p" | "priority" )
    priority=$1
    shift;
    setPriority $priority $*
;;

# Test
"t" )
    echo 'test'
;;

* )
    echo 'Any help?'
;;
esac

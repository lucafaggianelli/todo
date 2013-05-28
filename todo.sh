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

######## Options parsing end

DEBUG() {
    [ $_DEBUG -ne 0 ] && $@
}

add() {

    cat=$1
    shift
    todo="$@"
    # make it smarter with ! ? etc...

    id=`sed -n -e "/^$cat/,/^[a-zA-Z][.]*/p" $TODO_LIST |
          sed -n -e "/^[0-9]* \[/p" |
          sed 's/^\([0-9]*\) .*/\1/' |
          sed -n '$p'`

    new_id=$(( $id+1 ))

    todo="$(( $id+1 )) [ ] ( ) $todo"

    sed "/^$id/a $todo" $TODO_LIST
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
        echo $id
        sed "s/\($id \)\[.\]/\1[$mark]/" $TODO_LIST
    done
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
        sed "s/\($id \[.\] \)(.)/\1($priority)/" $TODO_LIST
    done
}

lsCategories() {
    # List categories
    sed -n -e '/^[A-Za-z]/p' $TODO_LIST
}

lsTodoCategories() {
    # List all todo in category
    #
    # $1: category

    #category=$1

    for category in "$@"; do
        echo $category
        sed -n -e "/^$category/,/^[a-zA-Z][.]*/p" $TODO_LIST | sed -n -e "/^[0-9]* \[/p"
    done
}

lsTodoAll() {
    less $TODO_LIST
}


# Main, execute the command
# $0 is still the script name
# $1 is the command

action=$1
shift;

case $action in


"a" | "add" )
    add "$@"
;;

# List TODOs by category
"ls" )

    if [ $# -eq 0 ]; then
        # No category, list all
        lsTodoAll
    else
        lsTodoCategories "$@"
    fi
;;


# List categories
"lscat" ) lsCategories ;;


# Mark as done, pending or todo
"x" | "?" | "o" ) mark $action $@ ;;
"m" | "mark" )
    marker=$1
    shift;
    mark $marker $@
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

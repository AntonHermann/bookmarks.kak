declare-option -hidden line-specs bookmarks
declare-option -hidden line-specs bookmarks_short

declare-user-mode bookmarks

map global bookmarks b '<esc>: bookmarks-menu<ret>' -docstring "Jump to a bookmark"
map global bookmarks d '<esc>: bookmarks-delete<ret>' -docstring "Delete a bookmark"
map global bookmarks a '<esc>: bookmarks-add<ret>' -docstring "Bookmark current cursor position"
map global bookmarks t '<esc>: bookmarks-toggle-short<ret>' -docstring "Toggle short/long display"
map global bookmarks h '<esc>: bookmarks-hide<ret>' -docstring "Hide bookmark line-markings"
map global bookmarks n '<esc>: bookmarks-next<ret>' -docstring "goto next bookmark"
map global bookmarks p '<esc>: bookmarks-prev<ret>' -docstring "goto previous bookmark"

define-command -params 0..1 bookmarks-enable -docstring %{
    bookmarks-enable [key]
    Enables bookmarks user mode, optionally mapping 'user+key' to enter bookmark mode
} %{
    evaluate-commands %sh{
        if [ $# -eq 1 ] ; then
            printf "map window user %s '<esc>: enter-user-mode bookmarks<ret>' -docstring 'Bookmarks mode'\n" "$1"
            printf "echo 'bookmarks: %s'\n" "$1"
        fi
    }
    bookmarks-enable-short
}

define-command bookmarks-hide %{
    remove-highlighter window/bookmarks
    remove-highlighter window/bookmarks_s
} -docstring "Hide bookmark line-markings"

define-command bookmarks-add %{
    prompt "Bookmark name:" %{
        update-option window bookmarks
        set-option -add window bookmarks "%val{cursor_line}|%val{text}"       
    }
}

define-command bookmarks-menu %{
    bookmarks-menu-command bookmarks-jump-id
}

define-command bookmarks-delete %{
    bookmarks-menu-command bookmarks-delete-id
}

define-command -params 1 bookmarks-menu-command %{ evaluate-commands %sh{
    arg=$1
    eval set -- ${kak_quoted_opt_bookmarks}
    shift

    if [ $# -eq 0 ] ; then
    	printf "fail 'Bookmarks list is empty'\n"
    	exit
    fi


    # Start the menu
    printf 'menu '

    # Iterate over bookmarks
    i=1
    for bookmark; do
    	#printf 'echo -debug "bookmark %i: %s"\n' $i "$bookmark"
        name=$(printf "$bookmark" | cut -s -d '|' -f 2)

	# Print the menu entry
    	printf "'%s' '%s %i' " "$name" "$arg" $i

    	i=$((i+1))
    done
}}

define-command -params 1 bookmarks-jump-id %{
    update-option window bookmarks
    evaluate-commands %sh{
    arg=$1
    eval set -- ${kak_quoted_opt_bookmarks}
    shift $arg
    line=$(printf "$1" | cut -s -d '|' -f 1)
    name=$(printf "$1" | cut -s -d '|' -f 2)
    if [ -z "$line" -o -z "$name"]; then
    	printf 'fail "Invalid bookmark number: %s"\n' "$arg"
    else
        printf "execute-keys '%ig'\n" "$line"
        printf "echo 'bookmark arg $arg line $line name $name'\n"
        printf "info 'Went to bookmark \"$name\"'"
    fi
}}

define-command -params 1 bookmarks-delete-id %{
    update-option window bookmarks
    evaluate-commands %sh{
        arg="$1"
        eval set -- ${kak_quoted_opt_bookmarks}
        shift
        printf 'set-option window bookmarks %%val{timestamp}'
        i=1
        for bookmark; do
            if [ $i -ne "$arg" ] ; then
            	printf " '%s'" "$bookmark"
            fi
    	    i=$((i+1))
    	done
    }
}

define-command bookmarks-toggle-short %{
    try %{
        add-highlighter window/bookmarks flag-lines blue bookmarks
        echo -debug 'bookmark: long display'
        remove-highlighter winow/bookmarks_s
        remove-hooks window bookmarks-update
    } catch %{
        echo 'bookmark: short display'
        bookmarks-enable-short
    }
}
define-command bookmarks-update-short -hidden %{
    evaluate-commands %sh{
        eval set -- ${kak_quoted_opt_bookmarks}
        shift

        # if `bookmarks` is empty, so should `bookmarks_short`
        if [ $# -eq 0 ] ; then
            printf 'unset-option window bookmarks_short\n'
            exit;
        fi

        # construct bookmarks_short from bookmarks by shortening the name
        printf 'set-option window bookmarks_short %%val{timestamp}'
        for bookmark; do
            line=$(printf "$bookmark" | cut -s -d '|' -f 1)
            name_short=$(printf "$bookmark" | cut -s -d '|' -f 2 | cut -c 1)

        	printf " '%s|%s'" "$line" "$name_short"
        done
    }
}
define-command bookmarks-enable-short %{
    hook -group bookmarks-update -always window WinSetOption bookmarks=.* %{
        bookmarks-update-short
    }
    add-highlighter -override window/bookmarks_s flag-lines blue bookmarks_short
    try %{ remove-highlighter window/bookmarks }
}

define-command bookmarks-next -docstring "goto next bookmark" %{
    fail "TODO: not implemented yet!"
}
define-command bookmarks-prev -docstring "goto previous bookmark" %{
    fail "TODO: not implemented yet!"
}

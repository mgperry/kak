# https://www.r-project.org/
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*[.](r|R|Rscript) %{
    set-option buffer filetype r
}

# Highlighters & Completion
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter shared/r regions
add-highlighter shared/r/code default-region group
add-highlighter shared/r/double_string  region '"'   (?<!\\)(\\\\)*"  fill string
add-highlighter shared/r/single_string  region "'"   (?<!\\)(\\\\)*'  fill string
add-highlighter shared/r/deparse_string region '`'   '`'              fill string
add-highlighter shared/r/comment        region '#'   '$'              fill comment

# numerical formats
add-highlighter shared/r/code/ regex '(?i)\b([1-9]\d*|0)l?\b' 0:value
add-highlighter shared/r/code/ regex '\b\d+[eE][+-]?\d+\b' 0:value
add-highlighter shared/r/code/ regex '(\b\d+)?\.\d+\b' 0:value
add-highlighter shared/r/code/ regex '\b\d+\.' 0:value

evaluate-commands %sh{
    # Grammar
    values="TRUE|FALSE|T|F|NA|NULL|Inf|NA_integer_|NA_real_|NA_complex_|NA_character_"
    meta="library|source"

    # Are there any other exception like things?
    exceptions="stop|try|catch|quit|q"

    # Keyword list from https://stat.ethz.ch/R-manual/R-devel/library/base/html/Reserved.html
    keywords="if|else|repeat|while|function|for|in|next|break"

    # incomplete list of common types
    types="vector|list|integer|complex|numeric|double|factor"

    # from https://www.statmethods.net/management/functions.html, full list is massive (see builtins())
    functions="abs|acos|acosh|c|ceiling|cos|cosh|cut|diff|dnorm|exp|floor|grep"
    functions="${functions}|is[.]na|is[.]infinite|is[.]nan|is[.]null"
    functions="${functions}|log|log10|mad|max|mean|median|min|object|paste|plot|pretty|quantile"
    functions="${functions}|range|rep|round|scale|sd|seed|seq|signif|sin|sqrt|strsplit|sub"
    functions="${functions}|substr|sum|tan|tolower|toupper|trunc|var"
    functions="${functions}|print|dev|dev[.]off|plot|paste|paste0"

    distributions="unif|binom|cauchy|chisq|exp|f|gamma|geom|hyper|logis|lnorm"
    distributions="${distributions}|nbinom|norm|pois|signrank|t|unif|weibull|wilcox"

    # Add the language's grammar to the static completion list
    printf %s\\n "hook global WinSetOption filetype=r %{
        set-option window static_words ${values} ${meta} ${attributes} ${methods} ${exceptions} ${keywords} ${types} ${functions}
    }" | tr '|' ' '

    # Highlight keywords
    printf %s "
        add-highlighter shared/r/code/ regex '\b(${values})\b' 0:value
        add-highlighter shared/r/code/ regex '\b(${meta})\b' 0:meta
        add-highlighter shared/r/code/ regex '\b(${exceptions})\b' 0:function
        add-highlighter shared/r/code/ regex '\b(${keywords})\b' 0:keyword
        add-highlighter shared/r/code/ regex '\b(${functions})\b' 0:builtin
        add-highlighter shared/r/code/ regex '\b[dpqr](${distributions})\b' 0:builtin
        add-highlighter shared/r/code/ regex '\b(${types})\b' 0:type
        add-highlighter shared/r/code/ regex '\bas[.](${types})\b' 0:type
    "
}

# symbols
add-highlighter shared/r/code/ regex [*!$&+<>=^~:@-] 0:operator
add-highlighter shared/r/code/ regex '(%%|%/%|%in%|%[*]%|%>%)' 0:operator

# Hadleyverse
# ‾‾‾‾‾‾‾‾‾‾‾

define-command -hidden r-insert-pipe %{ try %{
    exec -draft hH<a-k>\|\s<ret>
    exec -draft hh c%>%
}}

# Commands
# ‾‾‾‾‾‾‾‾

define-command -hidden r-indent-on-new-line %~
    evaluate-commands -draft -itersel %=
        # preserve previous line indent
        try %{ execute-keys -draft \;K<a-&> }
        # indent after lines ending with { or (
        try %[ execute-keys -draft k<a-x> <a-k> [{(]\h*$ <ret> j<a-gt> ]
        # indent after initial + or %>%
        try %{ execute-keys -draft k<a-x> <a-k> \A\H.*((%>%)|\+)\h*$ <ret> j<a-gt> }
        # cleanup trailing white spaces on the previous line
        try %{ execute-keys -draft k<a-x> s \h+$ <ret>d }
        # align to opening paren of previous line
        try %{ execute-keys -draft [( <a-k> \A\([^\n]+\n[^\n]*\n?\z <ret> s \A\(\h*.|.\z <ret> '<a-;>' & }
        # copy # comments prefix
        try %{ execute-keys -draft \;<c-s>k<a-x> s ^\h*\K# <ret> y<c-o>P<esc> }
        # indent after a switch's case/default statements
        try %[ execute-keys -draft k<a-x> <a-k> ^\h*(case|default).*:$ <ret> j<a-gt> ]
        # indent after if|else|while|for
        try %[ execute-keys -draft \;<a-F>)MB <a-k> \A(if|else|while|for)\h*\(.*\)\h*\n\h*\n?\z <ret> s \A|.\z <ret> 1<a-&>1<a-space><a-gt> ]
    =
~

define-command -hidden r-indent-on-opening-curly-brace %[
    # align indent with opening paren when { is entered on a new line after the closing paren
    try %[ execute-keys -draft -itersel h<a-F>)M <a-k> \A\(.*\)\h*\n\h*\{\z <ret> s \A|.\z <ret> 1<a-&> ]
]

define-command -hidden r-indent-on-closing-curly-brace %[
    # align to opening curly brace when alone on a line
    try %[ execute-keys -itersel -draft <a-h><a-k>^\h+\}$<ret>hms\A|.\z<ret>1<a-&> ]
]


# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook -group r-highlight global WinSetOption filetype=r %{ add-highlighter window/r ref r
}


hook global WinSetOption filetype=r %{
    hook window InsertChar " " -group r-pipe r-insert-pipe
    hook window InsertChar \n -group r-pipe r-insert-pipe
}

hook global WinSetOption filetype=r %{
    # cleanup trailing whitespaces when exiting insert mode
    hook window ModeChange insert:.* -group r-hooks %{ try %{ execute-keys -draft <a-x>s^\h+$<ret>d } }
    hook window InsertChar \n -group r-indent r-indent-on-new-line
    hook window InsertChar \{ -group r-indent r-indent-on-opening-curly-brace
    hook window InsertChar \} -group r-indent r-indent-on-closing-curly-brace
}

hook -group r-highlight global WinSetOption filetype=(?!r).* %{ remove-highlighter window/r
}

hook global WinSetOption filetype=(?!r).* %{
    remove-hooks window r-hooks
    remove-hooks window r-indent
    remove-hooks window r-pipe
}

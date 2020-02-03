# kakrc

### OPTIONS ###

set global grepcmd 'rg --column'

### KEYBINDINGS ###

# swap l and t for dvorak
map global normal t l
map global normal T L
map global normal <a-t> <a-l>
map global normal <a-T> <a-L>

map global normal l t
map global normal L T
map global normal <a-l> <a-t>
map global normal <a-L> <a-T>

map -docstring 'line end' global goto t l
# unmap global goto l # doesn't work :O

# swap f with /
map global normal f '/'
map global normal F '?'
map global normal <a-f> '<a-/>'
map global normal <a-F> '<a-?>'

map global normal / f
map global normal <a-/> <a-f>
map global normal ? F
map global normal <a-?> <a-F>

# easy comments
map global normal '#' :comment-line<ret>
map global normal '<a-#>' :comment-block<ret>

# tab for <> in insert
# it's funny on newlines for some reason
map global insert <tab> '<a-;><a-gt>'
map global insert <s-tab> '<a-;><a-lt>'
map global insert <a-tab> <tab>

# tab for bn in normal
map global normal <tab> ':bn<ret>'
map global normal <s-tab> ':bp<ret>'

# swap ; and <space>

# map global normal ';' <space>
# map global normal <space> ';'
# map global normal '<a-;>' <a-space>
# map global normal <a-space> '<a-;>'

map global insert <backspace> '<a-;>:insert-bs<ret>'
# hook global InsertChar <backspace> %{ try %{
#     exec -draft h %opt{indentwidth}HL <a-k>\A<space>+\z<ret> d
# } }

def -hidden insert-bs %{
    try %{
        # delete indentwidth spaces before cursor
        exec -draft h %opt{indentwidth}HL <a-k>\A<space>+\z<ret> d
    } catch %{
        exec <backspace>
    }
}

hook global InsertChar k %{ try %{
    exec -draft hH <a-k>jk<ret> d
    exec <esc>
}}

### R ASSIGNMENT ###

def -hidden assignment-operator %{
    # space in front
    try %{
        exec -draft h <a-k><space><ret> d
        exec -draft hl <a-k><space><ret> d
    }
    exec '<space><lt><minus><space>'
}

def -hidden assignment-reverse %{
    # space in front
    try %{
        exec -draft h <a-k><space><ret> d
        exec -draft hl <a-k><space><ret> d
    }
    exec '<space><minus><gt><space>'
}

map global insert <a-minus> '<a-;>:assignment-operator<ret>'
map global insert <a-_> '<a-;>:assignment-reverse<ret>'

### LINES AND PARAGRAPHS ###

map global normal X X<a-x> # easier on the fingers, we usually want both
map global normal <a-x> 'h<a-x><a-;>'
map global normal <a-X> 'H<a-x><a-:><a-;>'
map global normal <minus> '<a-s>glGi_'

# hook global WinCreate .* %{ autowrap-enable }
set-option global autowrap_format_paragraph yes

map global normal = '_:autowrap-selection<ret>'

def autowrap-selection %{
    try %{
        exec -draft "s\n.<ret>" #multiline selection
    } catch %{
        exec '<a-o>' # escape default a-j behaviour
    }
    exec "<a-x><a-j>|fold -s -w %opt{autowrap_column}<ret>"
    try %{ exec -draft 's\h+$<ret>d' }
}

### WHITESPACE ###

set-option global tabstop 4

### SURROUND ###

map global normal I :auto-pairs-surround<ret>
map global normal <a-i> I

# match spaces when surrounding words
# set-option -add global auto_pairs ' ' ' '

hook global WinSetOption filetype=markdown %{
  set-option -add buffer auto_pairs_surround _ _ * *
}

hook global WinCreate .* %{
    add-highlighter window/show-matching show-matching
}

### REGISTERS ###

def show-register %{
    on-key %{
        eval %sh{ printf %s "echo %reg{$kak_key}" }
    }
}

# allow copying to system clipboard
map global normal Y y:pbcopy<ret>
map global normal D :pbcopy<ret>d

def pbcopy %{
    execute-keys "<a-|>pbcopy<ret>"
}

### OBJECT SELECTION ###

declare-user-mode object-motion

map global normal v ":enter-user-mode object-motion<ret>"

map global object-motion a -docstring "around object"          '<a-a>'
map global object-motion i -docstring "inside object"          '<a-i>'
map global object-motion h -docstring "inner start of object"  '<a-[>'
map global object-motion H -docstring "outer start of object"  '['
map global object-motion t -docstring "inner end of object"    '<a-]>'
map global object-motion T -docstring "outer end of object"    ']'

declare-user-mode object-motion-extend

map global normal V ":enter-user-mode object-motion-extend<ret>"

map global object-motion-extend h -docstring "inner start of object"  '<a-{>'
map global object-motion-extend H -docstring "outer start of object"  '{'
map global object-motion-extend t -docstring "inner end of object"    '<a-}>'
map global object-motion-extend T -docstring "outer end of object"    '}'

map global normal <a-v> v
map global normal <a-V> V
map global view <space> -docstring "exit" <esc>

### TEXT OBJECTS ###

map -docstring "rmarkdown block" global object <a-b> \
    "c```\{.?\}\n,```<ret>"

### CASES ###

declare-user-mode case

map global normal <a-~> ':enter-user-mode case<ret>'
map global normal '~' '<a-`>'

map global case l       -docstring "lowercase"      '`'
map global case u       -docstring "uppercase"      '~'
map global case c       -docstring "camelCase"      ':camelcase<ret>'
map global case k       -docstring "kebab-case"     ':kebabcase<ret>'
map global case s       -docstring "snake_case"     ':snakecase<ret>'
map global case <space> -docstring "separate words" ':to-spaces<ret>'

def camelcase %{
  exec 's[-_<space>]+<ret>d~<a-i>w'
}

def to-spaces %{
    try %{ exec -draft 's[a-z]\K[A-Z]<ret>i<space>' }
    try %{ exec -draft 's[-_<space>]+<ret>c<space>' }
}

def snakecase %{
    to-spaces
    exec 's\s+<ret>c_<esc><a-i>w`'
}

def kebabcase %{
    to-spaces
    exec 's\s+<ret>c-<esc><a-i>w`'
}

### AUTOINCREMENT ###

map global normal <c-a> ':increment %val{count} +<ret>'
map global normal <c-x> ':increment %val{count} -<ret>'

def -params 2 -docstring "<count> [+-] increase or decrease number" increment %{
    try %{
        exec -draft "<a-l>s\d<ret>" # check for number
        exec "<a-l>s\d+<ret>)<space><a-i>n:inc %arg{1} %arg{2}<ret>"
    }
}

def -params 2 -docstring "increment selected value" inc %{ eval %{
        reg '"' %sh{ echo "$kak_selection $2 $(( $1 > 0 ? $1 : 1 ))" | bc }
        exec R
} }

### TMUX REPL ###

declare-option -docstring "tmux split height" str tmux_height 20 

map global user v -docstring "vertical split" :tmux-repl-vertical-prompt<ret>

def tmux-repl-vertical-prompt -docstring "run command in a v-split" %{
    prompt "cmd: " %{
        tmux-repl-vertical '-l %opt{tmux_height} %val{text} '
    } 
}

map global user r -docstring "start R" \
    ':tmux-repl-vertical "-l %opt{tmux_height} R --no-save --no-restore" <ret>'

map global user h -docstring "start R (horizontal split" \
    ':tmux-repl-horizontal " R --no-save --no-restore" <ret>'

map global user p -docstring "start ipython3" \
    ':tmux-repl-vertical "-l %opt{tmux_height} ipython3" <ret>'

map global user , -docstring "send lines to tmux split" \
    "<a-x>:tmux-send-text<ret>jx"

map global user . -docstring "send selection to tmux split" \
    "_\a<ret><esc>:tmux-send-text<ret>a<backspace><esc>"

define-command -hidden tmux-send-c-c -docstring "send <c-c> to tmux repl" %{
     nop %sh{ tmux send-keys -t "$kak_opt_tmux_repl_id" C-c }
}

map global user c -docstring "repl-><c-c>" ":tmux-send-c-c<ret>"


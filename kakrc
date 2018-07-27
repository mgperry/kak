# kakrc

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
unmap global goto l

map global normal '#' :comment-line<ret>
map global normal '<a-#>' :comment-block<ret>

map global insert <tab> '<a-;><a-gt>'
map global insert <s-tab> '<a-;><a-lt>'

hook global InsertChar k %{ try %{
  exec -draft hH <a-k>jk<ret> d
  exec <esc>
}}

### LINES AND PARAGRAPHS ###

map global normal X X<a-x>
map global normal <a-x> 'k<a-x><a-;>'
map global normal <a-X> 'K<a-x><a-:><a-;>'
map global normal <minus> '_<a-s>_x_<a-;>'

hook global WinCreate .* %{ autowrap-enable }
set-option global autowrap_format_paragraph yes

map global normal = ':autowrap-selection<ret>'
 
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

map global normal <a-m> :auto-pairs-surround<ret>

# match spaces when surrounding words
set-option -add global auto_pairs ' ' ' ' * * 

# see https://www.reddit.com/r/kakoune/comments/7ud73x/simple_surround_command/

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

# this goes all the way up to 15 and down to -14 !!!

# seven times fifty is 350

# easier to use bc inline tbh
def math %{
    prompt "math: " %{
        reg '"' %sh{ echo "$kak_text" | bc }
        exec P
    }
}

### TMUX REPL ###

declare-option -docstring "tmux split height" str tmux_height 20 

map global user v -docstring "vertical split" :tmux-repl-vertical-prompt<ret>

def tmux-repl-vertical-prompt -docstring "run command in a v-split" %{
    prompt "cmd: " %{
        tmux-repl-vertical %{ -l %opt{tmux_height} %val{text} }
    } 
}

map global user r -docstring "start R" \
    ':tmux-repl-vertical "-l %opt{tmux_height} R --no-save --no-restore" <ret>'

map global user , -docstring "send lines to tmux split" \
    "<a-x>:tmux-send-text<ret>jx"

map global user . -docstring "send selection to tmux split" \
    ":send-selection<ret>"

def send-selection %{
    execute-keys -draft "_:tmux-send-text<ret>"
    evaluate-commands %{ tmux-send-text %sh{echo ""} }
}

define-command tmux-send-text-newline -params 0..1 -docstring "tmux-send-text [text]: Send text(append new line) to the REPL pane.
  If no text is passed, then the selection is used" %{
    nop %sh{
        if [ $# -eq 0 ]; then 
            selection=$( printf '%s\n' ${kak_selection} )
        else
            selection=$( printf '%s\n' $1 )
        fi
        tmux set-buffer -b kak_selection ${selection}
        kak_orig_window=$(tmux display-message -p '#I')
        kak_orig_pane=$(tmux display-message -p '#P')
        tmux select-window -t:$(tmux show-buffer -b kak_repl_window)
        tmux select-pane -t:.$(tmux show-buffer -b kak_repl_pane)
        tmux paste-buffer -b kak_selection
        tmux select-window -t:${kak_orig_window}
        tmux select-pane -t:.${kak_orig_pane}
    }
}

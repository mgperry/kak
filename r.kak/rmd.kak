# https://rmarkdown.rstudio.com/
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*[.](r|R)md %{
    set-option buffer filetype rmd
}

# Highlighters & Completion
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter shared/rmd regions
add-highlighter shared/rmd/markdown default-region ref markdown
add-highlighter shared/rmd/yaml region (---) (---) ref yaml

add-highlighter shared/rmd/block region ```\{(r|R).*?\} ``` regions
add-highlighter shared/rmd/block/ default-region fill meta
add-highlighter shared/rmd/block/inner region \A```[^\n]*\K (?=```) ref r

add-highlighter shared/rmd/inline region `(?!``) (?<!``)` regions
add-highlighter shared/rmd/inline/ default-region fill meta
add-highlighter shared/rmd/inline/inner region (?<=`) (?=`) ref r

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook -group rmd-highlight global WinSetOption filetype=rmd %{ add-highlighter window/rmd ref rmd }

hook -group rmd-highlight global WinSetOption filetype=(?!rmd).* %{ remove-highlighter window/rmd }


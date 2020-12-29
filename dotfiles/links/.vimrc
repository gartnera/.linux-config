syntax on
filetype plugin indent on

set updatetime=250

set ts=4
set ss=4
set sw=4

set backspace=indent,eol,start
set autoindent
syntax on
set hlsearch
set ignorecase
set smartcase
set linebreak
set incsearch
set number

set bg=dark
set cursorline
colorscheme PaperColor
let g:PaperColor_Theme_Options = {
  \   'theme': {
  \     'default': {
  \       'transparent_background': 1
  \     }
  \   }
  \ }

highlight Normal ctermbg=NONE
highlight nonText ctermbg=NONE

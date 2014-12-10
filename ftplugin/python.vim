" -*- vim -*-
" FILE: python_fn.vim
" LAST MODIFICATION: 2014-11-15 09:11
" (C) Copyright 2001-2005 Mikael Berthe <bmikael@lists.lilotux.net>
" Maintained by Jon Franklin <jvfranklin@gmail.com>
" Modified by Bruce Yang <ayang23@gmail.com>
" Version: 1.14

" This script has been modified by Bruce for key binding compatibility
" to unimpaired vim plugin. Menus are removed for clearly.

" USAGE:
"
" Save this file to $VIMFILES/ftplugin/python.vim. You can have multiple
" python ftplugins by creating $VIMFILES/ftplugin/python and saving your
" ftplugins in that directory. If saving this to the global ftplugin
" directory, this is the recommended method, since vim ships with an
" ftplugin/python.vim file already.
"
" REQUIREMENTS:
" vim (>= 7)
"
" Shortcuts:
"   [k      -- Jump to beginning of block
"   ]k      -- Jump to end of block
"   vik      -- Select (Visual Line Mode) block
"   [c       -- Jump to previous class
"   ]c       -- Jump to next class
"   [f       -- Jump to previous function
"   ]f       -- Jump to next function
"   vic      -- Select current/previous class
"   vif      -- Select current/previous function

" Only do this when not done yet for this buffer
if exists("b:loaded_py_ftplugin")
  finish
endif
let b:loaded_py_ftplugin = 1

map <buffer>   [k   :PBoB<CR>
vmap <buffer>  [k   :<C-U>PBoB<CR>m'gv``
map <buffer>   ]k   :PEoB<CR>
vmap <buffer>  ]k   :<C-U>PEoB<CR>m'gv``

vmap <buffer>   ik   [kV]k

omap <buffer>   ac   :call PythonSelectObject("class")<CR>
omap <buffer>   af   :call PythonSelectObject("function")<CR>

" jump to previous class
map <buffer>   [c   :call PythonDec("class", -1)<CR>
vmap <buffer>  [c   :call PythonDec("class", -1)<CR>

" jump to next class
map <buffer>   ]c   :call PythonDec("class", 1)<CR>
vmap <buffer>  ]c   :call PythonDec("class", 1)<CR>

" jump to previous function
map <buffer>   [f   :call PythonDec("function", -1)<CR>
vmap <buffer>  [f   :call PythonDec("function", -1)<CR>

" jump to next function
map <buffer>   ]f   :call PythonDec("function", 1)<CR>
vmap <buffer>  ]f   :call PythonDec("function", 1)<CR>


:com! PBoB execute "normal ".PythonBoB(line('.'), -1, 1)."G"
:com! PEoB execute "normal ".PythonBoB(line('.'), 1, 1)."G"

" Go to a block boundary (-1: previous, 1: next)
" If force_sel_comments is true, 'g:py_select_trailing_comments' is ignored
function! PythonBoB(line, direction, force_sel_comments)
  let ln = a:line
  let ind = indent(ln)
  let mark = ln
  let indent_valid = strlen(getline(ln))
  let ln = ln + a:direction
  if (a:direction == 1) && (!a:force_sel_comments) &&
      \ exists("g:py_select_trailing_comments") &&
      \ (!g:py_select_trailing_comments)
    let sel_comments = 0
  else
    let sel_comments = 1
  endif

  while((ln >= 1) && (ln <= line('$')))
    if  (sel_comments) || (match(getline(ln), "^\\s*#") == -1)
      if (!indent_valid)
        let indent_valid = strlen(getline(ln))
        let ind = indent(ln)
        let mark = ln
      else
        if (strlen(getline(ln)))
          if (indent(ln) < ind)
            break
          endif
          let mark = ln
        endif
      endif
    endif
    let ln = ln + a:direction
  endwhile

  return mark
endfunction


" Go to previous (-1) or next (1) class/function definition
function! PythonDec(obj, direction)
  if (a:obj == "class")
    let objregexp = "^\\s*class\\s\\+[a-zA-Z0-9_]\\+"
        \ . "\\s*\\((\\([a-zA-Z0-9_,. \\t\\n]\\)*)\\)\\=\\s*:"
  else
    let objregexp = "^\\s*def\\s\\+[a-zA-Z0-9_]\\+\\s*(\\_[^:#]*)\\s*:"
  endif
  let flag = "W"
  if (a:direction == -1)
    let flag = flag."b"
  endif
  let res = search(objregexp, flag)
endfunction


" Select an object ("class"/"function")
function! PythonSelectObject(obj)
  " Go to the object declaration
  normal $
  call PythonDec(a:obj, -1)
  let beg = line('.')

  if !exists("g:py_select_leading_comments") || (g:py_select_leading_comments)
    let decind = indent(beg)
    let cl = beg
    while (cl>1)
      let cl = cl - 1
      if (indent(cl) == decind) && (getline(cl)[decind] == "#")
        let beg = cl
      else
        break
      endif
    endwhile
  endif

  if (a:obj == "class")
    let eod = "\\(^\\s*class\\s\\+[a-zA-Z0-9_]\\+\\s*"
            \ . "\\((\\([a-zA-Z0-9_,. \\t\\n]\\)*)\\)\\=\\s*\\)\\@<=:"
  else
   let eod = "\\(^\\s*def\\s\\+[a-zA-Z0-9_]\\+\\s*(\\_[^:#]*)\\s*\\)\\@<=:"
  endif
  " Look for the end of the declaration (not always the same line!)
  call search(eod, "")

  " Is it a one-line definition?
  if match(getline('.'), "^\\s*\\(#.*\\)\\=$", col('.')) == -1
    let cl = line('.')
    execute ":".beg
    execute "normal V".cl."G"
  else
    " Select the whole block
    execute "normal \<Down>"
    let cl = line('.')
    execute ":".beg
    execute "normal V".PythonBoB(cl, 1, 0)."G"
  endif
endfunction


" vim:set et sts=2 sw=2:


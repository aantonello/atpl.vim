" Vim plugin file
" Description: Simple snippet and template application script.
" Version: 1.3
" Maintainer: Alessandro Antonello <antonello.ale@gmail.com>
" Last Change: 2009 Jun 20
" License: This file has put in the public domain.
"
" For a long time I searched for plugins that I could use to apply file 
" templates and code snippets. Some of then was just to complicated for a 
" simple solution that I was looking for. Others had so much dependencies that 
" I give up before install. For some time I used one that was simple, but
" boring to configure. Well, those was my motive to write this script.
" =============================================================================

" Just source this once. Or don't source at all.
if exists('g:loaded_apptpl')
  finish
endif
let g:loaded_apptpl = 103

" We use line continuation here so, backup 'cpoptions'.
let s:saved_cpo = &cpo
set cpo&vim

" Global variables {{{1
if !exists('g:atpl_UserList')
  let g:atpl_UserList = {}
endif
" g:atpl_TemplatePath: List of paths to find templates.
" g:atpl_SnippetMap: Map to use for apply snippets.

" Local variables {{{1
let s:atpl_ConstMacro   = '<{@\(\w\+\)@}>'
let s:atpl_SubstMacro   = '<{\$\(\w\+\)\$}>'
let s:atpl_EvalMacro    = '<{#\([^}]\+\)#}>'
let s:atpl_IncludeMacro = '<{<\([^>]\+\)>}>'

" Default dictionary {{{2
let s:atpl_DefaultList = 
  \ {
  \ '$FILENAME$': "expand('%:t')",
  \ '$BASENAME$': "expand('%:t:r')",
  \ '$UFILENAME$': "toupper(expand('%:t'))",
  \ '$UBASENAME$': "toupper(expand('%:t:r'))",
  \ '$LFILENAME$': "tolower(expand('%:t'))",
  \ '$LBASENAME$': "tolower(expand('%:t:r'))",
  \ '$DATETIME$': "strftime('%c')",
  \ '$LONGDATE$': "strftime('%Y %B %d')",
  \ '$SHORTDATE$': "strftime('%Y-%m-%d')",
  \ '$LONGTIME$': "strftime('%H:%M:%S')",
  \ '$SHORTTIME$': "strftime('%H:%M')" 
  \ }

" User Commands {{{1
" :Template name.ext | To load a file template {{{2
if !exists(":Template")
  command -nargs=1 -complete=custom,s:TemplateComplete Template :call s:AtplLoadTemplate(<q-args>)
endif

" :Apply name | To apply a snippet {{{2
if !exists(":Apply")
  command -nargs=1 Apply :call s:AtplApplySnippet('<args>')
endif

" Key mappings. Only if g:atpl_SnippetMap exists. {{{2
if exists('g:atpl_SnippetMap')
  exec "inoremap <silent> ". g:atpl_SnippetMap ."  <C-O>:call <SID>ApplySnippet()<CR>"
  exec "nnoremap <silent> ". g:atpl_SnippetMap ."  :call <SID>ApplySnippet()<CR>"
endif

" Exported Functions {{{1

" s:AtplLoadTemplate(name) {{{2
" Loads a template file and parses it.
" The template loaded will be added at the current cursor position in the 
" buffer.
" =============================================================================
func s:AtplLoadTemplate(name)

  " Check if the path for find templates was set.
  if !exists('g:atpl_TemplatePath') || strlen(g:atpl_TemplatePath) == 0
    call s:ShowMsg('error', "The 'g:atpl_TemplatePath' option must be set!")
    return
  endif

  " The s:atpl_LoadedList must exist before s:LoadFile() get called.
  let s:atpl_LoadedList = []

  " Loads the file and put it in a List
  let flist = s:LoadFile(a:name)
  if empty(flist)
"""    call s:ShowMsg('error', "The file '". a:name ."' was not found!")
    return
  endif

  " The s:atpl_LoadedList can be removed after s:LoadFile() ends.
  unlet s:atpl_LoadedList

  " Process the file doing any substitution required.
  call s:ProcessTemplate(flist)

  let line_no = line(".")
  let line_cn = len(flist)

  " In the current line of the buffer we will write the new code.
  call setline(".", flist)
  
  " Sets the cursor position
  call s:SetCursorPos(line_no, (line_no + line_cn))

endfunc

" s:AtplApplySnippet(name) {{{2
" Applies a code snippet at the current cursor position.
" @param name The name of the snippet to be loaded.
" =============================================================================
func s:AtplApplySnippet(name)

  " Check if the path for find templates was set.
  if !exists('g:atpl_TemplatePath') || strlen(g:atpl_TemplatePath) == 0
    call s:ShowMsg('error', "The 'g:atpl_TemplatePath' option must be set!")
    return
  endif

  " Get current line number.
  let line_no = line('.')

  " Find and load the snippet code.
  let scode = s:LoadSnippetCode(a:name)
  if empty(scode)
    call s:ShowMsg('error', "Snippet named '".a:name."' not found!")
    return
  endif

  " Process the snippet code.
  call s:ProcessTemplate( scode )

  " Insert the snippet code in the buffer at current line.
  let last_line = s:ApplySnippetCode(a:name, scode, line_no)

  " Update the cursor position.
  call s:SetCursorPos(line_no, last_line)

endfunc

" s:ApplySnippet() {{{2
" Apply the snippet code that the name is under or before the cursor.
" =============================================================================
func s:ApplySnippet()

  " Search for the snippet name at the current line. Under or before the 
  " cursor position.
  let name_pos = searchpos('\(\w\+\)\>', 'bc', line('.'))
  if empty(name_pos)
    call s:ShowMsg('error', "Could not found a valid snippet name!")
    return
  endif

  " Get the name of the snippet.
  let sname = expand('<cword>')
  if strlen(sname) == 0
    call s:ShowMsg('error', "Could not find any snippet name at line: ". name_pos[1] ."!")
    return
  endif

  " Apply the snippet.
  call s:AtplApplySnippet(sname)

endfunc

" Local Functions {{{1

" s:ShowMsg(type, msg) {{{2
" Shows a message in the command window.
" @param type A string with a type. Can be 'error', 'warning', 'question' or
" 'debug'. It is used to set the correct highlight of the message shown.
" @param msg The text with the message.
" @returns Nothing.
" ============================================================================
func s:ShowMsg(type, msg)
  if a:type ==? 'error' || a:type ==? 'debug'
    echohl ErrorMsg
  elseif a:type ==? 'warning'
    echohl WarningMsg
  elseif a:type ==? 'question'
    echohl Question
  endif
  echo a:msg
  echohl None
endfunc

" s:IsFileLoaded(fname) {{{2
" Checks if a template or snippet file was already loaded.
" @param fname A string with the file name.
" @return 0 if the files isn't loaded yet. Otherwise 1.
" =============================================================================
func s:IsFileLoaded(fname)

  if !exists('s:atpl_LoadedList')
    let s:atpl_LoadedList = [ a:fname ]
    return 0
  endif

  if !empty(s:atpl_LoadedList)
    for item in s:atpl_LoadedList
      if item ==? a:fname
        return 1
      endif
    endfor
  endif

  call add(s:atpl_LoadedList, a:fname)
  return 0

endfunc

" s:LoadFile(fname) {{{2
" Loads the template file and put it in a memory list.
" @param fname Name of the file to load.
" @return A List with the file content or an empty list, if the file is not 
" found.
" =============================================================================
func s:LoadFile(fname)

  let l:fileName = a:fname

  " Use globpath() to search the file in all defined directories.
  let l:searchPath = globpath(g:atpl_TemplatePath, l:fileName)
  if strlen(l:searchPath) == 0
    return []
  endif

  " The result of globpath() is a string separated by new lines. Convert it to
  " a list that will be searched in reverse order.
  let l:pathList = split(l:searchPath, "\n")
  let l:pathSize = len(l:pathList) - 1
  let l:fileData = []

  while l:pathSize >= 0
    let l:fileName = l:pathList[l:pathSize]

    if filereadable(l:fileName) && !s:IsFileLoaded(l:fileName)
      try
        let l:fileData = readfile(l:fileName)
      catch
        return []
      finally
        break
      endtry
    endif
    let l:pathSize -= 1
  endwhile

  if empty(l:fileData)
    return []
  endif

  " Check if there is any 'include' statement into the file data.
  return s:ProcessIncludeMacro(l:fileData)

endfunc

" s:ProcessTemplate(flist) {{{2
" Process the template code replacing replaceable values.
" @param flist The template content in a memory List.
" @returns Nothing. The buffer will be written directly.
" =============================================================================
func s:ProcessTemplate(flist)
  
  let index = 0         " For the modifications
  let start = 0
  let s:atpl_TempList = {}

  try
    for line in a:flist
      " If the line has less than 6 characters long we don't need to process it.
      if strlen(line) > 6
        " Search for a constant macro to be replaced.
        let start = match(line, s:atpl_ConstMacro, 0)
        while start >= 0
          let line = s:ProcessConstMacro(line, start)
          let start = match(line, s:atpl_ConstMacro, start)
        endwhile

        " Search for a substitution macro to be evaluated.
        let start = match(line, s:atpl_SubstMacro, 0)
        while start >= 0
          let line = s:ProcessSubstMacro(line, start)
          let start = match(line, s:atpl_SubstMacro, start)
        endwhile

        " Now we will search for all the evaluation macros.
        let start = match(line, s:atpl_EvalMacro, 0)
        while start >= 0
          let line = s:ProcessEvalMacro(line, start)
          let start = match(line, s:atpl_EvalMacro, start)
        endwhile

        " Restore the line with all substitutions made at the list and go to the 
        " next line.
        let a:flist[index] = line
      endif
      let index = index + 1
    endfor
  catch
    call s:ShowMsg('error', "' ". v:exception ." ' when processing a template, ". v:throwpoint)
  finally
    unlet s:atpl_TempList
  endtry

endfunc

" s:ProcessIncludeMacro(list) {{{2
" Process an include macro.
" An include macro is used to include another file into the processed one.
" @param list A list with all lines of the parent file. All lines will be
" processed to check if there is an include macro. The file included will be
" loaded and included in the line where the macro was found.
" @return A list with the file lines loaded. All included file from included
" files will be loaded. The funcion take care of circular references.
" =============================================================================
func s:ProcessIncludeMacro(list)

  let macro  = ''
  let outlst = []
  let flist  = []

  for line in a:list
    let macro = matchstr(line, s:atpl_IncludeMacro, 0)
    if strlen(macro) > 6
      " Extract the file name inside the line.
      let macro = strpart(macro, 3, (strlen(macro) - 6))
      " Loads the list of lines of the included file
      let flist = s:LoadFile(macro)
      if !empty(flist)
        let outlst += flist
      endif
    else
      call add(outlst, line)
    endif
  endfor

  return outlst

endfunc

" s:ProcessConstMacro(sline, cstart) {{{2
" Process a constant value.
" @param sline  The string containing the macro.
" @param cstart The character index where the macro was found.
" @returns The result is the line after the processement.
" =============================================================================
func s:ProcessConstMacro(sline, cstart)

  " First we get the entire macro inside the text.
  let macro = matchstr(a:sline, s:atpl_ConstMacro, a:cstart)

  " Now we extract the constant name inside the <{...}> delimiters.
  let cname = strpart(macro, 2, (strlen(macro) - 4))
  let value = ''
  let found = 0

  " We search for a match in the users list first.
  if exists('g:atpl_UsersList')
    if has_key(g:atpl_UsersList, cname)
      let value = g:atpl_UsersList[cname]
      let found = 1
    endif
  endif

  " If the value was not found in the users list, we try the default one.
  if !found && has_key(s:atpl_DefaultList, cname)
    let value = s:atpl_DefaultList[cname]
    let found = 1
  endif

  " If the value was not found yet, we check the temporary list.
  if !found
    if has_key(s:atpl_TempList, cname)
      let value = s:atpl_TempList[cname]
    else
      let value = input("Type the value for variable '".strpart(cname, 1, strlen(cname) - 2)."': ")
      let s:atpl_TempList[cname] = value
    endif
  endif

  " Now we substitute all instances of the macro with the result and return it.
  return substitute(a:sline, macro, value, "g")

endfunc

" s:ProcessSubstMacro(sline, cstart) {{{2
" Process a substitution macro.
" @param sline  The string containing the macro.
" @param cstart The character index where the macro was found.
" @returns The name of the macro is searched for a match in the global list. If 
" it is found the substitution is made right in the 'sline' argument. If the 
" name isn't found the user will be prompted to inform the value for the macro. 
" The value given by the user is added to a temporary list to be used again.
" The result is the line with the substitution made.
" =============================================================================
function s:ProcessSubstMacro(sline, cstart)

  " First we get the entire macro inside the text.
  let macro = matchstr(a:sline, s:atpl_SubstMacro, a:cstart)

  " Now we extract the constant name inside the <{...}> delimiters.
  let cname = strpart(macro, 2, (strlen(macro) - 4))
  let value = ''
  let found = 0

  " We search for a match in the users list first.
  if exists('g:atpl_UsersList')
    if has_key(g:atpl_UsersList, cname)
      let value = eval(g:atpl_UsersList[cname])
      let found = 1
    endif
  endif

  " If the value was not found in the users list, we try the default one.
  if !found && has_key(s:atpl_DefaultList, cname)
    let value = eval(s:atpl_DefaultList[cname])
    let found = 1
  endif

  " If the value was not found yet, we check the temporary list.
  if !found
    if has_key(s:atpl_TempList, cname)
      let value = eval(s:atpl_TempList[cname])
    else
      let value = input("Type the value for variable '".strpart(cname, 1, strlen(cname) - 2)."': ")
      let s:atpl_TempList[cname] = value
    endif
  endif

  " Now we substitute all instances of the macro with the result and return it.
  return substitute(a:sline, macro, value, "g")

endfunction

" s:ProcessEvalMacro(text, pos) {{{2
" Process an evaluation macro.
" This kind of macro must have a VIM internal function or command to be 
" executed in the current buffer.
" @param text Text line with the macro to be evaluated.
" @param pos  The current position of the macro to be evaluated.
" @returns The text line with the macro substituted by its evaluation.
" =============================================================================
function s:ProcessEvalMacro(text, pos)

  " First we get the entire macro inside the text line.
  let macro = matchstr(a:text, s:atpl_EvalMacro, a:pos)

  " We extract the evaluation code inside the delimiters.
  let scode = strpart(macro, 3, (strlen(macro) - 6))
  if strlen(scode) == 0
    return a:text
  endif

  " Do the evaluation of the expression.
  let result = eval(scode)

  " Now we substitute all instances of the macro with the result and return it.
  return substitute(a:text, macro, result, "g")

endfunction

" s:LoadSnippetCode(name) {{{2
" Search for a named snippet and load it.
" @param name The snippet name.
" @returns On success the return is a 'List' with the snippet text loaded. On 
" failure the function will return a empty list.
" =============================================================================
func s:LoadSnippetCode(name)

  let ftype = &ft
  let fext  = expand("%:e")

  " First we try to find the snippet code in the 'snippets.tpl' file. This is
  " a global file where the user can put global snippets.
  let l:snippetCode = s:LookUpSnippet('snippets.tpl', a:name)
  if !empty(l:snippetCode)
    return l:snippetCode
  endif

  " Now we try to find a snippet based on the current file's extension.
  let l:snippetCode = s:LookUpSnippet('snippets.'.fext, a:name)
  if !empty(l:snippetCode)
    return l:snippetCode
  endif

  " By the last try we search for a snippet based on the current file type.
  let l:snippetCode = s:LookUpSnippet('snippets.'.ftype, a:name)
  if !empty(l:snippetCode)
    return l:snippetCode
  endif

  return []

endfunc

" s:LookUpSnippet(fname, sname) {{{2
" Search for a snippet name inside a file.
" @param fname Path name of the file where the snippet must be searched.
" @param sname Name of the snippet block code.
" @returns If the snippet code is found a 'List' will be returned. Each line 
" of that list has a line of the snippet. If the snippet isn't found a empty 
" list will be returned.
" =============================================================================
func s:LookUpSnippet(fname, sname)

  " Load the file in a list. Notice that we are using the s:LoadFile()
  " function that should not search in the 's:atpl_TemplatePath' path because
  " we are passing the absolute path. Also we need that all 'include' macros
  " be processed. Notice that the 's:atpl_LoadedList' must be created before
  " the function call.
  let s:atpl_LoadedList = []
  let flist = s:LoadFile(a:fname)
  unlet s:atpl_LoadedList

  if empty(flist)
    return []
  endif

  " Search for the snippet name. The name must be in a single line and 
  " enclosed by '<+...+>' marks.
  let idx_start = match(flist, "<+".a:sname."+>")
  if idx_start < 0
    return []
  endif
  
  " Find the end of the snippet code.
  let idx_stop = match(flist, "<+".a:sname."+>", (idx_start + 1))

  " Return the sub-list containing only the snippet code.
  return flist[idx_start+1:idx_stop-1]

endfunc

" s:ApplySnippetCode(sname, scode, line_no) {{{2
" Apply the snippet template in the current file position.
" @param sname String with the name typed by the user.
" @param scode List with the template lines already processed.
" @param line_no Line number to start the snippet application.
" @return The index of the last line added.
" =============================================================================
func s:ApplySnippetCode(sname, scode, line_no)

  " Get current indentation of the start line.
  let ind = indent(a:line_no)

  " We must remove the name of the snippet code typed by the user at the 
  " buffer. If it was put in this way.
  let str_line = getline(a:line_no)
  let start_no = match(str_line, a:sname)
  let end_no   = matchend(str_line, a:sname)

  if (start_no >= 0) && (end_no >= 0)
    let str_before = strpart(str_line, 0, start_no)
    let str_after  = strpart(str_line, end_no)
    call setline(a:line_no, str_before . a:scode[0] . str_after)
  else
    call setline(a:line_no, a:scode[0])
  endif

  call remove(a:scode, 0)         " Remove the first line added.

  let lno = a:line_no

  if ind <= 0
    call append(a:line_no, a:scode)
    let lno = (a:line_no + len(a:scode))
  else
    " We must apply the same indentation of the first line in the next lines.
    for line in a:scode
      call append(lno, repeat(' ', ind) . line)
      let lno = lno + 1
    endfor
  endif

  " We return the index of the last line added.
  return lno

endfunc

" s:SetCursorPos(lstart, lend) {{{2
" Set cursor position at the first mark found.
" @param lstart The index of the first line added to the buffer.
" @param lend The index of the last line added to the buffer.
" @returns Nothing.
" =============================================================================
func s:SetCursorPos(lstart, lend)

  " We first search for the mark '<|>' and the buffer where the cursor sould 
  " be put in.
  let [lnum, cnum] = searchpos("<|>", "n", a:lend)
  if lnum == 0 && cnum == 0
    return
  endif

  " Get the entire line where the mark is and remove it.
  let sline = getline(lnum)
  let sleft = strpart(sline, 0, (cnum - 1))
  let sright = strpart(sline, (cnum + 2))

  " Replace the line and set the cursor position
  call setline(lnum, sleft . sright)
  call cursor(lnum, strchars(sleft)+1)

  if strlen(sright) > 0
    startinsert
  else
    startinsert!
  endif

endfunc

" s:TemplateComplete(argLead, cmdLine, cursorPos) {{{2
" Search for template files and show a list to the user.
" @param argLead The leading portion of the argument to be completed.
" @param cmdLine The entire command line.
" @param cursorPos The cursor position in the command line.
" @return The function returns a list of matches to be shown.
" ============================================================================
func s:TemplateComplete(argLead, cmdLine, cursorPos)
  let l:fileExt  = expand("%:e")
  let l:fileType = &ft
  let l:fileList = []
  let l:fileLead = ""

  if (a:argLead)
    let l:fileLead = a:argLead
  endif

  let l:fextList = []
  if strlen(l:fileExt) > 0
    let l:fextList = split(globpath(g:atpl_TemplatePath, "*.".l:fileExt), "\n")

    " Adding to the final list only the file name.
    for item in l:fextList
      call add(l:fileList, matchstr(item, "\\w\\+\\.".l:fileExt."$"))
    endfor
  endif

  " We use the file type only in the lack of extension.
  let l:ftypeList = []
  if strlen(l:fileType) > 0 && empty(l:fileExt)
    let l:ftypeList = split(globpath(g:atpl_TemplatePath, "*.".l:fileType), "\n")

    " Adding to the final list only the file name.
    for item in l:ftypeList
      call add(l:fileList, matchstr(item, "\\w\\+\\.".l:fileType."$"))
    endfor
  endif

  "" We can remove any 'snippet' file
  call filter(l:fileList, 'v:val !~? "snippets\\.."')
  return join(l:fileList, "\n")

endfunc
" Restoring 'cpoptions' {{{1
let &cpo = s:saved_cpo
unlet s:saved_cpo
" }}}1
" vim:ff=unix:ts=2:sw=2

" greputils.vim -- Interface with grep and id-utils.
" Author: Hari Krishna (hari_vim at yahoo dot com)
" Last Change: 02-Jul-2004 @ 09:48
" Created:     10-Jun-2004 from idutils.vim
" Requires: Vim-6.3, genutils.vim(1.13), multvals.vim(3.6)
" Depends On: cmdalias.vim(1.0)
" Version: 2.1.3
" Licence: This program is free software; you can redistribute it and/or
"          modify it under the terms of the GNU General Public License.
"          See http://www.gnu.org/copyleft/gpl.txt 
" Download From:
"     http://www.vim.org/script.php?script_id=113
" Description:
"   - There are many plugins that wrap the Vim built-in :grep command and try
"     to simplify the usage. However this plugin aims at providing two
"     specific features:
"         - Escape the arguments such that the arguments can be passed to the
"           external grep/lid literally. This avoids unwanted interpretations
"           by the shell, thus allowing you to concentrate on the regular
"           expression patterns rather than how to escape them.
"         - Allow you to preview the results before letting Vim handle them as
"           part of quickfix. This, besides allowing you to further filter the
"           results, also prevents Vim from adding buffers for files that are
"           uninteresting and thus help reduce the number of buffers. It also
"           supports basic quickfix commands that can be used to open a buffer 
"           without needing to convert it to a quickfix window. You can
"           consider it as a lightweight quickfix window.
"     - As a bonus, the plugin also works around Vim problem with creating a
"       number of unnamed buffers as you close and open quickfix window
"       several times. This helps keep buffer list uncluttered.
"
"   - The command merely wraps the built-in :grep, :grepadd and :cfile
"     commands to create the quickfix list. The rest of the quickfix commands
"     work just like they do on the quickfix results created by using only the
"     built-in functionality. This also means that the plugin assume that you
"     have the options such as 'grepprg', 'shellpipe' are properly set. Read
"     the help on quickfix for the full list of commands and options that you
"     have.
"
"       :h quickfix 
"
"   - Other than the preview functionality which enables filtering, the plugin
"     also provides an easy way to specify a number of filter commands that
"     you can chain on the output of the grep/lid output each prefixed with
"     "+f". The arguments to the filter command are themselves escaped, the
"     same way as the grep command arguments as described above.
"   - Supports GNU "grep" and MS Windows "findstr" for running "find-in-file"
"     kind of searches, and id-utils "lid" for running index searches.  If you
"     need to add support for a new grep command or a grep-like tool, it is
"     just a matter of modifying a few internal variables and possibly adding
"     a new set of commands.
"   - Uses EscapeCommand() function from genutils.vim plugin that supports
"     Cygwin "bash", MS Windows "cmd" and Unix "sh" for shell escaping. Other
"     environments are untested.
"   - Defines the following commands:
"
"       Grep, GrepAdd, IDGrep, IDGrepAdd, Find, FindAdd
"       Grepp, GreppAdd, IDGrepp, IDGreppAdd, Findp, FindpAdd
"
"     The second set of commands are used to open the results in a preview
"     window instead of directly in the quickfix window. And those that have a
"     suffix of "Add" add the new list of results to the existing list,
"     instead of replacing them (just like in :grepadd). This can be very
"     useful in combination with the preview commands.
"
"     You can open the preview window at anytime using GrepPreview command.
"     Once you are in the preview window, you can filter the results using the
"     regular Vim commands, and when you would like to browse the results
"     using Vim quickfix commands, just use Cfile Cgetfile commands, which are
"     equivalent to the built-in cfile and cgetfile commands respectively,
"     exept that they don't take any arguments.
"
"     If cmdalias.vim is installed, it also creates aliases for the Grep,
"     GrepAdd, Cfile and Cgetfile commands to the corresponding built-in
"     commands, i.e., grep, grepadd, cfile and cgetfile respectively.
"
"     The preview window supports the following commands:
"       preview command     quickfix command ~
"       GG [count]          cc [count]
"       [count]GNext        [count]cnext
"       [count]GPrev        [count]cNext, cprevious
"       <CR>                <CR>
"       <2-LeftMouse>       <2-LeftMouse>
"
"     The commands supports [count] argument just like the corresponding
"     quickfix command.
"
"   General Syntax:
"       <grep command> [<grep/lid options> ...] <regex/keyword>
"                      [<filename patterns>] [+f <filter arguments> ...]
"
"     Note that typically you have to pass in at least one filename pattern to
"     grep/findstr where as you don't pass in any for lid.
"
" Examples:
"   The following examples assume that you are using GNU grep for both the
"   'grepprg' and as the g:greputilsFiltercmd.
"
"   - Run GNU grep from the directory of the current file recursively while
"     limiting the search only for Java files.
"       Grep -r --include=*.java \<main\> %:h
"   - Run lid while filtering the lines that are not from Java source.
"       IDGrep main +f \.java
"   - Run lid while filtering the lines that contain src.
"       IDGrep main +f -v src
"
"   - To search for the current word in all the files and filter the results
"     not containing \.java in the grepped output. This will potentially
"     return all the occurences in the java files only. 
"       IDGrep <cword> +f \.java 
"
"   - If any argument contains spaces, then you need to protect them by
"     prefixing them with a backslash.  The following will filter those lines
"     that don't contain "ABC XYZ".
"       IDGrep <cword> +f ABC\ XYZ 
"
" Installation:
"   - Drop the file in your plugin directory or source it from your vimrc.
"   - Make sure genutils.vim and multvals.vim are also installed.
"
"   Settings:
"       g:greputilsLidcmd, g:greputilsFindcmd, g:greputilsFiltercmd,
"       g:greputilsFindMsgFmt, g:greputilsAutoCopen, g:greputilsVimGrepCmd,
"       g:greputilsVimGrepAddCmd, g:greputilsGrepCompMode,
"       g:greputilsLidCompMode, g:greputilsFindCompMode,
"       g:greputilsExpandCurWord
"
"     - Use g:greputilsLidcmd and g:greputilsFiltercmd to set the path/name to
"       the lid and GNU or compatible find executable (defaults to "lid").
"     - Use g:greputilsFiltercmd to set the path/name of the command that you
"       would like to use as the filter when "+f" option is used (defaults to
"       "grep").
"     - Set g:greputilsFindMsgFmt to change the message (%m) part of the find
"       results. You can specify anything that is accepted in the argument for
"       "-printf" find option.
"     - Use g:greputilsAutoCopen to specify if the error list window should
"       automatically be opened or closed based on whether there are any
"       results or not (runs :cwindow command at the end).
"     - Use g:greputilsVimGrepCmd and g:greputilsVimGrepAddCmd to have the
"       plugin run a different command than the built-in :grep command to
"       generate the results. This is mainly useful to use the plugin as a
"       wrapper to finally invoke another plugin after the arguments are
"       escaped and 'shellpipe' is properly set. The callee typically can just
"       run the :grep command on the arguments and do additional setup.
"     - Use g:greputilsGrepCompMode, g:greputilsLidCompMode and
"       g:greputilsFindCompMode to change the completion mode for Grep, IDGrep
"       and Find commands respectively. The default completion mode for Grep
"       and Find are "file" to match that of the built-in commands, where as
"       it is set to "tag" for IDGrep (except the -f argument to specify an ID
"       file, you never need to pass filenam to lid). When completion mode is
"       "file", Vim automatically expands filename meta-characters such as "%"
"       and "#" on the command-line, so you still need to escape then. If this
"       is an issue for you, then you should switch to "tag" or a different
"       completion mode. When completion mode is not "file", the plugin
"       expands the filename meta characters in the file arguments anyway, and
"       this can be considered as an advantage (think about passing patterns
"       to the command literally). However it is still useful to have
"       "<cword>" and "<cWORD>" expand inside the patterns, in which case you
"       can set g:greputilsExpandCurWord setting.  Changing this option at
"       runtime requires you to reload the plugin.
"     - When completion mode is not set to "file", you can set
"       g:greputilsExpandCurWord to have the plugin expand "<cword>" and
"       "<cWORD>" tokens. This essentially gives you all the goodness of file
"       completion while still being able to do tag completions.
" TODO:
"   - On windows, setting multiple ID files for IDPATH doesn't work, provide a
"     workaround.
"   - Can I implement custom completion to support both tag and filenames?
"   - How can I move GrepPreview window to the bottom like the :cwindow?
"   - Is it possible that I am setting 'winfixheight' on a wrong window?
"   - Can I use python to execute a grep in the background and fillup preview
"     buffer when done?

if exists("loaded_greputils")
  finish
endif
if v:version < 603
  echomsg 'greputils: You need at least Vim 6.3'
  finish
endif
if !exists("loaded_multvals")
  runtime plugin/multvals.vim
endif
if !exists("loaded_multvals") || loaded_multvals < 306
  echomsg "greputils: You need a newer version of multvals.vim plugin"
  finish
endif
if !exists("loaded_genutils")
  runtime plugin/genutils.vim
endif
if !exists("loaded_genutils") || loaded_genutils < 113
  echomsg "greputils: You need a newer version of genutils.vim plugin"
  finish
endif
let loaded_greputils=1

" No error if not found.
if !exists("loaded_cmdalias")
  runtime plugin/cmdalias.vim
endif

if !exists("g:greputilsLidcmd")
  let g:greputilsLidcmd = 'lid'
endif

if !exists("g:greputilsFindcmd")
  let g:greputilsFindcmd = 'find'
endif

if !exists("g:greputilsFiltercmd")
  let g:greputilsFiltercmd = 'grep'
endif

if !exists("g:greputilsFindMsgFmt")
  let g:greputilsFindMsgFmt = '\ Size(%s)\ Modified(%Tb\ %Td\ %TH:%TM)\ Mode(%m)\ Links(%n)\n'
endif

if !exists("g:greputilsAutoCopen")
  let g:greputilsAutoCopen = 1
endif

if !exists("g:greputilsVimGrepCmd")
  let g:greputilsVimGrepCmd = 'grep'
endif

if !exists("g:greputilsVimGrepAddCmd")
  let g:greputilsVimGrepAddCmd = 'grepadd'
endif

if !exists("g:greputilsGrepCompMode")
  let g:greputilsGrepCompMode = 'file'
endif

if !exists("g:greputilsLidCompMode")
  let g:greputilsLidCompMode = 'tag'
endif

if !exists("g:greputilsFindCompMode")
  let g:greputilsFindCompMode = 'file'
endif

if !exists("g:greputilsExpandCurWord")
  let g:greputilsExpandCurWord = 0
endif

" Add the "lid -R grep" and "find -printf" format to grep formats.
set gfm+=%f:%l:%m

exec 'command! -nargs=+ -complete='.g:greputilsGrepCompMode
      \ 'Grep call <SID>Grep("grep", 0, 0, <f-args>)'
exec 'command! -nargs=+ -complete='.g:greputilsGrepCompMode
      \ 'GrepAdd call <SID>Grep("grep", 0, 1, <f-args>)'
exec 'command! -nargs=+ -complete='.g:greputilsGrepCompMode
      \ 'Grepp call <SID>Grep("grep", 1, 0, <f-args>)'
exec 'command! -nargs=+ -complete='.g:greputilsGrepCompMode
      \ 'GreppAdd call <SID>Grep("grep", 1, 1, <f-args>)'
exec 'command! -nargs=+ -complete='.g:greputilsLidCompMode
      \ 'IDGrep call <SID>Grep("lid", 0, 0, <f-args>)'
exec 'command! -nargs=+ -complete='.g:greputilsLidCompMode
      \ 'IDGrepAdd call <SID>Grep("lid", 0, 1, <f-args>)'
exec 'command! -nargs=+ -complete='.g:greputilsLidCompMode
      \ 'IDGrepp call <SID>Grep("lid", 1, 0, <f-args>)'
exec 'command! -nargs=+ -complete='.g:greputilsLidCompMode
      \ 'IDGreppAdd call <SID>Grep("lid", 1, 1, <f-args>)'
exec 'command! -nargs=+ -complete='.g:greputilsFindCompMode
      \ 'Find call <SID>Grep("find", 0, 0, <f-args>)'
exec 'command! -nargs=+ -complete='.g:greputilsFindCompMode
      \ 'FindAdd call <SID>Grep("find", 0, 1, <f-args>)'
exec 'command! -nargs=+ -complete='.g:greputilsFindCompMode
      \ 'Findp call <SID>Grep("find", 1, 0, <f-args>)'
exec 'command! -nargs=+ -complete='.g:greputilsFindCompMode
      \ 'FindpAdd call <SID>Grep("find", 1, 1, <f-args>)'

if exists('*CmdAlias')
  call CmdAlias('grep', 'Grep')
  call CmdAlias('grepadd', 'GrepAdd')
  call CmdAlias('find', 'Find')
endif

command! -count=0 GrepPreview :call <SID>OpenGrepPreview(<count>)

if !exists('s:myBufNum')
let s:myBufNum = -1
let s:title = '[Grep Preview]'

let s:savedGrepprg = ''
let s:savedShellpipe = ''

let s:prevCwd = ''
let s:prevCurHit = 1
endif

let s:curQuickFixBufs = ''
aug GrepUtilsAutoQFBufWipeout
  au!
  au BufReadPost quickfix :call s:RegisterQuickfixBuf(bufnr('%'))
aug END

let s:supportedCmds = 'grep,lid,find,'

let s:grepCmdExpr = '' " Just depend on the default settings.
let s:lidCmdExpr = 'g:greputilsLidcmd'
let s:findCmdExpr = 'g:greputilsFindcmd'

" These options are appended at the end of user supplied options.
let s:grepAddOptsExpr = ''
let s:lidAddOptsExpr = '"-R grep"'
let s:findAddOptsExpr = '"-printf %h/%f:1:".g:greputilsFindMsgFmt'

" Options for GNU grep that require an argument.
let s:gnuGrepArgOpts = 'A,B,C,D,d,e,f,m,'
let s:gnuGrepOptPrfx = '-'
let s:gnuGrepNumPatterns = 1
let s:findstrArgOpts = 'D'
let s:findstrOptPrfx = '/'
let s:findstrNumPatterns = 1
let s:lidNumPatterns = -1 " Unlimited (no file args).
let s:findNumPatterns = -1

" Pass an optional filter pattern as a second argument.
function! s:Grep(cmdType, preview, grepAdd, ...)
  if a:0 == 0
    echohl ERROR | echo "Missing arguments." | echohl None
    return
  endif

  let grepOpts = ''
  let fileArgs = ''
  let filterArgs = ''
  let filterArgsStarted = 0
  let patternsCollected = 0
  let arg = ''
  let prevArg = ''
  let i = 1
  let cmdType = s:SubCmdType(a:cmdType)
  while i <= a:0
    try
      let arg = a:{i}
      if !filterArgsStarted && arg ==# '+f'
        let filterArgsStarted = 1
        continue
      endif

      if !filterArgsStarted
        let argIsFilePat = 1
        if s:{cmdType}NumPatterns < 0
          let argIsFilePat = 0
        else
          if fileArgs == ''
            if s:IsOpt(arg, cmdType)
              let argIsFilePat = 0
            elseif s:IsOpt(prevArg, cmdType)
              let opt = strpart(prevArg, 1)
              " If the previous option required an argument.
              if MvContainsElement(s:{cmdType}ArgOpts, ',', opt)
                let argIsFilePat = 0
              endif
            elseif patternsCollected < s:{cmdType}NumPatterns
              let argIsFilePat = 0
              let patternsCollected = patternsCollected + 1
            endif
          endif
        endif
        if argIsFilePat
          let fileArgs = fileArgs . ' ' . arg
        else
          let grepOpts = grepOpts . ' ' . escape(arg, ' ')
        endif
      else
        let filterArgs = filterArgs . ' ' . escape(arg, ' ')
      endif
    finally
      let prevArg = arg
      let i = i + 1
    endtry
  endwhile

  try
    " When completion mode is not file, let us manually do the Vim filename
    "   special character expansions (like %, # etc.)
    if (fileArgs !~ '^\s*$') && (
          \ (a:cmdType == 'grep' && g:greputilsGrepCompMode != 'file') || 
          \ (a:cmdType == 'lid' && g:greputilsLidCompMode != 'file'))
      let fileArgs = UserFileExpand(fileArgs)
      if g:greputilsExpandCurWord
        " Also expand <cword> and <cWORD> in other arguments.
        let grepOpts = substitute(grepOpts, '<cword>\|<cWORD>',
              \ '\=expand(submatch(0))', 'g')
        let filterArgs = substitute(filterArgs, '<cword>\|<cWORD>',
              \ '\=expand(submatch(0))', 'g')
      endif
    endif
    call s:GrepSet(a:cmdType, a:preview, filterArgs)
    if s:{a:cmdType}AddOptsExpr != ''
      let grepOpts = grepOpts.' '.s:EvalExpr(s:{a:cmdType}AddOptsExpr)
    endif
    let grepOpts = EscapeCommand('', grepOpts, fileArgs)
    let grepOpts = Escape(grepOpts, '%#!')
    if !a:preview
      if a:grepAdd == 1
        exec g:greputilsVimGrepAddCmd grepOpts
      else
        exec g:greputilsVimGrepCmd grepOpts
      endif
      if g:greputilsAutoCopen
        cwindow
      endif
    else
      let cmd = &grepprg . ' ' . grepOpts
      call s:OpenGrepPreview(0)
      if a:grepAdd
        $
      else
        call OptClearBuffer()
      endif
      " Just to make it look more authentic.
      let pathsep = exists('+shellslash')?(&shellslash?'/':'\'):'/'
      echo '!'.cmd.' '.&shellredir.' '.
            \ CleanupFileName($TMP).pathsep.'<temp file>'
      silent! exec 'read !'.cmd
      if v:shell_error
        " Mimic the Vim message for the built-in :grep command.
        echomsg 'shell returned '.v:shell_error
        return
      endif
      let s:prevCwd = getcwd()
      let s:prevCurHit = 1
      call SilentSubstitute("\<CR>$", "%s///e")
      "call SilentSubstitute("\%([a-zA-Z]\)\@<!:", "%s//|/e")
      call SilentSubstitute('^\(\f\+\):\(\d\+\):', '%s//\1|\2|/e')
      exec MakeArgumentList('argumentList', ' ')
      call setline(1, 'Results for: '.a:cmdType.' '.argumentList)
      setl ft=qf
      1
    endif
  finally
    call s:GrepReset()
  endtry
endfunction

function! s:IsOpt(arg, cmdType)
  " A short option.
  return a:arg[0] == s:{a:cmdType}OptPrfx && a:arg[1] != s:{a:cmdType}OptPrfx
endfunction

function! s:SubCmdType(cmdType)
  if a:cmdType ==# 'grep'
    if OnMS() && &grepprg =~? '\<findstr\>'
      return 'findstr'
    else
      return 'gnuGrep'
    endif
  else
    return a:cmdType
  endif
endfunction

function! s:GrepCfile(cmd, useBang, ...)
  if a:0 > 0
    exec a:cmd.(a:useBang?'!':'') a:1
  else
    let tempFile = tempname()
    let _errorfile = &errorfile
    let _undolevels = &undolevels
    let _cpo = &cpo
    let curWinNr = winnr()
    try
      set undolevels=2 " Make sure we can at least undo the below change.
      call SilentSubstitute('^\(\f\+\)|\(\d\+\)|', '%s//\1:\2:/e')
      silent! 1delete _
      if line('$') == 1 && getline(1) =~ '^\s*$'
        undo | undo
        echo 'Cfile: No results to read'
        return | " No hits.
      endif
      set cpo-=A
      let restoreCwd = 0
      if getcwd() !=# s:prevCwd
        let restoreCwd = 1
        exec 'lcd' s:prevCwd
      endif
      silent! exec 'write' tempFile
      if restoreCwd
        lcd -
      endif
      undo

      if NumberOfWindows() > 1
        wincmd p
      endif
      exec a:cmd.(a:useBang?'!':'') tempFile
    finally
      let &cpo = _cpo
      let &undolevels = _undolevels
      let &errorfile = _errorfile
      call delete(tempFile)
    endtry
  endif
  if winnr() != curWinNr
    wincmd p
    silent! quit
  endif
  if g:greputilsAutoCopen
    cwindow
  endif
endfunction

function! s:OpenGrepPreview(size)
  let _isf = &isfname
  let _splitbelow = &splitbelow
  let _equalalways = &equalalways
  set splitbelow
  set noequalalways
  try
    if s:myBufNum == -1
      " Temporarily modify isfname to avoid treating the name as a pattern.
      set isfname-=\
      set isfname-=[
      if exists('+shellslash')
        exec "sp \\\\". s:title
      else
        exec "sp \\". s:title
      endif
      exec "normal i\<C-G>u\<Esc>"
      let s:myBufNum = bufnr('%')
    else
      let buffer_win = bufwinnr(s:myBufNum)
      if buffer_win == -1
        exec 'sb '. s:myBufNum
      else
        exec buffer_win . 'wincmd w'
      endif
    endif
  finally
    let &equalalways = _equalalways
    let &isfname = _isf
    let &splitbelow = _splitbelow
  endtry
  call s:SetupBuf()

  " Resize only if this is not the only window vertically.
  if !IsOnlyVerticalWindow()
    exec 'resize' ((a:size > 0) ? a:size : 10)
  endif
endfunction

function! s:SetupBuf()
  call SetupScratchBuffer()
  "setlocal nowrap " It is difficult to see the full line otherwise.
  setlocal bufhidden=hide

  setlocal winfixheight

  command! -buffer -bang -nargs=? Cfile
        \ :call <SID>GrepCfile('cfile', '<bang>' == '!' ? 1 : 0, <q-args>)
  command! -buffer -bang -nargs=? Cgetfile
        \ :call <SID>GrepCfile('cgetfile', '<bang>' == '!' ? 1 : 0, <q-args>)

  if exists('*CmdAlias') && g:loaded_cmdalias >= 101
    call CmdAlias('cfile', 'Cfile', '<buffer>')
    call CmdAlias('cgetfile', 'Cgetfile', '<buffer>')
  endif

  command! -buffer -range=1 GNext :call s:GNextImpl(1, <line1>)
  command! -buffer -range=1 GPrev :call s:GNextImpl(-1, <line1>)
  command! -buffer -count=0 GG :call s:GNextImpl(0, <count>)

  nnoremap <buffer> <silent> <CR> :GG<CR>
  nnoremap <buffer> <silent> <2-LeftMouse> :GG<CR>
  nnoremap <buffer> <silent> <C-N> :GNext<CR>
  nnoremap <buffer> <silent> <C-P> :GPrev<CR>

  hi! def link GrepUtilsPreviewPosition Search
  call s:MarkCcLine()
endfunction

function! s:MarkCcLine()
  silent! syn clear GrepUtilsPreviewPosition
  if s:prevCurHit > 1
    exec 'syn match GrepUtilsPreviewPosition "\%'.s:prevCurHit.'l.*"'
  endif
endfunction

function! s:GNextImpl(forward, cnt)
  if a:forward == 0
    " Calculate absolution error.
    let newHit = (a:cnt > 0) ? (a:cnt+1) : line('.')
  else
    " Calculate relative error.
    let newHit = s:prevCurHit + (a:forward * a:cnt)
  endif
  if newHit < 2
    let newHit = 2
  elseif newHit > line('$')
    let newHit = line('$')
  endif
  exec newHit
  let fileName = ''
  let lineNr = 1
  silent! exec substitute(getline('.'), '^\(\f\+\)|\(\d\+\)|.*',
        \ "let fileName='\\1' | let lineNr='\\2'", '')
  if fileName != ''
    if !filereadable(fileName)
      let fileName = s:prevCwd.((exists('+shellslash') && !&shellslash)?'\':'/')
            \ . fileName
      if !filereadable(fileName)
        echohl ErrorMsg | echo "Can't read file: " . fileName | echohl NONE
        return
      endif
    endif

    let s:prevCurHit = newHit
    call s:MarkCcLine()
    if NumberOfWindows() == 1
      exec 'split +'.lineNr fileName
    else
      let winnr = bufwinnr(fileName)
      if winnr != -1
        exec winnr.'wincmd w'
      else
        if &switchbuf ==# 'split'
          split
        else
          wincmd p
        endif
        exec 'edit' fileName
      endif
      exec lineNr
    endif
  endif
endfunction

" You can pass an optional filter.
function! s:GrepSet(cmdType, preview, filterArgs)
  " So that they can be restored later.
  let s:savedGrepprg = &grepprg
  let s:savedShellpipe = &shellpipe
  let s:savedShellredir = &shellredir

  if s:{a:cmdType}CmdExpr != ''
    let &grepprg = s:EvalExpr(s:{a:cmdType}CmdExpr)
  endif
  let filterCmd = ''
  if a:filterArgs != ''
    call MvIterCreate(a:filterArgs, '+f', 'GrepSet')
    while MvIterHasNext('GrepSet')
      let filterCmd = filterCmd . '| ' .
            \ EscapeCommand(g:greputilsFiltercmd, MvIterNext('GrepSet'), '')
      let filterCmd = Escape(filterCmd, '%#!')
    endwhile
    call MvIterDestroy('GrepSet')
  endif
  " We assume that the existing value of these settings is set such that the
  "   redirection happens for both stdout and stderr.
  if a:preview
    let &shellredir = filterCmd . ' ' . &shellredir
  else
    let &shellpipe = filterCmd . ' ' . &shellpipe
  endif
endfunction

function! s:EvalExpr(expr)
  exec 'let result = '.a:expr
  return result
endfunction

function! s:GrepReset()
  if exists("s:savedGrepprg")
    let &grepprg=s:savedGrepprg
    "unlet s:savedGrepprg
  endif
  if exists("s:savedShellpipe")
    let &shellpipe=s:savedShellpipe
    "unlet s:savedShellpipe
  endif
  if exists("s:savedShellredir")
    let &shellredir=s:savedShellredir
    "unlet s:savedShellredir
  endif
endfunction

function! s:RegisterQuickfixBuf(bufNr)
  " First wipeout any already registered buffers, if they are not visible
  "   anywhere.
  if s:curQuickFixBufs != ''
    " A simple optimization for detecting :colder and :cnewer cases.
    if s:curQuickFixBufs =~ '^\d\+\s*$' && a:bufNr == (s:curQuickFixBufs + 0)
      return
    endif
    let s:undeletedBufs = ''
    call MvIterCreate(s:curQuickFixBufs, ' ', 'RegisterQuickfixBuf')
    while MvIterHasNext('RegisterQuickfixBuf')
      let bufNr = MvIterNext('RegisterQuickfixBuf') + 0
      if bufwinnr(bufNr) == -1
        silent! exec 'bwipeout' bufNr
      else
        let s:undeletedBufs = MvAddElement(s:undeletedBufs, ' ', bufNr)
      endif
    endwhile
    call MvIterDestroy('RegisterQuickfixBuf')
    let s:curQuickFixBufs = s:undeletedBufs
  endif

  let s:curQuickFixBufs = MvAddElement(s:curQuickFixBufs, ' ', a:bufNr)
endfunction

" vim6:fdm=marker sw=2 et

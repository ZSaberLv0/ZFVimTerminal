
if !exists('g:ZFVimTerminal_shell')
    let g:ZFVimTerminal_shell = ''
endif

if !exists('g:ZFVimTerminal_windowConfig')
    let g:ZFVimTerminal_windowConfig = {
                \   'newWinCmd' : 'rightbelow new',
                \   'filetype' : 'ZFTerminal',
                \   'makeDefaultKeymap' : 1,
                \   'maxLine' : '60000',
                \   'autoShow' : 1,
                \ }
endif

if !exists('g:ZFVimTerminalCompatibleMode')
    let g:ZFVimTerminalCompatibleMode = 0
endif

if !exists('g:ZFVimTerminal_autoDetectShellEnd')
    let g:ZFVimTerminal_autoDetectShellEnd = 1
endif

if !exists('g:ZFVimTerminal_autoEnterInsert')
    let g:ZFVimTerminal_autoEnterInsert = 1
endif

if !exists('g:ZFVimTerminal_termEncoding')
    let g:ZFVimTerminal_termEncoding = 'auto'
endif
if !exists('g:ZFVimTerminal_termEncodingCompatible')
    let g:ZFVimTerminal_termEncodingCompatible = 'auto'
endif

function! ZFVimTerminalShellPrefix()
    return '======= ZFTerminal-' . substitute(s:shell, ' .*', '', 'g') . '$'
endfunction
if !exists('g:ZFVimTerminal_shellPrefix')
    let g:ZFVimTerminal_shellPrefix = function('ZFVimTerminalShellPrefix')
endif

function! ZFVimTerminalShellPrefixCompatible()
    return '=== CompatibleMode-' . substitute(s:shell, ' .*', '', 'g') . '$'
endfunction
if !exists('g:ZFVimTerminal_shellPrefixCompatible')
    let g:ZFVimTerminal_shellPrefixCompatible = function('ZFVimTerminalShellPrefixCompatible')
endif


" ============================================================
command! -nargs=* -complete=file ZFTerminal :call s:zfterminal(<q-args>)
command! -nargs=0 ZFTerminalCtrlC :call s:zfterminalCtrlC()
command! -nargs=0 ZFTerminalClose :call s:zfterminalClose()
command! -nargs=0 ZFTerminalHide :call s:zfterminalHide()


" ============================================================
" configs
let s:shell = ''
let s:autoDetectShellEnd = g:ZFVimTerminal_autoDetectShellEnd
let s:autoDetectShellEndFlag = 's:autoDetectShellEnd_FLAG'
let s:autoDetectShellEndCmd = 'echo ' . s:autoDetectShellEndFlag
let s:termEncoding = ''
let s:termEncodingCompatible = ''

function! ZFTerminalDebug()
    return {
                \   'shell' : s:shell,
                \   'autoDetectShellEnd' : s:autoDetectShellEnd,
                \   'termEncoding' : s:termEncoding,
                \   'termEncodingCompatible' : s:termEncodingCompatible,
                \   'state' : s:state,
                \ }
endfunction

function! s:updateConfig()
    if !empty(g:ZFVimTerminal_shell)
        let s:shell = g:ZFVimTerminal_shell
    elseif has('win32')
        if match(system('sh --version'), '[0-9]\+\.[0-9]\+\.[0-9]\+') >= 0
            let s:shell = 'sh'
        else
            let s:shell = 'cmd'
        endif
    else
        if match(system('sh --version'), '[0-9]\+\.[0-9]\+\.[0-9]\+') >= 0
            let s:shell = 'sh --login'
        else
            let s:shell = 'sh'
        endif
    endif

    let s:autoDetectShellEnd = g:ZFVimTerminal_autoDetectShellEnd

    if g:ZFVimTerminal_termEncoding != 'auto'
        let s:termEncoding = g:ZFVimTerminal_termEncoding
    elseif match(s:shell, '\<cmd\>') >= 0
        let s:termEncoding = ZFJobImplGetWindowsEncoding()
    endif

    if g:ZFVimTerminal_termEncodingCompatible != 'auto'
        let s:termEncodingCompatible = g:ZFVimTerminal_termEncodingCompatible
    else
        let s:termEncodingCompatible = s:termEncoding
    endif
endfunction

function! s:getOption(value)
    if type(a:value) == type(function('function'))
        return a:value()
    else
        return a:value
    endif
endfunction

" ============================================================
" state:
"   jobId : -1 if not started, 0 for compatible mode
let s:state = {
            \   'jobId' : -1,
            \   'cmdQueue' : [],
            \   'cmdRunning' : 0,
            \   'cmdLast' : '',
            \ }

function! s:compatibleMode()
    return g:ZFVimTerminalCompatibleMode || !ZFJobAvailable()
endfunction

function! s:zfterminal(...)
    let cmd = get(a:, 1, '')

    call s:termWinInit()

    if s:state['jobId'] == -1
        call s:updateConfig()
        call s:outputShellPrefix()
    endif
    if s:state['jobId'] > 0
        call s:termWinFocus()
        call add(s:state['cmdQueue'], cmd)
        call s:runNextCmd()
        call s:autoEnterInsert()
        return
    endif

    let jobOption = {
                \   'onOutput' : ZFJobFunc(function('s:onOutput')),
                \   'onExit' : ZFJobFunc(function('s:onExit')),
                \ }
    if s:compatibleMode()
        let s:state['jobId'] = 0
        if empty(cmd)
            call s:outputCmd('')
            call s:termWinFocus()
            call s:autoEnterInsert()
            return
        else
            let s:state['cmdRunning'] = 0
            call s:outputCmd(cmd)
        endif
        let jobOption['jobCmd'] = ZFJobFunc(function('s:compatibleModeJobCmd'), [cmd])
        let jobOption['jobEncoding'] = s:termEncodingCompatible
    else
        let jobOption['jobCmd'] = s:shell
        let jobOption['jobEncoding'] = s:termEncoding
        if !empty(cmd)
            call add(s:state['cmdQueue'], cmd)
        endif
    endif

    let jobId = ZFJobStart(jobOption)
    if jobId == -1
        let s:state['jobId'] = -1
        let s:state['cmdQueue'] = []
        let s:state['cmdRunning'] = 0
        call s:output('terminal unable to start job: ' . s:shell)
        return
    endif
    let s:state['jobId'] = jobId
    call s:runNextCmd()
    call s:autoEnterInsert()
endfunction

function! s:zfterminalCtrlC()
    if s:state['jobId'] > 0
        call ZFJobStop(s:state['jobId'])
        call s:termWinFocus()
    endif
endfunction

function! s:zfterminalHide()
    call ZFLogWinHide(s:logId)
endfunction

function! s:zfterminalClose()
    if s:state['jobId'] > 0
        call ZFJobStop(s:state['jobId'])
        let s:state['jobId'] = -1
    endif
    call ZFLogWinClose(s:logId)
    let s:state['cmdQueue'] = []
    let s:state['cmdRunning'] = 0
endfunction

function! s:compatibleModeJobCmd(cmd, jobStatus)
    let result = system(a:cmd)
    return {
                \   'output' : result,
                \   'exitCode' : '' . v:shell_error,
                \ }
endfunction

function! s:output(line)
    call ZFLogWinAdd(s:logId, a:line)
endfunction

function! s:outputShellPrefix()
    if s:compatibleMode()
        let output = s:getOption(g:ZFVimTerminal_shellPrefixCompatible)
    else
        let output = s:getOption(g:ZFVimTerminal_shellPrefix)
    endif
    call ZFLogWinAdd(s:logId, output)
endfunction

function! s:outputCmd(cmd)
    let s:state['cmdLast'] = a:cmd
    if empty(a:cmd)
        let output = a:cmd
    else
        let output = ' ' . a:cmd
    endif

    let content = ZFLogWinContent(s:logId)
    if empty(content)
        call s:outputShellPrefix()
        let content = ZFLogWinContent(s:logId)
    endif
    if empty(content)
        return
    endif
    let content[-1] .= output
    call ZFLogWinRedraw(s:logId)
endfunction

function! s:onOutput(jobStatus, text, type)
    if a:text == s:autoDetectShellEndFlag
        let s:state['cmdRunning'] = 0
        call s:outputShellPrefix()
        call s:runNextCmd()
        redraw
        return
    endif
    let text = substitute(a:text, s:autoDetectShellEndFlag, '', 'g')
    if !(match(s:shell, '\<cmd\>') >= 0 && s:onOutput_cmdIgnore(text))
        call s:output(text)
    endif
    if text != a:text
        call ZFJobSend(s:state['jobId'], s:autoDetectShellEndCmd . "\n")
    endif
endfunction

" tricks to solve cmd.exe's extra output
" `@echo off` still has some annoying output
let s:onOutput_cmdIgnoreFlag = 0
function! s:onOutput_cmdIgnore(text)
    if s:onOutput_cmdIgnoreFlag > 0
        let s:onOutput_cmdIgnoreFlag -= 1
        return 1
    endif
    if stridx(a:text, s:autoDetectShellEndCmd) >= 0
        let content = ZFLogWinContent(s:logId)
        if !empty(content)
            call remove(content, -1)
        endif
        let s:onOutput_cmdIgnoreFlag = 1
        return 1
    endif
    if match(a:text, '^[a-zA-Z]:\\.*>') >= 0 && stridx(a:text, s:state['cmdLast']) >= 0
        return 1
    endif
    return 0
endfunction

function! s:onExit(jobStatus, exitCode)
    let s:state['cmdRunning'] = 0
    call s:outputShellPrefix()
    if a:jobStatus['jobId'] == 0
        call ZFLogWinRedraw(s:logId)
    else
        let s:state['jobId'] = -1
        let s:state['cmdQueue'] = []
        call s:output('terminal exit with code ' . a:exitCode)
    endif
endfunction

function! s:runNextCmd()
    if empty(s:state['cmdQueue'])
        call ZFLogWinRedraw(s:logId)
        return
    endif
    if s:state['cmdRunning']
        return
    endif
    let s:state['cmdRunning'] = 1

    let cmd = remove(s:state['cmdQueue'], 0)
    call s:outputCmd(cmd)

    call ZFJobSend(s:state['jobId'], cmd . "\n")
    if s:autoDetectShellEnd
        call ZFJobSend(s:state['jobId'], s:autoDetectShellEndCmd . "\n")
    endif
endfunction

" ============================================================
" terminal window
let s:logId = 'ZFTerminal'

function! s:termWinOnInit(logId)
    if get(g:ZFVimTerminal_windowConfig, 'makeDefaultKeymap', 1)
        nnoremap <buffer> i :<c-u>ZFTerminal<space>
        nnoremap <buffer> I :<c-u>ZFTerminal<space>
        nnoremap <buffer> o :<c-u>ZFTerminal<space>
        nnoremap <buffer> O :<c-u>ZFTerminal<space>
        nnoremap <buffer> a :<c-u>ZFTerminal<space>
        nnoremap <buffer> A :<c-u>ZFTerminal<space>
        nnoremap <buffer> <cr> :<c-u>ZFTerminal<cr>
        nnoremap <buffer> p :<c-u>ZFTerminal <c-r>"
        nnoremap <buffer> P :<c-u>ZFTerminal <c-r>"
        nnoremap <buffer> q :ZFTerminalClose<cr>
        nnoremap <buffer> x :ZFTerminalHide<cr>
        nnoremap <buffer> <c-c> :ZFTerminalCtrlC<cr>
    endif
endfunction
function! s:termWinStatusline(logId)
    let Fn_statusline = get(g:ZFVimTerminal_windowConfig, 'statusline', {})
    if !empty(Fn_statusline)
        if type(Fn_statusline) == type('')
            return Fn_statusline
        else
            return ZFJobFuncCall(Fn_statusline, [a:logId])
        endif
    endif

    if !empty(s:state['cmdLast'])
        return ZFStatuslineLogValue(':ZFTerminal ' . s:state['cmdLast'])
    else
        return ZFStatuslineLogValue(':ZFTerminal')
    endif
endfunction

function! s:termWinInit()
    let config = extend(copy(g:ZFVimTerminal_windowConfig), {
                \   'makeDefaultKeymap' : 0,
                \   'statusline' : function('s:termWinStatusline'),
                \   'initCallback' : function('s:termWinOnInit'),
                \ })
    call ZFLogWinConfig(s:logId, config)
    call ZFLogWinFocus(s:logId)
endfunction

function! s:termWinFocus()
    call ZFLogWinFocus(s:logId)
endfunction

" ============================================================
let s:autoEnterInsertTimerId = -1
function! s:autoEnterInsertTimerStop()
    if s:autoEnterInsertTimerId != -1
        call timer_stop(s:autoEnterInsertTimerId)
        let s:autoEnterInsertTimerId = -1
    endif
endfunction
function! s:autoEnterInsertCallback(...)
    let s:autoEnterInsertTimerId = -1
    if ZFLogWinIsFocused(s:logId)
        call feedkeys('i', 't')
    endif
    redraw
endfunction
function! s:autoEnterInsert()
    if g:ZFVimTerminal_autoEnterInsert
        if has('timers')
            call s:autoEnterInsertTimerStop()
            let s:autoEnterInsertTimerId = timer_start(1, function('s:autoEnterInsertCallback'))
        else
            call s:autoEnterInsertCallback()
        endif
    endif
endfunction


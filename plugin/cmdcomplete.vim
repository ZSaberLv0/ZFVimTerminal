
function! ZFVimTerminal_cmdComplete(ArgLead, CmdLine, CursorPos)
    return ZFVimTerminal_cmdCompleteDefault(a:ArgLead, a:CmdLine, a:CursorPos)
endfunction

function! ZFVimTerminal_cmdCompleteDefault(ArgLead, CmdLine, CursorPos)
    let ret = ZFVimTerminal_cmdComplete_env(a:ArgLead, a:CmdLine, a:CursorPos)
    if !empty(ret)
        return ret
    endif

    let paramIndex = ZFVimTerminal_cmdComplete_paramIndex(a:ArgLead, a:CmdLine, a:CursorPos)
    if paramIndex == 0
        let ret = ZFVimTerminal_cmdComplete_shellcmd(a:ArgLead, a:CmdLine, a:CursorPos)
        if empty(ret)
            let ret = ZFVimTerminal_cmdComplete_file(a:ArgLead, a:CmdLine, a:CursorPos)
        endif
        return ret
    endif
    return ZFVimTerminal_cmdComplete_file(a:ArgLead, a:CmdLine, a:CursorPos)
endfunction

" ============================================================
function! ZFVimTerminal_cmdComplete_paramIndex(ArgLead, CmdLine, CursorPos)
    let cmd = substitute(a:CmdLine, '\\\\', '', 'g')
    let cmd = substitute(cmd, '\\.', '', 'g')
    let paramList = split(a:CmdLine, ' ')
    if empty(a:ArgLead)
        return len(paramList) - 1
    else
        return len(paramList) - 2
    endif
endfunction
function! ZFVimTerminal_cmdComplete_filter(list, prefix)
    let i = len(a:list) - 1
    while i >= 0
        if match(tolower(a:list[i]), tolower(a:prefix)) != 0
            call remove(a:list, i)
        endif
        let i -= 1
    endwhile
endfunction

" ============================================================
function! ZFVimTerminal_cmdComplete_env(ArgLead, CmdLine, CursorPos)
    " (?<!\\)\$[a-zA-Z0-9_]*$
    let pos = match(a:ArgLead, '\%(\\\)\@<!\$[a-zA-Z0-9_]*$')
    if pos < 0
        return []
    endif
    let pos += 1

    let lines = split(system('export'), "\n")
    let ret = []
    for line in lines
        " ^[a-zA-Z0-9_]+=
        if match(line, '^[a-zA-Z0-9_]\+=') >= 0
            " ^([a-zA-Z0-9_]+)=.*$
            call add(ret, substitute(line, '^\([a-zA-Z0-9_]\+\)=.*$', '\1', ''))
        endif
    endfor
    if pos < len(a:ArgLead)
        call ZFVimTerminal_cmdComplete_filter(ret, strpart(a:ArgLead, pos))
    endif
    let prefix = strpart(a:ArgLead, 0, pos)
    let i = len(ret) - 1
    while i >= 0
        let ret[i] = prefix . ret[i]
        let i -= 1
    endwhile
    return ret
endfunction

function! ZFVimTerminal_cmdComplete_shellcmd(ArgLead, CmdLine, CursorPos)
    return getcompletion(a:ArgLead, 'shellcmd')
endfunction

function! ZFVimTerminal_cmdComplete_file(ArgLead, CmdLine, CursorPos)
    return getcompletion(a:ArgLead, 'file')
endfunction


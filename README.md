terminal inside vim, inspired from [mattn/vim-terminal](https://github.com/mattn/vim-terminal)

![](https://raw.githubusercontent.com/ZSaberLv0/ZFVimTerminal/master/preview.gif)

if you like my work, [check here](https://github.com/ZSaberLv0?utf8=%E2%9C%93&tab=repositories&q=ZFVim) for a list of my vim plugins


# Difference

* Compared to `Vim8's :terminal`

    * low dependency, require `+channel` only, easily works on Windows, both `cmd.exe` or `Cygwin bash`
        * fallback to `system()` if `+channel` not supported
    * all keymaps works inside terminal window
    * easily to copy command output

* Compared to [mattn/vim-terminal](https://github.com/mattn/vim-terminal)

    * support NeoVim
    * use vim's `:command` complete to input shell commands, should be more friendly to use


# How to use

1. use [Vundle](https://github.com/VundleVim/Vundle.vim) or any other plugin manager you like to install

    ```
    Plugin 'ZSaberLv0/ZFVimJob' " required for job impl
    Plugin 'ZSaberLv0/ZFVimTerminal'
    " recommended key map
    nnoremap <leader>zs :ZFTerminal<space>
    ```

1. use `:ZFTerminal [your_cmd]` to run terminal, use `<tab>` to complete file names

    * take care of special chars of vim cmdline, `:h cmdline-special`

1. `<esc>` to quit input, you may visual select and copy the text inside the terminal window
1. use `i/I/a/A/o/O` to start input again
1. use `q` to kill and close terminal,
    we would create new terminal session for next `:ZFTerminal` call
1. use `x` to hide terminal,
    we would use existing terminal session for next `:ZFTerminal` call
1. during editing the shell command, you may also use this keymap
    `cnoremap :: <c-c>q:k$` to edit the command itself quickly


# Configs

* `g:ZFVimTerminal_shell`

    which shell to use, default:

    ```
    let g:ZFVimTerminal_shell = ''
    ```

    when empty, we would try to detect a proper one, possible values:

    * `cmd` : for Windows
    * `sh` : for Windows Cygwin
    * `sh --login` : for others

* `g:ZFVimTerminal_windowConfig`

    terminal window's config, see [Log window](https://github.com/ZSaberLv0/ZFVimJob#log-window) for more info

    those keymaps would be made by default

    ```
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
    ```

    you may add your own keymaps by:

    ```
    autocmd FileType ZFTerminal nnoremap <buffer> q :ZFTerminalClose<cr>
    ```

* `g:ZFVimTerminalCompatibleMode`

    whether run in compatible mode, default: 0

    when run in compatible, we use `system()` instead of `job` to run shell

* `g:ZFVimTerminal_autoDetectShellEnd`

    whether use special tricks to detect shell command end, default:

    ```
    let g:ZFVimTerminal_autoDetectShellEnd = 1
    ```

    when on, we use `echo` to output special string to detect whether user input command has end,
    if any strange things occurred,
    you may disable this feature

* `g:ZFVimTerminal_autoEnterInsert`

    whether auto enter insert mode after running a command, default:

    ```
    let g:ZFVimTerminal_autoEnterInsert = 1
    ```

* `g:ZFVimTerminal_termEncoding` / `g:ZFVimTerminal_termEncodingCompatible`

    the encoding of your terminal, default:

    ```
    let g:ZFVimTerminal_termEncoding = 'auto'
    ```

    when not empty, we would try to convert encoding by `iconv()` to `&encoding`,
    see `:h encoding-values` for possible value, see also `:h termencoding`

    use 'auto' to enable auto detect:

    * for Windows without `sh` executable, try to detect by `chcp`
    * otherwise, `utf-8` would be used

* `g:ZFVimTerminal_shellPrefix` / `g:ZFVimTerminal_shellPrefixCompatible`

    shell prefix, can be string or `function()`

* `g:ZFVimTerminal_CRFix`

    how to resolve `\r`, default is `clearLine`, posible values:

    * `clearLine` : same as default shell, clear current line
    * `newLine` : treat `\r` as `\n`
    * `keep` : do not modify, keep original


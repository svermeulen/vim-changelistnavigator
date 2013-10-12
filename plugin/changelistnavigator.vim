
function! s:GetChanges()
    set nomore
    redir => changesStr
    silent changes
    redir END
    set more
    return changesStr
endfunction

function! s:ParseLine(lineStr)

    let vars = split(a:lineStr, '\v\s+')

    let lineNo = vars[1]
    let colNo = vars[2]
    let bufnum = bufnr('%')

    return [bufnum, lineNo, colNo, 0]
endfunction

function! s:FindCurrentLine(lines)

    let numLines = len(a:lines)

    if a:lines[numLines-1] == '>'
        return s:ParseLine(a:lines[numLines-2])
    endif

    for line in a:lines
        if line =~ '\v^\>'
            let line = strpart(line, 1)
            return s:ParseLine(line)
        endif
    endfor

    return ''
endfunction

function! s:NavigateChangeList(forward)

    let changes = s:GetChanges()
    let lines = split(changes, '\n')
    let numLines = len(lines)

    if numLines == 2 && lines[numLines-1] == '>'
        echo 'Change list is empty'
        return
    endif

    let currentLine = s:FindCurrentLine(lines)
    let lineNo = line('.')

    if lineNo == currentLine[1]
        try
            " Don't care about changes that occur within the same line
            while line('.') == lineNo

                if a:forward
                    normal! g,
                else
                    normal! g;
                endif
            endwhile

        catch /.*/
            echo "At " . (a:forward ? "start" : "end") . " of changelist"
        endtry
    else
        call setpos('.', currentLine)
    endif
endfunction

nnoremap <silent> <plug>NavigateChangeListForward :call <sid>NavigateChangeList(0)<cr>
nnoremap <silent> <plug>NavigateChangeListBackward :call <sid>NavigateChangeList(1)<cr>




function! g:GetChanges()
    set nomore
    redir => changesStr
    silent changes
    redir END
    set more
    return changesStr
endfunction

function! g:ParseLine(lineStr)

    let lineStr = a:lineStr

    if lineStr =~# '\v^\>'
        let lineStr = strpart(lineStr, 1)
    endif

    let vars = split(lineStr, '\v\s+')

    let lineNo = vars[1]
    let colNo = vars[2]
    let bufnum = bufnr('%')

    return [bufnum, lineNo, colNo, 0]
endfunction

function! g:IsValidPos(pos)
    let lineNo = a:pos[1]

    if lineNo <= 0
        return 0
    endif

    if lineNo > line('$')
        return 0
    endif

    let lineStr = getline(lineNo)

    let colNo = a:pos[2]

    if colNo >= len(lineStr)
        return 0
    endif

    if colNo < 0
        return 0
    endif

    return 1
endfunction

function! g:GetChangeData()

    let currentChangePosIndex = -1
    let changes = g:GetChanges()
    let changeData = []

    for line in split(changes, '\n')
        if line !~# '-invalid-' && line !~# '\vchange.*line.*col.*text'

            let wasAdded = 0

            if line ==# '>'
                let isLineCurrent = 1
            else
                let isLineCurrent = (line =~# '\v^\>')
                let changePos = g:ParseLine(line)

                if g:IsValidPos(changePos)
                    let alreadyHaveLine = 0

                    for lineData in changeData
                        if lineData.pos[1] == changePos[1]
                            let alreadyHaveLine = 1
                            break
                        endif
                    endfor

                    if !alreadyHaveLine
                        if isLineCurrent
                            let currentChangePosIndex = len(changeData)
                        endif

                        let data = {'line':line, 'pos':changePos}
                        call add(changeData, data)
                        let wasAdded = 1
                    endif
                endif
            endif

            if !wasAdded
                if isLineCurrent
                    if len(changeData) == 0
                        let currentChangePosIndex = 0
                    else
                        let currentChangePosIndex = len(changeData)-1
                    endif
                endif
            endif
        endif
    endfor

    return [changeData, currentChangePosIndex]
endfunction

function! g:NavigateChangeList(forward)

    let [changeData, currentChangePosIndex] = g:GetChangeData()

    "for data in changeData
        "echom string(data)
    "endfor

    let numLines = len(changeData)

    if numLines == 0 || (numLines == 1 && changeData[0].line ==# '>')
        echom 'Change list is empty'
        return
    endif

    if currentChangePosIndex == -1
        echoerr "Could not find current change number"
        return
    endif

    let currentChangePos = changeData[currentChangePosIndex].pos

    let lineNo = line('.')

    if lineNo == currentChangePos[1]

        if a:forward
            if currentChangePosIndex+1 >= len(changeData)
                echo "Reached end of change list"
                return
            endif

            let goalPos = changeData[currentChangePosIndex+1].pos
        else
            if currentChangePosIndex <= 0
                echo "Reached beginning of change list"
                return
            endif

            let goalPos = changeData[currentChangePosIndex-1].pos
        endif

        let failed = 0
        while line('.') != goalPos[1] || col('.')-1 != goalPos[2]

            try
                if a:forward
                    normal! g,
                else
                    normal! g;
                endif
            catch /.*/
                let failed = 1
                break
            endtry
        endwhile

        if failed
            echoerr "Failure occurred while trying to find goal line"
        endif
    else
        normal! m`
        call setpos('.', currentChangePos)
    endif
endfunction

nnoremap <silent> <plug>NavigateChangeListForward :call g:NavigateChangeList(0)<cr>
nnoremap <silent> <plug>NavigateChangeListBackward :call g:NavigateChangeList(1)<cr>



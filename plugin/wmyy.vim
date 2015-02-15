function! s:Move(Dir)
  if a:Dir != 'h' && a:Dir != 'l'
    return
  endif

  if s:HasNeighbour(a:Dir)
    let l:OldWinNum = winnr()
    let l:OldBufNum = bufnr('%')
    exe 'wincmd ' . a:Dir
    exe 'wincmd s'
    let l:NewWinNum = winnr()
    exe 'hide buf' l:OldBufNum
    exe l:OldWinNum . 'wincmd w'
    exe 'wincmd c'
    exe l:NewWinNum . 'wincmd w'
  else
    if s:HasSiblings()
      exe 'wincmd ' . toupper(a:Dir)
    endif
  endif
endfunction

function! s:HasSiblings(...)
  let l:Dir = a:0 > 0 ? a:1 : ''
  if l:Dir == 'k' || l:Dir == 'j'
    return s:HasAdjacent(l:Dir)
  else
    return s:HasSiblings('k') || s:HasSiblings('j')
  endif
endfunction

function! s:HasNeighbour(Dir)
  return s:HasAdjacent(a:Dir)
endfunction

function! s:HasAdjacent(Dir)
  if a:Dir == 'k' || a:Dir == 'j' || a:Dir == 'h' || a:Dir == 'l'
    let l:CurWinNum = winnr()
    exe 'wincmd ' . a:Dir
    let l:HasAdjacent = winnr() != l:CurWinNum
    exe l:CurWinNum . 'wincmd w'
    return l:HasAdjacent
  else
    return 0
  endif
endfunction

function! s:Swap(Dir)
  let l:FromWinNum = winnr()
  let l:FromBufNum = bufnr('%')

  exe 'wincmd ' . a:Dir

  let l:ToWinNum = winnr()
  let l:ToBufNum = bufnr('%')

  exe l:FromWinNum . 'wincmd w'
  exe 'hide buf' l:ToBufNum
  exe l:ToWinNum . 'wincmd w'
  exe 'hide buf' l:FromBufNum
endfunction

command! WmyyMoveLeft call s:Move('h')
command! WmyyMoveRight call s:Move('l')

command! WmyySwapUp call s:Swap('k')
command! WmyySwapDown call s:Swap('j')
command! WmyySwapLeft call s:Swap('h')
command! WmyySwapRight call s:Swap('l')


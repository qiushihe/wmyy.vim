function! s:Move(Dir)
  if a:Dir != 'h' && a:Dir != 'l' && a:Dir != 'k' && a:Dir != 'j'
    return
  endif

  if a:Dir == 'h' || a:Dir == 'l'
    if s:HasNeighbour(a:Dir)
      " Vim's "window number" is not a unique identifier for an instance of window. Instead the
      " window number is simply an index, and the number of a given window can change at run time
      " if there are windows being created before it (i.e. above or to the left).

      " Grab the number of the old window and buffer
      let l:OldWinNum = winnr()
      let l:OldBufNum = bufnr('%')

      " Figure out sibling window number
      let l:SiblingWinNum = 0
      let l:SiblingWinDir = ''
      if s:HasSiblings('k')
        exe 'wincmd k'
        let l:SiblingWinNum = winnr()
        let l:SiblingWinDir = 'k'
        exe l:OldWinNum . 'wincmd w'
      else
        if s:HasSiblings('j')
          exe 'wincmd j'
          let l:SiblingWinNum = winnr()
          let l:SiblingWinDir = 'j'
          exe l:OldWinNum . 'wincmd w'
        endif
      endif

      " Focus and close old window
      exe l:OldWinNum . 'wincmd w'
      exe 'wincmd c'

      " Enlarge sibling of old window if necessary
      if l:SiblingWinNum > 0
        " If the sibling is below the window we just closed, the sibling's window number would be
        " decremented by 1. So we need to adjust l:SiblingWinNum accordingly.
        if l:SiblingWinDir == 'j'
          let l:SiblingWinNum = l:SiblingWinNum - 1
        endif
        exe l:SiblingWinNum . 'wincmd w'
        exe 'resize 9999'
      endif

      " Switch to neighbour stack and create a new window
      exe 'wincmd ' . a:Dir
      exe 'wincmd s'

      " Load buffer into new window
      exe 'hide buf' l:OldBufNum

      " Move the new window to the top of the stack
      while s:HasSiblings('k')
        call s:Swap('k')
      endwhile

      " Finally enlarge the new window
      exe 'resize 9999'
    else
      if s:HasSiblings()
        let l:CurWinNum = winnr()
        " Rotate current window to create a new stack
        exe 'wincmd ' . toupper(a:Dir)

        " Go back the opposite direction and enalrge a remaining window
        if a:Dir == 'h'
          exe 'wincmd l'
        else
          exe 'wincmd h'
        endif
        exe 'resize 9999'

        " Refocus the new stack
        exe l:CurWinNum . 'wincmd w'
      endif
    endif
  endif

  if a:Dir == 'k' || a:Dir == 'j'
    call s:Swap(a:Dir)
    exe 'resize 9999'
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

  " Load new buffer into old window
  exe l:FromWinNum . 'wincmd w'
  exe 'hide buf' l:ToBufNum

  " Load old buffer into new window
  exe l:ToWinNum . 'wincmd w'
  exe 'hide buf' l:FromBufNum
endfunction

function! s:NewWindow()
  exe 'wincmd s'
  exe 'resize 9999'
endfunction

function! s:CloseWindow()
  exe 'wincmd c'
  exe 'resize 9999'
endfunction

function! s:Focus(Dir)
  if a:Dir == 'k' || a:Dir == 'j' || a:Dir == 'h' || a:Dir == 'l'
    " When shifting focus left or right, we want to focus the tallest window in the destination
    " stack instead of always focusing the first window in the destination stack
    if a:Dir == 'h' || a:Dir == 'l'
      " Shift focus to the stack in the direction specified
      exe 'wincmd ' . a:Dir

      " Shift focus to the window on top of the stack without enlarging it
      while s:HasSiblings('k')
        exe 'wincmd k'
      endwhile

      " Loop through all the window in the stack to find the tallest one
      let l:TallestWinNum = winnr()
      let l:TallestWinHeight = winheight(winnr())
      while s:HasSiblings('j')
        exe 'wincmd j'
        let l:CurrentWinHeight = winheight(winnr())
        if l:CurrentWinHeight > l:TallestWinHeight
          let l:TallestWinHeight = l:CurrentWinHeight
          let l:TallestWinNum = winnr()
        endif
      endwhile

      " Focus the tallest window
      exe l:TallestWinNum . 'wincmd w'
      exe 'resize 9999'
    else
      exe 'wincmd ' . a:Dir
      exe 'resize 9999'
    endif
  else
    return
  endif
endfunction

command! WmyyMoveUp call s:Move('k')
command! WmyyMoveDown call s:Move('j')
command! WmyyMoveLeft call s:Move('h')
command! WmyyMoveRight call s:Move('l')

command! WmyySwapUp call s:Swap('k')
command! WmyySwapDown call s:Swap('j')
command! WmyySwapLeft call s:Swap('h')
command! WmyySwapRight call s:Swap('l')

command! WmyyFocusUp call s:Focus('k')
command! WmyyFocusDown call s:Focus('j')
command! WmyyFocusLeft call s:Focus('h')
command! WmyyFocusRight call s:Focus('l')

command! WmyyNewWindow call s:NewWindow()
command! WmyyCloseWindow call s:CloseWindow()

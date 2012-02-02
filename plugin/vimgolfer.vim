if !executable('vimgolf') || get(g:, 'vimgolfer_loaded', 0)
  finish
endif
let g:vimgolfer_loaded = 1

if len([globpath(&rtp, 'autoload/http.vim'),globpath(&rtp, 'autoload/xml.vim')])!=2
  echohl WarningMsg
  echomsg "Warning: Vimgolfer require http://github.com/mattn/webapi-vim"
  echohl None
  finish
endif

if len([globpath(&rtp, 'autoload/open-browser.vim')])!=1
  echohl WarningMsg
  echomsg "Warning: Vimgolfer require https://github.com/tyru/open-browser.vim"
  echohl None
  finish
endif

function! s:to_source_lines(code)
  let lines = split(a:code, '\n')
  return map(range(len(lines)), 'printf("%05d: %s", v:val, lines[v:val])')
endfunction

function! s:show_challenge(line)
  let title = matchstr(a:line, '^\[\w\+\] \zs.*')
  let id = matchstr(a:line, '^\[\zs\w\+\ze\]')
  if len(id) == 0 | return | endif
  silent edit __VIMGOLFER__ | silent only!
  setlocal buftype=nofile bufhidden=hide noswapfile modifiable nocursorline
  silent %d _ | redraw!
  let res = http#get('http://www.vimgolf.com/challenges/'.id)
  let json = json#decode(res.content)
  call setline('$',
  \  [title, '', 'Start file:', '']
  \  +map(s:to_source_lines(json.in.data), '"  ".v:val')
  \  +['', 'End file:', '']
  \  +map(s:to_source_lines(json.out.data), '"  ".v:val')
  \  +['', '"q" to back list, "x" to challenge this']
  \)
  setlocal modified nomodifiable
  nmapclear <buffer>
  exe "nnoremap <silent> <buffer> x :!vimgolf put ".id."<cr>"
  nnoremap <silent> <buffer> q :call <SID>show_recent_challenges()<cr>
  match none
  match Title /^\(Start file\|End file\):$/
endfunction

function! s:show_recent_challenges()
  silent edit __VIMGOLFER__ | silent only!
  setlocal buftype=nofile bufhidden=hide noswapfile modifiable cursorline
  silent %d _ | redraw!
  let dom = xml#parseURL('http://feeds.vimgolf.com/latest-challenges')
  call setline('$', map(dom.childNode('channel').childNodes('item'),
  \ '"[".matchstr(v:val.childNode("guid").value(), ''[^/]\+$'')."] "'
  \ .'.v:val.childNode("title").value()')
  \ +['', '"q" to quit, <cr> to show the challenge'])
  setlocal modified nomodifiable
  nmapclear <buffer>
  nnoremap <silent> <buffer> <cr> :call <SID>show_challenge(getline('.'))<cr>
  nnoremap <silent> <buffer> q :bw!<cr>
  match none
endfunction

command! -nargs=0 VimGolfer call s:show_recent_challenges()

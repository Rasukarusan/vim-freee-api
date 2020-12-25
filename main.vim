function! s:winid2tabnr(win_id) abort
  return win_id2tabwin(a:win_id)[1]
endfunction

function! s:create_main_window(config, date)
  let buffer = nvim_create_buf(v:false, v:true)
  let field = 
    \ [a:date]
    \ + repeat(['-'], 4)
    \ + [repeat('#', 16)]
  call nvim_buf_set_lines(buffer, 0, -1, v:true, field)
  return nvim_open_win(buffer, v:true, a:config)
endfunction

function! s:create_border_window(config)
  let width = a:config.width
  let height = a:config.height
  let top = "╭" . repeat("─", width - 2) . "╮"
  let mid = "│" . repeat(" ", width - 2) . "│"
  let bot = "╰" . repeat("─", width - 2) . "╯"
  let lines = [top] + repeat([mid], height - 2) + [bot]
  let buffer = nvim_create_buf(v:false, v:true)
  call nvim_buf_set_lines(buffer, 0, -1, v:true, lines)

  return nvim_open_win(buffer, v:true, a:config)
endfunction

function! CreateDays(timer)
  let width = 20
  let height = 3
  let col = 30
  let row = 10

  let days = ['日','月','火','水','木','金','土']
  for day in days
    let main_config = {'relative': 'editor', 'row': 1, 'col': 1, 'width': width - 4, 'height': height - 2, 'style': 'minimal'}
    let buffer = nvim_create_buf(v:false, v:true)
    let field = [day]
    call nvim_buf_set_lines(buffer, 0, -1, v:true, field)
    let main_window = nvim_open_win(buffer, v:true, main_config)

    let border_config = {'relative': 'editor', 'row': 1, 'col': 1, 'width': width, 'height': height, 'style': 'minimal'}
    let border_window = s:create_border_window(border_config)

    let col += width - 1
    call add(g:win_ids, main_window)
    call add(g:win_ids, border_window)
    let g:dict[main_window] = {'y': row + 1, 'x': col + 2}
    let g:dict[border_window] = {'y': row, 'x': col}
  endfor
endfunction

function! CreateCenteredFloatingWindow(timer)
    set winhl=Normal:Floating
    let width = 20
    let height = 10
    let col = 30
    let row = 12
    let dates = [29,30,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,1,2]
    " let dates = [29,30,1,2,3,4,5,6,7,8,9,10,11,12]
    for date in dates
      if date % 7 == 6
        let col = 30
        let row += height - 1
      endif
      let main_config = {'relative': 'editor', 'row': 1, 'col': 1, 'width': width - 4, 'height': height - 2, 'style': 'minimal'}
      let main_window = s:create_main_window(main_config, printf('%d', date ))

      let border_config = {'relative': 'editor', 'row': 1, 'col': 1, 'width': width, 'height': height, 'style': 'minimal'}
      let border_window = s:create_border_window(border_config)

      let col += width - 1
      call add(g:win_ids, main_window)
      call add(g:win_ids, border_window)
      let g:dict[main_window] = {'y': row + 1, 'x': col + 2}
      let g:dict[border_window] = {'y': row, 'x': col}
    endfor
endfunction

function! CreateWindows(num, timer)
    set winhl=Normal:Floating
    echo a:num
    let width = 20
    let height = 10
    let col = 30
    let row = a:num
    let dates = [29,30,1,2,3,4,5]
    for date in dates
      let main_config = {'relative': 'editor', 'row': 1, 'col': 1, 'width': width - 4, 'height': height - 2, 'style': 'minimal'}
      let main_window = s:create_main_window(main_config, printf('%d', date ))

      let border_config = {'relative': 'editor', 'row': 1, 'col': 1, 'width': width, 'height': height, 'style': 'minimal'}
      let border_window = s:create_border_window(border_config)

      let col += width - 1
      call add(g:win_ids, main_window)
      call add(g:win_ids, border_window)
      let g:dict[main_window] = {'y': row + 1, 'x': col + 2}
      let g:dict[border_window] = {'y': row, 'x': col}
    endfor
endfunction

function! MoveWindows(timer)
  for win_id in g:win_ids
    let rect = g:dict[win_id]
    let newConfig = {'relative': 'editor', 'row': rect.y, 'col': rect.x}
    call nvim_win_set_config(win_id, newConfig)
    redraw
    sleep 20ms
  endfor
endfunction

function! Main()
  call timer_start(0, 'CreateDays', {'repeat': 1})
  " call timer_start(0, 'CreateCenteredFloatingWindow', {'repeat': 1})
  call timer_start(10, function('CreateWindows', [12]), {'repeat': 1})
  call timer_start(20, function('CreateWindows', [21]), {'repeat': 1})
  call timer_start(30, function('CreateWindows', [30]), {'repeat': 1})
  call timer_start(20, function('CreateWindows', [39]), {'repeat': 1})
  call timer_start(20, function('CreateWindows', [48]), {'repeat': 1})
  call timer_start(100, 'MoveWindows', {'repeat': 1})
endfunction

let g:dict = {}
let g:win_ids = []
let g:main_win_ids = []
let g:border_win_ids = []

function! GetWork()
  let cmd = 'curl -s -X GET "https://api.freee.co.jp/hr/api/v1/employees/966774/work_record_summaries/2021/1?company_id=2689772&work_records=true" -H "accept: application/json" -H "Authorization: Bearer 9c2d04b5ccbb50524bc0e1265f92eefcffaa12f1e7c99fa54d333064188d1a65"'
  let result = json_decode(system(cmd))
  echo result.work_records[0].clock_in_at
endfunction

nnoremap <silent> T :call Main()<CR>
nnoremap <silent> R :call GetWork()<CR>
" nnoremap <silent> T :call <SID>main()<CR>

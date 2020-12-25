function! s:winid2tabnr(win_id) abort
  return win_id2tabwin(a:win_id)[1]
endfunction

function! s:create_main_window(config, field) abort
  let config = {'relative': 'editor', 'row': a:config.row + 1, 'col': a:config.col + 2, 'width': a:config.width - 4, 'height': a:config.height - 2, 'style': 'minimal'}
  let buffer = nvim_create_buf(v:false, v:true)
  call nvim_buf_set_lines(buffer, 0, -1, v:true, a:field)
  return nvim_open_win(buffer, v:true, config)
endfunction

function! s:create_border_window(config) abort
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

function! s:new_border_window(config, field, timer) abort
  call s:create_border_window(a:config)
  call s:create_main_window(a:config, a:field)
endfunction

function! s:create_config(rect)
  let rect = a:rect
  return {'relative': 'editor', 'row': rect.row, 'col': rect.col, 'width': rect.width, 'height': rect.height, 'style': 'minimal'}
endfunction

function! CreateDays(timer) abort
  let rect = { 'width': 20, 'height': 3, 'col': 30, 'row': 10 }
  for day in ['日','月','火','水','木','金','土']
    call timer_start(0, function('s:new_border_window', [s:create_config(rect), [day]]), { 'repeat':1 })
    let rect.col += rect.width - 1
  endfor
endfunction

function! CreateCalender(timer)
  let rect = { 'width': 20, 'height': 10, 'col': 30, 'row': 12 }
  " let dates = [29,30,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,1,2]
  let dates = [29,30,1,2,3,4,5,6] + [7,8,9,10,11,12]

  for date in dates
    if date % 7 == 6
      let rect.col = 30
      let rect.row += rect.height - 1
    endif
    let field = [printf('%d', date )] + repeat(['-'], 4) + [repeat('#', 16)]
    call timer_start(0, function('s:new_border_window', [s:create_config(rect), field]), { 'repeat':1 })
    let rect.col += rect.width - 1
  endfor
endfunction

function! Main()
  call timer_start(0, 'CreateDays', {'repeat': 1})
  call timer_start(0, 'CreateCalender', {'repeat': 1})
endfunction

function! GetWork()
  let cmd = 'curl -s -X GET "https://api.freee.co.jp/hr/api/v1/employees/966774/work_record_summaries/2021/1?company_id=2689772&work_records=true" -H "accept: application/json" -H "Authorization: Bearer 9c2d04b5ccbb50524bc0e1265f92eefcffaa12f1e7c99fa54d333064188d1a65"'
  let result = json_decode(system(cmd))
  echo result.work_records[0].clock_in_at
endfunction

set winhl=Normal:Floating
nnoremap <silent> T :call Main()<CR>
nnoremap <silent> R :call GetWork()<CR>

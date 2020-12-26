source ./env
let g:win_ids = []

function! s:winid2tabnr(win_id) abort
  return win_id2tabwin(a:win_id)[1]
endfunction

function! s:create_contents_window(config, field) abort
  let config = {'relative': 'editor', 'row': a:config.row + 1, 'col': a:config.col + 2, 'width': a:config.width - 4, 'height': a:config.height - 2, 'style': 'minimal'}
  let buffer = nvim_create_buf(v:false, v:true)
  call nvim_buf_set_lines(buffer, 0, -1, v:true, a:field)
  return nvim_open_win(buffer, v:true, config)
endfunction

function! s:create_border_window(config) abort
  set winhl=Normal:Floating
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

function! s:new_border_window(config, field, today, timer) abort
  let border_window_id = s:create_border_window(a:config)
  let contents_window_id = s:create_contents_window(a:config, a:field)
  let date = a:field[0]
  if a:today == date && date > 0
    call add(g:win_ids, contents_window_id)
  endif
  redraw
endfunction

function! s:create_config(rect) abort
  let rect = a:rect
  return {'relative': 'editor', 'row': rect.row, 'col': rect.col, 'width': rect.width, 'height': rect.height, 'style': 'minimal'}
endfunction

function! CreateDays(timer) abort
  let rect = { 'width': 20, 'height': 3, 'col': 50, 'row': 10 }
  for day in ['日','月','火','水','木','金','土']
    call timer_start(0, function('s:new_border_window', [s:create_config(rect), [day], 0]), { 'repeat':1 })
    let rect.col += rect.width - 1
  endfor
endfunction

function! CreateCalender(timer) abort
  let col = 50
  let rect = { 'width': 20, 'height': 10, 'col': col, 'row': 12 }
  " let dates = [29,30,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,1,2]
  let dates = [29,30,1,2,3,4,5] + [6,7,8,26,10,11]
  let works = GetWork()
  let time_clock = GetTimeClock()

  for date in dates
    if date % 7 == 6
      let rect.col = col
      let rect.row += rect.height - 1
    endif
    let label = ''
    if time_clock.date == date
      let label = time_clock.label
    endif
    let field = 
      \ [printf('%d', date )] 
      \ + ['']
      \ + [works[date]]
      \ + ['']
      \ + [label]
      \ + ['']
    call timer_start(1, function('s:new_border_window', [s:create_config(rect), field, time_clock.date]), { 'repeat':1 })
    let rect.col += rect.width - 1
  endfor
endfunction

function! Main()
  call timer_start(10, 'CreateDays', {'repeat': 1})
  call timer_start(15, 'CreateCalender', {'repeat': 1})
endfunction

function! GetWork() abort
  let cmd = 'curl -s -X GET "https://api.freee.co.jp/hr/api/v1/employees/'.g:EMP_ID.'/work_record_summaries/2021/1?company_id='.g:COMPANY_ID.'&work_records=true" -H "accept: application/json" -H "Authorization: Bearer '.g:TOKEN.'"'
  let json = json_decode(system(cmd))
  let result = {}
  for record in json.work_records
    let date = system("gdate '+%-d' -d" . record.date . '| tr -d "\n"')
    let time = ''
    if record.clock_in_at != 'null'
      let clock_in = system("gdate '+%H:%M' -d" . record.clock_in_at)
      let clock_out = system("gdate '+%H:%M' -d" . record.clock_out_at)
      let time = substitute(clock_in.' ~ '.clock_out, '\n', '', 'g')
    endif
    let result[date] = time
  endfor
  return result
endfunction

function! GetTimeClock() abort
  let cmd = 'curl -s -X GET "https://api.freee.co.jp/hr/api/v1/employees/'.g:EMP_ID.'/time_clocks/available_types?company_id='.g:COMPANY_ID.'" -H "accept: application/json" -H "Authorization: Bearer '.g:TOKEN.'"'
  let json = json_decode(system(cmd))
  let available_types = json.available_types
  let label = ''
  let type = ''
  let date = system("gdate '+%-d' -d" . json.base_date . '| tr -d "\n"')
  if match(available_types, 'clock_in') != -1 " 未出勤の場合
    let label = '出勤する'
    let type = 'clock_in'
  elseif match(available_types, 'clock_out') != -1 " 出勤済みの場合
    let label = '退勤する'
    let type = 'clock_out'
  else
  endif
  return {'date': date, 'label': label, 'type': type}
endfunction

function! PostWork() abort
  let line = getline('.')
  let action = line == '出勤する' ?
        \ {'type': 'clock_in', 'msg': '出勤しました'} :
        \ {'type': 'clock_out', 'msg': '退勤しました'}
  let cmd = 'curl -s -X POST "https://api.freee.co.jp/hr/api/v1/employees/'.g:EMP_ID.'/time_clocks" -H "accept: application/json" -H "Authorization: Bearer '.g:TOKEN.'" -H "Content-Type: application/json" -d "{ \"company_id\": '.g:COMPANY_ID.', \"type\": \"'.action.type.'\"}"'
  let json = json_decode(system(cmd))
  echo json
  let date = system("gdate '+%-d' -d" . json.employee_time_clock.date . '| tr -d "\n"')
  let time = system("gdate '+%H:%M' -d" . json.employee_time_clock.datetime . '| tr -d "\n"')
  let field = 
    \ [date] 
    \ + ['']
    \ + ['     '. time]
    \ + ['']
    \ + [action.msg]
  call nvim_buf_set_lines(0, 0, -1, v:true, field)
endfunction

function Random(max) abort
  return str2nr(matchstr(reltimestr(reltime()), '\v\.@<=\d+')[1:]) % a:max
endfunction

set winhl=Normal:Floating
nnoremap <silent> T :call Main()<CR>
vnoremap <silent> <CR> :call PostWork()<CR>

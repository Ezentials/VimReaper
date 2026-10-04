-- VimReaper: learn Neovim by playing inside real Neovim.
-- Every level is an ordinary buffer; the game only watches the cursor and the text.
local levels = require('vimreaper.levels')

local M = {}

local api = vim.api
local ns = api.nvim_create_namespace('vimreaper')
local root = debug.getinfo(1, 'S').source:sub(2):match('(.*)/lua/vimreaper/init%.lua$')
M.progress_path = root .. '/progress.json'

local S = {
  info_buf = nil,
  info_win = nil,
  game_win = nil,
  buf = nil, -- the buffer currently shown in the game window (menu or level)
  menu_rows = {}, -- menu line number -> level index
  idx = nil, -- current level, nil while the menu is shown
  keys = 0,
  reaped = 0,
  done = false,
  counting = false,
  started = nil,
  result = nil,
  progress = {}, -- level id -> best stars
}

local banner = {
  [[ __   ___         ___                        ]],
  [[ \ \ / (_)_ __   | _ \___ __ _ _ __  ___ _ _ ]],
  [[  \ V /| | '  \  |   / -_) _` | '_ \/ -_) '_|]],
  [[   \_/ |_|_|_|_| |_|_\___\__,_| .__/\___|_|  ]],
  [[                              |_|            ]],
}

function M.count_keys(cmds)
  local n = 0
  for _, c in ipairs(cmds) do
    local plain = c:gsub('<[^>]+>', '_')
    n = n + #plain
  end
  return n
end

for _, lv in ipairs(levels) do lv.par = M.count_keys(lv.solution) end

local function stars_for(keys, par)
  if keys <= par then return 3 end
  if keys <= par + math.max(2, math.ceil(par / 2)) then return 2 end
  return 1
end

local function star_text(n)
  return ('★'):rep(n) .. ('☆'):rep(3 - n)
end

local function load_progress()
  local f = io.open(M.progress_path, 'r')
  if not f then return {} end
  local ok, data = pcall(vim.json.decode, f:read('*a'))
  f:close()
  return ok and type(data) == 'table' and data or {}
end

local function save_progress()
  local f = io.open(M.progress_path, 'w')
  if not f then return end
  f:write(vim.json.encode(S.progress))
  f:close()
end

-- rows: list of lines, each a list of {text, hl_group?} chunks.
local function set_info(rows)
  local lines, marks = {}, {}
  for i, row in ipairs(rows) do
    local text = ''
    for _, chunk in ipairs(row) do
      if chunk[2] then table.insert(marks, { i - 1, #text, #text + #chunk[1], chunk[2] }) end
      text = text .. chunk[1]
    end
    lines[i] = text
  end
  local b = S.info_buf
  vim.bo[b].modifiable = true
  api.nvim_buf_set_lines(b, 0, -1, false, lines)
  vim.bo[b].modifiable = false
  api.nvim_buf_clear_namespace(b, ns, 0, -1)
  for _, m in ipairs(marks) do
    api.nvim_buf_set_extmark(b, ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
  end
  -- The info pane wraps, so size it by screen rows rather than lines.
  local width = math.max(api.nvim_win_get_width(S.info_win), 1)
  local height = 0
  for _, l in ipairs(lines) do
    height = height + math.max(1, math.ceil(vim.fn.strdisplaywidth(l) / width))
  end
  api.nvim_win_set_height(S.info_win, height)
end

-- Replaces the game window's buffer with a fresh one, so undo history, marks
-- and highlights never leak between levels.
local function show_buf(lines, modifiable)
  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].undolevels = -1
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].undolevels = 1000
  vim.bo[buf].modifiable = modifiable
  api.nvim_win_set_buf(S.game_win, buf)
  S.buf = buf
  return buf
end

local function render_level()
  local lv = levels[S.idx]
  local rows = {
    {
      { ' ☠ VimReaper ', 'VimReaperTitle' },
      { ('  Bane %d/%d · %s · '):format(S.idx, #levels, lv.chapter), 'VimReaperDim' },
      { lv.title, 'VimReaperHead' },
    },
    { { ' ' .. lv.task } },
    { { ' Tip: ', 'VimReaperDim' }, { lv.tip } },
  }
  if lv.goal then
    table.insert(rows, { { ' Sådan skal teksten ende:', 'VimReaperDim' } })
    for _, l in ipairs(lv.goal) do
      table.insert(rows, { { '   │ ', 'VimReaperDim' }, { l, 'VimReaperGoal' } })
    end
  end

  if S.done then
    local r = S.result
    table.insert(rows, {
      { (' ☠ Høstet!  %d tryk (par %d)  ' ):format(S.keys, lv.par), 'VimReaperHead' },
      { star_text(r.stars), 'VimReaperStar' },
      { ('  %.1f sek.'):format(r.secs), 'VimReaperDim' },
    })
    table.insert(rows, { { ' Par-løsning: ', 'VimReaperDim' }, { table.concat(lv.solution, '  '), 'VimReaperGoal' } })
    local next_text = S.idx < #levels and 'næste bane' or 'baneoversigten'
    table.insert(rows, { { (' <Enter> %s · :Retry prøv igen · :Menu alle baner'):format(next_text), 'VimReaperDim' } })
  else
    local status = { { (' Tryk: %d · Par: %d'):format(S.keys, lv.par), 'VimReaperHead' } }
    if lv.kind == 'hunt' then
      table.insert(status, { ('  ·  Sjæle: %d/%d'):format(S.reaped, #lv.targets), 'VimReaperHead' })
    end
    table.insert(rows, status)
    table.insert(rows, { { ' :Retry starter forfra · :Menu alle baner · :q afslutter', 'VimReaperDim' } })
  end
  set_info(rows)
end

local function mark_game()
  api.nvim_buf_clear_namespace(S.buf, ns, 0, -1)
  local lv = levels[S.idx]
  if S.done then return end
  if lv.kind == 'hunt' then
    local t = lv.targets[S.reaped + 1]
    if t[2] then
      api.nvim_buf_set_extmark(S.buf, ns, t[1] - 1, t[2] - 1, { end_col = t[2], hl_group = 'VimReaperSoul' })
    else
      api.nvim_buf_set_extmark(S.buf, ns, t[1] - 1, 0, {
        line_hl_group = 'VimReaperSoul',
        virt_text = { { ' ☠ hele linjen', 'VimReaperSoul' } },
      })
    end
  else
    for i, line in ipairs(api.nvim_buf_get_lines(S.buf, 0, -1, false)) do
      local ok = lv.goal[i] == line
      api.nvim_buf_set_extmark(S.buf, ns, i - 1, 0, {
        virt_text = { { ok and '  ✓' or '  ✗', ok and 'VimReaperOk' or 'VimReaperBad' } },
      })
    end
  end
end

local function refresh()
  if not S.idx then return end
  render_level()
  mark_game()
end

local show_menu

local function finish()
  local lv = levels[S.idx]
  S.done, S.counting = true, false
  local secs = S.started and (vim.uv.hrtime() - S.started) / 1e9 or 0
  S.result = { stars = stars_for(S.keys, lv.par), secs = secs }
  if S.result.stars > (S.progress[lv.id] or 0) then
    S.progress[lv.id] = S.result.stars
    save_progress()
  end
  vim.cmd('stopinsert')
  vim.bo[S.buf].modifiable = false
  vim.keymap.set('n', '<CR>', function()
    if S.idx < #levels then M.play(S.idx + 1) else show_menu() end
  end, { buffer = S.buf })
  refresh()
end

local function check()
  if S.done or not S.idx or api.nvim_get_current_buf() ~= S.buf then return end
  local lv = levels[S.idx]
  if lv.kind == 'hunt' then
    local t = lv.targets[S.reaped + 1]
    local cur = api.nvim_win_get_cursor(S.game_win)
    if cur[1] == t[1] and (t[2] == nil or cur[2] + 1 == t[2]) then
      S.reaped = S.reaped + 1
      if S.reaped == #lv.targets then return finish() end
    end
  elseif api.nvim_get_mode().mode == 'n' -- edits only count once back in Normal mode
    and vim.deep_equal(api.nvim_buf_get_lines(S.buf, 0, -1, false), lv.goal) then
    return finish()
  end
  refresh()
end

function M.play(i)
  local lv = levels[i]
  S.idx, S.keys, S.reaped, S.done, S.started, S.result = i, 0, 0, false, nil, nil
  local buf = show_buf(lv.lines, lv.kind == 'edit')
  api.nvim_buf_set_name(buf, lv.file or (lv.id .. '.txt'))
  if lv.ft then vim.bo[buf].filetype = lv.ft end
  api.nvim_win_set_cursor(S.game_win, { lv.start[1], lv.start[2] - 1 })
  -- Separate undo steps the player has to undo (see the undo level).
  for _, keys in ipairs(lv.prank or {}) do
    vim.cmd('let &l:undolevels = &l:undolevels')
    vim.cmd('normal! ' .. keys)
  end
  if lv.prank then api.nvim_win_set_cursor(S.game_win, { lv.start[1], lv.start[2] - 1 }) end
  vim.fn.setreg('/', '')
  S.counting = true
  refresh()
end

function show_menu()
  S.idx, S.counting, S.done = nil, false, false
  local lines, first_open, first_row = {}, nil, nil
  S.menu_rows = {}
  for _, l in ipairs(banner) do table.insert(lines, l) end
  vim.list_extend(lines, {
    '',
    '  Lær Neovim ved at høste sjæle. Alt herinde er ægte Neovim.',
    '  Gå til en bane med j/k og tryk <Enter>.',
  })
  local chapter, earned = nil, 0
  for i, lv in ipairs(levels) do
    if lv.chapter ~= chapter then
      chapter = lv.chapter
      vim.list_extend(lines, { '', '  ' .. chapter })
    end
    local stars = S.progress[lv.id] or 0
    earned = earned + stars
    table.insert(lines, ('    %02d  %s  %s'):format(i, star_text(stars), lv.title))
    S.menu_rows[#lines] = i
    first_row = first_row or #lines
    if stars == 0 and not first_open then first_open = #lines end
  end

  local buf = show_buf(lines, false)
  api.nvim_buf_set_name(buf, 'VimReaper')
  for row = 1, #banner do
    api.nvim_buf_set_extmark(buf, ns, row - 1, 0, { line_hl_group = 'VimReaperBanner' })
  end
  for row in pairs(S.menu_rows) do
    api.nvim_buf_set_extmark(buf, ns, row - 1, 8, { end_col = 8 + #star_text(0), hl_group = 'VimReaperStar' })
  end
  vim.keymap.set('n', '<CR>', function()
    local i = S.menu_rows[api.nvim_win_get_cursor(0)[1]]
    if i then M.play(i) end
  end, { buffer = buf })
  api.nvim_win_set_cursor(S.game_win, { first_open or first_row, 4 })

  set_info({
    { { ' ☠ VimReaper ', 'VimReaperTitle' }, { '  Baneoversigt', 'VimReaperHead' } },
    { { (' Stjerner: %d/%d'):format(earned, #levels * 3), 'VimReaperStar' } },
    { { ' Piletaster og mus er slået fra – her bruger man hjkl. :q afslutter.', 'VimReaperDim' } },
  })
end

function M.status()
  return { idx = S.idx, done = S.done, keys = S.keys, reaped = S.reaped }
end

local function setup_editor()
  vim.o.shortmess = vim.o.shortmess .. 'I'
  vim.o.mouse = ''
  vim.o.swapfile = false
  vim.o.number = true
  vim.o.relativenumber = true
  vim.o.cursorline = true
  vim.o.scrolloff = 3
  vim.o.wrap = false
  vim.o.expandtab = true
  vim.o.shiftwidth = 2
  vim.o.tabstop = 2
  vim.o.laststatus = 3

  local hl = {
    VimReaperSoul = { fg = '#ffffff', bg = '#c0392b', bold = true },
    VimReaperTitle = { fg = '#ffffff', bg = '#6c3483', bold = true },
    VimReaperBanner = { fg = '#c0392b', bold = true },
    VimReaperHead = { bold = true },
    VimReaperDim = { link = 'Comment' },
    VimReaperGoal = { link = 'String' },
    VimReaperOk = { fg = '#2ecc71', bold = true },
    VimReaperBad = { fg = '#e74c3c', bold = true },
    VimReaperStar = { fg = '#f1c40f' },
  }
  for name, spec in pairs(hl) do api.nvim_set_hl(0, name, spec) end

  for _, k in ipairs({ '<Up>', '<Down>', '<Left>', '<Right>' }) do
    vim.keymap.set({ 'n', 'i', 'v' }, k, function()
      api.nvim_echo({ { 'Ingen piletaster i reaperens rige – brug h j k l ☠', 'WarningMsg' } }, false, {})
    end)
  end
end

function M.start()
  S.progress = load_progress()
  setup_editor()

  S.game_win = api.nvim_get_current_win()
  S.info_buf = api.nvim_create_buf(false, true)
  vim.cmd('topleft split')
  S.info_win = api.nvim_get_current_win()
  api.nvim_win_set_buf(S.info_win, S.info_buf)
  local wo = vim.wo[S.info_win]
  wo.number, wo.relativenumber, wo.cursorline = false, false, false
  wo.wrap, wo.winfixheight = true, true
  api.nvim_set_current_win(S.game_win)

  local group = api.nvim_create_augroup('VimReaper', {})
  api.nvim_create_autocmd({ 'CursorMoved', 'TextChanged', 'TextChangedI' }, { group = group, callback = check })
  api.nvim_create_autocmd('InsertLeave', { group = group, callback = function() vim.schedule(check) end })
  api.nvim_create_autocmd('WinEnter', {
    group = group,
    callback = function()
      if api.nvim_get_current_win() == S.info_win then
        vim.schedule(function() api.nvim_set_current_win(S.game_win) end)
      end
    end,
  })
  api.nvim_create_autocmd('WinClosed', {
    group = group,
    callback = function(args)
      local win = tonumber(args.match)
      if win == S.game_win or win == S.info_win then vim.schedule(function() vim.cmd('qa!') end) end
    end,
  })
  api.nvim_create_autocmd('VimResized', { group = group, callback = function() if S.idx then refresh() end end })

  vim.on_key(function(_, typed)
    if S.counting and typed ~= '' and api.nvim_get_current_buf() == S.buf then
      S.keys = S.keys + 1
      S.started = S.started or vim.uv.hrtime()
      vim.schedule(refresh)
    end
  end, ns)

  api.nvim_create_user_command('Menu', function() show_menu() end, {})
  api.nvim_create_user_command('Retry', function() if S.idx then M.play(S.idx) end end, {})

  show_menu()
end

return M

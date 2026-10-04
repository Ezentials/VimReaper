-- Plays every level's par solution in an embedded Neovim, fed through the real
-- input loop so CursorMoved/TextChanged fire exactly as they do for a player.
-- Run: nvim --headless --clean -l test/run.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
local progress = vim.fn.tempname()

local ch = vim.fn.jobstart({ 'nvim', '--embed', '--headless', '--clean', '--cmd', 'set rtp^=' .. root }, { rpc = true })

local function lua(code, ...)
  return vim.rpcrequest(ch, 'nvim_exec_lua', code, { ... })
end

-- Feed one complete command. If Neovim is still waiting for more keys, any
-- non-fast request would block forever, so bail out instead.
local function feed(keys)
  vim.rpcrequest(ch, 'nvim_input', keys)
  vim.wait(30)
  if vim.rpcrequest(ch, 'nvim_get_mode').blocking then
    error(('%q left Neovim waiting for more keys'):format(keys))
  end
  lua('return 1') -- let scheduled callbacks (InsertLeave check) run
end

lua("local vr = require('vimreaper'); vr.progress_path = ...; vr.start()", progress)
local levels = lua("return vim.tbl_map(function(l) return { id = l.id, par = l.par, solution = l.solution } end, require('vimreaper.levels'))")

local failed = 0
for i, lv in ipairs(levels) do
  local ok, err = pcall(function()
    lua("require('vimreaper').play(...)", i)
    for j, keys in ipairs(lv.solution) do
      feed(keys)
      local st = lua("return require('vimreaper').status()")
      if j < #lv.solution and st.done then error(('finished early after %q'):format(keys)) end
    end
    local st = lua("return require('vimreaper').status()")
    if not st.done then
      local lines = lua('return vim.api.nvim_buf_get_lines(0, 0, -1, false)')
      local cur = lua('return vim.api.nvim_win_get_cursor(0)')
      error(('not finished (reaped %d), cursor %s, buffer:\n    %s'):format(
        st.reaped, vim.inspect(cur), table.concat(lines, '\n    ')))
    end
    if st.keys ~= lv.par then error(('counted %d keys, par is %d'):format(st.keys, lv.par)) end
  end)
  print(('%s %02d %-14s par %d%s'):format(ok and 'ok  ' or 'FAIL', i, lv.id, lv.par, ok and '' or ('\n     ' .. err)))
  if not ok then failed = failed + 1 end
end

vim.fn.jobstop(ch)
os.remove(progress)
print(failed == 0 and ('all %d levels pass'):format(#levels) or ('%d failed'):format(failed))
os.exit(failed == 0 and 0 or 1)

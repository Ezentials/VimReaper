-- Level data. Two kinds:
--   hunt: move the cursor onto each target in turn ({row, col}, or {row} for a whole line).
--   edit: change the buffer until it matches `goal`, then be back in Normal mode.
-- `keys` lists the keys a level teaches as {key, what it does}; `also` names keys from earlier
-- levels that the level needs, and `tip` is an optional hint.
-- `solution` is a list of complete commands; its key count is the level's par (set in init.lua).
-- test/run.lua plays every solution through real Neovim input, so keep them honest.

-- {row, col} of the first `needle` on a row (plus `off` chars), 1-based.
local function at(lines, row, needle, off)
  local col = assert(lines[row]:find(needle, 1, true), needle)
  return { row, col + (off or 0) }
end

local function grid(rows, cols)
  local lines = {}
  for i = 1, rows do lines[i] = ('.'):rep(cols) end
  return lines
end

local village = {
  'the reaper walks slowly through the quiet village at night',
  'every soul he meets is counted and written in his book',
}

local reapers = { 'grim reapers never forget a single name' }

local word_code = {
  'local soul = reaper.find(name, "village"):first()',
  'if soul.age > 99 then reaper.collect(soul) end',
}

local line_code = {
  '    return reaper.collect(soul)',
  '        -- the end is near',
  '    local count = 0',
}

local registry = {}
local names = { 'alice', 'bob', 'carol', 'dave', 'eve', 'frank', 'grete', 'hans', 'ida', 'jens' }
for i = 1, 60 do
  registry[i] = ('%03d  soul registered: %s'):format(i, names[(i - 1) % #names + 1])
end

local chapters = {
  '-- chapter one',
  'local a = 1',
  'local b = 2',
  '',
  '-- chapter two',
  'local c = 3',
  '',
  '-- chapter three',
  'local d = 4',
  'local e = 5',
  '',
  '-- chapter four',
  'local f = 6',
}

local marks = { 'reaper.mark(soul_a, soul_b, soul_c); reaper.sleep(100)' }

local says = { 'print("the reaper says: " .. greeting .. "!")' }

local ghost_log = {
  'night 1: the village sleeps',
  'night 2: a ghost knocks on the door',
  'night 3: nothing happens',
  'night 4: nothing happens again',
  'night 5: the ghost returns with a friend',
  'night 6: the reaper sharpens his scythe',
  'night 7: one more ghost is seen by the well',
  'night 8: quiet',
}

local levels = {
  -- Chapter 1 --------------------------------------------------------------
  {
    id = 'hjkl',
    chapter = 'The reaper\'s feet',
    title = 'First steps',
    task = 'Walk onto the red cell and reap the soul. A new one appears once you have taken it.',
    keys = {
      { 'h', '← one step left' },
      { 'j', '↓ one line down' },
      { 'k', '↑ one line up' },
      { 'l', '→ one step right' },
    },
    tip = 'Your fingers stay on the home row.',
    kind = 'hunt',
    lines = grid(7, 30),
    start = { 1, 1 },
    targets = { { 1, 5 }, { 4, 5 }, { 4, 2 }, { 2, 2 } },
    solution = { 'llll', 'jjj', 'hhh', 'kk' },
  },
  {
    id = 'counts',
    chapter = 'The reaper\'s feet',
    title = 'Count your steps',
    task = 'Same hunt, but further away. Put a number in front of the motion.',
    keys = {
      { '8j', '↓ 8 lines down – a number in front repeats the motion' },
      { '19l', '→ 19 steps right – works with h, j, k and l alike' },
    },
    also = 'h  j  k  l',
    tip = 'The relative line numbers on the left show the number to use with j and k.',
    kind = 'hunt',
    lines = grid(15, 40),
    start = { 1, 1 },
    targets = { { 9, 1 }, { 9, 20 }, { 3, 20 }, { 3, 5 } },
    solution = { '8j', '19l', '6k', '15h' },
  },

  -- Chapter 2 --------------------------------------------------------------
  {
    id = 'words',
    chapter = 'Word hopping',
    title = 'Word by word',
    task = 'Reap the souls. They always sit at the start of a word.',
    keys = {
      { 'w', '→ forward to the start of the next word' },
      { 'b', '← back to the start of a word' },
    },
    tip = 'Numbers work here too: 3w jumps three words.',
    kind = 'hunt',
    lines = village,
    start = { 1, 1 },
    targets = { at(village, 1, 'walks'), at(village, 1, 'village'), at(village, 1, 'through'), at(village, 1, 'night') },
    solution = { '2w', '5w', '3b', '5w' },
  },
  {
    id = 'word-end',
    chapter = 'Word hopping',
    title = 'End of the word',
    task = 'Now the souls sit at the end of the words.',
    keys = {
      { 'e', '→ forward to the end of a word' },
      { 'ge', '← back to the end of the previous word' },
    },
    tip = 'Numbers work here too: 2e jumps two word ends.',
    kind = 'hunt',
    lines = reapers,
    start = { 1, 1 },
    targets = {
      at(reapers, 1, 'grim', 3),
      at(reapers, 1, 'never', 4),
      at(reapers, 1, 'single', 5),
      at(reapers, 1, 'name', 3),
    },
    solution = { 'e', '2e', '3e', 'e' },
  },
  {
    id = 'WORD',
    chapter = 'Word hopping',
    title = 'Big WORDS',
    task = 'Code is full of punctuation. Reap the souls without tripping over it.',
    keys = {
      { 'W', '→ forward to the start of the next WORD' },
      { 'B', '← back to the start of a WORD' },
      { 'E', '→ forward to the end of a WORD' },
    },
    tip = 'Only spaces separate WORDs: reaper.find(name, is one WORD. Try 3W too.',
    kind = 'hunt',
    file = 'reap.lua',
    ft = 'lua',
    lines = word_code,
    start = { 1, 1 },
    targets = {
      at(word_code, 1, 'reaper'),
      at(word_code, 1, '"village"'),
      at(word_code, 2, 'if'),
      at(word_code, 2, 'reaper'),
      at(word_code, 2, 'soul.age'),
    },
    solution = { '3W', 'W', 'W', '5W', '4B' },
  },

  -- Chapter 3 --------------------------------------------------------------
  {
    id = 'line-ends',
    chapter = 'Around the line',
    title = 'End to end',
    task = 'Jump to the edges of the lines.',
    keys = {
      { '0', 'first column of the line' },
      { '^', 'first non-blank character of the line' },
      { '$', 'last character of the line' },
    },
    also = 'j',
    tip = 'In indented code 0 lands in the indentation and ^ on the code itself.',
    kind = 'hunt',
    file = 'reap.lua',
    ft = 'lua',
    lines = line_code,
    start = { 1, 1 },
    targets = {
      { 1, #line_code[1] },
      at(line_code, 1, 'return'),
      { 2, 1 },
      { 3, #line_code[3] },
      at(line_code, 3, 'local'),
    },
    solution = { '$', '^', 'j0', 'j$', '^' },
  },
  {
    id = 'file-jumps',
    chapter = 'Around the line',
    title = 'Around the whole file',
    task = 'The souls fill whole lines now – hitting the line is enough.',
    keys = {
      { 'gg', 'first line of the file' },
      { 'G', 'last line of the file' },
      { '42G', 'line 42 (any number works)' },
      { ':42<Enter>', 'line 42, typed on the command line' },
    },
    kind = 'hunt',
    lines = registry,
    start = { 1, 1 },
    targets = { { 60 }, { 1 }, { 42 }, { 17 } },
    solution = { 'G', 'gg', '42G', ':17<CR>' },
  },
  {
    id = 'paragraphs',
    chapter = 'Around the line',
    title = 'Paragraph hopping',
    task = 'The souls hide in the blank lines between paragraphs.',
    keys = {
      { '}', 'forward to the next empty line' },
      { '{', 'back to the previous empty line' },
    },
    tip = 'A line with only spaces is not empty. 2} jumps two paragraphs.',
    kind = 'hunt',
    file = 'chapters.lua',
    ft = 'lua',
    lines = chapters,
    start = { 1, 1 },
    targets = { { 4 }, { 11 }, { 7 } },
    solution = { '}', '2}', '{' },
  },

  -- Chapter 4 --------------------------------------------------------------
  {
    id = 'find',
    chapter = 'Find and jump',
    title = 'Find the character',
    task = 'Jump straight to the character instead of walking there.',
    keys = {
      { 'f', '→ onto a character: f( jumps onto the next ( on the line' },
      { ';', 'repeat the last f, t, F or T' },
      { ',', 'repeat it in the other direction' },
    },
    kind = 'hunt',
    file = 'mark.lua',
    ft = 'lua',
    lines = marks,
    start = { 1, 1 },
    targets = {
      at(marks, 1, '('),
      at(marks, 1, ','),
      at(marks, 1, ', soul_c'),
      at(marks, 1, ';'),
      at(marks, 1, '1'),
    },
    solution = { 'f(', 'f,', ';', 'f;', 'f1' },
  },
  {
    id = 'till',
    chapter = 'Find and jump',
    title = 'Just before',
    task = 'The souls sit right next to the character, not on it.',
    keys = {
      { 't', '→ just before a character: t" stops right before the next "' },
      { 'F', '← like f, but backwards: Fh jumps back onto the previous h' },
      { 'T', '← like t, but backwards: T( stops right after the previous (' },
    },
    kind = 'hunt',
    file = 'says.lua',
    ft = 'lua',
    lines = says,
    start = { 1, 1 },
    targets = {
      at(says, 1, '('),
      at(says, 1, 'says', 3),
      at(says, 1, 'the', 1),
      at(says, 1, '"'),
    },
    solution = { 't"', 't:', 'Fh', 'T(' },
  },
  {
    id = 'search',
    chapter = 'Find and jump',
    title = 'Ghost hunt',
    task = 'The souls sit on the ghosts. Search for the word ghost instead of walking.',
    keys = {
      { '/', 'search: type /ghost and press <Enter> to jump to the next ghost' },
      { 'n', 'jump to the next match' },
      { 'N', 'jump to the previous match' },
    },
    kind = 'hunt',
    lines = ghost_log,
    start = { 1, 1 },
    targets = {
      at(ghost_log, 2, 'ghost'),
      at(ghost_log, 5, 'ghost'),
      at(ghost_log, 7, 'ghost'),
      at(ghost_log, 5, 'ghost'),
    },
    solution = { '/ghost<CR>', 'n', 'n', 'N' },
  },

  -- Chapter 5 --------------------------------------------------------------
  {
    id = 'x',
    chapter = 'Delete',
    title = 'Weeds',
    task = 'Remove the extra letters.',
    keys = { { 'x', 'delete the character under the cursor' } },
    also = 'f  ;',
    kind = 'edit',
    lines = { 'the reaperr walkss in thhe night' },
    goal = { 'the reaper walks in the night' },
    start = { 1, 1 },
    solution = { 'fr', ';', 'x', 'fs', 'x', 'fh', 'x' },
  },
  {
    id = 'dw',
    chapter = 'Delete',
    title = 'Echo echo',
    task = 'Some words appear twice. Delete the duplicates.',
    keys = { { 'dw', 'delete from the cursor to the start of the next word' } },
    also = 'w',
    tip = 'd is an operator: d + any motion deletes what the motion moves over.',
    kind = 'edit',
    lines = { 'the reaper reaper visits visits every every house' },
    goal = { 'the reaper visits every house' },
    start = { 1, 1 },
    solution = { 'w', 'dw', 'w', 'dw', 'w', 'dw' },
  },
  {
    id = 'dd',
    chapter = 'Delete',
    title = 'Whole lines',
    task = 'The ghosts have sneaked onto the list. Delete their lines.',
    keys = {
      { 'dd', 'delete the whole line' },
      { '2dd', 'delete two lines (any count works)' },
    },
    also = 'j',
    kind = 'edit',
    lines = { 'soul 1: alice', 'GHOST: boo', 'soul 2: bob', 'GHOST: boo', 'GHOST: boo', 'soul 3: carol' },
    goal = { 'soul 1: alice', 'soul 2: bob', 'soul 3: carol' },
    start = { 1, 1 },
    solution = { 'j', 'dd', 'j', '2dd' },
  },
  {
    id = 'd-motion',
    chapter = 'Delete',
    title = 'Cut off the tail',
    task = 'Clean up the code.',
    keys = {
      { 'D', 'delete from the cursor to the end of the line' },
      { 'dt', 'delete till a character: dt1 deletes everything before the next 1' },
    },
    also = 'f  h  j  0',
    tip = 'D starts at the cursor – step back with h first to take the space too.',
    kind = 'edit',
    file = 'cleanup.lua',
    ft = 'lua',
    lines = { 'local name = "reaper" -- TODO remove this comment', 'local age = 9999 + 1' },
    goal = { 'local name = "reaper"', 'local age = 1' },
    start = { 1, 1 },
    solution = { 'f-', 'hD', 'j0', 'f9', 'dt1' },
  },

  -- Chapter 6 --------------------------------------------------------------
  {
    id = 'insert',
    chapter = 'Type',
    title = 'Missing letters',
    task = 'Insert what is missing. Remember <Esc> afterwards – only then does it count.',
    keys = {
      { 'i', 'type before the cursor' },
      { 'a', 'type after the cursor' },
      { '<Esc>', 'back to Normal mode' },
    },
    also = 'f',
    kind = 'edit',
    lines = { 'the rper is hre' },
    goal = { 'the reaper is here' },
    start = { 1, 1 },
    solution = { 'fp', 'iea<Esc>', 'fh', 'ae<Esc>' },
  },
  {
    id = 'append',
    chapter = 'Type',
    title = 'Ends of the line',
    task = 'Finish the list.',
    keys = {
      { 'I', 'type at the start of the line (before the first non-blank)' },
      { 'A', 'type at the end of the line' },
      { 'o', 'open a new line below and type' },
      { 'O', 'open a new line above and type' },
    },
    also = 'j  <Esc>',
    kind = 'edit',
    lines = { 'grim reaper', 'souls collected: 3' },
    goal = { '# souls', 'the grim reaper', 'souls collected: 3!', 'done' },
    start = { 1, 1 },
    solution = { 'O# souls<Esc>', 'j', 'Ithe <Esc>', 'j', 'A!<Esc>', 'odone<Esc>' },
  },

  -- Chapter 7 --------------------------------------------------------------
  {
    id = 'replace',
    chapter = 'Change',
    title = 'Typos',
    task = 'Fix the wrong letters without entering Insert mode.',
    keys = { { 'r', 'replace the character under the cursor: re turns it into an e' } },
    also = 'f',
    tip = 'r stays in Normal mode, so no <Esc> is needed.',
    kind = 'edit',
    lines = { 'tha reapor iz hore' },
    goal = { 'the reaper is here' },
    start = { 1, 1 },
    solution = { 'fa', 're', 'fo', 're', 'fz', 'rs', 'fo', 're' },
  },
  {
    id = 'change-word',
    chapter = 'Change',
    title = 'Swap the word',
    task = 'The ghosts must become souls, and the old name must become new.',
    keys = {
      { 'cw', 'change to the end of the word (delete it, then type)' },
      { 'ct', 'change till a character: ct_ changes everything before the next _' },
    },
    also = 'w  f  <Esc>',
    tip = 'c works like d, but leaves you in Insert mode. Finish with <Esc>.',
    kind = 'edit',
    file = 'find.lua',
    ft = 'lua',
    lines = { 'local ghost = find_ghost(old_name)' },
    goal = { 'local soul = find_soul(new_name)' },
    start = { 1, 1 },
    solution = { 'w', 'cwsoul<Esc>', 'fg', 'cwsoul<Esc>', 'fo', 'ct_new<Esc>' },
  },
  {
    id = 'change-inside',
    chapter = 'Change',
    title = 'Inside',
    task = 'Change the contents of the quotes and the parentheses.',
    keys = {
      { 'ci"', 'change everything inside the "…"' },
      { 'ci(', 'change everything inside the (…)' },
      { 'ci{', 'change everything inside the {…}' },
    },
    also = 'f  j  0  <Esc>',
    tip = 'di( deletes inside without typing – handy when the brackets end up empty.',
    kind = 'edit',
    file = 'say.lua',
    ft = 'lua',
    lines = { 'reaper.say("hello there", { volume = 1 })', 'print(get_all_the_souls(now))' },
    goal = { 'reaper.say("boo", {})', 'print()' },
    start = { 1, 1 },
    solution = { 'ci"boo<Esc>', 'f{', 'ci{<Esc>', 'j0', 'f(', 'ci(<Esc>' },
  },

  -- Chapter 8 --------------------------------------------------------------
  {
    id = 'dot',
    chapter = 'Repeat and undo',
    title = 'Dot magic',
    task = 'Turn every ghost into a soul. Do it once – and let . do the rest.',
    keys = {
      { 'ciw', 'change the whole word, wherever in it the cursor is' },
      { '.', 'repeat your last change' },
    },
    also = 'j  <Esc>',
    kind = 'edit',
    lines = { 'ghost alice', 'ghost bob', 'ghost carol', 'ghost dave', 'ghost eve' },
    goal = { 'soul alice', 'soul bob', 'soul carol', 'soul dave', 'soul eve' },
    start = { 1, 1 },
    solution = { 'ciwsoul<Esc>', 'j.', 'j.', 'j.', 'j.' },
  },
  {
    id = 'undo',
    chapter = 'Repeat and undo',
    title = 'The ghost\'s prank',
    task = 'A ghost made three changes to the file. Undo them all.',
    keys = {
      { 'u', 'undo the last change' },
      { '<C-r>', 'redo (Ctrl+r) – if you undid too much' },
    },
    kind = 'edit',
    lines = { 'the reaper keeps a list', 'of every soul in town', 'and checks it twice' },
    goal = { 'the reaper keeps a list', 'of every soul in town', 'and checks it twice' },
    prank = { 'Gdd', 'ggAboo<Esc>', 'x' },
    start = { 1, 1 },
    solution = { 'u', 'u', 'u' },
  },

  -- Chapter 9 --------------------------------------------------------------
  {
    id = 'yank',
    chapter = 'Copy and move',
    title = 'The order',
    task = 'Swap the first two steps, and rest twice at the end.',
    keys = {
      { 'yy', 'copy (yank) the whole line' },
      { 'p', 'put what you copied or deleted – whole lines go below' },
      { 'ddp', 'swap a line with the one below (delete it, put it back below)' },
    },
    also = 'G',
    kind = 'edit',
    lines = { 'step 2: harvest', 'step 1: sharpen scythe', 'step 3: rest' },
    goal = { 'step 1: sharpen scythe', 'step 2: harvest', 'step 3: rest', 'step 3: rest' },
    start = { 1, 1 },
    solution = { 'ddp', 'G', 'yyp' },
  },
  {
    id = 'visual',
    chapter = 'Copy and move',
    title = 'Visual harvest',
    task = 'Indent the three print lines into the function.',
    keys = {
      { 'V', 'select whole lines (Visual Line mode)' },
      { '>', 'indent the selected lines' },
    },
    also = 'j',
    tip = 'Grow the selection with j or k before pressing >.',
    kind = 'edit',
    file = 'reap.lua',
    lines = { 'function reap()', 'print("one")', 'print("two")', 'print("three")', 'end' },
    goal = { 'function reap()', '  print("one")', '  print("two")', '  print("three")', 'end' },
    start = { 1, 1 },
    solution = { 'j', 'Vjj>' },
  },

  -- Chapter 10 --------------------------------------------------------------
  {
    id = 'substitute',
    chapter = 'The command line',
    title = 'Mass replace',
    task = 'Every single ghost must be a soul. Everywhere.',
    keys = { { ':%s/old/new/g', 'replace every old with new – your own words, then <Enter>' } },
    tip = '% = every line · g = every match on a line, not only the first.',
    kind = 'edit',
    lines = {
      'ghost one met ghost two',
      'ghost three was alone',
      'no ghost here, said ghost four',
      'the end',
    },
    goal = {
      'soul one met soul two',
      'soul three was alone',
      'no soul here, said soul four',
      'the end',
    },
    start = { 1, 1 },
    solution = { ':%s/ghost/soul/g<CR>' },
  },
  {
    id = 'boss',
    chapter = 'The command line',
    title = 'The final judgement',
    task = 'The boss: fix the code so it matches the goal. Use everything you have learned.',
    keys = { { 'xp', 'swap two characters (delete one, put it back after the next)' } },
    also = 'ciw  .  f  j  dd  o  <Esc>',
    tip = 'There are many ways – find a short one.',
    kind = 'edit',
    file = 'reap.lua',
    ft = 'lua',
    lines = {
      'local function reap(souls)',
      '  for i, ghost in ipairs(souls) do',
      '    print("collecting " .. ghost.nmae)',
      '    print("debug!!!")',
      '  end',
      'end',
    },
    goal = {
      'local function reap(souls)',
      '  for i, soul in ipairs(souls) do',
      '    print("collecting " .. soul.name)',
      '  end',
      '  return #souls',
      'end',
    },
    start = { 1, 1 },
    solution = { 'j', 'fg', 'ciwsoul<Esc>', 'j', 'fh', '.', 'fm', 'xp', 'jdd', 'oreturn #souls<Esc>' },
  },
}

return levels

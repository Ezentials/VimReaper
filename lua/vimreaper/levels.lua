-- Level data. Two kinds:
--   hunt: move the cursor onto each target in turn ({row, col}, or {row} for a whole line).
--   edit: change the buffer until it matches `goal`, then be back in Normal mode.
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
  -- Kapitel 1 ---------------------------------------------------------------
  {
    id = 'hjkl',
    chapter = 'Reaperens fødder',
    title = 'Første skridt',
    task = 'Gå hen på det røde felt og høst sjælen. Der kommer en ny, når du har taget den.',
    tip = 'h ← venstre · j ↓ ned · k ↑ op · l → højre. Fingrene bliver på hjemmerækken.',
    kind = 'hunt',
    lines = grid(7, 30),
    start = { 1, 1 },
    targets = { { 1, 5 }, { 4, 5 }, { 4, 2 }, { 2, 2 } },
    solution = { 'llll', 'jjj', 'hhh', 'kk' },
  },
  {
    id = 'counts',
    chapter = 'Reaperens fødder',
    title = 'Tæl skridtene',
    task = 'Samme jagt, men længere væk. Brug et tal foran bevægelsen.',
    tip = '8j går 8 linjer ned. Tallene i venstre side er relative – de viser, hvor langt der er.',
    kind = 'hunt',
    lines = grid(15, 40),
    start = { 1, 1 },
    targets = { { 9, 1 }, { 9, 20 }, { 3, 20 }, { 3, 5 } },
    solution = { '8j', '19l', '6k', '15h' },
  },

  -- Kapitel 2 ---------------------------------------------------------------
  {
    id = 'words',
    chapter = 'Ordhop',
    title = 'Ord for ord',
    task = 'Høst sjælene. De sidder altid i starten af et ord.',
    tip = 'w hopper frem til næste ords start, b tilbage. Tal virker også: 3w.',
    kind = 'hunt',
    lines = village,
    start = { 1, 1 },
    targets = { at(village, 1, 'walks'), at(village, 1, 'village'), at(village, 1, 'through'), at(village, 1, 'night') },
    solution = { '2w', '5w', '3b', '5w' },
  },
  {
    id = 'word-end',
    chapter = 'Ordhop',
    title = 'Ordets ende',
    task = 'Nu sidder sjælene for enden af ordene.',
    tip = 'e hopper til slutningen af ordet (ge baglæns). 2e = to ord-ender frem.',
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
    chapter = 'Ordhop',
    title = 'Store ORD',
    task = 'Kode er fuld af tegnsætning. Høst sjælene uden at snuble over den.',
    tip = 'W, B og E tæller kun mellemrum som ordgrænse, så reaper.find(name, er ét ORD.',
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

  -- Kapitel 3 ---------------------------------------------------------------
  {
    id = 'line-ends',
    chapter = 'Linjen rundt',
    title = 'Fra ende til anden',
    task = 'Spring til linjernes yderpunkter.',
    tip = '0 = linjens første tegn · ^ = første tegn der ikke er mellemrum · $ = sidste tegn.',
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
    chapter = 'Linjen rundt',
    title = 'Hele filen rundt',
    task = 'Sjælene fylder hele linjer nu – det er nok at ramme linjen.',
    tip = 'gg = første linje · G = sidste · 42G eller :42<Enter> = linje 42.',
    kind = 'hunt',
    lines = registry,
    start = { 1, 1 },
    targets = { { 60 }, { 1 }, { 42 }, { 17 } },
    solution = { 'G', 'gg', '42G', ':17<CR>' },
  },
  {
    id = 'paragraphs',
    chapter = 'Linjen rundt',
    title = 'Afsnitshop',
    task = 'Sjælene gemmer sig i de tomme linjer mellem afsnittene.',
    tip = '} hopper til næste tomme linje, { til forrige. 2} hopper to afsnit.',
    kind = 'hunt',
    file = 'chapters.lua',
    ft = 'lua',
    lines = chapters,
    start = { 1, 1 },
    targets = { { 4 }, { 11 }, { 7 } },
    solution = { '}', '2}', '{' },
  },

  -- Kapitel 4 ---------------------------------------------------------------
  {
    id = 'find',
    chapter = 'Find og spring',
    title = 'Find tegnet',
    task = 'Spring direkte til tegnet i stedet for at gå derhen.',
    tip = 'f( hopper til næste ( på linjen. ; gentager sidste f, og , går den anden vej.',
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
    chapter = 'Find og spring',
    title = 'Lige før',
    task = 'Sjælene sidder lige ved siden af tegnet, ikke på det.',
    tip = 't" stopper lige før næste " · F og T virker baglæns.',
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
    chapter = 'Find og spring',
    title = 'Spøgelsesjagt',
    task = 'Find spøgelserne i loggen. Det er hurtigere at søge end at gå.',
    tip = '/ghost<Enter> søger frem · n = næste fund · N = forrige fund.',
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

  -- Kapitel 5 ---------------------------------------------------------------
  {
    id = 'x',
    chapter = 'Slet',
    title = 'Ukrudt',
    task = 'Fjern de ekstra bogstaver.',
    tip = 'x sletter tegnet under markøren. Kombinér med f for at komme hurtigt hen.',
    kind = 'edit',
    lines = { 'the reaperr walkss in thhe night' },
    goal = { 'the reaper walks in the night' },
    start = { 1, 1 },
    solution = { 'fr', ';', 'x', 'fs', 'x', 'fh', 'x' },
  },
  {
    id = 'dw',
    chapter = 'Slet',
    title = 'Ekko ekko',
    task = 'Nogle ord står der to gange. Slet dubletterne.',
    tip = 'dw sletter fra markøren til næste ord. d er en operator: d + bevægelse.',
    kind = 'edit',
    lines = { 'the reaper reaper visits visits every every house' },
    goal = { 'the reaper visits every house' },
    start = { 1, 1 },
    solution = { 'w', 'dw', 'w', 'dw', 'w', 'dw' },
  },
  {
    id = 'dd',
    chapter = 'Slet',
    title = 'Hele linjer',
    task = 'Spøgelserne har sneget sig ind på listen. Slet deres linjer.',
    tip = 'dd sletter linjen. 2dd sletter to linjer.',
    kind = 'edit',
    lines = { 'soul 1: alice', 'GHOST: boo', 'soul 2: bob', 'GHOST: boo', 'GHOST: boo', 'soul 3: carol' },
    goal = { 'soul 1: alice', 'soul 2: bob', 'soul 3: carol' },
    start = { 1, 1 },
    solution = { 'j', 'dd', 'j', '2dd' },
  },
  {
    id = 'd-motion',
    chapter = 'Slet',
    title = 'Klip halen af',
    task = 'Ryd op i koden.',
    tip = 'D sletter resten af linjen · dt1 sletter frem til (men ikke med) næste 1.',
    kind = 'edit',
    file = 'cleanup.lua',
    ft = 'lua',
    lines = { 'local name = "reaper" -- TODO remove this comment', 'local age = 9999 + 1' },
    goal = { 'local name = "reaper"', 'local age = 1' },
    start = { 1, 1 },
    solution = { 'f-', 'hD', 'j0', 'f9', 'dt1' },
  },

  -- Kapitel 6 ---------------------------------------------------------------
  {
    id = 'insert',
    chapter = 'Skriv',
    title = 'Manglende bogstaver',
    task = 'Indsæt det, der mangler. Husk <Esc> bagefter – først da tæller det.',
    tip = 'i skriver før markøren · a skriver efter · <Esc> tilbage til Normal mode.',
    kind = 'edit',
    lines = { 'the rper is hre' },
    goal = { 'the reaper is here' },
    start = { 1, 1 },
    solution = { 'fp', 'iea<Esc>', 'fh', 'ae<Esc>' },
  },
  {
    id = 'append',
    chapter = 'Skriv',
    title = 'Linjens ender',
    task = 'Byg listen færdig.',
    tip = 'I = skriv i starten af linjen · A = i slutningen · o = ny linje under · O = ny linje over.',
    kind = 'edit',
    lines = { 'grim reaper', 'souls collected: 3' },
    goal = { '# souls', 'the grim reaper', 'souls collected: 3!', 'done' },
    start = { 1, 1 },
    solution = { 'O# souls<Esc>', 'j', 'Ithe <Esc>', 'j', 'A!<Esc>', 'odone<Esc>' },
  },

  -- Kapitel 7 ---------------------------------------------------------------
  {
    id = 'replace',
    chapter = 'Ændr',
    title = 'Stavefejl',
    task = 'Ret de forkerte bogstaver uden at gå i Insert mode.',
    tip = 'r<tegn> erstatter tegnet under markøren og bliver i Normal mode.',
    kind = 'edit',
    lines = { 'tha reapor iz hore' },
    goal = { 'the reaper is here' },
    start = { 1, 1 },
    solution = { 'fa', 're', 'fo', 're', 'fz', 'rs', 'fo', 're' },
  },
  {
    id = 'change-word',
    chapter = 'Ændr',
    title = 'Skift ordet',
    task = 'Spøgelserne skal være sjæle, og det gamle navn skal være nyt.',
    tip = 'cw sletter til ordets ende og går i Insert mode · ct_ ændrer frem til næste _.',
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
    chapter = 'Ændr',
    title = 'Indeni',
    task = 'Skift indholdet i anførselstegn og parenteser.',
    tip = 'ci" ændrer inden i "…" · ci( inden i (…) · ci{ inden i {…}. di( sletter bare.',
    kind = 'edit',
    file = 'say.lua',
    ft = 'lua',
    lines = { 'reaper.say("hello there", { volume = 1 })', 'print(get_all_the_souls(now))' },
    goal = { 'reaper.say("boo", {})', 'print()' },
    start = { 1, 1 },
    solution = { 'ci"boo<Esc>', 'f{', 'ci{<Esc>', 'j0', 'f(', 'ci(<Esc>' },
  },

  -- Kapitel 8 ---------------------------------------------------------------
  {
    id = 'dot',
    chapter = 'Gentag og fortryd',
    title = 'Prik-magi',
    task = 'Gør alle spøgelser til sjæle. Gør det én gang – og lad . gøre resten.',
    tip = '. gentager din sidste ændring. ciw ændrer hele ordet, uanset hvor i ordet du står.',
    kind = 'edit',
    lines = { 'ghost alice', 'ghost bob', 'ghost carol', 'ghost dave', 'ghost eve' },
    goal = { 'soul alice', 'soul bob', 'soul carol', 'soul dave', 'soul eve' },
    start = { 1, 1 },
    solution = { 'ciwsoul<Esc>', 'j.', 'j.', 'j.', 'j.' },
  },
  {
    id = 'undo',
    chapter = 'Gentag og fortryd',
    title = 'Spøgelsets spøg',
    task = 'Et spøgelse har lavet tre ændringer i filen. Fortryd dem alle.',
    tip = 'u fortryder · <C-r> gentager det fortrudte, hvis du kom for langt tilbage.',
    kind = 'edit',
    lines = { 'the reaper keeps a list', 'of every soul in town', 'and checks it twice' },
    goal = { 'the reaper keeps a list', 'of every soul in town', 'and checks it twice' },
    prank = { 'Gdd', 'ggAboo<Esc>', 'x' },
    start = { 1, 1 },
    solution = { 'u', 'u', 'u' },
  },

  -- Kapitel 9 ---------------------------------------------------------------
  {
    id = 'yank',
    chapter = 'Kopiér og flyt',
    title = 'Rækkefølgen',
    task = 'Byt om på de to første trin, og hvil dig to gange til sidst.',
    tip = 'ddp bytter en linje med den under · yy kopierer linjen · p sætter ind under.',
    kind = 'edit',
    lines = { 'step 2: harvest', 'step 1: sharpen scythe', 'step 3: rest' },
    goal = { 'step 1: sharpen scythe', 'step 2: harvest', 'step 3: rest', 'step 3: rest' },
    start = { 1, 1 },
    solution = { 'ddp', 'G', 'yyp' },
  },
  {
    id = 'visual',
    chapter = 'Kopiér og flyt',
    title = 'Visuel høst',
    task = 'Ryk de tre print-linjer ind i funktionen.',
    tip = 'V markerer hele linjer, j/k udvider markeringen, og > rykker den ind.',
    kind = 'edit',
    file = 'reap.lua',
    lines = { 'function reap()', 'print("one")', 'print("two")', 'print("three")', 'end' },
    goal = { 'function reap()', '  print("one")', '  print("two")', '  print("three")', 'end' },
    start = { 1, 1 },
    solution = { 'j', 'Vjj>' },
  },

  -- Kapitel 10 --------------------------------------------------------------
  {
    id = 'substitute',
    chapter = 'Kommandolinjen',
    title = 'Masseudskiftning',
    task = 'Hvert eneste ghost skal være soul. Overalt.',
    tip = ':%s/gammel/ny/g erstatter i hele filen (% = alle linjer, g = alle på linjen).',
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
    chapter = 'Kommandolinjen',
    title = 'Den sidste dom',
    task = 'Bossen: ret koden, så den matcher målet. Brug alt, hvad du har lært.',
    tip = 'ciw, ., f, xp (byt to tegn), dd, o … Der er mange veje – find en kort.',
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

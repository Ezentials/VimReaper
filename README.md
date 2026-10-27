# ☠ VimReaper

A small game that teaches you Neovim, played **inside real Neovim**. Nothing is emulated:
every level is an ordinary buffer, and the game just watches the cursor and the text. What you
learn here works exactly the same way when you open your own files afterwards.

```sh
./vimreaper
```

Requires Neovim 0.10+. The game starts with `nvim --clean`, so your own config and plugins
stay out of the way (e.g. flash.nvim taking over `s`).

## How to play

- **Hunt levels**: walk onto the red cell and reap the soul. A new one appears once you have
  taken it.
- **Edit levels**: change the text until it matches the goal shown at the top, then go back to
  Normal mode with `<Esc>`. ✓/✗ next to each line shows whether it is already right.
- Each level lists the keys to use and what they do; **Also useful** names keys from earlier
  levels that it needs. The level list shows which keys each level teaches.
- Every level has a **par**, the number of keystrokes in a short solution. Match or beat par
  for ★★★. Once a level is done, the par solution is shown so you can see the trick.
- `:Retry` restarts the level, `:Menu` lists all levels, `:q` quits.
- Arrow keys and the mouse are disabled.

26 levels in 10 chapters: hjkl and counts, w/b/e/W, 0 ^ $ gg G { }, f/t and search,
x/dw/dd/D/dt, i/a/I/A/o/O, r/cw/ciw/ci", `.` and `u`, yy/p/ddp/V>, `:%s` – and a boss at the end.

Progress is saved in `progress.json` (delete it to start over).

## New levels

Levels live in `lua/vimreaper/levels.lua` as plain data. Each level has `keys` (the keys it
teaches, with a short explanation) and a `solution`. The test
plays every solution through Neovim's real input loop and checks that the level is completed
exactly on the last command and that the key count matches par:

```sh
nvim --headless --clean -l test/run.lua
```

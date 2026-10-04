# ☠ VimReaper

Et lille spil, der lærer dig Neovim – spillet **inde i ægte Neovim**. Der er ingen emulering:
hver bane er en almindelig buffer, og spillet holder bare øje med markøren og teksten. Det, du
lærer her, virker derfor præcis på samme måde, når du bagefter åbner dine egne filer.

```sh
./vimreaper
```

Kræver Neovim 0.10+. Spillet starter med `nvim --clean`, så din egen config og dine plugins ikke
blander sig (fx flash.nvim, der tager `s`).

## Sådan spiller man

- **Jagtbaner**: gå hen på det røde felt og høst sjælen. Der dukker en ny op, når du har taget den.
- **Redigeringsbaner**: ret teksten, så den matcher målet øverst, og gå tilbage til Normal mode
  med `<Esc>`. ✓/✗ ud for hver linje viser, om den allerede er rigtig.
- Hver bane har et **par**, altså antallet af tastetryk i en kort løsning. Rammer du par eller
  bedre, får du ★★★. Når banen er klaret, får du vist par-løsningen, så du kan se tricket.
- `:Retry` starter banen forfra, `:Menu` viser alle baner, og `:q` afslutter.
- Piletaster og mus er slået fra.

26 baner i 10 kapitler: hjkl og tal, w/b/e/W, 0 ^ $ gg G { }, f/t og søgning, x/dw/dd/D/dt,
i/a/I/A/o/O, r/cw/ciw/ci", `.` og `u`, yy/p/ddp/V>, `:%s` – og en boss til sidst.

Fremskridtet gemmes i `progress.json` (slet filen for at starte forfra).

## Nye baner

Banerne ligger i `lua/vimreaper/levels.lua` som rene data. Hver bane har en `solution`. Testen
spiller alle løsninger igennem Neovims rigtige input-loop og tjekker, at banen bliver klaret
præcis på sidste kommando, og at tastetællingen passer med par:

```sh
nvim --headless --clean -l test/run.lua
```

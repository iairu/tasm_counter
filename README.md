# TASM Counter

## Program will output the amount of digits, small letters, big letters and other characters for every line and for the whole input (file).

See comments in `count.asm`.

The whole program is linked as an external procedure because there were some bonus points promised for it, no real reason other than that.

## Help

Some notes are in Slovak (such as the requirements for this exercise and selected bonus sub-exercises), but they're not crucial to understanding of what is happening. The only annoying part may be that the actual user-output is in Slovak incl. help. So to summarize in English:

```
Help for SPAASM Z1:
Ondrej Spanik 2022 (c) iairu.com
Program will output the amount of digits, small letters, big letters and other characters for every line and for the whole input (file).

Possible arguments:
[file] - Program input at the given point
-h - Help output at the given point (in Slovak)
-s - Switch to summary-only output at the given point (no per-line amounts)
-c - Clear the screen at the given point

Any combination of arguments is possible.
Every argument is always processed in order of entry.
The amounts will overflow every 16-bits (~64kB) because WORD type is used.
Works for files >64kB.
```

## How to run this on Windows using VSCode

My recommendation is to use **MASM/TASM VSCode extension**, set it to **dosbox-x** mode with the whole "**workspace**" mounted (not just single-file mode). 

Then (considering the external procedure requires combined linking) use "**Open emulator**" in right-click menu of any .asm file here and within it use **compile.bat**.

### Mac/Linux

It is possible to use the given VSCode extension on **Mac/Linux**, but you have to refer to its GitHub page for information about how to download & link-up dosbox for given platforms (included only for Windows).

## Info

This was done as a part of SPAASM subject at the FIIT faculty of STU Bratislava by me in 2022-03. It was also my first Assembly project.

## It's 2022, why are we using 16-bit TASM built for DOS sometime in 1990s?

No idea, it was "really fun" to find any help when i got stuck. But i managed. Not sure why we don't use NASM or something newer.

https://iairu.com (c) 2022

Have fun.


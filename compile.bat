@echo off
TASM main.asm
TASM count.asm
TLINK main.obj count.obj
DEL main.obj
DEL count.obj
DEL main.map

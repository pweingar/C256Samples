@echo off

REM The name portion of the top source file and all generated files
set SOURCE=sample

REM The location of 64TASS
set TASSHOME=d:\64tass

set OPTS=--long-address --flat -b
set DEST=--m65816 -o %SOURCE%.pgx
set AUXFILES=--list=%SOURCE%.lst --labels=%SOURCE%.lbl

%TASSHOME%\64tass %OPTS% %DEST% %AUXFILES% src\%SOURCE%.s

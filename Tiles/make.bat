@echo off

REM Make sure we have up-to-date tile pixmap and color data
python ..\util\c256img.py -i src\rsrc\GameTiles.bmp

REM The name portion of the top source file and all generated files
set SOURCE=tiles

REM The location of 64TASS
set TASSHOME=d:\64tass

set OPTS=--long-address --flat -b
set DEST=--m65816 --intel-hex -o %SOURCE%.hex
set AUXFILES=--list=%SOURCE%.lst --labels=%SOURCE%.lbl

%TASSHOME%\64tass %OPTS% %DEST% %AUXFILES% src\%SOURCE%.s

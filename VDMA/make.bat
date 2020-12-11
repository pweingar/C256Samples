@echo off

REM Make sure we have up-to-date sprite pixmap and color data
REM python ..\util\c256img.py -i src\rsrc\sprite.bmp

REM The name portion of the top source file and all generated files
set SOURCE=vdma

REM The location of 64TASS
set TASSHOME=d:\64tass

set DEFINES=-D FILETYPE=0
set OPTS=--long-address --flat -b
set DEST=--m65816 --intel-hex -o %SOURCE%.hex
set AUXFILES=--list=%SOURCE%.lst --labels=%SOURCE%.lbl

%TASSHOME%\64tass %OPTS% %DEFINES% %DEST% %AUXFILES% src\%SOURCE%.s
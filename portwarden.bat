@echo off 

title Portwarden backut / decrypt / restore

rem This script will use portwarden to perform a bitwarden backup, is able to encrypt it or restore it into a blank bitwarden vault.
rem For this to work, there need to be the following files present in the same directory as this batch:
rem - portwarden.exe (https://github.com/vwxyzjn/portwarden/releases/)
rem - bw.exe (https://github.com/bitwarden/cli/releases)


rem Here we can include the password for the encryption of the backup directly in this file.
rem It will then be used for Encryption as well as decryption
rem ATTENTION!!!! ONLY use this if you have this whole deal inside an encrypted container.
rem Just insert the password after the = in the next command. Like so: 			set cryptpw1=heresmypassword

set cryptpw1=

rem check if portwarden.exe and bw.exe are present
:checkfiles
if exist "%~dp0\portwarden.exe" if exist "%~dp0\bw.exe" goto :start
echo.
echo portwarden.exe and bw.exe need to be present in the same directory this batch file is in. Please download them here:
echo https://github.com/vwxyzjn/portwarden/releases/
echo https://github.com/bitwarden/cli/releases
echo.
)
pause
goto :checkfiles

rem Ask the user what they want to do. Then jup to the respective marker
:start
echo Do you want to:
echo [1] pull a backup from the bitwarden vault?
echo [2] decrypt a .portwarden file into plain text?
echo [3] restore a .portwarden file into a blank bitwarden vault?


set /p select=[1/2/3]? 

if /I "%select%" EQU "1" goto :backup 
if /I "%select%" EQU "2" goto :decrypt
if /I "%select%" EQU "3" goto :restore

cls
echo Only select 1, 2 or 3!
echo.
goto :start

rem ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


:backup
rem This is the part where the actual backup is performed
title Portwarden Backup
cls

rem check if the cryptpw1 variable is empty. (this only matters if you have the crypt password in this file)
IF "%cryptpw1%" == "" goto :setpw

REM	Ask if we want to use the predefined Password for the encryption (this only matters if you have the crypt password in this file)
echo Do you want to use the following password to encrypt the backup?
echo.
echo %cryptpw1%
echo.
set /p defpass=[Y/N]?
if /I "%defpass%" EQU "Y" goto :pwbackup

REM	Ask for the Password with which the backup file shall be encrypted.
:setpw
set /p cryptpw1=Please enter the password with which you want to encrypt your BitWarden backup:
set /p cryptpw2=Please repeat the entered password:

REM	If the both are eqal, start the portwarden routine. If not, try again. 
if %cryptpw1% EQU %cryptpw2% goto :pwbackup

REM	We jump back to the beginning if the two encryption passwords are not equal
echo.
echo Passwords do not match. Please try again.
echo.
echo.
goto :setpw

REM	This starts the portwarden routine.
:pwbackup
%~dp0portwarden.exe --passphrase %cryptpw1% --filename backup-%date%.portwarden encrypt

rem check if the backup folder exists, if not, create it
if not exist "%~dp0\backup\" mkdir %~dp0\backup\

REM	Move the Backup to the backup folder
move "%~dp0\*.portwarden" "%~dp0\backup\"

REM	End
echo Backup complete
pause
exit

rem is this errorhandling?
echo This is an error. Please restart the script!
pause
exit



rem ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

:decrypt
rem This part decrypts an encrypted .portwarden file into plain text

Title Portwarden Decrypt
cls

REM	Let the user chose the file to decript
echo( & echo( Please choose the file you want to decrypt
set "FileName="
set pwshcmd=powershell -noprofile -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms') | Out-Null;$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $OpenFileDialog.ShowDialog()|out-null; $OpenFileDialog.FileName}"
 
rem	To get result in FileName variable
 for /f "delims=" %%I in ('%pwshcmd%') do set "FileName=%%I"
 cls
 If defined FileName (goto :contdecrypt) else (
echo No File is chosen.
pause
goto :decrypt)

:contdecrypt
echo Decrypting the following file: %filename%

rem check if cryptpw1 from the beginning is not empty (this only matters if you have the crypt password in this file)
IF "%pwempty%" == "true" goto :setdecpw

REM	Ask if we want to use the predefined Password for the encryption (this only matters if you have the crypt password in this file)
echo Do you want to use the following password to decrypt the backup?
echo.
echo %cryptpw1%
echo.
set /p defpass=[Y/N]?
if /I "%defpass%" EQU "Y" (goto :pwdecrypt) else (goto :setdecpw)

:setdecpw
set /p cryptpw1=Please enter the password you want to use to decrypt your BitWarden backup:

:pwdecrypt
portwarden --passphrase %cryptpw1% --filename %filename% decrypt

echo Decrypted file stored in same path as backup as .zip

pause
exit



rem ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



rem this is the part where we restore the backup into a blank bitwarden account
:restore

Title Portwarden Restore
cls

echo RESTORE IS EXPERIMENTAL!! YOU MAY LOSE YOUR DATA
echo IF YOU RESTORE TO YOUR MAIN ACCOUNT
echo PLEASE MAKE SURE YOU KNOW WHAT YOU ARE DOING
echo ------------------------------------------------
echo Please use a **spare** account for restoring backup
echo Portwarden doesn't handle conflicts therefore a
echo separate account is needed
echo ------------------------------------------------
echo In fact we setup a check to make sure the account your
echo are restoring to does not have any data in it
echo ------------------------------------------------

REM	Let the user chose the file to decript
echo( & echo( Please choose a file ...
set "FileName="
set pwshcmd=powershell -noprofile -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms') | Out-Null;$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $OpenFileDialog.ShowDialog()|out-null; $OpenFileDialog.FileName}"
 
rem	To get result in FileName variable
 for /f "delims=" %%I in ('%pwshcmd%') do set "FileName=%%I"
 cls
 If defined FileName (goto :rest) else (
echo No File is chosen.
pause
goto :restore

:rest
echo Restoring the following file: %filename%

rem check if cryptpw1 from the beginning is not empty (this only matters if you have the crypt password in this file)
IF "%pwempty%" == "true" goto :setrestpw

REM	Ask if we want to use the predefined Password for the encryption (this only matters if you have the crypt password in this file)
echo Do you want to use the following password to decrypt the backup?
echo.
echo %cryptpw1%
echo.
set /p defpass=[Y/N]?
if /I "%defpass%" EQU "Y" goto :pwrestore

:setrestpw
set /p cryptpw1=Please enter the password you want to use to restore your BitWarden backup:

:pwrestore
portwarden --passphrase %cryptpw1% --filename %filename% restore

echo Backup succesfully restored
pause
exit
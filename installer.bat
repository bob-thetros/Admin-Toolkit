@echo off
REM /**
REM  * Copies registry files, modifies registry settings, sets PowerShell execution policy, 
REM  * generates a self-signed certificate, runs Company installer, associates file extensions,
REM  * creates folder and copies ODT, prints message to reboot and install Veeam.
REM  */
set "filename=company.txt"
set "network_path="\\had-stars1.horiba.lcl\starsBackup"

:: Check if the file exists
if exist "%filename%" (
    for /f "usebackq delims=" %%a in ("%filename%") do set "company=%%a"
) else (
    set /p "company=Please enter the company name: "    
    echo %company% > "%filename%"
)
echo The current company name variable is: %company%
pause
echo Generating the Destination folders
set "folder=%UserProfile%\DOCUMENTS\reg"
if not exist "%folder%" (
   md "%folder%"
   echo %folder% did not exist and was created
) else (
   echo %folder% already exists
)
 set "folderScripts=c:\scripts"
rem echo %folderScripts%
if not exist "%folderScripts%" (
   md "%folderScripts%"
   md "%folderScripts%\%company%"
   echo %folderScripts% did not exist and was created
) else (
   echo %folderScripts% already exists
) 
 set "folderlgpo=c:\scripts\lgpo"
rem echo %folderlgpo%
if not exist "%folderlgpo%" (
   md "%folderlgpo%"
   echo %folderlgpo% did not exist and was created
) else (
   echo %folderlgpo% already exists
) 
rem echo %UserProfile%\%company%-Fonts
if not exist "%UserProfile%\%company%-Fonts" (
   md %UserProfile%\%company%-Fonts
   echo %UserProfile%\%company%-Fonts did not exist and was created
) else (
   echo %UserProfile%\%company%-Fonts already exists
) 
rem echo %UserProfile%\%company%-Wallpaper
if not exist "%UserProfile%\%company%-Wallpaper" (
    md %UserProfile%\%company%-Wallpaper
   echo %UserProfile%\%company%-Wallpaper did not exist and was created
) else (
    echo %UserProfile%\%company%-Wallpaper already exists
) 
if not exist "%UserProfile%\%company%" (
   md %UserProfile%\%company%
   echo %UserProfile%\%company% did not exist and was created
) else (
   echo %UserProfile%\%company% already exists
) 
if not exist "%UserProfile%\ODT" (
    md %UserProfile%\ODT
    echo %UserProfile%\ODT did not exist and was created
) else (
   echo %UserProfile%\ODT already exists
)
if exist "D:\" (  
  if not exist "D:\Troubleshooting" (
    md D:\Troubleshooting
    echo D:\Troubleshooting did not exist and was created
  ) else (
   echo D:\Troubleshooting already exists
  )
  if not exist "D:\STARSData" (
    md D:\STARSData
    echo D:\STARSData did not exist and was created
  ) else (
   echo D:\STARSData already exists
  )
  if not exist "D:\STARSApps" (
    md D:\STARSData
    echo D:\STARSData did not exist and was created
  ) else (
   echo D:\STARSData already exists
  )
)
pause
:start
echo Select installation source:
echo 1 - Install from A drive
echo 2 - Install from USB drive
set /p source="Enter 1 or 2: "

if "%source%"=="1" goto installA
if "%source%"=="2" goto installUSB

echo Invalid input 
goto start

:installA
echo Installing from A drive... If prompted for File or Directory select F for File.
:loop
if EXIST a:\NUL goto AMOUNTED
echo a is not mounted, attempting to mount
:: 1. Prompt for Username
set /p "user_name=Enter Username: "

:: 2. Prompt for Password
:: NOTE: The password will be visible on the screen as you type!
set /p "password=Enter Password: "

echo.
echo Attempting to map Drive A: to %network_path%...

:: 3. Execute the mapping command
:: /persistent:no ensures the drive is removed when you log out/restart
net use A: "%network_path%" %password% /user:"%user_name%" /persistent:no >nul 2>&1
echo Ctrl C to abort if you don't have A Drive mapped...
goto doPing
:doPing
goto :loop
:AMOUNTED

pause
rem Run installation commands from A drive
set usbDrive=A:\Preinstall\
xcopy /s /Y /D A:\Preinstall\reg\*.reg %UserProfile%\DOCUMENTS\reg
xcopy /s /Y /D A:\Preinstall\Scripts\*.* c:\scripts\HORIBA
xcopy /s /Y /D A:\Preinstall\fonts\*.fon %UserProfile%\HORIBA-Fonts
xcopy /s /Y /D A:\Preinstall\fonts\*.ttf %UserProfile%\HORIBA-Fonts
xcopy /s /Y /D A:\Preinstall\Wallpaper\*.jpg %UserProfile%\HORIBA-Wallpaper
xcopy /s /Y /D A:\Preinstall\toolbar\*.* %UserProfile%\HORIBA 
xcopy /s /Y /D A:\Preinstall\lgpo\*.* c:\lgpo
xcopy /s /Y /D A:\Preinstall\lgpo\*.* c:\LGPO
xcopy /s /Y /D A:\Preinstall\\ODT\*.* %UserProfile%\ODT
copy /Y A:\Preinstall\GenerateSelfSigning.ps1 c:\scripts\GenerateSelfSigning.ps1
copy /Y A:\Preinstall\Apps\STARSTroubleshootingTool2.1.zip d:\Troubleshooting
$
goto RegiserKeys

:installUSB 
set "usbDrive="
set "idx=-1"
for /f "tokens=2 delims==:" %%i in ('wmic logicaldisk where "drivetype=2" get DeviceID /value') do set "usbDrive=USB Drive leters available:%%i"&set /a "idx+=1"

echo %usbDrive%
set /p usbDrive="Enter the USB drive letter:"

if not exist %usbDrive%: (
  echo USB drive %usbDrive% not found
  goto start 
)

xcopy /s /Y /D %usbDrive%:\reg\*.reg %UserProfile%\DOCUMENTS\reg
xcopy /s /Y /D %usbDrive%:\Scripts\*.* c:\scripts\HORIBA
xcopy /s /Y /D %usbDrive%:\fonts\*.fon %UserProfile%\HORIBA-Fonts
xcopy /s /Y /D %usbDrive%:\fonts\*.ttf %UserProfile%\HORIBA-Fonts
xcopy /s /Y /D %usbDrive%:\Wallpaper\*.jpg %UserProfile%\HORIBA-Wallpaper
xcopy /s /Y /D %usbDrive%:\toolbar\*.* %UserProfile%\HORIBA 
xcopy /s /Y /D %usbDrive%:\lgpo\*.* c:\lgpo
xcopy /s /Y /D %usbDrive%:\ODT\*.* %UserProfile%\ODT

:RegiserKeys
REM modify registry settings so that the UAC prompt does not appear when installing and the A drive is available as a network drive to admin and non-admin users
reg import "%UserProfile%\DOCUMENTS\reg\EnableLinkedConnections.reg"
reg import "%UserProfile%\DOCUMENTS\reg\TrustedLocations.reg"
reg import "%UserProfile%\DOCUMENTS\reg\Toolbars_HORIBA.reg"
reg import "%UserProfile%\DOCUMENTS\reg\ps1-assos.reg"
reg import "%UserProfile%\DOCUMENTS\reg\APCStarsShutdown.reg"
reg import "%UserProfile%\DOCUMENTS\reg\TrustVBProjects.reg"
REM Patch
echo 'Installing Windows Patches .. This takes a few minutes be patient.'
call "%usbDrive%:\LTSC-Updates\Install-Patches.bat"
REM Allow PowerShell scripts to run
powershell set-executionpolicy unrestricted
REM Generate self-signed certificate for use with HORIBA scripts
powershell c:\Scripts\GenerateSelfSigning.ps1 %usbDrive%
powershell set-executionpolicy AllSigned
copy /Y C\Scripts\Preinstaller.ps1 c:\scripts\%company%installer.ps1

REM Run HORIBA installer
powershell c:\Scripts\c:\scripts\%company%installer.ps1 %usbDrive%
REM Now only allow PowerShell scripts to run that are signed with the locally signed certificate.
powershell set-executionpolicy allsigned
REM Power management for video off
powercfg.exe /setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0
powercfg.exe /setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOCONLOCK 0
REM Associate file extensions with applications
if exist "C:\Program Files\uvnc bvba\UltraVNC\vncviewer.exe" (  
  Ftype VncViewer.Config=C:\Program Files\uvnc bvba\UltraVNC\vncviewer.exe %1
  assoc .vnc="C:\Program Files\uvnc bvba\UltraVNC\vncviewer.exe"
)
Ftype VncViewer.Config=C:\Program Files\uvnc bvba\UltraVNC\vncviewer.exe %1
if exist "C:\Program Files\Notepad++\notepad++.exe" (  
  Ftype txtfile=C:\Program Files\Notepad++\notepad++.exe %1
  assoc .xml="C:\Program Files\Notepad++\notepad++.exe"
)
if exist "C:\Windows\System32\WindowsPowerShell\v1.0\powershell_ise.exe" (  
  Ftype ps1file=C:\Windows\System32\WindowsPowerShell\v1.0\powershell_ise.exe %1
  assoc .ps1="C:\Windows\System32\WindowsPowerShell\v1.0\powershell_ise.exe"
)
pause
if exist "D:\" (  
  xcopy /s /Y /D %usbDrive%:apps\STARSTroubleshootingTool2.2.zip d:\Troubleshooting
  PowerShell c:\scripts\HORIBA\TroubleShooter2Desktop.ps1 %usbDrive%
)
echo reboot to complete
pause

@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

choco install kitty 7zip virtualbox -y

setlocal
:PROMPT
SET /P AREYOUSURE=Do you want to install developer tools (Y/[N])?
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END




:END
endlocal

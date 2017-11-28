$GawatiOSURL = "https://gawati.org/GawatiVM.7z"

$ZIPFile = "$Env:USERPROFILE\Downloads\GawatiVM.7z"
(New-Object System.Net.WebClient).DownloadFile($GawatiOSURL,$ZIPFile)

Start-Process "$Env:ProgramFiles\7-Zip\7z.exe" -Wait -ArgumentList "x -o""$Env:USERPROFILE\VirtualBox VMs"" ""$ZIPFile"""

VBoxManage registervm "$Env:USERPROFILE\VirtualBox VMs\Gawati\Gawati.vbox"

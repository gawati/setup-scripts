Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$InstallScript="gawati_devsetup.sh"

$BOXNAME="Gawati"
$SNAPNAME=$BOXNAME + "_Snap"
$TESTNAME=$BOXNAME + "_CITest"
$GAWATIHOST="my.gawati.local"
$LOG=$Env:TEMP + "\cisetup_gawati_" + (get-date).toString(‘yyyyMMddHHmm’) + ".log"


function WaitForVM {
  $i=0
  while ( -not ( Test-Connection $GAWATIHOST -count 1 -quiet )) {
    $i++
    echo "Waiting for VM to come up: $i"
    }
  Start-Sleep 3
  }


#VBoxManage snapshot $BOXNAME list
VBoxManage snapshot $BOXNAME showvminfo $SNAPNAME
if ($?) { VBoxManage snapshot $BOXNAME delete $SNAPNAME }
VBoxManage snapshot $BOXNAME take $SNAPNAME
VBoxManage clonevm $BOXNAME --snapshot $SNAPNAME --options link --options keepallmacs --name $TESTNAME --register
VBoxManage startvm $TESTNAME --type headless

WaitForVM


#kitty -pw MyGawatiLocal -ssh root@my.gawati.local -m scripts\gawati_devsetup.sh -log $LOG
#cmd /c start powershell -Command "& { Get-Content -Path $LOG -Wait }"

Get-Command -Module Posh-SSH

$GAWATIHOST="my.gawati.local"
$SSHusr = "root"
$SSHpwd = ConvertTo-SecureString "MyGawatiLocal" -AsPlainText -Force
$SSHcred = New-Object System.Management.Automation.PSCredential ($SSHusr, $SSHpwd)

$SSHsession = New-SSHSession -ComputerName $GAWATIHOST -Credential $SSHcred -Force

$SSHlog = ""

Get-Content $InstallScript | ForEach-Object {
  $SSHresult = Invoke-SSHCommand -SSHSession $SSHsession -Timeout 600 -Command $_
  $SSHlog += $SSHresult.Output | Out-String
  }

Remove-SSHSession -SSHSession $SSHsession -Verbose

$line = $SSHlog -split "`r`n|`r|`n"

$XSTSTPWD = $line | Select-String -Pattern 'Admin Password of existDB instance eXist-st:' -ca | select -exp line
$MONITPWD = $line | Select-String -Pattern 'Admin Password for user >admin< on monit webinterface:' -ca | select -exp line

$XSTSTPWD = $XSTSTPWD.Substring(46,10)
$MONITPWD = $MONITPWD.Substring(56,10)

Write-Host "-----------------------------------------------------------------------------------------"
Write-Host "Please note, your admin password for eXist DB is >$XSTSTPWD<."
Write-Host "Please note, your admin password for monit is >$MONITPWD<."
Write-Host "-----------------------------------------------------------------------------------------"

pause

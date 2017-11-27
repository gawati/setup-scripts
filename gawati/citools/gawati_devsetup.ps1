$BOXNAME="Gawati"
$SNAPNAME=$BOXNAME + "_Snap"
$TESTNAME=$BOXNAME + "_CITest"
$GAWATIHOST="my.gawati.local"
$LOG=$Env:TEMP + "\cisetup_gawati.log"

#VBoxManage snapshot $BOXNAME list
VBoxManage snapshot $BOXNAME showvminfo $SNAPNAME
if (-not $?) { VBoxManage snapshot $BOXNAME take $SNAPNAME }
VBoxManage clonevm $BOXNAME --snapshot $SNAPNAME --options link --options keepallmacs --name $TESTNAME --register
VBoxManage startvm $TESTNAME --type headless

for ($i=0; $i -le 60; $i++) { ping $GAWATIHOST -w 1000 -n 1 }

kitty -pw MyGawatiLocal -ssh root@my.gawati.local -m gawati_devsetup.sh -log $LOG -send-to-tray 
cmd /c start powershell -Command "& { Get-Content -Path $LOG -Wait }"

while ($?) { ping $GAWATIHOST -w 1000 -n 2 | Out-Null; }

$XSTSTPWD = Select-String -Path $LOG -Pattern 'Admin Password of existDB instance eXist-st:' -ca | select -exp line
$MONITPWD = Select-String -Path $LOG -Pattern 'Admin Password for user >admin< on monit webinterface:' -ca | select -exp line

$XSTSTPWD = $XSTSTPWD.Substring(46,10)
$MONITPWD = $MONITPWD.Substring(56,10)

# edit hosts file: 192.168.56.101  my.gawati.local

for ($i=0; $i -le 60; $i++) { ping $GAWATIHOST -w 1000 -n 1 }

#kitty -pw MyGawatiLocal -ssh root@my.gawati.local -L 10443:localhost:10443

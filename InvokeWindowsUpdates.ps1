#Invoke Windows Update Installation
#Schedules installation of all available updates, with automatic reboot

#Targets should be a txt or csv file containing list of computers needing install
$Targets = (Get-Content C:\Dev\Targets.txt)

#TriggerDate should be set to a time outside of business hours, when updates can install and automatically reboot
#for immediate run of updates, change -triggerdate to -runnow 
$triggerDate = (Get-Date -Hour 22 -Minute 0 -Second 0)
$PSWUModulePath = "\\$PC\C$\Program Files\WindowsPowerShell\Modules\PSWindowsUpdate"
$Modulesource = "D:\PSWindowsUpdate"
Foreach($PC in $Targets) {
Write-Host "Working on $PC"
If(!(Test-path $PSWUModulePath)){
    Copy-Item $Modulesource -destination $PSWUModulePath -recurse -Force
    Start-Sleep -Seconds 10
    }

If(Test-path $PSWUModulePath){

Invoke-command -computername $PC -scriptBlock {set-executionpolicy bypass | import-module PSWindowsUpdate | Invoke-WUJob -Script "ipmo PSWindowsUpdate; Install-WindowsUpdate -AcceptAll -Autoreboot | Out-File \\FS\Share02\WSUS\PSWindowsUpdate_$PC.log" -triggerdate (Get-Date -Hour 22 -Minute 0 -Second 0) -Force}
}
elseif(!(Test-path $PSWUModulePath)){write-host "Module does not exist on client $PC"}
}
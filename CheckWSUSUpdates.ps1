#List of Computers
$Computers = Get-Content "\\fs\Share02\Automation-Resources\Scripts\Reboot\RebootTargets.txt"

Write-Host "Running Command" -ForegroundColor Green
Foreach ($Computer in $Computers)
{
    Write-Host $Computer
    #uncomment STARTSCAN line to run a scan for updates and download any available
    #Invoke-Command -ComputerName $Computer -ScriptBlock{C:\Windows\system32\usoclient StartScan}
    #uncomment SCANINSTALLWAIT line to run a scan for updates and download any available
    Invoke-Command -ComputerName $Computer -ScriptBlock{C:\Windows\system32\usoclient scaninstallwait}
    #uncomment STARTINSTALL line to install updates
    #Invoke-Command -ComputerName $Computer -ScriptBlock{C:\Windows\system32\usoclient startinstall}
    #uncomment RESTARTDEVICE to restart client and install updates
    #Invoke-Command -ComputerName $Computer -ScriptBlock{C:\Windows\system32\usoclient restartdevice}
}
Function Run-AdobeSerialization{
<#
.SYNOPSIS
    This script runs the Adobe pro Serialization.

.DESCRIPTION
    After dropping the LicenseFix onto the computer, this script will run the serialzation for you.
    Compiled by Christopher Catron
    Compiled date 11/8/2019
    Last revision date 11/8/2019
    Last revision date 11/13/2019 LGS
    Changed copy and remove destination folders to C:\NEC

.EXAMPLE
    Run-AdobeSerization LEEEWKCASPCIO15, LEEENBCASP10120 
    Run-AdobeSerization LEEENBSCTC00006, LEEENBCASPBL105
    Press ENTER and it will run the file.
    If no computer is identified upon running it, the script will ask for the names and use the names provided to check the information.
    If only one system is required hit enter and then enter again and the script will run.
#>
[cmdletbinding()]
            param(
                [Parameter(Mandatory=$True,
                                    Helpmessage='Enter Computer name',
                                    Valuefrompipelinebypropertyname=$true,
                                    valuefrompipeline=$true)]
                [Alias('cn')]
                [string[]]$computers
            )
$FS = "\\fs\share02\Patches\Adobe\LicenseFix\"
$NECfile = "LicenseFix"
foreach($computer in $computers)
    {    
    Set-Service -Name WinRM -ComputerName $computer -StartupType Automatic -Status Running
    Start-Service -Name WinRM
    write-host "$computer - Please wait while I remove and read the serial number"   
    Invoke-Command -ComputerName $computer -ScriptBlock {start Winrm quickconfig}
    Copy-Item "$NEC\$NECfile" -Destination "\\$computer\C$\NEC" -recurse -container -Force    
    Invoke-Command -ComputerName $computer -ScriptBlock {Start-Process "C:\NEC\LicenseFix\RemoveVolumeSerial.exe" -wait}
    Write-host "                     Serial Number Removed"
    Invoke-Command -ComputerName $computer -ScriptBlock {Start-Process "C:\NEC\LicenseFix\AdobeSerialization.exe" -wait}
    Write-host "                     Serial Number Added"
    #Copy-Item "$NEC\$Software\$NECfile\AdobeSerialization.txt" -Destination "\\$computer\C$\Program Files (x86)\Adobe\Acrobat DC\"
    Copy-Item "$NEC\$NECfile\AdobeSerialization.txt" -Destination "\\$computer\C$\Program Files (x86)\Adobe\Acrobat DC\"
    write-host "                     AdobeSerialization.txt copied to Program Files (x86)"
    Remove-Item -Path "\\$computer\C$\NEC\Licensefix" -Force
    Write-Host "Serialization complete. Test program now."
    }
}
CLS
Run-AdobeSerialization
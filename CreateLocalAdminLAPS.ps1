# Create Local Administrator Account with randomized password for use with LAPS
# Author: Joshua Lambert
# Revision: 22JUNE2020 - Initial Draft

Add-Type -AssemblyName System.web
$NewLocalAdmin = "SECLAN001"
$minLength = 14 ## characters
$maxLength = 15 ## characters
$length = Get-Random -Minimum $minLength -Maximum $maxLength
$nonAlphaChars = 5
$clearPW = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars)
$secPw = ConvertTo-SecureString -String $clearPW -AsPlainText -Force
if(!(Test-Path 'C:\program files\laps')){
     msiexec.exe /i \\fs\Share02\LAPS\LAPS.x64.msi /quiet
}
If(!(Get-LocalUser $NewLocalAdmin)){
    New-LocalUser "$NewLocalAdmin" -Password $secPW -FullName "$NewLocalAdmin" -Description "Emergency local admin - LAPS managed password"
    Write-Verbose "$NewLocalAdmin local user crated"
    Add-LocalGroupMember -Group "Administrators" -Member "$NewLocalAdmin"
    Write-Verbose "$NewLocalAdmin added to the local administrator group"
}
Else
{}
 

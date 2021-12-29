$Targets = (Get-Content C:\dev\targets.txt)
$temppath = "\\$PC\c$\temp\"
$binpath = "\\fs\Share02\Patches\Microsoft\BootHole\content.bin"
$sigpath = "\\fs\Share02\Patches\Microsoft\BootHole\signature.p7"


Foreach($PC in $Targets){
Write-host "Working on $PC"

Invoke-Command -ComputerName $PC -ScriptBlock {Suspend-BitLocker -MountPoint $env:SystemDrive -rebootcount 1}
    
Write-Host "Suspending BitLocker on $PC"

If(!(Test-Path $temppath)){
mkdir -Path $temppath

}
copy-item $binpath $temppath
Copy-Item $sigpath $temppath
}
sleep -Seconds 15
Invoke-Command -ComputerName $PC -ScriptBlock{
Set-SecureBootUefi -Name dbx -ContentFilePath C:\temp\content.bin -SignedFilePath C:\temp\signature.p7 -Time 2010-03-06T19:17:21Z -AppendWrite
}


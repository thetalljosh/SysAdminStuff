$List = get-content "C:\Dev\targets2.txt"
foreach($PC in $List){
write-host "Starting work on $PC"
write-host "Copying file to $PC"
Copy-Item  -path "\\fs\share02\MicrosoftSoftware\SSMS-Setup-ENU.exe" -destination "\\$PC\C$\Temp\SSMS-Setup-ENU.exe" -Force
sleep -Seconds 30
    if(Test-Path "\\$PC\C$\Temp\SSMS-Setup-ENU.exe"){
        invoke-command -ComputerName $PC -ScriptBlock {start-process "C:\Temp\SSMS-Setup-ENU.exe" -argumentList '/install /quiet /norestart'}
        write-host "waiting 60 seconds for install on $PC"
        sleep -Seconds 300
        if((Get-Item -Path "\\$PC\C$\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe").VersionInfo.ProductVersion -ge "15.0.18369.0"){
        Write-Host "Update installed on $PC"
        }
        else{write-host "Update failed on $PC"}
    }
}
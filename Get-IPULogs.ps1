$searchBase = read-host "Enter OU SearchBase"

if(!(test-path "C:\temp\ipulogs")){
new-item "C:\temp\IPULogs" -ItemType Directory
}

$List = Get-ADComputer -SearchBase $searchBase -filter {enabled -eq $true} -properties OperatingSystemVersion
foreach ($System in $List) {

    $sysName = $System.name.tostring()
   
    if($System.OperatingSystemVersion -eq "10.0 (19042)" -or $System.OperatingSystemVersion -eq "10.0 (18363)"){
    
        if (!(test-path "\\$sysname\C$\ProgramData\Armylocal\IPULogs\IPULogs.zip")){
        Write-Host "IPULogs.zip does not exist on target: $sysName" -ForegroundColor Red
        }  
        else{
        write-host "IPU logs found on " $sysName " copying to local system at ""C:\Temp\IPULogs\$sysname\IPULogs.zip"
        new-item "C:\Temp\IPULogs\$sysname" -ItemType Directory
        copy-item "\\$sysname\C$\ProgramData\Armylocal\IPULogs\IPULogs.zip" -Destination "C:\Temp\IPULogs\$sysname\IPULogs.zip"
        }
   
    }
    else{ write-host $sysName "does not meet criteria. Operating system version is: " $system.OperatingSystemVersion}  

} 
 
try{
$BitlockerVol = Get-BitLockerVolume -MountPoint $env:SystemDrive
        $KPID=""
        foreach($KP in $BitlockerVol.KeyProtector){
            if($KP.KeyProtectorType -eq "RecoveryPassword"){
                $KPID=$KP.KeyProtectorId
                break;
            }
        }
       $output = BackupToAAD-BitLockerKeyProtector -MountPoint "$($env:SystemDrive)" -KeyProtectorId $KPID
return $true
}
catch{
     return $false
}

<#
1. Sign-in to the Microsoft Endpoint Manager admin center portal. 
2. Browse to Devices – Windows – PowerShell Scripts
3. Click on Add
4. Give a Name
5. Select the script
6. Set Run this script using the logged on credentials as No
7. Set Enforce script signature check to No
8. Set Run script in 64 bit PowerShell Host as Yes
9. Deploy to the user\device based group.
#>

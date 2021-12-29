$TPM = Get-WmiObject win32_tpm -Namespace root\cimv2\security\microsofttpm | where {$_.IsEnabled().Isenabled -eq 'True'} -ErrorAction SilentlyContinue
$WindowsVer = Get-WmiObject -Query 'select * from Win32_OperatingSystem where (Version like "6.2%" or Version like "6.3%" or Version like "10.0%") and ProductType = "1"' -ErrorAction SilentlyContinue
$BitLockerReadyDrive = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue

 
#If all of the above prequisites are met, then create the key protectors, then enable BitLocker and backup the Recovery key to AD.
if ($WindowsVer -and $TPM -and $BitLockerReadyDrive) {
 
#Creating the recovery key
Add-BitLockerKeyProtector -MountPoint 'C:' -RecoveryPasswordProtector
 
#Adding TPM key
Add-BitLockerKeyProtector -MountPoint 'C:' -TpmProtector
sleep -Seconds 15 #This is to give sufficient time for the protectors to fully take effect.
 
#Enabling Encryption
#Write-Host "Attempting to enable BitLocker"
manage-bde.exe -on 'C:' 
 
#Getting Recovery Key GUID and Backing up
#$RecoveryKeyGUID = (Get-BitLockerVolume -MountPoint $env:SystemDrive).keyprotector | where {$_.Keyprotectortype -eq 'RecoveryPassword'} | Select-Object -ExpandProperty KeyProtectorID

#manage-bde.exe  -protectors $env:SystemDrive -adbackup -id $RecoveryKeyGUID

#Microsoft-recommended key backup process
$BLV = Get-BitLockerVolume -MountPoint 'C:'
Backup-BitLockerKeyProtector -MountPoint 'C:' -KeyProtectorId $BLV.KeyProtector[1].KeyProtectorId 

#Restarting the computer, to begin the encryption process
Restart-Computer -Force
}
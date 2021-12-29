set-executionpolicy bypass 
Install-PackageProvider -Name NuGet -force 
If (Get-Module -ListAvailable -Name DellBIOSProvider)
   {write-host "DellBIOSProvider found on $env:COMPUTERNAME"} 
  Else
   {
   write-host "Installing DellBIOSProvider on $env:COMPUTERNAME"
   Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
   Install-Module -Name DellBIOSProvider -Force 
   }
  #get-command -module DellBIOSProvider | out-null
  Import-Module DellBIOSProvider
write-host "Setting Dell WakeOnLan and AutoOn Settings"
si DellSmbios:\PowerManagement\WakeOnLan LanOnly
si dellsmbios:\powermanagement\autoon everyday
si dellsmbios:\powermanagement\autoonhr 01
si dellsmbios:\powermanagement\autoonmn 00

write-host "Writing Dell WakeOnLan and AutoOn settings to log at C:\DellBiosSettings.log"
dir DellSmbios:\PowerManagement\WakeOnLan >> C:\DellBiosSettings.log
dir dellsmbios:\powermanagement\autoon >> C:\DellBiosSettings.log
dir dellsmbios:\powermanagement\autoonhr >> C:\DellBiosSettings.log
dir dellsmbios:\powermanagement\autoonmn >> C:\DellBiosSettings.log


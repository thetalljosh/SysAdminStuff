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

  si DellSmbios:\SecureBoot\SecureBoot enabled
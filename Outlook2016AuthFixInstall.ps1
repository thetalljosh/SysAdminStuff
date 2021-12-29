$list = ('AZURW4FH11WKJLT')
$officePath = "\\$PC\C$\Program Files (x86)\Microsoft Office\Office16"
$remoteTempPath = "\\$PC\C$\Temp"
$patchOnShare = "\\fs\Share02\Patches\Microsoft\Outlook\outlook2016-kb3115147-fullfile-x86-glb.exe"
foreach($PC in $List){

if(test-path $officePath){
write-host "$PC has office 2016 - proceeding to attempt patch install"
    if(!(Test-Path $remoteTempPath)){
    #write-host "Creating temp directory on $PC"
        new-item $remoteTempPath -ItemType Directory}
        
            Copy-Item $patchOnShare $remoteTempPath\patch.exe
            sleep -Seconds 15
          #  write-host "Patch copied to local machine, sending install command to $PC"
            invoke-command -computerName $PC -scriptBlock {Start-Process C:\temp\patch.exe -argumentlist '/quiet /norestart' -wait}

           # write-host "Writing reg keys to $PC"
            invoke-command -computerName $PC -scriptBlock {new-itemproperty "HKCU:\Software\Microsoft\Exchange" -name "AlwaysUseLegacyAuthForAutodiscover" -Value 1 -Type DWORD -Force}
            invoke-command -computerName $PC -scriptBlock {new-itemproperty "HKCU:\Software\policies\Microsoft\Office\16.0\Outlook\RPC" -name "EnableSmartCard" -Value 1 -Type DWORD -Force}
            }
            }

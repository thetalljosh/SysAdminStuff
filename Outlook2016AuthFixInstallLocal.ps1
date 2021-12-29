$officePath = "C:\Program Files (x86)\Microsoft Office\Office16"
$TempPath = "C:\Temp"
$patchOnShare = "\\fs\Share02\Patches\Microsoft\Outlook\outlook2016-kb3115147-fullfile-x86-glb.exe"

 if(!(Test-Path $TempPath)){
    new-item $TempPath -ItemType Directory}
    Copy-Item $patchOnShare $TempPath\patch.exe
    sleep -Seconds 15

    if(test-path $tempPath\patch.exe){
        Start-Process C:\temp\patch.exe -argumentlist '/quiet /norestart' -wait

        new-itemproperty "HKCU:\Software\Microsoft\Exchange" -name "AlwaysUseLegacyAuthForAutodiscover" -Value 1 -Type DWORD -Force
        new-itemproperty "HKCU:\Software\policies\Microsoft\Office\16.0\Outlook\RPC" -name "EnableSmartCard" -Value 1 -Type DWORD -Force
       }    
   
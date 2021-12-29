$dir = "C:\!Windows_Upgrade\packages\"
If(!(test-path $dir)){
mkdir $dir -Force
}
$webClient = New-Object System.Net.WebClient
$url = 'https://go.microsoft.com/fwlink/?LinkID=799445'
$file = "$($dir)\Win10Upgrade.exe"
if(!(Test-Path $file)){
$webClient.DownloadFile($url,$file)
}
Start-Sleep -Seconds 15
if(!(Test-Path $file)){
start-sleep -Seconds 15
}
else{
start-process $file -argumentlist "/quietinstall /skipeula /auto upgrade /telemetry disable /showoobe none /copylogs $dir" -wait
#if(!(Get-Process -Name Windows10UpgraderApp.exe)){start-process "C:\Windows10Upgrade\Windows10UpgraderApp.exe" -ArgumentList "/Passive" -wait}
rmdir $dir -Force -recurse
}
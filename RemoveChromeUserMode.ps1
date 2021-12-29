foreach ($Folder in (gci c:\users\)){
$path = $Folder.fullname
#write-host $path
if (test-path "$Path\AppData\local\Google\Chrome\Application\"){
start-process "$Path\AppData\local\Google\Chrome\Application\installer\setup.exe" -ArgumentList '-uninstall -multi-install -chrome -force-uninstall -delete-profile' -wait
del "$Path\AppData\local\Google\Chrome" -Force -Recurse
}
}
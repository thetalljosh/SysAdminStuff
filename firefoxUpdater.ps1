$host.ui.RawUI.WindowTitle = "Firefox Updater”

#CheckFirefox 
Write-Host "Checking FireFox versions available..."
$FirefoxLatestVersion = ( Invoke-WebRequest  "https://product-details.mozilla.org/1.0/firefox_versions.json" -UseBasicParsing | ConvertFrom-Json ).LATEST_FIREFOX_VERSION
$FirefoxLatestESR = ( Invoke-WebRequest  "https://product-details.mozilla.org/1.0/firefox_versions.json" -UseBasicParsing | ConvertFrom-Json ).FIREFOX_ESR

Write-Host "The Latest Rolling Release of Firefox is $FirefoxLatestVersion. The Latest ESR version is $FirefoxLatestESR" -ForegroundColor Green


write-host "Getting path of installed Firefox directly from Windows registry." -ForegroundColor Green


$firefoxinstalled = test-path("HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe")
if($firefoxinstalled){

foreach($queryresult in (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe" -Name Path)) {
     
    if ($queryresult) {
        $FirefoxFolder = $queryresult.path
        Write-Host "Firefox installed at $FirefoxFolder" -ForegroundColor Green}


}
}


#installLatestFF 

If(test-path "$FirefoxFolder\firefox.exe"){
$existingversion = ((get-item -path "$FirefoxFolder\firefox.exe").versioninfo.fileversion)
write-host "Current firefox version is $existingversion" -ForegroundColor Green

if($existingversion -eq $FirefoxLatestVersion) {
write-host "Latest Firefox version $existingversion installed. No further action required at this time." -ForegroundColor Green
Exit
}

}

elseif(!(Test-Path "$FirefoxFolder\firefox.exe")){Write-Host "Firefox is not currently installed. Proceeding with new installation." -ForegroundColor Yellow}

$tempfolder = "C:\FFTemp\"
$source = "$tempfolder\FFCurrVersion.exe"
new-item -itemtype directory -path $tempfolder -force

Write-Host "Please select FireFox version. Enter 0 for ESR or 1 for latest version, or" -NoNewline -ForegroundColor Cyan
Write-Host "[CTRL+C] " -ForegroundColor Yellow -NoNewline
Write-Host "to exit: " -NoNewline -ForegroundColor Cyan

$RollingOrESR = Read-host 

If($RollingOrESR = "0"){
    $installme = $FirefoxLatestESR
    $URI = "https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=win64&lang=en-US"
}
if($RollingOrESR = "1"){
    $installme = $FirefoxLatestVersion
    $URI = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
}

write-host "Downloading Firefox Version $installme..." -ForegroundColor Green
Invoke-WebRequest -URI $URI -OutFile $source 
write-host "Installing Firefox Version $installme, please wait..." -ForegroundColor Green
Start-Process $source -ArgumentList "/s" -Wait

$firefoxinstalled = test-path("HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe")
if($firefoxinstalled){

foreach($queryresult in (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe" -Name Path)) {
     
    if ($queryresult) {
        $FirefoxFolder = $queryresult.path
        Write-Host "Firefox installed at $FirefoxFolder" -ForegroundColor Green}


}
}

$newversion = ((get-item -path "$FirefoxFolder\firefox.exe").versioninfo.FileVersion)
if($newversion -eq $installme) {
write-host "Update Check Complete. You now have Firefox version $newversion" -ForegroundColor Green
}
else{Write-Host "Installation error, please contact your system administrator" -ForegroundColor Red}
write-host "Cleaning Up!" -ForegroundColor Green
if(test-path $tempfolder){rmdir $tempfolder -Force -Recurse}


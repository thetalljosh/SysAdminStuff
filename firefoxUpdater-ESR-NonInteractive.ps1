$host.ui.RawUI.WindowTitle = "Firefox Updater”

#CheckFirefox 
$FirefoxVersion = ( Invoke-WebRequest  "https://product-details.mozilla.org/1.0/firefox_versions.json" -UseBasicParsing | ConvertFrom-Json ).FIREFOX_ESR
#Write-Host "The ESR Release of Firefox is version $FirefoxVersion."

#write-host "Get path of installed Firefox directly from Windows registry."
$firefoxinstalled = test-path("HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe")
if($firefoxinstalled -eq $true){

foreach($queryresult in (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe" -Name Path)) {
     
    if ($queryresult) {
        $FirefoxFolder = $queryresult.path}


}
}


#installLatestFF 
$existingversion = ((get-item -path "$FirefoxFolder\firefox.exe").versioninfo.fileversion)
#write-host "Current firefox version is $existingversion"
if($existingversion -eq $FirefoxVersion) {
#write-host "Latest Firefox version $existingversion installed"
}
else{
$tempfolder = "C:\FFTemp\"
$source = "$tempfolder\FF_ESRVersion.exe"
new-item -itemtype directory -path $tempfolder -force

#write-host "Downloading Firefox Version $FirefoxVersion..."
Invoke-WebRequest -URI "https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=win64&lang=en-US" -OutFile $source 
#write-host "Installing Firefox Version $FirefoxVersion, please wait..."
Start-Process $source -ArgumentList "/s" -Wait
}
$newversion = ((get-item -path "$FirefoxFolder\firefox.exe").versioninfo.FileVersion)
if($newversion -eq $FirefoxVersion) {
new-item -ItemType File -Path "$FirefoxFolder\" -Name "$newversion.ccm"
#write-host "Update Check Complete. You now have Firefox version $newversion"
}
else{}#Write-Host "Installation error, please contact your system administrator"}
#write-host "Cleaning Up!"
if(test-path $tempfolder){rmdir $tempfolder -Force -Recurse}


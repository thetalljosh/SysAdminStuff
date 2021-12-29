#Check for Chrome on the PC first

if(Test-Path "c:\program files (x86)\google\chrome\application"){
$chromeMSI = "http://dl.google.com/edgedl/chrome/install/GoogleChromeStandaloneEnterprise.msi"
$output = "c:\temp\chrome.msi"

taskkill /im chrome.exe -f

Invoke-WebRequest -Uri $chromeMSI -OutFile $output -ErrorAction SilentlyContinue

msiexec /q /i c:\temp\chrome.msi

start-sleep -Seconds 300

Remove-Item -Path c:\temp\chrome.msi -Force

}
elseif(Test-Path "c:\program files\google\chrome\application"){
$chromeMSI = "http://dl.google.com/edgedl/chrome/install/GoogleChromeStandaloneEnterprise64.msi"
$output = "c:\temp\chrome.msi"

taskkill /im chrome.exe -f

Invoke-WebRequest -Uri $chromeMSI -OutFile $output -ErrorAction SilentlyContinue

msiexec /q /i c:\temp\chrome.msi

start-sleep -Seconds 300

Remove-Item -Path c:\temp\chrome.msi -Force

}

else

{

}




# Get Current Adobe reader version from the registry
$CurrentReaderVersion = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Where-Object{$_.DisplayName -like "*Adobe*" -and $_.DisplayName -like "*Acrobat DC*"}

# If reader is installed then...
If ($CurrentReaderVersion -ne $null) {

# Tidy version to numeric string.
$CurrentReaderVersion = ($CurrentReaderVersion.DisplayVersion.ToString()).Replace(".","")

# Set temp folder and source folder variables
$TempFolder = "C:\Windows\Temp\"
$SourceFolderUrl = "\\fs\Share02\Adobe\21.005.20058 - Full\21.005.20058 - Full"

#could copy from FTP server, but would need addtl logic for licensefix process
#$FTPRequest = [System.Net.FtpWebRequest]::Create("$SourceFolderUrl")
#$FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
#$FTPResponse = $FTPRequest.GetResponse()
#$ResponseStream = $FTPResponse.GetResponseStream()
#$FTPReader = New-Object System.IO.Streamreader -ArgumentList $ResponseStream
#$DirList = $FTPReader.ReadToEnd()

#from Directory Listing get last entry in list, but skip one to avoid the 'misc' dir
$LatestUpdate = "2100520058"

# Compare latest availiable update version to currently installed version.
If ($LatestUpdate -ne $CurrentReaderVersion){

#build file name
#$LatestFile = "AcroRdrDC" + $LatestUpdate + "_en_US.exe"

#build download url for latest file
#$DownloadURL = "$SourceFolderUrl$LatestUpdate/$LatestFile"

# Build filepath
#$FilePath = "$TempFolder$LatestFile"

#download file
#"1. Downloading latest Reader version."
#(New-Object System.Net.WebClient).DownloadFile($DownloadURL, $FilePath)

# Install quietly
"Installing."
Start "$SourceFolderUrl\install.cmd" -NoNewWindow -Wait

# Clean up after install
##"Cleaning."
#Remove-Item -Path "$Tempfolder" 
}

Else
{"Latest version already installed."}
}

Else
{"Reader not installed."}
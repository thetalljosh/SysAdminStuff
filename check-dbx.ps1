Write-Host "Checking for Administrator permission..."
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as administrator and run this script again."
  Break
} else {
  Write-Host "Running as administrator — continuing execution..." -ForegroundColor Green
}

 $patchfile  = $args[0]

 if ($patchfile -eq  $null) {
   $patchfile = ".\dbx-2021-April.bin"
   Write-Host "Patchfile not specified, using latest $patchfile`n"
 }
 $patchfile = (gci $patchfile).FullName

 Import-Module -Force .\Get-UEFIDatabaseSignatures.ps1

 # Print computer info
 $computer = gwmi Win32_ComputerSystem
 $bios = gwmi Win32_BIOS
 "Manufacturer: " + $computer.Manufacturer
 "Model: " + $computer.Model
 $biosinfo = $bios.Manufacturer , $bios.Name , $bios.SMBIOSBIOSVersion , $bios.Version -join ", "
 "BIOS: " + $biosinfo + "`n"

 $DbxRaw = Get-SecureBootUEFI dbx
 $DbxFound = $DbxRaw | Get-UEFIDatabaseSignatures

 $DbxBytesRequired = [IO.File]::ReadAllBytes($patchfile)
 $DbxRequired = Get-UEFIDatabaseSignatures -BytesIn $DbxBytesRequired

 # Flatten into an array of required EfiSignatureData data objects
 $RequiredArray = foreach ($EfiSignatureList in $DbxRequired) {
     Write-Verbose $EfiSignatureList
     foreach ($RequiredSignatureData in $EfiSignatureList.SignatureList) {
         Write-Verbose  $RequiredSignatureData
         $RequiredSignatureData.SignatureData
     }
 }
 Write-Information "Required `n" $RequiredArray

 # Flatten into an array of EfiSignatureData data objects (read from dbx)
 $FoundArray = foreach ($EfiSignatureList in $DbxFound) {
     Write-Verbose $EfiSignatureList
     foreach ($FoundSignatureData in $EfiSignatureList.SignatureList) {
         Write-Verbose  $FoundSignatureData
         $FoundSignatureData.SignatureData
     }
 }
 Write-Information "Found `n" $FoundArray

 $successes = 0
 $failures = 0
 $requiredCount = $RequiredArray.Count
 foreach ($RequiredSig in $RequiredArray) {
    if ($FoundArray -contains $RequiredSig) {
        Write-Information "FOUND: $RequiredSig"
        $successes++
    } else {
        Write-Error "!!! NOT FOUND`n$RequiredSig`n!!!`n"
        $failures++
    }
    $i = $successes + $failures
    Write-Progress -Activity 'Checking if all patches applied' -Status "Checking element $i of $requiredCount" -PercentComplete ($i/$requiredCount *100)
 }

 if ($failures -ne 0) {
     Write-Error "!!! FAIL:  $failures failures detected!"
     # $DbxRaw.Bytes | sc -encoding Byte dbx_found.bin
 } elseif ($successes -ne $RequiredArray.Count) {
     Write-Error "!!! Unexpected: $successes != $requiredCount expected successes!"
 } elseif ($successes -eq 0) {
     Write-Error "!!! Unexpected failure:  no successes detected, check command-line usage."
 } else {
     Write-Host "SUCCESS:  dbx.bin patch appears to be successfully applied"
 }
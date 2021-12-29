#Run this from invoke-command -computername $computer -filepath \path\to\this\script

$DownloadURL="http://www.java.com/en/download/manual.jsp"
$32bit="https://javadl.oracle.com/webapps/download/AutoDL?BundleId=244582_d7fc238d0cbf4b0dac67be84580cfb4b"
$64bit="https://javadl.oracle.com/webapps/download/AutoDL?BundleId=244584_d7fc238d0cbf4b0dac67be84580cfb4b"
$UserAgent="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:25.0) Gecko/20100101 Firefox/25.0"
$InstallString="/s"
$UninstallSwitches="/qn /norestart"
$UninstallDisplayNameWildcardString="Java*"
$UninstallTimeout="45"
$Temp = "C:\Temp"
$TempTest = if(!(test-path $temp)){new-item -itemtype directory -path $temp -force}
$outpath = "$TEMP\javaupdater.exe"
$outpath64 = "$TEMP\javaupdater64.exe"
$wc = New-Object System.Net.WebClient
$JavaTempFilePath = "C:\Temp\javaupdater.exe"
$JavaTempFilePath64 = "C:\Temp\javaupdater64.exe"

function MyLog {
    param([string] $Message)
    (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + "`t$Message" | Out-File $TEMP\JavaUpdate.log -Append
    Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') "`t$Message"
}  
 
        
        if (test-path "C:\Program Files (x86)\Java") {
                #$32bitDL = (((Invoke-WebRequest -UseBasicParsing -uri $DownloadURL).links | Where-Object {$_.title -like $32bit}).href | select -First 1) 
                $wc.DownloadFile($32bit, $outpath)
               # Invoke-WebRequest $32bitDL | out-file $TEMP\javaupdater.exe -Force

        }
        
        if (test-path "C:\Program Files\Java") {

            #$64bitDL = (((Invoke-WebRequest -UseBasicParsing -uri $DownloadURL).links | Where-Object {$_.title -eq $64bit}).href | select -First 1) 
            $wc.DownloadFile($64bit, $outpath64)
            #Invoke-WebRequest $64bitDL | out-file $TEMP\javaupdater.exe -Force
           

        }

        if(!(test-path $JavaTempFilePath)){MyLog "Java 32 download failed.";exit 10}
        elseif(test-path $JavaTempFilePath){MyLog "Java 32  downloaded to $JavaTempFilePath"}
    
        if(!(test-path $JavaTempFilePath64)){MyLog "Java 64 download failed.";exit 10}
        elseif(test-path $JavaTempFilePath64){MyLog "Java 64  downloaded to $JavaTempFilePath64"}

# Uninstall stuff. Try to uninstall everything whose DisplayName matches the wildcard string in the config file.
    
    $UninstallRegPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    $RegUninstallString = Get-ChildItem $UninstallRegPath | ForEach-Object {
        Get-ItemProperty ($_.Name -replace '^HKEY_LOCAL_MACHINE', 'HKLM:') # ugh...
    } | Where-Object { $_.DisplayName -like $UninstallDisplayNameWildcardString } | Select -ExpandProperty UninstallString
    
    $JavaGUIDs = @()
    $RegUninstallString | ForEach-Object {
        if ($_ -match '(\{[^}]+\})') {
            $JavaGUIDs += $Matches[1]
        }
    }
    
    $Failed = $false
    # Now this is a fun error on uninstalls:
    # "There was a problem starting C:\Program Files\Java\jre7\bin\installer.dll. The specified module could not be found"
    # So... Start the uninstall in a job, return the exit code (if/when done), wait for the specified number of seconds,
    # and kill rundll32.exe if it takes longer than the timeout... ugh. Oracle, I curse you! Currently testing with 7u45,
    # which consistently does this if it's installed silently more than once ("reconfigured" (and broken) the second time).
    foreach ($JavaGUID in $JavaGUIDs) {
        $Result = Start-Job -Name UninstallJob -ScriptBlock {
            Start-Process -Wait -NoNewWindow -PassThru -FilePath msiexec.exe -ArgumentList $args
            } -ArgumentList ("/X $JavaGUID " + $UninstallSwitches)
        
        Wait-Job -Name UninstallJob -Timeout $UninstallTimeout | Out-Null
        $Timeout = 0
        while (1) {
            
            if ((Get-Job -Name UninstallJob).State -eq 'Completed') {
                
                MyLog "Presumably successfully uninstalled Java with GUID: $JavaGUID"
                break
                
                           }
            # Let's kill rundll32.exe ... ugh.
            else {
                Get-Process -Name rundll32 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 10
                $Timeout += 10
                if ($Timeout -ge 40) {
                    MyLog "Timed out waiting for rundll32.exe to die or job to finish."
                    $Failed = $true
                    break
                }
            }
            
            Wait-Job -Name UninstallJob -Timeout $UninstallTimeout | Out-Null
            
        } # end of infinite while (1)

        Remove-Job -Name UninstallJob
        
    } # end of foreach JavaGUID

    if ($Failed) { MyLog "Exiting because a Java uninstall previously failed."; exit 10 }
    


try {
    MyLog "Attempting to install Java"
    $Install32 = Start-Process -Wait -NoNewWindow -PassThru -FilePath $JavaTempFilePath -ArgumentList $InstallString -ErrorAction Stop
    $Install64 = Start-Process -Wait -NoNewWindow -PassThru -FilePath $JavaTempFilePath64 -ArgumentList $InstallString -ErrorAction Stop
    if ($Install32.ExitCode -eq 0) {
        MyLog "Successfully updated Java 32."
        
        if ($Env:PROCESSOR_ARCHITECTURE -eq 'x86' -or $Force32bit) { $Id }
        else { $Id  }
        MyLog "Cleaning Up!"
        if (Test-Path $JavaTempFilePath){rm $JavaTempFilePath -Recurse -Force}
        MyLog "Removing old versions of Java directories"
        gci "C:\Program Files (x86)\Java\"| Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-1)} | rmdir -Force -Recurse
    }
    if ($Install64.ExitCode -eq 0) {
        MyLog "Successfully updated Java 64."
        
        if ($Env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $Force64bit) { $Id }
        else { $Id  }
        MyLog "Cleaning Up!"
        if (Test-Path $JavaTempFilePath64){rm $JavaTempFilePath64 -Recurse -Force}
        MyLog "Removing old versions of Java directories"
        gci "C:\Program Files\Java\"| Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-1)} | rmdir -Force -recurse
    }
    else {
        MyLog ("Exit code of installer: " + $Install.ExitCode)
        MyLog ("Exit code of installer: " + $Install64.ExitCode)
    }
    
    
    
    

}
catch {
    MyLog "Failed to install Java: $($Error[0])"
}

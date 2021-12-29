<# Adobe Manual Update Check

This script will find the currently installed version of
the internet explorer ActiveX and other browser plugins
and run the installer to find and prompt for any available
version updates. 
Author: Josh Lambert
Revision History: Initial Draft - 25JUNE2020

#>

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
function killbrowsers{
$browserlist = @('msedge','chrome','firefox','iexplore')
foreach($browser in $browserlist){
$browserproc = Get-Process $browser -ErrorAction SilentlyContinue
if ($browserproc) {
  # try gracefully first
  $browserproc.CloseMainWindow()
  # kill after five seconds
  Sleep 5
  if (!$browserproc.HasExited) {
    $browserproc | Stop-Process -Force
  }
}
}
}
if ((test-path C:\windows\System32\Macromed\Flash) -eq $true) {
    try {
        Set-Location -path C:\windows\System32\Macromed\Flash
        if ((test-path .\*ActiveX.exe) -eq $true) {
            write-host "Adobe Flash ActiveX Plugin for Internet Explorer Found"
            $ActiveX = (get-childitem -path .\ -Name '*ActiveX.exe' )
            if ($ActiveX) { 
                $msgboxinput = [System.Windows.Forms.Messagebox]::Show("ActiveX Found. All Browsers must be stopped prior to update. Kill browsers now?", 'Alert', 'YesNo')
                switch ($msgboxinput) {
                    'Yes' {
                        killbrowsers
                        #Get-Process iexplore | stop-process -ErrorAction SilentlyContinue
                        #Get-Process chrome | Stop-Process -ErrorAction SilentlyContinue
                        #Get-Process firefox | stop-process -ErrorAction SilentlyContinue
                        #Get-Process msedge | Stop-Process -ErrorAction SilentlyContinue
                        start-process -FilePath $ActiveX -ArgumentList "-update plugin" -wait
                    }
                    'no' { break outer }        
                }
            }
            else { write-host "ActiveX not found" }                   
                   
    
            else {
                write-host "No ActiveX Updates Available"
            }
        }
    
    }

    catch {
        
    }
    Write-Host "Continuing in 5 seconds"
    Start-Sleep -Seconds 5
    try {
        if ((test-path .\*PlugIn.exe) -eq $true) {
            write-host "Adobe Flash Plugin for Other Browsers Found"
            $PlugIn = (Get-ChildItem -path .\ -Name '*PlugIn.exe' )
            if ($PlugIn) {  
                
                start-process -FilePath $PlugIn -ArgumentList "-update plugin" -wait
            }
                
                                  
                      
                
                
            else {
                write-host "PlugIn not found" 
            }
                     
        }
        else {
            write-host "No Flash PlugIn Updates Available"
        }
    }
    catch {
        write-host "Adobe Flash is not installed on this system"
    }
        
    [System.Windows.Forms.Messagebox]::Show("Update Check Complete. Your IT Team Thanks You.", "Complete")

}
else {
    [System.Windows.Forms.Messagebox]::Show("It appears Flash is not installed on your system. If you believe this is an error, please contact your IT Administrator. Thank you for checking for updates!", "Complete")
}
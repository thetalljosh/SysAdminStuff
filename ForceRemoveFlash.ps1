<# Force Remove Flash

This script will remove all installed Flash Player versions


#>

$FlashUninstaller = "\\fs\Share02\Patches\Microsoft\KillFlash\uninstall_flash_player.exe"
$FlashUninstallerLocal = "C:\temp\uninstall_flash_player.exe"

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
if (test-path 'C:\windows\System32\Macromed\Flash') {
 
        
                        killbrowsers
                        #Get-Process iexplore | stop-process -ErrorAction SilentlyContinue
                        #Get-Process chrome | Stop-Process -ErrorAction SilentlyContinue
                        #Get-Process firefox | stop-process -ErrorAction SilentlyContinue
                        #Get-Process msedge | Stop-Process -ErrorAction SilentlyContinue
                        if(!(test-path 'C:\temp')){mkdir -Path 'c:\temp'}
                        copy-item $FlashUninstaller 'c:\temp\' -force
                        start-process -FilePath $FlashUninstallerLocal -ArgumentList "-uninstall" -wait
                        Sleep 5
                        Remove-Item -Path C:\windows\System32\Macromed\Flash -Recurse -Force -ErrorAction SilentlyContinue 
               
    
    }
    if (test-path 'C:\windows\SysWow64\Macromed\Flash') {
 
        
                        killbrowsers
                        #Get-Process iexplore | stop-process -ErrorAction SilentlyContinue
                        #Get-Process chrome | Stop-Process -ErrorAction SilentlyContinue
                        #Get-Process firefox | stop-process -ErrorAction SilentlyContinue
                        #Get-Process msedge | Stop-Process -ErrorAction SilentlyContinue
                        if(!(test-path 'C:\temp')){mkdir -Path 'c:\temp'}
                        copy-item $FlashUninstaller 'c:\temp\' -force
                        start-process -FilePath $FlashUninstallerLocal -ArgumentList "-uninstall" -wait
                        Sleep 5
                        Remove-Item -Path C:\windows\System32\Macromed\Flash -Recurse -Force -ErrorAction SilentlyContinue 
               
    
    }

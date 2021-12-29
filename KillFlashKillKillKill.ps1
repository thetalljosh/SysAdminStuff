$WinProdQuery = (Get-Item "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue('ProductName')
$WinVerQuery = (Get-Item "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue('ReleaseID')
$HotFixID = 'KB4577586'

#Logs are good. let's do some logging
# Create Write-Log function
function Write-Log() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$message,
        [Parameter(Mandatory=$false)]
        [Alias('LogPath')]
        [string]$path = "$env:windir\FlashRemoval.log",
        [Parameter(Mandatory=$false)]
        [ValidateSet("Error","Warn","Info")]
        [string]$level = "Info"
    )
    Begin {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $verbosePreference = 'Continue'
    }
    Process {
		if ((Test-Path $Path)) {
			$logSize = (Get-Item -Path $Path).Length/1MB
			$maxLogSize = 5
		}
        # Check for file size of the log. If greater than 5MB, it will create a new one and delete the old.
        if ((Test-Path $Path) -AND $LogSize -gt $MaxLogSize) {
            Write-Error "Log file $Path already exists and file exceeds maximum file size. Deleting the log and starting fresh."
            Remove-Item $Path -Force
            $newLogFile = New-Item $Path -Force -ItemType File
        }
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (-NOT(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $newLogFile = New-Item $Path -Force -ItemType File
        }
        else {
            # Nothing to see here yet.
        }
        # Format Date for our Log File
        $formattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($level) {
            'Error' {
                Write-Error $message
                $levelText = 'ERROR:'
            }
            'Warn' {
                Write-Warning $Message
                $levelText = 'WARNING:'
            }
            'Info' {
                Write-Verbose $Message
                $levelText = 'INFO:'
            }
        }
        # Write log entry to $Path
        "$formattedDate $levelText $message" | Out-File -FilePath $path -Append
    }
    End {
    }
}

#first, let's see if the hotfix is already installed

if(Get-HotFix -Id $HotFixID | Select-Object HotFixID){
    Write-Log -message "$HotFixID already installed. Exiting script."
    Exit
    }
    Else{
       
        #let's make a folder to put the update in
        if(!(test-path 'C:\temp')){mkdir -Path 'c:\temp'}

        #alright, let's find out if we're running a server OS or desktop OS

        If($WinProdQuery -like 'Windows 10*'){
        Write-Log -message "Running Windows 10. Next we'll grab the build version."

        #let's grab the specific windows build so we know which msu to install. this could be written more elegantly, but if it works it works. 
            if($WinVerQuery -eq '1809'){
                Write-Log -message "Running Windows 10 version $WinVerQuery"
                Write-Log -message "Copying install files to local system"
                copy-item "\\fs\Share02\Patches\Microsoft\KillFlash\windows10.0-kb4577586-x64_1809.msu" 'c:\temp\' -force
                start-sleep 10
                Write-Log -message "Beginning to install update using WUSA"
                Start-process Wusa.exe -Wait -ArgumentList '"C:\temp\windows10.0-kb4577586-x64_1809.msu" /quiet /norestart' 
                }
            elseif($WinVerQuery -eq '1903'){
                Write-Log -message "Running Windows 10 version $WinVerQuery"
                Write-Log -message "Copying install files to local system"
                copy-item "\\fs\Share02\Patches\Microsoft\KillFlash\windows10.0-kb4577586-x64_1903.msu" 'c:\temp\' -force
                start-sleep 10
                Write-Log -message "Beginning to install update using WUSA"
                Start-process Wusa.exe -Wait -ArgumentList '"C:\temp\windows10.0-kb4577586-x64_1903.msu" /quiet /norestart' 
                }
            elseif($WinVerQuery -eq '1909'){
                Write-Log -message "Running Windows 10 version $WinVerQuery"
                Write-Log -message "Copying install files to local system"
                copy-item "\\fs\Share02\Patches\Microsoft\KillFlash\windows10.0-kb4577586-x64_1909.msu" 'c:\temp\' -force
                start-sleep 10
                Write-Log -message "Beginning to install update using WUSA"
                Start-process Wusa.exe -Wait -ArgumentList '"c:\temp\windows10.0-kb4577586-x64_1909.msu" /quiet /norestart' 
                }
            elseif($WinVerQuery -eq '2004'){
                Write-Log -message "Running Windows 10 version $WinVerQuery"
                Write-Log -message "Copying install files to local system"
                copy-item "\\fs\Share02\Patches\Microsoft\KillFlash\windows10.0-kb4577586-x64_2004.msu" 'c:\temp\' -force
                start-sleep 10
                Write-Log -message "Beginning to install update using WUSA"
                Start-process Wusa.exe -Wait -ArgumentList '"C:\temp\windows10.0-kb4577586-x64_2004.msu" /quiet /norestart' 
                }
           }
           #moving on to server versions now
           If($WinProdQuery -like '*Server 2016*'){
                Write-Log -message "Running $WinProdQuery version $WinVerQuery"
                Write-Log -message "Copying install files to local system"
                copy-item "\\fs\Share02\Patches\Microsoft\KillFlash\windows10.0-kb4577586-x64_server2016.msu" 'c:\temp\' -force
                start-sleep 10
                Write-Log -message "Beginning to install update using WUSA"
                Start-process Wusa.exe -Wait -ArgumentList '"C:\temp\windows10.0-kb4577586-x64_Server2016.msu" /quiet /norestart' 
                }
            If($WinProdQuery -like '*Server 2012*'){
                Write-Log -message "Running $WinProdQuery version $WinVerQuery"
                Write-Log -message "Copying install files to local system"
                copy-item "\\fs\Share02\Patches\Microsoft\KillFlash\windows10.0-kb4577586-x64_Server2012R2.msu" 'c:\temp\' -force
                start-sleep 10
                Write-Log -message "Beginning to install update using WUSA"
                Start-process Wusa.exe -Wait -ArgumentList '"C:\temp\windows10.0-kb4577586-x64_Server2012R2.msu" /quiet /norestart' 
            }
            If($WinProdQuery -like '*Server 2019*'){
                Write-Log -message "Running $WinProdQuery version $WinVerQuery"
                Write-Log -message "Copying install files to local system"
                copy-item "\\fs\Share02\Patches\Microsoft\KillFlash\windows10.0-kb4577586-x64_server2019.msu" 'c:\temp\' -force
                start-sleep 10
                Write-Log -message "Beginning to install update using WUSA"
                Start-process Wusa.exe -Wait -ArgumentList '"C:\temp\windows10.0-kb4577586-x64_Server2019.msu" /quiet /norestart' 
            }
    #alright, let's give the installer a minute to wrap up and see if it succeeded
    Start-Sleep -Seconds 60

    if(Get-HotFix -Id $HotFixID | Select-Object HotFixID){
    Write-Log -message "$HotFixID successfully installed. Cleaning up and Exiting script."
    remove-item -Path 'C:\temp\*.msu' -Force
    Exit
    }
    else{ Write-Log -message "$HotFixID Install Failed!!!"}
}

    
    

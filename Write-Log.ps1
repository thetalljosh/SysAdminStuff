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
        [string]$path = "$env:windir\PowerShellScript.log",
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
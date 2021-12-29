#--------------------------------------------------------------------------------
#       Script: SMTPCheck.PS1
#      Author: Josh Lambert
#     Version: 1.0
#
# Information:
# This script checks the status of the Microsoft SMTP virtual server and tries to start it if it's not running
#--------------------------------------------------------------------------------

#This Function is for logging. We like logging. 

function Write-Log() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$message,
        [Parameter(Mandatory=$false)]
        [Alias('LogPath')]
        [string]$path = "$env:windir\!SMTPEventAlerts.log",
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


Write-Log -message "Checking the SMTP server status" -level Info

## let's look up server status
Function serverStatusDescription ($val)
{
	Switch ($val){
		0 {"Unknown"}
		1 {"Unknown"}    
		2 {"Running"}
		3 {"Unknown"}
		4 {"Stopped"}
		default {"Unknown ($val)"}
	 }
}

## check server status
$SMTP=[adsi]"IIS://localhost/SMTPSVC/1"
$StatusDescription = serverStatusDescription($SMTP.ServerState)

If ($StatusDescription -ne "Running") {
    Write-Log -message "Server not running! Status is $SMTP.ServerState" -level Error
    
    ## try to start the smtp virtual server
    Write-Log -message "Trying to start the SMTP server" -level Info
    $SMTP.ServerState = 2
    $SMTP.SetInfo()
    Write-Log -message "Checking to see if server started" -level Info
    Start-Sleep -Seconds 15
    If ($StatusDescription -ne "Running") {
        Write-Log -message "Failed to start the SMTP server. Sorry" -level Error
        }
}
Elseif($StatusDescription -eq "Running"){
    Write-Log -message "Server is running" -level Info
}

##check SMTP service
if ((Get-Service -Name SMTPSVC).Status -ne "Running"){
    Write-Log -message "Trying to start the SMTP Service" -level Info
    Start-Service -Name SMTPSVC
    Write-Log -message "Checking to see if SMTP Service started" -level Info
    Start-Sleep -Seconds 15
    If ((Get-Service -Name SMTPSVC).Status -ne "Running") {
        Write-Log -message "Failed to start the SMTP Service. Sorry" -level Error
        }
}
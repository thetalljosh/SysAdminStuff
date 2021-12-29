#Script name Send-EventEmail
#this script will send an email with specified event details via SMTP relay

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
        [string]$path = "$env:windir\!AuditEventAlerts.log",
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

$event = get-eventlog -LogName Security -source "Microsoft-Windows-Security-Auditing" -newest 1
#get-help get-eventlog will show there are a handful of other options available for selecting the log entry you want.
#if (($event.EntryType -eq "Information") -or ($event.EntryType -eq "Warning") -or ($event.EntryType -eq "Error") -or ($event.EntryType -eq "Critical")) $event.
if($event)
{
    $PCName = $env:COMPUTERNAME
    $EmailBody = $event.Message
    $EmailFrom = "Domain Event Alert <EventAlert@seceis.army.mil>"
    $EmailTo = "joshua.a.lambert18.ctr@army.mil", "herbert.g.shaw.civ@army.mil" 
    $EmailSubject = "Active Directory Alert!"
    $SMTPServer = "155.154.226.8"
    #Write-host "Sending Email"
    Write-log -message "Sending Alert to $EmailTo - Event entry $EmailSubject"
    Send-MailMessage -From $EmailFrom -To $EmailTo -Subject $EmailSubject -body $EmailBody -SmtpServer $SMTPServer
}
else
{
    write-log -message "No error found"
    write-log -message "Here is the log entry that was inspected: $event"
    
}
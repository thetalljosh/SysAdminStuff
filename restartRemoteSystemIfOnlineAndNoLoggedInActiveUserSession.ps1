Write-host "Select Text/CSV File with List of Computers"

#Provides Dialog Box to select a file with list of computers.  File must contain only 1 of each of the Computer name(s) per line
Function Get-OpenFile($initialDirectory)
{ 
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.ShowDialog()
    $OpenFileDialog.filename
    $OpenFileDialog.ShowHelp = $true
}

$InputFile = Get-OpenFile
If($InputFile -eq "Cancel"){
Write-host "Canceled By User"
exit}
Else{
$ComputerList = @(get-content -path $InputFile -ErrorAction SilentlyContinue) 
}


function Convert-QueryToObjects
{
    [CmdletBinding()]
    [Alias('QueryToObject')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $false,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 0)]
        [Alias('ComputerName', 'Computer')]
        [string]
        $Name = $env:COMPUTERNAME
    )

    Process
    {
        Write-Verbose "Running query.exe against $Name."
        $Users = query user /server:$Name 2>&1

        if ($Users -like "*No User exists*")
        {
            # Handle no user's found returned from query.
            # Returned: 'No User exists for *'
            Write-Error "There were no users found on $Name : $Users"
            Write-Verbose "There were no users found on $Name."
        }
        elseif ($Users -like "*Error*")
        {
            # Handle errored returned by query.
            # Returned: 'Error ...<message>...'
            Write-Error "There was an error running query against $Name : $Users"
            Write-Verbose "There was an error running query against $Name."
        }
        elseif ($Users -eq $null -and $ErrorActionPreference -eq 'SilentlyContinue')
        {
            # Handdle null output called by -ErrorAction.
            Write-Verbose "Error action has supressed output from query.exe. Results were null."
        }
        else
        {
            Write-Verbose "Users found on $Name. Converting output from text."

            # Conversion logic. Handles the fact that the sessionname column may be populated or not.
            $Users = $Users | ForEach-Object {
                (($_.trim() -replace ">" -replace "(?m)^([A-Za-z0-9]{3,})\s+(\d{1,2}\s+\w+)", '$1  none  $2' -replace "\s{2,}", "," -replace "none", $null))
            } | ConvertFrom-Csv

            Write-Verbose "Generating output for $($Users.Count) users connected to $Name."

            # Output objects.
            foreach ($User in $Users)
            {
                Write-Verbose $User
                if ($VerbosePreference -eq 'Continue')
                {
                    # Add '| Out-Host' if -Verbose is tripped.
                    [PSCustomObject]@{
                        ComputerName = $Name
                        Username = $User.USERNAME
                        SessionState = $User.STATE.Replace("Disc", "Disconnected")
                        SessionType = $($User.SESSIONNAME -Replace '#', '' -Replace "[0-9]+", "")
                    } | Out-Host
                }
                else
                {
                    # Standard output.
                    [PSCustomObject]@{
                        ComputerName = $Name
                        Username = $User.USERNAME
                        SessionState = $User.STATE.Replace("Disc", "Disconnected")
                        SessionType = $($User.SESSIONNAME -Replace '#', '' -Replace "[0-9]+", "")
                    }
                }
            }
        }
    }
}

Foreach($PC in $computerList){
if(Test-NetConnection -computername $PC -InformationLevel Quiet){
   $sessions = Convert-QueryToObjects($PC) -ErrorAction SilentlyContinue 
   $ActiveUser = ($sessions.Username)
    if(!($sessions.SessionState)){
    Write-host "No Active Sessions on $PC, OK to restart..." -ForegroundColor Green
    invoke-command -ComputerName $PC -ScriptBlock{ cmd /c 'shutdown /r /t 1 /c "Rebooting to apply updates"'}
        }
        elseif($sessions.SessionState = '*Active*'){write-host "$PC has active session from $ActiveUser and should not be restarted" -ForegroundColor Red}
    
    }
    else{write-host "$PC is unreachable"}}
    
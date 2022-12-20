#####################
## Start of Script ##
#####################

$ErrorActionPreference = "Inquire"
Clear-Host
write-host ' ' 
write-host ' ' 
write-host '#######################' -foregroundcolor Magenta
write-host '## WSUS INSTALLATION ##' -foregroundcolor Magenta
write-host '#######################' -foregroundcolor Magenta
write-host ' ' 
write-host ' '

Install-WindowsFeature -Name UpdateServices -IncludeManagementTools

if (!(test-path D:\)) {
    write-host "Error: Data drive D:\ not detected. Please configure D:\ and try again" -foregroundcolor Red
    
}
if (!(test-path D:\WSUS)) {
    mkdir D:\WSUS
}
set-location "C:\Program Files\Update Services\Tools"
Write-Host "Starting Post Install Tasks" -ForegroundColor Green
.\wsusutil.exe postinstall CONTENT_DIR=D:\WSUS

Write-Host "Pause for 5 minutes to let install complete." -ForegroundColor Green
start-sleep -Seconds 300

# Begin WSUS initial Config

# per http://msdn.microsoft.com/en-us/library/aa349325(v=vs.85).aspx
#$w  = [reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
#$ww = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer()

$wsus = Get-WSUSServer
$wsusConfig = $wsus.GetConfiguration()

# This tells it not to use every available language
## Change to attribute
$wsusConfig.AllUpdateLanguagesEnabled = $false           


# This sets it just to do English (for multiple languages use collection)
# $language = New-Object -Type System.Collections.Specialized.StringCollection
# $language.Add("en")
$wsusConfig.SetEnabledUpdateLanguages("en")           
$wsusConfig.Save()

# Tells it to Sync from MS
## Change to attribute (true for master/ false for slave)
Set-WsusServerSynchronization –SyncFromMU

<#
$Configuration   = $ww.GetConfiguration()
$Synchronization = $ww.GetSubscription()
$Rules           = $ww.GetInstallApprovalRules()
#>
# Configure the Platforms that we want WSUS to receive updates

Get-WsusProduct | where-Object {
    $_.Product.Title -in (
        'Windows 10',
        'Windows Server 2016',
        'Windows Server 2019',
        'Windows Server 2022',
        'Windows 11',
        'Windows 10 version 1903 and later'
    )
} | Set-WsusProduct

# Configure the Classifications
write-host 'Setting WSUS Classifications'
Get-WsusClassification | Where-Object {
    $_.Classification.Title -in (
        'Critical Updates',
        'Definition Updates',
        'Feature Packs',
        'Security Updates',
        'Service Packs',
        'Update Rollups',
        'Updates')
} | Set-WsusClassification

# This sets synchronization to be automatic
## Change to attribute
$Synchronization.SynchronizeAutomatically = $true  

# This sets the time, GMT, in 24 hour format (00:00:00) format
$Synchronization.SynchronizeAutomaticallyTimeOfDay = '04:00:00'

# Set the WSUS Server Synchronization Number of Syncs per day 
$Synchronization.NumberOfSynchronizationsPerDay = '1'

# Saving to avoid losing changes after Category Sync starts
$Synchronization.save()

# Set WSUS to download available categories
# This can take up to 10 minutes
$Synchronization.StartSynchronizationForCategoryOnly()

# Kick off a synchronization
$subscription.StartSynchronization()

# Monitor Progress of Synchronisation

write-host 'Beginning full WSUS Sync, will take some time' -ForegroundColor Magenta   
Start-Sleep -Seconds 60 # Wait for sync to start before monitoring      
while ($subscription.GetSynchronizationProgress().ProcessedItems -ne $subscription.GetSynchronizationProgress().TotalItems) {            
    Write-Progress -PercentComplete (            
        $subscription.GetSynchronizationProgress().ProcessedItems * 100 / ($subscription.GetSynchronizationProgress().TotalItems)            
    ) -Activity "WSUS Sync Progress"            
}  
Write-Host "Sync is done." -ForegroundColor Green

# Decline Unwanted Updates

if ($DeclineUpdates -eq $True) {
    write-host 'Declining Unwanted Updates'
    $approveState = 'Microsoft.UpdateServices.Administration.ApprovedStates' -as [type]

    # Declining All Internet Explorer 10
    $updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope -Property @{
        TextIncludes   = '2718695'
        ApprovedStates = $approveState::Any
    }
    $wsus.GetUpdates($updateScope) | ForEach-Object {
        Write-Verbose ("Declining {0}" -f $_.Title) -Verbose
        $_.Decline()
    }

    # Declining Microsoft Browser Choice EU
    $updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope -Property @{
        TextIncludes   = '976002'
        ApprovedStates = $approveState::Any
    }
    $wsus.GetUpdates($updateScope) | ForEach-Object {
        Write-Verbose ("Declining {0}" -f $_.Title) -Verbose
        $_.Decline()
    }

    # Declining all Itanium Update
    $updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope -Property @{
        TextIncludes   = 'itanium'
        ApprovedStates = $approveState::Any
    }
    $wsus.GetUpdates($updateScope) | ForEach-Object {
        Write-Verbose ("Declining {0}" -f $_.Title) -Verbose
        $_.Decline()
    }
}

# Configure Default Approval Rule
write-host 'Configuring default automatic approval rule'
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
$rule = $wsus.GetInstallApprovalRules() | Where-Object {
    $_.Name -eq "Default Automatic Approval Rule" }
# Change Classifications (available classifications)
# 'Critical Updates',
# 'Definition Updates',
# 'Feature Packs',
# 'Security Updates',
# 'Service Packs',
# 'Update Rollups',
# 'Updates'

$class = $wsus.GetUpdateClassifications() | Where-Object { $_.Title -In (
        'Critical Updates',
        'Definition Updates',
        'Security Updates'
    ) }
$class_coll = New-Object Microsoft.UpdateServices.Administration.UpdateClassificationCollection
$class_coll.AddRange($class)
$rule.SetUpdateClassifications($class_coll)
$rule.Enabled = $True
$rule.Save()


# Loop to make sure new products synch up. And a anti-lock to prevent getting stuck.
$lock_prevention = [DateTime]::now.AddMinutes(10)
do { 
    Start-Sleep -Seconds 20
    write-host 'Running Default Approval Rule'
    write-host ' >This step may timeout, but the rule will be applied and the script will continue' -ForegroundColor Yellow
    try {
        $Apply = $rule.ApplyRule()
    }
    catch { 
        write-warning $_
    }
} until ($Status -like "*NotProcessing*" -or $lock_prevention -lt [datetime]::now) 


write-host 'WSUS log files can be found here: %ProgramFiles%\Update Services\LogFiles'
write-host 'Done!' -foregroundcolor Green

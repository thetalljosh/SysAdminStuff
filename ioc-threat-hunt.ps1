#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
Threat hunting script for PDFast.exe (SHA256: a7f0794872bc5d0fedcf6161c7002e0d9fc7e23cd8d390e0327db7c010dd7a1a) IOCs.
.DESCRIPTION
This script searches for known Indicators of Compromise associated with the PDFast.exe malware.
It checks for file hashes, file paths, registry keys/values, running processes, network connections,
DNS cache entries, scheduled tasks, and specific certificates.
IOCs are based on JoeSandbox analysis reports  and.
.PARAMETER LogPath
Specifies the full path for the log file. Defaults to "$PSScriptRoot\PDFast_Hunt_Log.txt".
.PARAMETER ScanPathForHashes
An array of directory paths to scan for file hash matching. Defaults to common system and user directories.
.EXAMPLE
.\Hunt-PDFastIOCs.ps1 -Verbose
.EXAMPLE
.\Hunt-PDFastIOCs.ps1 -LogPath "C:\ThreatHunting\Logs\PDFast_$(Get-Date -Format 'yyyyMMdd_HHmmss').log" -ScanPathForHashes "C:", "D:\Users"
.NOTES
Run this script with Administrator privileges for full access to system resources.
#>

param (
    [string]$LogPath = "$PSScriptRoot\PDFast_Hunt_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt",
    [string]$ScanPathForHashes = @(
        "$env:SystemRoot\Temp",
        "$env:TEMP",
        "$env:USERPROFILE\AppData\Local\Temp",
        "$env:USERPROFILE\AppData\Roaming",
        "$env:ProgramData",
        "$env:SystemRoot\Installer"
        # Add more paths as needed, e.g., C:\Users for broader user profile scanning
    )
)

# --- Global IOC Definitions ---
# Based on [1] and [2]

$MaliciousFileHashes = @{
    MD5 = @(
        "1e995eef7deba589543f502c4b14da47", # PDFast.exe (main)
        "9899D6C26DDB1284D2FF6BE3F15024FA", # Dropped PDFast.exe
        "D5BFC5859BE9782F3165C875038CCB54", # upd.exe
        "D1A940CE42F649F2AC95D329F5B89B85", # Core.dll [1]
        "93360F0FC18F7F181437C1D9EF745CAE", # Core.dll [2]
        "B7A6A99CBE6E762C0A61A8621AD41706", # MSIA8D5.tmp (PDFizer.exe) / MSIF0C9.tmp
        "114D2C82B6432CB549705E1301718354"  # PDFast.msi
    );
    SHA1 = @(
        "8950965f40f30eb40d11de71754a4fe93b098f3d", # PDFast.exe (main)
        "DB3219531C43AC483667B725750C0B521A79D541", # Dropped PDFast.exe
        "E2FA23138E3C33D2C97F4232151E4467E6225D74", # Core.dll
        "4C98A72B137AD4C5C447209413A2442D68BF652B"  # PDFast.msi
    );
    SHA256 = @(
        "a7f0794872bc5d0fedcf6161c7002e0d9fc7e23cd8d390e0327db7c010dd7a1a", # PDFast.exe (main)
        "5FD8304642C89A71420E55EB3EC4468011501FCEBA69077F323D07BF9D0B6B8C", # Dropped PDFast.exe
        "A7DB637C9A590D87B9A053C75441B03EFA242199A152C68D30E9509CAA312D51", # Core.dll
        "2101E0032A1072EB4C5A7A2CEF573B1CAB864B724FC71CEFBCCEA1C287A3579C"  # PDFast.msi
    )
}

$MaliciousFilePaths = @(
    "C:\Users\*\Desktop\PDFast.exe", # Wildcard for any user
    "C:\Users\*\AppData\Roaming\PDFast\PDFast 1.0.0\install\CA604DA\PDFast.msi",
    "C:\Users\*\AppData\Roaming\PDFast\upd.exe",
    "C:\Users\*\AppData\Roaming\PDFast\Core.dll",
    "C:\Users\*\AppData\Roaming\PDFast\PDFast 1.0.0\install\CA604DA\PDFast.exe",
    "C:\Users\*\AppData\Roaming\PDFast\PDFast 1.0.0\install\CA604DA\upd.exe",
    "C:\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\PDFast.lnk",
    "C:\Windows\Installer\MSI*.tmp", # Pattern for temporary MSI files
    "C:\Users\*\AppData\Local\Temp\MSI*.tmp" # Pattern for temporary MSI files in user temp
)

$MaliciousRegistryKeysValues = @(
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PDFast 1.0.0"; CheckExists = $true },
    @{ Path = "HKLM:\SOFTWARE\Microsoft\SystemCertificates\AuthRoot\Certificates\4EFC31460C619ECAE59C1BCE2C008036D94C84B8"; CheckExists = $true }
    # Add more specific value checks if needed, e.g. -Name "DisplayName" -ExpectedValue "PDFast"
)

$MaliciousProcessNames = @(
    "PDFast.exe",
    "upd.exe"
)

$MaliciousCommandLinesPatterns = @(
    "msiexec.exe.*PDFast\.msi", # msiexec launching PDFast.msi
    "rundll32\.exe.*MSI.*\.tmp.*zzzzInvokeManagedCustomActionOutOfProc.*RequestSender", # rundll32 with temp MSI file and custom action
    "chrome\.exe.*https://pdf-fast\.com/thankyou\.html" # Chrome opening the specific thank you page
)

$MaliciousIPAddresses = @(151.101.130.133)

$MaliciousDomains = @(
    "pdf-fast.com",
    "b.pdf-fast.com",
    "d.pdf-fast.com"
)

$MaliciousScheduledTaskNamePatterns = @(
    "PDFast_updater_*" # Pattern to catch user-specific SID
)

$MaliciousCertificateThumbprints = @(1, 2)

$SuspiciousLNKTargetPaths = @( # General suspicious patterns for startup LNKs
    "$env:TEMP\\",
    "$env:APPDATA\\",
    "$env:LOCALAPPDATA\\Temp\\"
)

# --- Logging Function ---
function Write-Log {

    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $false)]

        [string]$Severity = "INFO",
        [Parameter(Mandatory = $false)]
        [string]$FunctionName = $($MyInvocation.MyCommand.Name)
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp[$FunctionName] - $Message"
    Write-Host $logEntry
    try {
        Add-Content -Path $LogPath -Value $logEntry -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to write to log file: $LogPath. Error: $($_.Exception.Message)"
    }
}


# --- File System Scanning Functions ---
function Find-MaliciousFilesByPath {
    Write-Log "Starting search for malicious file paths..." -FunctionName "Find-MaliciousFilesByPath"
    foreach ($filePathPattern in $MaliciousFilePaths) {
        Write-Verbose "Checking path pattern: $filePathPattern"
        try {
            $resolvedPaths = Resolve-Path -Path $filePathPattern -ErrorAction SilentlyContinue
            if ($resolvedPaths) {
                foreach($resolvedPath in $resolvedPaths){
                    if (Test-Path -Path $resolvedPath.Path -PathType Leaf) {
                         Write-Log "CRITICAL HIT: Known malicious file path found: $($resolvedPath.Path)" -Severity "CRITICAL HIT" -FunctionName "Find-MaliciousFilesByPath"
                    } elseif (Test-Path -Path $resolvedPath.Path -PathType Container) {
                         Write-Log "WARNING: Directory associated with malicious activity found: $($resolvedPath.Path). Further investigation of contents recommended." -Severity "WARNING" -FunctionName "Find-MaliciousFilesByPath"
                    }
                }
            }
        }
        catch {
            Write-Log "Error resolving path pattern $filePathPattern : $($_.Exception.Message)" -Severity "WARNING" -FunctionName "Find-MaliciousFilesByPath"
        }
    }
    Write-Log "Finished search for malicious file paths." -FunctionName "Find-MaliciousFilesByPath"
}

function Find-MaliciousFilesByHash {
    Write-Log "Starting search for malicious file hashes in specified scan paths..." -FunctionName "Find-MaliciousFilesByHash"
    Write-Verbose "Scan paths: $($ScanPathForHashes -join ', ')"

    foreach ($scanPath in $ScanPathForHashes) {
        if (-not (Test-Path -Path $scanPath -PathType Container)) {
            Write-Log "Scan path $scanPath does not exist or is not a directory. Skipping." -Severity "WARNING" -FunctionName "Find-MaliciousFilesByHash"
            continue
        }
        Write-Log "Scanning directory: $scanPath" -FunctionName "Find-MaliciousFilesByHash"
        try {
            $filesToScan = Get-ChildItem -Path $scanPath -Recurse -File -Include "*.exe", "*.dll", "*.msi", "*.tmp" -ErrorAction SilentlyContinue
            foreach ($file in $filesToScan) {
                Write-Verbose "Calculating hashes for: $($file.FullName)"
                try {
                    $fileHashes = Get-FileHash -Path $file.FullName -Algorithm MD5, SHA1, SHA256 -ErrorAction SilentlyContinue
                    if ($fileHashes) {
                        foreach($hashEntry in $fileHashes){
                            if ($MaliciousFileHashes[$hashEntry.Algorithm] -contains $hashEntry.Hash) {
                                Write-Log "CRITICAL HIT: Malicious file hash found! Path: $($file.FullName), Algorithm: $($hashEntry.Algorithm), Hash: $($hashEntry.Hash)" -Severity "CRITICAL HIT" -FunctionName "Find-MaliciousFilesByHash"
                            }
                        }
                    }
                }
                catch {
                    Write-Log "Could not get hash for file $($file.FullName): $($_.Exception.Message)" -Severity "WARNING" -FunctionName "Find-MaliciousFilesByHash"
                }
            }
        }
        catch {
            Write-Log "Error enumerating files in $scanPath : $($_.Exception.Message)" -Severity "WARNING" -FunctionName "Find-MaliciousFilesByHash"
        }
    }
    Write-Log "Finished search for malicious file hashes." -FunctionName "Find-MaliciousFilesByHash"
}

# --- Registry Analysis Function ---
function Test-MaliciousRegistryKeysValues {
    Write-Log "Starting search for malicious registry keys and values..." -FunctionName "Test-MaliciousRegistryKeysValues"
    foreach ($regEntry in $MaliciousRegistryKeysValues) {
        $regPath = $regEntry.Path
        Write-Verbose "Checking registry path: $regPath"
        try {
            if (Test-Path -Path $regPath) {
                if ($regEntry.CheckExists) {
                     Write-Log "CRITICAL HIT: Known malicious registry key path found: $regPath" -Severity "CRITICAL HIT" -FunctionName "Test-MaliciousRegistryKeysValues"
                }
                if ($regEntry.Name) {
                    $property = Get-ItemProperty -Path $regPath -Name $regEntry.Name -ErrorAction SilentlyContinue
                    if ($property -and ($property.($regEntry.Name) -eq $regEntry.ExpectedValue)) {
                        Write-Log "CRITICAL HIT: Known malicious registry value found. Path: $regPath, Name: $($regEntry.Name), Value: $($property.($regEntry.Name))" -Severity "CRITICAL HIT" -FunctionName "Test-MaliciousRegistryKeysValues"
                    } elseif ($property) {
                         Write-Log "INFO: Registry key $regPath has value $($regEntry.Name) but does not match expected. Actual: $($property.($regEntry.Name))" -Severity "INFO" -FunctionName "Test-MaliciousRegistryKeysValues"
                    }
                }
            }
        }
        catch {
            Write-Log "Error accessing registry path $regPath : $($_.Exception.Message)" -Severity "WARNING" -FunctionName "Test-MaliciousRegistryKeysValues"
        }
    }
    Write-Log "Finished search for malicious registry keys and values." -FunctionName "Test-MaliciousRegistryKeysValues"
}

# --- Process Analysis Function ---
function Find-MaliciousProcesses {
    Write-Log "Starting search for malicious running processes..." -FunctionName "Find-MaliciousProcesses"
    try {
        $processes = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Select-Object ProcessId, Name, CommandLine
        if (-not $processes) {
            Write-Log "Could not retrieve running processes." -Severity "WARNING" -FunctionName "Find-MaliciousProcesses"
            return
        }

        foreach ($process in $processes) {
            if ($MaliciousProcessNames -contains $process.Name) {
                Write-Log "CRITICAL HIT: Known malicious process name running. PID: $($process.ProcessId), Name: $($process.Name), CommandLine: $($process.CommandLine)" -Severity "CRITICAL HIT" -FunctionName "Find-MaliciousProcesses"
            }
            foreach ($pattern in $MaliciousCommandLinesPatterns) {
                if ($process.CommandLine -match $pattern) {
                    Write-Log "CRITICAL HIT: Process with suspicious command line found. PID: $($process.ProcessId), Name: $($process.Name), CommandLine: $($process.CommandLine)" -Severity "CRITICAL HIT" -FunctionName "Find-MaliciousProcesses"
                }
            }
        }
    }
    catch {
        Write-Log "Error retrieving or analyzing processes: $($_.Exception.Message)" -Severity "WARNING" -FunctionName "Find-MaliciousProcesses"
    }
    Write-Log "Finished search for malicious running processes." -FunctionName "Find-MaliciousProcesses"
}

# --- Network Artifact Collection Functions ---
function Check-NetworkConnections {
    Write-Log "Starting check for suspicious network connections..." -FunctionName "Check-NetworkConnections"
    try {
        $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue
        if (-not $connections) {
            Write-Log "Could not retrieve network connections." -Severity "WARNING" -FunctionName "Check-NetworkConnections"
            return
        }
        foreach ($conn in $connections) {
            if ($MaliciousIPAddresses -contains $conn.RemoteAddress) {
                $processInfo = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                $processName = if($processInfo) { $processInfo.ProcessName } else { "N/A" }
                Write-Log "CRITICAL HIT: Active connection to known malicious IP. Local: $($conn.LocalAddress):$($conn.LocalPort), Remote: $($conn.RemoteAddress):$($conn.RemotePort), PID: $($conn.OwningProcess), Process: $processName, State: $($conn.State)" -Severity "CRITICAL HIT" -FunctionName "Check-NetworkConnections"
            }
        }
    }
    catch {
        Write-Log "Error retrieving or analyzing network connections: $($_.Exception.Message)" -Severity "WARNING" -FunctionName "Check-NetworkConnections"
    }
    Write-Log "Finished check for suspicious network connections." -FunctionName "Check-NetworkConnections"
}

function Check-DnsCache {
    Write-Log "Starting check of DNS cache for malicious domains..." -FunctionName "Check-DnsCache"
    try {
        $dnsCache = Get-DnsClientCache -ErrorAction SilentlyContinue
        if (-not $dnsCache) {
            Write-Log "Could not retrieve DNS cache entries." -Severity "INFO" -FunctionName "Check-DnsCache" # Might be empty or service disabled
            return
        }
        foreach ($entry in $dnsCache) {
            foreach ($domain in $MaliciousDomains) {
                if ($entry.Entry -like "*$domain*") { # Using -like for broader matching of subdomains
                    Write-Log "CRITICAL HIT: Malicious domain found in DNS cache. Entry: $($entry.Entry), Type: $($entry.Type), Status: $($entry.Status)" -Severity "CRITICAL HIT" -FunctionName "Check-DnsCache"
                }
            }
        }
    }
    catch {
        Write-Log "Error retrieving or analyzing DNS cache: $($_.Exception.Message)" -Severity "WARNING" -FunctionName "Check-DnsCache"
    }
    Write-Log "Finished check of DNS cache." -FunctionName "Check-DnsCache"
}

# --- Persistence Check Functions ---
function Check-ScheduledTasks {
    Write-Log "Starting check for malicious scheduled tasks..." -FunctionName "Check-ScheduledTasks"
    try {
        $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue
        if (-not $tasks) {
            Write-Log "Could not retrieve scheduled tasks." -Severity "WARNING" -FunctionName "Check-ScheduledTasks"
            return
        }
        foreach ($task in $tasks) {
            foreach ($pattern in $MaliciousScheduledTaskNamePatterns) {
                if ($task.TaskName -like $pattern) {
                    $taskInfo = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue
                    $actions = ($task | Get-ScheduledTask).Actions
                    Write-Log "CRITICAL HIT: Suspicious scheduled task found. Name: $($task.TaskName), Path: $($task.TaskPath), State: $($task.State), Actions: $($actions | ForEach-Object {$_.Execute + ' ' + $_.Arguments} | Out-String -Stream), LastRun: $($taskInfo.LastRunTime)" -Severity "CRITICAL HIT" -FunctionName "Check-ScheduledTasks"
                }
            }
        }
    }
    catch {
        Write-Log "Error retrieving or analyzing scheduled tasks: $($_.Exception.Message)" -Severity "WARNING" -FunctionName "Check-ScheduledTasks"
    }
    Write-Log "Finished check for malicious scheduled tasks." -FunctionName "Check-ScheduledTasks"
}

function Check-StartupLNKs {
    Write-Log "Starting check for suspicious LNK files in startup folders..." -FunctionName "Check-StartupLNKs"
    $startupFolders = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
    )
    $wshShell = New-Object -ComObject WScript.Shell -ErrorAction SilentlyContinue
    if (-not $wshShell) {
        Write-Log "Could not create WScript.Shell COM object. Skipping LNK check." -Severity "WARNING" -FunctionName "Check-StartupLNKs"
        return
    }

    foreach ($folder in $startupFolders) {
        if (Test-Path $folder) {
            Write-Verbose "Scanning startup folder: $folder"
            try {
                $lnkFiles = Get-ChildItem -Path $folder -Filter "*.lnk" -File -ErrorAction SilentlyContinue
                foreach ($lnkFile in $lnkFiles) {
                    try {
                        $shortcut = $wshShell.CreateShortcut($lnkFile.FullName)
                        $targetPath = $shortcut.TargetPath
                        $arguments = $shortcut.Arguments
                        Write-Verbose "LNK File: $($lnkFile.FullName), Target: $targetPath, Arguments: $arguments"

                        # Check if target path is suspicious (e.g., in Temp) or if target executable name is known malicious
                        if (($MaliciousProcessNames -contains (Split-Path $targetPath -Leaf)) -or ($SuspiciousLNKTargetPaths | Where-Object {$targetPath -like ($_ + "*")})) {
                            Write-Log "WARNING: Suspicious LNK file found in startup. LNK: $($lnkFile.FullName), Target: $targetPath, Arguments: $arguments" -Severity "WARNING" -FunctionName "Check-StartupLNKs"
                        }
                    }
                    catch {
                        Write-Log "Error reading LNK file $($lnkFile.FullName): $($_.Exception.Message)" -Severity "WARNING" -FunctionName "Check-StartupLNKs"
                    }
                }
            }
            catch {
                 Write-Log "Error enumerating LNK files in $folder : $($_.Exception.Message)" -Severity "WARNING" -FunctionName "Check-StartupLNKs"
            }
        }
    }
    Write-Log "Finished check for startup LNK files." -FunctionName "Check-StartupLNKs"
}

# --- Event Log Querying Function ---
function Query-RelevantEvents {
    Write-Log "Starting query for relevant security and operational events (this may take time)..." -FunctionName "Query-RelevantEvents"

    # Check for Process Creation Events (ID 4688)
    Write-Log "Querying Security log for Event ID 4688 (Process Creation)..." -FunctionName "Query-RelevantEvents"
    $processCreationFilter = @{
        LogName   = 'Security'
        ID        = 4688
        StartTime = (Get-Date).AddDays(-7) # Look back 7 days, adjust as needed
    }
    try {
        $processEvents = Get-WinEvent -FilterHashtable $processCreationFilter -ErrorAction SilentlyContinue
        foreach ($event in $processEvents) {
            $eventData = [xml]$event.ToXml()
            $newProcessName = $eventData.Event.EventData.Data | Where-Object {$_.Name -eq 'NewProcessName'} | Select-Object -ExpandProperty '#text'
            $commandLine = $eventData.Event.EventData.Data | Where-Object {$_.Name -eq 'CommandLine'} | Select-Object -ExpandProperty '#text'

            if ($MaliciousProcessNames -contains (Split-Path $newProcessName -Leaf)) {
                 Write-Log "CRITICAL HIT: Event 4688 - Known malicious process created. Time: $($event.TimeCreated), Process: $newProcessName, CommandLine: $commandLine" -Severity "CRITICAL HIT" -FunctionName "Query-RelevantEvents"
            }
            foreach ($pattern in $MaliciousCommandLinesPatterns) {
                if ($commandLine -match $pattern) {
                    Write-Log "CRITICAL HIT: Event 4688 - Process created with suspicious command line. Time: $($event.TimeCreated), Process: $newProcessName, CommandLine: $commandLine" -Severity "CRITICAL HIT" -FunctionName "Query-RelevantEvents"
                }
            }
        }
    }
    catch {
        Write-Log "Error querying Security log for Event ID 4688: $($_.Exception.Message)" -Severity "WARNING" -FunctionName "Query-RelevantEvents"
    }

    # Check for Scheduled Task Creation Events (ID 106 in TaskScheduler log, 4698 in Security log)
    Write-Log "Querying TaskScheduler log for Event ID 106 (Task Registered) and Security log for 4698 (Task Created)..." -FunctionName "Query-RelevantEvents"
    $taskSchedulerFilter = @{
        LogName   = 'Microsoft-Windows-TaskScheduler/Operational'
        ID        = 106
        StartTime = (Get-Date).AddDays(-7)
    }
    $taskSecurityFilter = @{
        LogName   = 'Security'
        ID        = 4698
        StartTime = (Get-Date).AddDays(-7)
    }
    try {
        $taskEvents = Get-WinEvent -FilterHashtable $taskSchedulerFilter -ErrorAction SilentlyContinue
        $taskEvents += Get-WinEvent -FilterHashtable $taskSecurityFilter -ErrorAction SilentlyContinue
        foreach ($event in $taskEvents) {
             $taskName = ""
             if ($event.Id -eq 106) { # Task Scheduler Log
                $taskName = ($event.Properties | Where-Object {$_.Id -eq 0}).Value # TaskName is usually the first property for 106
             } elseif ($event.Id -eq 4698) { # Security Log
                $eventDataXml = [xml]$event.ToXml()
                $taskName = ($eventDataXml.Event.EventData.Data | Where-Object {$_.Name -eq 'TaskName'}).'#text'
             }

            if ($taskName) {
                foreach ($pattern in $MaliciousScheduledTaskNamePatterns) {
                    if ($taskName -like $pattern) {
                        Write-Log "CRITICAL HIT: Event $($event.Id) - Suspicious scheduled task activity. Time: $($event.TimeCreated), TaskName: $taskName, User: $($event.UserId)" -Severity "CRITICAL HIT" -FunctionName "Query-RelevantEvents"
                    }
                }
            }
        }
    }
    catch {
        Write-Log "Error querying for scheduled task creation events: $($_.Exception.Message)" -Severity "WARNING" -FunctionName "Query-RelevantEvents"
    }
    Write-Log "Finished querying event logs." -FunctionName "Query-RelevantEvents"
}

# --- Certificate Store Inspection Function ---
function Check-MaliciousCertificates {
    Write-Log "Starting check for malicious certificates..." -FunctionName "Check-MaliciousCertificates"
    $certStores = @(
        "Cert:\LocalMachine\AuthRoot",
        "Cert:\LocalMachine\My",
        "Cert:\CurrentUser\AuthRoot",
        "Cert:\CurrentUser\My"
    )
    foreach ($storePath in $certStores) {
        Write-Verbose "Checking certificate store: $storePath"
        try {
            if(Test-Path $storePath) {
                $certs = Get-ChildItem -Path $storePath -ErrorAction SilentlyContinue
                foreach ($cert in $certs) {
                    if ($MaliciousCertificateThumbprints -contains $cert.Thumbprint) {
                        Write-Log "CRITICAL HIT: Known malicious certificate thumbprint found. Store: $storePath, Subject: $($cert.Subject), Thumbprint: $($cert.Thumbprint)" -Severity "CRITICAL HIT" -FunctionName "Check-MaliciousCertificates"
                    }
                }
            } else {
                Write-Log "Certificate store path not found: $storePath" -Severity "INFO" -FunctionName "Check-MaliciousCertificates"
            }
        }
        catch {
            Write-Log "Error accessing certificate store $storePath : $($_.Exception.Message)" -Severity "WARNING" -FunctionName "Check-MaliciousCertificates"
        }
    }
    Write-Log "Finished check for malicious certificates." -FunctionName "Check-MaliciousCertificates"
}

# --- Mutex Detection Function (General Capability) ---
# PDFast.exe analysis [1, 2] listed "NULL" for mutexes, so this is a placeholder
# or for future expansion if specific mutexes for PDFast variants are identified.
function Test-Mutexes {
    Write-Log "Starting check for known malicious mutexes..." -FunctionName "Test-Mutexes"
    $KnownMaliciousMutexes = @(
        # "ExampleGlobalMutexName1", # Add known malicious mutex names here
        # "AnotherMutex"
    )

    if ($KnownMaliciousMutexes.Count -eq 0) {
        Write-Log "No specific malicious mutexes defined for checking." -Severity "INFO" -FunctionName "Test-Mutexes"
        return
    }

    foreach ($mutexName in $KnownMaliciousMutexes) {
        Write-Verbose "Checking for mutex: $mutexName"
        $mutex = $null
        try {
            $mutex =::OpenExisting($mutexName)
            Write-Log "CRITICAL HIT: Potentially malicious mutex '$mutexName' exists." -Severity "CRITICAL HIT" -FunctionName "Test-Mutexes"
            $mutex.Close() # Close the handle if successfully opened
        }

        catch {
            Write-Log "Error checking mutex '$mutexName': $($_.Exception.Message)" -Severity "WARNING" -FunctionName "Test-Mutexes"
        }
    }
    Write-Log "Finished check for malicious mutexes." -FunctionName "Test-Mutexes"
}

# --- Main Execution Block ---
Write-Log "========== PDFast.exe IOC Hunt Started ==========" -Severity "INFO" -FunctionName "Main"
Write-Log "Host: $(Get-ComputerInfo | Select-Object -ExpandProperty CsName)" -Severity "INFO" -FunctionName "Main"
# Write-Log "User: $(::GetCurrent().Name)" -Severity "INFO" -FunctionName "Main"
Write-Log "Log file: $LogPath" -Severity "INFO" -FunctionName "Main"

# Call hunting functions
Find-MaliciousFilesByPath
Find-MaliciousFilesByHash
Test-MaliciousRegistryKeysValues
Find-MaliciousProcesses
Check-NetworkConnections
Check-DnsCache
Check-ScheduledTasks
Check-StartupLNKs
Check-MaliciousCertificates
Test-Mutexes # Will be a no-op if $KnownMaliciousMutexes is empty
Query-RelevantEvents # Optional: Can be very time-consuming

Write-Log "========== PDFast.exe IOC Hunt Finished ==========" -Severity "INFO" -FunctionName "Main"

$criticalHits = Get-Content $LogPath | Where-Object { $_ -like "*CRITICAL HIT*" }
if ($criticalHits) {
    Write-Host "`nCRITICAL HITS FOUND! Review log file: $LogPath" -ForegroundColor Red
    $criticalHits | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
} else {
    Write-Host "`nNo CRITICAL HITS found based on the defined IOCs." -ForegroundColor Green
}

<#
.NOTES
Script Function Name	IOCs Covered	Key PowerShell Cmdlets Used
Find-MaliciousFilesByPath	Specific malicious file paths and patterns.	Resolve-Path, Test-Path 
Find-MaliciousFilesByHash	MD5, SHA1, SHA256 hashes of PDFast.exe and its dropped components.	Get-ChildItem, Get-FileHash 
Test-MaliciousRegistryKeysValues	Known malicious registry key paths and specific values (e.g., for uninstallation, certificates).	Test-Path, Get-ItemProperty 
Find-MaliciousProcesses	Known malicious process names (PDFast.exe, upd.exe) and command-line patterns.	Get-CimInstance Win32_Process 
Check-NetworkConnections	Active TCP connections to known malicious IP addresses.	Get-NetTCPConnection 
Check-DnsCache	DNS cache entries for known malicious domains.	Get-DnsClientCache 
Check-ScheduledTasks	Scheduled tasks matching known malicious names/patterns.	Get-ScheduledTask, Get-ScheduledTaskInfo 
Check-StartupLNKs	LNK files in startup folders pointing to suspicious targets (general persistence).	Get-ChildItem, New-Object -ComObject WScript.Shell
Query-RelevantEvents	Event logs for process creation (4688), task registration (106/4698).	Get-WinEvent 
Check-MaliciousCertificates	Installed certificates matching known malicious thumbprints.	Get-ChildItem Cert:\, Test-Path 
Test-Mutexes	Presence of known malicious mutex names (general capability, none specific for PDFast.exe).	::OpenExisting 
#>

#Requires -Version 5.1
<#
.SYNOPSIS
    Multi-Computer Network Monitor and Remote Command GUI.
.DESCRIPTION
    Monitors computers in parallel using threads and displays status in a Windows Forms GUI.
    Allows running ad-hoc commands or script files on multiple selected computers via a right-click menu.
    Includes "run once detected online" functionality for executing commands when computers come online.
.PARAMETER ComputerList
    Array of computer names or IP addresses to monitor
.EXAMPLE
    .\Computer-Monitor-GUI.ps1 -ComputerList @("Server01", "Server02", "192.168.1.100")
#>

param(
    [Parameter(Mandatory = $false)]
    [string[]]$ComputerList = @()
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# --- Global variables for thread-safe operations ---
$global:ComputerData = @{}
$global:Jobs = @{}
$global:AsyncJobs = @()
$global:PendingCommands = @{}  # Stores commands to run when computers come online
$global:LockObject = New-Object System.Object
$global:RunspacePool = $null
$global:Form = $null
$global:DataGridView = $null
# ---------------------------------------------------


# Function to start continuous ping for a computer IN A THREAD
function Start-ContinuousPing {
    param(
        [string]$ComputerName,
        [System.Collections.Hashtable]$SharedData,
        [System.Object]$LockObject,
        [System.Collections.Hashtable]$PendingCommandsRef
    )
    
    # This scriptblock will run in a separate thread
    $scriptBlock = {
        param($Computer, $DataRef, $DataLock, $PendingCmdsRef)
        
        $lastSeen = Get-Date
        $isOnline = $false
        
        while ($true) {
            try {
                $ping = Test-Connection -ComputerName $Computer -Count 1 -Quiet -ErrorAction SilentlyContinue
                
                $wasOffline = $false
                if ($DataRef.ContainsKey($Computer)) {
                    $wasOffline = -not $DataRef[$Computer].IsOnline
                }
                
                if ($ping) {
                    $isOnline = $true
                    $lastSeen = Get-Date
                    $status = "Online"
                    
                    # If computer just came online, mark it for pending command execution
                    if ($wasOffline -and $isOnline) {
                        $lockTaken2 = $false
                        try {
                            [System.Threading.Monitor]::Enter($DataLock, [ref]$lockTaken2)
                            if ($PendingCmdsRef.ContainsKey($Computer)) {
                                # Add a flag to indicate this computer just came online
                                $DataRef[$Computer].JustCameOnline = $true
                            }
                        }
                        finally {
                            if ($lockTaken2) {
                                [System.Threading.Monitor]::Exit($DataLock)
                            }
                        }
                    }
                }
                else {
                    $isOnline = $false
                    $status = "Offline"
                }
                
                try {
                    $ipAddress = [System.Net.Dns]::GetHostEntry($Computer).AddressList[0].IPAddressToString
                }
                catch {
                    $ipAddress = "Unknown"
                }
                
                $lockTaken = $false
                try {
                    [System.Threading.Monitor]::Enter($DataLock, [ref]$lockTaken)
                    if ($DataRef.ContainsKey($Computer)) {
                        $DataRef[$Computer] = @{
                            Status    = $status
                            LastSeen  = $lastSeen
                            IPAddress = $ipAddress
                            IsOnline  = $isOnline
                            JustCameOnline = $DataRef[$Computer].JustCameOnline
                        }
                    }
                }
                finally {
                    if ($lockTaken) {
                        [System.Threading.Monitor]::Exit($DataLock)
                    }
                }
                
                Start-Sleep -Seconds 2
            }
            catch [System.Management.Automation.PipelineStoppedException] {
                Write-Warning "Stopping monitor for $Computer"
                return
            }
            catch {
                Write-Warning "Error pinging $Computer`: $_"
                Start-Sleep -Seconds 5
            }
        }
    }
    
    $ps = [PowerShell]::Create()
    $ps.RunspacePool = $global:RunspacePool
    $null = $ps.AddScript($scriptBlock).AddArgument($ComputerName).AddArgument($SharedData).AddArgument($LockObject).AddArgument($PendingCommandsRef)
    $ps.BeginInvoke()
    return $ps
}

# Function to create and show the GUI
function Show-MonitorGUI {
    param([string[]]$Computers)
    
    # Create the form
    $global:Form = New-Object System.Windows.Forms.Form
    $global:Form.Text = "Computer Network Monitor"
    $global:Form.Size = New-Object System.Drawing.Size(800, 600)
    $global:Form.StartPosition = "CenterScreen"
    $global:Form.FormBorderStyle = "Sizable"
    $global:Form.MaximizeBox = $true
    
    # Create menu strip
    $menuStrip = New-Object System.Windows.Forms.MenuStrip
    $fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem("File")
    $addComputerMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Add Computer")
    $removeComputerMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Remove Computer")
    $separator = New-Object System.Windows.Forms.ToolStripSeparator
    $exitMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")
    
    $fileMenu.DropDownItems.Add($addComputerMenu)
    $fileMenu.DropDownItems.Add($removeComputerMenu)
    $fileMenu.DropDownItems.Add($separator)
    $fileMenu.DropDownItems.Add($exitMenu)
    $menuStrip.Items.Add($fileMenu)
    $global:Form.Controls.Add($menuStrip)
    
    # Create DataGridView
    $global:DataGridView = New-Object System.Windows.Forms.DataGridView
    $global:DataGridView.Location = New-Object System.Drawing.Point(10, 35)
    $global:DataGridView.Size = New-Object System.Drawing.Size(760, 450)
    $global:DataGridView.Anchor = "Top,Left,Right,Bottom"
    $global:DataGridView.AllowUserToAddRows = $false
    $global:DataGridView.AllowUserToDeleteRows = $false
    $global:DataGridView.ReadOnly = $true
    $global:DataGridView.SelectionMode = "FullRowSelect"
    $global:DataGridView.MultiSelect = $true
    $global:DataGridView.AutoSizeColumnsMode = "Fill"
    
    # Add columns
    $computerColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $computerColumn.Name = "Computer"
    $computerColumn.HeaderText = "Computer Name"
    $computerColumn.Width = 150
    $statusColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $statusColumn.Name = "Status"
    $statusColumn.HeaderText = "Status"
    $statusColumn.Width = 100
    $lastSeenColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $lastSeenColumn.Name = "LastSeen"
    $lastSeenColumn.HeaderText = "Last Seen"
    $lastSeenColumn.Width = 200
    $ipColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $ipColumn.Name = "IPAddress"
    $ipColumn.HeaderText = "IP Address"
    $ipColumn.Width = 150
    
    $global:DataGridView.Columns.Add($computerColumn)
    $global:DataGridView.Columns.Add($statusColumn)
    $global:DataGridView.Columns.Add($lastSeenColumn)
    $global:DataGridView.Columns.Add($ipColumn)
    $global:Form.Controls.Add($global:DataGridView)
    
    # Create Context Menu for DataGridView
    $contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $runCommandItem = New-Object System.Windows.Forms.ToolStripMenuItem("Run Command...")
    $runScriptItem = New-Object System.Windows.Forms.ToolStripMenuItem("Run Script File...")
    $separator1 = New-Object System.Windows.Forms.ToolStripSeparator
    $runOnceOnlineCommandItem = New-Object System.Windows.Forms.ToolStripMenuItem("Run Command Once Online...")
    $runOnceOnlineScriptItem = New-Object System.Windows.Forms.ToolStripMenuItem("Run Script Once Online...")
    $separator2 = New-Object System.Windows.Forms.ToolStripSeparator
    $viewPendingItem = New-Object System.Windows.Forms.ToolStripMenuItem("View Pending Commands...")
    $clearPendingItem = New-Object System.Windows.Forms.ToolStripMenuItem("Clear Pending Commands")
    $contextMenu.Items.AddRange(@($runCommandItem, $runScriptItem, $separator1, $runOnceOnlineCommandItem, $runOnceOnlineScriptItem, $separator2, $viewPendingItem, $clearPendingItem))
    $global:DataGridView.ContextMenuStrip = $contextMenu

    # Create status bar
    $statusBar = New-Object System.Windows.Forms.StatusStrip
    $statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $statusLabel.Text = "Monitoring $($Computers.Count) computers..."
    $statusBar.Items.Add($statusLabel)
    $global:Form.Controls.Add($statusBar)
    
    # Create control buttons
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Location = New-Object System.Drawing.Point(10, 500)
    $buttonPanel.Size = New-Object System.Drawing.Size(760, 40)
    $buttonPanel.Anchor = "Bottom,Left,Right"
    $refreshButton = New-Object System.Windows.Forms.Button
    $refreshButton.Text = "Refresh"
    $refreshButton.Location = New-Object System.Drawing.Point(0, 5)
    $refreshButton.Size = New-Object System.Drawing.Size(80, 30)
    $stopButton = New-Object System.Windows.Forms.Button
    $stopButton.Text = "Stop Monitoring"
    $stopButton.Location = New-Object System.Drawing.Point(90, 5)
    $stopButton.Size = New-Object System.Drawing.Size(120, 30)
    
    $buttonPanel.Controls.Add($refreshButton)
    $buttonPanel.Controls.Add($stopButton)
    $global:Form.Controls.Add($buttonPanel)
    
    # Initialize data rows and shared data
    foreach ($computer in $Computers) {
        $row = $global:DataGridView.Rows.Add()
        $global:DataGridView.Rows[$row].Cells["Computer"].Value = $computer
        $global:DataGridView.Rows[$row].Cells["Status"].Value = "Initializing..."
        $global:DataGridView.Rows[$row].Cells["LastSeen"].Value = "Never"
        $global:DataGridView.Rows[$row].Cells["IPAddress"].Value = "Resolving..."
        
        $global:ComputerData[$computer] = @{
            Status    = "Initializing..."
            LastSeen  = "Never"
            IPAddress = "Resolving..."
            IsOnline  = $false
            JustCameOnline = $false
        }
    }
    
    # Create timer for updating GUI
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000
    $timer.Add_Tick({ Update-GUI })
    $timer.Start()
    
    # Event handlers
    $addComputerMenu.Add_Click({
        $computerName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter computer name or IP address:", "Add Computer", "")
        if ($computerName -and $computerName.Trim() -ne "") {
            Add-ComputerToMonitor $computerName.Trim()
        }
    })
    
    $removeComputerMenu.Add_Click({
        $selectedComputers = Get-SelectedComputers
        if ($selectedComputers.Count -gt 0) {
            foreach($computer in $selectedComputers) {
                 Remove-ComputerFromMonitor $computer
            }
        }
    })
    
    $exitMenu.Add_Click({ $global:Form.Close() })
    $refreshButton.Add_Click({ Update-GUI })
    $stopButton.Add_Click({ $global:Form.Close() })
    $global:Form.Add_FormClosing({ $timer.Stop() })
    
    # Context Menu Event Handlers
    $runCommandItem.Add_Click({
        $selectedComputers = Get-SelectedComputers
        if ($selectedComputers.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Please select at least one computer.", "No Selection")
            return
        }
        
        $command = [Microsoft.VisualBasic.Interaction]::InputBox("Enter command to run:", "Run Remote Command")
        if ([string]::IsNullOrWhiteSpace($command) -eq $false) {
            Start-RemoteCommand -ComputerList $selectedComputers -Command $command
        }
    })
    
    $runScriptItem.Add_Click({
        $selectedComputers = Get-SelectedComputers
        if ($selectedComputers.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Please select at least one computer.", "No Selection")
            return
        }
        
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Filter = "PowerShell Scripts (*.ps1)|*.ps1|All Files (*.*)|*.*"
        $fileDialog.Title = "Select PowerShell Script"
        if ($fileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            Start-RemoteCommand -ComputerList $selectedComputers -ScriptPath $fileDialog.FileName
        }
    })
    
    $runOnceOnlineCommandItem.Add_Click({
        $selectedComputers = Get-SelectedComputers
        if ($selectedComputers.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Please select at least one computer.", "No Selection")
            return
        }
        
        $command = [Microsoft.VisualBasic.Interaction]::InputBox("Enter command to run once online:", "Run Command Once Online")
        if ([string]::IsNullOrWhiteSpace($command) -eq $false) {
            Add-PendingCommand -ComputerList $selectedComputers -Command $command
        }
    })
    
    $runOnceOnlineScriptItem.Add_Click({
        $selectedComputers = Get-SelectedComputers
        if ($selectedComputers.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Please select at least one computer.", "No Selection")
            return
        }
        
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Filter = "PowerShell Scripts (*.ps1)|*.ps1|All Files (*.*)|*.*"
        $fileDialog.Title = "Select PowerShell Script to Run Once Online"
        if ($fileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            Add-PendingCommand -ComputerList $selectedComputers -ScriptPath $fileDialog.FileName
        }
    })
    
    $viewPendingItem.Add_Click({
        Show-PendingCommands
    })
    
    $clearPendingItem.Add_Click({
        Clear-PendingCommands
    })
    
    # Start monitoring jobs
    Start-MonitoringJobs $Computers
    
    # Show form
    $global:Form.Add_Shown({ $global:Form.Activate() })
    [System.Windows.Forms.Application]::Run($global:Form)
}

# Function to start monitoring jobs for all computers
function Start-MonitoringJobs {
    param([string[]]$Computers)
    
    Write-Host "Starting monitoring for $($Computers.Count) computers..."
    
    foreach ($computer in $Computers) {
        $job = Start-ContinuousPing -ComputerName $computer -SharedData $global:ComputerData -LockObject $global:LockObject -PendingCommandsRef $global:PendingCommands
        $global:Jobs[$computer] = $job
        Write-Host "Started monitoring job for: $computer"
    }
}

# Function to update GUI with current data
function Update-GUI {
    if ($global:DataGridView -eq $null) { return }
    
    $lockTaken = $false
    try {
        [System.Threading.Monitor]::Enter($global:LockObject, [ref]$lockTaken)
        
        for ($i = 0; $i -lt $global:DataGridView.Rows.Count; $i++) {
            $row = $global:DataGridView.Rows[$i]
            $computerName = $row.Cells["Computer"].Value
            
            if ($global:ComputerData.ContainsKey($computerName)) {
                $data = $global:ComputerData[$computerName]
                
                $row.Cells["Status"].Value = $data.Status
                $row.Cells["IPAddress"].Value = $data.IPAddress
                
                if ($data.LastSeen -is [DateTime]) {
                    $row.Cells["LastSeen"].Value = $data.LastSeen.ToString("yyyy-MM-dd HH:mm:ss")
                }
                else {
                    $row.Cells["LastSeen"].Value = $data.LastSeen
                }
                
                if ($data.IsOnline) {
                    $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightGreen
                    
                    # Check if this computer just came online and has pending commands
                    if ($data.JustCameOnline -eq $true) {
                        Check-PendingCommands -ComputerName $computerName
                        $data.JustCameOnline = $false  # Reset the flag
                    }
                }
                else {
                    $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightCoral
                }
            }
        }
    }
    finally {
        if ($lockTaken) {
            [System.Threading.Monitor]::Exit($global:LockObject)
        }
    }
}

# Function to add a computer to monitoring
function Add-ComputerToMonitor {
    param([string]$ComputerName)
    
    foreach ($row in $global:DataGridView.Rows) {
        if ($row.Cells["Computer"].Value -eq $ComputerName) {
            [System.Windows.Forms.MessageBox]::Show("Computer '$ComputerName' is already being monitored.", "Duplicate Entry")
            return
        }
    }
    
    $rowIndex = $global:DataGridView.Rows.Add()
    $global:DataGridView.Rows[$rowIndex].Cells["Computer"].Value = $ComputerName
    $global:DataGridView.Rows[$rowIndex].Cells["Status"].Value = "Initializing..."
    $global:DataGridView.Rows[$rowIndex].Cells["LastSeen"].Value = "Never"
    $global:DataGridView.Rows[$rowIndex].Cells["IPAddress"].Value = "Resolving..."
    
    $job = Start-ContinuousPing -ComputerName $ComputerName -SharedData $global:ComputerData -LockObject $global:LockObject -PendingCommandsRef $global:PendingCommands
    
    $lockTaken = $false
    try {
        [System.Threading.Monitor]::Enter($global:LockObject, [ref]$lockTaken)
        $global:ComputerData[$ComputerName] = @{
            Status    = "Initializing..."
            LastSeen  = "Never"
            IPAddress = "Resolving..."
            IsOnline  = $false
            JustCameOnline = $false
        }
        $global:Jobs[$ComputerName] = $job
    }
    finally {
        if ($lockTaken) {
            [System.Threading.Monitor]::Exit($global:LockObject)
        }
    }
}

# Function to remove a computer from monitoring
function Remove-ComputerFromMonitor {
    param([string]$ComputerName)
    
    $jobToStop = $global:Jobs[$ComputerName]
    
    if ($jobToStop) {
        $jobToStop.Stop()
        $jobToStop.Dispose()
    }
    
    $lockTaken = $false
    try {
        [System.Threading.Monitor]::Enter($global:LockObject, [ref]$lockTaken)
        if ($global:ComputerData.ContainsKey($ComputerName)) { $global:ComputerData.Remove($ComputerName) }
        if ($global:Jobs.ContainsKey($ComputerName)) { $global:Jobs.Remove($ComputerName) }
    }
    finally {
        if ($lockTaken) {
            [System.Threading.Monitor]::Exit($global:LockObject)
        }
    }
    
    for ($i = $global:DataGridView.Rows.Count - 1; $i -ge 0; $i--) {
        if ($global:DataGridView.Rows[$i].Cells["Computer"].Value -eq $ComputerName) {
            $global:DataGridView.Rows.RemoveAt($i)
            break
        }
    }
}

# Function to stop all monitoring
function Stop-Monitoring {
    Write-Host "Stopping all monitoring threads..."
    
    $lockTaken = $false
    try {
        [System.Threading.Monitor]::Enter($global:LockObject, [ref]$lockTaken)
        foreach ($computer in $global:Jobs.Keys) {
            $job = $global:Jobs[$computer]
            if ($job) {
                $job.Stop()
                $job.Dispose()
            }
        }
        $global:Jobs.Clear()
    }
    finally {
        if ($lockTaken) {
            [System.Threading.Monitor]::Exit($global:LockObject)
        }
    }
    
    # Clean up any remaining async remote command jobs
    if ($global:AsyncJobs) {
        foreach ($job in $global:AsyncJobs) {
            try {
                if ($job.AsyncResult -and -not $job.AsyncResult.IsCompleted) {
                    $job.PowerShell.Stop()
                }
                if ($job.PowerShell) {
                    $job.PowerShell.Dispose()
                }
            }
            catch {
                Write-Warning "Error cleaning up async job: $_"
            }
        }
        $global:AsyncJobs.Clear()
    }
    
    if ($global:RunspacePool -ne $null) {
        $global:RunspacePool.Close()
        $global:RunspacePool.Dispose()
        $global:RunspacePool = $null
    }
    Write-Host "All monitoring stopped."
}

# Function to get computer list from user input
function Get-ComputerListFromUser {
    $computerInput = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Enter computer names or IP addresses separated by commas:`n`nExample: Server01, Server02, 192.168.1.100",
        "Computer List",
        "localhost, 127.0.0.1"
    )
    
    if ($computerInput) {
        $computers = $computerInput -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
        return $computers
    }
    return @()
}

# --- Remote Command Functions ---

# Helper function to get selected computer names from the grid
function Get-SelectedComputers {
    $computers = @()
    if ($global:DataGridView.SelectedRows.Count -gt 0) {
        foreach ($row in $global:DataGridView.SelectedRows) {
            $computers += $row.Cells["Computer"].Value
        }
    }
    return $computers
}

# Creates and shows a new window to display command results
function Show-ResultsWindow {
    param(
        [string]$Title = "Remote Command Results"
    )
    
    $resultsForm = New-Object System.Windows.Forms.Form
    $resultsForm.Text = $Title
    $resultsForm.Size = New-Object System.Drawing.Size(700, 500)
    $resultsForm.StartPosition = "CenterParent"
    
    $resultsTextBox = New-Object System.Windows.Forms.TextBox
    $resultsTextBox.Multiline = $true
    $resultsTextBox.ReadOnly = $true
    $resultsTextBox.Dock = "Fill"
    $resultsTextBox.ScrollBars = "Vertical"
    $resultsTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $resultsTextBox.BackColor = [System.Drawing.Color]::Black
    $resultsTextBox.ForeColor = [System.Drawing.Color]::LightGray
    
    $resultsForm.Controls.Add($resultsTextBox)
    $resultsForm.Show()
    
    return $resultsTextBox
}

# Starts the remote command execution in a new thread
function Start-RemoteCommand {
    param(
        [string[]]$ComputerList,
        [string]$Command,
        [string]$ScriptPath
    )
    
    $title = if ($Command) { "Run Command" } else { "Run Script" }
    $resultsTextBox = Show-ResultsWindow -Title "$title on $($ComputerList.Count) computer(s)"
    
    $resultsTextBox.Text = "Starting remote execution...`r`n"
    
    # This scriptblock will run in the background thread pool
    $scriptBlock = {
        param($Computers, $Cmd, $Path, $ResultsTextBox)
        
        # Helper function to safely append text to the results window
        # from this background thread.
        $updateGui = {
            param($text)
            try {
                if ($ResultsTextBox.IsDisposed) { return }
                # Use Invoke instead of BeginInvoke for synchronous UI updates
                $ResultsTextBox.Invoke([Action]{
                    $ResultsTextBox.AppendText("`r`n" + $text)
                    $ResultsTextBox.ScrollToCaret()
                })
            }
            catch {
                Write-Warning "Failed to update GUI: $_"
            }
        }
        
        $invokeParams = @{ 
            ErrorAction = 'Continue'
        }
        
        if ($Cmd) {
            & $updateGui "Running Command: $Cmd"
            & $updateGui "Target Computers: $($Computers -join ', ')"
            $invokeParams.ScriptBlock = [ScriptBlock]::Create($Cmd)
        }
        else {
            & $updateGui "Running Script: $Path"
            & $updateGui "Target Computers: $($Computers -join ', ')"
            if (-not (Test-Path $Path)) {
                & $updateGui "ERROR: Script file not found: $Path"
                return
            }
            $invokeParams.FilePath = $Path
        }
        
        foreach ($c in $Computers) {
            & $updateGui "--- Connecting to $c... ---"
            $invokeParams.ComputerName = $c
            try {
                $result = Invoke-Command @invokeParams -ErrorVariable remoteError
                
                if ($result) {
                    # Format output to a string, ensuring it's readable
                    $output = $result | Out-String -Width 120
                    & $updateGui $output.Trim()
                }
                else {
                    & $updateGui "[No output returned]"
                }
                
                # Show any non-terminating errors from the remote command
                if ($remoteError) {
                    foreach ($err in $remoteError) {
                        & $updateGui "WARNING: $($err.ToString())"
                    }
                }
            }
            catch {
                & $updateGui "ERROR connecting to $c`: $($_.Exception.Message)"
                # Also show the full error details if available
                if ($_.CategoryInfo) {
                    & $updateGui "Category: $($_.CategoryInfo.Category) - $($_.CategoryInfo.Reason)"
                }
            }
            & $updateGui "--- Finished $c ---`r`n"
        }
        & $updateGui "All remote commands complete."
    }
    
    # Run the scriptblock in the thread pool
    $ps = [PowerShell]::Create()
    $ps.RunspacePool = $global:RunspacePool
    $null = $ps.AddScript($scriptBlock).AddArgument($ComputerList).AddArgument($Command).AddArgument($ScriptPath).AddArgument($resultsTextBox)
    
    # Start the asynchronous command and store the handle for cleanup
    $asyncResult = $ps.BeginInvoke()
    
    # Store the PowerShell object and async result for later cleanup
    if (-not $global:AsyncJobs) {
        $global:AsyncJobs = @()
    }
    $global:AsyncJobs += @{
        PowerShell = $ps
        AsyncResult = $asyncResult
    }
}

# --- Pending Command Functions ---

# Function to add a pending command for specific computers
function Add-PendingCommand {
    param(
        [string[]]$ComputerList,
        [string]$Command,
        [string]$ScriptPath
    )
    
    $lockTaken = $false
    try {
        [System.Threading.Monitor]::Enter($global:LockObject, [ref]$lockTaken)
        
        foreach ($computer in $ComputerList) {
            if (-not $global:PendingCommands.ContainsKey($computer)) {
                $global:PendingCommands[$computer] = @()
            }
            
            $pendingCmd = @{
                Command = $Command
                ScriptPath = $ScriptPath
                Timestamp = Get-Date
                Executed = $false
            }
            
            $global:PendingCommands[$computer] += $pendingCmd
        }
    }
    finally {
        if ($lockTaken) {
            [System.Threading.Monitor]::Exit($global:LockObject)
        }
    }
    
    $cmdType = if ($Command) { "Command" } else { "Script" }
    $cmdText = if ($Command) { $Command } else { Split-Path $ScriptPath -Leaf }
    [System.Windows.Forms.MessageBox]::Show("$cmdType '$cmdText' queued for $($ComputerList.Count) computer(s). It will run automatically when they come online.", "Command Queued")
}

# Function to check and execute pending commands for newly online computers
function Check-PendingCommands {
    param([string]$ComputerName)
    
    $lockTaken = $false
    try {
        [System.Threading.Monitor]::Enter($global:LockObject, [ref]$lockTaken)
        
        if ($global:PendingCommands.ContainsKey($ComputerName)) {
            $pendingCmds = $global:PendingCommands[$ComputerName] | Where-Object { -not $_.Executed }
            
            if ($pendingCmds.Count -gt 0) {
                Write-Host "Executing $($pendingCmds.Count) pending command(s) for $ComputerName"
                
                foreach ($cmd in $pendingCmds) {
                    if ($cmd.Command) {
                        Start-RemoteCommand -ComputerList @($ComputerName) -Command $cmd.Command
                    }
                    else {
                        Start-RemoteCommand -ComputerList @($ComputerName) -ScriptPath $cmd.ScriptPath
                    }
                    $cmd.Executed = $true
                }
            }
        }
    }
    finally {
        if ($lockTaken) {
            [System.Threading.Monitor]::Exit($global:LockObject)
        }
    }
}

# Function to show pending commands window
function Show-PendingCommands {
    $pendingForm = New-Object System.Windows.Forms.Form
    $pendingForm.Text = "Pending Commands"
    $pendingForm.Size = New-Object System.Drawing.Size(600, 400)
    $pendingForm.StartPosition = "CenterParent"
    
    $listView = New-Object System.Windows.Forms.ListView
    $listView.Dock = "Fill"
    $listView.View = "Details"
    $listView.FullRowSelect = $true
    $listView.GridLines = $true
    
    $listView.Columns.Add("Computer", 120)
    $listView.Columns.Add("Command/Script", 250)
    $listView.Columns.Add("Queued", 120)
    $listView.Columns.Add("Status", 80)
    
    $lockTaken = $false
    try {
        [System.Threading.Monitor]::Enter($global:LockObject, [ref]$lockTaken)
        
        foreach ($computer in $global:PendingCommands.Keys) {
            foreach ($cmd in $global:PendingCommands[$computer]) {
                $item = New-Object System.Windows.Forms.ListViewItem($computer)
                $cmdText = if ($cmd.Command) { $cmd.Command } else { Split-Path $cmd.ScriptPath -Leaf }
                $item.SubItems.Add($cmdText)
                $item.SubItems.Add($cmd.Timestamp.ToString("yyyy-MM-dd HH:mm:ss"))
                $item.SubItems.Add($(if ($cmd.Executed) { "Executed" } else { "Pending" }))
                $listView.Items.Add($item)
            }
        }
    }
    finally {
        if ($lockTaken) {
            [System.Threading.Monitor]::Exit($global:LockObject)
        }
    }
    
    $pendingForm.Controls.Add($listView)
    $pendingForm.Show()
}

# Function to clear all pending commands
function Clear-PendingCommands {
    $result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to clear all pending commands?", "Confirm Clear", [System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $lockTaken = $false
        try {
            [System.Threading.Monitor]::Enter($global:LockObject, [ref]$lockTaken)
            $global:PendingCommands.Clear()
        }
        finally {
            if ($lockTaken) {
                [System.Threading.Monitor]::Exit($global:LockObject)
            }
        }
        [System.Windows.Forms.MessageBox]::Show("All pending commands cleared.", "Commands Cleared")
    }
}

# =================
# Main execution
# =================
try {
    if ($ComputerList.Count -eq 0) {
        $ComputerList = Get-ComputerListFromUser
        if ($ComputerList.Count -eq 0) {
            Write-Host "No computers specified. Exiting."
            exit
        }
    }
    
    $throttleLimit = $ComputerList.Count + 10 # +10 to handle ad-hoc command threads
    if ($throttleLimit -lt 1) { $throttleLimit = 1 }
    if ($throttleLimit -gt 50) { $throttleLimit = 50 } 
    
    Write-Host "Computers to monitor: $($ComputerList -join ', ')"
    Write-Host "Initializing Runspace Pool with throttle limit: $throttleLimit"
    
    $global:RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $throttleLimit)
    $global:RunspacePool.Open()
    
    Show-MonitorGUI $ComputerList
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    Write-Host "GUI closed. Cleaning up resources..."
    Stop-Monitoring
}

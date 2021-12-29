    <#
    .DESCRIPTION
        Vuln ID: V-225230
        STIG ID: APPNET0062
        Rule Title: The .NET CLR must be configured to use FIPS approved encryption modules.
    #>

    $XmlElement = "enforceFIPSPolicy"
    $XmlAttributeName = "enabled"
    $XmlAttributeValue = "false" # Non-compliant setting
    $Compliant = $true # Set initial compliance for this STIG item to true.

    If (Test-Path $env:windir\Temp\Evaluate-STIG\Evaluate-STIG_Net4FileList.txt) {
        $allConfigFiles = Get-Content $env:windir\Temp\Evaluate-STIG\Evaluate-STIG_Net4FileList.txt
    }
    Else {
        # Get .Net 4 Framework machine.config files
        $frameworkMachineConfig = "$env:SYSTEMROOT\Microsoft.NET\Framework\v4.0.30319\Config\machine.config"
        $framework64MachineConfig = "$env:SYSTEMROOT\Microsoft.NET\Framework64\v4.0.30319\Config\machine.config"

        # Get hard disk drive letters
        $driveLetters = (Get-CimInstance Win32_LogicalDisk | Where-Object DriveType -eq 3).DeviceID

        # Get configuration files
        $allConfigFiles = @()
        $allConfigFiles += (Get-ChildItem $frameworkMachineConfig).FullName
        $allConfigFiles += (Get-ChildItem $framework64MachineConfig).FullName
        $allConfigFiles += (ForEach-Object -InputObject $driveLetters { (Get-ChildItem ($_.DeviceID + "\") -Recurse -Filter *.exe.config -ErrorAction SilentlyContinue | Where-Object { ($_.FullName -NotLike "*Windows\CSC\*") -and ($_.FullName -NotLike "*Windows\WinSxS\*") }).FullName })
    }

    ForEach ($File in $allConfigFiles) {
        If (Test-Path $File) {
            $XML = (Select-Xml -Path $File / -ErrorAction SilentlyContinue).Node
            $xmlDoc = $File
            If ($XML) {
                $Node = ($XML | Select-Xml -XPath "//$($XmlElement)" | Select-Object -ExpandProperty "Node" | Where-Object $XmlAttributeName -eq $XmlAttributeValue | Select-Object *)
                If ($Node) {
                    $xmlDoc.configuration.runtime.enforceFIPSPolicy.enabled = "true"
                }
            }
        }
    }

    If ($Compliant -eq $true) {
        write-host "No machine.config or *.exe.config files found with 'enforceFIPSPolicy enabled=false'."
        #write-host "$FindingDetails"
    }
    

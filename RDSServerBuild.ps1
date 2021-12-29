$RDSServerName = "AZURW4FH11B4RD2"
$FQDN = "AZURW4FH11B4RD2.SEC.local"

New-Alias -Name "wh" -Value Write-Host

#Automated deployment of RDS server roles to a remote server

Import-module RemoteDesktop

wh "Beginning Initial Deployment to $RDSServerName" -ForegroundColor Green

New-RDSessionDeployment -connectionBroker $FQDN -sessionhost $FQDN -WebAccessServer $FQDN

wh "taking a 10 minute break while install finishes" -ForegroundColor DarkYellow
start-sleep -seconds 360
#restart-computer -ComputerName $RDSServerName -Force
#Start-Sleep -Seconds 60

wh "Adding RDS Licensing role to $FQDN" -ForegroundColor Green
Add-RDServer -Server $FQDN -Role RDS-LICENSING -ConnectionBroker $FQDN
Start-Sleep -Seconds 120
wh "set licensing mode" -ForegroundColor Green
Set-RDLicenseConfiguration -LicenseServer $FQDN -Mode PerUser -ConnectionBroker $FQDN
Start-Sleep -Seconds 120
wh "adding RDS Gateway role to $FQDN" -ForegroundColor Green
Add-RDServer -Server $FQDN -Role "RDS-GATEWAY" -ConnectionBroker $FQDN -GatewayExternalFqdn "rdg.seceis.army.mil" 

start-sleep -seconds 120
Restart-Computer -ComputerName $RDSServerName -Force
#wh "setting RD Gateway configuration" -ForegroundColor Green
#invoke-command -computername $FQDN -ScriptBlock {Set-RDDeploymentGatewayConfiguration -GatewayMode Custom -LogonMethod AllowUserToSelectDuringConnection -BypassLocal $True -UseCachedCredentials $true -GatewayExternalFqdn "rdg.seceis.army.mil"}

#Add-RDServer -Server "$RDSServerName.sec.local" -Role RDS-GATEWAY -GatewayExternalFqdn "rdg.seceis.army.mil" -ConnectionBroker "$RDSServerName.sec.local" 

#wh "taking a 1 minute break while install finishes" -ForegroundColor DarkYellow
#start-sleep -seconds 60
#restart-computer -ComputerName $RDSServerName -Force
Start-Sleep -Seconds 60

wh "Importing Certificate" -ForegroundColor Green
copy-item "\\fs\Share02\Josh\Certificates\rdg_seceis_army_mil.pfx" "\\$RDSServerName\C$\temp\"

$mypwd = (ConvertTo-SecureString -String "DREN1234!@#$" -AsPlainText -force)
invoke-command -computername $RDSServerName -ScriptBlock {Import-PFXCertificate -FilePath "C:\temp\rdg_seceis_army_mil.pfx" -exportable -Password $mypwd -CertStoreLocation Cert:\LocalMachine\my}
$thumbprint = invoke-command -HideComputerName $RDSServerName -ScriptBlock {(Get-ChildItem "cert:\localmachine\my\" | where{$_.Subject -eq "CN=RDG.SECEIS.ARMY.MIL"}).Thumbprint}

invoke-command -computername $RDSServerName -ScriptBlock {Set-RDCertificate -Role RDGateway -Thumbprint $thumbprint -ConnectionBroker $FQDN}
invoke-command -computername $RDSServerName -ScriptBlock {Set-RDCertificate -Role RDPublishing -Thumbprint $thumbprint -ConnectionBroker $FQDN}
invoke-command -computername $RDSServerName -ScriptBlock {Set-RDCertificate -Role RDWebAccess -Thumbprint $thumbprint -ConnectionBroker $FQDN}

invoke-command -computername $RDSServerName -scriptblock{start "C:\temp\Set-RDPublishedName.ps1" -ArgumentList ' -clientaccessname "rdg.seceis.army.mil"'}
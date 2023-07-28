$subs = Get-AzSubscription 
$orphanedVnets = @()
$usedVnets = @()
foreach ($Sub in $Subs) {
    if ($sub.Name -like "luck*") {
        Write-Host "***************************"
        Write-Host " "
        $Sub.Name 

        $SelectSub = Select-AzSubscription -SubscriptionName $Sub.Name

        $VNETs = Get-AzVirtualNetwork 
        foreach ($VNET in $VNETs) {
            $vnetDevCount = 0
            Write-Host "--------------------------"
            Write-Host " "
            Write-Host "   vNet: " $VNET.Name 
            Write-Host "   AddressPrefixes: " ($VNET).AddressSpace.AddressPrefixes

            $vNetExpanded = Get-AzVirtualNetwork -Name $VNET.Name -ResourceGroupName $VNET.ResourceGroupName -ExpandResource 'subnets/ipConfigurations' 

            foreach ($subnet in $vNetExpanded.Subnets) {
                $vnetDevCount += $subnet.IpConfigurations.Count
                Write-Host "       Subnet: " $subnet.Name
                if ($subnet.IpConfigurations.Count -eq 0) {
                    Write-Host "   subnet: " $subnet.Name + " has zero connected devices" -ForegroundColor Yellow
                }
                else {
                    Write-Host "          Connected devices " $subnet.IpConfigurations.Count
                }
                foreach ($ipConfig in $subnet.IpConfigurations) {
                    Write-Host "            " $ipConfig.PrivateIpAddress
                }
            }
            if ($vnetDevCount -eq 0) {
                Write-Host "   vNet: " $VNET.Name + " has zero connected devices" -ForegroundColor Red
                $orphanedVnets += $VNET
            }
            else {
                Write-Host "   vNet: " $VNET.Name + " has $vnetDevCount connected devices"
                $usedVnets += $VNET
            }

            Write-Host " " 
        } 
    }
}
Write-Host "`n Orphaned VNets: " -ForegroundColor Magenta
$orphanedVnets | ft

Write-host "`n VNets in use: " -ForegroundColor Green
$usedVnets | ft

###Bulk Create New-ADComputer
###Load values for PCName, OU Distinguished name, and Description in to ComputerOUDesc.csv and verify path of $computerData is correct
###A List of OU and their DN can be found with Get-ADOrganizationalUnit -Filter 'Name -like "*"' | Format-Table Name, DistinguishedName -A
###CSV EXAMPLE BELOW
###ComputerName,ORG,Description
###"LEEEW4FH11NBDRH","OU=Workstations,OU=AFMIS,OU=SEC,DC=SEC,DC=local","Bob Hermanns Workstation"
###"LEEEW4FH11NBDEE","OU=Workstations,OU=CRRD,OU=SEC,DC=SEC,DC=local","Ethan Eanes Workstation"
###"LEEEW4FH11NBD48","OU=Workstations,OU=ITSB,OU=SEC,DC=SEC,DC=local","DREN ITSB Temp Workstation"

$computerData = Import-Csv -path 'F:\Shares\Share02\Josh\Dev\ComputerOUDesc.csv' -Delimiter ','
#$computerData | Format-Table -AutoSize
foreach($row in $computerData){
    $PCName = $row.ComputerName
    $PCOrg = $row.Org
    $PCDesc = $row.Description
    #if (@(Get-ADComputer $PCName -ErrorAction SilentlyContinue).Count) {
        try{
            Get-ADComputer $PCName -ErrorAction STOP
            Write-Host "#########################"  
            Write-Host "Computer object $PCName exists"
            Write-Host "#########################"
    }
        catch{
            Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!"  
            Write-Host "Computer object NOT FOUND"
            Write-Host "Creating object $PCName"
            Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!"
            #New-ADComputer -name $PCName -SAMAccountName $PCName -Path $PCOrg -Description $PCDesc
    }
    
}


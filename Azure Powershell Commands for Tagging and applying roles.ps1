Connect-AzureAD 
$TeamTag = Read-Host "Enter the team name to tag" 
$AzureADGroupName = Read-Host "Enter the AD Group" 
$GroupID = (get-azureadgroup -SearchString "AFMISAdmins").ObjectID 
#$SubScope = (Get-AzSubscription).Id 

$ResourceGroupsToTag = (Get-AzVM | where-object {$_.Tags['Team'] -eq "$TeamTag"}).ResourceGroupName 

Foreach($RG in $ResourceGroupsToTag){set-azresourcegroup -name $RG -tag @{'Team' = "$TeamTag"}} 

$RGsToAssignRole = (Get-AzResourceGroup -Tag @{'Team' = 'AFMIS'}).ResourceGroupName

Foreach($RG in $RGsToAssignRole){
New-AzRoleAssignment -ObjectId $GroupID -RoleDefinitionName "Virtual Machine User Login" -ResourceGroupName $RG
}
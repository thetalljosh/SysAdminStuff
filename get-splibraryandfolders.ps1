$ReportOutput = "C:\Temp\SPOPermissions\"
if (!(test-path $ReportOutput)) {
    mkdir $ReportOutput
}
Function Get-PnPFolderPermission([Microsoft.SharePoint.Client.Folder]$Folder) {
    Try {
        Write-host -f Yellow "Processing Folder '$($Folder.Name)' at '$($Folder.ServerRelativeUrl)'..."
        #Get permissions assigned to the Folder
        Get-PnPProperty -ClientObject $Folder.ListItemAllFields -Property HasUniqueRoleAssignments, RoleAssignments
  
        #Check if Folder has unique permissions
        $HasUniquePermissions = $Folder.ListItemAllFields.HasUniqueRoleAssignments
     
        #Loop through each permission assigned and extract details
        $PermissionCollection = @()
        Foreach ($RoleAssignment in $Folder.ListItemAllFields.RoleAssignments) {
            #Get the Permission Levels assigned and Member
            Get-PnPProperty -ClientObject $RoleAssignment -Property RoleDefinitionBindings, Member
 
            #Leave the Hidden Permissions
            If ($RoleAssignment.Member.IsHiddenInUI -eq $False) {    
                #Get the Principal Type: User, SP Group, AD Group
                $PermissionType = $RoleAssignment.Member.PrincipalType
                $PermissionLevels = $RoleAssignment.RoleDefinitionBindings | Select -ExpandProperty Name
  
                #Remove Limited Access
                $PermissionLevels = ($PermissionLevels | Where { $_ -ne "Limited Access" }) -join ","
                If ($PermissionLevels.Length -eq 0) { Continue }
  
                #Get SharePoint group members
                If ($PermissionType -eq "SharePointGroup") {
                    #Get Group Members
                    $GroupName = $RoleAssignment.Member.LoginName
                    $GroupMembers = Get-PnPGroupMember -Identity $GroupName
                  
                    #Leave Empty Groups
                    If ($GroupMembers.count -eq 0) { Continue }
                    If ($GroupName -notlike "*System Account*" -and $GroupName -notlike "*SharingLinks*" -and $GroupName -notlike "*tenant*" -and $GroupName -notlike `
                            "Excel Services Viewers" -and $GroupName -notlike "Restricted Readers" -and $GroupName -notlike "Records Center Web Service Submitters for records") { 
                        ForEach ($User in $GroupMembers) {
                            #Add the Data to Folder
                            $Permissions = New-Object PSObject
                            $Permissions | Add-Member NoteProperty FolderName($Folder.Name)
                            $Permissions | Add-Member NoteProperty FolderURL($Folder.ServerRelativeUrl)
                            $Permissions | Add-Member NoteProperty User($User.Title)
                            $Permissions | Add-Member NoteProperty Type($PermissionType)
                            $Permissions | Add-Member NoteProperty Permissions($PermissionLevels)
                            $Permissions | Add-Member NoteProperty GrantedThrough("SharePoint Group: $($RoleAssignment.Member.LoginName)")
                            $PermissionCollection += $Permissions
                        }
                    }
                }
                Else {
                    #Add the Data to Folder
                    $Permissions = New-Object PSObject
                    $Permissions | Add-Member NoteProperty FolderName($Folder.Name)
                    $Permissions | Add-Member NoteProperty FolderURL($Folder.ServerRelativeUrl)
                    $Permissions | Add-Member NoteProperty User($RoleAssignment.Member.Title)
                    $Permissions | Add-Member NoteProperty Type($PermissionType)
                    $Permissions | Add-Member NoteProperty Permissions($PermissionLevels)
                    $Permissions | Add-Member NoteProperty GrantedThrough("Direct Permissions")
                    $PermissionCollection += $Permissions
                }
            }
        }
        #Export Permissions to CSV File
        $PermissionCollection | Export-CSV $ReportFile -NoTypeInformation -Append
        Write-host -f Green "`n*** Permissions of Folder '$($Folder.Name)' at '$($Folder.ServerRelativeUrl)' Exported Successfully!***"
    }
    Catch {
        write-host -f Red $folder.Name "- Error Generating Folder Permission Report!" $_.Exception.Message
    }
}
function get-libraryroles($LibraryName) {
    # Get the document library
    $Library = Get-PnpList -Identity $LibraryName -Includes RoleAssignments
 
    # Get all users and groups who has access
    $RoleAssignments = $Library.RoleAssignments
    $PermissionCollection = @()
    Foreach ($RoleAssignment in $RoleAssignments) {
        #Get the Permission Levels assigned and Member
        Get-PnPProperty -ClientObject $roleAssignment -Property RoleDefinitionBindings, Member
 
        #Get the Principal Type: User, SP Group, AD Group
        $PermissionType = $RoleAssignment.Member.PrincipalType
        $PermissionLevels = $RoleAssignment.RoleDefinitionBindings | Select -ExpandProperty Name
     
        #Get all permission levels assigned (Excluding:Limited Access)
        $PermissionLevels = ($PermissionLevels | Where { $_ -ne "Limited Access" }) -join ","
        If ($PermissionLevels.Length -eq 0) { Continue }
 
        #Get SharePoint group members
        If ($PermissionType -eq "SharePointGroup") {
            #Get Group Members
            $GroupMembers = Get-PnPGroupMember -Identity $RoleAssignment.Member.LoginName                 
            #Leave Empty Groups
            If ($GroupMembers.count -eq 0) { Continue }
 
            ForEach ($User in $GroupMembers) {
                #Add the Data to Object
                $Permissions = New-Object PSObject
                $Permissions | Add-Member NoteProperty User($User.Title)
                $Permissions | Add-Member NoteProperty Type($PermissionType)
                $Permissions | Add-Member NoteProperty Permissions($PermissionLevels)
                $Permissions | Add-Member NoteProperty GrantedThrough("SharePoint Group: $($RoleAssignment.Member.LoginName)")
                $PermissionCollection += $Permissions
            }
        }
        Else {
            #Add the Data to Object
            $Permissions = New-Object PSObject
            $Permissions | Add-Member NoteProperty User($RoleAssignment.Member.Title)
            $Permissions | Add-Member NoteProperty Type($PermissionType)
            $Permissions | Add-Member NoteProperty Permissions($PermissionLevels)
            $Permissions | Add-Member NoteProperty GrantedThrough("Direct Permissions")
            $PermissionCollection += $Permissions
        }
    }
    #Export Permissions to CSV File
    #$PermissionCollection
    $PermissionCollection | Export-CSV "$ReportOutput\$LibraryName Library Permissions.csv" -NoTypeInformation
    Write-host -f Green "Permission Report Generated Successfully for $libraryname!"
    return $PermissionCollection

}

function Get-LibraryAndFolders {

    # get all libraries

    $lists = Get-PnPList | Where-Object { $_.BaseType -eq 'DocumentLibrary' }
    

    # loop through all the libraries
    foreach ($list in $lists) {
        
        $folderArr.add(
            [pscustomobject]@{
                "Name" = $list.Title
                "Type" = "Library"
                "Url"  = $list.RootFolder.ServerRelativeUrl
            }
        )
        

        # get all the folders in the current list
        $folders = Get-PnPFolder -ListRootFolder $list

        # loop through all the folders
        foreach ($folder in $folders) {
            #$properties = Get-PnPProperty -ClientObject $Folder.ListItemAllFields -Property HasUniqueRoleAssignments, RoleAssignments

            # add the folder name, type and Url to the array
            $folderArr.add(
                [pscustomobject]@{
                    "Name" = $folder.Name
                    "Type" = "Folder"
                    "Url"  = $folder.ServerRelativeUrl
                    #"Properties" = $Folder.ListItemAllFields.RoleAssignments
                }
            )

        }
    }
}

function Get-LibraryAndFolders2($namecontains) {
    $folderArr.clear()
    # get all libraries
    $lists = Get-PnPList | Where-Object { $_.BaseType -eq 'DocumentLibrary' -and $_.Title.Contains($namecontains) }
    

    # loop through all the libraries
    foreach ($list in $lists) {
        write-host "Found list: " $list.Title
        $folderArr.add(
            [pscustomobject]@{
                "Name"        = $list.Title
                "Type"        = "Library"
                "Url"         = $list.RootFolder.ServerRelativeUrl
            }
        )
        

        # get all the folders in the current list
        $folders = Get-PnPFolder -ListRootFolder $list

        # loop through all the folders
        foreach ($folder in $folders) {
            # add the folder name, type and Url to the array
            $folderArr.add(
                [pscustomobject]@{
                    "Name"        = $folder.Name
                    "Type"        = "Folder"
                    "Url"         = $folder.ServerRelativeUrl
                }
            )

        }
    }
}

# connect to rootsite
Connect-PnPOnline -Url "https://luckcompanies.sharepoint.com/" -Interactive

# create a array to store all objects in
$folderArr = [System.Collections.Generic.List[PSObject]]::new()
$LibraryArray = [System.Collections.Generic.List[PSObject]]::new()
$nestedLibraryArr = [System.Collections.Generic.List[PSObject]]::new()
$nestedItemsArr = [System.Collections.Generic.List[PSObject]]::new()
$filesArr = [System.Collections.Generic.List[PSObject]]::new()
$allArr = [System.Collections.Generic.List[PSObject]]::new()

"subsites"

# get subsites
$subsites = Get-PnPSubWeb | where { $_.title -like "Documents and Reports Center" }
# get library and folders
#Get-LibraryAndFolders -permsCheck $false

# loop through all subsites
foreach ($subsite in $subsites) {

    "connect subsite"
    # connect to subsite
    Connect-PnPOnline -Url $subsite.Url -Interactive

    "get library and folders"
    # get library and folders
    #Get-LibraryAndFolders
    Get-LibraryAndFolders2("Financ")

    foreach ($item in $folderArr) {
        #write-host "Adding $item to allArr"
        #$allArr.add($item)

        if ($item.Type -in "Folder") {
            "Iterating through folder $item"
            #$itemperm = Get-PnPListItemPermission -List $item.Name | convertto-json 
            $itemperm = get-libraryroles -LibraryName $item.Name
            $nesteditems = Get-PnPFolderItem $item.Name  -Recursive -Verbose 
            Foreach ($nest in $nesteditems) {

                $nestUrl = $item.url + "/" + $nest.Name

                if ($nest.Type -in "Folder") {
                    write-host "Processing " $nest.Name " in folder " $item.name
                    $LibraryArray.add(
                        [pscustomobject]@{
                            "Name"        = $nest.Name
                            "Type"        = "Folder"
                            "Url"         = $nestUrl
                            "Library Permissions" = $itemperm | ConvertTo-Json
                        }
                    )
                    #Get-PnPFile -Url $item.url -AsFileObject
                }
                <#
                if ($nest.Type -in "File") {
                    write-host "Found file " $nest.Name " in folder " $item.name

                    $filesArr.add(
                        [pscustomobject]@{
                            "Name"        = $nest.Name
                            "Type"        = "File"
                            "Url"         = $nestUrl
                            "Permissions" = "Parent folder permission: " + $itemperm
                        }
                    )
                }
                #>
                
            }           
        }
        
        if ($item.Type -eq "library") {
            #connect back to parent site
            #Connect-PnPOnline -Url "https://luckcompanies.sharepoint.com/" -Interactive
            "Iterating through library $item"
            <#    
            $libperm = get-libraryroles -LibraryName $item.Name
                    
                $nestedLibraryArr.add(
                    [pscustomobject]@{
                        "Name"        = $item.Name
                        "Url"         = $item.Url
                        "Type"        = "Library"
                        "Permissions" = $libperm | convertto-csv
                    }
                )
            #>
            
            $listItems = Get-PnPListItem -List $item.Name -fields "Path", "Title", "GUID", "ID", "Name", "FileLeafRef", "FileRef", "FileDirRef","Modified","Modified_x0020_By","SMTotalSize"
            $i = 1
            $c = $listItems.Count
            foreach ($li in $listItems) {
                if ($li.HasUniqueRoleAssignments -eq $true) {
                    $liperms = (Get-PnPListItemPermission -List $item.Name -Identity $li.Id).permissions | ConvertTo-Json -depth 5
                }
                else {
                    $liperms = "Inherit from parent: " + $item.Name
                }
                $pe = ($i / $c) * 100
                write-host "Processing" $item.Name "Percent Complete: " $pe "%"
                if(($li.fieldvalues.FileLeafRef).ToString().contains(".")){                
                    $litype = ($li.fieldvalues.FileLeafRef).ToString().split(".")[-1]
                }  
                else{
                    $litype = "Folder"
                }
                $nestedItemsArr.add(
                    [pscustomobject]@{
                        "Name"        = $li.fieldvalues.FileLeafRef
                        "Path"        = $li.fieldvalues.FileRef
                        "Type"        = $litype
                        "Created"     = $li.fieldvalues.Created
                        "Last Modified" = $li.fieldvalues.Modified
                        "Last Modified By" = $li.fieldvalues.Modified_x0020_By
                        "Parent Library"     = $item.Name
                        "Size (KB)"       =  [Math]::Round($li.FieldValues.SMTotalSize.LookupId/1KB,2)
                        "Item Permissions" = $liperms
                    }
                )
                $i++
                
            }     
            
        }
        #Connect-PnPOnline -Url $subsite.Url -Interactive
        #>
        

    }
    # disconnect from subsite
    Disconnect-PnPOnline
}

write-host "Nested Items contains " $nestedItemsArr.Count " records"
$nestedItemsArr | export-csv  "$ReportOutput\NestedItems.csv" 
<#
write-host "Sublist array contains " $nestedLibraryArr.Count " records"
$nestedLibraryArr | Export-CSV "$ReportOutput\SubLists.csv" -NoTypeInformation

Write-host "Subfolder array contains " $LibraryArray.count " records"
$LibraryArray | Export-CSV "$ReportOutput\SubFolders.csv" -NoTypeInformation

write-host "Folder array contains " $folderarr.Count " records"
$folderArr | Export-CSV "$ReportOutput\Folders.csv" -NoTypeInformation
#>
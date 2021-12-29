$versionsToRemove = get-content c:\temp\aspVersions.txt
$listofComputers = get-content c:\temp\list.txt

foreach($computer in $listofComputers){
    foreach($version in $versionsToRemove)
    {
    remove-item -Path "\\$computer\C$\Program Files\dotnet\shared\Microsoft.AspNetCore.All\$version" -Recurse -Force
    }
    }


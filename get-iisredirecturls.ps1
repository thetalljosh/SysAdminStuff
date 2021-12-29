Function Get-IISRedirectURLs { 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$false)][String]$SiteName 
    ) 
     
    If ([String]::IsNullOrEmpty($SiteName)) { 
        Get-Website | ForEach-Object { 
            $SiteName = $_.Name 
            $prop = Get-WebConfigurationProperty -filter /system.webServer/httpRedirect -name 'destination' -PSPath "IIS:\Sites\$SiteName" 
            Write-Host "$SiteName`t$($prop.value)" 
        } 
 
    } Else { 
        $prop = Get-WebConfigurationProperty -filter /system.webServer/httpRedirect -name 'destination' -PSPath "IIS:\Sites\$SiteName" 
        Write-Host "$SiteName`t$($prop.value)" 
    } 
} 
Get-IISRedirectURLs
Function Remove-GPOUnknownSIDs {
   param ([parameter(mandatory = $true)][Microsoft.GroupPolicy.Gpo]$GPO)
   $name = $GPO.DisplayName
   $gpoSecurity = $GPO.GetSecurityInfo()
   $UnknownSIDs = $gpoSecurity.Trustee | Where SidType -Like "Unknown"
      foreach($UnknownSID in $UnknownSIDs) {
         $SIDToRemove = $UnknownSID.Sid.Value
         $gpoSecurity.RemoveTrustee($SIDToRemove)
         $GPO.SetSecurityInfo($gpoSecurity)
      }
}

$domain = "sec.local"
$aGPOs = Get-GPO -Domain $domain -All
   foreach($GPO in $aGPOs) {
      Remove-GPOUnknownSIDs $GPO
   }    
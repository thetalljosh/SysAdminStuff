$ProvisionedAppPackageNames = @(


"Microsoft.BingWeather"

"Microsoft.Getstarted"

"Microsoft.Messaging"

"Microsoft.MicrosoftSolitaireCollection"

"Microsoft.OneConnect"

"Microsoft.People"

"Microsoft.SkypeApp"

"Microsoft.StorePurchaseApp"

"Microsoft.Wallet"

"microsoft.windowscommunicationsapps"

"Microsoft.WindowsFeedbackHub"

"Microsoft.WindowsMaps"

"Microsoft.WindowsSoundRecorder"

"Microsoft.XboxApp"

"Microsoft.XboxGameOverlay"

"Microsoft.XboxIdentityProvider"

"Microsoft.XboxSpeechToTextOverlay"

"Microsoft.ZuneMusic"

"Microsoft.ZuneVideo"

)

foreach ($ProvisionedAppName in $ProvisionedAppPackageNames) {

Get-AppXProvisionedPackage -Online | where DisplayName -EQ $ProvisionedAppName | Remove-AppxProvisionedPackage -Online

}
new-itemproperty "HKCU:\Software\Microsoft\Exchange" -name "AlwaysUseLegacyAuthForAutodiscover" -Value 1 -Type DWORD -Force
new-itemproperty "HKCU:\Software\policies\Microsoft\Office\16.0\Outlook\RPC" -name "EnableSmartCard" -Value 1 -Type DWORD -Force


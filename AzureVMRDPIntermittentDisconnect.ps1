set-itemproperty 'hklm:\SYSTEM\CurrentControlSet\Control\Terminal Server\winstations\rdp-tcp' -name MaxInstanceCount -value 4294967295  -type DWORD
set-itemproperty 'hklm:\SYSTEM\CurrentControlSet\Control\Terminal Server\winstations\rdp-tcp' -name MaxIdleTime -value 0 -type DWORD
set-itemproperty 'hklm:\SYSTEM\CurrentControlSet\Control\Terminal Server\winstations\rdp-tcp' -name fInheritMaxIdleTime -value 1 -type DWORD
set-itemproperty 'hklm:\SYSTEM\CurrentControlSet\Control\Terminal Server\winstations\rdp-tcp' -name MaxconnectionTime -value 0 -type DWORD
set-itemproperty 'hklm:\SYSTEM\CurrentControlSet\Control\Terminal Server\winstations\rdp-tcp' -name fInheritMaxDisconnectionTime -value 1 -type DWORD
set-itemproperty 'hklm:\SYSTEM\CurrentControlSet\Control\Terminal Server\winstations\rdp-tcp' -name MaxDisconnectionTime -value 0 -type DWORD
set-itemproperty 'hklm:\SYSTEM\CurrentControlSet\Control\Terminal Server\winstations\rdp-tcp' -name fInheritMaxSessionTime -value 1 -type DWORD
set-itemproperty 'hklm:\Software\policies\microsoft\windows nt\Terminal Services\' -name keepAliveInterval -value 1 -type DWORD
set-itemproperty 'hklm:\Software\policies\microsoft\windows nt\Terminal Services\' -name keepAliveEnable -value 1 -type DWORD
set-itemproperty 'hklm:\SYSTEM\CurrentControlSet\Control\Terminal Server\winstations\rdp-tcp' -name keepAliveTimeout -value 1 -type DWORD
set-itemproperty 'hklm:\SYSTEM\CurrentControlSet\Control\Terminal Server\winstations\rdp-tcp' -name fQueryUserConfigFromLocalMachine -value 1 -type DWORD

<# following are not STIG compliant
set-itemproperty 'hklm:\SYSTEM\CurrentControlSet\Control\Terminal Server\winstations\rdp-tcp' -name MinEncryptionLevel -value 1
set-itemproperty 'hklm:\SYSTEM\CurrentControlSet\Control\Terminal Server\winstations\rdp-tcp' -name SecurityLayer -value 0
#>
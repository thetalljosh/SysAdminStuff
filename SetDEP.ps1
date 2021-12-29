#Be careful with this one. If you screw up DEP, it'll lock out bitlocker

Suspend-BitLocker -MountPoint $env:SystemDrive -RebootCount 2
bcdedit /set nx OptOut
Resume-BitLocker -MountPoint $env:SystemDrive
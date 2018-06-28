import-module "$PSScriptroot\HpBCU.psm1" -force

Export-HpBcu -BcuPath $PSScriptroot -ConfigFile "$PSScriptRoot\HPConfig.txt"

Copy-Item "$PSScriptRoot\HPConfig.txt" "$PSScriptRoot\New_HPConfig.txt"
#$BiosData = Get-BiosData -ConfigFile "$PSScriptRoot\New_HPConfig.txt"

Set-BiosData -ConfigFile "$PSScriptRoot\New_HPConfig.txt" -Section "Post Messages" -Value "Disable"
Set-BiosData -ConfigFile "$PSScriptRoot\New_HPConfig.txt" -Section "Post Messages" -Value "Enable"

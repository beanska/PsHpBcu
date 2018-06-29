import-module "$PSScriptroot\HpBCU.psm1" -force

Export-HpBcu -BcuPath $PSScriptroot -ConfigFile "$PSScriptRoot\HPConfig.txt"

Copy-Item "$PSScriptRoot\HPConfig.txt" "$PSScriptRoot\New_HPConfig.txt"
$data = Get-BiosData -ConfigFile "$PSScriptRoot\New_HPConfig.txt"
#$data | % {$_} | select 'read-only'
#$data.Values.type
#$data.Values.'read-only'

Set-BiosData -ConfigFile "$PSScriptRoot\New_HPConfig.txt" -Section "Post Messages" -Value "Disable"
#Set-BiosData -ConfigFile "$PSScriptRoot\New_HPConfig.txt" -Section "Post Messages" -Value "Enable"

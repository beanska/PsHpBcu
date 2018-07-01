import-module "$PSScriptroot\HpBCU.psm1" -force

Export-HpBcu -BcuPath $PSScriptroot -ConfigFile "$PSScriptRoot\HPConfig.txt"

Copy-Item "$PSScriptRoot\HPConfig.txt" "$PSScriptRoot\New_HPConfig.txt"
#$data = Get-BiosData -ConfigFile "$PSScriptRoot\New_HPConfig.txt"
#$data | % {$_} | select 'read-only'
#$data.Values.type
#$data.Values.'read-only'
#$data.Values.'read-only'
#$data | show-object
#$data['Post Messages'].type
<#$oldKey = $data['Asset Tag'].data.Keys | Select-Object -First 1
$data['Asset Tag'].data.Remove($oldKey)
$data['Asset Tag'].data.Add('12345', $false)
$data['Asset Tag'].data#>
#Set-BiosData -ConfigFile "$PSScriptRoot\New_HPConfig.txt" -Section "Post Messages" -Value "Disable"
$newData = Set-BiosData -ConfigFile "$PSScriptRoot\New_HPConfig.txt" -Section "Asset Tag" -Value "12345678"

#Show-HpBcu -BiosData $newData
#$data["Asset Tag"].data
#$newData

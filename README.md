# PsHpBcu

Wrapper module for the HP Bios Configuration Utility. Designed to make altering UEFI/BIOS settings easier for automation purposes.

```powershell
# Export firmware settings to text file and make a copy.
Invoke-HpBcu -Export -BcuPath $PSScriptroot -ConfigFile "$PSScriptRoot\HPConfig.txt"
Copy-Item "$PSScriptRoot\HPConfig.txt" "$PSScriptRoot\New_HPConfig.txt"

# Change the asset tag setting
Set-BiosData -ConfigFile "$PSScriptRoot\New_HPConfig.txt" -Section "Asset Tag" -Value "12345678"

# Write the changes to the firmware.
Invoke-HpBcu -Import -BcuPath $PSScriptroot -ConfigFile "$PSScriptRoot\New_HPConfig.txt"
```
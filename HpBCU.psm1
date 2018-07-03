 function Set-BiosData {
<#
.SYNOPSIS
Makes changes to the settings pulled from the BCU executable.
.DESCRIPTION
Reads the data from BCU utility and makes changes based on the specified section.
.PARAMETER ConfigFile
Text file from the BCU that you want to alter.
.PARAMETER Section
The section that you wish to alter.
.PARAMETER Value
The new value. If section is multiple choice then choice you want to be selected. If an ordered list then use -Order to specify the position (0 based).
.PARAMETER Order
For use with sections that are ordered lists (like boot order).
.EXAMPLE
# String section
Set-BiosData -ConfigFile "$PSScriptRoot\New_HPConfig.txt" -Section "Asset Tag" -Value "12345678"
.EXAMPLE
# Multiple choice section
Set-BiosData -ConfigFile "$PSScriptRoot\New_HPConfig.txt" -Section "TPM State" -Value "Enable"
.EXAMPLE
# Ordered List, this make "USB Hard Drive" the first entry in the section.
Set-BiosData -ConfigFile "$PSScriptRoot\New_HPConfig.txt" -Section "UEFI Boot Sources" -Value "USB Hard Drive" -Order 0
#>
    param (
        [Parameter(Mandatory=$True)]
        [string] $ConfigFile,

        [Parameter(Mandatory=$True)]
        [string] $Section,

        [Parameter(Mandatory=$True)]
        [string] $Value,

        [Parameter(Mandatory=$False)]
        [int32] $Order
    )

    $biosData = Get-BiosData -ConfigFile $ConfigFile

    if ($biosData[$Section].'read-only'){
        write-error "Section ""$Section"" is read only."
    } elseif ($biosData[$Section]){
        if ($biosData[$section].type -eq 'string'){       
            $oldKey = $biosData[$section].data.Keys | Select-Object -First 1
            $biosData[$section].data.Remove($oldKey)
            $biosData[$section].data.Add($Value, $false)
        } elseif ($biosData[$section].type -eq 'multipleChoice') {
            $curSelected = $biosData[$section].data.GetEnumerator() | Where-Object {$_.Value -eq $true} | Select-Object -ExpandProperty Name
            $biosData[$section].data.$curSelected = $False
            $biosData[$section].data.$value = $True
        } elseif ($biosData[$section].type -eq 'orderedList' -and $order -ne $null) {
            $curPosition = $biosData[$section].data.$value
            for($i=$order; $i -lt $biosData[$section].data.Count; $i++){
                if ($i -lt $curPosition){
                    $biosData[$section].data[$i]++
                }
            }
            $biosData[$section].data.$value = $order
        }
    } else {
        write-error "Section ""$Section"" not found"
    }
    Write-BiosData -BiosData $biosData -ConfigFile $ConfigFile
}

function Test-Section {
<#
.SYNOPSIS
Tests if a section exists in the config file.
.DESCRIPTION
Will return boolean based on if the given section exists in the config file
.PARAMETER ConfigFile
Text file from the BCU that you want to check.
.PARAMETER Section
The section that you wish to test for.
.EXAMPLE
Test-Section -ConfigFile "$PSScriptRoot\New_HPConfig.txt" -Section "Asset Tag"
#>
    param (
        [Parameter(Mandatory=$True)]
        [string] $Section,

        [Parameter(Mandatory=$True)]
        [string] $ConfigFile
    )

    $biosData = Get-BiosData -ConfigFile $ConfigFile

    if ($biosData[$section] -eq $null){
        return $false
    } else {
        return $true
    }
}

function Write-BiosData {
    param (
        [Parameter(Mandatory=$True)]
        [string] $ConfigFile,

        [Parameter(Mandatory=$True)]
        [System.Collections.Specialized.OrderedDictionary] $BiosData
    )

    Try {
        Remove-Item -Path $ConfigFile -ErrorAction Stop
    } Catch {
        throw "Unable to delete ""$ConfigFile"""
    }

    foreach ($Section in $BiosData.GetEnumerator().Name){
        
        if ($Section -like "Comment_*") {
            $BiosData.$Section | Out-File -FilePath $ConfigFile -Append -Encoding ASCII
        } else {
            $Section | Out-File -FilePath $ConfigFile -Append -Encoding ASCII
        }

        if ($BiosData[$Section].type -eq 'orderedList'){
            foreach ($item in $BiosData[$Section].data.GetEnumerator() | Sort Value){
                "`t$($item.Name)" | Out-File -FilePath $ConfigFile -Append -Encoding ASCII
            }
        } else {
            foreach ($item in $BiosData[$Section].data.keys){
                if ($BiosData[$Section].data.$item) {
                    "`t`*$($item)" | Out-File -FilePath $ConfigFile -Append -Encoding ASCII
                } else {
                    "`t$($item)" | Out-File -FilePath $ConfigFile -Append -Encoding ASCII
                }
            }
        }


    }
}
Function Get-BiosData {
    param (
        [Parameter(Mandatory=$True)]
        [string] $ConfigFile
    )

    [string] $section = $null
    [int] $comment = 0

    if (!(test-path $ConfigFile)){
        throw "Config file ""$ConfigFile"" not found"
    }

    $biosHash = ([ordered]@{})
	$biosData = Get-Content $ConfigFile
	
	foreach ($line in ($biosData | % {$_.replace('`t','') }) ) {
		switch -wildcard ($line) {
			"`t*" 	{ 
                $value = ($line.replace("`t", ''))
                
				if ($value -match "\*.*"){
					$biosHash[$section].data.Add($value.Substring(1), $true)
				} else {
					$biosHash[$section].data.Add($value, $false)
				}
 			}
			";*" 	{ 
                $biosHash.Add("Comment_$($comment)", $line)
                $comment++
			}
			default {
                $lastSection = $section
                $section = $line
                
                $biosHash.Add($section, 
                    ([ordered]@{
                        'type' = $null;
                        'data' = ([ordered]@{});
                        'read-only' = $false
                    })
                )
                
                # Get the data type of the last section
                if ($lastSection) {
                    if ($biosHash[$lastSection].data.count -eq 1){
                        $biosHash[$lastSection].type = 'string'
                    } else {
                        if ($biosHash[$lastSection].data.values -contains $true){
                            $biosHash[$lastSection].type = 'multipleChoice'
                        } else {
                            $biosHash[$lastSection].type = 'orderedList'
                            for($i=0; $i -lt $biosHash[$lastSection].Data.Count; $i++){
                                $biosHash[$lastSection].Data[$i] = $i
                            }
                            <#foreach ($key in $biosHash[$lastSection].Data){

                            }#>
                        }
                    }
                }             

				if ($section -like "*(ReadOnly)"){
					$biosHash[$lastSection].'read-only' = $true
				}
	           
			}
		}
	}
    
    return $biosHash
}

function Show-HpBcu {
    param (
        [Parameter(Mandatory=$True)]
        [System.Collections.Specialized.OrderedDictionary] $BiosData
    )

    #foreach ($Section in $BiosData.Keys){
    foreach ($Section in $BiosData.GetEnumerator().Name){
            write-host "$Section"
        foreach ($item in $BiosData[$Section].data.keys){
            write-host "`t$($item)"
        }
    }
}
function Invoke-HpBcu {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$False, ParameterSetName='Export')]
        [switch] $Export,

        [Parameter(Mandatory=$False, ParameterSetName='Import')]
        [switch] $Import,

        [Parameter(Mandatory=$True)]
        [string] $BcuPath,

        [Parameter(Mandatory=$True)]
        [string] $ConfigFile
    )

    if ( (test-path "$BcuPath\BiosConfigUtility64.exe") -and (test-path "$BcuPath\BiosConfigUtility.exe") ){
        Write-Information ""
    } else {
        Throw "Cannot find HP Bios Configuration Utility executables in path ""$BcuPath""."
    }

    if ((Get-WmiObject Win32_OperatingSystem).OSArchitecture -eq "64-bit"){
		$bcuExe = "$bcuPath\BiosConfigUtility64.exe"
	} else {
		$bcuExe = "$bcuPath\BiosConfigUtility.exe"
    }

    if ($Export) {
        $return = Start-Proc $bcuExe @("/Get:$($ConfigFile)") -hidden -waitforexit 
    } elseif ($Import) {
        $return = Start-Proc $bcuExe @("/Set:$($ConfigFile)") -hidden -waitforexit 
    } else {
        throw "-Import or -Export must be specified."
    }
    
    write-debug $return.StandardOutput.ReadToEnd()
    write-debug $return.ExitCode

}

function Start-Proc  {
    param (
       [string]$exe = $(Throw "An executable must be specified"),
       [string]$arguments,
       [switch]$hidden,
       [switch]$waitforexit
   )    

   # Build Startinfo and set options according to parameters
   $startinfo = new-object System.Diagnostics.ProcessStartInfo
   $startinfo.FileName = $exe
   $startinfo.Arguments = $arguments
   $startinfo.RedirectStandardError = $true 
   $startinfo.RedirectStandardOutput = $true
   $startinfo.UseShellExecute = $false 
   if ($hidden){
       $startinfo.WindowStyle = "Hidden"
       $startinfo.CreateNoWindow = $TRUE
   }
   $process = [System.Diagnostics.Process]::Start($startinfo)
   if ($waitforexit) {$process.WaitForExit()}
   return $process
}
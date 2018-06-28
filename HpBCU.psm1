
<#
.SYNOPSIS
Generates the folder and file structure needed to create a new Powershell module.
.DESCRIPTION
In order to provide some standardisation, this script will create the necessary folder/file structure for a new Powershell module.
The structure includes folders for Public and Private functions, creates a basic manifest file and root module loader, and creates a Pester test file for the manifest.
Once the environment is setup, proper development can begin.  Any public functions to be exported should still be added to the FunctionsToExport array in the manifest file.
Private functions are those which are internal to the module and are therefore not for public consumption.
Each public function should have its own test file in the Tests folder.
.PARAMETER ModuleName
The name you wish to give the module.  The root folder, manifest, and root loader will be named after the module.
.PARAMETER Author
Enter a name to be listed as the Author in the module manifest.
.PARAMETER Description
A short description of the module to be listed in the module manifest.
.PARAMETER PowershellVersion
The minimum version of Powershell supported by the module.  One of 2.0, 3.0 (the default), 4.0 or 5.0.
.PARAMETER ModulesPath
The full path to the directory you wish to develop the module in.  This is where the module structure will be created.
Include a trailing \ or don't, it doesn't matter.
.EXAMPLE
New-PSModule.ps1 -ModuleName WackyRaces -Author 'Penelope Pitstop' -Description 'Win the wacky races' -PowershellVersion '4.0' -ModulesPath 'c:\development\powershell-modules'
Creates a new module structure called WackyRaces in c:\development\powershell-modules\WackyRaces.  The module manifest will require Powershell v4.0.
#>

function Set-BiosData {
    param (
        [Parameter(Mandatory=$True)]
        [string] $ConfigFile,

        [Parameter(Mandatory=$True)]
        [string] $Section,

        [Parameter(Mandatory=$True)]
        [string] $Value
    )

    $biosData = Get-BiosData -ConfigFile $ConfigFile

    if ($biosData.$Section){
        if ($biosData.$Section.length -gt 1){
            #$biosData.$Section | ForEach-Object { $_ -like "\**"}
            $selected = $biosData.$Section -match "\*.*"
            if ("\*$($value)" -eq $selected) {
                Write-Information "The correct value ""$value"" is already selected"
            }
        } else {

        }
        
        #if (){

        #}
    } else {
        write-error "Section ""$Section"" not found"
    }

}
Function Get-BiosData {
    param (
        [Parameter(Mandatory=$True)]
        [string] $ConfigFile
    )

	$biosHash = [ordered]@{}
	$biosData = Get-Content $ConfigFile
	
	foreach ($line in ($biosData | % {$_.replace('`t','') }) ) {
		
		switch -wildcard ($line) {
			"`t*" 	{ 
                $biosHash[$section] += ($line.replace("`t", ''))
 			}
			";*" 	{ 
				#write-output "Comment: $Line"
				$biosHash[$line] = $null
			}
			default 	{ 	
				$section = $Line
	            $biosHash[$section] = @()
	            $CommentCount = 0
			}
		}
	}
	
	return $biosHash
}
function Export-HpBcu {
    [cmdletbinding()]
    param (
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
    
    $return = Start-Proc $bcuExe @("/Get:$($ConfigFile)") -hidden -waitforexit 
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
# Requires -Version 7
### Sample PowerShell Script for BloxOne DDI
### Author:  Don Smith
### Author-Email: dsmith@infoblox.com
### Version: 2020-08-03 Initial release

#$DebugPreference   = 'continue'
$VerbosePreference = 'continue'

# Remove the module if loaded so we can reload it
# For debugging and testing purposes
Write-OutPut "Removing old instances of public functions"
Get-Module BloxOne-DDI | Remove-Module

# Store locations for the module, tests, and parent directories
$testDir   = Get-Location
$parentDir = (get-item $testDir).parent.FullName
$scriptDir = "$parentDir\BloxOne-DDI"
@{ "parentDir" = $parentDir; "testDir" = $testDir; "scriptDir" = $scriptDir} | Write-OutPut

# Load the current module
Import-Module “$scriptDir\BloxOne-DDI.psd1”

# List all Public and Private functions
<#
$moduleObj    = Get-Module BloxOne-DDI
$allFunctions = $moduleObj.Invoke({Get-Command -Module BloxOne-DDI})
$pubFunctions = Get-Command -Module BloxOne-DDI
Write-Verbose "Private Functions"
Compare-Object -ReferenceObject $allFunctions -DifferenceObject $pubFunctions | Select-Object -ExpandProperty InputObject
Write-Verbose "Public Functions"
$pubFunctions
#>

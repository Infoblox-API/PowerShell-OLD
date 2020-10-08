# Requires -Version 7
### Sample PowerShell Script for BloxOne DDI
### Author:  Don Smith
### Author-Email: dsmith@infoblox.com
### Version: 2020-08-03 Initial release

#$DebugPreference   = 'continue'
#$VerbosePreference = 'SilentlyContinue'


Write-Output @"
************************
>>> Beginning test : Get-ConfigInfo <<<
************************
"@


<#
    Test #1: Execute the commond without providing a file path
    Expected Results:
        - bloxone.ini in the current directory will be read
        - bloxone.ini has a [Private] section with a path to private.ini in the current directory
        - private.ini will also be read
        - results from private.ini will be used
#>
# Read the INI file for the base configuration
Write-Output "Test #1: Attempting to read the default INI file (bloxone.ini)"
$iniConfig = Get-ConfigInfo -DoNotCreate -Verbose
if (Test-Path "bloxone.ini") {
    $iniConfig2 = Get-ConfigInfo "bloxone.ini" -DoNotCreate
    $iniConfig2 | Write-Output
} else {
    Write-Warning "Expected file 'bloxone.ini' does not exist"
}

<#
    Test #2: Execute the commond providing a random filename
    Expected Results:
        - the filename will not exist so it will be automatically created
        - the contents of the file will have all of the necessary key/value pairs
        - the values will be defaults except for the API key
#>
# Read a random INI file
Write-Output "Test #2: Create a random INI file template, create it if it does not exist"
$randomFile = [System.IO.Path]::GetRandomFileName()
Write-Output "Attempting to read the INI file $randomFile"
$iniConfig2 = Get-ConfigInfo $randomFile
# The file should have been created
if (Test-Path $randomFile) {
    Write-Output "Contents of $randomFile"
    Get-Content $randomFile | Write-Output
    Remove-Item -Path $randomFile
} else {
    # Error condition
    Write-Warning "Random file $randomFile was not created"
}

<#
    Test #3: Execute the commond providing a random filename
    Expected Results:
        - the filename will not exist and will not be created
#>
# Read a random INI file
Write-OutPut "Test #3: Test a random file but do not create it"
$randomFile = [System.IO.Path]::GetRandomFileName()
Write-Output "Attempting to read the INI file $randomFile"
$iniConfig2 = Get-ConfigInfo $randomFile -DoNotCreate
# The file should NOT have been created
if (Test-Path $randomFile) {
    # Error condition
    Write-Warning "Random file $randomFile was created. Contents of $randomFile"
    Get-Content $randomFile | Write-Output
    Remove-Item -Path $randomFile
} else {
    Write-Output "Random file $randomFile was not created"
}

<#
    Test 4: Pass the filename via the pipeline
    Expected Results:
        - the filename is read and the results are determined similar to other tests
#>
Write-OutPut "Test #4: Accept the filename from the pipeline"
$randomFile = [System.IO.Path]::GetRandomFileName()
$iniConfig2 = $randomFile | Get-ConfigInfo -DoNotCreate
# The file should NOT have been created
if (Test-Path $randomFile) {
    # Error condition
    Write-Warning "Random file $randomFile was created. Contents of $randomFile"
    Get-Content $randomFile | Write-Output
    Remove-Item -Path $randomFile
} else {
    Write-Output "Random file $randomFile was not created"
}


Write-Output @"
************************
>>> Test Complete <<<
************************
"@

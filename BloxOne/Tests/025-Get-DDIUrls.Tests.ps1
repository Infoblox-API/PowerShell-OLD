# Requires -Version 7
### Sample PowerShell Script for BloxOne DDI
### Author:  Don Smith
### Author-Email: dsmith@infoblox.com
### Version: 2020-08-04 Initial release

#$DebugPreference   = 'continue'
#$VerbosePreference = 'SilentlyContinue'



Write-Output @"
************************
>>> Beginning test : Get-DDIUrls <<<
************************
"@

<#
    Test #1: Execute function only to use defaults
    Expected Results:
        - hashtable with mutliple valid URLs
#>
Write-Output "Test #1: Do not pass any values (accept defaults)"
[hashtable]$myUrls = Get-DDIUrls
if ($myUrls.Count -eq 3) {
    Write-Output "Success:: $($myurls.Count) items returned."
} else {
    Write-Warning "Failure:: $($myurls.Count) items returned. Expected 3"
}
Write-Verbose $myUrls

<#
    Test #2: Override the default values for cspHostname and apiVersion
    Expected Results:
        - generate a valid CSP URL with the modified values
#>
Write-Output "Test #2: Positionally pass modified values for cspHostname and apiVersion"
[hashtable]$myUrls = Get-DDIUrls "https://modified.csp.infoblox.com" "v99"
if ($myUrls.Count -eq 3) {
    Write-Output "Success:: $($myurls.Count) items returned."
} else {
    Write-Warning "Failure:: $($myurls.Count) items returned. Expected 3"
}
# Test one result
$expectedResult = "https://modified.csp.infoblox.com/api/ddi/v99"
if ($myUrls.ipamUrl -eq $expectedResult) {
    Write-Output "Success:: cspHostname and apiVersion successfully modified"
} else {
    Write-Warning "Failure:: modified ipamUrl not returned"
    Write-Output $myUrls
}

<#
    Test #3: Pass the INI config and section to get the desired values
    Expected Results:
        - generate a valid CSP URL with the specific settings from a section in the INI data
#>
Write-Output "Test #3: Pass the iniConfig and iniSection"
[hashtable]$myUrls = Get-DDIUrls -iniConfig (Get-ConfigInfo) -iniSection "BloxOne"
if ($myUrls.Count -eq 3) {
    Write-Output "Success:: $($myurls.Count) items returned."
} else {
    Write-Warning "Failure:: $($myurls.Count) items returned. Expected 3"
}
Write-Verbose $myUrls
# Save this value for the next test
$myBloxOneIpamUrl = $myUrls.ipamUrl

<#
    Test #4: Pass the INI config and section to get the desired values, Override the apiVersion
    Expected Results:
        - generate a valid CSP URL with the specific settings from a section in the INI data
#>
Write-Output "Test #4: Pass the iniConfig and iniSection and apiVersion"
[hashtable]$myUrls4 = Get-DDIUrls -apiVersion "v99" -iniConfig (Get-ConfigInfo) -iniSection "BloxOne"
$myBloxOneModifiedIpamUrl = $myUrls4.ipamUrl

$mySplitMod = @($myBloxOneModifiedIpamUrl -split "/")
$mySplitOrg = @($myBloxOneIpamUrl -split "/")

# Make sure we have the same number of elements
if ($mySplitMod.Count -eq $mySplitOrg.Count) {
    # We are on the right track
    $elementCount = $mySplitMod.Count
    # Only the last element should be different
    for ($i=0; $i -lt $elementCount-1; $i++) {
        if ($mySplitMod[$i] -eq $mySplitOrg[$i]) {
            # We are on the right track
            Write-Verbose "Success:: Match at $i, value $($mySplitMod[$i])"
        } else {
            Write-Warning "Failure:: element $i does not match ($($mySplitMod[$i]) vs $($mySplitOrg[$i]))"
        }
    }
    # Manually check the last element because it SHOULD be different
    if ($mySplitMod[-1] -ne $mySplitOrg[-1]) {
        Write-Output "Success:: Found desired difference ($($mySplitMod[$i]) vs $($mySplitOrg[$i]))"
    } else {
        Write-Warning "Failure:: Desired difference not found ($($mySplitMod[$i]) vs $($mySplitOrg[$i]))"
    }
} else {
    Write-Warning "Failure:: Wrong # of elements returned ($mySplitMod.Count vs $mySplitOrg.Count)"
}


Write-Output @"
************************
>>> Test Complete <<<
************************
"@

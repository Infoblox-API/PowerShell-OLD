# Requires -Version 7
### Sample PowerShell Script for BloxOne DDI
### Author:  Don Smith
### Author-Email: dsmith@infoblox.com
### Version: 2020-08-03 Initial release

#$DebugPreference   = 'continue'
#$VerbosePreference = 'SilentlyContinue'


Write-Output @"
************************
>>> Beginning test : Get-BaseUrl <<<
************************
"@

<#
    Test #1: Pass only the cspApp value
    Expected Results:
        - generate a valid CSP URL using defaults and the provided app
#>
Write-Output "Test #1: Pass only cspApp and generate a valid CSP URL"
$myUrl = Get-BaseUrl -cspApp "ddi"
if ($myUrl -eq "https://csp.infoblox.com/api/ddi/v1") {
    Write-Output "Passed with correct construction of Url"
} else {
    Write-Warning "Wrong Url value created: $myUrl"
}


<#
    Test #2: Override the url default
    Expected Results:
        - generate a valid CSP URL
#>
Write-OutPut "Test #2: Define a custom URL"
$myUrl = Get-BaseUrl "https://test3.csp.infoblox.com" "ddi"
if ($myUrl -eq "https://test3.csp.infoblox.com/api/ddi/v1") {
    Write-Output "Passed with correct construction of Url"
} else {
    Write-Warning "Wrong Url value created: $myUrl"
}

Write-Output @"
************************
>>> Test Complete <<<
************************
"@

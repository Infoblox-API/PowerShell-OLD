# Requires -Version 7
### Sample PowerShell Script for BloxOne DDI
### Author:  Don Smith
### Author-Email: dsmith@infoblox.com
### Version: 2020-08-04 Initial release

#$DebugPreference   = 'continue'
#$VerbosePreference = 'continue'


Write-Output @"
************************
>>> Beginning test : List-DhcpServer <<<
************************
"@

Write-Output "Prep configuration for subsequent tests..."

# Get a valid config to work with
$iniConfig = Get-ConfigInfo -DoNotCreate

# Get all of the necessary URLs using the correct config info
[hashtable]$h = Get-DDIUrls -iniSection "AMS" -iniConfig $iniConfig
Write-Output $h

# Build the Authorization header using the appropriate API Key from the config
$headers = @{
    "Authorization" = "Token " + $iniConfig.AMS.api_key
}
Write-Verbose "Authorization header = $($headers.Authorization)"

# Get a list of all DHCP Servers
# Start with constructing the URL
$dhcpServersUrl = $h.ipamUrl + "/dhcp/server”
Write-Output "Url to pull the list of servers: $dhcpServersUrl"

# Get the object(s)
$serverList = Invoke-RestMethod -Method ‘Get’ -Uri $dhcpServersUrl -Headers $headers
Write-Output "$($serverList.results.Length) results returned"

# Loop through the objects and display the name
for ($i=0; $i -lt $serverList.results.Length; $i++) {
    Write-Verbose "#$i $($serverList.results[$i].name)"
}


Write-Output @"
************************
>>> Test Complete <<<
************************
"@

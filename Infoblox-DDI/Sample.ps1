# Remove the module if loaded so we can reload it
Get-Module Infoblox-DDI | Remove-Module
clear

# Load the current module
Import-Module .\Infoblox-DDI.psd1
Write-Host ""
Get-Command -Module Infoblox-DDI
Write-Host ""

#$GridMaster = Read-Host "Grid Master"
#$Username   = Read-Host "Username"
#Connect-IBGridMaster $GridMaster $Username -ask -force
#Connect-IBGridmaster demogm1.infoblox.com dsmith -ask -force
#Connect-IBGridMaster 172.16.98.15 admin infoblox -force
Connect-IBGridMaster 172.16.98.16 admin infoblox -force

Show-IBSessionVariables
Write-Host ""

$schema_obj = Get-IBSchema
Write-Host "Objects supported by WAPI version: ", $schema_obj.supported_objects.Count

# Could do checks to see if objects are supported by the current/in use WAPI version before acting on them
#if ($schema_obj.supported_objects.Contains("network") -eq $true) {} else {}
#if ($schema_obj.supported_objects.Contains("network") -eq $true) { Write-Host "1" } else { Write-Host "0" }


# Fail tests
#Write-Host "Fail Tests"
#Set-IBMaxResults 0
#Set-IBMaxResults 1000001
#Set-IBWapiVersion "1.7"
#Set-IBWapiVersion "v 1.7"

# Success tests
#Write-Host "Success Tests"
Set-IBMaxResults 10
#Set-IBWapiVersion "v1.7"
#Set-IBWapiVersion

Write-Host "Find all networks starting with '192.168'"
Find-IBNetwork -return_fields "extattrs" -network 192.168

Write-Host "Find network '192.168.1.0'"
Find-IBNetwork -return_fields "extattrs" -network 192.168.1.0 -network_exact_match

Write-Host "Find networks starting with 'Test' in the comment"
Find-IBNetwork -return_fields "extattrs" -comment Test -comment_match_type ~=

Write-Host "Find networks with 'Test Internal 1' in the comment"
Find-IBNetwork -return_fields "extattrs" -comment "Test Internal 1"

Write-Host "Find networks with 'test internal 1' in the comment (case insensitive)"
Find-IBNetwork -return_fields "extattrs" -comment "test internal 1" -comment_match_type :=

Write-Host "Find networks with 'test' in the comment (case insensitive)"
Find-IBNetwork -return_fields "extattrs" -comment test -comment_match_type ~:= -network_view "Company 1"

Write-Host "Find all networks in the 'default' network view"
Find-IBNetwork -return_fields "extattrs" -network_view default

Write-Host "Find all networks in the 'Company 1' network view"
Find-IBNetwork -return_fields "extattrs" -network_view "Company 1"

Write-Host "Find all networks starting with '192.168' where the Country is 'US'"
Find-IBNetwork -return_fields "extattrs" -network 192.168 -search_string "*Country=US"

Write-Host "Find the smallest network (from the default view) that contains the IP address '192.168.0.5'"
Find-IBNetwork -return_fields "extattrs" -contains_address 192.168.0.5

Write-Host "Find all unmanaged networks"
Find-IBNetwork -unmanaged

Write-Host "Find all networks in network container 25.25.0.0/16"
Find-IBNetwork -network_container 25.25.0.0/16

Write-Host "Find networks where the EA 'Country' does not equal 'US'"
Find-IBNetwork -return_fields "extattrs" -search_string "*Country!=US" -Verbose

#Write-Host "Get network with ref"
#$test_data = Get-IBNetwork network/ZG5zLm5ldHdvcmskMTkyLjE2OC4xLjAvMjQvMA:192.168.1.0/24/Company%201 -json
#$test_data

#Get-IBSchema network | ConvertTo-Json



################################################
#
# Lots of stuff below for testing.
# Need to clean up the object because not all of the values can be written back to the server.
# Maybe loop through the fields and check the schema to see which need to be "removed" from the object to send back
#
################################################


# Get some valid network object and loop through the EAs
$mynet1 = Get-IBNetwork network/ZG5zLm5ldHdvcmskMTcyLjE2Ljk4LjAvMjQvMg:172.16.98.0/24/Company%201 -return_fields "disable,extattrs,netmask,network_container,extattrs"

# Grab the existing EAs
$mykeys = $mynet1.extattrs.Keys
$myEAArray = @{}
foreach ($key in $mykeys) {
    $myEA = @{}
    $myEA.Add("value", $mynet1.extattrs.$key.value)
    $myEAArray.Add($key, $myEA)
}

# Add a new EA (State = CA) to the network
$myEAArray | ConvertTo-Json
$myEAArray += Add-IBExtensibleAttribute "State" "CA"
$myEAArray | ConvertTo-Json

# Create the new object to store the data to write
$myNewObject = @{}
$myNewObject | Add-Member -Name "comment" -Value $mynet1.comment -MemberType NoteProperty
$myNewObject | Add-Member -Name "disable" -Value $mynet1.disable -MemberType NoteProperty
$myNewObject | Add-Member -Name "extattrs" -Value $myEAArray -MemberType NoteProperty
$jsonData = $myNewObject | ConvertTo-Json

# Establish our update URI and credentials
$uri = "https://172.16.98.16/wapi/v2.5/network/ZG5zLm5ldHdvcmskMTcyLjE2Ljk4LjAvMjQvMg:172.16.98.0/24/Company%201"
$uri
$securePwd = ConvertTo-SecureString "infoblox" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("admin", $securePwd)

try {
    $response = Invoke-RestMethod -Uri $uri -Method Put -ContentType 'application/json' -Body $jsonData -Credential $credential
} catch {
    # Get the actual message provided by Infoblox
    $result = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($result)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd()
    Write-Error "[ERROR] $responseBody"
}

$response

# Curl commands to update/restore EA settings
#curl -k1 -u admin:infoblox -X PUT https://172.16.98.16/wapi/v2.5/network/ZG5zLm5ldHdvcmskMTcyLjE2Ljk4LjAvMjQvMg:172.16.98.0/24/Company%201 -d '{ "extattrs": { "Country": { "value": "CA" }, "Site": { "value": "Toronto"}, "State": { "value": "CA" }}}' -H "Content-Type: application/json"
#curl -k1 -u admin:infoblox -X PUT https://172.16.98.16/wapi/v2.5/network/ZG5zLm5ldHdvcmskMTcyLjE2Ljk4LjAvMjQvMg:172.16.98.0/24/Company%201 -d '{ "extattrs": { "Country": { "value": "CA" }, "Site": { "value": "Toronto"}}}' -H "Content-Type: application/json"


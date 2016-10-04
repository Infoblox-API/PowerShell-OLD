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
Connect-IBGridmaster demogm1.infoblox.com dsmith -ask -force
#Connect-IBGridMaster 172.16.98.15 admin infoblox -force

Show-IBSessionVariables
Write-Host ""

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
Set-IBWapiVersion

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

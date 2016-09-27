Import-Module .\Infoblox-DDI.psd1
Write-Host ""

$GridMaster = Read-Host "Grid Master"
$Username   = Read-Host "Username"

Connect-IBGridMaster $GridMaster $Username -ask -force

Show-IBSessionVariables
Write-Host ""

Find-IBNetwork 192.168.1.0

Get-IBNetwork network/ZG5zLm5ldHdvcmskMTkyLjE2OC4xLjAvMjQvMA:192.168.1.0/24/Company%201


# Load class(es) before doing anything else
#Using module ".\Class\bloxonesession.psm1"
#Using module ".\Class\bloxone.psm1"


#Requires -Version 7.0

# Remove the module if loaded so we can reload it
# For debugging and testing purposes
Write-Verbose "Removing old instances of functions"
Get-Module BloxOne-DDI | Remove-Module

# Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

# Dot source the files
Foreach($import in @($Public + $Private))
{
    Try
    {
        . $import.fullname
        Write-Debug "Imported function '$($import.fullname)'"
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}


# Export everything in the public folder
Export-ModuleMember -Function $Public.Basename

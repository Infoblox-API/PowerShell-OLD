<#
	.Synopsis
		Search for an Infoblox network and return a list of results
		
	.Description
		Requires a search string to find the network (generally all of or a portion of the address)
		
	.Parameter search_string
		A string in URI compatible format

	.Outputs
		An array of results
		
	.Example
		Find-Network 192.168.1.0 network
		Find-Network -search_string 192.168.1.0
	
		Find a network that matches the address 192.168.1.0
		
	.Example
		Find-Network 192.168
		
		Find all networks that contain 192.168 in the address

#>

function script:Find-Network {
    Param (
        [Parameter(Mandatory=$true,Position=0)]
            [string]$search_string = $null
    )

    BEGIN {    }

    PROCESS {    }

    END {
        Write-Verbose "[Find-Network] $search_string"
        $local_results = Find-Object -search_string $search_string -objtype network

        return $local_results
    }
}
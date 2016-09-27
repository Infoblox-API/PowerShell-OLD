<#
	.Synopsis
		Search for an Infoblox object and return a list of results
		
	.Description
		Request an object type and search string to find matching objects in the Grid.
		Results are always returned as an array.
		
	.Parameter search_string
		A string in URI compatible format
		
	.Parameter objtype
		A valid Infoblox object type (for example: 'network' or 'record:host')

	.Outputs
		An array of results
		
	.Example
		Find-Object 192.168.1.0 network
		Find-Object -search_string 192.168.1.0 -objtype network
	
		Find a network that matches the address 192.168.1.0
		
	.Example
		Find-Object 192.168 network
		
		Find all networks that contain 192.168 in the address
		
	.Example
		Find-Object
		
		Prompt for the search string and object type
		
#>

function script:Find-Object {
    Param (
        [Parameter(Mandatory=$false,Position=0)]
            [string]$search_string  = $( Read-Host -Prompt "Enter a valid search string" ),
        [Parameter(Mandatory=$false,Position=1)]
            [string]$objtype        = $( Read-Host -Prompt "Enter a valid object type" )
    )

    BEGIN {
        # Make sure we already have a session established
        if (!$ib_session) {
            Write-Host "[ERROR] Try creating a session first using 'Connect-GridMaster'"
            return $false
        }
    }

    PROCESS {    }

    END {
        Write-Verbose "[Find-Object] $objtype : $search_string"
        # Build the URI
        # Search for the object reference
        if ($search_string)  { $uri_filter = "search_string~=$search_string" }
        if ($objtype)        { $uri_filter = "$uri_filter"+'&'+"objtype=$objtype" }
        $uri        = "$ib_uri_base/search"+'?'+"$uri_filter"
        Write-Debug "[DEBUG] Find-Object: uri = $uri"

        try {
            $results = Invoke-RestMethod -Uri $uri -Method Get -WebSession $ib_session
        } catch {
            Write-Host "[ERROR] There was an error performing the search."
            write-host $_.ErrorDetails
            return $false
        }

        return $results
    }
}
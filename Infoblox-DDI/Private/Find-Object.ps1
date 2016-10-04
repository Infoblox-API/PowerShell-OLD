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
            [string]$search_string = $( Read-Host -Prompt "Enter a valid search string" ),
        [Parameter(Mandatory=$false,Position=1)]
            [string]$objtype       = $( Read-Host -Prompt "Enter a valid object type" )
    )

    BEGIN {
        Write-Debug "[DEBUG:Find-Object] Begin"

        # Make sure we already have a session established
        if (!$ib_session) {
            Write-Error "[ERROR:Find-Object] Try creating a session first using 'Connect-GridMaster'"
            return $false
        }
    }

    PROCESS {
    }

    END {
        Write-Verbose "[Find-Object] $objtype : $search_string"

        # Build the URI filter/search string
        if ($search_string) { $uri_filter = "search_string~=$search_string" }
        if ($objtype)       { $uri_filter = "$uri_filter"+'&'+"objtype=$objtype" }

        # Assemble the URI search string
        $uri = "$ib_uri_base/search"+'?'+"$uri_filter"

        # Append the max results we want returned
        if ($script:ib_max_results) { $uri = "$uri"+'&'+"_max_results=$script:ib_max_results" }

        # Debug the URI
        Write-Debug "[DEBUG:Find-Object] URI '$uri'"

        # Send the request and print any error messages
        try {
            $results = Invoke-RestMethod -Uri $uri -Method Get -WebSession $ib_session
        } catch {
            Write-Error "[ERROR:Find-Object] There was an error performing the search."
            # $_.ErrorDetails is absolutely useless here
            #Write-Host $_.ErrorDetails

            # Get the actual message provided by Infoblox
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd()
            Write-Error [ERROR:Find-Object] $responseBody

            return $false
        }

        return $results
    }
}
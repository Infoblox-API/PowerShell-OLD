<#
    .Synopsis
        Search for an Infoblox network and return a list of results

    .Description
        Requires at least one parameter for the search to work.

    .Parameter search_string
        A string in WAPI URI compatible format.

    .Parameter return_fields
        A list of comma separated return fields to be included in the results.

    .Parameter comment
        The comment or initial part of the comment to search for

    .Parameter comment_match_type
        The operator to use for the comment search (defaults to '=' which is an exact match).
        Acceptable options are: (1) '=' for an exact match, (2) ':=' for exact case insensitive match, (3) '~=' for contains, and (4) '~:=' for case insensitive begins with.

    .Parameter network
        The network address to search for (no mask).
        Defaults to allow a 'begins with' search.

    .Parameter network_exact_match
        A switch that enables an exact match on the network address

    .Parameter network_view
        The name of the network view to filter results for.

    .Parameter contains_address
        Requires a valid IP address and will return the network the IP address belongs to.
        WAPI documentation says this is only compatible with network_view.

    .Parameter network_container
        Requires a network/mask (i.e. 172.16.0.0/16) and will return networks that are contained within this network container.

    .Parameter unmanaged
        Switch parameter that filters results to unmanaged networks only

    .Parameter ipv4member
        Requires a valid IPv4 address and will return networks assigned to this Infoblox Grid member.

    .Parameter ipv6member
        Requires a valid IPv6 address and will return networks assigned to this Infoblox Grid member.

    .Parameter msftmember
        Requires a valid IPv4 address and will return networks assigned to this Microsoft Grid member.

    .Outputs
        An array of results

    .Example
        Find-Network -return_fields "extattrs" -network 192.168

        Find all networks starting with '192.168'" and include the 'extattrs' field in the results

    .Example
        Find-Network -return_fields "extattrs" -network 192.168 -search_string "*Country=US"

        Find all networks starting with '192.168' where the Country is 'US'" and include the 'extattrs' field in the results

    .Example
        Find-Network -return_fields "extattrs" -comment test -comment_match_type ~:= -network_view external

        Find networks with 'test' in the comment (case insensitive) located in the 'external' network view and include the 'extattrs' field in the results
#>


function script:Find-Network {
    Param (
        [Parameter(Mandatory=$false,Position=0)]
            [string]$search_string,
        [Parameter(Mandatory=$false,Position=1)]
            [string]$return_fields = $null,

        [Parameter(Mandatory=$false,Position=2)]
            [string]$comment,
        [Parameter(Mandatory=$false,Position=3)]
            [ValidateSet("=", "~=", ":=", "~:=")]
            [string]$comment_match_type,

        [Parameter(Mandatory=$false,Position=4)]
            [string]$network,
        [Parameter(Mandatory=$false,Position=5)]
            [switch]$network_exact_match,

        [Parameter(Mandatory=$false,Position=6)]
            [string]$network_view,

        [Parameter(Mandatory=$false,Position=7)]
            [string]$contains_address,

        [Parameter(Mandatory=$false,Position=8)]
            [string]$network_container,

        # Only from the following will actually work at any one time
        # Tried using ParameterSetName but got errors for some reason
        [Parameter(Mandatory=$false,Position=9)]
            [switch]$unmanaged,

        [Parameter(Mandatory=$false,Position=10)]
            [ValidatePattern("(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)")]
            [string]$ipv4member,

        [Parameter(Mandatory=$false,Position=11)]
            [ValidatePattern("(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}")]
            [string]$ipv6member,

        # Validate only IPv4 for now; may need to update this later
        [Parameter(Mandatory=$false,Position=12)]
            [ValidatePattern("(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)")]
            [string]$msftmember
        
    )

    BEGIN {
        Write-Debug "[DEBUG:Find-Network] Begin"
        $my_Debug = $false

        ##########
        # Gather data for debugging and verbose output
        $myinvoc         = $MyInvocation
        $my_functionName = $myinvoc.InvocationName

        ##########
        # Gather more data for debugging purposes (if necessary)
        if ($myinvoc.BoundParameters.Debug) {
            $my_functionLine   = $myinvoc.Line.Trim()
            $my_functionParams = $my_functionLine -replace "$my_functionName ", ""
            $my_Debug = $true

            Write-Host "[DEBUG:Find-Network] Line  : '$my_functionLine'"
            Write-Host "[DEBUG:Find-Network] Name  : '$my_functionName'"
            Write-Host "[DEBUG:Find-Network] Params: '$my_functionParams'"

            #$incoming_parameters = $myinvoc.BoundParameters
            #foreach ($key in $incoming_parameters.GetEnumerator()) { $key.Key + "," + $key.Value }
            Write-Host ""
        }

        # Set up our search array
        $search_array = @()

        # Set up for determining if we have a valid search string
        $valid_search = $false

        # Check to make sure the $return_fields value is comma separated
        $fields_array = $return_fields.Split(",").Trim()
        $return_fields = $fields_array -join ","

        # Include the search string passed
        if (! [string]::IsNullorEmpty($search_string)) {
            $search_array += "$search_string"
        }

        # Process network handling; network contains the value to search, network_exact_match (=)
        if ($network) {
            $str1 = "network"
            if (! $network_exact_match) {
                $str1 += "~"
            }
            $str1 += "=$network"
            $search_array += $str1
        }

        # Process comment handling; comment contains the value to search, comment_match_type (=, ~=, :=, ~:=)
        if ($comment) {
            if ([string]::IsNullorEmpty($comment_match_type)) {
                $comment_match_type = "="
            }
            $str1 = "comment" + $comment_match_type + $comment
            #$str1 = $str1 -replace " ", "%20"
            $search_array += $str1
        }

        # Set up network_view filtering
        if ($network_view) {
            $str1 = "network_view=$network_view"
            $search_array += $str1
        }

        # Set up contains_address filtering
        if ($contains_address) {
            $search_array += "contains_address=$contains_address"
        }

        # Set up network_container filtering
        if ($network_container) {
            $search_array += "network_container=$network_container"
        }

        # Set up unmanaged network filtering
        if ($unmanaged) {
            $search_array += "unmanaged=1"
        }

        # Process ipv4member, ipv6member, and msftmember
        if ($ipv4member) {
            $search_array += "member=dhcpmember,$ipv4member"
        }
        if ($ipv6member) {
            $search_array += "member=ipv6dhcpmember,$ipv6member"
        }
        if ($msftmember) {
            $search_array += "member=msdhcpserver,$msftmember"
        }

        Write-Debug "[DEBUG:Find-Network] search_array = '$search_array'"

        # If the array is not empty, we have valid criteria
        if ((! [string]::IsNullorEmpty($search_array)) -or (! [string]::IsNullorEmpty($search_string))) {
            $valid_search = $true
        }
    }

    PROCESS {
        Write-Debug "[DEBUG:Find-Network] Process"

        # Make sure we have something to do
        if (! $valid_search) {
            Write-Verbose "[DEBUG:Find-Network] No valid search criteria provided"
            return $false
        }

        # Build the URI base object filter
        $uri = "$ib_uri_base/network" + '?'

        # Process the array we just built
        if ($search_array.Count -gt 0) {
            # Add the return fields to the search string
            $combined_search = $search_array -join '&'
            Write-Debug "[DEBUG:Find-Network] combined_search = '$combined_search'"

            $uri += "$combined_search"
        }

        # Append any additional return fields requested
        $uri += "&_return_fields+=" + $return_fields

        # Append the max results we want returned
        if ($script:ib_max_results) { $uri += '&' + "_max_results=$script:ib_max_results" }
        
        # Debug the URI
        Write-Verbose "[DEBUG:Find-Network]     URI '$uri'"

        # Fix up the URI since the WAPI and/or PowerShell chokes
        if ($my_Debug) {
            $uri = ConvertTo-URIEncodedFormat $uri -Debug
        }
        else {
            $uri = ConvertTo-URIEncodedFormat $uri
        }

        # Debug the encoded URI
        Write-Verbose "[DEBUG:Find-Network] ENC-URI '$uri'"
    }

    END {
        Write-Debug "[DEBUG:Find-Network] End"
        # Send the request and print any error messages
        try {
            $local_results = Invoke-RestMethod -Uri $uri -Method Get -WebSession $ib_session
        } catch {
            Write-Error "[ERROR:Find-Network] There was an error performing the network search."
            # $_.ErrorDetails is absolutely useless here
            #Write-Host $_.ErrorDetails

            # Get the actual message provided by Infoblox
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd()
            Write-Error "[ERROR:Find-Network] $responseBody"

            return $false
        }

        return $local_results
    }
}
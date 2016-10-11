<#
    .Synopsis
        Get an Infoblox object based on the reference passed.

    .Description
        Get the referenced object and any additional columns requested.

    .Parameter _ref
        The object reference obtained from a 'find' operation

    .Parameter _return_fields
        Additional columns to retrieve aside from those returned by default

    .Outputs
        An object array of name/value pairs

    .Example
        Get-Object 192.168.1.0 network

        Find a network that matches the address 192.168.1.0

#>

function script:Get-Object {
    Param (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
            [string]$_ref,
        [Parameter(Mandatory=$false,Position=1)]
            [string]$_return_fields
    )

    BEGIN {
        Write-Debug '[DEBUG:Get-Object] Begin'

        if (!$script:ib_session) {
            Write-Error "[ERROR:Get-Object] Try creating a session first. 'Connect-GridMaster'"
            return $false
        }

        # Initialize our counter and hashtable
        [hashtable[]]$data_array = $null
    }

    PROCESS {
        Write-Verbose "[Get-Object] [$_ref] [$_return_fields]"
        Write-Debug "[DEBUG:Get-Object] _ref           = $_ref"
        Write-Debug "[DEBUG:Get-Object] _return_fields = $_return_fields"

        # Set up the URI
        $uri_return_type = "_return_type=json-pretty"
        $uri = $script:ib_uri_base + "$_ref" + '?' + $uri_return_type

        # Add the requested return fields to the URI
        if ($_return_fields) {
            # Replace '+' with '%2b'
            $uri = "$uri" + '&' + "_return_fields%2b=$_return_fields"
        }

        # Set the limit for the maximum results to return
        if ($script:ib_max_results) { $uri = "$uri" + '&' + "_max_results=$script:ib_max_results" }

        # Debug the URI
        Write-Debug "[DEBUG:Get-Object] URI '$uri'"

        # Try to obtain the data and print an error message if there is one
        try {
            $local_results = Invoke-WebRequest -Uri $uri -Method Get -WebSession $script:ib_session
        } catch {
            Write-Error "[ERROR:Get-Object] There was an error getting the data."
            Write-Error "[ERROR:Get-Object] URI '$uri'"
            # $_.ErrorDetails is absolutely useless here
            #Write-Host $_.ErrorDetails

            # Get the actual message provided by Infoblox
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd()
            Write-Error [ERROR:Get-Object] $responseBody

        }  

        # Grab only the content portion of the returned object
        $obj_content = $local_results.Content

        # Deserialize the JSON data into something manageable
        $data = $obj_content | IB-ConvertFrom-JSON

        # Debug the raw data
        Write-Debug "[DEBUG:Get-Object] Got data '$data'"

        # Append the raw data into an array (for pipeline requests)
        $data_array += $data
        Write-Debug "[DEBUG:Get-Object] Array '$data_array'"
    }

    END {
        Write-Debug "[DEBUG:Get-Object] Returning data array"
        return $data_array
    }
}
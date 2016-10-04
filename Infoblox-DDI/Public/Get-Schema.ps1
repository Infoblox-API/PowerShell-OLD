<#
    .SYNOPSIS
        Retrieves the schema object from the Grid and displays it

    .DESCRIPTION
        Retrieves the schema object from the Grid and displays it

    .OUTPUTS
        Shows schema data from the Grid

    .EXAMPLE
        Show-Schema
        
#>

function script:Get-Schema {
    BEGIN {
        Write-Debug "[DEBUG:Get-Schema] Begin"
    }

    PROCESS {
    }

    END {
        # Set the URI to retrieve the Grid object
        $uri = "https://$script:ib_grid_master/wapi/v1.0/?_schema"
        Write-Debug "[DEBUG:Get-Schema] URI = $uri"

        # Make a connection to the Grid and print the detailed error message as necessary
        try {
            $schema_obj = Invoke-RestMethod -Uri $uri -Method Get -WebSession $script:ib_session
        } catch {
            Write-Error '[ERROR:Get-Schema] There was an error retrieving the schema.'
            # $_.ErrorDetails is absolutely useless here
            #Write-Host $_.ErrorDetails

            # Get the actual message provided by Infoblox
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd()
            Write-Error [ERROR:Get-Schema] $responseBody

            return $false
        }

        Write-Debug "[DEBUG:Get-Schema] $schema_obj"
        return $schema_obj
    }
}

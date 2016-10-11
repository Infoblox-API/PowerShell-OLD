<#
    .SYNOPSIS
        Establishes a session to an Infoblox Grid Master for all subsequent data calls.

    .DESCRIPTION
        Creates a connection to an Infoblox Grid Master and leaves open an active session.  Defines several global variables for subsequent use.

        ib_grid_name    The name of the Grid (for multi Grid environments -- like Test/Dev vs. Production)
        ib_grid_master  The IP or hostname of the Grid we are connecting to
        ib_grid_ref     A reference to the Grid object
        ib_session      The WebSession variable
        ib_uri_base     "https://$grid_master/wapi/$wapi_ver"
        ib_username     The admin name
        ib_wapi_ver     The WAPI version string used to connect

    .PARAMETER grid_master 
        A single computer name or IP address.

    .PARAMETER username
        Authenticating user; defaults to "admin"

    .PARAMETER password
        Admin password.  If not entered, use the -ask_pw option.

    .PARAMETER wapi_ver
        Use to specify the exact version of the WAPI to use.
        The version must be in "v#.#" format and must be supported by the installed version of NIOS.
        Defaults to "v1.3"

    .PARAMETER max_results
        Determines the maximum number of results to be returned.
        Enter as a whole number ("10000").
        Defaults to 10,000.

    .Parameter force
        Forces a connection where self-signed certificates are used

    .PARAMETER ask_pw
        Forces a prompt for inputting the password manually so it does not have to be entered in clear text on the command line.

    .OUTPUTS
        Optional connection message (Grid name you are connected to)
        TRUE or FALSE depending on the connection status

    .EXAMPLE
        IB-Create-Session 192.168.1.2 admin infoblox
        Creates a connection to a Grid Master using default credentials and IP address.

    .EXAMPLE 
        IB-Create-Session 192.168.1.2 admin -ask_pw
        Creates a connection but allows entering the password securely (via prompt with masking).

    .NOTES
        This should be the first command run to ensure that a connection is established and global variables are properly configured.

#>

function script:Connect-GridMaster {
    Param (
        [Parameter(Mandatory=$false,Position=0)]
            [string]$grid_master = "192.168.1.2",
        [Parameter(Mandatory=$false,Position=1)]
            [string]$username    = "admin",
        [Parameter(Mandatory=$false,Position=2)]
            [string]$password    = "infoblox",
        [Parameter(Mandatory=$false,Position=3)]
            [string]$wapi_ver    = "v1.3",
        [Parameter(Mandatory=$false,Position=4)]
            [int]$max_results    = "1000",
        [Parameter(Mandatory=$false)]
            [switch]$force,
        [Parameter(Mandatory=$false)]
            [switch]$ask_pw
    )

    BEGIN {
        Write-Debug "[DEBUG:Connect-GridMaster] Begin"

        # Reset all script variables to null until a successful connection is established
        $script:ib_grid_name   = $null
        $script:ib_grid_master = $null
        $script:ib_grid_ref    = $null
        $script:ib_max_results = $null
        $script:ib_session     = $null
        $script:ib_uri_base    = $null
        $script:ib_username    = $null
        $script:ib_wapi_ver    = $null
    }

    PROCESS {
        # There is nothing to loop through so we'll skip this
    }

    END {
        # Check to see if we are forcing a connection to a Grid with self-signed certificates
        if ($force) {
            Write-Debug "[DEBUG:Connect-GridMaster] Forcing connection"
            Set-IgnoreSelfSignedCerts
        }

        # Prompt for the password, if required and build the credentials
        if ($ask_pw) {
            $secure_pw = $( Read-Host -Prompt "Enter password" -AsSecureString )
            Write-Host ""
        } else {
            $secure_pw = ConvertTo-SecureString $password -AsPlainText -Force
        }
        $credential = New-Object System.Management.Automation.PSCredential ($username, $secure_pw)

        # Set the base URI for all WAPI requests
        $uri_base = "https://$grid_master/wapi/$wapi_ver/"
        Write-Debug "[DEBUG:Connect-GridMaster] URI base = $uri_base"

        # Set the URI to retrieve the Grid object
        $uri = $uri_base + "grid"

        # Make a connection to the Grid and print the detailed error message as necessary
        try {
            $grid_obj = Invoke-RestMethod -Uri $uri -Method Get -Credential $credential -SessionVariable new_session
        } catch {
            Write-Error '[ERROR:Connect-GridMaster] There was an error connecting to the Grid.'
            # $_.ErrorDetails is absolutely useless here
            #Write-Host $_.ErrorDetails

            # Get the actual message provided by Infoblox
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd()
            Write-Error [ERROR:Connect-GridMaster] $responseBody

            return $false
        }

        # Get the name of the Grid
        $s1        = $grid_obj._ref.IndexOf(":")
        $grid_name = $grid_obj._ref.Substring( $( $s1 + 1 ) )

        # Update global variables with new connection information
        $script:ib_grid_name   = $grid_name
        $script:ib_grid_master = $grid_master
        $script:ib_grid_ref    = $( $grid_obj._ref )
        $script:ib_max_results = $max_results
        $script:ib_session     = $new_session
        $script:ib_uri_base    = $uri_base
        $script:ib_username    = $username
        $script:ib_wapi_ver    = $wapi_ver

        Write-Host "# Connected to Grid: '$grid_name'"

        # Update the schema version to the latest if we are still using v1.3
        if ($wapi_ver -eq "v1.3") {
            Set-IBWapiVersion
        }

        return $true
    }
}

<#
	.SYNOPSIS
		Establishes a session to an Infoblox Grid Master for all subsequent data calls.
		
	.DESCRIPTION
		Creates a connection to an Infoblox Grid Master and leaves open an active session.  Defines several global variables for subsequent use.
		
		ib_grid_name            The name of the Grid (for multi Grid environments -- like Test/Dev vs. Production)
		ib_grid_master          The IP or hostname of the Grid we are connecting to
		ib_grid_ref             A reference to the Grid object
		ib_session              The WebSession variable
		ib_uri_base             "https://$grid_master/wapi/$wapi_ver"
		ib_username             The admin name
		ib_wapi_ver             The WAPI version string used to connect
		
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
            [string]$max_results = "_max_results=10000",
        [Parameter(Mandatory=$false)]
            [switch]$force,
        [Parameter(Mandatory=$false)]
            [switch]$ask_pw
    )

    BEGIN {
        # Reset all script variables to null until a successful connection is established
        $script:ib_grid_name   = $null
        $script:ib_grid_master = $null
        $script:ib_grid_ref    = $null
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
			Write-Debug "[DEBUG] Forcing connection"
			Set-IgnoreSelfSignedCerts
		}
		
        ##########
        # Build the values that need built
        if ($ask_pw) {
            $secure_pw = $( Read-Host -Prompt "Enter password" -AsSecureString )
            Write-Host ""
        } else {
            $secure_pw = ConvertTo-SecureString $password -AsPlainText -Force
        }
        $credential = New-Object System.Management.Automation.PSCredential ($username, $secure_pw)
        $uri_base = "https://$grid_master/wapi/$wapi_ver"
        Write-Debug "[DEBUG] Connect-GridMaster:  URI base = $uri_base"

        ##########
        # Establish an initial connection
        #   Exit if there is an error
        $uri = "$uri_base/grid"
        try {
            $grid_obj = Invoke-RestMethod -Uri $uri -Method Get -Credential $credential -SessionVariable new_session
        } catch {
            Write-Host '[ERROR] There was an error connecting to the Grid.'
            Write-Host $_.ErrorDetails
            return $false
        }
    
        $s1        = $grid_obj._ref.IndexOf(":")
        $grid_name = $grid_obj._ref.Substring( $( $s1 + 1 ) )

        # Update global variables with new connection information
        $script:ib_grid_name   = $grid_name
        $script:ib_grid_master = $grid_master
        $script:ib_grid_ref    = $( $grid_obj._ref )
        $script:ib_session     = $new_session
        $script:ib_uri_base    = $uri_base
        $script:ib_username    = $username
        $script:ib_wapi_ver    = $wapi_ver

        Write-Verbose "# You are now connected to Grid: '$grid_name'"

        return $true
    }
}

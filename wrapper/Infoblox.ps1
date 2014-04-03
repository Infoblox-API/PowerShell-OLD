#requires -version 4

########################################
#
# Author:  Don Smith
# Email :  don@infoblox.com
#       :  smithdonalde@gmail.com
# This script is provided as is.  Use at your own risk.
#


<#

TO DO:
    - Fix update function (not sure how as the JSON parser appears broken on the server)
    - Fix create function (when assigning with an EA)
    - Figure out how to make GET function work with direct output of multi-add
        - Maybe just do the GET right after the ADD then append to the array

#>

########################################
#
# Remember to enable powershell scripts to run on your system
#    example >> Set-ExecutionPolicy -ExecutionPolicy Unrestricted
#
[CmdletBinding()]
Param ()

########################################
#
# NOTES
#   Global Variables
#     $ib_*   are set in IB-Create-Session
#   Functions
#     All begin with "IB-"
#
########################################
$script:ib_script_revision = "2013-11-19 v1.11.19"


########################################
#
# UTILITY FUNCTIONS
#
########################################

function script:IB-ConvertFrom-JSON {
<#
.SYNOPSIS
Uses the JavaScript serializer object.   
#>
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] 
            $json
    )

    BEGIN {
        Write-Verbose '[convert-from-json] Begin'
        $ser  = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        $data_array = @()
    }

    PROCESS {
        $data = $ser.DeSerializeObject($json)
        $data_array += $data
    }

    END {
        return $data_array
    }
}

function script:IB-ConvertTo-JSON {
<#
.SYNOPSIS
Uses the JavaScript serializer object. The built-in PS ConvertTo-Json script is broken for nested extattr information.
#>
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
            $data
    )

    BEGIN {
        Write-Verbose '[convert-to-json] Begin'
        $ser  = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        $data_array = @()
    }

    PROCESS {
        $json = $ser.Serialize($data)
        $data_array += $json
    }

    END {
        return $data_array
    }
}

function script:IB-Ignore-Self-Signed-Certs {
########################################
# Do the following to ignore self-signed certificates
    add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

function script:IB-Get-Input-Choice {
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
            [int]$num_choices
    )

    BEGIN {
        Write-Verbose "[get-input-choice] range = 1..$num_choices"
    }

    PROCESS {   }

    END {
        # Return the "last" answer if there are fewer than 2 choices
        if ($num_choices -lt 2) {
            Write-Debug "[dbg] Fewer than 2 choices.  Returning '$num_choices'."
            return $num_choices
        }

        # Zero means quit, otherwise let's get a value from the range of 1 to the highest value
        [int]$input_value = -1
        while ($input_value -lt 0 -or $input_value -gt $num_choices) {
            [int]$input_value = Read-Host "--> Please choose from 1 to $num_choices.  Enter '0' (zero) to quit: "
        }
        return $input_value
    }

}

function script:IB-Write-Data {
<#
.SYNOPSIS
Displays data in PS default output format for custom objects (name/value pair table).
.PARAMETER data 
A data object to display.

.EXAMPLE
IB-Write-Data $my_data

Name                           Value                                                                                                                                                           
----                           -----                                                                                                                                                           
field1                         field_value1                                                                                                                                           
field2                         field_value2                                                                                                                                           
#>
    Param (
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
            [hashtable]$data
    )

    BEGIN {
        Write-Verbose '[write-data] Write to host'
    }

    PROCESS {
        Write-Debug "[dbg] Write-Data : num keys = $( $data.Keys.Count )"
        Write-Debug "[dbg] Write-Data : object count = $( $data.Count )"

        if ($data.Keys) {
            # We should be dealing with only a single object here
            $output = [ordered]@{}

            foreach ($field_name in $data.Keys) {
                $field_type = $data.Item($field_name).GetType().Name

                switch -wildcard ($field_type) {
                    "Object*" {
                        foreach ($attr in $data.Item($field_name).Keys) {
                            $my_key   = "[$field_name] $attr"
                            $my_value = $( $data.Item($field_name).$attr.value )
                            if (!$my_value) {
                                $my_value = $( $data.Item($field_name).$attr )
                            }
                            $output.Add( $my_key, $my_value )
                        }
                    }
                    "Dictionary*" {
                        foreach ($attr in $data.Item($field_name).Keys) {
                            $my_key   = "[$field_name] $attr"
                            $my_value = $( $data.Item($field_name).$attr.value )
                            if (!$my_value) {
                                $my_value = $( $data.Item($field_name).$attr )
                            }
                            $output.Add( $my_key, $my_value )
                        }
                    }
                    "String*" { 
                        $output.Add( $field_name, $( $data.$field_name ) )
                    }
                    default {
                        $output.Add( $field_name, $( $data.$field_name ) )
                    }
                }

            }
            $output
            Write-Host ""
        } else {
            # It's possible we'll get many objects so let's loop through
            foreach ($data_record in $data) { 
                $output = @{}
                $data_record | Get-Member -MemberType *Property | % { 
                    $output.($_.name) = $data_record.($_.name)
                } 
                $output
                Write-Host ""
            } 
        }
    }

    END {
        #Write-Verbose '[write-data] End'
    }

    # $data.Keys.Contains("extattrs")   |  True or False
    # $data.Item("extattrs")            |  displays the value of the object
    # $data.Item("name").GetType().Name |  Returns the data type of the field
}


########################################
#
# Infoblox core FUNCTIONS
#   Called by helper functions and may be called directly as well
#
########################################

function script:IB-Create-Object {
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
            [hashtable]$record,
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
            [string]$obj_type
    )

    BEGIN {
        Write-Verbose "[create-object] Creating object(s) in Infoblox"
        [array]$record_array = @()
    }

    PROCESS {
        # Prepare the data
        $json = $record | IB-ConvertTo-JSON

        # Prepare the URI
        $uri = "$ib_uri_base/$obj_type"
        Write-Debug "[dbg] $uri"

        # Send the update
        try {
            $result_ref = Invoke-WebRequest -Uri $uri -ContentType application/json -Method Post -WebSession $ib_session -Body ([System.Text.Encoding]::UTF8.GetBytes($json))
        } catch {
            Write-Host "[ERROR] There was an error creating the data."
            Write-Host "[ERROR] $uri"
            Write-Host $_.ErrorDetails
        }

        if ($result_ref) {
            [string]$rec_ref = $( IB-ConvertFrom-JSON $result_ref )
            [hashtable]$hash_obj = @{ "_ref" = $rec_ref }
            $record_array += $hash_obj
        }
    }

    END {
        return $record_array
    }
}

function script:IB-Create-Session {
<#
.SYNOPSIS
Establishes a session to an Infoblox Grid Master for all subsequent data calls.
.PARAMETER grid_master 
A single computer name or IP address.
.EXAMPLE
IB-Create-Session 192.168.1.2 admin infoblox
Creates a connection to a Grid Master using default credentials and IP address.
.EXAMPLE 
IB-Create-Session 192.168.1.2 admin -ask_pw
Creates a connection but allows entering the password securely (via prompt with masking).
.NOTES
This should be the first command run to ensure that a connection is established and global variables are properly configured.
#>
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

    PROCESS {   }

    END {
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
        Write-Debug "[DEBUG] Create-Session:  URI base = $uri_base"

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

        Write-Verbose "### You are now connected to Grid: '$grid_name' ###"

        return $true
    }
}

function script:IB-Delete-Object {
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
            [hashtable]$record,
#        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
#            [string]$_ref,
        [Parameter(Mandatory=$false,ValueFromPipeline=$false)]
            [switch]$force
    )

    BEGIN {
        [array]$results = @()
    }

    PROCESS {
        # Prepare the data
        $_ref = $record.Item("_ref")
        Write-Verbose "[delete-object] $_ref"

        switch ($force) {
            $true {
                $json = $record | IB-ConvertTo-JSON
                Write-Debug "[DEBUG] $json"

                # Prepare the URI
                $uri = "$ib_uri_base/$_ref"
                Write-Debug "[DEBUG] $uri"

                # Don't do this unless they force me to
                if ($force) {
                    # Send the update
                    try {
                        $result_ref = Invoke-WebRequest -Uri $uri -ContentType application/json -Method Delete -WebSession $ib_session -Body ([System.Text.Encoding]::UTF8.GetBytes($json))
                    } catch {
                        Write-Host "[ERROR] There was an error deleting the data."
                        Write-Host "[ERROR] $uri"
                        Write-Host $_.ErrorDetails
                    }

                    [string]$rec_ref = $( IB-ConvertFrom-JSON $result_ref )
                    [hashtable]$hash_obj = @{ "_ref" = $rec_ref }
                    $results += $hash_obj
                }
            }
            $false {
                Write-Host " >>Nothing deleted but I would have deleted $_ref"
                Write-Host " >>-force me next time to do it for real"
            }
        }

    }

    END {
        return $results
    }
}

function script:IB-Get-Object {
    Param (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [string]$_ref,
        [Parameter(Mandatory=$false)]
            [string]$_return_fields
    )

    BEGIN {
        if (!$ib_session) {
            Write-Host "[ERROR] Try creating a session first.  'IB-Create-Session'"
            return $false
        }

        # Initialize our counter and hashtable
        [hashtable[]]$data_array = $null
    }

    PROCESS {
        Write-Verbose "[get-object] $_ref"
        Write-Debug "[DEBUG] Get-Object: _ref           = $_ref"
        Write-Debug "[DEBUG] Get-Object: _return_fields = $_return_fields"

        $uri_return_type = "_return_type=json-pretty"
        $uri = "$ib_uri_base/$_ref"+'?'+$uri_return_type

        if ($_return_fields) {
            $uri = "$uri"+'&'+"_return_fields%2b=$_return_fields"
        }

        Write-Debug "[DEBUG-URI] $uri"

        # Try to obtain the data and print an error message if there is one
        try {
            $local_results = Invoke-WebRequest -Uri $uri -Method Get -WebSession $ib_session
        } catch {
            Write-Host "[ERROR] There was an error getting the data."
            Write-Host "[ERROR-URI] $uri"
            Write-Host $_.ErrorDetails
        }  

        # Grab only the content portion of the returned object
        $obj_content = $local_results.Content

        # Deserialize the JSON data into something manageable
        $data = $obj_content | IB-ConvertFrom-JSON

        $data_array += $data
    }

    END {
        return $data_array
    }
}

function script:IB-Search {
    Param (
        [Parameter(Mandatory=$false,Position=0)]
            [string]$search_string  = $( Read-Host -Prompt "Enter a valid search string" ),
        [Parameter(Mandatory=$false,Position=1)]
            [string]$objtype        = $( Read-Host -Prompt "Enter a valid object type" )
    )

    BEGIN {
        # Make sure we already have a session established
        if (!$ib_session) {
            Write-Host "[ERROR] Try creating a session first.  'IB-Create-Session'"
            return $false
        }
    }

    PROCESS {    }

    END {
        Write-Verbose "[search] $objtype : $search_string"
        # Build the URI
        # Search for the object reference
        if ($search_string)  { $uri_filter = "search_string~=$search_string" }
        if ($objtype)        { $uri_filter = "$uri_filter"+'&'+"objtype=$objtype" }
        $uri        = "$ib_uri_base/search"+'?'+"$uri_filter"
        Write-Debug "[DEBUG] Search: uri = $uri"

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

function script:IB-Show-Examples {
    Write-Host ""
    Write-Host "###### Infoblox functions loaded"
    Write-Host "###### Revision $ib_script_revision"
    Write-Host ""
    Write-Host "Examples of what you can do now"
    Write-Host "   IB-Create-Session 192.168.1.2 admin -ask"
    Write-Host "   `$my_results = IB-Search-Range"
    Write-Host "   `$my_obj_ref = IB-Select-Range `$my_results"
    write-host "   `$my_range   = IB-Get-Range  `$my_obj_ref"
    Write-Host "          OR"
    write-host "   `$my_range   = IB-Get-Object `$my_obj_ref [<optional field list, comma separated>]"
    write-host "   IB-Write-Data `$my_range"
    Write-Host ""
    Write-Host "Pipelining"
    Write-Host "   IB-Search-Range 192.168 | IB-Select-Range | IB-Get-Range | IB-Write-Data"
    Write-Host ""
    Write-Host "Use the following to see all available Infoblox functions"
    Write-Host "   Get-ChildItem function:\IB-* | Sort-Object"
    write-host ""
}

function script:IB-Update-Object {
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
            [hashtable]$record
    )

    BEGIN {
        [array]$results = @()
    }

    PROCESS {
        # Get the ref of the object to update
        $_ref = $record.Item("_ref")
        Write-Verbose "[update-object] $_ref"

        # Prepare the data
        $json = $record | IB-ConvertTo-JSON
        Write-Debug "[DEBUG] $json"

        # Prepare the URI
        $uri = "$ib_uri_base/$_ref"
        Write-Debug "[DEBUG] $uri"

        # Send the update
        try {
            $result_ref = Invoke-WebRequest -Uri $uri -ContentType application/json -Method Put -WebSession $ib_session -Body ([System.Text.Encoding]::UTF8.GetBytes($json))
        } catch {
            Write-Host "[ERROR-exception] $_.Exception"
            Write-Host "[ERROR-uri] $uri"
            Write-Host "[ERROR-details] $_.ErrorDetails"
        }

        if ($result_ref) {
            [string]$rec_ref = $( IB-ConvertFrom-JSON $result_ref )
            [hashtable]$hash_obj = @{ "_ref" = $rec_ref }
            $results += $hash_obj
        }
    }

    END {
        return $results
    }
}


########################################
#
# Infoblox helper FUNCTIONS
#
########################################

function script:IB-Add-EA-to-Object {
<#
.SYNOPSIS
This only adds the value to the in-memory object.  You still need to commit the change.
.NOTES
There is a display issue that doesn't show the data properly after adding values.  To get the display to update, convert the record TO JSON and then back.  The original object is modified.
#>
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
            [hashtable]$record,
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
            [string]$attribute,
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
            [string]$value
    )

    BEGIN {    }

    PROCESS {
        Write-Verbose "[add-ea] $( $record._ref ), $attribute = $value"
        Write-Debug "[add-ea] object = $( $record._ref )"
        Write-Debug "[add-ea] attribute = $attribute"
        Write-Debug "[add-ea] value     = $value"

        $new_ea = @{ "value" = $value }

        if ($record.ContainsKey("extattrs")) {
            $record.extattrs.Add($attribute, $new_ea)
        } else {
            $record.Add("extattrs", $new_ea)
        }

    }

    END {
        return
    }
}

function script:IB-Get-Network {
    Param (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [string]$_ref
    )

    BEGIN {
        [hashtable[]]$data_array = $null
    }

    PROCESS {
        Write-Verbose "[get-member] $_ref"
        # Specify the extra fields to return
        $return_fields = "comment,extattrs,members"

        # Get the data being requested
        $local_results = IB-Get-Object -_ref $_ref -_return_fields $return_fields

        # Add the data to our array
        $data_array += $local_results
    }

    END {
        return $data_array
    }
}

function script:IB-Get-Range {
    Param (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [string]$_ref
    )

    BEGIN {
        [hashtable[]]$data_array = $null
    }

    PROCESS {
        Write-Verbose "[get-range] $_ref"
        # Specify the extra fields to return
        $return_fields = "comment,name,extattrs,member"

        # Get the data being requested
        $local_results = IB-Get-Object -_ref $_ref -_return_fields $return_fields

        # Add the data to our array
        $data_array += $local_results
    }

    END {
        return $data_array
    }
}

function script:IB-Range-Member-Action {
<#
.SYNOPSIS
This only adds the value to the in-memory object.  You still need to commit the change.
.NOTES
There is a display issue that doesn't show the data properly after adding values.  To get the display to update, convert the record TO JSON and then back.  The original object is modified.
#>
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
            [hashtable]$record,
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
            [string]$member,
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        [ValidateSet("Add","Delete")]
            [string]$action
    )

    BEGIN {    }

    PROCESS {
        Write-Verbose "[range-member-action] $( $record._ref ), $member, $action"
        Write-Debug "[range-member-action] object = $( $record._ref )"
        Write-Debug "[range-member-action] member = $member"
        Write-Debug "[range-member-action] action = $action"

        # We could save a couple of lines but let's keep this simple to understand
        # We may also need this structure for more work later
        switch ($action) {
            "Add" {
                $new_member_record = @{
                    "_struct" = "dhcpmember";
                    "name"    = $member
                }

                if ($record.ContainsKey("member")) {
                    $record.Remove("member")
                }
                $record.Add("member", $new_member_record)
                
            }
            "Delete" {
                if ($record.ContainsKey("member")) {
                    $record.Remove("member")
                }
            }
        }
    }

    END {
        return
    }
}

function script:IB-Search-Network {
    Param (
        [Parameter(Mandatory=$true,Position=0)]
            [string]$search_string = $null
    )

    BEGIN {    }

    PROCESS {    }

    END {
        Write-Verbose "[search-network] $search_string"
        $local_results = IB-Search -search_string $search_string -objtype network

        return $local_results
    }
}

function script:IB-Search-Range {
    Param (
        [Parameter(Mandatory=$true,Position=0)]
            [string]$search_string = $null
    )

    BEGIN {    }

    PROCESS {    }

    END {
        Write-Verbose "[search-range] $search_string"
        $local_results = IB-Search -search_string $search_string -objtype range

        return $local_results
    }
}

function script:IB-Select-Range {
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
            [hashtable]$range_results,
        [Parameter(Mandatory=$false)]
            [switch]$ref_only
    )

    BEGIN {
        if (!$ib_session) {
            Write-Host "[ERROR] Try creating a session first.  'IB-Create-Session'"
            return $false
        }

        [array]$range_array = $()
        [int]$counter = 0
        Write-Verbose '[select-range] begin'
    }

    PROCESS {
        # Print the current record
        $range_results | foreach { $counter++; write-host "  [$counter] $($_.network), $($_.start_addr)-$($_.end_addr), $($_.network_view), $($_.comment)" }

        # Store the record so we can return only the one we want later
        $range_array += $range_results
    }

    END {
        Write-Debug "[DEBUG] Select-Range: number of options: $counter"

        switch ($counter) {
            0 { return $false }
            1 { return $range_results }
            default {
                Write-Host "Multiple matches found:  Please select an option from below"
                [int]$choice = IB-Get-Input-Choice( $counter )

                # Then return the indexed _ref for the appropriate answer
                if ($choice) {
                    if ($ref_only) {
                        return $( $range_array[$( $choice-1 )]._ref )
                    } else {
                        return $( $range_array[$( $choice-1 )] )
                    }
                }
            }
        }
  
        return $false
    }
}

function script:IB-Show-Connection-Details {
    #Get-ChildItem variable:ib_* | foreach { write-host "$($_.Name) = $($_.Value)" }
    Get-ChildItem variable:ib* -Exclude ib_session

    #Get-ChildItem function:IB-* | Sort-Object
}


########################################
#
# MAIN
#
########################################


########################################
# Show examples of what someone should do now
#
IB-Ignore-Self-Signed-Certs

IB-Show-Examples

# Clear-Variable ibvar_*
if (ib-create-session -wapi_ver v1.2.1) {
    Write-Host "Create a single network..."
    [hashtable]$ibvar_new0       = @{ "network" = "12.0.0.0/24"; "comment" = "net0" }
    $ibvar_add_one               = IB-Create-Object $ibvar_new0 -obj_type network

    Write-host "Create multiple newtorks..."
    [hashtable]$ibvar_new1       = @{ "network" = "12.0.1.0/24"; "comment" = "net1" }
    [hashtable]$ibvar_new2       = @{ "network" = "12.0.2.0/24"; "comment" = "net2" }
    [array]$ibvar_new_rec_array  = @()
    $ibvar_new_rec_array        += $ibvar_new1
    $ibvar_new_rec_array        += $ibvar_new2
    $ibvar_add_multiple          = $ibvar_new_rec_array | IB-Create-Object -obj_type network
    IB-Write-Data $ibvar_add_multiple[0]

    Write-Host "Create network with an EA..."
    [hashtable]$ibvar_new3       = @{ "network" = "12.0.3.0/24"; "comment" = "net3" }
    #IB-Add-EA-to-Object $ibvar_new3 -attribute "Site" -value "Test Site"
    IB-Create-Object $ibvar_new3 -obj_type network

    Write-Host "Search for created networks..."
    $ibvar_net12_search = IB-Search-Network 12.0
    $ibvar_net12_objs   = $ibvar_net12_search | IB-Get-Object
    $ibvar_net12_objs | IB-Write-Data

    Write-Host "Delete a single network..."
    IB-Delete-Object $ibvar_net12_objs[0] -force
    $ibvar_net12_search = IB-Search-Network 12.0
    $ibvar_net12_objs   = $ibvar_net12_search | IB-Get-Object
    $ibvar_net12_objs | IB-Write-Data

    Write-Host "Perform a simple update..."
    $ibvar_net12_search = IB-Search-Network 12.0.1.0
    $ibvar_net12_objs   = $ibvar_net12_search | IB-Get-Object
    $ibvar_net12_objs.comment
    $ibvar_net12_objs[0].comment = "index-0 changed"
    #IB-Update-Object $ibvar_net12_objs[0]

    Write-Host "Change the comments on several objects and update them..."
    $ibvar_net12_objs.comment
    $ibvar_net12_objs | foreach { $_.comment = "multi-update" }
    $ibvar_net12_objs.comment
    #$ibvar_net12_objs | IB-Update-Object


    Write-Host "Create several ranges..."
    $members = ib-search -objtype member -search_string .
    $dhcp_member = $members[0].host_name

    [hashtable]$ibvar_new_range1 = @{ 
        #"network"    = "12.0.1.0/24"; 
        "name"       = "range1.1"; 
        "comment"    = "new range 1"; 
        "start_addr" = "12.0.1.101"; 
        "end_addr"   = "12.0.1.150";
        #"server_association_type" = "MEMBER";
        #"member"     = "$( $dhcp_member )"
        }

    [hashtable]$ibvar_new_range2 = @{ 
        #"network"    = "12.0.1.0/24"; 
        "name"       = "range1.2"; 
        "comment"    = "new range 2"; 
        "start_addr" = "12.0.1.201"; 
        "end_addr"   = "12.0.1.250";
        #"server_association_type" = "MEMBER";
        #"member"     = "$( $dhcp_member )"
        }

    [hashtable]$ibvar_new_range3 = @{ 
        #"network"    = "12.0.2.0/24"; 
        "name"       = "range2"; 
        "comment"    = "new range 3"; 
        "start_addr" = "12.0.2.101"; 
        "end_addr"   = "12.0.2.150";
        #"server_association_type" = "MEMBER";
        #"member"     = "$( $dhcp_member )"
        }

    [array]$ibvar_new_range_array = @()
    $ibvar_new_range_array      += $ibvar_new_range1
    $ibvar_new_range_array      += $ibvar_new_range2
    $ibvar_new_range_array      += $ibvar_new_range3
    $ibvar_add_multiple          = $ibvar_new_range_array | IB-Create-Object -obj_type range

    Write-Host "Search for a single range match..."
    $ibvar_r         = ib-search-range 12.0.1
    $ibvar_r_details = $ibvar_r | ib-get-range

    Write-Host "Search for multiple ranges in a network..."
    $ibvar_w         = IB-Search-Range 12.0
    $ibvar_w_details = $ibvar_w | IB-Get-Range

    Write-Host "Clean up created objects..."
    #ib-search-range 12.0 | IB-Delete-Object -force

    # Debugging
    #IB-Search 192.168 range | IB-Get-Range | IB-Write-Data
    IB-Search 192.168 range | IB-Get-Range | IB-Range-Member-Action -action Delete -member gm.lab.local
    IB-Search 192.168 range | IB-Get-Range | IB-Range-Member-Action -action Add -member gm.lab.local
    IB-Search-Network 192.168 | IB-Get-Network | IB-Write-Data
}

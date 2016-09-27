<#
	.SYNOPSIS
		Configures PowerShell to ignore self-signed certificates
		
	.DESCRIPTION
		Infoblox uses self-signed certificates by default.
		This function overrides the PowerShell default setting so a successful connection can be established.
		
	.EXAMPLE 
		Set-IgnoreSelfSignedCerts
		
	.NOTES
		This should be the first command run (before attempting to create a session) unless you have uploaded signed certificates to the Infoblox Grid Master.
		
#>
function script:Set-IgnoreSelfSignedCerts {
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

# export-modulemember -function Set-IgnoreSelfSignedCerts

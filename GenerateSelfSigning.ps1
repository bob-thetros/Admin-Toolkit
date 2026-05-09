#This script generates script self-signing for powershell utilities to be used on the PC.  It signs the scripts within the
#

function Get-Company {
    <#
    .SYNOPSIS
        Reads the company name from <current folder>\company.txt.
        If the file does not exist, prompts the user, writes the value to
        the file and returns it.

    .OUTPUTS
        System.String – The company name that was read or entered.

    .NOTES
        This function sets `$global:Company` so that the caller can use the
        variable directly without needing to capture the return value.
    #>

    [CmdletBinding()]
    param()

    # Resolve the absolute path to company.txt in the current directory
    $companyFile = Join-Path -Path (Get-Location) -ChildPath 'company.txt'

    if (Test-Path -Path $companyFile) {
        # File exists – read its content (trim any trailing newline)
        try {
            $Company = Get-Content -Path $companyFile -ErrorAction Stop | Out-String
            $Company = $Company.Trim()
        } catch {
            Write-Warning "Unable to read `$($companyFile): $_"
            return $null
        }
    } else {
        # File does not exist – ask the user for a name and create it
        $Company = Read-Host 'Enter company name'
        if ($Company) {  # only write non‑empty values
            try {
                Set-Content -Path $companyFile -Value $Company -ErrorAction Stop
            } catch {
                Write-Warning "Unable to write `$($companyFile): $_"
                return $null
            }
        } else {
            Write-Warning 'No company name supplied – nothing written.'
            return $null
        }
    }

    # Make the variable available globally (so callers can just use $Company)
    Set-Variable -Name Company -Scope Global -Value $Company -Force

    # Return it for good measure
    return $Company
}
Get-Company
Write-Host "The company is: $Company"
IF(!(Test-Path "c:\scripts\$($Company)\" ))
{if(-not $usbDrive) {
  #USB or A Drive Letter Prompt
  $Title = "Select USB/A Drive"
  $Prompt = "Enter your choice"
  $Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("A", "D", "E", "Cancel")
  $Default = 3
  $Choice = $host.UI.PromptForChoice($Title, $Prompt, $Choices, $Default)
  # Action based on the choice
  switch($Choice)
  {
    0 {
        # A
        $usbDrive = " A:\Preinstall-scripts\"
    }
    1 {
        # D
        $usbDrive = "D:\"
    }
    2 {
        # E
        $usbDrive = "E:\"
    }
    
    3 {
        # Cancel
        Write-Host "You chose Cancel"
        Exit(1)
    }
  }
        Write-Host "$usbDrive"
  }  
}
#Determine if self sign exists
$codeCertificate = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=$($Company) Local Authenticode Script Signing"}
Write-Host $codeCertificate
If (!($codeCertificate))
{
  # Generate a self-signed Authenticode certificate in the local computer's personal certificate store.
  $authenticode = New-SelfSignedCertificate -Subject "$($Company) Local Authenticode Script Signing" -CertStoreLocation Cert:\LocalMachine\My -Type CodeSigningCert
  # Add the self-signed Authenticode certificate to the computer's root certificate store.
  ## Create an object to represent the LocalMachine\Root certificate store.
  $rootStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("Root","LocalMachine")
  ## Open the root certificate store for reading and writing.
  $rootStore.Open("ReadWrite")
  ## Add the certificate stored in the $authenticode variable.
  $rootStore.Add($authenticode)
  ## Close the root certificate store.
  $rootStore.Close()
  # Add the self-signed Authenticode certificate to the computer's trusted publishers certificate store.
  ## Create an object to represent the LocalMachine\TrustedPublisher certificate store.
  $publisherStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("TrustedPublisher","LocalMachine")
  ## Open the TrustedPublisher certificate store for reading and writing.
  $publisherStore.Open("ReadWrite")
  ## Add the certificate stored in the $authenticode variable.
  $publisherStore.Add($authenticode)
  ## Close the TrustedPublisher certificate store.
  $publisherStore.Close()
  # Get the code-signing certificate from the local computer's certificate store with the name *$($Company) Local Authenticode Script Signing* and store it to the $codeCertificate variable.
  $codeCertificate = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=$($Company) Local Authenticode Script Signing"}
  Write-Host "Selfsign certificate has now been Generated on this system."
}else{
 $codeCertificate = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=$($Company) Local Authenticode Script Signing"}
	Write-Host "Selfsign already exist on this system."
}
IF(!(Test-Path "c:\scripts\$($Company)\" ))
{
   md "c:\scripts\"
   md "c:\scripts\$($Company)\"
   xcopy /y /s /d "$usbDrive\Scripts\*.*"  "c:\scripts\$($Company)\*.*"
   xcopy /y /s /d "%usbDrive%\Scripts\*.*"  "c:\scripts\$($Company)\*.*"
}
Set-AuthenticodeSignature -FilePath "C:\scripts\$($Company)\*.ps1" -Certificate $codeCertificate 
Write-Host "Certificate has now been applied to the scripts within the c:\scripts\$($Company) folder."

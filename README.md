# AS2Go-Victim-PC-Add-Encryption

Files to prepare the AS2Go | Ransomware Attack. AS2Go is an acronym for Attack Scenario To Go. 

```PowerShell
Minimum required version of AS2Go.ps1 is 2.0.4.000!!!
```


Find more information here in my blog post [AS2Go | Lab Setup | Victim PC | Ransomware](https://herrhozi.com/2022/01/18/as2go--prepare-amp-run-the-attack--ransomware/). 

# Using an X.509 public key certificate to encrypt the files

The additional PowerShell script (AS2Go-encryption.ps1) encrypts files using an X.509 public key certificate. 
The PowerShell script is based on https://github.com/leomatias/Ransomware-Simulator⬈

Before the encryption, examples files are copied to the backup share e.g. \\\DC01\AD-Backup\VI-HerrHozi

AS2Go has NO procedure to decrypt the data after the attack, but the decryption routine is available in the Ransomware Simulator. Just delete the test directory after the attack.

# AS2Go-Victim-PC-Add-Encryption

The additional PowerShell script (AS2Go-encryption.ps1) encrypts files using an X.509 public key certificate. 
The PowerShell script is based on https://github.com/leomatias/Ransomware-Simulator⬈

Before the encryption, examples files are copied to the backup share \\<dc>\AD-Backup\<victim>, e.g. \\DC01\AD-Backup\VI-HerrHozi

AS2Go has NO procedure to decrypt the data after the attack, but the decryption routine is available in the Ransomware Simulator. Just delete the test directory after the attack.

# ================================================================
#  Digital Shield Corporation — AD Lab Misconfiguration Setup
#  Run as Domain Admin on DC01
#  Domain: digitalshield.local
# ================================================================

Import-Module ActiveDirectory

Write-Host "`n[*] Digital Shield Corp — AD Lab Setup" -ForegroundColor Cyan
Write-Host "[*] Adding Digital Shield employees and misconfigurations`n" -ForegroundColor Cyan

# ──── ORGANIZATIONAL UNITS ────
$OUs = @("IT","Security","DevOps","Executive","HR","Finance","ServiceAccounts")
foreach ($ou in $OUs) {
    try {
        New-ADOrganizationalUnit -Name $ou -Path "DC=digitalshield,DC=local" -ErrorAction Stop
        Write-Host "[+] Created OU: $ou" -ForegroundColor Green
    } catch { Write-Host "[-] OU $ou already exists" -ForegroundColor Yellow }
}

# ──── DIGITAL SHIELD EMPLOYEES (matching the lab) ────
$Users = @(
    @{Name="James Reynolds";    SAM="j.reynolds";    Pass="Summer2026!";     OU="Security";        Title="Senior Security Analyst"},
    @{Name="Michelle Chen";     SAM="m.chen";         Pass="DevOps2026!";     OU="DevOps";          Title="DevOps Lead"},
    @{Name="Adrian Kowalski";   SAM="a.kowalski";     Pass="SysAdmin2026!";   OU="IT";              Title="Systems Administrator"},
    @{Name="Dayo Okafor";      SAM="d.okafor";        Pass="Ex3cutive!2026";  OU="Executive";       Title="Chief Technology Officer"},
    @{Name="Sarah Martinez";    SAM="s.martinez";     Pass="HRWelcome2026!";  OU="HR";              Title="HR Manager"},
    @{Name="Kevin Park";       SAM="k.park";          Pass="Eng1neer!2026";   OU="IT";              Title="Software Engineer"},
    # Weak password users (for brute forcing)
    @{Name="Backup Service";   SAM="svc_backup";      Pass="Bk@gent_2026!";   OU="ServiceAccounts"; Title="Backup Service Account"},
    @{Name="Deploy Service";   SAM="svc_deploy";      Pass="D3pl0y_2026!";    OU="ServiceAccounts"; Title="Deployment Service"},
    @{Name="Web Admin";        SAM="webadmin";         Pass="W3b@dm1n_2026!";  OU="ServiceAccounts"; Title="Web Administration"},
    @{Name="DB Admin";         SAM="dbadmin";          Pass="Vault_Adm1n!";    OU="ServiceAccounts"; Title="Database Administrator"},
    @{Name="Vault Admin";      SAM="vaultadmin";       Pass="V@ultAdm1n_2026!";OU="ServiceAccounts"; Title="Vault Administrator"},
    # Honeypot/easy targets
    @{Name="Temp Intern";      SAM="intern";           Pass="Password1";       OU="IT";              Title="Summer Intern"},
    @{Name="Test Account";     SAM="testuser";         Pass="Test1234!";       OU="IT";              Title="Test Account"}
)

foreach ($u in $Users) {
    try {
        $ouPath = "OU=$($u.OU),DC=digitalshield,DC=local"
        New-ADUser -Name $u.Name -SamAccountName $u.SAM -UserPrincipalName "$($u.SAM)@digitalshield.local" `
            -AccountPassword (ConvertTo-SecureString $u.Pass -AsPlainText -Force) `
            -Enabled $true -Path $ouPath -Title $u.Title `
            -Description $u.Title -ChangePasswordAtLogon $false -PasswordNeverExpires $true
        Write-Host "[+] Created: $($u.SAM) / $($u.Pass)" -ForegroundColor Green
    } catch { Write-Host "[-] $($u.SAM) already exists" -ForegroundColor Yellow }
}

# ──── MISCONFIG 1: KERBEROASTABLE SPN ────
Write-Host "`n[*] Setting up Kerberoastable SPNs..." -ForegroundColor Cyan
try {
    Set-ADUser -Identity "svc_backup" -ServicePrincipalNames @{Add="MSSQLSvc/filestore.digitalshield.local:1433"}
    Set-ADUser -Identity "svc_deploy" -ServicePrincipalNames @{Add="HTTP/deploy.digitalshield.local"}
    # SQLService should already have an SPN from the existing setup
    Write-Host "[+] SPNs set on svc_backup and svc_deploy (Kerberoastable)" -ForegroundColor Green
} catch { Write-Host "[-] SPN setup error: $_" -ForegroundColor Red }

# ──── MISCONFIG 2: AS-REP ROASTABLE ────
Write-Host "`n[*] Setting up AS-REP Roastable accounts..." -ForegroundColor Cyan
try {
    Set-ADAccountControl -Identity "intern" -DoesNotRequirePreAuth $true
    Set-ADAccountControl -Identity "testuser" -DoesNotRequirePreAuth $true
    Set-ADAccountControl -Identity "svc_backup" -DoesNotRequirePreAuth $true
    Write-Host "[+] Pre-auth disabled on: intern, testuser, svc_backup" -ForegroundColor Green
} catch { Write-Host "[-] AS-REP setup error: $_" -ForegroundColor Red }

# ──── MISCONFIG 3: UNCONSTRAINED DELEGATION ────
Write-Host "`n[*] Setting up Unconstrained Delegation..." -ForegroundColor Cyan
try {
    # Set the Win10 machine for unconstrained delegation (if it exists)
    $ws = Get-ADComputer -Filter {Name -like "*WS*" -or Name -like "*WIN*" -or Name -like "*CLIENT*"} | Select-Object -First 1
    if ($ws) {
        Set-ADComputer -Identity $ws -TrustedForDelegation $true
        Write-Host "[+] Unconstrained delegation on: $($ws.Name)" -ForegroundColor Green
    }
} catch { Write-Host "[-] Delegation error: $_" -ForegroundColor Red }

# ──── MISCONFIG 4: WEAK GROUP MEMBERSHIPS ────
Write-Host "`n[*] Setting up weak group memberships..." -ForegroundColor Cyan
try {
    Add-ADGroupMember -Identity "Remote Desktop Users" -Members "j.reynolds","a.kowalski","intern"
    Add-ADGroupMember -Identity "Remote Management Users" -Members "a.kowalski"
    Write-Host "[+] j.reynolds, a.kowalski, intern added to RDP Users" -ForegroundColor Green
    Write-Host "[+] a.kowalski added to Remote Management Users (WinRM)" -ForegroundColor Green
} catch { Write-Host "[-] Group error: $_" -ForegroundColor Red }

# ──── MISCONFIG 5: GPP/SYSVOL CREDENTIAL ────
Write-Host "`n[*] Planting credential in SYSVOL..." -ForegroundColor Cyan
try {
    $sysvolPath = "\\DC01\SYSVOL\digitalshield.local\Policies"
    $gppDir = "$sysvolPath\{31B2F340-016D-11D2-945F-00C04FB984F9}\MACHINE\Preferences\Groups"
    New-Item -ItemType Directory -Path $gppDir -Force | Out-Null
    $gppXml = '<?xml version="1.0" encoding="utf-8"?><Groups clsid="{3125E937-EB16-4b4c-9934-544FC6D24D26}"><User clsid="{DF5F1855-51E5-4d24-8B1A-D9BDE98BA1D1}" name="svc_admin" image="2" changed="2026-01-15 09:30:00" uid="{A12B34C5}"><Properties action="U" newName="" fullName="Service Admin" description="Backup admin" cpassword="edBSHOwhZLTjt/QS9FeIcJ83mjWA98gw9guKOhJOdcqh+ZGMeXOsQbCpZ3xUjTLfCuNH8pG5aSVYdYw/NglVmQ" userName="svc_admin" /></User></Groups>'
    Set-Content "$gppDir\Groups.xml" $gppXml -Force
    Write-Host "[+] GPP Groups.xml planted in SYSVOL (cpassword recoverable)" -ForegroundColor Green
} catch { Write-Host "[-] SYSVOL error: $_" -ForegroundColor Red }

# ──── MISCONFIG 6: WRITABLE SHARES ────
Write-Host "`n[*] Setting up vulnerable shares..." -ForegroundColor Cyan
try {
    New-Item -ItemType Directory -Path "C:\Shares\IT_Docs" -Force | Out-Null
    New-Item -ItemType Directory -Path "C:\Shares\Credentials" -Force | Out-Null

    # IT docs with sensitive info
    $itNotes = "IT Department Internal Notes`r`n============================`r`nDC Admin backup: administrator / Password123!`r`nWSUS Server: wsus.digitalshield.local`r`nVPN PSK: DigitalShield-VPN-2026!`r`nWiFi Corp: DS-Corp-W1F1-2026`r`n`r`nFLAG{ds_ad_1_share_enumeration}"
    Set-Content "C:\Shares\IT_Docs\admin_notes.txt" $itNotes

    # Credentials file
    $svcCreds = "Service Account Credentials (DO NOT SHARE)`r`n==========================================`r`nsvc_backup: Bk@gent_2026!`r`nsvc_deploy: D3pl0y_2026!`r`nSQLService: Password123!`r`ndbadmin: Vault_Adm1n!`r`n`r`nFLAG{ds_ad_2_credential_in_share}"
    Set-Content "C:\Shares\Credentials\service_accounts.txt" $svcCreds

    New-SmbShare -Name "IT_Docs" -Path "C:\Shares\IT_Docs" -FullAccess "Everyone" -ErrorAction Stop
    New-SmbShare -Name "Credentials" -Path "C:\Shares\Credentials" -ReadAccess "Authenticated Users" -ErrorAction Stop
    Write-Host "[+] Shares created: IT_Docs (Everyone), Credentials (Authenticated Users)" -ForegroundColor Green
} catch { Write-Host "[-] Share error: $_" -ForegroundColor Red }

# ──── MISCONFIG 7: DCSYNC PERMISSION ────
Write-Host "`n[*] Setting up DCSync permission for a.kowalski..." -ForegroundColor Cyan
try {
    $domainDN = "DC=digitalshield,DC=local"
    $user = Get-ADUser -Identity "a.kowalski"
    $acl = Get-ACL "AD:\$domainDN"

    $guidReplicatingChanges = [GUID]"1131f6ad-9c07-11d1-f79f-00c04fc2dcd2"
    $guidReplicatingChangesAll = [GUID]"1131f6aa-9c07-11d1-f79f-00c04fc2dcd2"

    $ace1 = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($user.SID, "ExtendedRight", "Allow", $guidReplicatingChanges)
    $ace2 = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($user.SID, "ExtendedRight", "Allow", $guidReplicatingChangesAll)

    $acl.AddAccessRule($ace1)
    $acl.AddAccessRule($ace2)
    Set-ACL "AD:\$domainDN" $acl
    Write-Host "[+] DCSync rights granted to a.kowalski" -ForegroundColor Green
} catch { Write-Host "[-] DCSync ACL error: $_" -ForegroundColor Red }

# ──── MISCONFIG 8: DISABLE SMB SIGNING ON WIN10 ────
Write-Host "`n[*] Note: Disable SMB signing on Win10 manually for relay attacks" -ForegroundColor Yellow
Write-Host "    reg add HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters /v RequireSecuritySignature /t REG_DWORD /d 0 /f" -ForegroundColor Yellow

# ──── AD FLAGS ────
Write-Host "`n[*] Planting AD flags..." -ForegroundColor Cyan
try {
    Set-ADUser -Identity "administrator" -Description "FLAG{ds_ad_5_domain_admin_compromised}"
    New-Item -ItemType Directory -Path "C:\Flags" -Force | Out-Null
    "FLAG{ds_ad_3_kerberoast_success}" | Set-Content "C:\Flags\kerberoast.txt"
    "FLAG{ds_ad_4_dcsync_complete}" | Set-Content "C:\Flags\dcsync.txt"
    Write-Host "[+] AD flags planted" -ForegroundColor Green
} catch { Write-Host "[-] Flag error: $_" -ForegroundColor Red }

# ──── SUMMARY ────
Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  Digital Shield Corp AD Lab — Setup Complete" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  AD Flags (5 total):" -ForegroundColor White
Write-Host "    FLAG{ds_ad_1_share_enumeration}         — IT_Docs share" -ForegroundColor Gray
Write-Host "    FLAG{ds_ad_2_credential_in_share}       — Credentials share" -ForegroundColor Gray
Write-Host "    FLAG{ds_ad_3_kerberoast_success}        — Kerberoast SPN cracking" -ForegroundColor Gray
Write-Host "    FLAG{ds_ad_4_dcsync_complete}           — DCSync with a.kowalski" -ForegroundColor Gray
Write-Host "    FLAG{ds_ad_5_domain_admin_compromised}  — DA account description" -ForegroundColor Gray
Write-Host ""
Write-Host "  Misconfigurations:" -ForegroundColor White
Write-Host "    [1] Kerberoastable SPNs (svc_backup, svc_deploy)" -ForegroundColor Gray
Write-Host "    [2] AS-REP Roastable (intern, testuser, svc_backup)" -ForegroundColor Gray
Write-Host "    [3] Unconstrained Delegation (Win10)" -ForegroundColor Gray
Write-Host "    [4] Weak passwords (intern=Password1, SQLService desc)" -ForegroundColor Gray
Write-Host "    [5] GPP cpassword in SYSVOL" -ForegroundColor Gray
Write-Host "    [6] World-readable shares with credentials" -ForegroundColor Gray
Write-Host "    [7] DCSync rights for a.kowalski" -ForegroundColor Gray
Write-Host "    [8] No password complexity, no lockout" -ForegroundColor Gray
Write-Host "    [9] Password reuse across services" -ForegroundColor Gray
Write-Host ""
Write-Host "  Attack Path: Vault creds → AD creds → Kerberoast → DCSync → DA" -ForegroundColor Yellow
Write-Host "================================================================`n" -ForegroundColor Cyan

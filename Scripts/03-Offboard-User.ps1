# 03-Offboard-User.ps1
# Purpose: Offboard an Entra ID user by disabling sign-in, revoking sessions,
# removing license assignment, and removing role-based group membership.

Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All", "Group.ReadWrite.All"

# --- Target User ---
$userPrincipalName = "taylor.reed@SkyLab33.onmicrosoft.com"

Write-Host "Starting offboarding for: $userPrincipalName" -ForegroundColor Cyan

# --- Get User ---
$user = Get-MgUser -UserId $userPrincipalName -ErrorAction SilentlyContinue

if (-not $user) {
    Write-Host "User not found. Exiting script." -ForegroundColor Red
    return
}

# --- Disable Account ---
Update-MgUser -UserId $user.Id -AccountEnabled:$false
Write-Host "Account disabled." -ForegroundColor Green

# --- Revoke Sessions ---
Revoke-MgUserSignInSession -UserId $user.Id
Write-Host "Active sign-in sessions revoked." -ForegroundColor Green

# --- Remove License ---
$sku = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -eq "SPB" }
$currentLicenses = Get-MgUserLicenseDetail -UserId $user.Id
$hasLicense = $currentLicenses | Where-Object { $_.SkuId -eq $sku.SkuId }

if ($hasLicense) {
    Set-MgUserLicense -UserId $user.Id -AddLicenses @() -RemoveLicenses @($sku.SkuId)
    Write-Host "License removed." -ForegroundColor Green
}
else {
    Write-Host "No SPB license assigned. Skipping license removal." -ForegroundColor Yellow
}

# --- Remove from Operations Group ---
$group = Get-MgGroup -Filter "displayName eq 'Operations-Users'"
$membership = Get-MgUserMemberOf -UserId $user.Id | Where-Object { $_.Id -eq $group.Id }

if ($group -and $membership) {
    Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $user.Id
    Write-Host "Removed from Operations-Users group." -ForegroundColor Green
}
else {
    Write-Host "User is not a member of Operations-Users. Skipping group removal." -ForegroundColor Yellow
}

# --- Final Summary ---
Write-Host "`nOffboarding complete." -ForegroundColor Green
Write-Host "Display Name: $($user.DisplayName)"
Write-Host "UPN: $($user.UserPrincipalName)"
Write-Host "User ID: $($user.Id)"

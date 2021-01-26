#Gets License count & usage for the citrix XenDesktop License. 

#Region Settings
#Your License Server
$CitrixLicenseServer = "servername1"
 
#Do you want to report on licenses with 0 users?
$ShowUnusedLicenses = $true
 
#Toggle an alert above this percentage of licenses used
$UsageAlertThreshold = 5
 
#EndRegion Settings
#License user gets collected from the udadmin utility that comes pre-installed with citrix.
C:\"Program Files (x86)"\Citrix\Licensing\LS\udadmin.exe -list -a
#Grabs data about the citrix license. data includes number of licenses available and the expiration date for each license server.
C:\"Program Files (x86)"\Citrix\Licensing\LS\lmutil.exe lmstat -c "C:\Program Files (x86)\Citrix\Licensing\MyFiles\LicenseName-#####.##.#.lic" -a
#Region CollectData
#retrieve license information from the license server
$LicenseData = Get-WmiObject -class "Citrix_GT_License_Pool" -namespace "ROOT\CitrixLicensing"  -ComputerName $CitrixLicenseServer
 
$usageReport = @() 
$LicenseData |  select-object pld -unique | foreach { 
    $CurrentLicenseInfo = "" | Select-Object License, Count, Usage, pctUsed, Alert, #Expiration
    $CurrentLicenseInfo.License = $_.pld    
    $CurrentLicenseInfo.Count   = ($LicenseData  | where-object {$_.PLD -eq $CurrentLicenseInfo.License } | measure-object -property Count      -sum).sum 
    $CurrentLicenseInfo.Usage   = ($LicenseData  | where-object {$_.PLD -eq $CurrentLicenseInfo.License } | measure-object -property InUseCount -sum).sum
    #$CurrentLicenseInfo.Expiration   = ($LicenseData  | where-object {$_.PLD -eq $CurrentLicenseInfo.License } | Get-member -MemberType NoteProperty)
    $CurrentLicenseInfo.pctUsed = [Math]::Round($CurrentLicenseInfo.Usage / $CurrentLicenseInfo.Count * 100,2)
    $CurrentLicenseInfo.Alert   = ($CurrentLicenseInfo.pctUsed -gt $UsageAlertThreshold)
    if ($ShowUnusedLicenses -and $CurrentLicenseInfo.Usage -eq 0) {
        $usageReport += $CurrentLicenseInfo
    } elseif ($CurrentLicenseInfo.Usage -ne 0) {
        $usageReport += $CurrentLicenseInfo
    }
}

#EndRegion CollectData    
#$usageReport | Format-Table -AutoSize 
$usageReport | Format-Table -AutoSize | out-file "C:\ctrx-usage-report.txt"
 
# If any record raises an alert, send an email.
if (($usagereport | where {$_.alert -eq "True"}) -ne $null) {
    #Send Email Here
}

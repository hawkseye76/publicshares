#############################################################################################################################
#  Script based on info from this blog:
#  https://blogs.technet.microsoft.com/cmpfekevin/2016/09/27/using-powershell-to-update-dns-records-on-godaddy-api/
#############################################################################################################################

#############################################################
#    Import Required Modules
#    Optional Module for Notification
#############################################################

#Import-Module PushoverForPS


#############################################################
#    Setup Local Variables
#############################################################

$currentIp = $null

###############################
#    Pushover API Info
###############################
$pushover_app_key = "your_app_key_here"
$pushover_user_key = "your_user_key_here"

#Pushover Message if No Public IP Address (pulls host name and OS)
$message = @"
Attempts to get Public IP Address Failed

Source: $([System.Net.Dns]::GetHostName()) -  $($PSVersionTable.OS.split(" ")[0])
"@

###############################
#    GoDaddy API Info
###############################
$apiKey = ‘your_godaddy_api_key’
$apiSecret = ‘your_godaddy_api_secret'


###############################
#    GoDaddy API Headers
###############################
$Headers = @{}
$Headers[“Authorization”] = ‘sso-key ‘ + $apiKey + ‘:’ + $apiSecret


###############################
#    Current IP Addresses
###############################
$currentIp = ((Invoke-WebRequest -Uri "https://api.ipify.org?format=json").content | ConvertFrom-Json).ip
$currentIp6 = ((Invoke-WebRequest -Uri "https://api.ipify.org?format=json").content | ConvertFrom-Json).ip

Write-Output "IPv4 Public IP Address: $($currentIp)"
Write-Output "IPv6 Public IP Address: $($currentIp6)"


#############################################################
#    Verify that we actually pulled IP Addresses
#############################################################
if (($currentIp -eq "" -or $currentIp -eq $null)) # -and ($currentIp6 -eq "" -or $currentIp6 -eq $null))
{
    ###############################
    #    No IP Addresses found
    ###############################
    Write-Output "No Public IP Address was returned."
    #optional notification
    #Send-Pushover -UserKey $pushover_user_key -AppToken $pushover_app_key -Title "Public IP Address Failed" -Message $message -Device "your_device_name_here" -Priority Quiet
    exit
}
else
{
    ###############################
    #   Document IP's Found
    ###############################
    Write-Output "$(Get-Date) - Current Public IPv4 Address - $($currentIp)"
    
    Write-Output "$(Get-Date) - Current Public IPv6 Address - $($currentIp6)"
    
}

#############################################################
#    Set Records for your domain
#############################################################

###############################
#   Set domain name and records
###############################

$domain = "domain_name_here"
#sets all A records to same IP address
$records = @("*","@")

Write-Output "Processing Records for $($domain)"

foreach ($name in $records)
{
    ###############################
    #   Pull Current IP for record
    ###############################
    $dnsIp = ((Invoke-WebRequest https://api.godaddy.com/v1/domains/$domain/records/A/$name -method get -headers $headers).Content | ConvertFrom-Json).data

    #User for debugging
    #Write-Output "Current IP set on DNS Record $($name) - $($dnsIp)"
    #Write-Output "Current Public IP - $($currentIp)"
    
    ############################################
    #   Compare record ip vs pulled public ip
    ############################################
    if ( $currentIp -ne $dnsIp)
    {
        ############################################
        #   IP's don't match, update DNS record
        ############################################
        $JSON = ConvertTo-Json @(@{data=$currentIp;ttl=600})
        Invoke-WebRequest https://api.godaddy.com/v1/domains/$domain/records/A/$name -method put -headers $headers -Body $json -ContentType “application/json”
    }
    else
    {
        ############################################
        #   IP's match, no update required
        ############################################
        Write-Output "IP addresses match for $($name).$($domain), so no update will be processed for $($name) at this time." 
    }

    Write-Output " "
}

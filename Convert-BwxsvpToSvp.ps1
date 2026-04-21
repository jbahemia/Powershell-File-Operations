# Converts a BeamworX .bwxsvp XML file to an ASCII .svp file
# Usage: .\Convert-BwxsvpToSvp.ps1 -InputBwxsvp "input.bwxsvp" -OutputSvp "output.svp"

param(
    [string]$InputBwxsvp = $(Read-Host "Enter path to .bwxsvp file")
)

# Remove quotes if present
$InputBwxsvp = $InputBwxsvp.Trim('"')
$OutputSvp = [System.IO.Path]::ChangeExtension($InputBwxsvp, ".svp")
Write-Host ("Output will be written to: {0}" -f $OutputSvp)

function DecimalToDms {
    param([double]$decimal)
    $sign = if ($decimal -lt 0) { "-" } else { "" }
    $decimal = [math]::Abs($decimal)
    $deg = [int][math]::Truncate($decimal)
    $minf = ($decimal - $deg) * 60
    $min = [int][math]::Truncate($minf)
    $sec = ($minf - $min) * 60
    # Only degrees get the sign, minutes and seconds always positive
    return "{0}{1}:{2:00}:{3:00.00}" -f $sign, $deg, $min, [math]::Abs($sec)
}

function EpochToSvpDateTime {
    param([string]$epoch)
    $epochClean = ($epoch -replace '\s','') -replace '\..*',''
    $epochRef = [ref]0
    if ([double]::TryParse($epochClean, $epochRef)) {
        $dt = $null
        try {
            $dt = [System.DateTimeOffset]::FromUnixTimeSeconds($epochRef.Value).UtcDateTime
        } catch {
            Write-Warning "Epoch value out of range for DateTime: $($epochRef.Value)"
        }
        if ($dt -ne $null) {
            $year = $dt.Year
            $doy = $dt.DayOfYear
            $hms = $dt.ToString("HH:mm:ss")
            return @($year, $doy, $hms)
        } else {
            Write-Warning "Could not convert epoch to DateTime: $($epochRef.Value)"
            return @("0000", "000", "00:00:00")
        }
    } else {
        Write-Warning "Invalid epoch value: $epoch"
        return @("0000", "000", "00:00:00")
    }
}

[xml]$xml = Get-Content $InputBwxsvp
$out = @()
$out += "[SVP_VERSION_2]"
$out += $InputBwxsvp

foreach ($profile in $xml.BeamworX.Profiles.SoundVelocityProfile) {
    $epoch = $profile.Time
    $dtParts = EpochToSvpDateTime $epoch
    $year = $dtParts[0]
    $doy = $dtParts[1]
    $hms = $dtParts[2]
    # Latitude (Y), Longitude (X) - match SVP order
    $lat = DecimalToDms([double]$profile.Position.Y)
    $lon = DecimalToDms([double]$profile.Position.X)
    $section = "Section $year-$doy $hms $lat $lon"
    $out += $section
    foreach ($entry in $profile.Entries.Entry) {
        $depth = $entry.Depth
        $speed = $entry.Speed
        $out += "  $depth $speed"
    }
}

Set-Content -Path $OutputSvp -Value $out -Encoding UTF8
Write-Host "Conversion complete: $OutputSvp"

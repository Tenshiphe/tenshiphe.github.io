[CmdletBinding(DefaultParameterSetName = 'Simple')]
param (
    [Parameter(Mandatory)]
    [string]$InputFile = "C:\Temp\<file>.txt",

    [Parameter(ParameterSetName = 'Simple')]
    [switch]$HtmlOutput,

    [Parameter(ParameterSetName = 'Position')]
    [switch]$Position,

    [Parameter(ParameterSetName = 'Bigramme')]
    [switch]$Bigramme,

    [Parameter(ParameterSetName = 'Bigramme')]
    [ValidateRange(1, 8)]
    [int]$Step = 1
)

if (-not (Test-Path $InputFile)) {
    throw "File '$InputFile' not found."
}

try {
    $lines = Get-Content $InputFile | Where-Object { $_.Trim() -ne "" }    
}
catch {
    throw "Error during reading content."
}

if ($null -eq $lines) { throw "No data found." }

# Initialisation
$digitFreq = @{}
0..9 | ForEach-Object { $digitFreq["$_"] = 0 }

$positionFreq = @{}
$bigramFreq = @{}

0..9 | ForEach-Object {
    $i = $_
    $bigramFreq["$i"] = @{}
    0..9 | ForEach-Object { $bigramFreq["$i"]["$_"] = 0 }
}

foreach ($line in $lines) {
    $chars = $line.ToCharArray()
    $digits = @()
    foreach ($c in $chars) {
        if ($c -match '\d') { $digits += "$c" }
    }

    for ($i = 0; $i -lt $digits.Count; $i++) {
        $digit = $digits[$i]
        $digitFreq["$digit"]++
        if (-not $positionFreq.ContainsKey($i)) {
            $positionFreq[$i] = 0
        }
        $positionFreq[$i]++

        if ($Bigramme -and ($i + $Step -lt $digits.Count)) {
            $nextDigit = $digits[$i + $Step]
            $bigramFreq["$digit"]["$nextDigit"]++
        }
    }
}

# Sortie Bigramme
if ($Bigramme) {
    $result = @()
    foreach ($row in 0..9) {
        $entry = [ordered]@{ Chiffre = "${row}_" }
        foreach ($col in 0..9) {
            $entry["$col"] = $bigramFreq["$row"]["$col"]
        }
        $result += [PSCustomObject]$entry
    }

    if ($HtmlOutput) {
        $htmlPath = [System.IO.Path]::ChangeExtension($InputFile, ".bigramme.html")
        $result | ConvertTo-Html -Title "Bigrammes (step=$Step)" |
            Out-File -Encoding UTF8 $htmlPath
        Write-Host "Fichier HTML généré : $htmlPath"
    } else {
        $result | Format-Table -AutoSize
    }
}

# Sortie Position
elseif ($Position) {
    $result = $positionFreq.GetEnumerator() | Sort-Object Name | ForEach-Object {
        [PSCustomObject]@{
            Position = $_.Key
            Fréquence = $_.Value
        }
    }
 
    if ($HtmlOutput) {
        $htmlPath = [System.IO.Path]::ChangeExtension($InputFile, ".position.html")
        $result | ConvertTo-Html -Property Position, Fréquence -Title "Fréquence par Position" |
            Out-File -Encoding UTF8 $htmlPath
        Write-Host "Fichier HTML généré : $htmlPath"
    } else {
        $result | Format-Table -AutoSize
    }
}

# Sortie Fréquence simple
else {
    $result = $digitFreq.GetEnumerator() | Sort-Object Name | ForEach-Object {
        [PSCustomObject]@{
            Chiffre = $_.Key
            Fréquence = $_.Value
        }
    }

    if ($HtmlOutput) {
        $htmlPath = [System.IO.Path]::ChangeExtension($InputFile, ".html")
        $result | ConvertTo-Html -Property Chiffre, Fréquence -Title "Analyse Fréquentielle" |
            Out-File -Encoding UTF8 $htmlPath
        Write-Host "Fichier HTML généré : $htmlPath"
    } else {
        $result | Format-Table -AutoSize
    }
}

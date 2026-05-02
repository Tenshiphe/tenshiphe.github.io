<#
    .SYNOPSIS
    Generates TOTP codes for a given period.

    .DESCRIPTION
    This script generates TOTP (Time-based One-Time Password) codes from a Base32 secret key
    for a specified period. Codes are calculated according to RFC 6238.

    .PARAMETER SecretKey
    The Base32 secret key. If not provided, it will be requested securely.

    .PARAMETER TimeStep
    The interval in seconds between each code. Default: 30 seconds.

    .PARAMETER HashAlgorithm
    The hashing algorithm to use (SHA1, SHA256, SHA512). Default: SHA1.

    .PARAMETER CodeLength
    The length of generated codes (6 to 8 digits). Default: 6.

    .PARAMETER StartDate
    Mandatory. The start date in DD/MM/YYYY format.

    .PARAMETER Duration
    Mandatory. The generation duration: 1D (1 day), 1W (1 week), 1M (1 month), 1Y (1 year).

    .PARAMETER OutputFile
    The CSV output file. If not specified, a default name will be generated.

    .PARAMETER NoHeader
    Don't add header informations. The output file will containt only TOTP codes.

    .PARAMETER Force
    Forces overwriting of the output file if it already exists.

    .EXAMPLE
    .\Generate-TOTPCode.ps1 -SecretKey "JBSWY3DPHEPK5PXP" -StartDate "01/01/2025" -Duration "1D"
    Generates TOTP codes for January 1st, 2025 over one day.

    .EXAMPLE
    .\Generate-TOTPCode.ps1 -StartDate "01/01/2025" -Duration "1W" -HashAlgorithm SHA256 -CodeLength 8 -NoHeader
    Prompts for secret key and generates 8-digit codes with SHA256 over one week. Only TOTP code will be write in the out file.

    .EXAMPLE
    .\Generate-TOTPCode.ps1 -StartDate "01/01/2025" -Duration "1M" -OutputFile "codes.csv" -Force -Verbose
    Generates codes over one month with detailed output and overwrites the file if it exists.

    .NOTES
    Version: 1.0
    Date: 20/07/2025
    Author: Tenshiphe
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(HelpMessage = "The secret key to compute TOTP codes.")]
    [string]$SecretKey,
    
    [Parameter(HelpMessage = "The interval in second (default : 30)")]
    [int]$TimeStep = 30,
    
    [Parameter(HelpMessage = "Select the algoritm to compute TOTP codes (default : SHA1)")]
    [ValidateSet('SHA1', 'SHA256', 'SHA512')]
    [string]$HashAlgorithm = 'SHA1',
    
    [Parameter(HelpMessage = "The number of digits in the code (6-8, default : 6)")]
    [ValidateRange(6, 8)]
    [int]$CodeLength = 6,
    
    [Parameter(Mandatory, HelpMessage = "The start date")]
    [string]$StartDate,

    [Parameter(Mandatory, HelpMessage = "Choose the duration of code to compute (default : 1D)")]
    [ValidateSet('1D', '1W', '1M', '1Y')]
    [string]$Duration = '1D',
    
    [Parameter(HelpMessage = "The output file. The name is compute if not specified.")]
    [string]$OutputFile,

    [Parameter(HelpMessage = "The out file will contain TOTP codes without time informations.")]
    [string]$NoHeaders,

    [Parameter(HelpMessage = "Use this parameter to overwrite the output file")]
    [switch]$Force
)

function Convert-Base32ToBytes {
    param([string]$base32)
    
    $base32chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'
    $base32 = $base32.ToUpper()
    $bitsLength = $base32.Length * 5
    $bits = [System.Collections.BitArray]::new($bitsLength)
    $bitIndex = 0
    
    foreach ($char in $base32.ToCharArray()) {
        $val = $base32chars.IndexOf($char)
        if ($val -eq -1) { throw "Invalid Base32 character: $char" }
        
        $b = [Convert]::ToString($val, 2).PadLeft(5, '0')
        foreach ($bit in $b.ToCharArray()) {
            $bits[$bitIndex] = [bool]([int]::Parse($bit))
            $bitIndex++
        }
    }
    
    $bytes = New-Object byte[] ([Math]::Floor($bits.Length / 8))
    $bits.CopyTo($bytes, 0)
    return $bytes
}

function Get-TOTPCode {
    param(
        [byte[]]$secretBytes,
        [long]$timeCounter
    )
    
    $hmac = switch ($HashAlgorithm) {
        'SHA1'   { New-Object System.Security.Cryptography.HMACSHA1 }
        'SHA256' { New-Object System.Security.Cryptography.HMACSHA256 }
        'SHA512' { New-Object System.Security.Cryptography.HMACSHA512 }
    }
    $hmac.Key = $secretBytes
    
    $timeBytes = [BitConverter]::GetBytes([Int64]$timeCounter)
    if ([BitConverter]::IsLittleEndian) {
        [Array]::Reverse($timeBytes)
    }
    
    $hash = $hmac.ComputeHash($timeBytes)
    $offset = $hash[$hash.Length - 1] -band 0xf
    
    $code = ($hash[$offset] -band 0x7f) -shl 24
    $code += ($hash[$offset + 1] -band 0xff) -shl 16
    $code += ($hash[$offset + 2] -band 0xff) -shl 8
    $code += ($hash[$offset + 3] -band 0xff)
    
    $modulo = [Math]::Pow(10, $CodeLength)
    $result = $code % $modulo
    return $result.ToString().PadLeft($CodeLength, '0')
}

function Get-TextHash {
    param([string]$Text)
    
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    $hash = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text))
    return [System.BitConverter]::ToString($hash).Replace("-", "").ToLower()
}

# Calculate duration in seconds
$durationInSeconds = switch ($Duration) {
    '1D' { 86400 }
    '1W' { 604800 }
    '1M' { 2592000 }
    '1Y' { 31536000 }
}

# Handle secret key input if not provided
if (-not $SecretKey) {
    $secureKey = Read-Host -Prompt "Please enter your secret key" -AsSecureString
    $SecretKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey))
}

# Calculate secret key hash
$secretHash = Get-TextHash -Text $SecretKey

# Start the stopwatch
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Set French culture
$culture = [System.Globalization.CultureInfo]::new("fr-FR")
[System.Threading.Thread]::CurrentThread.CurrentCulture = $culture
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture

# Convert secret key to bytes
$secretBytes = Convert-Base32ToBytes $SecretKey

# Convert date to UTC
try {
    $parsedDate = [DateTime]::Parse($StartDate, $culture)
    $startDate = [DateTime]::SpecifyKind($parsedDate.Date, [DateTimeKind]::Utc)
} catch {
    throw "The date must be in DD/MM/YYYY format"
}

# Generate TOTP codes
$results = @()
$startEpoch = [DateTimeOffset]::new($startDate).ToUnixTimeSeconds()
$endEpoch = $startEpoch + $durationInSeconds

for ($time = $startEpoch; $time -le $endEpoch; $time += $TimeStep) {
    $timeCounter = [Math]::Floor($time / $TimeStep)
    $code = Get-TOTPCode -secretBytes $secretBytes -timeCounter $timeCounter
    $timestamp = [DateTimeOffset]::FromUnixTimeSeconds($time).DateTime.ToString("yyyy-MM-dd HH:mm:ss")

    if ($NoHeaders) {
        $results += [PSCustomObject]@{
            Code = $code
        }
    }
    else {
        $results += [PSCustomObject]@{
            Timestamp = $timestamp
            Code = $code
        }
    }
}

# Generate default output filename if not specified
if (-not $OutputFile) {
    $dateStr = ([datetime]::ParseExact($startDate, 'MM/dd/yyyy HH:mm:ss', $null)).ToString('yyyyddMM')
    $OutputFile = Join-Path $PSScriptRoot "TOTP-${HashAlgorithm}-${dateStr}-${Duration}.txt"
}

# Check if output file already exists
if (Test-Path $OutputFile) {
    if (-not $Force) {
        Write-Warning "File $OutputFile already exists. Use -Force to overwrite."
        return
    }
    Write-Verbose "File $OutputFile exists and will be overwritten (-Force)"
}

# Export results
if (-not $NoHeaders) {
    $header = @"
#############################################
# TOTP Code Generation Summary
# Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
#############################################
# Secret Hash (SHA256): $SecretHash
# Start date: $($StartDate.ToString("dd/MM/yyyy"))
# Duration: $Duration
# Algorithm: $Algorithm
# Code length: $CodeLength digits
# Interval: $TimeStep seconds
# Generated codes: $([string]::Format('{0:N0}', $results.Count))
# Execution time: $($stopwatch.Elapsed.ToString('hh\:mm\:ss\.fff'))
#############################################

"@

$results = $header + $results

}

$results | Export-Csv -Path $OutputFile -NoTypeInformation -Delimiter ";" -Encoding UTF8

# Stop the stopwatch and display verbose summary
$stopwatch.Stop()
Write-Verbose "Execution summary:"
Write-Verbose "- Start date: $startDate"
Write-Verbose "- Duration: $Duration"
Write-Verbose "- Algorithm: $HashAlgorithm"
Write-Verbose "- Code length: $CodeLength digits"
Write-Verbose "- Interval: $TimeStep seconds"
Write-Verbose "- Generated codes: $([string]::Format('{0:N0}', $results.Count))"
Write-Verbose "- Execution time: $($stopwatch.Elapsed.ToString('hh\:mm\:ss\.fff'))"
Write-Verbose "- Output file: $OutputFile"

Write-Host "Compute completed"
param(
    [string]$PartsDirectory = $PSScriptRoot,
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"
$manifestPath = Join-Path $PartsDirectory "manifest.json"
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $PartsDirectory $manifest.original_name
}

if (Test-Path -LiteralPath $OutputPath) {
    throw "Output already exists: $OutputPath"
}

foreach ($part in $manifest.parts) {
    $partPath = Join-Path $PartsDirectory $part.name

    if (-not (Test-Path -LiteralPath $partPath)) {
        throw "Missing part: $($part.name)"
    }

    $partInfo = Get-Item -LiteralPath $partPath
    if ($partInfo.Length -ne $part.size) {
        throw "Size mismatch for $($part.name)"
    }

    $partHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $partPath).Hash
    if ($partHash -ne $part.sha256) {
        throw "SHA-256 mismatch for $($part.name)"
    }
}

$output = [System.IO.File]::Create($OutputPath)

try {
    foreach ($part in $manifest.parts) {
        $partPath = Join-Path $PartsDirectory $part.name
        $input = [System.IO.File]::OpenRead($partPath)

        try {
            $input.CopyTo($output)
        }
        finally {
            $input.Dispose()
        }
    }
}
finally {
    $output.Dispose()
}

$restoredInfo = Get-Item -LiteralPath $OutputPath
$restoredHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $OutputPath).Hash

if ($restoredInfo.Length -ne $manifest.total_size) {
    throw "Restored size mismatch: expected $($manifest.total_size), got $($restoredInfo.Length)"
}

if ($restoredHash -ne $manifest.sha256) {
    throw "Restored SHA-256 mismatch: expected $($manifest.sha256), got $restoredHash"
}

[pscustomobject]@{
    OutputPath = $OutputPath
    Size = $restoredInfo.Length
    SHA256 = $restoredHash
    Verified = $true
}

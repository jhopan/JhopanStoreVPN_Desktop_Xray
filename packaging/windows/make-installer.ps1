$ErrorActionPreference = "Stop"

function Resolve-IsccPath {
    $cmd = Get-Command ISCC -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $candidates = @(
        "$Env:ProgramFiles\Inno Setup 6\ISCC.exe",
        "$Env:ProgramFiles(x86)\Inno Setup 6\ISCC.exe",
        "$Env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

$isccPath = Resolve-IsccPath
if (-not $isccPath) {
    Write-Error "Inno Setup Compiler (ISCC.exe) not found. Install Inno Setup first."
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$issPath = Join-Path $scriptDir "JhopanStoreVPN.iss"

& $isccPath $issPath
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build installer"
    exit $LASTEXITCODE
}

Write-Output "Installer build completed"

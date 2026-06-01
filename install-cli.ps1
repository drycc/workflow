#!/usr/bin/env pwsh
#Requires -Version 5.1

<#
.SYNOPSIS
    Install Drycc Workflow CLI for Windows.

.DESCRIPTION
    This script downloads and installs the Drycc Workflow CLI (drycc.exe)
    to the specified directory.

    Supports one-liner installation via:
        irm https://www.drycc.cc/install-cli.ps1 | iex

    Environment variables:
        INSTALL_DRYCC_PATH     - Override installation directory
        INSTALL_DRYCC_VERSION  - Override version to install
        INSTALL_DRYCC_MIRROR   - Set to "cn" for China mirror

.PARAMETER InstallPath
    The directory to install drycc.exe. Defaults to $env:LOCALAPPDATA\drycc.

.PARAMETER Version
    The version of drycc to install. Defaults to 'stable'.

.EXAMPLE
    .\install-cli.ps1

.EXAMPLE
    .\install-cli.ps1 -InstallPath "C:\Program Files\drycc"

.EXAMPLE
    $env:INSTALL_DRYCC_MIRROR="cn"; irm https://www.drycc.cc/install-cli.ps1 | iex
#>

param(
    [string]$InstallPath = "$env:LOCALAPPDATA\drycc",
    [string]$Version = "stable"
)

$ErrorActionPreference = "Stop"

# Support environment variables for one-liner installation
if ($env:INSTALL_DRYCC_PATH) {
    $InstallPath = $env:INSTALL_DRYCC_PATH
}
if ($env:INSTALL_DRYCC_VERSION) {
    $Version = $env:INSTALL_DRYCC_VERSION
}

# Support mirror for China users
if ($env:INSTALL_DRYCC_MIRROR -eq "cn") {
    $script:DryccBinUrlBase = "https://drycc-mirrors.drycc.cc/drycc/workflow-cli/releases"
} else {
    $script:DryccBinUrlBase = "https://github.com/drycc/workflow-cli/releases"
}

function Get-Architecture {
    $arch = $env:PROCESSOR_ARCHITECTURE.ToLower()
    switch ($arch) {
        "amd64" { return "amd64" }
        "x86"   { return "386" }
        "arm64" { return "arm64" }
        default {
            Write-Error "Unsupported architecture: $arch"
            exit 1
        }
    }
}

function Get-LatestVersion {
    $releasesUrl = "$script:DryccBinUrlBase"
    try {
        $response = Invoke-WebRequest -Uri $releasesUrl -UseBasicParsing
    } catch {
        Write-Error "Could not fetch releases page from $releasesUrl"
        exit 1
    }

    # FIX #1: The server may not return a Content-Type header, causing
    # Invoke-WebRequest to return $response.Content as System.Byte[] instead
    # of a decoded string. We must explicitly decode it before regex matching.
    $content = $response.Content
    if ($content -is [System.Byte[]]) {
        $content = [System.Text.Encoding]::UTF8.GetString($content)
    }

    $version = $content |
        Select-String -Pattern '/drycc/workflow-cli/releases/tag/(v[0-9\.]+)' |
        ForEach-Object { $_.Matches[0].Groups[1].Value } |
        Select-Object -First 1

    if (-not $version) {
        Write-Error "Could not extract version from $releasesUrl"
        exit 1
    }

    return $version
}

function Install-DryccCli {
    $platform = "windows"
    $arch = Get-Architecture
    $latestVersion = Get-LatestVersion

    if ($Version -eq "stable") {
        $Version = $latestVersion
    }

    # FIX #2: The release asset filenames on GitHub do NOT include a .exe
    # extension (e.g. "drycc-v1.10.2-windows-amd64"), but the script was
    # appending .exe to the download URL, causing a 404 Not Found.
    # We use the bare name for the download URL and rename locally.
    $assetName = "drycc-${Version}-${platform}-${arch}"
    $downloadUrl = "$script:DryccBinUrlBase/download/${Version}/${assetName}"
    $tempFile = [System.IO.Path]::GetTempFileName() + ".exe"

    Write-Host "Downloading Drycc Workflow CLI ${Version} for ${platform}-${arch}..."
    Write-Host "URL: $downloadUrl"

    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing
    } catch {
        Write-Error "Failed to download from $downloadUrl`n$($_.Exception.Message)"
        exit 1
    }

    # Validate the downloaded file is actually a PE executable, not an error page
    $fileMagic = [System.IO.File]::ReadAllBytes($tempFile)[0..1]
    $magicString = [System.Text.Encoding]::ASCII.GetString($fileMagic)
    if ($magicString -ne 'MZ') {
        Write-Error "Downloaded file is not a valid Windows executable (got '$magicString' instead of 'MZ'). The release asset may not exist."
        Remove-Item -Path $tempFile -Force
        exit 1
    }

    # Create install directory if it doesn't exist
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    }

    $installExe = Join-Path $InstallPath "drycc.exe"
    Move-Item -Path $tempFile -Destination $installExe -Force

    # Add to PATH if not already present
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$InstallPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$InstallPath", "User")
        Write-Host "Added $InstallPath to your PATH."
        Write-Host "Please restart your terminal or run: refreshenv"
    }

    Write-Host ""
    Write-Host "Drycc Workflow CLI (drycc) has been installed to: $installExe"
    Write-Host ""
    Write-Host "To learn more about Drycc Workflow, execute:"
    Write-Host "    $installExe --help"
    Write-Host ""
}

Install-DryccCli

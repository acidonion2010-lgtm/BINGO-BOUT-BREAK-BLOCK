# Windows PowerShell 5.1 and PowerShell 7 are supported.
# Public GitHub downloads only. No credentials or execution-policy changes.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('\A[0-9a-fA-F]{40}\z')]
    [string]$Revision,

    [string]$Destination = (Join-Path (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads') 'BINGO-BOUT-20261016'),

    [switch]$Starter
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Revision = $Revision.ToLowerInvariant()
$Repository = 'acidonion2010-lgtm/BINGO-BOUT-BREAK-BLOCK'
$RepositoryPath = 'handoff/20261016'
$BaseUrl = 'https://raw.githubusercontent.com/' + $Repository + '/' + $Revision + '/' + $RepositoryPath

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)
    return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-TemporaryPath {
    return (Join-Path $Destination ('.bingo-' + [Guid]::NewGuid().ToString('N') + '.partial'))
}

function Assert-Descriptor {
    param(
        [Parameter(Mandatory = $true)]$Descriptor,
        [Parameter(Mandatory = $true)][string]$ExpectedName
    )
    foreach ($PropertyName in @('name', 'bytes', 'sha256')) {
        if ($null -eq $Descriptor.PSObject.Properties[$PropertyName]) {
            throw "Manifest descriptor is missing: $PropertyName"
        }
    }
    if (($Descriptor.name -isnot [string]) -or ($Descriptor.name -cne $ExpectedName)) {
        throw "Unexpected manifest filename. Expected: $ExpectedName"
    }
    if ($Descriptor.bytes -isnot [ValueType]) {
        throw "Invalid byte count: $ExpectedName"
    }
    $ByteCount = [Int64]$Descriptor.bytes
    if (($ByteCount -le 0) -or ($ByteCount -gt 107374182400) -or ($Descriptor.bytes -ne $ByteCount)) {
        throw "Invalid byte count: $ExpectedName"
    }
    if (($Descriptor.sha256 -isnot [string]) -or ($Descriptor.sha256 -cnotmatch '\A[0-9a-fA-F]{64}\z')) {
        throw "Invalid SHA-256: $ExpectedName"
    }
}

function Assert-FileMatches {
    param(
        [Parameter(Mandatory = $true)][string]$LiteralPath,
        [Parameter(Mandatory = $true)]$Descriptor
    )
    if (-not [IO.File]::Exists($LiteralPath)) {
        throw "Expected a regular file: $LiteralPath"
    }
    $ActualLength = (Get-Item -LiteralPath $LiteralPath -Force).Length
    if (($ActualLength -ne [Int64]$Descriptor.bytes) -or ((Get-Sha256 $LiteralPath) -cne $Descriptor.sha256.ToLowerInvariant())) {
        throw "File verification failed: $LiteralPath . Existing files are not overwritten; choose an empty destination or inspect this file."
    }
}

function Receive-VerifiedFile {
    param([Parameter(Mandatory = $true)]$Descriptor)
    $FinalPath = Join-Path $Destination $Descriptor.name
    if (Test-Path -LiteralPath $FinalPath) {
        Assert-FileMatches -LiteralPath $FinalPath -Descriptor $Descriptor
        Write-Host ('Verified existing file: ' + $Descriptor.name)
        return $FinalPath
    }
    $TemporaryPath = Get-TemporaryPath
    try {
        Write-Host ('Downloading: ' + $Descriptor.name)
        $DownloadUrl = $BaseUrl + '/' + [Uri]::EscapeDataString($Descriptor.name)
        Invoke-WebRequest -UseBasicParsing -Uri $DownloadUrl -OutFile $TemporaryPath
        Assert-FileMatches -LiteralPath $TemporaryPath -Descriptor $Descriptor
        [IO.File]::Move($TemporaryPath, $FinalPath)
    }
    finally {
        if ([IO.File]::Exists($TemporaryPath)) {
            [IO.File]::Delete($TemporaryPath)
        }
    }
    return $FinalPath
}

if ([string]::IsNullOrWhiteSpace($Destination)) {
    throw 'Destination must not be empty.'
}
if (-not (Test-Path -LiteralPath $Destination)) {
    New-Item -ItemType Directory -Path $Destination | Out-Null
}
if (-not [IO.Directory]::Exists($Destination)) {
    throw "Destination must be a directory: $Destination"
}
$Destination = (Resolve-Path -LiteralPath $Destination).ProviderPath

$ManifestTemporaryPath = Get-TemporaryPath
try {
    Invoke-WebRequest -UseBasicParsing -Uri ($BaseUrl + '/manifest.json') -OutFile $ManifestTemporaryPath
    $ManifestLength = (Get-Item -LiteralPath $ManifestTemporaryPath -Force).Length
    if (($ManifestLength -le 0) -or ($ManifestLength -gt 1048576)) {
        throw 'Manifest size is outside the allowed range.'
    }
    $ManifestSha256 = Get-Sha256 $ManifestTemporaryPath
    $Manifest = [IO.File]::ReadAllText($ManifestTemporaryPath) | ConvertFrom-Json
    foreach ($PropertyName in @('schema', 'archive', 'parts')) {
        if ($null -eq $Manifest.PSObject.Properties[$PropertyName]) {
            throw "Manifest is missing: $PropertyName"
        }
    }
    if ($Manifest.schema -ne 1) {
        throw 'Unsupported manifest schema.'
    }
    Assert-Descriptor -Descriptor $Manifest.archive -ExpectedName 'BINGO-BOUT-new-chat-handoff-20261016.zip'
    $PartList = @($Manifest.parts)
    if (($PartList.Count -lt 1) -or ($PartList.Count -gt 999)) {
        throw 'Manifest must contain between 1 and 999 ordered ZIP parts.'
    }
    [Int64]$TotalPartBytes = 0
    for ($PartIndex = 0; $PartIndex -lt $PartList.Count; $PartIndex++) {
        $ExpectedPartName = '{0}.part{1:D3}' -f $Manifest.archive.name, ($PartIndex + 1)
        Assert-Descriptor -Descriptor $PartList[$PartIndex] -ExpectedName $ExpectedPartName
        $TotalPartBytes += [Int64]$PartList[$PartIndex].bytes
    }
    if ($TotalPartBytes -ne [Int64]$Manifest.archive.bytes) {
        throw 'ZIP part lengths do not add up to the archive length.'
    }
    if ($null -ne $Manifest.PSObject.Properties['starter']) {
        Assert-Descriptor -Descriptor $Manifest.starter -ExpectedName 'BINGO-BOUT-new-chat-starter-20261016.zip'
    }
    elseif ($Starter) {
        throw 'This manifest does not provide a starter ZIP.'
    }

    $SavedManifestPath = Join-Path $Destination ('manifest-' + $Revision + '.json')
    if (Test-Path -LiteralPath $SavedManifestPath) {
        if ((-not [IO.File]::Exists($SavedManifestPath)) -or ((Get-Sha256 $SavedManifestPath) -cne $ManifestSha256)) {
            throw "Existing manifest differs: $SavedManifestPath"
        }
    }
    else {
        [IO.File]::Move($ManifestTemporaryPath, $SavedManifestPath)
    }

    $Publication = [ordered]@{
        Schema = 1
        Revision = $Revision
        Repository = $Repository
        Path = $RepositoryPath
        ManifestSha256 = $ManifestSha256
        ManifestUrl = ($BaseUrl + '/manifest.json')
        ArchiveName = $Manifest.archive.name
        ArchiveBytes = [Int64]$Manifest.archive.bytes
        ArchiveSha256 = $Manifest.archive.sha256.ToLowerInvariant()
    }
    $PublicationText = ($Publication | ConvertTo-Json -Depth 4) + [Environment]::NewLine
    $PublicationPath = Join-Path $Destination 'PUBLICATION.json'
    if (Test-Path -LiteralPath $PublicationPath) {
        if ((-not [IO.File]::Exists($PublicationPath)) -or ([IO.File]::ReadAllText($PublicationPath) -cne $PublicationText)) {
            throw "PUBLICATION.json belongs to another publication. Choose an empty destination: $Destination"
        }
    }

    if ($Starter) {
        $ArchivePath = Receive-VerifiedFile -Descriptor $Manifest.starter
    }
    else {
        $ArchivePath = Join-Path $Destination $Manifest.archive.name
        if (Test-Path -LiteralPath $ArchivePath) {
            Assert-FileMatches -LiteralPath $ArchivePath -Descriptor $Manifest.archive
            Write-Host ('Verified existing archive: ' + $Manifest.archive.name)
        }
        else {
            $PartPaths = @()
            foreach ($PartDescriptor in $PartList) {
                $PartPaths += Receive-VerifiedFile -Descriptor $PartDescriptor
            }
            $AssemblyPath = Get-TemporaryPath
            try {
                $OutputStream = [IO.File]::Open($AssemblyPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
                try {
                    foreach ($PartPath in $PartPaths) {
                        $InputStream = [IO.File]::Open($PartPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
                        try {
                            $InputStream.CopyTo($OutputStream, 1048576)
                        }
                        finally {
                            $InputStream.Dispose()
                        }
                    }
                }
                finally {
                    $OutputStream.Dispose()
                }
                Assert-FileMatches -LiteralPath $AssemblyPath -Descriptor $Manifest.archive
                [IO.File]::Move($AssemblyPath, $ArchivePath)
            }
            finally {
                if ([IO.File]::Exists($AssemblyPath)) {
                    [IO.File]::Delete($AssemblyPath)
                }
            }
        }
        if ($null -ne $Manifest.PSObject.Properties['starter']) {
            $StarterArchivePath = Receive-VerifiedFile -Descriptor $Manifest.starter
            Write-Host ('Starter ZIP for the next chat: ' + $StarterArchivePath)
        }
    }

    if (-not [IO.File]::Exists($PublicationPath)) {
        $PublicationTemporaryPath = Get-TemporaryPath
        try {
            [IO.File]::WriteAllText($PublicationTemporaryPath, $PublicationText, (New-Object Text.UTF8Encoding($false)))
            [IO.File]::Move($PublicationTemporaryPath, $PublicationPath)
        }
        finally {
            if ([IO.File]::Exists($PublicationTemporaryPath)) {
                [IO.File]::Delete($PublicationTemporaryPath)
            }
        }
    }

    Write-Host ''
    Write-Host ('SHA-256 verified ZIP: ' + $ArchivePath)
    Write-Host ('Publication record: ' + $PublicationPath)
    Write-Host 'Extract the ZIP, then open 00_START_HERE.md and 01_NEW_CHAT_PROMPT.txt inside its folder.'
    return $ArchivePath
}
finally {
    if ([IO.File]::Exists($ManifestTemporaryPath)) {
        [IO.File]::Delete($ManifestTemporaryPath)
    }
}

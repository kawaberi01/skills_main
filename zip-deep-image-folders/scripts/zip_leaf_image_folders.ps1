param(
    [Parameter(Mandatory = $false)]
    [string]$RootPath = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [string[]]$ImageExtensions = @('jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'avif'),

    [switch]$DryRun,

    [switch]$Force,

    [switch]$OrganizeRootZips,

    [string]$WorkDirName = 'work_rename_zips',

    [string]$Title,

    [string]$AuthorName = '',

    [string]$SeriesSortName,

    [string]$SummaryFolderName,

    [string]$VolumePattern = '(?:v)?(\d{1,2})(?:s)?\.zip$'
)

$ErrorActionPreference = 'Stop'
$volumeKanji = [char]0x5DFB

function Get-LeafImageTargets {
    param(
        [string]$BasePath,
        [System.Collections.Generic.HashSet[string]]$AllowedExtensions,
        [System.IO.DirectoryInfo]$BaseItem
    )

    $leafDirs = Get-ChildItem -LiteralPath $BasePath -Directory -Recurse -Force | Where-Object {
        -not (Get-ChildItem -LiteralPath $_.FullName -Directory -Force -ErrorAction SilentlyContinue)
    }

    $rootIsLeaf = -not (Get-ChildItem -LiteralPath $BasePath -Directory -Force -ErrorAction SilentlyContinue)
    if ($rootIsLeaf) {
        $leafDirs = @([pscustomobject]@{ FullName = $BasePath }) + @($leafDirs)
    }

    foreach ($dir in $leafDirs) {
        $hasImage = Get-ChildItem -LiteralPath $dir.FullName -File -Force | Where-Object {
            $AllowedExtensions.Contains($_.Extension)
        } | Select-Object -First 1

        if (-not $hasImage) {
            continue
        }

        $relative = $dir.FullName.Substring($BasePath.Length).TrimStart('\')
        $zipBaseName = if ([string]::IsNullOrWhiteSpace($relative)) {
            $BaseItem.Name
        } else {
            $relative -replace '[\\/]', '_'
        }

        [pscustomobject]@{
            Directory = $dir.FullName
            RelativePath = $relative
            ZipName = ($zipBaseName + '.zip')
            ZipPath = (Join-Path -Path $BasePath -ChildPath ($zipBaseName + '.zip'))
        }
    }
}

function New-LeafFolderZips {
    param(
        [string]$BasePath,
        [string[]]$Extensions,
        [switch]$Overwrite,
        [switch]$Preview
    )

    $rootItem = Get-Item -LiteralPath $BasePath
    if (-not $rootItem.PSIsContainer) {
        throw "RootPath must be a directory: $BasePath"
    }

    $allowed = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($ext in $Extensions) {
        $null = $allowed.Add(('.' + $ext.TrimStart('.')))
    }

    $targets = Get-LeafImageTargets -BasePath $rootItem.FullName.TrimEnd('\') -AllowedExtensions $allowed -BaseItem $rootItem
    foreach ($target in $targets) {
        if (Test-Path -LiteralPath $target.ZipPath) {
            if (-not $Overwrite) {
                Write-Host "Skipping existing ZIP: $($target.ZipName)"
                continue
            }
            Remove-Item -LiteralPath $target.ZipPath -Force
        }

        if ($Preview) {
            Write-Host "Would create: $($target.ZipName) from $($target.RelativePath)"
            continue
        }

        Compress-Archive -LiteralPath $target.Directory -DestinationPath $target.ZipPath
        Write-Host "Created: $($target.ZipName)"
    }
}

function Get-VolumeNumber {
    param(
        [string]$FileName,
        [string]$Pattern
    )

    if ($FileName -imatch $Pattern) {
        return [int]$matches[1]
    }
    throw "Could not parse volume number from: $FileName"
}

function Remove-VolumeToken {
    param(
        [string]$BaseName,
        [string]$Pattern
    )

    return (($BaseName -replace $Pattern, '').TrimEnd('_', '-', ' ')).Trim()
}

function Remove-KnownNoise {
    param([string]$Value)

    $cleaned = $Value
    $prefixes = @(
        'MANGA-ZIP.APP_',
        'MANGA-ZIP.APP ',
        'MANGA-ZIP_',
        'MANGA-ZIP '
    )

    foreach ($prefix in $prefixes) {
        if ($cleaned.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $cleaned = $cleaned.Substring($prefix.Length)
            break
        }
    }

    return $cleaned.Trim('_', '-', ' ')
}

function Get-InferredTitle {
    param(
        [System.IO.FileInfo[]]$Files,
        [string]$Pattern
    )

    $candidates = foreach ($file in $Files) {
        $withoutExt = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $trimmed = Remove-VolumeToken -BaseName $withoutExt -Pattern ('(?i)' + $Pattern.Replace('\.zip$', '$'))
        $cleaned = Remove-KnownNoise -Value $trimmed
        if (-not [string]::IsNullOrWhiteSpace($cleaned)) {
            $cleaned
        }
    }

    if (-not $candidates) {
        throw 'Could not infer a title from the root ZIP files.'
    }

    $distinct = $candidates | Group-Object | Sort-Object -Property Count, Name -Descending
    if ($distinct.Count -gt 1 -and $distinct[0].Count -eq $distinct[1].Count) {
        $values = ($distinct | Select-Object -ExpandProperty Name) -join ', '
        throw "Could not infer a single title. Specify -Title. Candidates: $values"
    }

    return $distinct[0].Name
}

function Get-DefaultSeriesSortName {
    param([string]$Value)

    Add-Type -AssemblyName Microsoft.VisualBasic
    return [Microsoft.VisualBasic.Strings]::StrConv($Value, [Microsoft.VisualBasic.VbStrConv]::Narrow)
}

function Organize-RootZips {
    param(
        [string]$BasePath,
        [switch]$Overwrite,
        [switch]$Preview,
        [string]$WorkingDirectoryName,
        [string]$SeriesTitle,
        [string]$Author,
        [string]$SortName,
        [string]$FolderName,
        [string]$Pattern
    )

    $rootZips = Get-ChildItem -LiteralPath $BasePath -Filter *.zip -File | Sort-Object Name
    if (-not $rootZips) {
        throw "No ZIP files found at root: $BasePath"
    }

    if ([string]::IsNullOrWhiteSpace($SeriesTitle)) {
        $SeriesTitle = Get-InferredTitle -Files $rootZips -Pattern $Pattern
    }

    if ([string]::IsNullOrWhiteSpace($SortName)) {
        $SortName = Get-DefaultSeriesSortName -Value $SeriesTitle
    }

    if ([string]::IsNullOrWhiteSpace($FolderName)) {
        $FolderName = '{0}[{1}]{2}' -f $SortName, $Author, $SeriesTitle
    }

    $workDir = Join-Path $BasePath $WorkingDirectoryName
    $summaryDir = Join-Path $BasePath $FolderName

    if ($Preview) {
        Write-Host "Would prepare work directory: $workDir"
        Write-Host "Would prepare summary directory: $summaryDir"
        foreach ($file in $rootZips) {
            Write-Host "Would copy root ZIP: $($file.Name)"
        }
        return
    }

    if (Test-Path -LiteralPath $workDir) {
        Remove-Item -LiteralPath $workDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $workDir | Out-Null

    if (-not (Test-Path -LiteralPath $summaryDir)) {
        New-Item -ItemType Directory -Path $summaryDir | Out-Null
    }

    foreach ($file in $rootZips) {
        Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $workDir $file.Name)
    }

    $workFiles = Get-ChildItem -LiteralPath $workDir -Filter *.zip -File | Sort-Object Name
    $groups = $workFiles | Group-Object { '{0:D2}' -f (Get-VolumeNumber -FileName $_.Name -Pattern $Pattern) }

    foreach ($group in $groups) {
        $volume = $group.Name
        $items = $group.Group | Sort-Object Name
        $useSuffix = $items.Count -gt 1

        for ($i = 0; $i -lt $items.Count; $i++) {
            $suffix = ''
            if ($useSuffix) {
                $suffix = '-' + [char]([int][char]'a' + $i)
            }

            $newName = '{0} {1}{2}{3}.zip' -f $SeriesTitle, $volume, $volumeKanji, $suffix
            Rename-Item -LiteralPath $items[$i].FullName -NewName $newName
        }
    }

    Get-ChildItem -LiteralPath $workDir -Filter *.zip -File | Sort-Object Name | ForEach-Object {
        $destination = Join-Path $summaryDir $_.Name
        if ((Test-Path -LiteralPath $destination) -and (-not $Overwrite)) {
            throw "Destination already exists: $destination"
        }
        Move-Item -LiteralPath $_.FullName -Destination $destination -Force:$Overwrite
    }

    Write-Host "Prepared summary folder: $summaryDir"
}

$rootItem = Get-Item -LiteralPath $RootPath
if (-not $rootItem.PSIsContainer) {
    throw "RootPath must be a directory: $RootPath"
}

$rootFullPath = $rootItem.FullName.TrimEnd('\')
New-LeafFolderZips -BasePath $rootFullPath -Extensions $ImageExtensions -Overwrite:$Force -Preview:$DryRun

if ($OrganizeRootZips) {
    Organize-RootZips `
        -BasePath $rootFullPath `
        -Overwrite:$Force `
        -Preview:$DryRun `
        -WorkingDirectoryName $WorkDirName `
        -SeriesTitle $Title `
        -Author $AuthorName `
        -SortName $SeriesSortName `
        -FolderName $SummaryFolderName `
        -Pattern $VolumePattern
}

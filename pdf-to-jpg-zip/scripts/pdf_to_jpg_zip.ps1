[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$PdfPath,

  [string]$OutputDir,

  [ValidateRange(72, 1200)]
  [int]$Dpi = 200,

  [ValidateRange(0, 100000)]
  [int]$MaxPages = 0,

  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-Executable {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Pattern
  )

  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) {
    return $cmd.Source
  }

  $root = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
  if (Test-Path -LiteralPath $root) {
    $match = Get-ChildItem -Path $root -Recurse -Filter $Pattern -ErrorAction SilentlyContinue |
      Select-Object -First 1 -ExpandProperty FullName
    if ($match) {
      return $match
    }
  }

  throw "Could not locate $Name. Install Poppler or add it to PATH."
}

if (-not (Test-Path -LiteralPath $PdfPath)) {
  throw "PDF not found: $PdfPath"
}

$pdfItem = Get-Item -LiteralPath $PdfPath
if (-not $OutputDir) {
  $OutputDir = Join-Path $pdfItem.DirectoryName ($pdfItem.BaseName + '_jpg')
}

$zipPath = $OutputDir + '.zip'

if ((Test-Path -LiteralPath $OutputDir) -and -not $Force) {
  throw "Output directory already exists: $OutputDir. Use -Force to replace it."
}
if (Test-Path -LiteralPath $OutputDir) {
  Remove-Item -LiteralPath $OutputDir -Recurse -Force
}
if (Test-Path -LiteralPath $zipPath) {
  Remove-Item -LiteralPath $zipPath -Force
}

New-Item -ItemType Directory -Path $OutputDir | Out-Null

$pdfinfo = Resolve-Executable -Name 'pdfinfo' -Pattern 'pdfinfo.exe'
$pdftoppm = Resolve-Executable -Name 'pdftoppm' -Pattern 'pdftoppm.exe'

$infoText = & $pdfinfo $PdfPath
$pageLine = $infoText | Select-String -Pattern '^Pages:\s+(\d+)' | Select-Object -First 1
if (-not $pageLine) {
  throw "Could not determine page count for: $PdfPath"
}

$totalPages = [int]$pageLine.Matches[0].Groups[1].Value
$lastPage = $totalPages
if ($MaxPages -gt 0 -and $MaxPages -lt $totalPages) {
  $lastPage = $MaxPages
}

$prefix = Join-Path $OutputDir 'page'
& $pdftoppm -jpeg -r $Dpi -f 1 -l $lastPage $PdfPath $prefix

$jpgCount = (Get-ChildItem -LiteralPath $OutputDir -File -Filter '*.jpg').Count
if ($jpgCount -eq 0) {
  throw "No JPG files were created for: $PdfPath"
}

Compress-Archive -LiteralPath $OutputDir -DestinationPath $zipPath -Force

[pscustomobject]@{
  PdfPath = $PdfPath
  OutputDir = $OutputDir
  ZipPath = $zipPath
  PagesRendered = $jpgCount
  TotalPages = $totalPages
  Dpi = $Dpi
}

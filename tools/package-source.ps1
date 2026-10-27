param([string]$StudentCode = 'BookShelf-source')
$ErrorActionPreference = 'Stop'
if ($StudentCode -notmatch '^[A-Za-z0-9_-]+$') { throw 'StudentCode must contain only letters, digits, _ or -.' }
$project = Split-Path -Parent $PSScriptRoot
$output = Join-Path $project 'submission'
New-Item -ItemType Directory -Path $output -Force | Out-Null
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$target = Join-Path $output "$StudentCode.zip"
$stream = [System.IO.File]::Open($target, [System.IO.FileMode]::Create)
$zip = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
try {
  # Explicit allowlist keeps SDKs, caches, reports and build output out of the archive.
  $files = @('pubspec.yaml','pubspec.lock','analysis_options.yaml','README.md',
    '.gitignore','.metadata','firebase.json','firestore.rules','firestore.indexes.json')
  foreach ($folder in @('lib','android','assets','test','integration_test','test_driver','tools','rules-tests','docs','.github')) {
    $path = Join-Path $project $folder
    if (Test-Path -LiteralPath $path) {
      $files += Get-ChildItem -LiteralPath $path -Recurse -File -Force |
        ForEach-Object { $_.FullName.Substring($project.Length + 1) }
    }
  }
  foreach ($relative in $files) {
    $normalized = $relative.Replace('\','/')
    if ($normalized -match '(^|/)(node_modules|build|\.gradle|\.kotlin|\.cxx|\.externalNativeBuild|\.dart_tool|\.git|\.firebase)/') { continue }
    if ($normalized -match '(service.?account|firebase-adminsdk|key\.properties|local\.properties|\.jks$|\.keystore$|debug.*\.log$)') { continue }
    if ($normalized.EndsWith('.iml')) { continue }
    if ($normalized.EndsWith('GeneratedPluginRegistrant.java')) { continue }
    $source = Join-Path $project $relative
    if (!(Test-Path -LiteralPath $source -PathType Leaf)) {
      if ($relative -in @('pubspec.yaml','pubspec.lock','firestore.rules')) { throw "Missing required file: $relative" }
      continue
    }
    if ($normalized.EndsWith('.json')) {
      $raw = Get-Content -LiteralPath $source -Raw
      if ($raw -match '"private_key"\s*:|"type"\s*:\s*"service_account"') { throw "Private key found in $relative" }
    }
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $source, $normalized) | Out-Null
  }
} finally { $zip.Dispose(); $stream.Dispose() }
Write-Output "Source archive: $target"

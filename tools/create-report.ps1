param([string]$Config = (Join-Path $PSScriptRoot '..\report.local.json'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$configPath = (Resolve-Path -LiteralPath $Config).Path
$data = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$project = Split-Path -Parent $PSScriptRoot
$output = Join-Path $project 'submission'
New-Item -ItemType Directory -Path $output -Force | Out-Null
$code = $data.studentCode
if ($code -notmatch '^[A-Za-z0-9_-]+$') { throw 'Invalid StudentCode' }
$target = Join-Path $output "$code.docx"
function EscapeXml([string]$value) { [System.Security.SecurityElement]::Escape($value) }
function Paragraph([string]$value) { '<w:p><w:r><w:t xml:space="preserve">' + (EscapeXml $value) + '</w:t></w:r></w:p>' }
$stream = [System.IO.File]::Open($target, [System.IO.FileMode]::Create)
$zip = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
function AddText([string]$path, [string]$value) {
  $entry = $zip.CreateEntry($path)
  $writer = New-Object System.IO.StreamWriter($entry.Open(), (New-Object System.Text.UTF8Encoding($false)))
  try { $writer.Write($value) } finally { $writer.Dispose() }
}
try {
  $body = '<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders><w:top w:val="single" w:sz="4"/><w:left w:val="single" w:sz="4"/><w:bottom w:val="single" w:sz="4"/><w:right w:val="single" w:sz="4"/></w:tblBorders></w:tblPr><w:tr><w:tc>'
  foreach ($line in @(
    "Student Code: $($data.studentCode)", "Full Name: $($data.fullName)",
    "GitHub Repository URL: $($data.repositoryUrl)", "APK Download Link: $($data.apkUrl)",
    "Firebase Project ID: $($data.firebaseProjectId)", "Test account email: $($data.testEmail)",
    "Test account password: $($data.testPassword)")) { $body += Paragraph $line }
  $body += '</w:tc></w:tr></w:tbl><w:p/>'
  if (!$data.screenshots -or $data.screenshots.Count -eq 0) {
    $body += Paragraph 'DRAFT - Chua co anh chup thuc te. Chua du dieu kien nop bai.'
  }
  $rels = '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
  $types = '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="png" ContentType="image/png"/><Default Extension="jpg" ContentType="image/jpeg"/><Default Extension="jpeg" ContentType="image/jpeg"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>'
  $index = 0
  Add-Type -AssemblyName System.Drawing
  foreach ($shot in $data.screenshots) {
    $index++
    if (!$shot.caption) { throw "Screenshot $index needs a caption." }
    $imagePath = $shot.path
    if (![System.IO.Path]::IsPathRooted($imagePath)) { $imagePath = Join-Path (Split-Path -Parent $configPath) $imagePath }
    $imagePath = (Resolve-Path -LiteralPath $imagePath).Path
    $extension = [System.IO.Path]::GetExtension($imagePath).TrimStart('.').ToLowerInvariant()
    if ($extension -notin @('png','jpg','jpeg')) { throw 'Use PNG or JPEG screenshots.' }
    $picture = [System.Drawing.Image]::FromFile($imagePath)
    try {
      $scale = [Math]::Min(5486400.0 / $picture.Width, 7315200.0 / $picture.Height)
      $cx = [long]($picture.Width * $scale); $cy = [long]($picture.Height * $scale)
    } finally { $picture.Dispose() }
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $imagePath, "word/media/image$index.$extension") | Out-Null
    $rels += "<Relationship Id=`"rId$index`" Type=`"http://schemas.openxmlformats.org/officeDocument/2006/relationships/image`" Target=`"media/image$index.$extension`"/>"
    $body += Paragraph $shot.caption
    $body += "<w:p><w:r><w:drawing><wp:inline><wp:extent cx=`"$cx`" cy=`"$cy`"/><wp:docPr id=`"$index`" name=`"Screenshot $index`"/><a:graphic><a:graphicData uri=`"http://schemas.openxmlformats.org/drawingml/2006/picture`"><pic:pic><pic:nvPicPr><pic:cNvPr id=`"$index`" name=`"Screenshot $index`"/><pic:cNvPicPr/></pic:nvPicPr><pic:blipFill><a:blip r:embed=`"rId$index`"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill><pic:spPr><a:xfrm><a:off x=`"0`" y=`"0`"/><a:ext cx=`"$cx`" cy=`"$cy`"/></a:xfrm><a:prstGeom prst=`"rect`"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>"
    if ($shot.note) { $body += Paragraph $shot.note }
  }
  $rels += '</Relationships>'
  $body += '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134"/></w:sectPr>'
  AddText '[Content_Types].xml' $types
  AddText '_rels/.rels' '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>'
  AddText 'word/_rels/document.xml.rels' $rels
  AddText 'word/document.xml' ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"><w:body>' + $body + '</w:body></w:document>')
} finally { $zip.Dispose(); $stream.Dispose() }
Write-Output "Word report: $target"

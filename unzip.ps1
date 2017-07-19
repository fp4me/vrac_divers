Add-Type -AssemblyName System.IO.Compression.FileSystem
function UnzipInDir
{
    param([string]$zipfile)

    $extractPath = (Split-Path $zipfile -Parent)
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipFile)

    foreach ($item in $zip.Entries) {

    Write-Host "UNZIP"(Join-Path -Path $extractPath -ChildPath $item.FullName)
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($item,(Join-Path -Path $extractPath -ChildPath $item.FullName),$true)
    }
    <#[System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, (Split-Path $zipfile -Parent))#>
}

get-childitem  -recurse -Include *_23,*_21  | % {
     Write-Host "RENAME"$_.FullName "TO" ($_.FullName -replace "_21|_23", "_0")
     Rename-Item $_.FullName ($_.FullName -replace "_21|_23", "_0")
} 

get-childitem -recurse |  where {$_.extension -eq ".zip"} |  % {
    UnzipInDir $_.FullName
}
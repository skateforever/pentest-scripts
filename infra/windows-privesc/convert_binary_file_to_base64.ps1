Param(
    $filePath,
    [switch]$reverse = $false
)

## Usage
#
# From binary to UTF8 base-64 file with "b64" extension:
#     .\convert_binary_file_to_base64.ps1 path\to\file.bin
#
# From UTF8 base-64 file back to binary:
#     .\convert_binary_file_to_base64.ps1 -reverse path\to\file.bin.b64
#
##

$base64ext = ".b64"

if ($reverse)
{
    $contentString = Get-Content $filePath -Encoding UTF8
    $binary = [Convert]::FromBase64String($contentString)
    $originalFileName = ($filePath -split $base64ext)[0]
    $ext = [IO.Path]::GetExtension($originalFileName)
    $filenameWithoutExt = [IO.Path]::GetFileNameWithoutExtension($originalFileName)
    $parentDir = [IO.Path]::GetPathRoot($originalFileName)
    $unixTimeStamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $newFileName = ("{0}{1}{2}{3}{4}" -f $parentDir, $filenameWithoutExt, ".", $unixTimeStamp , $ext)
    Set-Content -Path $newFileName -Value $binary -Encoding Byte
}
else 
{
    $contentBytes = Get-Content $filePath -Encoding Byte
    $base64 = [Convert]::ToBase64String($contentBytes)
    Set-Clipboard -Value ($base64).ToString()
    Set-Content -Path ("{0}{1}" -f $filePath,$base64ext) -Value $base64
}

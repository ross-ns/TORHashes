$knownVersions = Get-Content ./knownVersions.txt        #Known versions of the TOR Browser bundle. Stops updates if the version is already known. Must contain at least one version
$baseUrl = "https://dist.torproject.org/torbrowser/"
$signedHashFile = "sha256sums-signed-build.txt"         #Filename containing the hashes of the signed builds of the TOR Browser
$unsignedHashFile = "sha256sums-unsigned-build.txt"     #Filename containing the hashes of the unsigned builds of the TOR Browser
$hashes = @()

#Scrape the TOR download page for links
$links = (Invoke-WebRequest -Uri $baseUrl).Links.Href | Get-Unique

foreach ($link in $links) {
    $parts = $link.Split(".")

    if ($parts[0] -match "^\d+$") {
        if (!$knownVersions.Contains($link)) {
            $link | Out-File ./knownVersions.txt -Encoding ascii -Append -Force

            Invoke-WebRequest -Uri (-join ($baseUrl, $link, $signedHashFile)) -OutFile (-join ($link.Trim("/"), "_", $signedHashFile))
            Invoke-WebRequest -Uri (-join ($baseUrl, $link, $unsignedHashFile)) -OutFile (-join ($link.Trim("/"), "_", $unsignedHashFile))

            $hashes += Import-Csv -Delimiter " " -Header "Hashes" -Path (-join ("./", $link.Trim("/"), "_", $signedHashFile))
            $hashes += Import-Csv -Delimiter " " -Header "Hashes" -Path (-join ("./", $link.Trim("/"), "_", $unsignedHashFile))
        }
    }
}
$hashes | Select-Object -ExpandProperty Hashes | Out-File ./tor_browser_hashes.txt -Append -Force # -Encoding unicode

$timeDate = Get-Date -Format "yyyyMMddTHHmmssffff"
git add *.txt *.ps1
git commit -m $timeDate
git push
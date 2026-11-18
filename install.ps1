# SUPORTE STACKFORGE - Instalador remoto
# Fonte oficial: https://github.com/HuugoCL/stackforge
# Uso: irm https://stackforge.pages.dev/sup | iex
$ErrorActionPreference = 'Stop'
$repo = 'HuugoCL/stackforge'
$releaseApi = "https://api.github.com/repos/$repo/releases/latest"
$zipName = 'SUPORTE-STACKFORGE-PTBR.zip'
$work = Join-Path $env:LOCALAPPDATA 'Stackforge\Suporte'
$download = Join-Path $work 'download'
$extract = Join-Path $work 'Arquivos'
$staging = Join-Path $work 'Arquivos.novo'

try {
    if ($PSVersionTable.PSVersion.Major -lt 5) { throw 'PowerShell 5.1 ou superior e necessario.' }
    if ($env:OS -ne 'Windows_NT') { throw 'Este instalador requer Windows.' }
    if (-not [Environment]::Is64BitOperatingSystem) { throw 'Windows 64 bits e necessario.' }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Abra o Windows PowerShell como administrador e execute o comando novamente.'
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    New-Item -ItemType Directory -Path $work -Force | Out-Null

    Write-Host 'Consultando a ultima Release oficial no GitHub...' -ForegroundColor Cyan
    $release = Invoke-RestMethod -Uri $releaseApi -Headers @{ 'User-Agent' = 'SUPORTE-STACKFORGE-Installer'; 'Accept' = 'application/vnd.github+json' }
    if (-not $release.assets) { throw 'A ultima Release nao possui arquivos publicados.' }
    $asset = @($release.assets | Where-Object { $_.name -ceq $zipName }) | Select-Object -First 1
    if (-not $asset -or -not $asset.browser_download_url) { throw "A ultima Release nao contem $zipName." }
    $assetUri = [Uri]$asset.browser_download_url
    if ($assetUri.Scheme -ne 'https' -or $assetUri.Host -notin @('github.com', 'objects.githubusercontent.com', 'release-assets.githubusercontent.com')) {
        throw 'A URL do pacote nao pertence a um host oficial de distribuicao do GitHub.'
    }

    if (Test-Path -LiteralPath $download) { Remove-Item -LiteralPath $download -Recurse }
    New-Item -ItemType Directory -Path $download | Out-Null
    $zip = Join-Path $download $zipName
    Write-Host "Baixando $zipName ($($release.tag_name))..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
    if (-not (Test-Path -LiteralPath $zip) -or (Get-Item -LiteralPath $zip).Length -lt 1000) { throw 'O arquivo ZIP baixado esta ausente ou pequeno demais.' }
    if ($asset.size -and (Get-Item -LiteralPath $zip).Length -ne [long]$asset.size) { throw 'O tamanho do pacote nao corresponde ao informado pelo GitHub.' }
    if ($asset.digest -match '^sha256:([a-fA-F0-9]{64})$') {
        $actualHash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
        if ($actualHash -ne $Matches[1]) { throw 'A verificacao SHA-256 do pacote falhou.' }
    } elseif ($release.body -match '(?im)^SHA256\s*:\s*([a-fA-F0-9]{64})\s*$') {
        $expectedHash = $Matches[1]
        $actualHash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
        if ($actualHash -ne $expectedHash) { throw 'A verificacao SHA-256 publicada na Release falhou.' }
    } else {
        throw 'A Release nao publicou um SHA-256 verificavel para o pacote. Instalacao cancelada.'
    }

    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse }
    Expand-Archive -LiteralPath $zip -DestinationPath $staging
    $compile = Get-ChildItem -LiteralPath $staging -Recurse -Filter 'Compile.ps1' -File | Select-Object -First 1
    if (-not $compile) { throw 'O pacote validado nao contem Compile.ps1.' }
    if (-not (Test-Path -LiteralPath (Join-Path $compile.DirectoryName 'LICENSE'))) { throw 'O pacote nao contem o arquivo de licenca esperado.' }

    if (Test-Path -LiteralPath $extract) { Remove-Item -LiteralPath $extract -Recurse }
    Move-Item -LiteralPath $staging -Destination $extract
    $relativeCompile = $compile.FullName.Substring($staging.Length).TrimStart('\','/')
    $compilePath = Join-Path $extract $relativeCompile
    $project = Split-Path -Parent $compilePath
    Push-Location $project
    try {
        Write-Host 'Compilando SUPORTE STACKFORGE...' -ForegroundColor Cyan
        & powershell.exe -NoProfile -File (Join-Path $project 'Compile.ps1')
        if ($LASTEXITCODE -ne 0) { throw "A compilacao falhou (codigo $LASTEXITCODE)." }
        $runner = Join-Path $project 'winutil.ps1'
        if (-not (Test-Path -LiteralPath $runner)) { throw 'A compilacao nao gerou winutil.ps1.' }
        Write-Host 'Iniciando SUPORTE STACKFORGE...' -ForegroundColor Cyan
        & powershell.exe -NoProfile -File $runner
        if ($LASTEXITCODE -ne 0) { throw "O aplicativo encerrou com codigo $LASTEXITCODE." }
    } finally { Pop-Location }
} catch {
    $message = $_.Exception.Message
    Write-Error "SUPORTE STACKFORGE: $message`nConsulte as instrucoes em https://github.com/$repo e verifique a ultima Release."
}

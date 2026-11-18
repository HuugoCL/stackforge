# SUPORTE STACKFORGE - Instalador remoto
# Fonte: https://github.com/HuugoCL/stackforge
# Uso: irm https://raw.githubusercontent.com/HuugoCL/stackforge/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'
$repo = 'HuugoCL/stackforge'
$zipName = 'SUPORTE-STACKFORGE-PTBR.zip'
$url = "https://github.com/$repo/releases/latest/download/$zipName"
$work = Join-Path $env:LOCALAPPDATA 'Stackforge\Suporte'
$zip = Join-Path $work $zipName
$extract = Join-Path $work 'Arquivos'

try {
    if ($PSVersionTable.PSVersion.Major -lt 5) { throw 'PowerShell 5.1 ou superior e necessario.' }
    if (-not [Environment]::Is64BitOperatingSystem) { throw 'Windows 64 bits e necessario.' }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Abra o Windows PowerShell como administrador e execute o comando novamente.'
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    New-Item -ItemType Directory -Force -Path $work | Out-Null
    Write-Host 'Baixando SUPORTE STACKFORGE...' -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    if ((Get-Item $zip).Length -lt 1000) { throw 'Arquivo ZIP recebido e invalido.' }
    if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
    Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force
    $compile = Get-ChildItem -Path $extract -Recurse -Filter 'Compile.ps1' -File | Select-Object -First 1
    if (-not $compile) { throw 'O pacote nao contem Compile.ps1.' }
    $project = $compile.DirectoryName
    Push-Location $project
    try {
        Write-Host 'Compilando e iniciando SUPORTE STACKFORGE...' -ForegroundColor Cyan
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $project 'Compile.ps1')
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao compilar o SUPORTE STACKFORGE.' }
        $runner = Join-Path $project 'winutil.ps1'
        if (-not (Test-Path $runner)) { throw 'A compilacao nao gerou winutil.ps1.' }
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner
        if ($LASTEXITCODE -ne 0) { throw "O aplicativo encerrou com codigo $LASTEXITCODE." }
    }
    finally { Pop-Location }
}
catch {
    Write-Error ("SUPORTE STACKFORGE: " + $_.Exception.Message + " Verifique se a release mais recente contem $zipName em https://github.com/$repo/releases")
}

<#
    DiscordCameraLive standalone - instalador

    Instala direto no Discord, sem Equicord e sem Vencord. Nao precisa de Node, nem de pnpm,
    nem de git: o bypass e um arquivo .js que o proprio Discord carrega.

    Uso:
      .\DiscordCameraLive-Standalone.ps1
      .\DiscordCameraLive-Standalone.ps1 -Proxy "socks5://127.0.0.1:9050"
      .\DiscordCameraLive-Standalone.ps1 -Mode Uninstall
#>

[CmdletBinding()]
param(
    [ValidateSet('Install', 'Uninstall', 'Status')]
    [string] $Mode = 'Install',

    [string] $Proxy = '',

    [string] $ExcludedCountries = 'BR',

    [switch] $Yes
)

$ErrorActionPreference = 'Stop'
try { Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force } catch { }

# O trecho antes do @ e opcional e casado com ganancia, para a senha poder conter @ e :
# codificados. Sem validar aqui, um endereco com erro de digitacao viraria configuracao e o
# bypass cairia para a lista gratuita sem dizer por que.
if ($Proxy -ne '' -and $Proxy -notmatch '^(socks5|socks4|https?)://(?:.+@)?[^:/@\s]+:\d{1,5}$') {
    Write-Host ''
    Write-Host '  [X] Endereco de proxy invalido.' -ForegroundColor Red
    Write-Host '      Use socks5://host:porta, ou socks5://usuario:senha@host:porta.' -ForegroundColor DarkGray
    Write-Host '      Senha com @ ou : precisa vir codificada (@ vira %40, : vira %3A).' -ForegroundColor DarkGray
    Write-Host ''
    exit 1
}

$InstallDir = Join-Path $env:LOCALAPPDATA 'DiscordCameraLive'
$PatcherName = 'discordcameralive.js'
$DiscordFlavours = @('Discord', 'DiscordPTB', 'DiscordCanary')
$StubPackage = '{"name":"discord","main":"index.js"}'

function Write-Step($m) { Write-Host "  [*] $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "  [!] $m" -ForegroundColor Yellow }
function Write-Bad($m)  { Write-Host "  [X] $m" -ForegroundColor Red }

function Confirm-Action($question) {
    if ($Yes) { return $true }
    Write-Host ''
    $answer = Read-Host "  $question [s/N]"
    return $answer -match '^[sSyY]'
}

# Cada versao do Discord vive numa pasta app-VERSAO propria. A que importa e a mais nova, que
# e a que o atalho abre.
function Get-DiscordResources {
    $found = @()
    foreach ($flavour in $DiscordFlavours) {
        $root = Join-Path $env:LOCALAPPDATA $flavour
        if (-not (Test-Path -LiteralPath $root)) { continue }

        $versions = Get-ChildItem -LiteralPath $root -Directory -Filter 'app-*' -ErrorAction SilentlyContinue |
            Sort-Object { [Version]($_.Name -replace '^app-', '') } -ErrorAction SilentlyContinue
        if (-not $versions) { continue }

        $resources = Join-Path $versions[-1].FullName 'resources'
        if (Test-Path -LiteralPath (Join-Path $resources 'app.asar')) {
            $found += [pscustomobject]@{ Flavour = $flavour; Resources = $resources }
        }
    }
    return $found
}

# Tres estados possiveis, e confundir eles apagaria a instalacao de outra pessoa:
#   Vanilla   - Discord intocado
#   Nosso     - ja tem o standalone
#   OutroMod  - Equicord, Vencord ou parecido ja esta injetado
function Get-InjectionState($resources) {
    $asar = Join-Path $resources 'app.asar'
    $original = Join-Path $resources '_app.asar'

    if (-not (Test-Path -LiteralPath $original)) { return 'Vanilla' }

    $index = Join-Path $asar 'index.js'
    if (Test-Path -LiteralPath $index) {
        $content = [IO.File]::ReadAllText($index, [Text.Encoding]::UTF8)
        if ($content -like "*$PatcherName*") { return 'Nosso' }
    }
    return 'OutroMod'
}

function Stop-Discord {
    $running = @()
    foreach ($flavour in $DiscordFlavours) {
        $procs = Get-Process -Name $flavour -ErrorAction SilentlyContinue
        if ($procs) { $running += $flavour }
    }
    if (-not $running) { return }

    Write-Step "Fechando o Discord ($($running -join ', '))"
    foreach ($flavour in $running) {
        Get-Process -Name $flavour -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }

    # Esperar a saida de verdade: gravar por cima de um processo vivo falha no Windows.
    for ($i = 0; $i -lt 40; $i++) {
        Start-Sleep -Milliseconds 250
        $alive = $false
        foreach ($flavour in $DiscordFlavours) {
            if (Get-Process -Name $flavour -ErrorAction SilentlyContinue) { $alive = $true }
        }
        if (-not $alive) { return }
    }
    throw 'O Discord nao fechou. Feche na mao e rode de novo.'
}

function Install-Patcher {
    $source = Join-Path $PSScriptRoot $PatcherName
    if (-not (Test-Path -LiteralPath $source)) {
        throw "Nao achei $PatcherName ao lado deste script."
    }

    if (-not (Test-Path -LiteralPath $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
    Copy-Item -LiteralPath $source -Destination (Join-Path $InstallDir $PatcherName) -Force
    Write-Ok "Bypass copiado para $InstallDir"

    # As configuracoes ficam fora da pasta do Discord de proposito: uma atualizacao do Discord
    # apaga resources/ inteiro, e levaria a proxy do usuario junto.
    $settingsPath = Join-Path $InstallDir 'settings.json'
    $settings = @{}
    if (Test-Path -LiteralPath $settingsPath) {
        try { $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $settings = @{} }
    }

    $result = [ordered]@{
        enabled = $true
        proxy = $Proxy
        excludedCountries = $ExcludedCountries
    }
    if ($Proxy -eq '' -and $settings.proxy) { $result.proxy = $settings.proxy }

    [IO.File]::WriteAllText($settingsPath, ($result | ConvertTo-Json), (New-Object Text.UTF8Encoding $false))
    Write-Ok "Configuracao gravada em $settingsPath"
}

function Install-Injection($resources) {
    $asar = Join-Path $resources 'app.asar'
    $original = Join-Path $resources '_app.asar'
    $patcher = Join-Path $InstallDir $PatcherName

    Rename-Item -LiteralPath $asar -NewName '_app.asar' -Force
    try {
        New-Item -ItemType Directory -Path $asar -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $asar 'package.json'), $StubPackage, (New-Object Text.UTF8Encoding $false))
        [IO.File]::WriteAllText((Join-Path $asar 'index.js'), "require($($patcher | ConvertTo-Json));", (New-Object Text.UTF8Encoding $false))
    } catch {
        # Sem o desfazer, uma falha aqui deixaria o Discord sem app.asar nenhum: ele nao abriria
        # mais, e o usuario nao teria como saber o porque.
        if (Test-Path -LiteralPath $asar) { Remove-Item -LiteralPath $asar -Recurse -Force -ErrorAction SilentlyContinue }
        Rename-Item -LiteralPath $original -NewName 'app.asar' -Force
        throw
    }
}

function Remove-Injection($resources) {
    $asar = Join-Path $resources 'app.asar'
    $original = Join-Path $resources '_app.asar'

    if (-not (Test-Path -LiteralPath $original)) { return $false }

    if (Test-Path -LiteralPath $asar) { Remove-Item -LiteralPath $asar -Recurse -Force }
    Rename-Item -LiteralPath $original -NewName 'app.asar' -Force
    return $true
}

function Show-Status {
    $installs = Get-DiscordResources
    if (-not $installs) { Write-Bad 'Nao achei nenhum Discord instalado.'; return }

    foreach ($install in $installs) {
        $state = Get-InjectionState $install.Resources
        $label = switch ($state) {
            'Vanilla'  { 'sem nada instalado' }
            'Nosso'    { 'com o DiscordCameraLive standalone' }
            'OutroMod' { 'com Equicord/Vencord (ou outro mod)' }
        }
        Write-Host "  $($install.Flavour): $label" -ForegroundColor White
        Write-Host "    $($install.Resources)" -ForegroundColor DarkGray
    }

    $log = Join-Path $InstallDir 'discordcameralive.log'
    if (Test-Path -LiteralPath $log) {
        Write-Host ''
        Write-Host '  ultimas linhas do registro:' -ForegroundColor White
        Get-Content -LiteralPath $log -Tail 12 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    }
}

Write-Host ''
Write-Host '      .------.' -ForegroundColor Yellow
Write-Host '     /  x7rG  \' -ForegroundColor Yellow
Write-Host "     '--------'" -ForegroundColor Yellow
Write-Host '       \    /' -ForegroundColor Yellow
Write-Host '        \  /' -ForegroundColor Yellow
Write-Host '         \/' -ForegroundColor Yellow
Write-Host '      -- E N T E R P R I S E --' -ForegroundColor DarkYellow
Write-Host ''
Write-Host '  DiscordCameraLive standalone' -ForegroundColor Magenta
Write-Host '  Go Live e camera de volta, direto no Discord' -ForegroundColor DarkGray
Write-Host '  Mantido por x7rG' -ForegroundColor DarkGray
Write-Host ''

if ($Mode -eq 'Status') { Show-Status; return }

$installs = Get-DiscordResources
if (-not $installs) { Write-Bad 'Nao achei nenhum Discord instalado.'; return }

if ($Mode -eq 'Uninstall') {
    Stop-Discord
    foreach ($install in $installs) {
        if ((Get-InjectionState $install.Resources) -ne 'Nosso') {
            Write-Warn "$($install.Flavour) nao tem o standalone, deixando como esta."
            continue
        }
        if (Remove-Injection $install.Resources) { Write-Ok "$($install.Flavour) voltou ao normal." }
    }
    Write-Host ''
    Write-Host "  A pasta $InstallDir ficou, com o registro e a sua configuracao." -ForegroundColor DarkGray
    return
}

foreach ($install in $installs) {
    $state = Get-InjectionState $install.Resources
    Write-Host "  $($install.Flavour): $state" -ForegroundColor White

    if ($state -eq 'OutroMod') {
        Write-Warn 'Este Discord ja tem Equicord ou Vencord injetado.'
        Write-Host '      O standalone ocupa o mesmo lugar, entao instalar aqui desliga o outro mod.' -ForegroundColor DarkGray
        Write-Host '      Se voce usa Equicord ou Vencord, prefira o plugin: ele convive com o resto.' -ForegroundColor DarkGray
        if (-not (Confirm-Action "Substituir o mod em $($install.Flavour) pelo standalone?")) {
            Write-Warn "$($install.Flavour) ficou como estava."
            continue
        }
    }

    Install-Patcher
    Stop-Discord

    if ($state -eq 'OutroMod') { Remove-Injection $install.Resources | Out-Null }
    if ((Get-InjectionState $install.Resources) -eq 'Nosso') {
        Write-Ok "$($install.Flavour) ja estava injetado, so atualizei o bypass."
        continue
    }

    Install-Injection $install.Resources
    Write-Ok "$($install.Flavour) pronto."
}

Write-Host ''
Write-Host '  Abra o Discord. O Go Live deve voltar sozinho.' -ForegroundColor Green
Write-Host "  Se algo der errado, o registro fica em $(Join-Path $InstallDir 'discordcameralive.log')" -ForegroundColor DarkGray
Write-Host '  Para desfazer: .\DiscordCameraLive-Standalone.ps1 -Mode Uninstall' -ForegroundColor DarkGray
Write-Host ''

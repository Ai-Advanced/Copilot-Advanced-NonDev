#Requires -Version 7.2
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$SitePath,
    [Parameter(Mandatory)][string]$ConfigPath,
    [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json -AsHashtable
foreach ($key in @('subscriptionId', 'tenantId', 'resourceGroup', 'prefix', 'appName')) {
    if (-not $config.ContainsKey($key) -or $config[$key] -isnot [string] -or [string]::IsNullOrWhiteSpace($config[$key])) {
        throw "Missing or invalid configuration field: $key"
    }
}
foreach ($key in @('subscriptionId', 'tenantId')) {
    $id = [guid]::Empty
    if (-not [guid]::TryParse($config[$key], [ref]$id) -or $id -eq [guid]::Empty) {
        throw "Replace $key with your instructor-approved identifier."
    }
}
if ($config.prefix -cnotmatch '^[a-z][a-z0-9]{2,15}$' -or
    $config.resourceGroup -cne "rg-copilot-$($config.prefix)" -or
    $config.appName -cne "$($config.prefix)-web") {
    throw 'Use the exact learner resource group and <prefix>-web app assigned by your instructor.'
}
$root = Get-Item -LiteralPath $SitePath
if (-not $root.PSIsContainer -or ($root.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw 'SitePath must be a real directory, not a file or symbolic link.'
}
if (-not (Test-Path -LiteralPath (Join-Path $root.FullName 'index.html') -PathType Leaf)) {
    throw 'The deployment folder must contain index.html.'
}
$allowed = @('.html', '.css', '.js', '.json', '.svg', '.png', '.jpg', '.jpeg', '.webp', '.ico', '.txt', '.woff', '.woff2')
$items = @(Get-ChildItem -LiteralPath $root.FullName -Recurse -Force)
foreach ($item in $items) {
    if ($item.Name.StartsWith('.') -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Hidden files/directories and symbolic links are not deployable: $($item.Name)"
    }
    if (-not $item.PSIsContainer -and $item.Extension.ToLowerInvariant() -notin $allowed) {
        throw "Not a static web asset: $($item.Name). Deploy only the dedicated site folder."
    }
    if (-not $item.PSIsContainer -and $item.Extension -in @('.html', '.css', '.js', '.json', '.svg', '.txt')) {
        $content = Get-Content -LiteralPath $item.FullName -Raw
        if ($content -match '-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}') {
            throw "Possible credential in $($item.Name). Remove it and rotate it before continuing."
        }
    }
}
$files = @($items | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
    [IO.Path]::GetRelativePath($root.FullName, $_.FullName)
})
if (-not $Apply) {
    [pscustomobject]@{
        Mode = 'Offline plan only; no Azure requests'
        App = $config.appName
        ResourceGroup = $config.resourceGroup
        Files = $files
    }
    return
}

function Invoke-Az {
    param([string[]]$Arguments)
    $result = & az @Arguments --only-show-errors
    if ($LASTEXITCODE -ne 0) { throw "Azure CLI failed: $($Arguments[0..1] -join ' ')" }
    return $result
}

Get-Command swa -ErrorAction Stop | Out-Null
$account = (Invoke-Az @('account', 'show', '--subscription', $config.subscriptionId, '-o', 'json')) | ConvertFrom-Json
if ($account.tenantId -ne $config.tenantId -or $account.id -ne $config.subscriptionId) {
    throw 'Azure tenant/subscription does not match the approved configuration.'
}
$group = (Invoke-Az @('group', 'show', '-n', $config.resourceGroup, '--subscription', $config.subscriptionId, '-o', 'json')) | ConvertFrom-Json -AsHashtable
if (-not $group.ContainsKey('tags') -or $group.tags.purpose -ne 'copilot-training' -or $group.tags.learner -ne $config.prefix) {
    throw 'The resource group must have matching purpose=copilot-training and learner tags.'
}
$targetArgs = @('--name', $config.appName, '--resource-group', $config.resourceGroup, '--subscription', $config.subscriptionId)
$app = (Invoke-Az (@('staticwebapp', 'show') + $targetArgs + @('-o', 'json'))) | ConvertFrom-Json
if ($app.sku.name -ne 'Free') { throw 'This basic lab supports only an existing Free Static Web App.' }
Write-Output "Files approved for upload: $($files -join ', ')"
if ($PSCmdlet.ShouldProcess($app.id, 'Publish the reviewed static files to the training URL')) {
    $previousToken = $env:SWA_CLI_DEPLOYMENT_TOKEN
    try {
        $token = Invoke-Az (@('staticwebapp', 'secrets', 'list') + $targetArgs + @('--query', 'properties.apiKey', '-o', 'tsv'))
        if ([string]::IsNullOrWhiteSpace(($token -join ''))) { throw 'Azure returned no deployment token.' }
        $env:SWA_CLI_DEPLOYMENT_TOKEN = ($token -join '').Trim()
        & swa deploy $root.FullName --env production --no-use-keychain
        if ($LASTEXITCODE -ne 0) { throw 'Static Web Apps deployment failed. Inspect the error before retrying.' }
        Write-Output "Open and verify the deployed application: https://$($app.defaultHostname)"
    } finally {
        $env:SWA_CLI_DEPLOYMENT_TOKEN = $previousToken
        $token = $null
    }
}

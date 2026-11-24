[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$')]
  [string]$GitHubUser,

  [ValidatePattern('^(?:|[A-Za-z0-9][A-Za-z0-9._-]{0,99})$')]
  [string]$PagesRepo = "",

  [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._/-]{0,127}$')]
  [string]$DeployBranch = "main",

  [ValidatePattern("^(?:|(?:https://[A-Za-z0-9._-]+(?::\d+)?/[A-Za-z0-9._~:/?#\[\]@!$&'()*+,;=-]+|git@[A-Za-z0-9._-]+:[A-Za-z0-9._/-]+(?:\.git)?))$")]
  [string]$SourceRepoUrl = "",

  [switch]$SkipInstall,
  [switch]$SkipCommit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-Checked {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [string[]]$Arguments = @()
  )
  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "命令执行失败（退出码 $LASTEXITCODE）：$FilePath $($Arguments -join ' ')"
  }
}

function Invoke-Probe {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [string[]]$Arguments = @()
  )
  $prevPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = "Continue"
    & $FilePath @Arguments *> $null
    return $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $prevPreference
  }
}

function Write-Utf8NoBom {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$Content
  )
  [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

if (-not $PagesRepo) {
  $PagesRepo = "$GitHubUser.github.io"
}
if ($PagesRepo.Contains("..")) {
  throw "PagesRepo 不能包含连续点号（..）：$PagesRepo"
}
if ($DeployBranch.Contains("..") -or $DeployBranch.EndsWith("/") -or $DeployBranch.EndsWith(".lock")) {
  throw "DeployBranch 格式不合法：$DeployBranch"
}

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

function Require-Command([string]$Name, [string]$Hint) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw $Hint
  }
}

Require-Command -Name "node" -Hint "未检测到 node，请先安装 Node.js LTS。"
Require-Command -Name "npm" -Hint "未检测到 npm，请先安装 Node.js（含 npm）。"
Require-Command -Name "git" -Hint "未检测到 git，请先安装 Git。"

$isUserSite = $PagesRepo.Equals("$GitHubUser.github.io", [System.StringComparison]::OrdinalIgnoreCase)
$siteUrl = if ($isUserSite) { "https://$GitHubUser.github.io" } else { "https://$GitHubUser.github.io/$PagesRepo" }
$siteRoot = if ($isUserSite) { "/" } else { "/$PagesRepo/" }
$deployRepo = "https://github.com/$GitHubUser/$PagesRepo.git"

$configPath = Join-Path $projectRoot "_config.yml"
$configContent = [System.IO.File]::ReadAllText($configPath, [System.Text.UTF8Encoding]::new($false))
$configContent = $configContent.Replace("<你的GitHub用户名>", $GitHubUser)

$configContent = [regex]::Replace(
  $configContent,
  '(?m)^url:.*?(?=\r?$)',
  [System.Text.RegularExpressions.MatchEvaluator]{ param($m) "url: `"$siteUrl`"" }
)
$configContent = [regex]::Replace(
  $configContent,
  '(?m)^root:.*?(?=\r?$)',
  [System.Text.RegularExpressions.MatchEvaluator]{ param($m) "root: $siteRoot" }
)
$deployBlockPattern = '(?m)^deploy:(?:\r?\n(?:[ \t]+.*)?)*'
$deployEvaluator = [System.Text.RegularExpressions.MatchEvaluator]{
  param($m)
  $block = $m.Value
  $block = [regex]::Replace(
    $block,
    '(?m)^([ \t]+)repo:.*?(?=\r?$)',
    [System.Text.RegularExpressions.MatchEvaluator]{ param($im) "$($im.Groups[1].Value)repo: `"$deployRepo`"" }
  )
  $block = [regex]::Replace(
    $block,
    '(?m)^([ \t]+)branch:.*?(?=\r?$)',
    [System.Text.RegularExpressions.MatchEvaluator]{ param($im) "$($im.Groups[1].Value)branch: $DeployBranch" }
  )
  return $block
}
$configContent = [regex]::Replace($configContent, $deployBlockPattern, $deployEvaluator)
Write-Utf8NoBom -Path $configPath -Content $configContent

$nextConfigPath = Join-Path $projectRoot "_config.next.yml"
if (Test-Path -LiteralPath $nextConfigPath) {
  $nextContent = [System.IO.File]::ReadAllText($nextConfigPath, [System.Text.UTF8Encoding]::new($false))
  $nextContent = $nextContent.Replace("https://<你的GitHub用户名>.github.io", $siteUrl)
  $nextContent = $nextContent.Replace("<你的GitHub用户名>", $GitHubUser)
  Write-Utf8NoBom -Path $nextConfigPath -Content $nextContent
}

$aboutPath = Join-Path $projectRoot "source/about/index.md"
if (Test-Path -LiteralPath $aboutPath) {
  $aboutContent = [System.IO.File]::ReadAllText($aboutPath, [System.Text.UTF8Encoding]::new($false))
  $aboutContent = $aboutContent.Replace("<你的GitHub用户名>", $GitHubUser)
  Write-Utf8NoBom -Path $aboutPath -Content $aboutContent
}

$gitignorePath = Join-Path $projectRoot ".gitignore"
if (-not (Test-Path -LiteralPath $gitignorePath)) {
  $gitignoreText = @(
    "node_modules/"
    "public/"
    ".deploy_git/"
    "db.json"
    ".env*"
    "*.key"
    "*.pem"
    "*.log"
    ".DS_Store"
    "Thumbs.db"
  ) -join "`n"
  Write-Utf8NoBom -Path $gitignorePath -Content ($gitignoreText + "`n")
}

$gitDir = Join-Path $projectRoot ".git"
if (-not (Test-Path -LiteralPath $gitDir)) {
  Write-Host "[1/5] 初始化 Git 仓库"
  Invoke-Checked -FilePath "git" -Arguments @("init") | Out-Null
  Invoke-Checked -FilePath "git" -Arguments @("symbolic-ref", "HEAD", "refs/heads/main")
}

if ($SourceRepoUrl) {
  $remoteCode = Invoke-Probe -FilePath "git" -Arguments @("remote", "get-url", "origin")
  if ($remoteCode -ne 0) {
    Invoke-Checked -FilePath "git" -Arguments @("remote", "add", "--", "origin", $SourceRepoUrl)
  }
}

if (-not $SkipInstall) {
  Write-Host "[2/5] 安装依赖"
  Invoke-Checked -FilePath "npm" -Arguments @("install")
}

if (-not $SkipCommit) {
  Write-Host "[3/5] 写入初始提交"
  Invoke-Checked -FilePath "git" -Arguments @("add", "--", ".")
  $headCode = Invoke-Probe -FilePath "git" -Arguments @("rev-parse", "--verify", "HEAD")
  if ($headCode -ne 0) {
    $commitCode = Invoke-Probe -FilePath "git" -Arguments @("commit", "-m", "chore: initialize hexo blog")
    if ($commitCode -ne 0) {
      Write-Host "提交失败（通常是未设置 git user.name / user.email），继续执行部署。"
    }
  } else {
    Write-Host "已有提交，跳过初始提交。"
  }
}

Write-Host "[4/5] 生成静态文件"
Invoke-Checked -FilePath "npm" -Arguments @("run", "clean")
Invoke-Checked -FilePath "npm" -Arguments @("run", "build")

Write-Host "[5/5] 首次发布到 GitHub Pages"
Invoke-Checked -FilePath "npm" -Arguments @("run", "deploy")

Write-Host "完成。"
Write-Host "部署仓库: $deployRepo"
Write-Host "分支: $DeployBranch"
Write-Host "页面地址: $siteUrl/"

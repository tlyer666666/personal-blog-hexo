[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$')]
  [string]$GitHubUser,

  [ValidatePattern('^(?:|[A-Za-z0-9][A-Za-z0-9._-]{0,99})$')]
  [string]$PagesRepo = "",

  [switch]$Private
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

if (-not $PagesRepo) {
  $PagesRepo = "$GitHubUser.github.io"
}
if ($PagesRepo.Contains("..")) {
  throw "PagesRepo 不能包含连续点号（..）：$PagesRepo"
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  throw "未检测到 gh CLI，请先安装并登录 GitHub CLI。"
}

Write-Host "[1/3] 检查 GitHub CLI 登录状态..."
Invoke-Checked -FilePath "gh" -Arguments @("auth", "status") | Out-Null

$repoFullName = "$GitHubUser/$PagesRepo"
Write-Host "[2/3] 检查仓库是否已存在: $repoFullName"
$viewCode = Invoke-Probe -FilePath "gh" -Arguments @("repo", "view", "--", $repoFullName)

if ($viewCode -eq 0) {
  Write-Host "仓库已存在，无需创建。"
  exit 0
}

$visibility = if ($Private) { "--private" } else { "--public" }
Write-Host "[3/3] 创建仓库: $repoFullName"
Invoke-Checked -FilePath "gh" -Arguments @("repo", "create", $visibility, "--", $repoFullName)

Write-Host "已创建: https://github.com/$repoFullName"

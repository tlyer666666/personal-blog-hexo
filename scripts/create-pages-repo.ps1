[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$GitHubUser,
  [string]$PagesRepo,
  [switch]$Private
)

$ErrorActionPreference = "Stop"

if (-not $PagesRepo) {
  $PagesRepo = "$GitHubUser.github.io"
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  throw "未检测到 gh CLI，请先安装并登录 GitHub CLI。"
}

Write-Host "[1/3] 检查 GitHub CLI 登录状态..."
& gh auth status | Out-Null

$repoFullName = "$GitHubUser/$PagesRepo"
Write-Host "[2/3] 检查仓库是否已存在: $repoFullName"
& gh repo view $repoFullName *> $null

if ($LASTEXITCODE -eq 0) {
  Write-Host "仓库已存在，无需创建。"
  exit 0
}

$visibility = if ($Private) { "--private" } else { "--public" }
Write-Host "[3/3] 创建仓库: $repoFullName"
& gh repo create $repoFullName $visibility --confirm

Write-Host "已创建: https://github.com/$repoFullName"

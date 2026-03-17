[CmdletBinding()]
param(
  [string]$GitHubUser = "542869246",
  [string]$PagesRepo,
  [string]$DeployBranch = "main",
  [string]$SourceRepoUrl = "",
  [switch]$SkipInstall,
  [switch]$SkipCommit
)

$ErrorActionPreference = "Stop"

if (-not $PagesRepo) {
  $PagesRepo = "$GitHubUser.github.io"
}

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

function Require-Command([string]$Name, [string]$Hint) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw $Hint
  }
}

Require-Command -Name "node" -Hint "未检测到 node，请先安装 Node.js LTS。"
Require-Command -Name "npm" -Hint "未检测到 npm，请先安装 Node.js（含 npm）。"
Require-Command -Name "git" -Hint "未检测到 git，请先安装 Git。"

$configPath = Join-Path $projectRoot "_config.yml"
$configContent = Get-Content -Raw -Encoding UTF8 $configPath
$deployRepo = "https://github.com/$GitHubUser/$PagesRepo.git"

$configContent = [regex]::Replace($configContent, "(?m)^  repo:.*$", "  repo: $deployRepo")
$configContent = [regex]::Replace($configContent, "(?m)^  branch:.*$", "  branch: $DeployBranch")
Set-Content -Encoding UTF8 $configPath $configContent

$gitignorePath = Join-Path $projectRoot ".gitignore"
if (-not (Test-Path $gitignorePath)) {
@"
node_modules/
public/
.deploy_git/
db.json
.DS_Store
Thumbs.db
"@ | Set-Content -Encoding UTF8 $gitignorePath
}

if (-not (Test-Path (Join-Path $projectRoot ".git"))) {
  Write-Host "[1/5] 初始化 Git 仓库"
  & git init | Out-Null
}

& git symbolic-ref HEAD "refs/heads/main" *> $null

if ($SourceRepoUrl) {
  & git remote get-url origin *> $null
  if ($LASTEXITCODE -ne 0) {
    & git remote add origin $SourceRepoUrl
  }
}

if (-not $SkipInstall) {
  Write-Host "[2/5] 安装依赖"
  & npm install
}

if (-not $SkipCommit) {
  Write-Host "[3/5] 写入初始提交"
  & git add .
  & git rev-parse --verify HEAD *> $null
  if ($LASTEXITCODE -ne 0) {
    & git commit -m "chore: initialize hexo blog"
    if ($LASTEXITCODE -ne 0) {
      Write-Host "提交失败（通常是未设置 git user.name / user.email），继续执行部署。"
    }
  } else {
    Write-Host "已有提交，跳过初始提交。"
  }
}

Write-Host "[4/5] 生成静态文件"
& npm run clean
& npm run build

Write-Host "[5/5] 首次发布到 GitHub Pages"
& npm run deploy

Write-Host "完成。"
Write-Host "部署仓库: $deployRepo"
Write-Host "分支: $DeployBranch"
Write-Host "页面地址: https://$GitHubUser.github.io/"

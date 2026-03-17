$ErrorActionPreference = "Stop"

Write-Host "[1/4] 检查 Node.js"
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  throw "未检测到 node，请先安装 Node.js LTS。"
}

Write-Host "[2/4] 检查 npm"
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
  throw "未检测到 npm，请先安装 Node.js（含 npm）。"
}

Write-Host "[3/4] 检查 Git"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw "未检测到 git，请先安装 Git。"
}

Write-Host "[4/4] 安装依赖并启动"
npm install
npm run server

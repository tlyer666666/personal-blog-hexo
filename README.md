# Hexo + NexT Blog

## Before You Start

请先安装：

- Node.js LTS（含 npm）
- Git

可选：

- GitHub CLI (`gh`) 用于自动创建仓库

## A. 自动创建 GitHub Pages 仓库（可选）

```powershell
cd E:\codex\personal-blog-hexo
powershell -ExecutionPolicy Bypass -File .\scripts\create-pages-repo.ps1 -GitHubUser 542869246
```

默认创建：`542869246/542869246.github.io`

## B. 初始化并首次发布（一键）

```powershell
cd E:\codex\personal-blog-hexo
powershell -ExecutionPolicy Bypass -File .\scripts\first-publish.ps1 -GitHubUser 542869246
```

常用参数：

- `-PagesRepo your-pages-repo`
- `-DeployBranch main`
- `-SourceRepoUrl https://github.com/<you>/<source-repo>.git`
- `-SkipInstall`（调试时跳过 npm install）
- `-SkipCommit`（跳过初始提交）

## C. 手动开发命令

```powershell
npm install
npm run server
npm run build
npm run deploy
```

## Theme Notes

主题配置在 `_config.next.yml`，已启用：

- 暗色模式
- 本地搜索
- 代码块复制按钮

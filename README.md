# Hexo + NexT 博客工程

基于 Hexo 7 与 NexT 8 的博客脚手架，附带建仓与首次发布脚本。

仓库里的站点信息都是占位符，使用前先改成自己的账号。

## 环境要求

- Node.js LTS（含 npm）
- Git
- 可选：GitHub CLI（`gh`），只有用脚本自动建仓时才需要

## 1. 改配置

`_config.yml`：

- `url`：`https://<你的GitHub用户名>.github.io`
- `deploy.repo`：`https://github.com/<你的GitHub用户名>/<你的GitHub用户名>.github.io.git`

`_config.next.yml` 里的 `social` 链接同理。

## 2. 本地预览

在仓库根目录（`<仓库克隆路径>`）执行：

```powershell
npm install
npm run server
```

默认地址 http://localhost:4000。

## 3. 生成与部署

```powershell
npm run build
npm run deploy
```

## 一键脚本（可选，Windows PowerShell）

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\first-publish.ps1 -GitHubUser <你的GitHub用户名>
```

脚本会检查 node / npm / git，安装依赖、生成静态文件并部署到 GitHub Pages。它还会按传入的用户名改写 `_config.yml` 里的 `deploy.repo` 与 `deploy.branch`，运行后留意这两处改动。

自动创建 `<你的GitHub用户名>.github.io` 仓库（需要 `gh` 已登录）：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\create-pages-repo.ps1 -GitHubUser <你的GitHub用户名>
```

两个脚本的 `-GitHubUser` 都必须显式传入，没有默认值。其它参数：`-PagesRepo`（默认 `<用户名>.github.io`）、`-DeployBranch`（默认 `main`）、`-SourceRepoUrl`、`-SkipInstall`、`-SkipCommit`。

`setup.ps1` 只做环境检查并启动本地预览，等价于 `npm install` 加 `npm run server`。

## 主题

主题配置在 `_config.next.yml`，已启用暗色模式、本地搜索和代码块复制按钮。

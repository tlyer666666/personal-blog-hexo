---
title: 从 Hexo + NexT 开始搭建个人博客
date: 2026-03-17 10:20:00
tags:
  - Hexo
  - NexT
  - Blog
categories:
  - 建站
---

这篇文章记录博客初始化和主题配置的最短路径。

## 1. 初始化

```bash
npm install
npm run server
```

## 2. 开启代码复制

在 `_config.next.yml` 中启用：

```yml
codeblock:
  copy_button:
    enable: true
    show_result: true
```

## 3. 部署

```bash
npm run build
npm run deploy
```

如果你的 GitHub Pages 仓库是 `username.github.io`，把 `_config.yml` 里的 `deploy.repo` 改成对应仓库地址即可。

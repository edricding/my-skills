# my-skills

这个仓库用于存放本地 skills（当前主要分布在 `.claude/skills` 和 `.codex`）。

另外，根目录当前维护 `dzh-skills-autogitcommit` 作为源版本（agent-neutral），
会同步到 Claude/Codex 两端对应目录。

## 当前 Skills（去重后）

以下按技能名去重整理，`来源` 表示该 skill 存在于哪个目录。

| Skill | 作用摘要 | 来源 |
|---|---|---|
| `baoyu-article-illustrator` | 文章配图辅助：分析文章结构，识别插图位置，并按 Type × Style 生成配图方案 | `.claude` / `.codex` |
| `baoyu-comic` | 知识漫画生成：支持多种画风、语气、分镜布局，适合教育/传记/教程类漫画 | `.claude` / `.codex` |
| `baoyu-compress-image` | 图片压缩与格式转换（默认 WebP），自动选择可用工具链以降低体积 | `.claude` / `.codex` |
| `baoyu-cover-image` | 文章封面图生成：基于 type/palette/rendering/text/mood 多维参数组合生成封面 | `.claude` / `.codex` |
| `baoyu-infographic` | 信息图生成：按 layout × style 组合生成可发布的信息图/视觉摘要 | `.claude` / `.codex` |
| `baoyu-slide-deck` | 幻灯片图片化生成：从内容生成大纲与单页 slide 图像，并可合并为 PPT/PDF | `.claude` / `.codex` |
| `dzh-skills-autogitcommit` | GitHub 改动总结与 commit title/body 生成（含长度校验与 `.gitignore` 过滤） | 根目录（源） / `.claude` / `.codex` |
| `docx` | 处理 Word 文档（创建、读取、编辑、内容提取、格式化等） | `.claude` / `.codex` |
| `frontend-design` | 高质量前端界面设计与实现，强调审美方向和非模板化 UI | `.claude` / `.codex` |
| `pdf` | PDF 读取、提取、合并、拆分、OCR、表单处理等 | `.claude` / `.codex` |
| `planning-with-files` | 文件驱动的任务规划流程（如 `task_plan.md`、`progress.md`） | `.claude` / `.codex` |
| `pptx` | PPT/演示文稿的创建、读取、编辑、拆分合并、模板处理等 | `.claude` / `.codex` |
| `seo-audit` | 网站 SEO 审计与诊断（技术 SEO、页面优化、内容质量与优先级整改建议） | `.claude` / `.codex` |
| `skill-creator` | 创建或更新 skill 的方法论与规范指南 | `.claude` / `.codex` |
| `ui-ux-pro-max` | UI/UX 设计知识库与规则集（风格、配色、字体、可访问性等） | `.codex` |
| `xlsx` | Excel/表格文件处理（`.xlsx`/`.xlsm`/`.csv`/`.tsv`）与格式规范 | `.claude` / `.codex` |

## 目录说明

- `dzh-skills-autogitcommit/`（根目录）: 自动生成 GitHub-ready commit 文案的源版本
- `.claude/skills/`: 面向 Claude 的 skills 目录（每个 skill 在独立子目录中）
- `.codex/`: 面向 Codex 的 skills 目录（多数 skill 与 `.claude/skills` 同名/同用途）

## dzh-skills-autogitcommit 同步说明

- 根目录源版本：`dzh-skills-autogitcommit/`
- Claude 版本目录：`.claude/skills/dzh-skills-autogitcommit/`
- Codex 版本目录：`.codex/dzh-skills-autogitcommit/`
- 推荐维护方式：优先修改根目录源版本，再同步到两端目录

## 统计

- 去重后技能数：`16`
- 两端共有（同名）技能数：`15`
- 仅 `.codex` 独有：`ui-ux-pro-max`
- 根目录源 skill 数：`1`（`dzh-skills-autogitcommit`）

# 📁 EndlessRegret 项目管理文件索引

> 整理日期：2026-08-16 | 适用仓库版本：`main @ a142c38`（2026-10-10 更新）
> ⏸ **项目状态：暂时搁置**（2026-10-10 用户决定）——本索引与全部文档保留原样，恢复时按此索引定位。详见 `docs/devlog/2026-10-10.md`。
> 本文件列出项目中与项目管理相关的全部文件及其作用，方便快速定位。

## 一、核心管理文档（`docs/`，已纳入 Git 版本控制）

| 路径 | 作用 |
|------|------|
| `docs/GDD.md` | **游戏设计文档** — 项目的"宪法"：游戏概述、核心主题、移动/战斗系统设计、美术风格、技术架构、发布计划、待决策清单。玩法定稿与架构原则都在这里。 |
| `docs/ROADMAP.md` | **开发路线图** — 里程碑（M0~M5）总览、每个里程碑的任务清单与完成标准、当前优先级排序（P0~P3）、决策记录。是"现在该做什么"的权威依据。 |
| `docs/devlog/2026-08-16.md` | **开发日志（首篇）** — 按日期记录每次开发会话：做了什么、决策与理由、踩坑、下一步。含日志规范说明。 |
| `docs/devlog/TEMPLATE.md` | **开发日志模板** — 每日收尾生成日志的骨架与提问清单（见工作流规则 4）。 |
| `docs/DEBUG_NOTES.md` | **调试知识库** — 射线判定等已验证的原理、陷阱与最佳实践（2026-08 挂边调试沉淀）。 |
| `docs/story/` | **剧情产出目录** — 剧情 Agent 负责：世界观 / 大纲 / 角色 / 场景脚本。`_inbox/` 存用户原始构思存档（未定稿、非 canon）。详见 `ref_books/README.md` 的转换链路。 |
| `docs/devlog/` | **开发日志目录** — 命名规则 `YYYY-MM-DD.md`（同一天多篇加 `-b`/`-c` 后缀）。 |

## 一之二、剧情素材入口（项目根 `EndlessRegret/ref_books/`）

| 路径 | 作用 |
|------|------|
| `ref_books/` | **剧情 Agent 的书籍素材入口**（非产出目录）— 上传书籍 → `book-to-skill` 转 `.dsh/skills/story-library/` → 供剧情会话按需加载。**第三方版权书籍不入 Git**（`.gitignore` 仅保留 README.md/.gitignore）。 |

## 一之三、本机私有工作区（项目根 `.dsh/`，整体已 gitignore，**不入 Git**）

> 属"游戏本身之外"的工具 / 资料资产，随项目搁置**保留原样**。`.dsh/` 已在根级 `.gitignore` 中忽略，本节登记仅为**可检索性与可恢复性**，不代表纳入版本控制。

| 路径 | 作用 |
|------|------|
| `.dsh/knowledge/` | **本机私有知识库根目录** — 存放供 AI 会话检索的离线资料库（不入 Git） |
| `.dsh/knowledge/godot-docs/` | **Godot 官方开发文档全库** — 来源 `godotengine/godot-docs`，分支 **`4.7`**（对齐 `Game_Build/project.godot:15` 的引擎版本），commit **`9adca4c1c72917bfe1b7be3108abed5ce26696a6`**；**1479 个 `.rst`**（classes 1079 + tutorials 24 子目录），约 39 MB（正文 ~30.7 MB），MIT 许可（`LICENSE.txt` / `AUTHORS.md` 原样保留）。**检索须显式给 path**：`grep pattern="..." path=".dsh/knowledge/godot-docs/classes"`；更新用 `git -C .dsh/knowledge/godot-docs pull`（sparse 配置已存）。 |
| `.dsh/knowledge/README.md` | **文档库索引** — 库元信息 + 「常见开发问题 → 文档路径」映射 17 条（CharacterBody2D / 物理射线 / TileMapLayer / 动画 / 输入 / 粒子 / 着色器 / 导出 / 性能 / 最佳实践等），含本次迁址记录 |
| `.dsh/team/` | **团队协作信箱** — 值班室简报、各角色 agent 消息与决策队列（`decisions.md`），本机私有 |

## 二、仓库级管理配置（项目根 `EndlessRegret/`）

| 路径 | 作用 |
|------|------|
| `.gitignore` | 根级 Git 忽略规则（OS 文件、IDE 配置等） |
| `.gitattributes` | Git 属性：统一换行符（`text=auto eol=lf`），保证跨平台行尾一致 |
| `.editorconfig` | 编辑器统一编码（UTF-8），任何编辑器打开项目都遵循同一规范 |
| `PROJECT_INDEX.md` | 本文件 — 项目管理相关文件的索引清单 |

## 三、工程内配置（`Game_Build/`）

| 路径 | 作用 |
|------|------|
| `Game_Build/project.godot` | **引擎项目配置** — 项目名、主场景、autoload（DebugManager）、输入映射（move_left/right、jump 等）、渲染/物理设置。属于"工程层面的管理信息"。 |
| `Game_Build/README.md` | 项目说明（运行方式、简介）。 |
| `Game_Build/.gitignore` | 子目录 Git 忽略：Godot 的 `.godot/` 缓存、导入产物等 |
| `Game_Build/export_presets.cfg` | 导出预设（打包 Steam 版时的目标平台配置） |

## 四、目录结构速览

```
EndlessRegret/                  # 项目根（Git 仓库根）
├── .editorconfig               # 编辑器规范
├── .gitattributes              # Git 换行规范
├── .gitignore                  # Git 忽略规则（根级；含 .dsh/ content/ exports/ 等）
├── PROJECT_INDEX.md            # 本文件：项目管理文件索引
├── .dsh/                       # 本机私有工作区（整体不入 Git）
│   ├── knowledge/              #   离线知识库（godot-docs 官方文档全库 + README 索引）
│   └── team/                   #   团队通讯信箱与决策队列（值班室 / 各角色 agent）
├── docs/                       # 文档中心
│   ├── GDD.md                  # 游戏设计文档
│   ├── ROADMAP.md              # 开发路线图（含 Bug 跟踪表）
│   ├── DEBUG_NOTES.md          # 调试知识库
│   ├── story/                  # 剧情产出（剧情 Agent 负责，_inbox/ 存用户原始构思）
│   └── devlog/                 # 开发日志
│       ├── TEMPLATE.md         # 日志模板（每日收尾用）
│       └── YYYY-MM-DD(-x).md   # 日志正文（如 2026-08-16.md / 2026-08-17-b.md）
├── ref_books/                  # 剧情书籍素材入口（第三方版权书籍不入 Git）
├── Game_Build/                 # Godot 工程
│   ├── .gitignore              # Git 忽略规则（工程级）
│   ├── README.md               # 项目说明
│   ├── project.godot           # 引擎配置
│   ├── export_presets.cfg      # 导出预设
│   ├── playground.tscn         # 测试主场景
│   ├── addons/                 # 插件（debug_system）
│   ├── assets/                 # 游戏资源
│   ├── tools/                  # 回归测试套件（headless：dump_tiles / test_b1 / test_b2 / test_head / test_climb）
│   ├── player/                 # 玩家代码（scripts / states）
└── Source_Files/               # 美术源文件（Aseprite）
```

## 五、文档协作工作流（当前约定）

1. **决策** → 先写进 `docs/devlog/当天日期.md`，再同步到 ROADMAP / GDD
2. **开发前** → 看 `ROADMAP.md` 优先级表（P0~P3）
3. **设计疑问** → 查 `GDD.md` 待决策清单
4. **每日收尾** → 你说 **"今天任务已结束"** 时，AI 读取 `docs/devlog/TEMPLATE.md`，引导你补充缺失字段；无补充则直接按模板生成当日日志（`YYYY-MM-DD.md`，同日多篇加后缀）
5. **路径/结构变更** → 任何文件路径修改、目录调整、文件增删、仓库结构变化，**必须同步更新本文件（PROJECT_INDEX.md）**，保持索引与实际结构一致
6. **周期性任务** → ROADMAP 章节 R（当前：R1 每周开发日志自媒体视频，素材取自 `docs/devlog/`）
7. **开发工具更新归档** → 涉及**软件、引擎、宿主或电脑等游戏本身之外**的改动（DSH 插件 / agent / skill、团队协作机制、工具链与脚本、录屏与素材采集工具、引擎与编辑器版本配置、本机环境依赖等），统一记入当日 devlog 的独立小节 **「开发工具更新（游戏本身之外）」**，与游戏开发内容分离（标准见 `docs/devlog/TEMPLATE.md`；用户 2026-09-21 指令）

## 六、更新记录

- 2026-08-16：创建本文件（索引首版）
- 2026-08-17：新增工作流规则 5（路径变更同步更新）、规则 6（周期性任务 R1）；GDD 结构树同步登记本文件；新增规则 4"每日收尾"（TEMPLATE.md 流程）、devlog 模板入索引
- 2026-08-19：登记 `docs/DEBUG_NOTES.md`（调试知识库）；ROADMAP 新增 Bug 跟踪表
- 2026-08-21：登记 `Game_Build/tools/`（回归测试套件）；GDD 结构树修正 dev_tools/ → tools/（dev_tools 目录实际不存在，属文档过时条目）；适用仓库版本更新至 2c24849
- 2026-08-21：登记剧情 Agent 新增目录 `docs/story/`（剧情产出，_inbox/ 存用户原始构思）与 `ref_books/`（书籍素材入口，第三方版权书不入 Git）；GDD 核心主题标注 `[待定]`（赎罪之路 vs 赋予意义 并存为暂定假设）
- 2026-09-21：新增工作流规则 7（开发工具更新归档，devlog 独立小节）；剧情线状态更正为「暂缓，等书库建成」（用户澄清 v0 大纲仅早期草稿）；游戏定位变更像素 ARPG
- 2026-10-10：**项目状态变更为「暂时搁置」**（用户决定，见 devlog 2026-10-10），头部加搁置标注；新增「一之三、本机私有工作区（`.dsh/`，不入 Git）」章节，登记 `.dsh/knowledge/`（**Godot 官方文档全库新落点**，分支 4.7 / commit 9adca4c / 1479 个 `.rst`）与 `.dsh/knowledge/README.md`、`.dsh/team/`；目录树补 `.dsh/` 子树；适用仓库版本更新至 `a142c38`

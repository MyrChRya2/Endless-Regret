# 📁 EndlessRegret 项目管理文件索引

> 整理日期：2026-08-16 | 适用仓库版本：`main @ 7c63d4c`
> 本文件列出项目中与项目管理相关的全部文件及其作用，方便快速定位。

## 一、核心管理文档（`docs/`，已纳入 Git 版本控制）

| 路径 | 作用 |
|------|------|
| `docs/GDD.md` | **游戏设计文档** — 项目的"宪法"：游戏概述、核心主题、移动/战斗系统设计、美术风格、技术架构、发布计划、待决策清单。玩法定稿与架构原则都在这里。 |
| `docs/ROADMAP.md` | **开发路线图** — 里程碑（M0~M5）总览、每个里程碑的任务清单与完成标准、当前优先级排序（P0~P3）、决策记录。是"现在该做什么"的权威依据。 |
| `docs/devlog/2026-08-16.md` | **开发日志（首篇）** — 按日期记录每次开发会话：做了什么、决策与理由、踩坑、下一步。含日志规范说明。 |
| `docs/devlog/TEMPLATE.md` | **开发日志模板** — 每日收尾生成日志的骨架与提问清单（见工作流规则 4）。 |
| `docs/devlog/` | **开发日志目录** — 命名规则 `YYYY-MM-DD.md`（同一天多篇加 `-b`/`-c` 后缀）。 |

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
├── .gitignore                  # Git 忽略规则（根级）
├── PROJECT_INDEX.md            # 本文件：项目管理文件索引
├── docs/                       # 文档中心
│   ├── GDD.md                  # 游戏设计文档
│   ├── ROADMAP.md              # 开发路线图
│   └── devlog/                 # 开发日志
│       ├── TEMPLATE.md         # 日志模板（每日收尾用）
│       └── YYYY-MM-DD(-x).md   # 日志正文（如 2026-08-16.md / 2026-08-17-b.md）
├── Game_Build/                 # Godot 工程
│   ├── .gitignore              # Git 忽略规则（工程级）
│   ├── README.md               # 项目说明
│   ├── project.godot           # 引擎配置
│   ├── export_presets.cfg      # 导出预设
│   ├── playground.tscn         # 测试主场景
│   ├── addons/                 # 插件（debug_system）
│   ├── assets/                 # 游戏资源
│   └── player/                 # 玩家代码（scripts / states）
└── Source_Files/               # 美术源文件（Aseprite）
```

## 五、文档协作工作流（当前约定）

1. **决策** → 先写进 `docs/devlog/当天日期.md`，再同步到 ROADMAP / GDD
2. **开发前** → 看 `ROADMAP.md` 优先级表（P0~P3）
3. **设计疑问** → 查 `GDD.md` 待决策清单
4. **每日收尾** → 你说 **"今天任务已结束"** 时，AI 读取 `docs/devlog/TEMPLATE.md`，引导你补充缺失字段；无补充则直接按模板生成当日日志（`YYYY-MM-DD.md`，同日多篇加后缀）
5. **路径/结构变更** → 任何文件路径修改、目录调整、文件增删、仓库结构变化，**必须同步更新本文件（PROJECT_INDEX.md）**，保持索引与实际结构一致
6. **周期性任务** → ROADMAP 章节 R（当前：R1 每周开发日志自媒体视频，素材取自 `docs/devlog/`）

## 六、更新记录

- 2026-08-16：创建本文件（索引首版）
- 2026-08-17：新增工作流规则 5（路径变更同步更新）、规则 6（周期性任务 R1）；GDD 结构树同步登记本文件；新增规则 4"每日收尾"（TEMPLATE.md 流程）、devlog 模板入索引

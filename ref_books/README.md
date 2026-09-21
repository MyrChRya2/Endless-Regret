# ref_books — 剧情 Agent 的原始书籍素材

这个目录是**素材入口**，不是产出目录。

把剧情 Agent 需要"读进去"的书籍、资料直接丢在这里（子目录分类也可以），
然后在剧情设计会话里说 **"建库"** / **"这批书转 skill"**，剧情 Agent 会调用
`book-to-skill` 把它们提炼成可检索的剧情资料库 skill。

## 转换链路

```
ref_books/<书>            ← 你上传的原始书（本目录）
        ↓  book-to-skill（技能转换器）
.dsh/skills/story-library/  ← 生成的剧情资料库 skill（按知识点归并，不是按书归并）
        ↓  剧情设计会话按需加载
docs/story/                 ← 剧情产出（世界观 / 大纲 / 角色 / 场景脚本）
```

- 资料库草稿与路径约定见预设自带技能 `story-library-build`。
- **资料库按"叙事的形状"组织**（人物弧光 / 结构模型 / 场景工具 / 对白技法），
  不按"书的形状"组织，否则检索价值归零。

## 支持的格式

`.pdf` `.epub` `.docx` `.txt` `.md` `.markdown` `.rst` `.adoc` `.html` `.htm` `.rtf` `.mobi` `.azw` `.azw3`

- 扫描版 PDF 无文字层时需要先 OCR（`ocrmypdf input.pdf output.pdf`）。
- `.mobi` / `.azw` 需要本机装 Calibre。

## 版权（重要）

**本目录内容不入 Git。** `ref_books/.gitignore` 已忽略除本说明外的全部文件。

原因：EndlessRegret 仓库是公开的 CC0 项目，而这里的书是第三方版权作品。
原始书籍与由它们派生的资料库都只在本机私有使用，不上传、不分发。
（书单里若确有自己撰写或明确可公开分发的内容，单独说明，再决定是否例外。）

## 建议书单（用户此前已列，按需上传）

| 优先级 | 书名 | 作者 | 对项目的用处 |
|---|---|---|---|
| ⭐ | 故事写作大师班（The Anatomy of Story） | John Truby | 道德论证骨架，正对"赎罪"主题 |
| 高 | 作家之旅（The Writer's Journey） | Christopher Vogler | 英雄之旅结构，关卡节奏 |
| 高 | 故事（Story） | Robert McKee | 场景设计与冲突原理 |
| 中 | Video Game Storytelling | Evan Skolnick | 游戏叙事与玩法的结合 |
| 中 | Understanding Comics | Scott McCloud | 无对话系统的画面叙事 |
| 中 | The Art of Game Design | Jesse Schell | 体验视角的设计透镜 |
| 低 | 电影镜头设计 | Steven Katz | 过场/镜头语言 |

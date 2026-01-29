# Jutiku Quiz Expert (AI 出题专家)

**Jutiku Quiz Expert** 是一个强大的 AI 智能出题系统，专注于根据用户提供的文档（PDF, DOCX, PPTX）或指定主题，自动生成高质量、多模态的测试题目。

它不仅支持文本分析，还具备先进的多模态能力，能够识别文档中的几何图形、统计图表，并将其无缝整合到题目生成过程中，支持图文混排和复杂的数学公式（LaTeX）。

## 核心功能

*   **多模态支持**：自动提取和分析文档中的图片资源（如几何题插图），并保留在题目中。
*   **多种出题模式**：
    *   **基于文档 (Document-Based)**：全篇扫描，基于已有材料出题。
    *   **基于主题 (Topic-Based)**：根据关键词调用外部知识库扩展出题。
    *   **混合模式 (Hybrid)**：智能组合文档内容与外部知识。
    *   **多模态模式 (Multimodal)**：专门针对包含视觉信息的材料（如数学几何、生物解剖图）出题。
*   **专业格式输出**：
    *   支持标准的 **JSON** 格式，便于程序处理。
    *   支持优化的 **Markdown** 格式，便于人类阅读和排版。
*   **自动化流程**：自动处理文件解压、图片提取、内容清洗到题目生成的全流程。

## 目录结构说明

本系统在运行时区分 **技能定义** 与 **工作区数据** 两个逻辑空间：

### 1. 技能库 (Skill Library)
包含技能的核心定义与规范文档，通常由系统预置。
*   `Jutiku_Quiz_Expert/SKILL.md`: 核心逻辑定义
*   `Jutiku_Quiz_Expert/references/`: 输出协议规范 (`.md` & `.json` spec)

### 2. Agent 工作区 (Workspace)
任务执行时的动态目录，包含所有输入输出数据：

*   **`./temp/`** (临时区)
    *   存放解压后的原始图片、中间态 Markdown、语义图谱 (`graph.json`)。
    *   *注：任务失败时可安全清理。*

*   **`./assets/`** (资源池)
    *   存放所有提取并清洗后的媒体资源（图片）。
    *   采用 **SHA256 内容寻址** 存储，文件名即哈希值，确保全局唯一且不重复。

*   **`./quiz/`** (交付区)
    *   存放最终生成的题库文件。
    *   输出命名格式：`{YYYY-MM-DD_HHMMSS}.[json|md]`


## 输出规范

本系统支持两种标准的输出格式，详细定义请参考 `references` 目录：

1.  **JSON 数据协议**: [Quiz Data Schema Specification](./references/QUIZ_JSON_SPEC.md)
    *   定义了题目的标准字段：`qid` (题目ID), `type` (题型), `lev` (难度), `point` (知识点), `question` (题干), `options` (选项), `correct_answer` (正确答案), `explanation` (解析) 等。
    
2.  **Markdown 排版规范**: [Quiz Markdown Specification](./references/QUIZ_MARKDOWN_SPEC.md)
    *   定义了易读的题目展示格式，包含 LaTeX 公式渲染规范和图片引用标准。

## 快速开始

1.  准备您的源文档（DOCX, PDF, PPTX 等）或确定出题主题。
2.  调用 AI 出题专家 (Jutiku_Quiz_Expert) Skill。
3.  输入具体指令，例如：
    *   “请根据这份 PDF 生成 10 道单选题，重点考察第三章内容。”
    *   “生成一套关于‘勾股定理’的混合题型试卷，包含几何计算题。”
4.  系统将自动提取内容、分析图片，并在 `./quiz/` 目录下生成包含时间戳的题库文件。

## 许可证

MIT License

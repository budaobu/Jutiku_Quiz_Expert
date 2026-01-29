# Jutiku Quiz Expert (AI 出题专家)

基于 AI 的出题专家系统，可根据文档或主题生成高质量题目。该系统能够自动识别文档类型，并采用混合出题策略。

## 功能特性

- **多模式生成**：
  - **基于文档 (Document-Based)**：直接从提供的材料中提取题目（适用于内容详尽的文档）。
  - **基于主题 (Topic-Based)**：根据大纲或知识点利用内部知识库生成题目（适用于仅提供框架的文档）。
  - **混合模式 (Hybrid)**：根据内容分析结果，智能组合上述两种策略。
- **格式支持**：
  - **JSON**：标准化数据格式，便于系统集成 (`references/QUIZ_JSON_SPEC.md`)。
  - **Markdown**：人类可读格式，支持 LaTeX 公式渲染 (`references/QUIZ_MARKDOWN_SPEC.md`)。
- **自动化流程**：
  - 通过 `markitdown` 自动将输入文件转换为 Markdown。
  - 严格验证输出结构及嵌入流程中的约束条件。

## 使用方法

只需直接要求 AI 根据指定文件或主题生成题目即可。

### 目录结构

系统会自动在您的工作区管理以下目录：

- `./temp/`：存储转换过程中的中间文件（例如：PDF -> Markdown）。
- `./quiz/`：存储最终生成的题库文件，文件名格式为精确到秒的时间戳 (`YYYY-MM-DD-HHMMSS.[json|md]`)。

## 输出示例

### JSON 格式
```json
{
  "qid": "cs_001",
  "type": "单选题",
  "lev": 2,
  "point": ["计算机科学"],
  "question": "...",
  "options": ["A...", "B..."],
  "correct_answer": ["B"],
  "explanation": ["..."],
  "score": 5
}
```

### Markdown 格式
采用标准化排版，包含详细的选项解析和元数据表格。

## 依赖项

- **markitdown**：如果环境缺失，将尝试自动安装 (`https://github.com/davila7/claude-code-templates`)。

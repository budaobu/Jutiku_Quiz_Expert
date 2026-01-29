---
name: Jutiku_Quiz_Expert
description: 多模态出题专家。基于语义图重建的出题系统,支持图文协同推理、内容寻址资源管理、可编译题库输出。
keywords:
  - quiz
  - semantic-graph
  - multimodal
  - content-addressable
  - visual-reasoning
---

# AI 出题专家系统 v2.0 - 语义图重建架构

## 0. 核心原理

**第一性假设**：文档是语义网络的物理投影。图片不是孤立资源,而是被文本节点引用的语义锚点。

**系统目标**：重建文档的语义拓扑,在图文协同的知识图谱上生成题目。

### 0.1 目录拓扑

系统运行涉及两个相互独立的顶层目录空间：

**1. 技能库目录 (Skill Library)**
> **属性**：系统预置，只读，存放核心逻辑与规范定义。
```text
skills/Jutiku_Quiz_Expert/                 # 技能包根目录
  ├─ SKILL.md                       # 技能核心逻辑（本文档）
  └─ references/                    # 标准规范库
      ├─ QUIZ_JSON_SPEC.md          # JSON 输出协议定义
      └─ QUIZ_MARKDOWN_SPEC.md      # Markdown 排版协议定义
```

**2. Agent 工作区 (Workspace)**
> **属性**：运行时动态创建，读写，存放任务执行过程中的所有数据。
```text
${WORKSPACE}/                       # 当前任务工作区根目录
  ├─ temp/                          # [临时] 处理缓冲区
  │
  ├─ assets/                        # [全局] 媒体资源池 (CAS内容寻址)
  │   ├─ a3f7e2b1...png             # 所有历史资源
  │
  └─ quiz/                          # [交付] 最终交付物目录
      ├─ {TIMESTAMP}.md             # 题库文档
      ├─ {TIMESTAMP}.json           # 题库数据
      └─ assets/                    # [交付] 本次题库依赖的资源副本
          └─ a3f7e2b1...png
```

### 0.2 内容寻址原则
- 图片文件名 = `SHA256(图片内容).ext`
- 图片保存位置: `./assets/{hash}.ext`
- 题目引用格式: `![语义标注](./assets/{hash}.png)`（相对于题库文件的相对路径）
- 资源池不可变,失败时仅清理题目文件

### 0.3 输出格式规范

本系统支持两种标准输出格式：

**Markdown格式**：适用于人类阅读、文档发布、静态站点生成  
**规范文档**：技能包中的 `references/QUIZ_MARKDOWN_SPEC.md`

**JSON格式**：适用于程序解析、数据交换、系统集成  
**规范文档**：技能包中的 `references/QUIZ_JSON_SPEC.md`

**关键约束**：
- 生成题库前，**必须**先使用 `view` 工具阅读上述两份规范文档
- 两种格式必须语义等价，包含相同的题目内容和元数据
- 图片资源引用路径必须一致，均指向 `./assets/{hash}.ext`（相对路径）

---

## 1. 文档解析与语义图构建

### 1.1 多模态提取

**步骤A: 图片解耦**
```python
# DOCX/PPTX: 解压缩包提取 media/
# PDF: 使用 pymupdf 提取图片对象 (非整页截图)
# 过滤条件: 文件大小 > 10KB, 分辨率 > 200x200
# 保存位置: ./temp/images/
```

**步骤B: 文档转换**
```bash
# 使用 markitdown 生成 Markdown,保留图片占位符
markitdown input.docx > ./temp/source.md
```

**步骤C: 坐标标注**
在 Markdown 中标记每个图片的文档坐标:
```markdown
<!-- IMG_ANCHOR: id=img_01, page=3, para_idx=7 -->
![](./temp/images/fig_01.png)
```

### 1.2 上下文绑定

扫描 `./temp/source.md`,建立双向索引:

**文本→图片映射**:
- 正则匹配指代词: `/(如图|见图|Figure\s+\d+|上图|下图)/`
- 提取前后各 3 个段落文本
- 记录: `段落ID → [关联图片ID列表]`

**图片→文本映射**:
- 基于文档坐标,提取图片前后 2 段文本
- 记录: `图片ID → {前文, 后文, 指代句}`

**输出**: `./temp/graph.json`
```json
{
  "nodes": [
    {"id": "para_12", "type": "text", "content": "..."},
    {"id": "img_01", "type": "image", "path": "./temp/images/fig_01.png", "anchor": {...}}
  ],
  "edges": [
    {"from": "para_12", "to": "img_01", "relation": "refers"}
  ]
}
```

### 1.3 视觉理解分级

对每张图片执行分级识别:

**L0 - 装饰图** (丢弃)
- 特征: 纯色背景、Logo、水印
- 判断: 边缘检测后有效区域 < 30%

**L1 - 概念图** (提取拓扑)
- 类型: 流程图、思维导图
- 操作: OCR 提取文本框 → 识别连接线 → 构建有向图
- 输出: `{"nodes": ["开始", "判断", "结束"], "edges": [...]}`

**L2 - 数据图** (结构化)
- 类型: 柱状图、折线图、饼图
- 操作: 识别坐标轴、图例 → 提取数据点
- 输出: `{"x_axis": [...], "y_axis": [...], "series": [...]}`

**L3 - 计算图** (符号解析)
- 类型: 几何图、物理图、化学结构
- 操作: 
  - 符号识别: OCR + 数学符号库匹配
  - 空间关系: 边长、角度、平行/垂直/相交
  - 约束提取: "AC=3, ∠B=90°"
- 输出: 
```json
  {
    "type": "triangle",
    "vertices": ["A", "B", "C"],
    "constraints": {"AC": 3, "angle_B": 90},
    "implicit": ["BC⊥AC"]
  }
```

**容错机制**: 如果视觉分析失败,降级为 L1(纯文本描述)。

---

## 2. 出题策略引擎

### 2.1 文档类型识别

计算置信度向量:
```python
confidence = {
    "content_based": len(文本段落) / (len(文本段落) + len(图片)),
    "syllabus_based": 关键词密度(大纲标题词汇),
    "visual_based": L2/L3图片数量 / 总图片数量
}
```

**策略路由**:
- `visual_based >= 0.4` → 强制启用多模态模式
- `syllabus_based >= 0.6` → 主题扩展模式
- 其他 → 混合模式

### 2.2 多模态出题核心算法

**输入**: 语义图 `./temp/graph.json` + 视觉分析结果

**执行流程**:

1. **图遍历**:
```python
   for img_node in L2_L3_images:
       context = get_linked_paragraphs(img_node, graph)
       visual_data = img_node.visual_analysis
```

2. **题目生成**:
   - **几何题**: 
     - 从 `constraints` 中选择已知条件
     - 从 `implicit` 中推导可问问题(如求面积、证明)
     - 模板: `已知{constraints},求{target}`
   
   - **读图题**:
     - 掩盖图中关键标注(如坐标轴刻度、化学式)
     - 题干: "下图所示的曲线表示..."
   
   - **综合应用题**:
     - 结合 `context` 文本 + `visual_data`
     - 例: "根据图示实验装置,分析..."

3. **资源迁移**:
```python
   # 1. 从临时目录存入全局资源池 (去重)
   hash = sha256(img_file_content)
   global_asset_path = f"./assets/{hash}.png"
   if not exists(global_asset_path):
       copy(source_path, global_asset_path)
       
   # 2. 准备交付目录资源 (确保 Markdown 可通过相对路径访问)
   delivery_asset_path = f"./quiz/assets/{hash}.png"
   os.makedirs("./quiz/assets", exist_ok=True)
   if not exists(delivery_asset_path):
       copy(global_asset_path, delivery_asset_path)

   # 3. 题目引用路径: ./assets/{hash}.png (相对于 ./quiz/{TIMESTAMP}.md)
```

---

## 3. 题目质量保证

### 3.1 可编译性检查

在写入题库前执行:
```python
def validate_quiz(quiz_md):
    # 1. 解析所有图片引用
    refs = re.findall(r'!\[.*?\]\((./assets/.*?)\)', quiz_md)
    
    # 2. 检查文件存在性
    for ref in refs:
        # ref 是 './assets/xxx.png'
        assert os.path.exists(ref), f"Missing: {ref}"
    
    # 3. 校验语义标注与图片内容一致性
    for img, caption in extract_images_with_caption(quiz_md):
        visual_desc = analyze_image(img)
        assert semantic_match(caption, visual_desc)
```

### 3.2 事实校验
- LaTeX 公式: 自动检查括号配对、符号规范
- 数值计算: 对几何题的答案进行计算验证
- 逻辑一致性: 题干条件不能推出多个矛盾结论

### 3.3 格式规范校验

**Markdown格式校验**:
```python
def validate_markdown_format(quiz_md):
    # 1. 检查文档标题格式
    assert re.match(r'^# 题库 - \d{4}-\d{2}-\d{2}_\d{6}', quiz_md)
    
    # 2. 检查元数据区块存在性
    assert '## 📋 元数据' in quiz_md
    
    # 3. 检查题目结构完整性
    for question in extract_questions(quiz_md):
        assert has_stem(question)
        assert has_options(question) or is_calculation_question(question)
        assert has_metadata_table(question)
        assert has_explanation(question)
```

**JSON格式校验**:
```python
def validate_json_format(quiz_json):
    # 1. 检查顶层结构
    assert "meta" in quiz_json and "questions" in quiz_json
    
    # 2. 检查元数据完整性
    required_meta_fields = ["timestamp", "source", "total", "multimodal_count"]
    assert all(field in quiz_json["meta"] for field in required_meta_fields)
    
    # 3. 检查题目字段规范
    for q in quiz_json["questions"]:
        assert validate_question_fields(q)  # 详见 QUIZ_JSON_SPEC.md
```

---

## 4. 输出流程

### 4.1 准备阶段

**步骤1**: 读取输出格式规范（从技能目录）
```python
# 必须先读取规范文档
view(".agent/skills/Jutiku_Quiz_Expert/references/QUIZ_MARKDOWN_SPEC.md")
view(".agent/skills/Jutiku_Quiz_Expert/references/QUIZ_JSON_SPEC.md")
```

**步骤2**: 生成时间戳
```python
timestamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
```

**步骤3**: 准备元数据
```python
meta = {
    "timestamp": timestamp,
    "source": source_filename,
    "source_hash": compute_sha256(source_file),
    "total": len(questions),
    "multimodal_count": count_multimodal_questions(questions),
    "generator_version": "2.0.0"
}
```

### 4.2 双格式输出

**Markdown输出**:
```python
def generate_markdown_quiz(questions, meta):
    # 1. 构建文档头部
    content = f"# 题库 - {meta['timestamp']}\n\n"
    content += "## 📋 元数据\n"
    content += f"- **来源文档**: {meta['source']}\n"
    content += f"- **来源哈希**: {meta['source_hash']}\n"
    # ... 其他元数据字段
    
    # 2. 逐题生成（严格遵循 QUIZ_MARKDOWN_SPEC.md）
    for q in questions:
        content += format_question_markdown(q)
        content += "\n---\n\n"
    
    # 3. 格式校验
    validate_markdown_format(content)
    
    # 4. 写入工作区 quiz/ 目录
    write_file(f"./quiz/{meta['timestamp']}.md", content)
```

**JSON输出**:
```python
def generate_json_quiz(questions, meta):
    # 1. 构建JSON结构（严格遵循 QUIZ_JSON_SPEC.md）
    quiz_data = {
        "meta": meta,
        "questions": [format_question_json(q) for q in questions]
    }
    
    # 2. 格式校验
    validate_json_format(quiz_data)
    
    # 3. 写入工作区 quiz/ 目录
    write_file(f"./quiz/{meta['timestamp']}.json", 
               json.dumps(quiz_data, ensure_ascii=False, indent=2))
```

### 4.3 一致性验证
```python
def verify_output_consistency(timestamp):
    """确保Markdown和JSON输出语义等价"""
    md_file = f"./quiz/{timestamp}.md"
    json_file = f"./quiz/{timestamp}.json"
    
    md_questions = parse_markdown_questions(md_file)
    json_questions = load_json(json_file)["questions"]
    
    assert len(md_questions) == len(json_questions)
    
    for md_q, json_q in zip(md_questions, json_questions):
        # 检查题目ID、题干、答案是否一致
        assert md_q["id"] == json_q["qid"]
        assert normalize_text(md_q["stem"]) == normalize_text(json_q["question"])
        assert md_q["answer"] == json_q["correct_answer"]
        
        # 检查图片引用是否一致
        if md_q.get("media"):
            assert md_q["media"]["url"] == json_q["media"]["url"]
            assert md_q["media"]["hash"] == json_q["media"]["hash"]
```

### 4.4 移动到输出目录并展示
```python
def finalize_and_present(timestamp):
    """验证题库生成结果并通知用户"""
    
    # 最终输出文件路径
    md_output = f"./quiz/{timestamp}.md"
    json_output = f"./quiz/{timestamp}.json"
    
    # 确保文件已成功生成
    assert os.path.exists(md_output), "Markdown quiz generation failed"
    assert os.path.exists(json_output), "JSON quiz generation failed"
    
    # 通知用户任务完成
    print(f"Task Completed. Quiz generated at: ./quiz/{timestamp}.[md|json]")
    # 可以在这里展示部分内容或提供下载链接（取决于具体环境）
```

---

## 5. 执行检查清单

### 阶段零: 规范学习
- [ ] 已使用 `view` 工具读取技能包内的 `references/QUIZ_MARKDOWN_SPEC.md`
- [ ] 已使用 `view` 工具读取技能包内的 `references/QUIZ_JSON_SPEC.md`
- [ ] 理解Markdown和JSON的字段映射关系

### 阶段一: 预处理
- [ ] 图片提取完成,保存至 `./temp/images/`
- [ ] Markdown 转换完成,保存至 `./temp/source.md`
- [ ] 语义图构建完成,保存至 `./temp/graph.json`,edges 数量 > 0

### 阶段二: 出题
- [ ] 视觉分析完成,L2/L3 图片有结构化输出
- [ ] 题目生成完成,多模态题目数量符合预期
- [ ] 资源迁移完成,`./assets/` 非空

### 阶段三: 质检
- [ ] 可编译性检查通过(无 broken links)
- [ ] LaTeX 公式语法检查通过
- [ ] 几何题答案计算验证通过
- [ ] Markdown格式规范校验通过
- [ ] JSON格式规范校验通过
- [ ] 双格式输出一致性验证通过
- [ ] 题库文件已写入 `./quiz/`

### 阶段四: 交付
- [ ] 题库文件已生成在 `./quiz/` 目录
- [ ] 依赖资源已正确复制到 `./quiz/assets/` 目录
- [ ] 验证 Markdown 中的图片引用路径 `./assets/...` 有效

---

## 6. 失败处理

**原则**: 出题过程失败时,保持资源池不可变。
```python
try:
    # 1. 读取规范文档（从技能目录读取）
    view("references/QUIZ_MARKDOWN_SPEC.md")
    view("references/QUIZ_JSON_SPEC.md")
    
    # 2. 生成题目
    quiz_content = generate_quiz(graph, visual_results)
    
    # 3. 验证题目
    validate_quiz(quiz_content)
    
    # 4. 双格式输出（工作区 quiz/ 目录）
    timestamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    generate_markdown_quiz(quiz_content, meta, timestamp)
    generate_json_quiz(quiz_content, meta, timestamp)
    
    # 5. 一致性验证
    verify_output_consistency(timestamp)
    
    # 6. 完成交付
    finalize_and_present(timestamp)
    
except Exception as e:
    # 仅清理工作区临时文件,assets/ 保持原样
    log_error(e)
    cleanup("./temp/*")
    # 不删除 ./assets/,因为其他题库可能引用同一图片
    raise
```

---

## 7. 扩展能力

### 7.1 动态题库
- 为同一张几何图生成 3 种难度的变体题目
- 通过修改约束条件(改变边长、角度)生成同构题目

### 7.2 协同推理
- 对于复杂物理题,调用符号计算引擎(SymPy)验证答案
- 对于化学题,调用分子式解析器校验化学方程式

### 7.3 多语言支持
- 语义图中的文本节点支持多语言标注
- 图片 OCR 识别多语言符号(中文、英文、希腊字母)

### 7.4 格式转换工具
```python
def convert_json_to_markdown(json_file):
    """将JSON题库转换为Markdown格式"""
    quiz_data = load_json(json_file)
    return generate_markdown_quiz(quiz_data["questions"], quiz_data["meta"])

def convert_markdown_to_json(md_file):
    """将Markdown题库转换为JSON格式"""
    questions = parse_markdown_questions(md_file)
    meta = extract_metadata_from_markdown(md_file)
    return generate_json_quiz(questions, meta)
```

---

## 8. 使用示例

### 基本工作流程
```python
# 步骤1: 读取规范文档（必需，从技能目录）
view("references/QUIZ_MARKDOWN_SPEC.md")
view("references/QUIZ_JSON_SPEC.md")

# 步骤2: 解析源文档（假设文档已位于工作区）
source_file = "./高中数学必修2.docx"  # 或用户指定的其他路径
graph = parse_document(source_file)

# 步骤3: 视觉分析
visual_results = analyze_images(graph["image_nodes"])

# 步骤4: 生成题目
questions = generate_questions(graph, visual_results)

# 步骤5: 双格式输出（工作区 quiz/ 目录）
timestamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
generate_markdown_quiz(questions, meta, timestamp)
generate_json_quiz(questions, meta, timestamp)

# 步骤6: 验证输出
verify_output_consistency(timestamp)

# 步骤7: 完成交付
finalize_and_present(timestamp)
```

---

## 9. 关键约束提醒

1. **规范优先**：任何输出操作前，必须先阅读技能包内的 `references/` 中的规范文档
2. **双格式输出**：默认同时生成 Markdown 和 JSON 两种格式
3. **语义等价**：两种格式必须包含完全相同的题目内容和元数据
4. **路径约定**：
   - 全局资源池：`./assets/{hash}.ext`
   - 交付题库：`./quiz/{timestamp}.[md|json]`
   - 交付资源：`./quiz/assets/{hash}.ext`
   - 引用路径：`./assets/{hash}.ext` (在 Markdown/JSON 中相对于题库文件的路径)
5. **哈希验证**：输出文件中的 `资源哈希` 字段必须与实际文件内容匹配
6. **格式校验**：输出前必须通过 `validate_markdown_format()` 和 `validate_json_format()` 校验
7. **目录结构**：
   - 技能规范文档在 `skills/Jutiku_Quiz_Expert/references/`（只读，路径可能随环境变化）
   - 工作区在 `./`（当前目录，可读写）
   - 最终交付物在 `./quiz/` 目录

---

**系统完成标志**:
- 题库文件可独立迁移
- 在任何环境下运行 `validate_quiz()` 均通过
- 图文语义完整对应
- Markdown 和 JSON 输出语义等价
- 所有格式规范校验通过
- 题库文件已成功生成在 `./quiz/` 目录并验证通过
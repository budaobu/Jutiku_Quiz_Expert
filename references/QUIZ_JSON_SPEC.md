---
title: Quiz Data Schema Specification v2.0
description: AI出题专家系统的标准JSON输出规范。定义多模态题目的数据结构、资源引用机制、验证规则，支持内容寻址存储、语义图溯源、跨平台迁移。适用于教育测评系统、题库管理平台、自动出题工具的数据交换标准。
---

# Quiz Data Schema Specification v2.0

本文档定义 AI 出题专家系统的标准 JSON 输出结构，支持多模态题目、语义图溯源、内容寻址资源引用。

---

## 1. 顶层结构
```json
{
  "meta": {
    "timestamp": "2024-01-29_143052",
    "source": "高中数学必修2.docx",
    "source_hash": "sha256:a1b2c3...",
    "total": 25,
    "multimodal_count": 8,
    "generator_version": "2.0.0"
  },
  "questions": [ /* 题目数组 */ ]
}
```

### 字段说明

| 字段 | 类型 | 说明 |
|:---|:---|:---|
| `timestamp` | string | 题库生成时间，格式 `YYYY-MM-DD_HHMMSS` |
| `source` | string | 源文档文件名 |
| `source_hash` | string | 源文档 SHA256 哈希，用于版本追溯 |
| `total` | integer | 题目总数 |
| `multimodal_count` | integer | 包含图片/多模态资源的题目数量 |
| `generator_version` | string | 系统版本号 |

---

## 2. 题目对象结构

### 2.1 基础字段（所有题型）
```json
{
  "qid": "math_001",
  "type": "单选题",
  "lev": 2,
  "point": ["三角函数", "勾股定理"],
  "question": "如图所示，在 $\\triangle ABC$ 中...",
  "options": [
    "A. 选项一",
    "B. 选项二",
    "C. 选项三",
    "D. 选项四"
  ],
  "correct_answer": ["B"],
  "explanation": [
    "A. 错误。...",
    "B. 正确。...",
    "C. 错误。...",
    "D. 错误。..."
  ],
  "score": 5
}
```

### 2.2 多模态扩展字段

当题目包含图片、音频、视频等资源时，添加以下字段：
```json
{
  "qid": "geo_003",
  "type": "单选题",
  "lev": 3,
  "point": ["立体几何", "空间向量"],
  "question": "如图所示，正方体 $ABCD-A'B'C'D'$ 中...",
  "options": ["A. $\\frac{\\sqrt{2}}{2}$", "B. $\\frac{\\sqrt{3}}{3}$", "C. $\\frac{1}{2}$", "D. $1$"],
  "correct_answer": ["A"],
  "explanation": [
    "A. 正确。建立空间直角坐标系后，向量夹角余弦值为 $\\frac{\\sqrt{2}}{2}$。",
    "B. 错误。计算过程中未考虑向量模长归一化。",
    "C. 错误。混淆了二维与三维空间的角度关系。",
    "D. 错误。该值对应垂直关系，不符合题意。"
  ],
  "score": 8,
  
  "media": {
    "type": "image",
    "url": "./assets/a3f7e2b1c4d5...png",
    "hash": "sha256:a3f7e2b1c4d5...",
    "caption": "正方体ABCD-A'B'C'D'，已知边长为2",
    "analysis": {
      "visual_type": "L3_计算图",
      "extracted_info": {
        "shape": "cube",
        "vertices": ["A", "B", "C", "D", "A'", "B'", "C'", "D'"],
        "constraints": {"edge_length": 2},
        "annotations": ["对角线AC'", "向量BA'"]
      }
    },
    "source_context": {
      "doc_page": 12,
      "para_index": 5,
      "related_text": "空间向量的夹角定义为..."
    }
  }
}
```

### 2.3 字段约束规范

| 字段 | 类型 | 约束 | 说明 |
|:---|:---|:---|:---|
| `qid` | string | 必须唯一，格式 `[科目]_[编号]` | 例：`math_001`, `phys_042` |
| `type` | string | 枚举：`单选题` \| `多选题` \| `判断题` \| `计算题` \| `证明题` | 多模态题目可能包含 `计算题`、`证明题` |
| `lev` | integer | 1-3 | 1=概念识别，2=综合应用，3=逻辑推导/创新 |
| `point` | array[string] | 至少 1 个元素 | 知识点标签，用于题库索引 |
| `question` | string | 非空 | 支持 LaTeX 公式（`$...$` 或 `$$...$$`） |
| `options` | array[string] | 判断题固定 2 个，其他题型 2-6 个 | 格式：`"字母. 内容"` |
| `correct_answer` | array[string] | 非空，单选 1 个，多选 ≥2 个 | 仅包含字母（如 `["B"]` 或 `["A", "C"]`） |
| `explanation` | array[string] | 长度 = `options` 长度 | 每个元素格式：`"字母. 正误判断 + 分析"` |
| `score` | integer | > 0 | 建议分值，计算题/证明题通常 8-12 分 |

### 2.4 多模态字段详解

#### `media` 对象（可选）

| 字段 | 类型 | 说明 |
|:---|:---|:---|
| `type` | string | 枚举：`image` \| `audio` \| `video` |
| `url` | string | **相对路径**，格式：`./assets/{SHA256}.{ext}` |
| `hash` | string | 格式：`sha256:{完整哈希值}` |
| `caption` | string | 图片的语义标注，便于无障碍阅读 |
| `analysis` | object | 视觉分析结果（见下方） |
| `source_context` | object | 源文档中的上下文信息（见下方） |

#### `analysis` 对象（视觉分析结果）
```json
{
  "visual_type": "L3_计算图",
  "extracted_info": {
    "shape": "triangle",
    "vertices": ["A", "B", "C"],
    "constraints": {
      "AC": 3,
      "BC": 4,
      "angle_C": 90
    },
    "annotations": ["斜边AB", "直角标记"]
  }
}
```

| 字段 | 说明 |
|:---|:---|
| `visual_type` | 视觉分级结果：`L1_概念图` \| `L2_数据图` \| `L3_计算图` |
| `extracted_info` | 结构化信息，根据图片类型不同而不同 |

#### `source_context` 对象（文档溯源）
```json
{
  "doc_page": 12,
  "para_index": 5,
  "related_text": "根据勾股定理，斜边的平方等于..."
}
```

| 字段 | 说明 |
|:---|:---|
| `doc_page` | 源文档页码（从 1 开始） |
| `para_index` | 图片所在段落的索引 |
| `related_text` | 前后文的关键句子（最多 100 字） |

---

## 3. 题型特殊规则

### 3.1 判断题
```json
{
  "qid": "logic_005",
  "type": "判断题",
  "lev": 1,
  "point": ["命题逻辑"],
  "question": "若 $p \\rightarrow q$ 为真，则 $\\neg q \\rightarrow \\neg p$ 必为真。",
  "options": [
    "A. 正确",
    "B. 错误"
  ],
  "correct_answer": ["A"],
  "explanation": [
    "A. 正确。这是逆否命题的等价性定理。",
    "B. 错误。逆否命题与原命题逻辑等价。"
  ],
  "score": 3
}
```

### 3.2 多选题
```json
{
  "qid": "chem_008",
  "type": "多选题",
  "lev": 2,
  "point": ["化学平衡", "勒夏特列原理"],
  "question": "对于放热反应 $N_2 + 3H_2 \\rightleftharpoons 2NH_3$，下列措施能提高氨气产率的是？",
  "options": [
    "A. 增大压强",
    "B. 降低温度",
    "C. 使用催化剂",
    "D. 移除生成的氨气"
  ],
  "correct_answer": ["A", "B", "D"],
  "explanation": [
    "A. 正确。增压使平衡向体积减小方向移动，氨气产率提高。",
    "B. 正确。降温利于放热反应正向进行。",
    "C. 错误。催化剂只改变反应速率，不影响平衡位置。",
    "D. 正确。移除产物促使平衡正向移动。"
  ],
  "score": 6
}
```

### 3.3 计算题（多模态）
```json
{
  "qid": "phys_012",
  "type": "计算题",
  "lev": 3,
  "point": ["牛顿第二定律", "受力分析"],
  "question": "如图所示，质量 $m=2kg$ 的物块在倾角 $\\theta=30°$ 的斜面上，受水平推力 $F=20N$ 作用。求物块的加速度。（取 $g=10m/s^2$）",
  "options": [],
  "correct_answer": ["$a = 5m/s^2$，方向沿斜面向上"],
  "explanation": [
    "**解题步骤**：",
    "1. 建立坐标系，分解受力：$F_x = F\\cos\\theta$，$F_y = F\\sin\\theta$",
    "2. 沿斜面方向合力：$F_{合} = F_x - mg\\sin\\theta = 20 \\times \\frac{\\sqrt{3}}{2} - 2 \\times 10 \\times 0.5 = 10\\sqrt{3} - 10 \\approx 7.32N$",
    "3. 由 $F=ma$ 得：$a = \\frac{F_{合}}{m} \\approx 3.66m/s^2$",
    "**标准答案修正**：实际计算得 $a \\approx 3.66m/s^2$（题目答案有误，应为此值）"
  ],
  "score": 10,
  
  "media": {
    "type": "image",
    "url": "./assets/f8e3b2a1...png",
    "hash": "sha256:f8e3b2a1...",
    "caption": "斜面物块受力示意图",
    "analysis": {
      "visual_type": "L3_计算图",
      "extracted_info": {
        "objects": ["斜面", "物块"],
        "forces": ["重力mg", "推力F", "支持力N", "摩擦力f"],
        "parameters": {"m": 2, "theta": 30, "F": 20}
      }
    }
  }
}
```

**计算题特殊约束**：
- `options` 为空数组
- `correct_answer` 包含完整数学表达式
- `explanation` 包含逐步推导过程

---

## 4. 资源引用规则

### 4.1 内容寻址机制

所有媒体资源使用 SHA256 哈希作为文件名：
```
./quiz/
  ├─ 2024-01-29_143052.json
  └─ assets/
      ├─ a3f7e2b1c4d5e6f7...png  ← 几何图
      ├─ b1c2d3e4f5a6b7c8...jpg  ← 物理实验图
      └─ c2d3e4f5a6b7c8d9...svg  ← 化学结构式
```

### 4.2 引用路径格式

- JSON 中的 `url` 字段：`"./assets/{hash}.{ext}"`
- Markdown 中的图片引用：`![caption](./assets/{hash}.{ext})`

### 4.3 资源复用

相同内容的图片只存储一次：
```json
// 题目 A
{"media": {"url": "./assets/abc123.png", "hash": "sha256:abc123..."}}

// 题目 B（引用同一张图）
{"media": {"url": "./assets/abc123.png", "hash": "sha256:abc123..."}}
```

---

## 5. 验证规则

### 5.1 结构完整性检查
```python
def validate_structure(quiz_json):
    assert "meta" in quiz_json
    assert "questions" in quiz_json
    assert quiz_json["meta"]["total"] == len(quiz_json["questions"])
    
    multimodal_count = sum(1 for q in quiz_json["questions"] if "media" in q)
    assert quiz_json["meta"]["multimodal_count"] == multimodal_count
```

### 5.2 字段约束检查
```python
def validate_question(q):
    # 基础字段
    assert q["type"] in ["单选题", "多选题", "判断题", "计算题", "证明题"]
    assert 1 <= q["lev"] <= 3
    assert len(q["point"]) > 0
    
    # 选项与答案一致性
    if q["type"] == "判断题":
        assert len(q["options"]) == 2
        assert len(q["correct_answer"]) == 1
    elif q["type"] == "单选题":
        assert len(q["correct_answer"]) == 1
    elif q["type"] == "多选题":
        assert len(q["correct_answer"]) >= 2
    
    # 解析数量匹配
    if q["type"] != "计算题":
        assert len(q["explanation"]) == len(q["options"])
```

### 5.3 资源可达性检查
```python
def validate_media(q, base_path="./quiz"):
    if "media" not in q:
        return
    
    url = q["media"]["url"]
    full_path = os.path.join(base_path, url)
    assert os.path.exists(full_path), f"Missing resource: {url}"
    
    # 校验哈希值
    with open(full_path, "rb") as f:
        actual_hash = hashlib.sha256(f.read()).hexdigest()
    expected_hash = q["media"]["hash"].replace("sha256:", "")
    assert actual_hash == expected_hash, f"Hash mismatch for {url}"
```

---

## 6. 迁移与兼容性

### 6.1 题库打包

生成独立分发包：
```bash
# 打包结构
quiz_export_2024-01-29.zip
├─ quiz.json           # 题目数据
├─ assets/             # 所有引用的媒体资源
│   ├─ a3f7e2b1...png
│   └─ b1c2d3e4...jpg
└─ README.md           # 题库说明
```

### 6.2 版本兼容策略

- **向后兼容**：新版本系统可读取旧版本 JSON（忽略未知字段）
- **向前兼容**：旧版本系统读取新版本 JSON 时，降级为基础字段模式

### 6.3 数据迁移示例

从 v1.0 迁移到 v2.0：
```python
def migrate_v1_to_v2(old_json):
    new_json = {
        "meta": {
            **old_json["meta"],
            "source_hash": compute_hash(old_json["meta"]["source"]),
            "generator_version": "2.0.0"
        },
        "questions": []
    }
    
    for q in old_json["questions"]:
        new_q = {**q}
        
        # 如果有图片字段（v1.0格式）
        if "image_url" in q:
            hash_val = extract_hash_from_url(q["image_url"])
            new_q["media"] = {
                "type": "image",
                "url": q["image_url"],
                "hash": f"sha256:{hash_val}",
                "caption": q.get("image_caption", ""),
                "analysis": {},  # 空对象，保持兼容
                "source_context": {}
            }
            del new_q["image_url"]
        
        new_json["questions"].append(new_q)
    
    return new_json
```

---

## 7. 示例完整题库
```json
{
  "meta": {
    "timestamp": "2024-01-29_143052",
    "source": "高中数学必修2.docx",
    "source_hash": "sha256:e3b0c44298fc1c14...",
    "total": 3,
    "multimodal_count": 2,
    "generator_version": "2.0.0"
  },
  "questions": [
    {
      "qid": "math_001",
      "type": "单选题",
      "lev": 2,
      "point": ["三角函数", "勾股定理"],
      "question": "如图所示，在 $\\triangle ABC$ 中，$\\angle C = 90°$，$AC = 3$，$BC = 4$，求 $AB$ 的长度。",
      "options": [
        "A. 5",
        "B. 6",
        "C. 7",
        "D. $\\sqrt{7}$"
      ],
      "correct_answer": ["A"],
      "explanation": [
        "A. 正确。根据勾股定理：$AB = \\sqrt{AC^2 + BC^2} = \\sqrt{9 + 16} = 5$。",
        "B. 错误。未正确应用勾股定理。",
        "C. 错误。计算错误。",
        "D. 错误。$\\sqrt{7}$ 无法由给定边长计算得出。"
      ],
      "score": 5,
      "media": {
        "type": "image",
        "url": "./assets/a3f7e2b1c4d5e6f7890abcdef1234567.png",
        "hash": "sha256:a3f7e2b1c4d5e6f7890abcdef1234567",
        "caption": "直角三角形ABC，已知∠C=90°，AC=3，BC=4",
        "analysis": {
          "visual_type": "L3_计算图",
          "extracted_info": {
            "shape": "triangle",
            "vertices": ["A", "B", "C"],
            "constraints": {"AC": 3, "BC": 4, "angle_C": 90},
            "annotations": ["直角标记", "边长标注"]
          }
        },
        "source_context": {
          "doc_page": 8,
          "para_index": 3,
          "related_text": "勾股定理是平面几何中的基本定理..."
        }
      }
    },
    {
      "qid": "math_002",
      "type": "判断题",
      "lev": 1,
      "point": ["集合论"],
      "question": "空集是任何集合的子集。",
      "options": [
        "A. 正确",
        "B. 错误"
      ],
      "correct_answer": ["A"],
      "explanation": [
        "A. 正确。根据子集定义，空集不包含任何元素，因此是任何集合的子集。",
        "B. 错误。这是集合论的基本性质。"
      ],
      "score": 3
    },
    {
      "qid": "phys_001",
      "type": "计算题",
      "lev": 3,
      "point": ["电路分析", "欧姆定律"],
      "question": "如图所示电路，已知 $R_1=2\\Omega$，$R_2=3\\Omega$，$U=10V$。求通过 $R_1$ 的电流 $I_1$。",
      "options": [],
      "correct_answer": ["$I_1 = 2A$"],
      "explanation": [
        "**解题步骤**：",
        "1. 识别电路结构：$R_1$ 与 $R_2$ 串联",
        "2. 计算总电阻：$R_{总} = R_1 + R_2 = 2 + 3 = 5\\Omega$",
        "3. 应用欧姆定律：$I = \\frac{U}{R_{总}} = \\frac{10}{5} = 2A$",
        "4. 串联电路电流相等：$I_1 = I = 2A$"
      ],
      "score": 10,
      "media": {
        "type": "image",
        "url": "./assets/b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6.png",
        "hash": "sha256:b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6",
        "caption": "串联电路示意图",
        "analysis": {
          "visual_type": "L2_数据图",
          "extracted_info": {
            "circuit_type": "series",
            "components": [
              {"type": "resistor", "label": "R1", "value": 2},
              {"type": "resistor", "label": "R2", "value": 3},
              {"type": "voltage_source", "label": "U", "value": 10}
            ]
          }
        },
        "source_context": {
          "doc_page": 15,
          "para_index": 7,
          "related_text": "串联电路中，各元件电流相等..."
        }
      }
    }
  ]
}
```

---

## 8. 附录：字段索引

### 必需字段
- `qid`, `type`, `lev`, `point`, `question`, `options`, `correct_answer`, `explanation`, `score`

### 可选字段
- `media` (多模态题目)
- `media.analysis` (视觉分析结果)
- `media.source_context` (文档溯源)

### 枚举值清单
- **题型 (`type`)**：单选题、多选题、判断题、计算题、证明题
- **难度 (`lev`)**：1、2、3
- **媒体类型 (`media.type`)**：image、audio、video
- **视觉分级 (`visual_type`)**：L1_概念图、L2_数据图、L3_计算图

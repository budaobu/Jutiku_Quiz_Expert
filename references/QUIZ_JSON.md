---
title: JSON 题目格式规范
description: 本文档定义了 AI 出题专家系统的标准 JSON 输出结构，旨在提升题目数据的机器可读性与解析效率。
version: 1.1
---

## 1. 结构定义

使用标准的 JSON 格式封装，包含元数据 `meta` 与题目集合 `questions`。

```json
{
  "meta": {
    "timestamp": "YYYY-MM-DD_HHMMSS",
    "source": "string",
    "version": "string",
    "total": integer
  },
  "questions": [
    {
      "qid": "string (unique ID)",
      "type": "string (单选题 | 多选题 | 判断题 | 填空题 | 简答题)",
      "lev": "integer (1 | 2 | 3)",
      "point": ["string"],
      "tags": ["string"],
      "question": "string",
      "options": ["string"],
      "correct_answer": ["string"],
      "explanation": {
        "analysis": "string (解题思路与核心逻辑)",
        "options_detail": ["string (对应 options 顺序的逐项解析)"]
      },
      "score": "integer"
    }
  ]
}
```

## 1.1 生成规则与约束

在生成题目时，请严格遵守以下规则：

- **题型支持**：单选题、多选题、判断题、填空题、简答题。
- **判断题约束**：`options` 数组必须固定为 `["A. 正确", "B. 错误"]`。
- **难度分布策略**：
    - **1级（简单）**：直接回忆，定义匹配。
    - **2级（中等）**：概念应用，比较分析。
    - **3级（困难）**：复杂分析，综合推理，多步骤推理。
    - **分布比例**：建议保持 30% 简单、50% 中等、20% 困难。
- **字段完整性**：每道题 **必须** 包含 `qid`, `type`, `question`, `options`, `correct_answer`, `explanation`, `point`, `lev`, `score` 等所有核心字段。



## 2. 字段约束说明

### 2.1 Meta 对象 (元数据层)
元数据用于记录数据集的全局属性，便于版本追溯与传输校验。

| 字段名 | 类型 | 约束条件 | 说明 |
| :--- | :--- | :--- | :--- |
| `timestamp` | String | `YYYY-MM-DD_HHMMSS` | 记录生成时间，如 `2026-01-28_233015`。 |
| `source` | String | 必填 | 标明原始资料名称（如文件名、数据库 ID 或 URL）。 |
| `version` | String | 语义化版本 | 当前规范版本为 `1.1`。 |
| `total` | Int | >= 0 | `questions` 数组的长度，用于完整性校验。 |

### 2.2 Questions 数组 (数据内容层)
每一项代表一个独立的题目对象。

| 字段名 | 类型 | 约束条件 | 说明 |
| :--- | :--- | :--- | :--- |
| `qid` | String | 唯一索引 | 建议格式：`[科目缩写]_[知识点缩写]_[编号]`。 |
| `type` | String | 枚举值 | 仅限：`单选题`、`多选题`、`判断题`、`填空题`、`简答题`。 |
| `lev` | Int | 1 \| 2 \| 3 | 1: 基础认知；2: 综合应用；3: 专家/逻辑推导。 |
| `point` | Array | 非空 | 包含该题考察的核心知识点标签。 |
| `tags` | Array | 可选 | 额外的分类标签（如：章节、易错题、重点）。 |
| `question` | String | 必填 | 题目正文，支持 Markdown 格式。 |
| `options` | Array | 视题型定义 | 判断题固定为 `["A. 正确", "B. 错误"]`；非选择题设为空数组 `[]`。 |
| `correct_answer`| Array | 字母/索引数组 | 仅包含选项字母，如 `["A"]`；填空/简答题则填入参考答案。 |
| `explanation` | Object | 结构化对象 | 包含 `analysis` (整体思路) 与 `options_detail` (选项解析)。 |
| `score` | Int | 正整数 | 建议分值，反映题目权重。 |

---

## 3. 标准规范示例

```json
{
  "meta": {
    "timestamp": "2026-01-28_233015",
    "source": "2026年计算机等级考试模拟卷.pdf",
    "version": "1.2",
    "total": 1
  },
  "questions": [
    {
      "qid": "CS_NET_001",
      "type": "单选题",
      "lev": 2,
      "point": ["TCP/IP", "三次握手"],
      "tags": ["重点", "考研常考"],
      "question": "在 TCP 三次握手协议中，第二次握手发送的报文段中，SYN 和 ACK 标志位的值分别是？",
      "options": [
        "A. SYN=1, ACK=0",
        "B. SYN=1, ACK=1",
        "C. SYN=0, ACK=1",
        "D. SYN=0, ACK=0"
      ],
      "correct_answer": ["B"],
      "explanation": {
        "analysis": "第二次握手由服务器发出，旨在响应客户端的同步请求（ACK=1）并同时发起服务器端的同步请求（SYN=1）。",
        "options_detail": [
          "A. 错误。这是第一次握手的特征。",
          "B. 正确。此时服务端既在回应也在发起同步。",
          "C. 错误。这是第三次握手的典型特征。",
          "D. 错误。无效配置，不符合协议规范。"
        ]
      },
      "score": 5
    }
  ]
}
```
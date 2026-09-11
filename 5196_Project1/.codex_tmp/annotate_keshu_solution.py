from __future__ import annotations

import ast
import copy
import json
import re
from pathlib import Path


SOURCE = Path(
    r"C:\Users\张可姝\Desktop\FIT5196 Data Wrangling\Ass1\提交"
    r"\Group050_solution.ipynb"
)
OUTPUT = Path(r"C:\monash\Monash_Project\5196_Project1\Group50_solution_K.ipynb")
MARKER = "[Keshu presentation note]"


TARGET_CELLS = {
    29: "Task 2 products：把结构化XML产品记录转换为一行一个product_id的21字段标准化表。",
    31: "Task 2 product_reviews：分别标准化JSON/XML评论，再按review_id处理源内重复和跨源重叠。",
    37: "Task 4 Keshu验证辅助：统一生成验证记录，并检查产品/评论字段的语义类型与表结构。",
    38: "Task 4 schema和类型：确认products与product_reviews严格符合公共数据字典。",
    43: "Task 4主外键：检查产品与评论主键，以及评论到orders、order_items、products、customers的外键。",
    49: "Task 4范围、类别、row flow和reconciliation：验证业务范围及源记录到canonical记录的完整流转。",
    59: "Task 4文本与多语言：验证Task 3函数、派生长度、引用、多语言字段和字面量NaN规则。",
    62: "Task 4最终register整合：统一四位成员的验证结果并检查ID唯一性和总PASS/FAIL。",
}


FUNCTION_DESCRIPTIONS = {
    "_normalise_required_product_text": "清理必填产品文本：转字符串、NFC标准化、去除首尾空格，同时保留ID前导零和大小写。",
    "_parse_product_currency": "解析产品金额：删除AUD标签和千位逗号，使用Decimal转换并按两位小数四舍五入。",
    "_parse_product_integer": "解析产品整数：拒绝小数型输入，避免把错误数据静默取整。",
    "_parse_product_number": "解析一般产品数值：通过Decimal检查后转换为float。",
    "_parse_product_date": "解析XML产品日期：把DD/MM/YYYY转换为目标YYYY-MM-DD。",
    "_parse_product_boolean": "解析XML布尔值：只允许Y/N并转换为Python True/False。",
    "_remove_product_description_emoji": "删除产品描述中的常见emoji码位；这是Task 2私有辅助函数，不是个人Task 3函数。",
    "_clean_product_description_for_task2": "生成product_description_clean：优先调用共享clean_narrative_text，否则执行等价的Task 2私有清洗流程。",
    "_standardise_product_record": "把一条XML Product记录映射为数据字典规定的21个目标字段。",
    "_reconcile_product_candidates": "按product_id协调候选记录；逐字段记录冲突，不静默偏向某条记录。",
    "_normalise_required_review_text": "清理必填评论结构字段，同时保留ID前导零和来源大小写。",
    "_parse_required_review_integer": "统一JSON数字与XML文本整数的目标类型，并拒绝非整数值。",
    "_parse_review_timestamp": "依据来源选择时间格式，再统一输出YYYY-MM-DD HH:MM:SS。",
    "_parse_review_boolean": "分别处理JSON原生bool和XML Y/N，统一返回Python bool。",
    "_standardise_product_review_record": "把一条JSON或XML评论标准化为21字段，并按正确顺序完成提取、清洗和多语言派生。",
    "_reconcile_product_review_candidates": "按review_id逐字段协调JSON/XML候选记录，并单独保留冲突证据。",
    "_record_keshu_validation": "按统一列结构记录Keshu范围内的一条validation结果。",
    "_semantic_type_issue_count": "按公共数据字典的语义类型统计不符合要求的值。",
    "_table_contract_observation": "汇总字段缺失、额外字段、字段顺序、Python缺失值和类型问题。",
    "_serialise_observed_result": "把字典、列表等observed_result稳定序列化，便于合并和展示。",
    "_normalise_component_register": "把某位成员的validation register统一为最终register的公共列结构。",
}


VARIABLE_DESCRIPTIONS = {
    "text": "保存当前文本处理中间结果。",
    "result": "保存当前函数计算得到的结果。",
    "amount": "保存成功解析的Decimal金额。",
    "number": "保存Decimal数值，用于继续检查整数性或精度。",
    "boolean_mapping": "建立XML Y/N到Python布尔值的显式映射。",
    "emoji_ranges": "列出需要从产品描述中删除的emoji Unicode区间。",
    "shared_cleaner": "从当前notebook命名空间查找已导入的共享clean_narrative_text。",
    "canonical_rows": "累计每个业务主键对应的一条canonical输出记录。",
    "conflict_rows": "累计字段级冲突证据，避免冲突被静默覆盖。",
    "canonical": "保存当前主键正在构建的canonical记录。",
    "non_missing_values": "收集当前字段的非缺失候选值。",
    "distinct_values": "按稳定顺序去除重复值，供冲突判断和canonical取值使用。",
    "canonical_frame": "把canonical记录列表转换为目标DataFrame。",
    "conflict_frame": "把冲突列表转换为结构化冲突DataFrame。",
    "product_columns": "从公共数据字典读取products的准确字段顺序。",
    "product_candidates": "保存所有标准化后的Product候选记录。",
    "product_conflicts": "保存产品候选记录的字段级冲突。",
    "products": "保存最终一行一个product_id的标准化产品表。",
    "product_row_flow": "建立产品从结构化来源到canonical输出的行数证据。",
    "source_patterns": "定义JSON和XML评论时间戳各自的解析格式。",
    "xml_boolean_mapping": "定义XML评论Y/N到Python bool的转换。",
    "source_field_maps": "定义JSON和XML原字段名到统一评论语义字段的映射。",
    "fields": "选择当前source_format对应的评论字段映射。",
    "raw_review": "保存尚未清洗的原始评论文本；reference和SKU必须从这里提取。",
    "extracted_order_reference": "在清洗前从原始评论中提取order reference。",
    "extracted_product_sku": "在清洗前从原始评论中提取product SKU。",
    "review_body_clean": "调用共享清洗函数生成保留多语言内容的标准化评论正文。",
    "review_body_latin_analysis": "调用本人负责的build_latin_analysis生成Latin-script分析文本。",
    "review_contains_non_latin": "调用本人负责的contains_non_latin_script生成非Latin脚本布尔标记。",
    "review_length_chars": "保存清洗后评论正文的字符数量。",
    "review_word_count": "保存按空白分词得到的评论词数。",
    "product_review_columns": "从数据字典取得product_reviews的21个字段及准确顺序。",
    "json_product_review_candidates": "保存JSON来源标准化后的评论候选记录。",
    "xml_product_review_candidates": "保存XML来源标准化后的评论候选记录。",
    "product_review_candidates": "纵向合并JSON和XML评论候选记录，等待按review_id协调。",
    "product_review_conflicts": "保存评论跨记录字段级冲突证据。",
    "product_reviews": "保存最终一行一个review_id的标准化评论表。",
    "product_review_row_flow": "建立评论源内重复、跨源重叠和canonical输出的row-flow证据。",
    "keshu_validation_rows": "累计本人负责范围内的validation记录。",
    "keshu_validation_register": "把本人validation记录整理成表格。",
    "task3_test_observed": "汇总公共测试、自建测试和接口测试的通过数量。",
    "task3_tests_passed": "判断三类Task 3测试是否全部通过。",
    "clean_bodies": "引用review_body_clean列，供长度、多语言和NaN检查复用。",
    "expected_review_lengths": "根据review_body_clean重新计算预期字符数。",
    "expected_review_word_counts": "根据review_body_clean重新计算预期空白分词数。",
    "expected_latin_analysis": "重新调用build_latin_analysis得到可复算的预期值。",
    "expected_non_latin": "重新调用contains_non_latin_script得到预期布尔标记。",
    "validation_register": "保存四位成员validation合并后的最终登记表。",
    "validation_status_summary": "按owner scope和status汇总验证数量。",
    "duplicate_validation_ids": "收集重复的validation_id；最终必须为空。",
    "failed_validation_checks": "筛选最终register中所有FAIL记录，不能隐藏失败。",
}


def target_text(node: ast.AST) -> str:
    try:
        return ast.unparse(node)
    except Exception:
        return "当前变量"


def short_expression(node: ast.AST | None, limit: int = 105) -> str:
    if node is None:
        return "空值"
    try:
        text = re.sub(r"\s+", " ", ast.unparse(node)).strip()
    except Exception:
        return "当前表达式"
    return text if len(text) <= limit else text[: limit - 3] + "..."


def describe_statement(node: ast.AST) -> str | None:
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
        return FUNCTION_DESCRIPTIONS.get(
            node.name,
            f"定义函数 `{node.name}`，把这一组可重复逻辑封装起来供后续调用。",
        )
    if isinstance(node, ast.Assign):
        names = [target_text(t) for t in node.targets]
        first_simple = names[0] if len(names) == 1 else ""
        if first_simple in VARIABLE_DESCRIPTIONS:
            return VARIABLE_DESCRIPTIONS[first_simple]
        return f"计算并保存 `{', '.join(names)}`；右侧来源为 `{short_expression(node.value)}`。"
    if isinstance(node, ast.AnnAssign):
        name = target_text(node.target)
        return VARIABLE_DESCRIPTIONS.get(
            name,
            f"声明并计算 `{name}`，作为后续步骤的中间结果。",
        )
    if isinstance(node, ast.AugAssign):
        return f"更新 `{target_text(node.target)}`，把本次计算结果累加或合并到已有值。"
    if isinstance(node, ast.If):
        return f"检查条件 `{short_expression(node.test)}`；只有条件成立时才执行下一缩进代码块。"
    if isinstance(node, (ast.For, ast.AsyncFor)):
        return f"遍历 `{short_expression(node.iter)}`，每轮把当前元素赋给 `{target_text(node.target)}`。"
    if isinstance(node, ast.While):
        return f"条件 `{short_expression(node.test)}` 为真时重复执行下一代码块。"
    if isinstance(node, ast.Try):
        return "尝试执行容易发生格式或转换错误的代码；异常由后续处理逻辑解释。"
    if isinstance(node, ast.ExceptHandler):
        exc_name = short_expression(node.type) if node.type else "任意异常"
        return f"捕获 `{exc_name}`，把底层错误转成更清楚、带字段语境的失败信息。"
    if isinstance(node, ast.With):
        return "进入受控资源或上下文范围，并在代码块结束后自动完成清理。"
    if isinstance(node, ast.Return):
        return f"返回 `{short_expression(node.value)}`，作为当前函数的输出。"
    if isinstance(node, ast.Raise):
        return f"发现不符合规则的数据后立即抛出 `{short_expression(node.exc)}`，阻止错误结果继续传播。"
    if isinstance(node, ast.Assert):
        return f"断言 `{short_expression(node.test)}` 必须成立，否则停止运行并暴露数据问题。"
    if isinstance(node, ast.Expr):
        if isinstance(node.value, ast.Constant) and isinstance(node.value.value, str):
            return None
        expression = short_expression(node.value)
        if expression.startswith("show(") or expression.startswith("display("):
            return "显示本步骤的可审计证据，便于检查实际观测结果。"
        if expression.startswith("print("):
            return "打印完成状态和关键计数，作为Restart and Run All时的运行证据。"
        return f"执行 `{expression}`，触发当前步骤需要的函数调用或输出。"
    if isinstance(node, ast.Break):
        return "满足结束条件后退出当前循环。"
    if isinstance(node, ast.Continue):
        return "跳过本轮剩余步骤，继续处理下一条记录。"
    if isinstance(node, ast.Pass):
        return "保留空代码块，不执行额外操作。"
    return None


def statement_comments(source: str) -> dict[int, list[str]]:
    tree = ast.parse(source)
    comments: dict[int, list[str]] = {}
    seen: set[tuple[int, str]] = set()
    nodes: list[ast.AST] = []
    for node in ast.walk(tree):
        if isinstance(node, ast.stmt) or isinstance(node, ast.ExceptHandler):
            nodes.append(node)
    nodes.sort(key=lambda n: (getattr(n, "lineno", 0), getattr(n, "col_offset", 0)))
    for node in nodes:
        line = getattr(node, "lineno", None)
        if not line:
            continue
        description = describe_statement(node)
        if not description:
            continue
        key = (line, description)
        if key in seen:
            continue
        seen.add(key)
        comments.setdefault(line, []).append(description)
    return comments


def annotate_source(source: str, scope: str) -> str:
    original_lines = source.splitlines(keepends=True)
    comments = statement_comments(source)
    output_lines: list[str] = []

    first_code_line = next(
        (i for i, line in enumerate(original_lines, start=1) if line.strip() and not line.lstrip().startswith("#")),
        1,
    )
    comments.setdefault(first_code_line, []).insert(
        0,
        f"负责范围：{scope}",
    )
    comments[first_code_line].insert(
        1,
        "阅读方法：每条新增中文注释解释其下一条可执行语句；原代码、输出和执行编号均未修改。",
    )

    for line_number, line in enumerate(original_lines, start=1):
        if line_number in comments:
            indentation = line[: len(line) - len(line.lstrip(" \t"))]
            for explanation in comments[line_number]:
                output_lines.append(f"{indentation}# {MARKER} {explanation}\n")
        output_lines.append(line)
    return "".join(output_lines)


def annotate_task3_import(source: str) -> str:
    lines = source.splitlines(keepends=True)
    insert_at = next(
        i for i, line in enumerate(lines)
        if line.startswith("from Group050_text_functions import")
    )
    notes = [
        f"# {MARKER} 本单元导入固定的六函数Task 3接口；这里只说明本人负责的两个多语言函数，不认领其他成员函数。\n",
        f"# {MARKER} `build_latin_analysis` 从review_body_clean生成Latin-script分析文本；没有Latin字母时返回字面量`NaN`。\n",
        f"# {MARKER} `contains_non_latin_script` 检查Unicode字母脚本；出现非Latin字母时返回Python `True`。\n",
    ]
    return "".join(lines[:insert_at] + notes + lines[insert_at:])


def strip_added_notes(source: str) -> str:
    return "".join(
        line for line in source.splitlines(keepends=True)
        if MARKER not in line
    )


def verify(original: dict, annotated: dict) -> dict:
    if len(original["cells"]) != len(annotated["cells"]):
        raise AssertionError("Cell count changed")

    changed_cells = []
    comments_added = 0
    for index, (before, after) in enumerate(zip(original["cells"], annotated["cells"])):
        before_without_source = {k: v for k, v in before.items() if k != "source"}
        after_without_source = {k: v for k, v in after.items() if k != "source"}
        if before_without_source != after_without_source:
            raise AssertionError(f"Non-source content changed in cell {index}")

        before_source = "".join(before.get("source", []))
        after_source = "".join(after.get("source", []))
        if before_source != after_source:
            changed_cells.append(index)
            comments_added += after_source.count(MARKER)
            if strip_added_notes(after_source) != before_source:
                raise AssertionError(f"Code or pre-existing text changed in cell {index}")

    expected = sorted([16, *TARGET_CELLS])
    if changed_cells != expected:
        raise AssertionError(f"Unexpected changed cells: {changed_cells}; expected {expected}")

    if original.get("metadata") != annotated.get("metadata"):
        raise AssertionError("Notebook metadata changed")
    if original.get("nbformat") != annotated.get("nbformat"):
        raise AssertionError("nbformat changed")
    if original.get("nbformat_minor") != annotated.get("nbformat_minor"):
        raise AssertionError("nbformat_minor changed")

    return {
        "changed_cells": changed_cells,
        "comments_added": comments_added,
        "code_changes": 0,
        "output_changes": 0,
        "metadata_changes": 0,
    }


def main() -> None:
    original = json.loads(SOURCE.read_text(encoding="utf-8"))
    annotated = copy.deepcopy(original)

    cell16 = "".join(annotated["cells"][16].get("source", []))
    annotated["cells"][16]["source"] = annotate_task3_import(cell16).splitlines(keepends=True)

    for cell_index, scope in TARGET_CELLS.items():
        cell = annotated["cells"][cell_index]
        if cell.get("cell_type") != "code":
            raise AssertionError(f"Target cell {cell_index} is not code")
        source = "".join(cell.get("source", []))
        cell["source"] = annotate_source(source, scope).splitlines(keepends=True)

    report = verify(original, annotated)
    OUTPUT.write_text(
        json.dumps(annotated, ensure_ascii=False, indent=1) + "\n",
        encoding="utf-8",
    )

    reloaded = json.loads(OUTPUT.read_text(encoding="utf-8"))
    second_report = verify(original, reloaded)
    if report != second_report:
        raise AssertionError("Verification changed after writing and reloading")

    print(json.dumps({"output": str(OUTPUT), **report}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

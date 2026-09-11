import hashlib
import sys
import zipfile
from copy import copy
from pathlib import Path

from lxml import etree


W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
NS = {"w": W_NS}
XML_SPACE = "{http://www.w3.org/XML/1998/namespace}space"
EXPECTED_SHA256 = "2577cfe8f0cc7d997dbaaed81ea1e848b5ce0b98fe6d5a3f927068d3ede71286"


def qn(local: str) -> str:
    return f"{{{W_NS}}}{local}"


def paragraph_text(paragraph) -> str:
    return "".join(paragraph.xpath(".//w:t/text()", namespaces=NS))


def replace_body_paragraph(root, prefix: str, new_text: str) -> None:
    matches = [
        paragraph
        for paragraph in root.xpath("/w:document/w:body/w:p", namespaces=NS)
        if paragraph_text(paragraph).startswith(prefix)
    ]
    if len(matches) != 1:
        raise RuntimeError(f"Expected one paragraph beginning {prefix!r}; found {len(matches)}")
    text_nodes = matches[0].xpath(".//w:t", namespaces=NS)
    if not text_nodes:
        raise RuntimeError(f"Paragraph beginning {prefix!r} has no text node")
    text_nodes[0].text = new_text
    for node in text_nodes[1:]:
        node.text = ""


def set_cell_lines(cell, lines) -> None:
    paragraphs = cell.xpath("./w:p", namespaces=NS)
    if not paragraphs:
        paragraph = etree.SubElement(cell, qn("p"))
    else:
        paragraph = paragraphs[0]

    for run in paragraph.xpath("./w:r", namespaces=NS):
        paragraph.remove(run)

    run = etree.SubElement(paragraph, qn("r"))
    for index, line in enumerate(lines):
        if index:
            etree.SubElement(run, qn("br"))
        text = etree.SubElement(run, qn("t"))
        text.text = line
        if line[:1].isspace() or line[-1:].isspace():
            text.set(XML_SPACE, "preserve")


def table_cell(root, table_index: int, row_index: int, col_index: int):
    tables = root.xpath("/w:document/w:body/w:tbl", namespaces=NS)
    table = tables[table_index]
    rows = table.xpath("./w:tr", namespaces=NS)
    cells = rows[row_index].xpath("./w:tc", namespaces=NS)
    return cells[col_index]


def main(reference: Path, output: Path) -> None:
    actual_sha = hashlib.sha256(reference.read_bytes()).hexdigest()
    if actual_sha != EXPECTED_SHA256:
        raise RuntimeError(f"Template hash mismatch: {actual_sha}")

    with zipfile.ZipFile(reference, "r") as source:
        document_xml = source.read("word/document.xml")
        parser = etree.XMLParser(remove_blank_text=False, resolve_entities=False)
        root = etree.fromstring(document_xml, parser)

        replace_body_paragraph(root, "Group Number:", "Group Number: Group050")
        replace_body_paragraph(
            root,
            "Submission:",
            "Submission: Group050_A1_submission.zip and Group050_EDA.pdf",
        )
        replace_body_paragraph(
            root,
            "Convert the signed declaration",
            "Convert the signed declaration to Group050_AI_declaration.pdf. When conversational AI was used, include Group050_AI_index.pdf and every complete export in AI_records/ inside Group050_A1_submission.zip.",
        )

        set_cell_lines(table_cell(root, 0, 1, 1), ["Keshu Zhang"])
        set_cell_lines(table_cell(root, 0, 1, 2), ["36436763"])

        set_cell_lines(
            table_cell(root, 1, 1, 1),
            [
                "Keshu Zhang",
                "OpenAI Codex (GPT-5)",
                "AI01_Keshu.pdf",
            ],
        )
        set_cell_lines(
            table_cell(root, 1, 1, 2),
            [
                "Code review and concise drafting for my assigned Products/Product Reviews scope: Tasks 2, 3.4 and 4; Figures 7-8; Findings 9-10; MLQ 4-5. Files: Group050_solution.ipynb, Group050_text_functions.py and Group050_EDA.ipynb/report."
            ],
        )
        set_cell_lines(
            table_cell(root, 1, 1, 3),
            [
                "Source/data-dictionary comparison; public text-function tests; 20 passing validations; offline rerun; Review-Product join check: 7,000 rows, 0 orphans and 1.0 multiplication."
            ],
        )

        edited_xml = etree.tostring(
            root,
            xml_declaration=True,
            encoding="UTF-8",
            standalone=True,
        )

        output.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(output, "w") as target:
            for info in source.infolist():
                data = edited_xml if info.filename == "word/document.xml" else source.read(info.filename)
                target.writestr(copy(info), data)

    print(output)


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]))

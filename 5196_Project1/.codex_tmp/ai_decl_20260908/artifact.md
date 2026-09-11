# Reference

- Reference DOCX: `C:\monash\Monash_Project\5196_Project1\Group050_A1\templates\A1_AI_use_declaration_template.docx`
- SHA-256: `2577cfe8f0cc7d997dbaaed81ea1e848b5ce0b98fe6d5a3f927068d3ede71286`
- Page count: 3
- Section count: 1
- Reference render: `C:\monash\Monash_Project\5196_Project1\.codex_tmp\ai_decl_20260908\template-reference-render`
- Style evidence: `C:\monash\Monash_Project\5196_Project1\.codex_tmp\ai_decl_20260908\template-style-evidence.json`

# Page system

- A4 portrait, 8.2701 by 11.6903 inches.
- Margins: 1 inch on all sides.
- Header and footer distances: 0.5 inch; no visible header or footer.
- One section, no different first page and no odd/even-page variation.
- Page 1 contains the title, notice, group declaration and the beginning of the signature table. Page 2 continues the signature table and its note. Page 3 contains the AI records and verification section with two tables.

# Typography and components

- Title uses the Word Title style, 25 pt, black, left aligned, with 12 pt after and 1.25 line spacing.
- Main headings use the existing Heading 2 style. Page 3 section headings use direct Arial formatting in dark blue `17365D` at 16 pt, 12.5 pt or 11.5 pt as present in the source.
- Body text is primarily Arial 10.5 pt with existing paragraph spacing and indents preserved.
- Horizontal gray rules, paragraph borders and table borders are source furniture and must remain unchanged.
- The signature table spans pages 1 and 2. It has five columns and five editable member rows.
- The conversational AI table has four columns measuring approximately 0.625, 1.7361, 2.1528 and 1.9861 inches. Its light blue header, borders, cell margins, row behavior and existing blank rows must be preserved.
- The inline-completion table has four columns measuring approximately 1.4583, 1.6667, 1.6319 and 1.7431 inches. It remains blank because the declared use has a conversational record.

# Content flow

1. Preserve the full Important Notice and Group Declaration.
2. Fill the group number and exact submission filenames.
3. Fill only Keshu Zhang's printed name and student ID in signature row 1; leave signature and date blank and preserve rows for other members.
4. Fill one concise AI-01 conversational record covering the related uses in Keshu Zhang's assigned scope.
5. Preserve AI-02 and AI-03 for any additional group records and leave the inline-completion register blank.

# Slot map

- `word/document.xml`, body paragraph containing `Group Number:`: replace placeholder with `Group050`.
- `word/document.xml`, body paragraph containing `Submission:`: replace `GroupNNN` with `Group050` in both filenames.
- `word/document.xml`, body paragraph beginning `Convert the signed declaration`: replace all three `GroupNNN` placeholders with `Group050`.
- First body table, row 1, column 1: insert `Keshu Zhang`.
- First body table, row 1, column 2: insert `36436763`.
- First body table, row 1, columns 3 and 4: preserve blank for handwritten signature and date.
- Second body table, row 1, column 1: insert member, tool/model and the chosen complete export filename.
- Second body table, row 1, column 2: insert purpose and affected work limited to the assigned Products/Product Reviews scope.
- Second body table, row 1, column 3: insert concise non-AI verification evidence.
- All other body paragraphs, cells, styles, relationships and package parts are preserve-only.

# Package preservation

Only `word/document.xml` is editable. Preserve these parts and relationships byte-for-byte:

- `word/numbering.xml`, 7922 bytes, `463f5272e455ce36e7a7499d6243cdd591ab5e610d0ef7851a4a1812e4bd5771`
- `word/settings.xml`, 2152 bytes, `26f2853fde05b88d4b0a9da0bb016d56a896901f60c9272dddf33c3f3fa61e4a`
- `word/fontTable.xml`, 1719 bytes, `737a2c4505c65fcb20fe02f634fd01b6f57f2990fafa86fdb4b5d5cb5a87abe5`
- `word/styles.xml`, 5611 bytes, `669c31632687620bc4f400358d1b7fac111c4398366ec0bfda5e5184542382cb`
- `word/_rels/document.xml.rels`, 812 bytes, `2f88ba313d7d77c73d3737c12338686a29f13f029e69a783e026da83a7dd891c`
- `_rels/.rels`, 298 bytes, `1cc87395d4a229f21c23af406724de12dd9454071925f983e4b648a7b2be8cc5`
- `word/theme/theme1.xml`, 7643 bytes, `b2295d3198893d2c03f5e584c749a15751b798aefdcd9bee2889f13903d68cb2`
- `[Content_Types].xml`, 1172 bytes, `70100a2bc0a6ff5fcce135d1b8ab0d9f108c4cdd39ead3ce88eda6ca2b6d7581`

# Fidelity gates

- The retained template must still match its recorded SHA-256.
- Preserve one section, A4 portrait geometry, the title/notice/declaration wording, table structures, blue headers, borders and all blank group-use slots.
- The final may gain pagination only if the filled AI-01 row cannot fit without clipping; text must not be shrunk below the source body size.
- Render every final page and inspect at 100 percent. No clipping, overlaps, broken table borders, missing text or unexplained changes outside the filled slots are acceptable.
- Compare all preserve-only package parts against the baseline hashes before delivery.

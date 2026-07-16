"""Export shareable Markdown and PDF workshop materials.

This script creates:
- lesson.md from lesson.Rmd
- individual PDFs for the lesson/setup/data/troubleshooting materials
- a combined participant handout PDF
- a PDF version of the intro slides if slide PNG previews are available
"""

from __future__ import annotations

import re
from pathlib import Path

from pypdf import PdfReader, PdfWriter
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    Image,
    ListFlowable,
    ListItem,
    PageBreak,
    Paragraph,
    Preformatted,
    SimpleDocTemplate,
    Spacer,
)


ROOT = Path(__file__).resolve().parents[1]
PDF_DIR = ROOT / "materials_pdf"
SLIDE_PREVIEW_DIR = Path("/private/tmp/codex-presentations/sdm-dengue-workshop/tmp/qa")


def strip_rmd_to_md(source: Path, target: Path) -> None:
    text = source.read_text(encoding="utf-8")
    text = re.sub(r"\A---\n.*?\n---\n", "", text, flags=re.S)
    text = re.sub(r"```\{r[^}]*\}", "```r", text)
    target.write_text(text.strip() + "\n", encoding="utf-8")


def markdown_blocks(text: str):
    in_code = False
    code_lines: list[str] = []
    list_items: list[str] = []

    def flush_list():
        nonlocal list_items
        if list_items:
            items = list_items
            list_items = []
            return ("list", items)
        return None

    for raw_line in text.splitlines():
        line = raw_line.rstrip()

        if line.startswith("```"):
            if in_code:
                yield ("code", "\n".join(code_lines))
                code_lines = []
                in_code = False
            else:
                pending = flush_list()
                if pending:
                    yield pending
                in_code = True
            continue

        if in_code:
            code_lines.append(line)
            continue

        if not line.strip():
            pending = flush_list()
            if pending:
                yield pending
            yield ("space", "")
            continue

        heading = re.match(r"^(#{1,3})\s+(.*)$", line)
        if heading:
            pending = flush_list()
            if pending:
                yield pending
            yield (f"h{len(heading.group(1))}", heading.group(2).strip())
            continue

        bullet = re.match(r"^\s*[-*]\s+(.*)$", line)
        if bullet:
            list_items.append(bullet.group(1).strip())
            continue

        pending = flush_list()
        if pending:
            yield pending
        yield ("p", line.strip())

    pending = flush_list()
    if pending:
        yield pending


def clean_inline(text: str) -> str:
    text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    text = re.sub(r"`([^`]+)`", r"<font face='Courier'>\1</font>", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"\*([^*]+)\*", r"<i>\1</i>", text)
    return text


def make_styles():
    styles = getSampleStyleSheet()
    styles.add(
        ParagraphStyle(
            name="WorkshopTitle",
            parent=styles["Title"],
            fontName="Helvetica-Bold",
            fontSize=24,
            leading=29,
            textColor=colors.HexColor("#0B3D3A"),
            alignment=TA_LEFT,
            spaceAfter=18,
        )
    )
    styles.add(
        ParagraphStyle(
            name="H1Workshop",
            parent=styles["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=18,
            leading=23,
            textColor=colors.HexColor("#0B3D3A"),
            spaceBefore=16,
            spaceAfter=8,
        )
    )
    styles.add(
        ParagraphStyle(
            name="H2Workshop",
            parent=styles["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=14,
            leading=18,
            textColor=colors.HexColor("#1B7F72"),
            spaceBefore=12,
            spaceAfter=6,
        )
    )
    styles.add(
        ParagraphStyle(
            name="BodyWorkshop",
            parent=styles["BodyText"],
            fontName="Helvetica",
            fontSize=10.5,
            leading=15,
            textColor=colors.HexColor("#1F2933"),
            spaceAfter=6,
        )
    )
    styles.add(
        ParagraphStyle(
            name="CodeWorkshop",
            parent=styles["Code"],
            fontName="Courier",
            fontSize=8.3,
            leading=10.5,
            backColor=colors.HexColor("#EEF5F2"),
            borderPadding=6,
            leftIndent=0,
            rightIndent=0,
            spaceBefore=4,
            spaceAfter=8,
        )
    )
    styles.add(
        ParagraphStyle(
            name="Footer",
            parent=styles["BodyText"],
            fontSize=8,
            alignment=TA_CENTER,
            textColor=colors.HexColor("#5F6F6A"),
        )
    )
    return styles


def footer(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(colors.HexColor("#5F6F6A"))
    canvas.setFont("Helvetica", 8)
    canvas.drawCentredString(letter[0] / 2, 0.38 * inch, f"SDM dengue vector workshop | page {doc.page}")
    canvas.restoreState()


def markdown_to_pdf(md_path: Path, pdf_path: Path, title: str) -> None:
    styles = make_styles()
    story = [Paragraph(title, styles["WorkshopTitle"])]
    text = md_path.read_text(encoding="utf-8")

    for kind, value in markdown_blocks(text):
        if kind == "space":
            story.append(Spacer(1, 4))
        elif kind == "h1":
            story.append(Paragraph(clean_inline(value), styles["H1Workshop"]))
        elif kind in {"h2", "h3"}:
            story.append(Paragraph(clean_inline(value), styles["H2Workshop"]))
        elif kind == "p":
            story.append(Paragraph(clean_inline(value), styles["BodyWorkshop"]))
        elif kind == "code":
            story.append(Preformatted(value, styles["CodeWorkshop"], maxLineLength=92))
        elif kind == "list":
            flowables = [
                ListItem(Paragraph(clean_inline(item), styles["BodyWorkshop"]), leftIndent=14)
                for item in value
            ]
            story.append(ListFlowable(flowables, bulletType="bullet", leftIndent=18))

    doc = SimpleDocTemplate(
        str(pdf_path),
        pagesize=letter,
        rightMargin=0.7 * inch,
        leftMargin=0.7 * inch,
        topMargin=0.7 * inch,
        bottomMargin=0.7 * inch,
        title=title,
        author="SDM dengue vector workshop",
    )
    doc.build(story, onFirstPage=footer, onLaterPages=footer)


def combine_pdfs(paths: list[Path], output: Path) -> None:
    writer = PdfWriter()
    for path in paths:
        reader = PdfReader(str(path))
        for page in reader.pages:
            writer.add_page(page)
    with output.open("wb") as handle:
        writer.write(handle)


def slides_to_pdf(output: Path) -> bool:
    slide_pngs = sorted(SLIDE_PREVIEW_DIR.glob("slide-*.png"))
    if not slide_pngs:
        return False

    doc = SimpleDocTemplate(
        str(output),
        pagesize=landscape(letter),
        rightMargin=0.25 * inch,
        leftMargin=0.25 * inch,
        topMargin=0.25 * inch,
        bottomMargin=0.25 * inch,
        title="Intro SDM Dengue Brazil Slides",
    )

    max_width = landscape(letter)[0] - 0.5 * inch
    max_height = landscape(letter)[1] - 0.5 * inch
    story = []

    for index, png in enumerate(slide_pngs):
        image = Image(str(png))
        scale = min(max_width / image.imageWidth, max_height / image.imageHeight)
        image.drawWidth = image.imageWidth * scale
        image.drawHeight = image.imageHeight * scale
        image.hAlign = "CENTER"
        story.append(image)
        if index != len(slide_pngs) - 1:
            story.append(PageBreak())

    doc.build(story)
    return True


def assert_pdf_ok(path: Path) -> int:
    reader = PdfReader(str(path))
    if len(reader.pages) == 0:
        raise RuntimeError(f"{path} has no pages")
    return len(reader.pages)


def main() -> None:
    PDF_DIR.mkdir(exist_ok=True)

    lesson_md = ROOT / "lesson.md"
    strip_rmd_to_md(ROOT / "lesson.Rmd", lesson_md)

    md_jobs = [
        (ROOT / "README_setup.md", PDF_DIR / "README_setup.pdf", "Dengue Vector SDM Workshop: Setup Guide"),
        (lesson_md, PDF_DIR / "lesson.pdf", "Mapping Dengue Vector Suitability In Brazil"),
        (ROOT / "data_sources.md", PDF_DIR / "data_sources.pdf", "Data Sources And Provenance"),
        (ROOT / "troubleshooting" / "install_help.md", PDF_DIR / "install_help.pdf", "Troubleshooting Package Installation"),
    ]

    created = []
    for md_path, pdf_path, title in md_jobs:
        markdown_to_pdf(md_path, pdf_path, title)
        created.append(pdf_path)

    combine_pdfs(created, PDF_DIR / "participant_handout_combined.pdf")

    slides_pdf = PDF_DIR / "intro_sdm_dengue_brazil_slides.pdf"
    slides_created = slides_to_pdf(slides_pdf)

    check_paths = created + [PDF_DIR / "participant_handout_combined.pdf"]
    if slides_created:
        check_paths.append(slides_pdf)

    for path in check_paths:
        pages = assert_pdf_ok(path)
        print(f"{path.relative_to(ROOT)}: {pages} pages")

    print(f"Created Markdown lesson: {lesson_md.relative_to(ROOT)}")


if __name__ == "__main__":
    main()

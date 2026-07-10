---
name: pdf-to-jpg-zip
description: Convert PDF files into per-page JPG folders and zip the expanded folder. Use when the user asks to split a PDF into JPG images, expand the pages into a directory, or package the extracted JPG folder into a ZIP archive.
---

# PDF to JPG ZIP

## Overview

Use this skill for PDF-to-image extraction jobs that should end with a JPG folder and a ZIP archive.

## Standard Workflow

1. Locate the source PDF and derive the output folder from the PDF name.
2. Create a sibling folder with the `_jpg` suffix.
3. Render each page to JPG with `pdftoppm`.
4. Verify the page count in the output folder.
5. Zip the folder as `<folder>.zip` with the folder preserved at the archive root.

## Recommended Script

Use `scripts/pdf_to_jpg_zip.ps1` for repeatable jobs.

Preferred invocation:

```powershell
.\scripts\pdf_to_jpg_zip.ps1 -PdfPath "path\to\book.pdf"
```

Useful options:

```powershell
.\scripts\pdf_to_jpg_zip.ps1 -PdfPath "path\to\book.pdf" -Dpi 200
.\scripts\pdf_to_jpg_zip.ps1 -PdfPath "path\to\book.pdf" -OutputDir "path\to\book_jpg"
.\scripts\pdf_to_jpg_zip.ps1 -PdfPath "path\to\book.pdf" -MaxPages 3
```

## Operational Notes

- Use literal paths for file names that contain spaces, brackets, or Japanese text.
- Prefer `pdfinfo` to confirm the page count before or after rendering.
- Prefer `Compress-Archive -LiteralPath` on Windows so special characters are preserved correctly.
- If `pdftoppm` is not on `PATH`, resolve it from the local WinGet Poppler install or prompt for a Poppler install before retrying.

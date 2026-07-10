---
name: zip-deep-image-folders
description: Archive the deepest folders that contain image files into ZIPs placed at the workspace root, then optionally copy those root ZIPs into a work folder, rename them by parsed volume numbers such as `v01`, `2s`, or `3` into `01巻` form, and collect them in a summary folder. Use when Codex needs to package nested image folders and normalize manga-volume ZIP names without modifying the original root ZIPs.
---

# Zip Deep Image Folders

Use this skill when a tree contains leaf folders with images and each leaf folder should become a ZIP at the root of the workspace. Use the same script again when the root ZIPs should be copied, renamed by volume number, and moved into a summary folder while leaving the original root ZIPs untouched.

## Standard Workflow

1. Find leaf directories under the target root.
2. Keep only leaf directories that contain image files.
3. Create one ZIP per matching folder at the root of the tree.
4. Name the ZIP from the folder's relative path, replacing path separators with underscores.
5. When needed, copy the root ZIPs into a work directory, rename them to `<title> 01巻.zip` style names, add `-a`, `-b` for duplicate volumes, and move the renamed copies into a summary folder.
6. Leave the source folders and original root ZIPs in place unless the user explicitly asks for cleanup.

## Preferred Script

Use `scripts/zip_leaf_image_folders.ps1` for repeatable jobs.

Create root ZIPs only:

```powershell
.\scripts\zip_leaf_image_folders.ps1 -RootPath "D:\path\to\collection"
```

Create root ZIPs, then organize copied ZIPs by volume:

```powershell
.\scripts\zip_leaf_image_folders.ps1 `
  -RootPath "D:\path\to\collection" `
  -OrganizeRootZips `
  -Title "異世界AV撮影隊 リマスター" `
  -SeriesSortName "ｲｾｶｲｴｰﾌﾞｲｻﾂｴｲﾀｲﾘﾏｽﾀｰ"
```

Useful options:

```powershell
.\scripts\zip_leaf_image_folders.ps1 -RootPath "D:\path\to\collection" -DryRun
.\scripts\zip_leaf_image_folders.ps1 -RootPath "D:\path\to\collection" -Force
.\scripts\zip_leaf_image_folders.ps1 -RootPath "D:\path\to\collection" -ImageExtensions jpg,png,webp
.\scripts\zip_leaf_image_folders.ps1 -RootPath "D:\path\to\collection" -OrganizeRootZips -AuthorName "Author"
.\scripts\zip_leaf_image_folders.ps1 -RootPath "D:\path\to\collection" -OrganizeRootZips -SummaryFolderName "custom-folder"
```

## Volume Rename Rules

- Parse the volume number from the end of the ZIP file name.
- Accept patterns such as `v01.zip`, `2s.zip`, and `3.zip`.
- Rename to `01巻`, `02巻`, `03巻`.
- If multiple ZIPs map to the same volume, append `-a`, `-b`, and so on.
- Copy root ZIPs into the work directory before renaming so the originals remain at the root.

## Title And Summary Folder Rules

- Prefer `-Title` when the book title is already known.
- If `-Title` is omitted, infer it from the copied root ZIP names after removing common noise prefixes such as `MANGA-ZIP.APP_` and the trailing volume token.
- Prefer `-SeriesSortName` when the summary folder needs a specific reading or half-width representation.
- If `-SeriesSortName` is omitted, the script uses a best-effort narrow-width conversion for existing kana and ASCII only.
- Build the summary folder name as `<series-sort-name>[<author-name>]<title>`.
- Use an empty `[]` block when the author is unknown.

## Operational Notes

- Use `-LiteralPath` and literal strings for paths with spaces, Japanese text, or brackets.
- Treat a leaf directory as a directory with no child directories.
- Only zip folders that contain at least one image file.
- Write the ZIP to the root directory, not beside the source folder.
- Overwrite an existing ZIP or summary ZIP only when `-Force` is set.
- If title inference produces multiple equally likely titles, rerun with `-Title`.

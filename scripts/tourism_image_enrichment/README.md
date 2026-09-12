# UniSafeX Tourism Image Enrichment

This folder prepares the 3,698 monument workbook for a scalable image pipeline.

The workbook tool:

- Keeps existing `Image_URL_1` and `Image_URL_2`.
- Adds image slots up to `Image_URL_8`.
- Adds alt text and disclosure columns for production safety.
- Creates `Image_Generation_Queue` with six AI-ready prompts per monument.
- Creates `Image_Automation_Config` and `README_Image_Automation` sheets.

It does not invent final image URLs. The queue is designed for Google Apps Script,
Google Drive, or a future Supabase Edge Function to generate/upload images and
write back real shareable URLs.

## Run

```bash
/Users/ak/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  scripts/tourism_image_enrichment/enrich_monument_workbook.py \
  "/Users/ak/Library/Containers/net.whatsapp.WhatsApp/Data/tmp/documents/7FEEB158-AFF5-423B-8B26-88AB13317122/India_3698_Monuments_Full_Profile (4).xlsx" \
  outputs/tourism_image_enrichment/India_3698_Monuments_Full_Profile_enriched_images.xlsx
```

## Automation Flow

1. Admin adds/updates monument rows in Google Sheet.
2. Apps Script reads `Image_Generation_Queue`.
3. Script processes rows with `Status = Pending`.
4. Script calls the configured AI image endpoint.
5. Script stores generated images in Google Drive.
6. Script writes the shareable image URL to `Result_Image_URL`.
7. Admin reviews images, then copies approved links into `Image_URL_3` to `Image_URL_8`.

## Security

- Do not store API keys in the workbook.
- Store `IMAGE_API_ENDPOINT`, `IMAGE_API_KEY`, and `DRIVE_FOLDER_ID` in Apps Script
  Script Properties.
- Keep AI-generated images labelled until manually verified.
- Do not use generated visuals for official monument facts unless reviewed.

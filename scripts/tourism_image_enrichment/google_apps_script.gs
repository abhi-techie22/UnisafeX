/**
 * UniSafeX tourism image automation template.
 *
 * Store secrets in Apps Script:
 * Project Settings -> Script properties:
 *   IMAGE_API_ENDPOINT=https://your-image-api.example.com/generate
 *   IMAGE_API_KEY=your_secret_key
 *   DRIVE_FOLDER_ID=google_drive_root_folder_id
 *
 * Do not put API keys inside the spreadsheet.
 */

const QUEUE_SHEET_NAME = 'Image_Generation_Queue';
const STATUS_PENDING = 'Pending';
const STATUS_PROCESSING = 'Processing';
const STATUS_DONE = 'Done';
const STATUS_FAILED = 'Failed';

function processPendingMonumentImages() {
  const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = spreadsheet.getSheetByName(QUEUE_SHEET_NAME);
  if (!sheet) {
    throw new Error(`Missing sheet: ${QUEUE_SHEET_NAME}`);
  }

  const properties = PropertiesService.getScriptProperties();
  const endpoint = properties.getProperty('IMAGE_API_ENDPOINT');
  const apiKey = properties.getProperty('IMAGE_API_KEY');
  const rootFolderId = properties.getProperty('DRIVE_FOLDER_ID');

  if (!endpoint || !apiKey || !rootFolderId) {
    throw new Error('Missing IMAGE_API_ENDPOINT, IMAGE_API_KEY, or DRIVE_FOLDER_ID in Script Properties.');
  }

  const values = sheet.getDataRange().getValues();
  const headers = values[0];
  const col = indexByHeader_(headers);
  const maxRowsPerRun = 20;
  let processed = 0;

  for (let rowIndex = 1; rowIndex < values.length; rowIndex += 1) {
    const row = values[rowIndex];
    if (row[col.Status] !== STATUS_PENDING) {
      continue;
    }
    if (processed >= maxRowsPerRun) {
      break;
    }

    const sheetRow = rowIndex + 1;
    try {
      sheet.getRange(sheetRow, col.Status + 1).setValue(STATUS_PROCESSING);
      SpreadsheetApp.flush();

      const imageBlob = callImageApi_(endpoint, apiKey, {
        prompt: row[col.Prompt],
        negative_prompt: row[col.Negative_Prompt],
        output_file_name: row[col.Output_File_Name],
        image_type: row[col.Image_Type],
        monument_name: row[col.Monument_Name],
        global_id: row[col.Global_ID],
      });

      const folder = ensureFolder_(rootFolderId, String(row[col.Global_ID]));
      const file = folder.createFile(imageBlob).setName(row[col.Output_File_Name]);
      file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);

      sheet.getRange(sheetRow, col.Result_Image_URL + 1).setValue(file.getUrl());
      sheet.getRange(sheetRow, col.Status + 1).setValue(STATUS_DONE);
      processed += 1;
    } catch (error) {
      sheet.getRange(sheetRow, col.Status + 1).setValue(STATUS_FAILED);
      sheet.getRange(sheetRow, col.Result_Image_URL + 1).setValue(String(error));
    }
  }
}

function indexByHeader_(headers) {
  const map = {};
  headers.forEach((header, index) => {
    map[String(header).trim()] = index;
  });
  return map;
}

function callImageApi_(endpoint, apiKey, payload) {
  const response = UrlFetchApp.fetch(endpoint, {
    method: 'post',
    contentType: 'application/json',
    headers: {
      Authorization: `Bearer ${apiKey}`,
    },
    payload: JSON.stringify(payload),
    muteHttpExceptions: true,
  });

  const status = response.getResponseCode();
  if (status < 200 || status >= 300) {
    throw new Error(`Image API failed: ${status} ${response.getContentText().slice(0, 500)}`);
  }

  const contentType = response.getHeaders()['Content-Type'] || 'image/jpeg';
  return response.getBlob().setContentType(contentType);
}

function ensureFolder_(rootFolderId, childName) {
  const root = DriveApp.getFolderById(rootFolderId);
  const folders = root.getFoldersByName(childName);
  if (folders.hasNext()) {
    return folders.next();
  }
  return root.createFolder(childName);
}

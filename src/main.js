// Google Sheet ID
const SHEET_ID = '13CMolEbu5D9yC_69G-90QPw9BU_zAj96xpbmipcH-TY';
const SHEET_NAME = 'sheet1';

function doGet(e) {
  const action = e.parameter.action;

  // 處理訂購頁面
  if (action === 'order') {
    const githubRawUrl = 'https://github.com/chyuanwei/ai-proj-dev/raw/dev/src/order.html';

    try {
      const response = UrlFetchApp.fetch(githubRawUrl);
      const htmlContent = response.getContentText('UTF-8');
      return HtmlService.createHtmlOutput(htmlContent);
    } catch (error) {
      return HtmlService.createHtmlOutput(
        '<h1>錯誤</h1><p>無法從 GitHub 載入訂購頁面：' + error.toString() + '</p>'
      );
    }
  }

  // 處理確認頁面
  if (action === 'confirm') {
    const githubRawUrl = 'https://github.com/chyuanwei/ai-proj-dev/raw/dev/src/confirm.html';

    try {
      const response = UrlFetchApp.fetch(githubRawUrl);
      const htmlContent = response.getContentText('UTF-8');
      return HtmlService.createHtmlOutput(htmlContent);
    } catch (error) {
      return HtmlService.createHtmlOutput(
        '<h1>錯誤</h1><p>無法從 GitHub 載入確認頁面：' + error.toString() + '</p>'
      );
    }
  }

  // 處理獲取訂購資訊
  if (action === 'getOrder') {
    const orderId = e.parameter.id;
    if (!orderId) {
      return ContentService
        .createTextOutput(JSON.stringify({ success: false, message: '缺少訂購編號' }))
        .setMimeType(ContentService.MimeType.JSON);
    }

    try {
      const order = getOrderById(orderId);
      if (order) {
        return ContentService
          .createTextOutput(JSON.stringify({ success: true, order: order }))
          .setMimeType(ContentService.MimeType.JSON);
      } else {
        return ContentService
          .createTextOutput(JSON.stringify({ success: false, message: '找不到訂購記錄' }))
          .setMimeType(ContentService.MimeType.JSON);
      }
    } catch (error) {
      return ContentService
        .createTextOutput(JSON.stringify({ success: false, message: '獲取訂購資訊失敗：' + error.toString() }))
        .setMimeType(ContentService.MimeType.JSON);
    }
  }

  // 預設頁面 (從 GitHub 加載 index.html)
  const githubRawUrl = 'https://github.com/chyuanwei/ai-proj-dev/raw/dev/src/index.html';

  try {
    const response = UrlFetchApp.fetch(githubRawUrl);
    const htmlContent = response.getContentText('UTF-8');
    return HtmlService.createHtmlOutput(htmlContent);
  } catch (error) {
    return HtmlService.createHtmlOutput(
      '<h1>錯誤</h1><p>無法從 GitHub 載入預設頁面：' + error.toString() + '</p>'
    );
  }
}

function doPost(e) {
  const action = e.parameter.action || (e.postData ? JSON.parse(e.postData.contents).action : null);

  // 處理訂購提交
  if (action === 'submitOrder') {
    try {
      let data;
      if (e.postData) {
        data = JSON.parse(e.postData.contents);
      } else {
        // 處理表單數據
        data = {
          orderer: e.parameter.orderer,
          products: []
        };

        const productNames = e.parameter['productName[]'];
        const quantities = e.parameter['quantity[]'];

        if (Array.isArray(productNames)) {
          for (let i = 0; i < productNames.length; i++) {
            data.products.push({
              name: productNames[i],
              quantity: quantities[i]
            });
          }
        } else {
          data.products.push({
            name: productNames,
            quantity: quantities
          });
        }
      }

      // 驗證數據
      if (!data.orderer || !data.products || data.products.length === 0) {
        return ContentService
          .createTextOutput(JSON.stringify({ success: false, message: '缺少必要欄位' }))
          .setMimeType(ContentService.MimeType.JSON);
      }

      // 生成訂購編號
      const orderId = generateOrderId();

      // 儲存到 Google Sheet
      const result = saveOrderToSheet(orderId, data);

      if (result.success) {
        return ContentService
          .createTextOutput(JSON.stringify({ success: true, id: orderId, message: '訂購成功' }))
          .setMimeType(ContentService.MimeType.JSON);
      } else {
        return ContentService
          .createTextOutput(JSON.stringify({ success: false, message: result.message }))
          .setMimeType(ContentService.MimeType.JSON);
      }
    } catch (error) {
      return ContentService
        .createTextOutput(JSON.stringify({ success: false, message: '處理訂購時發生錯誤：' + error.toString() }))
        .setMimeType(ContentService.MimeType.JSON);
    }
  }

  return ContentService
    .createTextOutput(JSON.stringify({ success: false, message: '未知的操作' }))
    .setMimeType(ContentService.MimeType.JSON);
}

// 生成訂購編號
function generateOrderId() {
  const timestamp = new Date().getTime();
  const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
  return 'ORD-' + timestamp + '-' + random;
}

// 儲存訂購到 Google Sheet
function saveOrderToSheet(orderId, data) {
  try {
    const spreadsheet = SpreadsheetApp.openById(SHEET_ID);
    const sheet = spreadsheet.getSheetByName(SHEET_NAME);

    if (!sheet) {
      return { success: false, message: '找不到工作表：' + SHEET_NAME };
    }

    // 如果是空工作表，添加標題行
    if (sheet.getLastRow() === 0) {
      sheet.appendRow(['訂購編號', '訂購人', '產品名稱', '數量', '訂購時間']);
    }

    const timestamp = new Date().toLocaleString('zh-TW');

    // 為每個產品添加一行
    data.products.forEach(product => {
      sheet.appendRow([
        orderId,
        data.orderer,
        product.name,
        product.quantity,
        timestamp
      ]);
    });

    return { success: true };
  } catch (error) {
    return { success: false, message: '儲存到 Google Sheet 失敗：' + error.toString() };
  }
}

// 根據訂購編號獲取訂購資訊
function getOrderById(orderId) {
  try {
    const spreadsheet = SpreadsheetApp.openById(SHEET_ID);
    const sheet = spreadsheet.getSheetByName(SHEET_NAME);

    if (!sheet) {
      return null;
    }

    const data = sheet.getDataRange().getValues();

    // 找到對應的訂購記錄
    const orderRows = data.filter(row => row[0] === orderId);

    if (orderRows.length === 0) {
      return null;
    }

    const firstRow = orderRows[0];
    const order = {
      id: firstRow[0],
      orderer: firstRow[1],
      timestamp: firstRow[4],
      products: orderRows.map(row => ({
        name: row[2],
        quantity: row[3]
      }))
    };

    return order;
  } catch (error) {
    console.error('獲取訂購資訊失敗：', error);
    return null;
  }
}

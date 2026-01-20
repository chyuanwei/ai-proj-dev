function doGet() {
  // GitHub 上 index.html 的原始文件 URL
  const githubRawUrl = 'https://github.com/chyuanwei/ai-proj-dev/raw/dev/src/index.html';
  
  try {
    // 尝试从 GitHub 获取 HTML 内容
    const response = UrlFetchApp.fetch(githubRawUrl);
    // 明确指定 UTF-8 编码以避免乱码
    const htmlContent = response.getContentText('UTF-8');
    
    // 返回 GitHub 上的 HTML 输出
    return HtmlService.createHtmlOutput(htmlContent);
  } catch (error) {
    // 如果 GitHub 获取失败，使用 GAS 本地的 index.html 作为备用
    try {
      return HtmlService.createHtmlOutputFromFile('index');
    } catch (fallbackError) {
      // 如果本地文件也失败，返回错误信息
      return HtmlService.createHtmlOutput(
        '<h1>錯誤</h1><p>無法載入 HTML 檔案!：' + error.toString() + '</p>'
      );
    }
  }
}

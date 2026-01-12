/*
 * This script counts unique values in a specified column, ignoring duplicates.
 * This script does not affect any pre-existing data in the workbook.
 */
function main(
  workbook: ExcelScript.Workbook,
  sheetName: string = "Sheet1",
  columnLetter: string = "C"
): number {
  // Get the worksheet named "Sheet1".
  const sheet = workbook.getWorksheet(sheetName);

  // Get the entire data range.
  const range = sheet.getUsedRange(true);

  // If the used range is empty, end the script.
  if (!range) {
    console.log("No data on this sheet.");
    return 0;
  }

  // Get the column index (A=0, B=1, C=2, etc.)
  const columnIndex = columnLetter.toUpperCase().charCodeAt(0) - 65;

  // Get all values in the range
  const values = range.getValues();

  // Use a Set to store unique values (Sets automatically ignore duplicates)
  let uniqueValues = new Set<string>();

  // Start from row 1 to skip header row
  for (let i = 1; i < values.length; i++) {
    const cellValue = values[i][columnIndex];
    
    // Only add non-empty values
    if (cellValue !== null && cellValue !== undefined && cellValue.toString().trim() !== "") {
      uniqueValues.add(cellValue.toString());
    }
  }

  // Log the result
  console.log(`Unique values in column ${columnLetter}: ${uniqueValues.size}`);
  
  return uniqueValues.size;
}











===============
/*
 * This script counts how many instances of each Version name exist.
 */
function main(
  workbook: ExcelScript.Workbook,
  sheetName: string = "cmdb_ci_db_mssql_instance"
): string {
  // Get the worksheet
  const sheet = workbook.getWorksheet(sheetName);

  // Get the entire data range
  const range = sheet.getUsedRange(true);

  if (!range) {
    return "No data found";
  }

  // Get all values
  const values = range.getValues();

  // Column C (index 2) = "Version name" (2012, 2014, 2005, etc.)
  const versionNameIndex = 2;

  // Count each version name
  let versionCounts = new Map<string, number>();

  // Skip header row (start at 1)
  for (let i = 1; i < values.length; i++) {
    const versionName = values[i][versionNameIndex];

    if (versionName !== null && versionName !== undefined && versionName.toString().trim() !== "") {
      const version = versionName.toString();
      versionCounts.set(version, (versionCounts.get(version) || 0) + 1);
    }
  }

  // Build summary
  let summary = "Version Name Counts:\n";
  summary += "-------------------\n";
  
  versionCounts.forEach((count, version) => {
    summary += `${version}: ${count} instance(s)\n`;
  });

  summary += `-------------------\n`;
  summary += `Unique versions: ${versionCounts.size}`;

  console.log(summary);
  return summary;
}
```

**Expected output based on your data:**
```
Version Name Counts:
-------------------
2012: 4 instance(s)
2014: 1 instance(s)
2005: 1 instance(s)
-------------------
Unique versions: 3

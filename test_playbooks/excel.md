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
 * This script counts how many instances of each version exist.
 * Returns a summary of version counts.
 */
function main(
  workbook: ExcelScript.Workbook,
  sheetName: string = "Sheet1"
): string {
  // Get the worksheet
  const sheet = workbook.getWorksheet(sheetName);

  // Get the entire data range
  const range = sheet.getUsedRange(true);

  // If the used range is empty, end the script
  if (!range) {
    console.log("No data on this sheet.");
    return "No data found";
  }

  // Get all values in the range
  const values = range.getValues();

  // Column C (index 2) contains "Version name"
  const versionColumnIndex = 2;

  // Use a Map to count occurrences of each version
  let versionCounts = new Map<string, number>();

  // Start from row 1 to skip header row
  for (let i = 1; i < values.length; i++) {
    const version = values[i][versionColumnIndex];

    // Only count non-empty values
    if (version !== null && version !== undefined && version.toString().trim() !== "") {
      const versionStr = version.toString();
      
      if (versionCounts.has(versionStr)) {
        versionCounts.set(versionStr, versionCounts.get(versionStr)! + 1);
      } else {
        versionCounts.set(versionStr, 1);
      }
    }
  }

  // Build summary output
  let summary = "Version Counts:\n";
  let totalUniqueVersions = 0;

  versionCounts.forEach((count, version) => {
    summary += `${version}: ${count} instance(s)\n`;
    totalUniqueVersions++;
  });

  summary += `\nTotal unique versions: ${totalUniqueVersions}`;
  summary += `\nTotal instances: ${values.length - 1}`;

  console.log(summary);
  return summary;
}
```

**Output example:**
```
Version Counts:
2012: 4 instance(s)
2014: 1 instance(s)
2005: 1 instance(s)
2008: 1 instance(s)

Total unique versions: 4
Total instances: 14

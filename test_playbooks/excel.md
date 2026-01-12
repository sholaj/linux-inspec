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
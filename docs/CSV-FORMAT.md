# CSV File Format Specification

This document provides detailed specifications for CSV files used in bulk processing mode.

## 📋 Basic Format Requirements

### Required Columns

The CSV file **must** contain exactly these two columns:

| Column Name | Data Type | Description | Example |
|-------------|-----------|-------------|---------|
| `SCRIPT` | Text | The text to convert to speech | "Welcome to our service" |
| `FILENAME` | Text | Output filename (without extension) | "welcome_message" |

### Format Rules

1. **Column Names**: Must be exactly `SCRIPT` and `FILENAME` (case-sensitive)
2. **Header Row**: Required as first row
3. **Delimiter**: Comma (`,`) separated
4. **Encoding**: UTF-8 or ANSI recommended
5. **Line Endings**: Windows (CRLF) or Unix (LF) supported

## 📝 Basic Example

```csv
SCRIPT,FILENAME
"Hello and welcome to our service","welcome_greeting"
"Thank you for your order","order_confirmation"
"Your appointment is confirmed","appointment_confirmed"
```

## 🔤 Text Content Guidelines

### SCRIPT Column Best Practices

#### Length Recommendations
- **Optimal**: 50-200 characters per script
- **Maximum**: 5,000 characters (Google Cloud limit)
- **Azure**: No strict limit, but shorter is better for quality

#### Text Formatting
```csv
SCRIPT,FILENAME
"Hello, welcome to our service. How can we help you today?","greeting_01"
"Your order number is 12345. It will be delivered tomorrow.","order_12345"
"Please hold while we transfer your call.","hold_message"
```

#### Special Characters
- **Quotation Marks**: Escape with double quotes (`""`)
- **Commas**: Enclose entire field in quotes
- **Line Breaks**: Use `\n` or actual line breaks in quoted fields
- **Unicode**: Supported but test with your TTS provider

#### Examples of Special Character Handling
```csv
SCRIPT,FILENAME
"She said ""Hello"" to everyone","greeting_with_quotes"
"The price is $29.99, including tax","price_announcement"
"Line one\nLine two\nLine three","multiline_script"
"Café, résumé, naïve","international_text"
```

### FILENAME Column Requirements

#### Naming Rules
- **Characters**: Letters, numbers, underscore, hyphen only
- **No Spaces**: Use underscores instead
- **No Extension**: Extension added automatically based on format
- **Length**: Maximum 100 characters (after sanitization)

#### Valid Examples
```csv
SCRIPT,FILENAME
"Welcome message","welcome_message"
"Order confirmation","order_confirm_2024"
"Hold music replacement","hold_music_v2"
```

#### Invalid Examples (Will be Sanitized)
```csv
SCRIPT,FILENAME
"Welcome message","welcome message"          # Spaces become underscores
"Order confirmation","order/confirm"          # Slash becomes underscore  
"Hold music","../../../system"               # Path traversal removed
"Test","file.with.dots"                      # Dots become underscores
```

## 📊 Advanced Examples

### Large Dataset Example
```csv
SCRIPT,FILENAME
"Welcome to TechCorp customer service. Please hold while we connect you.","techcorp_welcome_hold"
"Your call is important to us. Current wait time is approximately 5 minutes.","wait_time_5min"
"Press 1 for sales, 2 for support, or 3 for billing.","main_menu_options"
"Thank you for choosing TechCorp. Have a great day!","goodbye_message"
"Due to high call volume, your wait time may be longer than usual.","high_volume_warning"
```

### Multi-Language Support
```csv
SCRIPT,FILENAME
"Welcome to our service","welcome_en"
"Bienvenue à notre service","welcome_fr"
"Bienvenido a nuestro servicio","welcome_es"
"Willkommen bei unserem Service","welcome_de"
```

### Different Voice Styles
```csv
SCRIPT,FILENAME
"Urgent: Your account requires immediate attention.","urgent_security_alert"
"Congratulations! Your order has been processed.","celebration_order_success"
"We apologize for the inconvenience. Please try again.","apologetic_error_message"
"Thank you for your patience while we assist you.","polite_patience_request"
```

## 🔍 Validation Rules

The application validates CSV files according to these rules:

### Structural Validation
1. **File Exists**: Must be readable file
2. **Parse Successfully**: Valid CSV format
3. **Header Present**: First row contains column names
4. **Required Columns**: Both SCRIPT and FILENAME present
5. **Data Rows**: At least one data row after header

### Content Validation
1. **Non-Empty Values**: Both columns must have content
2. **Character Limits**: Within provider limits
3. **Filename Safety**: No path traversal characters
4. **Encoding**: Readable text content

### Example Validation Errors
```csv
# Missing FILENAME column
SCRIPT,DESCRIPTION
"Hello world","greeting"

# Empty values
SCRIPT,FILENAME
"Hello world","greeting"
"","empty_script"        # Error: Empty script
"Goodbye","              # Error: Empty filename

# Invalid characters
SCRIPT,FILENAME
"Hello world","../../../etc/passwd"  # Error: Path traversal attempt
```

## 🛠️ Creating CSV Files

### Using Excel

1. **Create Spreadsheet**:
   - Column A: SCRIPT
   - Column B: FILENAME
   - Add your data starting from row 2

2. **Save as CSV**:
   - File → Save As
   - Choose "CSV (Comma delimited)"
   - Encoding: UTF-8 recommended

3. **Verify Format**:
   - Open in text editor to check structure
   - Ensure proper quoting of text with commas

### Using PowerShell

```powershell
# Create sample CSV programmatically
$data = @(
    [PSCustomObject]@{SCRIPT="Hello world"; FILENAME="hello_world"}
    [PSCustomObject]@{SCRIPT="Goodbye"; FILENAME="goodbye"}
)
$data | Export-Csv -Path "sample.csv" -NoTypeInformation
```

### Using Text Editor

```csv
SCRIPT,FILENAME
"First message","message_01"
"Second message","message_02"
"Third message with, comma","message_03"
```

## 📋 Testing Your CSV File

### Quick Validation Script

```powershell
# Test CSV file format
function Test-TtsCSV {
    param([string]$FilePath)
    
    try {
        $csv = Import-Csv $FilePath
        
        # Check required columns
        if (-not ($csv[0].PSObject.Properties.Name -contains "SCRIPT")) {
            Write-Error "Missing SCRIPT column"
            return $false
        }
        
        if (-not ($csv[0].PSObject.Properties.Name -contains "FILENAME")) {
            Write-Error "Missing FILENAME column"
            return $false
        }
        
        # Check for empty values
        $emptyScripts = $csv | Where-Object {[string]::IsNullOrWhiteSpace($_.SCRIPT)}
        $emptyFilenames = $csv | Where-Object {[string]::IsNullOrWhiteSpace($_.FILENAME)}
        
        if ($emptyScripts) {
            Write-Warning "Found $($emptyScripts.Count) rows with empty SCRIPT"
        }
        
        if ($emptyFilenames) {
            Write-Warning "Found $($emptyFilenames.Count) rows with empty FILENAME"
        }
        
        Write-Host "CSV validation successful: $($csv.Count) rows found"
        return $true
    }
    catch {
        Write-Error "CSV validation failed: $($_.Exception.Message)"
        return $false
    }
}

# Usage
Test-TtsCSV -FilePath "your_file.csv"
```

## 📈 Performance Considerations

### Optimal File Sizes

| Row Count | Processing Time | Memory Usage | Recommendation |
|-----------|----------------|--------------|----------------|
| 1-50 | < 2 minutes | Low | Optimal for testing |
| 51-200 | 2-10 minutes | Medium | Good for production |
| 201-500 | 10-25 minutes | Medium-High | Consider batching |
| 500+ | 25+ minutes | High | Split into multiple files |

### Batch Processing Tips

1. **Split Large Files**:
   ```powershell
   # Split CSV into smaller batches
   $csv = Import-Csv "large_file.csv"
   $batchSize = 100
   for ($i = 0; $i -lt $csv.Count; $i += $batchSize) {
       $batch = $csv[$i..($i + $batchSize - 1)]
       $batch | Export-Csv "batch_$([math]::Floor($i/$batchSize) + 1).csv" -NoTypeInformation
   }
   ```

2. **Monitor Progress**: Watch application log for completion status

3. **Error Recovery**: Failed items are logged - create new CSV with only failed items

## 🚨 Common Mistakes

### Format Issues
```csv
# Wrong column names (case sensitive)
script,filename                    # Lowercase not allowed
SCRIPTS,FILENAMES                  # Plural not allowed

# Missing quotes around text with commas
Hello, world,greeting              # Should be "Hello, world",greeting

# Inconsistent quoting
"Hello world",greeting             # Good
Hello world,"greeting"             # Inconsistent but works
"Hello world","greeting"           # Best practice
```

### Content Issues
```csv
SCRIPT,FILENAME
"","empty_script"                  # Empty script
"Hello world",""                   # Empty filename
"Hello world","file name"          # Space in filename
"Hello world","file/name"          # Invalid character
```

## 📁 Sample Files

### Download Examples

Create these sample files for testing:

**simple_test.csv**:
```csv
SCRIPT,FILENAME
"Hello world","test_hello"
"Goodbye world","test_goodbye"
```

**comprehensive_test.csv**:
```csv
SCRIPT,FILENAME
"Welcome to our automated system. Please listen carefully as our menu options have changed.","menu_intro_2024"
"Press 1 for sales, press 2 for customer service, or press 3 for technical support.","main_menu_options"
"Thank you for holding. Your call is important to us.","hold_message_standard"
"We're sorry, but all our representatives are currently busy. Please try again later.","busy_message"
"Your transaction has been completed successfully. Thank you for your business.","transaction_complete"
```

Save these as `.csv` files and test with the application to verify your setup works correctly.
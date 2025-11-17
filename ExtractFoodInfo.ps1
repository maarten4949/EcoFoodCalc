Clear-Host

# Source folder containing the .cs files - Ensure to point where your ECO SERVER is installed.
$SourceFolder = "D:\SteamLibrary\steamapps\common\Eco Server\Mods\__core__\AutoGen\Food"

# Output file path for the generated JSON
$OutputFile = ".\foodsource.json" 

# Array to hold all food objects
$FoodData = @()

# Regular Expressions to extract the required information.

# Regex to capture the display name (e.g., "Baked Agave")
$RegexDisplayName = '\[LocDisplayName\("(.+?)"\)\]'

# Regex to capture the Calories value (e.g., 700)
$RegexCalories    = 'public override float Calories\s*=>\s*(\d+)'

# Regex to capture Nutrients: Carbs, Fat, Protein, Vitamins, in that order.
$RegexNutrients   = 'Nutrients\(\) \{ Carbs = (\d+), Fat = (\d+), Protein = (\d+), Vitamins = (\d+)\};'

Write-Host "Starting data extraction from folder: $SourceFolder"

# Get all .cs files recursively and iterate
Get-ChildItem -Path $SourceFolder -Filter "*.cs" -File -Recurse | ForEach-Object {
    $FilePath = $_.FullName
    $Content = Get-Content $FilePath -Raw
    
    # Initialize variables
    $FoodName = $null
    $Calories = $null
    $Carbs = $null
    $Fat = $null
    $Protein = $null
    $Vitamins = $null
    
    # 1. Extract Display Name
    if ($Content -match $RegexDisplayName) {
        $FoodName = $Matches[1]
    }
    
    # 2. Extract Calories
    if ($Content -match $RegexCalories) {
        # Cast to integer just in case, though it usually captures the number string
        $Calories = [int]$Matches[1] 
    }
    
    # 3. Extract Nutrients (Carbs, Fat, Protein, Vitamins)
    if ($Content -match $RegexNutrients) {
        # Matches[1] = Carbs, Matches[2] = Fat, Matches[3] = Protein, Matches[4] = Vitamins
        $Carbs = [int]$Matches[1]
        $Fat = [int]$Matches[2]
        $Protein = [int]$Matches[3]
        $Vitamins = [int]$Matches[4]
    }
    
    # 4. Create the Custom Object if essential data is found
    if ($FoodName -and $Calories) {
        $FoodObject = [PSCustomObject]@{
            Food_Name            = $FoodName
            Carbs                = $Carbs
            Fat                  = $Fat
            Protein              = $Protein
            Vitamins             = $Vitamins
            Official_Calories_Game = $Calories
        }
        
        # Add the object to the main array
        $FoodData += $FoodObject
        Write-Host "✅ Processed: $FoodName (Calories: $Calories)" -ForegroundColor Green
    } else {
        # Warn if essential information is missing
        Write-Host "⚠️ Skipped: $($_.Name). Essential information not found." -ForegroundColor Yellow
    }
}

# 5. Convert to JSON and save
$FoodData | ConvertTo-Json -Depth 10 | Out-File $OutputFile -Encoding UTF8

Write-Host "---"
Write-Host "The JSON file has been successfully created at: $OutputFile" -ForegroundColor Cyan
Write-Host "Total items processed: $($FoodData.Count)" -ForegroundColor Cyan
Write-Host "---"

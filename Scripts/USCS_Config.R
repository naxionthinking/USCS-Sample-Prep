# ==============================================================================
# Configuration File for USCS Sample Prep Script
# ==============================================================================
# This file contains file paths and other hard coded variables for the sample prep
# Any variables starting with "." are not actively used in the .Rmd and are hidden from the environment
# ==============================================================================

# Loads in necessary packages, and installs them if you don't have them installed
if (!require("glue")) install.packages("glue")

# Lets you embed variables into strings like python f-strings

f_str <- function(str, ...) {
  do.call(glue::glue, c(list(str), list(...))) %>% as.character()
}

# ------------------------------------------------------------------------------
# VARIABLES TO UPDATE
# ------------------------------------------------------------------------------
DATE_SAMPLE_RECIEVED <- as.Date("2024-11-21") # UPDATE -- used in Tenure

YEAR <- 2024 # UPDATE
MONTH_NO <- 12 # UPDATE

MONTH <- month.abb[MONTH_NO] %>% str_to_upper() # Get the 3 letter abbreviation (i.e, "JAN") used for file naming
MONTH_2_DIGITS <- sprintf("%02d", MONTH_NO) # Two digit month

# ------------------------------------------------------------------------------
# FILE PATHS TO UPDATE
# ------------------------------------------------------------------------------

## This should automatically create the correct name of the sample prep holder using the above variables
.SAMPLE_PREP_PATH <- "../USCS_Sample_Prep_Helper_{MONTH}_{YEAR}.xlsx" %>% f_str() 

## This is where the raw files lie. Only thing I've seen change is sometimes "raw" is "raw files"
.raw_files_path <- '\\\\pm1/27-610/Sampling-Weighting/{YEAR}/{YEAR}_{MONTH_2_DIGITS}/raw' %>% f_str() 

# Get base and spend files
.raw_files <- list.files(.raw_files_path)

.base_file <- .raw_files[str_detect(.raw_files, "BASE")]
.spend_file <- .raw_files[str_detect(.raw_files, "SPEND")]

if (length(.base_file) == 0) stop("Base file not found")
if (length(.spend_file) == 0) stop("Spend file not found")

# If there are errors, paste in the file yourself and comment the above out
# base_file <- ""
# spend_file <- ""

.BASE_PATH <- '{.raw_files_path}/{.base_file}' %>% f_str()
.SPEND_PATH <- '{.raw_files_path}/{.spend_file}' %>% f_str() 

## This uses relative paths to find the file lookups folder. Theoretically, it should always be 3 folders back, but change if not
.file_lookups <- f_str("../../../File Lookups")# L:/Amex.549/Sample/2023/File Lookups

## Change file names if they change
.OPEN_SEG_PATH <-       "{.file_lookups}/Managed_List_2024_SAT 06.25.24.csv"  %>% f_str()
.SUBJECT_LINE_PATH <-   "{.file_lookups}/MarketVoice - Card Lookup20230124_ForAnalytics.csv"  %>% f_str()
# CENTURION_TIER_PATH <- "{.file_lookups}/760_CENTURION_TIER_CVs.csv" %>% f_str() # No longer used
.CARD_ART_PATH <-       "{.file_lookups}/Card Art URLs 20230929.csv" %>% f_str()


# ------------------------------------------------------------------------------
# VARIABLES THAT DO NOT CHANGE OFTEN -- Used for CVs mostly
# ------------------------------------------------------------------------------

# Main cell codes
MAIN_CELL_CODES <- c("CCSG01", "CCSG02", "CCSG03")

# Marketer codes NOT allowed negative spend
.MARKETER_CODES_NO_NEGATIVES <- c("SP111", "SP112", "SP113", "SP114", "SP115", 
                          "SP117", "SP118", "SP123", "SP127", "SP132", 
                          "SP136", "SP145", "SP153", "SP156")

# Card names
CARD_NAME_MAPPING <- list(
  SP101 = "Platinum",
  SP103 = "Gold Charge No Rewards",
  SP105 = "Gold",
  SP106 = "Senior Gold",
  SP108 = "Green Charge No Rewards",
  SP110 = "Senior Green",
  SP111 = "Platinum, Platinum Preferred, Gold Optima",
  SP112 = "Standard and Classic Optima",
  SP113 = "Blue",
  SP114 = "Blue Cash",
  SP115 = "BlueSky",
  SP117 = "One",
  SP118 = "Clear",
  SP120 = "Zync",
  SP123 = "Hilton Honors",
  SP124 = "Hilton Honors Surpass",
  SP125 = "Delta Gold",
  SP126 = "Delta Platinum",
  SP127 = "Delta Blue",
  SP129 = "Delta Reserve",
  SP130 = "Marriott Bonvoy",
  SP132 = "Blue Cash Everyday",
  SP133 = "Blue Cash Preferred",
  SP135 = "Centurion",
  SP136 = "Morgan Stanley Credit",
  SP137 = "Morgan Stanley Platinum",
  SP138 = "Ameriprise Gold",
  SP139 = "Ameriprise Platinum",
  SP142 = "Goldman Sachs Platinum",
  SP145 = "Amex EveryDay",
  SP146 = "Amex EveryDay Preferred",
  SP148 = "Traditional Gold with Rewards",
  SP149 = "Classic Gold",
  SP150 = "Green",
  SP151 = "Traditional Green with Rewards",
  SP153 = "Schwab Investor",
  SP154 = "Schwab Platinum",
  SP155 = "Hilton Honors Aspire",
  SP156 = "Cash Magnet",
  SP157 = "Marriott Bonvoy Brilliant",
  SP158 = "Marriott Bonvoy Bevy"
)

# Fee status mapping
.amex_fee_status <- list(
  has_fee = c("SP101", "SP103", "SP105", "SP106", "SP108", "SP110", 
              "SP120", "SP124", "SP125", "SP126", "SP129", "SP130", 
              "SP133", "SP135", "SP137", "SP138", "SP139", "SP142",
              "SP146", "SP148", "SP149", "SP150", "SP151", "SP154", 
              "SP155", "SP157", "SP158"),
  
  no_fee = c("SP111", "SP112", "SP113", "SP114", "SP115", "SP117", 
             "SP118", "SP123", "SP127", "SP132", "SP136", "SP145", 
             "SP153", "SP156")
)


# Create a named vector for fee status
AMEX_FEE_MAPPING <- c(
  setNames(rep("1", length(.amex_fee_status$has_fee)), .amex_fee_status$has_fee),
  setNames(rep("2", length(.amex_fee_status$no_fee)), .amex_fee_status$no_fee)
)

# Portfolio categorization
.portfolio_categories <- list(
  category_1 = c('SP101', 'SP103', 'SP105', 'SP106', 'SP108', 
                 'SP110', 'SP117', 'SP120', 'SP135', 'SP148', 
                 'SP149', 'SP150', 'SP151'),
  
  category_2 = c('SP111', 'SP112', 'SP113', 'SP114', 'SP115', 
                 'SP118', 'SP132', 'SP133', 'SP145', 'SP146', 
                 'SP156'),
  
  category_3 = c('SP123', 'SP124', 'SP125', 'SP126', 'SP127', 
                 'SP129', 'SP130', 'SP136', 'SP137', 'SP138', 
                 'SP139', 'SP142', 'SP153', 'SP154', 'SP155', 
                 'SP157', 'SP158')
)

# Create a named vector for portfolio categories
PORTFOLIO_MAPPING <- c(
  setNames(rep(1L, length(.portfolio_categories$category_1)), .portfolio_categories$category_1),
  setNames(rep(2L, length(.portfolio_categories$category_2)), .portfolio_categories$category_2),
  setNames(rep(3L, length(.portfolio_categories$category_3)), .portfolio_categories$category_3)
)

ENROLLMENT_CODE_MAPPING <- c(
  'C' = "1",
  'E' = "2", 
  'H' = "3",
  'I' = "4",
  'N' = "5",
  'O' = "6",
  'R' = "7",
  'S' = "8",
  'X' = "9",
  'P' = "10"
)

MR_CATEGORY_MAPPING <- c(
  "PR" = 1L,
  "MR" = 2L,
  "LF" = 3L
)

GENERATION_MAPPING <- list(
  thresholds = c(-Inf, 1946, 1965, 1980, 1989, 1997, Inf),
  labels = c(
    "Silent: 1945 and prior",
    "Baby Boomers: 1946 - 1964",
    "Generation X: 1965 - 1979",
    "Older Millennials: 1980 - 1988",
    "Younger Millennials: 1989 - 1996",
    "Generation Z: 1997 and later"
  )
)

MR_IN_MAPPING <- c(
  "Y" = "1",
  "N" = "2"
)

MYCA_MAPPING <- c(
  "Y" = "1",
  "N" = "2"
)
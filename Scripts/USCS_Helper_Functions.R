# ==============================================================================
# Helper Functions for USCS Sample Prep Script
# ==============================================================================
# This file contains helper functions for USCS Sample prep.
# ==============================================================================

# ------------------------------------------------------------------------------
# Package Management
# ------------------------------------------------------------------------------

# Loads in necessary packages, and installs them if you don't have them installed
if (!require("pacman")) install.packages("pacman")

pacman::p_load("tidyverse",
               "glue",
               "readxl",
               "kableExtra",
               "knitr",
               "conflicted",
               "cli",
               'scales')

conflicts_prefer(dplyr::select, 
                 dplyr::filter, 
                 .quiet = T)

# Source configuration
source("USCS_Config.R")

# ------------------------------------------------------------------------------
# Basic Data Validation Functions
# ------------------------------------------------------------------------------

# Check that a string doesn't match any non-letter
is_letters_only <- function(x) !grepl("[^A-Za-z]", x)

# Check that a string doesn't match any non-number
is_numbers_only <- function(x) !grepl("\\D", x)

# Extract first or last number of string
# Used for creating weighting_segment conditions
get_first_num <- function(interval) stri_extract_first(interval, regex="[0-9]+")
get_last_num <- function(interval) stri_extract_last(interval, regex = "[0-9]+")

# Count number of missing observations for given variables
count_missing <- function(data, miss_vars){
  data %>%
    select(all_of(miss_vars)) %>%
    summarise_all(~sum(is.na(.))) %>%
    pivot_longer(cols = everything(), names_to = "Variable", values_to = "n_missing") %>%
    mutate("Percent Missing" = paste0(round(n_missing / nrow(data) * 100, 4), " %")) %>% 
    arrange(desc(n_missing)) %>% make_nice_table("Number of Missing Values per Key Variable")
}

# ------------------------------------------------------------------------------
# Data Loading Functions
# ------------------------------------------------------------------------------
# Because there is no delimiter in the text files, we need to use fixed widths for variables
# The data frame info is of the form VAR_NAME| NUM_SPACES | TYPE
# Where the number of spaces is the length of the variable, and the 
# Type is either "c" for character/text or "n" for numeric
# ------------------------------------------------------------------------------

load_base <- function(skip=2){
  # df_info is the mapping of variable name, length, and column type
  df_info <- data.frame(c('REC_TYPE',               1,'c'),
                        c('GMPI_BASE_CUST_ID',     19,'c'),
                        c('ACCOUNT_NUMBER',        15,'c'),
                        c('NM_PFX_TX',             10,'c'),
                        c('FIRST_NM',              20,'c'),
                        c('MID_NM',                20,'c'),
                        c('LAST_NM',               30,'c'),
                        c('NM_SUFF_TX',            20,'c'),
                        c('CARE_OF_LINE_AD',       38,'c'),
                        c('BEST_ADDR_LINE1_TX',    40,'c'),
                        c('BEST_ADDR_LINE2_TX',    40,'c'),
                        c('CITY_NM',               30,'c'),
                        c('STATE_TX',               2,'c'),
                        c('US_ZIP',                 9,'c'),
                        c('CARRY_RTE_CD',           5,'c'),
                        c('ADV_BARCODE_TX',        14,'c'),
                        c('FILLER1',                1,'c'),
                        c('SAL_TX',                20,'c'),
                        c('HOME_PHONE_LN_NO',      20,'c'),
                        c('BUS_PHONE_LN_NO',       20,'c'),
                        c('LAST5',                  5,'c'),
                        c('IA_ID',                  6,'c'),
                        c('FMLY_DS_TX',            20,'c'),
                        c('CARD_ROLLUP_DS_TX',     20,'c'),
                        c('CONS_FRIENDLY_DS_TX',   60,'c'),
                        c('SETUP_DT',              30,'c'),
                        c('BEST_DMA_CD',           11,'c'),
                        c('MAIL_ID',                8,'c'),
                        c('EXPIRATION_DT',          8,'c'),
                        c('CELL_CODE',             10,'c'),
                        c('LEAD_IND',               4,'c'),
                        c('POID',                   9,'c'),
                        c('MARKETER_CODE',          5,'c'),
                        c('SEQ_NUMBER',             8,'n'),
                        c('TM_FILLER',              6,'c'),
                        c('MYCA_FLAG',              1,'c'),
                        c('HVCM_FLG',               1,'c'),
                        c('MR_IN',                  1,'c'),
                        c('CCSG_OPEN_CHRG_ACCT_CT', 6,'n'),
                        c('CCSG_OPEN_LEND_ACCT_CT', 6,'n'),
                        c('OSBN_OPEN_CHRG_ACCT_CT', 6,'n'),
                        c('OSBN_OPEN_LEND_ACCT_CT', 6,'n'),
                        c('ACCOUNT_SPEND',         10,'n'),
                        c('SIZE_OF_WALLET',        10,'n'),
                        c('SHARE_OF_WALLET_AMEX',   5,'n'),
                        c('PERSONALIZATION1',      10,'c'),
                        c('PERSONALIZATION2',      10,'c'),
                        c('PERSONALIZATION3',      10,'c'),
                        c('CARD_ANNIV_DT',         30,'c'),
                        c('AGE_RANGE',              2,'n'),
                        c('CUSTOMER_SPEND',        10,'n'),
                        c('FICO_Range',             3,'c'),
                        c('ACTIVE_SUPP_CT',         6,'n'),
                        c('ST_EXP_ENROLL_IN',       1,'c'),
                        c('EXPO_ENROLL_IN',         1,'c'),
                        c('PRIM_SIC_CUR_CD',        5,'c'),
                        c('EMP_CT',                11,'n'),
                        c('MR_TIER_PROG_CD',        2,'c'),
                        c('MR_INIT_ENROLL_DT',     30,'c'),
                        c('MR_LINK_STA_CD',         1,'c'),
                        c('AVLBL_PNTS',            20,'n'),
                        c('ACCT_TRANS_PNTS_NO',    20,'n'),
                        c('CARD_STA_CD',            2,'c'),
                        c('TOT_RVLV_INT_AM',       22,'n'),
                        c('RVLV_MTHS_NO',           6,'n'),
                        c('TOT_LOC_INT_AM',        22,'n'),
                        c('TOT_LOC_INT_MTH_NO',     6,'n'),
                        c('TOT_LOC_AM',            22,'n'),
                        c('LED_RSN_CD',             6,'c'),
                        c('m12892',                22,'c'),
                        c('m13184',                22,'c'),
                        c('m13083',                22,'c'),
                        c('m13197',                22,'c'),
                        c('m13223',                22,'c'),
                        c('RDM_NET_12M_CT',        14,'n'),
                        c('LINE_OF_CREDIT_AM',     20,'n'),
                        c('PURCH_APR_RT',           8,'n'),
                        c('SMART_REV',             20,'n'),
                        c('SMART_SIC',             20,'n'),
                        c('T_ADD',                 20,'n'),
                        c('RAW_AGE',                7,'n'),
                        c('RAW_FICO',               7,'n'),
                        c('NEW_SMART_REV_char',    20,'n'),
                        c('CUST_ACQ_CODE',         10,'c')) %>% 
    t() %>% as.data.frame() %>% mutate(V2 = as.numeric(V2)) %>% 
    set_names(c("col_names", "col_widths", "col_types"))
  
  #### Verify file format is what we expect
  total_length <- sum(df_info$col_widths)
  
  # Read in the first valid line
  first_line <- read_lines(.BASE_PATH, skip = skip, n_max = 1)
  
  if (nchar(first_line) != total_length) {
    cli_abort(c("Input widths do not match expected column widths. Must fix.",
                "i" = "Expected width: {total_length}",
                "x" = "Actual width: {nchar(first_line)}"), .envir = environment())
  }
  
  # We use df_info to load in the file properly
  df <- read_fwf(file = .BASE_PATH,
                 skip = skip, # If the raw file contains the funky lines on top, include a skip
                 col_positions = fwf_widths(df_info$col_widths),
                 col_types = paste0(df_info$col_types, collapse = ""), # collapses into something like 'cccnnnccc'
                 na = c("")) %>% # What missing values are represented as in the text file
    set_names(str_to_lower(df_info$col_names)) 
  
  cli_alert_info("There were {comma(nrow(df))} observations loaded in for BASE")
  
  return(df)
}

# ------------------------------------------------------------------------------

load_spend <- function(){
  
  # df_info is the mapping of variable name, length, and column type
  df_info <- data.frame(c('rec',                 1,'c'),
                        c('BASE_ACCT_ID',       11,'c'),
                        c('REPL_NUMBER',         1,'n'),
                        c('BASIC_SUPP_NO',       2,'n'),
                        c('CHECK_DIGIT',         1,'n'),
                        c('GMPI_BASE_CUST_ID',  19,'c'),
                        c('Prestige_spnd',      10,'n'),
                        c('Prestige_ROCs',       4,'n'),
                        c('Internet_spnd',      10,'n'),
                        c('Internet_ROCs',       4,'n'),
                        c('Charity_spnd',       10,'n'),
                        c('Charity_ROCs',        4,'n'),
                        c('Communication_spnd', 10,'n'),
                        c('Communication_ROCs',  4,'n'),
                        c('Education_spnd',     10,'n'),
                        c('Education_ROCs',      4,'n'),
                        c('Entertainment_spnd', 10,'n'),
                        c('Entertainment_ROCs',  4,'n'),
                        c('Equipment_spnd',     10,'n'),
                        c('Equipment_ROCS',      4,'n'),
                        c('Every_day_spnd',     10,'n'),
                        c('Every_day_ROCs',      4,'n'),
                        c('Govt_spnd',          10,'n'),
                        c('Govt_ROCs',           4,'n'),
                        c('Insurance_spnd',     10,'n'),
                        c('Insurance_ROCs',      4,'n'),
                        c('Pers_home_spnd',     10,'n'),
                        c('Pers_home_ROCs',      4,'n'),
                        c('Raw_mat_spnd',       10,'n'),
                        c('Raw_mat_ROCs',        4,'n'),
                        c('Rent_spnd',          10,'n'),
                        c('Rent_ROCs',           4,'n'),
                        c('Restaurant_spnd',    10,'n'),
                        c('Restaurant_ROCS',     4,'n'),
                        c('Retail_spnd',        10,'n'),
                        c('Retail_ROCS',         4,'n'),
                        c('Services_spnd',      10,'n'),
                        c('Services_ROCS',       4,'n'),
                        c('Supplies_spnd',      10,'n'),
                        c('Supplies_ROCS',       4,'n'),
                        c('Travel_spnd',        10,'n'),
                        c('Travel_ROCS',         4,'n'),
                        c('Utilities_spnd',     10,'n'),
                        c('Utilities_ROCS',      4,'n'),
                        c('All_spnd',           10,'n'),
                        c('All_ROCs',            4,'n')) %>% 
    t() %>% as.data.frame() %>% mutate(V2 = as.numeric(V2)) %>% 
    set_names(c("col_names", "col_widths", "col_types"))
  
  #### Verify file format is what we expect
  total_length <- sum(df_info$col_widths)
  
  # Read in the third line of the file
  # Skipping possible weird first 2 lines
  third_line <- read_lines(.SPEND_PATH, skip = 2, n_max = 1)
  
  if (nchar(third_line) != total_length) {
    cli_abort(c("Input widths do not match expected column widths. Must fix.",
                "i" = "Expected width: {total_length}",
                "x" = "Actual width: {nchar(third_line)}"), .envir = environment())
  }
  
  # We use df_info to load in the file properly
  df <- read_fwf(file = .SPEND_PATH,
                 skip = 2, # If the raw file contains the funky lines on top, include a skip
                 show_col_types = FALSE,
                 col_positions = fwf_widths(df_info$col_widths),
                 col_types = paste0(df_info$col_types, collapse = ""), # collapses into something like 'cccnnnccc'
                 na = c("")) %>% # What missing values are represented as in the text file
    set_names(str_to_lower(df_info$col_names))
  
  cli_alert_info("There were {comma(nrow(df))} observations loaded in for SPEND")
  
  return(df)
  
}

load_req_marketer_codes <- function(){
  read_excel(.SAMPLE_PREP_PATH, sheet = "Sp_Code_Freqs") %>% 
    set_names(c("sp_code", "card_name", "count_requested")) %>% 
    drop_na(sp_code) %>% # Remove blank spaces if they were kept in
    mutate(marketer_code = glue("SP{sp_code}")) %>% 
    # If blank spaces were loaded in, the columns might be characters when we want them to be numbers, this will fix that
    suppressMessages(type_convert())
}

load_augment_specs <- function(){
  read_excel(.SAMPLE_PREP_PATH, sheet = "Augment_Specs")
}

load_valid_dmas <- function(){
  read_excel(.SAMPLE_PREP_PATH, sheet = "Valid_DMA_Codes") %>% pull(Valid_DMA)
}

load_open_seg <- function(){
  read_csv(.OPEN_SEG_PATH, show_col_types = F) %>% 
    rename(gmpi_base_cust_id = cust_xref_id) %>% 
    mutate(customer_id = as.numeric(gmpi_base_cust_id)) # Get numeric ID
}

load_weighting_conditions <- function(){
  read_excel(.SAMPLE_PREP_PATH, sheet = "Weighting_Segments", na = c("", "n/a")) %>% 
    drop_na(sp_code) %>%  select(-starts_with("X")) # Drop empty rows and unused columns
}

load_subject_line_info <- function(){
  read_csv(.SUBJECT_LINE_PATH, show_col_types = FALSE) %>% 
    set_names(c('ia_id', 'subject_line_insert'))
}

load_card_art <- function(){
  suppressMessages(read_csv(.CARD_ART_PATH, show_col_types = FALSE)) %>% 
    select(marketer_code = `SP Code`, sv_card_art = SV_CARD_ART)
}

# ------------------------------------------------------------------------------
# Table Generation Functions
# ------------------------------------------------------------------------------

# Make a nice looking table for the html output
make_nice_table <- function(tab, caption){
  
  if (knitr::is_html_output()){ # Only print the table nicely if we're knitting to save time when diagnosing issues
    knitr::kable(tab, format = "html",
                 caption = paste("<center><strong>", caption, "</strong></center>"),
                 escape = FALSE,
                 booktabs = TRUE) %>% 
      kable_styling(bootstrap_options = "striped",
                    full_width = F, position = "center") %>% print()
  } else{
    print(tab)
  }
  
  tab %>% return() # Return the original table to avoid printing NULL in output
}

# Function to generate a frequency table
freq_table <- function(df, var, caption=NULL){
  tab <- df %>% group_by(across(all_of(var))) %>% 
    summarise(Freq = n()) %>% 
    ungroup() %>% 
    mutate(pct = (Freq / sum(Freq) * 100),
           cum_freq = cumsum(Freq),
           cum_pct = cumsum(pct)) %>% 
    mutate_if(is.numeric, round, digits = 2)
  
  if (!is.null(caption)) make_nice_table(tab, caption) # print table
  
  tab %>% return() # Return the table
}

# Get descriptive stats
group_by_summary_table <- function(df, group_var, sum_var){
  # Creates a nice summary table of one variable by another variable
  df %>% group_by(!!as.name(group_var)) %>% 
    summarize(n=n(),
              mean = mean(!!as.name(sum_var)),
              sd = sd(!!as.name(sum_var)),
              min = min(!!as.name(sum_var)),
              max = max(!!as.name(sum_var)),
    ) %>% 
    mutate_if(is.numeric, round, digits=2) %>% 
    return()
}

# ------------------------------------------------------------------------------
# Sampling and Weight Functions
# ------------------------------------------------------------------------------

# Create a stratified random sample for select variable
create_ab_split <- function(df, strat_var, sample_size){
  set.seed(519) # Set random seed
  
  df <- df %>% mutate(id = row_number())
  
  a_group <- df %>% 
    group_by(!!as.name(strat_var)) %>% 
    sample_frac(sample_size) %>% 
    pull(id)
  
  df %>% 
    mutate(selected = ifelse(id %in% a_group, 1, 0)) %>% 
    select(-id) %>% return()
}

# Assign conditions based on the weighting file--assign weighting conditions
#  An example is 
#  - If sp_code = 130 & tenure_var $\geq$ 241 & account_spend $\geq$ 1500 THEN weighting_segment='SP103HTHS'
assign_weight_conditions <- function(weight_conditions){
  weight_conditions %>% 
    # We first need to extract the sp codes (which are 3 digit numbers)
    # This extracts the sp codes into a list to account for if there are multiple codes associated with a single weighting segment
    mutate(sp_code = if_else(str_detect(sp_code, "[0-9]{3}"), 
                             str_extract_all(sp_code, "\\b[0-9]{3}(?![a-zA-Z])\\b"),
                             as.list(NA_character_))) %>% 
    
    # Extract tenure and spend conditions from excel's format
    mutate(
      # The tenure variable either looks like
      # NUM days+
      # NUM mos+
      # tenure < NUM mos
      # NUM1 to <NUM2 mos
      # Num1 to NUM2 mos
      # So we need to account for all cases
      tenure_var = if_else(str_detect(tenure, "days"), 
                           # If this is the days case. then divide by 30 and round up
                           ceiling(parse_number(tenure)/ 30) %>% as.character(),
                           # If not, extract all numbers (NUM or NUM1 and NUM2)
                           map_chr(str_extract_all(tenure, "[0-9]+"), ~ str_c(.x, collapse=","))),
      
      # The spend variable only has one number but can be of the form
      # $NUM+
      # <$NUM
      account_spend = parse_number(spend), # This extracts just the number
      
      # Here we determine if there was a < or + indicating whether 
      # we are looking at values less than or greater than the number
      tenure_sign = case_when(str_detect(tenure, "\\+") ~ ">=",
                              str_detect(tenure, "\\<") ~ "<",
                              TRUE ~ NA_character_), 
      spend_sign = case_when(str_detect(spend, "\\+") ~ ">=",
                             str_detect(spend, "\\<") ~ "<",
                             TRUE ~ NA_character_)) %>% 
    
    # Create all the conditions from the information in the excel
    mutate(
      # Now we create the tenure condition
      # This looks like 
      # NUM1 <= tenure_var  & tenure_var >= NUM2
      # NUM < tenure_var ETC
      tenure_cond = case_when(is.na(tenure) ~ NA_character_,
                              # in this case, there is NUM1 and NUM2
                              str_detect(tenure_var, ",") ~ paste(get_first_num(tenure_var),
                                                                  " <= tenure_var & tenure_var ", 
                                                                  # This is where we determine if 
                                                                  # the condition is NUM1 to <NUM2 or NUM1 to NUM2
                                                                  if_else(is.na(tenure_sign),
                                                                          "<=",
                                                                          tenure_sign),
                                                                  get_last_num(tenure_var)),
                              # This case is one NUM and we just incorporate the sign we extracted
                              TRUE ~ paste("tenure_var", tenure_sign, tenure_var)),
      
      # Here we create the spend condition which just uses the extracted sign
      spend_cond = if_else(is.na(spend), 
                           NA_character_,
                           paste("account_spend", spend_sign, account_spend)),
      # get the sp code condition
      sp_cond = if_else(is.na(sp_code),
                        NA_character_,
                        # This just creates the conditions when there are multiple codes
                        sapply(sp_code, function(x) paste0("sp_code %in% c(", paste(x, collapse = ","), ")"))),
      
      # Augmented cell condition
      cell_code_cond = if_else(is.na(cell_code),
                         NA_character_,
                         paste0("cell_code ==", "'", cell_code, "'"))) %>% 
    
    # we need to properly order the conditions so ones that overlap work properly
    mutate(
      ordering = case_when(str_detect(weighting_segment, "^TX")  ~ 1,
                           str_detect(weighting_segment, "^ZX")  ~ 2,
                           str_detect(weighting_segment, "^AUG") ~ 3,
                           str_detect(weighting_segment, "^ET")  ~ 4,
                           !str_detect(weighting_segment, "SP")  ~ 5,
                           TRUE ~ 6)) %>% 
    # Create the full condition by bringing together all conditions
    unite(col = 'full_cond', sp_cond, tenure_cond, spend_cond, cell_code_cond, 
          sep = " & ", na.rm=TRUE) %>% # Removes any conditions that are not relevant to the given segment
    mutate(full_cond = glue("{full_cond} ~ '{weighting_segment}'")) %>% 
    arrange(ordering) %>% 
    # 
    select(weighting_segment, 
           sp_code, 
           cell_code, 
           tenure, spend, 
           full_cond)
}

# Generate summary of weight segments
create_weight_summary <- function(data) {
  data %>% 
    group_by(weighting_segment) %>%
    summarize(
      sp_codes = paste(unique(marketer_code), collapse = ", "),
      n = n(),
      across(
        c(account_spend, tenure_var),
        list(
          mean = ~mean(.x, na.rm = TRUE),
          sd = ~sd(.x, na.rm = TRUE),
          min = ~min(.x, na.rm = TRUE),
          max = ~max(.x, na.rm = TRUE)
        ),
        .names = "{.col}_{.fn}"
      )
    ) %>% 
    mutate(across(where(is.numeric), ~round(.x, 2)))
}

# ------------------------------------------------------------------------------
# Logging and Validation Functions
# ------------------------------------------------------------------------------

# Message template constants
.MESSAGE_TEMPLATES <- list(
  "dupes" = list(
    "success" = "No {type} duplicates found",
    "error" = "Found {count} {type} duplicates"
  ),
  "validity" = list(
    "success" = "All {type} are valid",
    "error" = "Found {count} invalid {type}"
  ),
  "missing" = list(
    "success" = "No missing {type} values",
    "error" = "Found {count} missing {type} values"
  ),
  "counts" = list(
    "success" = "All {type} meet requested counts",
    "error" = "Found {count} mismatches in {type}"
  ),
  "removal" = list(
    "success" = "No {type} to remove",
    "error" = "Found {count} records to remove due to {type}"
  )
)


# Helper function for consistent section logging
log_section_start <- function(title) cli_h2("{title} Validation")

# Helper function for consistent check results
log_check_result <- function(condition, type, check_type = "validation", data = NULL, row_message = NULL, count = NULL) {
  if (condition) {
    # Success message
    cli_alert_success(.MESSAGE_TEMPLATES[[check_type]][["success"]])
  } else {
    # Error message
    error_template <- .MESSAGE_TEMPLATES[[check_type]][["error"]]
    
    if (!is.null(count)) {
      cli_alert_danger(error_template)
      # Invisible return
      return(invisible())
    }
    
    count <- if (is.data.frame(data)) nrow(data) else length(data)
    cli_alert_danger(error_template)
    
    if (!is.null(data)) {
      if (is.data.frame(data)) {
        row_template <- ifelse(is.null(row_message), 
                               paste(names(row), row, sep = ": ", collapse = ", "),
                               row_message)
        walk(seq_len(nrow(data)), function(i) {
          row <- data[i,]
          cli_li(row_template)
        })
      } else {
        cli_li(if (is.null(row_message)) data else row_message)
      }
    }
  }
}

# Check for negative spend codes
check_negative_marketer_codes <- function(df, sp_code_no_negatives=.MARKETER_CODES_NO_NEGATIVES){
  log_section_start("Checking Negative and Zero Spends in Main Marketer Codes") 
  
  # Analyze spend patterns
  spend_analysis <- df %>%
    mutate(has_zero_neg_spend = account_spend <= 0) %>%
    group_by(marketer_code) %>%
    summarise(
      total_records = n(),
      zero_neg_records = sum(has_zero_neg_spend),
      pct_zero_neg = round(zero_neg_records / total_records * 100, 2)
    )
  
  # Validation and logging
  validation_results <- list()
  
  # Check unauthorized negative spends
  unauthorized_negatives <- spend_analysis %>%
    filter(marketer_code %in% sp_code_no_negatives, zero_neg_records > 0)
  
  if (nrow(unauthorized_negatives) > 0) {
    validation_results$unauthorized <- sprintf(
      "Marketer Code %s: %d/%d records (%.1f%%) have unauthorized zero/negative spend",
      unauthorized_negatives$marketer_code,
      unauthorized_negatives$zero_neg_records,
      unauthorized_negatives$total_records,
      unauthorized_negatives$pct_zero_neg
    )
    cli_warn(paste(validation_results$unauthorized, collapse = "\n"))
    cli_warn("ACTION REQUIRED: Obtain operations approval for exclusion")
  }
  
  # Check missing negative spends
  missing_negatives <- spend_analysis %>%
    filter(!marketer_code %in% sp_code_no_negatives, zero_neg_records == 0)
  
  if (nrow(missing_negatives) > 0) {
    validation_results$missing <- sprintf(
      "Marketer Code %s: Expected zero/negative spend not found in %d records",
      missing_negatives$marketer_code,
      missing_negatives$total_records
    )
    cli_warn(paste(validation_results$missing, collapse = "\n"))
    cli_warn("ACTION REQUIRED: Compare UC file suppression counts and verify sample distribution")
  }
  
  if (length(validation_results) == 0) {
    cli_alert_success("All spend patterns align with expectations")
  }
  
  return(validation_results)
}

# Check for overlap in open segment file
check_open_seg_overlap <- function(data, open_seg_data) {
  main_df_check <- data %>% filter(is_main) %>% semi_join(open_seg, by = "gmpi_base_cust_id")
  augment_df_check <- data %>% filter(!is_main) %>% semi_join(open_seg, by = "gmpi_base_cust_id")
  
  cli_h1("Overlap with Open Segment Check")
  
  
  log_section_start("Main Sample")
  if (nrow(main_df_check) > 0) {
    cli_warn("{nrow(main_df_check)} Customers in the main file appear in the new segment file")
    if (nrow(main_df_check) > 3000) {
      cli_warn("More than 3000 main file customers appear in the new segment. REPORT")
    } else{
      cli_alert_success(
        "Less than 3000 main file customers appear in the new segment. Note and explain these customers. No need to report"
      )
    }
  } else{
    cli_alert_success("No main file customers appear in the new segment")
  }
  log_section_start("Augment Sample")
  if (nrow(augment_df_check) > 0) {
    cli_warn(
      "{nrow(augment_df_check)} Customers in the augmented file appear in the new segment file"
    )
    if (nrow(augment_df_check) > 3000) {
      cli_warn("More than 3000 augmented file customers appear in the new segment. REPORT")
    } else{
      cli_alert_success(
        "Less than 3000 augmented file customers appear in the new segment. Note and explain these customers. No need to report"
      )
    }
  } else{
    cli_alert_success("No augmented file customers appear in the new segment")
  }
  
  return(list(main_check = main_df_check, augment_check = augment_df_check))
}

# Log and remove observations
remove_bad_sample <- function(data, to_remove, name){
  removal_count <- data %>%
    semi_join(to_remove, by = "gmpi_base_cust_id") %>%
    nrow()
  
  cli_alert_info("Removals due to {name}: {removal_count}")
  
  if(removal_count == 0) return(data)
  
  data %>% anti_join(to_remove, by = "gmpi_base_cust_id")
}

# ------------------------------------------------------------------------------
# Utility Functions
# ------------------------------------------------------------------------------
left_join_suppress <- function(x,y, ...){
  suppressMessages(left_join(x,y,...))
}

add_and_write_sheet <- function(wb, sheet_name, data){
  if (sheet_name %in% sheets(Diagnostic_WB)){
    cli_alert_info("Sheet {sheet_name} already present, overwriting data")
    removeWorksheet(wb, sheet_name)
  }
  addWorksheet(wb, sheet_name)
  writeData(wb, sheet_name, data)
}

# The cfrsuite package has been discontinued but we use this function. So defining it on my own.
# Basically the same as sprintf but just handles NA's
txt_sprintf <- function (fmt, ...) 
{
  x <- sprintf(fmt = fmt, ...)
  ldots <- list(...)
  if (length(ldots) > 0) {
    inputi <- order(sapply(ldots, length), decreasing = TRUE)
    make_na <- is.na(ldots[[inputi[1]]])
    if (length(ldots) >= 2) {
      for (i in inputi[-1]) {
        make_na <- make_na | is.na(ldots[[i]])
      }
    }
    x[make_na] <- NA_character_
  }
  x
}
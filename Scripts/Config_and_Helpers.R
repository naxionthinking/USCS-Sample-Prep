if (!require("pacman")) install.packages("pacman")

# Loads in necessary packages, and installs them if you don't have them installed
pacman::p_load("tidyverse",
               "glue",
               "readxl",
               "kableExtra",
               "knitr")

# Equivalent to python f-string
f_str <- function(str) str %>% glue() %>% as.character() 

# VARIABLES TO UPDATE
YEAR <- 2023
MONTH_NO <- 02

# Get the month name (i.e, "January")
MONTH <- month.name[MONTH_NO] 

# Get the 3 letter abbreviation (i.e, "JAN")
MONTH_SHORT <- month.abb[MONTH_NO] %>% str_to_upper() 

# Get previous month and year info for loading in raw data
PREV_MONTH_NO <- ifelse(MONTH_NO == 1, 12, MONTH_NO - 1)
PREV_MONTH_SHORT <-month.abb[PREV_MONTH_NO] %>% str_to_upper() 
PREV_YEAR_SHORT <- ifelse(MONTH_NO == 1, YEAR-1,YEAR) - 2000

# FILE PATHS TO UPDATE
# SAMPLE_PREP_PATH <- "../Sample_Prep_Helper_{MONTH_SHORT}_{YEAR}.xlsx" %>% f_str()
# 
# RAW_FILES_PATH <- '\\\\pm1/27-610/Sampling-Weighting/{YEAR}_{str_pad(MONTH_NO,2,pad="0")}/raw' %>% f_str()
# 
# BASE_PATH <- '{RAW_FILES_PATH}/LET.NATLANAL.X80A3.BASE.{PREV_MONTH_SHORT}{PREV_YEAR_SHORT}-cleaned.txt' %>% f_str()
# SPEND_PATH <- '{RAW_FILES_PATH}/LET.NATLANAL.X80A4.SPEND.{PREV_MONTH_SHORT}{PREV_YEAR_SHORT}-cleaned.txt' %>% f_str()
# 
# FILE_LOOKUPS <- "../../../File Lookups"
# OPEN_SEG_PATH <-       "{FILE_LOOKUPS}/Managed_2022_segment_SAT 06232022.csv"  %>% f_str()
# SUBJECT_LINE_PATH <-   "{FILE_LOOKUPS}/MarketVoice - Card Lookup20230124_ForAnalytics.csv"  %>% f_str()
# CENTURION_TIER_PATH <- "{FILE_LOOKUPS}/760_CENTURION_TIER_CVs.csv" %>% f_str()
# CARD_ART_PATH <-       "{FILE_LOOKUPS}/Card Art URLs 20230124.csv" %>% f_str()

# TESTING ABSOLUTE PATHS FOR JANUARY
SAMPLE_PREP_PATH <- "../Sample_Prep_Helper_{MONTH_SHORT}_{YEAR}.xlsx" %>% f_str()

RAW_FILES_PATH <- '\\\\pm1/27-610/Sampling-Weighting/{YEAR}_{str_pad(MONTH_NO,2,pad="0")}/raw' %>% f_str()

BASE_PATH <- '{RAW_FILES_PATH}/LET.NATLANAL.X80A3.BASE.{PREV_MONTH_SHORT}{PREV_YEAR_SHORT}-cleaned.txt' %>% f_str()
SPEND_PATH <- '{RAW_FILES_PATH}/LET.NATLANAL.X80A4.SPEND.{PREV_MONTH_SHORT}{PREV_YEAR_SHORT}-cleaned.txt' %>% f_str()

FILE_LOOKUPS <- "L:/Amex.549/Sample/2023/File Lookups" %>% f_str()
OPEN_SEG_PATH <-       "{FILE_LOOKUPS}/Managed_2022_segment_SAT 06232022.csv"  %>% f_str()
SUBJECT_LINE_PATH <-   "{FILE_LOOKUPS}/MarketVoice - Card Lookup20230124_ForAnalytics.csv"  %>% f_str()
CENTURION_TIER_PATH <- "{FILE_LOOKUPS}/760_CENTURION_TIER_CVs.csv" %>% f_str()
CARD_ART_PATH <-       "{FILE_LOOKUPS}/Card Art URLs 20230124.csv" %>% f_str()

# Check that a string doesn't match any non-letter
is_letters_only <- function(x) !grepl("[^A-Za-z]", x)

# Check that a string doesn't match any non-number
is_numbers_only <- function(x) !grepl("\\D", x)


get_first_num <- function(interval) stri_extract_first(interval, regex="[0-9]+")
get_last_num <- function(interval) stri_extract_last(interval, regex = "[0-9]+")

# Make a nice looking table for the output

make_nice_table <- function(tab, caption){
  
  knitr::kable(tab, format = "html",
               caption = paste("<center><strong>", caption, "</strong></center>"),
               escape = FALSE,
               booktabs = TRUE) %>% 
    kable_styling(bootstrap_options = "striped",
                  full_width = F, position = "center") %>% print()
  
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
  
  if (!is.null(caption)) make_nice_table(tab, caption)
  
  tab %>% return()
}


group_by_summary_table <- function(df, group_var, sum_var){
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


# LOADING IN DATA

# Because there is no delimiter in the text files, we need to use fixed widths for variables
# The data frame info is of the form VAR_NAME| NUM_SPACES | TYPE
# Where the number of spaces is the length of the variable, and the 
# Type is either "c" for character/text or "n" for numeric


load_base <- function(){
  
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
  
  
  readr::read_fwf(file = BASE_PATH,
                  #skip = 2,
                 col_positions = fwf_widths(df_info$col_widths),
                 col_types = paste0(df_info$col_types, collapse = ""),
                 na = c("")) %>% 
    set_names(str_to_lower(df_info$col_names)) %>% return()
  
  }


load_spend <- function(){
  
  df_info <- data.frame(c('rec',                 1,'c'),
                        c('BASE_ACCT_ID',       11,'c'),
                        c('REPL_NUMBER',         1,'n'),
                        c('BASIC_SUPP_NO',       2,'n'),
                        c('CHECK_DIGIT',         1,'n'),
                        c('CUSTOMER_ID',        19,'c'),
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
  
   readr::read_fwf(file = SPEND_PATH,
                   #skip = 2,
                   show_col_types = FALSE,
                   col_positions = fwf_widths(df_info$col_widths),
                   col_types = paste0(df_info$col_types, collapse = ""),
                   na = c("")) %>% 
     set_names(str_to_lower(df_info$col_names)) %>% return()
  
}




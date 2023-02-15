# USCS Sample Prep Documentation

# Folder Strcture

-   **Consumer BD**
    -   `Sample_Prep_Helper_MONTH_YEAR.xlsx` - Contains important infomration on requested frenquecies of the Cell Codes and Marketer Codes, weighting categories, and expected ranges of tenure and account spend for augment cells. This information is used for checking if the data lines up with what is requested.
    -   **Scripts** : Scripts for preparing samples
        -   `Config_and_Helpers.R` - Contains helper functions and file paths for the main scripts
        -   `Scripts.Rproj` : The Rstudio project that should be used to run the scripts
        -   `USCS_Prep_for_Weighting.html` - Output of the `USCS_Prep_for_Weighting.Rmd` script including information such as warnings on whether or not tests were passed and descriptive tables. This replaces the SAS log and lst files.
        -   `USCS_Prep_for_Weighting.Rmd` Takes raw text data, cleans it up, verifies frequencies are correct, creates new variables. Prepares sample for weighting. (Replaces steps 1 and 2)
        -   `USCS_Weighting.html` - Output of the `USCS_Weighting.Rmd` script including information such as warnings on whether or not tests were passed and descriptive tables. This replaces the SAS log and lst files.
        -   `USCS_Weighting.Rmd` - Segments the data based on desired weights and creates new variables. Also contains validation checks. (Replaces step 3)
    -   **Data** : Where all intermediary storage files are outputted. These are not used again in the scripts after they are outputted except for *unweighted_samples.Rdata* but are stored just in case.
        -   *base_MONTH_YEAR.csv* - Cleaned version of BASE text file
        -   *spend_MONTH_YEAR.csv* - Cleaned version of SPEND text file
        -   *all_MONTH_YEAR.csv* - Merged Base and Spend datasets with additional variables
        -   *augment_MONTH_YEAR.csv* - Unweighted augmented samples
        -   *main_MONTH_YEAR.csv* - Unweighted main samples
        -   *unweighted_samples_MONTH_YEAR.Rdata* - Contains augmented sample and main sample created by `USCS_Prep_for_Weighting.Rmd` for faster loading into `USCS_Weighting.Rmd`. This is just for convenience, the information is also in *main.csv* and *augment.csv*
    -   **Files_to_send** : Contains datasets that should be sent to project managers.
        -   *Amex_760_MONTH_YEAR_All_Sample_Frame_Information_Qualtrics_DATE.csv* - Final weighted dataset
        -   *Cell_Code_Freqs_MONTH_YEAR.csv* - Frequency table of Cell codes to be sent to the operations manager
        -   *Main_Code_Freqs_MONTH_YEAR.csv* - Main sample marketer code frequencies table to be sent to the operations manager
        -   *Tenure_or_Spend_Flagged_MONTH_YEAR.csv* - Contains observations with flags for deletion
            -   1 = Delete because Wrong Sp Code in Augment
            -   2 = Delete because High Tenure in Augment
            -   3 = Delete because Spend not \> \$0 in Augment

```{=html}
<!-- | MARKETER_CODE | Freq  | pct   | cum_freq | cum_pct |
| :---:         | :---: | :---: | :---:    | :---: |
| SP101         | 39922 | 12.54 | 39922    | 12.54 |
| SP103         | 4101  | 1.29  | 44023    | 13.83 | -->
```
# Preparatory Steps to do each Month

## Creating `Sample_Prep_Helper_MONTH_YEAR.xlsx`

The `Sample_Prep_Helper_MONTH_YEAR.xlsx` contains 3 sheets :

-   *Cell_Code_Freqs_Ranges* : Contains expected frequencies for each cell code and expected ranges for tenure and account spend for the augments
-   *Sp_Code_Freqs*: Contains expected frequencies for each marketer code
-   *Weighting_Segments*: Contains criteria for each weighting segment in terms of what their tenure, account spend, marketer code, and naw cell code are.

It is probably easiest to copy this workbook from last month into the new month's folder, change the name to reflect the current month and year, and do the changes inside the sheets. Here's how to create the sheets

1.  *Augment_Specs*

I'm not sure where this information originally comes from, but I have been extracting it from the **Augment Sample Checks** section of the *Main List* sheet of the `Sample Process Notes` excel document. Below is how I've been storing it in the *Augment_Specs* sheet.

<center>

| CELL_CODE | NAW_CELL_CODE | tenure_var_min | tenure_var_max | min_spend |
|:---------:|:-------------:|:--------------:|:--------------:|:---------:|
|  CNCE14   |    CELL14     |       5        |                | Any Spend |
|  CNPL18   |    CELL18     |       2        |       15       | Any Spend |
|  CNHH21   |    CELL21     |       3        |       15       |   \>\$0   |
|  CNDP22   |    CELL22     |       2        |       15       | Any Spend |
|  CNPR35   |    CELL35     |       2        |       4        | Any Spend |

</center>

2.  *Sp_Code_Freqs*

This is the easiest sheet to create. The information for this sheet is found in the *Global Criteria* sheet of the latest version of the excel file `MONTH_YEAR_MainFileBuildAugments_NA.xlsx` which can be found in the `requests` folder of the job drive for the current month. Then do the following:

-   Copy and paste the table beginning with the headers **SP Code**, **Card Name**, **Total Sample needed** and down to the row right above the summed total.
-   This is technically all that needs to be done as the script will remove the unnecesarry lines such as one that says "CCSG Prop Lend" in the Card Name as and has no information about Sp Code or Total Sample needed. But you can delete these lines in the excel sheet for clarity if desired. Here's an example of a few lines.

<center>

| SP Code |              Card Name              | Total Sample needed |
|:-------:|:-----------------------------------:|:-------------------:|
|   101   |           CCSG: Platinum            |        39922        |
|   149   |         CCSG: Classic Gold          |        8703         |
|   148   | CCSG: Traditional Gold With Rewards |        3728         |
|   103   |  CCSG: Traditional Gold No Rewards  |        4101         |

</center>

3.  *Weighting_Segments*

The weighting segments sheet corresponds to the sheet *YEAR-USCS Targets QUARTER* in the latest `Weighting Target Summary for OPEN and USCS` excel file.

-   Copy columns E-K into the *Weighting_Segments* sheet. These correspond to columns named **SP_Code**, **Tenure**, **Spend** **X**, and **Weighting_Segment**.
    -   Column **X** is not importance, hence the lack of name.
-   The scripts that perform the weighting DO NOT INFER ANYTHING. All required information must be present in the *Weighting_Segments* sheet prior to running the scripts. This means that extra information not contained in the `Weighting Target Summary` file must be included manually. I've only stumbled across two instances that require manual addition so far.
    -   Some Weighting Segments (i.e.,'ZX132ET' or 'ZX132HTHS') are only for a certain NAW_CELL_CODE (i.e, "CELL66"). This information is not included in the `Weighting Target Summary` file and thus would not be included in the *Weighting_Segments* sheet. This should manually be inputted into the column called **NAW_CELL_CODE**.
    -   Also all SP Codes for a given segment need to be specified in the **SP_Code** column. If it is not specified, specify them manually.
        -   For example. The Weighting Segment "Z01" is labelled under **SP_Code** as "Z01: CENTURION" and does not say it is only for SP 135. Thus, it should be changed to something like "Z01: SP 135; CENTURION". Multiple SP Codes can be specified for the same segment too. The script will extract all 3 digit numbers and treat them as SP Codes

Additional checks for this sheet:

-   If there is no minimum or maximum tenure or account spend, the cell should be left blank or should contain "n/a".
    -   For example, a new segment was created for marketer code 158 for all values. The `Weighting Target Summary` file listed the tenure range as "Any Tenure" and spend range as "Any Spend". These were then manually changed to n/a in the *Weighting_Segments* sheet. They could also be deleted and left as blank cells.
-   I also tend to delete blank rows or rows calculating totals. The script can automatically remove these, but it's cleaner to have them removed in the excel file itself.

Here are a few examples of the different cases; most of which are straight copy paste from the `Weighting Target Summary` file.

<center>

|                         SP_Code                          | Tenure  |   Spend   |   X    | Weighting_Segment | NAW_CELL_CODE |
|:--------------------------------------------------------:|:-------:|:---------:|:------:|:-----------------:|:-------------:|
|                   Early Tenure: SP 101                   | \<5 mos |    n/a    | 98242  |       ET11        |               |
| Early Tenure (Other Prop Lend) = 111, 112, 114, 115, 118 | \<5 mos |    n/a    |   20   |       ET35        |               |
|        SP101HTHS: SP 101; High tenure; High spend        | 73 mos+ | \$35,000+ | 649235 |     SP101HTHS     |               |
|                  Z01: SP 135; CENTURION                  |   n/a   |    n/a    | 19424  |        Z01        |               |
|                   Early Tenure: SP 132                   | \<5 mos |    n/a    | 97931  |      ZX132ET      |    CELL66     |
|        SP132HTHS: SP 132; High tenure; High spend        | 73 mos+ | \$2,500+  | 846443 |     ZX132HTHS     |    CELL66     |

</center>

## Changes inside of Scripts

The Major changes to be done each month are for the current date, and file paths. These are located in `Config_and_Helpers.R` script. All variables to update are all the top of the script. The path variables are either absolute or relative paths to the files necessary for the script. \> Ideally, I'd love if there was consistent naming and usage of these files and it could all be loaded in dynamically based on the YEAR and MONTH, but that doesn't seem to be the case since some files are from months ago and some have small changes to their names. That's why some of them look a little wonky at the moment. I've dynamicized parts of them, but it's not consistent so it looks a little messy.

Theoretically only the lines highlighted in red should need to be changed, and not all need to be updated each month.

<center><img src="https://raw.githubusercontent.com/Beck-DeYoung-NA/USCS-Sample-Prep/main/Readme_Icons/Config_What_To_Edit.png"/></center>

Other changes to the scripts are dependent on the needs of the given month. Hopefully once we identify what is commonly changed, we can dynamically account for those in configuration rather than changing what is hard coded. But obviously, right now, things need to be changed in the code itself.

### *Possible locations for changes*

Find these by clicking on the tab right above the Console that probably says \# USCS Read Step 1. Then find the named chunks that are specified below.

<center><img src="https://raw.githubusercontent.com/Beck-DeYoung-NA/USCS-Sample-Prep/main/Readme_Icons/Chunk%20Selection.png"/></center>

`USCS_Prep_for_Weighting.Rmd` 1. **Flag for Deleting Cases**: Chunk `FLAG DELETION` 2. **Changing Subject Line Definition for Augment**: Chunk `SUBJECT LINE`

`USCS_Weighting.Rmd`

3.  **New Variable Creation/Adjustment**: Chunk `NEW VARIABLES`

# Creating the Ouput and Running the Scripts

## Running the Scripts

1.  First run through `USCS_Prep_for_Weighting.Rmd`.
    -   I would suggest running the script a few chunks at a time when first getting the data instead of running the entire script at once. The markdown files generate the output in real time and do it in line. So if you run a certain chunk (hitting the green play button), it will produce the output below the cell. The variables will also all be stored and generated in the environment tab on the right, which makes for easy debugging and problem identification. Everything is chronological and self-contained, so no back and forth between excel and R.
    -   Importantly, any chunk can be run at any time, but will not work properly if the variables required for the chunk have not been created yet. So if you want to run Chunk 10, make sure to run Chunks 1-9 first. But once you have run Chunks 1-10, you can rerun any of them and regenerate the output.
    -   Once you've made it through the entire script without worrying warnings (i.e., all problems have been identified and remedied or noted), then you will knit it to an html document. Click on the arrow next to Knit and select "Knit to HTML". This will run the entire script in the background and generate the output as an HTML. If there were any errors or warnings in the code that prevent it from fully running, then the output will not be generated. So those need to be dealt with first.

<center><img src="https://raw.githubusercontent.com/Beck-DeYoung-NA/USCS-Sample-Prep/main/Readme_Icons/Knit.png"/></center>

1.  Then run through `USCS_Weighting.Rmd` the same way.

## Output

Currently, the script is outputted an HTML file that contains all the generated tables, warnings if checks are not passed, and success messages if the checks are passed. \> The warnings indicate a check is not met. These will be printouts with "Warning:" before them. If a check is passed, a message will be printed with "SUCCESS:" before it. If any warnings are printed, figure out why and report if the warning says to.

The scripts also output csv files that need to be emailed to project managers. See the `Folder Structure` section to see what is outputted. The HTML file does not include any of the code, but it does currently include the instructions of how to use the script, which does look a little odd when the code is not included. Knowing who the audience is for the output can help me tailor the information that is provided.

I can also add more descriptive statements for the outputs, such as

> "Currently checking if the observed frequencies of each cell code match the requested frequencies:"

>   "SUCCESS: Observed and requested frequencies match for the cell codes"

### **Beck's Questions**

<center>`USCS_Prep_for_Weighting`</center>

**Line 79**: Is any cell code that does not start with "CCSG" considered an augment? I currently have an extra condition saying that augments start with "C" but not "CCSG". If it is the case that every non-CCSG code is an augment, then we can update lines 99-100.

**Lines 144-149** : This code checks for missing marketer codes, but is unnecessary because we already filter out blank marketer codes before. I'm happy to remove this check if you guys approve.

**Lines 369-377** : In the SAS code and excel file, there is a check for the DMA frequency. I'm not sure what is happening in this check, so I was never able to code it up in R.

**Lines 711-728** : This checks if the cell code frequencies for the augment cells are the same as before segmented the data. This seems unnecessary because these numbers are generated from the same dataset just with one having SP138 and 139 removed. Is this the problem this is checking for?

/*****************************************************************************
 * Program:     00_import_data.sas
 * Section:     4 — Import Data into SAS
 * Purpose:     Load the Telco Customer Churn CSV file into a SAS dataset
 *              and establish the project library structure.
 * Dataset:     WA_Fn-UseC_-Telco-Customer-Churn.csv (renamed to telco_churn.csv)
 * Input:       Data/Raw/telco_churn.csv
 * Output:      CHURN.raw_telco (SAS dataset)
 * Author:      [Your Name]
 * Date:        [Date]
 * SAS Version: SAS 9.4 / SAS Studio / SAS Viya
 *****************************************************************************/

/*==========================================================================
  STEP 0: Define Project Paths and Libraries
  
  EXPLANATION:
  A SAS "library" (LIBNAME) is a named reference to a physical folder.
  It lets you permanently store datasets so they survive between sessions.
  Without a LIBNAME, SAS puts data in the temporary WORK library, which
  is deleted when your session ends.
  
  Change the path below to match where you saved the project on your system.
==========================================================================*/

/* --- EDIT THIS PATH to your project location --- */
%let project_path = /home/your_username/SAS_Churn_Project;

/* Create the project folder structure if it doesn't exist */
options dlcreatedir;

libname CHURN "&project_path./Data/Processed";
libname RAW   "&project_path./Data/Raw";

/* Verify the libraries are assigned */
proc sql;
    select libname, path 
    from dictionary.libnames 
    where libname in ('CHURN', 'RAW');
quit;

/*==========================================================================
  STEP 1: Import CSV Data
  
  EXPLANATION:
  PROC IMPORT reads external files (CSV, Excel, etc.) and converts them 
  to SAS datasets. Key options:
  - DATAFILE  = path to the source file
  - DBMS      = file type (CSV, XLSX, etc.)
  - OUT       = output SAS dataset name (library.dataset)
  - GETNAMES  = YES means the first row contains column headers
  - GUESSINGROWS = MAX tells SAS to scan ALL rows before deciding 
    data types (prevents misclassification on small samples)
==========================================================================*/

proc import 
    datafile = "&project_path./Data/Raw/telco_churn.csv"
    dbms     = csv
    out      = CHURN.raw_telco
    replace;
    getnames     = yes;
    guessingrows = max;
run;

/*==========================================================================
  STEP 1b: Alternative — Import from Excel (if your file is .xlsx)
  
  Uncomment the block below if you have an Excel file instead of CSV.
==========================================================================*/

/*
proc import 
    datafile = "&project_path./Data/Raw/telco_churn.xlsx"
    dbms     = xlsx
    out      = CHURN.raw_telco
    replace;
    getnames = yes;
    sheet    = "Sheet1";
run;
*/

/*==========================================================================
  STEP 1c: Alternative — Manual DATA step import (more control)
  
  This approach gives you explicit control over variable types, lengths,
  informats, and labels. Use this when PROC IMPORT guesses types incorrectly.
==========================================================================*/

/*
data CHURN.raw_telco;
    infile "&project_path./Data/Raw/telco_churn.csv" 
           dsd 
           firstobs=2 
           missover;
    
    length customerID      $12
           gender           $8
           Partner          $4
           Dependents       $4
           PhoneService     $4
           MultipleLines    $20
           InternetService  $16
           OnlineSecurity   $24
           OnlineBackup     $24
           DeviceProtection $24
           TechSupport      $24
           StreamingTV      $24
           StreamingMovies  $24
           Contract         $16
           PaperlessBilling $4
           PaymentMethod    $32
           Churn            $4;
    
    input customerID      $
          gender           $
          SeniorCitizen
          Partner          $
          Dependents       $
          tenure
          PhoneService     $
          MultipleLines    $
          InternetService  $
          OnlineSecurity   $
          OnlineBackup     $
          DeviceProtection $
          TechSupport      $
          StreamingTV      $
          StreamingMovies  $
          Contract         $
          PaperlessBilling $
          PaymentMethod    $
          MonthlyCharges
          TotalCharges     $
          Churn            $;
    
    label customerID       = "Unique Customer ID"
          gender           = "Customer Gender"
          SeniorCitizen    = "Senior Citizen (1=Yes, 0=No)"
          Partner          = "Has Partner (Yes/No)"
          Dependents       = "Has Dependents (Yes/No)"
          tenure           = "Months with Company"
          PhoneService     = "Has Phone Service (Yes/No)"
          MultipleLines    = "Has Multiple Lines"
          InternetService  = "Internet Service Type"
          OnlineSecurity   = "Has Online Security"
          OnlineBackup     = "Has Online Backup"
          DeviceProtection = "Has Device Protection"
          TechSupport      = "Has Tech Support"
          StreamingTV      = "Has Streaming TV"
          StreamingMovies  = "Has Streaming Movies"
          Contract         = "Contract Type"
          PaperlessBilling = "Uses Paperless Billing (Yes/No)"
          PaymentMethod    = "Payment Method"
          MonthlyCharges   = "Monthly Charge Amount ($)"
          TotalCharges     = "Total Charges to Date ($)"
          Churn            = "Churned (Yes/No)";
run;
*/

/*==========================================================================
  STEP 2: Quick Verification — Confirm the Import
==========================================================================*/

/* 2a. View the first 10 rows */
proc print data=CHURN.raw_telco (obs=10);
    title "First 10 Rows of Telco Customer Churn Data";
run;

/* 2b. Check number of rows and columns */
proc sql;
    select nobs as Total_Rows, 
           nvar as Total_Columns
    from dictionary.tables
    where libname = 'CHURN' and memname = 'RAW_TELCO';
quit;

/* Expected: 7,043 rows and 21 columns */

/* 2c. View variable names, types, and lengths */
proc contents data=CHURN.raw_telco varnum;
    title "Variable Metadata for raw_telco";
run;

/*==========================================================================
  STEP 3: Understanding the SAS Library/Table Structure
  
  HOW SAS ORGANIZES DATA:
  
  ┌──────────────────────────────────────────────┐
  │                SAS Session                    │
  │                                               │
  │  ┌─────────┐  ┌─────────┐  ┌──────────────┐ │
  │  │  WORK   │  │  CHURN  │  │    RAW       │ │
  │  │ (temp)  │  │ (perm)  │  │   (perm)     │ │
  │  │         │  │         │  │              │ │
  │  │ Tables  │  │ Tables  │  │  Tables      │ │
  │  │ deleted │  │ saved   │  │  saved       │ │
  │  │ on exit │  │ to disk │  │  to disk     │ │
  │  └─────────┘  └─────────┘  └──────────────┘ │
  └──────────────────────────────────────────────┘
  
  - WORK:  Temporary library. Data lost when session ends.
  - CHURN: Our permanent library. Points to Data/Processed/ folder.
  - RAW:   Our permanent raw data library. Points to Data/Raw/ folder.
  
  Naming convention: LIBRARY.TABLE_NAME
  Example: CHURN.raw_telco = the table "raw_telco" in the CHURN library
  
  Each SAS table is stored as a .sas7bdat file on disk.
==========================================================================*/

title;  /* Clear titles */

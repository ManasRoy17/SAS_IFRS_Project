/* IFRS Assignment */

LIBNAME ifrs "/home/u63835816/sasuser.v94/IFRS";

/* input sheet */

proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOANS.xlsx"
    out=ifrs.s6t1
    dbms=xlsx
    replace;
    sheet="Input Sheet";
    getnames=yes;
    range="A2:Z232";
run;

/* lookup table sheet */
proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOANS.xlsx"
    out=ifrs.s10t5
    dbms=xlsx
    replace;
    sheet="Lookup Table";
    getnames=yes;
    range="J33:K176";
run;

proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOANS.xlsx"
    out=ifrs.s10t6
    dbms=xlsx
    replace;
    sheet="Lookup Table";
    getnames=yes;
    range="M33:N173";
run;

/* Rating lookup sheet */
proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx"
    out=ifrs.s7t
    dbms=xlsx
    replace;
    sheet="Rating lookup Copy";
    getnames=yes;
    range="B2:I26";
run;

proc print data=ifrs.s10t5 noobs;
run;

proc print data=ifrs.s6t1 noobs;
run;

/* Adding Moody's Current Rating from S10T5 to S6T1 */

proc sort data=ifrs.s10t5;
    by Country;
run;

proc sort data=ifrs.s6t1;
    by COUNTRY;
run;

proc print data=ifrs.s6t1 noobs;
run;

/* Inspect variable types in s6t1 */
proc contents data=ifrs.s6t1;
run;

/* Inspect variable types in s10t5 */
proc contents data=ifrs.s10t5;
run;

data work.s6t1;
    length Moodys_Current_Rating $32; /* Define the length of the character variable */
    merge work.s6t1 (in=a)
    	  
		  work.s10t5 (in=b); /* Adjust variable name if needed */
    by country;
    if a; /* Keep only records from s6t1 */
    Moodys_Current_Rating = Rating;
run;

data work.s10t5;
	set ifrs.s10t5;
	Country=strip(Country);
run;

proc print data=work.s6t1;
var COUNTRY Rating;
run;

proc sql;
	Create Table work.s6t1 as
	Select a.*,b.Rating
	from ifrs.s6t1 as a
	Left Join ifrs.s10t5 as b
	on a.COUNTRY=b.Country
	Order by COUNTRY;
quit;

proc sql;
	update work.s6t1
	set Rating="B3"
	where Rating is null;
quit;

data work.s6t1;
	set work.s6t1(rename=(Rating=Moodys_Current_Rating));
run;

proc print data=work.s6t1;
run;

data ifrs.s6t1_modified;
	set work.s6t1;
run;

/* Adding Moody's Current Numeral on S6T1 from S7T */

proc contents data=ifrs.s7t;
run;

proc contents data=ifrs.s6t1_modified;
run;

proc print data=ifrs.s6t1_modified;
run;

proc print data=ifrs.s7t;
var "Moody's Long-term"n;
run;

proc sql;
	Create Table work.s6t1_test as 
	Select a.*, b.Score
	from ifrs.s6t1_modified as a
	left join ifrs.s7t as b
	on a.Moodys_Current_Rating=b."Moody's Long-Term"n;
quit;

proc contents data=work.s6t1_test;
run;

proc sql;
	update work.s6t1_test
	set Score=15
	where Score is null;
quit;

data ifrs.s6t1_modified;
	set work.s6t1_test(rename=(Score=Moodys_Current_Numeral));
run;

proc print data=ifrs.s6t1_modified;
run;

/* Adding Moody's Initial Rating to S6T1 from S10T6 */

proc contents data=ifrs.s10t6;
run;

proc contents data=ifrs.s6t1_modified;
run;

proc sort data=ifrs.s10t6;
	by Country;
run;

proc print data=ifrs.s6t1_modified;
run;

proc sql;
	Create Table work.s6t1_test as 
	Select a.*, b.Rating
	from ifrs.s6t1_modified as a
	left join ifrs.s10t6 as b
	on a.COUNTRY=b.Country
	order by COUNTRY;
quit;

proc contents data=work.s6t1_test;
run;

proc sql;
	update work.s6t1_test
	set Rating='B3'
	where Rating is null;
quit;

data ifrs.s6t1_modified;
	set work.s6t1_test(rename=(Rating=Moodys_Initial_Rating));
run;

proc print data=ifrs.s6t1_modified;
run;

proc contents data=ifrs.s6t1_modified;
run;

/* Adding Moody's Initial Numeral to S6T1 from S7T */

proc contents data=ifrs.s7t;
run;

proc contents data=ifrs.s6t1_modified;
run;

proc print data=ifrs.s6t1_modified;
run;

proc print data=ifrs.s7t;
var "Moody's Long-term"n;
run;

proc sql;
	Create Table work.s6t1_test as 
	Select a.*, b.Score
	from ifrs.s6t1_modified as a
	left join ifrs.s7t as b
	on a.Moodys_Initial_Rating=b."Moody's Long-Term"n;
quit;

proc contents data=work.s6t1_test;
run;

proc sql;
	update work.s6t1_test
	set Score=15
	where Score is null;
quit;

data ifrs.s6t1_modified;
	set work.s6t1_test(rename=(Score=Moodys_Initial_Numeral));
run;

/* data ifrs.s6t1_modified(drop=Moodys_Initial_Rating Moodys_Initial_Numeral); */
/* 	set ifrs.s6t1_modified; */
/* run; */

proc print data=ifrs.s6t1_modified noobs;
run;

/* Finding Notch Downgrade value by Subtracting Moodys_Current_Numeral from Moodys_Initial_Numeral */

data work.s6t1_test;
    set ifrs.s6t1_modified;
    if Moodys_Current_Numeral - Moodys_Initial_Numeral < 0 then Notch_Downgrade = 0;
    else Notch_Downgrade = Moodys_Current_Numeral - Moodys_Initial_Numeral;
run;

data ifrs.s6t1_modified;
    set work.s6t1_test;
run;

proc print data=ifrs.s6t1_modified noobs;
run;

/* Sheet 6 Table 1 Formulation is Complete */

*************************************************************************************************************************************************;

/* Loading S10T1 for Creating S6T2 */

proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx"
    out=ifrs.s10t1
    dbms=xlsx
    replace;
    sheet="Lookup Table";
    getnames=yes;
    range="B2:C10";
run;

PROC PRINT DATA=IFRS.S10T1 NOOBS;
RUN;

/* Loading S10T4 for Creating S6T2 */

proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx"
    out=ifrs.s10t4
    dbms=xlsx
    replace;
    sheet="Lookup Table";
    getnames=yes;
    range="J3:K27";
run;

PROC PRINT DATA=IFRS.S10T4 NOOBS;
RUN;

/* Importing S10T2 from The Excel */

proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx"
    out=ifrs.s10t2
    dbms=xlsx
    replace;
    sheet="Lookup Table";
    getnames=yes;
    range="B12:B82";
run;

/* Adding Discount Rate to S10T2 from S6T1 */

data work.s10t2_test;
	set ifrs.s10t2;
run;


data work.s6t1_test(Keep=COUNTRY INTEREST);
	set ifrs.s6t1_modified;
RUN;

proc print data=work.s6t1_test noobs;
run;

proc print data=work.s10t2_test;
run;

proc sql;
    create table ifrs.s10t2_final as
    select 
        a.Country,
        mean(b.INTEREST)/100 as Discount_Rate format=percent8.2
    from 
        work.s10t2_test as a
    left join 
        work.s6t1_test as b
    on 
        a.Country = b.COUNTRY
    group by 
        a.Country
    ;
quit;

/* Creating S6T2 from S10T1, S10T4, S10T2, S6T1 and lastly S5 B1 value(Reporting_Date) */

proc print data=ifrs.s10t1 noobs;
run;

proc print data=ifrs.s10t4 noobs;
run;

proc print data=ifrs.s10t2_final noobs;
run;

proc contents data=ifrs.s6t1_modified;
run;

data work.s6t2_test(keep=PROJ_ENG_NAME Loan Reporting_Date 'First Principal  Date'n 'First Interest  Date'n 'Settlement Year'n);
	set ifrs.s6t1_modified;
	Reporting_Date=&report_date;
	format Reporting_Date MMDDYY10.;
run;

proc sql;
	create table work.s6t2_test2 as
	select PROJ_ENG_NAME, Loan, Reporting_Date, 'First Principal  Date'n, 'First Interest  Date'n, 'Settlement Year'n
	from work.s6t2_test;
quit;

data s6t2_test3(keep=PROJ_ENG_NAME Loan Reporting_Date 'First Principal  Date'n 'First Interest  Date'n 'Settlement Year'n MATURITY_DATE_1
				SANCTIONED_AMT WITHDRAWN_AMT);
    set ifrs.s6t1_modified;
    Reporting_Date= &report_date;
	format Reporting_Date MMDDYY10.;
    
	 if missing(MATURITY_DATE) then do;
        MATURITY_DATE_1 = intnx('month', 'First Principal Date'n, 'Settlement Year'n*12, 'E');
    end;
    else do;
        MATURITY_DATE_1 = MATURITY_DATE;
    end;
    
    /* Assuming OUTSTANDING_PRINCIPAL and ACCRUED_INTEREST are columns */
    /* Calculate the sum of OUTSTANDING_PRINCIPAL and ACCRUED_INTEREST */
    sum_Q3_R3 = sum(OUTSTANDING_PRINCIPAL, ACCRUED_INTEREST);
    
    /* Format the date variable */
    format MATURITY_DATE_1 MMDDYY10.;
run;

/* Assigning the S5 B1 Value in a macro */

%let report_date = '31DEC2018'd;

data work.s6t2_test4(keep=PROJ_ENG_NAME Loan Reporting_Date 'First Principal  Date'n 'First Interest  Date'n 'Settlement Year'n MATURITY_DATE_1
				SANCTIONED_AMT WITHDRAWN_AMT Future_Disbursment_Amount 'Disbursment Frequency'n 'Principal Payment Frequency'n 
				'Interest payment Frequency'n);
    set ifrs.s6t1_modified;
    
	/*Calling Reporting Date */
    Reporting_Date=&report_date;
	format Reporting_Date MMDDYY10.;
	
    /*Calculating Maturity Date */
	if missing(MATURITY_DATE) then do;
        MATURITY_DATE_1 = intnx('month', 'First Principal Date'n, 'Settlement Year'n*12, 'E');
    end;
    else do;
        MATURITY_DATE_1 = MATURITY_DATE;
    end;
    
    /* Assuming OUTSTANDING_PRINCIPAL and ACCRUED_INTEREST are columns */
    /* Calculate the sum of OUTSTANDING_PRINCIPAL and ACCRUED_INTEREST */
    sum_Q3_R3 = sum(OUTSTANDING_PRINCIPAL, ACCRUED_INTEREST);
    
    /* Format the date variable */
    format MATURITY_DATE_1 MMDDYY10.;
    /* Maturity Date Calculation Over */
    
	/* Future Disbursment Amount Calculation */
    if 'Future Disbursment Flag'n = "No" then 
        Future_Disbursment_Amount = 0;
    else 
        Future_Disbursment_Amount = SANCTIONED_AMT - WITHDRAWN_AMT;
    Format Future_Disbursment_Amount SANCTIONED_AMT WITHDRAWN_AMT comma15.2;

run;

/* Loading S10T1 for Creating S6T2 but only uptil C9 not C10 */

proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx"
    out=ifrs.s10t1_c9
    dbms=xlsx
    replace;
    sheet="Lookup Table";
    getnames=yes;
    range="B2:C9";
run;


/* Calculation Disbursement Frequency for S6t2 from S10T1 */

proc sql;
    create table work.s6t2_test09 as
    select a.*, b.'Lookup Number (Repayment every Y'n as Disbursement_Frequency
    from work.s6t2_test08 as a
    left join ifrs.s10t1 as b
    on a.'Disbursment Frequency'n = b.'Payment Frequency Type'n;
quit;

/* Calculation Principal Payment Frequency for S6t2 from S10T1 */

proc sql;
    create table work.s6t2_test10 as
    select a.*, b.'Lookup Number (Repayment every Y'n as Principal_Payment_Frequency
    from work.s6t2_test09 as a
    left join ifrs.s10t1_c9 as b
    on a.'Principal Payment Frequency'n = b.'Payment Frequency Type'n;
quit;

/* Calculation Interest Payment Frequency for S6t2 from S10T1 */

proc sql;
    create table work.s6t2_test11 as
    select a.*, b.'Lookup Number (Repayment every Y'n as Interest_Payment_Frequency
    from work.s6t2_test10 as a
    left join ifrs.s10t1_c9 as b
    on a.'Interest payment Frequency'n = b.'Payment Frequency Type'n;
quit;

data work.s6t2_test17(drop='Interest payment Frequency'n);
	set work.s6t2_test16;
run;

proc contents data=work.s6t2_test2;
run;

proc print data=work.s6t2_test5;
run;

/* Backup till Interest_Payment_Frequency_1 */
data ifrs.s6t2_modified;
	set work.s6t2_test17;
run;

proc print data=ifrs.s6t2_modified;
run;

proc print data=ifrs.s6t1_modified;
run;

%let Regulatory_LGD = 0.45;

/* data work.s6t2_test_01(keep=PROJ_ENG_NAME Loan 'First Principal  Date'n 'First Interest  Date'n 'Settlement Year'n  */
/* 	set ifrs.s6t1_modified; */

data work.s6t2_test08 (rename=(SANCTIONED_AMT=Sanction_Amount 
	 WITHDRAWN_AMT=Withdrawal_Amount
	 OUTSTANDING_PRINCIPAL=Principal_Amount
	 Moodys_Current_Rating=Current_Rating
	 ));
/* 	(keep=PROJ_ENG_NAME Loan Reporting_Date 'First Principal Date'n 'First Interest Date'n 'Settlement Year'n MATURITY_DATE_1  */
/*     SANCTIONED_AMT WITHDRAWN_AMT Future_Disbursment_Amount 'Disbursment Frequency'n  */
/*     'Principal Payment Frequency'n 'Interest payment Frequency'n OUTSTANDING_PRINCIPAL INTEREST ACCURED_INTEREST  */
/*     'Moodys Current Rating'n COUNTRY Moodys_Current_Numeral Moodys_Initial_Numeral Notch_Downgrade MATURITY_DATE  */
/*     'Restructure Flag'n 'Default Flag'n 'High Risk Project'n 'Loan Type'n LGD */
/*     rename=( */
/*         SANCTIONED_AMT=Sanction_Amount  */
/*         WITHDRAWN_AMT=Withdrawal_Amount  */
/*         OUTSTANDING_PRINCIPAL=Principal_Amount  */
/*         INTEREST=Interest_Rate  */
/*         ACCURED_INTEREST=Accured_Interest  */
/*         'Moodys Current Rating'n=Current_Rating  */
/*         COUNTRY=Country */
/*     ) */
/* ); */
	set ifrs.s6t1_modified;
    
	/*Calling Reporting Date */
    Reporting_Date=&report_date;
	format Reporting_Date MMDDYY10.;
	
    /*Calculating Maturity Date */
	if missing(MATURITY_DATE) then do;
        MATURITY_DATE_1 = intnx('month', 'First Principal Date'n, 'Settlement Year'n*12, 'E');
    end;
    else do;
        MATURITY_DATE_1 = MATURITY_DATE;
    end;
    
    /* Format the date variable */
    format MATURITY_DATE_1 MMDDYY10.;
    /* Maturity Date Calculation Over */
    
	/* Future Disbursment Amount Calculation */
    if 'Future Disbursment Flag'n = "No" then do;
        Future_Disbursment_Amount = 0;
    end;
    else do;
        Future_Disbursment_Amount = SANCTIONED_AMT - WITHDRAWN_AMT;
    *Format Future_Disbursment_Amount Sanction_Amount Withdrawal_Amount comma15.2;
    end;
    
    Interest_Rate = round(INTEREST, 1);
    Interest_Rate = Interest_Rate / 100;
    format Interest_Rate PERCENTN8.0;
        
    LGD = &Regulatory_LGD;
    format LGD PERCENT8.0;
    
    /* Replicating the Excel formula */
    if Moodys_Initial_Numeral <= 10 and Notch_Downgrade >= 2 and Moodys_Current_Numeral > 10 then
        Downgrade_Staging = 2;
    else if Moodys_Initial_Numeral > 10 and Notch_Downgrade >= 1 then
        Downgrade_Staging = 2;
    else
        Downgrade_Staging = 1;
    
    if 'Restructure Flag'n = "Yes" then
        Restructure_Stage = 2;
    else
        Restructure_Stage = 1;
        
    /* Replicating the Excel formula */
    if MATURITY_DATE < &report_date and 'Restructure Flag'n = "No" then
        Payment_Default_Staging = 3;
    else if 'Default Flag'n = "Yes" then
        Payment_Default_Staging = 2;
    else
        Payment_Default_Staging = 1;
        
    if 'High Risk Project'n = "Yes" then
        Management_Staging = 3;
    else
        Management_Staging = 1;
        
    /* Calculate the maximum value across columns BA to BE */
    *max_value = max(of Current_Rating_Staging, Downgrade_Staging, Restructure_Stage, Payment_Default_Staging, Management_Staging);

    /* Replicating the Excel formula */
/*     if max_value = 2 then */
/*         stage = "Stage 2"; */
/*     else if max_value = 3 then */
/*         stage = "Stage 3"; */
/*     else */
/*         stage = "Stage 1"; */

run;

/* Adding Discount Rate in S6T2 from S10T2 */

proc sql;
	Create Table work.s6t2_test12 as 
	select a.*, b.Discount_Rate 
	from work.s6t2_test11 as a 
	Left Join ifrs.s10t2_final as b 
	on a.COUNTRY=b.Country
	order by a.COUNTRY;
QUIT;

/* Adding Current Rating Staging to S6T2 from S10T4 */
proc sql;
	Create Table work.s6t2_test13 as 
	select a.*, b.'Final Score Staging'n as Current_Rating_Staging
	from work.s6t2_test12 as a 
	Left Join ifrs.s10t4 as b 
	on a.Current_Rating=b."Moody's Rating"n
	order by a.COUNTRY;
QUIT;

proc print data=work.s6t2_test08;
run;

proc contents data=ifrs.s10t4;
run;

PROC contents DATA=work.s6t2_test14;
run;

data=work.s6t2_test15;
	
/* Creating the Final Stage Column */

data work.s6t2_test14;
	set work.s6t2_test13;
    
    max_value = max(of Current_Rating_Staging,Downgrade_Staging,Restructure_Stage,Payment_Default_Staging,Management_Staging);

    /* Replicating the Excel formula */
    if max_value = 2 then
        Final_Stage = "Stage 2";
    else if max_value = 3 then
        Final_Stage = "Stage 3";
    else
        Final_Stage = "Stage 1";
run;

/* backup till ECL_Calculation */
/* data ifrs.s6t2_modified02; */
/* 	set work.s6t2_test15; */
/* run; */

/* Creating ECL_Calculation Column in S6T2 (Note: Here the value for ECL Calculation if No then there is a space in "No " as the length */
/* of the first value specifies the length permanently */
data work.s6t2_test15;
	set work.s6t2_test14;
	Length ECL_Calculation $3.;
    /* Replicate the Excel formula using SAS syntax */
    if ('First Interest Date'n < Reporting_Date and Principal_Amount <= 0) or ('Loan Type'n = "Grant") then
        ECL_Calculation = "No ";
    else
        ECL_Calculation = "Yes";

    /* Rename or format the new variable if necessary */
	/* format ECL_Calculation $3.; */
run;

proc contents data=ifrs.s6t2_modified02;
run;

data ifrs.s6t2_modified03(keep=PROJ_ENG_NAME Loan Reporting_Date 'First Principal Date'n 'First Interest Date'n 'Settlement Year'n MATURITY_DATE_1 
					  Sanction_Amount Withdrawal_Amount Future_Disbursment_Amount Disbursement_Frequency Principal_Payment_Frequency Interest_Payment_Frequency
					  Principal_Amount Interest_Rate ACCRUED_INTEREST Current_Rating Discount_Rate LGD COUNTRY Current_Rating_Staging Downgrade_Staging
					  Restructure_Stage Payment_Default_Staging Management_Staging Final_Stage ECL_Calculation);

	set ifrs.s6t2_modified03;
run;

/* Final S6T2 TABLE COMPLETE */
data ifrs.s6t2_final;
	set ifrs.s6t2_modified03;
run;

/* Sheet6 Table 2 Assembled and Complete */

*************************************************************************************************************************************************;

/* Sheet 1 Computation */

/* Importing S5T1 from Excel */

proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx"
    out=ifrs.s5t1
    dbms=xlsx
    replace;
    sheet="ECL Calculation";
    getnames=yes;
    range="A3:Z111";
run;

PROC PRINT DATA=ifrs.s5t1;
run;

proc sql;
    /* Creating the summary table for each stage */
    create table summary_stage as
    select 
        'Stage 1' as Stage,
        sum(case when 'Final Stage'n = 'Stage 1' then 'Principal Amount'n else 0 end) as Principal_Amount format=comma20.2,
        sum(case when 'Final Stage'n = 'Stage 1' then 'Future Interest Amount'n else 0 end) as Total_Interest_Amount format=comma20.2,
        sum(case when 'Final Stage'n = 'Stage 1' then 'Final ECL'n else 0 end) as Final_ECL format=comma20.2
    from ifrs.s5t1
    union all
    select 
        'Stage 2' as Stage,
        sum(case when 'Final Stage'n = 'Stage 2' then 'Principal Amount'n else 0 end) as Principal_Amount format=comma20.2,
        sum(case when 'Final Stage'n = 'Stage 2' then 'Future Interest Amount'n else 0 end) as Total_Interest_Amount format=comma20.2,
        sum(case when 'Final Stage'n = 'Stage 2' then 'Final ECL'n else 0 end) as Final_ECL format=comma20.2
    from ifrs.s5t1
    union all
    select 
        'Stage 3' as Stage,
        sum(case when 'Final Stage'n = 'Stage 3' then 'Principal Amount'n else 0 end) as Principal_Amount format=comma20.2,
        sum(case when 'Final Stage'n = 'Stage 3' then 'Future Interest Amount'n else 0 end) as Total_Interest_Amount format=comma20.2,
        sum(case when 'Final Stage'n = 'Stage 3' then 'Final ECL'n else 0 end) as Final_ECL format=comma20.2
    from ifrs.s5t1;

    /* Adding the totals row */
    create table summary_total as
    select 
        'Total' as Stage,
        sum(Principal_Amount) as Principal_Amount format=comma20.2,
        sum(Total_Interest_Amount) as Total_Interest_Amount format=comma20.2,
        sum(Final_ECL) as Final_ECL format=comma20.2
    from summary_stage;

    /* Combining the stages and total */
    create table final_summary as
    select Stage, 
           Principal_Amount, 
           Total_Interest_Amount, 
           Final_ECL,
           (Final_ECL / Principal_Amount) as ECL_Percentage format=PERCENT8.2
    from summary_stage
    union all
    select Stage, 
           Principal_Amount, 
           Total_Interest_Amount, 
           Final_ECL,
           (Final_ECL / Principal_Amount) as ECL_Percentage format=PERCENT8.2
    from summary_total;
quit;

/* Display the final summary */
proc print data=final_summary;
run;


/* Display the final summary */
proc print data=final_summary;
run;


proc print data=work.final_summary noobs;
run;

data ifrs.s3t1_final;
	set work.final_summary;
run;
	
/* Importing S3T2 and S3T3 from the Excel */

proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx"
    out=ifrs.s3t2_final
    dbms=xlsx
    replace;
    sheet="Provision Summary";
    getnames=yes;
    range="B16:F20";
run;

proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx"
    out=ifrs.s3t3_final
    dbms=xlsx
    replace;
    sheet="Provision Summary";
    getnames=yes;
    range="B25:F29";
run;

/* Creating S1T3 from S3T1 */

data ifrs.s1t3_final;
	set ifrs.s3t1_final;
run;

/* Importing S1T1 from the Excel */

proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx"
    out=ifrs.s1t1_final
    dbms=xlsx
    replace;
    sheet="Recon to ECL summary (restated)";
    getnames=yes;
    range="A3:E7";
run;

/* Importing S1T2 from the Excel */

proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx"
    out=ifrs.s1t2_final
    dbms=xlsx
    replace;
    sheet="Recon to ECL summary (restated)";
    getnames=yes;
    range="G3:K7";
run;

data ifrs.s1t1_final;
	set work.s1t1_final;
	format 'Principal Amount'n comma20.;
	format 'Total Interest Amount'n comma20.;
	format 'Final ECL'n comma20.;
	format 'ECL %age'n PERCENT8.2;
run;

data ifrs.s1t2_final;
	set work.s1t2_final;
	format 'Principal Amount'n comma20.;
	format 'Total Interest Amount'n comma20.;
	format 'Final ECL'n comma20.;
	format 'ECL %age'n PERCENT8.2;
run;

data ifrs.s1t3_final;
	set work.s1t3_final;
	format Principal_Amount comma20.;
	format Total_Interest_Amount comma20.;
	format Final_ECL comma20.;
	format ECL_Percentage PERCENT8.2;
run;

/* Creating S1T4 by finding the difference between S1T2 and S1T3 */

data work.s1t4(keep = Stage Principal_Amount_diff Total_Interest_Amount_diff Final_ECL_diff);
    merge ifrs.s1t2_final(in=a rename=('Principal Amount'n=Principal_Amount_t2 'Total Interest Amount'n=Total_Interest_Amount_t2 'Final ECL'n=Final_ECL_t2))
          ifrs.s1t3_final(in=b rename=(Principal_Amount=Principal_Amount_t3 Total_Interest_Amount=Total_Interest_Amount_t3 Final_ECL=Final_ECL_t3));
    by Stage;
    if a and b;
    
    /* Calculate differences */
    Principal_Amount_diff = Principal_Amount_t3 - Principal_Amount_t2;
    Total_Interest_Amount_diff = Total_Interest_Amount_t3 - Total_Interest_Amount_t2;
    Final_ECL_diff = Final_ECL_t3 - Final_ECL_t2;
        
    Principal_Amount_diff = abs(Principal_Amount_diff);
    Total_Interest_Amount_diff = abs(Total_Interest_Amount_diff);
    Final_ECL_diff = abs(Final_ECL_diff);
    
    format Principal_Amount_diff Total_Interest_Amount_diff Final_ECL_diff comma20.;
    
    /* Optionally: Add more variables to compare */
run;

data ifrs.s1t4_final(rename=(Principal_Amount_diff=Principal_Amount Total_Interest_Amount_diff = Total_Interest_Amount Final_ECL_diff = Final_ECL));
	set work.s1t4;
run;

/* Sheet 1 Computation Complete */

****************************************************************************************************************************************************;

/* Importing S8T1 from the Excel Sheet */

proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx"
    out=ifrs.s8t1_final
    dbms=xlsx
    replace;
    sheet="Rating Matrix";
    getnames=yes;
    range="B4:K11";
run;

data work.s8t1_final;
	set ifrs.s8t1_final;
	'1-Default'n=1-Defaulted;
	
	format '1-Default'n Percent8.2;
run;

data ifrs.s8t1_final;
	set work.s8t1_final;
run;

/* Creating S8T2 from S8T1 */

data ifrs.s8t2_final(drop=i);
    set ifrs.s8t1_final;
    /* Perform the calculation with division by zero protection */
    array col{*} Aaa Aa A Baa Ba B 'Caa-C'n Withdrawn Defaulted;
    do i=1 to dim(col);
    	col(i) = col(i) + ((col(i) / '1-Default'n) * Withdrawn);
    end;
    '1-Default'n=sum(of col(*));
	Format Aaa Aa A Baa Ba B 'Caa-C'n Withdrawn Defaulted Percent8.;
	format '1-Default'n Percent12.2;
run;


proc print data=work.s8t2 noobs;
run;

/* Creating S8T3 from S8T2 */

data ifrs.s8t3_final(drop= Withdrawn '1-Default'n );
	set ifrs.s8t2_final;
	/* Output all existing rows */
    output;

	/* Add the Defaulted row */
    if _N_ = 7 then do;
        'From/To:'n = "Defaulted";
        Aaa = 0;
        Aa = 0;
        A = 0;
        Baa = 0;
        Ba = 0;
        B = 0;
        'Caa-C'n = 0;
        Defaulted = 1.000; /* Set Defaulted to 100% */
        output;
    end;
    
    Format Defaulted percent10.3;
run;

proc print data=ifrs.s8t3_final noobs;
run;

/* Importing S8T4 from the Excel */

proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx"
    out=ifrs.s8t4_final
    dbms=xlsx
    replace;
    sheet="Rating Matrix";
    getnames=yes;
    range="B38:J62";
run;

proc print data=ifrs.s8t4_final noobs;
run;

/* Computation of Sheet 8 Complete */

**********************************************************************************************************************************************************;

/* Computation of Sheet 11 */

/* Importing S11T1 */
proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx"
    out=ifrs.s11t1_final
    dbms=xlsx
    replace;
    sheet="Gov. Net Revenue  MEV Modelling";
    getnames=yes;
    range="A2:X63";
run;


/* data work.s11t1_final01; */
/* 	set work.s11t1_final; */
/* 	array yr{*} '2005'n -- '2024'n; */
/* 	Output all existing rows */
/*      */
/*  	array col{*} '2005'n -- '2024'n; /* '2005'n '2006'n '2007'n '2008'n '2009'n '2010'n '2011'n '2012'n '2013'n '2014'n '2015'n '2016'n '2017'n '2018'n '2019'n '2020'n '2021'n '2022'n '2023'n '2024'n; */
/* 	Add the Defaulted row */
/*      if 1 <= _N_ <= 61 then do; */
/*      	output; */
/*      	do i=1 to dim(yr); */
/*      		yr(i) = mean(of yr(i)); */
/*         end; */
/*      end; */
/*      else if _N_ > 61 then do; */
/*      	Country = "Others"; */
/*         'Subject Descriptor'n = "General government revenue"; */
/*         Units = "Percent of GDP"; */
/*         Scale = ""; */
/*         yr(i); */
/*       end; */
/* run; */

proc sort data=work.s11t1_final out=work.s11t1_final01;
	by Country;
run;

/* Created Table S11T1 full uptill X64 */
proc sql;
	create table work.test_s11t1 as
	select * 
	from work.s11t1_final01
	union all
	select      
        'Others' as Country,
        'General government revenue' as 'Subject Descriptor'n,
        'Percent of GDP' as Units,
        '' as Scale,
        mean('2005'n) as '2005'n,
        mean('2006'n) as '2006'n,
        mean('2007'n) as '2007'n,
        mean('2008'n) as '2008'n,
        mean('2009'n) as '2009'n,
        mean('2010'n) as '2010'n,
        mean('2011'n) as '2011'n,
        mean('2012'n) as '2012'n,
        mean('2013'n) as '2013'n,
        mean('2014'n) as '2014'n,
        mean('2015'n) as '2015'n,
        mean('2016'n) as '2016'n,
        mean('2017'n) as '2017'n,
        mean('2018'n) as '2018'n,
        mean('2019'n) as '2019'n,
        mean('2020'n) as '2020'n,
        mean('2021'n) as '2021'n,
        mean('2022'n) as '2022'n,
        mean('2023'n) as '2023'n,
        mean('2024'n) as '2024'n
    from work.s11t1_final;
quit;

/* Backup with sorted Country */
/* data ifrs.s11t1_final02; */
/* 	set work.test_s11t1; */
/* run; */

proc print data=work.test_s11t1;
run;

proc sort data=ifrs.s11t1_final out=work.s11t1_test02;
	by Country;
run;

/* Creating S11T2 from S11T1 */

/* data work.s11t2_test; */
/* 	set ifrs.s11t1_final02; */
/* 	Average=mean(of '2005'n -- '2018'n); */
/* 	format Average 8.2; */
/* run; */

/* proc means data=work.s11t1_test02 noprint; */
/*     by Country; /* Group by country */
/*     var '2005'n '2006'n '2007'n '2008'n '2009'n '2010'n '2011'n '2012'n '2013'n '2014'n '2015'n '2016'n '2017'n '2018'n ; /* Specify the columns you want to include */
/*     output out=work.s11t2_test01; /* Calculate standard deviation and output it */
/* run; */

data work.s11t2_test05;
    set ifrs.s11t1_final02;
    
    /* Calculate the mean for columns '2005' to '2018' */
    Average = mean(of '2005'n -- '2018'n);
    
    /* Calculate the standard deviation for columns '2005' to '2018' */
    StdDev = std(of '2005'n -- '2018'n);
    
	'%St.Dev.'n = StdDev / Average;
    
    format Average StdDev 8.2 '%St.Dev.'n Percent8.2;
run;

data ifrs.s11t2_modified(keep= Average StdDev '%St.Dev.'n);
	set work.s11t2_test05;
run;

/* Creating S11T3 from S11T1 and S11T2 */

%Let AE1 = 0.60;
%Let AF1 = 0.10;
%Let AG1 = 0.30;

data work.s11t3_test;
    set work.s11t2_test05;
    /* Calculate the Forecast_Average */
    Forecast_Average = mean(of '2019'n--'2024'n);
    
    /* Calculate Baseline */
    Baseline = (Forecast_Average - Average) / Average;
    
    /* Calculate Optimistic and Pessimistic */
    Optimistic = Baseline + '%St.Dev.'n;
    Pessimistic = Baseline - '%St.Dev.'n;
    
    /* Calculate Product_AE, Product_AF, and Product_AG */
    Product_AE = Optimistic * &AE1; 
    Product_AF = Optimistic * &AF1; 
    Product_AG = Pessimistic * &AG1;
    
    /* Calculate Scenario_Weightage */
    Scenario_Weightage = Product_AE + Product_AF + Product_AG;
    
    /* Apply formats */
    format Forecast_Average 8.2 
           Baseline PERCENT8.2 
           Optimistic PERCENT8.2 
           Pessimistic PERCENT8.2 
           Scenario_Weightage PERCENT8.2;
run;

PROC PRINT DATA=work.s11t3_test NOOBS;
RUN;
	
/* proc sql; */
/*     create Table work.s11t3_test as  */
/*     select *, */
/*         (('2019'n + '2020'n + '2021'n + '2022'n + '2023'n + '2024'n) / 6) as Forecast_Average, */
/*         ((('2019'n + '2020'n + '2021'n + '2022'n + '2023'n + '2024'n) / 6 - Average) / Average) as Baseline, */
/*         (((('2019'n + '2020'n + '2021'n + '2022'n + '2023'n + '2024'n) / 6 - Average) / Average) + '%St.Dev.'n) as Optimistic, */
/*         (((('2019'n + '2020'n + '2021'n + '2022'n + '2023'n + '2024'n) / 6 - Average) / Average) - '%St.Dev.'n) as Pessimistic, */
/*         ((((('2019'n + '2020'n + '2021'n + '2022'n + '2023'n + '2024'n) / 6 - Average) / Average) + '%St.Dev.'n) * &AE1) as Product_AE, */
/*         ((((('2019'n + '2020'n + '2021'n + '2022'n + '2023'n + '2024'n) / 6 - Average) / Average) + '%St.Dev.'n) * &AF1) as Product_AF, */
/*         ((((('2019'n + '2020'n + '2021'n + '2022'n + '2023'n + '2024'n) / 6 - Average) / Average) - '%St.Dev.'n) * &AG1) as Product_AG, */
/*         ((((((('2019'n + '2020'n + '2021'n + '2022'n + '2023'n + '2024'n) / 6 - Average) / Average) + '%St.Dev.'n) * &AE1) +  */
/*         ((((('2019'n + '2020'n + '2021'n + '2022'n + '2023'n + '2024'n) / 6 - Average) / Average) + '%St.Dev.'n) * &AF1) +  */
/*         ((((('2019'n + '2020'n + '2021'n + '2022'n + '2023'n + '2024'n) / 6 - Average) / Average) - '%St.Dev.'n) * &AG1))) as Scenario_Weightage */
/*     from work.s11t2_test05; */
/* quit; */

/* proc sql; */
/* 	create Table work.s11t3_test as  */
/* 	select *, */
/* 		(('2019'n+'2020'n+'2021'n+'2022'n+'2023'n+'2024'n)/6) as Forecast_Average */
/* 		((Forecast_Average - Average) / Average) as Baseline */
/*         (Baseline + '%St.Dev.'n) as Optimistic */
/*         (Baseline - '%St.Dev.'n) as Pessimistic */
/*         (Baseline * &AE1) as Product_AE */
/* 	    (Optimistic * &AF1) as Product_AF */
/* 	    (Pessimistic * &AG1) as Product_AG */
/* 	    (Product_AE + Product_AF + Product_AG) as Scenario_Weightage */
/*     from work.s11t2_test05; */
/* quit; */

data ifrs.s11t3_modified;
	set work.s11t3_test;
run;

/* Creating S11T4 from S11T1 and S11T2 (Both S11T1 and S11T2 is present in work.s11t3_test) */

/* proc sql; */
/*     create table work.standardized as */
/*     select *, */
/*         ('2005'n - Average) / StdDev as '2005_s'n */
/*     from work.s11t3_test; /* Replace with your dataset name */
/* quit; */

data work.s11t4_test(drop=Average StdDev '%St.Dev.'n Forecast_Average Baseline Optimistic Pessimistic Product_AE Product_AF Product_AG Scenario_Weightage i);
	set work.s11t3_test;
	array yrs{*} '2005'n--'2024'n;
	do i=1 to dim(yrs);
		yrs(i)=(yrs(i) - Average)/StdDev;
	end;
run;

data ifrs.s11t4_modified;
	set work.s11t4_test;
run;

/* Creating S11T5 from S11t4 */

data work.s11t5_test(keep=Average);
	set work.s11t4_test;
	Average = mean(of '2019'n-'2024'n);
	format Average 8.2;
run;

data ifrs.s11t5_modified;
	set work.s11t5_test;
run;

/* Computation of Sheet 11 Complete */

************************************************************************************************************************************************;

PROC PRINT DATA=work.s11t3_test;
RUN;

/* Creating S10T7 from S11T3 */

data work.s10t7_test(keep= Country 'Subject Descriptor'n Units Average StdDev Direction Baseline_Scenario Optimistic_Scenario Pessimistic_Scenario Average_Z_Value);
    set work.s11t3_test;
    Direction = 1;
    rename Baseline = Baseline_Scenario;
    rename Optimistic = Optimistic_Scenario;
    rename Pessimistic = Pessimistic_Scenario;
    rename Scenario_Weightage = Average_Z_Value;
    format Direction 8.2;
run;

data ifrs.s10t7_final;
	set work.s10t7_test;
run;

/* Importing S9T2 from the excel */

/* proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx" */
/*     out=work.s5t1_test0 */
/*     dbms=xlsx */
/*     replace; */
/*     sheet="ECL Calculation"; */
/*     getnames=yes; */
/*     range="A3:Z111"; */
/* run; */
/*  */
/* libname ifrs clear; */

proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx"
    out=ifrs.s9t2_final
    dbms=xlsx
    replace;
    sheet="PiT PD Structure";
    getnames=yes;
    range="B45:J405";
run;

/* Creating Value of AN2=@INDIRECT("D"&$CN$1+3) */

/* %macro getIndirectValue(excelFile=, sheetName=, targetCol=D); */
/*     Assign a specific value to CN1 */
/*     %let CN1 = 108; */
/*  */
/*     Calculate the target row number */
/*     %let targetRow = %eval(&CN1 + 3); */
/*  */
/*     Initialize noData variable */
/*     %let noData = 0; */
/*  */
/*     Print CN1 and targetRow for debugging */
/*     %put NOTE: The value of CN1 is &CN1; */
/*     %put NOTE: The targetRow is &targetRow; */
/*  */
/*     Create a libname to read the Excel file */
/*     libname myExcel XLSX "&excelFile"; */
/*     Read the specific cell value from the calculated row in the target column */
/*     data _null_; */
/*         Read the entire sheet to check if data is correctly accessed */
/*         set myExcel.&sheetName. end=last; */
/*  */
/*         Debug: Print data read from the sheet */
/*         put "NOTE: Reading data from row " _N_ " and column " &targetCol; */
/*  */
/*         if _N_ = &targetRow then do; */
/*             Retrieve the date value from the target column */
/*             dateStr = strip(&targetCol); /* Ensure no leading or trailing spaces */
/*              */
/*             Debug: Print raw date value */
/*             put "NOTE: Raw date value is " dateStr=; */
/*  */
/*             Convert the date string (MM/DD/YYYY) to a SAS date */
/*             Using MMDDYY10. informat for MM/DD/YYYY */
/*             sasDate = input(dateStr, mmddyy10.);  */
/*              */
/*             Check for conversion errors */
/*             if sasDate = . then do; */
/*                 put "WARNING: Failed to convert dateStr to SAS date."; */
/*                 call symputx('noData', '1'); */
/*             end; */
/*             else do; */
/*                 Debug: Print converted SAS date value */
/*                 put "NOTE: Converted SAS date value is " sasDate= date9.; */
/*                 Format the SAS date to a readable format */
/*                 call symputx('AN', put(sasDate, date9.)); /* Format as DDMMMYYYY */
/*             end; */
/*         end; */
/*  */
/*         Check if the data was found and processed */
/*         if last then do; */
/*             if symget('AN') = '' then call symputx('noData', '1'); */
/*         end; */
/*     run; */
/*  */
/*     Clear the libname */
/*     libname myExcel clear; */
/*  */
/*     Check if the macro variable AN was set */
/*     %put NOTE: The value stored in AN is &AN; */
/*     %put NOTE: If AN is not set, noData = &noData; */
/* %mend getIndirectValue; */
/*  */
/* Call the macro with your parameters */
/* %getIndirectValue( */
/*     excelFile=/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx,  */
/*     sheetName='ECL Calculation'n,  */
/*     targetCol=D */
/* ); */
/*  */
/* %macro getIndirectValue(excelFile=, sheetName=, targetCol=D); */
/*     Assign a specific value to CN1 */
/*     %let CN1 = 108; */
/*  */
/*     Calculate the target row number */
/*     %let targetRow = %eval(&CN1 + 3); */
/*  */
/*     Initialize noData variable */
/*     %let noData = 0; */
/*  */
/*     Print CN1 and targetRow for debugging */
/*     %put NOTE: The value of CN1 is &CN1; */
/*     %put NOTE: The targetRow is &targetRow; */
/*  */
/*     Create a libname to read the Excel file */
/*     libname myExcel XLSX "&excelFile"; */
/*  */
/*     Read the specific cell value from the calculated row in the target column */
/*     data _null_; */
/*         Read the entire sheet to check if data is correctly accessed */
/*         set myExcel.&sheetName. end=last; */
/*  */
/*         Debug: Print data read from the sheet */
/*         put "NOTE: Reading data from row " _N_ " and column " &targetCol; */
/*  */
/*         if _N_ = &targetRow then do; */
/*             Retrieve the value from the target column */
/*             value = strip(&targetCol); /* Ensure no leading or trailing spaces */
/*              */
/*             Debug: Print raw value */
/*             put "NOTE: Raw value is " value=; */
/*  */
/*             Store the value in macro variable AN */
/*             call symputx('AN', value, 'G'); */
/*         end; */
/*  */
/*         Check if the data was found and processed */
/*         if last then do; */
/*             if symget('AN') = '' then call symputx('noData', '1', 'G'); */
/*         end; */
/*     run; */
/*  */
/*     Clear the libname */
/*     libname myExcel clear; */
/*  */
/*     Check if the macro variable AN was set */
/*     %put NOTE: The value stored in AN is &AN; */
/*     %put NOTE: If AN is not set, noData = &noData; */
/* %mend getIndirectValue; */
/*  */
/* Call the macro with your parameters */
/* %getIndirectValue( */
/*     excelFile=/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx,  */
/*     sheetName='ECL Calculation'n,  */
/*     targetCol=D */
/* ); */
/*  */
/* data work.s5t1_test0; */
/* 	set work.s5t1_test0; */
/* 	ANVALUE="&datadate"; */
/* run; */
/*  */
/* %macro getIndirectValue(excelFile=, sheetName=, targetCol=D); */
/*     Assign a specific value to CN1 */
/*     %let CN1 = 108; */
/*  */
/*     Calculate the target row number */
/*     %let targetRow = %eval(&CN1 + 3); */
/*  */
/*     Initialize noData variable */
/*     %let noData = 0; */
/*  */
/*     Print CN1 and targetRow for debugging */
/*     %put NOTE: The value of CN1 is &CN1; */
/*     %put NOTE: The targetRow is &targetRow; */
/*  */
/*     Create a libname to read the Excel file */
/*     libname myExcel XLSX "&excelFile"; */
/*  */
/*     Read the specific cell value from the calculated row in the target column */
/*     data _null_; */
/*         Read the entire sheet to check if data is correctly accessed */
/*         set myExcel.&sheetName. end=last; */
/*  */
/*         Debug: Print data read from the sheet */
/*         put "NOTE: Reading data from row " _N_ " and column " &targetCol; */
/*  */
/*         if _N_ = &targetRow then do; */
/*             Retrieve the value from the target column */
/*             value = strip(&targetCol); /* Ensure no leading or trailing spaces */
/*              */
/*             Debug: Print raw value */
/*             put "NOTE: Raw value is " value=; */
/*  */
/*             Store the value in macro variable AN */
/*             call symputx('datadate', value, 'G'); */
/*         end; */
/*  */
/*         Check if the data was found and processed */
/*         if last then do; */
/*             if symget('datadate') = '' then call symputx('noData', '1', 'G'); */
/*         end; */
/*     run; */
/*  */
/*     Clear the libname */
/*     libname myExcel clear; */
/*  */
/*     Check if the macro variable AN was set */
/*     %put NOTE: The value stored in AN is &AN; */
/*     %put NOTE: If AN is not set, noData = &noData; */
/* %mend getIndirectValue; */
/*  */
/* Call the macro with your parameters */
/* %getIndirectValue( */
/*     excelFile=/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx,  */
/*     sheetName='ECL Calculation'n,  */
/*     targetCol=D */
/* ); */

proc print data=ifrs.s5t1 noobs;
run;

proc contents data=ifrs.s5t1;
run;

proc print data=work.s5t2 noobs;
var 'Reporting Date'n Monthly_Dates;
run;

/* Creating S5T3 */

%Let ppf=1.00;
%Let AN2= '31DEC2018'd;
%Let AO2='30OCT2000'd;
%Let AR= '31DEC2023'd;
%let ED= '31DEC2060'd;

data ifrs.s5t3_modified(keep=Valuation_Date Month Payment_Indicator Payment_Date);
    format Valuation_Date Payment_Date date9.;
    retain Valuation_Date;
    
    Valuation_Date = &AN2;
    do while (Valuation_Date <= &ED);
        Month = month(Valuation_Date);
		
		Payment_Indicator = 0;

        /* Convert the comparison dates to SAS date values */
        end_month_Valuation_Date = intnx('month', Valuation_Date, 0, 'end');
        end_month_AR2 = intnx('month', &AR, 0, 'end');
        end_month_AO2 = intnx('month', &AO2, 0, 'end');

        /* Main Conditional Check */
        if end_month_Valuation_Date > end_month_AR2 then do;
            Payment_Indicator = 0;
        end;
        else if end_month_Valuation_Date >= end_month_AO2 then do;
            /* Condition based on &ppf */
            if &ppf = 1 then do;
                if month(&AO2) = Month then Payment_Indicator = 1;
                else Payment_Indicator = 0;
            end;
            else if &ppf = 2 then do;
                if month(&AO2) = Month or month(&AO2)+6 = Month or month(&AO2)-6 = Month then Payment_Indicator = 1;
                else Payment_Indicator = 0;
            end;
            else if &ppf = 4 then do;
                if month(&AO2) = Month or month(&AO2)+3 = Month or month(&AO2)+6 = Month or month(&AO2)+9 = Month or month(&AO2)-9 = Month or month(&AO2)-3 = Month or month(&AO2)-6 = Month then Payment_Indicator = 1;
                else Payment_Indicator = 0;
            end;
            else if &ppf = 6 then do;
                if month(&AO2) = Month or month(&AO2)+2 = Month or month(&AO2)+4 = Month or month(&AO2)+6 = Month or month(&AO2)+8 = Month or month(&AO2)+10 = Month or month(&AO2)-2 = Month or month(&AO2)-4 = Month or month(&AO2)-6 = Month or month(&AO2)-8 = Month or month(&AO2)-10 = Month then Payment_Indicator = 1;
                else Payment_Indicator = 0;
            end;
            else if &ppf = 12 then do;
                Payment_Indicator = 1;
            end;
            else if &ppf = 0 and end_month_Valuation_Date = end_month_AR2 then do;
                Payment_Indicator = 1;
            end;
            else do;
                Payment_Indicator = 0;
            end;
        end;

        if Payment_Indicator = 1 then Payment_Date = Valuation_Date;
        else Payment_Date = .;

        /* Output each record */
        output;

        /* Move to the next month */
        Valuation_Date = intnx('month', Valuation_Date, 1, 'end');
    end;

    /* Drop intermediate variables if not needed */
    drop end_month_Valuation_Date end_month_AR2 end_month_AO2;
run;

/* Print the result */
proc print data=ifrs.s5t3_modified;
run;

/* Create Table S5T4 */

/* Define macro variables for user input parameters */
%let start_date = '31DEC2018'd;
%let end_date = '31DEC2060'd;
%let AR = '31DEC2023'd;
%let AP = '31OCT1997'd;
%let BX3 = 2.00;

/* Generate a dataset with dates from start_date to end_date */
data work.date_range;
    format Valuation_Date date9.;
    Valuation_Date = &start_date;
    do while (Valuation_Date <= &end_date);
        output;
        Valuation_Date = intnx('month', Valuation_Date, 1, 'end');
    end;
run;

/* Simulate the dataset with Valuation_Date and Month values */
data work.sample_data;
    set work.date_range;
    Month = month(Valuation_Date);
run;

/* Implement the logic from the Excel formula */
data ifrs.s5t4_modified;
    set work.sample_data;
    format EOMONTH_Valuation_Date EOMONTH_AR EOMONTH_AP Payment_Date date9.;
    EOMONTH_Valuation_Date = intnx('month', Valuation_Date, 0, 'end');
    EOMONTH_AR = intnx('month', &AR, 0, 'end');
    EOMONTH_AP = intnx('month', &AP, 0, 'end');

    if EOMONTH_Valuation_Date > EOMONTH_AR then 
        Payment_Indicator = 0;
    else if EOMONTH_Valuation_Date >= EOMONTH_AP then do;
        select (&BX3);
            when (1) Payment_Indicator = (month(&AP) = Month);
            when (2) Payment_Indicator = (month(&AP) = Month or month(&AP) + 6 = Month or month(&AP) - 6 = Month);
            when (4) Payment_Indicator = (month(&AP) = Month or month(&AP) + 3 = Month or month(&AP) + 6 = Month or month(&AP) + 9 = Month or 
                              month(&AP) - 9 = Month or month(&AP) - 3 = Month or month(&AP) - 6 = Month);
            when (6) Payment_Indicator = (month(&AP) = Month or month(&AP) + 2 = Month or month(&AP) + 4 = Month or month(&AP) + 6 = Month or 
                              month(&AP) + 8 = Month or month(&AP) + 10 = Month or month(&AP) - 2 = Month or month(&AP) - 4 = Month or 
                              month(&AP) - 6 = Month or month(&AP) - 8 = Month or month(&AP) - 10 = Month);
            when (12) Payment_Indicator = 1;
            when (0) Payment_Indicator = (EOMONTH_Valuation_Date = EOMONTH_AR);
            otherwise Payment_Indicator = 0;
        end;
    end;
    else 
        Payment_Indicator = 0;
        
    /* Apply the conditional logic */
    if Payment_Indicator = 1 then Payment_Date = Valuation_Date;
    else Payment_Date = .;

    drop EOMONTH_Valuation_Date EOMONTH_AR EOMONTH_AP;
run;

proc print data=ifrs.s5t4_modified; 
run;

/* Create Table S5T5 */

/* Define macro variables for user input parameters */
%let start_date = '31DEC2018'd;
%let end_date = '31DEC2060'd;
%let AR2 = '31DEC2023'd;
%Let AO2='30OCT2000'd;
%let CC3 = 1.00;

/* Generate a dataset with dates from start_date to end_date */
data work.date_s5t5;
    format Valuation_Date date9.;
    Valuation_Date = &start_date;
    do while (Valuation_Date <= &end_date);
        output;
        Valuation_Date = intnx('month', Valuation_Date, 1, 'end');
    end;
run;

/* Simulate the dataset with Valuation_Date and Month values */
data work.month_s5t5;
    set work.date_s5t5;
    Month = month(Valuation_Date);
run;

data ifrs.s5t5_modified;
    set work.month_s5t5;

    /* Calculate end of month dates */
    eomonth_Valuation_Date = intnx('month', Valuation_Date, 0, 'end');
    eomonth_ar2 = intnx('month', &AR2, 0, 'end');
    eomonth_br6 = intnx('month', Valuation_Date, 0, 'end');
    eomonth_ao2 = intnx('month', &AO2, 0, 'end');

    /* Initialize result variable */
    Payment_Indicator = 0;

    /* Step-by-step condition evaluation */
    if eomonth_Valuation_Date > eomonth_ar2 then do;
        Payment_Indicator = 0;
    end;
    else if eomonth_br6 >= eomonth_ao2 then do;
            /* Condition based on &CC3 */
            if &CC3 = 1 then do;
                if month(&AO2) = Month then Payment_Indicator = 1;
                else Payment_Indicator = 0;
            end;
            else if &CC3 = 2 then do;
                if month(&AO2) = Month or month(&AO2)+6 = Month or month(&AO2)-6 = Month then Payment_Indicator = 1;
                else Payment_Indicator = 0;
            end;
            else if &CC3 = 4 then do;
                if month(&AO2) = Month or month(&AO2)+3 = Month or month(&AO2)+6 = Month or month(&AO2)+9 = Month or month(&AO2)-9 = Month or month(&AO2)-3 = Month or month(&AO2)-6 = Month then Payment_Indicator = 1;
                else Payment_Indicator = 0;
            end;
            else if &CC3 = 6 then do;
                if month(&AO2) = Month or month(&AO2)+2 = Month or month(&AO2)+4 = Month or month(&AO2)+6 = Month or month(&AO2)+8 = Month or month(&AO2)+10 = Month or month(&AO2)-2 = Month or month(&AO2)-4 = Month or month(&AO2)-6 = Month or month(&AO2)-8 = Month or month(&AO2)-10 = Month then Payment_Indicator = 1;
                else Payment_Indicator = 0;
            end;
            else if &CC3 = 12 then do;
                Payment_Indicator = 1;
            end;
            else if &CC3 = 0 and eomonth_Valuation_Date = eomonth_ar2 then do;
                Payment_Indicator = 1;
            end;
            else do;
                Payment_Indicator = 0;
            end;
        end;

    if Payment_Indicator = 1 then Payment_Date = Valuation_Date;
    else Payment_Date = .;
    
    /* Drop intermediate variables if not needed */
    drop eomonth_Valuation_Date eomonth_ar2 eomonth_ao2 eomonth_br6;
    format Payment_Date date9.;
run;

proc print data=ifrs.s5t5_modified noobs;
run;

/* Creating S5T2 from S5T1, S5T3, S5T4, S5T5, S9T2 */

proc print data=ifrs.s5t1 noobs;
run;

proc sql;
	create table work.s5t2_test as 
	select * from ifrs.s5t1
	where PROJ_ENG_NAME = "EMIRATES &MOROCOO CO.";
quit;

data ifrs.s5t6_modified(keep=Valuation_Date
					First_Principal_Payment_Date 
					Expiry_Date
					First_Interest_Payment_Date 
					Settlement_Year 
					Principal_Payment_Frequency 
					Interest_Payment_Frequency 
					Disbursement_Frequency 
					Remaining_Loan_Amount 
					Outstanding_Principal 
					Principal_Exposure 
					Interest_Rate 
					Accrued_Interest 
					'PD-12 m'n 
					'Discount Rate- 12 M'n 
					LGD
					Country);
	set work.s5t2_test;
	Valuation_Date='Reporting Date'n;
	First_Principal_Payment_Date ='First Principal  Date'n;
	Expiry_Date = 'Maturity Date'n;
	First_Interest_Payment_Date = 'First Interest  Date'n;
	Settlement_Year = 'Settlement Year'n;
	Principal_Payment_Frequency = 'Principal Payment Frequency'n;
	Interest_Payment_Frequency = 'Interest Payment Frequency'n;
	Disbursement_Frequency = 'Disbursement Frequency'n;
	Remaining_Loan_Amount = 'Future Disbursment Amount'n;
	Outstanding_Principal = 'Principal Amount'n;
	Principal_Exposure = Remaining_Loan_Amount + Outstanding_Principal;
	Interest_Rate = 'Interest Rate'n;
	Accrued_Interest = 'Accrued Interest'n;
	'PD-12 m'n = 'Current Rating'n;
	'Discount Rate- 12 M'n = 'Discount Rate'n;
run;
	

/* %Let AV=0; */
/* %Let AX= 4500000; */
/* %Let AR='31DEC2023'd; */
/* %Let AW= 0; */
/* %Let BA = 3290077.33; */

%let end_date='31DEC2060'd;

/* Creating Monthly_Dates and Loan_Disbursement_Indicator in S5T2 */

data work.s5t2(keep=Monthly_Dates Loan_Disbursement_Indicator);
    set ifrs.s5t6_modified;
    format Monthly_Dates date9.;
    retain Monthly_Dates;
    Monthly_Dates = Valuation_Date;
    
    do while (Monthly_Dates <= &end_date);
    	
        if intnx('month', Monthly_Dates, 0, 'end') = Valuation_Date then
            Loan_Disbursement_Indicator = 1;
        else
            Loan_Disbursement_Indicator = 0;
        output;
        Monthly_Dates = intnx('month', Monthly_Dates, 1, 'end');
    end;
run;

/* Creating Monthly_Dates and Loan_Disbursement_Indicator in S5T2 */
data work.s5t2_test;
	merge work.s5t2 ifrs.s5T5_modified(rename=(Valuation_Date=Monthly_Dates));
	by Monthly_Dates;
	Loan_Disbursment_Date=Payment_Date;
	
run;

/* Step 1: Calculate the sum of the AO column from s5t2 */
proc sql noprint;
    select sum(Loan_Disbursement_Indicator) into :sum_AO
    from work.s5t2_test;
quit;

/* Step 2: Create a new column in s5t6 with the desired calculation */
data ifrs.s5t6_modified;
    set ifrs.s5t6_modified;
    Disbursement_Amount = Remaining_Loan_Amount / &sum_AO;
    format Valuation_Date First_Principal_Payment_Date Expiry_Date First_Interest_Payment_Date date9.;
run;

/* Create Column Disbursment from Loan_Disbursement_Indicator of S5T2 and Disbursement_Amount from S5T6 */

/* Step 1: Extract the Disbursement_Amount from s5t6 */
data _null_;
    set ifrs.s5t6_modified;
    call symputx('disb_amount', Disbursement_Amount);
run;

/* Check the value of the macro variable */
%put &disb_amount;

data _null_;
    set ifrs.s5t6_modified;
    call symputx('out_principal', Outstanding_Principal);
    call symputx('ex_dt', Expiry_Date);
run; 

/* Step 2: Use the extracted value to create the new column in s5t2 */
data ifrs.s5t2_test01(drop=prev_PEAOMD Payment_Date);
    set work.s5t2_test;
    format Loan_Disbursment_Date date9.;
    rename Payment_Indicator=Payment_Indicator_s5t5
    		Month=Month_s5t5;
    retain prev_PEAOMD;
    Disbursment = Loan_Disbursement_Indicator * &disb_amount;
    if _N_ = 1 then do;
        Principal_Exposure_AOMD = Disbursment + &out_principal;
        prev_PEAOMD = Principal_Exposure_AOMD; /* Set initial retained value */
    end;
    else do;
        if Disbursment > 0 and Monthly_Dates <= &ex_dt then 
            Principal_Exposure_AOMD = prev_PEAOMD + Disbursment;
        else 
            Principal_Exposure_AOMD = 0;
        
        prev_PEAOMD = Principal_Exposure_AOMD; /* Update retained value */
    end;
run;

/* Creating Principal Repayment Dates from S5T3 */

data ifrs.s5t2_test02(rename=(Payment_Indicator=Payment_Indicator_s5t3
								Month=Month_s5t3));
	merge ifrs.s5t2_test01 ifrs.s5t3_modified(rename=Valuation_Date=Monthly_Dates);
	by Monthly_Dates;
	
	Principal_Repayment_Dates = Payment_Date;
	Principal_Repayment_Indicator = Payment_Indicator;
	
	drop Payment_Date;
	format Principal_Repayment_Dates date9.;
run;

proc print data=ifrs.s5t2_test02 noobs;
run;
	
/* Creating Principal Repayment Column from s5t6 into s5t2 */

proc sql noprint;
    select sum(Principal_Repayment_Indicator) into :sum_AS
    from ifrs.s5t2_test02;
quit;

proc print data=ifrs.s5t6_modified;
run;

/* data ifrs.s5t6_modified_01; */
/*     set ifrs.s5t6_modified; */
/*     Principal_Repayments_t6 = &sum_AS; */
/*     Principal_Repayment_Amount = Principal_Exposure / Principal_Repayments_t6; */
/*     format Valuation_Date First_Principal_Payment_Date Expiry_Date First_Interest_Payment_Date date9.; */
/* run; */

data _null_;
    set ifrs.s5t6_modified;
    call symputx('prn_ra', Principal_Repayment_Amount);
    call symputx('ar2', Expiry_Date);
    call symputx('az2', Interest_Rate);
    call symputx('ba2', Accrued_Interest);
run;

/* data ifrs.s5t2_test02; */
/* 	set ifrs.s5t2_test02; */
/* 	format Interest_Amount_Future Principal_Repayment Remaining_Principal_Exposure Interest_accrued_Till_Date comma12.; */
/* 	retain cumulative_Exposure cumulative_Repayment; */
/* 	 */
/* 	Principal_Repayments = Principal_Repayment_Indicator * &prn_ra; */
/* 	 */
/* 	if _N_ = 1 then do; */
/*         cumulative_Exposure = Principal_Exposure_AOMD; */
/*         cumulative_Repayment = Principal_Repayments; */
/*     end; */
/*     else do; */
/*         cumulative_Exposure = cumulative_Exposure + Principal_Exposure_AOMD; */
/*         cumulative_Repayment = cumulative_Repayment + Principal_Repayments; */
/*     end; */
/*      */
/*     Calculate the result based on the formula */
/*     Remaining_Principal_Exposure = max(cumulative_Exposure - cumulative_Repayment, 0); */
/*      */
/*     Days_Diff = &ar2 - Monthly_Dates; */
/*     Months_Diff = intck('month', Monthly_Dates, &ar2); */
/*      */
/*     if _N_ = 1 then do; */
/*     	Interest_Amount_Future = 0; */
/*     	Interest_accrued_Till_Date=&ba2; */
/*     end; */
/*     else do; */
/* 	    if Remaining_Principal_Exposure > 0 and Monthly_Dates <= &ar2 then do; */
/* 	        if Months_Diff > 0 then /* Ensure no division by zero */
/* 	            Interest_Amount_Future = (Remaining_Principal_Exposure * (&az2 * (Days_Diff / 365))) / Months_Diff; */
/* 	        else */
/* 	            Interest_Amount_Future = 0; */
/* 	    end; */
/* 	    else  */
/* 	        Interest_Amount_Future = 0; */
/* 	        Interest_accrued_Till_Date=.; */
/* 	end; */
/* run; */

/* data ifrs.s5t2_test001; */
/*     set ifrs.s5t2_test02; */
/*     format Interest_Amount_Future Principal_Repayment Remaining_Principal_Exposure Interest_accrued_Till_Date comma12.; */
/*      */
/*     Retain variables for cumulative calculations and previous exposure */
/*     retain cumulative_Exposure cumulative_Repayment prev_Remaining_Exposure; */
/*      */
/*     Calculate Principal Repayment */
/*     Principal_Repayment = Principal_Repayment_Indicator * &prn_ra; */
/*      */
/*     Initialize for the first record */
/*     if _N_ = 1 then do; */
/*         cumulative_Exposure = Principal_Exposure_AOMD; */
/*         cumulative_Repayment = Principal_Repayment; */
/*         prev_Remaining_Exposure = Principal_Exposure_AOMD - Principal_Repayment; */
/*     end; */
/*     else do; */
/*         cumulative_Exposure = cumulative_Exposure + Principal_Exposure_AOMD; */
/*         cumulative_Repayment = cumulative_Repayment + Principal_Repayments; */
/*         prev_Remaining_Exposure = Remaining_Principal_Exposure; /* Update previous exposure */
/*     end; */
/*      */
/*     Calculate Remaining Principal Exposure */
/*     Remaining_Principal_Exposure = max(cumulative_Exposure - cumulative_Repayment, 0); */
/*      */
/*     Compute Days and Months Difference */
/*     Days_Diff = &ar2 - Monthly_Dates; */
/*     Months_Diff = intck('month', Monthly_Dates, &ar2); */
/*      */
/*     Calculate Interest Amount Future */
/*     if _N_ = 1 then do; */
/*         Interest_Amount_Future = 0; */
/*         Interest_accrued_Till_Date = &ba2; */
/*     end; */
/*     else do; */
/*         if prev_Remaining_Exposure > 0 and Monthly_Dates <= &ar2 then do; */
/*             if Months_Diff > 0 then /* Ensure no division by zero */
/*                 Interest_Amount_Future = (prev_Remaining_Exposure * (&az2 * (Days_Diff / 365))) / Months_Diff; */
/*             else */
/*                 Interest_Amount_Future = 0; */
/*         end; */
/*         else  */
/*             Interest_Amount_Future = 0; */
/*          */
/*         Interest_accrued_Till_Date = .; */
/*     end; */
/*      */
/* run; */

/* Here in the below program the value for Remaining_Principal_Exposure for row16 is coming wrong  */
/* data ifrs.s5t2_test001; */
/* 	set ifrs.s5t2_test02; */
/* 	format Interest_Amount_Future Principal_Repayment Remaining_Principal_Exposure Interest_accrued_Till_Date comma12.; */
/* 	retain cumulative_Exposure cumulative_Repayment; */
/* 	 */
/* 	Principal_Repayment = Principal_Repayment_Indicator * &prn_ra; */
/* 	 */
/* 	if _N_ = 1 then do; */
/*         cumulative_Exposure = Principal_Exposure_AOMD; */
/*         cumulative_Repayment = Principal_Repayment; */
/*     end; */
/*     else do; */
/*         cumulative_Exposure = cumulative_Exposure + Principal_Exposure_AOMD; */
/*         cumulative_Repayment = cumulative_Repayment + Principal_Repayment; */
/*     end; */
/*      */
/*     Calculate the result based on the formula */
/*     Remaining_Principal_Exposure = max(cumulative_Exposure - cumulative_Repayment, 0); */
/*      */
/*     Days_Diff = &ar2 - Monthly_Dates; */
/*     Months_Diff = intck('month', Monthly_Dates, &ar2); */
/*      */
/*     if _N_ = 1 then do; */
/*     	Interest_Amount_Future = 0; */
/*     	Interest_accrued_Till_Date=&ba2; */
/*     end; */
/*     else do; */
/* 	    if Remaining_Principal_Exposure > 0 and Monthly_Dates <= &ar2 then do; */
/* 	        if Months_Diff > 0 then /* Ensure no division by zero */
/* 	            Interest_Amount_Future = (Remaining_Principal_Exposure * (&az2 * (Days_Diff / 365))) / Months_Diff; */
/* 	        else */
/* 	            Interest_Amount_Future = 0; */
/* 	    end; */
/* 	    else  */
/* 	        Interest_Amount_Future = 0; */
/* 	        Interest_accrued_Till_Date=.; */
/* 	end; */
/* run; */


/* data ifrs.s5t2_test002; */
/*     set ifrs.s5t2_test02; */
/*     format Interest_Amount_Future Principal_Repayment Remaining_Principal_Exposure Interest_accrued_Till_Date comma12.; */
/*     retain cumulative_Exposure cumulative_Repayment prev_AV; */
/*  */
/*     Calculate Principal Repayments */
/*     Principal_Repayment = Principal_Repayment_Indicator * &prn_ra; */
/*  */
/*     Initialize for the first record */
/*     if _N_ = 1 then do; */
/*         cumulative_Exposure = Principal_Exposure_AOMD; */
/*         cumulative_Repayment = Principal_Repayment; */
/*         Remaining_Principal_Exposure = max(cumulative_Exposure - cumulative_Repayment, 0); */
/*         prev_AV = .; /* No previous value for the first record */
/*     end; */
/*     else do; */
/*         cumulative_Exposure + Principal_Exposure_AOMD; */
/*         cumulative_Repayment + Principal_Repayment; */
/*         Remaining_Principal_Exposure = max(cumulative_Exposure - cumulative_Repayment, 0); */
/*         prev_AV = lag(Remaining_Principal_Exposure); /* Use LAG function to access previous row's AV */
/*     end; */
/* run;     */
/* 	Calculate Remaining Principal Exposure */
/*     Remaining_Principal_Exposure = max(cumulative_Exposure - cumulative_Repayment, 0); */
/*      */
/*     Compute Days and Months Difference */
/*     Days_Diff = intck('day', Monthly_Dates, &ar2); */
/*     Months_Diff = intck('month', Monthly_Dates, &ar2); */
/*  */
/*     Calculate Interest Amount Future */
/*     if _N_ = 1 then do; */
/*         Interest_Amount_Future = 0; */
/*         Interest_accrued_Till_Date = &ba2; */
/*         prev_AV = 0; */
/*     end; */
/*     else do; */
/* 		prev_AV = prev_AV + Remaining_Principal_Exposure; */
/*         if Remaining_Principal_Exposure > 0 and Monthly_Dates <= &ar2 then do; */
/*             if Months_Diff > 0 then /* Ensure no division by zero */
/*                 Interest_Amount_Future = (prev_AV * (&az2 * (Days_Diff / 365))) / Months_Diff; */
/*             else */
/*                 Interest_Amount_Future = 0; */
/*         end; */
/*         else */
/*             Interest_Amount_Future = 0; */
/*  */
/*         Interest_accrued_Till_Date = .; */
/*     end; */
/*      */
/*     Optional: Drop intermediate variables if not needed in the output */
/*     drop prev_AV Days_Diff Months_Diff; */
/* run; */

data ifrs.s5t2_test002;
    set ifrs.s5t2_test02;
    format Interest_Amount_Future Principal_Repayment Remaining_Principal_Exposure Interest_accrued_Till_Date comma12.;
    retain cumulative_Exposure cumulative_Repayment prev_Exposure;

    /* Calculate Principal Repayments */
    Principal_Repayment = Principal_Repayment_Indicator * &prn_ra;

    /* Initialize for the first record */
    if _N_ = 1 then do;
        cumulative_Exposure = Principal_Exposure_AOMD;
        cumulative_Repayment = Principal_Repayment;
        /* No previous exposure for the first record */
        Interest_accrued_Till_Date = &ba2;
        Interest_Amount_Future = 0;
        Remaining_Principal_Exposure=max(cumulative_Exposure - cumulative_Repayment, 0);
        prev_Exposure = Remaining_Principal_Exposure;
        
    end;
    else do;
        cumulative_Exposure = cumulative_Exposure + Principal_Exposure_AOMD;
        cumulative_Repayment = cumulative_Repayment + Principal_Repayment;
        
        /* Calculate Remaining Principal Exposure */
        Remaining_Principal_Exposure = max(cumulative_Exposure - cumulative_Repayment, 0);
        
        
/*         Calculate Interest Amount Future */
        if Remaining_Principal_Exposure > 0 and Monthly_Dates <= &ar2 then do;
/*             Use the previous value of Remaining_Principal_Exposure */
            if prev_Exposure > 0 then do;
                Days_Diff = intck('day', Monthly_Dates, &ar2);
                Months_Diff = intck('month', Monthly_Dates, &ar2);
                if Months_Diff > 0 then /* Ensure no division by zero */
                    Interest_Amount_Future = (prev_Exposure * (&az2 * (Days_Diff / 365))) / Months_Diff;
                else
                    Interest_Amount_Future = 0;
            end;
            else
                Interest_Amount_Future = 0;
        end;
        else
            Interest_Amount_Future = 0;

        /* Update previous exposure */
        prev_Exposure = Remaining_Principal_Exposure;
        
        Interest_accrued_Till_Date = .;
    end;
run;

proc print data=ifrs.s5t2_test002 noobs;
var Monthly_Dates Interest_Amount_Future;
run;

data ifrs.s5t2_test003(drop=prev_Exposure Days_Diff Months_Diff cumulative_Exposure cumulative_Repayment);
	set ifrs.s5t2_test002;
run;

/* Creating column Interest Repayment Dates from S5T4 to S5T2 */

data ifrs.s5t2_test004;
	merge ifrs.s5t2_test003 ifrs.s5t4_modified(rename=(Valuation_Date=Monthly_Dates));
	by Monthly_Dates;
	retain cum_AW cum_AX cum_BA prev_IR;
/* 	cumulative_IAF cumulative_IATD cumulative_IRP; */
	
	Interest_Repayment_Dates=Payment_Date;
	Interest_Repayment_Indicator=Payment_Indicator;
	
	
	if _N_ = 1 then do;
		if Interest_Repayment_Indicator = 1 then 
			Interest_Repayment=Interest_accrued_Till_Date + Interest_Amount_Future;
		else Interest_Repayment=0;
		
        cum_AW = Interest_Amount_Future;
        cum_AX = Interest_accrued_Till_Date;
        cum_BA = Interest_Repayment;
        prev_IR = Interest_Repayment;
	end;
	else do;
		cum_AW + Interest_Amount_Future;
        cum_AX + Interest_accrued_Till_Date;
        cum_BA + prev_IR;
		if Interest_Repayment_Indicator = 1 then
			Interest_Repayment = (cum_AW + cum_AX - cum_BA);
		else
			Interest_Repayment = 0;
		
		prev_IR = Interest_Repayment;
	end;
	
/* 	cumulative_IAF + Interest_Amount_Future; */
/*     cumulative_IATD + Interest_accrued_Till_Date; */
/*     cumulative_IRP + Interest_Repayment; */
/*      */
/*     if _N_ = 1 then EAD_End_of_Period = Remaining_Principal_Exposure + Interest_Amount_Future + Interest_accrued_Till_Date + Interest_Repayment; */
/*     else EAD_End_of_Period = Remaining_Principal_Exposure + cumulative_IAF + cumulative_IATD - cumulative_IRP; */
    
	format Interest_Repayment_Dates date9. Interest_Repayment comma20.;
run;

proc print data=ifrs.s5t4_modified;
run;


data ifrs.s5t2_test005;
	merge ifrs.s5t2_test004 ifrs.s5t4_modified(rename=(Valuation_Date=Monthly_Dates));
	by Monthly_Dates;
	retain cumulative_IAF cumulative_IATD cumulative_IRP;
	
	cumulative_IAF + Interest_Amount_Future;
    cumulative_IATD + Interest_accrued_Till_Date;
    cumulative_IRP + Interest_Repayment;
    
    if _N_ = 1 then do;
    	EAD_End_of_Period = Remaining_Principal_Exposure + Interest_Amount_Future + Interest_accrued_Till_Date + Interest_Repayment;
    end;
    else do;
    	EAD_End_of_Period = Remaining_Principal_Exposure + cumulative_IAF + cumulative_IATD - cumulative_IRP;
    end;
    
    format EAD_End_of_Period comma20.;
run;

	
data _null_;
    set ifrs.s5t6_modified;
    call symputx('ar2', Expiry_Date);
run;

data ifrs.s5t2_test006;
    set ifrs.s5t2_test005;
    by Monthly_Dates;
    retain Sl_No prev_sl;

    /* Initialize SL_No for the first record */
    if _N_ = 1 then do;
        Sl_No = 1;
        prev_sl = Sl_No;
    end;
    else do;
        /* For rows after the first one */
        if _N_ = 2 then do;
            if Principal_Repayment_Dates = . then do;
                Sl_No = prev_sl + 1;
            end;
            else do;
                Sl_No = .;
            end;
            prev_sl = Sl_No;
        end;
        else do;
            /* Increment SL_No if Monthly_Dates <= &ar2 */
            if Monthly_Dates <= &ar2 then do;
                Sl_No = prev_sl + 1;
            end;
            else do;
                Sl_No = .; /* Use missing value if condition not met */
            end;
            prev_sl = Sl_No;
        end;
    end;

    /* Output the result */
    output;
run;

proc print data=ifrs.s5t2_test007 noobs;
var Sl_No Monthly_Dates Days_for_Discounting;
run;

/* data ifrs.s5t2_test007; */
/* 	set ifrs.s5t2_test006; */
/* 	if _N_ = 1 then do; */
/* 		Days_for_Discounting = 0; */
/* 	end; */
/* 	else do; */
/* 		Use lag() function to get the previous row value for AM */
/* 		Days_for_Discounting = ifn(Sl_No > 0, Monthly_Dates - lag(Monthly_Dates), 0); */
/* 	end; */
/* run;	 */
		
data ifrs.s5t2_test007;
    set ifrs.s5t2_test006;
    by Monthly_Dates; /* Ensure proper ordering */
    retain prev_date;
    
    if _N_ = 1 then do;
        Days_for_Discounting = 0;
        prev_date = Monthly_Dates;
    end;
    else do;
        /* Calculate Days_for_Discounting using the retained previous date */
        if Sl_No > 0 then 
            Days_for_Discounting = Monthly_Dates - prev_date;
        else
            Days_for_Discounting = 0; /* Set to missing if condition not met */
        
        /* Update the retained previous date */
        prev_date = Monthly_Dates;
    end;

    /* Output the result */
    output;
run;

/* Importing S9T2 table with modifications */

proc import datafile="/home/u63835816/sasuser.v94/IFRS/Input_Sheet/IFRS9_LOAN_Edited.xlsx"
    out=ifrs.s9t2_modified
    dbms=xlsx
    replace;
    sheet="Copy PiT PD Structure T2";
    getnames=yes;
    range="A1:J506";
run;

/* Adding Column PD Marginal to S5T2 from S9T2_modified */

proc sql;
	create table ifrs.s5t2_test008 as 
	select a.*, b.'Monthly PD'n as PD_Marginal
	from ifrs.s5t2_test007 as a 
	left join ifrs.s9t2_modified as b 
	on a.Monthly_Dates=b.'Monthly Dates'n;
quit;

data _null_;
	set ifrs.s5t6_modified;
    call symputx('lgd', LGD);
    call symputx('be2', 'Discount Rate- 12 M'n);
run;

data ifrs.s5t2_test009;
	set ifrs.s5t2_test008;
	LGD = &lgd;
	
	if _N_ =  1 then do;
		Discount_Rate = 1;
	end;
	else do;
		Discount_Rate = 1 / (1 + &be2)**(Days_for_Discounting / 360);
	end;
	
	EL = ifn(Sl_No = 0, 0, EAD_End_of_Period * PD_Marginal * LGD * Discount_Rate);
	
	format Discount_Rate PERCENT9.2 EL 8.2;
run;

proc sql noprint;
    select sum(EL) into :sum_el
    from ifrs.s5t2_test009;
quit;

data ifrs.s5t2_test010;
	set ifrs.s5t2_test009;
	by Monthly_Dates;
	
	retain prev_EL prev_cumel;
	

    /* Initialize cumulative_sum and prev_EL for the first record */
    if _N_ = 1 then do;
        prev_EL = EL;
        CUM_EL = &sum_el;
        prev_cumel = CUM_EL;
    end;
    else if _N_ = 2 then do;
        CUM_EL = &sum_el - prev_EL;
        prev_cumel = CUM_EL;
        prev_EL = EL;
    end;
    else do;
    	CUM_EL = prev_cumel - prev_EL;
    	prev_EL = EL;
    	prev_cumel = CUM_EL;
    end;
    
    if 12 >= _N_ >= 1 then do;
    	'12_M_Selector'n = 1;
    end;
    else do;
    	'12_M_Selector'n = .;
    end;
    
    if 13 >= _N_ >= 1 then do;
    	'12_M_EL'n = '12_M_Selector'n * EL;
    end;
    else do;
    	'12_M_EL'n = .;
    end;
    Payment_Till_Date =.;
    Total_Repayment =.;
    format CUM_EL '12_M_EL'n comma12.2 Principal_Exposure_AOMD comma12. LGD Percent9.;
run;

/* Final S5T2 Table */

proc contents data=ifrs.s5t2_test010;
run;

proc sql;
    create table ifrs.s5t2_final as
    select 
        Sl_No,
		Monthly_Dates,
		Loan_Disbursment_Date,
		Loan_Disbursement_Indicator,
		Disbursment,
		Principal_Exposure_AOMD,
		Principal_Repayment_Dates,
		Principal_Repayment_Indicator,
		Principal_Repayment,
		Payment_Till_Date,
		Remaining_Principal_Exposure,
		Interest_Amount_Future,
		Interest_accrued_Till_Date,
		Interest_Repayment_Dates,
		Interest_Repayment_Indicator,
		Interest_Repayment,
		Total_Repayment,
		EAD_End_of_Period,
		Days_for_Discounting,
		PD_Marginal,
		LGD,
		Discount_Rate,
		EL,
		CUM_EL,
		'12_M_Selector'n,
		'12_M_EL'n 
    from ifrs.s5t2_test010;
quit;

/* Final S5T6 table */

proc sql noprint;
    select sum(EL) into :sum_el
    from ifrs.s5t2_final;
    
    select sum('12_M_EL'n) into :sum_mel
    from ifrs.s5t2_final;
    
    select sum(Interest_Repayment_Indicator) into :sum_iri
    from ifrs.s5t2_final;
    
    select sum(Interest_Repayment) into :sum_ir
    from ifrs.s5t2_final;
quit;


data ifrs.s5t6_final;
	set ifrs.s5t6_modified;
	Interest_Repayments = &sum_iri;
	Total_Interest_Repayment_Amount = &sum_ir;
	LECL = &sum_el;
	'12_M_ECL'n = &sum_mel;
	format Total_Interest_Repayment_Amount comma12. LECL '12_M_ECL'n 8.2;
run;

/* Sheet 5 Computation End */

**************************************************************************************************************************************************;

/* Assignment Technical Solution */

********************************************************************************************************************************************************;
/* check */
proc sql;
	select Interest_Repayment, Interest_Amount_Future, Remaining_Principal_Exposure from ifrs.s5t2_final where Interest_Repayment <> 0;
quit;

/* proc print data=ifrs.s5t2_test010 noobs; */
/* var Monthly_Dates CUM_EL; */
/* run; */
/*  */
/*  */
/* proc print data=ifrs.s5t6_modified; */
/* run; */
/*     */
/*        	if (Loan_Disbursement_Indicator > 0 AND Monthly_Dates <= Expiry_Date) then */
/*         	Principal_Exposure_AOMD = Disbursement + Outstanding_Principal; */
/*     	else */
/*         	Principal_Exposure_AOMD = 0; */
/*         output; */
/*     end; */
/*      */
/*     retain Monthly_Dates; */
/*     if _N_ = 1 then  */
/*         Monthly_Dates = Valuation_Date; */
/*     else  */
/*     	Monthly_Dates = intnx('month', Monthly_Dates, 1, 'end'); */
/*      */
/*     if intnx('month', Monthly_Dates, 0, 'end') = 'Reporting Date'n then */
/*         Loan_Disbursement_Indicator = 1; */
/*     else */
/*         Loan_Disbursement_Indicator = 0; */
/*          */
/* 	Disbursement = Loan_Disbursement_Indicator * &AV; */
/* 		 */
/*     if (Loan_Disbursement_Indicator > 0 AND Monthly_Dates <= &AR) then */
/*         Principal_Exposure_AOMD = Disbursement + &AX; */
/*     else */
/*         Principal_Exposure_AOMD = 0; */
/*       */
/*     if (Monthly_Dates='31DEC2018'd AND Loan_Disbursement_Indicator=1) then  */
/*     	Interest_accrued_TD = PUT(&BA, COMMA20.); */
/*     else */
/*     	Interest_accrued_TD = 0; */
/*     ARC=&AR; */
/*     '12-M Selector'n = 1; */
/*     Format dates for readability */
/*     format Monthly_Dates Reporting_Date ARC date9. Principal_Exposure_AOMD Interest_accrued_TD comma20.; */
/*      */
/* run; */

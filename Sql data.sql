CREATE TABLE loans (
    LoanNr_ChkDgt BIGINT,
    Name TEXT,
    City TEXT,
    State TEXT,
    Zip INT,
    Bank TEXT,
    BankState TEXT,
    NAICS INT,
    ApprovalDate DATE,
    ApprovalFY INT,
    Term INT,
    NoEmp INT,
    NewExist INT,
    CreateJob INT,
    RetainedJob INT,
    FranchiseCode INT,
    UrbanRural INT,
    RevLineCr TEXT,
    LowDoc TEXT,
    DisbursementDate DATE,
    DisbursementGross NUMERIC,
    BalanceGross NUMERIC,
    MIS_Status TEXT,
    ChgOffPrinGr NUMERIC,
    GrAppv NUMERIC,
    SBA_Appv NUMERIC
);

-- Summary of loan statuses
SELECT MIS_Status, COUNT(*) AS Count
FROM loans
GROUP BY MIS_Status;

-- Loan amount by state
SELECT State, AVG(DisbursementGross) AS AvgLoanAmount
FROM loans
GROUP BY State
ORDER BY AvgLoanAmount DESC;

-- Loan defaults by year
SELECT ApprovalFY, COUNT(*) AS TotalLoans, 
       SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) AS Defaults
FROM loans
GROUP BY ApprovalFY
ORDER BY ApprovalFY;

-- 1. Default Rate Analysis
-- a) By State:
SELECT State, 
       COUNT(*) AS TotalLoans, 
       SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) AS DefaultedLoans,
       ROUND(SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DefaultRate
FROM loans
GROUP BY State
ORDER BY DefaultRate DESC;

-- b) By Industry (NAICS):
SELECT NAICS, 
       COUNT(*) AS TotalLoans, 
       SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) AS DefaultedLoans,
       ROUND(SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DefaultRate
FROM loans
GROUP BY NAICS
ORDER BY DefaultRate DESC;

-- c) By Loan Amount Ranges:
SELECT CASE 
         WHEN DisbursementGross < 50000 THEN '<50K'
         WHEN DisbursementGross BETWEEN 50000 AND 100000 THEN '50K-100K'
         WHEN DisbursementGross BETWEEN 100001 AND 500000 THEN '100K-500K'
         ELSE '>500K'
       END AS LoanAmountRange,
       COUNT(*) AS TotalLoans,
       SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) AS DefaultedLoans,
       ROUND(SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DefaultRate
FROM loans
GROUP BY LoanAmountRange
ORDER BY LoanAmountRange;


-- 2. Loan Duration and Risk:

SELECT Term, 
       COUNT(*) AS TotalLoans, 
       SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) AS DefaultedLoans,
       ROUND(SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DefaultRate
FROM loans
GROUP BY Term
ORDER BY Term;

-- 3. Employment and Risk:

SELECT CASE 
           WHEN NoEmp <= 10 THEN 'Small (<=10)'
           WHEN NoEmp BETWEEN 11 AND 50 THEN 'Medium (11-50)'
           ELSE 'Large (>50)'
         END AS CompanySize,
         COUNT(*) AS TotalLoans,
         SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) AS DefaultedLoans,
         ROUND(SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DefaultRate
FROM loans
GROUP BY CompanySize
ORDER BY DefaultRate DESC;

-- 4. FranchiseCode Analysis:

SELECT FranchiseCode, 
       COUNT(*) AS TotalLoans,
       SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) AS DefaultedLoans,
       ROUND(SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DefaultRate
FROM loans
GROUP BY FranchiseCode
ORDER BY DefaultRate DESC;

-- 5. Bank Performance:

SELECT Bank, 
       COUNT(*) AS TotalLoans, 
       SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) AS DefaultedLoans,
       ROUND(SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DefaultRate
FROM loans
GROUP BY Bank
ORDER BY DefaultRate DESC
LIMIT 10;

-- 6. Time Series Analysis:

SELECT ApprovalFY, 
       COUNT(*) AS TotalLoans, 
       SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) AS DefaultedLoans,
       ROUND(SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DefaultRate
FROM loans
GROUP BY ApprovalFY
ORDER BY ApprovalFY;


-- Loan-to-Approval Ratio:

ALTER TABLE loans ADD COLUMN LoanToApprovalRatio NUMERIC;

UPDATE loans
SET LoanToApprovalRatio = GrAppv / NULLIF(DisbursementGross, 0);

-- Employees-to-Loan Ratio:

ALTER TABLE loans ADD COLUMN EmpToLoanRatio NUMERIC;

UPDATE loans
SET EmpToLoanRatio = NoEmp / NULLIF(DisbursementGross, 0);

-- Categorizing Loan Term:

ALTER TABLE loans ADD COLUMN TermCategory TEXT;

UPDATE loans
SET TermCategory = CASE
    WHEN Term <= 24 THEN 'Short'
    WHEN Term BETWEEN 25 AND 60 THEN 'Medium'
    ELSE 'Long'
END;

-- Grouping Industries by NAICS Code:

ALTER TABLE loans ADD COLUMN IndustryGroup TEXT;

UPDATE loans
SET IndustryGroup = CASE
    WHEN NAICS BETWEEN 110000 AND 210000 THEN 'Agriculture and Mining'
    WHEN NAICS BETWEEN 220000 AND 230000 THEN 'Utilities and Construction'
    WHEN NAICS BETWEEN 310000 AND 330000 THEN 'Manufacturing'
    WHEN NAICS BETWEEN 420000 AND 490000 THEN 'Trade and Transportation'
    ELSE 'Other'
END;

-- Urban vs. Rural:

ALTER TABLE loans ADD COLUMN UrbanIndicator INT;

UPDATE loans
SET UrbanIndicator = CASE
    WHEN UrbanRural = 1 THEN 1
    ELSE 0
END;


-- Preview the updated data:

SELECT LoanNr_ChkDgt, LoanToApprovalRatio, EmpToLoanRatio, TermCategory, IndustryGroup, UrbanIndicator
FROM loans
LIMIT 10;

-- Backup:

CREATE TABLE loans_with_features AS
SELECT * FROM loans;


CREATE TABLE new_loan_applications (
    id SERIAL PRIMARY KEY,
    LoanToApprovalRatio NUMERIC,
    EmpToLoanRatio NUMERIC,
    Term INT,
    DisbursementGross NUMERIC,
    NoEmp INT,
    UrbanIndicator INT,
    TermCategory_Medium INT,
    TermCategory_Long INT,
    IndustryGroup_Manufacturing INT,
    IndustryGroup_Other INT,
    Prediction TEXT DEFAULT NULL -- To store prediction results
);

ALTER TABLE new_loan_applications ADD COLUMN Prediction TEXT DEFAULT NULL;


INSERT INTO new_loan_applications
(LoanToApprovalRatio, EmpToLoanRatio, Term, DisbursementGross, NoEmp, UrbanIndicator, TermCategory_Medium, TermCategory_Long, IndustryGroup_Manufacturing, IndustryGroup_Other)
VALUES
(0.8, 0.02, 36, 50000, 10, 1, 1, 0, 0, 1);



ALTER TABLE new_loan_applications ADD COLUMN id SERIAL PRIMARY KEY;

INSERT INTO new_loan_applications
(LoanToApprovalRatio, EmpToLoanRatio, Term, DisbursementGross, NoEmp, UrbanIndicator, TermCategory_Medium, TermCategory_Long, IndustryGroup_Manufacturing, IndustryGroup_Other)
VALUES
(0.8, 0.02, 36, 50000, 10, 1, 1, 0, 0, 1);

SELECT * FROM new_loan_applications WHERE Prediction IS NOT NULL;

SELECT * FROM new_loan_applications WHERE Prediction IS NULL;

INSERT INTO new_loan_applications
(LoanToApprovalRatio, EmpToLoanRatio, Term, DisbursementGross, NoEmp, UrbanIndicator, TermCategory_Medium, TermCategory_Long, IndustryGroup_Manufacturing, IndustryGroup_Other)
VALUES
(0.8, 0.02, 46, 900000, 10, 1, 1, 0, 0, 1);

CREATE TABLE prediction_feedback (
    id SERIAL PRIMARY KEY,
    loan_id INT REFERENCES new_loan_applications(id),
    correct_prediction BOOLEAN,
    feedback_notes TEXT
);

SELECT 
    id, 
    LoanToApprovalRatio, 
    EmpToLoanRatio, 
    Term, 
    DisbursementGross, 
    NoEmp, 
    UrbanIndicator, 
    TermCategory_Medium, 
    TermCategory_Long, 
    IndustryGroup_Manufacturing, 
    IndustryGroup_Other, 
    Prediction,
    CASE 
        WHEN Prediction = 'No Default' THEN 'Approved'
        WHEN Prediction = 'Default' THEN 'Not Approved'
        ELSE 'Pending'
    END AS LoanApprovalStatus
FROM new_loan_applications;




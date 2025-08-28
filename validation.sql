SELECT * FROM dbo.banking_transaction

SELECT * FROM dbo.customer_account

--1
-- Check for NULL records in banking_transaction table
SELECT COUNT(*)
FROM dbo.banking_transaction
WHERE transaction_id IS NULL
   OR account_number IS NULL
   OR transaction_type IS NULL
   OR amount IS NULL
   OR transaction_date IS NULL
   OR branch_code IS NULL
   OR currency IS NULL
   OR transaction_time IS NULL;

-- Check for NULL records in customer_account table
SELECT COUNT(*)
FROM dbo.customer_account
WHERE account_number IS NULL
   OR account_holder IS NULL
   OR account_type IS NULL
   OR balance IS NULL;

--2
-- Check for duplicate transaction_id values
SELECT transaction_id, COUNT(*)
FROM dbo.banking_transaction
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- Check for duplicate account_number values
SELECT account_number, COUNT(*)
FROM dbo.customer_account
GROUP BY account_number
HAVING COUNT(*) > 1;

-- 3.Check Distinct Values for All Columns
-- Banking Transaction Table
SELECT 
    COUNT(DISTINCT transaction_id) AS distinct_transaction_ids,
    COUNT(DISTINCT account_number) AS distinct_account_numbers,
    COUNT(DISTINCT transaction_type) AS distinct_transaction_types,
    COUNT(DISTINCT amount) AS distinct_amounts,
    COUNT(DISTINCT transaction_date) AS distinct_dates,
    COUNT(DISTINCT branch_code) AS distinct_branches,
    COUNT(DISTINCT currency) AS distinct_currencies,
    COUNT(DISTINCT transaction_time) AS distinct_times
FROM dbo.banking_transaction;

-- View actual distinct values for categorical columns
SELECT 'transaction_type' AS column_name, transaction_type AS value, COUNT(*) AS count
FROM dbo.banking_transaction
GROUP BY transaction_type
ORDER BY count DESC;

SELECT 'currency' AS column_name, currency AS value, COUNT(*) AS count
FROM dbo.banking_transaction
GROUP BY currency
ORDER BY count DESC;

SELECT 'branch_code' AS column_name, branch_code AS value, COUNT(*) AS count
FROM dbo.banking_transaction
GROUP BY branch_code
ORDER BY count DESC;

-- Customer Account Table
SELECT 
    COUNT(DISTINCT account_number) AS distinct_account_numbers,
    COUNT(DISTINCT account_holder) AS distinct_account_holders,
    COUNT(DISTINCT account_type) AS distinct_account_types,
    COUNT(DISTINCT balance) AS distinct_balances,
    COUNT(DISTINCT interest_rate) AS distinct_interest_rates,
    COUNT(DISTINCT credit_score) AS distinct_credit_scores,
    COUNT(DISTINCT opening_date) AS distinct_opening_dates,
    COUNT(DISTINCT loan_amount) AS distinct_loan_amounts,
    COUNT(DISTINCT account_holder_details) AS distinct_holder_details
FROM dbo.customer_account;

-- View actual distinct values for categorical columns
SELECT 'account_type' AS column_name, account_type AS value, COUNT(*) AS count
FROM dbo.customer_account
GROUP BY account_type
ORDER BY count DESC;

SELECT 'account_holder' AS column_name, account_holder AS value, COUNT(*) AS count
FROM dbo.customer_account
GROUP BY account_holder
ORDER BY count DESC;


--4. Check Value Ranges for Numerical Columns
-- Banking Transaction Table
SELECT 
    MIN(transaction_id) AS min_id,
    MAX(transaction_id) AS max_id,
    AVG(transaction_id) AS avg_id,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount,
    AVG(amount) AS avg_amount,
    MIN(transaction_time) AS min_time,
    MAX(transaction_time) AS max_time,
    AVG(transaction_time) AS avg_time
FROM dbo.banking_transaction;

-- Customer Account Table
SELECT 
    MIN(account_number) AS min_account_no,
    MAX(account_number) AS max_account_no,
    AVG(account_number) AS avg_account_no,
    MIN(balance) AS min_balance,
    MAX(balance) AS max_balance,
    AVG(balance) AS avg_balance,
    MIN(interest_rate) AS min_interest,
    MAX(interest_rate) AS max_interest,
    AVG(interest_rate) AS avg_interest,
    MIN(credit_score) AS min_credit_score,
    MAX(credit_score) AS max_credit_score,
    AVG(credit_score) AS avg_credit_score,
    MIN(loan_amount) AS min_loan,
    MAX(loan_amount) AS max_loan,
    AVG(loan_amount) AS avg_loan
FROM dbo.customer_account;

-- 5. Check Data Consistency Between Tables
-- Check if all transaction account numbers exist in customer account table
SELECT 
    COUNT(DISTINCT bt.account_number) AS transaction_accounts,
    COUNT(DISTINCT ca.account_number) AS customer_accounts,
    COUNT(DISTINCT CASE WHEN ca.account_number IS NULL THEN bt.account_number END) AS missing_accounts
FROM dbo.banking_transaction bt
LEFT JOIN dbo.customer_account ca ON bt.account_number = ca.account_number;

-- List transactions with missing account numbers
SELECT bt.*
FROM dbo.banking_transaction bt
LEFT JOIN dbo.customer_account ca ON bt.account_number = ca.account_number
WHERE ca.account_number IS NULL;

-- Check date ranges for both tables
SELECT 
    'Transaction' AS table_name,
    MIN(transaction_date) AS earliest_date,
    MAX(transaction_date) AS latest_date,
    DATEDIFF(day, MIN(transaction_date), MAX(transaction_date)) AS date_range_days
FROM dbo.banking_transaction
UNION ALL
SELECT 
    'Customer Account' AS table_name,
    MIN(opening_date) AS earliest_date,
    MAX(opening_date) AS latest_date,
    DATEDIFF(day, MIN(opening_date), MAX(opening_date)) AS date_range_days
FROM dbo.customer_account;


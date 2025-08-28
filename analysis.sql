/* -- Capstone Project: Bank Transactions Analysis
Student: Thanh Vu
Data source: banking.bak
-- */

USE banking
GO

/* -----------------------------------------------------------------------------------------------------------------
Q1: 
Calculate the total number of transactions, total transaction amount, average balance, and total loan amount for each year.
- Exclude years without complete data
- Round transaction amount, balance, and loan amount to millions (2 decimal places)
- Round number of transactions to thousands (1 decimal place)
*/
SELECT 
    YEAR(transaction_date) AS [year],
    ROUND(COUNT(*) / 1000.0, 1) AS nb_transactions_in_thousands,
    ROUND(SUM(amount) / 1000000.0, 2) AS total_amount_million,
    ROUND(AVG(a.balance) / 1000000.0, 2) AS avg_balance_million,
    ROUND(SUM(a.loan_amount) / 1000000.0, 2) AS total_loans_million
FROM dbo.banking_transaction t
JOIN dbo.customer_account a ON t.account_number = a.account_number
GROUP BY YEAR(transaction_date)
ORDER BY [year];


/* -----------------------------------------------------------------------------------------------------------------
Q2: 
Calculate the growth rate (%) of transaction amount, number of transactions, and loan amount in the most recent year compared to the previous year.
*/
WITH yearly AS (
    SELECT 
        YEAR(transaction_date) AS [year],
        COUNT(*) AS nb_transactions,
        SUM(amount) AS total_amount,
        SUM(a.loan_amount) AS total_loans
    FROM dbo.banking_transaction t
    JOIN dbo.customer_account a ON t.account_number = a.account_number
    GROUP BY YEAR(transaction_date)
)
SELECT 
    y.[year],
    y.nb_transactions,
    y.total_amount,
    y.total_loans,
    (y.total_amount - LAG(y.total_amount) OVER (ORDER BY y.[year])) * 100.0 
        / NULLIF(LAG(y.total_amount) OVER (ORDER BY y.[year]),0) AS amount_growth_pct,
    (y.nb_transactions - LAG(y.nb_transactions) OVER (ORDER BY y.[year])) * 100.0 
        / NULLIF(LAG(y.nb_transactions) OVER (ORDER BY y.[year]),0) AS tx_growth_pct,
    (y.total_loans - LAG(y.total_loans) OVER (ORDER BY y.[year])) * 100.0 
        / NULLIF(LAG(y.total_loans) OVER (ORDER BY y.[year]),0) AS loan_growth_pct
FROM yearly y
ORDER BY y.[year] DESC;


/* -----------------------------------------------------------------------------------------------------------------
Q3: 
Calculate the year-over-year growth rate of transaction amount.
*/
WITH yearly AS (
    SELECT 
        YEAR(transaction_date) AS [year],
        SUM(amount) AS total_amount
    FROM dbo.banking_transaction
    GROUP BY YEAR(transaction_date)
)
SELECT 
    y.[year],
    y.total_amount,
    LAG(y.total_amount) OVER (ORDER BY y.[year]) AS prev_amount,
    (y.total_amount - LAG(y.total_amount) OVER (ORDER BY y.[year])) * 100.0 
        / NULLIF(LAG(y.total_amount) OVER (ORDER BY y.[year]),0) AS growth_rate_pct
FROM yearly y
ORDER BY y.[year];


/* -----------------------------------------------------------------------------------------------------------------
Q4: 
Calculate total transaction amount and the percentage contribution of each transaction type per year.
*/
WITH yearly_type AS (
    SELECT 
        YEAR(transaction_date) AS [year],
        transaction_type,
        SUM(amount) AS total_amount
    FROM dbo.banking_transaction
    GROUP BY YEAR(transaction_date), transaction_type
)
SELECT 
    yt.[year],
    yt.transaction_type,
    yt.total_amount,
    ROUND(yt.total_amount * 100.0 / SUM(yt.total_amount) OVER (PARTITION BY yt.[year]), 2) AS pct_contribution
FROM yearly_type yt
ORDER BY yt.[year], yt.total_amount DESC;


/* -----------------------------------------------------------------------------------------------------------------
Q5: 
Summarize total transaction amount by branch (branch_code) and by currency. 
Sort in descending order of transaction amount.
*/
-- by branch
SELECT branch_code, SUM(amount) AS total_amount
FROM dbo.banking_transaction
GROUP BY branch_code
ORDER BY total_amount DESC;

-- by currency
SELECT currency, SUM(amount) AS total_amount
FROM dbo.banking_transaction
GROUP BY currency
ORDER BY total_amount DESC;


/* -----------------------------------------------------------------------------------------------------------------
Q6: 
Rank the branches with the highest transaction amount (or highest growth rate) in the most recent year.
*/
WITH yearly_branch AS (
    SELECT 
        YEAR(transaction_date) AS [year],
        branch_code,
        SUM(amount) AS total_amount
    FROM dbo.banking_transaction
    GROUP BY YEAR(transaction_date), branch_code
)
SELECT *
FROM (
    SELECT 
        yb.[year],
        yb.branch_code,
        yb.total_amount,
        RANK() OVER (PARTITION BY yb.[year] ORDER BY yb.total_amount DESC) AS branch_rank
    FROM yearly_branch yb
) ranked
WHERE ranked.[year] = (SELECT MAX(YEAR(transaction_date)) FROM dbo.banking_transaction)
ORDER BY branch_rank;


/* -----------------------------------------------------------------------------------------------------------------
Q7: 
Calculate the percentage share of transaction amount by credit score range.
Calculate the percentage share of transaction amount by account type.
*/
-- by credit score range
SELECT 
    CASE 
        WHEN credit_score < 580 THEN 'Poor'
        WHEN credit_score BETWEEN 580 AND 669 THEN 'Fair'
        WHEN credit_score BETWEEN 670 AND 739 THEN 'Good'
        WHEN credit_score BETWEEN 740 AND 799 THEN 'Very Good'
        ELSE 'Excellent'
    END AS credit_score_range,
    SUM(t.amount) AS total_amount,
    ROUND(SUM(t.amount) * 100.0 / SUM(SUM(t.amount)) OVER (), 2) AS pct_share
FROM dbo.banking_transaction t
JOIN dbo.customer_account a ON t.account_number = a.account_number
GROUP BY 
    CASE 
        WHEN credit_score < 580 THEN 'Poor'
        WHEN credit_score BETWEEN 580 AND 669 THEN 'Fair'
        WHEN credit_score BETWEEN 670 AND 739 THEN 'Good'
        WHEN credit_score BETWEEN 740 AND 799 THEN 'Very Good'
        ELSE 'Excellent'
    END;


-- by account type
SELECT 
    a.account_type,
    SUM(t.amount) AS total_amount,
    ROUND(SUM(t.amount) * 100.0 / SUM(SUM(t.amount)) OVER (), 2) AS pct_share
FROM dbo.banking_transaction t
JOIN dbo.customer_account a ON t.account_number = a.account_number
GROUP BY a.account_type;


/* -----------------------------------------------------------------------------------------------------------------
Q8: 
Calculate the percentage share of transaction amount by transaction type within each credit score range.
Calculate the percentage share of transaction amount by transaction type within each account type.
*/
-- by transaction type and credit score range
SELECT 
    CASE 
        WHEN credit_score < 580 THEN 'Poor'
        WHEN credit_score BETWEEN 580 AND 669 THEN 'Fair'
        WHEN credit_score BETWEEN 670 AND 739 THEN 'Good'
        WHEN credit_score BETWEEN 740 AND 799 THEN 'Very Good'
        ELSE 'Excellent'
    END AS credit_score_range,
    t.transaction_type,
    SUM(t.amount) AS total_amount,
    ROUND(SUM(t.amount) * 100.0 
        / SUM(SUM(t.amount)) OVER (PARTITION BY 
            CASE 
                WHEN credit_score < 580 THEN 'Poor'
                WHEN credit_score BETWEEN 580 AND 669 THEN 'Fair'
                WHEN credit_score BETWEEN 670 AND 739 THEN 'Good'
                WHEN credit_score BETWEEN 740 AND 799 THEN 'Very Good'
                ELSE 'Excellent'
            END), 2) AS pct_share
FROM dbo.banking_transaction t
JOIN dbo.customer_account a ON t.account_number = a.account_number
GROUP BY t.transaction_type,
    CASE 
        WHEN credit_score < 580 THEN 'Poor'
        WHEN credit_score BETWEEN 580 AND 669 THEN 'Fair'
        WHEN credit_score BETWEEN 670 AND 739 THEN 'Good'
        WHEN credit_score BETWEEN 740 AND 799 THEN 'Very Good'
        ELSE 'Excellent'
    END;

-- by transaction type and account type
SELECT 
    a.account_type,
    t.transaction_type,
    SUM(t.amount) AS total_amount,
    ROUND(SUM(t.amount) * 100.0 
        / SUM(SUM(t.amount)) OVER (PARTITION BY a.account_type), 2) AS pct_share
FROM dbo.banking_transaction t
JOIN dbo.customer_account a ON t.account_number = a.account_number
GROUP BY a.account_type, t.transaction_type;


/* -----------------------------------------------------------------------------------------------------------------
Q9: 
Analyze transaction amount by profession, residence, and city (account_holder_details).
*/
-- by sector
SELECT LTRIM(RTRIM(
        SUBSTRING(
            a.account_holder_details,
            CHARINDEX(':', a.account_holder_details) + 1,
            CHARINDEX(',', a.account_holder_details) - CHARINDEX(':', a.account_holder_details) - 1
        )
    )) AS sector , 
SUM(t.amount) AS total_amount
FROM dbo.banking_transaction t
JOIN dbo.customer_account a ON t.account_number = a.account_number
GROUP BY LTRIM(RTRIM(
        SUBSTRING(
            a.account_holder_details,
            CHARINDEX(':', a.account_holder_details) + 1,
            CHARINDEX(',', a.account_holder_details) - CHARINDEX(':', a.account_holder_details) - 1
        )
    ))
ORDER BY total_amount DESC;

-- by residence
SELECT CAST(
        LTRIM(RTRIM(
            SUBSTRING(
                a.account_holder_details,
                CHARINDEX('Residence:', a.account_holder_details) + LEN('Residence:'),
                CHARINDEX('years', a.account_holder_details) - CHARINDEX('Residence:', a.account_holder_details) - LEN('Residence:')
            )
        )) AS INT
    ) AS residence_year,
SUM(t.amount) AS total_amount
FROM dbo.banking_transaction t
JOIN dbo.customer_account a ON t.account_number = a.account_number
GROUP BY CAST(
        LTRIM(RTRIM(
            SUBSTRING(
                a.account_holder_details,
                CHARINDEX('Residence:', a.account_holder_details) + LEN('Residence:'),
                CHARINDEX('years', a.account_holder_details) - CHARINDEX('Residence:', a.account_holder_details) - LEN('Residence:')
            )
        )) AS INT)
ORDER BY total_amount DESC;

-- by city
SELECT LTRIM(RTRIM(
        SUBSTRING(
            a.account_holder_details,
            CHARINDEX(':', a.account_holder_details, CHARINDEX(':', a.account_holder_details, CHARINDEX(':', a.account_holder_details) + 1) + 1) + 1,
            LEN(a.account_holder_details)
        )
    )) AS city,
SUM(t.amount) AS total_amount
FROM dbo.banking_transaction t
JOIN dbo.customer_account a ON t.account_number = a.account_number
GROUP BY LTRIM(RTRIM(
        SUBSTRING(
            a.account_holder_details,
            CHARINDEX(':', a.account_holder_details, CHARINDEX(':', a.account_holder_details, CHARINDEX(':', a.account_holder_details) + 1) + 1) + 1,
            LEN(a.account_holder_details)
        )
    ))
ORDER BY total_amount DESC;

/* -----------------------------------------------------------------------------------------------------------------
Q10: 
For which day of the week do customers in each credit score range make the most transactions?
At what hour of the day do customers typically make the most transactions?
*/

SELECT 
    CASE 
        WHEN credit_score < 580 THEN 'Poor'
        WHEN credit_score BETWEEN 580 AND 669 THEN 'Fair'
        WHEN credit_score BETWEEN 670 AND 739 THEN 'Good'
        WHEN credit_score BETWEEN 740 AND 799 THEN 'Very Good'
        ELSE 'Excellent'
    END AS credit_score_range,
    DATENAME(WEEKDAY, t.transaction_date) AS weekday_name,
    COUNT(*) AS nb_transactions
FROM dbo.banking_transaction t
JOIN dbo.customer_account a ON t.account_number = a.account_number
GROUP BY DATENAME(WEEKDAY, t.transaction_date),
    CASE 
        WHEN credit_score < 580 THEN 'Poor'
        WHEN credit_score BETWEEN 580 AND 669 THEN 'Fair'
        WHEN credit_score BETWEEN 670 AND 739 THEN 'Good'
        WHEN credit_score BETWEEN 740 AND 799 THEN 'Very Good'
        ELSE 'Excellent'
    END
ORDER BY credit_score_range, nb_transactions DESC;

-- Peak transaction hours
SELECT transaction_time AS [hour], COUNT(*) AS nb_transactions
FROM dbo.banking_transaction
GROUP BY transaction_time
ORDER BY nb_transactions DESC;


/* ============================================================================
1. Relationship between account balance and transaction frequency
   - Group customers into Low / Medium / High balance levels
   - Compare average number of transactions per group
============================================================================ */
WITH balance_groups AS (
    SELECT 
        account_number,
        CASE 
            WHEN balance < 1000 THEN 'Low'
            WHEN balance BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS balance_group
    FROM dbo.customer_account
)
SELECT 
    bg.balance_group,
    COUNT(t.transaction_id) * 1.0 / COUNT(DISTINCT bg.account_number) AS avg_transactions_per_account
FROM balance_groups bg
LEFT JOIN dbo.banking_transaction t 
    ON bg.account_number = t.account_number
GROUP BY bg.balance_group
ORDER BY avg_transactions_per_account DESC;


/* ============================================================================
2. Impact of credit score on transaction type
   - Compare distribution of transaction types (withdrawal, deposit, transfer, payment)
   - Across credit score categories
============================================================================ */
WITH credit_groups AS (
    SELECT 
        account_number,
        CASE 
            WHEN credit_score < 600 THEN 'Low'
            WHEN credit_score BETWEEN 600 AND 750 THEN 'Medium'
            ELSE 'High'
        END AS credit_group
    FROM dbo.customer_account
)
SELECT 
    cg.credit_group,
    t.transaction_type,
    COUNT(*) AS transaction_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY cg.credit_group), 2) AS pct_within_group
FROM credit_groups cg
JOIN dbo.banking_transaction t
    ON cg.account_number = t.account_number
GROUP BY cg.credit_group, t.transaction_type
ORDER BY cg.credit_group, pct_within_group DESC;


/* ============================================================================
3. Transaction trends by time and branch
   - Hour of day
   - Day of week
   - Branch activity levels
============================================================================ */
SELECT 
    DATEPART(HOUR, t.transaction_date) AS transaction_hour,
    DATENAME(WEEKDAY, t.transaction_date) AS weekday_name,
    t.branch_code,
    COUNT(*) AS transaction_count
FROM dbo.banking_transaction t
GROUP BY DATEPART(HOUR, t.transaction_date), DATENAME(WEEKDAY, t.transaction_date), t.branch_code
ORDER BY t.branch_code, transaction_count DESC;


/* ============================================================================
4. Factors affecting long-term account retention
   - Retained = accounts still open (close_date IS NULL)
   - Compare by account type, avg balance, transaction frequency
============================================================================ */

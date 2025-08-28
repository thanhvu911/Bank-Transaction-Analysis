SELECT * FROM dbo.banking_transaction
-- Transform NULL amount to 0
UPDATE dbo.banking_transaction
SET amount = 0
WHERE amount IS NULL;
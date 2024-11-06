USE demo;

SELECT * FROM bank_data;

-- 1. General Loan Insights

-- 1.1 Total Number of Applications
SELECT COUNT(id) as total_loan_applications 
FROM bank_data;
-- we have 38,576 loan appliations

-- 1.2 Total funded amount
SELECT sum(loan_amount)/1000000 as total_funded_amount_in_millions 
FROM bank_data;

-- 1.3 Total payment received
SELECT sum(total_payment)/1000000 as total_payment_recieved_in_millions
FROM bank_data; 
-- 473 million

-- 1.4 What is the average interest rate and debt-to-income (DTI) ratio of all loan applications?
SELECT ROUND(AVG(int_rate),3)*100 as Avg_interest_rate, ROUND(AVG(dti),3)*100 as Avg_debt_to_income
FROM
bank_data;
-- Average Interest rate = 12%
-- Average DTI = 13.3%

-- 2. Good vs. Bad Loans:
-- 2.1 What percentage of loan applications are considered good (paid on time or fully paid off)?
SELECT DISTINCT loan_status FROM bank_data;

SELECT COUNT(*) as Total_app,
COUNT(CASE WHEN loan_status in ('Fully Paid', 'Current') THEN 'Good Loan'
    END) as No_good_loans,
COUNT(CASE WHEN loan_status in ('Fully Paid', 'Current') THEN 'Good Loan'
    END)*100/COUNT(*) AS percentage_of_good_loan
FROM 
bank_data;
-- 86.1753% good loans out of 38576 i.e. 335243

-- 2.2 What percentage of loan applications are considered bad (borrowers who failed to repay)?
SELECT COUNT(*) as Total_app,
COUNT(CASE WHEN loan_status not in ('Fully Paid', 'Current') THEN 'Bad Loan'
    END) as No_good_loans,
COUNT(CASE WHEN loan_status not in ('Fully Paid', 'Current') THEN 'Bad Loan'
    END)*100/COUNT(*) AS percentage_of_good_loan
FROM 
bank_data;
-- 5333 i.e. 13.824% Bad Loans

-- 2.3 What is the total amount received from good loans compared to bad loans?
WITH good_bad_loan AS(
SELECT CASE WHEN loan_status in ('Fully Paid', 'Current') THEN 'Good Loan'
	ELSE 'Bad Loan'
    END AS Good_or_Bad_loan,
    total_payment
	FROM bank_data)
SELECT 
Good_or_Bad_loan, ROUND(SUM(total_payment)/1000000,2) AS total_payment_millions
FROM good_bad_loan
GROUP BY Good_or_Bad_loan;
-- Good -> 435.79M
-- Bad -> 37.28M

-- 2.4 What is the trend in the repayment behavior over time for good vs. bad loans?
SELECT 
    DATE_FORMAT(issue_date, '%Y-%m') AS month,
    SUM(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 ELSE 0 END) AS good_loans,
    SUM(CASE WHEN loan_status IN ('Charged Off', 'Default') THEN 1 ELSE 0 END) AS bad_loans
FROM bank_data
GROUP BY month
ORDER BY month;

-- 3. Regional Analysis
-- 3.1 What are the total loan amounts disbursed in each state?
SELECT address_state, ROUND(SUM(loan_amount)/1000000,2) as amount_disbursed
FROM bank_data
GROUP BY address_state
ORDER BY amount_disbursed DESC;

-- 3.2 Which state has the highest number of loan applications?
SELECT address_state , COUNT(*) as no_of_loan_applications
FROM bank_data
GROUP BY address_state
ORDER BY no_of_loan_applications DESC; 

-- 3.3 How do the rates of good and bad loans compare by state?
WITH good_bad_loan AS(
SELECT address_state,
SUM(CASE WHEN loan_status in ('Fully Paid', 'Current') THEN 1 ELSE 0 END) AS Good_loan,
SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS Bad_loan
FROM bank_data
GROUP BY address_state)
SELECT 
address_state,
ROUND((Good_loan/(Good_loan+Bad_loan))*100,2) AS Good_loan_percentage,
ROUND((Bad_loan/(Good_loan+Bad_loan))*100,2) AS Bad_loan_percentage
FROM good_bad_loan;

-- 4. Monthly and Long-Term Analysis:
-- Transforming issue_date column from text format to date
UPDATE bank_data
SET issue_date = STR_TO_DATE(`issue_date`, '%d-%m-%Y')
WHERE issue_date IS NOT NULL;
ALTER TABLE bank_data
CHANGE COLUMN issue_date issue_date DATE NULL;

-- 4.1 What is the monthly trend in the number of loan applications submitted?
SELECT MONTH(issue_date) as month, COUNT(id) as no_of_applications
FROM bank_data
GROUP BY MONTH(issue_date)
ORDER BY month;
-- increasing in application trend over the months

-- 4.2 How much money has been lent and received by the bank each month (net interest income)?
SELECT MONTH(issue_date) as month, 
	ROUND((SUM(total_payment) - SUM(loan_amount))/1000000,2) as net_interest_income_millions
FROM bank_data
GROUP BY MONTH(issue_date)
ORDER BY month;

-- 5. Purpose-Based Analysis
-- 5.1 What are the most common purposes for which loans are taken?
SELECT DISTINCT purpose, ROUND((COUNT(id)/(SELECT COUNT(*) FROM bank_data))*100,2) as percentage_of_applications
FROM bank_data
GROUP BY purpose
ORDER BY percentage_of_applications DESC;

-- 5.2 How does the loan repayment success rate vary by purpose?
SELECT 
    purpose,
    COUNT(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 END) AS good_loans,
    COUNT(CASE WHEN loan_status IN ('Charged Off', 'Default') THEN 1 END) AS bad_loans,
    COUNT(*) AS total_loans,
    ROUND(
        (COUNT(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 END) / COUNT(*)) * 100, 
        2
    ) AS success_rate_percentage
FROM bank_data
GROUP BY purpose
ORDER BY success_rate_percentage DESC;

-- 5.3 Which loan purposes contribute the most to bad loans?
SELECT DISTINCT purpose,
ROUND( (SUM(
		CASE 
			WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) 
            OVER (PARTITION BY purpose) / (SELECT COUNT(*) FROM bank_data WHERE loan_status = 'Charged Off')) *100,2)
as percentage_of_bad_loans
FROM bank_data
ORDER BY percentage_of_bad_loans DESC;



















-- ---------------------------------------------------------


SELECT DISTINCT purpose from bank_data;




-- Avg interest rate for each type of loan
SELECT purpose, ROUND(avg(int_rate),3) as avg_int_rate
FROM bank_data
GROUP BY purpose
ORDER BY avg_int_rate DESC;

-- Calculate the avg dti which will be grouped by monthly basis for year 2021
SELECT YEAR(issue_date) as Year,
MONTH(issue_date) as Month,
ROUND(avg(dti),2) as avg_dti
FROM bank_data
WHERE YEAR(issue_date) = 2021
GROUP BY YEAR(issue_date), month(issue_date)
ORDER BY Month;

-- Good Loan vs Bad Loan
SELECT DISTINCT loan_status from bank_data;
-- Good Loan applications in %
SELECT COUNT(
CASE WHEN loan_status = 'Fully Paid' OR loan_status = 'Current' THEN 'Good Loan'
	ELSE 'Bad Loan'
    END) as loan_type
FROM bank_data;

SELECT COUNT(
CASE when loan_status = 'Fully Paid' OR loan_status = 'Current' THEN id end) * 100 / count(id)
AS good_loan_percentage from bank_data;

SELECT COUNT(*) as total_loan_applications, COUNT(
CASE WHEN loan_status in ('Fully paid', 'Current') then id end)
as good_loan_app 
FROM bank_data;

-- Total amount received in good loan applications
SELECT ROUND(SUM(total_payment)/1000000,2) as total_amount_received_in_millions
FROM bank_data
WHERE loan_status in ('Fully paid', 'Current');
-- -------------

-- Month to Month total amount recieved
WITH monthlytotals AS(
SELECT year(issue_date) as year, month(issue_date) as month,
SUM(total_payment) as monthly_payment
FROM bank_data
WHERE year(issue_date) = 2021
group by year(issue_date), month(issue_date)
),
monthovermonth as (
SELECT year, month, monthly_payment as current_month_payment,
monthly_payment as previous_month_payment,
monthly_payment - monthly_payment as month_over_month_amt
FROM






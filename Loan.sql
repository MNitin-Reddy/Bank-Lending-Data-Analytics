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
FROM good_bad_loan
ORDER BY Good_loan_percentage DESC;

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

-- 6. Home Ownership Analysis
-- 6.1 How does home ownership status impact the likelihood of timely payments?
SELECT home_ownership,
SUM(CASE WHEN loan_status IN ('Fully paid','Current') THEN 1 ELSE 0 END) as No_of_good_loans,
SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as No_of_bad_loans,
COUNT(*) as Total_loans,
ROUND( SUM(CASE WHEN loan_status IN ('Fully paid','Current') THEN 1 ELSE 0 END)*100 / COUNT(*) ,2) as Timely_payment_percentage
FROM bank_data
GROUP BY home_ownership
ORDER BY Timely_payment_percentage DESC;
-- Not a significant impact on loan repayment

-- 6.2 What percentage of loan applicants are homeowners, renters, or have a mortgage?
SELECT b.home_ownership, b.total_loans, b.total_loans*100 / a.overall_loans as percentage_of_loans
FROM
(SELECT COUNT(*)  as overall_loans
FROM bank_data) AS a
CROSS JOIN
(SELECT home_ownership, COUNT(*) as total_loans
FROM bank_data
GROUP BY home_ownership) AS b;

-- 6.3 How do the average loan amounts and repayment success differ by home ownership status?
SELECT home_ownership, 
ROUND(AVG(loan_amount)/1000,2) as avg_loan_amount_in_k$,
ROUND(COUNT(CASE WHEN loan_status = 'Fully Paid' OR loan_status = 'Current' THEN 1 END) * 100.0 / COUNT(*),2) AS repayment_success_rate
FROM bank_data
GROUP BY home_ownership
ORDER BY repayment_success_rate DESC;



-- 7. Loan Status Breakdown:

-- 7.1 How many loans have been paid off, are pending, or have been charged off?
SELECT DISTINCT loan_status , COUNT(*) OVER (PARTITION BY loan_status) as no_of_applications
FROM bank_data
ORDER BY no_of_applications DESC;

-- 7.2 What are the repayment trends over the past year(s)?
SELECT 
    YEAR(last_payment_date) AS year,
    COUNT(CASE WHEN loan_status = 'Fully Paid' THEN 1 END) * 100.0 / COUNT(*) AS repayment_success_rate,
    SUM(total_payment) AS total_repayment_amount
FROM bank_data
WHERE  last_payment_date IS NOT NULL 
GROUP BY YEAR(last_payment_date)
ORDER BY year;


-- 8. Annual Income vs. Loan Amount:
-- 8.1 What is the correlation between annual income and the average loan amount taken?
SELECT 
    FLOOR(annual_income / 100000) * 100000 AS income_range,
    AVG(loan_amount) AS average_loan_amount
FROM bank_data
GROUP BY income_range
ORDER BY income_range;

SELECT @firstValue:=avg(annual_income) as mean1,
	@secondValue:=avg(loan_amount) as mean2,
    @division:=(stddev_samp(annual_income) * stddev_samp(loan_amount))  as std
FROM bank_data;
select ROUND ( sum( ( annual_income - @firstValue ) * (loan_amount - @secondValue) ) / ((count(annual_income) -1) * @division), 2 ) as correlation
FROM bank_data;
-- Not much correlaion between these columns that means higher or lower income doesn't effect the loan amount taken.

-- 8.2 How many borrowers have taken loans higher than a set multiple of their annual income?
SELECT
CASE WHEN multiples >= 0.8 THEN "0.8x more than annual_income"
	WHEN multiples >= 0.5 AND multiples < 0.8 THEN "0.5x more than annual_income"
    ELSE "Less than 0.5x annual_income"
    END as multiple_more_than_income,
COUNT(*)
FROM (
SELECT loan_amount/annual_income as multiples from bank_data) as loan_multiples
GROUP BY multiple_more_than_income;
-- Most of the people take less than 50% of annual_income as loan_amount

-- 8.3 How does income level impact loan repayment success (good vs. bad loans)?
SELECT MIN(annual_income) as min , MAX(annual_income) as max from bank_data;
SELECT annual_income from bank_data ORDER BY annual_income DESC;
SELECT 
    CASE 
        WHEN annual_income < 30000 THEN '< 30k'
        WHEN annual_income BETWEEN 30000 AND 60000 THEN '30k-60k'
        WHEN annual_income BETWEEN 60001 AND 100000 THEN '60k-100k'
        WHEN annual_income BETWEEN 100001 AND 150000 THEN '100k-150k'
        WHEN annual_income BETWEEN 150001 AND 200000 THEN '150k-200k'
        WHEN annual_income > 200000 THEN '> 200k'
    END AS income_level,
    ROUND(COUNT(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 END) * 100.0 / COUNT(*) , 2) AS good_loan_percentage,
    ROUND(COUNT(CASE WHEN loan_status IN ('Charged Off', 'Defaulted') THEN 1 END) * 100.0 / COUNT(*), 2) AS bad_loan_percentage
FROM bank_data
GROUP BY income_level
ORDER BY income_level;
-- Higher income levels are associated with better loan repayment success. 
-- Borrowers earning over $200k have a high good loan percentage (89.79%), while those earning under $30k have a lower success rate (82.56%). 
-- Mid-range income borrowers fall between these extremes. 
-- This trend suggests that higher-income borrowers are more financially capable of timely repayments, while lower-income borrowers may benefit from flexible repayment options to improve loan outcomes.

-- 9. Employment Analysis
-- 9.1 What is the distribution of loan amounts by employment length?
SELECT emp_length, AVG(loan_amount) as avg_loan_amount
FROM bank_data
GROUP BY emp_length
ORDER BY emp_length;
-- There seems to be a positive correlation between emp_length and avgerage loan_amount taken

-- 9.2 How does the repayment success rate vary by different employment lengths?
SELECT
emp_length, 
ROUND(COUNT(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 END) * 100.0 / COUNT(*) , 2) AS good_loan_percentage,
ROUND(COUNT(CASE WHEN loan_status IN ('Charged Off', 'Defaulted') THEN 1 END) * 100.0 / COUNT(*), 2) AS bad_loan_percentage
from bank_data
GROUP BY emp_length
ORDER BY emp_length;
-- Similar trend for all the employment length ranges

-- 10. Interest Rate and Installment Analysis
-- 10.1 What is the average interest rate and how does it differ by grade?
SELECT grade, ROUND( AVG(int_rate)*100, 2) as avg_interest_rate  FROM bank_data
GROUP BY grade
ORDER BY grade;
-- Grade G has the highest interest rate of 21% and with lowest if 7.3%
-- As the grade goes from A to G the interest rate increases by 2% through each level

-- 10.2  What is the average installment amount, and how does it relate to loan repayment status?
SELECT DISTINCT installment FROM bank_data ORDER BY installment DESC;

SELECT 
    CASE 
        WHEN installment < 200 THEN '< 200'
        WHEN installment BETWEEN 200 AND 400 THEN '200-400'
        WHEN installment BETWEEN 400 AND 600 THEN '400-600'
        WHEN installment BETWEEN 600 AND 800 THEN '600-800'
        WHEN installment BETWEEN 800 AND 1000 THEN '800-1000'
        WHEN installment > 1000 THEN '>1000'
    END AS installment_level,
    ROUND(COUNT(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 END) * 100.0 / COUNT(*) , 2) AS good_loan_percentage,
    ROUND(COUNT(CASE WHEN loan_status IN ('Charged Off', 'Defaulted') THEN 1 END) * 100.0 / COUNT(*), 2) AS bad_loan_percentage
FROM bank_data
GROUP BY installment_level
ORDER BY installment_level;
-- Lower monthly installments correlate with higher repayment success, while higher installments—especially between $800 and $1000—show increased repayment difficulties. 
-- This suggests that lenders could potentially improve repayment rates by offering loan structures with smaller, more manageable installments.

-- 10.3 What is the distribution of interest rates for good vs. bad loans?
SELECT MIN(int_rate), MAX(int_rate) from bank_data;
SELECT 
CASE WHEN int_rate < 0.10 THEN "<10%" 
	WHEN int_rate BETWEEN 0.10 AND 0.15 THEN "10% - 15%"
    WHEN int_rate BETWEEN 0.15 AND 0.20 THEN "15% - 20%"
    ELSE ">20%" 
    END AS int_rate_levels,
    ROUND(COUNT(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 END) * 100.0 / COUNT(*) , 2) AS good_loan_percentage,
    ROUND(COUNT(CASE WHEN loan_status IN ('Charged Off', 'Defaulted') THEN 1 END) * 100.0 / COUNT(*), 2) AS bad_loan_percentage
FROM 
bank_data
GROUP BY int_rate_levels;
-- Higher interest rates constitiute to inability to repay loans as the int_rate increases so does the failure to repay loans

-- 11. Verification Status Insights
-- 11.1 How does the verification status of applications impact loan repayment success?
SELECT verification_status, 
ROUND(COUNT(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 END) * 100.0 / COUNT(*) , 2) AS good_loan_percentage,
ROUND(COUNT(CASE WHEN loan_status IN ('Charged Off', 'Defaulted') THEN 1 END) * 100.0 / COUNT(*), 2) AS bad_loan_percentage
FROM bank_data
GROUP BY verification_status;
-- THis indicate that verification status alone is not a strong predictor of repayment success, 
-- as Not Verified loans have a slightly better repayment success rate than Verified and Source Verified loans. 

-- 11.2 What is the average loan amount and interest rate for verified vs. non-verified applications?
SELECT verification_status, ROUND(AVG(loan_amount),2) as Average_loan_amount, ROUND(AVG(int_rate),2)*100 as Average_int_rate
FROM bank_data
GROUP BY verification_status
ORDER BY Average_loan_amount;

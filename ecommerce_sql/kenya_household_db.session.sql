CREATE TABLE gender(
    gender_id SERIAL PRIMARY KEY,
    gender_name VARCHAR(10) NOT NULL
);

CREATE TABLE counties (
    county_id SERIAL PRIMARY KEY,
    county_name VARCHAR (50) NOT NULL,
    region VARCHAR (50) NOT NULL,
    residence_type VARCHAR(50) NOT NULL
);

CREATE TABLE employment (
    employment_id SERIAL PRIMARY KEY,
    employment_type VARCHAR(20) NOT NULL,
    sector VARCHAR(20) NOT NULL,
    employment_category VARCHAR(20) NOT NULL
);

CREATE TABLE education (
    education_id SERIAL PRIMARY KEY,
    education_level VARCHAR(20) NOT NULL,
    years_range VARCHAR(10) NOT NULL,
    education_category VARCHAR(20) NOT NULL
);

CREATE TABLE wealth (
    wealth_id SERIAL PRIMARY KEY,
    wealth_index VARCHAR(10) NOT NULL,
    wealth_description VARCHAR (50) NOT NULL,
    income_range VARCHAR (30) NOT NULL
);

CREATE TABLE households (
    household_id SERIAL PRIMARY KEY,
    county_id INT REFERENCES counties(county_id),
    employment_id INT REFERENCES employment(employment_id),
    education_id INT REFERENCES education(education_id),
    wealth_id INT REFERENCES wealth(wealth_id),
    gender_id INT REFERENCES gender(gender_id),
    age_head INT NOT NULL,
    household_size INT NOT NULL,
    years_education INT NOT NULL,
    distance_to_market NUMERIC(5,1) NOT NULL
);

CREATE TABLE financials (
    financial_id SERIAL PRIMARY KEY,
    household_id INT REFERENCES households(household_id),
    monthly_income NUMERIC(12,2) NOT NULL,
    monthly_expenditure NUMERIC(12,2) NOT NULL,
    monthly_savings NUMERIC(12,2) NOT NULL
);

SELECT * FROM gender;

ALTER TABLE households
ALTER COLUMN household_id
DROP DEFAULT;

ALTER TABLE financials
ALTER COLUMN financial_id
DROP DEFAULT;

-- QUERY 1: Basic overview of the dataset

SELECT
    COUNT(*)    AS total_households,
    ROUND(AVG(monthly_income), 2) AS avg_income,
    ROUND(AVG(monthly_expenditure), 2) AS avg_expenditure,
    ROUND(AVG(monthly_savings), 2) AS avg_savings,
    ROUND(MIN(monthly_income), 2) AS min_income,
    ROUND(MAX(monthly_income), 2) AS max_income,
    ROUND(MIN(monthly_expenditure), 2) AS min_expenditure,
    ROUND(MAX(monthly_expenditure), 2) AS max_expenditure
FROM financials;
/* FINDINGS

-We have 300 households in our dataset
-Average monthly income is KES 23,762.65
-Average monthly expenditure is KES 21,282.07 — households spend most of what they earn
-Average monthly savings is KES 4,120.35
-Income ranges widely from KES 2,000 (very poor) to KES 118,930 (high income)
-Expenditure ranges from KES 150 to KES 105,557.65 — very wide spread

Notable observation: Average savings (4,120.35) + average expenditure (21,282.07) = 25,402.42 
which is slightly higher than average income (23,762.65) — this suggests some households 
are spending more than they earn (going into debt or using past savings).
*/


-- QUERY 2: Income and expenditure by county
-- using JOIN to combine households and financials with counties table

SELECT 
    counties.county_name,
    counties.residence_type,
    COUNT(households.household_id) AS total_households,
    ROUND(AVG(financials.monthly_income), 2) AS avg_income,
    ROUND(AVG(financials.monthly_expenditure), 2) AS avg_expenditure,
    ROUND(AVG(financials.monthly_savings), 2) AS avg_savings
FROM households
INNER JOIN counties ON households.county_id = counties.county_id
INNER JOIN financials ON households.household_id = financials.household_id
GROUP BY counties.county_name, counties.residence_type
ORDER BY avg_income DESC;
/* FINDINGS 
-- Nairobi has the highest average income (KES 33,658) and expenditure (KES 29,248) 
   expected as it is the capital city
-- Kisumu has the lowest average income (KES 18,199) and expenditure (KES 16,803)  
   consistent with it being a rural county
-- Urban counties (Nairobi, Mombasa, Eldoret) generally earn and spend more than Rural counties (Nakuru, Kisumu)
-- Nakuru has the most households (72) despite being rural
-- Savings are highest in Nairobi (KES 6,055) and lowest in Kisumu (KES 3,021)
*/

--  QUERY 3: Income and Expenditure by Gender

SELECT
    gender.gender_name,
    COUNT(households.household_id) AS total_households,
    ROUND(AVG(financials.monthly_income), 2) AS avg_income,
    ROUND(AVG(financials.monthly_expenditure), 2) AS avg_expenditure,
    ROUND(AVG(financials.monthly_savings), 2) AS avg_savings,
    ROUND(MIN(financials.monthly_income), 2) AS min_income,
    ROUND(MAX(financials.monthly_income), 2) AS max_income
FROM households
INNER JOIN gender ON households.gender_id = gender.gender_id
INNER JOIN financials ON households.household_id = financials.household_id
GROUP BY gender.gender_name
ORDER BY avg_income DESC;
/*Interpretation:

-Female headed households (162) outnumber Male headed households (138)
-Female headed households earn slightly more on average (KES 24,669 vs KES 22,699)
-Female headed households also spend more (KES 22,063 vs KES 20,257)
-Savings are similar — Female KES 4,195 vs Male KES 4,033
-Both groups have the same minimum income (KES 2,000) showing poverty affects both genders equally
-Maximum income is higher for Female households (KES 118,930 vs KES 99,805)

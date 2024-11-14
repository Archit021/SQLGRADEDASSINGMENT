use fda;
select count(*) from `Product_tecode`;-- 15257
select count(*) from `Product`; -- 34465
select count(*) from `AppDoc`; -- 45504
select count(*) from `RegActionDate`; -- 129073
select count(*) from `Application`; -- 20558
select count(*) from `ChemTypeLookup`; -- 10
select count(*) from `AppDocType_Lookup`; -- 19
select count(*) from `DocType_lookup`; -- 57
select count(*) from `ReviewClass_Lookup`; -- 3

/*Task 1 Identifying Approval Trends

1. Determine the number of drugs approved each year and provide insights
 into the yearly trends.
*/
use fda;
SELECT EXTRACT(YEAR FROM ActionDate) AS approval_year,
COUNT(ApplNo) AS approved_drugs
FROM Regactiondate
WHERE ActionType = 'AP'  -- approved
GROUP BY EXTRACT(YEAR FROM ActionDate)
ORDER BY approval_year;
/* Starting from 1939, the number of approved drugs were incresing till 2002 being the year with highest number of drugs approved
Then there is a decline in number and an increase again.*/


/* 2. Identify the top three years that got the highest and lowest approvals, in descending and ascending order, respectively.*/
SELECT EXTRACT(YEAR FROM ActionDate) AS approval_year,
COUNT(ApplNo) AS num_approved_drugs
FROM Regactiondate
WHERE ActionType = 'AP'  -- approved
GROUP BY EXTRACT(YEAR FROM ActionDate)
ORDER BY num_approved_drugs desc
limit 3; 

/*years with highest approvals*
# approval_year	num_approved_drugs
2002	5661
2000	5204
2001	5098*/
SELECT EXTRACT(YEAR FROM ActionDate) AS approval_year,
COUNT(ApplNo) AS num_approved_drugs
FROM Regactiondate
WHERE ActionType = 'AP' and actiondate is not null -- approved
GROUP BY EXTRACT(YEAR FROM ActionDate)
ORDER BY num_approved_drugs
limit 3;

/*# approval_year	num_approved_drugs
1945	5
1943	6
1944	9*/

/*3. Explore approval trends over the years based on sponsors. */
select * from application;
select Application.SponsorApplicant,extract(year from regactiondate.actiondate) as approval_date , count(regactiondate.applNo) as num_of_application_approved
FROM regactiondate
JOIN application 
ON regactiondate.ApplNo = Application.ApplNo 
WHERE regactiondate.ActionType = 'AP'  
GROUP BY Application.SponsorApplicant,approval_date
ORDER BY  EXTRACT(YEAR FROM regactiondate.ActionDate)asc,(num_of_application_approved) desc/*Application.SponsorApplicant*/;

/*4.Rank sponsors based on the total number of approvals they received each year between 1939 and 1960.*/
WITH ApprovalsPerYear AS (
    SELECT 
        A.SponsorApplicant,
        EXTRACT(YEAR FROM R.ActionDate) AS approval_year,
        COUNT(*) AS number_of_approvals
    FROM 
        regactionDate AS R
    JOIN 
        Application AS A ON R.ApplNo = A.ApplNo  
    WHERE 
        R.ActionType = 'AP'  
        AND EXTRACT(YEAR FROM R.ActionDate) BETWEEN 1939 AND 1960  
    GROUP BY 
        A.SponsorApplicant,
        EXTRACT(YEAR FROM R.ActionDate)
)
SELECT 
    approval_year,
    SponsorApplicant,
    number_of_approvals,
    dense_rank() OVER (PARTITION BY approval_year ORDER BY number_of_approvals DESC) AS rank1
FROM 
    ApprovalsPerYear
ORDER BY 
    approval_year, rank1;


/*Task 2 Segmentation Analysis Based on Drug MarketingStatus

1. Group products based on MarketingStatus. Provide meaningful insights into the segmentation patterns.*/
SELECT ProductMktStatus, COUNT(*) AS number_of_products
FROM Product
GROUP BY ProductMktStatus
ORDER BY number_of_products DESC;

/*# ProductMktStatus	number_of_products
1	18344
3	14209
4	1231
2	681  */

/*2. Calculate the total number of applications for each MarketingStatus year-wise after the year 2010.*/

SELECT EXTRACT(YEAR FROM R.ActionDate) AS approval_year,P.ProductMktStatus,
COUNT(DISTINCT A.ApplNo) AS total_applications
FROM Product P
JOIN Application A ON P.ApplNo = A.ApplNo  
JOIN RegActionDate R ON A.ApplNo = R.ApplNo 
WHERE EXTRACT(YEAR FROM R.ActionDate) > 2010  
GROUP BY EXTRACT(YEAR FROM R.ActionDate), P.ProductMktStatus
ORDER BY approval_year, P.ProductMktStatus;

/*3. Identify the top MarketingStatus with the maximum number of applications and analyze its trend over time.*/

SELECT P.productmktstatus, COUNT(DISTINCT A.ApplNo) AS total_appli
FROM Product P
JOIN Application A ON P.ApplNo = A.ApplNo  -- Assuming Product references Application by ApplNo
GROUP BY P.productmktstatus
ORDER BY total_appli DESC
LIMIT 1;
or
SELECT P.productmktstatus, COUNT(DISTINCT p.ApplNo) AS total_appli
FROM Product P
GROUP BY P.productmktstatus
ORDER BY total_appli DESC
LIMIT 1;
/*# productmktstatus	total_appli
3	10039*/

/*Task 3 Analyzing Products

1. Categorize Products by dosage form and analyze their distribution.

2. Calculate the total number of approvals for each dosage form and identify the most successful forms.

3. Investigate yearly trends related to successful forms. */

select count(productno) as numberofproduct,form from product
group by form
order by numberofproduct desc;


SELECT P.Form AS dosage_form, COUNT(DISTINCT A.ApplNo) AS total_approvals
FROM Product P
JOIN Application A ON P.ApplNo = A.ApplNo
JOIN RegActionDate RAD ON A.ApplNo = RAD.ApplNo  
WHERE RAD.ActionType = 'AP'  
GROUP BY P.Form
ORDER BY total_approvals DESC;

SELECT EXTRACT(YEAR FROM R.ActionDate) AS approval_year,P.Form AS dosage_form, 
COUNT(DISTINCT A.ApplNo) AS total_approvals
FROM Product P
JOIN Application A ON P.ApplNo = A.ApplNo
JOIN RegActionDate R ON A.ApplNo = R.ApplNo  
WHERE R.ActionType = 'AP' 
GROUP BY EXTRACT(YEAR FROM R.ActionDate), P.Form
ORDER BY approval_year, total_approvals DESC;

/*Task 4 Exploring Therapeutic Classes and Approval Trends

1. Analyze drug approvals based on the therapeutic evaluation code (TE_Code).

2. Determine the therapeutic evaluation code (TE_Code) with the highest number of Approvals in each year.*/


SELECT P.TECode AS therapeutic_equivalence_code, COUNT(DISTINCT R.ApplNo) AS total_approvals
FROM Product P
JOIN regactionDate R ON P.ApplNo = R.ApplNo
WHERE R.ActionType = 'AP'  
GROUP BY P.TECode
ORDER BY total_approvals DESC;


WITH ApprovalsPerYear AS 
(SELECT EXTRACT(YEAR FROM R.ActionDate) AS approval_year,
P.TECode AS therapeutic_code, COUNT(DISTINCT R.ApplNo) AS total_approvals
FROM Product_tecode P
JOIN RegActionDate R ON P.ApplNo = R.ApplNo
WHERE R.ActionType = 'AP'  
GROUP BY EXTRACT(YEAR FROM R.ActionDate), P.TECode
)
SELECT 
    approval_year,
    therapeutic_code,
    total_approvals
FROM (
    SELECT approval_year,therapeutic_code,total_approvals,
	RANK() OVER (PARTITION BY approval_year ORDER BY total_approvals DESC) AS rank2
    FROM ApprovalsPerYear
) AS ranked_approvals
WHERE rank2 = 1
ORDER BY approval_year;
/*--------------------------------- END---------------------------------------------------------*/


--  1A) Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims. NPI=1881634483

SELECT npi, SUM(total_claim_count) AS sum_total_claim_count
FROM prescription
GROUP BY npi
ORDER BY sum_total_claim_count DESC
LIMIT 1;

SELECT *
FROM prescription;



--  1B) Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT prescriber.npi, 
		nppes_provider_first_name,
		nppes_provider_last_org_name,
	    specialty_description, 
	    SUM(total_claim_count) AS claim_count
FROM prescriber INNER JOIN prescription USING (npi)
GROUP BY prescriber.npi,
		 nppes_provider_first_name,
		 nppes_provider_last_org_name,
		 specialty_description
ORDER BY claim_count DESC
LIMIT 1;



--  2A) Which specialty had the most total number of claims (totaled over all drugs)? Family Practice // 9752347


SELECT prescriber.specialty_description, SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription ON prescriber.npi = prescription.npi
GROUP BY prescriber.specialty_description
ORDER BY total_claims DESC
NULLS LAST;

--  2B) Which specialty had the most total number of claims for opioids? Nurse Practitioner /// 900845

SELECT prescriber.specialty_description, SUM(prescription.total_claim_count) as total_claims
FROM prescription
INNER JOIN drug ON prescription.drug_name = drug.drug_name
INNER JOIN prescriber ON prescription.npi = prescriber.npi
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC;


--  3A) Which drug (generic_name) had the highest total drug cost? generic_name INSULIN GLARGINE, HUM.REC.ANLOG // total_cost = 104264066.35

SELECT drug.generic_name, SUM(total_drug_cost) AS total_cost
FROM prescription
INNER JOIN drug ON prescription.drug_name = drug.drug_name
GROUP BY drug.generic_name
ORDER BY total_cost DESC;



--  3B) Which drug (generic_name) has the highest total cost per day? C1 esterase inhibitor // 3495.22


SELECT drug.generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply),2) AS cost_per_day
FROM prescription
LEFT JOIN drug ON prescription.drug_name = drug.drug_name
GROUP BY drug.generic_name
ORDER BY cost_per_day DESC;



-- 4A) -- GROUP BY  = 3260 rows , No GROUP BY = 3425 rows // ask chris


SELECT drug_name, 
CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	 ELSE 'neither' 
	 END AS drug_type
FROM drug;

-- 4B) -- Determine which drug_type more money was spent on. Opioid (105,108,626.37) / Antibiotic (38,435,121.26)

SELECT *
-- USED SUBQUERY to remove 'neither' from table, wanted to clean up the look. (need to practice these more)
FROM (SELECT SUM(total_drug_cost)::money AS total,
			  CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	 	           WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'			       
				   WHEN opioid_drug_flag <>'Y' AND antibiotic_drug_flag<>'Y' THEN 'neither' END AS drug_type
FROM drug 
INNER JOIN prescription ON drug.drug_name = prescription.drug_name
GROUP BY drug_type
ORDER BY total DESC) AS total_drug_type
WHERE drug_type = 'opioid' OR drug_type = 'antibiotic'
ORDER BY total DESC;


--  5A) How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee. 
	   -- 10

SELECT COUNT(DISTINCT CBSA) AS cbsa_count
FROM cbsa
WHERE cbsaname LIKE '%TN%';



--  5B) part 1 - Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population. 
--  Name- Nashville-Davidson-Murfreesboro--Franklin,TN // total_pop: 1,830,410


SELECT c.cbsaname, SUM(p.population) AS total_pop
FROM cbsa AS c
JOIN population AS p ON c.fipscounty = p.fipscounty
WHERE c.cbsaname LIKE '%TN%'
GROUP BY c.cbsaname
ORDER BY total_pop DESC
LIMIT 1;


--  5B) part 2  Smallest = Morristown, TN - total_pop: 116352
SELECT c.cbsaname, SUM(p.population) AS total_pop
FROM cbsa AS c
JOIN population AS p ON c.fipscounty = p.fipscounty
WHERE c.cbsaname LIKE '%TN%'
GROUP BY c.cbsaname
ORDER BY total_pop ASC
LIMIT 1;

--  5C) What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
   -- Sevier (gatlinburg in the house!!! - as well as pigeon forge) population: 95523 , smallest is Pickett Co. (nobody likes Byrdstown) pop: 5071
   -- (Fun fact - here in TN, if you're dating someone new and you take a trip to Gatlinburg in Sevier county, you're referred to as "gatlinburg official" and ya'll are steady ha!""
   
SELECT county, population
FROM fips_county as fc
LEFT JOIN population AS p ON fc.fipscounty = p.fipscounty
LEFT JOIN cbsa as c ON fc.fipscounty = c.fipscounty
WHERE state = 'TN' AND cbsa IS NULL
ORDER BY population DESC
NULLS LAST;


--  6a) Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
 
SELECT drug_name,total_claim_count
FROM prescription 
JOIN drug 
USING (drug_name)
WHERE total_claim_count>=3000
ORDER BY total_claim_count DESC;
	
		
--  6B)	b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name,total_claim_count,
CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
     ELSE 'Not_opioid' END AS category
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count>=3000
ORDER BY total_claim_count DESC;

--  6C)  Add another column to your answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT prescription.drug_name,prescription.total_claim_count,prescriber.nppes_provider_first_name,prescriber.nppes_provider_last_org_name,
CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
     ELSE 'Not_opioid' END AS category
FROM prescription
INNER JOIN drug on prescription.drug_name = drug.drug_name
LEFT JOIN prescriber on prescription.npi = prescriber.npi
WHERE total_claim_count>=3000
ORDER BY total_claim_count DESC;


--  7A) First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.  
-- (cross joins with this question don't use ON/USING)

SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y'
GROUP BY npi, drug_name
ORDER BY npi DESC;


--  7B) Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count)

SELECT npi, drug.drug_name, SUM(prescription.total_claim_count) AS total_claims
FROM drug
CROSS JOIN prescriber
LEFT JOIN prescription USING (npi, drug_name)
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y'
GROUP BY npi, drug.drug_name
ORDER BY total_claims DESC
NULLS LAST;



--  7C) Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT npi, drug.drug_name,COALESCE(SUM(prescription.total_claim_count),'0') AS total_claims
FROM drug
CROSS JOIN prescriber
LEFT JOIN prescription USING (npi, drug_name)
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y'
GROUP BY npi, drug.drug_name
ORDER BY total_claims DESC
NULLS LAST;







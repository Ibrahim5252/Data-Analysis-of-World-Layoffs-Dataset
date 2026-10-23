use world_layoffs;
select * from layoffs;

-- ____STEPS OF DATA CLEANING_____
-- REMOVE DUPLICATES
-- STANDARDIZE DATA
-- NULL VALUE OR BLANK values
-- REMOVE ANY COLUMN


-- 1. REMOVING DUPLICATION
CREATE TABLE staging_layoff like layoffs ;
INSERT staging_layoff SELECT * FROM layoffs;
select * from staging_layoff;

with duplicate_cte AS
(
SELECT *,
ROW_NUMBER () OVER(PARTITION BY company, location, industry, total_laid_off, total_laid_off, `date`, stage, country, funds_raised_millions) 
as row_num 
FROM staging_layoff
)


SELECT * FROM duplicate_cte WHERE row_num > 1;

CREATE TABLE `staging_layoff2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



INSERT INTO staging_layoff2 SELECT *,
ROW_NUMBER () OVER(PARTITION BY company, location, industry, total_laid_off, total_laid_off, `date`, stage, country, funds_raised_millions) 
as row_num 
FROM staging_layoff;

select * from staging_layoff2;




-- 2. STANDARIZATION

SELECT company, trim(company) FROM staging_layoff2;

UPDATE staging_layoff2 SET company = trim(company);

SELECT DISTINCT industry from staging_layoff2 ORDER BY 1;

SELECT * FROM staging_layoff2 WHERE industry LIKE 'Crypto%';

UPDATE staging_layoff2 SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';




UPDATE staging_layoff2 SET country = 'United States' WHERE country LIKE 'United States.';

select distinct country from staging_layoff2 order by 1;


-- FORMATING DATE FROM TEXT TO DATE FORMAT.

select `date`,
str_to_date(`date`, '%m/%d/%Y') -- write the format in this to get yyyy-mm-dd
from staging_layoff2;

UPDATE staging_layoff2 SET `date` = str_to_date(`date`, '%m/%d/%Y');

alter table staging_layoff2
modify `date` date;

select *
from staging_layoff2;



-- CHANGING BLANKS FEILD TO NULL IN INDUSTRY.

update staging_layoff2
set industry = null
where industry = '';

select *
from staging_layoff2
where industry is NULL;

-- finding a null value in industry which is not null in same company
select *
from staging_layoff2 t1
join staging_layoff2 t2
	on t1.company = t2.company
where t1.industry is NULL and t2.industry is not NULL;

-- 	populating the null vlalue with actul value of industry of same company.
update staging_layoff2 t1
join staging_layoff2 t2
	on t1.company = t2.company
set t1.industry = t2.industry
where t1.industry is NULL and t2.industry is not NULL;

-- deleting row where total_laid_off and percentage_laid_off is null.

select *
from staging_layoff2 -- checking in total_laid_off if there is any blank value which need to convert into null
where total_laid_off = '';

select *
from staging_layoff2 -- checking in percentage_laid_off if there is any blank value which need to convert into null
where percentage_laid_off = '';


select *
from staging_layoff2
where total_laid_off is null and percentage_laid_off is null;

delete
from staging_layoff2
where total_laid_off is null and percentage_laid_off is null;

select *
from staging_layoff2;

alter table staging_layoff2
drop column row_num;


-- Analysis

with company_year (company, years, total_laid_off) as
(
select company, year(`date`), sum(total_laid_off)
from staging_layoff2
group by company, year(`date`)
),company_year_ranking as
(
select *,
dense_rank() over (partition by years order by total_laid_off desc) as ranking
from company_year
where years is not null
)

select * 
from company_year_ranking
where ranking <= 5;





















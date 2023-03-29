
-- Quick preview of the data we are working on
SELECT
	*
FROM
	covid_deaths
-- let's filter out the null or blank data in the continent column to exclude the unnecessary data (world data)
WHERE
	continent = '' OR continent IS NULL

-- Looking at total cases vs total deaths
-- shows the likelihood of dying if you contract covid in your country
SELECT
	location,
	date,
	total_cases,
	total_deaths,
	ROUND(((total_deaths / total_cases) * 100), 2) AS percentage_of_death
FROM
	covid_deaths
ORDER BY
	location,
	date


-- Looking at Total cases vs population
-- shows what percentage of population got Covid
SELECT
	location,
	date,
	total_cases,
	population,
	ROUND(((total_cases / population) * 100), 2) AS percentage_of_population_infected
FROM
	covid_deaths
--WHERE
--	location like '%phil%'
ORDER BY
	location,
	date


-- Looking at Countries with the highest percentage of population infected

SELECT
	location,
	population,
	MAX(total_cases) AS highest_infection_count,
	MAX(ROUND(((total_cases / population) * 100), 4)) AS percentage_of_population_infected
FROM
	covid_deaths
GROUP BY
	population, location
ORDER BY
	percentage_of_population_infected desc


-- Showing Countries with Highest Death Count per Country

SELECT
	location,
	MAX(total_deaths) AS total_death_count
FROM
	covid_deaths
-- this filters out the cases per continents and salary based cases
WHERE
	continent != ''
GROUP BY
	location
ORDER BY 
	total_death_count desc

-- LET'S BREAK THINGS DOWN BY CONTINENT
-- there is a problem with this not including some data
SELECT
	continent,
	MAX(total_deaths) AS total_death_count
FROM
	covid_deaths
WHERE
	location != ''
GROUP BY
	continent
ORDER BY 
	total_death_count desc
-----------------------OR---------------------------------------
SELECT
	location,
	continent,
	MAX(total_deaths) AS total_death_count
FROM
	covid_deaths
WHERE
	continent = '' or continent is null
GROUP BY
	location, continent
ORDER BY 
	total_death_count desc


-- Showing the continents with the highest death counts

SELECT
	location,
	continent,
	MAX(total_deaths) AS total_death_count
FROM
	covid_deaths
WHERE
	continent = '' or continent is null
GROUP BY
	location, continent
ORDER BY 
	total_death_count desc


-- Global numbers
-- We used the CASE to prevent error caused by dividing by zero
SELECT
    SUM(new_cases) as total_cases,
    SUM(new_deaths) as total_deaths,
    CASE
        WHEN SUM(new_cases)= 0 THEN 0
        ELSE (SUM(new_deaths) / SUM(new_cases)) * 100
    END AS death_percentage
FROM
	covid_deaths
WHERE
	continent != ''
ORDER BY
	1, 2
-----------OR-----------------
SELECT
    SUM(new_cases) as total_cases,
    SUM(new_deaths) as total_deaths,
    SUM(new_deaths) / SUM(new_cases)* 100 AS death_percentage
FROM
	covid_deaths
WHERE
	continent != ''
ORDER BY
	1, 2

-- Vaccination trends
SELECT
	deaths.location,
	deaths.date,
	deaths.population,
	vacs.new_vaccinations,
	SUM(CAST(vacs.new_vaccinations as float)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_vaccinated

FROM 
	covid_deaths AS deaths
JOIN 
	covid_vaccinations AS vacs
	ON deaths.location = vacs.location
	AND deaths.date = vacs.date
	AND deaths.iso_code = vacs.iso_code
WHERE
	deaths.continent != ''

---------------------------------------------CTE_VERSION-----------------------------------------------
-- Create a CTE based on the query above

WITH vac_trends (location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT
	deaths.location,
	deaths.date,
	deaths.population,
	vacs.new_vaccinations,
	SUM(CAST(vacs.new_vaccinations as float)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_vaccinated

FROM 
	covid_deaths AS deaths
JOIN 
	covid_vaccinations AS vacs
	ON deaths.location = vacs.location
	AND deaths.date = vacs.date
	AND deaths.iso_code = vacs.iso_code
WHERE
	deaths.continent != ''
)
SELECT
	*,
	ROUND((rolling_people_vaccinated/population) * 100, 2) AS percent_vaccinated
FROM
	vac_trends


------------------------------TEMP_TABLE_VERSION-----------------------------------------------
DROP TABLE #vac_trends
-- take note, Ensure data types match between temp table columns and data being inserted.
CREATE TABLE #vac_trends
(
location nvarchar(255),
date datetime,
population float,
new_vaccinations float,
rolling_people_vaccinated float
)

INSERT INTO #vac_trends
SELECT
	deaths.location,
	deaths.date,
	deaths.population,
	CAST(vacs.new_vaccinations as float),
	SUM(CAST(vacs.new_vaccinations as float)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_vaccinated
FROM 
	covid_deaths AS deaths
JOIN 
	covid_vaccinations AS vacs
	ON deaths.location = vacs.location
	AND deaths.date = vacs.date
	AND deaths.iso_code = vacs.iso_code
WHERE
	deaths.continent != ''
-------------------------------end_of_insert----------------------------------------
-- Let's query on the created Temp Table
-- rolling percent vaccinated for each country
SELECT
	*,
	ROUND((rolling_people_vaccinated/population) * 100, 2) AS percent_vaccinated
FROM
	#vac_trends

-- Looking at total vaccine administered of every country
-- Querying on the created Temp Table (#percent_vaccinated)
SELECT 
	location,
	MAX(rolling_people_vaccinated) AS total_vaccinations
FROM 
	#percent_vaccinated
GROUP BY
	location
ORDER BY
	total_vaccinations desc

-- Creating a View to store data for later Visualization

CREATE VIEW vaccination_trends
AS
SELECT
	deaths.location,
	deaths.date,
	deaths.population,
	CAST(vacs.new_vaccinations as float) AS new_vaccinations,
	SUM(CAST(vacs.new_vaccinations as float)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_vaccinated
FROM 
	covid_deaths AS deaths
JOIN 
	covid_vaccinations AS vacs
	ON deaths.location = vacs.location
	AND deaths.date = vacs.date
	AND deaths.iso_code = vacs.iso_code
WHERE
	deaths.continent != ''


--Data Exploration COVIDVACCINATIONS
SELECT 
	*
FROM covidvaccinations;

--Data Exploration COVIDDEATHS
SELECT 
	*
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

--Pilih data yang akan digunakan 
SELECT 
	location,
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM CovidDeaths
ORDER BY 1,2;

--Perbandingan total kasus (Total Cases) dan total kematian (Total Deaths)
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths,
	(total_deaths/total_cases)*100 AS DeathRate
FROM coviddeaths
WHERE location = 'Indonesia'
ORDER BY 1,2;

--Perbandingan jumlah kasus (Total Case) dengan jumlah populasi (Population)/Rasio Infeksi
--Menunjukkan seberapa banyak (%) populasi yang terinfeksi Covid-19
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths,
	population, 
	(total_cases/population)*100 AS [CasesRate/InfectionRate]
FROM CovidDeaths
WHERE location = 'Indonesia'
ORDER BY 1,2;

--Negara dengan Rasio Infeksi tertinggi berbanding dengan populasinya
SELECT 
	location, 
	population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY 4 DESC; 

--Negara dengan Jumlah Kematian tertinggi berbanding dengan populasinya
SELECT 
	location, 
	MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC; 

--Pengelompokan berbasis data continent
SELECT 
	continent, 
	MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--Benua dengan jumlah kematian tertinggi berbanding dengan populasi
SELECT DISTINCT
	continent, 
	population,
	SUM(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent, population
ORDER BY TotalDeathCount DESC;

--Global Numbers
SELECT 
	date, 
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS INT)) AS total_deaths, 
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
	--total_deaths, 
	--(total_deaths/total_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

--Total resulting in one result (global)
SELECT 
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deaths, 
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS deathpercentage
FROM coviddeaths
WHERE continent IS NOT NULL; 

--COVID VACCINATIONS
SELECT 
	*
FROM coviddeaths AS CDEA 
INNER JOIN CovidVaccinations AS CVAC 
ON CDEA.location = CVAC.location AND
   CDEA.date = CVAC.date;

--Jumlah populasi dengan yang sudah divaksinasi

WITH PopulationsVSVaccinated 
	(continent, location, date, population, new_vaccinations, rollingpeople_vaccinated) AS 
	(
	SELECT 
		CDEA.continent, 
		CDEA.location, 
		CDEA.date, 
		CDEA.population, 
		CVAC.new_vaccinations,
		SUM(CAST(CVAC.new_vaccinations AS INT)) OVER(PARTITION BY CDEA.location
			ORDER BY CDEA.location, CDEA.date) AS RollingPeople_Vaccinated
		--(RollingPeople_Vaccinated/population)*100
	FROM coviddeaths AS CDEA
	INNER JOIN covidvaccinations AS CVAC
	ON CDEA.location = CVAC.location AND
	   CDEA.date = CVAC.date
	WHERE CDEA.continent IS NOT NULL
	--ORDER BY 2,3
)
SELECT *, (rollingpeople_vaccinated/population)*100 
FROM PopulationsVSVaccinated

--USE CTE 
--WITH PopulationVSVaccinated

--TEMPORARY TABLE 
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255), 
date datetime, 
population numeric, 
new_vaccinations numeric, 
RollingPeople_Vaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
	SELECT 
			CDEA.continent, 
			CDEA.location, 
			CDEA.date, 
			CDEA.population, 
			CVAC.new_vaccinations,
			SUM(CAST(CVAC.new_vaccinations AS INT)) OVER(PARTITION BY CDEA.location
				ORDER BY CDEA.location, CDEA.date) AS RollingPeople_Vaccinated
			--(RollingPeople_Vaccinated/population)*100
		FROM coviddeaths AS CDEA
		INNER JOIN covidvaccinations AS CVAC
		ON CDEA.location = CVAC.location AND
		   CDEA.date = CVAC.date
		--WHERE CDEA.continent IS NOT NULL
		--ORDER BY 2,3
SELECT *, (RollingPeople_Vaccinated/population)*100
FROM #PercentPopulationVaccinated

--CREATE VIEW 
CREATE VIEW PercentPopulationVaccinated AS 
SELECT  
	CDEA.continent, 
	CDEA.location, 
	CDEA.date, 
	CDEA.population, 
	CVAC.new_vaccinations,
	SUM(CAST(CVAC.new_vaccinations AS INT)) OVER(PARTITION BY CDEA.location
		ORDER BY CDEA.location, CDEA.date) AS RollingPeople_Vaccinated
	--(RollingPeople_Vaccinated/population)*100
FROM coviddeaths AS CDEA
INNER JOIN covidvaccinations AS CVAC
ON CDEA.location = CVAC.location AND
	CDEA.date = CVAC.date
WHERE CDEA.continent IS NOT NULL
--ORDER BY 2,3

--NEW VIEW USED AS SOURCE FOR LATER VIZ
SELECT 
	*
FROM percentpopulationvaccinated;
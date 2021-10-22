SELECT *
FROM PortfolioProject.dbo.CovidDeath
WHERE continent is not NULL
ORDER BY 3,4

SELECT *
FROM PortfolioProject.dbo.CovidVaccination
ORDER BY 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeath
ORDER BY 1,2

--Total cases vs total deaths
-- This shows the likelihood of dying if you are infected in the US
SELECT Location, date, total_cases, new_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2)  as Death_percentage
FROM PortfolioProject.dbo.CovidDeath
WHERE location like '%state%'
ORDER BY 1,2

-- Total cases vs Population
-- what percentage of population got covid
SELECT Location, date, population, total_cases, ROUND((total_cases/population)*100,2)  as Death_percentage
FROM PortfolioProject.dbo.CovidDeath
---WHERE location like '%state%'
WHERE continent is not NULL
ORDER BY 1,2

-- Country with highest infection rate compared to population
SELECT Location, population, max(total_cases) as Highest_Infection_Count, ROUND(MAX((total_cases/population)*100),2)  as Percent_Population_Infected
FROM PortfolioProject.dbo.CovidDeath
WHERE continent is not NULL
GROUP BY Location, population
ORDER BY Percent_Population_Infected DESC

-- Country with the highest death count per population
SELECT Location, MAX(CAST(total_deaths as int)) as Total_Death_Count
FROM PortfolioProject.dbo.CovidDeath
WHERE continent is not NULL
GROUP BY Location, population
ORDER BY Total_Death_Count DESC

-- Some grouping continent that should not be there -- some country record as named by continent and the continent attribute of those is null
-- Death count by continent
SELECT continent, MAX(CAST(total_deaths as int)) as Total_Death_Count
FROM PortfolioProject.dbo.CovidDeath
WHERE continent is not NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC

SELECT location, MAX(CAST(total_deaths as int)) as Total_Death_Count
FROM PortfolioProject.dbo.CovidDeath
WHERE continent is NULL
GROUP BY location
ORDER BY Total_Death_Count DESC

-- Continent with the highest death count per population
SELECT continent, MAX(CAST(total_deaths as int)) as Total_Death_Count
FROM PortfolioProject.dbo.CovidDeath
WHERE continent is not NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC


-- Global numbers
SELECT date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject.dbo.CovidDeath
---WHERE location like '%state%'
WHERE continent is not NULL
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject.dbo.CovidDeath
WHERE continent is not NULL
ORDER BY 1,2



--Total population vs vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
,SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinated
FROM PortfolioProject.dbo.CovidDeath dea
JOIN PortfolioProject.dbo.CovidVaccination vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3

-- Common Table Expression (CTE)
With PopsVac (continent, Location, Date, Population, New_Vaccinations, RollingVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
,SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinated
FROM PortfolioProject.dbo.CovidDeath dea
JOIN PortfolioProject.dbo.CovidVaccination vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not NULL
)
SELECT *, (RollingVaccinated/Population)*100
FROM PopsVac

-- TEMP TABLE
DROP table if exists #PercentPopulationVaccinated
CREATE table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeath dea
JOIN PortfolioProject.dbo.CovidVaccination vac
   ON dea.location = vac.location
   AND dea.date = vac.date
--WHERE dea.continent is not NULL

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Create View to store data for later visualization
CREATE VIEW PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeath dea
JOIN PortfolioProject.dbo.CovidVaccination vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not NULL

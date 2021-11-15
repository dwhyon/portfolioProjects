use COVID19
--select *
--from [owid-covid-data]
--order by 3, 4


--Total Cases vs Total Deaths

Select location, date, total_cases, total_deaths, population, (total_deaths/ total_cases) * 100 as DeathRate
from [owid-covid-data]
Where location like '%United States%'
order by 1, 2


-- Total Cases vs Population

Select location, date, total_cases, population, (total_cases / population) * 100 as InfectionRate, (total_deaths / population) * 100 as DeathPercentage
from [owid-covid-data]
where location like '%states%'
order by 1, 2

--Countries with highest Infection rates 

Select location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases / population)*100 as percentPopulationInfected
from [owid-covid-data]
group by location, population
order by 4 desc

--Countries with highest Death rates

Select location, MAX(total_deaths) as TotalDeathCount, MAX(total_deaths / population)*100 as percentDead
from [owid-covid-data]
where continent is not null
group by location
order by percentDead 


Select location, continent, total_deaths as TotalDeathCount, total_deaths / population*100 as percentDead
from [owid-covid-data]
where location like '%canada%'


--Global numbers

Select  Sum(new_cases) as totalCases, Sum(new_deaths) as totalDeaths, (SUM(new_deaths) / SUM(new_cases)) * 100 as DeathRate
from [owid-covid-data]
where continent is not null
order by 1,2 

--Total Population vs. Vaccinations

Select continent, location, date, population, CONVERT(float, new_vaccinations), SUM(CONVERT(float, new_vaccinations)) OVER (Partition by location order by location, date) 
as RollingPeopleVaccinated
From [owid-covid-data]
where continent is not null
order by 2, 3

-- USE CTE
With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select continent, location, date, population, CONVERT(float, new_vaccinations), SUM(CONVERT(float, new_vaccinations)) OVER (Partition by location order by location, date) 
as RollingPeopleVaccinated
From [owid-covid-data]
where continent is not null
)
Select *, (RollingPeopleVaccinated / Population)* 100 as percentVaccinated
From PopvsVac
order by 2, 3

-- TEMP TABLE

DROP table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date date,
Population numeric,
newVaccinations numeric,
rollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select continent, location, date, population, CONVERT(float, new_vaccinations), SUM(CONVERT(float, new_vaccinations)) OVER (Partition by location order by location, date) 
as RollingPeopleVaccinated
From [owid-covid-data]
where continent is not null

Select *, (RollingPeopleVaccinated / Population)* 100 as percentVaccinated
From #PercentPopulationVaccinated
order by 2, 3

-- Create View of Vaccinated

Create View PercentPopulationVaccinated as
Select continent, location, date, population, CONVERT(float, new_vaccinations) as newVaccinations, SUM(CONVERT(float, new_vaccinations)) OVER (Partition by location order by location, date) 
as RollingPeopleVaccinated
From [owid-covid-data]
where continent is not null


Select *
from PercentPopulationVaccinated
use PortfolioProject
select * from [Covid Deaths Data]
where continent is not null
order by 3,4 

--select * from [Covid Vaccinations Data]
--order by 3,4 

Select location, date, total_cases, new_cases, total_deaths,population
from [Covid Deaths Data]
where continent is not null
order by 1,2 --the 1st and 2nd column after running above code chunk i.e. location, date

-- Now we will see how much is the percentage of total deaths out of the total cases.
-- The below code chunk will show the chances of you succumbing to covid in your respective countries.
Select location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 as Death_Percentage 
from [Covid Deaths Data]
where location = 'United States' and continent is not null
order by 1,2


-- Let's check the total cases vs population. It will give us the percentage of the total population in the respective country which has been infected with covid. 
Select location, date, population, total_cases, (total_cases / population)*100 as Cases_Percentage 
from [Covid Deaths Data]
--where location = 'United States'
order by 1,2

--Below code chunk will reflect the data of the countries with highest infection rate compared to population.
--Results shows us that Andorra has the highest percent of population infected out of total population.
Select location, population, max(total_cases) as highest_infected_count, max((total_cases / population)*100)as Percent_population_infected 
from [Covid Deaths Data]
--where location = 'United States'
group by population,location
order by 4 desc

-- Countries with highest death count per population.
select location, max(cast (total_deaths as int)) as total_death_count, max((total_deaths / population)*100) as Percent_Deaths
-- In the above code we changed the datatype of total_death. The column was in nvarchar so we changed it into integer.
from [Covid Deaths Data]
where continent is not null  --since there are rows in data in the location columns where location = name of the continent
group by location
order by total_death_count desc


-- LET'S DIG DEEP IN THE DATA AS PER CONTINENTS

-- HIGHEST DEATH COUNT PER POPULATION 
select continent, max(cast(total_deaths as int)) as total_death_count, max((total_deaths / population)*100) as Percent_Deaths
from [Covid Deaths Data]
where continent is not null
group by continent
order by total_death_count desc


-- GLOBAL NUMBERS
-- Following code chunk will give us the total number new of cases and new deaths across the world on each day.
select sum(new_cases) as total_cases_globally, sum(cast(new_deaths as int)) as total_deaths_globally, (sum(cast(new_deaths as int))/sum(new_cases)*100) as Percent_Death_Globally
from [Covid Deaths Data]
where continent is not null
--group by date
order by 1,2

--Now lets look at some data after joining 2 datasets
select *
from [Covid Deaths Data] as deaths
join [Covid Vaccinations Data] as vaccinations
	on deaths.location = vaccinations.location 
	and deaths.date = vaccinations.date

-- The following code chunk will give us the idea about total number of people got vaccinated from each country.

select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
sum(cast(vaccinations.new_vaccinations as int)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_people_vaccinated
from [Covid Deaths Data] as deaths
join [Covid Vaccinations Data] as vaccinations
	on deaths.location = vaccinations.location 
	and deaths.date = vaccinations.date
where deaths.continent is not null
order by 2,3

--In order to calculate the percentage of total number of people got vaccincated from the total population of each country we will make a CTE as we cannot use newly created column for calculation.

with total_pop_vs_total_vac (continent,location, date, population,new_vaccinations, rolling_people_vaccinated)
	as(
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
sum(cast(vaccinations.new_vaccinations as int)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_people_vaccinated
from [Covid Deaths Data] as deaths
join [Covid Vaccinations Data] as vaccinations
	on deaths.location = vaccinations.location 
	and deaths.date = vaccinations.date
where deaths.continent is not null
--order by 2,3
)
select * ,(rolling_people_vaccinated / population *100) as percentage_of_total_population_vaccinated
from total_pop_vs_total_vac

-- We can perform the above operation by creating temporary table as well. For reference I have created temporary table.

--TEMP TABLE
Drop Table if exists #Percentpopulationvaccinated
create table #Percentpopulationvaccinated
(
	continent nvarchar(250),
	location nvarchar(250),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	rolling_people_vaccinated numeric
)

Insert Into #Percentpopulationvaccinated
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
sum(cast(vaccinations.new_vaccinations as int)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_people_vaccinated
from [Covid Deaths Data] as deaths
join [Covid Vaccinations Data] as vaccinations
	on deaths.location = vaccinations.location 
	and deaths.date = vaccinations.date
where deaths.continent is not null
--order by 2,3

select * ,(rolling_people_vaccinated / population *100) as percentage_of_total_population_vaccinated
from #Percentpopulationvaccinated


---I have created some views to store the data for the visualization.
create view HighestDeathCountAcrossContinent as
select continent, max(cast(total_deaths as int)) as total_death_count, max((total_deaths / population)*100) as Percent_Deaths
from [Covid Deaths Data]
where continent is not null
group by continent
select * from HighestDeathCountAcrossContinent



create view Percentpopulationvaccinated as
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
sum(cast(vaccinations.new_vaccinations as int)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_people_vaccinated
from [Covid Deaths Data] as deaths
join [Covid Vaccinations Data] as vaccinations
	on deaths.location = vaccinations.location 
	and deaths.date = vaccinations.date
where deaths.continent is not null
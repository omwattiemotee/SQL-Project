/* 
 Dbeaver Sample Database Cleaning, Analyzing & Exploration:
 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

--Removes duplicates 

--List and rank all sales from highest to lowest for each customer Id. 

--Using ROW_NUMBER() --NOTE DUPLICATES 

SELECT CustomerId, Total,
ROW_NUMBER() OVER(PARTITION BY CustomerId ORDER BY Total DESC) AS Row_Num
FROM Invoice i

--Using RANK() --Note DUPLICATES

SELECT CustomerId, Total,
RANK() OVER(PARTITION BY CustomerId ORDER BY Total DESC) as Row_Num
FROM Invoice i 

--Change Null by replacing it with 0 in Employee table. 

Update Employee 
Set ReportsTo = 0 
Where ReportsTo is null

--Set null to N/A in Customer table

Update Customer 
Set Company = 'N/A'
Where Company is null 

--Select the full name of an employee and the full name of their supervisor

Select e.FirstName ||" "|| e.LastName as Employee, e.ReportsTo, 
Employee.FirstName ||" "||Employee.LastName as Supervisor   
From Employee Join Employee e 
On Employee.EmployeeId = e.ReportsTo 

--Pull all invoice fromcountries that are not the US & Canada

SELECT *
FROM Invoice i 
WHERE BillingCountry != 'USA' AND BillingCountry != 'Canda'

--Select name, AlbumID, Title fromm the Artist and Album Table. 

Select *
From Artist a Join Album a2 
On a.ArtistId = a2.ArtistId 
--OR 
Select *
From Album a Join Artist a2 
On a.ArtistId = a2.ArtistId 

--Show invoices from 2009 and 2011 from USA

Select * From Invoice i 
Where InvoiceDate Between '2009-01-01' And '2012-01-01'
And BillingCountry ='USA'

--What is the total amount spent by our customers?

Select sum(total)
From Invoice i 

--Select our top 5 customers by customer ID? 

Select customerID, sum(total)
From Invoice i 
Group by customerId
Order by sum(total) DESC 
Limit 5

--Show average sales by country

Select BillingCountry, Round(avg(total),2)
From Invoice i 
Group by BillingCountry 
Order by avg(total) DESC 

--Show average sales by country in countries that are not the US or Canada with the average spending over $6.00

Select BillingCountry, ROUND(Avg(total),2) as Average_sales
From Invoice i 
Where BillingCountry != 'USA' And BillingCountry != 'Canada'
Group by BillingCountry 
Having Average_sales > 6.00
       
--Add Row Numbers to every record in the previously created table

SELECT a.Name, a2.AlbumId, a2.Title,
ROW_NUMBER() OVER() as Row_Num
FROM Artist a 
JOIN Album a2 
ON a.ArtistId = a2.ArtistId 

--Add Row Numbers to every record in the previously created table Partitioned by Band name 

SELECT a.Name, a2.AlbumId, a2.Title,
ROW_NUMBER() OVER(PARTITION BY a.Name) as Row_Num
FROM Artist a 
JOIN Album a2 
ON a.ArtistId = a2.ArtistId 

--Assuming that AlbumID are given to albums in order of release 
--ORDER table by name and album id allowing the row_number to represent release order

SELECT a.Name, a2.AlbumId, a2.Title,
ROW_NUMBER() OVER(PARTITION BY a.Name ORDER BY AlbumId) as Release_order 
FROM Artist a 
JOIN Album a2 
ON a.ArtistId = a2.ArtistId

--Select all records from table where row number is greater than 5

SELECT * 
FROM 
(SELECT a.Name, a2.AlbumId, a2.Title,
ROW_NUMBER() OVER(PARTITION BY a.Name) as Row_Num
FROM Artist a 
JOIN Album a2 
ON a.ArtistId = a2.ArtistId)
WHERE Row_Num > 5

--Find the top 5 sales in for each customer ID 

SELECT * 
FROM 
(SELECT CustomerId, Total,
RANK() OVER(PARTITION BY CustomerId ORDER BY Total DESC) as row_num
FROM Invoice i)
WHERE row_num <6 

--What is the best selling musical genre? 

Select Genre.Name, ROUND(sum(Invoice.Total),2) as Total_spent
From Invoice Join InvoiceLine  
On Invoice.InvoiceId = InvoiceLine.InvoiceId 
Join Track  
On InvoiceLine.TrackId = Track.TrackId 
Join Genre  
On Track.GenreId = Genre.GenreId 
Group by Genre.Name 
Order by Total_spent DESC 

-- Combining the Playlist & Track table to produce a table showing the total minutes of music available in each playlist. 

Select Playlist.Name, Playlist.PlaylistId, sum(Track.Milliseconds)/600000 as Mins
From Playlist  Join PlaylistTrack  
On Playlist.PlaylistId = PlaylistTrack.PlaylistId 
Left Join Track On PlaylistTrack.TrackId = Track.TrackId 
Group by Playlist.Name

--Create a list for BillingCountry, BillingCity, total, and the Sum Total for a country  

Select BillingCountry, BillingCity, Total, SUM(Total) OVER (PARTITION BY BillingCountry) as Sum_Total_Country
From Invoice i 
Order By BillingCountry, Total DESC

--Create a table with the following columns InvoiceId, BillingCountry, Total, AVG_Total_Per_Country

With avg_per_country_table as 
(Select InvoiceId , BillingCountry, Total, AVG(Total) OVER(PARTITION BY BillingCountry) Avg_Total_Per_Country
from Invoice i ) 
Select InvoiceId , BillingCountry, Total, ROUND(Avg_Total_Per_Country,2) as Avg_Total_Per_Country
From avg_per_country_table
ORDER BY InvoiceId 

--Create a table with the following columns InvoiceId, BillingCountry, Total, Max_Total per country,  
--and the difference between total and max total. 

With max_total_table as 
(Select InvoiceId, BillingCountry, Total, MAX(Total) OVER(PARTITION BY BillingCountry) Max_Total_Per_Country 
From Invoice i ) 
Select InvoiceId, BillingCountry, Total, Max_Total_Per_Country,(Max_Total_Per_Country - Total) as Difference
From max_total_table
Order By InvoiceId 

--Create a table Showing the BillingCountry and the Average difference from the Max per Country

With max_total_table as 
(Select InvoiceId, BillingCountry, Total, MAX(Total) OVER(PARTITION BY BillingCountry) as Max_Total_Per_Country 
From Invoice i ),

diff_table as 
(Select InvoiceId, BillingCountry, Total, Max_Total_Per_Country,(Max_Total_Per_Country - Total) as Difference
From max_total_table) 

Select diff_table.BillingCountry, ROUND(AVG(diff_table.difference),2) 
From diff_table
Group By diff_table.BillingCountry 

--Max total per country was divided by avg total per country to see how sales were deviated from the avg total per country. 

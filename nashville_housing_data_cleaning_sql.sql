/*
Cleaning Data in SQL Queries
*/


Select
	*
From 
	portfolio_project..nashville_housing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format
SELECT
	CAST(Saledate AS date)
FROM
	portfolio_project..nashville_housing

-- Permanently convert Saledate datatype into date using CAST
UPDATE portfolio_project..nashville_housing
SET Saledate = CAST(Saledate AS date)

-------------OR_USE_ALTER_TABLE------------------
ALTER TABLE portfolio_project..nashville_housing
ALTER COLUMN Saledate date

-- Do some preview to check if the alterations are successful
SELECT
	Saledate
FROM
	portfolio_project..nashville_housing

 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

SELECT
	*
FROM
	portfolio_project..nashville_housing
--WHERE
	--PropertyAddress IS NULL OR PropertyAddress = ''
ORDER BY
	ParcelID
-- We examined the data and saw that there are null values in the PropertyAddress Column
-- We noticed that each ParcelID has only one unique PropertyAddress, we can use this information to fill in the null values.

/* 
Now that we know that each ParcelID has only one unique PropertyAddress.
We can use the ISNULL() Function in the SELECT statement to retrieve the PropertyAddress associated with a specific ParcelID.
We are also joining the same table twice based on two different conditions: a.ParcelID = b.ParcelID and a.[UniqueID] != b.[UniqueID].
This helps to ensure that only rows with the same ParcelID but different UniqueIDs are returned.
*/

SELECT
	a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM
	portfolio_project..nashville_housing AS a
JOIN
	portfolio_project..nashville_housing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] != b.[UniqueID]
WHERE
	a.PropertyAddress IS NULL

-- Let's insert the values that we have identified
UPDATE a
SET
	a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM
	portfolio_project..nashville_housing AS a
JOIN
	portfolio_project..nashville_housing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] != b.[UniqueID ]
WHERE
	a.PropertyAddress IS NULL


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

-- Lets start with the PropertyAddress
SELECT
	PropertyAddress,
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress))
FROM 
	portfolio_project..nashville_housing

-- Lets add their respective columns and insert the data.
-- And let's add the Trim function to remove the trailing whitespaces
ALTER TABLE 
	portfolio_project..nashville_housing
ADD 
	PropertySplitAddress NVARCHAR(255),
	PropertySplitCity NVARCHAR(255)

UPDATE 
	portfolio_project..nashville_housing
SET 
	PropertySplitAddress = TRIM(SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)),
	PropertySplitCity = TRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress)))


-- Using PARSENAME to split the owner address into individual columns

SELECT
	OwnerAddress,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

FROM 
	portfolio_project..nashville_housing

-- Lets add their respective columns and insert the data..
-- And let's add the Trim function to remove the trailing whitespaces
ALTER TABLE 
	portfolio_project..nashville_housing
ADD 
	OwnerSplitAddress NVARCHAR(255),
	OwnerSplitCity NVARCHAR(255),
	OwnerSplitState NVARCHAR(255)

UPDATE 
	portfolio_project..nashville_housing
SET 
	OwnerSplitAddress = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)),
	OwnerSplitCity = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)),
	OwnerSplitState = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1))

-- Quick glance to double check if it worked..
SELECT * FROM portfolio_project..nashville_housing
-- It Worked!

--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT 
	SoldAsVacant,
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes' 
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END AS SoldAsVacantClean
FROM 
	portfolio_project..nashville_housing

--Let's Update the data in the SoldAsVacant field
ALTER TABLE 
	portfolio_project..nashville_housing
ADD 
	SoldAsVacantClean NVARCHAR(55)

UPDATE 
	portfolio_project..nashville_housing
SET
	SoldAsVacantClean = CASE 
	               	WHEN SoldAsVacant = 'Y' THEN 'Yes' 
					WHEN SoldAsVacant = 'N' THEN 'No'
					ELSE SoldAsVacant
					END

-- Let's see if it worked...
SELECT * FROM portfolio_project..nashville_housing
-- It Worked!
-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

SELECT 
	*,
	ROW_NUMBER() OVER (PARTITION BY ParcelID,
									PropertyAddress,
									SalePrice,
									LegalReference
									ORDER BY
										UniqueID
										) AS RowNum 

FROM
	portfolio_project..nashville_housing

-- Let's use a CTE to determine if there are RowNum > 1
-- After that we will delete all the rows that have RowNum > 1.
WITH RowNumCTE AS
(
SELECT 
	*,
	ROW_NUMBER() OVER (PARTITION BY ParcelID,
									PropertyAddress,
									SalePrice,
									LegalReference
									ORDER BY
										UniqueID
										) AS RowNum 

FROM
	portfolio_project..nashville_housing
)
DELETE
-- SELECT
-- 	*
FROM 
	RowNumCTE
WHERE
	RowNum > 1
---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

ALTER TABLE
	portfolio_project..nashville_housing
DROP COLUMN
	OwnerAddress, 
	TaxDistrict,
	PropertyAddress,
	SoldAsVacant

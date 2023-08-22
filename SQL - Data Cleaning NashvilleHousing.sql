SELECT *
FROM Nashville2

-----------------------------------
----Standardize date format--------
-----------------------------------

ALTER TABLE Nashville2
ADD SaleDateConverted date

UPDATE Nashville2
SET SaleDateConverted = CONVERT(date, SaleDate)



----------------------------------
---Populate Property Address-----
----------------------------------

SELECT t1.UniqueID, t1.ParcelID, t1.PropertyAddress , t2.UniqueID, t2.ParcelID, t2.PropertyAddress
FROM Nashville2 AS t1
JOIN Nashville2 AS t2
ON t1.ParcelID = t2.ParcelID
AND t1.[UniqueID ] <> t2.[UniqueID ]
WHERE t1.PropertyAddress IS NULL

UPDATE t1
SET PropertyAddress = ISNULL(t1.PropertyAddress, t2.PropertyAddress)
FROM Nashville2 AS t1
JOIN Nashville2 AS t2
ON t1.ParcelID = t2.ParcelID
AND t1.[UniqueID ] <> t2.[UniqueID ]
WHERE t1.PropertyAddress IS NULL



---------------------------------------------------
---Breaking out Address into Individual columns----
---------------------------------------------------
-- breaking out address using substrings

SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1),
	SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1,LEN(PropertyAddress))
FROM Nashville2


ALTER TABLE Nashville2
ADD PropertySplitAddress nvarchar(255)

UPDATE Nashville2
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE Nashville2
ADD PropertySplitCity nvarchar(255)

UPDATE Nashville2
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1,LEN(PropertyAddress))


SELECT *
FROM Nashville2



-----------------------------------------------
-----------Spliting owner address--------------
-----------------------------------------------
-- spliting owner address using PARSENAME

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',','.'), 3) AS OwnersAddress,
	PARSENAME(REPLACE(OwnerAddress, ',','.'), 2) AS OwnersCity,
	PARSENAME(REPLACE(OwnerAddress, ',','.'), 1) AS OwnerState
FROM Nashville2

ALTER TABLE Nashville2
ADD OwnersAddress nvarchar(255)

UPDATE Nashville2
SET OwnersAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'), 3)

ALTER TABLE Nashville2
ADD OwnersCity nvarchar(255)

UPDATE Nashville2
SET OwnersCity = PARSENAME(REPLACE(OwnerAddress, ',','.'), 2)

ALTER TABLE Nashville2
ADD OwnersState nvarchar(255)

UPDATE Nashville2
SET OwnersState = PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)


SELECT *
FROM Nashville2



----------------------------------------------------
---Change Y and N to YES and NO in Sold as vacant---
----------------------------------------------------

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Nashville2
GROUP BY SoldAsVacant
ORDER BY 2


SELECT 
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
	        ELSE SoldAsVacant
	END 
FROM Nashville2


UPDATE Nashville2
SET SoldAsVacant =
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
	        ELSE SoldAsVacant
	END 



-----------------------------------------------
-----------Remove duplicates-------------------
-----------------------------------------------

WITH RowNumCTE AS
( 
        SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS row_num
        FROM Nashville2
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1

-- check if duplicates are deleted 
WITH RowNumCTE AS
( 
        SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS row_num
        FROM Nashville2
)
SELECT * 
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress



-----------------------------------------------
---------Delete unused columns-----------------
-----------------------------------------------

SELECT *
FROM Nashville2

ALTER TABLE Nashville2
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

----------------------------------------------------------------------------------------
-- 1 -- THE BASICS 
----------------------------------------------------------------------------------------
-- Explore the data 
SELECT 
	*
FROM nashvillehousing;

-- Standardize the SalesDate format
SELECT 
	saledate,
	CONVERT(DATE, SaleDate)
FROM nashvillehousing;

--- Update the updated SalesDate format to the table
UPDATE NashvilleHousing
SET SaleDate = CONVERT(DATE, SaleDate)

-- Or if above doesnt work, use this
ALTER TABLE nashvillehousing
ADD SaleDateConverted DATE;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate);

--- Check if anything change
SELECT 
	SaleDateConverted,
	CONVERT(DATE, SaleDate)
FROM NashvilleHousing;

----------------------------------------------------------------------------------------
-- 2 -- POPULATE PROPERTY ADDRESS DATA
----------------------------------------------------------------------------------------
-- Explore All Data
SELECT 
	* 
FROM NashvilleHousing

-- Explore the Property Address Column
SELECT
	PropertyAddress
FROM NashvilleHousing;

-- Check if there is any nulls
SELECT 
	*,
	PropertyAddress
FROM nashvillehousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

-- Kalau misal row x dan row y sama nilai Parcel ID nya, dan row y tidak ada PropertyAddress,
--- maka gunakan PropertyAddres row x karena dasarnya mereka merujuk ke PropertyAddress yang sama
--- USE SELF JOIN TO SOLVE THIS
SELECT 
	NH1.ParcelID, 
	NH1.PropertyAddress, 
	NH2.ParcelID, 
	NH2.PropertyAddress, 
	ISNULL(NH1.propertyaddress, NH2.PropertyAddress)
FROM nashvillehousing AS NH1
INNER JOIN NashvilleHousing AS NH2
	ON NH1.parcelid = NH2.parcelid
	AND NH1.[UniqueID ] <> NH2.[UniqueID ]
WHERE NH1.PropertyAddress IS NULL;

-- Update sehingga NH1 Property Address bisa diisi dengan isian ISNULL NH2 PropertyAddress
UPDATE NH1
SET PropertyAddress = ISNULL(NH1.propertyaddress, NH2.PropertyAddress)
FROM nashvillehousing AS NH1
INNER JOIN NashvilleHousing AS NH2
	ON NH1.parcelid = NH2.parcelid
	AND NH1.[UniqueID ] <> NH2.[UniqueID ]
WHERE NH1.PropertyAddress IS NULL;

-----------------------------------------------------------------------------------------
-- 3 -- PISAH SETIAP DETAIL PROPERTY ADDRESS JADI BEBERAPA KOLOM 
-----------------------------------------------------------------------------------------
-- Use Substring
SELECT 
	SUBSTRING(propertyaddress, 1, CHARINDEX(',', propertyaddress)-1) AS Address, 
	SUBSTRING(propertyaddress, CHARINDEX(',', propertyaddress)+1) AS Address2,
	LEN(propertyaddress) AS AddressLength,
	CHARINDEX(',', propertyaddress) AS UrutanKoma
FROM nashvillehousing;

-- PropertyAddress Data 
SELECT 
	propertyaddress
FROM NashvilleHousing

-- All Data 
SELECT 
	*
FROM nashvillehousing

-- Buat 2 kolom baru 
--- Kolom 1 
ALTER TABLE nashvillehousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(propertyaddress, 1, CHARINDEX(',', propertyaddress)-1);
--- Kolom 2 
ALTER TABLE nashvillehousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(propertyaddress, CHARINDEX(',', propertyaddress)+1, LEN(propertyaddress));

--------------------------------------------------------------------------------------------------------------------------------
-- 4 -- EDIT OWNERADDRESS 
--------------------------------------------------------------------------------------------------------------------------------
-- Explore All Data 
SELECT 
	*
FROM nashvillehousing; 

-- OwnerAddress Data 
SELECT 
	OwnerAddress
FROM nashvillehousing; 

-- PARSENAME OwnerAddress Data 
--- Note: PARSENAME works BACKWARDS (i.e. from RIGHT to LEFT)
--- PARSENAME jauh lebih mudah dari SUBSTRING
---- Jadi nomor 1 adalah yang PALING BELAKANG/PALING KANAN
----- Tinggal ganti 1 JADI 3 kalau mau keterangan di mulai dari PALING KIRI 
------ Contoh di bawah ini yang ORIGINAL 
SELECT 
	OwnerAddress,
	PARSENAME(REPLACE(owneraddress, ',', '.') ,1) AS State,
	PARSENAME(REPLACE(owneraddress, ',', '.') ,2) AS City,
	PARSENAME(REPLACE(owneraddress, ',', '.') ,3) AS Address
FROM nashvillehousing;

------ Contoh di bawah ini yang udah di EDIT jadi 3 (ADDRESS) JADI 1 (Bagian PALING AWAL/PALING KIRI)
SELECT 
	OwnerAddress,
	PARSENAME(REPLACE(owneraddress, ',', '.') ,3) AS Address,
	PARSENAME(REPLACE(owneraddress, ',', '.') ,2) AS City,
	PARSENAME(REPLACE(owneraddress, ',', '.') ,1) AS State
FROM nashvillehousing;

-- Update the table
-- Buat 3 kolom baru untuk ADDRESS, CITY, dan STATE 
--- Kolom 1 
ALTER TABLE nashvillehousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(owneraddress, ',', '.') ,3);
--- Kolom 2 
ALTER TABLE nashvillehousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(owneraddress, ',', '.') ,2);
--- Kolom 3
ALTER TABLE nashvillehousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(owneraddress, ',', '.') ,1);

-------------------------------------------------------------------------------------------------------------------------------------------
-- 5 -- Ganti Y dan N jadi Yes dan No di kolom 'SoldAsVacant'
-------------------------------------------------------------------------------------------------------------------------------------------
-- Explore All Data 
SELECT 
	*
FROM nashvillehousing;

-- SoldAsVacant Data 
SELECT 
	DISTINCT SoldAsVacant, 
	COUNT(SoldAsVacant) 
FROM nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- Ganti Y dan N jadi Yes dan No pakai CASE WHEN
SELECT 
	SoldAsVacant, 
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END
FROM nashvillehousing;

-- Setelah itu, update tabelnya supaya permanen change nya 
UPDATE NashvilleHousing
SET SoldAsVacant = 
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes' 
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END 
FROM NashvilleHousing;

---------------------------------------------------------------------------------------------------------------------------------------------
-- 6 -- Hapus Duplikat
---------------------------------------------------------------------------------------------------------------------------------------------
-- Explore All Data
SELECT 
	*
FROM nashvillehousing;

-- Hapus Duplikat dan apply CTE
WITH RowNumCTE AS (
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY parcelid, propertyaddress, saleprice, saledate, legalreference ORDER BY uniqueid ASC) AS row_num
	FROM nashvillehousing 
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress;

-----------------------------------------------------------------------------------------------------------------------------------------
-- 7 -- Hapus Kolom yang Tidak Terpakai 
-----------------------------------------------------------------------------------------------------------------------------------------
-- Explore all data 
SELECT 
	*
FROM nashvillehousing; 

-- Hapus kolom yang tidak sesuai 
ALTER TABLE nashvillehousing
DROP COLUMN owneraddress, taxdistrict, propertyaddress;

ALTER TABLE nashvillehousing
DROP COLUMN saledate;
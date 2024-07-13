
DROP TABLE IF EXISTS [dbo].[Dim_Country]
GO


BEGIN
as 
CREATE TABLE dbo.Dim_Country (
  DimCountryKey INT  NOT NULL ,
  CountryCode CHAR(2) NOT NULL,
  CountryName VARCHAR(80) NOT NULL,
  Nicename VARCHAR(80) NOT NULL,
  ISO3 CHAR(3) DEFAULT NULL,
  NumCode SMALLINT DEFAULT NULL,
  PhoneCode INT NOT NULL,
  ValidFrom DATETIME2(7) NOT NULL,
  IsCurrent BIT NOT NULL,
  ValidTo DATETIME2(7) NULL
 CONSTRAINT PK_DimCountry PRIMARY KEY CLUSTERED 
(
	DimCountryKey ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


GO


CREATE PROCEDURE [dbo].[uspSearchCandidateResumes]



-- Define the dates used in validity - assume whole 24 hour cycles
DECLARE @Yesterday DATETIME = GETDATE()
DECLARE @Today DATETIME = GETDATE()
-- Outer insert - the updated records are added to the SCD2 table
INSERT INTO dbo.Dim_Country ([DimCountryKey], [CountryCode], [CountryName], [Nicename], [ISO3], [NumCode], [PhoneCode], [ValidFrom], [IsCurrent])
SELECT [CountryKey], [CountryCode], [CountryName], [Nicename], [ISO3], [NumCode], [PhoneCode], @Today, 1
FROM
(
-- Merge statement
MERGE INTO dbo.Dim_Country AS DST
USING dbo.STG_Country AS SRC
ON (SRC.CountryKey = DST.DimCountryKey)
-- New records inserted
WHEN NOT MATCHED THEN 
INSERT ([DimCountryKey], [CountryCode], [CountryName], [Nicename], [ISO3], [NumCode], [PhoneCode], [ValidFrom], [IsCurrent])
VALUES (SRC.[CountryKey], SRC.[CountryCode], SRC.[CountryName], SRC.[Nicename], SRC.[ISO3], SRC.[NumCode], SRC.[PhoneCode],@Today, 1)
-- Existing records updated if data changes
WHEN MATCHED 
AND IsCurrent = 1
AND (
 ISNULL(DST.[DimCountryKey],0) <> ISNULL(SRC.[CountryKey],0) 
	 OR ISNULL(DST.[CountryCode],'') <> ISNULL(SRC.[CountryCode],'') 
	 OR ISNULL(DST.[CountryName],'') <> ISNULL(SRC.[CountryName],'')
	 OR ISNULL(DST.[Nicename],'') <> ISNULL(SRC.[Nicename],'')
	 OR ISNULL(DST.[ISO3],'') <> ISNULL(SRC.[ISO3],'')
	 OR ISNULL(DST.[NumCode],'') <> ISNULL(SRC.[NumCode],'')
	 OR ISNULL(DST.[PhoneCode],0) <> ISNULL(SRC.[PhoneCode],0)
 )
-- Update statement for a changed dimension record, to flag as no longer active
THEN UPDATE 
SET DST.IsCurrent = 0, 
DST.ValidTo = @Yesterday
OUTPUT SRC.[CountryKey], SRC.[CountryCode], SRC.[CountryName], SRC.[Nicename], SRC.[ISO3], SRC.[NumCode], SRC.[PhoneCode], $Action AS MergeAction
) AS MRG
WHERE MRG.MergeAction = 'UPDATE'
;

/* insert data, new data wiil be nsertd on the dimension*/

go



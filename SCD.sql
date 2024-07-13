---https://www.techbrothersit.com/2013/10/tsql-how-to-load-slowly-changing.html



-- Insert Records from Inner Merge as they they are update and 
-- need to insert as new record
INSERT INTO TestDB.Dim.Customer (CustomerCode, FirstName, LastName,
[Address], Phone, IsLatest,StartDT)
SELECT CustomerCode, FirstName, LastName,[Address], Phone,1,GETDATE() AS StartDT FROM(
-- Start of Merge Statement
MERGE INTO TestDB.Dim.Customer AS DST
USING Test1.dbo.Customer AS SRC
ON (SRC.CustomerCode = DST.CustomerCode) 
-- Business Key for Matching
-- WHEN Business Key does not match with Destination Records, Then insert
WHEN NOT MATCHED THEN
INSERT (CustomerCode, FirstName, LastName, [Address], Phone, IsLatest,StartDT)
VALUES (SRC.CustomerCode, SRC.FirstName, SRC.LastName,
        SRC.[Address],SRC.Phone, 1,GETDATE())
-- Business Key Matched but One or More than One filed has changed in Source)
WHEN MATCHED AND IsLatest = 1 AND ( 
-- Comparing if any of the field is different from 
--Source in Destination WHEN Business Key matches.
 ISNULL(DST.FirstName,'') != ISNULL(SRC.FirstName,'')
 OR ISNULL(DST.LastName,'') != ISNULL(SRC.LastName,'')
 OR ISNULL(DST.Address,'') !=ISNULL(SRC.Address,'')
 OR ISNULL(DST.Phone,'') != ISNULL(SRC.Phone,'')
 )
--UPDATE the record. Expire the record by setting IsLatest=0 and EndDate=getdate()
THEN UPDATE
SET DST.IsLatest = 0,
    DST.EndDT = GETDATE()
-- Use the Source records which needs to be inserted in Dim because of Update.
 OUTPUT SRC.CustomerCode, SRC.FirstName, SRC.LastName, SRC.[Address],SRC.phone,
        $Action AS MergeAction) AS MRG
         WHERE MRG.MergeAction = 'UPDATE';

/*
 * datatools_iiif_summary
 */
IF EXISTS (SELECT * FROM sysobjects WHERE name = 'datatools_iiif_summary')
BEGIN
  DROP FUNCTION dbo.datatools_iiif_summary
END
GO

CREATE FUNCTION dbo.datatools_iiif_summary (@lastSuccessfulRun datetime)
  RETURNS TABLE
AS RETURN
(
  SELECT 
    CASE 
      WHEN count(DISTINCT O.cmsid) > 0 
        THEN 'New Records' 
      ELSE 'No New Records' 
    END AS 'Updates', 
    count(DISTINCT O.cmsid) as RecordCount
  FROM datatools_iiif_json O
  WHERE o.enteredDate >= @lastSuccessfulRun

  UNION ALL

  SELECT 
    CASE 
      WHEN count(DISTINCT O.cmsid) > 0 
        THEN 'Edits to Records' 
      ELSE 
        'No Edits to Records' 
    END AS 'Updates', 
    count(DISTINCT O.cmsid) as RecordCount
  FROM datatools_iiif_json O
  WHERE o.modifiedDate >= @lastSuccessfulRun

  UNION ALL
  
  SELECT 
    CASE 
      WHEN count(DISTINCT d.cmsid) > 0 
        THEN 'Appended deletions' 
      ELSE 
        'No deletions appended' 
    END AS 'Updates', 
    count(DISTINCT d.cmsid) as RecordCount
  FROM datatools_deletions d
  WHERE collectionName = 'iiif' -- NOTE - this is unique to this collection, change if re-using the sql
    AND d.published = 0
  
)
GO

GRANT SELECT on dbo.datatools_iiif_summary to PUBLIC
GO


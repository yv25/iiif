/*
 * datatools_iiif_obj_json_new
 *
 */
IF EXISTS (SELECT * FROM sysobjects WHERE type = 'p' AND name = 'datatools_iiif_obj_json_new')
BEGIN
  DROP PROC datatools_iiif_obj_json_new
END
GO

CREATE PROC datatools_iiif_obj_json_new (@lastSuccessfulUpdate datetime)
AS
BEGIN
  SET NOCOUNT ON

    IF OBJECT_ID('tempdb..#tmp_json') IS NOT NULL
      DROP TABLE #tmp_json

    CREATE TABLE #tmp_json
    (
      cmstype       [nchar](3)        COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
      cmsid         [int]             NOT NULL,
      content       [nvarchar](max)   COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
      modifiedDate  [datetime]        NOT NULL,
      enteredDate   [datetime]        NOT NULL  -- TODO A.EnteredDate?
    )

    INSERT INTO #tmp_json
      (cmstype, cmsID, modifieddate, entereddate, content) 
    SELECT 
	    'obj', 
      A.OBJECTID, 
      getdate(),  -- modifieddate 
      getdate(),  -- entereddate
	    ---- recID [c] ----
      (
        SELECT 
          'YUAG' as 'unit', 
          'obj' as 'cmsType', 
          CAST(O2.ObjectID as nvarchar(25)) as 'cmsId', 
          (
            SELECT 
              O.label, 
              O.value
            FROM datatools_iiif_metadata O
            WHERE o.cmsid = o2.objectid 
            AND o.cmstype = 'obj'
            ORDER BY O.displayorder
            FOR JSON AUTO
          ) metadata,
        	(
            SELECT 
              'https://artgallery.yale.edu/collections/objects/'+CAST(O3.objectid as varchar) as 'id',
              'catalog entry at the Yale University Art Gallery' as 'label'
            FROM Objects O3 
            WHERE O3.objectid=O2.Objectid and O3.DepartmentID not in (88,92)
            FOR JSON AUTO
          ) homepage
        FROM Objects O2
        WHERE O2.ObjectID = A.Objectid
        FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER
      )
      FROM Objects A
      WHERE A.EnteredDate >= @lastSuccessfulUpdate
      AND A.IsTemplate = 0

    /* Insert only records which aren't already there (e.g. in case of a re-run) */
    INSERT INTO datatools_iiif_json
    SELECT t.*
    FROM #tmp_json t
    LEFT OUTER JOIN datatools_iiif_json j ON (j.cmstype = t.cmstype AND j.cmsid = t.cmsid)
    WHERE j.cmstype IS NULL

  SET NOCOUNT OFF
END
GO

GRANT EXEC ON datatools_iiif_obj_json_new TO PUBLIC
GO

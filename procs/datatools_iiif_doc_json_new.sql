/*
 * datatools_iiif_doc_json_new
 *
 */
IF EXISTS (SELECT * FROM sysobjects WHERE type = 'p' AND name = 'datatools_iiif_doc_json_new')
BEGIN
  DROP PROC datatools_iiif_doc_json_new
END
GO

CREATE PROC datatools_iiif_doc_json_new (@lastSuccessfulUpdate datetime)
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
      enteredDate   [datetime]        NOT NULL
    )

    INSERT INTO #tmp_json
      (cmstype, cmsid, modifieddate, entereddate, content) 
    SELECT 
      'doc', 
      D.id, 
      getdate(), -- TODO d.lastModified?
      getdate(),
      ---- recID [c] ----
      (
        SELECT 
          'YUAG' as 'unit', 
          'doc' as 'cmsType', 
          cast(D2.ID as nvarchar(25)) as 'cmsId', 
          (
            select D3.label, D3.value
            from datatools_iiif_metadata D3
            where D3.cmsid=D2.ID and D3.cmstype='doc'
            order by D3.displayorder
            FOR JSON AUTO
          ) metadata
        FROM MediaTools_DocCMS D2
        WHERE D2.id=D.id
        FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER
      )
    FROM MediaTools_DocCMS D 
    WHERE D.id NOT IN (SELECT DISTINCT cmsid AS id FROM datatools_iiif_metadata WHERE cmstype = 'doc') 

    /* Insert only records which aren't already there (e.g. in case of a re-run) */
    INSERT INTO datatools_iiif_json
    SELECT t.*
    FROM #tmp_json t
    LEFT OUTER JOIN datatools_iiif_json j ON (j.cmstype = t.cmstype AND j.cmsid = t.cmsid)
    WHERE j.cmstype IS NULL

  SET NOCOUNT OFF
END
GO

GRANT EXEC ON datatools_iiif_doc_json_new TO PUBLIC
GO
    

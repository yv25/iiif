/*
 * datatools_iiif_exb_json_new
 *
 */
IF EXISTS (SELECT * FROM sysobjects WHERE type = 'p' AND name = 'datatools_iiif_exb_json_new')
BEGIN
  DROP PROC datatools_iiif_exb_json_new
END
GO

CREATE PROC datatools_iiif_exb_json_new (@lastSuccessfulUpdate datetime)
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
      (cmstype, cmsID, modifieddate, entereddate, content) 
    SELECT 
  	 'exb', 
     E.ExhibitionID, 
      getdate(),  -- modifieddate 
      getdate(),  -- entereddate  TODO E.EnteredDate ?
	    ---- recID [c] ----
      (
      	SELECT 
          'YUAG' as 'unit', 
          'exb' as 'cmsType', 
          CAST(E2.ExhibitionID as nvarchar(25)) as 'cmsId', 
			    (
				    SELECT 
              E3.label, 
              E3.value
				    FROM datatools_iiif_metadata E3
				    WHERE E3.cmsid = E2.ExhibitionID 
            AND E3.cmstype = 'exb'
				    ORDER BY E3.displayorder
				    FOR JSON AUTO
			    ) metadata
    	  FROM Exhibitions E2 
	      WHERE E2.ExhibitionID = E.ExhibitionID
	      FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER
	    )
    FROM Exhibitions E 
    WHERE E.EnteredDate >= @lastSuccessfulUpdate

    /* Insert only records which aren't already there (e.g. in case of a re-run) */
    INSERT INTO datatools_iiif_json
    SELECT t.*
    FROM #tmp_json t
    LEFT OUTER JOIN datatools_iiif_json j ON (j.cmstype = t.cmstype AND j.cmsid = t.cmsid)
    WHERE j.cmstype IS NULL

  SET NOCOUNT OFF
END
GO

GRANT EXEC ON datatools_iiif_exb_json_new TO PUBLIC
GO






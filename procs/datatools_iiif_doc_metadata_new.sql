/*
 * datatools_iiif_doc_metadata_new
 *
 */
IF EXISTS (SELECT * FROM sysobjects WHERE type = 'p' AND name = 'datatools_iiif_doc_metadata_new')
BEGIN
  DROP PROC datatools_iiif_doc_metadata_new
END
GO

CREATE PROC datatools_iiif_doc_metadata_new (@lastSuccessfulUpdate datetime)
AS
BEGIN
  SET NOCOUNT ON

    IF OBJECT_ID('tempdb..#tmp_metadata') IS NOT NULL
      DROP TABLE #tmp_metadata

    CREATE TABLE #tmp_metadata
    (
      cmstype   char(3)         COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
      cmsid     int             NOT NULL,
      label     nvarchar(50)    COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
	    value     nvarchar(max)   COLLATE SQL_Latin1_General_CP1_CI_AI NOT NULL,
	    displayOrder nvarchar(2)  NULL,
    )

    INSERT INTO #tmp_metadata
      (cmstype, cmsid, label, value, displayorder)

      /* =========================================================== Label */
      SELECT 
        'doc', 
        D.ID, 
        'Label', 
        CASE 
          WHEN D.eventdate IS NOT NULL 
            THEN D.title+', '+CAST(D.eventdate as nvarchar(10)) 
          ELSE D.title 
        END, 
        '01'
      FROM MediaTools_DocCMS D
      WHERE D.id NOT IN (SELECT DISTINCT cmsid AS id FROM datatools_iiif_metadata WHERE cmstype = 'doc') 

    UNION 

      /* =========================================================== Rights Description */
      SELECT 
        'doc', 
        D.ID, 
        'Rights Description', 
        'Data Provided about Yale University Art Gallery events are public domain. Rights restrictions may apply to cultural works or images of those works.',
        '02'
      FROM MediaTools_DocCMS D
      WHERE D.id NOT IN (SELECT DISTINCT cmsid AS id FROM datatools_iiif_metadata WHERE cmstype = 'doc') 

    UNION

      /* =========================================================== Rights URI */
      SELECT 
        'doc', 
        D.ID, 
        'Rights URI', 
        'https://creativecommons.org/publicdomain/zero/1.0/', 
        '03'
      FROM MediaTools_DocCMS D
      WHERE D.id NOT IN (SELECT DISTINCT cmsid AS id FROM datatools_iiif_metadata WHERE cmstype = 'doc') 

    UNION

      /* =========================================================== Title */
      SELECT 
        'doc', 
        D.ID, 
        'Title', 
        D.title, 
        '04'
      FROM MediaTools_DocCMS D
      WHERE D.id NOT IN (SELECT DISTINCT cmsid AS id FROM datatools_iiif_metadata WHERE cmstype = 'doc') 

    UNION

      /* =========================================================== Classification */
      SELECT 
        'doc', 
        D.ID, 
        'Classification', 
        CASE 
          WHEN D.classification IS NULL 
            THEN '' 
          ELSE D.classification 
        END, 
        '05' 
        FROM MediaTools_DocCMS D
      WHERE D.id NOT IN (SELECT DISTINCT cmsid AS id FROM datatools_iiif_metadata WHERE cmstype = 'doc') 

    UNION

      /* =========================================================== Date */
      SELECT 
        'doc', 
        D.ID, 
        'Date', 
        CASE 
          WHEN d.eventdate IS NULL 
            THEN '' 
          ELSE CAST(D.eventdate as nvarchar(10)) 
        END, 
        '06'
      FROM MediaTools_DocCMS D
      WHERE D.id NOT IN (SELECT DISTINCT cmsid AS id FROM datatools_iiif_metadata WHERE cmstype = 'doc') 

    UNION

      /* =========================================================== Institution */
      SELECT 
        'doc', 
        D.id, 
        'Institution', 
        'Yale University Art Gallery', 
        '15'
      FROM MediaTools_DocCMS D
      WHERE D.id NOT IN (SELECT DISTINCT cmsid AS id FROM datatools_iiif_metadata WHERE cmstype = 'doc') 

    UNION

      /* =========================================================== logo */
      SELECT 
        'doc',
        D.id,
        'logo', 
        'https://artgallery.yale.edu/sites/default/files/2023-03/LUX_YUAG_logo.png', 
        '17'
      FROM MediaTools_DocCMS D
      WHERE D.id NOT IN (SELECT DISTINCT cmsid AS id FROM datatools_iiif_metadata WHERE cmstype = 'doc') 


    /* Insert only records which aren't already there (e.g. in case of a re-run) */
    INSERT INTO datatools_iiif_metadata
    SELECT t.*
    FROM #tmp_metadata t 
    LEFT OUTER JOIN datatools_iiif_metadata m ON
      (
        m.cmstype = t.cmstype
        and m.cmsid = t.cmsid 
        and m.label = t.label
      ) 
    WHERE m.cmstype IS NULL

  SET NOCOUNT OFF
END
GO

GRANT EXEC ON datatools_iiif_doc_metadata_new TO PUBLIC
GO
    
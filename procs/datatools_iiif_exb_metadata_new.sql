/*
 * datatools_iiif_exb_metadata_new
 *
 */
IF EXISTS (SELECT * FROM sysobjects WHERE type = 'p' AND name = 'datatools_iiif_exb_metadata_new')
BEGIN
  DROP PROC datatools_iiif_exb_metadata_new
END
GO

CREATE PROC datatools_iiif_exb_metadata_new (@lastSuccessfulUpdate datetime)
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
      'exb', 
      E.ExhibitionID, 
      'Label', 
      CASE 
        WHEN E.BeginISODate IS NOT NULL AND E.EndISODate IS NOT NULL 
          THEN E.ExhTitle+', '+E.BeginISODate+' to '+E.EndISODate
        WHEN E.BeginISODate IS NOT NULL AND E.EndISODate IS NULL 
          THEN E.ExhTitle+', '+E.BeginISODate
        WHEN E.BeginISODate IS NULL AND E.EndISODate IS NOT NULL 
          THEN E.ExhTitle+', '+E.EndISODate
        ELSE 
          ISNULL(E.ExhTitle,'Research needed')
      END, 
      '01'
    FROM Exhibitions E
    WHERE E.EnteredDate >= @lastSuccessfulUpdate

    UNION 

    /* =========================================================== Rights Description */
    SELECT 
      'exb', 
      E.ExhibitionID, 
      'Rights Description', 
      'Data Provided about Yale University Art Gallery exhibitions are public domain. Rights restrictions may apply to cultural works or images of those works.',
      '02'
    FROM Exhibitions E
    WHERE E.EnteredDate >= @lastSuccessfulUpdate

    UNION

    /* =========================================================== Rights URI */
    SELECT 
      'exb', 
      E.ExhibitionID, 
      'Rights URI', 
      'https://creativecommons.org/publicdomain/zero/1.0/', 
      '03'
    FROM Exhibitions E
    WHERE E.EnteredDate >= @lastSuccessfulUpdate

    UNION

    /* =========================================================== Title */
    SELECT 
      'exb', 
      E.ExhibitionID, 
      'Title', 
      ISNULL(E.ExhTitle,'Research needed'),
      '04'
    FROM Exhibitions E
    WHERE E.EnteredDate >= @lastSuccessfulUpdate

    UNION

    /* =========================================================== Date */
    SELECT 
      'exb', 
      E.ExhibitionID, 
      'Date', 
      CASE 
        WHEN E.BeginISODate IS NOT NULL 
        AND E.EndISODate IS NOT NULL 
          THEN E.BeginISODate+' to '+E.EndISODate
        WHEN E.BeginISODate IS NOT NULL 
        AND E.EndISODate IS NULL 
          THEN E.BeginISODate 
        WHEN E.BeginISODate IS NULL 
        AND E.EndISODate IS NOT NULL 
          THEN E.EndISODate ELSE '' 
      END, 
      '05'
    FROM Exhibitions E
    WHERE E.EnteredDate >= @lastSuccessfulUpdate

    UNION 

    /* =========================================================== Venue(s) */
    SELECT 
      'exb', 
      E.ExhibitionID, 
      'Venue(s)', 
      dbo.YUAG_exhVenueArrayNoCity(E.exhibitionid), 
      '06'
    FROM Exhibitions E
    WHERE E.EnteredDate >= @lastSuccessfulUpdate

    UNION 

    /* =========================================================== Institution */
    SELECT 
      'exb', 
      E.ExhibitionID, 
      'Institution', 
      'Yale University Art Gallery', 
      '07'
    FROM Exhibitions E
    WHERE E.EnteredDate >= @lastSuccessfulUpdate

    UNION 

    /* =========================================================== logo */
    SELECT 
      'exb',
      E.ExhibitionID,
      'logo',
      'https://artgallery.yale.edu/sites/default/files/2023-03/LUX_YUAG_logo.png', 
      '08'
    FROM Exhibitions E
    WHERE E.EnteredDate >= @lastSuccessfulUpdate

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

GRANT EXEC ON datatools_iiif_exb_metadata_new TO PUBLIC
GO
    
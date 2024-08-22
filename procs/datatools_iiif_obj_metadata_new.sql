/*
 * datatools_iiif_obj_metadata_new
 *
 */

IF EXISTS (SELECT * FROM sysobjects WHERE type = 'p' AND name = 'datatools_iiif_obj_metadata_new')
BEGIN
  DROP PROC datatools_iiif_obj_metadata_new
END
GO

CREATE PROC datatools_iiif_obj_metadata_new (@lastSuccessfulUpdate datetime)
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
      'obj',
      O.ObjectID,
      'Label',
      CASE
        WHEN A.FullName IS NOT NULL AND T.Title IS NOT NULL AND O.dated IS NOT NULL
          THEN A.FullName+', '+T.Title+', '+O.Dated
        WHEN A.FullName IS NOT NULL AND T.Title IS NOT NULL AND O.dated IS NULL
          THEN A.FullName+', '+T.Title
        WHEN A.FullName IS NOT NULL AND T.Title IS NULL AND O.dated IS NOT NULL
          THEN A.FullName+', '+O.Dated
        WHEN A.FullName IS NOT NULL AND T.Title IS NULL AND O.dated IS NULL
          THEN A.FullName
        WHEN A.FullName IS NULL AND T.Title IS NOT NULL AND O.dated IS NOT NULL
          THEN T.Title+', '+O.Dated
        WHEN A.FullName IS NULL AND T.Title IS NOT NULL AND O.dated IS NULL
          THEN T.Title
        WHEN A.FullName IS NULL AND T.Title IS NULL AND O.dated IS NOT NULL
          THEN O.Dated
        ELSE  
          '<reseach pending>' 
      END,
      '01'
    FROM objects O 
    LEFT OUTER JOIN yuag_ObjRelCon1 A on O.objectid = A.ID
    LEFT OUTER JOIN yuag_ObjTitle1 T on O.objectid = T.ObjectID
    WHERE O.EnteredDate >= @lastSuccessfulUpdate 
      AND O.IsTemplate=0

  UNION

    /* =========================================================== Image Use Rights */
    SELECT 
      'obj', 
      O.ObjectID, 
      'Image Use Rights', 
      NR.NewRightsType, 
      '02'
    FROM Objects O 
    INNER JOIN Objrights R on O.ObjectID=R.ObjectID 
    INNER JOIN yuag_NewRights NR on R.ObjRightsTypeID=NR.ObjRightsTypeID
    WHERE O.EnteredDate>= @lastSuccessfulUpdate 
      AND O.IsTemplate=0

  UNION

    /* =========================================================== Image Use Rights URI */
    SELECT 
      'obj', 
      O.ObjectID, 
      'Image Use Rights URI', 
      NR.URI, 
      '03'
    FROM Objects O 
    INNER JOIN Objrights R on O.ObjectID=R.ObjectID 
    INNER JOIN yuag_NewRights NR on R.ObjRightsTypeID=NR.ObjRightsTypeID
    WHERE O.EnteredDate>= @lastSuccessfulUpdate 
      AND O.IsTemplate=0

  UNION


    /* =========================================================== Copyright Statement */
    SELECT 
      'obj', 
      O.ObjectID, 
      'Copyright Statement', 
      CASE 
        WHEN R.ObjRightsTypeID in (0, 3, 5) then 'Copyright Artist/Estate/Foundation'
		WHEN R.ObjRightsTypeID =12 then 'Copyright Undetermined'
		WHEN R.ObjRightsTypeID =6 then 'Rights-Holder unlocatable or unidentifiable'
        ELSE R.Copyright 
      END, 
      '04'
    FROM objects O 
    INNER JOIN ObjRights R on O.ObjectID=R.ObjectID
    WHERE O.EnteredDate >= @lastSuccessfulUpdate 
      AND R.Copyright IS NOT NULL                            -- TODO conflicts with CASE... remove if you want blanks for nulls
      AND O.IsTemplate=0
  
  UNION

    /* =========================================================== Rights Description */
    SELECT 
      'obj', 
      O.ObjectID, 
      'Rights Description', 
      Case 
		when O.DepartmentID=88 then 
		'Data Provided about Yale Campus Art collections are public domain. Rights restrictions may apply to cultural works or images of those works.'
		when O.DepartmentID=92 then
		'Data Provided about Yale Morris Steinert Collection of Musical Instruments are public domain. Rights restrictions may apply to cultural works or images of those works.'
		else
		'Data Provided about Yale University Art Gallery collections are public domain. Rights restrictions may apply to cultural works or images of those works.' end,
      '05'
    FROM objects O 
    WHERE O.EnteredDate>= @lastSuccessfulUpdate 
      AND O.IsTemplate=0

  UNION

    /* =========================================================== Rights URI */
    SELECT 
      'obj', 
      O.ObjectID, 
      'Rights URI', 
      'https://creativecommons.org/publicdomain/zero/1.0/', 
      '06'
    FROM objects O 
    WHERE O.EnteredDate>= @lastSuccessfulUpdate 
      AND O.IsTemplate=0

  UNION

    /* =========================================================== Title */
    SELECT 
      'obj', 
      O.Objectid, 
      'Title', 
      CASE 
        WHEN T.title IS NOT NULL THEN T.Title 
        ELSE '<research pending>' 
      END, 
      '07'
    FROM Objects O 
    LEFT OUTER JOIN yuag_ObjTitle1 T on O.objectid=T.Objectid
    WHERE O.EnteredDate>= @lastSuccessfulUpdate 
      AND O.IsTemplate=0

  UNION

    /* =========================================================== Creator(s) */
    SELECT 
      'obj', 
      O.Objectid, 
      'Creator(s)', 
      CASE 
        WHEN A.ID IS NULL THEN '' 
        ELSE dbo.YUAG_ConArrayRolesBio(O.Objectid, 1, 108) 
      END, 
      '08'
    FROM Objects O 
    INNER JOIN yuag_ObjRelCon1 A on O.ObjectID=A.ID
    WHERE O.EnteredDate>= @lastSuccessfulUpdate 
      AND O.IsTemplate=0

  UNION

    /* =========================================================== Culture */
    SELECT 
      'obj', 
      OC.objectid, 
      'Culture', 
      CASE 
        WHEN OC.Culture IS NULL THEN '<research pending>' 
        ELSE OC.Culture 
      END, 
      '09'
    FROM ObjContext OC 
    INNER JOIN Objects O on OC.ObjectID=O.Objectid
    WHERE OC.EnteredDate>= @lastSuccessfulUpdate 
      AND OC.Culture IS NOT NULL                                          -- TODO conflicts with CASE
      AND O.IsTemplate=0

  UNION

    /* =========================================================== Date */
    SELECT 
      'obj', 
      O.objectid, 
      'Date', 
      CASE 
        WHEN O.dated IS NULL THEN 'n.d.' 
        ELSE O.dated 
      END, 
      '10'
    FROM Objects O
    WHERE O.EnteredDate>= @lastSuccessfulUpdate 
      AND O.dated IS NOT NULL                                            -- TODO conflicts with CASE
      AND O.IsTemplate=0

  UNION

    /* ===========================================================  Medium */
    SELECT 
      'obj', 
      O3.objectID, 
      'Medium', 
      CASE 
        WHEN O3.Medium IS NULL THEN '<research pending>' 
        ELSE O3.Medium 
      END, '11'
    FROM objects O3 
    WHERE O3.EnteredDate>= @lastSuccessfulUpdate 
      AND O3.Medium IS NOT NULL                                           -- TODO conflicts with CASE
      AND O3.IsTemplate=0

  UNION

    /* ===========================================================  Dimensions */
    SELECT 
      'obj', 
      O4.objectid, 
      'Dimensions', 
      CASE 
        WHEN O4.dimensions IS NULL THEN '<research pending>' 
        ELSE O4.dimensions 
      END, 
      '12'
    FROM Objects O4
    WHERE O4.EnteredDate >= @lastSuccessfulUpdate 
      AND O4.Dimensions IS NOT NULL                                       -- TODO conflicts with CASE
      AND O4.IsTemplate=0

  UNION

    /* =========================================================== Creditline */
    SELECT 
      'obj',
      O.ObjectID,
      'Creditline',
      CASE 
        WHEN O.CreditLine IS NULL THEN '<research pending>' 
        ELSE O.Creditline 
      END, 
      '13'
    FROM objects O 
    WHERE O.EnteredDate >= @lastSuccessfulUpdate 
      AND O.IsTemplate=0

  UNION

    /* ===========================================================  Classification */
    SELECT 
      'obj', 
      OCL.Objectid, 
      'Classification', 
      CASE 
        WHEN CL.subclassification IS NOT NULL 
        AND CL.subclassification2 IS NOT NULL 
        AND CL.subclassification3 IS NOT NULL 
          THEN CL.classification + ' - ' + CL.subclassification + ' - ' + CL.subclassification2 + ' - ' + CL.subclassification3 
        WHEN CL.subclassification IS NOT NULL 
        AND CL.subclassification2 IS NOT NULL 
        AND CL.subclassification3 IS NULL 
          THEN CL.classification + ' - ' + CL.subclassification + ' - ' + CL.subclassification2 
        WHEN CL.subclassification IS NOT NULL 
        AND CL.subclassification2 IS NULL 
        AND CL.subclassification3 IS NULL 
          THEN CL.classification + ' - ' + CL.subclassification ELSE CL.classification 
      END AS value, 
      '14'
    FROM Objects OCL 
    INNER JOIN Classifications CL on ocl.ClassificationID=CL.ClassificationID AND OCL.IsTemplate=0
    WHERE OCL.EnteredDate >= @lastSuccessfulUpdate

  UNION

    /* =========================================================== Department */
    SELECT 
      'obj', 
      O.ObjectID, 
      'Department', 
      D.Department, 
      '15'
    FROM objects O 
    INNER JOIN Departments D on O.DepartmentID=D.departmentid
    WHERE O.EnteredDate >= @lastSuccessfulUpdate 
      AND O.IsTemplate=0

  UNION

    /* =========================================================== Institution */
    SELECT 
      'obj',
      O.Objectid,
      'Institution', 
      case
		when O.DepartmentID=88 then 'Yale Campus Art Collection'
		when O.DepartmentID=92 then 'Yale Morris Steinert Collection of Musical Instruments'
		else
		'Yale University Art Gallery' end, 
      '16'
    FROM Objects O
    WHERE O.EnteredDate >= @lastSuccessfulUpdate 
      AND O.IsTemplate=0

  UNION

    /* ===========================================================  Object Number */
    SELECT 
      'obj',
      O.ObjectID,
      'Object Number', 
      O.ObjectNumber, 
      '17'
    FROM objects O
    WHERE O.EnteredDate >= @lastSuccessfulUpdate 
      AND O.IsTemplate=0

  UNION

    /* =========================================================== logo */
    SELECT 
      'obj', 
      O.objectid, 
      'logo', 
      'https://artgallery.yale.edu/sites/default/files/2023-03/LUX_YUAG_logo.png', 
      '18'
    FROM Objects O
    WHERE O.EnteredDate >= @lastSuccessfulUpdate 
      AND O.IsTemplate=0

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

GRANT EXEC ON datatools_iiif_obj_metadata_new TO PUBLIC
GO


/*
 * datatools_iiif_metadata_update
 *
 */
IF EXISTS (SELECT * FROM sysobjects WHERE type = 'p' AND name = 'datatools_iiif_metadata_update')
BEGIN
  DROP PROC datatools_iiif_metadata_update
END
GO

CREATE PROC datatools_iiif_metadata_update (@lastSuccessfulUpdate datetime)
AS
BEGIN
  SET NOCOUNT ON

    /*=================================================================== Label */
    UPDATE datatools_iiif_metadata
    SET value = 
      CASE
        WHEN A.fullname IS NOT NULL AND T.title IS NOT NULL AND O.dated IS NOT NULL 
          THEN A.fullname + ', ' + T.title + ', ' + O.dated
        WHEN A.fullname IS NOT NULL AND T.title IS NOT NULL AND O.dated IS NULL 
          THEN A.fullname + ', ' + T.title
        WHEN A.fullname IS NOT NULL AND T.title IS NULL AND O.dated IS NOT NULL 
          THEN A.fullname + ', ' + O.dated
        WHEN A.fullname IS NOT NULL AND T.title IS NULL AND O.dated IS NULL 
          THEN A.fullname
        WHEN A.fullname IS NULL AND T.title IS NOT NULL AND O.dated IS NOT NULL 
          THEN T.title + ', ' + O.dated
        WHEN A.fullname IS NULL AND T.title IS NOT NULL AND O.dated IS NULL 
          THEN T.title
        WHEN A.fullname IS NULL AND T.title IS NULL AND O.dated IS NOT NULL 
          THEN O.dated
        ELSE '<reseach pending>'
      END
    FROM objects O
    LEFT OUTER JOIN yuag_objrelcon1 A ON O.objectid = A.id
    LEFT OUTER JOIN yuag_objtitle1 T ON O.objectid = T.objectid
    INNER JOIN datatools_iiif_metadata M ON O.objectid = M.cmsid
    INNER JOIN datatools_iiif_audittrail AT ON O.objectid = AT.cmsid
    WHERE  AT.cmstype = 'obj'
      AND M.label = 'Label'

    /*=================================================================== Image Use Rights */
    UPDATE datatools_iiif_metadata
    SET value = NR.newrightstype
    FROM objects O
    INNER JOIN objrights R ON O.objectid = R.objectid
    INNER JOIN yuag_newrights NR ON R.objrightstypeid = NR.objrightstypeid
    INNER JOIN datatools_iiif_metadata M ON O.objectid = M.cmsid
    INNER JOIN datatools_iiif_audittrail AT ON O.objectid = AT.cmsid
    WHERE  AT.cmstype = 'obj'
      AND M.label = 'Image Use Rights'

    /*=================================================================== Image Use Rights URI */
    UPDATE datatools_iiif_metadata
    SET value = NR.uri
    FROM objects O
    INNER JOIN objrights R ON O.objectid = R.objectid
    INNER JOIN yuag_newrights NR ON R.objrightstypeid = NR.objrightstypeid
    INNER JOIN datatools_iiif_metadata M ON O.objectid = M.cmsid
    INNER JOIN datatools_iiif_audittrail AT ON O.objectid = AT.cmsid
    WHERE  AT.cmstype = 'obj'
      AND M.label = 'Image Use Rights URI'

    /*=================================================================== Copyright Statement */
  UPDATE datatools_iiif_metadata
    SET value =     CASE 
        WHEN R.ObjRightsTypeID in (0, 3, 5) then 'Copyright Artist/Estate/Foundation'
		WHEN R.ObjRightsTypeID =12 then 'Copyright Undetermined'
		WHEN R.ObjRightsTypeID =6 then 'Rights-Holder unlocatable or unidentifiable'
        ELSE R.Copyright end
    FROM objects O
    INNER JOIN objrights R ON O.objectid = R.objectid
    INNER JOIN datatools_iiif_metadata M ON O.objectid = M.cmsid
    INNER JOIN datatools_iiif_audittrail AT ON O.objectid = AT.cmsid
    WHERE  AT.cmstype = 'obj'
      AND M.label = 'Copyright Statement'
      AND R.copyright IS NOT NULL

    /*=================================================================== Title */
    UPDATE datatools_iiif_metadata
    SET value = 
      CASE
        WHEN T.title IS NOT NULL 
        THEN T.title
      ELSE '<research pending>'
    END
    FROM objects O
    LEFT OUTER JOIN yuag_objtitle1 T ON O.objectid = T.objectid
    INNER JOIN datatools_iiif_metadata M ON O.objectid = M.cmsid
    INNER JOIN datatools_iiif_audittrail AT ON O.objectid = AT.cmsid
    WHERE  AT.cmstype = 'obj'
    AND M.label = 'Title'

    /*=================================================================== Creator(s) */
    UPDATE datatools_iiif_metadata
    SET value = dbo.Yuag_conarrayrolesbio(O.objectid, 1, 108)
    FROM objects O
    INNER JOIN yuag_objrelcon1 A ON O.objectid = A.id
    INNER JOIN datatools_iiif_metadata M ON O.objectid = M.cmsid
    INNER JOIN datatools_iiif_audittrail AT ON O.objectid = AT.cmsid
    WHERE  AT.cmstype = 'obj'
    AND M.label = 'Creator(s)'

    /*=================================================================== Culture */
    UPDATE datatools_iiif_metadata
    SET value = 
    CASE
       WHEN OC.culture IS NOT NULL THEN OC.culture
       ELSE '<research pending>'
    END
    FROM objcontext OC
    INNER JOIN datatools_iiif_metadata M ON OC.objectid = M.cmsid
    INNER JOIN datatools_iiif_audittrail AT ON OC.objectid = AT.cmsid
    WHERE  AT.cmstype = 'obj'
    AND M.label = 'Culture'

    /*=================================================================== Date */
    UPDATE datatools_iiif_metadata
    SET value = 
    CASE
      WHEN O.dated IS NOT NULL THEN O.dated
      ELSE 'n.d.'
    END
    FROM objects O
    INNER JOIN datatools_iiif_metadata M ON O.objectid = M.cmsid
    INNER JOIN datatools_iiif_audittrail AT ON O.objectid = AT.cmsid
    WHERE  AT.cmstype = 'obj'
      AND M.label = 'Date'

    /*=================================================================== Medium */
    UPDATE datatools_iiif_metadata
    SET value = 
    CASE
      WHEN O.medium IS NOT NULL THEN O.medium
      ELSE '<research pending>'
    END
    FROM objects O
    INNER JOIN datatools_iiif_metadata M ON O.objectid = M.cmsid
    INNER JOIN datatools_iiif_audittrail AT ON O.objectid = AT.cmsid
    WHERE  AT.cmstype = 'obj'
    AND M.label = 'Medium'

    /*=================================================================== Dimensions */
    UPDATE datatools_iiif_metadata
    SET value = 
    CASE
      WHEN O.dimensions IS NOT NULL THEN O.dimensions
      ELSE '<research pending>'
    END
    FROM objects O
    INNER JOIN datatools_iiif_metadata M ON O.objectid = M.cmsid
    INNER JOIN datatools_iiif_audittrail AT ON O.objectid = AT.cmsid
    WHERE  AT.cmstype = 'obj'
      AND M.label = 'Dimensions'

    /*=================================================================== Creditline */
    UPDATE datatools_iiif_metadata
    SET value = 
    CASE
      WHEN O.creditline IS NOT NULL THEN O.creditline
      ELSE '<research pending>'
    END
    FROM objects O
    INNER JOIN datatools_iiif_metadata M ON O.objectid = M.cmsid
    INNER JOIN datatools_iiif_audittrail AT ON O.objectid = AT.cmsid
    WHERE  AT.cmstype = 'obj'
      AND M.label = 'Creditline'

    /*=================================================================== Classification */
    UPDATE datatools_iiif_metadata
    SET value = 
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
    END
    FROM objects O
    INNER JOIN classifications CL ON o.classificationid = CL.classificationid
    INNER JOIN datatools_iiif_metadata M ON O.objectid = M.cmsid
    INNER JOIN datatools_iiif_audittrail AT ON O.objectid = AT.cmsid
    WHERE  AT.cmstype = 'obj'
      AND M.label = 'Classification'

    /*=================================================================== Department */
    UPDATE datatools_iiif_metadata
    SET value = D.department
    FROM objects O
    INNER JOIN departments D ON O.departmentid = D.departmentid
    INNER JOIN datatools_iiif_metadata M ON O.objectid = M.cmsid
    INNER JOIN datatools_iiif_audittrail AT ON O.objectid = AT.cmsid
    WHERE  AT.cmstype = 'obj'
      AND M.label = 'Department'

    /*=================================================================== Object Number */
    UPDATE datatools_iiif_metadata 
    SET value = O.objectnumber
    FROM objects O
    INNER JOIN datatools_iiif_metadata M ON O.objectid = M.cmsid
    INNER JOIN datatools_iiif_audittrail AT ON O.objectid = AT.cmsid
    WHERE  AT.cmstype = 'obj'
      AND M.label = 'Object Number'

    ----- EXHIBITIONS -------

    /*=================================================================== Label */
    UPDATE datatools_iiif_metadata
    SET value = 
    CASE
      WHEN E.beginisodate IS NOT NULL AND E.endisodate IS NOT NULL 
        THEN E.exhtitle + ', ' + E.beginisodate + ' to ' + E.endisodate
      WHEN E.beginisodate IS NOT NULL AND E.endisodate IS NULL 
        THEN E.exhtitle + ', ' + E.beginisodate
      WHEN E.beginisodate IS NULL AND E.endisodate IS NOT NULL 
        THEN E.exhtitle + ', ' + E.endisodate
      ELSE E.exhtitle
    END
    FROM exhibitions E
    INNER JOIN datatools_iiif_audittrail A ON E.exhibitionid = A.cmsid
    INNER JOIN datatools_iiif_metadata M ON A.cmsid = M.cmsid
    WHERE  A.cmstype = 'exb'
    AND M.label = 'Label'

    /*=================================================================== Title */
    UPDATE datatools_iiif_metadata
    SET value = E.exhtitle
    FROM exhibitions E
    INNER JOIN datatools_iiif_audittrail A ON E.exhibitionid = A.cmsid
    INNER JOIN datatools_iiif_metadata M ON A.cmsid = M.cmsid
    WHERE  A.cmstype = 'exb'
    AND M.label = 'Title'

    /*=================================================================== Date */
    UPDATE datatools_iiif_metadata
    SET value = 
    CASE
      WHEN E.beginisodate IS NOT NULL AND E.endisodate IS NOT NULL 
        THEN E.beginisodate + ' to ' + E.endisodate
      WHEN E.beginisodate IS NOT NULL AND E.endisodate IS NULL 
        THEN E.beginisodate
      WHEN E.beginisodate IS NULL AND E.endisodate IS NOT NULL 
        THEN E.endisodate
      ELSE ''
    END
    FROM exhibitions E
    INNER JOIN datatools_iiif_audittrail A ON E.exhibitionid = A.cmsid
    INNER JOIN datatools_iiif_metadata M ON A.cmsid = M.cmsid
    WHERE  A.cmstype = 'exb'
      AND M.label = 'Date'

    /*=================================================================== Venue(s) */
    UPDATE datatools_iiif_metadata
    SET value = dbo.Yuag_exhvenuearraynocity(E.exhibitionid)
    FROM exhibitions E
    INNER JOIN datatools_iiif_audittrail A ON E.exhibitionid = A.cmsid
    INNER JOIN datatools_iiif_metadata M ON A.cmsid = M.cmsid
    WHERE  A.cmstype = 'exb'
      AND M.label = 'Venue(s)' 

    ----- DOC CMS -------

    /*=================================================================== Label*/
    UPDATE datatools_iiif_metadata
    SET value = 
      CASE 
        WHEN D.eventdate IS NOT NULL 
          THEN D.title+', '+CAST(D.eventdate as nvarchar(10)) 
        ELSE D.title 
      END
    FROM MediaTools_DocCMS d
    JOIN datatools_iiif_audittrail A ON d.id = A.cmsid
    WHERE datatools_iiif_metadata.cmstype = 'doc'
      AND datatools_iiif_metadata.cmsid = d.id
      AND datatools_iiif_metadata.label = 'Label'
      
    /*=================================================================== Title */
    UPDATE datatools_iiif_metadata
    SET value = d.title
    FROM MediaTools_DocCMS d
    JOIN datatools_iiif_audittrail A ON d.id = A.cmsid
    WHERE datatools_iiif_metadata.cmstype = 'doc'
      AND datatools_iiif_metadata.cmsid = d.id
      AND datatools_iiif_metadata.label = 'Title'
    
    /*=================================================================== Classification */
    UPDATE datatools_iiif_metadata
    SET value = 
      CASE 
        WHEN D.classification IS NULL 
          THEN '' 
        ELSE D.classification 
      END    
    FROM MediaTools_DocCMS d
    JOIN datatools_iiif_audittrail A ON d.id = A.cmsid
    WHERE datatools_iiif_metadata.cmstype = 'doc'
      AND datatools_iiif_metadata.cmsid = d.id
      AND datatools_iiif_metadata.label = 'Classification'    
    
    /*=================================================================== Date */
    UPDATE datatools_iiif_metadata
    SET value = 
      CASE 
        WHEN d.eventdate IS NULL 
          THEN '' 
        ELSE CAST(D.eventdate as nvarchar(10)) 
      END
    FROM MediaTools_DocCMS d
    JOIN datatools_iiif_audittrail A ON d.id = A.cmsid
    WHERE datatools_iiif_metadata.cmstype = 'doc'
      AND datatools_iiif_metadata.cmsid = d.id
      AND datatools_iiif_metadata.label = 'Classification'    

  SET NOCOUNT OFF
END
GO

GRANT EXEC ON datatools_iiif_metadata_update TO PUBLIC
GO
    
/*
 * datatools_iiif_insert_audittrail
 *
 * Inserts rows into the datatools_<collectionName>_audittrail table where the 
 * specified cmsid+cmstype has specific TMS.auditTrail data since the date 
 * of the last successful run.
 */
IF EXISTS (SELECT * FROM sysobjects WHERE type = 'p' AND name = 'datatools_iiif_insert_audittrail')
BEGIN
  DROP PROC datatools_iiif_insert_audittrail
END
GO

CREATE PROC datatools_iiif_insert_audittrail (@lastSuccessfulUpdate datetime)
AS
BEGIN
  SET NOCOUNT ON

    -- Clear all existing rows
    truncate table datatools_iiif_audittrail

    /*================================================================== OBJECTS */

    /*-Changes to Constituents Name, Bio, Nationality----*/
    INSERT into datatools_iiif_audittrail (cmstype, cmsid)
    SELECT 'obj', A.ObjectID
    FROM AuditTrail A 
    INNER JOIN yuag_Constituents C ON A.ObjectID = C.ConstituentID
    WHERE A.EnteredDate >= @lastSuccessfulUpdate 
      AND A.ModuleID = 2 
      AND A.ColumnName IN ('DisplayName', 'DisplayDate') 
      AND C.TableID = 108 AND C.RoleTypeID = 1
    GROUP BY A.ObjectID


    /*-Changes to Tombstone Data----*/ 
    INSERT into datatools_iiif_audittrail (cmstype, cmsid)
    SELECT 'obj', A.ObjectID
    FROM AuditTrail A
    WHERE A.EnteredDate >= @lastSuccessfulUpdate
      AND a.objectId IS NOT NULL
      AND A.ModuleID = 1 
      AND A.ColumnName IN ('Classification', 'Medium', 'Dimensions', 'CreditLine', 'Title', 
                           'Dated', 'ObjRightsType', 'Copyright', 'ObjectNumber')
    GROUP BY A.ObjectID


    /*-Changes Conxrefs------*/ 
    INSERT into datatools_iiif_audittrail (cmstype, cmsid)
    SELECT 'obj', C.ID
    FROM AuditTrail A2 
    INNER JOIN ConXrefs C on A2.ObjectID=C.ConXrefID
    WHERE A2.EnteredDate >= @lastSuccessfulUpdate
      AND A2.ModuleID = 1 
      AND A2.explanation=108 
      AND A2.TableName='ConXRefs' 
      AND C.TableID=108
    GROUP BY C.ID

    /*================================================================== EXHIBITIONS */

    INSERT into datatools_iiif_audittrail (cmstype, cmsid)
    SELECT 'exb', A.ObjectID
    FROM AuditTrail A
    WHERE A.EnteredDate >= @lastSuccessfulUpdate
      AND A.ModuleID = 4 
      AND A.ColumnName IN ('ExhTitle', 'BeginISODate', 'EndISODate') 
      AND A.TableName = 'Exhibitions'
    GROUP BY A.ObjectID

    /*----EXHIBITION VENUES------*/ 
    INSERT into datatools_iiif_audittrail (cmstype, cmsid)
    SELECT 'exb', C.ID
    FROM AuditTrail A 
    INNER JOIN Conxrefs C on A.objectID=C.ConXrefID
    WHERE A.EnteredDate >= @lastSuccessfulUpdate
      AND A.ModuleID = 0 
      AND A.Explanation=51 
      AND A.TableName = 'ConXRefs'
    GROUP BY C.ID

    /*================================================================== DOCCMS */
    INSERT into datatools_iiif_audittrail (cmstype, cmsid)
    SELECT 'doc', d.id
    FROM MediaTools_DocCMS d
    WHERE d.lastmodified > @lastSuccessfulUpdate

  SET NOCOUNT OFF
END
GO

GRANT EXEC ON datatools_iiif_insert_audittrail TO PUBLIC
GO
    
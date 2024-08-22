/*
 * datatools_iiif_appenddeletions
 *
 */

IF EXISTS (SELECT * FROM sysobjects WHERE type = 'p' AND name = 'datatools_iiif_appenddeletions')
BEGIN
  DROP PROC datatools_iiif_appenddeletions
END
GO

CREATE PROC datatools_iiif_appenddeletions (@lastSuccessfulUpdate datetime)
AS
BEGIN
  SET NOCOUNT ON

    /* ========================================= OBJ */
    INSERT INTO datatools_deletions
      (cmstype, cmsid, collectionName, published, publishDate)
    select distinct  
      'obj', 
      objectid, 
      'iiif',
      0,
      NULL
    from audittrail a
    LEFT JOIN datatools_deletions d on 
      (d.cmstype = 'obj' 
       and d.cmsid = a.objectid
       and d.collectionName = 'iiif') 
    where a.explanation = 'Entire record was deleted' 
    and a.tablename = 'objects'
    and d.cmsid is null
    order by a.objectId

    /* ========================================= EXB */
    INSERT INTO datatools_deletions
      (cmstype, cmsid, collectionName, published, publishDate)
    select distinct  
      'exb', 
      objectid, 
      'iiif',
      0,
      NULL
    from audittrail a
    LEFT JOIN datatools_deletions d on 
      (d.cmstype = 'exb' 
       and d.cmsid = a.objectid
       and d.collectionName = 'iiif') 
    where a.explanation = 'Entire record was deleted' 
    and a.tablename = 'exhibitions'
    and d.cmsid is null
    order by a.objectId

    /* ========================================= DOC */    
    INSERT INTO datatools_deletions
      (cmstype, cmsid, collectionName, published, publishDate)
    SELECT DISTINCT  
      'doc', 
      m.doccmsid, 
      'iiif',
      0,
      NULL
    FROM MediaTools_DocCMS_deletions m
    LEFT JOIN datatools_deletions d on 
      (d.cmstype = 'doc' 
      and d.cmsid = m.doccmsid
      and d.collectionName = 'iiif')
    WHERE d.cmsid IS NULL
    ORDER BY m.doccmsid

  SET NOCOUNT OFF
END
GO

GRANT EXEC ON datatools_iiif_appenddeletions TO PUBLIC
GO
    
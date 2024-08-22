IF EXISTS (SELECT * FROM sysobjects WHERE type = 'u' AND name = 'datatools_iiif_audittrail')
BEGIN
  RAISERROR ('datatools_iiif_audittrail table already exists', 16, 1) with nowait
  RETURN
END
ELSE
BEGIN

  CREATE TABLE dbo.datatools_iiif_audittrail
  (
    cmsid     int           not null,
    cmstype   char(3)       not null
  )    

  GRANT INSERT, UPDATE, SELECT, DELETE ON dbo.datatools_iiif_audittrail TO [PUBLIC]

END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE type = 'v' AND name = 'datatools_iiif_feed')
BEGIN
  DROP VIEW datatools_iiif_feed
END
GO

CREATE VIEW dbo.datatools_iiif_feed
AS

  SELECT * from datatools_iiif_json

GO

GRANT SELECT ON datatools_iiif_feed TO PUBLIC
GO

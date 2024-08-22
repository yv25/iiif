IF EXISTS (SELECT * FROM sysobjects WHERE type = 'u' AND name = 'datatools_iiif_metadata')
BEGIN
  RAISERROR ('datatools_iiif_metadata table already exists', 16, 1) with nowait
  RETURN
END
ELSE
BEGIN

  CREATE TABLE dbo.datatools_iiif_metadata
  (
    cmstype   char(3)         not null,
    cmsid     int             not null,
    label     nvarchar(50)    not null,
	  value     nvarchar(max)   NULL,
	  displayOrder nvarchar(2)  NULL,
    CONSTRAINT [PK_datatools_iiif_metadata] PRIMARY KEY CLUSTERED 
    (
      [cmstype] ASC,
      [cmsid] ASC,
      [label] ASC
    )
    WITH 
    (
      PAD_INDEX = OFF, 
      STATISTICS_NORECOMPUTE = OFF, 
      IGNORE_DUP_KEY = OFF, 
      ALLOW_ROW_LOCKS = ON, 
      ALLOW_PAGE_LOCKS = ON
    ) ON [PRIMARY]
  ) ON [PRIMARY] 
  TEXTIMAGE_ON [PRIMARY]
 
  GRANT INSERT, UPDATE, SELECT, DELETE ON dbo.datatools_iiif_metadata TO [PUBLIC]

END
GO

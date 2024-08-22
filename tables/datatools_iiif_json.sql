IF EXISTS (SELECT * FROM sysobjects WHERE type = 'u' AND name = 'datatools_iiif_json')
BEGIN
  RAISERROR ('datatools_iiif_json table already exists', 16, 1) with nowait
  RETURN
END
ELSE
BEGIN

  CREATE TABLE dbo.datatools_iiif_json
  (
    cmstype       [nchar](3) NOT NULL,
    cmsid         [int] NOT NULL,
    content       [nvarchar](max) NOT NULL,
    modifiedDate  [datetime] NOT NULL,
    enteredDate   [datetime] NOT NULL,
    CONSTRAINT [PK_datatools_iiif_json] PRIMARY KEY CLUSTERED 
    (
      [cmstype] ASC,
      [cmsid] ASC
    )
    WITH 
    (
      PAD_INDEX = OFF, 
      STATISTICS_NORECOMPUTE = OFF, 
      IGNORE_DUP_KEY = OFF, 
      ALLOW_ROW_LOCKS = ON, 
      ALLOW_PAGE_LOCKS = ON
    ) 
    ON [PRIMARY]
  ) 
  ON [PRIMARY] 
  TEXTIMAGE_ON [PRIMARY]

  GRANT INSERT, UPDATE, SELECT, DELETE ON dbo.datatools_iiif_json TO [PUBLIC]

END
GO



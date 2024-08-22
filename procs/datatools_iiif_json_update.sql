/*
 * datatools_iiif_json_update
 *
 */
IF EXISTS (SELECT * FROM sysobjects WHERE type = 'p' AND name = 'datatools_iiif_json_update')
BEGIN
  DROP PROC datatools_iiif_json_update
END
GO

CREATE PROC datatools_iiif_json_update (@lastSuccessfulUpdate datetime)
AS
BEGIN
  SET NOCOUNT ON

    CREATE TABLE dbo.#yuagJSON_Temp
    (
      cmstype nchar(3),
      cmsid int NOT NULL,
      newjson nvarchar(max)
    )

    /* INSERT rows INTO TEMP containing:  'obj', objectId, <json label/value array>, <json homepage object>  */
    INSERT INTO dbo.#yuagJSON_Temp
      (cmstype, cmsid, newjson) 
    SELECT 
      'obj', 
      O3.OBJECTID, 
      (
        SELECT 
          'YUAG' as 'unit', 
          'obj' as 'cmsType', 
          cast(O2.ObjectID as nvarchar(25)) as 'cmsId', 
          (
            SELECT 
              m.label, 
              m.value
            FROM datatools_iiif_metadata m
            WHERE m.cmsid=o2.objectid 
            AND m.cmstype='obj'
            ORDER BY m.displayorder
            FOR JSON AUTO
          ) metadata,
          (
            SELECT 
              'https://artgallery.yale.edu/collections/objects/'+CAST(O3.objectid as Varchar) as 'id',
              'catalog entry at the Yale University Art Gallery' as 'label'
            FROM Objects O3
            WHERE O3.objectid = O2.Objectid and O3.DepartmentID not in (88,92)
            FOR JSON AUTO
          ) homepage
        FROM Objects O2
        WHERE O2.ObjectID=O3.Objectid
        FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER
      )
    FROM Objects O3 
    INNER JOIN datatools_iiif_audittrail A on O3.objectid=A.cmsid
    WHERE A.cmstype='obj'


    ------- EXHIBITIONS-----------------------

    /* INSERT rows INTO TEMP containing: 'exb', exhibitionId, <json label/value array> */
    INSERT INTO dbo.#yuagJSON_Temp
      (cmstype, cmsid, newjson) 
    SELECT 
      'exb',
      E.ExhibitionID, 
      (
        SELECT 
          'YUAG' as 'unit', 
          'exb' as 'cmsType', 
          cast(E2.ExhibitionID as nvarchar(25)) as 'cmsId', 
          (
            SELECT 
              E3.label, 
              E3.value
            FROM datatools_iiif_metadata E3
            WHERE E3.cmsid = E2.ExhibitionID 
              AND E3.cmstype='exb'
            ORDER BY E3.displayorder
            FOR JSON AUTO
          ) metadata
        FROM Exhibitions E2 
        WHERE E2.ExhibitionID = E.ExhibitionID
        FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER
      )
    FROM Exhibitions E 
    INNER JOIN datatools_iiif_audittrail A on E.ExhibitionID=A.cmsid
    WHERE A.cmstype='exb'

    ------- DOC CMS-----------------------

    /* INSERT rows INTO TEMP containing: 'doc', doc cms id, <json label/value array> */
    INSERT INTO dbo.#yuagJSON_Temp
      (cmstype, cmsid, newjson) 
    SELECT 
      'doc',
      d.id,
      (
        SELECT 
          'YUAG' as 'unit', 
          'doc' as 'cmsType', 
          cast(d2.id as nvarchar(25)) as 'cmsId', 
          (
            SELECT 
              m.label, 
              m.value
            FROM datatools_iiif_metadata m
            WHERE m.cmsid = d2.id
              AND m.cmstype='doc'
            ORDER BY m.displayorder
            FOR JSON AUTO
          ) metadata
        FROM MediaTools_DocCMS d2
        WHERE d2.id = d.id
        FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER
      )
    FROM MediaTools_DocCMS d
    JOIN datatools_iiif_audittrail A on d.id=A.cmsid
    WHERE A.cmstype='doc'


    /* UPDATE json table from TEMP for all cms types */

    UPDATE datatools_iiif_json
    SET 
      content = T.newjson, 
      modifiedDate = getdate()
    FROM dbo.#yuagJSON_Temp T 
    INNER JOIN datatools_iiif_json O on T.cmsid=O.cmsID AND T.cmstype='obj' AND O.cmstype='obj'

    UPDATE datatools_iiif_json
    SET 
      content = T.newjson, 
      modifiedDate = getdate()
    FROM dbo.#yuagJSON_Temp T 
    INNER JOIN datatools_iiif_json O on T.cmsid=O.cmsID AND T.cmstype='exb' AND O.cmstype='exb'

    UPDATE datatools_iiif_json
    SET 
      content = T.newjson, 
      modifiedDate = getdate()
    FROM dbo.#yuagJSON_Temp T 
    INNER JOIN datatools_iiif_json j on T.cmsid=j.cmsID AND T.cmstype='doc' AND j.cmstype='doc'

  SET NOCOUNT OFF
END
GO

GRANT EXEC ON datatools_iiif_json_update TO PUBLIC
GO
    
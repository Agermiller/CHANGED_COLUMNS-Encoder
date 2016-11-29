/*The intent of this script is to provide a manual alternative to the COLUMNS_UPDATED()
function typically found in SQL triggers. This script will allow you to generate a binary string
using the provided column ids of the table which was updated.*/

DECLARE @colsTable TABLE([Column_ID] INT);

/*Insert the the ID numbers of the updated columns to @colsTable, then execute the script.
Column ID information can be found using 
SELECT c.column_id, c.* FROM sys.columns as c WHERE c.object_id = <your_table's_objectid>;*/

INSERT INTO @colsTable VALUES (1), (2), (3), (7), (9), (12), (15), (23)

DECLARE @incr SMALLINT = 1;
DECLARE @totalBytes TINYINT = 1;
DECLARE @counter TINYINT = 8
DECLARE @two_nth SMALLINT = 1;
DECLARE @byteTotal SMALLINT = 0;
DECLARE @bytePiece BINARY(1);
DECLARE @binOutput VARBINARY(127) = 0x;

WHILE @totalBytes < 128 
BEGIN 
  WHILE @counter > 0
  BEGIN
    IF EXISTS (SELECT 1 FROM @colsTable WHERE Column_ID = @incr)
    BEGIN
      SELECT @byteTotal = @byteTotal + @two_nth
    END
    SELECT @incr += 1, @counter -= 1, @two_nth *= 2;
  END
  
  SELECT @bytePiece = CONVERT(BINARY(1), @byteTotal);
  SELECT @binOutput = CONVERT(VARBINARY(128), @binOutput + @bytePiece);
  
  SELECT @counter = 8, @two_nth = 1, @totalBytes += 1, @byteTotal = 0;
END

SELECT @binOutput AS 'COLUMNS_UPDATED'
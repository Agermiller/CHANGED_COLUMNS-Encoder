# CHANGED_COLUMNS-Encoder
A SQL query which mimics the behavior of the CHANGED_COLUMNS() function.

##Decoding CHANGED_COLUMNS()
In an attempt to make sense of how to read the binary string produced by the CHANGED_COLUMNS() function, I discovered a post by Slava Murygin. He provided SQL which could be included within a trigger, which would output the column names that were updated in a specific table. His post can be found [here](http://slavasql.blogspot.com/2015/08/decoding-columnsupdated-function.html).

I've slightly modified his SQL to better fit my needs. The below query can take a specific binary string obtained from an audit table, and the name of the root table which uses the trigger with CHANGED_COLUMNS(). *Please keep in mind that the below SQL belongs to Slava. I am simply altering it and showing it here for reference.*

```SQL
USE <database_name>

/* Insert the binary coded list of changed columns, and the table which to search.
256 characters MAX following the 0x. This is a random example for a table with 182 columns, thus I will 
only be using ⌈182/4⌉ = 46 characters following the 0x.*/
DECLARE @Changed_Columns BINARY(128) = 0x474940000000000000000000000000000000A0008E0002
DECLARE @roottable VARCHAR(50) = '<enter_table_name>';


DECLARE @i SMALLINT = 1;
DECLARE @k TINYINT = 1;
DECLARE @b TINYINT = 8
DECLARE @m SMALLINT = 1;
DECLARE @objId INT;
DECLARE @t TABLE([Column_ID] INT);

SET @objId =
(
    SELECT TOP 1 object_id FROM [sys].[objects]
    WHERE [name] = @roottable AND [type] = 'U'
);

WHILE @k < 128 
BEGIN
  WHILE @b > 0
  BEGIN
    IF CAST(SUBSTRING(@Changed_Columns,@k,1) as SMALLINT) & @m = @m 
      INSERT INTO @t(Column_ID) VALUES (@i);
    SELECT @i += 1, @b -= 1, @m *= 2;
  END
  SELECT @b = 8, @m = 1, @k += 1;
END

/* Extract list of the fields which were updated */
SELECT c.column_id, c.*
FROM sys.columns as c
INNER JOIN @t as t ON t.column_id = c.column_id
WHERE c.object_id = @objId;
```

##Encoding Columns
After seeing what the above SQL could do, I pondered how to create a query which could perform the opposite behavior. The query in this repository does just that. One must provide column ids of the columns which were updated, and the query will output a binary string just like COLUMNS_UPDATED() does.

##Application
This could be useful if a trigger was accidentally disabled. If one knew of a specific row in the table that was updated, could compare it to its former self, and gather a list of columns that were updated, then they should be able to use this query to generate a binary string which could be inserted in to an audit table. Though not an entirely practical script on a large scale, if a trigger did get disabled somehow then this could serve as a bandaid for an already unfortunate situation. 

This solution would come with a few challenging requirements. For one, it would require that all of the columns in a table be diffed with a backed up snapshot of the table to obtain a list of updated columns per row. On top of that, one would only be able to get the latest updates, and any updates performed while the trigger was disabled would be unrecoverable. In the very least, one would be able to capture *something* in the audit table so that some degree of history could be logged during this outage.

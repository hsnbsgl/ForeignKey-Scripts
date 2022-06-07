 
--- SCRIPT TO GENERATE THE DROP SCRIPT OF ALL FOREIGN KEY CONSTRAINTS
DECLARE @ForeignKeyName NVARCHAR(MAX);
DECLARE @ParentTableName NVARCHAR(MAX);
DECLARE @ParentTableSchema NVARCHAR(MAX);

DECLARE @SQL NVARCHAR(MAX);

DECLARE curFK CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
SELECT fk.name ForeignKeyName,
       SCHEMA_NAME(t.schema_id) ParentTableSchema,
       t.name ParentTableName
FROM sys.foreign_keys fk
    INNER JOIN sys.tables t ON fk.parent_object_id = t.object_id
WHERE fk.is_ms_shipped=0;

OPEN curFK;
FETCH NEXT FROM curFK
INTO @ForeignKeyName, @ParentTableSchema, @ParentTableName;
WHILE (@@FETCH_STATUS = 0)
BEGIN
    SET @SQL
        = N'ALTER TABLE ' + QUOTENAME(@ParentTableSchema) + N'.' + QUOTENAME(@ParentTableName) + N' DROP CONSTRAINT '
          + QUOTENAME(@ForeignKeyName) + N';' + CHAR(13) + CHAR(10) + N'GO';

    PRINT @SQL;

    FETCH NEXT FROM curFK
    INTO @ForeignKeyName, @ParentTableSchema, @ParentTableName;
END;
CLOSE curFK;
DEALLOCATE curFK;
 
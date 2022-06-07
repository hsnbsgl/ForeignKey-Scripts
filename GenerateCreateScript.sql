--- SCRIPT TO GENERATE THE CREATION SCRIPT OF ALL FOREIGN KEY CONSTRAINTS (ADDED REFERENCIAL ACTIONS)
DECLARE @ForeignKeyID INT;
DECLARE @ForeignKeyName NVARCHAR(MAX);
DECLARE @ParentTableName NVARCHAR(MAX);
DECLARE @ParentColumn NVARCHAR(MAX);
DECLARE @ReferencedTable NVARCHAR(MAX);
DECLARE @ReferencedColumn NVARCHAR(MAX);
DECLARE @StrParentColumn NVARCHAR(MAX);
DECLARE @StrReferencedColumn NVARCHAR(MAX);
DECLARE @ParentTableSchema NVARCHAR(MAX);
DECLARE @ReferencedTableSchema NVARCHAR(MAX);
DECLARE @SQL NVARCHAR(MAX);
DECLARE @deleterefencialAction TINYINT;
DECLARE @updaterefencialAction TINYINT;
DECLARE @deleterefencialActionDesc NVARCHAR(60);
DECLARE @updaterefencialActionDesc NVARCHAR(60);

--Written by Percy Reyes www.percyreyes.com
DECLARE CursorFK CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
SELECT object_id 
FROM sys.foreign_keys WHERE is_ms_shipped=0;
OPEN CursorFK;
FETCH NEXT FROM CursorFK
INTO @ForeignKeyID;
WHILE (@@FETCH_STATUS = 0)
BEGIN
    SET @StrParentColumn = '';
    SET @StrReferencedColumn = '';
    DECLARE CursorFKDetails CURSOR FOR
    SELECT fk.name ForeignKeyName,
           SCHEMA_NAME(t1.schema_id) ParentTableSchema,
           OBJECT_NAME(fkc.parent_object_id) ParentTable,
           c1.name ParentColumn,
           SCHEMA_NAME(t2.schema_id) ReferencedTableSchema,
           OBJECT_NAME(fkc.referenced_object_id) ReferencedTable,
           c2.name ReferencedColumn,
           fk.delete_referential_action,
           fk.update_referential_action,
           fk.delete_referential_action_desc,
           fk.update_referential_action_desc
    FROM sys.foreign_keys fk
        INNER JOIN sys.foreign_key_columns fkc
            ON fk.object_id = fkc.constraint_object_id
        INNER JOIN sys.columns c1
            ON c1.object_id = fkc.parent_object_id
               AND c1.column_id = fkc.parent_column_id
        INNER JOIN sys.columns c2
            ON c2.object_id = fkc.referenced_object_id
               AND c2.column_id = fkc.referenced_column_id
        INNER JOIN sys.tables t1
            ON t1.object_id = fkc.parent_object_id
        INNER JOIN sys.tables t2
            ON t2.object_id = fkc.referenced_object_id
    WHERE fk.object_id = @ForeignKeyID;
    OPEN CursorFKDetails;
    FETCH NEXT FROM CursorFKDetails
    INTO @ForeignKeyName, @ParentTableSchema, @ParentTableName,@ParentColumn, @ReferencedTableSchema,@ReferencedTable,
         @ReferencedColumn,@deleterefencialAction,@updaterefencialAction,@deleterefencialActionDesc,@updaterefencialActionDesc;
    WHILE (@@FETCH_STATUS = 0)
    BEGIN
        SET @StrParentColumn = @StrParentColumn + ', ' + QUOTENAME(@ParentColumn);
        SET @StrReferencedColumn = @StrReferencedColumn + ', ' + QUOTENAME(@ReferencedColumn);

        FETCH NEXT FROM CursorFKDetails
        INTO @ForeignKeyName, @ParentTableSchema, @ParentTableName,@ParentColumn, @ReferencedTableSchema,@ReferencedTable,
         @ReferencedColumn,@deleterefencialAction,@updaterefencialAction,@deleterefencialActionDesc,@updaterefencialActionDesc;
    END;
    CLOSE CursorFKDetails;
    DEALLOCATE CursorFKDetails;

    SET @StrParentColumn = SUBSTRING(@StrParentColumn, 2, LEN(@StrParentColumn) - 1);
    SET @StrReferencedColumn = SUBSTRING(@StrReferencedColumn, 2, LEN(@StrReferencedColumn) - 1);
    SET @SQL
        = 'ALTER TABLE ' + QUOTENAME(@ParentTableSchema) + '.' + QUOTENAME(@ParentTableName)
          + ' WITH CHECK ADD CONSTRAINT ' + QUOTENAME(@ForeignKeyName) + ' FOREIGN KEY(' + LTRIM(@StrParentColumn)
          + ') ' + CHAR(13) + CHAR(10) + 'REFERENCES ' + QUOTENAME(@ReferencedTableSchema) + '.' + QUOTENAME(@ReferencedTable)
          + ' (' + LTRIM(@StrReferencedColumn) + ') '
          + IIF(@deleterefencialAction = 1, CHAR(13) + CHAR(10) + 'ON DELETE ' + @deleterefencialActionDesc, '')
          + IIF(@updaterefencialAction = 1, CHAR(13) + CHAR(10) + 'ON UPDATE ' + @updaterefencialActionDesc, '')
          + CHAR(13) + CHAR(10) + ' GO';

    PRINT @SQL;

    FETCH NEXT FROM CursorFK
    INTO @ForeignKeyID;
END;
CLOSE CursorFK;
DEALLOCATE CursorFK;
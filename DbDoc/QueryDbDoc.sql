
/*
Created by oscar_b
Date: 07/07/2019
Obs: The final result set should be pasted into a HTML file.
*/

--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--Phase 1: Generation Tables
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||


DECLARE   @FLG_VALUES_EXAMPLES BIT = 090
		 ,@DATABASE			   VARCHAR(500)

SET @DATABASE = DB_NAME()

--===================================================
--1.1) - Deleting Tables used
--===================================================

DROP TABLE IF EXISTS ##DATABASE_PART1
DROP TABLE IF EXISTS ##DATABASE_PART2
DROP TABLE IF EXISTS ##DATABASE_PART3
DROP TABLE IF EXISTS ##DOCUMENTATION_INDEX_PART1
DROP TABLE IF EXISTS ##SCHEMA_PART1
DROP TABLE IF EXISTS ##TABLES_VIEWS_PART1
DROP TABLE IF EXISTS ##TABLES_VIEWS_PART2
DROP TABLE IF EXISTS ##TABLES_VIEWS_COLUMNS_PART1
DROP TABLE IF EXISTS ##TABLES_VIEWS_CONSTRAINT_PART1
DROP TABLE IF EXISTS ##TABLES_VIEWS_CONSTRAINT_PART2
DROP TABLE IF EXISTS ##TABLES_VIEWS_INDEX_PART1
DROP TABLE IF EXISTS ##PROCS_PART1
DROP TABLE IF EXISTS ##PROCS_PART2
DROP TABLE IF EXISTS ##PROCS_PART3
DROP TABLE IF EXISTS ##FUNCTIONS_PARTE1
DROP TABLE IF EXISTS ##FUNCTIONS_PARTE2
DROP TABLE IF EXISTS ##FUNCTIONS_PARTE3
DROP TABLE IF EXISTS ##FUNCTIONS_PARTE4
DROP TABLE IF EXISTS ##TABLES_VIEWS_TRIGGER_PART1
DROP TABLE IF EXISTS ##HTML_FINAL

--===================================================
--1.2) Tables about Databases
--===================================================
--Part1
DECLARE @spaceUsed TABLE (
	 DATABASE_NAME		VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,DATABASE_SIZE		VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,UNALLOCATED_SPACE	VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,RESERVED			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,DATA				VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,INDEX_SIZE			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,UNUSED				VARCHAR(2000) COLLATE Latin1_General_CI_AS
)

INSERT INTO @spaceUsed
exec sp_spaceused  @oneresultset = 1

--AuxPart1
DECLARE @sqlperf TABLE (
	 DATABASE_NAME			 VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,LOG_SIZE_MB			 VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,[LOG_SIZE_SPACE_USED_%] VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,STATUS				 	 VARCHAR(2000) COLLATE Latin1_General_CI_AS
)

INSERT INTO @sqlperf
EXEC ('DBCC SQLPERF(logspace)') 

--Part1
SELECT 
	 B.DATABASE_NAME
	,CREATE_DATE = CONVERT(VARCHAR(2000), A.CREATE_DATE, 111)				COLLATE Latin1_General_CI_AS
	,CREATE_TIME = CONVERT(VARCHAR(2000), CONVERT(TIME(0), A.CREATE_DATE))	COLLATE Latin1_General_CI_AS
	,COLLATION = CONVERT(VARCHAR(2000), A.COLLATION_NAME)					COLLATE Latin1_General_CI_AS
	,RECOVERY_MODEL = CONVERT(VARCHAR(2000), A.RECOVERY_MODEL)				COLLATE Latin1_General_CI_AS
	,COMPATIBILITY_LEVEL = CONVERT(VARCHAR(2000), A.COMPATIBILITY_LEVEL)	COLLATE Latin1_General_CI_AS
	,B.DATABASE_SIZE
	,B.UNALLOCATED_SPACE
	,B.RESERVED
	,B.DATA
	,B.INDEX_SIZE
	,B.UNUSED
	,C.LOG_SIZE_MB			
	,C.[LOG_SIZE_SPACE_USED_%]
	INTO ##DATABASE_PART1
	FROM SYS.DATABASES A
	INNER JOIN @spaceUsed B ON A.NAME = B.DATABASE_NAME
	LEFT JOIN  @sqlperf   C ON A.NAME = C.DATABASE_NAME
	WHERE A.NAME = DB_NAME()

--Part2
BEGIN
	WITH PART2 AS (
	SELECT 
		 FILENAME		= ISNULL(NAME, 'Total')									
		,CURRENTSIZEMB	= SUM(CONVERT(DECIMAL(30,2), size/128.0))							
		,FREESPACEMB	= SUM(CONVERT(decimal(30,2), size/128.0 
							- CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0))		
		FROM sys.database_files
		GROUP BY GROUPING SETS ( (NAME), ())
	)
	SELECT 
	 FILENAME		= FILENAME									COLLATE Latin1_General_CI_AS
	,CURRENTSIZEMB	= CONVERT(VARCHAR(MAX), CURRENTSIZEMB)		COLLATE Latin1_General_CI_AS
	,FREESPACEMB	= CONVERT(VARCHAR(MAX), FREESPACEMB)		COLLATE Latin1_General_CI_AS
	INTO ##DATABASE_PART2
	FROM PART2
END


--Part3
SELECT ATTRIBUTE, [VALUE]
	INTO ##DATABASE_PART3
	FROM ##DATABASE_PART1 A
	UNPIVOT ([VALUE] FOR ATTRIBUTE IN 
	(DATABASE_NAME, CREATE_DATE, CREATE_TIME, COLLATION, RECOVERY_MODEL, COMPATIBILITY_LEVEL
	,DATABASE_SIZE, UNALLOCATED_SPACE, RESERVED, DATA, INDEX_SIZE, UNUSED
	,LOG_SIZE_MB, [LOG_SIZE_SPACE_USED_%])
	) UNPVT

--===================================================
--1.3) Table about Documentation Index
--===================================================
SELECT 
	 ROW_ORDER = CONVERT(INT, NULL) 
	,TYPE	= CONVERT(VARCHAR(2000),
				CASE A.type_desc	WHEN 'USER_TABLE'						THEN 'Table'
									WHEN 'VIEW'								THEN 'View' 
									WHEN 'SQL_STORED_PROCEDURE'				THEN 'Procedure' 
									WHEN 'SQL_INLINE_TABLE_VALUED_FUNCTION'	THEN 'Inline Table-Valued Function'
									WHEN 'SQL_SCALAR_FUNCTION'				THEN 'Scalar Function' 
									WHEN 'SQL_TABLE_VALUED_FUNCTION'		THEN 'Table-Valued Function' 
									WHEN 'SQL_TRIGGER'						THEN 'Trigger' 
									END)						   COLLATE Latin1_General_CI_AS
	,TYPE_DESC		= CONVERT(VARCHAR(2000), A.TYPE_DESC)		   COLLATE Latin1_General_CI_AS
	,SCHEMA_NAME	= CONVERT(VARCHAR(2000), B.name)			   COLLATE Latin1_General_CI_AS
	,OBJECT_ID		= CONVERT(VARCHAR(2000), A.object_id)		   COLLATE Latin1_General_CI_AS
	,NAME			= CONVERT(VARCHAR(2000), A.name)			   COLLATE Latin1_General_CI_AS
	,COMPLETE_NAME	= CONVERT(VARCHAR(2000), B.name + '.' +A.name) COLLATE Latin1_General_CI_AS
	,CREATE_DATE	= CONVERT(VARCHAR(2000), A.CREATE_DATE, 111)   COLLATE Latin1_General_CI_AS
	,CREATE_TIME	= CONVERT(VARCHAR(2000), CONVERT(TIME(0), A.CREATE_DATE))	COLLATE Latin1_General_CI_AS
	INTO ##DOCUMENTATION_INDEX_PART1
	FROM SYS.objects A
	INNER JOIN sys.schemas B ON A.schema_id = B.schema_id
	WHERE B.SCHEMA_ID NOT IN 
		(2,3,4,16384,16385,16386,16387,16389,16390,16391,16392,16393)
		AND A.type_desc IN 
		('SQL_INLINE_TABLE_VALUED_FUNCTION','SQL_SCALAR_FUNCTION', 'SQL_STORED_PROCEDURE'
		,'SQL_TABLE_VALUED_FUNCTION', 'SQL_TRIGGER', 'USER_TABLE', 'VIEW')

--Updte Complete Name from Triggers (schema + table + trigger name)
UPDATE A
	SET A.COMPLETE_NAME = A.SCHEMA_NAME + '.' + C.NAME + '.' + A.NAME
	FROM ##DOCUMENTATION_INDEX_PART1 A
	INNER JOIN SYS.OBJECTS B ON A.OBJECT_ID = B.OBJECT_ID
	INNER JOIN ##DOCUMENTATION_INDEX_PART1 C ON B.PARENT_OBJECT_ID = C.OBJECT_ID
	WHERE A.TYPE = 'Trigger'  

--===================================================
--1.4) Table about Schemas
--===================================================
SELECT
	 SCHEMA_NAME = ISNULL(A.NAME, 'Total')
	,QTD_USER_TABLE					= SUM(CASE WHEN B.TYPE_DESC  = 'USER_TABLE'							THEN 1 ELSE 0 END)
	,QTD_STORED_PROCEDURE			= SUM(CASE WHEN B.TYPE_DESC  = 'SQL_STORED_PROCEDURE'				THEN 1 ELSE 0 END)
	,QTD_VIEW						= SUM(CASE WHEN B.TYPE_DESC  = 'VIEW'								THEN 1 ELSE 0 END)
	,QTD_TRIGGER					= SUM(CASE WHEN B.TYPE_DESC  = 'SQL_TRIGGER'						THEN 1 ELSE 0 END)
	,QTD_TABLE_VALUED_FUNCTION		= SUM(CASE WHEN B.TYPE_DESC  = 'SQL_TABLE_VALUED_FUNCTION'			THEN 1 ELSE 0 END)
	,QTD_SCALAR_FUNCTION			= SUM(CASE WHEN B.TYPE_DESC  = 'SQL_SCALAR_FUNCTION'				THEN 1 ELSE 0 END)
	,QTD_INLINE_TABLE_VALUED_FUNCTION= SUM(CASE WHEN B.TYPE_DESC = 'SQL_INLINE_TABLE_VALUED_FUNCTION'	THEN 1 ELSE 0 END)
	INTO ##SCHEMA_PART1
	FROM sys.schemas A
	INNER JOIN SYS.objects B ON A.schema_id = B.schema_id
	WHERE A.SCHEMA_ID NOT IN 
		(2,3,4,16384,16385,16386,16387,16389,16390,16391,16392,16393)
		AND B.type_desc IN 
		('SQL_INLINE_TABLE_VALUED_FUNCTION','SQL_SCALAR_FUNCTION', 'SQL_STORED_PROCEDURE'
		,'SQL_TABLE_VALUED_FUNCTION', 'SQL_TRIGGER', 'TYPE_TABLE', 'USER_TABLE', 'VIEW')
	GROUP BY GROUPING SETS ( (A.NAME), ())

--===================================================
--1.5) Table about Tables (that is not necessary to perform a loop)
--===================================================
SELECT DISTINCT
	 A.TYPE		
	,A.SCHEMA_NAME
	,A.OBJECT_ID
	,A.NAME			
	,A.COMPLETE_NAME
	,A.CREATE_DATE
	,A.CREATE_TIME
	,ROWS			= C.ROWS
	,ROWS_TEXT		= CONVERT(VARCHAR(2000), C.ROWS)			   COLLATE Latin1_General_CI_AS
	,ROWS_CATEGORY	= CONVERT(VARCHAR(2000), NULL)				   COLLATE Latin1_General_CI_AS
	,DATA_LOCATED_ON_FILEGROUP = CONVERT(VARCHAR(2000), NULL)	   COLLATE Latin1_General_CI_AS
	INTO ##TABLES_VIEWS_PART1
	FROM ##DOCUMENTATION_INDEX_PART1 A
	LEFT JOIN SYS.PARTITIONS C ON A.OBJECT_ID = C.OBJECT_ID
	WHERE A.type_desc IN ('USER_TABLE', 'VIEW')

--Update DATA_LOCATED_ON_FILEGROUP
UPDATE A
	SET A.DATA_LOCATED_ON_FILEGROUP = ISNULL(C.name, 'not applicable') 
	FROM ##TABLES_VIEWS_PART1 A
	LEFT JOIN SYS.INDEXES B ON A.OBJECT_ID = B.object_id
							AND B.INDEX_ID < 2
	LEFT JOIN SYS.DATA_SPACES C ON B.DATA_SPACE_ID = C.DATA_SPACE_ID

--Update Table Category (Paretto Rule applied to table qty of rows)
BEGIN 
	WITH ROWS_CATEGORY_1 AS (
	SELECT 
		ROWS_PERCENT_1 = CONVERT(DECIMAL(10,3), (100.0 * ROWS / SUM(ROWS) OVER()))
		,*
		FROM ##TABLES_VIEWS_PART1 A
		WHERE TYPE = 'Table'
	),
	ROWS_CATEGORY_2 AS (
	SELECT 
		ROWS_PERCENT_2 = DENSE_RANK() OVER(ORDER BY ROWS_PERCENT_1 DESC)
		,*
		FROM ROWS_CATEGORY_1
	),
	ROWS_CATEGORY_3 AS (
	SELECT
		 ROWS_PERCENT_3 =( A.ROWS_PERCENT_2 * 100.0) / B.MAX_ROW_PERCENT_2
		,*
		FROM ROWS_CATEGORY_2 A
		CROSS APPLY(SELECT MAX_ROW_PERCENT_2 = MAX(ROWS_PERCENT_2)
						FROM  ROWS_CATEGORY_2) B
	)
	UPDATE ROWS_CATEGORY_3
		SET ROWS_CATEGORY = CASE WHEN ROWS_PERCENT_3 <= 20.0 THEN 'Category A - Big Tables'
							     WHEN ROWS_PERCENT_3 <= 50.0 THEN 'Category B - Medium Tables'
														     ELSE 'Category C - Small Tables' END
END

--Table Columns Part1
SELECT
	 A.object_id
	,B.SCHEMA_NAME
	,B.NAME
	,B.COMPLETE_NAME
	,COLUMN_NAME = A.name
	,A.COLUMN_ID
	,TYPE = C.name
	,LENGTH = A.max_length
	,PRECISION = A.PRECISION
	,SCALE = A.SCALE
	,NULLABLE = CASE WHEN A.is_nullable = 0 THEN 'No' ELSE 'Yes' END
	,COLLATION = A.collation_name
	,IS_IDENTITY = CASE WHEN A.is_identity = 0 THEN 'No' ELSE 'Yes' END
	,IDENTITY_SEED = D.seed_value
	,IDENTITY_INCREMENT = D.increment_value
	,IDENTITY_NOT_FOR_REPLICATION = D.is_not_for_replication
	,IS_ROWGUIDCOL = CASE WHEN A.is_rowguidcol = 0 THEN 'No' ELSE 'Yes' END
	,VALUES_EXAMPLES = CONVERT(VARCHAR(MAX), NULL)
	INTO ##TABLES_VIEWS_COLUMNS_PART1
	FROM SYS.COLUMNS A
	INNER JOIN ##TABLES_VIEWS_PART1 B ON A.object_id = B.OBJECT_ID
	LEFT JOIN SYS.types C ON A.user_type_id = C.user_type_id
	LEFT JOIN SYS.identity_columns D ON A.object_id = D.object_id
									AND A.column_id = D.column_id




--Table Constraints
select  
	 OBJECT_ID = referenced_object_id
	,[Table is referenced by foreign key] =  
	db_name() + '.'  
		+ rtrim(schema_name(ObjectProperty(parent_object_id,'schemaid')))  
		+ '.' + object_name(parent_object_id)  
		+ ': ' + object_name(object_id) 
   INTO	##TABLES_VIEWS_CONSTRAINT_PART1
   FROM SYS.FOREIGN_KEYS 

--================================================================================
--1.5.1) Table columns value examples on columns
--================================================================================
IF @FLG_VALUES_EXAMPLES  = 1
BEGIN

DECLARE  @CVE_OBJECT_ID INT
		,@CVE_COMPLETE_NAME VARCHAR(MAX)
		,@CVE_COLUMN_NAME VARCHAR(MAX)
		,@CVE_QUERY AS NVARCHAR(MAX)
		,@CVE_DYNAMICPARAMDEC AS NVARCHAR(MAX)
		,@CVE_VALUES_EXAMPLE VARCHAR(MAX)


--UPDATE A SET VALUES_EXAMPLES = NULL FROM ##TABLES_VIEWS_COLUMNS_PART1  A

--Cursor for each row
DECLARE cursor4 CURSOR FOR
SELECT DISTINCT
	OBJECT_ID
	,COMPLETE_NAME
	,COLUMN_NAME 
	FROM ##TABLES_VIEWS_COLUMNS_PART1
	WHERE TYPE IN  ('bigint','bit','date','datetime','datetime2','decimal'
					,'Flag','int','money','Name','nchar'
					,'nvarchar','numeric','nvarchar','smallint'
					,'smallmoney','sysname','time','tinyint','uniqueidentifier') 
	AND ISNULL(COLLATION, '') NOT IN ('Latin1_General_BIN2')

--Opening Cursor
OPEN cursor4
 
--Reading Line
FETCH NEXT FROM cursor4 INTO @CVE_OBJECT_ID, @CVE_COMPLETE_NAME, @CVE_COLUMN_NAME 

--Reading Lines
WHILE @@FETCH_STATUS = 0
BEGIN


	SET @CVE_QUERY =
	'SELECT @VALORES = (SELECT CONCAT(''|'', [#CVE_COLUMN_NAME])
		FROM (
		SELECT DISTINCT TOP 3 [#CVE_COLUMN_NAME]
			FROM #CVE_TABLE_COMPLETE_NAME
			WHERE TRY_CONVERT(VARCHAR(MAX), [#CVE_COLUMN_NAME]) IS NOT NULL
		) A
		FOR XML PATH(''''))'
	SET @CVE_DYNAMICPARAMDEC = '@VALORES VARCHAR(MAX) OUTPUT'

	SET @CVE_QUERY = REPLACE(@CVE_QUERY, '#CVE_COLUMN_NAME', @CVE_COLUMN_NAME)
	SET @CVE_QUERY = REPLACE(@CVE_QUERY, '#CVE_TABLE_COMPLETE_NAME', @CVE_COMPLETE_NAME)

	EXECUTE SP_EXECUTESQL
		@CVE_QUERY,
		@CVE_DYNAMICPARAMDEC,
		@CVE_VALUES_EXAMPLE OUTPUT

	SET @CVE_VALUES_EXAMPLE = STUFF(@CVE_VALUES_EXAMPLE, 1, 1, '')

	UPDATE A
		SET A.VALUES_EXAMPLES = @CVE_VALUES_EXAMPLE
		FROM ##TABLES_VIEWS_COLUMNS_PART1 A
		WHERE A.object_id = @CVE_OBJECT_ID
			AND A.COMPLETE_NAME = @CVE_COMPLETE_NAME
			AND A.COLUMN_NAME = @CVE_COLUMN_NAME

--Reading next line
FETCH NEXT FROM cursor4 INTO @CVE_OBJECT_ID, @CVE_COMPLETE_NAME, @CVE_COLUMN_NAME 
END
 
-- Closing Cursor
CLOSE cursor4
 
--Ending Cursor
DEALLOCATE cursor4

END

--================================================================================
--1.6) Table about Procedures
--================================================================================
--Part1
 select distinct
 	 A.TYPE			
	,A.SCHEMA_NAME	
	,A.OBJECT_ID
	,A.NAME			
	,A.COMPLETE_NAME
	,A.CREATE_DATE	
	,A.CREATE_TIME	
	INTO ##PROCS_PART1
	FROM ##DOCUMENTATION_INDEX_PART1 A
	WHERE TYPE = 'Procedure'

--Part2
 select distinct
   'Param_order'	= b.parameter_id,  
	A.OBJECT_ID,
	A.COMPLETE_NAME,
   'Parameter_name' = CASE WHEN b.name = '' THEN 'Output' ELSE b.name END,  
   'Type'			= type_name(b.user_type_id),  
   'Length'			= b.max_length,  
   'Prec'			= case  when type_name(b.system_type_id) = 'uniqueidentifier' then precision  
							else OdbcPrec(b.system_type_id, b.max_length, precision) end,  
   'Scale'			= OdbcScale(b.system_type_id, b.scale),  
   'Collation'		= convert(sysname, case when b.system_type_id in (35, 99, 167, 175, 231, 239)  
					  then ServerProperty('collation') end)  
  INTO ##PROCS_PART2
  from ##PROCS_PART1 a
  inner join sys.all_parameters b on a.object_id = b.object_id


--Parte 3
SELECT OBJECT_ID = OBJECT_ID2, ATTRIBUTE, [VALUE]
	INTO ##PROCS_PART3
	FROM (SELECT *, OBJECT_ID2 = OBJECT_ID FROM ##PROCS_PART1 A) A
	UNPIVOT ([VALUE] FOR ATTRIBUTE IN 
	(TYPE, SCHEMA_NAME, OBJECT_ID, NAME, COMPLETE_NAME
	,CREATE_DATE, CREATE_TIME)
	) UNPVT


--================================================================
--1.7) Table about Functions
--================================================================
--Part1
SELECT DISTINCT
	 A.TYPE			
	,A.SCHEMA_NAME	
	,A.OBJECT_ID		
	,A.NAME			
	,A.COMPLETE_NAME	
	,A.CREATE_DATE	
	,A.CREATE_TIME	
	INTO ##FUNCTIONS_PARTE1
	FROM ##DOCUMENTATION_INDEX_PART1 A
	WHERE A.type_desc IN ('SQL_INLINE_TABLE_VALUED_FUNCTION','SQL_SCALAR_FUNCTION'
		,'SQL_TABLE_VALUED_FUNCTION')

--Part2
 select distinct
   'Param_order'	= b.parameter_id,  
	A.OBJECT_ID,
	FUNCTION_TYPE = A.TYPE,
	A.COMPLETE_NAME,
   'Parameter_name' = CASE WHEN b.name = '' THEN 'Output' ELSE b.name END,   
   'Type'			= type_name(b.user_type_id),  
   'Length'			= b.max_length,  
   'Prec'			= case  when type_name(b.system_type_id) = 'uniqueidentifier' then precision  
							else OdbcPrec(b.system_type_id, b.max_length, precision) end,  
   'Scale'			= OdbcScale(b.system_type_id, b.scale),  
   'Collation'		= convert(sysname, case when b.system_type_id in (35, 99, 167, 175, 231, 239)  
					  then ServerProperty('collation') end)  
  INTO ##FUNCTIONS_PARTE2
  from ##FUNCTIONS_PARTE1 a
  inner join sys.all_parameters b on a.object_id = b.object_id

--Part3
SELECT
	 A.object_id
	,FUNCTION_TYPE = B.TYPE
	,B.SCHEMA_NAME
	,B.NAME
	,B.COMPLETE_NAME
	,COLUMN_NAME = A.name
	,A.COLUMN_ID
	,TYPE = C.name
	,LENGTH = A.max_length
	,PRECISION = A.PRECISION
	,SCALE = A.SCALE
	,NULLABLE = CASE WHEN A.is_nullable = 0 THEN 'No' ELSE 'Yes' END
	,COLLATION = A.collation_name
	,IS_IDENTITY = CASE WHEN A.is_identity = 0 THEN 'No' ELSE 'Yes' END
	,IDENTITY_SEED = D.seed_value
	,IDENTITY_INCREMENT = D.increment_value
	,IDENTITY_NOT_FOR_REPLICATION = D.is_not_for_replication
	,IS_ROWGUIDCOL = CASE WHEN A.is_rowguidcol = 0 THEN 'No' ELSE 'Yes' END
	INTO ##FUNCTIONS_PARTE3
	FROM SYS.COLUMNS A
	INNER JOIN ##FUNCTIONS_PARTE1 B ON A.object_id = B.OBJECT_ID
	LEFT JOIN SYS.types C ON A.user_type_id = C.user_type_id
	LEFT JOIN SYS.identity_columns D ON A.object_id = D.object_id
									AND A.column_id = D.column_id

--Part4
SELECT OBJECT_ID = OBJECT_ID2, ATTRIBUTE, [VALUE]
	INTO ##FUNCTIONS_PARTE4
	FROM (SELECT *, OBJECT_ID2 = OBJECT_ID FROM ##FUNCTIONS_PARTE1 A) A
	UNPIVOT ([VALUE] FOR ATTRIBUTE IN 
	(TYPE, SCHEMA_NAME, OBJECT_ID, NAME, COMPLETE_NAME
	,CREATE_DATE, CREATE_TIME)
	) UNPVT

--================================================================================
--1.8) Table about Tables (that is necessary to perform a loop)
--================================================================================
--Constraint Part2
CREATE TABLE ##TABLES_VIEWS_CONSTRAINT_PART2 (
	 ARTIFICIAL_ID				INT IDENTITY
	,OBJECT_ID					VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,TABLE_COMPLETE_NAME		VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,CONSTRAINT_TYPE			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,CONSTRAINT_NAME			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,DELETE_ACTION				VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,UPDATE_ACTION				VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,STATUS_ENABLED				VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,STATUS_FOR_REPLICATION		VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,CONSTRAINT_KEYS			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	)

--Index (to receive the output of the proc sys.sp_helpindex)
DECLARE @proc_index TABLE (
	 INDEX_NAME			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,INDEX_DESCRIPTION	VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,INDEX_KEYS			VARCHAR(2000) COLLATE Latin1_General_CI_AS
)

--Index (Append the data of the table @proc_index)
CREATE TABLE ##TABLES_VIEWS_INDEX_PART1 (
	 ARTIFICIAL_ID		INT IDENTITY
	,OBJECT_ID			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,TABLE_COMPLETE_NAME		VARCHAR(2000) COLLATE Latin1_General_CI_AS	
	,INDEX_NAME			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,INDEX_DESCRIPTION	VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,INDEX_KEYS			VARCHAR(2000) COLLATE Latin1_General_CI_AS
)

--Trigger (to receive the output of the proc sys.sp_helptrigger)
DECLARE @proc_trigger TABLE (
	 TRIGGER_NAME		VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,TRIGGER_OWNER		VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,ISUPDATE			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,ISDELETE			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,ISINSERT			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,ISAFTER			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,ISINSTEADOF		VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,TRIGGER_SCHEMA		VARCHAR(2000) COLLATE Latin1_General_CI_AS

)

--Trigger (Append the data of the table @proc_trigger)
CREATE TABLE ##TABLES_VIEWS_TRIGGER_PART1 (
	 ARTIFICIAL_ID		INT IDENTITY
	,OBJECT_ID			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,TABLE_COMPLETE_NAME VARCHAR(2000) COLLATE Latin1_General_CI_AS	
	,TRIGGER_NAME		VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,TRIGGER_OWNER		VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,ISUPDATE			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,ISDELETE			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,ISINSERT			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,ISAFTER			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,ISINSTEADOF		VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,TRIGGER_SCHEMA		VARCHAR(2000) COLLATE Latin1_General_CI_AS
)


CREATE TABLE ##TABLES_VIEWS_PART2 (
	 ARTIFICIAL_ID		INT IDENTITY
	,OBJECT_ID			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,ATTRIBUTE			VARCHAR(2000) COLLATE Latin1_General_CI_AS
	,VALUE				VARCHAR(2000) COLLATE Latin1_General_CI_AS

)

declare @objname   nvarchar(776)
	   ,@type_desc nvarchar(776)
 
--Cursor for each row
DECLARE cursor1 CURSOR FOR
select DISTINCT COMPLETE_NAME, TYPE_DESC 
	from ##DOCUMENTATION_INDEX_PART1
	WHERE TYPE_DESC IN ('USER_TABLE', 'VIEW', 'SQL_INLINE_TABLE_VALUED_FUNCTION', 'SQL_TABLE_VALUED_FUNCTION')
 
--Opening Cursor
OPEN cursor1
 
--Reading Line
FETCH NEXT FROM cursor1 INTO @objname,@type_desc


 
--Reading Lines
WHILE @@FETCH_STATUS = 0
BEGIN

 
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--Table Constraint equivalent to sys.sp_helpconstraint: First Result Set
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
DROP TABLE IF EXISTS #spcnsttab
 set nocount on  

 
 declare @objid   int           -- the object id of the table  
   ,@cnstdes  nvarchar(4000)-- string to build up index desc  
   ,@cnstname  sysname       -- name of const. currently under consideration  
   ,@i    int  
   ,@cnstid  int  
   ,@cnsttype  character(2)  
   ,@keys   nvarchar(2126) --Length (16*max_identifierLength)+(15*2)+(16*3)  
   ,@dbname  sysname  

 select @objid = object_id(@objname)  

 -- Create temp table  
 CREATE TABLE #spcnsttab  
 (  
  cnst_id   int   NOT NULL  
  ,cnst_type   nvarchar(256) collate catalog_default NOT NULL   -- 128 for name + text for DEFAULT  
  ,cnst_name   sysname  collate catalog_default NOT NULL  
  ,cnst_nonblank_name sysname  collate catalog_default NOT NULL  
  ,cnst_2type   character(2) collate catalog_default NULL  
  ,cnst_disabled  bit    NULL  
  ,cnst_notrepl  bit    NULL  
  ,cnst_del_action  int    NULL  
  ,cnst_upd_action  int    NULL  
  ,cnst_keys   nvarchar(2126) collate catalog_default NULL -- see @keys above for length descr  
 )  
  
 -- Check to see that the object names are local to the current database.  
 select @dbname = parsename(@objname,3)  
  
  
 -- STATIC CURSOR OVER THE TABLE'S CONSTRAINTS  
 declare ms_crs_cnst cursor local static for  
  select object_id, type, name from sys.objects where parent_object_id = @objid  
   and type in ('C ','PK','UQ','F ', 'D ') -- ONLY 6.5 sysconstraints objects  
  for read only  
  
 -- Now check out each constraint, figure out its type and keys and  
 -- save the info in a temporary table that we'll print out at the end.  
 open ms_crs_cnst  
 fetch ms_crs_cnst into @cnstid ,@cnsttype ,@cnstname  
 while @@fetch_status >= 0  
 begin  
  
  if @cnsttype in ('PK','UQ')  
  begin  
   -- get indid and index description  
   declare @indid smallint  
   select @indid = i.index_id,  
     @cnstdes = case when @cnsttype = 'PK'  
        then 'PRIMARY KEY' else 'UNIQUE' end  
        + case when index_id = 1  
        then ' (clustered)' else ' (non-clustered)' end  
   from  sys.indexes i join  
      sys.key_constraints k on  
       (  
       k.parent_object_id = i.object_id and k.unique_index_id = i.index_id  
       )  
   where i.object_id = @objid and k.object_id = @cnstid  
  
   -- Format keys string  
   declare @thiskey nvarchar(131) -- 128+3  
  
   select @keys = index_col(@objname, @indid, 1), @i = 2  
   if (indexkey_property(@objid, @indid, 1, 'isdescending') = 1)  
    select @keys = @keys  + '(-)'  
  
   select @thiskey = index_col(@objname, @indid, @i)  
   if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))  
    select @thiskey = @thiskey + '(-)'  
  
   while (@thiskey is not null)  
   begin  
    select @keys = @keys + ', ' + @thiskey, @i = @i + 1  
    select @thiskey = index_col(@objname, @indid, @i)  
    if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))  
     select @thiskey = @thiskey + '(-)'  
   end  
  
   -- ADD TO TABLE  
   insert into #spcnsttab  
    (cnst_id,cnst_type,cnst_name, cnst_nonblank_name,cnst_keys, cnst_2type)  
   values (@cnstid, @cnstdes, @cnstname, @cnstname, @keys, @cnsttype)  
  end  
  
  else  
  if @cnsttype = 'F '  
  begin  
   -- OBTAIN TWO TABLE IDs  
   declare @fkeyid int, @rkeyid int  
   select @fkeyid = parent_object_id, @rkeyid = referenced_object_id  
    from sys.foreign_keys where object_id = @cnstid  
  
   -- USE CURSOR OVER FOREIGN KEY COLUMNS TO BUILD COLUMN LISTS  
   -- (NOTE: @keys HAS THE FKEY AND @cnstdes HAS THE RKEY COLUMN LIST)  
   declare ms_crs_fkey cursor local for  
    select parent_column_id, referenced_column_id  
     from sys.foreign_key_columns where constraint_object_id = @cnstid  
   open ms_crs_fkey  
   declare @fkeycol smallint, @rkeycol smallint  
   fetch ms_crs_fkey into @fkeycol, @rkeycol  
   select @keys = col_name(@fkeyid, @fkeycol), @cnstdes = col_name(@rkeyid, @rkeycol)  
   fetch ms_crs_fkey into @fkeycol, @rkeycol  
   while @@fetch_status >= 0  
   begin  
    select @keys = @keys + ', ' + col_name(@fkeyid, @fkeycol),  
      @cnstdes = @cnstdes + ', ' + col_name(@rkeyid, @rkeycol)  
    fetch ms_crs_fkey into @fkeycol, @rkeycol  
   end  
   deallocate ms_crs_fkey  
  
   -- ADD ROWS FOR BOTH SIDES OF FOREIGN KEY  
   insert into #spcnsttab  
    (cnst_id, cnst_type,cnst_name,cnst_nonblank_name,  
     cnst_keys, cnst_disabled,  
     cnst_notrepl, cnst_del_action, cnst_upd_action, cnst_2type)  
   values  
    (@cnstid, 'FOREIGN KEY', @cnstname, @cnstname,  
     @keys, ObjectProperty(@cnstid, 'CnstIsDisabled'),  
     ObjectProperty(@cnstid, 'CnstIsNotRepl'),  
     ObjectProperty(@cnstid, 'CnstDeleteAction'),  
     ObjectProperty(@cnstid, 'CnstUpdateAction'),  
     @cnsttype)  
   insert into #spcnsttab  
    (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,  
     cnst_keys,  
     cnst_2type)  
   select  
    @cnstid,' ', ' ', @cnstname,  
     'REFERENCES ' + db_name()  
      + '.' + rtrim(schema_name(ObjectProperty(@rkeyid,'schemaid')))  
      + '.' + object_name(@rkeyid) + ' ('+@cnstdes + ')',  
     @cnsttype  
  end  
  
  else  
  if @cnsttype = 'C'  
  begin  
   -- Check constraint  
   select @i = 1  
   select @cnstdes = null  
   select @cnstdes = text from syscomments where id = @cnstid and colid = @i  
  
   insert into #spcnsttab  
    (cnst_id, cnst_type ,cnst_name ,cnst_nonblank_name,  
     cnst_keys, cnst_disabled, cnst_notrepl, cnst_2type)  
   select @cnstid,  
    case when parent_column_id <> 0  
     then 'CHECK on column ' + col_name(@objid, parent_column_id)  
     else 'CHECK Table Level ' end,  
    @cnstname ,@cnstname ,substring(@cnstdes,1,2000),  
    is_disabled, is_not_for_replication,  
    @cnsttype  
   from sys.check_constraints where object_id = @cnstid  
  
   while @cnstdes is not null  
   begin  
    if @i > 1  
     insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
     select @cnstid,' ' ,' ' ,@cnstname ,substring(@cnstdes,1,2000), @cnsttype  
  
    if len(@cnstdes) > 2000  
     insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
     select @cnstid,' ' ,' ' ,@cnstname ,substring(@cnstdes,2001,2000), @cnsttype  
  
    select @i = @i + 1  
    select @cnstdes = null  
    select @cnstdes = text from syscomments where id = @cnstid and colid = @i  
   end  
  end  
  
  else  
  if (@cnsttype = 'D')  
  begin  
   select @i = 1  
   select @cnstdes = null  
   select @cnstdes = text from syscomments where id = @cnstid and colid = @i  
   insert into #spcnsttab  
    (cnst_id,cnst_type ,cnst_name ,cnst_nonblank_name ,cnst_keys, cnst_2type)  
   select @cnstid, 'DEFAULT on column ' + col_name(@objid, parent_column_id),  
    @cnstname ,@cnstname ,substring(@cnstdes,1,2000), @cnsttype  
    from sys.default_constraints where object_id = @cnstid  
  
   while @cnstdes is not null  
   begin  
    if @i > 1  
     insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
     select @cnstid,' ' ,' ' ,@cnstname ,substring(@cnstdes,1,2000), @cnsttype  
  
    if len(@cnstdes) > 2000  
     insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
     select @cnstid,' ' ,' ' ,@cnstname ,substring(@cnstdes,2001,2000), @cnsttype  
  
    select @i = @i + 1  
    select @cnstdes = null  
    select @cnstdes = text from syscomments where id = @cnstid and colid = @i  
   end  
  end  
  
  fetch ms_crs_cnst into @cnstid ,@cnsttype ,@cnstname  
 end  --of major loop  
 deallocate ms_crs_cnst  
  
 -- Find any rules or defaults bound by the sp_bind... method.  
 insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
 select c.rule_object_id,'RULE on column ' + c.name + ' (bound with sp_bindrule)',  
  object_name(c.rule_object_id), object_name(c.rule_object_id), m.text, 'R '  
 from sys.columns c join syscomments m on m.id = c.rule_object_id  
 where c.object_id = @objid  
  
 insert into #spcnsttab (cnst_id,cnst_type,cnst_name,cnst_nonblank_name,cnst_keys, cnst_2type)  
 select c.default_object_id, 'DEFAULT on column ' + c.name + ' (bound with sp_bindefault)',  
  object_name(c.default_object_id),object_name(c.default_object_id), m.text, 'D '  
 from sys.columns c join syscomments m on m.id = c.default_object_id  
 where c.object_id = @objid and objectproperty(c.default_object_id, 'IsConstraint') = 0  
  
  

  
 -- Now print out the contents of the temporary index table.  
 if exists (select * from #spcnsttab)  
 INSERT INTO  ##TABLES_VIEWS_CONSTRAINT_PART2
 (OBJECT_ID, TABLE_COMPLETE_NAME, CONSTRAINT_TYPE, CONSTRAINT_NAME
 ,DELETE_ACTION, UPDATE_ACTION, STATUS_ENABLED, STATUS_FOR_REPLICATION
 ,CONSTRAINT_KEYS)
  select  
	OBJECT_ID = @objid,
	TABLE_COMPLETE_NAME = @objname,
   'constraint_type' = cnst_type,  
   'constraint_name' = cnst_name,  
   'delete_action'=  
     case  
      when cnst_name = ' ' Then ' '  
      when cnst_2type in ('F ') Then  
       case cnst_del_action   
        when 0 Then 'No Action'  
        when 1 Then 'Cascade'   
        when 2 Then 'Set Null'  
        when 3 Then 'Set Default'   
        else 'Not Defined' end  
      else '(n/a)'  
      -- The case statement should be updated manually if 'Not Defined' is shown  
     end,  
   'update_action'=  
     case  
      when cnst_name = ' ' Then ' '  
      when cnst_2type in ('F ') Then  
       case cnst_upd_action   
        when 0 Then 'No Action'  
        when 1 Then 'Cascade'   
        when 2 Then 'Set Null'  
        when 3 Then 'Set Default'   
        else 'Not Defined' end  
      else '(n/a)'  
      -- The case statement should be updated manually if 'Not Defined' is shown  
     end,  
   'status_enabled' =  
     case  
      when cnst_name = ' ' Then ' '  
      when cnst_2type in ('F ','C ') Then  
       case when cnst_disabled = 1  
        then 'Disabled' else 'Enabled' end  
      else '(n/a)'  
     end,  
   'status_for_replication' =  
     case  
      when cnst_name = ' ' Then ' '  
      when cnst_2type in ('F ','C ') Then  
       case when cnst_notrepl = 1  
        Then 'Not_For_Replication' else 'Is_For_Replication' end  
      else '(n/a)'  
     end,  
   'constraint_keys' = cnst_keys  
  from #spcnsttab order by cnst_nonblank_name ,cnst_name desc  



--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--sys.sp_helpindex
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
DELETE FROM @proc_index

insert into @proc_index
exec sys.sp_helpindex @objname

INSERT INTO ##TABLES_VIEWS_INDEX_PART1 
(OBJECT_ID, TABLE_COMPLETE_NAME, INDEX_NAME
,INDEX_DESCRIPTION, INDEX_KEYS)
SELECT 
	OBJECT_ID = @objid
	,TABLE_COMPLETE_NAME = @objname
	,INDEX_NAME			
	,INDEX_DESCRIPTION	
	,INDEX_KEYS			
	FROM @proc_index


--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--sys.sp_helptrigger (only for tables)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
DELETE FROM @proc_trigger

IF @type_desc IN ('USER_TABLE')
BEGIN

	insert into @proc_trigger
	exec sys.sp_helptrigger @objname

	INSERT INTO ##TABLES_VIEWS_TRIGGER_PART1
	(OBJECT_ID, TABLE_COMPLETE_NAME, TRIGGER_NAME, TRIGGER_OWNER, ISUPDATE			
	,ISDELETE, ISINSERT, ISAFTER, ISINSTEADOF, TRIGGER_SCHEMA)
	SELECT 
		OBJECT_ID = @objid
		,TABLE_COMPLETE_NAME = @objname
		,TRIGGER_NAME		
		,TRIGGER_OWNER		
		,ISUPDATE			
		,ISDELETE			
		,ISINSERT			
		,ISAFTER			
		,ISINSTEADOF		
		,TRIGGER_SCHEMA		
		FROM @proc_trigger
END


--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--Table View Part2
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
INSERT INTO ##TABLES_VIEWS_PART2 
(OBJECT_ID, ATTRIBUTE, VALUE)
SELECT 
	 OBJECT_ID = @objid
	,ATTRIBUTE
	,[VALUE]
	FROM (SELECT 
			 SCHEMA_NAME
			,OBJECT_ID
			,NAME
			,COMPLETE_NAME
			,CREATE_DATE
			,CREATE_TIME
			,ROWS = ROWS_TEXT
			,ROWS_CATEGORY
			FROM ##TABLES_VIEWS_PART1
			WHERE [OBJECT_ID] = @objid) A
	UNPIVOT ([VALUE] FOR ATTRIBUTE IN 
	([SCHEMA_NAME], [OBJECT_ID], [NAME], [COMPLETE_NAME]
	,[CREATE_DATE], [CREATE_TIME], [ROWS_CATEGORY], [ROWS])
	) UNPVT


--Reading next line
FETCH NEXT FROM cursor1 INTO @objname,@type_desc
END
 
-- Closing Cursor
CLOSE cursor1
 
--Ending Cursor
DEALLOCATE cursor1


--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--Phase 2: Presentation (Generate HTML)
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

--================================================================================
--2.1) Setting HTML Variables
--================================================================================

DECLARE  @HTML				VARCHAR(MAX)
		,@TABLE_HTML		VARCHAR(MAX)
		,@TABLE_HTML_QUERY	VARCHAR(MAX)


--HTML
SET @HTML = 
'<style>
	table {
	text-align: left;
	border-collapse: collapse;
	margin: 0 0 1em 0;
	caption-side: 10px;
	font-family: "Arial";
	font-size: 80%;
	} 
	thead {
	text-align: center;
	font-weight: bold;
	}
	tbody {
	border-top: 5px solid #000;
	border-bottom: 5px solid #000;
	}
	.firstLine th, .firstLine td {
	color: #FFFFFF;
	}
	.lastLine th, .lastLine td {
	color: #FFFFFF;
	text-align: center;
	font-weight: bold;	 
	}
	 h1 { 
	 text-decoration: underline;
	 font-size: 265%; 
	}  
	 h2 { 
	 text-decoration: underline;
	 font-size: 200%; 
	}  
	 h3 { 
	 font-size: 150%; 
	 }  
	 h4 { 
	 text-decoration: underline;
	 font-size: 120%; 
	 }  
	 h5 { 
	 font-size: 100%; 
	 }   
</style>

<html>
<font face="arial">
<head>
	<title>DBDoc #DABATASE</title>
</head>

<body>

<h1 align="center">Database Documentation<br>"#DABATASE"<br><br></h1>
<h2><a name="summary">Summary</a></h3>
<ul>
	<li><a href="#databaseInfo">Database Info</a></li>
	<ul>
		<li><a href="#databaseSpecification">Database Specification</a></li>
		<li><a href="#databaseFilenames">Database Filenames</a></li>
	</ul>


	<li><a href="#schemas">Schemas</a></li>
	<li><a href="#tables"><a name="summaryTables">Tables</a></a></li>
	<ul>
		<li><a href="#bigTables">Big Tables</a></li>
		<ul>
			#1_summaryBigTables
		</ul>
		<li><a href="#mediumTables">Medium Tables</a></li>
		<ul>
			#2_summaryMediumTables
		</ul>
		<li><a href="#smallTables">Small Tables</a></li>
		<ul>
			#3_summarySmallTables
		</ul>
	</ul>
	<li><a href="#views"><a name="summaryViews">Views</a></a></li>
	<ul>
		#summary_views
	</ul>

	<li><a href="#functions"><a name="summaryFunctions">Functions</a></a></li>
	<ul>
		<li><a href="#scalarFunction">Scalar Functions</a></li>
		<ul>
			#summary_scalarFunctions
		</ul>
	</ul>
	<ul>
		<li><a href="#inlineTableValuedFunction">Inline Table-Valued Functions</a></li>
		<ul>
			#summary_inlineTableValuedFunctions
		</ul>
	</ul>
	<ul>
		<li><a href="#tableValuedFunction">Table-Valued Functions</a></li>
		<ul>
			#summary_tableValuedFunctions
		</ul>
	</ul>


	<li><a href="#procedures"><a name="summaryProcedures">Procedures</a></a></li>
	<ul>
		#summary_procedures
	</ul>

	<li><a href="#triggers"><a name="summaryTriggers">Triggers</a></a></li>
	<ul>
		#summary_triggers
	</ul>


</ul>

<br>
<h2><a name="databaseInfo">Database Info</a></h2>

<h3><a name="databaseSpecification">Database Specification</a></h3>
#tableDatabaseSpecification

<h3><a name="databaseFilenames">Database Filenames</a></h3>
#tableDatabaseFilenames
<h5><a href="#summary">Return to Summary</a><h5>


<h2><a name="schemas">Schemas</a></h2>
#tableSchemas
<h5><a href="#summary">Return to Summary</a><h5>


<h2><a name="tables">Tables</a></h2>

<h3><a name="bigTables">Big Tables</a></h2>
#1_contentBigTables

<h3><a name="mediumTables">Medium Tables</a></h2>
#2_contentMediumTables

<h3><a name="smallTables">Small Tables</a></h2>
#3_contentSmallTables

<br>
<h2><a name="views">Views</a></h2>
#contentView

<br>
<h2><a name="functions">Functions</a></h2>

<h3><a name="scalarFunction">Scalar Functions</a></h2>
#contentScalarFunction

<h3><a name="inlineTableValuedFunction">Inline Table-Valued Functions</a></h2>
#contentInlineTableValuedFunction

<h3><a name="tableValuedFunction">Table-Valued Functions</a></h2>
#contentTableValuedFunction

<br>
<h2><a name="procedures">Procedures</a></h2>
#contentProcedure


</body>
</font>
</html>
'

SET @HTML = REPLACE(@HTML, '#DABATASE', ISNULL(@DATABASE, ''))


--==================================================================
--2.2) Putting database Info into HTML
--==================================================================
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--tableDatabaseSpecification
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SET @TABLE_HTML_QUERY = 
'(SELECT 
	 Attribute
	,Value
	FROM TEMPDB..##DATABASE_PART3) A'

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = NULL


--Remove Class From Last Line
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#ff3b00">')
--Set Colors
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="lastLine"', '')

--Replace on the complete HTML
SET @HTML = REPLACE(@HTML, '#tableDatabaseSpecification', ISNULL(@TABLE_HTML,''))

--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--tableDatabaseFilenames
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SET @TABLE_HTML_QUERY = 
'(SELECT 
	 Filename
	,[Current Size<br>(MB)] = CURRENTSIZEMB
	,[Free Space<br>(MB)] = FREESPACEMB
	FROM TEMPDB..##DATABASE_PART2) A'

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = NULL


--Set Colors
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#d83d0f">')
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="lastLine">' , 'class="lastLine"  bgcolor="#d83d0f">')


--Replace on the complete HTML
SET @HTML = REPLACE(@HTML, '#tableDatabaseFilenames', ISNULL(@TABLE_HTML, ''))

--==================================================================
--2.2) Putting schema info into HTML
--==================================================================
SET @TABLE_HTML_QUERY = 
'(SELECT 
	[Schema Name] = SCHEMA_NAME 	
	,[Qtd<br>User Table] = QTD_USER_TABLE 	
	,[Qtd<br>Procs] = QTD_STORED_PROCEDURE 	
	,[Qtd<br>View] = QTD_VIEW 	
	,[Qtd<br>Trigger] = QTD_TRIGGER 	
	,[Qtd<br>Table Valued<br>Function] = QTD_TABLE_VALUED_FUNCTION 	
	,[Qtd<br>Scalar Function] = QTD_SCALAR_FUNCTION 	
	,[Qtd<br>Inline Table<br>Valued Function] = QTD_INLINE_TABLE_VALUED_FUNCTION
	FROM TEMPDB..##SCHEMA_PART1) A'

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = NULL

--Set Colors
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#af9c07">')
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="lastLine">' , 'class="lastLine"  bgcolor="#af9c07">')


--Replace on the complete HTML
SET @HTML = REPLACE(@HTML, '#tableSchemas', ISNULL(@TABLE_HTML, ''))


--==================================================================
--2.2) Putting other info into into HTML
--==================================================================
DECLARE  @HTML_TABLE_CONTENT VARCHAR(MAX)
		,@HTML_TABLE_SUMMARY VARCHAR(MAX)

declare @OBJECT_ID			 VARCHAR(MAX)
	   ,@TYPE				 VARCHAR(MAX)
	   ,@REPLACE_HTML		 VARCHAR(MAX)
	   ,@TABLE_COMPLETE_NAME VARCHAR(MAX)
	   ,@TABLE_NAME			 VARCHAR(MAX)
	   ,@TRIGGER_SUMMARY_AUX VARCHAR(MAX)
 
-- Cursor for each row
DECLARE cursor2 CURSOR FOR
SELECT 
	 A.OBJECT_ID
	,TYPE = UPPER(A.TYPE)
	,REPLACE_HTML =CASE WHEN A.[TYPE] = 'VIEW'								THEN '#contentView'
						WHEN A.[TYPE] = 'SCALAR FUNCTION'					THEN '#contentScalarFunction'
						WHEN A.[TYPE] = 'INLINE TABLE-VALUED FUNCTION'		THEN '#contentInlineTableValuedFunction'
						WHEN A.[TYPE] = 'TABLE-VALUED FUNCTION'				THEN '#contentTableValuedFunction'
						WHEN A.[TYPE] = 'PROCEDURE'							THEN '#contentProcedure' 
						WHEN A.[TYPE] = 'TRIGGER'							THEN '#contentTrigger' 
						WHEN A.[TYPE] = 'TABLE' AND B.ROWS_CATEGORY = 'Category A - Big Tables'		THEN '#1_contentBigTables'
						WHEN A.[TYPE] = 'TABLE' AND B.ROWS_CATEGORY = 'Category B - Medium Tables'	THEN '#2_contentMediumTables'
						WHEN A.[TYPE] = 'TABLE' AND B.ROWS_CATEGORY = 'Category C - Small Tables'	THEN '#3_contentSmallTables' 
						END
	,TABLE_COMPLETE_NAME = A.COMPLETE_NAME
	,TABLE_NAME			 = A.NAME
	FROM ##DOCUMENTATION_INDEX_PART1 A
	LEFT JOIN ##TABLES_VIEWS_PART1 B ON A.OBJECT_ID = B.OBJECT_ID
	WHERE A.TYPE IN ('TABLE', 'VIEW', 'PROCEDURE'
					,'SCALAR FUNCTION', 'TABLE-VALUED FUNCTION'
					,'INLINE TABLE-VALUED FUNCTION')
	ORDER BY TABLE_COMPLETE_NAME
	
	 
--Opening Cursor
OPEN cursor2
 
--Reading Line
FETCH NEXT FROM cursor2 INTO @OBJECT_ID, @TYPE, @REPLACE_HTML, @TABLE_COMPLETE_NAME, @TABLE_NAME
 
--Reading all lines
WHILE @@FETCH_STATUS = 0
BEGIN
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.1) Table Summary
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--Big Tables
IF @REPLACE_HTML = '#1_contentBigTables'
BEGIN
	SET @HTML_TABLE_SUMMARY = 
		REPLACE('<li><a href="#table_#1_summaryBigTables">#1_summaryBigTables</a></li>', '#1_summaryBigTables', @TABLE_COMPLETE_NAME) 
		+ CHAR(10) + '#1_summaryBigTables'

	--Replace on the complete HTML
	SET @HTML = REPLACE(@HTML, '#1_summaryBigTables', ISNULL(@HTML_TABLE_SUMMARY, ''))
END

--Medium Tables
IF @REPLACE_HTML = '#2_contentMediumTables'
BEGIN
	SET @HTML_TABLE_SUMMARY = 
		REPLACE('<li><a href="#table_#2_summaryMediumTables">#2_summaryMediumTables</a></li>', '#2_summaryMediumTables', @TABLE_COMPLETE_NAME) 
		+ CHAR(10) + '#2_summaryMediumTables'

	--Replace on the complete HTML
	SET @HTML = REPLACE(@HTML, '#2_summaryMediumTables', ISNULL(@HTML_TABLE_SUMMARY, ''))
END

--Small Tables
IF @REPLACE_HTML = '#3_contentSmallTables'
BEGIN
	SET @HTML_TABLE_SUMMARY = 
		REPLACE('<li><a href="#table_#3_summarySmallTables">#3_summarySmallTables</a></li>', '#3_summarySmallTables', @TABLE_COMPLETE_NAME) 
		+ CHAR(10) + '#3_summarySmallTables'

	--Replace on the complete HTML
	SET @HTML = REPLACE(@HTML, '#3_summarySmallTables', ISNULL(@HTML_TABLE_SUMMARY, ''))
END

--Views
IF @TYPE = 'VIEW'
BEGIN
	SET @HTML_TABLE_SUMMARY = 
		REPLACE('<li><a href="#view_#summary_views">#summary_views</a></li>', '#summary_views', @TABLE_COMPLETE_NAME) 
		+ CHAR(10) + '#summary_views'

	--Replace on the complete HTML
	SET @HTML = REPLACE(@HTML, '#summary_views', ISNULL(@HTML_TABLE_SUMMARY, ''))
END


--Scalar Function
IF @TYPE = 'SCALAR FUNCTION'
BEGIN
	SET @HTML_TABLE_SUMMARY = 
		REPLACE('<li><a href="#function_#scalarFunction">#scalarFunction</a></li>', '#scalarFunction', @TABLE_COMPLETE_NAME) 
		+ CHAR(10) + '#summary_scalarFunctions'

	--Replace on the complete HTML
	SET @HTML = REPLACE(@HTML, '#summary_scalarFunctions', ISNULL(@HTML_TABLE_SUMMARY, ''))
END

--Inline Table-Valued Function
IF @TYPE = 'INLINE TABLE-VALUED FUNCTION'
BEGIN
	SET @HTML_TABLE_SUMMARY = 
		REPLACE('<li><a href="#function_#InlineTableValuedFunction">#InlineTableValuedFunction</a></li>', '#InlineTableValuedFunction', @TABLE_COMPLETE_NAME) 
		+ CHAR(10) + '#summary_inlineTableValuedFunctions'

	--Replace on the complete HTML
	SET @HTML = REPLACE(@HTML, '#summary_inlineTableValuedFunctions', ISNULL(@HTML_TABLE_SUMMARY, ''))
END

--Table-Valued Function
IF @TYPE = 'TABLE-VALUED FUNCTION'
BEGIN
	SET @HTML_TABLE_SUMMARY = 
		REPLACE('<li><a href="#function_#tableValuedFunction">#tableValuedFunction</a></li>', '#tableValuedFunction', @TABLE_COMPLETE_NAME) 
		+ CHAR(10) + '#summary_tableValuedFunctions'

	--Replace on the complete HTML
	SET @HTML = REPLACE(@HTML, '#summary_tableValuedFunctions', ISNULL(@HTML_TABLE_SUMMARY, ''))
END

--Procedure
IF @TYPE = 'PROCEDURE'
BEGIN
	SET @HTML_TABLE_SUMMARY = 
		REPLACE('<li><a href="#proc_#procedure">#procedure</a></li>', '#procedure', @TABLE_COMPLETE_NAME) 
		+ CHAR(10) + '#summary_procedures'

	--Replace on the complete HTML
	SET @HTML = REPLACE(@HTML, '#summary_procedures', ISNULL(@HTML_TABLE_SUMMARY, ''))
END

--Triggers
IF @TYPE = 'Table' 
	AND EXISTS (SELECT 1 
				FROM ##TABLES_VIEWS_TRIGGER_PART1
				WHERE OBJECT_ID = @OBJECT_ID)
BEGIN
	SET @HTML_TABLE_SUMMARY = 
			REPLACE('<li><a href="#table_#summaryTables">#summaryTables</a></li>', '#summaryTables', @TABLE_COMPLETE_NAME) 
		+ CHAR(10) + '<ul>#list_triggers</ul>'
		+ CHAR(10) + '#summary_triggers'


	SET @TRIGGER_SUMMARY_AUX =
	(SELECT '<li><a href="#trigger_#triggerTable">' + TRIGGER_NAME + '</a></li>'
		FROM ##TABLES_VIEWS_TRIGGER_PART1
		WHERE OBJECT_ID = @OBJECT_ID
		ORDER BY 1
		FOR XML PATH(''))

	--Troca caracteres de escape do HTML
	SET @TRIGGER_SUMMARY_AUX = REPLACE(@TRIGGER_SUMMARY_AUX, '&lt;',  '<')
	SET @TRIGGER_SUMMARY_AUX = REPLACE(@TRIGGER_SUMMARY_AUX, '&gt;',  '>')
	SET @TRIGGER_SUMMARY_AUX = REPLACE(@TRIGGER_SUMMARY_AUX, '&amp;', '&')
	SET @TRIGGER_SUMMARY_AUX = REPLACE(@TRIGGER_SUMMARY_AUX, '&#x0D;', '<br>')

	SET @TRIGGER_SUMMARY_AUX = REPLACE(@TRIGGER_SUMMARY_AUX,'#triggerTable', @TABLE_COMPLETE_NAME) 
	SET @HTML_TABLE_SUMMARY  = REPLACE(@HTML_TABLE_SUMMARY, '#list_triggers',  @TRIGGER_SUMMARY_AUX)


	--Replace on the complete HTML
	SET @HTML = REPLACE(@HTML, '#summary_triggers', ISNULL(@HTML_TABLE_SUMMARY, ''))


END


--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.2) Setting Variables necessaries for other replaces (only for tables)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
IF @TYPE = 'Table'
BEGIN
SET @HTML_TABLE_CONTENT = 
'<h4><a name="table_#TABLE_COMPLETE_NAME">#TABLE_COMPLETE_NAME</a></h4>
<h5>Table Specification</h5>
#tableSpecification
<h5>Table Columns</h5>
#tableColumns
<h5>Table Index(es)</h5>
#tableIndexes
<h5>Foreign Keys</h5>
#tableConstraint1
<h5>Table Constraint</h5>
#tableConstraint2
<h5>Table Triggers</h5>
#tableTrigger
<h5><a href="#summaryTables">Return to Summary</a><h5>
#REPLACE_HTML
' 

SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#TABLE_COMPLETE_NAME',  @TABLE_COMPLETE_NAME)
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#REPLACE_HTML',  @REPLACE_HTML)


--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.2.1) Table Specification (only for tables)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SET @TABLE_HTML_QUERY = 
'(SELECT 
	 Attribute = ATTRIBUTE
	,Value
	FROM TEMPDB..##TABLES_VIEWS_PART2
	WHERE OBJECT_ID = ''#OBJECT_ID'') A'

SET @TABLE_HTML_QUERY = REPLACE(@TABLE_HTML_QUERY, '#OBJECT_ID', @OBJECT_ID)

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = NULL

--Remove Class From Last Line
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="lastLine"', '')
--Set Colors 
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#021e4f">')

--Replace on the complete HTML
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#tableSpecification', ISNULL(@TABLE_HTML, ''))

--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.2.2) Table Columns (only for tables)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SET @TABLE_HTML_QUERY = 
'(SELECT 
	 [Column<br>Name] = Column_name	
	,Type	
	,Length	
	,Precision
	,Scale	
	,Nullable
	,Collation
	,[Is<br>Identity] = Is_Identity
	,[Identity<br>Seed] = Identity_Seed
	,[Identity<br>Increment] = Identity_Increment
	,[Identity Not<br>For Replication] = Identity_Not_For_Replication
	,[Is<br>RowGuidCol] = Is_RowGuidCol
	,COLUMN_ID
	,#VALUES_EXAMPLES
	FROM  ##TABLES_VIEWS_COLUMNS_PART1
	WHERE OBJECT_ID = ''#OBJECT_ID'') A
	ORDER BY COLUMN_ID'


SET @TABLE_HTML_QUERY = REPLACE(@TABLE_HTML_QUERY, ',#VALUES_EXAMPLES', CASE WHEN @FLG_VALUES_EXAMPLES = 0 THEN '' ELSE ',[Values<br>Examples] = VALUES_EXAMPLES' END)
SET @TABLE_HTML_QUERY = REPLACE(@TABLE_HTML_QUERY, '#OBJECT_ID', @OBJECT_ID)

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = 'COLUMN_ID'

--Remove Class From Last Line
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="lastLine"', '')
--Set Colors
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#167776">')


--Replace on the complete HTML
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#tableColumns', ISNULL(@TABLE_HTML, ''))

--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.2.3) Table Indexes (only for tables)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SET @TABLE_HTML_QUERY = 
'(SELECT 
	 [Index Name] = INDEX_NAME
	,[Index Description] = INDEX_DESCRIPTION
	,[Index Keys] = INDEX_KEYS
	FROM  ##TABLES_VIEWS_INDEX_PART1
	WHERE OBJECT_ID = ''#OBJECT_ID'') A
	ORDER BY [Index Name]'

SET @TABLE_HTML_QUERY = REPLACE(@TABLE_HTML_QUERY, '#OBJECT_ID', @OBJECT_ID)

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = NULL
	,@RETURN_EMPTY_TABLE = 0

--Remove Class From Last Line
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="lastLine"', '')
--Set Colors
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#22939e">')
SET  @TABLE_HTML = NULLIF(@TABLE_HTML, '')

--Replace on the complete HTML
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#tableIndexes', ISNULL(@TABLE_HTML, 'There is no Index in the Table<br><br>'))

--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.2.4)Table Constraint - Table1 (only for tables)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SET @TABLE_HTML_QUERY = 
'(SELECT 
	 [Table is referenced by foreign key]
	FROM  ##TABLES_VIEWS_CONSTRAINT_PART1
	WHERE OBJECT_ID = ''#OBJECT_ID'') A'

SET @TABLE_HTML_QUERY = REPLACE(@TABLE_HTML_QUERY, '#OBJECT_ID', @OBJECT_ID)

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = NULL
	,@RETURN_EMPTY_TABLE = 0

--Remove Class From Last Line
SET  @TABLE_HTML = REPLACE(@TABLE_HTML, 'class="lastLine"', '')
--Set Colors
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#0f6491">')

SET  @TABLE_HTML = NULLIF(@TABLE_HTML, '')

--Replace on the complete HTML
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#tableConstraint1', ISNULL(@TABLE_HTML, 'Table is not referenced by foreign key<br><br>'))

--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.2.5)Table Constraint - Table2 (only for tables)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SET @TABLE_HTML_QUERY = 
'(SELECT 
	 [Constraint Type]			= constraint_type			 
	,[Constraint Name]			= constraint_name			
	,[Delete Action]			= delete_action			
	,[Update Action]			= update_action			
	,[Status Enabled]			= status_enabled			
	,[Status for Replication]	= status_for_replication	
	,[Constraint Keys]			= constraint_keys	
	FROM  ##TABLES_VIEWS_CONSTRAINT_PART2
	WHERE OBJECT_ID = ''#OBJECT_ID'') A'


SET @TABLE_HTML_QUERY = REPLACE(@TABLE_HTML_QUERY, '#OBJECT_ID', @OBJECT_ID)

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = NULL
	,@RETURN_EMPTY_TABLE = 0

--Remove Class From Last Line
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="lastLine"', '')
--Set Colors
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#02344f">')

SET  @TABLE_HTML = NULLIF(@TABLE_HTML, '')


--Replace on the complete HTML
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#tableConstraint2', ISNULL(@TABLE_HTML, 'No constraint was found for the object<br><br>'))


--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.2.6) Table Triggers - Table2 (only for tables)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SET @TABLE_HTML_QUERY = 
'(SELECT 
	 [Trigger name]	 = trigger_name 
	,[Trigger owner] = trigger_owner	 
	,[Isupdate]		 = isupdate		 
	,[Isdelete]		 = isdelete		 
	,[Isinsert]		 = isinsert		 
	,[Isafter]		 = isafter			 
	,[Isinsteadof]	 = isinsteadof		 
	,[Trigger Schema]= trigger_schema	
	FROM  ##TABLES_VIEWS_TRIGGER_PART1
	WHERE OBJECT_ID = ''#OBJECT_ID'') A'

SET @TABLE_HTML_QUERY = REPLACE(@TABLE_HTML_QUERY, '#OBJECT_ID', @OBJECT_ID)

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = NULL
	,@RETURN_EMPTY_TABLE = 0

--Remove Class From Last Line
SET  @TABLE_HTML = REPLACE(@TABLE_HTML, 'class="lastLine"', '')
--Set Colors
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#028987">')

SET  @TABLE_HTML = NULLIF(@TABLE_HTML, '')


IF @TABLE_HTML IS NULL 
BEGIN
	SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '<h5>Table Triggers</h5>', '') 
	SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '<h5>Table Triggers</h5>', '') 	
END

SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '<h5>Table Triggers</h5>', 
							REPLACE('<h5><a name="trigger_#tableTrigger">Table Triggers</a></h5>'
								   ,'#tableTrigger', @TABLE_COMPLETE_NAME)
						   ) 


--Replace on the complete HTML
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#tableTrigger', ISNULL(@TABLE_HTML, ''))

--Replace on the complete HTML
SET @HTML = REPLACE(@HTML, @REPLACE_HTML, ISNULL(@HTML_TABLE_CONTENT, ''))




END


--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.3) Setting Variables necessaries for other replaces (only for View)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
IF @TYPE = 'View'
BEGIN

SET @HTML_TABLE_CONTENT = 
'<h4><a name="view_#VIEW_COMPLETE_NAME">#VIEW_COMPLETE_NAME</a></h4>
<h5>View Specification</h5>
#viewSpecification
<h5>View Columns</h5>
#viewColumns
<h5><a href="#summaryViews">Return to Summary</a><h5>
#REPLACE_HTML
' 

SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#VIEW_COMPLETE_NAME',  @TABLE_COMPLETE_NAME)
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#REPLACE_HTML',  @REPLACE_HTML)


--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.3.1) Table Specification (only for view)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SET @TABLE_HTML_QUERY = 
'(SELECT 
	 Attribute = ATTRIBUTE
	,Value
	FROM TEMPDB..##TABLES_VIEWS_PART2
	WHERE OBJECT_ID = ''#OBJECT_ID'') A'

SET @TABLE_HTML_QUERY = REPLACE(@TABLE_HTML_QUERY, '#OBJECT_ID', @OBJECT_ID)

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = NULL

--Remove Class From Last Line
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="lastLine"', '')
--Set Colors 
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#7c134c">')


--Replace on the complete HTML
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#viewSpecification', ISNULL(@TABLE_HTML, ''))

--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.3.2) View Columns (only for view)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SET @TABLE_HTML_QUERY = 
'(SELECT 
	 [Column<br>Name] = Column_name	
	,Type	
	,Length	
	,Precision
	,Scale	
	,Nullable
	,Collation
	,[Is<br>Identity] = Is_Identity
	,[Identity<br>Seed] = Identity_Seed
	,[Identity<br>Increment] = Identity_Increment
	,[Identity Not<br>For Replication] = Identity_Not_For_Replication
	,[Is<br>RowGuidCol] = Is_RowGuidCol
	,COLUMN_ID
	,#VALUES_EXAMPLES
	FROM  ##TABLES_VIEWS_COLUMNS_PART1
	WHERE OBJECT_ID = ''#OBJECT_ID'') A
	ORDER BY COLUMN_ID'


SET @TABLE_HTML_QUERY = REPLACE(@TABLE_HTML_QUERY, ',#VALUES_EXAMPLES', CASE WHEN @FLG_VALUES_EXAMPLES = 0 THEN '' ELSE ',[Values<br>Examples] = VALUES_EXAMPLES' END)
SET @TABLE_HTML_QUERY = REPLACE(@TABLE_HTML_QUERY, '#OBJECT_ID', @OBJECT_ID)

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = 'COLUMN_ID'

--Remove Class From Last Line
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="lastLine"', '')
--Set Colors
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#563145">')

--Replace on the complete HTML
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#viewColumns', ISNULL(@TABLE_HTML, ''))


--Replace on the complete HTML
SET @HTML = REPLACE(@HTML, @REPLACE_HTML, ISNULL(@HTML_TABLE_CONTENT, ''))


END


--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.4) Setting Variables necessaries for other replaces (only for Functions)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

IF @TYPE IN ('SCALAR FUNCTION',  'INLINE TABLE-VALUED FUNCTION', 'TABLE-VALUED FUNCTION')
BEGIN
SET @HTML_TABLE_CONTENT = 
'<h4><a name="function_#FUNCTION_COMPLETE_NAME">#FUNCTION_COMPLETE_NAME</a></h4>
<h5>Function Specification</h5>
#functionSpecification
<h5>Function Parameters</h5>
#functionParameters
<h5>Function Columns</h5>
#functionColumns
<h5><a href="#summaryFunctions">Return to Summary</a><h5>
#REPLACE_HTML
' 

IF @TYPE IN ('SCALAR FUNCTION')
BEGIN
	SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '<h5>Function Columns</h5>', '')
	SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#functionColumns', '')
END



SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#FUNCTION_COMPLETE_NAME',  @TABLE_COMPLETE_NAME)
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#REPLACE_HTML',  @REPLACE_HTML)


--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.4.1) Function Specification (only for Functions)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SET @TABLE_HTML_QUERY = 
'(SELECT 
	 Attribute = ATTRIBUTE
	,Value
	FROM TEMPDB..##FUNCTIONS_PARTE4
	WHERE OBJECT_ID = ''#OBJECT_ID'') A'

SET @TABLE_HTML_QUERY = REPLACE(@TABLE_HTML_QUERY, '#OBJECT_ID', @OBJECT_ID)

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = NULL

--Remove Class From Last Line
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="lastLine"', '')
--Set Colors 
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#bc0101">')


--Replace on the complete HTML
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#functionSpecification', ISNULL(@TABLE_HTML, ''))

--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.4.2) Function Parameters (only for Functions)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SET @TABLE_HTML_QUERY = 
'(SELECT 
	 [Param_order]	 = Param_order		
	,[Parameter_name]= Parameter_name	
	,[Type]			 = Type			
	,[Length]		 = Length			
	,[Prec]			 = Prec			
	,[Scale]		 = Scale			
	,[Collation]	 = Collation		
	FROM TEMPDB..##FUNCTIONS_PARTE2
	WHERE OBJECT_ID = ''#OBJECT_ID'') A
	ORDER BY CONVERT(INT, PARAM_ORDER)'

SET @TABLE_HTML_QUERY = REPLACE(@TABLE_HTML_QUERY, '#OBJECT_ID', @OBJECT_ID)

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = NULL
	,@RETURN_EMPTY_TABLE = 0


--Remove Class From Last Line
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="lastLine"', '')
--Set Colors 
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#9b1818">')

SET  @TABLE_HTML = NULLIF(@TABLE_HTML, '')

--Replace on the complete HTML
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#functionParameters', ISNULL(@TABLE_HTML, 'There is no Parameters in this function<br>'))



--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.4.3) Function Columns (only for Table-Functions)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
IF @TYPE IN ('INLINE TABLE-VALUED FUNCTION', 'TABLE-VALUED FUNCTION')
BEGIN
SET @TABLE_HTML_QUERY = 
'(SELECT 
	 [Column<br>Name] = Column_name	
	,Type	
	,Length	
	,Precision
	,Scale	
	,Nullable
	,Collation
	,[Is<br>Identity] = Is_Identity
	,[Identity<br>Seed] = Identity_Seed
	,[Identity<br>Increment] = Identity_Increment
	,[Identity Not<br>For Replication] = Identity_Not_For_Replication
	,[Is<br>RowGuidCol] = Is_RowGuidCol
	,COLUMN_ID
	FROM  TEMPDB..##FUNCTIONS_PARTE3
	WHERE OBJECT_ID = ''#OBJECT_ID'') A
	ORDER BY COLUMN_ID'

SET @TABLE_HTML_QUERY = REPLACE(@TABLE_HTML_QUERY, '#OBJECT_ID', @OBJECT_ID)

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = 'COLUMN_ID'

--Remove Class From Last Line
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="lastLine"', '')
--Set Colors
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#720909">')

--Replace on the complete HTML
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#functionColumns', ISNULL(@TABLE_HTML, ''))

END

--Replace on the complete HTML
SET @HTML = REPLACE(@HTML, @REPLACE_HTML, ISNULL(@HTML_TABLE_CONTENT, ''))



END


--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.5) Setting Variables necessaries for other replaces (only for Procs)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
IF @TYPE = 'Procedure'
BEGIN

SET @HTML_TABLE_CONTENT = 
'<h4><a name="proc_#PROCEDURE_COMPLETE_NAME">#PROCEDURE_COMPLETE_NAME</a></h4>
<h5>Procedure Specification</h5>
#procedureSpecification
<h5>Procedure Parameters</h5>
#procedureParameters
<h5><a href="#summaryProcedures">Return to Summary</a><h5>
#REPLACE_HTML
' 

SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#PROCEDURE_COMPLETE_NAME',  @TABLE_COMPLETE_NAME)
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#REPLACE_HTML',  @REPLACE_HTML)



--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.5.1) Procs Specification (only for Procs)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SET @TABLE_HTML_QUERY = 
'(SELECT 
	 Attribute = ATTRIBUTE
	,Value
	FROM TEMPDB..##PROCS_PART3
	WHERE OBJECT_ID = ''#OBJECT_ID'') A'

SET @TABLE_HTML_QUERY = REPLACE(@TABLE_HTML_QUERY, '#OBJECT_ID', @OBJECT_ID)

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = NULL

--Remove Class From Last Line
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="lastLine"', '')
--Set Colors 
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#03560d">')


--Replace on the complete HTML
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#procedureSpecification', ISNULL(@TABLE_HTML, ''))

--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--2.2.5.2) Procs Parameters (only for Procs)
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SET @TABLE_HTML_QUERY = 
'(SELECT 
	 [Param_order]	 = Param_order		
	,[Parameter_name]= Parameter_name	
	,[Type]			 = Type			
	,[Length]		 = Length			
	,[Prec]			 = Prec			
	,[Scale]		 = Scale			
	,[Collation]	 = Collation		
	FROM TEMPDB..##PROCS_PART2
	WHERE OBJECT_ID = ''#OBJECT_ID'') A
	ORDER BY CONVERT(INT, PARAM_ORDER)'

SET @TABLE_HTML_QUERY = REPLACE(@TABLE_HTML_QUERY, '#OBJECT_ID', @OBJECT_ID)

EXEC DBO.PR_RETORNA_TABELA_HTML
	 @TABELA			 = @TABLE_HTML_QUERY
	,@HTML_COMPLETO		 = @TABLE_HTML OUTPUT
	,@COLUNAS_DESCONSIDERADAS = NULL
	,@RETURN_EMPTY_TABLE = 0


--Remove Class From Last Line
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="lastLine"', '')
--Set Colors 
SET  @TABLE_HTML = REPLACE( @TABLE_HTML, 'class="firstLine">', 'class="firstLine" bgcolor="#287231">')

SET  @TABLE_HTML = NULLIF(@TABLE_HTML, '')

--Replace on the complete HTML
SET @HTML_TABLE_CONTENT = REPLACE(@HTML_TABLE_CONTENT, '#procedureParameters', ISNULL(@TABLE_HTML, 'There is no Parameters in this Procedures<br>'))

--Replace on the complete HTML
SET @HTML = REPLACE(@HTML, @REPLACE_HTML, ISNULL(@HTML_TABLE_CONTENT, ''))

END

--Reading next line
FETCH NEXT FROM cursor2 INTO @OBJECT_ID,  @TYPE, @REPLACE_HTML, @TABLE_COMPLETE_NAME, @TABLE_NAME
END
 
--Closing Cursor
CLOSE cursor2
 
--Ending Cursor
DEALLOCATE cursor2


--==================================================================
--2.3) Replace Index Flag
--==================================================================
--Replace on the complete HTML
SET @HTML = REPLACE(@HTML, '#1_summaryBigTables'	, '')
SET @HTML = REPLACE(@HTML, '#2_summaryMediumTables'	, '')
SET @HTML = REPLACE(@HTML, '#3_summarySmallTables'	, '')
SET @HTML = REPLACE(@HTML, '#summary_views'	, '')
SET @HTML = REPLACE(@HTML, '#summary_scalarFunctions'	, '')
SET @HTML = REPLACE(@HTML, '#summary_inlineTableValuedFunctions'	, '')
SET @HTML = REPLACE(@HTML, '#summary_tableValuedFunctions'	, '')
SET @HTML = REPLACE(@HTML, '#summary_procedures'	, '')
SET @HTML = REPLACE(@HTML, '#summary_triggers'	, '')
SET @HTML = REPLACE(@HTML, '#1_contentBigTables'	, '')
SET @HTML = REPLACE(@HTML, '#2_contentMediumTables'	, '')
SET @HTML = REPLACE(@HTML, '#3_contentSmallTables'	, '')
SET @HTML = REPLACE(@HTML, '#contentView'	, '')
SET @HTML = REPLACE(@HTML, '#contentScalarFunction'	, '')
SET @HTML = REPLACE(@HTML, '#contentInlineTableValuedFunction'	, '')
SET @HTML = REPLACE(@HTML, '#contentTableValuedFunction'	, '')
SET @HTML = REPLACE(@HTML, '#contentProcedure'	, '')


SELECT 
	 LINHA = IDENTITY(INT,1,1) 
	,* 
	INTO ##HTML_FINAL
	FROM string_split(@HTML, CHAR(10))

DELETE FROM ##HTML_FINAL WHERE VALUE = CHAR(13)

--Copie esse select final em um arquivo html
SELECT * FROM ##HTML_FINAL ORDER BY LINHA



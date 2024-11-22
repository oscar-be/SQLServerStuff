CREATE PROCEDURE [dbo].[PLOT_GRAPH]
	 @OUTPUT_TYPE		VARCHAR(MAX)
	,@TABLE_NAME		VARCHAR(MAX)
	,@COLUMN_LABEL		VARCHAR(MAX)
	,@COLUMN_METRIC		VARCHAR(MAX)
AS

/*
--================
Testing the Procedure:
--================
--Creating a table for Tests
DROP TABLE IF EXISTS ##TEST_HISTOGRAM

SELECT
	 COL_LABEL
	,COUNT(*)	AS COL_METRIC
	INTO ##TEST_HISTOGRAM
	FROM (
SELECT 
	ABS(CHECKSUM(NEWID())) % 30 AS COL_LABEL
	FROM STRING_SPLIT(REPLICATE(';', 99), ';')
	) A
	GROUP BY COL_LABEL

--Example of Procedure Execution:
EXEC DBO.PLOT_GRAPH
	 @OUTPUT_TYPE		= 'HISTOGRAM'
	,@TABLE_NAME		= '##TEST_HISTOGRAM'
	,@COLUMN_LABEL		= 'COL_LABEL'
	,@COLUMN_METRIC		= 'COL_METRIC'

EXEC DBO.PLOT_GRAPH
	 @OUTPUT_TYPE		= 'LINE CHART'
	,@TABLE_NAME		= '##TEST_HISTOGRAM'
	,@COLUMN_LABEL		= 'COL_LABEL'
	,@COLUMN_METRIC		= 'COL_METRIC'


DROP TABLE IF EXISTS ##TEST_HISTOGRAM
*/

  --================
--Create Objects:
--================

--@TABLE_HISTOGRAM 
--Create table used in the process
DECLARE @TABLE_HISTOGRAM TABLE (
	 ID				INT IDENTITY
	,LABEL			NVARCHAR(MAX)
	,LABEL_SHOW		NVARCHAR(MAX)
	,METRIC		INT
	--Auxiliar Columns to create the polygon
	,VALUE_X_A		FLOAT
	,VALUE_X_B		FLOAT
	,VALUE_Y		FLOAT
	,TEXT_POLYGON	NVARCHAR(MAX)
)


--Variables Used in the process
DECLARE  @QUERY				NVARCHAR(MAX)
		,@STRING_POLYGON	NVARCHAR(MAX)
		,@ERROR_MESSAGE		VARCHAR(MAX)

--================
--Validations:
--================


--Check if the Correlation Type Value sent is correct
IF @OUTPUT_TYPE NOT IN ('HISTOGRAM', 'LINE CHART')
BEGIN
	SET @ERROR_MESSAGE = 'Invalid Parameter @OUTPUT_TYPE. It must be ''HISTOGRAM'' or ''LINE CHART''.'
	RAISERROR(@ERROR_MESSAGE, 11,1)
	RETURN
END

--COLUMN_LABEL and COLUMN_METRIC cannot have more than 1 column each
IF @COLUMN_LABEL LIKE '%,%' OR @COLUMN_METRIC LIKE '%,%'
BEGIN
	SET @ERROR_MESSAGE = 'Parameters @COLUMN_LABEL and @COLUMN_METRIC cannot have '','''
	RAISERROR(@ERROR_MESSAGE, 11,1)
	RETURN
END


--================
--Initial Updates
--================

--Query to Insert data Into @TABLE_HISTOGRAM
SET @QUERY =
'
SELECT *
	FROM 
	(SELECT
		 [#COLUMN_LABEL]
		,[#COLUMN_METRIC]
		FROM [#TABLE_NAME]) A
	ORDER BY [#COLUMN_LABEL] '

SET @QUERY = REPLACE(@QUERY, '[#COLUMN_LABEL]'		, @COLUMN_LABEL)
SET @QUERY = REPLACE(@QUERY, '[#COLUMN_METRIC]'	, @COLUMN_METRIC)
SET @QUERY = REPLACE(@QUERY, '[#TABLE_NAME]'		, @TABLE_NAME)

--Insert Parameters into table
INSERT INTO @TABLE_HISTOGRAM
(LABEL, METRIC)
EXEC (@QUERY)


--Update Label that is going to be shown in the histogram
UPDATE @TABLE_HISTOGRAM
	SET LABEL_SHOW =
	CONCAT(LEFT(LABEL, 50)
		  ,CASE WHEN LEN(LABEL) > 50 THEN '...' ELSE '' END
		  ,CHAR(10)
		  ,'f='
		  ,METRIC)


--================
--Draw Histogram
--================
IF @OUTPUT_TYPE = 'HISTOGRAM'
BEGIN

--String Used to draw the Polygon
SET @STRING_POLYGON =
'polygon(([#VALUE_X_A] 0
		 ,[#VALUE_X_B] 0
		 ,[#VALUE_X_B] [#VALUE_Y]
		 ,[#VALUE_X_A] [#VALUE_Y]
		 ,[#VALUE_X_A] 0))'

--Update Auxiliar Columns
--Version 1: Considers real values for Y and X values uses y scale
UPDATE A
	SET  A.VALUE_X_A = BAR_WIDTH * (ID - 1)
		,A.VALUE_X_B = BAR_WIDTH * ID
		,A.VALUE_Y   = METRIC
	FROM @TABLE_HISTOGRAM A
	CROSS APPLY(SELECT 1.0 * MAX(METRIC) / COUNT(DISTINCT LABEL)		AS BAR_WIDTH
					FROM @TABLE_HISTOGRAM) B

/*
--Update Auxiliar Columns
--Version 2: Values of Y and X are between 0 and 1
UPDATE A
	SET  A.VALUE_X_A = (1.0 * BAR_WIDTH * (ID - 1)) / MAX_ROWNO
		,A.VALUE_X_B = (1.0 * BAR_WIDTH * ID) / MAX_ROWNO
		,VALUE_Y	 = 1.0 * METRIC / BAR_SIZE
	FROM @TABLE_HISTOGRAM A
	CROSS APPLY(SELECT	 1					AS BAR_WIDTH
						,MAX(METRIC)		AS BAR_SIZE
						,MAX(ID)	 		AS MAX_ROWNO
					FROM @TABLE_HISTOGRAM) B
*/

--Update String for Polygon
UPDATE @TABLE_HISTOGRAM
	SET TEXT_POLYGON =
	REPLACE(
		REPLACE(
				REPLACE(@STRING_POLYGON, '[#VALUE_X_A]', VALUE_X_A)
			,'[#VALUE_X_B]', VALUE_X_B
		), '[#VALUE_Y]', VALUE_Y)


--Final Query (plot the histogram)
SELECT 
	 GEOMETRY::Parse(TEXT_POLYGON)	AS POLYGON
	,LABEL_SHOW						AS LABEL
	FROM @TABLE_HISTOGRAM

END


--================
--Draw Line Chart
--================
IF @OUTPUT_TYPE = 'LINE CHART'
BEGIN

--String Used to draw the Polygon
SET @STRING_POLYGON = (
        SELECT ',' + CONVERT(VARCHAR, ID - 1) + ' ' + CONVERT(VARCHAR, METRIC)
        FROM @TABLE_HISTOGRAM ORDER BY ID FOR XML PATH('')
    )

SET @STRING_POLYGON = CONCAT('linestring(', STUFF(@STRING_POLYGON, 1, 1, ''), ')')

--Final Query (plot the histogram)
SELECT GEOMETRY::Parse(@STRING_POLYGON)	AS POLYGON

END	

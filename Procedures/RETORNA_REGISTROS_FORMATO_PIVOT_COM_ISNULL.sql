CREATE PROCEDURE [dbo].[RETORNA_REGISTROS_FORMATO_PIVOT_COM_ISNULL] 
@TABELA VARCHAR(MAX),
@CAMPO VARCHAR(MAX),
@FORMATO_PIVOT AS VARCHAR(MAX) OUTPUT 
AS
/**********************************************************************************  
Procedure:		[RETORNA_REGISTROS_FORMATO_PIVOT_COM_ISNULL]
Data Criação:	25/03/2014
Autor:			oscar_b
Descrição:		 Procedure complementar à "RETORNA_REGISTROS_FORMATO_PIVOT". È utilizada para retornar os campos de uma tabela no formato pivot substituindo
				 valores nulos por zero. 
				 Ex: [valor1] = ISNULL([valor1], 0), [valor2] = ISNULL([valor2], 0), [valor3] = ISNULL([valor3], 0), [valor4] = ISNULL([valor4], 0) etc
Parâmetros:
@TABELA -> Nome da Tabela
@CAMPO -> Nome do campo que será feito o Pivot Dinâmico
@FORMATO_PIVOT -> Varíavel que receberá a string com a os valores de campos em Formato Pivot com Isnull
**********************************************************************************/  
BEGIN
	DECLARE @QUERY AS NVARCHAR(MAX),
			@DYNAMICPARAMDEC AS NVARCHAR(MAX)

	SET @CAMPO = 'CONVERT(VARCHAR(MAX), ' + @CAMPO + ')'

	SET @QUERY = 'SELECT @CAMPOS = (SELECT DISTINCT '', ['' + ' + @CAMPO + ' + ''] = ISNULL([''+' + @CAMPO + '+''],0)''' + CHAR(13)
	SET @QUERY = @QUERY + 'FROM ' + @TABELA + ' ORDER BY 1 ' + CHAR(13)
	SET @QUERY = @QUERY + 'FOR XML PATH('''')'
	SET @QUERY = @QUERY + ')'
	SET @DYNAMICPARAMDEC = '@CAMPOS VARCHAR(MAX) OUTPUT'
	--print @query 
	
	EXECUTE SP_EXECUTESQL
	@QUERY, 
	@DYNAMICPARAMDEC,
	@FORMATO_PIVOT OUTPUT
	SET @FORMATO_PIVOT = STUFF(@FORMATO_PIVOT, 1,2, '');
END

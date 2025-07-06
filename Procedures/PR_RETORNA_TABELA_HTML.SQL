/*
Descrição: Procedure utilizada para retornar uma string com o código HTML de uma tabela.
				    È recomendado que a tabela não contenha muitas colunas e registros, pois se corre o risco do código inteiro
				    não caber dentro de uma string.
Parâmetros:
@TABELA -> Nome da Tabela ou subquery que terá o código HTML, caso seja uma subquery a string deve conter a query entre parênteses e não
		   pode conter nome de coluna repetida.
@HTML_COMPLETO -> Varíavel que receberá a string com o código HTML especificado na variável da tabela.
@COLUNAS_DESCONSIDERADAS -> Colunas a serem desconsideradas na geração do HTML da Tabela.
@RETURN_EMPTY_TABLE -> Se deverá retornar o cabeçalho da tabela caso a mesma não possua registros
Exemplo de chamda:
  DECLARE @HTML VARCHAR(MAX)
  EXEC [dbo].[PR_RETORNA_TABELA_HTML] 
      @TABELA	 = 'SYS.TABLES'
     ,@HTML_COMPLETO		= @HTML OUTPUT
     ,@COLUNAS_DESCONSIDERADAS = NULL
     ,@RETURN_EMPTY_TABLE = 1
  SELECT @HTML

*/  


CREATE PROCEDURE [dbo].[PR_RETORNA_TABELA_HTML] 
 @TABELA	 NVARCHAR(MAX) 
,@HTML_COMPLETO		AS NVARCHAR(MAX) OUTPUT
,@COLUNAS_DESCONSIDERADAS NVARCHAR(MAX) = NULL
,@RETURN_EMPTY_TABLE BIT = 1
AS
BEGIN
	SET NOCOUNT ON

	DECLARE  @QUERY NVARCHAR(MAX)
			,@MENSAGEM_ERRO NVARCHAR(500)
			,@HTML_CABECALHO NVARCHAR(MAX)
			,@DYNAMICPARAMDEC AS NVARCHAR(MAX) --Variavel importante para o processo de jogar o SQL dinâmico em uma variável
			,@HTML_DADOS AS NVARCHAR(MAX)	   --Variavel que receberá a consulta do SQL dinâmico
			,@TABELA_HTML VARCHAR(500)



--==========================================================
--Joga a tabela em uma tabela Nova
--==========================================================

--SET @TABELA_HTML = '##NOME_TABELA_RANDOMICA'
SET @TABELA_HTML = CONCAT('[##NOME_TABELA_RANDOMICA_', NEWID(), ']')

IF EXISTS (SELECT 1 FROM  tempdb.SYS.TABLES WHERE OBJECT_ID = OBJECT_ID('tempdb..' + @TABELA_HTML))
BEGIN
	SET @QUERY = 'DROP TABLE ' + @TABELA_HTML 
	--PRINT @QUERY
	EXEC (@QUERY)
END



SET @QUERY = 'SELECT *' + CHAR(13)
SET @QUERY = @QUERY + 'INTO ' + @TABELA_HTML + CHAR(13)
SET @QUERY = @QUERY + 'FROM ' + @TABELA + CHAR(13)


--PRINT @QUERY
EXEC (@QUERY)

--Retorna a String Vazio caso não queira a tabela apenas com o cabeçalho
IF @RETURN_EMPTY_TABLE = 0 
	AND EXISTS (SELECT 1 
					FROM tempdb.SYS.partitions
					WHERE object_id = object_id('tempdb..' + @TABELA_HTML)
						AND ROWS = 0)
BEGIN
	SET @HTML_COMPLETO = ''
	RETURN
END

--==========================================================
--Retira Colunas a serem desconsideradas 
--==========================================================
IF @COLUNAS_DESCONSIDERADAS IS NOT NULL
BEGIN
	SET @QUERY = ''
	SET @QUERY = 
	(SELECT 'ALTER TABLE #TABELA DROP COLUMN ' + [value] + ';'
	FROM string_split(@COLUNAS_DESCONSIDERADAS, ',')
	FOR XML PATH('')
	)

	SET @QUERY = REPLACE(@QUERY, '#TABELA', @TABELA_HTML)

	--PRINT @QUERY
	EXEC (@QUERY)

END

--==========================================================
--Verifica se a tabela informada existe no banco de dados
--==========================================================
IF OBJECT_ID('tempdb..' + @TABELA_HTML) IS NULL
BEGIN
	SET @MENSAGEM_ERRO = 'O parâmetro informado como tabela não foi capaz de gerar uma tabela' + CHAR(13)
	RAISERROR(@MENSAGEM_ERRO, 11,1)
	RETURN
END

--==========================================================
--Escrevendo em HTML o cabeçalho da tabela
--==========================================================
SET  @HTML_CABECALHO = '<table class="pure-table" border="12">' + CHAR(13)

SET  @HTML_CABECALHO = @HTML_CABECALHO + '<thead>' + CHAR(13)

SET  @HTML_CABECALHO = @HTML_CABECALHO + '<tr class="firstLine">' + CHAR(13)


SET @HTML_CABECALHO = @HTML_CABECALHO +
(SELECT
	'<td>' + CONVERT(NVARCHAR(MAX), NAME) + '</td>' + CHAR(10)
	FROM tempdb.SYS.columns
	WHERE OBJECT_ID = OBJECT_ID('tempdb..' + @TABELA_HTML)
	ORDER BY COLUMN_ID
	FOR XML PATH('')
)

SET  @HTML_CABECALHO = @HTML_CABECALHO + '</tr>' + CHAR(13)

SET  @HTML_CABECALHO = @HTML_CABECALHO + '</thead>' + CHAR(13)

--Troca caracteres de escape do HTML
SET @HTML_CABECALHO = REPLACE(@HTML_CABECALHO, '&lt;',  '<')
SET @HTML_CABECALHO = REPLACE(@HTML_CABECALHO, '&gt;',  '>')
SET @HTML_CABECALHO = REPLACE(@HTML_CABECALHO, '&amp;', '&')
SET @HTML_CABECALHO = REPLACE(@HTML_CABECALHO, '&#x0D;', '<br>')




--PRINT @HTML_CABECALHO

--==========================================================
--Escrevendo em HTML os dados da tabela
--Para fazer isso, será necessário executar SQL dinâmico e jogar o resultado dessa consulta em uma variável 
--==========================================================

SET @DYNAMICPARAMDEC = '@HTML_DADOS_SQL_DIN NVARCHAR(MAX) OUTPUT'


--Parte Inicial da Query
SET @QUERY = 'SELECT @HTML_DADOS_SQL_DIN = (' + CHAR(13)
SET @QUERY = @QUERY + 'SELECT ' + CHAR(13)
SET @QUERY = @QUERY + '''<tr>'' + CHAR(10)	+'  + CHAR(13)

--Monta a Query que trará os dados
SET @QUERY = @QUERY + CONVERT(NVARCHAR(MAX),
(SELECT
	'''<td>'' + ISNULL(CONVERT(NVARCHAR(MAX),[' + NAME + ']), '''') + ''</td>'' + CHAR(10) + ' + CHAR(10)
	FROM tempdb.SYS.columns
	WHERE OBJECT_ID = OBJECT_ID('tempdb..' + @TABELA_HTML)
	ORDER BY COLUMN_ID
	FOR XML PATH('')
))

--Parte Final da Query
SET @QUERY = @QUERY + '''</tr>'' + CHAR(10)'  + CHAR(13)
SET @QUERY = @QUERY + 'FROM ' + @TABELA_HTML + CHAR(13)
SET @QUERY = @QUERY + 'FOR XML PATH('''')'  + CHAR(13)
SET @QUERY = @QUERY + ')'  + CHAR(13)

SET @QUERY = REPLACE(@QUERY, '&lt;',  '<')
SET @QUERY = REPLACE(@QUERY, '&gt;',  '>')
SET @QUERY = REPLACE(@QUERY, '&amp;', '&')

--PRINT @QUERY

----Executa o SQL dinâmico contido na variável @QUERY
EXECUTE SP_EXECUTESQL
	@QUERY
	,@DYNAMICPARAMDEC
	,@HTML_DADOS OUTPUT
	


--Troca caracteres de escape do HTML
SET @HTML_DADOS = REPLACE(@HTML_DADOS, '&lt;',  '<')
SET @HTML_DADOS = REPLACE(@HTML_DADOS, '&gt;',  '>')
SET @HTML_DADOS = REPLACE(@HTML_DADOS, '&amp;', '&')
SET @HTML_DADOS = REPLACE(@HTML_DADOS, '&#x0D;', '<br>')



--Coloca uma classe para a última linha (pode formatar depois com css
SET @HTML_DADOS =  REVERSE(
							STUFF(REVERSE(@HTML_DADOS), 
								CHARINDEX(REVERSE('<tr>'), REVERSE(@HTML_DADOS)), 
							LEN('<tr>')
					,REVERSE('<tr class="lastLine">')))	
					

--PRINT @HTML_DADOS

--==========================================================
--Monta o HTML definitivo
--==========================================================
SET @HTML_COMPLETO = @HTML_CABECALHO + '<tbody>' + ISNULL(@HTML_DADOS,'') + '</tbody>'
SET @HTML_COMPLETO = @HTML_COMPLETO + '</table>' + CHAR(13)

--PRINT @HTML_COMPLETO


IF EXISTS (SELECT 1 FROM  tempdb.SYS.TABLES WHERE OBJECT_ID = OBJECT_ID('tempdb..' + @TABELA_HTML))
BEGIN
	SET @QUERY = 'DROP TABLE ' + @TABELA_HTML 
--	PRINT @QUERY
	EXEC (@QUERY)
END

SET NOCOUNT OFF

END

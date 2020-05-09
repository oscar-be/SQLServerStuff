
/*
Objetivo:			Fazer um datediff que apresente dia, hora, minuto e segundo (tudo junto) entre 1 períodos de tempo:
Exemplo chamada:	SELECT [dbo].[FN_DATEDIFF_COM_TEXTO]('20200508 14:25:11', '20200508 17:43:56')  
*/

CREATE FUNCTION [dbo].[FN_DATEDIFF_COM_TEXTO] (@DATA_INICIAL DATETIME, @DATA_FINAL DATETIME)
RETURNS VARCHAR(50) AS 
BEGIN
       DECLARE  @DIAS        INT
               ,@HORAS       INT
               ,@MINUTOS     INT
               ,@SEGUNDOS    INT
               ,@TEXTO_SAIDA VARCHAR(50)

       SET @DIAS     =  DATEDIFF(HH, @DATA_INICIAL,  @DATA_FINAL) / 24
       SET @HORAS    = (DATEDIFF(MI, @DATA_INICIAL,  @DATA_FINAL) / 60) -   (@DIAS * 24)
       SET @MINUTOS  = (DATEDIFF(SS, @DATA_INICIAL,   @DATA_FINAL) / 60) - ((@DIAS * 24 * 60)        + (@HORAS * 60))
       SET @SEGUNDOS = (DATEDIFF(SS, @DATA_INICIAL,   @DATA_FINAL)    - ((@DIAS * 24 * 60 * 60) + (@HORAS * 60 * 60) + (@MINUTOS * 60))) * 1.0

       SET @TEXTO_SAIDA = CONCAT(CASE WHEN @DIAS    > 0 THEN CONCAT(@DIAS,    'dia')      ELSE '' END,
                                 CASE WHEN @HORAS   > 0 THEN CONCAT(@HORAS,   'h')        ELSE '' END,
                                 CASE WHEN @MINUTOS > 0 THEN CONCAT(@MINUTOS, 'min')      ELSE '' END,
                                 CASE WHEN @DIAS + @HORAS + @MINUTOS = 0 OR @SEGUNDOS > 0 THEN CONCAT(@SEGUNDOS, 's')  ELSE '' END)

       SET @TEXTO_SAIDA = NULLIF(@TEXTO_SAIDA, '')

       RETURN @TEXTO_SAIDA

END

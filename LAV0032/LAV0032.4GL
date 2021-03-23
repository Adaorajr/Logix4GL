DATABASE LOGIX

#------------------------------------------------------------#
# SISTEMA.:                                                  #
# PROGRAMA: LAV0032                                          #
# OBJETIVO: Consulta Funcionário AD                          #
# AUTOR   :                          #
# DATA    : 26/02/2021                                       #
#------------------------------------------------------------#
# ALTERADO:                                                  #
# AUTOR   :                         #
#------------------------------------------------------------#

GLOBALS
   
  DEFINE p_cod_empresa   LIKE empresa.cod_empresa,
         p_user          CHAR(8),
         p_versao        CHAR(18),
         p_status        SMALLINT

  END GLOBALS

  DEFINE MR_DADOS,     
         MR_DADOSR    RECORD
  		 FILIAL       VARCHAR(6), 
  		 NUMCAD       SMALLINT,
         CPF          DECIMAL(11),
         NOMFUN	      VARCHAR(40),
         DATADM       DATE,
         SITAFA       VARCHAR(20),
         NOMCCU       VARCHAR(80),
         TITCAR       VARCHAR(60),
         NUMEMP       DECIMAL(4)
     END RECORD 
     
          

  DEFINE m_comando      CHAR(80)
  DEFINE m_cnsul		SMALLINT
  
  MAIN
    
  LET p_versao = "LAV0032-12.01.01" #Favor nao alterar esta linha (SUPORTE)
  
  WHENEVER ERROR CONTINUE
  CALL log1400_isolation()
  SET LOCK MODE TO WAIT
  WHENEVER ERROR STOP
  
  DEFER INTERRUPT
  
  CALL log001_acessa_usuario("PADRAO","LOGERP;LOGLQ2")
     RETURNING p_status,p_cod_empresa,p_user

 IF p_status = 0 THEN
    CALL LAV0032_controle()
 END IF
  
 END MAIN
 
 #---------------------------#
 FUNCTION LAV0032_controle()
 #---------------------------#

  CALL log006_exibe_teclas('01',p_versao)
  CALL log130_procura_caminho('LAV0032') RETURNING m_comando 	 
  OPEN WINDOW w_LAV0032  AT 2,2 WITH FORM m_comando
       ATTRIBUTE(BORDER, MESSAGE LINE LAST, PROMPT LINE LAST)

  MENU 'MENU'
      
      COMMAND "Consultar" "Informe a Matricula, Cpf ou Nome."
	     HELP 008
	     CALL LAV0032_Consultar()
	  
	  COMMAND "Seguinte"   "Exibe registro seguinte"
         MESSAGE ""
          CALL LAV0032_paginacao("SEGUINTE")
         
     COMMAND "Anterior"   "Exibe registro anterior"
        MESSAGE ""
         CALL LAV0032_paginacao("ANTERIOR")
	   
      COMMAND "Fim" "Retorna ao menu anterior."
	     HELP 008
	     EXIT MENU
  
  END MENU
  WHENEVER ERROR CONTINUE
  CLOSE WINDOW w_LAV0032
  WHENEVER ERROR STOP
 
 END FUNCTION


 #---------------------------#
 FUNCTION LAV0032_Consultar()
 #---------------------------#
 
 DEFINE sql_stmt         VARCHAR(200),
        where_clause 	 VARCHAR(100)

  CLEAR FORM
  INITIALIZE mr_dados.*  TO NULL

  IF m_cnsul = FALSE THEN
  MESSAGE "Consulte previamente!" ATTRIBUTE(REVERSE)
  END IF
  
  CONSTRUCT BY NAME where_clause ON FILIAL, NUMCAD, CPF, NOMFUN, SITAFA

  END CONSTRUCT

  IF INT_FLAG THEN
     LET INT_FLAG = FALSE
     MESSAGE "Consulta cancelada." ATTRIBUTE(REVERSE)
     RETURN
  END IF
  
   LET sql_stmt = "SELECT * ",
   			      " FROM VW_LAV_LAV0032",
                  " WHERE 1=1 ",                                                                               
                  " AND ", where_clause

PREPARE var_query FROM sql_stmt
  DECLARE cq_cnsul SCROLL CURSOR WITH HOLD FOR var_query
     OPEN cq_cnsul
    FETCH cq_cnsul INTO mr_dados.*
    					    
  IF sqlca.sqlcode = 0 THEN                 
     MESSAGE "Consulta efetuada com sucesso." ATTRIBUTE (REVERSE)
     LET m_cnsul = TRUE                     
     CALL LAV0032_exibir()
  ELSE                                      
     LET m_cnsul = FALSE                    
     CALL LOG0030_MENSAGEM ("Dados não Encontrados","!")       
  END IF

 END FUNCTION

#-----------------------------------#
 FUNCTION LAV0032_exibir()
#-----------------------------------#

DISPLAY BY NAME MR_DADOS.FILIAL,
                MR_DADOS.NUMCAD,
                MR_DADOS.CPF,
                MR_DADOS.NOMFUN,
                MR_DADOS.DATADM,
                MR_DADOS.SITAFA,
                MR_DADOS.NOMCCU,
                MR_DADOS.TITCAR

END FUNCTION

#-----------------------------------#
 FUNCTION LAV0032_paginacao(p_funcao)
#-----------------------------------#
  DEFINE p_funcao       CHAR(20)
  
  LET mr_dadosr.* = mr_dados.*
  
  WHILE TRUE
    IF p_funcao = "SEGUINTE" THEN
      FETCH NEXT cq_cnsul INTO mr_dados.*
    ELSE
      FETCH PREVIOUS cq_cnsul INTO mr_dados.*
    END IF
    
    IF sqlca.sqlcode = 0 THEN
      WHENEVER ERROR CONTINUE
        SELECT * FROM VW_LAV_LAV0032 WHERE 1=1 AND numcad = mr_dados.numcad AND numemp = mr_dados.numemp
      WHENEVER ERROR STOP
        
        IF sqlca.sqlcode = 0 THEN
          IF (mr_dados.numcad = mr_dadosr.numcad AND mr_dados.numemp = mr_dadosr.numemp) THEN
            CONTINUE WHILE
          END IF
          EXIT WHILE
        
        ELSE
          LET mr_dados.* = mr_dadosr.*
          CONTINUE WHILE
        END IF
        
        SLEEP 2
        
        CALL LAV0032_exibir()
    
    ELSE
      MESSAGE 'Não existem mais dados nessa dir'
      EXIT WHILE
    
    END IF
    
  END WHILE
  
  CALL LAV0032_exibir()
 
 END FUNCTION

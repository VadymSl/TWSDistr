//I1TWSUX1   JOB    NOTIFY=&SYSUID,CLASS=S                              J0182789
//*JOBPARM SYSAFF=WAP1                                                          
//*                                                                             
//   SET  SOURCE=TWSZWAP.EXIT                                                   
//*  SET  SOURCE=IVSLO.EXIT                                                     
//*  SET  OUTLIB=IVSLO.LINKLIB                                                  
//*  SET  OUTLIB=TWSZWAD.LINKLIB                                                
//*  SET  OUTLIB=TWSZWAM.LINKLIB                                                
//   SET  OUTLIB=ZWAP.AUTHLIB.TWS                                               
//*                                                                             
//*  10/07/2017 assign user UDB2P for application MDB2#01CC*                    
//*                                                                             
//*  13/08/2013 add logic of selection of DB members to EQQUX001 to             
//*  serve submition of tenth of jobs in a few seconds                          
//*                                                                             
//*  13/06/2013 usage of macro MTRWADAT MTRDBENT WA7REC07                       
//*  06/12/2012 added MODJCLAF for ZMTRUS01 colaboration                        
//*  18/05/2006 user YATWS for R* appls                                         
//*  18/05/2006 user YATECH for U* appls                                        
//*  01/12/2017 user UDBAUTO, UDB2AUTH, UDB2P                                   
//*  10/08/2023 save DB2 weights after each refresh of weights                  
//*    if all weights are decrease to 1 during mass JCL submittion              
//*    then they are restored from saved copy                                   
//* DBENTNM is added to MTRWADAT macro to is increased to 40, as half           
//*    of allocated for DBLST storage is used for keeping saved copy.           
//*   23/08/23  SET_RUSE1 version for ZWAP                                      
//*                                                                             
//*                                                                             
//* ----------                                                                  
//* PROCEDURES:                                                                 
//* ----------                                                                  
//* SET_RUSE1:                                                                  
//*    SET THE RACF USER ACCORDING TO JOBNAME CHECK                             
//* CHKDISTR:                                                                   
//*    check if APPL should be distributed for DB2 selection                    
//*    according to GROUP AUTH ID value                                         
//* INITMCAU:                                                                   
//*    check and initialise work area from MCAUSER                              
//* SELFINAL                                                                    
//*    final analisys which DB2 subs NO selected                                
//* MODJCLAF                                                                    
//*    modify JCL according to DB2 selected                                     
//*                                                                             
//********************************************************************          
//ASMH     EXEC PGM=ASMA90,REGION=2048K,                                        
//         PARM='NODECK,OBJECT,XREF(SHORT),LIST,NORLD'                          
//SYSPRINT DD  SYSOUT=*                                                         
//SYSLIB   DD  DISP=SHR,DSN=SYS1.MACLIB                                         
//         DD  DISP=SHR,DSN=&SOURCE                                             
//SYSLIN   DD  UNIT=SYSDA,SPACE=(CYL,(2,1)),DISP=(,PASS),DSN=&&OBJ              
//SYSUT1   DD  UNIT=SYSDA,SPACE=(CYL,(2,1))                                     
//SYSIN    DD  *                                                                
         TITLE '  EQQUX001: OPC JOB SUBMIT USER EXIT'                           
EQQUX001 CSECT ,                                                                
@MAINENT DS    0H                                                               
         USING *,R15                                                            
         B     @PROLOG                                                          
         DC    AL1(16)                                                          
         DC    C'EQQUX001  03.201'                                              
         DROP  R15                                                              
@PROLOG  DS    0H                                                               
         STM   R14,R12,12(R13)         * SAVE REGISTERS                         
         LR    R12,R15                                                          
         USING EQQUX001,R12                                                     
         L     R0,@SIZDATD                                                      
         GETMAIN  R,LV=(0)                                                      
         LR    R10,R1                                                           
         USING @DATD,R10                                                        
         ST    R13,4(,R10)                                                      
         ST    R10,8(,R13)                                                      
         LM    R15,R1,16(R13)          * RESTORE REGISTERS                      
         LR    R13,R10                                                          
         MVC   PARMLST1(120),0(R1)                                              
                                                                                
*********************************************************************           
* MAIN EXECUTION BLOCK                                              *           
*********************************************************************           
                                                                                
MAIN     DS    0H                            MAIN PROGRAM                       
*---------------------------------------------------------------------          
*   INIT RETCO TO 0                                                             
*---------------------------------------------------------------------          
         L     R1,RETCO                                                         
         MVC   0(4,R1),RETVAL0               INIT RC=0                          
*---------------------------------------------------------------------          
*   INIT USDREC TO 0                                                            
*---------------------------------------------------------------------          
         L     R1,USDREC                                                        
         MVC   0(4,R1),=F'0'                 INIT USDREC=0                      
*        WTO   MF=(E,DMMSG)              ******************                     
         SLR   R15,R15                                                          
*---------------------------------------------------------------------          
*   SET RUSER:                                                                  
*---------------------------------------------------------------------          
         BAL   R14,SET_RUSE1                 CALL SET_RUS1                      
*---------------------------------------------------------------------          
*   Modify JCL section for DB2 distribution                                     
*  CHKDISTR sets R6 which is used in CHECKFNL and SELCKFNL                      
*                                                                               
*---------------------------------------------------------------------          
         BAL   R14,CHKDISTR   check if APPL should be distributed               
         LTR   R15,R15                                                          
         BNZ   @NMODJCL       if NO exit                                        
         BAL   R14,INITMCAU   check and init from MCAUSER                       
         LTR   R15,R15                                                          
         BNZ   @NMODJCL       if MCAUSERF not prepeared exit                    
*                                                                               
         BAS   R14,CLEARWGT   clear saved WEIGHTs periodicaly                   
*        BAS   R14,PRWEIGHT   print WEIGHTs                                     
         BAS   R14,CHWEIGHT   check WEIGHTs and save/restore if needed          
         BAS   R14,SELFINAL   final analisys which DB2 subs NO selected         
         ST    R15,SELSYSNO   save selected system NO                           
                                                                                
         BAL   R14,MODJCLAF   modify JCL according to DB2 selected              
@NMODJCL DS    0H                                                               
*---------------------------------------------------------------------          
*   End of modify JCL section for DB2 distribution                              
*---------------------------------------------------------------------          
EXIT_MAIN DS   0H                           EXIT MAIN PROGRAM                   
         LR    R2,R15                                                           
         LR    R1,R10                                                           
         L     R13,4(,R13)                                                      
         L     R0,@SIZDATD                                                      
         FREEMAIN R,LV=(0),A=(1)                                                
         LR    R15,R2                                                           
         L     R14,12(,R13)                  EXIT MAIN PROGRAM                  
         LM    R0,R12,20(R13)                RESTORE REGISTERS                  
         BR    R14                           RETURN TO CALLER                   
                                                                                
*===============VVV230803============================================           
* PROC: CLEARWGT                                                                
*    clear  weights every 4096 job run                                          
* input  :                                                                      
* returns:                                                                      
*====================================================================           
CLEARWGT DS    0H                                                               
                                                                                
         STM   R14,R12,12(R13)              SAVE REGISTERS                      
                                                                                
         L     R4,DBSUBCLC num of entries to R4                                 
         L     R3,PDBLIST                                                       
         USING DBENTRY,R3                                                       
         XR    R5,R5                                                            
                                                                                
*        MVC   OUTSTR1(1),SPACESTR                                              
*        MVC   OUTSTR1+1(79),OUTSTR1  clear OUTSTR1                             
*        MVC   OUTSTR1(9),=C'Total num'                                         
                                                                                
*   process count JOB  calculation loop                                         
@CLRWGT  DS    0H                                                               
                                                                                
*        LA    R1,DBJOBCL5                                                      
         AL    R5,DBJOBCL5                                                      
         AL    R5,DBJOBCL4                                                      
         AL    R5,DBJOBCL3                                                      
         AL    R5,DBJOBCLC                                                      
                                                                                
         LA    R3,DBENTSZ(R3)  size of DB entry                                 
                                                                                
         BCT   R4,@CLRWGT  goto loop                                            
                                                                                
*        ST    R4,OUTSTR1+10                                                    
*        MVC   OUTSTR1+16(16),0(R1)                                             
         LR    R7,R5       save for printing                                    
         LA    R6,20       shifting left to obtain 0 after some        *        
                             number of repeated execution              *        
                             20 = every 4096 submissions                        
         SLL   R5,0(R6)    R6 contains shift value                              
         LTR   R5,R5                                                            
         BNZ   @CLRNOT                                                          
                                                                                
*    clear saved weight copy. For all WEIGHTs assighn value 5                   
*                            unless current saved WEIGHT == 0                   
         L     R4,DBSUBCLC num of entries to R4                                 
         L     R3,PDBLIST                                                       
         USING DBENTRY,R3                                                       
         LA    R1,5                                                             
                                                                                
@CLRWGTS DS    0H                                                               
         L     R6,DBWEIGHT+WASAVSHF                                             
         LTR   R6,R6                                                            
         BZ    @CLRNO                                                           
         ST    R1,DBWEIGHT+WASAVSHF                                             
                                                                                
@CLRNO   DS    0H                                                               
         LA    R3,DBENTSZ(R3)  size of DB entry                                 
                                                                                
         BCT   R4,@CLRWGTS  clear weight loop                                   
                                                                                
*        MVC   OUTSTR1(5),=C'clring W'                                          
*        ST    R7,OUTSTR1+10                                                    
*        LA    R1,OUTSTR1                                                       
*        MVC   WTOTEXT(60),OUTSTR1                                              
*        BAL   R14,WTO                                                          
                                                                                
@CLRNOT  DS    0H                                                               
                                                                                
         DROP  R3                                                               
                                                                                
                                                                                
         L     R14,12(,R13)                                                     
         LM    R0,R12,20(R13)                RESTORE REGISTERS                  
         BR    R14                           RETURN TO CALLER                   
                                                                                
*===============VVV230803============================================           
* PROC: CHWEIGHT                                                                
*     check if there is copy of DB list with initial weights.                   
*     If current weights (decreased during submition) all 1                     
*     copy from weights frome saved                                             
*     If at least one of current weights grater then saved one                  
*     copy from current weights to saved (current weights are new               
*     weights obtained from last WLM query)                                     
* input  :  R6 should be prepared in CHKDISTR                                   
* returns: R15 returns 0 if no changes to WLM weights in list                   
*====================================================================           
CHWEIGHT DS    0H                                                               
                                                                                
         STM   R14,R12,12(R13)              SAVE REGISTERS                      
         L     R2,PDBLIST                                                       
         USING DBENTRY,R2                                                       
                                                                                
@CWEIGHT DS    0H                                                               
         L     R4,DBSUBCLC num of subs to R4                                    
         LA    R8,1        value 1 for use in loop                              
         LA    R7,1        indicator if there is weight > 1                     
                                                                                
@CWLOOP  DS    0H                                                               
*         check if DB2 member excluded from distribution                        
*         R7 will contain value > 1 if not all WEIGHTs == 1                     
         L     R6,STSSHIFT get shift frome saved  copy                          
         L     R3,DBSTS    get status from monitor                              
         SLL   R3,0(R6)    R6 has shift to obtain                               
         SRL   R3,31                                                            
         LTR   R3,R3                                                            
         BZ    @CNOSTS     if status 0 do not process-DB2 excluded              
*        MVC   WTOTEXT(11),=C'STS passed.'                                      
*        BAL   R14,WTO                                                          
         L     R5,DBWEIGHT  get WLM weight for DB2 sub                          
         L     R1,DBWEIGHT+WASAVSHF get saved WLM weight                        
         CR    R5,R1                                                            
         BC    B'0010',@CREFCPY branch if R5 high                               
*        B     @CNO1WGH                                                         
         CR    R5,R8       compare if weight > 1                                
         BC    B'0010',@CNO1WGH branch if R5 > 1                                
         B     @CNOACT                                                          
@CNOSTS  DS    0H       if WEIGHT == 1 then R7 remains unchanged                
*        MVC   WTOTEXT(11),=C'NO STS pass'                                      
*        BAL   R14,WTO                                                          
         B     @CNOACT                                                          
@CNO1WGH DS    0H            if current weight > 1 move it to R7                
         LR    R7,R5                                                            
                                                                                
@CNOACT  DS    0H                                                               
         LA    R2,DBENTSZ(R2)                                                   
         BCT   R4,@CWLOOP                                                       
                                                                                
*        XC    OUTSTR2,OUTSTR2                                                  
*        MVC   OUTSTR2+1(79),OUTSTR2                                            
*        MVC   OUTSTR2(5),=C'Max W'                                             
*        ST    R7,OUTSTR2+12                                                    
*        MVC   WTOTEXT(60),OUTSTR2                                              
*        BAL   R14,WTO                                                          
         BCT   R7,@ENDCW    if max wght(R7)>1 do not refresh weights            
*   copy weights from saved                                                     
@CREFCUR DS    0H                                                               
         L     R4,DBSUBCLC num of subs to R4                                    
         L     R2,PDBLIST                                                       
@CWCCUR  DS    0H                                                               
         LA    R1,DBWEIGHT                                                      
         L     R3,DBWEIGHT                                                      
         LTR   R3,R3                                                            
         BZ    @CWSKIP     curr wght 0 - DB2 can be down-do not restore         
         MVC   DBWEIGHT,WASAVSHF(R1)                                            
@CWSKIP  DS    0H                                                               
         LA    R2,DBENTSZ(R2)                                                   
         BCT   R4,@CWCCUR                                                       
         B     @ENDCW       to finish point                                     
                                                                                
*  copy current to saved copy                                                   
@CREFCPY DS    0H        saved copy need be refreshed                           
         L     R4,DBSUBCLC num of subs to R4                                    
         L     R2,PDBLIST                                                       
@CWCPLP  DS    0H                                                               
         MVC   WASAVSHF(DBENTSZ,R2),0(R2)                                       
         LA    R2,DBENTSZ(R2)                                                   
         BCT   R4,@CWCPLP                                                       
                                                                                
@ENDCW   DS    0H                                                               
         LR    R15,R3                                                           
                                                                                
         DROP  R2                                                               
                                                                                
         L     R14,12(,R13)                                                     
         LM    R0,R12,20(R13)                RESTORE REGISTERS                  
         BR    R14                           RETURN TO CALLER                   
                                                                                
*===============VVV230803============================================           
* PROC: PRWEIGHT                                                                
*     print weights                                                             
* input  :                                                                      
* returns: R15 returns 0 if no changes to WLM weights in list                   
*====================================================================           
PRWEIGHT DS    0H                                                               
                                                                                
         STM   R14,R12,12(R13)              SAVE REGISTERS                      
                                                                                
         L     R4,DBSUBCLC num of entries to R4                                 
         L     R3,PDBLIST                                                       
         USING DBENTRY,R3                                                       
                                                                                
         MVC   OUTSTR1(1),SPACESTR                                              
         MVC   OUTSTR2(1),SPACESTR                                              
         MVC   OUTSTR1+1(79),OUTSTR1  clear OUTSTR1                             
         LA    R2,OUTSTR1                                                       
         LA    R5,OUTSTR2+1                                                     
                                                                                
*   process WLM weight calculation loop                                         
@PRWGHT  DS    0H                                                               
                                                                                
         MVC   0(4,R2),LSYSNAM                                                  
         MVC   4(4,R2),DBWEIGHT                                                 
         MVC   0(4,R5),LSYSNAM+WASAVSHF                                         
         MVC   4(4,R5),DBWEIGHT+WASAVSHF                                        
         LA    R3,DBENTSZ(R3)  size of DB entry                                 
         LA    R2,8(,R2)       scroll list                                      
         LA    R5,8(,R5)       scroll list                                      
                                                                                
                                                                                
         BCT   R4,@PRWGHT  goto loop                                            
                                                                                
         DROP  R3                                                               
                                                                                
         LA    R1,OUTSTR1                                                       
*        BAS   R14,INSRTIME first 9 chars of OUTSTR1                            
         MVC   WTOTEXT(60),OUTSTR1                                              
         BAL   R14,WTO                                                          
                                                                                
         L     R14,12(,R13)                                                     
         LM    R0,R12,20(R13)                RESTORE REGISTERS                  
         BR    R14                           RETURN TO CALLER                   
                                                                                
*==================================================================             
* PROC: INSRTIME                                                                
*      Insert TIME into first 9 chars starting from R1 address                  
*                                                                               
* input  :                                                                      
* returns:                                                                      
*====================================================================           
INSRTIME DS    0H                                                               
         BAKR  R14,0       save regs on linkage stack                           
*              put current time to string                                       
         LR    R3,R1                                                            
         TIME  DEC         get current time                                     
         ST    R0,TMPSTR     store to outstr                                    
*                                                                               
         MVC   0(9,R3),TIMEPTRN                                                 
         ED    0(9,R3),TMPSTR                                                   
         PR                                                                     
*        BR   R14                                                               
                                                                                
*====================================================================           
* PROC: SET_RUSE1                                                               
*       SET RUSER ACCORDING TO JOBNAME                                          
*       - CUSTOMIZE USED VALUES ACCORDING TO YOUR NEEDS        <===             
*         (LOOK FOR USM3 TO LOCATE DEFINITIONS)                <===             
*====================================================================           
SET_RUSE1 DS    0H                           LOCAL PROCEDURE                    
         STM   R14,R12,12(R13)               SAVE REGISTERS                     
**********************************                                              
         L     R1,ADID                       GET APL NAME ADDR                  
         L     R2,JOBNAME                    GET JOBNAME ADDR                   
         CLC   ADIDZ(1,R1),APPRZS            CHECK OWNERID=S*                   
         BE    CHKPOK                        NO HIT: GO TO CHK2                 
         CLC   ADIDZ(1,R1),APPRZR            CHECK OWNERID=S*                   
         BNE   CHK2                          NO HIT: GO TO CHK2                 
CHKPOK   L     R1,RUSER                      HIT: SET RUSER                     
         MVC   RUSERZ(8,R1),USERPRZT                TO YATWS                    
         B     EXIT_SET_RUSE1                EXIT PROCEDURE                     
CHK2     CLC   ADIDZ(1,R1),APTECH            CHECK OWNERID=T*                   
         BE    CHKTOK                        NO HIT: go to CHK3                 
         CLC   ADIDZ(1,R1),APTECHU           CHECK OWNERID=T*                   
         BNE   CHK3                          NO HIT: go to CHK3                 
CHKTOK   L     R1,RUSER                      HIT: SET RUSER                     
         MVC   RUSERZ(8,R1),USERTECH               TO YATECH                    
         B     EXIT_SET_RUSE1                EXIT PROCEDURE                     
CHK3     CLC   ADIDZ(1,R1),APMNT             CHECK if starts from M             
         BE    CHKMOK                        HIT: USERMNT                       
         CLC   ADIDZ(1,R1),APMNT1            CHECK if starts from D             
         BE    NORMMNT                       NO HIT: EXIT PROCEDURE             
CHKMOK   DS    0H                                                               
         CLC   ADIDZ(09,R1),=C'MDB2#01CC'    CHECK if DB2 MNT appl              
         BNE   CHKNODB2                      HIT: USER DB2 MNT                  
         L     R1,RUSER                                                         
         MVC   RUSERZ(8,R1),=C'UDB2P   '                                        
         B     EXIT_SET_RUSE1                                                   
*************************                                                       
CHKNODB2 DS    0H                                                               
         CLC   ADIDZ(14,R1),=C'MAUT#01DBPGV$1' if AUTDB2 appl                   
         BNE   CHKNODB3                      HIT: USER DB2 MNT                  
         L     R1,RUSER                                                         
         MVC   RUSERZ(8,R1),=C'UDB2AUTH'                                        
         B     EXIT_SET_RUSE1                                                   
CHKNODB3 DS    0H                                                               
         CLC   ADIDZ(14,R1),=C'MDB2#01ARCRP$1' if AUTDB2 appl                   
         BNE   CHKNODB4                      HIT: USER DB2 MNT                  
         L     R1,RUSER                                                         
         MVC   RUSERZ(8,R1),=C'UDBAUTO '                                        
         B     EXIT_SET_RUSE1                                                   
CHKNODB4 DS    0H                                                               
         CLC   ADIDZ(14,R1),=C'MDB2#01IMGCQ$1' if AUTDB2 appl                   
         BNE   CHKNODB5                      HIT: USER DB2 MNT                  
         L     R1,RUSER                                                         
         MVC   RUSERZ(8,R1),=C'UDBAUTO '                                        
         B     EXIT_SET_RUSE1                                                   
CHKNODB5 DS    0H                                                               
         CLC   ADIDZ(14,R1),=C'MDB2#01RAPAR$1' if AUTDB2 appl                   
         BNE   CHKNODB6                      HIT: USER DB2 MNT                  
         L     R1,RUSER                                                         
         MVC   RUSERZ(8,R1),=C'UDBAUTO '                                        
         B     EXIT_SET_RUSE1                                                   
CHKNODB6 DS    0H                                                               
         CLC   ADIDZ(14,R1),=C'MDB2#01REOSP$1' if AUTDB2 appl                   
         BNE   CHKNODB7                      HIT: USER DB2 MNT                  
         L     R1,RUSER                                                         
         MVC   RUSERZ(8,R1),=C'UDBAUTO '                                        
         B     EXIT_SET_RUSE1                                                   
CHKNODB7 DS    0H                                                               
         CLC   ADIDZ(14,R1),=C'MDB2#01SRVTB$1' if AUTDB2 appl                   
         BNE   CHKNODB8                      HIT: USER DB2 MNT                  
         L     R1,RUSER                                                         
         MVC   RUSERZ(8,R1),=C'UDBAUTO '                                        
         B     EXIT_SET_RUSE1                                                   
****************                                                                
CHKNODB8 L     R1,RUSER                                                         
         CLC   JOBNAMEZ(7,R2),=C'I1AVTWS'    if jobanme I1AVTWS*                
         BNE   NORMMNT                                                          
         MVC   RUSERZ(8,R1),=C'UAVLUSR '                                        
         B     EXIT_SET_RUSE1                                                   
NORMMNT  L     R1,RUSER                                                         
         MVC   RUSERZ(8,R1),USERMNT                TO UTWS                      
         B     EXIT_SET_RUSE1                EXIT PROCEDURE                     
CHK5     CLC   ADIDZ(1,R1),APSYS             CHECK OWNERID=R*                   
         BNE   EXIT_SET_RUSE1                NO HIT: EXIT PROCEDURE             
         L     R1,RUSER                      HIT: SET RUSER                     
         MVC   RUSERZ(8,R1),USERSYS                TO UTWS                      
EXIT_SET_RUSE1 DS    0H                      EXIT PROCEDURE                     
         SLR   R15,R15                                                          
         L     R14,12(,R13)                                                     
         LM    R0,R12,20(R13)                RESTORE REGISTERS                  
         BR    R14                           RETURN TO CALLER                   
                                                                                
*====================================================================           
* PROC: INITMCAU                                                                
*   initialize and check data poined by MCAUSERF                                
*====================================================================           
INITMCAU DS    0H                          LOCAL PROCEDURE                      
         STM   R14,R12,12(R13)              SAVE REGISTERS                      
         L     R4,MCAUSERF                                                      
         L     R4,0(R4)                 addr of pointer ZMTRUS01 buffer         
         LA    R15,1                    store non successfull return            
         LTR   R4,R4                                                            
         BNZ   @UX000OK                                                         
         MVC   WTOTEXT(18),=C'No proper EQQUX000'                               
         BAL   R14,WTO                                                          
         B     @EXITCAU                                                         
@UX000OK DS    0H                                                               
                                                                                
         L     R4,0(R4)                 WA -storage pointed by MCAUSERF         
         USING @WADAT,R4                                                        
                                                                                
* check if ZMTRUS01 is active                                                   
         L     R5,WAINDAM               store first word of WA                  
         LTR   R5,R5                    is monitor active ?                     
         BZ    @EXINMCA                 0 means NO                              
         MVC   DBSUBCLC(4),WASUBCLC     num of DB2 subs                         
         LA    R5,WADATSZ(0,R4)         R5 points after WA for DBen             
         ST    R5,PDBLIST               save DBLIST address                     
         XR    R15,R15                  store successfull return                
         DROP  R4                                                               
         B     @EXITCAU                                                         
@EXINMCA DS    0H                            EXIT PROCEDURE                     
         MVC   WTOTEXT(15),=C'No distribution'                                  
         BAL   R14,WTO                                                          
         LA    R15,1                    store non successfull return            
@EXITCAU DS    0H                       EXIT PROCEDURE                          
         L     R14,12(,R13)                                                     
         LM    R0,R12,20(R13)           RESTORE REGISTERS                       
         BR    R14                      RETURN TO CALLER                        
*====================================================================           
* PROC: CHKDISTR                                                                
*   Check if aplication should be distributed checking GROUP AUTH ID            
*   if NO return in R15 1 else 0                                                
* if R15=0 R6 contains value for shift of correspondent bit in DBSTS            
* R6 should be preserved as it is used by following procedures                  
*====================================================================           
CHKDISTR DS    0H                                                               
         STM   R14,R12,12(R13)                                                  
         XR    R15,R15            prepare successful return                     
         L     R6,GROUP            check AUTH group name                        
         CLC   0(8,R6),=C'DB2DISTR' is AUTH GR = DB2DISTR ?                     
         BNE   @CHKMJA3           if no next check                              
         LA    R6,31                                                            
         MVC   INDYC(14),=C'  <-DB2distr->'  set indicator in JCL               
         B     @MJACHNG                                                         
@CHKMJA3 DS    0H                                                               
         CLC   0(8,R6),=C'DB2DIST3' is AUTH GR = DB2DIST3 ?                     
         BNE   @CHKMJA4           if no next check                              
         LA    R6,30                                                            
         MVC   INDYC(14),=C'  <-DB2dist3->'  set indicator in JCL               
         B     @MJACHNG                                                         
@CHKMJA4 DS    0H                                                               
         CLC   0(8,R6),=C'DB2DIST4' is AUTH GR = DB2DIST4 ?                     
         BNE   @CHKMJA5           if no next check                              
         LA    R6,29                                                            
         MVC   INDYC(14),=C'  <-DB2dist4->'  set indicator in JCL               
         B     @MJACHNG                                                         
@CHKMJA5 DS    0H                                                               
         CLC   0(8,R6),=C'DB2DIST5' is AUTH GR = DB2DIST5 ?                     
         BNE   @CHKDNOK         if no - not for DB2 distribution                
         LA    R6,28                                                            
         MVC   INDYC(14),=C'  <-DB2dist5->'  set indicator in JCL               
         B     @MJACHNG                                                         
@CHKDNOK LA    R15,1              unsuccesfull ret Val                          
                                                                                
@MJACHNG DS   0H                                                                
         ST    R6,44(R13)                    save R6                            
         ST    R6,STSSHIFT                   save R6                            
         L     R14,12(,R13)                                                     
         LM    R0,R12,20(R13)                RESTORE REGISTERS                  
         BR    R14                           RETURN TO CALLER                   
*====================================================================           
* PROC: MODJCLAF                                                                
*   modifies SYSAFF and SYSTEM(DB according to data pointed by MCAUSERF         
*   R6 should be preserved from CHKDISTR                                        
*====================================================================           
MODJCLAF  DS    0H                                                              
         STM   R14,R12,12(R13)                                                  
                                                                                
         L     R5,PDBLIST                                                       
         USING DBENTRY,R5                                                       
         L     R2,SELSYSNO                                                      
         BCTR  R2,0                         decrease  by 1                      
         MHI   R2,DBENTSZ                   shift of DB clone in R3             
         LA    R5,0(R2,R5)                  SUBLST + shift                      
                                                                                
         LA    R7,28          28 should be subtracted                           
         SR    R6,R7          R6 conteins returned by CHKDISTR                  
         MHI   R6,4           shift for DBJOBCLx                                
                                                                                
         L     R2,JCLAREA                   JCL start addr in R2                
         L     R3,JCLLEN                                                        
         L     R3,0(R3)                     JCL length in R3                    
         LA    R7,15                         R6=15                              
         SR    R3,R7                         R3 = JCLLEN - R6                   
                                                                                
* update SYSAFF statment in JCL submited by TWS                                 
                                                                                
                                                                                
@LKJCLLP DS    0H                                                               
         CLC   0(3,R2),=C'SYS'               check for SYS prefix               
         BNE   @NOTDB2S                                                         
                                                                                
         CLC   0(7,R2),=C'SYSAFF='           check for SYSAFF keyword           
         BNE   @NOTAFF                                                          
                                                                                
         MVC   7(4,R2),LSYSNAM               update SYSAFF  WASYSNAM            
         MVI   11(R2),C' '                                                      
         MVC   44(14,R2),INDYC               set indicator in JCL               
         B     @NOTDB2S                                                         
                                                                                
@NOTAFF  DS    0H                            SYSAFF keyword not found           
                                                                                
         CLC   0(9,R2),=C'SYSTEM(DB'         check for SYSTEM keyword           
         BNE   @NOTDB2S                                                         
*        CLC   7(2,R2),DBPRFNM     WADB2NAM  check for DB2 prf keyword          
*        BNE   @NOTDB2S                                                         
         MVC   9(2,R2),DBCLONM     WADB2NAM                                     
                                                                                
@NOTDB2S DS    0H                            SYSTEM keyword NOT found           
         LA    R2,1(,R2)                     next JCL char                      
         BCT   R3,@LKJCLLP                                                      
                                                                                
* increase JOBCLC by 1 for correspondent LPAR's counter                         
                                                                                
         LA    R2,DBJOBCL5                    address of first counter          
         LA    R3,0(R6,R2)                    add shift to needed cntr          
         ASI   0(R3),1                        increase by 1 count               
* decrease DBWEIGHT by DBMULT after one job run                                 
         L     R2,DBWEIGHT DB2 subs weight returned by WLM to R5                
         L     R1,DBMULT   DB2 sub num in LPAR                                  
         SR    R2,R1                                                            
         BC    B'0010',@XXSUBTR  if R2 >  R1 branch                             
         LA    R2,1                                                             
@XXSUBTR DS    0H                                                               
         ST    R2,DBWEIGHT store decreased weight                               
* vvvvvvvvv                                                                     
*        MVC   WTOTEXT(28),DBENTRY                                              
*        BAL   R14,WTO                                                          
*        MVI   WTOTEXT,C' '                                                     
*        MVC   WTOTEXT+1(28),DBENTRY+28                                         
*        BAL   R14,WTO                                                          
         DROP  R5                                                               
                                                                                
EXIT_MJA DS    0H                            EXIT PROCEDURE                     
         SLR   R15,R15                                                          
         L     R14,12(,R13)                                                     
         LM    R0,R12,20(R13)                RESTORE REGISTERS                  
         BR    R14                           RETURN TO CALLER                   
*====================================================================           
* PROC: SELFINAL                                                                
*     Final analisys before selecting of best DB2 subsystem.                    
*     This routine checks weights of DB2 members returned by WLM                
*     and statuses of DB2 members returned by monitors. It selects              
*     DB2 member whith maximum WLM weight among allowed for selection           
*     by DB2 monitors. If none of DB2 member is allowed by DB2 monitors         
*     it selects DB2 member with maximum WLM weight                             
* input  : R6 contains shift for calculating DB2 monitor status bit             
* returns: R15 contains selected system NO                                      
*====================================================================           
SELFINAL DS    0H                                                               
                                                                                
         STM   R14,R12,12(R13)              SAVE REGISTERS                      
                                                                                
         L     R2,PDBLIST                                                       
         USING DBENTRY,R2                                                       
                                                                                
@SELFOUT DS    0H                                                               
         XR    R1,R1       indicator                                            
         XR    R7,R7       selected sub no WLM+MTR                              
         XR    R8,R8       selected sub no WLM                                  
         L     R4,DBSUBCLC num of subs to R4                                    
                                                                                
@SFLOOP  DS    0H                                                               
         L     R5,DBWEIGHT  get WLM weight for DB2 sub                          
         CR    R8,R5                                                            
         BC    B'0010',@SNOTPR2 branch if R8 high                               
         LR    R8,R5       store max to R8 not counting monitors status         
         LR    R11,R4      store subno                                          
                                                                                
@SNOTPR2 DS    0H                                                               
*         check if DB2 member excluded from distribution                        
         L     R3,DBSTS    get status from monitor                              
         SLL   R3,0(R6)    R6 has shift to obtain                               
         SRL   R3,31                                                            
         LTR   R3,R3                                                            
         BZ    @SNOTPRC    if status 0 do not process                           
         CR    R7,R5       compare weights                                      
         BC    B'0010',@SNOTPRC branch if R7 high                               
         LR    R7,R5       store max to R7                                      
         LR    R1,R4       store subno                                          
                                                                                
@SNOTPRC DS    0H                                                               
         LA    R2,DBENTSZ(R2)                                                   
         BCT   R4,@SFLOOP                                                       
                                                                                
         LTR   R1,R1       does monitors allow ?                                
         BZ    @WLMSEL     if NO  goto @WLMSEL                                  
         L     R3,DBSUBCLC                                                      
         LA    R3,1(R3)    increase by 1                                        
         SR    R3,R1       R3 gets no of subs                                   
         LR    R15,R3      no of subsystem                                      
         B     @ENDSF                                                           
@WLMSEL  DS    0H                                                               
         L     R3,DBSUBCLC                                                      
         LA    R3,1(R3)    increase by 1                                        
         SR    R3,R11      R3 gets no of subs                                   
                                                                                
@ENDSF   DS    0H                                                               
         LR    R15,R3                                                           
         ST    R15,SELSYSNO                                                     
                                                                                
         DROP  R2                                                               
                                                                                
         L     R14,12(,R13)                                                     
         LM    R0,R12,20(R13)                RESTORE REGISTERS                  
         BR    R14                           RETURN TO CALLER                   
                                                                                
*====================================================================           
* PROC: WTO                                                                     
*       ISSUE A WTO MESSAGE                                                     
*====================================================================           
WTO      DS    0H                            LOCAL PROCEDURE                    
         STM   R14,R12,SAVE0013              SAVE REGISTERS                     
$WTO0029 MVC   WTOMSG(46),WTOSKEL            COPY WTO LIST SKELETON             
$WTO0030 MVC   WTOMSG+13(29),WTOTEXT         INSERT WTO TEXT                    
$WTO0031 LA    R1,WTOMSG                     ADDRESS OF WTO MESSAGE             
@GS00331 DS    0H                            WRITE TO OPERATOR                  
@WTO0032 WTO   ,MF=(E,(1))                                                      
@GE00331 DS    0H                                                               
         SLR   R15,R15                       SET RETURN CODE                    
EXIT_WTO DS    0H                            EXIT PROCEDURE                     
         L     R14,SAVE0013                                                     
         LM    R0,R12,SAVE0013+8             RESTORE REGISTERS                  
         BR    R14                           RETURN TO CALLER                   
                                                                                
*                                                                               
@DATA    DS    0H                                                               
@DATD    DSECT                                                                  
         DS    0F                                                               
SAVE0001 DS    18F                                                              
PARMLST1 DS    30F                                                              
SAVE0013 DS    15F                                                              
PDBLIST  DS    1F                                                               
DBSUBCLC DS    1F                                                               
SELSYSNO DS    1F                                                               
STSSHIFT DS    1F        * save shift of DBSTS bit for DB2DISTx                 
INDYC    DS    16C                                                              
OUTSTR1  DS    160C                                                             
OUTSTR2  DS    60C                                                              
TMPSTR   DS    CL32                                                             
UAWORKAR DS    200F                                                             
EQQUX001 CSECT ,                                                                
         DS    0F                                                               
@CF00018 DC    F'0'      * @AXGA                                                
@CF00295 DC    F'61'                                                            
@CF00316 DC    F'71'                                                            
@DATD    DSECT                                                                  
         DS    0D                                                               
JCLROW   DS    F                                                                
JCLADR   DS    F                                                                
STRPOS   DS    F                                                                
STRLEN   DS    F                                                                
JCLCOL   DS    F                                                                
JOBROW   DS    F                                                                
JOBADR   DS    F                                                                
USDADR   DS    F                                                                
START    DS    F                                                                
@TS00001 DS    CL256                                                            
JCLREC   DS    CL80                                                             
JOBN     DS    CL80                                                             
KEYWORD  DS    CL80                                                             
OLD_MCLASS DS  CL1                                                              
FIND     DS    CL1                                                              
DELIMITER DS   CL1                                                              
JOB_FLAG DS    CL1                                                              
PROC_FLAG DS   CL1                                                              
EXEC_FLAG DS   CL1                                                              
DLM      DS    CL2                                                              
WTOMSG   DS    CL46                                                             
WTOTEXT  DS    CL29                                                             
KEYVAL   DS    CL80                                                             
EQQUX001 CSECT ,                                                                
         LTORG                                                                  
         DS    0D                                                               
LRECL    DC    AL4(80)                                                          
EXIT01SZ DC    AL4(5000)                                                        
@CC00039 DC    CL1' '                                                           
         DC    1C' '                                                            
WASAVSHF EQU   DBENTSZ*(DBENTNM/2)                                              
*                                                                               
*** USM3 ** CHANGE APPL NAMES AND USERID TO MATCH YOUR INSTALLATION ***         
APPRZS   DC    CL8'S       '                                                    
APPRZR   DC    CL8'R       '                                                    
USERPRZT DC    CL8'YATWS   '                                                    
APTECH   DC    CL8'T       '                                                    
APTECHU  DC    CL8'U       '                                                    
USERTECH DC    CL8'YATECH  '                                                    
APSYS    DC    CL8'E       '                                                    
USERSYS  DC    CL8'UTWS    '                                                    
APMNT    DC    CL8'M       '                                                    
USERMNT  DC    CL8'AUTO1   '                                                    
APDB2MN  DC    CL10'MDB2#01CAT'                                                 
USDB2MN  DC    CL8'UDB2P   '                                                    
APMNT1   DC    CL8'D       '                                                    
*** USM3 **************************************************************         
*                                                                               
*                                                                               
RETVAL0  DC    CL4'0000'                                                        
WTOSKEL  WTO   'EQQUX001                              ',MF=L,ROUTCDE=11         
SPACESTR DC    C' '                                                             
TIMEPTRN DC    X'4020207A20207A2020'  patern xx:xx:xx for TIME output           
@DATD    DSECT                                                                  
         ORG   *+1-(*-@DATD)/(*-@DATD)                                          
@ENDDATD DS    0X                                                               
@DYNSIZE EQU   ((@ENDDATD-@DATD+7)/8)*8                                         
EQQUX001 CSECT ,                                                                
         DS    0F                                                               
@SIZDATD DS    0A                                                               
         DC    AL1(0)                                                           
         DC    AL3(@DYNSIZE)                                                    
R0       EQU   0                                                                
R1       EQU   1                                                                
R2       EQU   2                                                                
R3       EQU   3                                                                
R4       EQU   4                                                                
R5       EQU   5                                                                
R6       EQU   6                                                                
R7       EQU   7                                                                
R8       EQU   8                                                                
R9       EQU   9                                                                
R10      EQU   10                                                               
R11      EQU   11                                                               
R12      EQU   12                                                               
R13      EQU   13                                                               
R14      EQU   14                                                               
R15      EQU   15                                                               
JOBNAMEZ EQU   0,8,C'C'                                                         
JCLLENZ  EQU   0,4,C'F'                                                         
JCLAREAZ EQU   0,,C'C'                                                          
LATEOUTz EQU   0,10,C'C'                                                        
ESTDURZ  EQU   0,4,C'C'                                                         
NUMPSZ   EQU   0,2,C'H'                                                         
NUMR1Z   EQU   0,2,C'H'                                                         
NUMR2Z   EQU   0,2,C'H'                                                         
SPECRESZ EQU   0,8,C'C'                                                         
ADIDZ    EQU   0,16,C'C'                                                        
MCAUSERZ EQU   0,4,C'A'                                                         
GROUPZ   EQU   0,8,C'C'                                                         
RUSERZ   EQU   0,8,C'C'                                                         
OPERTYPZ EQU   0,1,C'C'                                                         
UPDATZ   EQU   0,1,C'C'                                                         
JCLUSERZ EQU   0,8,C'C'                                                         
JCLUTIMZ EQU   0,10,C'C'                                                        
OPNUMZ   EQU   0,4,C'F'                                                         
IATIMEZ  EQU   0,10,C'C'                                                        
OWNERZ   EQU   0,16,C'C'                                                        
SPECNRZ  EQU   0,2,C'H'                                                         
SPECBUFZ EQU   0,4,C'A'                                                         
WSNAMEZ  EQU   0,4,C'C'                                                         
RETCOZ   EQU   0,4,C'F'                                                         
NEWRECZ  EQU   0,4,C'F'                                                         
NEWJCLZ  EQU   0,,C'C'                                                          
USDRECZ  EQU   0,4,C'F'                                                         
CALTYPZ  EQU   0,1,C'C'                                                         
CALTYP   EQU   PARMLST1+116,4,C'F'                                              
XJNAMLEN EQU   PARMLST1+112,4,C'F'                                              
XINFO    EQU   PARMLST1+108,4,C'F'                                              
USDREC   EQU   PARMLST1+104,4,C'F'                                              
NEWJCL   EQU   PARMLST1+100,4,C'F'                                              
NEWREC   EQU   PARMLST1+96,4,C'F'                                               
RETCO    EQU   PARMLST1+92,4,C'F'                                               
WSNAME   EQU   PARMLST1+88,4,C'F'                                               
SPECBUF  EQU   PARMLST1+84,4,C'F'                                               
SPECNR   EQU   PARMLST1+80,4,C'F'                                               
OWNER    EQU   PARMLST1+76,4,C'F'                                               
IATIME   EQU   PARMLST1+72,4,C'F'                                               
OPNUM    EQU   PARMLST1+68,4,C'F'                                               
JCLUTIME EQU   PARMLST1+64,4,C'F'                                               
JCLUSER  EQU   PARMLST1+60,4,C'F'                                               
UPDAT    EQU   PARMLST1+56,4,C'F'                                               
OPERTYPE EQU   PARMLST1+52,4,C'F'                                               
RUSER    EQU   PARMLST1+48,4,C'F'                                               
GROUP    EQU   PARMLST1+44,4,C'F'                                               
MCAUSERF EQU   PARMLST1+40,4,C'F'                                               
ADID     EQU   PARMLST1+36,4,C'F'                                               
SPECRES  EQU   PARMLST1+32,4,C'F'                                               
NUMR2    EQU   PARMLST1+28,4,C'F'                                               
NUMR1    EQU   PARMLST1+24,4,C'F'                                               
NUMPS    EQU   PARMLST1+20,4,C'F'                                               
ESTDUR   EQU   PARMLST1+16,4,C'F'                                               
LATEOUT  EQU   PARMLST1+12,4,C'F'                                               
JCLAREA  EQU   PARMLST1+8,4,C'F'                                                
JCLLEN   EQU   PARMLST1+4,4,C'F'                                                
JOBNAME  EQU   PARMLST1,4,C'F'                                                  
         DS    0D                                                               
@ENDDATA EQU   *                                                                
@MODLEN  EQU   @ENDDATA-EQQUX001                                                
                                                                                
@WADAT   DSECT                                                                  
         MTRWADAT                                                               
                                                                                
@DAT01   DSECT                                                                  
         MTRDBENT                                                               
                                                                                
         END   EQQUX001                                                         
//*                                                                             
//LKED     EXEC PGM=IEWL,PARM='RENT,MAP,LIST,CALL',                             
//         COND=(4,LT,ASMH),REGION=512K                                         
//SYSPRINT DD  SYSOUT=*                                                         
//SYSUT1   DD  UNIT=SYSDA,SPACE=(CYL,(3,3))                                     
//*** USM2 *** CHANGE DSN BELOW TO MATCH YOUR INSTALLATION ***********          
//SYSLMOD  DD  DISP=SHR,DSN=&OUTLIB                                             
//SEQOBJ   DD  DISP=(OLD,DELETE),DSN=&&OBJ                                      
//SYSLIN   DD  *                                                                
 INCLUDE SEQOBJ                                                                 
 MODE    AMODE(31)                                                              
 ENTRY   EQQUX001                                                               
 NAME    EQQUX001(R)                                                            
/*                                                                              


//I1TWSU00   JOB NOTIFY=&SYSUID,CLASS=S                                         
//*                                                                             
//   SET  SOURCE=TWSZWAP.EXIT                                                   
//*  SET  SOURCE=IVSLO.EXIT                                                     
//*  SET  OUTLIB=TWSZWAM.LINKLIB                                                
//*  SET  OUTLIB=TWSZWAD.LINKLIB                                                
//*  SET  OUTLIB=IVSLO.LINKLIB                                                  
//   SET  OUTLIB=ZWAP.AUTHLIB.TWS                                               
//*                                                                             
//* 13/06/2013 usage of macro MTRWADAT MTRDBENT WA7REC07                        
//* 25/11/2009 checking UX7 buffer for unprocessed records                      
//* 25/09/2009 allocating  buffer for further use in SOZCOM01                   
//* 26/11/2007 allocates memory for further use in EQQUX001                     
//*    and ZMTRUS01 and assign it to MCAUSERF                                   
//* 16/08/2023 DBENTNM definiton moved to MTRWADAT macro                        
//*                                                                             
//*                                                                             
//*                                                                             
//* ---------------------------------------------------------------             
//*    This version of exit should be used:                                     
//*   -with EQQUX001 exit and ZMTRUS01 program for distribution                 
//*    TWS workload for DB2                                                     
//*     and/or                                                                  
//*   -with EQQUX007 exit and SOZCOM01 program for sending job                  
//*    start/stop event                                                         
//* ---------------------------------------------------------------             
//*                                                                             
//*                                                                             
//*                                                                             
//* Major PROCEDURES:                                                           
//* ----------                                                                  
//* ALLOC_MEM:                                                                  
//*    allocate memory and assign its address to MCAUSERF                       
//* CHK_UX7:                                                                    
//*    check unprocessed records inserted by EQQUX007                           
//*                                                                             
//*                                                                             
//* TO ACTIVATE THE EQQUX000 EXIT YOU SHOULD:                                   
//*                                                                             
//* 1. PLACE THE EQQUX000 LOAD MODULE IN A LIBRARY ACCESSIBLE BY                
//*    THE   OPC   CONTROLLER STARTED TASK.                                     
//*                                                                             
//* 2. MODIFY THE EXITS INSTALLATION STATEMENT TO SPECIFY                       
//*    CALL00(YES)                                                              
//*                                                                             
//* 3. RESTART THE   OPC   CONTROLLER STARTED TASK.                             
//*                                                                             
//*  19.02.2010  insert JOBID, JOBNAME into message EQQUX002                    
//*  10.03.2010  add space  for inserting timestamp by EQQUX007                 
//*                                                                             
//*                                                                             
//********************************************************************          
//ASMH     EXEC PGM=ASMA90,REGION=2048K,                                        
//         PARM='NODECK,OBJECT,XREF(SHORT),LIST,NORLD'                          
//SYSPRINT DD  SYSOUT=*                                                         
//SYSLIB   DD  DISP=SHR,DSN=SYS1.MACLIB                                         
//         DD  DISP=SHR,DSN=SYS1.MODGEN                                         
//         DD  DISP=SHR,DSN=&SOURCE                                             
//SYSLIN   DD  UNIT=SYSDA,SPACE=(CYL,(2,1)),DISP=(,PASS),DSN=&&OBJ              
//SYSUT1   DD  UNIT=SYSDA,SPACE=(CYL,(2,1))                                     
//SYSIN    DD  *                                                                
         TITLE '  EQQUX000: OPC START/STOP USER EXIT'                           
EQQUX000 CSECT ,                                                                
@MAINENT DS    0H                                                               
         USING *,R15                                                            
         B     @PROLOG                                                          
         DC    AL1(16)                                                          
         DC    C'EQQUX000  01.003'                                              
         DROP  R15                                                              
@PROLOG  DS    0H                                                               
         STM   R14,R12,12(R13)         * SAVE REGISTERS                         
         LR    R12,R15                                                          
         LA    R11,4095(,R12)                                                   
         USING EQQUX000,R12                                                     
         USING EQQUX000+4095,R11                                                
         L     R0,@SIZDATD                                                      
         GETMAIN  R,LV=(0)                                                      
         LR    R10,R1                                                           
         USING @DATD,R10                                                        
         ST    R13,4(,R10)                                                      
         ST    R10,8(,R13)                                                      
         LM    R15,R1,16(R13)          * RESTORE REGISTERS                      
         LR    R13,R10                                                          
         MVC   PARMLST1(8),0(R1)                                                
                                                                                
*********************************************************************           
                                                                                
MAIN     DS    0H                                                               
                                                                                
         L     R2,ACTION                                                        
         CLC   0(5,R2),=C'START'                                                
         BNE   @STOPTWS                                                         
         BAL   R14,ALLOC_MEM  allocate stor for BUFFs                           
                                                                                
         B     EXIT_MAIN                                                        
                                                                                
@STOPTWS DS    0H                                                               
         L     R2,ACTION                                                        
         CLC   0(4,R2),=C'STOP'                                                 
         BNE   EXIT_MAIN                                                        
                                                                                
         BAL   R14,CHK_UX7 check buffer for unprocessud UX7 records             
                                                                                
EXIT_MAIN DS    0H         EXIT MAIN PROGRAM                                    
         LR    R2,R15                                                           
         LR    R1,R10                                                           
         L     R13,4(,R13)                                                      
         L     R0,@SIZDATD                                                      
         FREEMAIN R,LV=(0),A=(1)                                                
         LR    R15,R2                                                           
         L     R14,12(,R13)                                                     
         LM    R0,R12,20(R13) RESTORE REGISTERS                                 
         BR    R14         RETURN TO CALLER                                     
                                                                                
*====================================================================           
* PROC: ALLOC_MEM                                                               
*       allocate storage and assigne its addr to MCAUSERF                       
*       This storage is used by program ZMTRUS01 and EQQUX001                   
*====================================================================           
ALLOC_MEM DS    0H                                                              
         STM   R14,R12,SAVE0003 SAVE REGISTERS                                  
*                                                                               
                                                                                
         L     R5,MCAUSERF                                                      
                                                                                
         L     R0,WASIZE                                                        
         GETMAIN  R,LV=(0)                                                      
         ST    R1,0(R5)    store addr of allocated memory to MCAUSERF           
                                                                                
         LA    R2,WALSTOFF(,R1) add offset of BUFFER for ZMTRUS01               
         ST    R2,0(0,R1)  store addr of BUFFER for ZMTRUS01                    
         LA    R2,W7BUFOFF(,R1) add offset of BUFFER for ZUX7CM01               
         ST    R2,4(0,R1)  store addr of BUFFER for ZUX7CM01                    
         L     R1,0(,R1)   work buff addr for ZMTRUS01                          
                                                                                
*        prepare buffer for ZMTRUS01                                            
         USING @WADAT,R1                                                        
         MVC   WASYSNAM(4),=C'    '  clear SYS name                             
*                                                                               
         LA    R2,WASYSNUM+4                                                    
                                                                                
         XR    R2,R2       clear R2                                             
         ST    R2,WAINDAM  to Indicate ZMTRUS01 is not active                   
                                                                                
         DROP  R1                                                               
                                                                                
*        prepare buffer for ZUX7CM01                                            
         L     R1,0(R5)    addr from MCAUSERF                                   
         L     R1,4(0,R1)  get addr of BUFFER for ZUX7CM01                      
         USING @WAUX7HD,R1                                                      
*                                                                               
         MVC   WA7CHK(4),CHKWD                                                  
         L     R2,NUM7REC                                                       
         ST    R2,WA7NUMR                                                       
                                                                                
         LA    R2,WA7RECL                                                       
         ST    R2,WA7RECLN                                                      
                                                                                
         XC    WA7CURIN,WA7CURIN  clear WA7CURIN                                
         XC    WA7CURFR,WA7CURFR  clear WA7CURFR                                
                                                                                
*                                                                               
         DROP  R1                                                               
                                                                                
EXIT_ALLOC_MEM DS    0H    EXIT PROCEDURE                                       
                                                                                
         L     R14,SAVE0003                                                     
         LM    R0,R12,SAVE0003+8  RESTORE REGISTERS                             
         BR    R14         RETURN TO CALLER                                     
                                                                                
                                                                                
*====================================================================           
* PROC: CHK_UX7                                                                 
*       Check if all records inserted by EQQUX007 is processed.                 
*       If not WTO and print unprocessed records to UX7ERREC DD                 
*                                                                               
*====================================================================           
CHK_UX7  DS    0H                                                               
         STM   R14,R12,SAVE0003 SAVE REGISTERS                                  
*                                                                               
         L   R5,MCAUSERF                                                        
         L   R5,0(,R5)     address of allocated user memory                     
         LTR R5,R5         check if not 0                                       
         BNZ @CNTCHK1                                                           
                                                                                
*        'EQQUX0003 MCAUSERF is no initialized            '                     
         MVC   WTOTEXT(44),MSG003                                               
         BAL   R14,WTO                                                          
         B     @ENDCHK                                                          
                                                                                
@CNTCHK1 DS  0H                                                                 
                                                                                
         L   R6,4(,R5)     address of ZUX7CM01 buff                             
                                                                                
         USING @WAUX7HD,R6                                                      
                                                                                
         L   R3,WA7NUMR    num of RECs in buffer                                
         LA  R4,WA7RECLN+2 addr of half word of length of record                
                                                                                
         L   R5,WA7CURFR   load num of current record                           
         LR  R7,R5                                                              
         MH  R7,0(,R4)     offset of record to get                              
         AR  R7,R6                                                              
         L   R4,WA7HDSZ(R7) get status WORD of record                           
                                                                                
         LA  R2,1                                                               
         CR  R2,R4                                                              
         BNE @NOUX7RC      no unprocessed record                                
                                                                                
*        'EQQUX0002 There are unprocessed EQQUX007 records'                     
         MVC   WTOTEXT(48),MSG002                                               
         BAL   R14,GET_JBID  get JOB info                                       
         BAL   R14,WTO                                                          
                                                                                
*                                                                               
*        print unprocessed records to UX7ERREC DD                               
*                                                                               
         BAL R14,OPNERPRT  open UX7ERREC DD                                     
                                                                                
*       print records loop start                                                
@PRTERRC DS  0H                                                                 
         L   R3,WA7NUMR    num of RECs in buffer                                
         LA  R4,WA7RECLN+2 addr of half word of length of record                
                                                                                
         L   R5,WA7CURFR   load num of current record                           
         LR  R7,R5                                                              
         MH  R7,0(,R4)     offset of record to get                              
         AR  R7,R6                                                              
         L   R4,WA7HDSZ(R7) get status WORD of record                           
*                                                                               
*        MVC  PRTREC(12),DATEEX   put date                                      
         MVC  PRTREC(WA7RECL-4),WA7HDSZ+4(R7)  record itself                    
         PUT  UX7EDCB,PRTREC   put current record to UX7ERREC                   
                                                                                
         LA  R2,0                                                               
         ST  R2,WA7HDSZ(R7)  status WORD of record set to 0                     
         LA  R5,1(,R5)     Increment by 1 free record pointer                   
         CR  R5,R3         chek if R5 reaches max allowed                       
         BNE @SETFR                                                             
         XR  R5,R5         zero                                                 
@SETFR   ST  R5,WA7CURFR   store val of current free record                     
                                                                                
         LA  R2,WA7RECLN+2 addr of half word of length of record                
                                                                                
         MH  R5,0(,R2)     offset of record to get                              
         L   R2,WA7HDSZ(R5,R6) get status word of current record                
         LTR R2,R2                                                              
         BZ  @ENDERPR      no more records                                      
         B  @PRTERRC       repeat print records loop                            
                                                                                
*       print records loop end                                                  
                                                                                
@ENDERPR DS 0H                                                                  
         DROP  R6                                                               
*                                                                               
         MVC   WORKA(@LNCLS),MODELCLS                                           
         CLOSE UX7EDCB,MF=(E,WORKA),MODE=24                                     
                                                                                
         B     @ENDCHK                                                          
                                                                                
@NOUX7RC DS  0H                                                                 
                                                                                
*       'EQQUX0001 No unprocessed EQQUX007 records'                             
         MVC   WTOTEXT(44),MSG001                                               
         BAL   R14,WTO                                                          
                                                                                
@ENDCHK  DS    0H                                                               
                                                                                
         L     R14,SAVE0003                                                     
         LM    R0,R12,SAVE0003+8  RESTORE REGISTERS                             
         BR    R14         RETURN TO CALLER                                     
                                                                                
*====================================================================           
* PROC: OPNERPRT                                                                
*       open UX7ERREC DD                                                        
*====================================================================           
OPNERPRT  DS    0H                                                              
         STM   R14,R12,SAVE0002 SAVE REGISTERS                                  
                                                                                
         MVC   UX7EDCB(@U7PROSZ),UX7PRT                                         
         MVC   WORKA(@LNOPEN),MODELOPN                                          
         OPEN  (UX7EDCB,(OUTPUT)),MF=(E,WORKA),MODE=24 open SYSPRINT            
*                                                                               
                                                                                
         L     R14,SAVE0002                                                     
         LM    R0,R12,SAVE0002+8  RESTORE REGISTERS                             
         BR    R14         RETURN TO CALLER                                     
*                                                                               
*====================================================================           
* PROC: CHK_UX7                                                                 
*       Check if all records inserted by EQQUX007 is processed.                 
*       If not WTO and print unprocessed records to UX7ERREC DD                 
*                                                                               
*====================================================================           
GET_JBID DS    0H                                                               
         STM   R14,R12,SAVE0005 SAVE REGISTERS                                  
                                                                                
         L     R3,548      current ASCB                                         
         USING ASCB,R3     ASCB map                                             
         L     R4,ASCBCSCB  CSCB address                                        
         USING CHAIN,R4     CSCB map                                            
         MVC   WTOTEXT+2(4),CHCLS    get job name                               
         DROP  R4                                                               
         L     R4,ASCBASSB  ASSB address                                        
         USING ASSB,R4     ASSB map                                             
         DROP  R3                                                               
         L     R3,ASSBJSAB  job scheduler address                               
         USING IAZJSAB,R3                                                       
         MVC   WTOTEXT+7(8),JSABJBID   get job ID                               
         DROP  R3,R4                                                            
         L     R14,SAVE0005                                                     
         LM    R0,R12,SAVE0005+8  RESTORE REGISTERS                             
         BR    R14         RETURN TO CALLER                                     
*                                                                               
*                                                                               
*====================================================================           
* PROC: WTO                                                                     
*       ISSUE A WTO MESSAGE                                                     
*====================================================================           
WTO      DS    0H                                                               
         STM   R14,R12,SAVE0004  SAVE REGISTERS                                 
WTO0029  MVC   WTOMSG(@WSKLSZ),WTOSKEL COPY WTO LIST SKELETON                   
WTO0030  MVC   WTOMSG+11(48),WTOTEXT  INSERT WTO TEXT                           
WTO0031  LA    R1,WTOMSG   ADDRESS OF WTO MESSAGE                               
@GS00331 DS    0H          WRITE TO OPERATOR                                    
WTO0032  WTO   ,MF=(E,(1))                                                      
@GE00331 DS    0H                                                               
         SLR   R15,R15     SET RETURN CODE                                      
EXIT_WTO DS    0H          EXIT PROCEDURE                                       
         L     R14,SAVE0004                                                     
         LM    R0,R12,SAVE0004+8  RESTORE REGISTERS                             
         BR    R14         RETURN TO CALLER                                     
                                                                                
*                                                                               
*                                                                               
@DATA    DS    0H                                                               
@DATD    DSECT                                                                  
         DS    0F                                                               
SAVE0001 DS    18F                                                              
PARMLST1 DS    2F                                                               
SAVE0002 DS    15F                                                              
SAVE0003 DS    15F                                                              
SAVE0004 DS    15F                                                              
SAVE0005 DS    15F                                                              
SAVETMP  DS    15F                                                              
DELAY    DS    1F                                                               
DATEEX   DS    16C                                                              
PRTREC   DS    CL(WA7RECL+8)                                                    
                                                                                
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
WTOMSG   DS    CL(@WSKLSZ+20)                                                   
WTOTEXT  DS    CL19                                                             
KEYVAL   DS    CL80                                                             
UX7EDCB  DS   CL(@U7PROSZ)                                                      
WORKA    DS   CL(200)                                                           
EQQUX000 CSECT ,                                                                
         LTORG                                                                  
         DS    0D                                                               
LRECL    DC    AL4(80)                                                          
EXIT01SZ DC    AL4(5000)                                                        
@CC00039 DC    CL1' '                                                           
         DC    1C' '                                                            
*                                                                               
CHKWD    DC    C'MSPO'                                                          
MSG001   DC    C'1 No unprocessed UX7 records                     '             
MSG002   DC    C'2               Unprocessed UX7 records detected '             
MSG003   DC    C'3 MCAUSERF is no initialized              '                    
                                                                                
*     LRECL = rec length from UX7 - 4                                           
UX7PRT   DCB DDNAME=UX7ERREC,RECFM=FB,LRECL=WA7RECL-4,DSORG=PS,        *        
               MACRF=PM,BLKSIZE=(WA7RECL-4)*20                                  
@U7PROSZ EQU   *-UX7PRT                                                         
UX7PRTCL CLOSE (UX7PRT),MF=L,MODE=24  model CLOSE prm list                      
@U7PRCSZ EQU   *-UX7PRTCL                                                       
MODELOPN OPEN (,OUTPUT),MF=L  OPEN for output dataset                           
@LNOPEN  EQU   *-MODELOPN  calculate length of OPEN macro                       
MODELCLS CLOSE (UX7PRT),MF=L  OPEN for output dataset                           
@LNCLS   EQU   *-MODELCLS  calculate length of OPEN macro                       
MODLTIME TIME LINKAGE=SYSTEM,MF=L                                               
LENTIME  EQU   *-MODLTIME                                                       
                                                                                
WTOSKEL  WTO 'SOZUX00                                                  *        
                                  ',                                   *        
               MF=L                                                             
*              MF=L,ROUTCDE=11,MCSFLAG=BRDCST                                   
@WSKLSZ  EQU   *-WTOSKEL                                                        
@DATD    DSECT                                                                  
@DATD    DSECT                                                                  
         ORG   *+1-(*-@DATD)/(*-@DATD)                                          
@ENDDATD DS    0X                                                               
@DYNSIZE EQU   ((@ENDDATD-@DATD+7)/8)*8                                         
EQQUX000 CSECT ,                                                                
         DS    0F                                                               
@SIZDATD DS    0A                                                               
         DC    AL1(0)                                                           
         DC    AL3(@DYNSIZE)                                                    
NUM7REC  DS    0A                                                               
         DC    AL4(WA7NUM)                                                      
WASIZE   DS    0A                                                               
         DC    AL4(@WASIZE)                                                     
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
ACTIONZ  EQU   0,8,C'C'                                                         
MCAUSERZ EQU   0,4,C'A'                                                         
MCAUSERF EQU   PARMLST1+4,4,C'F'                                                
ACTION   EQU   PARMLST1,4,C'F'                                                  
         DS    0D                                                               
@ENDDATA EQU   *                                                                
@MODLEN  EQU   @ENDDATA-EQQUX000                                                
                                                                                
@WADAT   DSECT                                                                  
         MTRWADAT              Control structure for EQQUX001 & MTR             
@DAT01   DSECT                                                                  
         MTRDBENT                                                               
                                                                                
@WAUX7HD DSECT                                                                  
         WA7REC07              Control structure for EQQUX007 & SOZM            
                                                                                
WA7NUM   EQU   20000              num of recs for ZUX7CM01                      
WA7RECL  EQU   128               length of rec for ZUX7CM01                     
WALSTOFF EQU   8                  ofset of list of ZMTRUS1's buffer             
* four byte before ZMTRUS buffer is also used by EQQUX001 as indicator          
W7BUFOFF EQU   WALSTOFF+WADATSZ+DBENTSZ*DBENTNM                        *        
                                  ofset of list of ZUX7CM1's buffer             
@WASIZE  EQU   W7BUFOFF+WA7HDSZ+WA7RECL*WA7NUM+16*DBENTSZ+WADATSZ      *        
                                  total size of all buffers                     
*          VVV230803                                                            
*BENTNM  EQU   40                 max number of entries in DB2 list*2  *        
                                  half of them is for saving weights            
         IEECHAIN CSCB                                                          
         IHAASCB  ASCB                                                          
         IHAASSB  ASSB                                                          
         IAZJSAB  JSAB                                                          
         END   EQQUX000                                                         
//LKED     EXEC PGM=IEWL,PARM='RENT,MAP,LIST,CALL',                             
//         COND=(4,LT,ASMH),REGION=512K                                         
//SYSPRINT DD  SYSOUT=*                                                         
//SYSUT1   DD  UNIT=SYSDA,SPACE=(CYL,(3,3))                                     
//*                                                                             
//SYSLMOD  DD  DISP=SHR,DSN=&OUTLIB                                             
//SEQOBJ   DD  DISP=(OLD,DELETE),DSN=&&OBJ                                      
//SYSLIN   DD  *                                                                
 INCLUDE SEQOBJ                                                                 
 ENTRY   EQQUX000                                                               
 NAME    EQQUX000(R)                                                            
/*                                                                              


! Calculates MSD where we have shifted reference. 
! EDIT:  have its own skipping file, and requires header and footer of the frame
!! CAUTION: IF YOU HAVE MORE SKIP AND PARTICLE CROSS THE 1/2 THE BOX LENGHT, IT WILL NOT CONSIDER THAT
! Input :  input file (input_msd.dat), trajectories file (gromacs) (31) 
! Output:  out_msd.dat (33), log_msd.dat (50)
! TEMP  :  temp_msd.dat (32)

PROGRAM MSD_LAMMPS
  IMPLICIT NONE
  REAL*8::X,Y,Z, RIJ(3), BOX(3),BOX_INV(3), TIME_STEP, TIME_DUR, XY,XZ,YZ
  REAL*8, ALLOCATABLE, DIMENSION(:):: RX,RY,RZ, RX_O,RY_O,RZ_O,&
          MSDX, MSDY, MSDZ, MSD
  INTEGER::I,J,K, INITIAL_DUMP_HEADER, NO_ATOM_TRACK, NATOM, ISTAT,&
           NHEAD, NHEAD_UPDATE, NSTEP, RAN_I1, RAN_I2, RAN_I3, &
           REF_COUNT, TIME_COUNT, NTAIL, NSKIP,NSKIP_FRAME
  INTEGER, ALLOCATABLE:: ATOM_TRACK(:), MSD_COUNT(:)
  CHARACTER*50:: TRAJFILE, GROFORMAT
  CHARACTER*3 :: RAN_C1
  CHARACTER*1 :: RAN_C2
  LOGICAL::      DIRECT
  GROFORMAT  = '(i5,2a5,i5,3f8.3)'
  OPEN(21,FILE="input_msd.dat",STATUS="OLD")
  READ(21,*) TRAJFILE
  READ(21,*) NHEAD, NTAIL, NSKIP 
  READ(21,*) TIME_STEP, TIME_DUR
  READ(21,*) BOX(1),BOX(2), BOX(3)
  READ(21,*) XY, XZ,YZ
  READ(21,*) NATOM
  READ(21,*) DIRECT
  READ(21,*) NO_ATOM_TRACK
  ALLOCATE(ATOM_TRACK(NO_ATOM_TRACK) ) ;  READ(21,*) !BLANK
  DO I = 1, NO_ATOM_TRACK
    READ(21,*) ATOM_TRACK(I)
  END DO
  CLOSE(21) 
  OPEN(50,FILE="log_msd.dat")
  WRITE(50,*) "MSD calucation started for  ", TRIM(TRAJFILE)
  WRITE(50,*) "NO OF HEADER LINES:         ", NHEAD
  WRITE(50,*) "NO OF TAIL LINES:           ", NTAIL 
  WRITE(50,*) "NSKIP                       ", NSKIP
  WRITE(50,*) "TIME STEP:                  ", TIME_STEP 
  WRITE(50,*) "TOTAL TIME DURATION:        ", TIME_DUR
  WRITE(50,*) "BOX DIMENSION:              ", BOX(:)
  WRITE(50,*) "BOX TILT FACTOR:            ", XY,XZ,YZ
  WRITE(50,*) "TOTAL NUMBER OF ATOMS:      ", NATOM
  WRITE(50,*) "NO OF ATOMS TO TRACK:       ", NO_ATOM_TRACK
  WRITE(50,*) "ATOMS:                      ", ATOM_TRACK(:)
  WRITE(50,*) "DIRECT READ CONFIGURATION ? ", DIRECT
  WRITE(50,*) "INPUT COMPLETE"

  ! INITILIZATION
  TIME_STEP =  TIME_STEP *DBLE(NSKIP)  
  NSKIP = NSKIP-1
  BOX_INV = 1.0D0 / BOX 
  NSTEP   = INT(TIME_DUR/TIME_STEP)
  NSKIP_FRAME =  NSKIP* (NHEAD+NTAIL+NATOM)

  WRITE(50,*) "TIME STEP TO BE USED         ", TIME_STEP
  WRITE(50,*) "TOTAL FRAMES TO BE READ      ", NSTEP
  WRITE(50,*) "TOTAL FRAMES SKIP BEFORE NEXT", NSKIP_FRAME
  ALLOCATE (MSDX(NSTEP),MSDY(NSTEP),MSDZ(NSTEP),&
            MSD(NSTEP) ,MSD_COUNT(NSTEP),       &
            RX(NO_ATOM_TRACK), RX_O(NO_ATOM_TRACK), &
            RY(NO_ATOM_TRACK), RY_O(NO_ATOM_TRACK), &
            RZ(NO_ATOM_TRACK), RZ_O(NO_ATOM_TRACK)    )
  IF (DIRECT) GOTO 80
  OPEN(31,FILE=TRIM(TRAJFILE),STATUS='OLD', IOSTAT=ISTAT)
  IF(ISTAT /= 0) THEN
  	WRITE(50,*) "ERROR WITH TRAJECTORY FILE ", TRIM(TRAJFILE)
  	CALL ERROR_STOP
  END IF 
  WRITE(50,*) "INITILIZATION OVER, EXTRACTING AND UNFLODING NOW"
  ! EXTRACT AND UNFOLDING THE REQUIRED ATOMS
  OPEN (34, FILE="temp_MSD.dat")
  OPEN (32, FILE="temp_MSD.xyz")
  DO I = 1, NHEAD
    READ(31,*) ! HEADER LINE
  END DO
  J = 1
  DO I = 1, NATOM ! REFERENCE
  	READ(31,GROFORMAT) RAN_I1,RAN_C1,RAN_C2,RAN_I1, X, Y, Z 
	  IF (RAN_I1 == ATOM_TRACK(J)) THEN	   
		  RX_O(J) = X
		  RY_O(J) = Y
		  RZ_O(J) = Z
		  J = J + 1      
		END IF
  END DO
  DO I = 1, NTAIL
    READ(31,*) ! BOX DIMENSION
  END DO 
  WRITE(32,*) NO_ATOM_TRACK, 1
  WRITE(32,*)
  WRITE(34,*) 1
  DO I = 1, NO_ATOM_TRACK
    WRITE(32,*) "A", RX_O(I)*10.0, RY_O(I)*10.0, RZ_O(I)*10.0
    WRITE(34,*) RX_O(I), RY_O(I), RZ_O(I)
  END DO

  DO TIME_COUNT = 2, NSTEP
    ! SKIPPING FRAME   
    DO I = 1, NSKIP_FRAME
      READ(31,*) ! SKIP
    END DO 
    DO I = 1, NHEAD
      READ(31,*) ! BLANK
    END DO   
    J = 1
    DO I = 1, NATOM
  	  READ(31,GROFORMAT) RAN_I1,RAN_C1,RAN_C2,RAN_I1, X, Y, Z 
		  IF (RAN_I1 == ATOM_TRACK(J)) THEN
	      RX(J) = X
	      RY(J) = Y
	      RZ(J) = Z
	      J = J + 1 
	    END IF  
    END DO
    DO I = 1, NTAIL   
      READ(31,*) ! BOX DIMENSION 
    END DO 
    RX = RX - RX_O ; RY = RY - RY_O ; RZ = RZ - RZ_O ! DIFF
    !RX = RX - ANINT(RX*BOX_INV(1)) *(BOX(1)+XY)!-ANINT(RY*BOX_INV(2))*XY
    RX = RX - ANINT(RX*BOX_INV(1)) *BOX(1)
    RY = RY - ANINT(RY*BOX_INV(2)) *BOX(2)            ! MIC
    RZ = RZ - ANINT(RZ*BOX_INV(3)) *BOX(3)  
    RX = RX + RX_O ; RY = RY + RY_O ; RZ = RZ + RZ_O ! UPDATE
    WRITE(32,*) NO_ATOM_TRACK, TIME_COUNT
    WRITE(32,*)
    WRITE(34,*) TIME_COUNT, TIME_COUNT*TIME_STEP
    DO I = 1, NO_ATOM_TRACK
      WRITE(32,*) "A", RX(I)*10.0,RY(I)*10.0, RZ(I)*10.0
      WRITE(34,*) RX(I),RY(I), RZ(I)
    END DO 
    RX_O = RX ; RY_O = RY ; RZ_O = RZ 
  END DO 
  CLOSE (31) !
  WRITE(50,*) "REQUIRED ATOMS EXTRACTED AND UNFLODED"
  CLOSE (32)
  CLOSE (34)
  
  80 CONTINUE 
  WRITE(50,*) "PERFORMING MSD CALCULATION"
  ! MSD CALCULATION
  MSDX = 0.0D0 ; MSDY = 0.0D0 ; MSDZ = 0.0D0 ; 
  MSD  = 0.0D0 
  MSD_COUNT = 0  
  NHEAD_UPDATE = 0
  DO REF_COUNT = 1, NSTEP-1
    print*, REF_COUNT, "of", NSTEP
    OPEN(32,FILE="temp_MSD.dat",STATUS='OLD')
    DO I = 1, NHEAD_UPDATE
      READ(32,*) ! SKIP ALL THE HEADER      
    END DO 
    READ(32,*) ! TIME
    DO I = 1, NO_ATOM_TRACK
        READ(32,*) RX_O(I),RY_O(I),RZ_O(I)
    END DO     
    NHEAD_UPDATE = NHEAD_UPDATE +  NO_ATOM_TRACK+1
    DO TIME_COUNT = 1, NSTEP-REF_COUNT
      READ(32,*) ! TIME
      DO I = 1, NO_ATOM_TRACK
          READ(32,*) RX(I),RY(I),RZ(I)        
      END DO 
      RX = RX - RX_O ; RY = RY - RY_O ; RZ = RZ -RZ_O ! DIFF
      RX = RX*RX     ; RY = RY*RY     ; RZ = RZ * RZ  ! SQUARE
      MSDX(TIME_COUNT) = MSDX(TIME_COUNT) + SUM(RX)   ! SUM 
      MSDY(TIME_COUNT) = MSDY(TIME_COUNT) + SUM(RY)   ! SUM 
      MSDZ(TIME_COUNT) = MSDZ(TIME_COUNT) + SUM(RZ)   ! SUM 
      MSD(TIME_COUNT)  = MSD(TIME_COUNT)  + SUM(RX + RY + RZ) 
      MSD_COUNT(TIME_COUNT) = MSD_COUNT(TIME_COUNT) + 1  ! COUNTER 
    END DO 
    CLOSE(32)
  END DO
  MSDX =  MSDX /DBLE(MSD_COUNT*NO_ATOM_TRACK)
  MSDY =  MSDY /DBLE(MSD_COUNT*NO_ATOM_TRACK)
  MSDZ =  MSDZ /DBLE(MSD_COUNT*NO_ATOM_TRACK)  
  MSD  =  MSD  /DBLE(MSD_COUNT*NO_ATOM_TRACK)
  OPEN(33,FILE="out_msd.dat")
  WRITE(33,*) "# TIME, MSDX, MSDY, MSDZ, MSD, MSD_COUNT"
  DO I =1, NSTEP-1
    WRITE(33,'(F8.2,4(1X,F20.8),1X,I3)') DBLE(I)*TIME_STEP,&
        MSDX(I), MSDY(I), MSDZ(I), MSD(I), MSD_COUNT(I) 
  END DO   
  CLOSE(33)
  WRITE(50,*) "PROGRAM RAN SUCCESSFULLY"
  CLOSE(50) 


  CONTAINS ! SUBROUTINES

  SUBROUTINE ERROR_STOP
  	PRINT*, "ERROR: PROGRAM STOPPED"
    WRITE(50,*) "ERROR: PROGRAM STOPPED"
  	STOP
  END SUBROUTINE ERROR_STOP


END PROGRAM MSD_LAMMPS
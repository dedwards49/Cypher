#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function DE_MoveMotorByCounts(Motor,Counts)
	string Motor
	variable Counts
	if(Counts>1000)
		print "Don't move by more than 200 µm"
		return -1
	endif
	MotorControl#MoveMotorToCount(motor, ReadMotorPosition(Motor, "counts")+Counts)
end

function DE_FocalScan()

	ARCheckFunc("ARUserCallbackMasterCheck_1",1)
	ARCheckFunc("ARUserCallbackImageDoneCheck_1",1)
	wave/T w1=root:packages:MFP3D:Main:Variables:GeneralVariablesDescription
	w1[%ARUserCallbackImageScan][%Description]="DE_SpotCallback()"
	variable HighDist=50e-6
	variable LowDist=-50e-6
	variable steps=50
	variable HighDistCount=HighDist/2e-7
	variable LowDistCount=LowDist/2e-7
	variable stepsCount=(HighDistCount-LowDistCount)/steps
//	
	if(stepsCount<=0)
		print "bad steps"
		return -1
	endif
//
	make/o/n=4 SpotProfParms
//	
	SpotProfParms={0,steps,stepscount,1}
	print HighDistCount
	DE_MoveMotorByCounts("Head",HighDistCount)

	Sleep/s 0.1
	DoScanFunc("UpScan_0")
	PV("LastScan",1)
end

function DE_SpotCallback()
	
	wave SpotProfParms
	
	if(SpotProfParms[3]==0)
		return -1
	
	endif
	
	SpotProfParms[0]+=1
	if(SpotProfParms[0]<=SpotProfParms[1])
		DE_MoveMotorByCounts("Head",-SpotProfParms[2])
		Sleep/s 0.1
		DoScanFunc("UpScan_0")
		PV("LastScan",1)
	else
		SpotProfParms[3]=0
		ARCheckFunc("ARUserCallbackMasterCheck_1",0)
		ARCheckFunc("ARUserCallbackImageDoneCheck_1",0)
		print "DONE"
		
	endif


end
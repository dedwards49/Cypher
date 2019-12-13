#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=DE_SmartSearch

Static Function Initialize()

	NewDataFolder/o root:SmartSearch
end


Static Function MakeAGrid(xpnts,xstart,xend,ypnts,ystart,yend)
	variable xpnts,xstart,xend,ypnts,ystart,yend
	
	variable TotalSpots=xpnts*ypnts
	
	make/free/n=(totalSpots,2) FreeSpot


	variable xstep=(xend-xstart)/(xpnts-1)
	variable ystep=(yend-ystart)/(ypnts-1)

	FreeSpot[][0] = (mod(P,xpnts)*xstep+xstart)/GV("XLVDTSEns")
	FreeSpot [][1]= (floor(P/xpnts)*ystep+ystart)/GV("yLVDTSEns")
	duplicate/o freespot root:SmartSearch:SpotWave
	
end

Static  function ZeroSetpointOffset(bank)
	variable bank
	variable times=stopmstimer(-2)
	if(bank!=0&&bank!=1&&bank!=2&&bank!=3&&bank!=4&&bank!=5)
		print "Invalid Bank"
		return -1
	endif
	variable Error,offset,set

		set=(td_rv("PIDSLoop."+num2str(bank)+".SetPoint"))+(td_rv("PIDSLoop."+num2str(bank)+".SetPointOffSet"))
	Make/O/T/n=(1,1) ZFeedbackParm
	td_RG("ARC.PIDSLoop."+num2str(bank), ZFeedbackParm)
	ZFeedbackParm[%SetpointOffset] =num2str(0)

	ZFeedbackParm[%Setpoint] =num2str(-1.5)
	ZFeedbackParm[%DynamicSetpoint]="Yes"
	ZFeedbackParm[%Status]="0"

	td_wg("ARC.PIDSLoop."+num2str(bank),ZFeedbackParm)
	 td_ws("Event."+ZFeedbackParm[%StartEvent],"once")
	 	killwaves ZFeedbackParm

end

Static Function StepAroundStart(TrialPulls,MaxSinceHit,MaxIterations,MinForce,MinDistance)
	variable TrialPulls,MaxSinceHit,MaxIterations,MinForce,MinDistance
	Wave SpotWave=root:SmartSearch:SpotWave
	Initialize()
	make/o/n=10 root:SmartSearch:Info
	wave SmartSearchInfo=root:SmartSearch:Info
	SetDimLabel 0,0,'CurrentPull',SmartSearchInfo
	SmartSearchInfo[%CurrentPull]=0 
	SetDimLabel 0,1,'TrialPulls',SmartSearchInfo
	SmartSearchInfo[%TrialPulls]=TrialPulls //Current Spot
	SetDimLabel 0,2,'TrialHits',SmartSearchInfo
	SmartSearchInfo[%TrialHits]=0 //Empty in Row
	SetDimLabel 0,3,'FoundFlag',SmartSearchInfo
	SmartSearchInfo[%FoundFlag]=0//Hits in Row
	SetDimLabel 0,4,'SinceHit',SmartSearchInfo
	SmartSearchInfo[%SinceHit]=0
	SetDimLabel 0,5,'MaxSinceHit',SmartSearchInfo
	SmartSearchInfo[%MaxSinceHit]=MaxSinceHit
	SetDimLabel 0,6,'MaxIterations',SmartSearchInfo
	SmartSearchInfo[%MaxIterations]=MaxIterations
	SetDimLabel 0,7,'MinForce',SmartSearchInfo
	SmartSearchInfo[%MinForce]=MinForce
	SetDimLabel 0,8,'MinDistance',SmartSearchInfo
	SmartSearchInfo[%MinDistance]=MinDistance
	SetDimLabel 0,9,'CurrentSpot',SmartSearchInfo
	SmartSearchInfo[%CurrentSpot]=0
	 ZeroSetpointOffset(0)
	 ZeroSetpointOffset(1)
	  
	String Graphstr = "ARCallbackPanel"
	DoWindow $GraphStr
	if (!V_Flag)
		MakePanel(GraphStr)
	endif
	ARExecuteControl("ARUserCallbackMasterCheck_1",GraphStr,1,"")
	
	//turn on Force callbacks.
	ARExecuteControl("ARUserCallbackForceDoneCheck_1",GraphStr,1,"")
	
	
	//set the callback
	ARExecuteControl("ARUserCallbackForceDoneSetVar_1",GraphStr,nan,"DE_SmartSearch#FECDone()")
	MoveToSpot(0)
end

Static Function FECDone()
	wave SmartInfo=root:SmartSearch:Info

	Variable Hit=LastWaveHit()
	SmartInfo[%CurrentPull]+=1
	if(SmartInfo[%FoundFlag]==1)
		if(Hit==1)
			SmartInfo[%SinceHit]=0
		else
			SmartInfo[%SinceHit]+=1
		endif

		if(SmartInfo[%SinceHit]>=SmartInfo[%MaxSinceHit])
			NextSpot()
		elseif(SmartInfo[%CurrentPull]>=SmartInfo[%MaxIterations])
			NextSpot()
		else
			Run()
		endif
	elseif(SmartInfo[%FoundFlag]==0)
		SmartInfo[%TrialHits]+=Hit

		if(SmartInfo[%CurrentPull]>=SmartInfo[%TrialPulls])
			if(Smartinfo[%TrialHits]>0)
				SmartInfo[%FoundFlag]=1
				Run()
			else
				NextSpot()
			endif
		else
			Run()
		endif

	endif
	
end

Static Function LastWaveHit()
	wave SmartSearchInfo=root:SmartSearch:Info
	variable ForceMin=SmartSearchInfo[5]
	variable SepMin=SmartSearchInfo[6]
	wave ForceWave=root:packages:MFP3D:Force:Force 
	wave ZWave=root:packages:MFP3D:Force:ZSensor
	variable TriggerForce=(GV("TriggerPoint"))
	variable TriggerDistance=TriggerForce/GV("SpringConstant")
	variable TriggerTime=td_rv("Arc.ctfc.TriggerTime1")
	variable SurfaceEstimate=ZWave(TriggerTime)-TriggerDistance
	wavestats/Q ForceWave
	variable MaxForce=v_min
	Variable MaxForceLocation=ZWave[v_minRowLoc]
	if(MaxForce<-1*ForceMin&&MaxForceLocation<SurfaceEstimate-SepMin)
			print "A Hit!"
			print MaxForce
			print time()
		return 1
	else
		return 0
	endif
	 

end

Static Function NextSpot()

	
	wave SmartSearchInfo=root:SmartSearch:Info
	wave SpotWave=root:SmartSearch:SpotWave
	variable spots=dimsize(SpotWave,0)
	SmartSearchInfo[%CurrentSpot]+=1
	SmartSearchInfo[%CurrentPull]=0
	SmartSearchInfo[%TrialHits]=0
	SmartSearchInfo[%FoundFlag]=0
	SmartSearchInfo[%SinceHit]=0

	if(SmartSearchInfo[0]<spots)

		MoveToSpot(SmartSearchInfo[%CurrentSpot])
	else
		String Graphstr = "ARCallbackPanel"
		DoWindow $GraphStr
		if (!V_Flag)
			MakePanel(GraphStr)
		endif
		ARExecuteControl("ARUserCallbackMasterCheck_1",GraphStr,0,"")
	
		//turn off Force callbacks.
		ARExecuteControl("ARUserCallbackForceDoneCheck_1",GraphStr,0,"")
	
	
		//set the callback
	endif

	

end

Static Function MoveToSpot(n)
	variable n
	Wave SpotWave=root:SmartSearch:SpotWave
	variable xspot,yspot
	xspot=SpotWave[n][0]
	yspot=SpotWave[n][1]
	td_SetRamp(0.1,"ARC.PIDSLoop.0.SetPointOffset", 0, xspot, "ARC.PIDSLoop.1.SetPointOffset", 0, yspot, "", 0,0,"DE_SmartSearch#Run()")

end

Static Function Run()
	//print td_rv("XSensor")*GV("XLVDTSENS")*1e6
	//print td_rv("YSensor")*GV("YLVDTSENS")*1e6
	DoForceFunc("SingleForce_2")
end

////	//enable callbacks.
//	ARExecuteControl("ARUserCallbackMasterCheck_1",GraphStr,1,"")
//	
//	//turn on Force callbacks.
//	ARExecuteControl("ARUserCallbackForceDoneCheck_1",GraphStr,1,"")
//	
//	
//	//set the callback
//	ARExecuteControl("ARUserCallbackForceDoneSetVar_1",GraphStr,nan,"ARUseGo2ImagePos("+num2str(XIndex+1)+","+num2str(YIndex)+")")
//ARCallbackPanel
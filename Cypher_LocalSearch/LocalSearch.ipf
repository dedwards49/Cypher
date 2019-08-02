#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=DE_LocalSearch
Static Function MakeAGrid(xpnts,xstart,xend,ypnts,ystart,yend)
	variable xpnts,xstart,xend,ypnts,ystart,yend
	wave Waveout
	
	variable TotalSpots=xpnts*ypnts
	
	make/free/n=(totalSpots,2) FreeSpot


	variable xstep=(xend-xstart)/(xpnts-1)
	variable ystep=(yend-ystart)/(ypnts-1)
	print ystep
	print xstep
	FreeSpot[][0] = (mod(P,xpnts)*xstep+xstart)/GV("XLVDTSEns")
	FreeSpot [][1]= (floor(P/xpnts)*ystep+ystart)/GV("yLVDTSEns")
	duplicate/o freespot SpotWave
	
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

Static Function StepAroundStart(TouchesPerSpot)
	variable TouchesPerSpot
	Wave SpotWave
	make/o/n=3 LocalSearchInfo
	LocalSearchInfo[0]=0
		LocalSearchInfo[1]=0
	LocalSearchInfo[2]=TouchesPerSpot

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
	ARExecuteControl("ARUserCallbackForceDoneSetVar_1",GraphStr,nan,"DE_LOcalSearch#NextSpot()")
	MoveToSpot(0)
end

Static Function NextSpot()
	wave SpotWave
	wave LocalSearchInfo
	LocalSearchInfo[1]+=1
	variable spots=dimsize(SpotWave,0)
	if(LocalSearchInfo[1]<	LocalSearchInfo[2])
			Run()
	else
				LocalSearchInfo[0]+=1
		LocalSearchInfo[1]=0
	if(LocalSearchInfo[0]<spots)

		MoveToSpot(LocalSearchInfo[0])
		else
		String Graphstr = "ARCallbackPanel"
	DoWindow $GraphStr
	if (!V_Flag)
		MakePanel(GraphStr)
	endif
	ARExecuteControl("ARUserCallbackMasterCheck_1",GraphStr,0,"")
	
	//turn on Force callbacks.
	ARExecuteControl("ARUserCallbackForceDoneCheck_1",GraphStr,0,"")
	
	
	//set the callback
	endif
	endif
	

end

Static Function MoveToSpot(n)
	variable n
	wave SpotWave
	variable xspot,yspot
	xspot=SpotWave[n][0]
	yspot=SpotWave[n][1]
	td_SetRamp(0.1,"ARC.PIDSLoop.0.SetPointOffset", 0, xspot, "ARC.PIDSLoop.1.SetPointOffset", 0, yspot, "", 0,0,"DE_LocalSearch#Run()")

end

Static Function Run()
print td_rv("XSensor")*GV("XLVDTSENS")*1e6
print td_rv("YSensor")*GV("YLVDTSENS")*1e6
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
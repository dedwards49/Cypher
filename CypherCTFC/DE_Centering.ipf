#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName = DE_Centering


//The goal of this to be able to "add" centering to any protocol by simply inserting new code in 
//the final callback of the standard pull (I.e., in  DE_RampDownDone()) Because of wanting this to be highly
//modular, I want to ensure to do ALL the Z-ramping with the setpoint offet and return it to 0
//at the end. I also need to include something that calls a particular function at the end.


Static function StartCentering()
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	wave ZsensorVolts_Fast=Zsensor_fast
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	wave DefVolts_Fast=DEfV_fast
	wave/t CenteringSettings

	variable rep,zerovolt,pvol,CenterLocVolt,endmultivolt,totaltime,DataLength,outdecirate,runFast,decirate
	
	variable SampleRate,FilterFreq
	
	SampleRate=str2num(CenteringSettings[%Rate][0])*1e3
	FilterFreq=str2num(CenteringSettings[%Bandwidth][0])*1e3
	CenteringSettings[%Zeroish][0]=td_rs("arc.input.A")
	DE_UpdatePlot("Triggered 1")
	
	variable CenteringEngage=DE_CheckRamp("Do You Want to Center?","Center",PopupName="popup8")
		
	if(CenteringEngage==2)  //If you don't wanna center GTFO
		zerovolt=(ZsensorVolts_Fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
		PVol=Zerovolt-str2num(RampInfo[%StartDistance][0])*1e-9/GV("ZLVDTSEns")  //PVol is the approximate location of the start position.
		DE_UpdatePlot("No Trigger")
		ir_StopPISloop(5)
		rep=DE_RepCheck()
		DE_RamptoVol(PVol,"Start","DE_CB_NoMol(\\\"TFE\\\","+num2str(rep)+")")
		return -1
	else
	endif
	
	variable OutDistance=str2num(CenteringSettings[%ForceSet][0])*1e-9
	variable Marker=DE_Centering#PlaceMarker(OutDistance)
	CenterLocVolt= Marker
	
	make/o/n=0 CenteringPathX,CenteringPathY
	totaltime=DE_Centering#MakePath(CenteringPathX,CenteringPathY)  //This makes the waves and returns the total time we expect it to take!
	
	make/o/n=(SampleRate*totaltime) CenteringXReadZ, CenteringYReadZ,CenteringXReadX,CenteringYReadY
	CenteringXReadZ=0
	 CenteringYReadZ=0
	 CenteringXReadX=0
	 CenteringYReadY=0
	
	td_ws("arc.crosspoint.inb","ZSnsr") //Sets the IN.B chanel to read a smoothed ZSnsr...I bet I could get away just reading ZSnsr
	//td_wv("Arc.Input.A.Filter.Freq",FilterFreq)
	td_wv("Arc.Input.B.Filter.Freq",FilterFreq)
	ReadFilterValues(3)
	PV("ZStateChanged",1)	
	decirate=50e3/SampleRate
	StartXandY()
		
	variable Error=0
	Error += td_WS("Event.1","Clear")	
	Error += td_WS("Event.2","Clear")	
	Error+= td_WS("Event.3","Clear")	
	Error += td_WS("Event.4","Clear")	
	Error += td_WS("Event.5","Clear")	
	Error += td_WS("Event.6","Clear")	
			Error += td_WS("Event.9","Clear")	

		Error += td_WS("Event.10","Clear")	
	Error += td_WS("Event.11","Clear")	
	Error+= td_WS("Event.12","Clear")	
	Error += td_WS("Event.13","Clear")	
	Error += td_WS("Event.14","Clear")	
	Error += td_WS("Event.15","Clear")	
	 // td_XSetInWavePair(0,"11","ZSensor",CenteringXReadZ,"XSensor",CenteringXReadX,"print \"FUCK\"",decirate)
	 //td_XSetInWavePair(1,"12","ZSensor",CenteringYReadZ,"YSensor",CenteringYReadY,"print \"You\"",decirate)	 
	  td_XSetInWavePair(0,"11","ZSensor",CenteringXReadZ,"XSensor",CenteringXReadX,"",decirate)
	 td_XSetInWavePair(1,"12","ZSensor",CenteringYReadZ,"YSensor",CenteringYReadY,"",decirate)
	IR_xSetOutWave(0,"11","$OutputXLoop.SetPointOffset",CenteringPathX,"DE_Centering#XDone()",decirate)
	IR_xSetOutWave(1,"12","$OutputYLoop.SetPointOffset",CenteringPathY,"DE_Centering#YDoneFirst()",decirate)

	variable TimetoStart=str2num(CenteringSettings[%Timetostart][0])
	CenterLocVolt/=GV("ZLVDTSENS")
	td_SetRamp(TimetoStart, "PIDSLoop.5.Setpointoffset", 0, CenterLocVolt, "", 0, 0, "", 0, 0, "DE_Centering#Init()")
	
end

Static Function Init()
	wave/t CenteringSettings
	DE_CEntering#PrepPIDS(10,13)
	CenteringSettings[%SurfaceLocation][0]=td_rs("ARC.PIDSLoop.5.SetPoint")
	CenteringSettings[%CurrentOffset][0]=td_rs("ARC.PIDSLoop.5.SetPointOffset")
	
	ir_StopPISLoop(5) //Kills PISLoop5
	td_ws("Event.10","once")  //Starts our new deflection loop
	variable dest0=-1*str2num(CenteringSettings[%ForceSet][0])*1e-12/GV("INVols")/GV("SpringConstant")+str2num(CenteringSettings[%Zeroish][0])
	
	td_SetRamp(0.01, "Arc.PIDSLoop.3.Setpoint", 0, dest0, "", 0, 0, "", 00, 00,"DE_Centering#Forced()" )
end

Static Function Forced()
	td_ws("Event.11","once")

end 
Static Function XDone()
	td_ws("Event.12","once")	//starts Y outwave AND Y WaveRead
end

Static Function YDoneFirst()

	wave/t CenteringSettings
	wave CenteringPathX,CenteringPathY
	variable/c Locations=FindZeros()
	if(real(Locations)==1)
		print "centering Failed!"
		DE_Centering#LostConnection()
		return -1
	endif
	variable/c CurrentLocation
	CurrentLocation+=cmplx(td_rv("ARC.PIDS Loop.0.SetPoint"),0)
	CurrentLocation+=cmplx(0,td_rv("ARC.PIDS Loop.1.SetPoint"))
	Variable/C OffSetMove= Locations-CurrentLocation
	CenteringPathX+=real(OffSetMove)
	CenteringPathY+=imag(OffSetMove)
	UpdateCenteringPlots()
	
	td_SetRamp(str2num(CenteringSettings[%TimeToStart][0]), "PIDSLoop.0.SetpointOffSet", 0, real(OffSetMove), "PIDSLoop.1.SetpointOffSet", 0, imag(OffSetMove), "", 0, 0, "DE_Centering#ReRunCentering()")
	//PrepZHold() //Sets up the ZHold again using the same setpoint as before.
	//td_ws("Event.13","once")	//This stops the deflection feedback, in preparation for setting everything up.
	//td_ws("Event.14","once")	//This starts the ZSnsr feedback on channel 5, it should be set to exactly where we are, so there shouldn't sudden movement.
	

	
	//variable TimetoStart=str2num(CenteringSettings[%Timetostart][0])
	//print TimetoStart
	//td_SetRamp(TimetoStart, "PIDSLoop.5.Setpointoffset", 0, 0, "", 0, 0, "", 0, 0, "DE_Centering#BackatSurface()") //We now ramp the setpointoffset to 0, placing us back at the surface.

end

Static Function ReRunCentering()
	wave/t CenteringSettings

	wave CenteringPathX,CenteringPathY

	variable SampleRate,decirate
	
	SampleRate=str2num(CenteringSettings[%Rate][0])*1e3
	decirate=50e3/SampleRate
	wave CenteringXReadZ, CenteringYReadZ,CenteringXReadX,CenteringYReadY
	IR_XSetInWavePair(0,"11","ZSensor",CenteringXReadZ,"XSensor",CenteringXReadX,"",decirate)
	IR_XSetInWavePair(1,"12","ZSensor",CenteringYReadZ,"YSensor",CenteringYReadY,"",decirate)
	IR_xSetOutWave(0,"11","$OutputXLoop.SetPointOffset",CenteringPathX,"DE_Centering#XDone()",decirate)
	IR_xSetOutWave(1,"12","$OutputYLoop.SetPointOffset",CenteringPathY,"DE_Centering#YDone()",decirate)

	td_ws("Event.11","once")

end

Static Function YDone()
	wave/t CenteringSettings
	PrepZHold() //Sets up the ZHold again using the same setpoint as before.
	td_ws("Event.13","once")	//This stops the deflection feedback, in preparation for setting everything up.
	td_ws("Event.14","once")	//This starts the ZSnsr feedback on channel 5, it should be set to exactly where we are, so there shouldn't sudden movement.


	
	variable TimetoStart=str2num(CenteringSettings[%Timetostart][0])
	td_SetRamp(TimetoStart, "PIDSLoop.5.Setpointoffset", 0, 0, "", 0, 0, "", 0, 0, "DE_Centering#BackatSurface()") //We now ramp the setpointoffset to 0, placing us back at the surface.

end
Static Function FailtoSurface()
	wave/t CenteringSettings
	PrepZHold() //Sets up the ZHold again using the same setpoint as before.
	td_ws("Event.13","once")	//This stops the deflection feedback, in preparation for setting everything up.
	td_ws("Event.14","once")	//This starts the ZSnsr feedback on channel 5, it should be set to exactly where we are, so there shouldn't sudden movement.


	
	variable TimetoStart=str2num(CenteringSettings[%Timetostart][0])
	td_SetRamp(TimetoStart, "PIDSLoop.5.Setpointoffset", 0, 0, "", 0, 0, "", 0, 0, "print \"returned\"") //We now ramp the setpointoffset to 0, placing us back at the surface.

end
Static Function BackatSurface()
	wave CenteringXReadZ, CenteringYReadZ,CenteringXReadX,CenteringYReadY

	Wave/T RampInfo=root:DE_CTFC:RampSettings
	wave ZsensorVolts_Fast=Zsensor_fast
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave/t CenteringSettings
	variable zerovolt,PVol,rep
	variable/c Locations=FindZeros()
	variable/c CurrentLocation
	
	CurrentLocation+=cmplx(td_rv("ARC.PIDS Loop.0.SetPoint"),0)
	CurrentLocation+=cmplx(0,td_rv("ARC.PIDS Loop.1.SetPoint"))
	Variable/C OffSetMove= Locations-CurrentLocation

	//print offsetmove
	if(real(Locations)==1)
		print "centering Failed!"
		DE_Centering#LostConnection()
		return -1
	endif
	DE_SaveReg(CenteringXReadZ,CenteringXReadX)
	DE_SaveReg(CenteringYReadZ,CenteringYReadY)
	td_SetRamp(str2num(CenteringSettings[%TimeToStart][0]), "PIDSLoop.0.SetpointOffSet", 0, real(OffSetMove), "PIDSLoop.1.SetpointOffSet", 0, imag(OffSetMove), "", 0, 0, "DE_Centering#Centered()")

	//td_SetRamp(str2num(CenteringSettings[%TimeToStart][0]), "PIDSLoop.0.Setpoint", 0, real(Locations), "PIDSLoop.1.Setpoint", 0, imag(Locations), "", 0, 0, "DE_Centering#Centered()")
end

Static Function Centered()
//DE_PIS_ZeroSetpointOffset(0,"")
//DE_PIS_ZeroSetpointOffset(1,"")
	UpdateCenteringPlots()
	controlinfo/W=DE_CTFC_Control  check1
	//v_value=1
	if(V_Value==0)
		DE_PauseStage()

	elseif(V_Value==1)
		PauseStage()
	
	endif
end

Static function PauseStage()
	wave/t RefoldSettings
	variable maxSeconds=str2num(RefoldSettings[%ApproachDelay][0])
	if (maxSeconds<=0)
		FinalRamp()
	else
		variable dest0=td_rv("PIDSLoop."+num2str(5)+".SetPoint")
		td_setramp(maxSeconds, "PIDSLoop."+num2str(5)+".SetPoint", 0, dest0, "", 0, 0, "", 0, 0, "DE_Centering#FinalRamp()")
	endif
end

Static Function FinalRamp()
	Wave/T rampsettings
	variable indatarate=str2num(rampsettings[%SampleRate][0])*1e3
	variable indecimation=-1*round(50e3/indatarate)
	variable outdecirate=imag(GenerateCentRampOut())

	wave CentDefv= root:DE_CTFC:DefV_cent
	wave CentZSnsr=root:DE_CTFC:ZSns_cent
	wave CW=root:DE_CTFC:CenteringRampOut
	
	 td_XSetInWavePair(0,"11","Deflection",CentDefv,"ZSensor",CentZSnsr,"",indecimation)
	IR_xSetOutWave(0,"11","PIDSLoop.5.SetPointOffset",CW,"DE_Centering#RampOutDone()",outdecirate)
	print td_Ws("Event.11","once")
	
end
Static Function RampOUtDone()
	Wave/T RepeaSettings,RampSettings
	wave CentDefv= root:DE_CTFC:DefV_cent
	wave CentZSnsr=root:DE_CTFC:ZSns_cent
	wave CW=root:DE_CTFC:CenteringRampOut
	DE_Glide#GlideSave(RepeaSettings,RampSettings,CentDefv,CentZSnsr)
	DE_UpdatePlot("Centered")
	DE_PauseStage()
	
	
end

Static Function/C GenerateCentRampOut()
	Wave/T rampsettings
	wave/t RefoldSettings
	variable totalpoints,slope2,decirate,totaldistance,outdecirate,constant2,endrmp1,endpause1,endrmp2,velocity,datarate

	totaldistance=2*str2num(rampsettings[%NoTriggerDistance][0])*1e-9
	datarate=str2num(RampSettings[%SampleRate][0])*1e3
	velocity=str2num(rampsettings[%RetractVElocity][0])*1e-6

	decirate=50e3/datarate
	totalpoints=datarate*(totaldistance/velocity)

	make/o/n=(totalpoints) root:DE_CTFC:DefV_cent,root:DE_CTFC:ZSns_cent
	if(totalpoints<=5000) //checks if we exceed the limit for IR_xSetOutWave
		outdecirate=decirate
		make/o/n=(totalpoints) root:DE_CTFC:CenteringRampOut
		wave CW=root:DE_CTFC:CenteringRampOut
		slope2=sign(totaldistance)*Velocity/1e-9/GV("ZLVDTSens")*1e-9/(50e3/outdecirate)  //The Sign in front tells us if we're ramping negative or positive.
		constant2=0
		endrmp1=round(50e3/outdecirate*(abs(totaldistance)/(Velocity)/2))
		CW[0,endrmp1-1]=slope2*p+constant2
		CW[endrmp1,]=slope2*endrmp1+constant2-slope2*(p-endrmp1+1)
	else
		totalpoints=5000
		outdecirate=round(50000/totalpoints)*(abs(totaldistance)/velocity)
		make/o/n=(totalpoints) root:DE_CTFC:CenteringRampOut
		wave CW=root:DE_CTFC:CenteringRampOut
		slope2=sign(totaldistance)*Velocity/1e-9/GV("ZLVDTSens")*1e-9/(50e3/outdecirate)  //The Sign in front tells us if we're ramping negative or positive.
		constant2=0
		endrmp1=round(50e3/outdecirate*(abs(totaldistance)/(Velocity)/2))
		CW[0,endrmp1-1]=slope2*p+constant2
		CW[endrmp1,]=slope2*endrmp1+constant2-slope2*(p-endrmp1+1)
//		
	endif
	variable offset=td_ReadValue("PIDSLoop.5.Setpoint")//This adjusts the wave to be a setrampoffset, rather than a straight setramp. 
//	//	//this way I don't have to worry about it, but I honestly don't quite understand this
	CW*=-1
//	if(numtype(offset)==0)		
//		//FastOP CW=CW-(offset)
//	else
//	endif
//
	return cmplx(totalpoints/(50e3/outdecirate),outdecirate)
//
End

Static Function UpdateCenteringPlots()
	wave CenteringXReadZ, CenteringYReadZ,CenteringXReadX,CenteringYReadY
	duplicate/o CenteringXReadZ root:DE_CTFC:MenuStuff:Display_XRZ
	duplicate/o CenteringYReadZ root:DE_CTFC:MenuStuff:Display_YRZ
	duplicate/o CenteringXReadX  root:DE_CTFC:MenuStuff:Display_XRX
	duplicate/o CenteringYReadY root:DE_CTFC:MenuStuff:Display_YRY
	wave fit_CenteringXReadZ,fit_CenteringYReadZ
	duplicate/o fit_CenteringXReadZ  root:DE_CTFC:MenuStuff:Display_FitX
	duplicate/o fit_CenteringYReadZ root:DE_CTFC:MenuStuff:Display_FitY
end
//Simple function that fits a polynomial of order 2 to the function and finds the zero...no particular reason this has to be a polynomial, will fuss with this
//when I have real data.
Static Function/C FindZeros()
	wave CenteringXReadZ, CenteringYReadZ,CenteringXReadX,CenteringYReadY
	CurveFit/Q/NTHR=0 poly 3,  CenteringXReadZ /X=CenteringXReadX /D
	wave w_coef
	variable Xans=-w_coef[1]/2/w_coef[2]
	note/k CenteringXReadZ note($("fit_"+nameofwave(CenteringXReadZ)))
	note/k CenteringXReadX note($("fit_"+nameofwave(CenteringXReadZ)))
	CurveFit/Q/NTHR=0 poly 3,  CenteringYReadZ /X=CenteringYReadY/D
	note/k CenteringYReadZ note($("fit_"+nameofwave(CenteringYReadZ)))
	note/k CenteringYReadY note($("fit_"+nameofwave(CenteringYReadZ)))
	variable Yans=-w_coef[1]/2/w_coef[2]
	variable/C result
	variable error

	Wavestats/Q CenteringXReadX
	variable XPercentMax=V_max-(V_max-V_Min)*.1
	variable XPercentMin=V_min+(V_max-V_Min)*.1

	if((Xans)<(XPercentMax)&&(Xans)>(XPercentMin))
	else
	Error=1
	print "ERROR IN X"
	result=cmplx(1,1)
	endif
	
	Wavestats/Q CenteringYReadY
	variable YPercentMax=V_max-(V_max-V_Min)*.1
	variable YPercentMin=V_min+(V_max-V_Min)*.1

	if((Yans)<(YPercentMax)&&(Yans)>(YPercentMin))
	
	else
		Error=1

	print "ERROR IN Y"
	result=cmplx(1,1)
	endif
	
	if (Error!=1)
	result=cmplx(Xans,Yans)
	endif
	return result
end



Static Function PrepZHold()
	
	Struct ARFeedbackStruct FB
	String ErrorStr = ""
	wave/t CenteringSettings
	ARGetFeedbackParms(FB,"Z")
	variable offset=td_rv("ZSensor")-str2num(CenteringSettings[%SurfaceLocation][0])
	FB.Bank = 5
	FB.Setpoint = str2num(CenteringSettings[%SurfaceLocation][0])
	FB.SetpointOffset = offset
	FB.DynamicSetpoint = 0
	FB.LoopName = "DwellLoop2"
	FB.StartEvent = "14"
	FB.StopEvent = "Never"
	ErrorStr += ir_WritePIDSloop(FB)

end

Static Function Clearloop(num)
	variable num
	Struct ARFeedbackStruct FB
	String ErrorStr = ""
	wave/t CenteringSettings
	ARGetFeedbackParms(FB,"Z")
	variable offset=td_rv("ZSensor")-str2num(CenteringSettings[%SurfaceLocation][0])
	FB.Bank = num
	FB.Setpoint = 0
	FB.SetpointOffset = 0
	FB.DynamicSetpoint = 0
	FB.StartEvent = "Never"
	FB.StopEvent = "Never"
	ErrorStr += ir_WritePIDSloop(FB)
end

//Sets up a deflection feedback loop w/ start and stop events
Static Function PrepPIDS(StartEvent,StopEvent)
	variable StartEvent,StopEvent
	variable Error

	Make/O/T PIDSLoopGroup

	td_RG("ARC.PIDSLoop.2",PIDSLoopGroup)
	
	//Now fill in all the parameters for the feedback loop.  Setpoint is the deflection setpoint //in volts. Note: If you mess with the crosspoint, you may need to change inputchannel
	PIDSLoopGroup[%DynamicSetPoint]="Yes"
	PIDSLoopGroup[%Setpoint]=num2str(-.5)
	PIDSLoopGroup[%SetpointOffset]=num2str(0)
	PIDSLoopGroup[%InputChannel]="arc.input.A"
	PIDSLoopGroup[%OutputChannel]="Output.Z"
	PIDSLoopGroup[%IGain]="3000"
	PIDSLoopGroup[%StartEvent]=num2str(StartEvent)
	PIDSLoopGroup[%StopEvent]=num2str(StopEvent)
	PIDSLoopGroup[%OutputMin]=num2str(td_rv("Output.Z")-200e-9/GV("ZPiezoSens"))
	PIDSLoopGroup[%OutputMax]=num2str(td_rv("Output.Z")+200e-9/GV("ZPiezoSens"))
	PIDSLoopGroup[%Status]="0"

	// Now write this to feedback loop 2 on the ARC.  
	td_WG("ARC.PIDSLoop.3",PIDSLoopGroup)

end


Static function StartXandY()
	Struct ARFeedbackStruct FB
	String ErrorStr = ""

	if(cmpstr(td_rs("Arc.PidsLoop.0.Status"),"1")==0)
		ir_StopPISLoop(0) 
	else
	endif
	ARGetFeedbackParms(FB,"X")
	FB.SetpointOffset = 0
	FB.Setpoint = NaN
	FB.DynamicSetpoint = 1
	ErrorStr += ir_WritePIDSloop(FB)

	if(cmpstr(td_rs("Arc.PidsLoop.1.Status"),"1")==0)
		ir_stopPISLoop(1)
	endif
		
	
	ARGetFeedbackParms(FB,"Y")
	FB.SetpointOffset = 0
	FB.Setpoint = NaN
	FB.DynamicSetpoint = 1
	ErrorStr += ir_WritePIDSloop(FB)
end

Static function MakePath(CenteringPathX,CenteringPathY)
	wave CenteringPathX,CenteringPathY
	wave/T CenteringSettings
	variable RampRange,RampRangeV,RampSpeed,RampSpeedV,RampRate, RampTime,npnts
	
	RampRange=str2num(CenteringSettings[%Distance][0])*1e-9 //Just making this up right now
	RampSpeed=str2num(CenteringSettings[%Velocity][0])*1e-9//in m/s

	RampRangeV=RampRange/GV("ZLVDTSENS")
	RampSpeedV=RampSpeed/GV("ZLVDTSENS")

	RampRate=str2num(CenteringSettings[%Rate][0])*1e3 //pnts/sec
	
	//This below movesX and Y in two steps. Currently those are identical ramps, but I left it coded to be easily changed. Furhter, it could be modified to make 
	//this all part of one ramp and the data is then split.
	RampTime=RampRange/RampSpeed*4 //The time to go one way, times 4, times 2= times8
	npnts=ceil(RampTime*RampRate/4)*4
	make/o/n=(npnts)  CenteringPathX,CenteringPathY
	
	CenteringPathX[0,npnts/4]=RampSpeedV*x/RampRate
	CenteringPathX[npnts/4,3*npnts/4]=CenteringPathX[npnts/4]-RampSpeedV*(x-npnts/4)/RampRate
	CenteringPathX[3*npnts/4,npnts-1]=CenteringPathX[3*npnts/4]+RampSpeedV*(x-3*npnts/4)/RampRate
	
	CenteringPathY[0,npnts/4]=RampSpeedV*x/RampRate
	CenteringPathY[npnts/4,3*npnts/4]=CenteringPathY[npnts/4]-RampSpeedV*(x-npnts/4)/RampRate
	CenteringPathY[3*npnts/4,npnts-1]=CenteringPathY[3*npnts/4]+RampSpeedV*(x-3*npnts/4)/RampRate

	return (RampTime)

end


Static function PlaceMarker(CenterLocation)
	variable CenterLocation
	
	wave/t RefoldSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave ZsensorVolts_Fast=Zsensor_fast
	variable zerovolt,CenterVoltage
	
	zerovolt=(ZsensorVolts_Fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
	CenterVoltage=Zerovolt-CenterLocation/GV("ZLVDTSEns")

	FindLevel/p/q ZsensorVolts_Fast,CenterVoltage
	variable Holdoffpnt=v_Levelx
	Cursor/p/W=DE_CTFC_Control#MostRecent A  Display_DEFV_1  Holdoffpnt
	
	
	ControlInfo /W=DE_CTFC_Control popup6 
	if(cmpstr(s_value,"Yes"))

	else
			DE_UserCursorAdjust("de_Ctfc_Control",0)

	endif
	
	
	CenterVoltage=ZsensorVolts_Fast[pcsr(A,"DE_CTFC_Control#MostRecent")]
	
	return (-td_rv("Zsensor")+CenterVoltage)*GV("ZLVDTSens") //Returns the distance to travel from the current location
end

Static Function LostConnection()
print "LostConnection"
	wave ZsensorVolts_Fast=Zsensor_fast
	wave/T TriggerInfo=root:DE_CTFC:TriggerSettings,RampInfo=root:DE_CTFC:RampSettings
	td_ws("Event.13","once")	//This stops the deflection feedback, in preparation for setting everything up.
	td_stopinwavebank(0)
	td_stopinwavebank(1)
	td_stopoutwavebank(0)
	td_stopoutwavebank(1)
	variable zerovolt,pVol,rep
	zerovolt=(ZsensorVolts_Fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
	PVol=Zerovolt-str2num(RampInfo[%StartDistance][0])*1e-9/GV("ZLVDTSEns")  //PVol is the approximate location of the start position.
	DE_UpdatePlot("No Trigger")
	ir_StopPISloop(5)
	rep=DE_RepCheck()
	DE_RamptoVol(PVol,"Start","DE_CB_NoMol(\\\"TFE\\\","+num2str(rep)+")")

end

Static Function CenteringMonitorConnection()
	
	Wave HackMeterWave
	Variable DeflOffset=0
	Variable ZPztOffset=0
	variable zerovolt,PVol,rep
	Wave/T TriggerInfo=root:DE_CTFC:MBullRefolding_TriggerSettings
	wave/t RefoldSettings
	wave Zsensor_fast
	Wave/T  OrigTriggerInfo=root:DE_CTFC:TriggerSettings
	wave/t RampSettings
	wave/t Command=root:DE_CTFC:MenuStuff:ListComwave
	String DataFolder = GetDF("Meter")
	Wave UpdateMeterUpdate = $DataFolder+"UpdateMeterUpdate"
	Variable Height_V =UpdateMeterUpdate[%Height]

	If (Height_V<0) // Zsensor railed, probably because the tip has disconnected from the molecule.

		Command="Detachment recorded"
		DE_Centering#LostConnection()
		Return 1  // Forces this background process to stop

	EndIf
	
	Return 0 // Must return 0 to keep background process repeating.

End



Function RampXandYAndRecord()
	make/o/n=0  DTEXRamp,DTEYRamp
	variable SampleRate=1e3
	variable totaltime=MakePathFromLine(DTEXRamp,DTEYRamp,500e-9,500e-9,1e3)

	make/o/n=(SampleRate*totaltime) CenteringXReadZ, CenteringYReadZ,CenteringXReadX,CenteringYReadY
	CenteringXReadZ=0
	 CenteringYReadZ=0
	 CenteringXReadX=0
	 CenteringYReadY=0
//	
//	td_ws("arc.crosspoint.inb","ZSnsr") //Sets the IN.B chanel to read a smoothed ZSnsr...I bet I could get away just reading ZSnsr
//	//td_wv("Arc.Input.A.Filter.Freq",FilterFreq)
//	td_wv("Arc.Input.B.Filter.Freq",FilterFreq)
//	ReadFilterValues(3)
//	PV("ZStateChanged",1)	
	variable decirate=50e3/SampleRate
//	StartXandY()
//		
//	variable Error=0
//	Error += td_WS("Event.1","Clear")	
//	Error += td_WS("Event.2","Clear")	
//	Error+= td_WS("Event.3","Clear")	
//	Error += td_WS("Event.4","Clear")	
//	Error += td_WS("Event.5","Clear")	
//	Error += td_WS("Event.6","Clear")	
//			Error += td_WS("Event.9","Clear")	
//
//		Error += td_WS("Event.10","Clear")	
//	Error += td_WS("Event.11","Clear")	
//	Error+= td_WS("Event.12","Clear")	
//	Error += td_WS("Event.13","Clear")	
//	Error += td_WS("Event.14","Clear")	
//	Error += td_WS("Event.15","Clear")	

	 td_XSetInWavePair(0,"11","Deflection",CenteringXReadZ,"XSensor",CenteringXReadX,"",decirate)
	 td_XSetInWavePair(1,"12","Deflection",CenteringYReadZ,"YSensor",CenteringYReadY,"",decirate)
	IR_xSetOutWave(0,"11","$OutputXLoop.SetPointOffset",DTEXRamp,"DE_Centering#RecordDone1()",decirate)
	IR_xSetOutWave(1,"12","$OutputYLoop.SetPointOffset",DTEYRamp,"DE_Centering#RecordDone2()",decirate)
	Td_WS("event.11","once")
//
//	CenterLocVolt/=GV("ZLVDTSENS")
//	td_SetRamp(TimetoStart, "PIDSLoop.5.Setpointoffset", 0, CenterLocVolt, "", 0, 0, "", 0, 0, "DE_Centering#Init()")
	

end

Static Function RecordDone1()
	Td_WS("event.12","once")
end

Static Function RecordDone2()
end
Static function MakePathFromLine(PathXOut,PathYOUt,RampRange,RampSpeed,RampRate)
	wave PathXOut,PathYOUt
	variable RampRange,RampSpeed,RampRate
	wave/T CenteringSettings
	variable RampRangeV,RampSpeedV, RampTime,npnts
	
	//RampRange=str2num(CenteringSettings[%Distance][0])*1e-9 //Just making this up right now
	//RampSpeed=str2num(CenteringSettings[%Velocity][0])*1e-9//in m/s

	RampRangeV=RampRange/GV("ZLVDTSENS")
	RampSpeedV=RampSpeed/GV("ZLVDTSENS")

	//RampRate=str2num(CenteringSettings[%Rate][0])*1e3 //pnts/sec
	
	//This below movesX and Y in two steps. Currently those are identical ramps, but I left it coded to be easily changed. Furhter, it could be modified to make 
	//this all part of one ramp and the data is then split.
	RampTime=RampRange/RampSpeed*4 //The time to go one way, times 4, times 2= times8
	npnts=ceil(RampTime*RampRate/4)*4
	make/free/n=(npnts)  CenteringPathX,CenteringPathY
	print npnts
	CenteringPathX[0,npnts/4]=RampSpeedV*x/RampRate
	CenteringPathX[npnts/4,3*npnts/4]=CenteringPathX[npnts/4]-RampSpeedV*(x-npnts/4)/RampRate
	CenteringPathX[3*npnts/4,npnts-1]=CenteringPathX[3*npnts/4]+RampSpeedV*(x-3*npnts/4)/RampRate
	
	CenteringPathY[0,npnts/4]=RampSpeedV*x/RampRate
	CenteringPathY[npnts/4,3*npnts/4]=CenteringPathY[npnts/4]-RampSpeedV*(x-npnts/4)/RampRate
	CenteringPathY[3*npnts/4,npnts-1]=CenteringPathY[3*npnts/4]+RampSpeedV*(x-3*npnts/4)/RampRate
	
	duplicate/o CenteringPathX PathXOut
	duplicate/o CenteringPathY PathYOUt
	return (RampTime)

end

#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName = DE_Menu_Centering
Static function Start()
	wave CenteringSettings=root:DE_CTFC:StuffToDo:Centering:CenteringWave
//	print td_rv("PIDSLoop.0.Setpoint")+td_RV("PIDSLoop.0.Setpointoffset")
//		print td_rv("PIDSLoop.1.Setpoint")+td_RV("PIDSLoop.1.Setpointoffset")

	
	//Pull some relevent parameters from the waves
	variable SampleRate,FilterFreq,OutDistance,Marker,CenterLocVolt,totaltime,decirate
	SampleRate=(CenteringSettings[%Rate_kHz][0])*1e3//Sampling for the centering wave
	FilterFreq=(CenteringSettings[%Bandwidth_kHz][0])*1e3//Filter frequency to apply to the centering and feedback
	CenteringSettings[%Zeroish_V][0]=str2num(td_rs("Deflection"))//Saves out "zero" for defleciton, which is the deflection votlage at whereever we have paused ourselves
	OutDistance=(CenteringSettings[%Distance_nm][0])*1e-9//How far to pull out in nm
	Marker=DE_Centering#PlaceMarker(OutDistance)//Drops a markers on that location which is outdistance nm from where we are
	CenterLocVolt= Marker//Records the Zsnsor Voltage of where we want to pull to
	
	//create some waves
	make/o/n=0 root:DE_CTFC:StuffToDo:Centering:CenteringPathX,root:DE_CTFC:StuffToDo:Centering:CenteringPathY
	wave CPX=root:DE_CTFC:StuffToDo:Centering:CenteringPathX
	wave CPY=root:DE_CTFC:StuffToDo:Centering:CenteringPathY
	totaltime=DE_Menu_Centering#MakePath(CPX,CPY)  //This makes the X and Y outwaves and returns the total time we expect it to take!
	make/o/n=(SampleRate*totaltime)  root:DE_CTFC:StuffToDo:Centering:CenteringXReadZ,  root:DE_CTFC:StuffToDo:Centering:CenteringYReadZ, root:DE_CTFC:StuffToDo:Centering:CenteringXReadX, root:DE_CTFC:StuffToDo:Centering:CenteringYReadY//makes the waves to read the centering
	
	wave CXRZ=root:DE_CTFC:StuffToDo:Centering:CenteringXReadZ
	wave CYRZ=root:DE_CTFC:StuffToDo:Centering:CenteringYReadZ
	wave CXRX=root:DE_CTFC:StuffToDo:Centering:CenteringXReadX
	wave CYRY=root:DE_CTFC:StuffToDo:Centering:CenteringYReadY

	td_ws("arc.crosspoint.inb","ZSnsr") //Sets the IN.B chanel to read a smoothed ZSnsr...I bet I could get away just reading ZSnsr
	//td_wv("Arc.Input.A.Filter.Freq",FilterFreq)
	td_wv("Arc.Input.B.Filter.Freq",FilterFreq)//Sets smoothing on that channel
	ReadFilterValues(3)
	PV("ZStateChanged",1)	
	decirate=50e3/SampleRate
	 
	DE_Menu_Centering#StartXandY()

	IR_XSetInWavePair(0,"11","ZSensor",CXRZ,"XSensor",CXRX,"",decirate)
	IR_XSetInWavePair(1,"12","ZSensor",CYRZ,"YSensor",CYRY,"",decirate)
	IR_xSetOutWave(0,"11","$OutputXLoop.SetPointOffset",CPX,"DE_Menu_Centering#XDone()",decirate)
	IR_xSetOutWave(1,"12","$OutputYLoop.SetPointOffset",CPY,"DE_Menu_Centering#YDoneFirst()",decirate)

	variable TimetoStart=0.01
	CenterLocVolt/=GV("ZLVDTSENS") //Turns this into a voltage
	td_SetRamp(TimetoStart, "PIDSLoop.5.Setpointoffset", 0, CenterLocVolt, "", 0, 0, "", 0, 0, "DE_Menu_Centering#Init()")//Ramps us back to the desired start point
	
end 
Static Function Forced()
	td_ws("Event.11","once")

end 
Static Function XDone()
	td_ws("Event.12","once")	//starts Y outwave AND Y WaveRead
end

//StartXandY sets up the X and Y PIDS loops on 0 and 1 respectively. If they are currently active, they are stopped to avoid any weirdness and allow them to be ramped from a locatl starting point
Static function StartXandY()
	Struct ARFeedbackStruct FB
	String ErrorStr = ""

	//Setup X as a dynamic feedback loop
	if(cmpstr(td_rs("Arc.PidsLoop.0.Status"),"1")==0)
		ir_StopPISLoop(0) 
	else
	endif
	ARGetFeedbackParms(FB,"X")
	FB.SetpointOffset = 0
	FB.Setpoint = NaN
	FB.DynamicSetpoint = 1
	ErrorStr += ir_WritePIDSloop(FB)

	//Setup Y as a dynamic feedback loop
	if(cmpstr(td_rs("Arc.PidsLoop.1.Status"),"1")==0)
		ir_stopPISLoop(1)
	endif
		
	
	ARGetFeedbackParms(FB,"Y")
	FB.SetpointOffset = 0
	FB.Setpoint = NaN
	FB.DynamicSetpoint = 1
	ErrorStr += ir_WritePIDSloop(FB)
end

//Init prepares the
Static Function Init()
	wave CenteringSettings=root:DE_CTFC:StuffToDo:Centering:CenteringWave
	DE_CEntering#PrepPIDS(10,13)
	CenteringSettings[%SurfaceLocation_V][0]=str2num(td_rs("ARC.PIDSLoop.5.SetPoint"))
	CenteringSettings[%CurrentOffset_V][0]=str2num(td_rs("ARC.PIDSLoop.5.SetPointOffset"))
	
	ir_StopPISLoop(5) //Kills PISLoop5
	td_ws("Event.10","once")  //Starts our new deflection loop
	variable dest0=-1*(CenteringSettings[%Force_pN][0])*1e-12/GV("INVols")/GV("SpringConstant")+(CenteringSettings[%Zeroish_V][0])

	td_SetRamp(0.01, "Arc.PIDSLoop.3.Setpoint", 0, dest0, "", 0, 0, "", 00, 00,"DE_Menu_Centering#Forced()" )
end


Static Function YDoneFirst()
	wave CenteringSettings=root:DE_CTFC:StuffToDo:Centering:CenteringWave
	wave CPX=root:DE_CTFC:StuffToDo:Centering:CenteringPathX
	wave CPY=root:DE_CTFC:StuffToDo:Centering:CenteringPathY
	variable/c Locations=FindZeros_KickIt()
	if(real(Locations)==1)
		print "centering Failed!"
		DE_Menu_Centering#FailtoSurface()
		return -1
	endif
	variable/c CurrentLocation
	CurrentLocation+=cmplx(td_rv("ARC.PIDS Loop.0.SetPoint"),0)
	CurrentLocation+=cmplx(0,td_rv("ARC.PIDS Loop.1.SetPoint"))
	Variable/C OffSetMove= Locations-CurrentLocation
	CPX+=real(OffSetMove)
	CPY+=imag(OffSetMove)

	td_SetRamp(.01, "PIDSLoop.0.SetpointOffSet", 0, real(OffSetMove), "PIDSLoop.1.SetpointOffSet", 0, imag(OffSetMove), "", 0, 0, "DE_Menu_Centering#ReRunCentering()")
end



Static Function FailtoSurface()
	wave/t CenteringSettings
	DE_Menu_Centering#PrepZHold() //Sets up the ZHold again using the same setpoint as before.
	td_ws("Event.13","once")	//This stops the deflection feedback, in preparation for setting everything up.
	td_ws("Event.14","once")	//This starts the ZSnsr feedback on channel 5, it should be set to exactly where we are, so there shouldn't sudden movement.


	
	variable TimetoStart=str2num(CenteringSettings[%Timetostart][0])
	td_SetRamp(TimetoStart, "PIDSLoop.5.Setpointoffset", 0, 0, "", 0, 0, "", 0, 0, "print \"returned\"") //We now ramp the setpointoffset to 0, placing us back at the surface.

end
Static Function/C FindZeros_KIckIt()
	wave CXRZ=root:DE_CTFC:StuffToDo:Centering:CenteringXReadZ
	wave CYRZ=root:DE_CTFC:StuffToDo:Centering:CenteringYReadZ
	wave CXRX=root:DE_CTFC:StuffToDo:Centering:CenteringXReadX
	wave CYRY=root:DE_CTFC:StuffToDo:Centering:CenteringYReadY
	duplicate/o CYRZ root:DE_CTFC:StuffToDo:Centering:XFit
	duplicate/o CYRY root:DE_CTFC:StuffToDo:Centering:YFit
	wave XFit=root:DE_CTFC:StuffToDo:Centering:XFit
	wave YFit=root:DE_CTFC:StuffToDo:Centering:YFit

	CurveFit/Q/NTHR=0 poly 3,  CXRZ /X=CXRX /D=XFit
	wave w_coef
	note/k CXRZ note(XFit)
	note/k CXRX note(XFit)
	variable Xans=-w_coef[1]/2/w_coef[2]
	CurveFit/Q/NTHR=0 poly 3,  CYRZ /X=CYRY/D=YFit
	note/k CYRY note(YFit)
	note/k CYRZ note(YFit)
	variable Yans=-w_coef[1]/2/w_coef[2]
	variable/C result
	variable error

	Wavestats/Q CXRX
	variable XPercentMax=V_max-(V_max-V_Min)*.1
	variable XPercentMin=V_min+(V_max-V_Min)*.1

	if((Xans)<(XPercentMax)&&(Xans)>(XPercentMin))
	else
	Error=1
	print "ERROR IN X"
	result=cmplx(1,1)
	endif
	
	Wavestats/Q CYRY
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


Static Function ReRunCentering()
	wave CenteringSettings=root:DE_CTFC:StuffToDo:Centering:CenteringWave
	wave CPX=root:DE_CTFC:StuffToDo:Centering:CenteringPathX
	wave CPY=root:DE_CTFC:StuffToDo:Centering:CenteringPathY
	wave CXRZ=root:DE_CTFC:StuffToDo:Centering:CenteringXReadZ
	wave CYRZ=root:DE_CTFC:StuffToDo:Centering:CenteringYReadZ
	wave CXRX=root:DE_CTFC:StuffToDo:Centering:CenteringXReadX
	wave CYRY=root:DE_CTFC:StuffToDo:Centering:CenteringYReadY
	
	variable SampleRate,decirate
	
	SampleRate=(CenteringSettings[%Rate_khz][0])*1e3
	decirate=50e3/SampleRate
	IR_XSetInWavePair(0,"11","ZSensor",CXRZ,"XSensor",CXRX,"",decirate)
	IR_XSetInWavePair(1,"12","ZSensor",CYRZ,"YSensor",CYRY,"",decirate)
	IR_xSetOutWave(0,"11","$OutputXLoop.SetPointOffset",CPX,"DE_Menu_Centering#XDone()",decirate)
	IR_xSetOutWave(1,"12","$OutputYLoop.SetPointOffset",CPY,"DE_Menu_Centering#YDone()",decirate)

	td_ws("Event.11","once")

end

Static Function YDone()
	DE_Menu_Centering#PrepZHold() //Sets up the ZHold again using the same setpoint as before.
	td_ws("Event.13","once")	//This stops the deflection feedback, in preparation for setting everything up.
	td_ws("Event.14","once")	//This starts the ZSnsr feedback on channel 5, it should be set to exactly where we are, so there shouldn't sudden movement.
//
//
//	
	variable TimetoStart=.01
	td_SetRamp(TimetoStart, "PIDSLoop.5.Setpointoffset", 0, 0, "", 0, 0, "", 0, 0, "DE_Menu_Centering#BackatSurface()") //We now ramp the setpointoffset to 0, placing us back at the surface.

end
//
Static Function PrepZHold()
	
	Struct ARFeedbackStruct FB
	String ErrorStr = ""
	wave CenteringSettings=root:DE_CTFC:StuffToDo:Centering:CenteringWave
	ARGetFeedbackParms(FB,"Z")
	variable offset=td_rv("ZSensor")-(CenteringSettings[%SurfaceLocation_V][0])
	FB.Bank = 5
	FB.Setpoint = (CenteringSettings[%SurfaceLocation_V][0])
	FB.SetpointOffset = offset
	FB.DynamicSetpoint = 0
	FB.LoopName = "DwellLoop2"
	FB.StartEvent = "14"
	FB.StopEvent = "Never"
	ErrorStr += ir_WritePIDSloop(FB)

end

Static Function BackatSurface()
	wave CenteringSettings=root:DE_CTFC:StuffToDo:Centering:CenteringWave
	wave CPX=root:DE_CTFC:StuffToDo:Centering:CenteringPathX
	wave CPY=root:DE_CTFC:StuffToDo:Centering:CenteringPathY
	wave CXRZ=root:DE_CTFC:StuffToDo:Centering:CenteringXReadZ
	wave CYRZ=root:DE_CTFC:StuffToDo:Centering:CenteringYReadZ
	wave CXRX=root:DE_CTFC:StuffToDo:Centering:CenteringXReadX
	wave CYRY=root:DE_CTFC:StuffToDo:Centering:CenteringYReadY
	
	
	//Wave/T RampInfo=root:DE_CTFC:RampSettings
	//wave ZsensorVolts_Fast=Zsensor_fast
	//Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	//wave/t CenteringSettings
	//variable zerovolt,PVol,rep
	variable/c Locations=FindZeros_KIckIt()
	variable/c CurrentLocation,OffsetPositions
	
	CurrentLocation+=cmplx(td_rv("ARC.PIDS Loop.0.SetPoint"),0)
	CurrentLocation+=cmplx(0,td_rv("ARC.PIDS Loop.1.SetPoint"))
	Variable/C OffSetMove=Locations- CurrentLocation


	if(real(Locations)==1)
		print "centering Failed!"
		//DE_Centering#LostConnection()
		return -1
	endif
	DE_SaveReg(CXRZ,CXRX)
	DE_SaveReg(CYRZ,CYRY)

	td_SetRamp(.03, "PIDSLoop.0.SetpointOffSet", 0, real(OffSetMove), "PIDSLoop.1.SetpointOffSet", 0, imag(OffSetMove), "", 0, 0, "DE_Menu_Centering#Centered()")

	//td_SetRamp(.01, "PIDSLoop.0.Setpoint", 0, real(Locations), "PIDSLoop.1.Setpoint", 0, imag(Locations), "", 0, 0, "DE_Centering#Centered_KickIt()")
end

Static Function Centered()
print "CENTERED"
CenterDone()
end

Static function MakePath(CenteringPathX,CenteringPathY)
	wave CenteringPathX,CenteringPathY
	wave CenteringSettings=root:DE_CTFC:StuffToDo:Centering:CenteringWave
	variable RampRange,RampRangeV,RampSpeed,RampSpeedV,RampRate, RampTime,npnts
	
	RampRange=(CenteringSettings[%Width_nm][0])*1e-9 //Just making this up right now
	RampSpeed=(CenteringSettings[%Velocity_nmps][0])*1e-9//in m/s

	RampRangeV=RampRange/GV("ZLVDTSENS")
	RampSpeedV=RampSpeed/GV("ZLVDTSENS")

	RampRate=(CenteringSettings[%Rate_kHz][0])*1e3 //pnts/sec
	
	//This below movesX and Y in two steps. Currently those are identical ramps, but I left it coded to be easily changed. Furhter, it could be modified to make 
	//this all part of one ramp and the data is then split.
	RampTime=RampRange/RampSpeed*4 //The time to go one way, times 4, times 2= times8
	npnts=ceil(RampTime*RampRate/4)*4
	make/o/n=(npnts)  root:DE_CTFC:StuffToDo:Centering:CenteringPathX,root:DE_CTFC:StuffToDo:Centering:CenteringPathY
	wave CPX=root:DE_CTFC:StuffToDo:Centering:CenteringPathX
	wave CPY=root:DE_CTFC:StuffToDo:Centering:CenteringPathY
	CPX[0,npnts/4]=RampSpeedV*x/RampRate
	CPX[npnts/4,3*npnts/4]=CenteringPathX[npnts/4]-RampSpeedV*(x-npnts/4)/RampRate
	CPX[3*npnts/4,npnts-1]=CenteringPathX[3*npnts/4]+RampSpeedV*(x-3*npnts/4)/RampRate
	
	CPY[0,npnts/4]=RampSpeedV*x/RampRate
	CPY[npnts/4,3*npnts/4]=CenteringPathY[npnts/4]-RampSpeedV*(x-npnts/4)/RampRate
	CPY[3*npnts/4,npnts-1]=CenteringPathY[3*npnts/4]+RampSpeedV*(x-3*npnts/4)/RampRate

	return (RampTime)

end

Static Function MakeWave()
	make/o/n=9 root:DE_CTFC:StuffToDo:Centering:CenteringWave
	wave CW=root:DE_CTFC:StuffToDo:Centering:CenteringWave


	CW={30,150,1,0.1,100,100,0,0,0}
	
	SetDimLabel 0,0,Width_nm,CW
	SetDimLabel 0,1,Velocity_nmps,CW
	SetDimLabel 0,2,Rate_kHz,CW
	SetDimLabel 0,3,Bandwidth_kHz,CW
	SetDimLabel 0,4,Distance_nm,CW
	SetDimLabel 0,5,Force_pN,CW
	SetDimLabel 0,6,Zeroish_V,CW
	SetDimLabel 0,7,SurfaceLocation_V,CW
	SetDimLabel 0,8,CurrentOffset_V,CW

end

Static Function UpdateLastCenterandSave(CXRX,CXRZ,CYRY,CYRZ)
	wave CXRX,CXRZ,CYRY,CYRZ
	note CXRX DE_CTFCMenu#GenericNoteFile()
	note CXRZ DE_CTFCMenu#GenericNoteFile()
	note CYRY DE_CTFCMenu#GenericNoteFile()
	note CYRZ DE_CTFCMenu#GenericNoteFile()

	duplicate/o CXRX root:DE_CTFC:StuffToDo:LastCXRX
	duplicate/o CXRZ root:DE_CTFC:StuffToDo:LastCXRZ
	duplicate/o CYRY root:DE_CTFC:StuffToDo:LastCYRY
	duplicate/o CYRZ root:DE_CTFC:StuffToDo:LastCYRZ
	NVar LCen= root:DE_CTFC:StuffToDo:LastCentered
	variable savenum=LCen+1
	LCen=savenum
	
	duplicate CXRX $("root:DE_CTFC:StuffToDo:Centering:Saves:CXRX_"+num2str(savenum))
	duplicate CXRZ $("root:DE_CTFC:StuffToDo:Centering:Saves:CXRZ_"+num2str(savenum))
	duplicate CYRY $("root:DE_CTFC:StuffToDo:Centering:Saves:CYRX_"+num2str(savenum))
	duplicate CYRZ $("root:DE_CTFC:StuffToDo:CEntering:Saves:CYRZ_"+num2str(savenum))
end
Static Function CenterDone()
	print td_rv("PIDSLoop.0.Setpoint")+td_RV("PIDSLoop.0.Setpointoffset")
	print td_rv("PIDSLoop.1.Setpoint")+td_RV("PIDSLoop.1.Setpointoffset")
	wave CXRZ=root:DE_CTFC:StuffToDo:Centering:CenteringXReadZ
	wave CYRZ=root:DE_CTFC:StuffToDo:Centering:CenteringYReadZ
	wave CXRX=root:DE_CTFC:StuffToDo:Centering:CenteringXReadX
	wave CYRY=root:DE_CTFC:StuffToDo:Centering:CenteringYReadY
	SVar Lcen=root:DE_CTFC:StuffToDo:LastCenteredTime
	LCen=time()

	DE_Menu_Centering#UpdateLastCenterandSave(CXRX,CXRZ,CYRY,CYRZ)
	DE_CTFCMEnu#SaveWavesOut("Centering")
	
	
	DE_CTFCMenu#DoAPlot("Centering")
	
	DE_CTFCMenu#CheckonPostRamp("Centered")
end
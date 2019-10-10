#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma modulename=DE_Calibrate

Static Function InitializeSettings()

	NewDataFolder/O root:DE_Calibrate

	make/T/o/n=14 root:DE_Calibrate:CalibrateSettings
	wave/T Settings=root:DE_Calibrate:CalibrateSettings
	
	SetDimLabel 0,0,ApproachSpeed,Settings
	SetDimLabel 0,1,SurfDwell,Settings
	SetDimLabel 0,2,RetractSpeed,Settings
	SetDimLabel 0,3,SurfaceForce,Settings
	SetDimLabel 0,4,TotalTime,Settings
	SetDimLabel 0,5, SampleRate,Settings
	SetDimLabel 0,6, TotalSpots,Settings
	SetDimLabel 0,7, StepSize,Settings
	SetDimLabel 0,8,Callback,Settings
	SetDimLabel 0,9,MaxPosition,Settings
	SetDimLabel 0,10,MinPosition,Settings
	SetDimLabel 0,11, CurrentSpot,Settings
	SetDimLabel 0,12, StartInvolsTime,Settings
	SetDimLabel 0,13, EndInvolsTime,Settings



	Settings={"0.4","0.2","0.4","500","25","50","5","0.5","DE_Calibrate#Done()","0","0","0","0","0"}
	

	
	

end

Static Function ResetSettingsWave()
wave/T Settings=root:DE_Calibrate:CalibrateSettings
	
	SetDimLabel 0,8,Callback,Settings
	SetDimLabel 0,9,MaxPosition,Settings
	SetDimLabel 0,10,MinPosition,Settings
	SetDimLabel 0,11, CurrentSpot,Settings
	SetDimLabel 0,12, StartInvolsTime,Settings
	SetDimLabel 0,13, EndInvolsTime,Settings
	Settings[%TotalTime]="25"
	Settings[%Callback]="DE_Calibrate#Done"
	Settings[%MaxPosition]="0"
	Settings[%MinPosition]="0"
	Settings[%CurrentSpot]="0"
	Settings[%StartInvolsTime]="0"
	Settings[%EndInvolsTime]="0"

end

Static Function StartNewLeverl()
	NewDataFolder/O root:DE_Calibrate:Current
	make/o/n=(9,0) root:DE_Calibrate:Current:Results
	wave Results=root:DE_Calibrate:Current:Results

	SetDimLabel 0,0,Invols,Results
	SetDimLabel 0,1,TopPos,Results
	SetDimLabel 0,2,TopSpringConstant,Results
	SetDimLabel 0,3,TopFrequency,Results
	SetDimLabel 0,4, TopQValue,Results
	SetDimLabel 0,5,BotPos,Results
	SetDimLabel 0,6,BotSpringConstant,Results
	SetDimLabel 0,7,BotFrequency,Results
	SetDimLabel 0,8, BotQValue,Results
end

Static Function GrabExistingCTFCparms()

	Make/O/T root:DE_Calibrate:TriggerSettings
	Wave/T Settings=root:DE_Calibrate:TriggerSettings
	Variable error=0
	error+=td_ReadGroup("ARC.CTFC",Settings)
	return error

End //DE_GrabExistingCTFCparms()


 Static Function LoadCTFCparms()
	Wave/T Settings=root:DE_Calibrate:CalibrateSettings
	Wave/T TriggerInfo=root:DE_Calibrate:TriggerSettings
	variable ApproachSpeed,RetractSpeed,SurfaceTrigger,CurrentVoltage
	ApproachSpeed = str2num(Settings[%ApproachSpeed][0])*1e-6/GV("ZPiezoSens") //set the approach speed by converting from um/s to V/s. Note this is positive to approach the surface.
	RetractSpeed = -1*str2num(Settings[%RetractSpeed][0])*1e-6/GV("ZPiezoSens") //set the approach speed by converting from um/s to V/s. Note this is positive to approach the surface.
	SurfaceTrigger = str2num(Settings[%SurfaceForce][0])*1e-12/GV("InvOLS")/GV("SpringConstant")   //The desired deflection (converted to Volts) to reach at the surface
	TriggerInfo[%RampChannel] = "Output.Z"
	TriggerInfo[%RampOffset1] = num2str(150) //Max Z Piezo (in volts) on initial push
	TriggerInfo[%RampSlope1] = num2str(ApproachSpeed)  //Z Piezo Volts/s
	TriggerInfo[%RampOffset2] = num2str(-150) //Max Z Piezo (in volts) on initial retraction.This retracts to the initial starting point. 
	TriggerInfo[%RampSlope2] = num2str(RetractSpeed) //Z Piezo Volts/s
	TriggerInfo[%TriggerChannel1] = "Deflection"
	TriggerInfo[%TriggerValue1] = num2str(SurfaceTrigger) //Deflection Volts
	TriggerInfo[%TriggerCompare1] = ">="
	TriggerInfo[%TriggerChannel2] = "Output.Dummy"
	TriggerInfo[%TriggerValue2] = num2str(0) 
	TriggerInfo[%TriggerCompare2] = "<="
	TriggerInfo[%TriggerHoldoff2] = num2str(0)
	TriggerInfo[%DwellTime1] = Settings[%SurfDwell][0]
	TriggerInfo[%DwellTime2] = num2str(0)
	TriggerInfo[%EventDwell] = "4,6"
	TriggerInfo[%EventRamp] = "3,5"
	TriggerInfo[%EventEnable] = "2"
	TriggerInfo[%CallBack] = Settings[%Callback][0]
	TriggerInfo[%TriggerType1] = "Relative Ramp Start" 
	TriggerInfo[%TriggerType2] = "Relative Ramp Start" 
	String ErrorStr = ""
	ErrorStr += num2str(td_WriteString("Event.5","Clear"))+","
	ErrorStr += num2str(td_WriteString("Event.3","Clear"))+","
	ErrorStr += num2str(td_writeGroup("ARC.CTFC",TriggerInfo))+","
	Struct ARFeedbackStruct FB
	ARGetFeedbackParms(FB,"Z")
	FB.Bank = 4
	FB.Setpoint = NaN
	FB.DynamicSetpoint = 1
	FB.LoopName = "DwellLoop"
	FB.StartEvent = "4"
	FB.StopEvent = "5"
	ErrorStr += ir_WritePIDSloop(FB)//This writes the CTFC parameters
	ARReportError(ErrorStr)	


End //LoadCTFCparms

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// DE_SetInWavesFromCTFC(): Setup Inwaves for Force Ramp.  I'm using bank 0 for deflection and z sensor waves.  This is set to event 2. The input wave of RampInfo provides the ramp parameters that have been input
//(specifically, this provides the sampling rate and trace length). The input string Experiment provides some string keywords to identify what sort of readout we want, and how to call the data done parameter at the end.
Static Function SetInWavesFromCTFC()
	Wave/T Settings=root:DE_Calibrate:CalibrateSettings

//	string Type
//	wave customwave1
//	variable decirate,total1,newrate
//	
//	//This makes and assigns the waves for reading the "fast" portion of the scan, which is the first pull.
	Make/o/N=(str2num(Settings[%SampleRate][0])*str2num(Settings[%TotalTime][0])*1000)/O root:DE_Calibrate:ZSensor_Calibrate,root:DE_Calibrate:DefV_Calibrate 
	wave ZWave=root:DE_Calibrate:ZSensor_Calibrate
	wave DEfWave=root:DE_Calibrate:DefV_Calibrate 
	IR_XSetInWavePair(1,"2","Deflection",DEfWave,"Cypher.LVDT.Z",ZWave,"",50/str2num(Settings[%SampleRate][0]))
//	
		
end//DE_SetInWavesFromCTFC

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


//DE_StartCTFC() Starts the first CTFC each and every time. This is the main one!
Static Function StartCalibrate()
	Wave/T Settings=root:DE_Calibrate:CalibrateSettings
	wave Results=root:DE_Calibrate:Current:Results

	if(str2num(Settings[%CurrentSpot])!=0)
		insertpoints/M=1 dimsize(Results,1),1, Results

	endif
//
	If(abs(Td_rv("Deflection"))>8)  //If you deflection is above a couple of volts, we freak out!
		print "Deflection Exceeds Max :8V"
		td_setramp(1,"arc.output.z",0,0,"",0,0,"",0,0,"") 

	return -1
	endif

	GrabExistingCTFCParms()
	LoadCTFCParms()
	SetInWavesFromCTFC()
	Variable Error = 0
	Error += td_WS("Event.2","Clear")	
	Error += td_WS("Event.3","Clear")	
	Error += td_WS("Event.4","Clear")	
	Error += td_WS("Event.5","Clear")	
	Error += td_WS("Event.6","Clear")		
	Error += td_WS("Event.2","Once")		//Fires event.2, this starts everything!
//	DE_TriggeredForcePanel#UpdateCommandOut("Begin Approach","Add")
	If (Error > 0)
		print "Error in StartMyCTFC"
	Endif

End //DE_StartCTFC()

Static Function Done()
	wave ZWave=root:DE_Calibrate:ZSensor_Calibrate
	wave DEfWave=root:DE_Calibrate:DefV_Calibrate 
	Wave/T Settings=root:DE_Calibrate:CalibrateSettings
	

	td_stopinwavebank(1)
	wavetransform/o zapNaNs ZWave
	wavetransform/o zapNaNs DEfWave
	String DName="root:DE_Calibrate:Current:DeflV_"+Settings[%CurrentSpot]
	String ZName="root:DE_Calibrate:Current:ZSnsr_"+Settings[%CurrentSpot]
	duplicate/o DEfWave $DName
	duplicate/o ZWave $ZName
	
	
	variable/C Positions=FindMaxandMin()
	Settings[%MaxPosition]=num2str(real(positions))
	Settings[%MinPosition]=num2str(imag(positions))

	if(str2num(Settings[%CurrentSpot])!=0)
		SelectInvolRegion()
	else
	endif
	
	CalculateInvols()

	StartJustZ()
	td_SetRamp(.01, "PIDSLoop.2.Setpoint", 0, real(positions), "", 0, 0, "", 0, 0, "DE_Calibrate#ToMax()")

end

Static Function ToMax()

	print td_rv("Cypher.LVDT.Z")
	SetupThermals("DE_Calibrate#MaxDone()")
	DoThermalFunc("DoThermalButton_1")
end

Static Function MaxDone()
	Wave/T Settings=root:DE_Calibrate:CalibrateSettings

	wave Results=root:DE_Calibrate:Current:Results

	DoThermalFunc("TryFit_1")
	SaveThermal("Top")
	StartJustZ()
	td_SetRamp(2, "PIDSLoop.2.Setpoint", 0, str2num(Settings[%MinPosition]), "", 0, 0, "", 0, 0, "DE_Calibrate#ToMin()")

end

Static Function ToMin()
	print td_rv("Cypher.LVDT.Z")
	SetupThermals("DE_Calibrate#MinDone()")
	DoThermalFunc("DoThermalButton_1")

end



Static Function MinDone()

	Wave/T Settings=root:DE_Calibrate:CalibrateSettings
	wave TVW=root:Packages:MFP3D:Main:Variables:ThermalVariablesWave
	wave MVW=root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	DoThermalFunc("TryFit_1")
	SaveThermal("Bottom")
	td_SetRamp(.1, "Output.Z", 0, -10, "", 0, 0, "", 0, 0, "DE_Calibrate#DoneorNot()")

	print "This worked you fat fuck"
end


Static Function DoneorNot()
	Wave/T Settings=root:DE_Calibrate:CalibrateSettings
	variable NewSpot=str2num(Settings[%CurrentSpot])+1
	if(newspot>=str2num(Settings[%TotalSpots]))
		FullCycleDone()
	else
		
		Settings[%CurrentSpot]=num2str(NewSpot)
		MoveStageandGo()
	endif
	

end

Static Function MoveStageandGo()
	Wave/T Settings=root:DE_Calibrate:CalibrateSettings
	variable StepSize=str2num(Settings[%StepSize])
	variable direction=(floor(enoise(2)))+2
	Variable TargetPosition=td_rv("PIDSLoop.0.Setpoint")+StepSize*1e-9/GV("XLVDTSENS")
	td_SetRamp(2, "PIDSLoop.0.Setpoint", 0, str2num(Settings[%MinPosition]), "", 0, 0, "", 0, 0, "DE_Calibrate#StartCalibrate()")
end

Static Function FullCycleDone()
	Wave/T Settings=root:DE_Calibrate:CalibrateSettings
	String LabelFolder
	string basename="root:DE_Calibrate:"
	string testfolder
	variable n=-1
	duplicate/T/o Settings root:DE_Calibrate:Current:CalibrateSettings 
	do
		n+=1
		LabelFolder="Save_"+num2str(n)
		testfolder=basename+LabelFolder
	while(DataFolderExists(testfolder)==1)
	
	Prompt LabelFolder,"This lever is done, enter prefered name for folder"
	DoPrompt "Folder Name", LabelFolder
	
	testfolder=basename+LabelFolder
	if(DataFolderExists(testfolder)==0)
		renamedatafolder root:DE_calibrate:Current $LabelFolder

		return 0
	endif
		LabelFolder="Save_"+num2str(n)

	Prompt LabelFolder,"That folder name is taken"
	DoPrompt "Folder Name", LabelFolder
	
	testfolder=basename+LabelFolder
	if(DataFolderExists(testfolder)==0)
		renamedatafolder root:DE_calibrate:Current $LabelFolder

		return 0
	endif
	
	LabelFolder="Save_"+num2str(n)
	print "You failed to give a unique name, so we've saved this folder as: "+LabelFolder
	renamedatafolder root:DE_calibrate:Current $LabelFolder

end

Static Function SelectInvolRegion()
	wave ZWave=root:DE_Calibrate:ZSensor_Calibrate
	wave DEfWave=root:DE_Calibrate:DefV_Calibrate 
	Wave/T TriggerInfo=root:DE_Calibrate:TriggerSettings
	Wave/T Settings=root:DE_Calibrate:CalibrateSettings
	variable CsrTime1,CsrTime2

	variable SurfaceTriggerTime=str2num(TriggerInfo[%TriggerTime1])
	variable ApproximateSurfaceTime=str2num(Settings[%SurfaceForce])*1e-12/gv("SpringConstant")/str2num(Settings[%ApproachSpeed])

	duplicate/o/R=(0,SurfaceTriggerTime) DEfWave root:DE_Calibrate:AppDef
	duplicate/o/R=(0,SurfaceTriggerTime) ZWave root:DE_Calibrate:AppZSn
	wave AppDef=root:DE_Calibrate:AppDef
	wave AppZSn=root:DE_Calibrate:AppZSn

	DoWindow $"InvolsSelect"
	if (V_Flag==1)
		killwindow $"InvolsSelect"	
	endif
	Display/N=InvolsSelect AppDef vs AppZSn
	SetAxis/W=InvolsSelect bottom (SurfaceTriggerTime-2*ApproximateSurfaceTime),SurfaceTriggerTime
	SetAxis/A=2/W=InvolsSelect left
	Cursor/W=InvolsSelect A  AppDef  (SurfaceTriggerTime-ApproximateSurfaceTime)
	Cursor/W=InvolsSelect B  AppDef  SurfaceTriggerTime
	DE_UserCursorAdjust("InvolsSelect",0)

	CsrTime1=pnt2x(AppZSn,pcsr(A,"InvolsSelect"))
	CsrTime2=pnt2x(AppZSn,pcsr(B,"InvolsSelect"))
	Settings[%StartInvolsTime]=num2str(SurfaceTriggerTime-CsrTime1)
	Settings[%EndInvolsTime]=num2str(SurfaceTriggerTime-CsrTime2)
	killwindow $"InvolsSelect"	

	killwaves AppDef,AppZSn
end

Static Function CalculateInvols()
	wave ZWave=root:DE_Calibrate:ZSensor_Calibrate
	wave DEfWave=root:DE_Calibrate:DefV_Calibrate 
	Wave/T Settings=root:DE_Calibrate:CalibrateSettings
	Wave/T TriggerInfo=root:DE_Calibrate:TriggerSettings
	wave Results=root:DE_Calibrate:Current:Results

	variable SurfaceTriggerTime=str2num(TriggerInfo[%TriggerTime1])
	variable CsrTime1=SurfaceTriggerTime-str2num(Settings[%StartInvolsTime])
	variable CsrTime2=SurfaceTriggerTime-str2num(Settings[%EndInvolsTime])
	duplicate/free/r=(csrTime1,csrTime2) DEfWave DefFree
	duplicate/free/r=(csrTime1,csrTime2) ZWave	ZFree
	CurveFit/Q/W=2/NTHR=0 line  DefFree /X=ZFree
	wave W_coef,W_sigma
	Results[%Invols][dimsize(Results,1)-1]=w_coef[1]
	ForceSetVarFunc("DisplaySpringConstantSetVar_1",w_coef[1],num2str(w_coef[1]),  "MasterVariablesWave[%DisplaySpringConstant][%Value]")
	killwaves W_coef,W_sigma
end

Static Function SaveThermal(ToporBottom)
	string ToporBottom
	Wave Thermal=root:packages:Mfp3d:Tune:TotalPsd
	wave Results=root:DE_Calibrate:Current:Results
	wave TVW=root:Packages:MFP3D:Main:Variables:ThermalVariablesWave
	wave MVW=root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	Wave/T Settings=root:DE_Calibrate:CalibrateSettings
	String SaveName="root:DE_Calibrate:Current:Thermal_"+Settings[%CurrentSpot]
	strswitch(ToporBottom)
		case "Top":
			//Results[%Invols][dimsize(Results,1)-1]=MVW[%InvOLS][%value]
			Results[%TopPos][dimsize(Results,1)-1]=td_rv("Zsensor")
			Results[%TopSpringConstant][dimsize(Results,1)-1]=MVW[%DisplaySpringConstant][%value]
			Results[%TopFrequency][dimsize(Results,1)-1]=TVW[%ThermalFrequency][%Value]
			Results[%TopQValue][dimsize(Results,1)-1]=TVW[%ThermalQ][%Value]
			SaveName=SaveName+"_Top"
		
		break
		
		
		case "Bottom":
			SaveName=SaveName+"_Bottom"
			Results[%BotPos][dimsize(Results,1)-1]=td_rv("Zsensor")
			Results[%BotSpringConstant][dimsize(Results,1)-1]=MVW[%DisplaySpringConstant][%value]
			Results[%BotFrequency][dimsize(Results,1)-1]=TVW[%ThermalFrequency][%Value]
			Results[%BotQValue][dimsize(Results,1)-1]=TVW[%ThermalQ][%Value]

		break
		
		default:
		
		break
		
	endswitch
	duplicate/o Thermal $SaveName
end

Static Function SetupThermals(Callback)
	String Callback
	ThermalSetVarFunc("ThermalSamplesLimitSetVar_1",50,"050","ThermalVariablesWave[%ThermalSamplesLimit][%Value]")
	
	String Graphstr = "ARCallbackPanel"
	DoWindow $GraphStr
	if (!V_Flag)
		MakePanel(GraphStr)
	endif
	ARExecuteControl("ARUserCallbackMasterCheck_1",GraphStr,1,"")
	
	//turn on Force callbacks.
	ARExecuteControl("ARUserCallbackThermDoneCheck_1",GraphStr,1,"")
	
	//set the callback
	ARExecuteControl("ARUserCallbackThermDoneSetVar_1",GraphStr,nan,Callback)

	DOThermalFunc("ShowThermalOpParmButton_1")
	checkbox XY_High_Voltage_RelayCheckBox value=1
	checkbox Z_High_Voltage_RelayCheckBox value=1
	checkbox LVDT_DriveCheckBox value=1
	ThermalOpParmFunc("XY_High_Voltage_RelayCheckBox",1)
	ThermalOpParmFunc("Z_High_Voltage_RelayCheckBox",1)
	ThermalOpParmFunc("LVDT_DriveCheckBox",1)
	checkbox PIS_LoopsCheckBox value=1
	ThermalOpParmFunc("PIS_LoopsCheckBox",1)
	killwindow ThermalOpParmPanel
end

Static Function/C FindMaxandMin()
	Wave/T Settings=root:DE_Calibrate:CalibrateSettings
	wave ZWave=root:DE_Calibrate:ZSensor_Calibrate
	wave DEfWave=root:DE_Calibrate:DefV_Calibrate 
	variable RetractSpeed
	RetractSpeed = str2num(Settings[%RetractSpeed][0])*1e-6//set the approach speed by converting from um/s to V/s. Note this is positive to approach the surface.
	variable waveLength=700e-9
	variable cutpntLength=700e-9/RetractSpeed/dimdelta(ZWave,0)

	duplicate/free/r=[numpnts(ZWave)-1-cutpntLength,] ZWave WZsen_fit
	duplicate/free/r=[numpnts(DEfWave)-1-cutpntLength,] DEfWave WDef_fit

	Make/D/N=6/O W_coef
	W_coef[0] = {(WDef_fit[0]),-00e-9,10e-3,30,0,0}

	FuncFit/Q/W=2/NTHR=0 linearsin2 W_coef  WDef_fit /X=WZsen_fit
	variable/C Result= EstimateZeroInRange(WDef_fit,WZsen_fit,W_coef)
	print/C Result
	wave W_Sigma
	killwaves W_coef,W_Sigma
	return Result
end

function linearsin2(w,x):fitfunc
	wave w
	variable x
	return w[0]+w[1]*x+(w[2]+w[5]*x)*Sin(w[3]*x+w[4])
end

Static Function/C EstimateZeroInRange(DCut,ZCut,W_coef)
	wave DCut,ZCut,W_coef
	duplicate/free ZCut DTest
	DTest=Cos(W_coef[3]*ZCut+W_coef[4])
	FindLevel/Q/P/R=[numpnts(DTest)-1,0] DTest,0
	variable FirstPnt=V_LevelX
	FindLevel/Q/P/R=[FirstPnt-100,0] DTest,0
	variable SecondPnt=V_LevelX
	variable/C Result
	if(DCut[FirstPnt]>DCut[SecondPnt])
		Result=cmplx(ZCut[FirstPnt],ZCut[SecondPnt])
 
	else
		Result=cmplx(ZCut[SecondPnt],ZCut[FirstPnt])

	endif
	wave W_FindLevels
	killwaves W_FindLevels
	return Result
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

Static function StartJustZ()
	Struct ARFeedbackStruct FB
	String ErrorStr = ""

	if(cmpstr(td_rs("Arc.PidsLoop.2.Status"),"1")==0)
		ir_stopPISLoop(2)
	endif
		
	
	ARGetFeedbackParms(FB,"Z")
	FB.SetpointOffset = 0
	FB.Setpoint = NaN
	FB.DynamicSetpoint = 1
	ErrorStr += ir_WritePIDSloop(FB)
end



Static Function DE_UserCursorAdjust(graphName,autoAbortSecs)
	String graphName
	Variable autoAbortSecs

	DoWindow/F $graphName							// Bring graph to front
	if (V_Flag == 0)									// Verify that graph exists
		Abort "UserCursorAdjust: No such graph."
		return -1
	endif

	NewPanel /K=2 /W=(187,368,437,531) as "Pause for Cursor"
	DoWindow/C tmp_PauseforCursor					// Set to an unlikely name
	AutoPositionWindow/E/M=1/R=$graphName			// Put panel near the graph

	DrawText 21,20,"Adjust the cursors and then"
	DrawText 21,40,"Click Continue."
	Button button0,pos={80,58},size={92,20},title="Continue"
	Button button0,proc=UserCursorAdjust_ContButtonProc
	Variable didAbort= 0
	if( autoAbortSecs == 0 )
		PauseForUser tmp_PauseforCursor,$graphName
	else
		SetDrawEnv textyjust= 1
		DrawText 162,103,"sec"
		SetVariable sv0,pos={48,97},size={107,15},title="Aborting in "
		SetVariable sv0,limits={-inf,inf,0},value= _NUM:10
		Variable td= 10,newTd
		Variable t0= ticks
		Do
			newTd= autoAbortSecs - round((ticks-t0)/60)
			if( td != newTd )
				td= newTd
				SetVariable sv0,value= _NUM:newTd,win=tmp_PauseforCursor
				if( td <= 10 )
					SetVariable sv0,valueColor= (65535,0,0),win=tmp_PauseforCursor
				endif
			endif
			if( td <= 0 )
				DoWindow/K tmp_PauseforCursor
				didAbort= 1
				break
			endif
				
			PauseForUser/C tmp_PauseforCursor,$graphName
		while(V_flag)
	endif
	return didAbort
End

STATIC Function SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Static Function ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			StartXandY()
			ResetSettingsWave()
			StartCalibrate()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Window DE_Calibrate() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel/N=DE_Calibrate /W=(150,77,450,277)
	DE_Calibrate#InitializeSettings()
	SetVariable DE_Calibrate_AppVel,pos={1,2},size={172,16},proc=DE_Calibrate#SetVarProc,title="Approach Velocity (µm/s)"
	SetVariable DE_Calibrate_AppVel,value= root:DE_Calibrate:CalibrateSettings[%ApproachSpeed]
	SetVariable DE_Calibrate_RetVel,pos={1,25},size={172,16},proc=DE_Calibrate#SetVarProc,title="Retract Velocity (µm/s)"
	SetVariable DE_Calibrate_RetVel,value= root:DE_Calibrate:CalibrateSettings[%RetractSpeed]
	SetVariable DE_Calibrate_SurfForce,pos={1,50},size={172,16},proc=DE_Calibrate#SetVarProc,title="Surface Force (pN)"
	SetVariable DE_Calibrate_SurfForce,value= root:DE_Calibrate:CalibrateSettings[%SurfaceForce]
	SetVariable DE_Calibrate_SurfDwell,pos={1,75},size={172,16},proc=DE_Calibrate#SetVarProc,title="Surface Dwell (s)"
	SetVariable DE_Calibrate_SurfDwell,value= root:DE_Calibrate:CalibrateSettings[%SurfDwell]
	SetVariable DE_Calibrate_SampRate,pos={1,100},size={172,16},proc=DE_Calibrate#SetVarProc,title="Sample Rate (kHz)"
	SetVariable DE_Calibrate_SampRate,value= root:DE_Calibrate:CalibrateSettings[%SampleRate]
	SetVariable DE_Calibrate_TotalSpots,pos={1,125},size={172,16},proc=DE_Calibrate#SetVarProc,title="TotalSpots"
	SetVariable DE_Calibrate_TotalSpots,value= root:DE_Calibrate:CalibrateSettings[%TotalSpots]
	SetVariable DE_Calibrate_StepSize,pos={1,150},size={172,16},proc=DE_Calibrate#SetVarProc,title="Step Size (µm)"
	SetVariable DE_Calibrate_StepSize,value= root:DE_Calibrate:CalibrateSettings[%StepSize]
	SetVariable DE_Calibrate_StepSize,pos={1,150},size={172,16},proc=DE_Calibrate#SetVarProc,title="Step Size (µm)"
	SetVariable DE_Calibrate_StepSize,value= root:DE_Calibrate:CalibrateSettings[%StepSize]
	Button DE_Calibrate_StartButt title="Start Calibrating",pos={1,175},size={172,16},proc=DE_Calibrate#ButtonProc
EndMacro


Menu "Calibration"
	"initialize",DE_Calibrate()
end

#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma modulename=DE_Calibrate

Static Function Initialize()

	NewDataFolder/O root:DE_Calibrate
	NewDataFolder/O root:DE_Calibrate:Current

	make/T/o/n=12 root:DE_Calibrate:CalibrateSettings
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


	Settings={"0.4","0.2","0.4","500","25","50","5","500","DE_Calibrate#Done()","0","0","0"}
	
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
	variable/C Positions=FindMaxandMin()
	Settings[%MaxPosition]=num2str(real(positions))
	Settings[%MinPosition]=num2str(imag(positions))

	if(str2num(Settings[%CurrentSpot])!=0)
		//SelectInvolRegion()
	else
		//CalculateInvols()
	endif


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

	print "This worked you fat fuck"
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
			Results[%Invols][dimsize(Results,1)-1]=MVW[%InvOLS][%value]
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


//function ThermalOpParmFunc(ctrlName,checked)
//	string ctrlName
//	variable checked
//	wave PanelParms = root:Packages:MFP3D:Main:Windows:ThermalOpParmPanelParms
//	ctrlName = ctrlName[0,strsearch(ctrlName,"CheckBox",0)-1]
//	PanelParms[%$ctrlName][0] = checked
//	GhostThermalOpParmPanel(0)
//	SafePVByLabel(PanelParms,0,"IsDefault")
//end //ThermalOpParmFunc


Static Function/C FindMaxandMin()
	Wave/T Settings=root:DE_Calibrate:CalibrateSettings
	wave ZWave=root:DE_Calibrate:ZSensor_Calibrate
	wave DEfWave=root:DE_Calibrate:DefV_Calibrate 
	variable RetractSpeed
	RetractSpeed = str2num(Settings[%RetractSpeed][0])*1e-6//set the approach speed by converting from um/s to V/s. Note this is positive to approach the surface.
	variable waveLength=700e-9
	variable cutpntLength=700e-9/RetractSpeed/dimdelta(ZWave,0)
	  
//	duplicate/o/r=[numpnts(ZWave)-1-cutpntLength,] ZWave root:DE_Calibrate:ZSensor_Cut
//	duplicate/o/r=[numpnts(DEfWave)-1-cutpntLength,] DEfWave root:DE_Calibrate:DefV_Cut
//	wave	WDef_fit=root:DE_Calibrate:DefV_Cut
//	wave	WZsen_fit=root:DE_Calibrate:ZSensor_Cut

	duplicate/free/r=[numpnts(ZWave)-1-cutpntLength,] ZWave WZsen_fit
	duplicate/free/r=[numpnts(DEfWave)-1-cutpntLength,] DEfWave WDef_fit

	//variable LVDTSens=GV("ZLVDTSEns")
	//WZsen_fit*=LVDTSens

	Make/D/N=6/O W_coef
	W_coef[0] = {(WDef_fit[0]),-00e-9,10e-3,30,0,0}
	//W_coef[0] = {-1.2074e-006,0.32438,-6.2937e-008,2.9686e+007,2.995,0.020003}
	//FuncFit/Q/NTHR=0 linearsin2 W_coef  WDef_fit[rstar,rend] /X=WZsen_fit/R=$ResName
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
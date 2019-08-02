#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#pragma ModuleName = DE_MultiCTFC	

Static function Start()

	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	wave DefVolts_Fast=DEfv_fast
	wave ZsensorVolts_Fast=Zsensor_fast
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	wave/t RefoldSettings
	variable rep,PVol,zerovolt
	
	variable MultiCTFCEngage=DE_CheckRamp("Do You Want to Sweep About?","Sweep")
	
	if(MultiCTFCEngage==2)
		ir_StopPISloop(5)
		DE_UpdatePlot("No Trigger")
		rep=DE_RepCheck()
		DE_RamptoVol(PVol,"Start","DE_CB_NoMol(\\\"TFE\\\","+num2str(rep)+")")
	else
		DE_FastPair(TriggerInfo,RepeatInfo,RampInfo,DefVolts_Fast,ZsensorVolts_Fast)//Saves the data from the fast (initial) pull here.

		RefoldSettings[%SurfaceLocation]=num2str(real(DE_AverageChan(0,"Arc.Input.A")))
		InitandRamp()
		
	endif
	return -1

	


end//DE_MultiCTFC_Start

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Static function InitandRamp()
	wave/t RefoldSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	wave DefVolts_Fast=DEfV_fast
	wave ZsensorVolts_Fast=Zsensor_fast
	Struct ARFeedbackStruct FB

	variable error	
	Error += td_WS("Event.7","Clear")	
	Error += td_WS("Event.8","Clear")	
	Error += td_WS("Event.9","Clear")	
	Error += td_WS("Event.10","Clear")	
	Error += td_WS("Event.11","Clear")	
	Error += td_WS("Event.12","Clear")	
	
	//variable zerovolt,runFast,DataLength,tot2,outdecirate,returndistance,outdistance,decirate
	variable Holdoffdistance, HoldoffVoltage,outdistance,tot2,newrate,decirate,totaltime
	variable/c Results
	
	
	HoldoffDistance=str2num(RefoldSettings[%HoldoffDistance][0])*1e-9
	outdistance=str2num(RefoldSettings[%GuessDistance][0])*1e-9//This is hugely random guess of how far we have to move before the CTFC quits
	
	if(StringMatch(RefoldSettings[%RefineHoldoff][0],"Yes")==1)

		Results=	DE_MultiCTFC_Markers(HoldoffDistance,outdistance)
		HoldoffVoltage=real(Results)
		outdistance=(HoldoffVoltage-imag(Results))*GV("ZLVDTSENS")

	else
	endif

	decirate=round(50/str2num(RefoldSettings[%DataRate][0])	)
	newrate=50/decirate
	totaltime=(str2num(RefoldSettings[%ExtendedDwell][0])+str2num(RefoldSettings[%LowDwell][0])+.1+abs(outdistance)/str2num(RefoldSettings[%RetractSpeed][0])/1e-6+abs(outdistance)/str2num(RefoldSettings[%ApproachSpeed][0])/1e-6+2)
	tot2=newrate*1e3*totaltime
	make/o/n=(tot2) ZSensor_Slow,DefV_Slow,Slow_ArcY,Slow_ArcX
	IR_XSetInWavePair(1,"8","Cypher.Input.FastA",DefV_Slow,"Cypher.LVDT.Z",ZSensor_Slow,"", decirate)
	IR_XSetInWavePair(2,"8","Arc.Input.A",Slow_ArcY,"Cypher.LVDT.Z",Slow_ArcX,"",decirate)

	//	if(StringMatch(RefoldSettings[%UltraFast][0],"Yes")==1)		
	//		DataLength=5e6*str2num(RefoldSettings[%ExtendedDwell][0])
	//		td_WriteValue("Cypher.Capture.0.Rate", 2)
	//		td_WriteValue("Cypher.Capture.0.Length", DataLength)
	//		runFast=1
	//	else
	//		runFast=0
	//	endif

	//	if(cmpstr(RampInfo[%Detrend][0],"Yes")==0)//If we are detrending, we want to actually trigger off of this channel, so we'll also sample these guys
	
	//Here I should fuck with the filtering some.
	
	//Here I am handing over the z-stage PIDS to Bank=3 because I want 4 and 5 to be the dwell loops. I'd rather have avoided pulling one of the 3 main loops into the question, but I want to setup the two dwells before I can the CTFC
	//I could have it 
	ARGetFeedbackParms(FB,"Z")
	FB.Bank = 3
	FB.Setpoint = NaN
	FB.DynamicSetpoint = 1
	FB.LoopName = "RampLoop"
	FB.StartEvent = "7"
	FB.StopEvent = "9" //This stops when the CTFC is fired
	ir_WritePIDSloop(FB)
	ir_StopPISloop(5)//Quickly stop the FB on loop 5
	td_ws("Event.7","Once") //And start it on loop 3 so that we are at constant Z again


	DE_MultiCTFC#GrabCTFC()
	SetCTFCParms(RampInfo,RefoldSettings)//This sets up everything we need for the CTFC, including both the dwell FB loops

//	
//	variable outpoints= //here we calculate the number of points we need to ramp out to our starting location. Since this isn't that complicate, we'll just digitize at 1 kHz and go from there.
	make/n=0 CTFCRamptoHoldOff  //This is just a generic voltage ramp which we will do in the time 0.1 second, which here I am just choosing to be fast.
	variable ramptime=0.1
	
	RampAway(CTFCRamptoHoldOff,HoldoffVoltage,ramptime)  //All this does is make the output wave
	
	td_xSetOutWave(0,"8,8,20,9","$RampLoop.SetpointOffset",CTFCRamptoHoldOff,10)  //This is 100 data points at 1 kHz (i.e., 0.1s). Now using more complex triggering so that trigger 9 fires at the end.

	
	td_WS("Event.8","Once")		//Fires event.8, This starts our subsequent scan.
	//

end

Static Function GrabCTFC()

	Make/O/T root:DE_CTFC:MultiCTFC_TriggerSettings
	Variable error=0
	error+=td_ReadGroup("ARC.CTFC",root:DE_CTFC:MultiCTFC_TriggerSettings)
	return error

End //DE_GrabExistingCTFCparms()

Function SetCTFCParms(RampSettings,RefoldSettings)
	Wave/T RampSettings
	wave/t RefoldSettings
	wave ZsensorVolts_Fast=Zsensor_fast

	Variable OutTrigger,InTrigger, OutSpeed, RetractSpeed, NoTriggerTime,MaxZVolt,HoldoffVoltage,RetractVoltage
	String InTriggerChannel,OutTriggerChannel,InTrigRel,OutTrigRel,RampChannel
	Wave/T TriggerInfo=root:DE_CTFC:MultiCTFC_TriggerSettings
	String ErrorStr = ""
	

	HoldoffVoltage=ZsensorVolts_Fast[pcsr(A,"DE_CTFC_Control#MostRecent")]
	RetractVoltage=ZsensorVolts_Fast[pcsr(B,"DE_CTFC_Control#MostRecent")]
	
	RampChannel =  "Output.Z"//We are going to be moving the Z voltage around
	OutTriggerChannel="Arc.Input.A" //This triggers us on the detrended force channel.
	OutTrigger = -1*str2num(RefoldSettings[%ForceTrigger][0])*1e-12/GV("InvOLS")/GV("SpringConstant")+(real(DE_AverageChan(0,"Arc.Input.A"))) //This sets the voltage trigger to the force point offset by our current deflection signal...VOLTS!
	//OutTrigger = -1*str2num(RefoldSettings[%ForceTrigger][0])*1e-12/GV("InvOLS")/GV("SpringConstant")+str2num(RefoldSettings[%SurfaceLocation])
	OutTrigRel="Absolute" //Sets the approach trigger to be relative to the start of the scan.
print real(DE_AverageChan(0,"Arc.Input.A"))
	OutSpeed = -str2num(RefoldSettings[%RetractSpeed][0])*1e-6/GV("ZPiezoSens") //set the approach speed by converting from um/s to V/s. Note this is negative to flee the surface
	
	
	InTriggerChannel="ZSensor" //sets the second trigger channel.
	InTrigger=HoldoffVoltage //We will start by ramping Back to the no trigger point. In the future we can add a deflection trigger instead.
	InTrigRel="Absolute" //Sets the approach trigger to be relative to nothing since we are by hand pluggin in a specific number

	RetractSpeed = 1*str2num(RefoldSettings[%ApproachSpeed][0])*1e-6/GV("ZPiezoSens") //set the retract speed by converting from um/s to V/s. Note this is positive to approach the surface

	//NoTriggerTime= (td_rv("ZSensor")-HoldoffVoltage)*GV("ZLVDTSENS")/(RetractSpeed*1e-6)
	NoTriggerTime=0 ///We don't need a no trigger time.

	TriggerInfo[%TriggerChannel2] = InTriggerChannel
	TriggerInfo[%RampChannel] = RampChannel
	TriggerInfo[%RampOffset1] =num2str(-400e-9/GV("ZPiezoSens")) //Max Z Piezo (in volts) on initial push
	TriggerInfo[%RampSlope1] = num2str(OutSpeed)  //Z Piezo Volts/s
	//TriggerInfo[%RampOffset2] = RefoldSettings[%SurfaceLocation] //Max Z Piezo (in volts) on initial retraction.This retracts to the initial starting point. 
	//TriggerInfo[%RampOffset2] = num2str(50e-9/GV("ZPiezoSens")) //Max Z Piezo (in volts) on initial retraction.This retracts to the initial starting point. 
	TriggerInfo[%RampOffset2] = num2str(Nan) //This just means the loop will, at most, return to its starting position. This is a good, safe way to avoid the surface! However, my fear is that the dwell won' trigger if it hits this.
	TriggerInfo[%RampSlope2] = num2str(RetractSpeed) //Z Piezo Volts/s
	TriggerInfo[%TriggerChannel1] = OutTriggerChannel
	TriggerInfo[%TriggerValue1] = num2str(OutTrigger) //Deflection Volts
	TriggerInfo[%TriggerCompare1] = "<="
	//	
	TriggerInfo[%TriggerValue2] = num2str(InTrigger) 
	TriggerInfo[%TriggerCompare2] = ">="
	//TriggerInfo[%TriggerHoldoff2] = num2str(NoTriggerTime)
	TriggerInfo[%TriggerHoldoff2] = num2str(0)
	TriggerInfo[%DwellTime1] = Refoldsettings[%ExtendedDwell][0]
	TriggerInfo[%DwellTime2] = Refoldsettings[%LowDwell][0]
	TriggerInfo[%EventDwell] = "10,12"
	TriggerInfo[%EventRamp] = "9,11"
	TriggerInfo[%EventEnable] = "8"
	TriggerInfo[%CallBack] = "DE_MultiCTFC_CB()"
	TriggerInfo[%TriggerType1] = OutTrigRel
	TriggerInfo[%TriggerType2] = InTrigRel


	//	

	ErrorStr += num2str(td_writeGroup("ARC.CTFC",TriggerInfo))+","
	//	//This sets up an extension feedback servo to engage only during the surface pause (i.e. between the firing of event 4 and event 5). This is setup on channel 4 of the PID loop

	Struct ARFeedbackStruct FB

	ARGetFeedbackParms(FB,"Z")
	FB.Bank = 4
	FB.Setpoint = NaN
	FB.DynamicSetpoint = 1
	FB.LoopName = "DwellLoop"
	FB.StartEvent = "10"
	FB.StopEvent = "11"
	ErrorStr += ir_WritePIDSloop(FB)
	ir_WritePIDSloop(FB)
	
	ARGetFeedbackParms(FB,"Z")
	FB.Bank = 5
	FB.Setpoint = NaN
	FB.DynamicSetpoint = 1
	FB.LoopName = "DwellLoop2"
	FB.StartEvent = "6"
	FB.StopEvent = "Never"
	ErrorStr += ir_WritePIDSloop(FB)	

	//ir_StopPISloop(5)//Quickly stop the FB BEFORE writing the new parameters
	//	If (Error > 0)
	//		print "Error in StartMyCTFC"
	//	Endif


	//	//This writes the CTFC parameters

End //LoadCTFCparms

//This is called following the ramp! However, the interesting things are happening on both ends (unlike during a surface touchoff)
Function DE_MultiCTFC_CB()
	String ErrorStr = ""
	variable adding, zerovolt,PVol
	Wave/T TriggerInfo=root:DE_CTFC:MultiCTFC_TriggerSettings
	wave ZSensorVolts_slow=Zsensor_slow
	wave DefVolts_slow=DEfv_slow
	Wave/T  OrigTriggerInfo=root:DE_CTFC:TriggerSettings
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RefoldInfo=root:DE_CTFC:RefoldSettings
	wave Zsensor_fast
	wave/t RampInfo
	wave/t RampSettings
	wave/t Command=root:DE_CTFC:MenuStuff:ListComwave

	td_ReadGroup("ARC.CTFC",TriggerInfo) //Pulls in the most recent CTFC parameters.
	variable rep
	zerovolt=(Zsensor_fast(str2num(OrigTriggerInfo[%TriggerTime1]))-str2num(RampSettings[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
	PVol=Zerovolt-str2num(RampSettings[%StartDistance][0])*1e-9/GV("ZLVDTSEns")

	// Check to see if molecule is attached.  If Triggertime1 is greater than 400,000,then we did not trigger before we ran out of range, which should lead us to
	//ramp right back to our start. At this point we basically want to restart.
	if (str2num(TriggerInfo[%TriggerTime1])> 400000)
		td_stopinwavebank(1)
		td_stopinwavebank(2)
		DE_UpdatePlot("No Trigger")
		Command="Lost Attachment or failed to trigger."
		ir_StopPISloop(5)
		rep=DE_RepCheck()
		DE_RamptoVol(PVol,"Start","DE_CB_NoMol(\\\"TFE\\\","+num2str(rep)+")")
	else
		Command="Hey Stupid, it didn't fall off"
		td_stopinwavebank(1)
		td_stopinwavebank(2)
		DE_UpdatePlot("Triggered Done")
		ir_StopPISloop(5)
		rep=DE_RepCheck()
		CTFCSave(RefoldInfo,TriggerInfo,DefVolts_Slow,ZsensorVolts_Slow)
		DE_RamptoVol(PVol,"Start","DE_CB_NoMol(\\\"TFE\\\","+num2str(rep)+")")

	endif
				
End //DE_CTFCCB_FE_Halt




function/C DE_MultiCTFC_Markers(HoldOffDistance,GuessDistance)
	variable HoldOffDistance,GuessDistance
	
	wave/t RefoldSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave ZsensorVolts_Fast=Zsensor_fast

	variable zerovolt,startmultivolt,endmultivolt,GuessVoltage,HoldoffVoltage
	zerovolt=(ZsensorVolts_Fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))

	HoldoffVoltage=Zerovolt-HoldOffDistance/GV("ZLVDTSEns")
	GuessVoltage=HoldoffVoltage-GuessDistance/GV("ZLVDTSEns")

	FindLevel/p/q ZsensorVolts_Fast,HoldoffVoltage
	variable Holdoffpnt=v_Levelx
	
	FindLevel/p/q ZsensorVolts_Fast,GuessVoltage
	variable Guesspnt=v_Levelx
	
	Cursor/p/W=DE_CTFC_Control#MostRecent A  Display_DEFV_1  Holdoffpnt
	Cursor/p/W=DE_CTFC_Control#MostRecent B  Display_DEFV_1  Guesspnt

	DE_UserCursorAdjust("de_Ctfc_Control",0)
	HoldoffVoltage=ZsensorVolts_Fast[pcsr(A,"DE_CTFC_Control#MostRecent")]
	GuessVoltage=ZsensorVolts_Fast[pcsr(B,"DE_CTFC_Control#MostRecent")]

	return cmplx(HoldoffVoltage,GuessVoltage)
end


function DE_MakeMultiCTFC(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,Wpar,c0,c1,c2,c3,c4,c5,c6,c7)
	string a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,c0,c1,c2,c3,c4,c5,c6,c7
	wave/t Wpar
	NewDataFolder/o root:DE_CTFC
	NewDataFolder/o root:DE_CTFC:Saved
	SetDataFolder root:DE_CTFC
	make/n=1/o FCD
	Make/O/T/N=(14,3) RampSettings		//Primary CTFC ramp settings
	
	RampSettings[0][0]= {a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13}
	RampSettings[0][1]= {"Approach Velocity","Surface Trigger Channel","Surface Trigger","Surface Dwell Time","Retract Velocity","Molecule Trigger Channel","Molecule Trigger","Retract Dwell Time","No Trigger Distance","DE_CTFCCB_TFE","Sample Rate","Total Time","Start Distance","Detrend"}
	RampSettings[0][2]= {"micron/s","Channel Name/Alias","pN","s","micron/s","Channel Name/Alias(No Trigger= output.Dummy)","pN","s","nm","Function to execute after ramp","kHz","s","nm","Yes/No"}
 	
	SetDimLabel 1,0,Values,RampSettings
	SetDimLabel 1,1,Desc,RampSettings
	SetDimLabel 1,2,Units,RampSettings

	SetDimLabel 0,0,ApproachVelocity,RampSettings
	SetDimLabel 0,1,SurfaceTriggerChannel,RampSettings
	SetDimLabel 0,2,SurfaceTrigger,RampSettings
	SetDimLabel 0,3,SurfaceDwellTime,RampSettings
	SetDimLabel 0,4,RetractVelocity,RampSettings
	SetDimLabel 0,5,MolecularTriggerChannel,RampSettings
	SetDimLabel 0,6,MolecularTrigger,RampSettings
	SetDimLabel 0,7,RetractDwellTime,RampSettings
	SetDimLabel 0,8,NoTriggerDistance,RampSettings
	SetDimLabel 0,9,CallBack,RampSettings
	SetDimLabel 0,10,SampleRate,RampSettings
	SetDimLabel 0,11,TotalTime,RampSettings
	SetDimLabel 0,12,StartDistance,RampSettings
	SetDimLabel 0,13,Detrend,RampSettings

	Make/O/T/N=(17,3) RefoldSettings		//Settings for ramp back to surface and final extension ramp.
	SetDimLabel 1,0,Values,RefoldSettings
	SetDimLabel 1,1,Desc,RefoldSettings
	SetDimLabel 1,2,Units,RefoldSettings

	SetDimLabel 0,0,ExperimentName,RefoldSettings
	SetDimLabel 0,1,ApproachDistance,RefoldSettings
	SetDimLabel 0,2,ApproachTime,RefoldSettings
	SetDimLabel 0,3,ApproachDelay,RefoldSettings
	SetDimLabel 0,4,RetractSpeed,RefoldSettings
	SetDimLabel 0,5,HoldoffDistance,RefoldSettings
	SetDimLabel 0,6,RefineHoldoff,RefoldSettings
	SetDimLabel 0,7,ForceTrigger,RefoldSettings
	SetDimLabel 0,8,ExtendedDwell,RefoldSettings
	SetDimLabel 0,9,ApproachSpeed,RefoldSettings
	SetDimLabel 0,10,GuessDistance,RefoldSettings
	SetDimLabel 0,11,LowDwell,RefoldSettings
	SetDimLabel 0,12,RetractIterations,RefoldSettings
	SetDimLabel 0,13,CurrentIteration,RefoldSettings
	SetDimLabel 0,14,SurfaceLocation,RefoldSettings

	SetDimLabel 0,15,Datarate,RefoldSettings
	SetDimLabel 0,16,UltraFast,RefoldSettings

	RefoldSettings[][0]= Wpar[p]
	RefoldSettings[0][1]= {"Experiment Name","Approach Distance","Approach Time","Approach Delay","Retract Speed","Holdoff Distance","Refine Holdoff","Force Trigger","Extension Pause","Return Speed","Guess Distance","Surface Dwell","Max Iterations","Current Iteration","Surface Pos","Data Rate","UltraFast Too?"}
	RefoldSettings[0][2]= {"","nm","s","s","nm","s","s","","kHz","Yes/No"}	
	

	Make/O/T/N=(8,3) RepeatSettings			//These are the instructions that are passed forward for repeating the experiment	
	RepeatSettings[0][0]= {c0,c1,c2,c3,c4,c5,c6,c7}
	RepeatSettings[0][1]= {"Want to Repeat","X Pnts","Y Pnts","Scan Size","Total Spots","Total Loops","Current Loops","Current Spot"}
	RepeatSettings[0][2]= {"Yes/No","Integer","Integer","um","Integer","Integer","Integer","Integer"}
	
	SetDimLabel 1,0,Values,RepeatSettings
	SetDimLabel 1,1,Desc,RepeatSettings
	SetDimLabel 1,2,Units,RepeatSettings

	SetDimLabel 0,0,Repeat,RepeatSettings
	SetDimLabel 0,1,XPnts,RepeatSettings
	SetDimLabel 0,2,YPnts,RepeatSettings
	SetDimLabel 0,3,ScanSize,RepeatSettings
	SetDimLabel 0,4,TotalSpots,RepeatSettings

	SetDimLabel 0,5,TotalLoops,RepeatSettings
	SetDimLabel 0,6,CurrentLoops,RepeatSettings
	SetDimLabel 0,7,CurrentSpot,RepeatSettings

	if(cmpstr(RepeatSettings[0][0],"Yes")==0)   //Checks if we want to repeat at all
	
		RepeatSettings[4][0]=num2str(str2num(RepeatSettings[1][0])*str2num(RepeatSettings[2][0]))    //How many total spots do we want? (x-spots * y-spots)
		
		
		if(str2num(RepeatSettings[4][0])==1) //If we only want one spot, then we do nothing
											
		else
		
			pv("Scansize",str2num(RepeatSettings[3][0])*1e-6)	//sets the scan size
			SpotGrid(str2num(RepeatSettings[1][0]),str2num(RepeatSettings[2][0]))  //sets up the spot grids
			pv("ForceSpotNumber",0)  //start at spot 0
			GoToSpot()   //Go to the spot. This assumes there will be plenty of time to reach this point in the intervening keystrokes etc.
		
		endif
	
	else
		
	endif
	
end


function CTFCSave(RefoldInfo,TriggerInfo,DefVolts_Slow,ZsensorVolts_Slow)
	Wave/T RefoldInfo,TriggerInfo
	
	Wave DefVolts_Slow, ZsensorVolts_Slow
	wave ZsensorVolts_Fast

	wave MVW = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	string suffixStr = num2strlen(MVW[%BaseSuffix][0],4)
	string AddComm="" 
	variable Index, ApproachDistance, ApproachTime, ApproachVelocity,ApproachDelay,sampleRate,TimetoStart
	variable RetractSpeed,HoldoffDistance,HoldoffVoltage,RetractVoltage,ForceTrigger,ExtendedDwell,	ApproachSpeed, GuessDistance, LowDwell, RetractIterations,	CurrentIteration, SurfaceLocation,	decirate

	variable TriggerSetVolt1=str2num(TriggerInfo[%TriggerValue1])
	variable TriggerSetVolt2=str2num(TriggerInfo[%TriggerValue2])	
	variable TriggerValue1=str2num(TriggerInfo[%TriggerPoint1])
	variable TriggerValue2=str2num(TriggerInfo[%TriggerPoint2])
	variable TriggerTime1=str2num(TriggerInfo[%TriggerTime1])
	variable TriggerTime2=str2num(TriggerInfo[%TriggerTime2])
	variable DwellTime1=str2num(TriggerInfo[%DwellTime1])
	variable DwellTime2=str2num(TriggerInfo[%DwellTime2])
	variable NoTrigTime=str2num(TriggerInfo[%TriggerHoldoff2 ]) 
	
	ApproachDistance=str2num(RefoldInfo[%ApproachDistance][0])  
	ApproachTime=str2num(RefoldInfo[%ApproachTime][0])
	ApproachVelocity=ApproachDistance/ApproachTime*1e-3
	ApproachDelay=str2num(RefoldInfo[%ApproachDelay][0])
	RetractSpeed=str2num(RefoldInfo[%RetractSpeed][0])  
	HoldoffDistance=str2num(RefoldInfo[%HoldoffDistance][0])  
	HoldoffVoltage=ZsensorVolts_Fast[pcsr(A,"DE_CTFC_Control#MostRecent")]
	RetractVoltage=ZsensorVolts_Fast[pcsr(B,"DE_CTFC_Control#MostRecent")]
	ForceTrigger=str2num(RefoldInfo[%ForceTrigger][0])  
	ExtendedDwell=str2num(RefoldInfo[%ExtendedDwell][0])  
	ApproachSpeed=str2num(RefoldInfo[%ApproachSpeed][0])  
	GuessDistance=str2num(RefoldInfo[%GuessDistance][0])  
	LowDwell=str2num(RefoldInfo[%LowDwell][0])  
	RetractIterations=str2num(RefoldInfo[%RetractIterations][0])  
	CurrentIteration=str2num(RefoldInfo[%CurrentIteration][0])  
	SurfaceLocation=str2num(RefoldInfo[%SurfaceLocation][0])  
	decirate=round (50/(str2num(RefoldInfo[%DataRate][0])))
	sampleRate=50/decirate*1e3
	TimetoStart=str2num(RefoldInfo[%TimeToStart][0])
	
	String Indexes = "0," //Start the index and directions 
	String Directions = "0,"


	variable dwellPoints0 = round(DwellTime1*sampleRate)   
	variable dwellpoints1=round(DwellTime2*sampleRate) 
	variable ramp2pts= round((TriggerTime2)*sampleRate)-1
	
	Index=round(TriggerTime1*sampleRate)-1      //Counts out to one point less than where it triggered
	Indexes += num2istr(Index)+","
	Directions += num2str(1)+","
	
	if (DwellPoints0)
		//
		Index += DwellPoints0
		Indexes += num2istr(Index)+","
		Directions += "0,"
		//	
	endif
	//	
	Index += ramp2pts
	Indexes += num2istr(Index)+","
	Directions += num2str(-1)+","

	//	//This just lists the rest of the wave (from where the trigger fired through to the end of the wave) as the dwell. This should contain the total official dwell
	//pluis a touch of overhead before we kill the collection.

	Index=dimsize(DefVolts_Slow,0)
	Indexes += num2istr(Index)+","
	Directions += "0,"

	AddComm = ReplaceStringbyKey("Indexes",AddComm,Indexes,":","\r")
	AddComm = ReplaceStringbyKey("Direction",AddComm,Directions,":","\r")
	AddComm = ReplaceStringbyKey("ApproachVelocity",AddComm,num2str(ApproachVelocity),":","\r")
	AddComm = ReplaceStringbyKey("ApproachDistance",AddComm,num2str(ApproachDistance),":","\r")
	AddComm = ReplaceStringbyKey("DwellTime",AddComm,num2str(ApproachDelay),":","\r")
	
	
	AddComm = ReplaceStringbyKey("TriggerSetVolt1",AddComm,num2str(TriggerSetVolt1),":","\r")
	AddComm = ReplaceStringbyKey("TriggerSetVolt2",AddComm,num2str(TriggerSetVolt2),":","\r")
	AddComm = ReplaceStringbyKey("TriggerValue1",AddComm,num2str(TriggerValue1),":","\r")
	AddComm = ReplaceStringbyKey("TriggerValue2",AddComm,num2str(TriggerValue2),":","\r")
	AddComm = ReplaceStringbyKey("TriggerTime1",AddComm,num2str(TriggerTime1),":","\r")
	AddComm = ReplaceStringbyKey("TriggerTime2",AddComm,num2str(TriggerTime2),":","\r")
	AddComm = ReplaceStringbyKey("DwellTime1",AddComm,num2str(DwellTime1),":","\r")
	AddComm = ReplaceStringbyKey("DwellTime2",AddComm,num2str(DwellTime2),":","\r")
	AddComm = ReplaceStringbyKey("NoTrigTime",AddComm,num2str(NoTrigTime),":","\r")
	AddComm = ReplaceStringbyKey("DwellTime1",AddComm,num2str(DwellTime1),":","\r")
	AddComm = ReplaceStringbyKey("DwellTime1",AddComm,num2str(DwellTime1),":","\r")
	AddComm = ReplaceStringbyKey("DwellTime1",AddComm,num2str(DwellTime1),":","\r")
	AddComm = ReplaceStringbyKey("DwellTime1",AddComm,num2str(DwellTime1),":","\r")
	AddComm = ReplaceStringbyKey("DwellTime1",AddComm,num2str(DwellTime1),":","\r")

	AddComm = ReplaceStringbyKey("RetractSpeed",AddComm,num2str(RetractSpeed),":","\r")
	AddComm = ReplaceStringbyKey("HoldoffDistance",AddComm,num2str(HoldoffDistance),":","\r")
	AddComm = ReplaceStringbyKey("HoldoffVoltage",AddComm,num2str(HoldoffVoltage),":","\r")
	AddComm = ReplaceStringbyKey("RetractVoltage",AddComm,num2str(RetractVoltage),":","\r")
	AddComm = ReplaceStringbyKey("ForceTrigger",AddComm,num2str(ForceTrigger),":","\r")
	AddComm = ReplaceStringbyKey("ExtendedDwell",AddComm,num2str(ExtendedDwell),":","\r")
	AddComm = ReplaceStringbyKey("ApproachSpeed",AddComm,num2str(ApproachSpeed),":","\r")
	AddComm = ReplaceStringbyKey("GuessDistance",AddComm,num2str(GuessDistance),":","\r")
	AddComm = ReplaceStringbyKey("LowDwell",AddComm,num2str(LowDwell),":","\r")
	AddComm = ReplaceStringbyKey("RetractIterations",AddComm,num2str(RetractIterations),":","\r")
	AddComm = ReplaceStringbyKey("CurrentIteration",AddComm,num2str(CurrentIteration),":","\r")
	AddComm = ReplaceStringbyKey("SurfaceLocation",AddComm,num2str(SurfaceLocation),":","\r")
	AddComm = ReplaceStringbyKey("decirate",AddComm,num2str(decirate),":","\r")
	AddComm = ReplaceStringbyKey("sampleRate",AddComm,num2str(sampleRate),":","\r")
	
	AddComm = ReplaceStringbyKey("PullType",AddComm,"Step Out",":","\r")
	AddComm = ReplaceStringbyKey("ExperimentType",AddComm,"CTFC",":","\r")
	AddComm = ReplaceStringbyKey("Corresponding Fast Pull",AddComm,num2strlen(str2num(suffixStr)-1,4),":","\r")

	


	DE_SaveReg(DefVolts_slow,ZSensorVolts_slow,AdditionalNote=AddComm)
	
		
end	//DE_SlowPair


Function RampAway(CTFCRamptoHoldOff,HoldoffVoltage,ramptime)
	wave CTFCRamptoHoldOff
	variable HoldoffVoltage,ramptime
	
	variable CurrentVoltage=td_rv("ZSensor")
	variable OffsetVoltageTarget=HoldoffVoltage-td_rv("ZSensor")   //Because the voltage we pull off the trace isn't in offset, we offset it for us. However, we could also just go ahead and ramp the 
															//setpoint rather than the setpoint offset, but for some reason I suspect it may be more convenient to have 0 be the surface
	
	variable pnts=100	//.1 second at 1 kHz, should be fine since this is a straight line
	variable slope=OffsetVoltageTarget/99  //Volts per point
	make/o/n=(100) CTFCRamptoHoldOff	
	CTFCRamptoHoldOff=(slope)*p  //If we have to I can comeback to make this fastop 

End // RampAway()


//
//
//Function SetupDwellFB(SetPoint,[DeflectionOffset,RampSettings])
//	Variable SetPoint,DeflectionOffset
//	Wave RampSettings
//	Variable Error=0
//	Variable StartEvent,StopEvent
//	
//	
//	If(ParamIsDefault(DeflectionOffset))
//		DeflectionOffset=0
//	EndIf
//
//	// Set up the start and stop event for the feedback loop.  This is critical!
//	// Make sure this matches up with dwell start and stop in your CTFC settings
//	If(ParamIsDefault(RampSettings))
//		StartEvent=5
//		StopEvent=3
//	Else
//		StartEvent=RampSettings[%'Event Dwell']
//		StopEvent=RampSettings[%'Event Ramp']
//	EndIf
//	
//// Make a text wave and then just use td_RG to put all the info from one of the ARC // //feedback loops into this.  Much easier than making it from scratch
//Make/O/T PIDSLoopGroup
//	Error+=td_RG("ARC.PIDSLoop.0",PIDSLoopGroup)
//	
////Now fill in all the parameters for the feedback loop.  Setpoint is the deflection setpoint //in volts. Note: If you mess with the crosspoint, you may need to change inputchannel
//	PIDSLoopGroup[%Setpoint]=num2str(SetPoint)
//	PIDSLoopGroup[%SetpointOffset]=num2str(DeflectionOffset)
//	PIDSLoopGroup[%InputChannel]="Deflection"
//	PIDSLoopGroup[%OutputChannel]="Output.Z"
//	PIDSLoopGroup[%IGain]="3000"
//	PIDSLoopGroup[%StartEvent]=num2str(StartEvent)
//	PIDSLoopGroup[%StopEvent]=num2str(StopEvent)
//	PIDSLoopGroup[%OutputMin]="-10"
//	PIDSLoopGroup[%OutputMax]="150"
//	PIDSLoopGroup[%Status]="0"
//
//	// Now write this to feedback loop 2 on the ARC.  
//	Error+=td_WG("ARC.PIDSLoop.2",PIDSLoopGroup)
//	
//	If(Error>0)
//		Print "Error code in SetupDwellFB: "+ num2str(Error)
//	EndIf
//End

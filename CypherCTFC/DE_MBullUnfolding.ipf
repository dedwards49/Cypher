#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=DE_MBUllUnfolding


//Start() initializes the Unfolding protocol starting from the surface. It is called by DE_RampDownDone(). It first asks if
//you want to initialize the program. If you select no, then if ramps back and pretends that no molecule was found. If you say
//yes, record the current Zsensor value for later use, and then pass to InitandRamp
Static function Start()

	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	wave DefVolts_Fast=DEfv_fast
	wave ZsensorVolts_Fast=Zsensor_fast
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	wave/t RefoldSettings
	variable rep,PVol,zerovolt
		td_wv("Arc.Input.A.Filter.Freq",str2num(RefoldSettings[%DataRate][0])/50*1e3)

	variable MultiCTFCEngage=DE_CheckRamp("Do You Want to Sweep About?","Sweep") //Check if you wanna sweep
	
	if(MultiCTFCEngage==2)  //No sweeping?
		ir_StopPISloop(5)		//kill out PIDS zpiezo
		DE_UpdatePlot("No Trigger")	//Update the plot as if it didn't trigger
		rep=DE_RepCheck()		
		DE_RamptoVol(PVol,"Start","DE_CB_NoMol(\\\"TFE\\\","+num2str(rep)+")")
	else

		RefoldSettings[%SurfaceLocation]=num2str(td_rv("Zsensor"))  //Read the current stage position so we can come back at the end
		InitandRamp()   //Move on!
	
	endif
	return -1

end //Start

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//InitandRamp() does the work of preparing the CTFC for our second triggered force pull. First it clears events, then it first allows you to modify the holdoff location on the graph if you desire. 
//It then makes the inwaves for deflection and the smoothed (detrended) signal, and then the fast capture if necessary. We then make a new wave for this CTFC, and then fill that up with
//GrabCTFC() and  SetCTFCParms(RampInfo,RefoldSettings). We then turn everything off and start!
Static Function InitandRamp()

	wave/t RefoldSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	wave DefVolts_Fast=DEfV_fast
	wave ZsensorVolts_Fast=Zsensor_fast
	Struct ARFeedbackStruct FB

	variable error,runFast,DataLength
	Error += td_WS("Event.7","Clear")	
	Error += td_WS("Event.8","Clear")	
	Error += td_WS("Event.9","Clear")	
	Error += td_WS("Event.10","Clear")	
	Error += td_WS("Event.11","Clear")	
	Error += td_WS("Event.12","Clear")			//Cleanup
	
	variable Holdoffdistance, tot2,newrate,decirate,totaltime
	variable Results
		
	HoldoffDistance=str2num(RefoldSettings[%HoldoffDistance][0])*1e-9  //Defines the holdoff distance
	
	if(StringMatch(RefoldSettings[%RefineHoldoff][0],"Yes")==1)	//If you want to refine the holdoff position visually on the graph that happens here

		Results=DE_MBullUnfolding#Markers(HoldoffDistance)
		HoldoffDistance=(Results)

	else
	endif

	decirate=round(50/str2num(RefoldSettings[%DataRate][0])	)
	newrate=50/decirate
	totaltime=str2num(RefoldSettings[%RetractDwell][0])+2*HoldoffDistance/str2num(RefoldSettings[%RetractSpeed][0])/1e-6+.1//This is a guess of total time, assuming that we retract forless than this number
																													//this means the precise dwell time may be exceeded, but we don't really care			
	tot2=newrate*1e3*totaltime
	
	make/o/n=(tot2) ZSensor_Slow,DefV_Slow,Slow_ArcY,Slow_ArcX
	IR_XSetInWavePair(1,"8","Cypher.Input.FastA",DefV_Slow,"Cypher.LVDT.Z",ZSensor_Slow,"DE_MBullUnfolding#RampDown()", -decirate)
	IR_XSetInWavePair(2,"8","Arc.Input.A",Slow_ArcY,"Cypher.LVDT.Z",Slow_ArcX,"",-decirate)				//Setup both Arc.Input.A and Deflection reads.
	
	if(StringMatch(RefoldSettings[%UltraFast][0],"5 MHz")==1)			//Sorts out what High bandwidth measurement we wanna make and prepares them.
				
		DataLength=5e6*(totaltime)
		td_WriteValue("Cypher.Capture.0.Rate", 2)
		td_WriteValue("Cypher.Capture.0.Length", DataLength)
		runFast=1
	elseif(StringMatch(RefoldSettings[%UltraFast][0],"2 MHz")==1)
		runFast=2
		make/o/n=1 HBDefl,HBZsnsr
		SetupStream(1,(totaltime),HBDefl,HBZsnsr)

	elseif(StringMatch(RefoldSettings[%UltraFast][0],"500 kHz")==1)
		runFast=2
		make/o/n=1 HBDefl,HBZsnsr
		SetupStream(0,(totaltime),HBDefl,HBZsnsr)
	else
		runFast=0
	endif
		
	DE_MBullUnfolding#GrabCTFC()			//Initialize the CTFC wave
	DE_MBullUnfolding#SetCTFCParms(RampInfo,RefoldSettings)//This sets up everything we need for the CTFC, including both the dwell FB loop

	if(runFast==1)
		td_WriteValue("Cypher.Capture.0.Trigger", 1)
	elseif(runFast==2)
		td_ws("ARC.Events.once", "1")
		
	endif
	ir_StopPISloop(5)

	td_WS("Event.8","Once")		//Fires event.8, This starts our CTFC and the data collection. 

end //InitandRamp

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//GrabCTFC just makes a wave (root:DE_CTFC:MBullRefolding_TriggerSettings) that is populated with the existing CTFC stuff.
Static Function GrabCTFC()

	Make/O/T root:DE_CTFC:MBullRefolding_TriggerSettings
	Variable error=0
	error+=td_ReadGroup("ARC.CTFC",root:DE_CTFC:MBullRefolding_TriggerSettings)
	return error

End //DE_GrabExistingCTFCparms()

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//SetCTFCParms() goes through and populates the CTFC wave and uploads it. It then goes ahead and prepares a Zsensor feedback look on loop 4 to engage as soon as the CTFC triggers
Static Function SetCTFCParms(RampSettings,RefoldSettings)



	Wave/T RampSettings
	wave/t RefoldSettings
	string RampChannel,ApproachTriggerChannel,SurfaceTrigger,ApproachTrigRel,RetractTriggerChannel,RetractTrigRel
	variable ApproachSpeed,MoleculeTrigger,RetractSpeed,HoldoffDistance,NoTriggerTime
	wave ZsensorVolts_Fast=Zsensor_fast
	Wave/T TriggerInfo=root:DE_CTFC:MBullRefolding_TriggerSettings
	
	RampChannel =  "Output.Z"  //Just moving the stage
	ApproachTriggerChannel="Zsensor" //Our approach (toward the surface) will be super super short, this is basically a dummy so that we can use the holdoff.
	SurfaceTrigger=num2str(td_rv("Zsensor")*+1*1e-9/GV("ZLVDTSens")) //This forces our move to be 0.5 nm toward the surface, just to trick the CTFC into doing what I want.
	ApproachTrigRel="Relative Start" //Sets the approach trigger to be relative to the start of the scan.
	
	//SurfaceTrigger=td_rv("Zsensor")*+.5*1e-9/GV("ZLVDTSens") //This forces our move to be 0.5 nm toward the surface, just to trick the CTFC into doing what I want.
	//ApproachTrigRel="Absolute" //Sets the approach trigger to be relative to the start of the scan.
	
	ApproachSpeed = str2num(refoldsettings[%RetractSpeed][0])*1e-6/GV("ZPiezoSens") //set the approach speed by converting from um/s to V/s. Since the approach is so short, I just use the retract speed.
	RetractTriggerChannel="Arc.Input.A" //sets the second trigger channel.		
	MoleculeTrigger = -1*str2num(refoldsettings[%ForceTrigger][0])*1e-12/GV("InvOLS")/GV("SpringConstant") //Deflection to reach
	variable SDef=td_rv("arc.input.a")  //Right now I'm just using a td_rv, the smoothing read was giving anomalous results.


	MoleculeTrigger=SDef+MoleculeTrigger  //This manually offsets the trigger channel to be from the starting deflection.
	RetractTrigRel="Absolute" //Sets the approach trigger to be relative to the start of the whole CTFC (i.e. compare to the initial deflection). I would use relative, but it doesn't seem to work well.
	RetractSpeed = -1*str2num(refoldsettings[%RetractSpeed][0])*1e-6/GV("ZPiezoSens") //set the retract speed by converting from um/s to V/s. Note this is negative to retract from the surface.

	if(StringMatch(RefoldSettings[%RefineHoldoff][0],"Yes")==1)
		HoldoffDistance=(td_rv("Zsensor")-ZsensorVolts_Fast[pcsr(A,"DE_CTFC_Control#MostRecent")])*GV("ZLVDTSENS")
	else
		HoldoffDistance=str2num(RefoldSettings[%HoldoffDistance][0])*1e-9
	endif

	NoTriggerTime = -1*HoldoffDistance/(RetractSpeed*GV("ZPiezoSens"))+2e-3 //an estimate of how long to wait to avoid the vs X nm of distance in the curve. I.e., triggering starts after this time.

	//Let's start loading this all into our wave
	TriggerInfo[%TriggerChannel2] = "arc.input.A"//I am always triggering off of this input which is filtered down. Sometimes it is detrended, but if it isn't detrended, I just don't sample it (i.e., if all happens in the CTFC).
	TriggerInfo[%TriggerChannel2] = RetractTriggerChannel
	TriggerInfo[%RampChannel] = RampChannel
	//TriggerInfo[%RampOffset1] = num2str(td_rv("output.z")+.5) //Max Z Piezo (in volts) on initial push, I won't let it move more than 0.5V, which is aout 80nm...this shouldn't be an issue but is an emergency protection.
	TriggerInfo[%RampOffset1] = num2str(0.5) //Max Z Piezo (in volts) on initial push, I won't let it move more than 0.5V, which is aout 80nm...this shouldn't be an issue but is an emergency protection.
	TriggerInfo[%RampSlope1] = num2str(ApproachSpeed)  //Z Piezo Volts/s
	//TriggerInfo[%RampOffset2] =  num2str(td_rv("output.z")-3) //Max Z Piezo (in volts) on initial retraction.This retracts to the initial starting point. 
	TriggerInfo[%RampOffset2] =  num2str(-10) //Max change in Z Piezo (in volts) on initial retraction, this fixes us to about 300 nm, which is more than enough
	TriggerInfo[%RampSlope2] = num2str(RetractSpeed) //Z Piezo Volts/s
	TriggerInfo[%TriggerChannel1] = ApproachTriggerChannel
	TriggerInfo[%TriggerValue1] = SurfaceTrigger //Deflection Volts
	TriggerInfo[%TriggerCompare1] = ">="
	TriggerInfo[%TriggerValue2] = num2str(MoleculeTrigger) 
	TriggerInfo[%TriggerCompare2] = "<="
	TriggerInfo[%TriggerHoldoff2] = num2str(NoTriggerTime)
	TriggerInfo[%DwellTime1] =num2str(1e-2) //No dwell at the surface, please
	//TriggerInfo[%DwellTime2] = refoldsettings[%RetractDwell][0]
	TriggerInfo[%DwellTime2] = num2str(1e-6)  //Here we are NOT gonna have the CTFC know about the pause, but because we engaged the feedback look on a successful trigger, we will be fine.
	TriggerInfo[%EventDwell] = "10,12"
	TriggerInfo[%EventRamp] = "9,11"
	TriggerInfo[%EventEnable] = "8" //Start this with "8"
	TriggerInfo[%CallBack] = "DE_MBullUnfolding#CallBack()"
	TriggerInfo[%TriggerType1] = ApproachTrigRel
	TriggerInfo[%TriggerType2] =RetractTrigRel


	td_writeGroup("ARC.CTFC",TriggerInfo)//Make it so

	//This sets up an extension feedback servo to engage during the final pause, it is one FB.Bank 4 because we're currently holding the position with 5, and I don't want to overwrite that.
	Struct ARFeedbackStruct FB
	ARGetFeedbackParms(FB,"Z")
	FB.Bank = 4
	FB.Setpoint = NaN
	FB.DynamicSetpoint = 1
	FB.LoopName = "DwellLoop"
	FB.StartEvent = "12"
	FB.StopEvent = "Never"
	ir_WritePIDSloop(FB)

End //LoadCTFCparms

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//UnfoldingDone() is called following the end of the data collection (td_setinwavepairx). It will always be called, unless the CTFC fails to trigger on the withdraw. Then the td_setinwave gets 
//killed in that callback. If this is firing even without triggering of the CTFC, it probably means the read delay is too short. All this does is to save the Fast and Slow
// The end of this ramp is a call to RampDown(), or to FastDone() via ReadHighBandwidth().
Static Function UnfoldingDone()
	
	Wave/T RefoldInfo=root:DE_CTFC:RefoldSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	wave DefVolts_Fast=DEfv_fast
	wave ZsensorVolts_Fast=Zsensor_fast
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	wave DefV_Slow, Zsensor_Slow
	variable ReadFast
	
	DE_FastPair(TriggerInfo,RepeatInfo,RampInfo,DefVolts_Fast,ZsensorVolts_Fast)//Saves the data from the fast (initial) pull here. Not earlier because if we drop the molecule, we don't care.
	SlowSave(RefoldInfo,DefV_Slow, Zsensor_Slow)//Saves the Slow pull.
	
	
	//This is our standard check for highbandwidth data
	if(StringMatch(RefoldInfo[%UltraFast][0],"No")!=1)	//Did we want highbandwidth?
		
		display/N=Test DefV_Slow
		ReadFast=DE_CheckFast("Access 5 MHz","5 MHz Check")   //Show the data and ask if we really want it
		killwindow Test
			
		if(ReadFast!=4)
			ReadHighBandwidth(ReadFast)
						
		else
			FinalPull()
		endif
			
	else
		FinalPull()
	endif
	
end //UnfoldingDone

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// RampDown() simply remembers where the surface is from the RefoldSettings wave and then ramps us there. It then calls to FinalPull()

Static Function RampDown()
	Wave/T RefoldInfo=root:DE_CTFC:RefoldSettings

	variable newpoint=str2num(RefoldInfo[%SurfaceLocation][0])
	td_SetRamp(str2num(RefoldInfo[%ApproachTime][0]), "PIDSLoop.4.Setpoint", 0, newpoint, "", 0, 0, "", 0, 0, "DE_MBullUnfolding#UnfoldingDone()")  //This should ramp is back to the surface on PIDSLoop.4 thanks to having recorded the surface before
end//RampDown()


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//FinalPull() initializes the final extension pull, which is just a ramp of PIDloop 4 setpoint offset. At the end, this ramp calls Done()
Static Function FinalPull()
	wave customwave2
	wave ZSensor_Final
	wave DefV_Final 
	wave/t RefoldSettings
	
	variable outdecirate=DE_Outdecirate("MBullUnfoldingFinal")
	IR_xSetOutWave(2,"15","PIDSLoop.4.SetpointOffset",CustomWave2,"DE_MBullUnfolding#Done()",outdecirate)
	IR_XSetInWavePair(1,"15","Deflection",DefV_Final,"Cypher.LVDT.Z",ZSensor_Final,"",-50/str2num(RefoldSettings[%DataRate][0]))
	td_ws("Event.15","once")//Fires the ramp away from the surface.
end

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Done() wraps everything up. It saves the final pull. Then kills the PISLoop, updates the graph and then initiates the next pull. 
Static Function Done()
	wave/t RefoldSettings
	wave DefVolts_Final=Defv_Final
	wave ZsensorVolts_Final=Zsensor_Final
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave ZsensorVolts_Fast=Zsensor_fast
	variable zerovolt,pvol,rep
	
	FinalSave(RefoldSettings,DefVolts_Final,ZsensorVolts_Final)  //Save final pull
	

	ir_StopPISloop(4)  //Halt the feedback loop.
	zerovolt=(ZSensorVolts_fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[2][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
	PVol=Zerovolt-str2num(RampInfo[%StartDistance][0])*1e-9/GV("ZLVDTSEns")  
	DE_UpdatePlot("Triggered Done")
	rep=DE_RepCheck()
	DE_RamptoVol(PVol,"Start","DE_CB_NoMol(\\\"TFE\\\","+num2str(rep)+")")   //Basically sends us through loop repeater.
end

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//FastReadDone is what gets called when we do the fastcapture data. Right now it does NOTHING except throw us to RampDown(). However, I wrote it this
//way to allow future changes.
Static Function FastDone()

	FinalPull()

end

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Callback() this is what gets called back when the CTFC  finishes. If it detects something, then this program does nothing as the triggering of the 2nd pull just 
//activates the feedback loop. However, if there is no trigger, this kills the wavereads and immediately restarts the scan.
Static function Callback()
	variable zerovolt,PVol,rep
	Wave/T TriggerInfo=root:DE_CTFC:MBullRefolding_TriggerSettings
	wave Zsensor_fast
	Wave/T  OrigTriggerInfo=root:DE_CTFC:TriggerSettings
	wave/t RampSettings
	wave/t Command=root:DE_CTFC:MenuStuff:ListComwave


	td_ReadGroup("ARC.CTFC",TriggerInfo) //Pulls in the most recent CTFC parameters.

	// Check to see if molecule is attached.  If Triggertime2 is greater than 400,000,then we did not trigger before we ran out of range, which should lead us to
	//ramp right back to our start. At this point we basically want to restart.
	if (str2num(TriggerInfo[%TriggerTime2])> 400000)
		zerovolt=(Zsensor_fast(str2num(OrigTriggerInfo[%TriggerTime1]))-str2num(RampSettings[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
		PVol=Zerovolt-str2num(RampSettings[%StartDistance][0])*1e-9/GV("ZLVDTSEns")

		td_stopinwavebank(1)
		td_stopinwavebank(2)
		DE_UpdatePlot("No Trigger")
		Command="Lost Attachment or failed to trigger."
		ir_StopPISloop(5)
		rep=DE_RepCheck()
		DE_RamptoVol(PVol,"Start","DE_CB_NoMol(\\\"TFE\\\","+num2str(rep)+")")
	else
		Command="Hey Stupid, it didn't fall off"


	endif
				
end

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Markers generates the markers to adjust the location of the holdoff location.
Static function Markers(HoldOffDistance)
	variable HoldOffDistance
	
	wave/t RefoldSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave ZsensorVolts_Fast=Zsensor_fast
	
	variable zerovolt,HoldoffVoltage
//
//	variable zerovolt,startmultivolt,endmultivolt,GuessVoltage,HoldoffVoltage
	zerovolt=(ZsensorVolts_Fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
	HoldoffVoltage=Zerovolt-HoldOffDistance/GV("ZLVDTSEns")
	

	FindLevel/p/q ZsensorVolts_Fast,HoldoffVoltage
	variable Holdoffpnt=v_Levelx
	Cursor/p/W=DE_CTFC_Control#MostRecent A  Display_DEFV_1  Holdoffpnt

	DE_UserCursorAdjust("de_Ctfc_Control",0)
	HoldoffVoltage=ZsensorVolts_Fast[pcsr(A,"DE_CTFC_Control#MostRecent")]

	return (td_rv("Zsensor")-HoldoffVoltage)*GV("ZLVDTSens") //Returns the distance to travel from the current location
end

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//MakeWaves populates the RampSettings, RefoldSettings, and RepeatSetting waves with parameters from the panel.
Static function MakeWaves(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,Wpar,c0,c1,c2,c3,c4,c5,c6,c7)
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

	Make/O/T/N=(14,3) RefoldSettings		//Settings for ramp back to surface and final extension ramp.
	SetDimLabel 1,0,Values,RefoldSettings
	SetDimLabel 1,1,Desc,RefoldSettings
	SetDimLabel 1,2,Units,RefoldSettings

	SetDimLabel 0,0,ExperimentName,RefoldSettings
	SetDimLabel 0,1,ApproachDistance,RefoldSettings
	SetDimLabel 0,2,ApproachTime,RefoldSettings
	SetDimLabel 0,3,ApproachDelay,RefoldSettings
	SetDimLabel 0,4,HoldoffDistance,RefoldSettings
	SetDimLabel 0,5,RefineHoldoff,RefoldSettings
	SetDimLabel 0,6,ForceTrigger,RefoldSettings
	SetDimLabel 0,7, RetractSpeed,RefoldSettings
	SetDimLabel 0,8,RetractDwell,RefoldSettings
	SetDimLabel 0,9,FinalDistance,RefoldSettings
	SetDimLabel 0,10,FinalVelocity,RefoldSettings
	SetDimLabel 0,11,SurfaceLocation,RefoldSettings

	SetDimLabel 0,12,Datarate,RefoldSettings
	SetDimLabel 0,13,UltraFast,RefoldSettings

	RefoldSettings[][0]= Wpar[p]
	RefoldSettings[0][1]= {"Experiment Name","Approach Distance","Approach Time","Approach Delay","Holdoff Distance","Refine Holdoff","Force Trigger","Retract Speed","Extension Pause","Surface Pos","Data Rate","UltraFast Too?"}
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
	
end//MakeWaves()

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//CustomRamp_Final() This makes the ramp that will take us from the surface in the final ramp. This includes a pause at the surface, followed by the ramp!
static function CustomRamp_Final(RampInfo,RefoldSettings,CustomWave2)
	wave/t RampInfo
	wave/t RefoldSettings
	wave CustomWave2
	variable total3,slope3,newrate

	total3=round(str2num(RefoldSettings[%DataRate][0])*(1e3+str2num(RefoldSettings[%FinalDistance][0])/str2num(RefoldSettings[%FinalVelocity][0])))
	make/o/n=(total3) ZSensor_Final,DefV_Final //These are the waves that are to be read during this process. We don't adjust their size.

	if(total3<=5000) //checks if we exceed the limit for IR_xSetOutWave
		make/o/n=(total3) CustomWave2
		slope3=1*abs(str2num(RefoldSettings[%FinalVelocity][0])/GV("ZLVDTSens")*1e-6/str2num(RefoldSettings[%DataRate][0])/1e3)
		newrate=str2num(RefoldSettings[%DataRate][0])
	else	//If we do, run with as high a bandwidth as we can while limitting the total points to 87000. Since this is a simple slope, we just use 5000 points, which should be plenty.
		
		total3=5000
		newrate=round(total3/(1+str2num(RefoldSettings[%FinalDistance][0])/str2num(RefoldSettings[%FinalVelocity][0])*1e-3))/1e3

		variable rdecirate=ceil(50/newrate)
		newrate=50e3/rdecirate
		total3=round(newrate*(1+str2num(RefoldSettings[%FinalDistance][0])/str2num(RefoldSettings[%FinalVelocity][0])*1e-3))
		make/o/n=(total3) CustomWave2

		
		slope3=1*abs(str2num(RefoldSettings[%FinalVelocity][0])/GV("ZLVDTSens")*1e-6/newrate)

	endif
	CustomWave2[0,floor(newrate*1)]=0
	CustomWave2[ceil(newrate*1),]=-slope3*(x-ceil(newrate*1))//This is a relative wave ramp, since this is applied to the setpointoffset, this will be fine

end//CustomRamp_Final

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//SlowSave() Saves the slow pull.
Static function SlowSave(RefoldInfo,DefVolts_Final,ZsensorVolts_Final)
	Wave/T RefoldInfo
	Wave DefVolts_Final, ZSensorVolts_Final

	wave MVW = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	string suffixStr = num2strlen(MVW[%BaseSuffix][0],4)
	string AddComm="" 
	variable Index, RetractDistance,RetractVelocity,RetractDelay,sampleRate,Timetostart
	String Indexes = "0," //Start the index and directions 
	String Directions = "Inf,"


	RetractDistance=str2num(RefoldInfo[%FinalDistance][0])
	RetractVelocity=str2num(RefoldInfo[%FinalVelocity][0])
	RetractDelay=str2num(RefoldInfo[%ApproachDelay][0])
	
	TimetoStart=str2num(RefoldInfo[%TimeToStart][0])


	sampleRate=str2num(RefoldInfo[%DataRate][0]) *1e3
	Index=dimsize(DefVolts_final,0)
	Indexes += num2istr(Index)+","
	Directions += "-1,"

	AddComm = ReplaceStringbyKey("Indexes",AddComm,Indexes,":","\r")
	AddComm = ReplaceStringbyKey("Direction",AddComm,Directions,":","\r")
		AddComm = ReplaceStringbyKey("Experiment Type",AddComm,RefoldInfo[%ExperimentName],":","\r")
	AddComm = ReplaceStringbyKey("Experiment Stage",AddComm,"Unfolding Curve",":","\r")
	AddComm = ReplaceStringbyKey("RetractDelay",AddComm,num2str(RetractDelay),":","\r")
	AddComm = ReplaceStringbyKey("RetractVelocity",AddComm,num2str(RetractVelocity),":","\r")
	AddComm = ReplaceStringbyKey("RetractDistance",AddComm,num2str(RetractDistance),":","\r")
	AddComm = ReplaceStringbyKey("NumPtsPerSec",AddComm,num2str(sampleRate),":","\r")
	AddComm = ReplaceStringbyKey("Pull Type",AddComm,"Final",":","\r")
	AddComm = ReplaceStringbyKey("Experiment Type",AddComm,"Step Out Equilibrium",":","\r")
	AddComm = ReplaceStringbyKey("TimeToStart",AddComm,num2str(TimetoStart),":","\r")	
	AddComm = ReplaceStringbyKey("Corresponding Fast Pull",AddComm,num2strlen(str2num(suffixStr)-1,4),":","\r")

	DE_SaveReg(DefVolts_final,ZSensorVolts_final,AdditionalNote=AddComm)
	
		
end	//DE_SlowPair

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//FinalSave() Saves the slow pull.
Static function FinalSave(RefoldInfo,DefVolts_Final,ZsensorVolts_Final)
	Wave/T RefoldInfo
	Wave DefVolts_Final, ZSensorVolts_Final

	wave MVW = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	string suffixStr = num2strlen(MVW[%BaseSuffix][0],4)
	string AddComm="" 
	variable Index, RetractDistance,RetractVelocity,RetractDelay,sampleRate,Timetostart
	String Indexes = "0," //Start the index and directions 
	String Directions = "Inf,"


	RetractDistance=str2num(RefoldInfo[%FinalDistance][0])
	RetractVelocity=str2num(RefoldInfo[%FinalVelocity][0])
	RetractDelay=str2num(RefoldInfo[%ApproachDelay][0])
	
	TimetoStart=str2num(RefoldInfo[%TimeToStart][0])


	sampleRate=str2num(RefoldInfo[%DataRate][0]) *1e3
	Index=dimsize(DefVolts_final,0)
	Indexes += num2istr(Index)+","
	Directions += "-1,"

	AddComm = ReplaceStringbyKey("Indexes",AddComm,Indexes,":","\r")
	AddComm = ReplaceStringbyKey("Direction",AddComm,Directions,":","\r")
	AddComm = ReplaceStringbyKey("Experiment Type",AddComm,RefoldInfo[%ExperimentName],":","\r")
	AddComm = ReplaceStringbyKey("Experiment Stage",AddComm,"Final Unfolding",":","\r")
	AddComm = ReplaceStringbyKey("RetractDelay",AddComm,num2str(RetractDelay),":","\r")
	AddComm = ReplaceStringbyKey("RetractVelocity",AddComm,num2str(RetractVelocity),":","\r")
	AddComm = ReplaceStringbyKey("RetractDistance",AddComm,num2str(RetractDistance),":","\r")
	AddComm = ReplaceStringbyKey("NumPtsPerSec",AddComm,num2str(sampleRate),":","\r")
	AddComm = ReplaceStringbyKey("Pull Type",AddComm,"Final",":","\r")
	AddComm = ReplaceStringbyKey("Experiment Type",AddComm,"Step Out Equilibrium",":","\r")
	AddComm = ReplaceStringbyKey("TimeToStart",AddComm,num2str(TimetoStart),":","\r")	
	AddComm = ReplaceStringbyKey("Corresponding Fast Pull",AddComm,num2strlen(str2num(suffixStr)-1,4),":","\r")

	DE_SaveReg(DefVolts_final,ZSensorVolts_final,AdditionalNote=AddComm)
	
		
end	//DE_SlowPair
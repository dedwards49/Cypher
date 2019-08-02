#pragma rtGlobals=1		// Use modern global access method.

#include ":AsylumResearch:Code3D:UserPanels:FastCapture"
#include ":DE_MultirampCL"
#include ":DE_MultiRamp"
#include ":DE_MultiCTFC"
#include ":DE_TriggeredForce_Panel"
#include ":DE_StepOut"
#include ":DE_Glide"
#include ":DE_SOEquil"
#include ":DE_RerunandMove"



Menu "Slow Unfolding"
	"Initialize", DE_InitializeCTFC()
end

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 function DE_InitializeCTFC()

	InitFastCapture()
	Execute "DE_CTFC_Control()"
end

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// DE_GrabExistingCTFCparms imports the existing CTFC parameter group.  Makes it easier to write CTFC parameters without errors
 Function DE_GrabExistingCTFCparms()

	Make/O/T root:DE_CTFC:TriggerSettings
	Variable error=0
	error+=td_ReadGroup("ARC.CTFC",root:DE_CTFC:TriggerSettings)
	return error

End //DE_GrabExistingCTFCparms()

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// DE_LoadCTFCparms function sets up the CTFC ramp parameters. It takes the information from the input wave RampSettings and Refold Settings
Function DE_LoadCTFCparms(RampSettings,RefoldSettings,Type)
	Wave/T RampSettings
	wave/t RefoldSettings
	string Type
	Variable SurfaceTrigger,MoleculeTrigger, ApproachSpeed, RetractSpeed, NoTriggerTime,MaxZVolt
	String RetractTriggerChannel,ApproachTriggerChannel,RetractTrigRel,ApproachTrigRel,RampChannel
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	String ErrorStr = ""
	Variable Scale = 1
	
	RampChannel =  "Output.Z"
	ApproachTriggerChannel=RampSettings[1][0]   //sets the first trigger channel. This will presumably often be deflection (to first touch of the surface), but could be something else
	strswitch(ApproachTriggerChannel)  //A switch to properly define the trigger levels (in voltage) based on the channel used for the first trigger. For now I just have Deflection and an option for not recognized
		
		case "Deflection":
			SurfaceTrigger = str2num(RampSettings[2][0])*1e-12/GV("InvOLS")/GV("SpringConstant")   //The desired deflection (converted to Volts) to reach at the surface
			ApproachTrigRel="Relative Start" //Sets the approach trigger to be relative to the start of the scan.
			break
			
		case "ZSensor":
			SurfaceTrigger=str2num(RampSettings[2][0])*1e-9/GV("ZLVDTSens") //Add the approximate distance from the surface we need.
			ApproachTrigRel="Relative Start" //Sets the approach trigger to be relative to the start of the scan.
			break
			
		default:
			print "Trigger channel not recognized"  //Abort out if the channel is poorly defined.
			abort
			
	endswitch
	
	ApproachSpeed = str2num(RampSettings[0][0])*1e-6/GV("ZPiezoSens") //set the approach speed by converting from um/s to V/s. Note this is positive to approach the surface.
	RetractTriggerChannel=RampSettings[5][0] //sets the second trigger channel.
	TriggerInfo[%TriggerChannel2] = RetractTriggerChannel
	
	strswitch(RetractTriggerChannel)  //A switch to properly define the trigger levels (in voltage) based on the channel used for the second trigger.
		
		case "output.Dummy":  
			MoleculeTrigger=0 //Is Ignored anyway
			RetractTrigRel="Relative Start" //Is ignored anyway
			break

		case "ZSensor":
			MoleculeTrigger=str2num(RampSettings[%MolecularTrigger][0])*1e-9+str2num(RampSettings[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")  //Add the approximate distance from the surface we need.
			MoleculeTrigger= -1*MoleculeTrigger/GV("ZLVDTSens") //How far to move converted from nm to Volts
			RetractTrigRel="Relative Ramp Start" //Sets the approach trigger to be relative to the start the second ramp (i.e. compare to the trigger position).
			break
		
		case "Deflection":
			MoleculeTrigger = -1*str2num(RampSettings[%MolecularTrigger][0])*1e-12/GV("InvOLS")/GV("SpringConstant") //Deflection to reach
			variable SDef=real(DE_AverageChan(0,"Arc.Input.A")) 
			MoleculeTrigger=SDef+MoleculeTrigger  //This manually offsets the trigger channel to be from the starting deflection.
			RetractTrigRel="Absolute" //Sets the approach trigger to be relative to the start of the whole CTFC (i.e. compare to the initial deflection).
			TriggerInfo[%TriggerChannel2] = "arc.input.A"//I am always triggering off of this input which is filtered down. Sometimes it is detrended, but if it isn't detrended, I just don't sample it (i.e., if all happens in the CTFC).
			break
		
		default:
			print "Trigger channel not recognized" //Abort out if the channel is poorly defined.
			abort
			
	endswitch
	
	RetractSpeed = -1*str2num(RampSettings[4][0])*1e-6/GV("ZPiezoSens") //set the retract speed by converting from um/s to V/s. Note this is negative to retract from the surface.
	NoTriggerTime= str2num(RampSettings[8][0])*1e-9+str2num(RampSettings[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")
	NoTriggerTime = NoTriggerTime/(str2num(RampSettings[4][0])*1e-6) //an estimate of how long to wait to avoid the vs X nm of distance in the curve. I.e., triggering starts after this time.
	TriggerInfo[%RampChannel] = RampChannel
	TriggerInfo[%RampOffset1] = num2str(150) //Max Z Piezo (in volts) on initial push
	TriggerInfo[%RampSlope1] = num2str(ApproachSpeed)  //Z Piezo Volts/s
	TriggerInfo[%RampOffset2] = "NaN" //Max Z Piezo (in volts) on initial retraction.This retracts to the initial starting point. 
	TriggerInfo[%RampSlope2] = num2str(RetractSpeed) //Z Piezo Volts/s
	TriggerInfo[%TriggerChannel1] = ApproachTriggerChannel
	TriggerInfo[%TriggerValue1] = num2str(SurfaceTrigger) //Deflection Volts
	TriggerInfo[%TriggerCompare1] = ">="
	
	TriggerInfo[%TriggerValue2] = num2str(MoleculeTrigger) 
	TriggerInfo[%TriggerCompare2] = "<="
	TriggerInfo[%TriggerHoldoff2] = num2str(NoTriggerTime)
	TriggerInfo[%DwellTime1] = RampSettings[3][0]
	TriggerInfo[%DwellTime2] = RampSettings[7][0]
	TriggerInfo[%EventDwell] = "4,6"
	TriggerInfo[%EventRamp] = "3,5"
	TriggerInfo[%EventEnable] = "2"
	TriggerInfo[%CallBack] = RampSettings[9][0]
	TriggerInfo[%TriggerType1] = ApproachTrigRel
	TriggerInfo[%TriggerType2] = RetractTrigRel
	
	strswitch(Type)  //When we are finding the surface OR just measuring the wiggles for detrend, the settings are changed
	
		case "Find":
			TriggerInfo[%DwellTime1] = num2str(.1)
			TriggerInfo[%DwellTime2] = num2str(0.001)
			TriggerInfo[%TriggerType2]="Relative Ramp Start"
			MoleculeTrigger=str2num(RampSettings[%StartDistance][0])*1e-9+str2num(RampSettings[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")  //Add the approximate distance from the surface we need.
			MoleculeTrigger= -1*MoleculeTrigger/GV("ZLVDTSens") //How far to move converted from nm to Volts
			TriggerInfo[%TriggerChannel2] = "ZSensor"
			TriggerInfo[%TriggerValue2] =num2str(MoleculeTrigger)
			TriggerInfo[%CallBack] ="DE_FindCallback()"
		break
			
		
		case "Detrend":
			TriggerInfo[%DwellTime1] = num2str(.1)
			TriggerInfo[%DwellTime2] = num2str(0.001)
			TriggerInfo[%TriggerType2]="Relative Ramp Start"
			MoleculeTrigger=str2num(RampSettings[%StartDistance][0])*1e-9+str2num(RampSettings[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")  //Add the approximate distance from the surface we need.
			MoleculeTrigger= -1*MoleculeTrigger/GV("ZLVDTSens") //How far to move converted from nm to Volts
			TriggerInfo[%TriggerChannel2] = "ZSensor"
			TriggerInfo[%TriggerValue2] =num2str(MoleculeTrigger)
			TriggerInfo[%CallBack] ="DE_DetrendCallback()"
			break
		
		case "Run":
			break
	
	
		default:
	
	endswitch
	
	ErrorStr += num2str(td_WriteString("Event.5","Clear"))+","
	ErrorStr += num2str(td_WriteString("Event.3","Clear"))+","
	ErrorStr += num2str(td_writeGroup("ARC.CTFC",TriggerInfo))+","
	
	strswitch(Type)//This controls whether or not we setup the extension feedback AFTER the end of the CTFC. For normal runs we want this, but when finding the surface or
					//setting up detrend, we don't.
	
		case "Find":

			break
		
		case "Detrend":
			
			break
		
		case "Run":
			//This sets up an extension feedback servo to AFTER the end of the CTFC. Evidently, this will only fire if we successfully detect a molecule.  This is setup on channel 5
			Struct ARFeedbackStruct FB

			ARGetFeedbackParms(FB,"Z")
			FB.Bank = 5
			FB.Setpoint = NaN
			FB.DynamicSetpoint = 1
			FB.LoopName = "DwellLoop2"
			FB.StartEvent = "6"
			FB.StopEvent = "Never"
			ErrorStr += ir_WritePIDSloop(FB)
			break
	
	
		default:
	
	endswitch
	
	//This sets up an extension feedback servo to engage only during the surface pause (i.e. between the firing of event 4 and event 5). This is setup on channel 4 of the PID loop

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
Function DE_SetInWavesFromCTFC(RampInfo,RefoldSettings,Type)
	wave/t RampInfo
	wave/t RefoldSettings
	string Type
	wave customwave1
	variable decirate,total1,newrate
	
	//This makes and assigns the waves for reading the "fast" portion of the scan, which is the first pull.
	Make/o/N=(str2num(RampInfo[%SampleRate][0])*str2num(RampInfo[%TotalTime][0])*1000)/O ZSensor_Fast,DefV_Fast 
	IR_XSetInWavePair(1,"2","Deflection",DefV_Fast,"Cypher.LVDT.Z",ZSensor_Fast,"",50/str2num(RampInfo[%SampleRate][0]))
	
	//This records the cloned version of the deflection signal that we are detrending.
	Make/o/N=(str2num(RampInfo[%SampleRate][0])*str2num(RampInfo[%TotalTime][0])*1000)/O ArcY,ArcX
	IR_XSetInWavePair(2,"2","Arc.Input.A",ArcY,"Cypher.LVDT.Z",ArcX,"",50/str2num(RampInfo[%SampleRate][0]))

	
	
	strswitch(Type)
	
		case "Find":
			td_stopdetrend()

			break
			
		
		case "Detrend":
			
			break
		
		case "Run":
			td_wv("Cypher.Input.FastA.Filter.Freq",str2num(RampInfo[%SampleRate][0])/2*1e3)  //This sets the filter to be at half the sample rate for anti-aliasing.
			td_wv("Arc.Input.A.Filter.Freq",str2num(RampInfo[%SampleRate][0])/2*1e3) //This does the same for the CTFC panel. However, I think it would be wise to filter this channel more.
			//ForceSetVarFunc("ForceFilterBWSetVar"+TabStr,str2num(RefoldSettings[7][0])/2*1e3,"",":Variables:ForceVariablesWave[%ForceFilterBW]")
			ReadFilterValues(3) //This updates the filter settings in Igor (I think)
			
			//This chunk just figures out the decimation rate for the output wave (Customwave1)				
			total1=round(str2num(RefoldSettings[%DataRate][0])*(str2num(RefoldSettings[%ApproachTime][0])+str2num(RefoldSettings[%ApproachDelay][0]))*1e3)
					 
			if(total1<=5000) //checks if we exceed the limit for IR_xSetOutWave
				decirate=50/str2num(RefoldSettings[%DataRate][0])
			
			else	//If we do, run with as high a bandwidth as we can while limitting the total points to 87000
				total1=5000
				newrate=total1/(str2num(RefoldSettings[%ApproachTime][0])+str2num(RefoldSettings[%ApproachDelay][0]))
				decirate=50/newrate*1e3
		
			endif

			
			break
	
		default:
	
	endswitch
	IR_xSetOutWave(2,"6","$DwellLoop2.SetpointOffset",CustomWave1,"DE_RampDownDone()",decirate)
		
end//DE_SetInWavesFromCTFC

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//This makes and fills the waves to cover the return of the tip to the surface.
Function DE_Custom1_Glide(RampInfo,RefoldSettings,CustomWave1)
	wave/t RampInfo
	wave/t RefoldSettings
	wave CustomWave1
	variable decirate, total1, midpoint1, endpoint1, slope1,constant1,newrate


	
	//This writes CustomWave1, which will drive the Z-position back toward the surface
	
	total1=round(str2num(RefoldSettings[%DataRate][0])*(str2num(RefoldSettings[%ApproachTime][0])+str2num(RefoldSettings[%ApproachDelay][0]))*1e3) //Total points expected.
	if(total1<=5000) //checks if we exceed the limit for IR_xSetOutWave
		//It isn't too many, so go ahead and just make this work.
		decirate=50/str2num(RefoldSettings[%DataRate][0])
		make/o/n=(total1) CustomWave1
		constant1=(str2num(RefoldSettings[%ApproachDistance][0])/GV("ZLVDTSens")*1e-9)
		slope1=1e-9/(str2num(RefoldSettings[%ApproachTime][0])*str2num(RefoldSettings[%DataRate][0])*1e3)*str2num(RefoldSettings[%ApproachDistance][0])/GV("ZLVDTSens")
		midpoint1=str2num( RefoldSettings[%ApproachTime][0])*str2num(RefoldSettings[%DataRate][0])*1e3
		endpoint1=(total1-1)
			
	else
		//Too many, cut back to 5000 points and then design the wave.
		total1=5000
		newrate=round(total1/(str2num(RefoldSettings[%ApproachTime][0])+str2num(RefoldSettings[%ApproachDelay][0])))/1e3
		variable rdecirate=floor(50/newrate)
		newrate=50e3/rdecirate
		total1=round(newrate*(str2num(RefoldSettings[%ApproachTime][0])+str2num(RefoldSettings[%ApproachDelay][0])))

		make/o/n=(total1) CustomWave1
		
		decirate=50/newrate*1e3
		constant1=(str2num(RefoldSettings[%ApproachDistance][0])/GV("ZLVDTSens")*1e-9)
		slope1=1e-9/(str2num(RefoldSettings[%ApproachTime][0])*newrate)*str2num(RefoldSettings[%ApproachDistance][0])/GV("ZLVDTSens")

		midpoint1=str2num( RefoldSettings[%ApproachTime][0])*newrate
		endpoint1=(total1-1)
			
	endif

	CustomWave1=(constant1)
	CustomWave1[0,midpoint1]=slope1*x
end//DE_Custom1_Glide

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


//

//DE_Custom2_StepOut sets up the customwave2, which will drive us away from the surface if it's called. In this case the "StepOut" tells us that we will go out in steps
//We need to hand it CustomWave1 so that it knows where customwave1 is going to stop


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//DE_StartCTFC() Starts the first CTFC each and every time. This is the main one!
Function DE_StartCTFC(Type)
	string Type
	td_ws("arc.crosspoint.ina","Defl") //Sets the IN.A chanel to read deflection.
		
	if(Exists("root:DE_CTFC:MenuStuff:Stop")==2)//Checks if someone hit "stop next" if so, runs stop.
		SVar T=root:DE_CTFC:MenuStuff:Stop
		if(cmpstr(T,"Yes")==0)
			td_stopdetrend()
			print "Stopped By Command"
			killstrings T
			if(waveExists(root:DE_CTFC:MenuStuff:ListComwave)==1)
			wave/z/T T2=root:DE_CTFC:MenuStuff:ListComwave
			T2="Stopped by User Command"

		endif
			return -1
		endif
		
	
	endif

	If(abs(Td_rv("Deflection"))>4)  //If you deflection is above a couple of volts, we freak out!
		print "Deflection Exceeds Max :4V"
		td_setramp(1,"arc.output.z",0,0,"",0,0,"",0,0,"") 

	return -1
	endif

	if(cmpstr(Type,"Find")!=0&&cmpstr(Type,"Detrend")!=0&&cmpstr(Type,"Run")!=0)
		print "Unrecognized Experiment Type"
		print Type
		return -1
	
	endif
	
	DE_GrabExistingCTFCParms()
	DE_LoadCTFCParms(RampSettings,RefoldSettings,Type)
	DE_SetInWavesFromCTFC(RampSettings,RefoldSettings,Type)
	
	Variable Error = 0
	
	Error += td_WS("Event.2","Clear")	
	Error += td_WS("Event.3","Clear")	
	Error += td_WS("Event.4","Clear")	
	Error += td_WS("Event.5","Clear")	
	Error += td_WS("Event.6","Clear")		
	
	Error += td_WS("Event.2","Once")		//Fires event.2, this starts everything!
	If (Error > 0)
		print "Error in StartMyCTFC"
	Endif

End //DE_StartCTFC()

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//DE_FindCallback is the callback that is called after the "find surface" protocol is run. From here the software either runs the "real" scan, or runs a detrend scan if it's desired.
function DE_FindCallback()
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave/t RampSettings
	td_ReadGroup("ARC.CTFC",TriggerInfo)
	td_stopinwavebank(1)
	td_stopinwavebank(2)
	ir_StopPISloop(5)
	if(cmpstr(RampSettings[%Detrend][0],"No")==0)
		DE_StartCTFC("Run")
		else
		DE_StartCTFC("Detrend")
	endif
end//DE_FindCallback

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//DE_DetrendCallback is the callback that is called after the "detrend" protocol is run. This does some housekeeping and then runs the "real" scan.
function DE_DetrendCallback()
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	
	td_ReadGroup("ARC.CTFC",TriggerInfo)
	td_stopinwavebank(1)
	td_stopinwavebank(2)
	DE_UpdateDeTrend("New")
	DE_UpdatePlot("Detrend")
	ir_StopPISloop(5)
	DE_StartCTFC("Run")

end//DE_DetrendCallback


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//DE_CTFCCB_TFE is the callback for the CTFC, If the CTFC does not find a molecule then this is what handles redisplaying the data and repeating the experimen as desired.
Function DE_CTFCCB_TFE() 
	String ErrorStr = ""
	variable adding, zerovolt,PVol
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	wave Zsensor_fast
	wave/t RampInfo=root:DE_CTFC:RampSettings
	wave/t RampSettings
wave/t Command=root:DE_CTFC:MenuStuff:ListComwave
	td_ReadGroup("ARC.CTFC",TriggerInfo)
	
	// Check to see if molecule is attached.  If Triggertime2 is greater than 400,000, then molecule did NOT attach and the ramp to the surface will not run. Then we need to check if we want to repeat the measurement.
	if (str2num(TriggerInfo[%TriggerTime2])> 400000)
			
		zerovolt=(Zsensor_fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampSettings[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
		PVol=Zerovolt-str2num(RampSettings[%StartDistance][0])*1e-9/GV("ZLVDTSEns")
		td_stopinwavebank(1)
		td_stopinwavebank(2)
		DE_UpdatePlot("No Trigger")
		//print "No Trigger"
		Command="No Trigger"
		ir_StopPISloop(5)
		variable rep=DE_RepCheck()
		DE_RamptoVol(PVol,"Start","DE_CB_NoMol(\\\"TFE\\\","+num2str(rep)+")")

	endif
				
End //DE_CTFCCB_FE_Halt

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//RampDownDone() is called if/when the setwavein command is done. This will only be called if the CTFC successfully triggers. 
//In this case we setup the NEXT movement, which is to jump out to the set distance and wait. I have also installed here a command called
//overage. 
function DE_RampDownDone()
	wave customwave2
	wave/t RefoldSettings
	variable decirate,DataLength,runFast,outdecirate,adding,total2,overage,zerovolt,PVol, startmultivolt,endmultivolt,TotalTime
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave DefVolts_Fast=DEfv_fast
	wave ZsensorVolts_Fast=Zsensor_fast
	wave ZSensorVolts_slow=Zsensor_slow
	wave DefVolts_slow=DEfv_slow
	variable TabNum = ARPanelTabNumLookUp("ForcePanel")
	string TabStr = "_"+num2str(TabNum)
	variable rep

	
	td_ReadGroup("ARC.CTFC",TriggerInfo) //Updates the triggerinfo
	
	//guess at where the surface occurs based on the trigger settings. This will work poorly
	//if there are significant wiggles, but should get us pretty close. that is ZeroVolt is basically "the surface"
	zerovolt=(ZsensorVolts_Fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
	PVol=Zerovolt-str2num(RampInfo[%StartDistance][0])*1e-9/GV("ZLVDTSEns")  //PVol is the approximate location of the start position.
	
	//Updates the filter for the next scane
	td_wv("Cypher.Input.FastA.Filter.Freq",str2num(RefoldSettings[%DataRate][0])/2*1e3)
	ReadFilterValues(3)
	PV("ForceFilterBW",str2num(RefoldSettings[%DataRate][0])/2*1e3)
	PV("ZStateChanged",1)	
	decirate=50/str2num(RefoldSettings[%DataRate][0])
	
	DE_PIS_ZeroSetpointOffset(5,"DwellLoop2") //This does some housework by setting the PIS loop so that the current position (i.e., following the ramp down) as the 0 position. This means we can ramp around at will and we know that zero is near the surface.
	

	td_stopinwavebank(1)
	td_stopinwavebank(2)

	DE_UpdatePlot("Triggered 1")
	
	strswitch(RefoldSettings[%ExperimentName][0])
		
		case "Glide":
			IR_XSetInWavePair(1,"7,7","Cypher.Input.FastA",DefVolts_slow,"Cypher.LVDT.Z",ZSensorVolts_slow,"", decirate)
			DE_Glide_Start()
			return 0
			break
		
		case "Step Out":
			IR_XSetInWavePair(1,"7,7","Cypher.Input.FastA",DefVolts_slow,"Cypher.LVDT.Z",ZSensorVolts_slow,"", decirate)
			DE_StepOut_Start()
			return 0
			break
		
		case "SOEquil":
			DE_SOEquil_Start()
			return 0
	 break
			
		case "MultiRamp":
			DE_MultiRamp_Start()
			return 0
			break
			
		case "MultiRampOL":
			DE_MultiRampOL_Start()
			return 0
		break
		
		case "MultiCTFC":
			
			DE_MultiCTFC#Start()
			
			//	
				
		return 0
		break
	endswitch
//
//
//	strswitch(RefoldSettings[%ExperimentName][0])//Right now every program except Multiramp can just launch. multiRamp does it's own thing as we may not be starting at the current location.
//
//		case "MultiRamp":
//			DE_FastPair(TriggerInfo,RepeatInfo,RampInfo,DefVolts_Fast,ZsensorVolts_Fast)//Saves the data from the fast (initial) pull here.
//			RefoldSettings[%CurrIter][0]="0" //sets the current iteration to 0. 
//			variable/g StartingPiezo=td_rv("output.z")
//			
//			td_SetRamp(str2num(RefoldSettings[%TimeToStart][0]), "PIDSLoop.5.Setpointoffset", 0, Customwave2[0], "", 0, 0, "", 0, 0, "DE_MultiRampInit("+num2str(outdecirate)+")")
//			break
//		default:
			
//	endswitch 


	
end//RampDownDone

function DE_RampJumpDone()
	
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave DefVolts_Fast=DEfV_fast
	wave ZsensorVolts_Fast=Zsensor_fast
	wave ZSensorVolts_slow=Zsensor_slow
	wave DefVolts_slow=DEfv_slow
	wave/t RefoldSettings
	variable adding,rep,readfast=0,zerovolt,Pvol
	
	strswitch(RefoldSettings[0][0])
	
		case "MultiRamp":
				//At the moment, we handle this elsewhere...I think I'll keep writing separate programs.
			break
			
			
		case "Glide":
//			ir_StopPISloop(5)  //Halt the feedback loop.
//	
//	
//
//			zerovolt=(ZSensorVolts_fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[2][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
//			PVol=Zerovolt-str2num(RampInfo[%StartDistance][0])*1e-9/GV("ZLVDTSEns")   //Move us back, in this case 200 nm from where I am guessing the surface is. Right now this is hard coded, but should be added as a parameter.
//		
//			DE_FastPair(TriggerInfo,RepeatInfo,RampInfo,DefVolts_Fast,ZsensorVolts_Fast)
//			DE_SlowPair(RepeatInfo,SlowInfo,DefVolts_slow,ZsensorVolts_slow)
//					
//			DE_UpdatePlot("Triggered Done")
//			if(StringMatch(RefoldSettings[8][0],"Yes")==1)
//				ReadFast=DE_CheckFast("Access 5 MHz","5 MHz Check")
//				
//				if(ReadFast!=1)
//				print "Devin This matters"
//					DE_MAPFastCaptureCallback("Read",ReadFast)
//						
//				else
//					rep=DE_RepCheck()
//					DE_RamptoVol(PVol,"Start","DE_CB_Mol(\\\"TFE\\\","+num2str(rep)+")")
//				endif
//			
//			else
//				rep=DE_RepCheck()
//				DE_RamptoVol(PVol,"Start","DE_CB_Mol(\\\"TFE\\\","+num2str(rep)+")")	
//			endif
//			
//			break
		
		case "Step Out":
//			ir_StopPISloop(5)  //Halt the feedback loop.
//	
//	
//
//			zerovolt=(ZSensorVolts_fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[2][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
//			PVol=Zerovolt-str2num(RampInfo[%StartDistance][0])*1e-9/GV("ZLVDTSEns")   //Move us back, in this case 200 nm from where I am guessing the surface is. Right now this is hard coded, but should be added as a parameter.
//		
//			DE_FastPair(TriggerInfo,RepeatInfo,RampInfo,DefVolts_Fast,ZsensorVolts_Fast)
//			DE_SlowPair(RepeatInfo,SlowInfo,DefVolts_slow,ZsensorVolts_slow)
//					
//			DE_UpdatePlot("Triggered Done")
//			if(StringMatch(RefoldSettings[9][0],"Yes")==1)	
//				ReadFast=DE_CheckFast("Test","Test")
//	
//				if(ReadFast!=4)
//					DE_MAPFastCaptureCallback("Read",ReadFast)
//				
//				else
//					rep=DE_RepCheck()
//					DE_RamptoVol(PVol,"Start","DE_CB_Mol(\\\"TFE\\\","+num2str(rep)+")")
//				endif
//			else
//				rep=DE_RepCheck()
//				DE_RamptoVol(PVol,"Start","DE_CB_Mol(\\\"TFE\\\","+num2str(rep)+")")				
//			endif
//			
//			break
			

		
	endswitch
	
end//RampJumpDown

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DE_RepCheck()
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
		Wave/T RampInfo=root:DE_CTFC:RampSettings

	variable adding
	if(cmpstr(RampInfo[%Detrend][0],"Yes")==0)   //If we want to Detrend
	
		DE_UpdateDeTrend("Update")

	endif
	
	if(cmpstr(RepeatInfo[0][0],"Yes")==0)   //If we want to repeat.
			
			adding=str2num(RepeatInfo[6][0])+1  //Calculate the new number of iteration
			RepeatInfo[6][0]=num2str(adding)  // Insert it into the Repeat loop.

			return 1
		else //If we don't want to repeat
				
			td_stopdetrend()

			return 0

		endif
end//DE_RepCheck()

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//DE_CB_NoMol
function DE_CB_NoMol(Experiment,Result)
	string Experiment
	variable Result
	NVAR DataDone,CTFCSucc

	strswitch(Experiment)

		case "TFE":
	
			if(Result==1)
				DE_LoopRepeater()
			else

			endif

			break

	endswitch

end //DE_CB_NoMol() 

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DE_CB_Mol(Experiment,Result)
	string Experiment
	variable Result
	NVAR DataDone,CTFCSucc

	strswitch(Experiment)

		case "TFE":
	
			if(Result==1)
				DE_LoopRepeater()
			else

			endif

			break

	endswitch

end //DE_CB_Mol() 

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//DE_LoopRepeater()
function DE_LoopRepeater()

	wave/t RepeatInfo=root:DE_CTFC:RepeatSettings
	variable add,PVol,zerovolt
	wave/t Command=root:DE_CTFC:MenuStuff:ListComwave

	if(str2num(RepeatInfo[6][0])<str2num(RepeatInfo[5][0]))  //Checks if the total number of iterations at this spot has been exceeded

		DE_StartCTFC("Run")      //If not, then just run again!

	else

		RepeatInfo[6][0]="0"   //Reset the iterations

		if((str2num(RepeatInfo[7][0])+1)<str2num(RepeatInfo[4][0]))  //Checks if the total number of spots has been exceeded
	
			print "Finding Next Spot"  //if Not, then we better find the next spot.
			add=str2num(RepeatInfo[7][0])+1  //increment spot location 
			RepeatInfo[7][0]=num2str(add)   //save the new spot location
			pv("ForceSpotNumber",str2num(RepeatInfo[7][0]))  //Set us to the new spot.
			zerovolt=td_rv("Zsensor")
			PVol=Zerovolt-500*1e-9/GV("ZLVDTSEns")
			td_stopdetrend()
			DE_RamptoVol(PVol,"Start","DE_newSpotStart()")
			

		else
		
			RepeatInfo[7][0]="0" //We reset the current spot back to zero and quick
			td_stopdetrend()
			//Print "All Spots and Iterations Done"  
			Command="All Spots and Iterations Done"
		endif
	
	endif

end //DE_LoopRepeater

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function DE_newSpotStart()


DE_ZeroPD() //Runs the zeroPD program
			GoToSpot() //Starts moving us to the next spot.
			DE_TestDevinWait(10000) //This is JUST an instrument pause to give plenty of time to get to the next spot. This needs to be checked out a little bit to be sure we're giving enough time. Could implement a loop
			//to check for nearing the right spot, but I think this will work so long as I tune the delay.
			wave/t RampSettings
//			if(cmpstr(RampSettings[%Detrend][0],"No")==0)
//						DE_StartCTFC("Run")	//Now we restart.
//
//else
			DE_StartCTFC("Find")	//Now we restart.
//endif
end
//DE_ZeroPD zeros the PD on the cypher. It has a built in "time-out", which I increased from 250 to 500 to ensure there's plenty of time. This is called from the auto-zero function that is in the thermal scan from 
//Asylum. 


function DE_ZeroPD()

	td_WriteString("Cypher.Head.ADCZeroChannel","Deflection") //This starts zeroing the deflection signal.
	Variable WeRunnin, DeflValue, Counter = 0, 	MaxCount=500 //Will try to get zero for 500 counts at most. but will click out early if Werunning (which checks whether the ARC has zeroed happily).
	FuncRef DoNothing UpdateFunc=$"TinyLittleFastFunction"   //This is just a little function that runs in circles to eat up processor time while we wait for it to zero.

	Do
		
		UpdateFunc()
		Counter += 1
		DoUpdate
		WeRunnin = td_ReadValue("Cypher.Head.ADCZeroChannel")
	
	while (!IsNan(WeRunnin) && WeRunnin && (Counter < MaxCount))  //Runs until td_ReadValue("Cypher.Head.ADCZeroChannel") changes (without going NaN) or until we reach the max.
						
end  //DE_ZeroPD


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//TestDevinWait Simply runs a meaningless loop in circle to kill time. Could Revise this so that it includes, say, a check of the GoToSpot arriving at its spot.
function DE_TestDevinWait(MaxCount)
	variable MaxCount   //Sets max counts
			
	Variable WeRunnin, DeflValue, Counter = 0	 
	FuncRef DoNothing UpdateFunc=$"TinyLittleFastFunction"  //a little time killing function
	variable tick
	tick=ticks 
	
	Do
	
		UpdateFunc()
		Counter += 1
		DoUpdate
	
	while ((Counter < MaxCount))   //Just kill a bunch of time!

	//print (tick-ticks)*1/60

end  //TestDevinWait

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//CheckFast()
function DE_CheckFast(MessageString,TitleString)
	string MessageString,TitleString
	Variable Collect=0
	Prompt Collect,MessageString,popup,"Yes,Save to Exp.;Yes-Save to HD;Yes-Save to Both; No; Yes-Don't Save"
	DoPrompt TitleString,Collect
	return Collect
end


//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//CheckFast()
function DE_CheckRamp(MessageString,TitleString)
	string MessageString,TitleString
	Variable Collect=0
	Beep
	Prompt Collect,MessageString,popup,"Yes;No"
	DoPrompt TitleString,Collect
	return Collect
end

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function/C DE_PlaceMarkers(startdist,enddist)
variable startdist, enddist
	wave/t RefoldSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave ZsensorVolts_Fast=Zsensor_fast

	variable zerovolt,startmultivolt,endmultivolt
	zerovolt=(ZsensorVolts_Fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))

	startmultivolt=Zerovolt-startdist/GV("ZLVDTSEns")
	endmultivolt=Zerovolt-enddist/GV("ZLVDTSEns")
	
	FindLevel/p/q ZsensorVolts_Fast,startmultivolt
	variable startmultipnt=v_Levelx
	FindLevel/p/q ZsensorVolts_Fast,Endmultivolt
	variable endmultipnt=v_Levelx
	Cursor/p/W=DE_CTFC_Control#MostRecent A  Display_DEFV_1  startmultipnt
	Cursor/p/W=DE_CTFC_Control#MostRecent B  Display_DEFV_1  endmultipnt
	ControlInfo /W=DE_CTFC_Control popup4 
	if(cmpstr(s_value,"Yes"))
	else
	
	DE_UserCursorAdjust("de_Ctfc_Control",0)
endif
	startmultivolt=ZsensorVolts_Fast[pcsr(A,"DE_CTFC_Control#MostRecent")]
	endmultivolt=ZsensorVolts_Fast[pcsr(B,"DE_CTFC_Control#MostRecent")]
	return cmplx(startmultivolt,endmultivolt)
end

Function DE_UserCursorAdjust(graphName,autoAbortSecs)
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

Function UserCursorAdjust_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/K tmp_PauseforCursor				// Kill self
End




//DE_FastPair()
function DE_FastPair(TriggerInfo,RepeatInfo,RampInfo,DefVolts_Fast,ZsensorVolts_Fast)
	Wave/T TriggerInfo,RepeatInfo,RampInfo
	Wave DefVolts_Fast, ZSensorVolts_Fast
	
	wave MVW = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	string suffixStr = num2strlen(MVW[%BaseSuffix][0],4)
	
	variable ApproachVelocity=str2num(RampInfo[%ApproachVelocity][0])   
	string TriggerChannel=RampInfo[%SurfaceTriggerChannel][0]
	variable TriggerSet1=str2num(RampInfo[%SurfaceTrigger][0])  
	variable RetractVelocity=str2num(RampInfo[%RetractVelocity][0])  
	string TriggerChannel2=RampInfo[%MolecularTriggerChannel][0]
	variable TriggerSet2=str2num(RampInfo[%MolecularTrigger][0])
	variable NoTrigSet=str2num(RampInfo[%NoTriggerDistance][0])         //Fix
	string Callback=RampInfo[%Callback][0]
	variable TriggerSetVolt1=str2num(TriggerInfo[%TriggerValue1])	 //Fix
	variable TriggerSetVolt2=str2num(TriggerInfo[%TriggerValue2])	  //Fix
	variable TriggerValue1=str2num(TriggerInfo[%TriggerPoint1])
	variable TriggerValue2=str2num(TriggerInfo[%TriggerPoint2])
	variable TriggerTime1=str2num(TriggerInfo[%TriggerTime1])
	variable TriggerTime2=str2num(TriggerInfo[%TriggerTime2])
	variable DwellTime1=str2num(TriggerInfo[%DwellTime1])
	variable DwellTime2=str2num(TriggerInfo[%DwellTime2])
	variable NoTrigTime=str2num(TriggerInfo[%TriggerHoldoff2 ])      //Fix
	variable sampleRate=str2num(RampInfo[%SampleRate][0]) *1e3   //This has to be updated to adapt to inputs.
	//	
	variable TriggerDeflection=0
	//		
	strswitch(TriggerChannel)  //A switch to properly define the trigger levels (in voltage) based on the channel used for the second trigger.
			//			
		case "Deflection":
			//
			TriggerDeflection=TriggerValue1/1e-12*GV("InvOLS")*GV("SpringConstant") //Deflection to reach
			break
			//		
		default:
			//		
	endswitch
	//	
	//	
	//	
	variable dwellPoints0 = round(DwellTime1*sampleRate)   
	variable dwellpoints1=round(DwellTime2*sampleRate) 
	variable ramp2pts= round((TriggerTime2)*sampleRate)-1
	//	
	String Indexes = "0," //Start the index and directions 
	String Directions = "Inf,"
	variable Index = round(TriggerTime1*sampleRate)-1      //Counts out to one point less than where it triggered
	Indexes += num2istr(Index)+","
	Directions += num2str(1)+","
	//	
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

	
	//	//This just lists the rest of the wave (from where the trigger fired through to the end of the wave) as a dwell. In general this contains both the approach back to the surface
	//and any dwell there.

	Index=dimsize(DefVolts_Fast,0)
	Indexes += num2istr(Index)+","
	Directions += "0,"
	//	
	string AddComm="" //This is a correction note for the string that the ARSaveAsForce() function is going to write when we save this as a force.
	AddComm = ReplaceStringbyKey("Indexes",AddComm,Indexes,":","\r")
	AddComm = ReplaceStringbyKey("Direction",AddComm,Directions,":","\r")
	AddComm = ReplaceStringbyKey("ApproachVelocity",AddComm,num2str(ApproachVelocity),":","\r")
	AddComm = ReplaceStringbyKey("RetractVelocity",AddComm,num2str(RetractVelocity),":","\r")
	AddComm = ReplaceStringbyKey("DwellTime",AddComm,num2str(DwellTime1),":","\r")
	AddComm = ReplaceStringbyKey("DwellTime2",AddComm,num2str(DwellTime2),":","\r")
	AddComm = ReplaceStringbyKey("NumPtsPerSec",AddComm,num2str(sampleRate),":","\r")
	AddComm = ReplaceStringbyKey("TriggerDeflection",AddComm,num2str(TriggerDeflection),":","\r")
	AddComm = ReplaceStringbyKey("TriggerChannel",AddComm,TriggerChannel,":","\r")
	AddComm = ReplaceStringbyKey("TriggerChannel2",AddComm,TriggerChannel2,":","\r")
	AddComm = ReplaceStringbyKey("TriggerTime1",AddComm,num2str(TriggerTime1),":","\r")
	AddComm = ReplaceStringbyKey("TriggerTime2",AddComm,num2str(TriggerTime2),":","\r")	
	AddComm = ReplaceStringbyKey("TriggerSet1",AddComm,num2str(TriggerSet1),":","\r")
	AddComm = ReplaceStringbyKey("TriggerSet2",AddComm,num2str(TriggerSet2),":","\r")
	AddComm = ReplaceStringbyKey("TriggerValue1",AddComm,num2str(TriggerValue1),":","\r")
	AddComm = ReplaceStringbyKey("TriggerValue2",AddComm,num2str(TriggerValue2),":","\r")
	AddComm = ReplaceStringbyKey("Pull Speed (Pair)",AddComm,"Fast",":","\r")
	AddComm = ReplaceStringbyKey("Force Dist",AddComm,num2str(TriggerSet2),":","\r")

	AddComm = ReplaceStringbyKey("Corresponding Slow Pull",AddComm,num2strlen(str2num(suffixStr)+1,4),":","\r")
	
	DE_SaveReg(DefVolts_Fast,ZSensorVolts_Fast,AdditionalNote=AddComm)
	
		
end	//DE_FastPair

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//DE_SlowPair
function DE_SlowPair(RepeatInfo,RampInfo,DefVolts_slow,ZsensorVolts_slow)
	Wave/T RepeatInfo,RampInfo
	Wave DefVolts_slow, ZSensorVolts_slow

	wave MVW = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	string suffixStr = num2strlen(MVW[%BaseSuffix][0],4)
	string AddComm="" 
	variable Index, ApproachDistance, ApproachTime, ApproachVelocity,ApproachDelay,RetractDistance,RetractVelocity,RetractDelay,sampleRate,dwellPoints0,ramppts
	String Indexes = "0," //Start the index and directions 
	String Directions = "0,"
	strswitch(RampInfo[0][0])
			variable RetractDistanceStep,RetractStepTime, RetractStepDelay,RetractStepNumber,RetractSpeed,TimeToStart,RetractStart,RetractEnd,SurfDwell
			variable 	RetractIterations,CurrIter,RetDwell
		case "Glide":

			ApproachDistance=str2num(RampInfo[1][0])  
			ApproachTime=str2num(RampInfo[2][0])
			ApproachVelocity=str2num(RampInfo[2][0])/str2num(RampInfo[1][0])*1e-3
			ApproachDelay=str2num(RampInfo[3][0])
			RetractDistance=str2num(RampInfo[4][0])  
			RetractVelocity=str2num(RampInfo[5][0])  
			RetractDelay=str2num(RampInfo[6][0])  
			sampleRate=str2num(RampInfo[7][0]) *1e3
			dwellPoints0 = round(RetractDelay*sampleRate)   
			ramppts= round((RetractDistance/RetractVelocity*1e-3)*sampleRate)-1
			Index = ramppts      //Counts out to one point less than where it triggered
			Indexes += num2istr(Index)+","
			Directions += num2str(-1)+","
			Index += DwellPoints0
			Indexes += num2istr(Index)+","
			Directions += "0,"
			AddComm = ReplaceStringbyKey("Indexes",AddComm,Indexes,":","\r")
			AddComm = ReplaceStringbyKey("Direction",AddComm,Directions,":","\r")
			AddComm = ReplaceStringbyKey("ApproachVelocity",AddComm,num2str(ApproachVelocity),":","\r")
			AddComm = ReplaceStringbyKey("ApproachDistance",AddComm,num2str(ApproachDistance),":","\r")
			AddComm = ReplaceStringbyKey("RetractDistance",AddComm,num2str(RetractDistance),":","\r")
			AddComm = ReplaceStringbyKey("RetractVelocity",AddComm,num2str(RetractVelocity),":","\r")
			AddComm = ReplaceStringbyKey("DwellTime",AddComm,num2str(ApproachDelay),":","\r")
			AddComm = ReplaceStringbyKey("DwellTime2",AddComm,num2str(RetractDelay),":","\r")
			AddComm = ReplaceStringbyKey("NumPtsPerSec",AddComm,num2str(sampleRate),":","\r")
			AddComm = ReplaceStringbyKey("Pull Speed (Pair)",AddComm,"Slow",":","\r")
			AddComm = ReplaceStringbyKey("Corresponding Fast Pull",AddComm,num2strlen(str2num(suffixStr)-1,4),":","\r")
			AddComm = ReplaceStringbyKey("Force Dist",AddComm,num2str(RetractDistance),":","\r")

			break
			
		case "Step Out":
		
			ApproachDistance=str2num(RampInfo[1][0])  
			ApproachTime=str2num(RampInfo[2][0])
			ApproachVelocity=str2num(RampInfo[2][0])/str2num(RampInfo[1][0])*1e-3
			ApproachDelay=str2num(RampInfo[3][0])
			RetractDistanceStep=str2num(RampInfo[4][0])  
			RetractStepTime=str2num(RampInfo[5][0])  
			RetractStepDelay=str2num(RampInfo[6][0])  
			RetractStepNumber=str2num(RampInfo[7][0])  
			sampleRate=str2num(RampInfo[7][0]) *1e3
			RetractDistance=str2num(RampInfo[7][0]) *str2num(RampInfo[4][0])  
			RetractVelocity=RetractDistance/((RetractStepDelay+RetractStepTime)*RetractStepNumber)*1e-3
			//variable dwellPoints0 = round(RetractDelay*sampleRate)   
			//variable ramppts= round((RetractDistance/RetractVelocity*1e-3)*sampleRate)-1
			Index=dimsize(DefVolts_slow,0)
			Indexes += num2istr(Index)+","
			Directions += "-1,"
			AddComm = ReplaceStringbyKey("Indexes",AddComm,Indexes,":","\r")
			AddComm = ReplaceStringbyKey("Direction",AddComm,Directions,":","\r")
			AddComm = ReplaceStringbyKey("ApproachVelocity",AddComm,num2str(ApproachVelocity),":","\r")
			AddComm = ReplaceStringbyKey("ApproachDistance",AddComm,num2str(ApproachDistance),":","\r")
			AddComm = ReplaceStringbyKey("RetractDistance",AddComm,num2str(RetractDistance),":","\r")
			AddComm = ReplaceStringbyKey("RetractVelocity",AddComm,num2str(RetractVelocity),":","\r")
			AddComm = ReplaceStringbyKey("DwellTime",AddComm,num2str(ApproachDelay),":","\r")
			AddComm = ReplaceStringbyKey("Retract Distance Step",AddComm,num2str(RetractDistanceStep),":","\r")
			AddComm = ReplaceStringbyKey("Retract Step Time",AddComm,num2str(RetractStepTime),":","\r")
			AddComm = ReplaceStringbyKey("Retract Step Delay",AddComm,num2str(RetractStepDelay),":","\r")
			AddComm = ReplaceStringbyKey("Retract Step Number",AddComm,num2str(RetractStepNumber),":","\r")
			AddComm = ReplaceStringbyKey("NumPtsPerSec",AddComm,num2str(sampleRate),":","\r")
			AddComm = ReplaceStringbyKey("Pull Speed (Pair)",AddComm,"Slow",":","\r")
			AddComm = ReplaceStringbyKey("Corresponding Fast Pull",AddComm,num2strlen(str2num(suffixStr)-1,4),":","\r")
			AddComm = ReplaceStringbyKey("Force Dist",AddComm,num2str(RetractDistance),":","\r")
		
			break
			
			
			
		case "MultiRamp":
			//		SetDimLabel 1,0,Values,RefoldSettings
			//	SetDimLabel 1,1,Desc,RefoldSettings
			//	SetDimLabel 1,2,Units,RefoldSettings
			//
			//	SetDimLabel 0,0,ExperimentName,RefoldSettings
			//	SetDimLabel 0,1,ApproachDistance,RefoldSettings
			//	SetDimLabel 0,2,ApproachTime,RefoldSettings
			//	SetDimLabel 0,3,ApproachDelay,RefoldSettings
			//	SetDimLabel 0,4,RetractStart,RefoldSettings
			//	SetDimLabel 0,5,RetractEnd,RefoldSettings
			//	SetDimLabel 0,6,TimeToStart,RefoldSettings
			//	SetDimLabel 0,7,RetractSpeed,RefoldSettings
			//	SetDimLabel 0,8,SurfDwell,RefoldSettings
			//	SetDimLabel 0,9,RetDwell,RefoldSettings
			//	SetDimLabel 0,10,RetractIterations,RefoldSettings
			//	SetDimLabel 0,11,CurrIter,RefoldSettings
			//	SetDimLabel 0,12,DataRate,RefoldSettings
			//	SetDimLabel 0,13,UltraFast,RefoldSettings
			
			wave/t RefoldSettings
			wave ZSensorVolts_fast=ZSensor_fast
			variable Datalength,startmultivolt,endmultivolt
			startmultivolt=ZsensorVolts_Fast[pcsr(A,"DE_CTFC_Control#MostRecent")]
			endmultivolt=ZsensorVolts_Fast[pcsr(B,"DE_CTFC_Control#MostRecent")]
			variable totaldistance=2*(endmultivolt-startmultivolt)*GV("ZLVDTSEns")
			DataLength=5e6*(abs(totaldistance)/(str2num(RefoldSettings[%RetractSpeed][0])*1e-6)+str2num(RefoldSettings[%SurfDwell][0])+str2num(RefoldSettings[%RetDwell][0]))
			variable decirate=50/str2num(RefoldSettings[%DataRate][0])
			variable outdecirate,endrmp1,endpause1,endrmp2,endpause2
			variable total2=round(1e3*str2num(RefoldSettings[%DataRate][0])*(abs(totaldistance)/(str2num(RefoldSettings[%Retractspeed][0])*1e-6)+str2num(RefoldSettings[%SurfDwell][0])+str2num(RefoldSettings[%RetDwell][0])))
//	
//if(total2<=5000) //checks if we exceed the limit for IR_xSetOutWave
		outdecirate=decirate
//		slope2=sign(totaldistance)*(str2num(RefoldSettings[%Retractspeed][0])/GV("ZLVDTSens")*1e-6)/(50e3/outdecirate)  //The Sign in front tells us if we're ramping negative or positive.
//		constant2=startmultivolt
		endrmp1=round(50e3/outdecirate*(abs(totaldistance)/(str2num(RefoldSettings[%Retractspeed][0])*1e-6)/2))
		endpause1=endrmp1+round(50e3/outdecirate*(str2num(RefoldSettings[%RetDwell][0])))
		endrmp2=endpause1+endrmp1
		endpause2=endrmp2+round(50e3/outdecirate*(str2num(RefoldSettings[%SurfDwell][0])))

//
//else
//		total2=5000
//		outdecirate=round(50000/total2*(abs(totaldistance)/(str2num(RefoldSettings[%Retractspeed][0])*1e-6)+str2num(RefoldSettings[%SurfDwell][0])+str2num(RefoldSettings[%RetDwell][0])))
//
//		endrmp1=round(50e3/outdecirate*(abs(totaldistance)/(str2num(RefoldSettings[%Retractspeed][0])*1e-6)/2))
////
//		endpause1=endrmp1+round(50e3/outdecirate*(str2num(RefoldSettings[%RetDwell][0])))
//		endrmp2=endpause1+endrmp1
//		endpause2=endrmp2+round(50e3/outdecirate*(str2num(RefoldSettings[%SurfDwell][0])))
//
////		
//endif
			
			
			
			
			Indexes = "0,"+num2str(endrmp1)+","+num2str(endpause1)+","+num2str(endrmp2)+","+num2str(endpause2)//Start the index and directions 
			Directions = "Inf,-1,0,1,0"
			ApproachDistance=str2num(RampInfo[%ApproachDistance][0])  
			ApproachTime=str2num(RampInfo[%ApproachTime][0])
			ApproachVelocity=str2num(RampInfo[%ApproachDistance][0])/str2num(RampInfo[%ApproachTime][0])*1e-3
			ApproachDelay=str2num(RampInfo[%ApproachDelay][0])
			RetractDistance=abs(totaldistance)/2
			TimeToStart=str2num(RampInfo[%TimeToStart][0])
			RetractStart=startmultivolt
			RetractEnd=endmultivolt
			
			SurfDwell=str2num(RampInfo[%SurfDwell][0])
			RetDwell=str2num(RampInfo[%RetDwell][0])
			RetractIterations=str2num(RampInfo[%RetractIterations][0])
			CurrIter=str2num(RampInfo[%CurrIter][0])

			sampleRate=str2num(RampInfo[%DataRate][0]) *1e3
			RetractVelocity=str2num(RampInfo[%RetractSpeed][0])
			//variable dwellPoints0 = round(RetractDelay*sampleRate)   
			//variable ramppts= round((RetractDistance/RetractVelocity*1e-3)*sampleRate)-1


			AddComm = ReplaceStringbyKey("Indexes",AddComm,Indexes,":","\r")
			AddComm = ReplaceStringbyKey("Direction",AddComm,Directions,":","\r")
			AddComm = ReplaceStringbyKey("ApproachVelocity",AddComm,num2str(ApproachVelocity),":","\r")
			AddComm = ReplaceStringbyKey("ApproachDistance",AddComm,num2str(ApproachDistance),":","\r")
			AddComm = ReplaceStringbyKey("RetractDistance",AddComm,num2str(RetractDistance),":","\r")
			AddComm = ReplaceStringbyKey("RetractVelocity",AddComm,num2str(RetractVelocity),":","\r")
			AddComm = ReplaceStringbyKey("DwellTime",AddComm,num2str(ApproachDelay),":","\r")
			AddComm = ReplaceStringbyKey("Time To Start",AddComm,num2str(TimeToStart),":","\r")
			AddComm = ReplaceStringbyKey("Retract Start",AddComm,num2str(RetractStart),":","\r")
			AddComm = ReplaceStringbyKey("Retract End",AddComm,num2str(RetractEnd),":","\r")
			AddComm = ReplaceStringbyKey("Surface Dwell",AddComm,num2str(SurfDwell),":","\r")
			AddComm = ReplaceStringbyKey("Retract Dwell",AddComm,num2str(RetDwell),":","\r")
			AddComm = ReplaceStringbyKey("Retract Iterations",AddComm,num2str(RetractIterations),":","\r")
			AddComm = ReplaceStringbyKey("Currrent Iteration",AddComm,num2str(CurrIter),":","\r")

			
			AddComm = ReplaceStringbyKey("NumPtsPerSec",AddComm,num2str(sampleRate),":","\r")
			AddComm = ReplaceStringbyKey("Pull Speed (Pair)",AddComm,"Slow",":","\r")
			AddComm = ReplaceStringbyKey("Corresponding Fast Pull",AddComm,num2strlen(str2num(suffixStr)-1,4),":","\r")
			AddComm = ReplaceStringbyKey("Force Dist",AddComm,num2str(RetractDistance),":","\r")
		
			break

	endswitch

	DE_SaveReg(DefVolts_slow,ZSensorVolts_slow,AdditionalNote=AddComm)
	
		
end	//DE_SlowPair

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//DE_SaveReg This saves the curves listed with whatever note you choose to add. This means it doesn't do the work for you, you have to write the note out yourself.
function DE_SaveReg(DefVolts,ZSensorVolts,[AdditionalNote])
	wave DefVolts
	Wave ZSensorVolts
	string AdditionalNote
	string CNote=""

	wavetransform/o zapNaNs DefVolts
	wavetransform/o zapNaNs ZSensorVolts
	duplicate/o ZSensorVolts Z_raw_save
	Fastop Z_raw_save=(GV("ZLVDTSens"))*ZSensorVolts
	SetScale d -10, 10, "m", Z_raw_save
	duplicate/o Z_raw_save Z_snsr_save
	duplicate/o DefVolts Def_save
	fastop Def_save=(GV("Invols"))*DefVolts
	SetScale d -10, 10, "m", Def_save
	 
	if (!ParamIsDefault(AdditionalNote) && Strlen(AdditionalNote))
		variable nop
		nop = ItemsInList(AdditionalNote,"\r")
		String CustomItem
		Variable n,A

		for (A = 0;A < nop;A += 1)
			CustomItem = StringFromList(A,AdditionalNote,"\r")
			n = strsearch(CustomItem,":",0,2)
	
			if (n < 0)
				Continue
	
			endif
	
			CNote = ReplaceStringByKey(CustomItem[0,n-1],CNote,Customitem[n+1,Strlen(CustomItem)-1],":","\r",0)
		
		endfor
	
	endif
	
	string indexes=StringByKey("Indexes", CNote,":","\r")
	string Directions=StringByKey("Directions",Cnote,":","\r")
	string ForceDist=StringByKey("ForceDist",Cnote,":","\r")
	MakeZPositionFinal(Z_Snsr_save,ForceDist=str2num(ForceDist),indexes=indexes,DirInfo=Directions)	
	ARSaveAsForce(3,"SaveForce","Defl;ZSnsr",Z_raw_save,Def_save,Z_snsr_save,$"",$"",$"",$"",CustomNote=CNote)
	killwaves Z_raw_save, Z_snsr_save,Def_save
			
end // DE_SaveReg()

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//DE_UpdatePlot
function DE_UpdatePlot(Desc)
	string Desc
	wave/t RefoldSettings
	wave/Z DetrendFit
	if(waveexists(root:DE_CTFC:MenuStuff:Display_DefV_1)==0)
		return -1		
	endif
	
	if(waveexists(root:DE_CTFC:MenuStuff:DetrendFit)==0)
	else
	if(strsearch(tracenamelist("DE_CTFC_Control#MostRecent","",1),"DetrendFit",0)==-1) 
		appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:DetrendFit 
		ModifyGraph/W=DE_CTFC_Control#MostRecent hideTrace(DetrendFit)=1

	else
		ModifyGraph/W=DE_CTFC_Control#MostRecent hideTrace(DetrendFit)=1

	endif
	endif
	
	strswitch(Desc)
			
		case "No Trigger":
					make/o/n=0 root:DE_CTFC:MenuStuff:Display_DefV_1,root:DE_CTFC:MenuStuff:Display_ZSensor_1	
					duplicate/o root:DE_CTFC:DefV_Fast root:DE_CTFC:MenuStuff:Display_DefV_1
					duplicate/o root:DE_CTFC:ZSensor_Fast root:DE_CTFC:MenuStuff:Display_ZSensor_1
					ModifyGraph/W=DE_CTFC_Control#MostRecent hideTrace(Display_DefV_1)=0,hideTrace(Display_DefV_2)=1
					SetAxis/A/W=DE_CTFC_Control#MostRecent		
					break
				
				case "Triggered 1":
					make/o/n=0 root:DE_CTFC:MenuStuff:Display_DefV_1,root:DE_CTFC:MenuStuff:Display_ZSensor_1	
					duplicate/o root:DE_CTFC:DefV_Fast root:DE_CTFC:MenuStuff:Display_DefV_1
					duplicate/o root:DE_CTFC:ZSensor_Fast root:DE_CTFC:MenuStuff:Display_ZSensor_1
					ModifyGraph/W=DE_CTFC_Control#MostRecent hideTrace(Display_DefV_1)=0,hideTrace(Display_DefV_2)=1
					SetAxis/A/W=DE_CTFC_Control#MostRecent	
					break
				
				case "Triggered Done":
					make/o/n=0 root:DE_CTFC:MenuStuff:Display_DefV_2,root:DE_CTFC:MenuStuff:Display_ZSensor_2	
					duplicate/o root:DE_CTFC:DefV_Slow root:DE_CTFC:MenuStuff:Display_DefV_2
					duplicate/o root:DE_CTFC:ZSensor_Slow root:DE_CTFC:MenuStuff:Display_ZSensor_2
					ModifyGraph/W=DE_CTFC_Control#MostRecent hideTrace(Display_DefV_1)=0,hideTrace(Display_DefV_2)=0
					SetAxis/A/W=DE_CTFC_Control#MostRecent
					DoUpdate/W=DE_CTFC_Control#MostRecent
					break
				
				case "Detrend":
					make/o/n=0 root:DE_CTFC:MenuStuff:Display_DefV_1,root:DE_CTFC:MenuStuff:Display_ZSensor_1	
					duplicate/o root:DE_CTFC:DefV_Fast root:DE_CTFC:MenuStuff:Display_DefV_1
					duplicate/o root:DE_CTFC:ZSensor_Fast root:DE_CTFC:MenuStuff:Display_ZSensor_1
					ModifyGraph/W=DE_CTFC_Control#MostRecent hideTrace(Display_DefV_1)=0,hideTrace(Display_DefV_2)=1
					ModifyGraph/W=DE_CTFC_Control#MostRecent hideTrace(DetrendFit)=0
					ModifyGraph/W=DE_CTFC_Control#MostRecent	lsize(DetrendFit)=2,rgb(DetrendFit)=(58368,6656,7168)

					SetAxis/A/W=DE_CTFC_Control#MostRecent	
					break
				
				default:
	
	endswitch
						DoUpdate/W=DE_CTFC_Control#MostRecent	

	
	
	return 0
end //DE_UpdatePlot

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DE_RamptoVol(PVol,State,Callback)
	variable PVol ///This is the voltage we will ramp to. It's important that this is already a voltage.
	string State,Callback
	string Fullcallback1
	Fullcallback1="DE_RamptoVol(0,\"Done\",\""+Callback+"\")"

	strswitch(State)
	
		case "Start":
			//Setup a feedback loop. I am using loop 5, which is the same as I use for the extension ramp normally. This 
			//is reset each time, so it should work OK.
			variable curpos= td_ReadValue("Zsensor")

			Struct ARFeedbackStruct FB
			ARGetFeedbackParms(FB,"Z")
			FB.Bank = 5
			FB.Setpoint = NaN
			FB.DynamicSetpoint = 1
			FB.LoopName = "DwellLoop2"
			FB.StartEvent = "8"		//Using a different start event just in case!
			FB.StopEvent = "Never"
			ir_WritePIDSloop(FB)
			make/o/n=500 RampVolt
			RampVolt=(PVol-curpos)/499*x+ curpos  //This rights the wave to take us from FB.SetPoint to PVol
			IR_xSetOutWave(2,"8","$DwellLoop2.Setpoint",RampVolt,Fullcallback1,10)  
			td_WS("Event.8","Once")

			break
	
		Case "Done":
			ir_StopPISloop(5)  //Halt the feedback loop.
			killwaves RampVolt
			execute/Q Callback
			break
	
		Default:
	
	endswitch


end

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//	This is just my personalized version of the Asylum program MAPFastCaptureCallback(). I have altered the callback structure so that
//	the fast data can be properly grabbed, and then call the next step in the progamming.
Function DE_MAPFastCaptureCallback(Action,SaveFast)
	String Action
	variable SaveFast
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	String CallBackStr, ErrorStr = ""
	Wave DestWave = root:FastCaptureData
	
	StrSwitch (Action)
		Case "Error":		//	There was an error in fast capture setup
			print "There was a problem - check the error log."
			MasterARGhostFunc("","MAPFastCaptureGo")
			break
			
		Case "Read":	//	Read the fast capture buffer, then call this function again to tell it we're done.
			CallBackStr = "DE_MAPFastCaptureCallback(\"ReadDone\","+num2str(SaveFast)+")"
			//CallBackStr="HEYO"
			ErrorStr = num2str(td_ReadCapture("Cypher.Capture.0", DestWave, CallBackStr)) + ","
			If ( ARReportError(ErrorStr) )
				DE_MAPFastCaptureCallback("Error",SaveFast)
			EndIf
			break
			
		Case "ReadDone":	//	Fast capture read-back completed
			//	Display the data if it's not already visible
			NVAR IsFastCapture = $InitOrDefault("root:packages:MAPIsFastCapture",0)
			variable zerovolt,Pvol,rep
			wave ZSensorVolts_fast=ZSensor_fast
			wave/t RefoldSettings
			STRING CorrectionIteration
			IsFastCapture = 0
			
				if(SaveFast==1||SaveFast==3)
							
					MakeWaitPanel("Saving data.")
					DoUpdate
					Wave/Z Data = root:FastCaptureData  
					Duplicate/FREE Data,xWave
					Ax2Wave(Data,0,xWave)
					ARSaveAsForce(1 | (GV("SaveForce") & 2),"SaveForce","Time;DeflV;",xWave,xWave,Data,$"", $"",$"",$"")
					KillUpdateWaitingPanel()
	
				endif	
					
					
				if(SaveFast==2||SaveFast==3)
	
					MakeWaitPanel("Saving data.")
					note/K DestWave "Spring Constant: "+num2str(GV("SpringConstant"))+";"
					note DestWave "Invols: "+num2str(GV("InvOLS"))+";"
					note DestWave "Date: "+date()+";"
					note DestWave "Time: "+time()+";"
					note DestWave "BaseSuffix: "+DE_PreviousForceRamp()+";"
	
					Print "Saving Fast Capture to Disk"
					string Pathname,SaveName
	
					strswitch(RefoldSettings[%ExperimentName][0])//Right now every program except Multiramp can just launch. multiRamp does it's own thing.
	
						case "Glide":
							PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
	
							SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+".pxp"
	
							break
				
						case "Step Out":
							PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
							SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+".pxp"
	
							break
							
						case "SOEquil":
							PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
							SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+".pxp"
	
							break
				
						case "MultiRamp":
							CorrectionIteration=RefoldSettings[%CurrIter]
							note DestWave "Iteration="+CorrectionIteration+";"
							PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
							SaveName=DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+CorrectionIteration+".pxp"
	
							break
				
						case "MultiRampOL":
							CorrectionIteration=RefoldSettings[%CurrIter]
							note DestWave "Iteration="+CorrectionIteration+";"
							PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
							SaveName=DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+CorrectionIteration+".pxp"
	
							break
					endswitch 
			print "pathname"
					print PathName
	
					NewPath/O/C/Q/Z FastCapturePath,PathName
					//Save/C/P=FastCapturePath DefVFast as SaveName
					SetDataFolder root:
					SaveData/L=1/Q/P=FastCapturePath SaveName
					SetDataFolder root:DE_CTFC
	
					KillUpdateWaitingPanel()
	
				endif

			//KilLWindow FastCaptureData	
			strswitch(RefoldSettings[%ExperimentName][0])//Right now every program except Multiramp can just launch. multiRamp does it's own thing.

			case "Glide":
				DE_FastDone_Glide()
			break
			
			case "Step Out":
				DE_FastDone_Glide() //Here we can just use the same reset as the glide.
			break
			
			case "SOEquil":
				DE_FastDone_SOEquil()
			break
		
			case "MultiRamp":
				DE_FastDone_MultiRamp()
			break
			
			case "MultiRampOL":
				DE_FastDone_MultiRampOL()
			break
	endswitch 


			break
			
	EndSwitch
End //DE_MAPFastCaptureCallback








//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function DE_UpdateDeTrend(State)
	String State
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	wave/t RampSettings
	td_ReadGroup("ARC.CTFC",TriggerInfo)
	variable endtime,endpnt,fitend,fitendtime
	//wave Zsensor_Fast,Defv_Fast
	wave ArcY,ArcX
	ArcY+=0//Just updates the ARCY
	wave/t RampInfo
	fitendtime=str2num(TriggerInfo[%TriggerTime1])
	fitend=x2pnt(ArcX,fitendtime)
	endtime=str2num(TriggerInfo[%TriggerTime1])-(str2num(RampSettings[2][0])*1e-12/GV("SpringConstant")+1e-8)/str2num(RampSettings[0][0])/1e-6
	endpnt=x2pnt(ArcX,endtime)


	Strswitch(State)
		case "New":
			make/o/n=7 Wparms
			WParms=0
			DE_FindDetrendParms(ArcY,ArcX,0,endpnt,endpnt,wparms)
		break
		case "Update":
			duplicate/o wparms wparms1
		
			WParms1=0
			DE_FindDetrendParms(ArcY,ArcX,0,endpnt,endpnt,wparms1)
			Wparms+=wparms1
		killwaves wparms1
		break
		default:
		
		
	endswitch
	
	if(waveexists(Wparms)==0)
		
	else
		make/o/n=7 Wparms1
		
	endif
	td_stopdetrend()
	td_SetDetrend("ZSensor", Wparms, "arc.input.A")

end

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DE_FindDetrendParms(wdefl,wzsensor,pstart,pend,fitend,wparms)
wave wdefl,wzsensor
variable pstart,pend,fitend
wave wparms

wavestats/q wparms
variable n=v_npnts
duplicate/o wdefl FitCase
FitCase[pend,]=wdefl[pend]
CurveFit/X=1/Q/NTHR=0 poly n,  FitCase[0,fitend] /X=wzsensor/D
duplicate/o fit_fitcase root:DE_CTFC:MenuStuff:DetrendFit
wave W_coef
wparms=W_coef
KillWaves  W_coef,W_sigma,W_ParamConfidenceInterval
//killwaves FitCase

end

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function/S DE_PreviousForceRamp()
	SVAR gBaseName = root:Packages:MFP3D:Main:Variables:BaseName
	wave MVW = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	Variable Suffix = MVW[%BaseSuffix][0]-1
	String CurrentIterationStr
	sprintf CurrentIterationStr, "%04d", Suffix

	String RampName=gBaseName+CurrentIterationStr
	Return RampName

end

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


function DE_Outdecirate(ExpName)
	string ExpName
	wave/t RefoldSettings
	variable total2,outdecirate,decirate,newrate
	variable	startmultivolt,endmultivolt,totaldistance,singledistance,rdecirate
	decirate=50/str2num(RefoldSettings[%DataRate][0])
	wave ZSensorVolts_fast=ZSensor_fast
	if (cmpstr(ExpName,"")==0)
		ExpName=RefoldSettings[%ExperimentName][0]

	endif
	
	strswitch(ExpName)
		
		case "Glide":

			total2=round(str2num(RefoldSettings[%DataRate][0])*( str2num(RefoldSettings[%RetractDistance][0])/str2num(RefoldSettings[%RetractSpeed][0])+str2num(RefoldSettings[%RetractPause][0])*1e3 ) )
			if(total2<=5000) //checks if we exceed the limit for IR_xSetOutWave
				outdecirate=decirate
			
			else	//If we do, run with as high a bandwidth as we can while limitting the total points to 87000
			
				total2=5000
				newrate=round(total2/(str2num(RefoldSettings[%RetractDistance][0])/str2num(RefoldSettings[%RetractSpeed][0])*1e-3+str2num(RefoldSettings[%RetractPause][0])))/1e3
				rdecirate=floor(50/newrate)
				newrate=50/rdecirate
				outdecirate=50/newrate
		
				//total2=5000
				//outdecirate=round(50000/total2*(str2num(RefoldSettings[%RetractDistance][0])/str2num(RefoldSettings[%RetractSpeed][0])*1e-3+str2num(RefoldSettings[%RetractPause][0])))
			endif

			break
		
		case "Step Out":

			total2=round( 1e3*str2num(RefoldSettings[%DataRate][0])*(str2num(RefoldSettings[%RetractStepNumber][0])*(str2num(RefoldSettings[%RetractStepTime][0])+str2num(RefoldSettings[%RetractStepPause][0])) ))

			if(total2<=50000) //checks if we exceed the limit for IR_xSetOutWave
				outdecirate=decirate

			else
			
					total2=50000
					newrate=round(total2/str2num(RefoldSettings[%RetractStepNumber][0])/(str2num(RefoldSettings[%RetractStepTime][0])+str2num(RefoldSettings[%RetractStepPause][0])))/1e3
					rdecirate=floor(50/newrate)
					outdecirate=rdecirate
				
			endif
			

			break
			
		case "SOEquil":

			startmultivolt=ZsensorVolts_Fast[pcsr(A,"DE_CTFC_Control#MostRecent")]
			endmultivolt=ZsensorVolts_Fast[pcsr(B,"DE_CTFC_Control#MostRecent")]
			totaldistance=(endmultivolt-startmultivolt)*GV("ZLVDTSEns")
			variable Dirs=sign(totaldistance)
			variable 	stepsize=str2num(RefoldSettings[%RetractStepSize][0])
			variable datarate=str2num(RefoldSettings[%DataRate][0])
			variable steptime=str2num(RefoldSettings[%RetractStepTime][0])
			variable pausetime=str2num(RefoldSettings[%RetractDwellTime][0])
			variable steps=ceil(abs(totaldistance)/stepsize*1e9)
			variable totalsteptime=pausetime+steptime	
			decirate=50/str2num(RefoldSettings[%DataRate][0])
			total2=round(1e3*datarate*(steps)*(totalsteptime))
	
			if(total2<=50000) //checks if we exceed the limit for IR_xSetOutWave
				outdecirate=decirate

			else
				total2=50000
				newrate=round(total2/steps/totalsteptime)/1e3
				rdecirate=floor(50/newrate)
				newrate=50/rdecirate
				outdecirate=50/newrate
			endif
			break
		
		case "SOEquilFinal":
			total2=round(str2num(RefoldSettings[%DataRate][0])*1e3*( str2num(RefoldSettings[%FinalDistance][0])/str2num(RefoldSettings[%FinalVelocity][0])))
			decirate=50/str2num(RefoldSettings[%DataRate][0])
			if(total2<=5000) //checks if we exceed the limit for IR_xSetOutWave
				outdecirate=decirate

			else	//If we do, run with as high a bandwidth as we can while limitting the total points to 87000
				
				total2=5000
				newrate=round(total2/(str2num(RefoldSettings[%FinalDistance][0])/str2num(RefoldSettings[%FinalVelocity][0])*1e-3))/1e3
				rdecirate=floor(50/newrate)
				newrate=50e3/rdecirate
				outdecirate=50e3/newrate
			endif

			break
		
		case "MultiRamp":
			startmultivolt=ZsensorVolts_Fast[pcsr(A,"DE_CTFC_Control#MostRecent")]
			endmultivolt=ZsensorVolts_Fast[pcsr(B,"DE_CTFC_Control#MostRecent")]
			totaldistance=2*(endmultivolt-startmultivolt)*GV("ZLVDTSEns")
						
			decirate=50/str2num(RefoldSettings[%DataRate][0])
			total2=round(1e3*str2num(RefoldSettings[%DataRate][0])*(abs(totaldistance)/(str2num(RefoldSettings[%Retractspeed][0])*1e-6)+str2num(RefoldSettings[%SurfDwell][0])+str2num(RefoldSettings[%RetDwell][0])))

	
			if(total2<=5000) //checks if we exceed the limit for IR_xSetOutWave
				outdecirate=decirate

			else
				total2=5000
				outdecirate=round(50000/total2*(abs(totaldistance)/(str2num(RefoldSettings[%Retractspeed][0])*1e-6)+str2num(RefoldSettings[%SurfDwell][0])+str2num(RefoldSettings[%RetDwell][0])))
			endif
			break
			
			
				
		case "MultiRampOL":
			startmultivolt=ZsensorVolts_Fast[pcsr(A,"DE_CTFC_Control#MostRecent")]
			endmultivolt=ZsensorVolts_Fast[pcsr(B,"DE_CTFC_Control#MostRecent")]
			decirate=50/str2num(RefoldSettings[%DataRate][0])
			variable LVDTDelta=(startmultivolt-endmultivolt)
			singledistance=(LVDTDelta)*GV("ZLVDTSEns")
			total2=round(1e3*str2num(RefoldSettings[%DataRate][0])*(abs(singledistance)/(str2num(RefoldSettings[%Retractspeed][0])*1e-6)+abs(singledistance)/(str2num(RefoldSettings[%Approachspeed][0])*1e-6)+str2num(RefoldSettings[%SurfDwell][0])+str2num(RefoldSettings[%RetDwell][0])))			
	
			if(total2<=5000) //checks if we exceed the limit for IR_xSetOutWave
				outdecirate=decirate

			else
				total2=5000
				outdecirate=round(50000/total2*(abs(singledistance)/(str2num(RefoldSettings[%Retractspeed][0])*1e-6)+abs(singledistance)/(str2num(RefoldSettings[%Approachspeed][0])*1e-6)+str2num(RefoldSettings[%SurfDwell][0])+str2num(RefoldSettings[%RetDwell][0])))
			endif
			break
			
			
	
		
		case "MultiRampFinal":
			total2=round(str2num(RefoldSettings[%DataRate][0])*1e3*( str2num(RefoldSettings[%FinalDistance][0])/str2num(RefoldSettings[%FinalVelocity][0])))
			decirate=50/str2num(RefoldSettings[%DataRate][0])
			if(total2<=5000) //checks if we exceed the limit for IR_xSetOutWave
				outdecirate=decirate

			else	//If we do, run with as high a bandwidth as we can while limitting the total points to 87000
				total2=5000
				newrate=round(total2/(str2num(RefoldSettings[%FinalDistance][0])/str2num(RefoldSettings[%FinalVelocity][0])*1e-3))
				outdecirate=50e3/newrate
			endif

			break
			
	endswitch

	return outdecirate
end

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DE_PolyCorr(x,y)
variable x,y
	wave/t RampSettings
if(cmpstr(RampSettings[%Detrend][0],"No")==0)
return y
endif
wave Wparms

return y-(wparms[0]+wparms[1]*x+wparms[2]*x^2+wparms[3]*x^3+wparms[4]*x^4+wparms[5]*x^5+wparms[6]*x^6)

end

function/C DE_AverageChan(bank,channel,[callback,decimation,points])
	variable bank,decimation,points
	string channel,callback
	variable n=0
	variable/c Result
	if( ParamIsDefault(callback) )
		callback="	killwaves Hold"
	endif
		
	if(ParamIsDefault(decimation))
		decimation=50
	endif
	if( ParamIsDefault(points))
		points=150

	endif
	td_WS("Event.1","Clear")		
	make/o/n=(points), Hold
	IR_XSetInWave(bank,"1",channel,Hold,callback,decimation)
	td_WS("Event.1","Once")		
	do
		sleep/s 0.025
		n+=1
	while(Hold[points-1]==0&&n<=10)
	td_WS("Event.1","Clear")	
	wavestats/q Hold
	result=cmplx(v_avg,v_sdev)


	return Result
end

function DE_PIS_ZeroSetpointOffset(bank,Name)
	variable bank
	string Name
	if(bank!=0&&bank!=1&&bank!=2&&bank!=3&&bank!=4&&bank!=5)
		print "Invalid Bank"
		return -1
	endif
	variable Error
	variable offset
	variable set
	set=(td_rv("PIDSLoop."+num2str(bank)+".SetPoint"))
	offset=(td_rv("PIDSLoop."+num2str(bank)+".SetPointOffSet"))


	set+=offset

	Make/O/T ZFeedbackParm
	
	error += td_RG("ARC.PIDSLoop."+num2str(bank), ZFeedbackParm)
	//
	//ZFeedbackParm[%InputChannel] = "ZSensor"
	//ZFeedbackParm[%OutputChannel] = "Output.Z"
	//ZFeedbackParm[%DynamicSetpoint] = "Yes"
	//ZFeedbackParm[%Setpoint] = num2str(set)
	//ZFeedbackParm[%Setpoint] = "NaN"
	//ZFeedbackParm[%SetpointOffset] = "0 V"
	//ZFeedbackParm[%DGain] = "0"
	//ZFeedbackParm[%PGain] = "0"
	//ZFeedbackParm[%IGain] = "125890"
	//ZFeedbackParm[%SGain] = "44.668"
	//ZFeedbackParm[%StartEvent] = "3"
	//ZFeedbackParm[%StopEvent] = "2;4"
	//ZFeedbackParm[%Status] = "1"
	Struct ARFeedbackStruct FB
	ARGetFeedbackParms(FB,"Z")
	FB.Bank = bank
	FB.Setpoint = set
	FB.SetpointOffset = 0
	FB.DynamicSetpoint =0
	FB.LoopName = Name
	FB.StartEvent = ZFeedbackParm[%StartEvent]
	FB.StopEvent = ZFeedbackParm[%StopEvent]
	ir_StopPISloop(bank) 

	ir_WritePIDSloop(FB)
	td_ws("Event."+ZFeedbackParm[%StartEvent],"once")
///	error += td_WG("ARC.PIDSLoop."+num2str(bank), ZFeedbackParm)

	if (error)
		print "TurnOnZFeedback: error in one of the td_ functions", error
	endif




end


Function/S DE_DateStringForSave()
	String ARDate=ARU_Date()
	Return StringFromList(0, ARDate,"-")[2,3]+StringFromList(1, ARDate,"-")+StringFromList(2, ARDate,"-")
End

Function/S DE_TimeStringForSave()
	String TimeString=Time()
	Return StringFromList(0, TimeString,":")+StringFromList(1, TimeString,":")+StringFromList(1,StringFromList(2, TimeString,":")," ")
End



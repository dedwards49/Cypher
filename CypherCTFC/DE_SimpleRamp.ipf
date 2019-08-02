#pragma rtGlobals=1		// Use modern global access method.
#pragma modulename=DE_SimpleRamp


//// DE_GrabExistingCTFCparms imports the existing CTFC parameter group.  Makes it easier to write CTFC parameters without errors
Static Function GrabExistingCTFCparms()

	Make/O/T root:DE_CTFC:TriggerSettings
	Variable error=0
	error+=td_ReadGroup("ARC.CTFC",root:DE_CTFC:TriggerSettings)
	return error

End //DE_GrabExistingCTFCparms()
//
////--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//
//// DE_LoadCTFCparms function sets up the CTFC ramp parameters. It takes the information from the input wave RampSettings and Refold Settings
Static Function LoadCTFCparms(RampSettings)
	Wave/T RampSettings
	Variable SurfaceTrigger,MoleculeTrigger, ApproachSpeed, RetractSpeed, NoTriggerTime,MaxZVolt
	String RetractTriggerChannel,ApproachTriggerChannel,RetractTrigRel,ApproachTrigRel,RampChannel
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	String ErrorStr = ""
	
	RampChannel =  "Output.Z"
	ApproachTriggerChannel=RampSettings[%SurfaceTriggerChannel][0]   //sets the first trigger channel. This will presumably often be deflection (to first touch of the surface), but could be something else
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
	TriggerInfo[%TriggerChannel2] = "ZSensor"
	
	strswitch(TriggerInfo[%TriggerChannel2] )  //A switch to properly define the trigger levels (in voltage) based on the channel used for the second trigger.
		
		case "output.Dummy":  
			MoleculeTrigger=0 //Is Ignored anyway
			RetractTrigRel="Relative Start" //Is ignored anyway
			MoleculeTrigger=str2num(RampSettings[%RetractDistance][0])*1e-9+str2num(RampSettings[%RetractDistance][0])*1e-12/GV("SpringConstant")
			print MoleculeTrigger
			MoleculeTrigger= -1*MoleculeTrigger/GV("ZPiezoSens")  
			print MoleculeTrigger
			break
		case "ZSensor":
			MoleculeTrigger=str2num(RampSettings[%RetractDistance][0])*1e-9+str2num(RampSettings[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")  //Add the approximate distance from the surface we need.
			MoleculeTrigger= -1*MoleculeTrigger/GV("ZLVDTSens") //How far to move converted from nm to Volts
			RetractTrigRel="Relative Ramp Start" //Sets the approach trigger to be relative to the start the second ramp (i.e. compare to the trigger position).
			break
		default:
			print "Trigger channel not recognized"  //Abort out if the channel is poorly defined.
			abort
	endswitch

	RetractSpeed = -1*str2num(RampSettings[4][0])*1e-6/GV("ZPiezoSens") //set the retract speed by converting from um/s to V/s. Note this is negative to retract from the surface.

	TriggerInfo[%RampChannel] = RampChannel
	TriggerInfo[%RampOffset1] = num2str(150) //Max Z Piezo (in volts) on initial push
	TriggerInfo[%RampSlope1] = num2str(ApproachSpeed)  //Z Piezo Volts/s
	TriggerInfo[%RampOffset2] = "-30" //Max Z Piezo (in volts) on initial retraction.This retracts to the initial starting point. 
	TriggerInfo[%RampSlope2] = num2str(RetractSpeed) //Z Piezo Volts/s
	TriggerInfo[%TriggerChannel1] = ApproachTriggerChannel
	TriggerInfo[%TriggerValue1] = num2str(SurfaceTrigger) //Deflection Volts
	TriggerInfo[%TriggerCompare1] = ">="
	
	TriggerInfo[%TriggerValue2] = num2str(MoleculeTrigger) 
	TriggerInfo[%TriggerCompare2] = "<="
	TriggerInfo[%TriggerHoldoff2] = num2str(0)//I set this large so that it doesn't get tickled.
	TriggerInfo[%DwellTime1] = RampSettings[%SurfaceDwellTime][0]
	TriggerInfo[%DwellTime2] = RampSettings[%RetractDwellTime][0]
	TriggerInfo[%EventDwell] = "4,6"
	TriggerInfo[%EventRamp] = "3,5"
	TriggerInfo[%EventEnable] = "2"
	TriggerInfo[%CallBack] = RampSettings[%CallBack][0]
	TriggerInfo[%TriggerType1] = ApproachTrigRel
	TriggerInfo[%TriggerType2] = RetractTrigRel
	
	ErrorStr += num2str(td_WriteString("Event.5","Clear"))+","
	ErrorStr += num2str(td_WriteString("Event.3","Clear"))+","
	ErrorStr += num2str(td_writeGroup("ARC.CTFC",TriggerInfo))+","
	
	//This sets up an extension feedback servo to engage only during the surface pause (i.e. between the firing of event 4 and event 5). This is setup on channel 4 of the PID loop
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


////--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


//// DE_SetInWavesFromCTFC(): Setup Inwaves for Force Ramp.  I'm using bank 0 for deflection and z sensor waves.  This is set to event 2. The input wave of RampInfo provides the ramp parameters that have been input
////(specifically, this provides the sampling rate and trace length). The input string Experiment provides some string keywords to identify what sort of readout we want, and how to call the data done parameter at the end.
Static Function SetInWavesFromCTFC(RampInfo,)
	wave/t RampInfo
	wave customwave1
	variable decirate,total1,newrate
	
	//This makes and assigns the waves for reading the "fast" portion of the scan, which is the first pull.
	Make/o/N=(str2num(RampInfo[%SampleRate][0])*str2num(RampInfo[%TotalTime][0])*1000)/O ZSensor_Retract,DefV_Retract 
	IR_XSetInWavePair(1,"2","Deflection",DefV_Retract,"Cypher.LVDT.Z",ZSensor_Retract,"",50/str2num(RampInfo[%SampleRate][0]))
	


	td_wv("Cypher.Input.FastA.Filter.Freq",str2num(RampInfo[%SampleRate][0])/2*1e3)  //This sets the filter to be at half the sample rate for anti-aliasing.
	td_wv("Arc.Input.A.Filter.Freq",str2num(RampInfo[%SampleRate][0])/2*1e3) //This does the same for the CTFC panel. However, I think it would be wise to filter this channel more.
	ReadFilterValues(3) //This updates the filter settings in Igor (I think)
		
end//DE_SetInWavesFromCTFC

////DE_StartCTFC() Starts the first CTFC each and every time. This is the main one!
Static Function StartSimpleRamp()
		
	if(Exists("root:DE_CTFC:MenuStuff:Stop")==2)//Checks if someone hit "stop next" if so, runs stop.
		SVar T=root:DE_CTFC:MenuStuff:Stop
		if(cmpstr(T,"Yes")==0)
			td_stopdetrend(1)
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


	GrabExistingCTFCParms()
	LoadCTFCParms(RampSettings)
	SetInWavesFromCTFC(RampSettings)
	
	Variable Error = 0
	
	Error += td_WS("Event.2","Clear")	
	Error += td_WS("Event.3","Clear")	
	Error += td_WS("Event.4","Clear")	
	Error += td_WS("Event.5","Clear")	
	Error += td_WS("Event.6","Clear")		

	Error += td_WS("Event.2","Once")		//Fires event.2, this starts everything!
	DE_TriggeredForcePanel#UpdateCommandOut("Begin Approach","Add")
	If (Error > 0)
		print "Error in StartMyCTFC"
	Endif

End //DE_StartCTFC()
//
////--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//

////DE_CTFCCB_TFE is the callback for the CTFC, If the CTFC does not find a molecule then this is what handles redisplaying the data and repeating the experimen as desired.
Static Function SimpleForceCallback() 
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	td_ReadGroup("ARC.CTFC",TriggerInfo)
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave/t RampInfo=root:DE_CTFC:RampSettings
	wave Zsensor_retract
	variable zerovolt,Pvol,rep
	td_stopinwavebank(1)
	zerovolt=(Zsensor_retract(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
	PVol=Zerovolt-str2num(RampInfo[%StartDistance][0])*1e-9/GV("ZLVDTSEns")
	DE_SimpleRamp#UpdatePlot()
	DE_SimpleRamp#SaveWave()
	rep=DE_SimpleRamp#RepCheck()
	DE_RamptoVol(PVol,"Start","DE_Simpleramp#LoopRepeater(\\\""+num2str(rep)+"\\\")")
				
End //DE_CTFCCB_FE_Halt


////--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//
////DE_LoopRepeater()

Static Function RepCheck()

	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings

	variable adding
	
	if(cmpstr(RepeatInfo[0][0],"Yes")==0)   //If we want to repeat.
			
			adding=str2num(RepeatInfo[6][0])+1  //Calculate the new number of iteration
			RepeatInfo[%Currentloops][0]=num2str(adding)  // Insert it into the Repeat loop.

			return 1
		else //If we don't want to repeat
				
		return 0

		endif
end


Static function LoopRepeater(rep)
	string rep
	if(cmpstr(Rep,"1")!=0)
		return -1
	endif
		wave/t RepeatInfo=root:DE_CTFC:RepeatSettings
		variable add,PVol,zerovolt
		string Command

		if(str2num(RepeatInfo[%CurrentLoops][0])<str2num(RepeatInfo[%TotalLoops][0]))  //Checks if the total number of iterations at this spot has been exceeded
			Command="StartSimpleRamp()"
			DE_TriggeredForcePanel#UpdateCommandOut(Command,"Clear")
			StartSimpleRamp()    //If not, then just run again!

		else

			RepeatInfo[%CurrentLoops][0]="0"   //Reset the iterations

			if((str2num(RepeatInfo[%CurrentSpot][0])+1)<str2num(RepeatInfo[%TotalSpots][0]))  //Checks if the total number of spots has been exceeded
	
				Command="Finding Next Spot"
				DE_TriggeredForcePanel#UpdateCommandOut(Command,"Clear")
				zerovolt=td_rv("Zsensor")
				PVol=Zerovolt-500*1e-9/GV("ZLVDTSEns")
				td_stopdetrend(1)
				Command="Retracting"
				DE_TriggeredForcePanel#UpdateCommandOut(Command,"Add")
				DE_RamptoVol(PVol,"Start","NextSpot()")
			

			else
		
				RepeatInfo[%CurrentSpot][0]="0" //We reset the current spot back to zero and quick
				td_stopdetrend(1)
				//Print "All Spots and Iterations Done"  
				Command="All Spots and Iterations Done"
				DE_TriggeredForcePanel#UpdateCommandOut(Command,"Replace")

			endif
	
		endif

end //DE_LoopRepeater

//-------------------------------------------------------------------------------------------------------------------------------------------------
Static function UpdatePlot()
	string Desc
	wave/t RefoldSettings
	wave/Z DetrendFit

	if(waveexists(root:DE_CTFC:MenuStuff:Display_DefV_1)==0)
		return -1		
	endif
	
	if(strsearch(tracenamelist("DE_CTFC_Control#MostRecent","",1),"DetrendFit",0)==-1) 
	else
		ModifyGraph/W=DE_CTFC_Control#MostRecent hideTrace(DetrendFit)=1
	endif

	duplicate/o root:DE_CTFC:DefV_Retract root:DE_CTFC:MenuStuff:Display_DefV_1
	duplicate/o root:DE_CTFC:ZSensor_Retract root:DE_CTFC:MenuStuff:Display_ZSensor_1
	ModifyGraph/W=DE_CTFC_Control#MostRecent hideTrace(Display_DefV_1)=0,hideTrace(Display_DefV_2)=1
	SetAxis/A/W=DE_CTFC_Control#MostRecent
	DoUpdate/W=DE_CTFC_Control#MostRecent
					
	duplicate/o root:DE_CTFC:DefV_Retract root:DE_CTFC:MenuStuff:Display_SMDefV_1
	controlinfo/W=DE_CTFC_Control CTFCsetvar0
	v_value=floor(v_value/2)*2+1
	if(v_value<2*numpnts(root:DE_CTFC:MenuStuff:Display_SMDefV_1))
		Smooth/S=2 (v_value), root:DE_CTFC:MenuStuff:Display_SMDefV_1
		ModifyGraph/W=DE_CTFC_Control#Smoothed hideTrace(Display_SMDefV_1)=0
	else
		ModifyGraph/W=DE_CTFC_Control#Smoothed hideTrace(Display_SMDefV_1)=1
	endif
	DoUpdate/W=DE_CTFC_Control#MostRecent	
	return 0

end //DE_UpdatePlot


////DE_FastPair()
Static function SaveWave()
	Wave/T TriggerInfo=TriggerSettings
	Wave/T RampInfo=RampSettings
	Wave DefVolts_Retract, ZSensorVolts_Retract
	wave MVW = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	string suffixStr = num2strlen(MVW[%BaseSuffix][0],4)

	variable ApproachVelocity=str2num(RampInfo[%ApproachVelocity][0])   
	string TriggerChannel=RampInfo[%SurfaceTriggerChannel][0]
	variable TriggerSet1=str2num(RampInfo[%SurfaceTrigger][0])  
	variable RetractVelocity=str2num(RampInfo[%RetractVelocity][0])  
	string TriggerChannel2=RampInfo[%RetractTriggerChannel][0]
	variable TriggerSet2=str2num(RampInfo[%RetractDistance][0])
	variable NoTrigSet=0      
	string Callback=RampInfo[%Callback][0]
	variable TriggerSetVolt1=str2num(TriggerInfo[%TriggerValue1])	 //Fix
	variable TriggerSetVolt2=str2num(TriggerInfo[%TriggerValue2])	  //Fix
	variable TriggerValue1=str2num(TriggerInfo[%TriggerPoint1])
	variable TriggerValue2=str2num(TriggerInfo[%TriggerPoint2])
	variable TriggerTime1=str2num(TriggerInfo[%TriggerTime1])
	variable TriggerTime2=str2num(TriggerInfo[%TriggerTime2])
	variable DwellTime1=str2num(TriggerInfo[%DwellTime1])
	variable DwellTime2=str2num(TriggerInfo[%DwellTime2])
	variable sampleRate=str2num(RampInfo[%SampleRate][0]) *1e3   //This has to be updated to adapt to inputs.

	variable TriggerDeflection=0

	strswitch(TriggerChannel)  //A switch to properly define the trigger levels (in voltage) based on the channel used for the second trigger.

		case "Deflection":

			TriggerDeflection=TriggerValue1/1e-12*GV("InvOLS")*GV("SpringConstant") //Deflection to reach
			break

		default:
	
	endswitch


	variable dwellPoints0 = round(DwellTime1*sampleRate)   
	variable dwellpoints1=round(DwellTime2*sampleRate) 
	variable ramp2pts= round((TriggerTime2)*sampleRate)-1
	String Indexes = "0," //Start the index and directions 
	String Directions = "Inf,"
	variable Index = round(TriggerTime1*sampleRate)-1      //Counts out to one point less than where it triggered
	Indexes += num2istr(Index)+","
	Directions += num2str(1)+","

	if (DwellPoints0)

		Index += DwellPoints0
		Indexes += num2istr(Index)+","
		Directions += "0,"
	
	endif
	
	Index += ramp2pts
	Indexes += num2istr(Index)+","
	Directions += num2str(-1)+","
//
//	
//	//	//This just lists the rest of the wave (from where the trigger fired through to the end of the wave) as a dwell. In general this contains both the approach back to the surface
//	//and any dwell there.
//
	Index=dimsize(DefVolts_Fast,0)
	Indexes += num2istr(Index)+","
	Directions += "0,"
//	//	
	string AddComm="" //This is a correction note for the string that the ARSaveAsForce() function is going to write when we save this as a force.
	AddComm = ReplaceStringbyKey("Experiment Type",AddComm,RampInfo[%ExperimentName],":","\r")
	AddComm = ReplaceStringbyKey("Experiment Stage",AddComm,"Initial Ramp",":","\r")
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
	AddComm = ReplaceStringbyKey("Force Dist",AddComm,num2str(TriggerSet2),":","\r")
	
	DE_SaveReg(DefV_Retract,ZSensor_Retract,AdditionalNote=AddComm)
		
end	//DE_FastPair
//
////--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//
////DE_SlowPair

Static function MakeSimple(InitialRamp,InitialRepeat,Repeat,TotalSpots,CurrentLoop,CurrentSpot)
	wave/T InitialRamp,InitialRepeat
	String Repeat,TotalSpots,CurrentLoop,CurrentSpot
	NewDataFolder/o root:DE_CTFC
	NewDataFolder/o root:DE_CTFC:Saved
	SetDataFolder root:DE_CTFC

	make/n=1/o FCD
	Make/O/T/N=(12,3) RampSettings		//Primary CTFC ramp settings
	
	RampSettings[0][0]= {InitialRamp[0][1],"Deflection",InitialRamp[1][1],InitialRamp[2][1],InitialRamp[3][1],"ZSensor",InitialRamp[4][1],InitialRamp[5][1],"DE_SimpleRamp#SimpleForceCallback()",InitialRamp[6][1],InitialRamp[7][1],InitialRamp[8][1]}
	RampSettings[0][1]= {"Approach Velocity","Surface Trigger Channel","Surface Trigger","Surface Dwell Time","Retract Velocity","Retract Trigger","Retract Distance","Retract Dwell Time","DE_CTFCCB_TFE","Sample Rate","Total Time","Start Distance"}
	RampSettings[0][2]=  {"µs/s","Alias","pN","s","µm/s","Alias","nm","s","CallBack","kHz","s","nm"}
 	
 	SetDimLabel 1,0,Values,RampSettings
 	SetDimLabel 1,1,Desc,RampSettings
 	SetDimLabel 1,2,Units,RampSettings

	SetDimLabel 0,0,ApproachVelocity,RampSettings
	SetDimLabel 0,1,SurfaceTriggerChannel,RampSettings
	SetDimLabel 0,2,SurfaceTrigger,RampSettings
	SetDimLabel 0,3,SurfaceDwellTime,RampSettings
	SetDimLabel 0,4,RetractVelocity,RampSettings
	SetDimLabel 0,5,RetractTriggerChannel,RampSettings
	SetDimLabel 0,6,RetractDistance,RampSettings
	SetDimLabel 0,7,RetractDwellTime,RampSettings
	SetDimLabel 0,8,CallBack,RampSettings
	SetDimLabel 0,9,SampleRate,RampSettings
	SetDimLabel 0,10,TotalTime,RampSettings
	SetDimLabel 0,11,StartDistance,RampSettings

	Make/O/T/N=(8,3) RepeatSettings			//These are the instructions that are passed forward for repeating the experiment	
	RepeatSettings[0][0]= {Repeat,InitialRepeat[0][1],InitialRepeat[1][1],InitialRepeat[2][1],TotalSpots,InitialRepeat[3][1],CurrentLoop,CurrentSpot}
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
		endif
	
	else
		
	endif
	
end
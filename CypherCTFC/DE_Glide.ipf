#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=DE_Glide

Static function Start()
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	variable datalength,runfast,outdecirate=DE_OUtdecirate("")
	string ErrorStr
	wave customwave2
	String Command="Glide Begun"
	DE_TriggeredForcePanel#UpdateCommandOut(Command,"Replace")
	
	if(StringMatch(SlowInfo[%UltraFast][0],"5 MHz")==1)
		DataLength=5e6*(str2num(SlowInfo[4][0])*1e-3/str2num(SlowInfo[5][0])+str2num(SlowInfo[6][0]))
		td_WriteValue("Cypher.Capture.0.Rate", 2)
		td_WriteValue("Cypher.Capture.0.Length", DataLength)
		runFast=1
	elseif(StringMatch(SlowInfo[%UltraFast][0],"2 MHz")==1)
		runFast=2
		print "2MHZ"
		make/o/n=1 HBDefl,HBZsnsr
		SetupStream(1,(str2num(SlowInfo[4][0])*1e-3/str2num(SlowInfo[5][0])+str2num(SlowInfo[6][0])),HBDefl,HBZsnsr)

	elseif(StringMatch(SlowInfo[%UltraFast][0],"500 kHz")==1)
		runFast=2
		print "500 kHz"
		make/o/n=1 HBDefl,HBZsnsr
		SetupStream(0,(str2num(SlowInfo[4][0])*1e-3/str2num(SlowInfo[5][0])+str2num(SlowInfo[6][0])),HBDefl,HBZsnsr)
	else
		runFast=0
	endif
	
	ErrorStr += IR_xSetOutWave(2,"7","PIDSLoop.5.SetpointOffset",CustomWave2,"DE_Glide#Done()",outdecirate)

	if(runFast==1)
		td_WriteValue("Cypher.Capture.0.Trigger", 1)
	elseif(runFast==2)
		td_ws("ARC.Events.once", "1")
	endif
	
	td_WS("Event.7","Once")

end

Static Function Done()
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings,RampInfo=root:DE_CTFC:RampSettings,SlowInfo=root:DE_CTFC:RefoldSettings,TriggerInfo=root:DE_CTFC:TriggerSettings
	wave DefVolts_Fast=DEfV_fast,ZsensorVolts_Fast=Zsensor_fast,DefVolts_slow=DEfv_slow,ZSensorVolts_slow=Zsensor_slow
	variable readfast=0
	String Command="Glide done"
	DE_TriggeredForcePanel#UpdateCommandOut(Command,"Add")
	ir_StopPISloop(5)  //Halt the feedback loop.
	DE_FastPair(TriggerInfo,RepeatInfo,RampInfo,DefVolts_Fast,ZsensorVolts_Fast)
	GlideSave(RepeatInfo,SlowInfo,DefVolts_slow,ZsensorVolts_slow)
					
	DE_UpdatePlot("Triggered Done")
	
	if(StringMatch(SlowInfo[%UltraFast][0],"No")!=1)
		ReadFast=DE_CheckFast("Access 5 MHz","5 MHz Check")
 			//ReadFast=1
		if(ReadFast!=4)
			Command="Glide done: Accessing High Bandwidth"
			DE_TriggeredForcePanel#UpdateCommandOut(Command,"Replace")
			ReadHighBandwidth(ReadFast)
			//DE_MAPFastCaptureCallback("Read",ReadFast)
						
		else
			DE_Glide#Repeat()
		endif
			
	else
		DE_Glide#Repeat()
	endif
			
end

Static Function FastDone()
	DE_Glide#Repeat()
end

Static function Repeat()
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave ZSensorVolts_fast=ZSensor_fast
	variable zerovolt,PVol,Rep
	string Command="Ramping Back"
	DE_TriggeredForcePanel#UpdateCommandOut(Command,"Replace")
	
	zerovolt=(ZSensorVolts_fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
	PVol=Zerovolt-str2num(RampInfo[%StartDistance][0])*1e-9/GV("ZLVDTSEns")
	rep=DE_RepCheck()
	DE_RamptoVol(PVol,"Start","DE_CB_Mol(\\\"TFE\\\","+num2str(rep)+")")

end

//DE_Custom2_Glide sets up the customwave2, which will drive us away from the surface if it's called. In this case the "Glide" tells us that we will do a simple ramp
//away from the surface with a pause at the end. We need to hand it CustomWave1 so that it knows where customwave1 is going to stop




Static Function CustomGlide(RampInfo,RefoldSettings,CustomWave2,customwave1)
	wave/t RampInfo
	wave/t RefoldSettings
	wave CustomWave2
	wave Customwave1
	variable total2,slope2,constant2,newrate,midpoint2,endpoint2,shift2
//
	total2=round(str2num(RefoldSettings[%DataRate][0])*( str2num(RefoldSettings[%RetractDistance][0])/str2num(RefoldSettings[%RetractSpeed][0])+str2num(RefoldSettings[%RetractPause][0])*1e3 ) )
	make/o/n=(total2) ZSensor_Slow,DefV_Slow //These are the waves that are to be read during this process. We don't adjust their size.
//
	if(total2<=5000) //checks if we exceed the limit for IR_xSetOutWave
		make/o/n=(total2) CustomWave2
		slope2=str2num(RefoldSettings[%RetractSpeed][0])/GV("ZLVDTSens")*1e-6/str2num(RefoldSettings[%DataRate][0])/1e3
		constant2=(-1*str2num(RefoldSettings[%RetractDistance][0])/GV("ZLVDTSens")*1e-9)
		midpoint2=str2num(RefoldSettings[%RetractDistance][0])/str2num(RefoldSettings[%RetractSpeed][0])*str2num(RefoldSettings[%DataRate][0])-1
		endpoint2=total2-1
	
		wavestats/q customwave1
		shift2=customwave1[v_npnts-1]
//			
	else	//If we do, run with as high a bandwidth as we can while limitting the total points to 87000
		total2=5000
		newrate=round(total2/(str2num(RefoldSettings[%RetractDistance][0])/str2num(RefoldSettings[%RetractSpeed][0])*1e-3+str2num(RefoldSettings[%RetractPause][0])))/1e3
		variable rdecirate=ceil(50/newrate)
		newrate=50/rdecirate*1e3
		total2=round(newrate*(str2num(RefoldSettings[%RetractDistance][0])/str2num(RefoldSettings[%RetractSpeed][0])*1e-3+str2num(RefoldSettings[%RetractPause][0])))
		make/o/n=(total2) CustomWave2

		slope2=str2num(RefoldSettings[%RetractSpeed][0])/GV("ZLVDTSens")*1e-6/newrate
		constant2=(-1*str2num(RefoldSettings[%RetractDistance][0])/GV("ZLVDTSens")*1e-9)
		midpoint2=(str2num(RefoldSettings[%RetractDistance][0])/str2num(RefoldSettings[%RetractSpeed][0])*newrate*1e-3)-1
		endpoint2=total2-1
		wavestats/q customwave1
		shift2=customwave1[v_npnts-1]
//			
	endif
//		
	CustomWave2=(constant2)
	CustomWave2[0,midpoint2]=-slope2*x
End // DE_Custom2_Glide()


Static function MakeGlide(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,b0,b1,b2,b3,b4,b5,b6,b7,b8,c0,c1,c2,c3,c4,c5,c6,c7)
	string a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,b0,b1,b2,b3,b4,b5,b6,b7,b8,c0,c1,c2,c3,c4,c5,c6,c7
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

	
	
	Make/O/T/N=(8,3) RefoldSettings		//Settings for ramp back to surface and final extension ramp.
	RefoldSettings[0][0]= {b0,b1,b2,b3,b4,b5,b6,b7,b8}
	RefoldSettings[0][1]= {"Experiment Name","Approach Distance","Approach Time","Approach Delay","Retract Distance","Retract Speed","Retract Pause","Data Rate","Ultra Fast Too?"}
	RefoldSettings[0][2]= {"","nm","s","s","nm","um/s","s","kHz","Yes/No"}	
	
	SetDimLabel 1,0,Values,RefoldSettings
 	SetDimLabel 1,1,Desc,RefoldSettings
 	SetDimLabel 1,2,Units,RefoldSettings

	SetDimLabel 0,0,ExperimentName,RefoldSettings
	SetDimLabel 0,1,ApproachDistance,RefoldSettings
	SetDimLabel 0,2,ApproachTime,RefoldSettings
	SetDimLabel 0,3,ApproachDelay,RefoldSettings
	SetDimLabel 0,4,RetractDistance,RefoldSettings
	SetDimLabel 0,5,RetractSpeed,RefoldSettings
	SetDimLabel 0,6,RetractPause,RefoldSettings
	SetDimLabel 0,7,DataRate,RefoldSettings
	SetDimLabel 0,8,UltraFast,RefoldSettings

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

Static function GlideSave(RepeatInfo,RampInfo,DefVolts_slow,ZsensorVolts_slow)
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
			AddComm = ReplaceStringbyKey("XVoltage",AddComm,num2str(td_rv("XSensor")),":","\r")
			AddComm = ReplaceStringbyKey("YVoltage",AddComm,num2str(td_rv("YSensor")),":","\r")

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
			AddComm = ReplaceStringbyKey("Experiment Type",AddComm,RampInfo[%ExperimentName],":","\r")
			AddComm = ReplaceStringbyKey("Experiment Stage",AddComm,"Ramp Out",":","\r")
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
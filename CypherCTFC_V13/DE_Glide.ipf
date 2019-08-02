#pragma rtGlobals=3		// Use modern global access method and strict wave access.
function DE_Glide_Start()
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	variable datalength,runfast
	variable outdecirate=DE_OUtdecirate("")
	string ErrorStr
	wave customwave2
	if(StringMatch(SlowInfo[%UltraFast][0],"Yes")==1)
				
		DataLength=5e6*(str2num(SlowInfo[4][0])*1e-3/str2num(SlowInfo[5][0])+str2num(SlowInfo[6][0]))
		td_WriteValue("Cypher.Capture.0.Rate", 2)
		td_WriteValue("Cypher.Capture.0.Length", DataLength)
		runFast=1
	else
		runFast=0
	endif
	

	ErrorStr += IR_xSetOutWave(2,"7","$DwellLoop2.SetpointOffset",CustomWave2,"DE_Glide_Done()",outdecirate)

	if(runFast==1)
		td_WriteValue("Cypher.Capture.0.Trigger", 1)
	else
		
	endif
	td_WS("Event.7","Once")

end

Function DE_Glide_Done()
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave DefVolts_Fast=DEfV_fast
	wave ZsensorVolts_Fast=Zsensor_fast
	wave ZSensorVolts_slow=Zsensor_slow
	wave DefVolts_slow=DEfv_slow
	variable rep,readfast=0,zerovolt,Pvol

	ir_StopPISloop(5)  //Halt the feedback loop.
	
	zerovolt=(ZSensorVolts_fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[2][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
	PVol=Zerovolt-str2num(RampInfo[%StartDistance][0])*1e-9/GV("ZLVDTSEns")   //Move us back.
	
	DE_FastPair(TriggerInfo,RepeatInfo,RampInfo,DefVolts_Fast,ZsensorVolts_Fast)
	DE_SlowPair(RepeatInfo,SlowInfo,DefVolts_slow,ZsensorVolts_slow)
					
	DE_UpdatePlot("Triggered Done")
	
	if(StringMatch(SlowInfo[8][0],"Yes")==1)
		ReadFast=DE_CheckFast("Access 5 MHz","5 MHz Check")
			
		if(ReadFast!=4)
			DE_MAPFastCaptureCallback("Read",ReadFast)
						
		else
			rep=DE_RepCheck()
			DE_RamptoVol(PVol,"Start","DE_CB_Mol(\\\"TFE\\\","+num2str(rep)+")")
		endif
			
	else
		rep=DE_RepCheck()
		DE_RamptoVol(PVol,"Start","DE_CB_Mol(\\\"TFE\\\","+num2str(rep)+")")	
	endif
			
end

function DE_FastDone_Glide()
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave ZSensorVolts_fast=ZSensor_fast
	variable zerovolt,PVol,Rep

	zerovolt=(ZSensorVolts_fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
	PVol=Zerovolt-str2num(RampInfo[%StartDistance][0])*1e-9/GV("ZLVDTSEns")
	rep=DE_RepCheck()
	DE_RamptoVol(PVol,"Start","DE_CB_Mol(\\\"TFE\\\","+num2str(rep)+")")

end

//DE_Custom2_Glide sets up the customwave2, which will drive us away from the surface if it's called. In this case the "Glide" tells us that we will do a simple ramp
//away from the surface with a pause at the end. We need to hand it CustomWave1 so that it knows where customwave1 is going to stop
Function DE_Custom2_Glide(RampInfo,RefoldSettings,CustomWave2,customwave1)
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

function DE_MakeGlide(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,b0,b1,b2,b3,b4,b5,b6,b7,b8,c0,c1,c2,c3,c4,c5,c6,c7)
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
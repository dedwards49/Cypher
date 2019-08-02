#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function DE_MultiRamp_Start()
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	wave ZsensorVolts_Fast=Zsensor_fast
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	wave DefVolts_Fast=DEfV_fast

	variable rep,zerovolt,pvol,startmultivolt,endmultivolt,totaltime,DataLength,outdecirate
	
	DE_UpdatePlot("Triggered 1")
	
	variable MultiRampEngage=DE_CheckRamp("Do You Want to Sweep About?","Sweep")
		
	if(MultiRampEngage==2)
		zerovolt=(ZsensorVolts_Fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
		PVol=Zerovolt-str2num(RampInfo[%StartDistance][0])*1e-9/GV("ZLVDTSEns")  //PVol is the approximate location of the start position.
		DE_UpdatePlot("No Trigger")
		ir_StopPISloop(5)
		rep=DE_RepCheck()
		DE_RamptoVol(PVol,"Start","DE_CB_NoMol(\\\"TFE\\\","+num2str(rep)+")")
		return -1
	else
	endif
	
	variable/c Markers=DE_PlaceMarkers(str2num(SlowInfo[%RetractStart][0])*1e-9,str2num(SlowInfo[%Retractend][0])*1e-9)
	startmultivolt=real(Markers)
	endmultivolt=imag(Markers)
	make/o/n=0 customwave2
	TotalTime=DE_Custom2_MultiRamp(RampInfo,SlowInfo,CustomWave2,startmultivolt,endmultivolt)
	
	if(StringMatch(SlowInfo[%UltraFast][0],"Yes")==1)		
		DataLength=ceil(5e6*(TotalTime))
		td_WriteValue("Cypher.Capture.0.Rate", 2)
		td_WriteValue("Cypher.Capture.0.Length", DataLength)
	else
	endif
	
	outdecirate=DE_OUtdecirate("MultiRamp")
	DE_FastPair(TriggerInfo,RepeatInfo,RampInfo,DefVolts_Fast,ZsensorVolts_Fast)//Saves the data from the fast (initial) pull here.

		//This is all currently done in the RampDownDone Procedure.
//	td_stopinwavebank(1)
//	td_stopinwavebank(2)		
//	IR_XSetInWavePair(1,"7,7","Cypher.Input.FastA",DefVolts_slow,"Cypher.LVDT.Z",ZSensorVolts_slow,"", decirate)

	SlowInfo[%CurrIter][0]="0" //sets the current iteration to 0. 
	variable/g StartingPiezo=td_rv("output.z")

	td_SetRamp(str2num(SlowInfo[%TimeToStart][0]), "PIDSLoop.5.Setpointoffset", 0, (startmultivolt- td_rv("PIDSLoop.5.Setpoint")), "", 0, 0, "", 0, 0, "DE_MultiRamp_Init("+num2str(outdecirate)+")")
	
end

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DE_MultiRamp_Init(outdecirate)
	variable outdecirate
	wave CustomWave2
	string ErrorStr
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave/t RefoldSettings
	wave DefVolts_Fast=DEfV_fast
	wave ZsensorVolts_Fast=Zsensor_fast
	wave ZSensorVolts_slow=Zsensor_slow
	wave DefVolts_slow=DEfv_slow
	variable current,decirate

	decirate=50/str2num(RefoldSettings[%DataRate][0])
	IR_XSetInWavePair(1,"7,7","Cypher.Input.FastA",DefVolts_slow,"Cypher.LVDT.Z",ZSensorVolts_slow,"", decirate)
	IR_xSetOutWave(2,"7,7","$DwellLoop2.Setpointoffset",CustomWave2,"DE_MultiRampRepeat()",outdecirate)
	td_WS("Event.7","Once")
	
	if(StringMatch(RefoldSettings[%UltraFast][0],"Yes")==1)		
		td_WriteValue("Cypher.Capture.0.Trigger", 1)
	else
		
	endif

end//DE_MultiRampInit

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DE_MultiRampRepeat()
	string ErrorStr
	wave ZSensorVolts_slow=Zsensor_slow
	wave DefVolts_slow=DEfv_slow
	wave/t RefoldSettings
	variable ReadFast
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	DE_UpdatePlot("Triggered Done")//Updates the graphs. Note that we haven't overwritten DefVolts_Fast, so this will just overwrite it.
	DE_SlowPair(RepeatInfo,RefoldSettings,DefVolts_slow,ZsensorVolts_slow)
	
	if(StringMatch(RefoldSettings[%UltraFast][0],"Yes")==1)	
		ReadFast=DE_CheckFast("Read 5 MHz","Read")
	
		if(ReadFast!=4)
			DE_MAPFastCaptureCallback("Read",ReadFast)
				
		else
			DE_MultiRampRepeatCheck()
		endif

	else
	DE_MultiRampRepeatCheck()
	
	endif		
	
end

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function DE_FastDone_MultiRamp()
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave/t SlowInfo=RefoldSettings
	wave customwave2
	wave ZSensorVolts_fast=ZSensor_fast
	variable Datalength,startmultivolt,endmultivolt,TotalTime
	startmultivolt=ZsensorVolts_Fast[pcsr(A,"DE_CTFC_Control#MostRecent")]
	endmultivolt=ZsensorVolts_Fast[pcsr(B,"DE_CTFC_Control#MostRecent")]
	variable totaldistance=2*(endmultivolt-startmultivolt)*GV("ZLVDTSEns")
	//DataLength=ceil(5e6*(abs(totaldistance)/(str2num(RefoldSettings[%RetractSpeed][0])*1e-6)+str2num(RefoldSettings[%SurfDwell][0])+str2num(RefoldSettings[%RetDwell][0])))
	TotalTime=DE_Custom2Time_MultiRamp(RampInfo,SlowInfo,CustomWave2,startmultivolt,endmultivolt)
	datalength=ceil(5e6*TotalTime)

	td_WriteValue("Cypher.Capture.0.Rate", 2)
	td_WriteValue("Cypher.Capture.0.Length", DataLength)
	DE_MultiRampRepeatCheck()
end


function DE_MultiRampRepeatCheck()
	wave/t RefoldSettings
	wave ZSensorVolts_slow=Zsensor_slow
	wave DefVolts_slow=DEfv_slow
	wave ZsensorVolts_Fast=Zsensor_fast
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	string ErrorStr
	variable zerovolt, PVol,rep,Last
	Last=0


	if(Exists("root:DE_CTFC:MenuStuff:Stop")==2)//Checks if someone hit "stop next" if so, runs stop.
		SVar T=root:DE_CTFC:MenuStuff:Stop
		
		if(cmpstr(T,"Yes")==0)
		Last=1
			if(waveExists(root:DE_CTFC:MenuStuff:ListComwave)==1)
				wave/z/T T2=root:DE_CTFC:MenuStuff:ListComwave
				T2="Stopped by User Command"

			endif
		endif
		killstrings T

	endif
	
	RefoldSettings[%CurrIter][0]=num2str(str2num(RefoldSettings[%CurrIter][0])+1)
	
	if(str2num(RefoldSettings[%CurrIter][0])>=str2num(RefoldSettings[%RetractIterations][0]))
	Last=1
	endif

	if(Last==1)//This is the kill switch for these loops, will now just go back to normal pulling.
			print "This Cycle is Done"
			DE_MultiRamp_End()
			return -1
						
	endif
	//If we make it through the previous If statement then we go through resetting and starting the waves.

	
	//wave customwave2
	variable outdecirate=DE_OutDecirate("MultiRamp")
	variable decirate=50/str2num(RefoldSettings[%DataRate][0])
	if(StringMatch(RefoldSettings[%UltraFast][0],"Yes")==1)		
//	variable Datalength,startmultivolt,endmultivolt
//	startmultivolt=ZsensorVolts_Fast[pcsr(A,"DE_CTFC_Control#MostRecent")]
//	endmultivolt=ZsensorVolts_Fast[pcsr(B,"DE_CTFC_Control#MostRecent")]
//	variable totaldistance=2*(endmultivolt-startmultivolt)*GV("ZLVDTSEns")
//					DataLength=5e6*(abs(totaldistance)/(str2num(RefoldSettings[%RetractSpeed][0])*1e-6)+str2num(RefoldSettings[%SurfDwell][0])+str2num(RefoldSettings[%RetDwell][0]))
//					td_WriteValue("Cypher.Capture.0.Rate", 2)
//					td_WriteValue("Cypher.Capture.0.Length", DataLength)
				else
				endif
	
	
//	IR_XSetInWavePair(1,"13","Cypher.Input.FastA",DefVolts_slow,"Cypher.LVDT.Z",ZsensorVolts_slow,"", decirate)
//	ErrorStr += IR_xSetOutWave(2,"7","$DwellLoop2.Setpointoffset",CustomWave2,"DE_MultiRampRepeat()",outdecirate)
	
	td_WS("Event.7","Once")
	if(StringMatch(RefoldSettings[%UltraFast][0],"Yes")==1)		
		td_WriteValue("Cypher.Capture.0.Trigger", 1)
	else
		
	endif	

end 

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DE_MultiRamp_End()
//td_setramp
wave/t RefoldSettings

			td_SetRamp(str2num(RefoldSettings[%TimeToStart][0]), "PIDSLoop.5.Setpointoffset", 0, 0, "", 0, 0, "", 0, 0, "DE_MultiRamp_End2()")
end

function DE_MultiRamp_End2()
	wave customwave3 
	wave ZSensor_Final
	wave DefV_Final 
	wave/t RefoldSettings
	variable outdecirate=DE_Outdecirate("MultiRampFinal")

	IR_xSetOutWave(2,"15","$DwellLoop2.SetpointOffset",CustomWave3,"DE_MultiRamp_End3()",outdecirate)
	IR_XSetInWavePair(1,"15","Deflection",DefV_Final,"Cypher.LVDT.Z",ZSensor_Final,"",50/str2num(RefoldSettings[%DataRate][0]))
	td_ws("Event.15","once")
end

function DE_MultiRamp_End3()

	wave/t RefoldSettings
wave ZSensor_Final
wave DefV_Final
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	variable zerovolt,pvol,rep
	wave ZsensorVolts_Fast=Zsensor_fast

	DE_SlowPair(RepeatInfo,TriggerInfo,DefV_Final,ZSensor_Final)

//	SetDimLabel 0,10,FinalDistance,RefoldSettings
//	SetDimLabel 0,11,FinalVelocity,RefoldSettings
//
//
//
			ir_StopPISloop(5)  //Halt the feedback loop.
			zerovolt=(ZSensorVolts_fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[2][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
			PVol=Zerovolt-str2num(RampInfo[%StartDistance][0])*1e-9/GV("ZLVDTSEns")  
			//PVol=Zerovolt
			DE_UpdatePlot("Triggered Done")
			rep=DE_RepCheck()
			DE_RamptoVol(PVol,"Start","DE_CB_NoMol(\\\"TFE\\\","+num2str(rep)+")")
//
//
end

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function DE_Custom2_MultiRamp(RampInfo,RefoldSettings,CustomWave2,startmultivolt,endmultivolt)

	wave/t RampInfo
	wave/t RefoldSettings
	wave CustomWave2
	variable startmultivolt,endmultivolt
	variable decirate,totaldistance,total2,slope2, constant2,endrmp1,endpause1,endrmp2,endpause2,outdecirate
	
	
	decirate=50/str2num(RefoldSettings[%DataRate][0])
	totaldistance=2*(endmultivolt-startmultivolt)*GV("ZLVDTSEns")
	total2=round(1e3*str2num(RefoldSettings[%DataRate][0])*(abs(totaldistance)/(str2num(RefoldSettings[%Retractspeed][0])*1e-6)+str2num(RefoldSettings[%SurfDwell][0])+str2num(RefoldSettings[%RetDwell][0])))
	make/o/n=(total2) ZSensor_Slow,DefV_Slow
	
	if(total2<=5000) //checks if we exceed the limit for IR_xSetOutWave
		outdecirate=decirate
		make/o/n=(total2) CustomWave2
		slope2=sign(totaldistance)*(str2num(RefoldSettings[%Retractspeed][0])/GV("ZLVDTSens")*1e-6)/(50e3/outdecirate)  //The Sign in front tells us if we're ramping negative or positive.
		constant2=startmultivolt
		endrmp1=round(50e3/outdecirate*(abs(totaldistance)/(str2num(RefoldSettings[%Retractspeed][0])*1e-6)/2))
		endpause1=endrmp1+round(50e3/outdecirate*(str2num(RefoldSettings[%RetDwell][0])))
		endrmp2=endpause1+endrmp1
		endpause2=endrmp2+round(50e3/outdecirate*(str2num(RefoldSettings[%SurfDwell][0])))
		CustomWave2[0,endrmp1-1]=slope2*p+constant2
		CustomWave2[endrmp1,endpause1-1]=endmultivolt
		CustomWave2[endpause1,endrmp2-1]=endmultivolt-slope2*(p-endpause1)
		CustomWave2[endrmp2,]=constant2

	else
		total2=5000
		outdecirate=round(50000/total2*(abs(totaldistance)/(str2num(RefoldSettings[%Retractspeed][0])*1e-6)+str2num(RefoldSettings[%SurfDwell][0])+str2num(RefoldSettings[%RetDwell][0])))
		make/o/n=(total2) CustomWave2
		slope2=sign(totaldistance)*(str2num(RefoldSettings[%Retractspeed][0])/GV("ZLVDTSens")*1e-6)/(50e3/outdecirate)
		constant2=startmultivolt
		endrmp1=round(50e3/outdecirate*(abs(totaldistance)/(str2num(RefoldSettings[%Retractspeed][0])*1e-6)/2))

		endpause1=endrmp1+round(50e3/outdecirate*(str2num(RefoldSettings[%RetDwell][0])))
		endrmp2=endpause1+endrmp1
		endpause2=endrmp2+round(50e3/outdecirate*(str2num(RefoldSettings[%SurfDwell][0])))
		CustomWave2[0,endrmp1-1]=slope2*p+constant2
		CustomWave2[endrmp1,endpause1-1]=endmultivolt
		CustomWave2[endpause1,endrmp2-1]=endmultivolt-slope2*(p-endpause1)
		CustomWave2[endrmp2,]=constant2
		
	endif
	variable offset=td_ReadValue("PIDSLoop.5.Setpoint")//This adjusts the wave to be a setrampoffset, rather than a straight setramp. 
	//this way I don't have to worry about it, but I honestly don't quite understand this
	if(numtype(offset)==0)		
	FastOP CustomWave2=CustomWave2-(offset)
	else
	endif

	
	
	
	return total2/(50e3/outdecirate)

	
	
end

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function DE_Custom2Time_MultiRamp(RampInfo,RefoldSettings,CustomWave2,startmultivolt,endmultivolt)

	wave/t RampInfo
	wave/t RefoldSettings
	wave CustomWave2
	variable startmultivolt,endmultivolt
	variable decirate,totaldistance,total2,slope2, constant2,endrmp1,endpause1,endrmp2,endpause2,outdecirate
	
	
	decirate=50/str2num(RefoldSettings[%DataRate][0])
	totaldistance=2*(endmultivolt-startmultivolt)*GV("ZLVDTSEns")
	total2=round(1e3*str2num(RefoldSettings[%DataRate][0])*(abs(totaldistance)/(str2num(RefoldSettings[%Retractspeed][0])*1e-6)+str2num(RefoldSettings[%SurfDwell][0])+str2num(RefoldSettings[%RetDwell][0])))
	
	if(total2<=5000) //checks if we exceed the limit for IR_xSetOutWave
		outdecirate=decirate
	else
		total2=5000
		outdecirate=round(50000/total2*(abs(totaldistance)/(str2num(RefoldSettings[%Retractspeed][0])*1e-6)+str2num(RefoldSettings[%SurfDwell][0])+str2num(RefoldSettings[%RetDwell][0])))
		
		
	endif
	
	
	return total2/(50e3/outdecirate)

	
	
end
//---------------------------------------------------------------------------------------------------------------------------------------------------------

Function DE_Custom3_MultiRamp(RampInfo,RefoldSettings,CustomWave3)
	wave/t RampInfo
	wave/t RefoldSettings
	wave CustomWave3
	variable total3,slope3,newrate
//

	total3=round(str2num(RefoldSettings[%DataRate][0])*(str2num(RefoldSettings[%FinalDistance][0])/str2num(RefoldSettings[%FinalVelocity][0])))
	make/o/n=(total3) ZSensor_Final,DefV_Final //These are the waves that are to be read during this process. We don't adjust their size.
//
	if(total3<=5000) //checks if we exceed the limit for IR_xSetOutWave
		make/o/n=(total3) CustomWave3
		slope3=str2num(RefoldSettings[%FinalVelocity][0])/GV("ZLVDTSens")*1e-6/str2num(RefoldSettings[%DataRate][0])/1e3
		//constant3=(-1*str2num(RefoldSettings[%RetractDistance][0])/GV("ZLVDTSens")*1e-9)
		//midpoint2=str2num(RefoldSettings[%RetractDistance][0])/str2num(RefoldSettings[%RetractSpeed][0])*str2num(RefoldSettings[%DataRate][0])*1e0
//			
	else	//If we do, run with as high a bandwidth as we can while limitting the total points to 87000
		total3=5000
		make/o/n=(total3) CustomWave3
		newrate=round(total3/(str2num(RefoldSettings[%FinalDistance][0])/str2num(RefoldSettings[%FinalVelocity][0])*1e-3))
		slope3=str2num(RefoldSettings[%FinalVelocity][0])/GV("ZLVDTSens")*1e-6/newrate
		//constant2=(-1*str2num(RefoldSettings[%RetractDistance][0])/GV("ZLVDTSens")*1e-9)
		//midpoint2=str2num(RefoldSettings[%RetractDistance][0])/str2num(RefoldSettings[%RetractSpeed][0])*newrate*1e-3
		//endpoint2=total2-1
	//	wavestats/q customwave1
		//shift2=customwave1[v_npnts-1]
//			
	endif
//									
	//CustomWave2=(constant2)
	CustomWave3[]=-slope3*x
	//CustomWave2+=shift2
	
End // DE_Custom2_Glide()

function DE_MakeMultiRamp(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,wpar,c0,c1,c2,c3,c4,c5,c6,c7)
	string a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13
	wave/T wpar
	string c0,c1,c2,c3,c4,c5,c6,c7
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
	SetDimLabel 0,4,RetractStart,RefoldSettings
	SetDimLabel 0,5,RetractEnd,RefoldSettings
	SetDimLabel 0,6,TimeToStart,RefoldSettings
	SetDimLabel 0,7,RetractSpeed,RefoldSettings
	SetDimLabel 0,8,ApproachSpeed,RefoldSettings

	SetDimLabel 0,9,SurfDwell,RefoldSettings
	SetDimLabel 0,10,RetDwell,RefoldSettings
	SetDimLabel 0,11,FinalDistance,RefoldSettings
	SetDimLabel 0,12,FinalVelocity,RefoldSettings
	SetDimLabel 0,13,RetractIterations,RefoldSettings
	SetDimLabel 0,14,CurrIter,RefoldSettings
	SetDimLabel 0,15,DataRate,RefoldSettings
	SetDimLabel 0,16,UltraFast,RefoldSettings


	RefoldSettings[0][0]= {wpar[0],wpar[1],wpar[2],wpar[3],wpar[4],wpar[5],wpar[6],wpar[7],wpar[8],wpar[9],wpar[10],wpar[11],wpar[12],wpar[13],wpar[14],wpar[15],wpar[16]}
	RefoldSettings[0][1]= {"Experiment Name","Approach Distance","Approach Time","Approach Delay","Retract Start","Retract End","Time Till Start","Retract Speed","Approach Speed","Surface Pause","Retract Pause","Final Distance", "Final Velocity","Max Iterations","Current Iteration","Data Rate","UltraFast Too?"}
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
//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#pragma rtGlobals=3		// Use modern global access method and strict wave access.
function DE_SOEquil_Start()
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	wave ZsensorVolts_Fast=Zsensor_fast
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	wave ZSensorVolts_slow=Zsensor_slow
	wave DefVolts_slow=DEfv_slow
	wave DefVolts_Fast=DEfV_fast
	variable rep,zerovolt,pvol,startmultivolt,endmultivolt,totaltime,DataLength,outdecirate,decirate
	decirate=50/str2num(SlowInfo[%DataRate][0])

	DE_UpdatePlot("Triggered 1")
	
	variable MultiRampEngage=DE_CheckRamp("Do You Want to Sweep About?","Sweep",PopupName="popup7")
	//variable	MultiRampEngage=1
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
	DE_FastPair(TriggerInfo,RepeatInfo,RampInfo,DefVolts_Fast,ZsensorVolts_Fast)//Saves the data from the fast (initial) pull here.

	TotalTime=DE_Custom2_SOEquil(RampInfo,SlowInfo,CustomWave2,startmultivolt,endmultivolt)
	IR_XSetInWavePair(1,"7,7","Cypher.Input.FastA",DefVolts_slow,"Cypher.LVDT.Z",ZSensorVolts_slow,"", -decirate)

	outdecirate=DE_OUtdecirate("SOEquil")
	SlowInfo[%CurrIter][0]="0" //sets the current iteration to 0. 
	variable/g StartingPiezo=td_rv("output.z")
	
	td_SetRamp(str2num(SlowInfo[%TimeToStart][0]), "PIDSLoop.5.Setpointoffset", 0, (startmultivolt- td_rv("PIDSLoop.5.Setpoint")), "", 0, 0, "", 0, 0, "DE_SOEquil_Init()")
	
end//DE_SOEquil_Start

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DE_SOEquil_Init()
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	variable datalength,runfast,outdecirate
	string ErrorStr
	wave CustomWave2
	outdecirate=DE_OUtdecirate("SOEquil")
	ErrorStr += IR_xSetOutWave(2,"7","$DwellLoop2.SetpointOffset",CustomWave2,"DE_SOEquil_StepsDone()",outdecirate)
//
	td_WS("Event.7","Once")

end

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//All that DE_SOEquil_StepsDone does is ramp us back to the surface and then calls "Surface"
function DE_SOEquil_StepsDone()
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	DE_UpdatePlot("Triggered Done")
	wave DefVolts_Step=Defv_Slow
	wave ZsensorVolts_Step=Zsensor_Slow
	td_stopinwavebank(-1)

	DE_SOEquil_StepSave(SlowInfo,DefVolts_Step,ZsensorVolts_Step)
	 td_SetRamp(str2num(SlowInfo[%TimeToStart][0]), "PIDSLoop.5.Setpointoffset", 0,0, "", 0, 0, "", 0, 0, "DE_SOEquil_Surface()")

end//DE_SOEquil_StepsDone

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// DE_SOEquil_Surface() Runs after the ramp done to the surface. 


function DE_SOEquil_Surface()
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	wave DefVolts_Equil=DefV_Equil
	wave ZsensorVolts_Equil=ZSensor_Equil
	wave customwave3
	wave ZSensorVolts_slow=Zsensor_slow
	wave DefVolts_slow=DEfv_slow
	variable HighVarTime,HighVarZSnsrV,outdecirate,decirate,DataLength,TotalTime,runFast
	variable/c outwaveinfo
	string ErrorStr
	

	decirate=50/str2num(SlowInfo[%DataRate][0])
	HighVarTime=DE_ScanSteps(DefVolts_slow)
	
	if(HighVarTime==-1)
	
		print "Error, no reasonable region of high variance found"
		DE_SOEquil_Complete()
		
		return -1
	
	endif
	
	HighVarZSnsrV=ZSensorVolts_slow(HighVarTime)
	outwaveinfo=DE_Custom3_SOEquil(Slowinfo,CustomWave3,HighVarZSnsrV)
	TotalTime=real(outwaveinfo)
	outdecirate=imag(outwaveinfo)

	ErrorStr += IR_XSetInWavePair(1,"7","Cypher.Input.FastA",DefVolts_Equil,"Cypher.LVDT.Z",ZSensorVolts_equil,"", -decirate)
	ErrorStr += IR_xSetOutWave(2,"7","PIDSLoop.5.Setpointoffset",CustomWave3,"DE_SOEquil_Done()",outdecirate)

if(StringMatch(SlowInfo[%UltraFast][0],"5 MHz")==1)			//Sorts out what High bandwidth measurement we wanna make and prepares them.
				
		DataLength=5e6*(totaltime)
		td_WriteValue("Cypher.Capture.0.Rate", 2)
		td_WriteValue("Cypher.Capture.0.Length", DataLength)
		runFast=1
	elseif(StringMatch(SlowInfo[%UltraFast][0],"2 MHz")==1)
		runFast=2
		make/o/n=1 HBDefl,HBZsnsr
		SetupStream(1,(totaltime),HBDefl,HBZsnsr)

	elseif(StringMatch(SlowInfo[%UltraFast][0],"500 kHz")==1)
		runFast=2
		make/o/n=1 HBDefl,HBZsnsr
		SetupStream(0,(totaltime),HBDefl,HBZsnsr)
	else
		runFast=0
	endif
	

	if(runFast==1)
		td_WriteValue("Cypher.Capture.0.Trigger", 1)
	elseif(runFast==2)
		td_ws("ARC.Events.once", "1")
		
	endif
	
		td_WS("Event.7","Once")


end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function DE_SOEquil_Done()
	wave/t SlowInfo=RefoldSettings
	wave/t RepeatInfo=RepeatSettings
	wave DefVolts_Equil=Defv_Equil
	wave ZsensorVolts_Equil=Zsensor_Equil
	variable readfast
	td_stopinwavebank(1)
	duplicate/o DefVolts_Equil DevlVoltsEquil_View
		duplicate/o DefVolts_Equil DevlVoltsEquil_View_SM
	Smooth/M=0 25, DevlVoltsEquil_View_SM
	DE_SOEquil_EquilSave(SlowInfo,DefVolts_Equil,ZsensorVolts_Equil)



if(StringMatch(SlowInfo[%UltraFast][0],"No")!=1)	//Did we want highbandwidth?
		
		display/N=Test DefVolts_Equil
		ReadFast=DE_CheckFast("Read 5 MHz","Read")
		killwindow Test
			
		if(ReadFast!=4)
			ReadHighBandwidth(ReadFast)
						
		else
			DE_SOEquil_Repeat()
		endif
			
	else
		DE_SOEquil_Repeat()
	endif
	
	
	
	
	
	
end

function DE_FastDone_SOEquil()
Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave/t SlowInfo=RefoldSettings
	wave customwave2
	wave ZSensorVolts_fast=ZSensor_fast
	variable Datalength,startmultivolt,endmultivolt,TotalTime

	DE_SOEquil_Repeat()
end
	
function DE_SOEquil_Repeat()
	wave/t SlowInfo=RefoldSettings
	wave/t RepeatInfo=RepeatSettings
	variable totaltime,DataLength
	if((str2num(SlowInfo[%CurrIter][0])+1)>=str2num(SlowInfo[%RetractIterations][0]))
	td_SetRamp(str2num(SlowInfo[%TimeToStart][0]), "PIDSLoop.5.Setpointoffset", 0,0, "", 0, 0, "", 0, 0, "DE_SOEquil_Complete()")

	else
	SlowInfo[%CurrIter][0]=num2str((str2num(SlowInfo[%CurrIter][0]))+1)
	td_SetRamp(str2num(SlowInfo[%TimeToStart][0]), "PIDSLoop.5.Setpointoffset", 0,0, "", 0, 0, "", 0, 0, "DE_SOEquil_Surface()")
	TotalTime=DE_Custom3Time_SOEquil(SlowInfo)
	
	DataLength=ceil(5e6*(TotalTime)/2)*2

	td_WriteValue("Cypher.Capture.0.Rate", 2)
	td_WriteValue("Cypher.Capture.0.Length", DataLength)
	endif

end

//-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DE_SOEquil_Complete()
	wave customwave4 
	wave ZSensor_Final
	wave DefV_Final 
	wave/t RefoldSettings
	variable outdecirate=DE_Outdecirate("SOEquilFinal")
	IR_xSetOutWave(2,"15","$DwellLoop2.SetpointOffset",CustomWave4,"DE_SOEquil_Done2()",outdecirate)
	IR_XSetInWavePair(1,"15","Deflection",DefV_Final,"Cypher.LVDT.Z",ZSensor_Final,"",-50/str2num(RefoldSettings[%DataRate][0]))/////
	td_ws("Event.15","once")
end

function DE_SOEquil_Done2()

	wave/t RefoldSettings
	wave DefVolts_Final=Defv_Final
	wave ZsensorVolts_Final=Zsensor_Final
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	variable zerovolt,pvol,rep
	
	DE_SOEquil_FinalSave(RefoldSettings,DefVolts_Final,ZsensorVolts_Final)
	wave ZsensorVolts_Fast=Zsensor_fast
print "DE_SOEquil_Done2"
	ir_StopPISloop(5)  //Halt the feedback loop.
	zerovolt=(ZSensorVolts_fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[2][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
	PVol=Zerovolt-str2num(RampInfo[%StartDistance][0])*1e-9/GV("ZLVDTSEns")  
	DE_UpdatePlot("Triggered Done")
	rep=DE_RepCheck()
	DE_RamptoVol(PVol,"Start","DE_CB_NoMol(\\\"TFE\\\","+num2str(rep)+")")


end


Function DE_Custom2_SOEquil(RampInfo,RefoldSettings,CustomWave2,startvolt,endvolt)
	wave/t RampInfo
	wave/t RefoldSettings
	wave CustomWave2
	variable startvolt,endvolt

	//This writes CustomWave2, which will drive the Z-position away from the surface in steps.
	variable stepsize,datarate,steptime,pausetime,Zsens
	stepsize=str2num(RefoldSettings[%RetractStepSize][0])
	datarate=str2num(RefoldSettings[%DataRate][0])
	steptime=str2num(RefoldSettings[%RetractStepTime][0])
	pausetime=str2num(RefoldSettings[%RetractDwellTime][0])
	Zsens=GV("ZLVDTSENS")

	variable totaldistance,steps,totalpoints,totalsteptime,slope,i,shift,s1,e1,s2,e2,constant2,corr,newrate,Dirs

	totaldistance=((endvolt-startvolt)*Zsens)
	Dirs=sign(totaldistance)
	steps=ceil(abs(totaldistance)/stepsize*1e9)
	totalsteptime=pausetime+steptime

	totalpoints=round(1e3*datarate*(steps)*(totalsteptime))
	make/o/n=(totalpoints) ZSensor_Slow,DefV_Slow

	if(totalpoints<=50000) //checks if we exceed the limit for IR_xSetOutWave
		make/o/n=(totalpoints) CustomWave2
		CustomWave2=Dirs*(steps)*stepsize*1e-9/Zsens

		i=0
		slope=Dirs*1e-9*stepsize/steptime/datarate/1e3/Zsens
		shift=startvolt

		for(i=0;i<steps;i+=1)
			
			s1=i*datarate*1e3*(totalsteptime)
			e1=s1+datarate*1e3*steptime-1
			s2=e1+1
			e2=(i+1)*datarate*1e3*(totalsteptime)-1
			constant2=Dirs*(i+1)*stepsize*1e-9/Zsens
			corr=slope*i*(e2-s2+1)
			customwave2[s1,e1]=slope*x-corr
			customwave2[s2,e2]=constant2
		endfor

	else
		totalpoints=50000
		newrate=round(totalpoints/steps/totalsteptime)/1e3
		variable rdecirate=ceil(50/newrate)
		newrate=50/rdecirate
		totalpoints=round(newrate*1e3*Totalsteptime*Steps)
		make/o/n=(totalpoints) CustomWave2
		CustomWave2=Dirs*(steps)*stepsize*1e-9/Zsens

		i=0
		slope=Dirs*1e-9*stepsize/steptime/newrate/1e3/Zsens
		shift=startvolt

		for(i=0;i<steps;i+=1)
			
			s1=i*newrate*1e3*(totalsteptime)
			e1=s1+newrate*1e3*steptime-1
			s2=e1+1
			e2=(i+1)*newrate*1e3*(totalsteptime)-1
			e2=min(e2,totalpoints-1)

			constant2=Dirs*(i+1)*stepsize*1e-9/Zsens
			corr=slope*i*(e2-s2+1)
			customwave2[s1,e1]=slope*x-corr
			customwave2[s2,e2]=constant2


		endfor

	endif

	FastOP CustomWave2=CustomWave2+(startvolt-td_rv("PIDSLoop.5.Setpoint"))
	//FastOP CustomWave2=CustomWave2+(startvolt)
	return (steps)*(totalsteptime)
End //DE_Custom2_SOEquil

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function/C DE_Custom3_SOEquil(RefoldSettings,CustomWave3,position)
	wave/t RefoldSettings
	wave CustomWave3
	variable position
	variable start=stopmstimer(-2)
	variable SurfacePause,EquilibriumPause,totalpoints,datarate,TimeToStart,slope,StartRise,Endrise,StartFall,EndFall,newrate,totaltime,outrate,upper,lower
	//variable total3,slope3,newrate
	variable setpoint=td_rv("PIDSLoop.5.Setpoint")

	SurfacePause=str2num(RefoldSettings[%SurfacePause][0])
	EquilibriumPause=str2num(RefoldSettings[%EquilibriumPause][0])
	datarate=str2num(RefoldSettings[%datarate][0])*1e3
	TimeToStart=str2num(RefoldSettings[%TimeToStart][0])
	upper=position+.6e-9/GV("ZLVDTSENS")
	lower=position-.6e-9/GV("ZLVDTSENS")
	position-=setpoint-.0e-9/GV("ZLVDTSENS")
	upper-=setpoint-.0e-9/GV("ZLVDTSENS")
	lower-=setpoint-.0e-9/GV("ZLVDTSENS")
	totaltime=3*(SurfacePause+EquilibriumPause+3*TimeToStart)
	totalpoints=round(datarate*(SurfacePause+EquilibriumPause+3*TimeToStart))
	make/o/n=(3*totalpoints) ZSensor_Equil,DefV_Equil //These are the waves that are to be read during this process. We don't adjust their size.
	
	if(totalpoints<=20000) //checks if we exceed the limit for IR_xSetOutWave
		make/o/n=(totalpoints) CustomWave3
		outrate=datarate
		slope=1/(TimeToStart*datarate-1)
		StartRise=SurfacePause*datarate
		Endrise=StartRise+TimeToStart*Datarate
		StartFall=Endrise+EquilibriumPause*datarate
		EndFall=StartFall+TimetoStart*Datarate
		CustomWave3[,StartRise-1]=0
		CustomWave3[StartRise,Endrise]=(x-StartRise)*slope
		CustomWave3[Endrise,StartFall-1]=1
		CustomWave3[StartFall,EndFall-1]=1-(x-StartFall)*slope
		CustomWave3[EndFall,]=0
	else	//If we do, run with as high a bandwidth as we can while limitting the total points to 87000
		totalpoints=20000
		newrate=round(totalpoints/(SurfacePause+EquilibriumPause+3*TimeToStart))/1e3
		variable rdecirate=ceil(50/newrate)
		newrate=50e3/rdecirate
		totalpoints=round(newrate*(SurfacePause+EquilibriumPause+3*TimeToStart))
		outrate=newrate
		make/o/n=(totalpoints) CustomWave3
		slope=1/(TimeToStart*newrate-1)
		StartRise=SurfacePause*newrate
		Endrise=StartRise+TimetoStart*newrate
		StartFall=Endrise+EquilibriumPause*newrate
		EndFall=StartFall+TimetoStart*newrate
		CustomWave3[,StartRise-1]=0
		CustomWave3[StartRise,Endrise]=(x-StartRise)*slope
		CustomWave3[Endrise,StartFall-1]=1
		CustomWave3[StartFall,EndFall-1]=1-(x-StartFall)*slope
		CustomWave3[EndFall,]=0

			
	endif
	wavestats/q Customwave3
	make/o/n=(3*totalpoints) Brief
	Brief[0,totalpoints-1]=upper*CustomWave3[p]
	Brief[totalpoints,2*totalpoints-1]=position*CustomWave3[p-totalpoints]
	Brief[2*totalpoints,3*totalpoints-1]=lower*CustomWave3[p-2*totalpoints]
	duplicate/o Brief Customwave3
	killwaves Brief
return cmplx(totaltime,50000/outrate)
end

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function DE_Custom3Time_SOEquil(RefoldSettings)
	wave/t RefoldSettings
	variable SurfacePause,EquilibriumPause,totalpoints,datarate,TimeToStart,newrate,totaltime,outrate
	SurfacePause=str2num(RefoldSettings[%SurfacePause][0])
	EquilibriumPause=str2num(RefoldSettings[%EquilibriumPause][0])
	datarate=str2num(RefoldSettings[%datarate][0])*1e3
	TimeToStart=str2num(RefoldSettings[%TimeToStart][0])

	totaltime=3*(SurfacePause+EquilibriumPause+3*TimeToStart)
	totalpoints=round(datarate*(SurfacePause+EquilibriumPause+3*TimeToStart))
	
	if(totalpoints<=20000) //checks if we exceed the limit for IR_xSetOutWave
		outrate=datarate
		
	else	//If we do, run with as high a bandwidth as we can while limitting the total points to 87000
		totalpoints=20000
		newrate=round(totalpoints/(SurfacePause+EquilibriumPause+3*TimeToStart))/1e3
		variable rdecirate=ceil(50/newrate)
		newrate=50e3/rdecirate
		totalpoints=round(newrate*(SurfacePause+EquilibriumPause+3*TimeToStart))
		outrate=newrate
			
	endif
	
return totaltime
end

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function 	DE_Custom4_SOEquil(RampInfo,RefoldSettings,CustomWave4)
	wave/t RampInfo
	wave/t RefoldSettings
	wave CustomWave4
	variable total3,slope3,newrate
//

	total3=round(str2num(RefoldSettings[%DataRate][0])*(str2num(RefoldSettings[%FinalDistance][0])/str2num(RefoldSettings[%FinalVelocity][0])))
	make/o/n=(total3) ZSensor_Final,DefV_Final //These are the waves that are to be read during this process. We don't adjust their size.
//
	if(total3<=5000) //checks if we exceed the limit for IR_xSetOutWave
		make/o/n=(total3) CustomWave4
		slope3=1*abs(str2num(RefoldSettings[%FinalVelocity][0])/GV("ZLVDTSens")*1e-6/str2num(RefoldSettings[%DataRate][0])/1e3)
		//constant3=(-1*str2num(RefoldSettings[%RetractDistance][0])/GV("ZLVDTSens")*1e-9)
		//midpoint2=str2num(RefoldSettings[%RetractDistance][0])/str2num(RefoldSettings[%RetractSpeed][0])*str2num(RefoldSettings[%DataRate][0])*1e0
//			
	else	//If we do, run with as high a bandwidth as we can while limitting the total points to 87000
		
		total3=5000
		newrate=round(total3/(str2num(RefoldSettings[%FinalDistance][0])/str2num(RefoldSettings[%FinalVelocity][0])*1e-3))/1e3

		variable rdecirate=ceil(50/newrate)
		newrate=50e3/rdecirate
		total3=round(newrate*(str2num(RefoldSettings[%FinalDistance][0])/str2num(RefoldSettings[%FinalVelocity][0])*1e-3))
		make/o/n=(total3) CustomWave4

		
		slope3=1*abs(str2num(RefoldSettings[%FinalVelocity][0])/GV("ZLVDTSens")*1e-6/newrate)

//			
	endif
//									
	//CustomWave2=(constant2)
	CustomWave4[]=-slope3*x//This is a relative wave ramp, we'll add the necessary offset to it when called
	//CustomWave2+=shift2
	
end

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DE_MakeSOEquil(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,wpar,c0,c1,c2,c3,c4,c5,c6,c7)
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

	Make/O/T/N=(18,3) RefoldSettings		//Settings for ramp back to surface and final extension ramp.
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
	SetDimLabel 0,7,RetractStepSize,RefoldSettings
	SetDimLabel 0,8,RetractStepTime,RefoldSettings

	SetDimLabel 0,9,RetractDwellTime,RefoldSettings
	SetDimLabel 0,10,SurfacePause,RefoldSettings
	SetDimLabel 0,11,EquilibriumPause,RefoldSettings
	SetDimLabel 0,12,FinalDistance,RefoldSettings
	SetDimLabel 0,13,FinalVelocity,RefoldSettings
	SetDimLabel 0,14,RetractIterations,RefoldSettings
	SetDimLabel 0,15,CurrIter,RefoldSettings
	SetDimLabel 0,16,DataRate,RefoldSettings
	SetDimLabel 0,17,UltraFast,RefoldSettings

	RefoldSettings[0][0]= {wpar[0],wpar[1],wpar[2],wpar[3],wpar[4],wpar[5],wpar[6],wpar[7],wpar[8],wpar[9],wpar[10],wpar[11],wpar[12],wpar[13],wpar[14],wpar[15],wpar[16],wpar[17]}
	RefoldSettings[0][1]= {"Experiment Name","Approach Distance","Approach Time","Approach Delay","Retract Start","Retract End","Time Till Start","Retract Step Time","Retract Dwell Time","Retract Step Size" ,"Retract Dwell Time","Equilibrium Pause","Final Distance", "Final Velocity","Max Iterations","Current Iteration","Data Rate","UltraFast Too?"}
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
	
end//DE_MakeSOEquil

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DE_ScanSteps(InVoltage)
	wave InVoltage
	wave/t RefoldSettings
	duplicate/o InVoltage DeflVoltage
	Smooth/M=0 75, DeflVoltage
	make/o/n=0 SDevs
	variable DwellTimes,datarate,steptime,pausetime,n,Maxloc
	datarate=str2num(RefoldSettings[%DataRate][0])
	steptime=str2num(RefoldSettings[%RetractStepTime][0])
	pausetime=str2num(RefoldSettings[%RetractDwellTime][0])
	n=0
	do
		wavestats/Q/R=(n*(steptime+pausetime)+2*steptime,n*(steptime+pausetime)+pausetime) DeflVoltage
		InsertPoints n, 1, SDevs
		SDevs[n]=abs(v_sdev)
		n+=1
		wavestats/Q/R=(n*(steptime+pausetime)+2*steptime,n*(steptime+pausetime)+pausetime) DeflVoltage
	while(v_npnts>1)
	wavestats/q Sdevs
	make/free/n=4 W_Coef={0,v_max,V_maxRowLoc,V_npnts/10}
	CurveFit/G/NTHR=0 gauss kwCWave=W_coef,  SDevs /D 


	
	Maxloc=w_coef[2]
	if(MaxLoc<0||MaxLoc>numpnts(SDevs)-4)
	MaxLoc=V_maxRowLoc
	endif
	//if(maxloc==0||maxloc==(v_npnts-1))
	//return -1
	//else
	//endif
	//killwaves SDevs
	print maxloc*(pausetime+steptime)+.5*pausetime
	//killwaves DeflVoltage
	return maxloc*(pausetime+steptime)+.5*pausetime
end

function DE_SOEquil_StepSave(RefoldInfo,DefVolts_Step,ZsensorVolts_Step)
	Wave/T RefoldInfo
	Wave DefVolts_step, ZSensorVolts_step

	wave MVW = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	string suffixStr = num2strlen(MVW[%BaseSuffix][0],4)
	string AddComm="" 
	variable Index, ApproachDistance, ApproachTime, ApproachVelocity,ApproachDelay,sampleRate,TimetoStart
	variable RetractDistanceStep,retractsteptime,retractstepdelay
	String Indexes = "0," //Start the index and directions 
	String Directions = "0,"

	ApproachDistance=str2num(RefoldInfo[%ApproachDistance][0])  
	ApproachTime=str2num(RefoldInfo[%ApproachTime][0])
	ApproachVelocity=ApproachDistance/ApproachTime*1e-3
	ApproachDelay=str2num(RefoldInfo[%ApproachDelay][0])
	RetractDistanceStep=str2num(RefoldInfo[%RetractStepSize][0])  
	RetractStepTime=str2num(RefoldInfo[%RetractStepTime][0])  
	RetractStepDelay=str2num(RefoldInfo[%RetractDwellTime][0])  
	sampleRate=str2num(RefoldInfo[%DataRate][0]) *1e3
	TimetoStart=str2num(RefoldInfo[%TimeToStart][0])
	Index=dimsize(DefVolts_step,0)
	Indexes += num2istr(Index)+","
	Directions += "-1,"

	AddComm = ReplaceStringbyKey("Indexes",AddComm,Indexes,":","\r")
	AddComm = ReplaceStringbyKey("Direction",AddComm,Directions,":","\r")
	AddComm = ReplaceStringbyKey("ApproachVelocity",AddComm,num2str(ApproachVelocity),":","\r")
	AddComm = ReplaceStringbyKey("ApproachDistance",AddComm,num2str(ApproachDistance),":","\r")
	AddComm = ReplaceStringbyKey("DwellTime",AddComm,num2str(ApproachDelay),":","\r")
	AddComm = ReplaceStringbyKey("TimeToStart",AddComm,num2str(TimeToStart),":","\r")
	AddComm = ReplaceStringbyKey("RetractDistanceStep",AddComm,num2str(RetractDistanceStep),":","\r")
	AddComm = ReplaceStringbyKey("RetractStepTime",AddComm,num2str(RetractStepTime),":","\r")
	AddComm = ReplaceStringbyKey("RetractStepDelay",AddComm,num2str(RetractStepDelay),":","\r")
	AddComm = ReplaceStringbyKey("NumPtsPerSec",AddComm,num2str(sampleRate),":","\r")
	AddComm = ReplaceStringbyKey("PullType",AddComm,"Step Out",":","\r")
	AddComm = ReplaceStringbyKey("ExperimentType",AddComm,"Step Out Equilibrium",":","\r")

	AddComm = ReplaceStringbyKey("Corresponding Fast Pull",AddComm,num2strlen(str2num(suffixStr)-1,4),":","\r")

	DE_SaveReg(DefVolts_step,ZSensorVolts_step,AdditionalNote=AddComm)
	
		
end	//DE_SlowPair



function DE_SOEquil_EquilSave(RefoldInfo,DefVolts_Equil,ZsensorVolts_Equil)
	Wave/T RefoldInfo
	Wave DefVolts_equil, ZSensorVolts_equil

	wave MVW = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	string suffixStr = num2strlen(MVW[%BaseSuffix][0],4)
	string AddComm="" 
	variable Index,sampleRate,dwellPoints0,ramppts
	variable SurfacePause,EquilibriumPause,timetostart
	String Indexes = "0," //Start the index and directions 
	String Directions ="NaN,"
	
	TimetoStart=str2num(RefoldInfo[%TimeToStart][0])
	SurfacePause=str2num(RefoldInfo[%SurfacePause][0])
	EquilibriumPause=str2num(RefoldInfo[%EquilibriumPause][0])

	sampleRate=str2num(RefoldInfo[%DataRate][0]) *1e3
	Index=dimsize(DefVolts_equil,0)
	Indexes += num2istr(Index)+","
	Directions += "-1,"

	AddComm = ReplaceStringbyKey("Indexes",AddComm,Indexes,":","\r")
	AddComm = ReplaceStringbyKey("Direction",AddComm,Directions,":","\r")
	AddComm = ReplaceStringbyKey("TimeToStart",AddComm,num2str(TimetoStart),":","\r")	
	AddComm = ReplaceStringbyKey("Surface Pause",AddComm,num2str(SurfacePause),":","\r")
	AddComm = ReplaceStringbyKey("Equilibrium Pause",AddComm,num2str(EquilibriumPause),":","\r")
	AddComm = ReplaceStringbyKey("NumPtsPerSec",AddComm,num2str(sampleRate),":","\r")
	AddComm = ReplaceStringbyKey("PullType",AddComm,"Equil",":","\r")
	AddComm = ReplaceStringbyKey("ExperimentType",AddComm,"Step Out Equilibrium",":","\r")

	AddComm = ReplaceStringbyKey("Corresponding Fast Pull",AddComm,num2strlen(str2num(suffixStr)-1,4),":","\r")
	DE_SaveReg(DefVolts_equil,ZSensorVolts_equil,AdditionalNote=AddComm)
	
		
end	//DE_SlowPair

function DE_SOEquil_FinalSave(,RefoldInfo,DefVolts_Final,ZsensorVolts_Final)
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
//
//
//function/C 	DE_ScaleCustom3_SOEquil(CustomWave3,Scale)
//	wave Customwave3
//	variable scale
//	wave/t RefoldSettings
//	variable totalpoints,datarate,SurfacePause,EquilibriumPause,TimeToStart,outdatarate,newrate,totaltime,upper,lower
//	upper=scale+.3e-9/GV("ZLVDTSENS")
//	lower=scale-.3e-9/GV("ZLVDTSENS")
//	SurfacePause=str2num(RefoldSettings[%SurfacePause][0])
//	EquilibriumPause=str2num(RefoldSettings[%EquilibriumPause][0])
//	datarate=str2num(RefoldSettings[%datarate][0])*1e3
//	TimeToStart=str2num(RefoldSettings[%TimeToStart][0])
//	totaltime=SurfacePause+EquilibriumPause+2*TimeToStart
//	totalpoints=round(datarate*(SurfacePause+EquilibriumPause+2*TimeToStart))
//	
//	if(totalpoints<=50000) //checks if we exceed the limit for IR_xSetOutWave
//		outdatarate=datarate
//	else	//If we do, run with as high a bandwidth as we can while limitting the total points to 87000
//		totalpoints=50000
//		newrate=round(totalpoints/(SurfacePause+EquilibriumPause+2*TimeToStart))
//		outdatarate=newrate
//	endif
//
//	wavestats/q Customwave3
//	make/o/n=(3*totalpoints) Brief
//	Brief[0,totalpoints-1]=lower*CustomWave3[p]
//	Brief[totalpoints,2*totalpoints-1]=Scale*CustomWave3[p-totalpoints]
//	Brief[2*totalpoints,3*totalpoints-1]=upper*CustomWave3[p-2*totalpoints]
//	duplicate/o Brief Customwave3
//	killwaves Brief
//	return cmplx(outdatarate,totaltime)
//end

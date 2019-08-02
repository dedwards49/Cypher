#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=DE_StepOut


Static function Start()
	
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	wave ZsensorVolts_Fast=Zsensor_fast
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	
	String Command="Step Out Begun"
	DE_TriggeredForcePanel#UpdateCommandOut(Command,"Replace")
	
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

	TotalTime=DE_StepOut#Custom2(RampInfo,SlowInfo,CustomWave2,startmultivolt,endmultivolt)
	wave ZSensorVolts_slow=Zsensor_slow
	wave DefVolts_slow=DEfv_slow
	IR_XSetInWavePair(1,"7,7","Cypher.Input.FastA",DefVolts_slow,"Cypher.LVDT.Z",ZSensorVolts_slow,"", decirate)
	
	if(StringMatch(SlowInfo[%UltraFast][0],"5 MHz")==1)			//Sorts out what High bandwidth measurement we wanna make and prepares them.
				
		DataLength=5e6*(totaltime)
		td_WriteValue("Cypher.Capture.0.Rate", 2)
		td_WriteValue("Cypher.Capture.0.Length", DataLength)
	elseif(StringMatch(SlowInfo[%UltraFast][0],"2 MHz")==1)
		make/o/n=1 HBDefl,HBZsnsr
		SetupStream(1,(totaltime),HBDefl,HBZsnsr)

	elseif(StringMatch(SlowInfo[%UltraFast][0],"500 kHz")==1)
		make/o/n=1 HBDefl,HBZsnsr
		SetupStream(0,(totaltime),HBDefl,HBZsnsr)
	else
	endif
	


	outdecirate=DE_OUtdecirate("SOEquil")
	SlowInfo[%SurfaceLocation]=num2str(td_rv("Zsensor"))  //Read the current stage position so we can come back at the end

	
	td_SetRamp(str2num(SlowInfo[%TimeToStart][0]), "PIDSLoop.5.Setpointoffset", 0, (startmultivolt- td_rv("PIDSLoop.5.Setpoint")), "", 0, 0, "", 0, 0, "DE_StepOut#Init()")

end


function Init()
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	variable datalength,runfast,outdecirate
	string ErrorStr
	wave CustomWave2
	outdecirate=DE_OUtdecirate("Step Out")
	ErrorStr += IR_xSetOutWave(2,"7","$DwellLoop2.SetpointOffset",CustomWave2,"DE_StepOut#RampDown()",outdecirate)
	
	if(StringMatch(SlowInfo[%UltraFast][0],"5 MHz")==1)			//Sorts out what High bandwidth measurement we wanna make and prepares them.
		td_WriteValue("Cypher.Capture.0.Trigger", 1)

	elseif(StringMatch(SlowInfo[%UltraFast][0],"2 MHz")==1)
		td_ws("ARC.Events.once", "1")


	elseif(StringMatch(SlowInfo[%UltraFast][0],"500 kHz")==1)
		td_ws("ARC.Events.once", "1")

	else
	endif


	td_WS("Event.7","Once")

end

Static function StepsDone()
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave DefVolts_Fast=DEfV_fast
	wave ZsensorVolts_Fast=Zsensor_fast
	wave ZSensorVolts_slow=Zsensor_slow
	wave DefVolts_slow=DEfv_slow
	wave/t RefoldSettings
	variable rep,readfast=0
	
	//ir_StopPISloop(5)  //Halt the feedback loop.
	
			
	StepSave(RepeatInfo,SlowInfo,DefVolts_slow,ZSensorVolts_slow)					
	DE_UpdatePlot("Triggered Done")
	
		if(StringMatch(RefoldSettings[%UltraFast][0],"No")!=1)	//Did we want highbandwidth?
		
		display/N=Test DefVolts_slow
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
	
	
end

Static Function FastDone()
	FinalPull()
end

Static Function RampDown()
	Wave/T RefoldInfo=root:DE_CTFC:RefoldSettings

	variable newpoint=str2num(RefoldInfo[%SurfaceLocation][0])
	td_SetRamp(str2num(RefoldInfo[%ApproachTime][0]), "PIDSLoop.5.Setpoint", 0, newpoint, "", 0, 0, "", 0, 0, "DE_StepOut#StepsDone()")  //This should ramp is back to the surface on PIDSLoop.4 thanks to having recorded the surface before
end//RampDown()


Static Function FinalPull()
	wave customwave3
	wave ZSensor_Final
	wave DefV_Final 
	wave/t RefoldSettings
	
	variable outdecirate=DE_Outdecirate("StepOutFinal")
	IR_xSetOutWave(2,"15","PIDSLoop.5.SetpointOffset",CustomWave3,"DE_StepOut#Done()",outdecirate)
	IR_XSetInWavePair(1,"15","Deflection",DefV_Final,"Cypher.LVDT.Z",ZSensor_Final,"",-50/str2num(RefoldSettings[%DataRate][0]))
	td_ws("Event.15","once")//Fires the ramp away from the surface.
end

Static Function Done()
	wave/t RefoldSettings
	wave DefVolts_Final=Defv_Final
	wave ZsensorVolts_Final=Zsensor_Final
	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave ZsensorVolts_Fast=Zsensor_fast
	variable zerovolt,pvol,rep
	
	DE_MBUllUnfolding#FinalSave(RefoldSettings,DefVolts_Final,ZsensorVolts_Final)  //Save final pull
	

	ir_StopPISloop(4)  //Halt the feedback loop.
	zerovolt=(ZSensorVolts_fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[2][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
	PVol=Zerovolt-str2num(RampInfo[%StartDistance][0])*1e-9/GV("ZLVDTSEns")  
	DE_UpdatePlot("Triggered Done")
	rep=DE_RepCheck()
	DE_RamptoVol(PVol,"Start","DE_CB_NoMol(\\\"TFE\\\","+num2str(rep)+")")   //Basically sends us through loop repeater.
end

Static Function Custom2(RampInfo,RefoldSettings,CustomWave2,startvolt,endvolt)
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
		print newrate
		variable rdecirate=ceil(50/newrate)
		print rdecirate
		newrate=50/rdecirate
		print newrate
		totalpoints=round(newrate*1e3*Totalsteptime*Steps)
		print totalpoints
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
	
End // DE_Custom2_StepOut()


static function CustomRamp_Final(RampInfo,RefoldSettings,CustomWave3)
	wave/t RampInfo
	wave/t RefoldSettings
	wave CustomWave3
	variable total3,slope3,newrate

	total3=round(str2num(RefoldSettings[%DataRate][0])*(1e3+str2num(RefoldSettings[%FinalDistance][0])/str2num(RefoldSettings[%FinalVelocity][0])))
	make/o/n=(total3) ZSensor_Final,DefV_Final //These are the waves that are to be read during this process. We don't adjust their size.

	if(total3<=5000) //checks if we exceed the limit for IR_xSetOutWave
		make/o/n=(total3) CustomWave3
		slope3=1*abs(str2num(RefoldSettings[%FinalVelocity][0])/GV("ZLVDTSens")*1e-6/str2num(RefoldSettings[%DataRate][0])/1e3)
		newrate=str2num(RefoldSettings[%DataRate][0])
	else	//If we do, run with as high a bandwidth as we can while limitting the total points to 87000. Since this is a simple slope, we just use 5000 points, which should be plenty.
		
		total3=5000
		newrate=round(total3/(1+str2num(RefoldSettings[%FinalDistance][0])/str2num(RefoldSettings[%FinalVelocity][0])*1e-3))/1e3

		variable rdecirate=ceil(50/newrate)
		newrate=50e3/rdecirate
		total3=round(newrate*(1+str2num(RefoldSettings[%FinalDistance][0])/str2num(RefoldSettings[%FinalVelocity][0])*1e-3))
		make/o/n=(total3) CustomWave3
		
		slope3=1*abs(str2num(RefoldSettings[%FinalVelocity][0])/GV("ZLVDTSens")*1e-6/newrate)

	endif
	CustomWave3[0,floor(newrate*1)]=0
	CustomWave3[ceil(newrate*1),]=-slope3*(x-ceil(newrate*1))//This is a relative wave ramp, since this is applied to the setpointoffset, this will be fine

end//CustomRamp_Final



Static Function MakeWaves(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,wpar,c0,c1,c2,c3,c4,c5,c6,c7)
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


	Make/O/T/N=(15,3) RefoldSettings		//Settings for ramp back to surface and final extension ramp.
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
	SetDimLabel 0,10,FinalDistance,RefoldSettings
	SetDimLabel 0,11,FinalVelocity,RefoldSettings
	SetDimLabel 0,12,DataRate,RefoldSettings
	SetDimLabel 0,13,SurfaceLocation,RefoldSettings
	SetDimLabel 0,14,UltraFast,RefoldSettings


	RefoldSettings[0][0]= {wpar[0],wpar[1],wpar[2],wpar[3],wpar[4],wpar[5],wpar[6],wpar[7],wpar[8],wpar[9],wpar[10],wpar[11],wpar[12],wpar[13],wpar[14]}
	RefoldSettings[0][1]= {"Experiment Name","Approach Distance","Approach Time","Approach Delay","Retract Start","Retract End","Time Till Start","Retract Step Size","Retract Step Time","Retract Dwell Size" ,"Final Distance","Final Velocity","Data Rate","Surface Location","UltraFast Too?"}
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
	
end //DE_Custom2_StepOut()

//DE_SlowPair
Static function StepSave(RepeatInfo,RampInfo,DefVolts_slow,ZsensorVolts_slow)
	Wave/T RepeatInfo,RampInfo
	Wave DefVolts_slow, ZSensorVolts_slow
	Wave ZsensorVolts_Fast

	wave MVW = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	string suffixStr = num2strlen(MVW[%BaseSuffix][0],4)
	string AddComm="" 
	variable RetractStartV,RetractEndV,Index, ApproachDistance, ApproachTime, ApproachVelocity,ApproachDelay,RetractDistance,RetractDelay,sampleRate,dwellPoints0,ramppts
	variable RetractStart,RetractEnd,RetractStepSize,RetractStepDelay,RetractStepTime
	String Indexes = "0," //Start the index and directions 
	String Directions = "0,"
	

	
	ApproachDistance=str2num(RampInfo[%ApproachDistance][0])*1e-9
	ApproachTime=str2num(RampInfo[%ApproachTime][0])
	ApproachVelocity=str2num(RampInfo[%ApproachDistance][0])/str2num(RampInfo[%ApproachTime][0])*1e-9
	ApproachDelay=str2num(RampInfo[%ApproachDelay][0])
	if(strlen(CsrInfo(A,"DE_CTFC_Control#MostRecent")) == 0)	// A is a name, not a string
	RetractStartV=0
	RetractEndV=0
	RetractStart=str2num(RampInfo[%RetractStart][0])  
	RetractEnd=str2num(RampInfo[%RetractEnd][0])  
	else
	RetractStartV=ZsensorVolts_Fast[pcsr(A,"DE_CTFC_Control#MostRecent")]
	RetractEndV=ZsensorVolts_Fast[pcsr(B,"DE_CTFC_Control#MostRecent")]
 	RetractStart=RetractStartV*GV("ZLVDTSENS")
 	RetractEnd=RetractEndV*GV("ZLVDTSENS")
 	endif
 	RetractStepTime=str2num(RampInfo[%RetractStepTime][0])  
	RetractStepDelay=str2num(RampInfo[%RetractDwellTime][0])  
	RetractStepSize=str2num(RampInfo[%RetractStepSize][0])  
	
	sampleRate=str2num(RampInfo[%DataRate][0]) *1e3
	RetractDistance=str2num(RampInfo[7][0]) *str2num(RampInfo[4][0])  
	//RetractVelocity=RetractDistance/((RetractStepDelay+RetractStepTime)*RetractStepNumber)*1e-3
	//variable dwellPoints0 = round(RetractDelay*sampleRate)   
	//variable ramppts= round((RetractDistance/RetractVelocity*1e-3)*sampleRate)-1
	Index=dimsize(DefVolts_slow,0)
	Indexes += num2istr(Index)+","
	Directions += "-1,"
	AddComm = ReplaceStringbyKey("Indexes",AddComm,Indexes,":","\r")
	AddComm = ReplaceStringbyKey("Direction",AddComm,Directions,":","\r")
	AddComm = ReplaceStringbyKey("Experiment Type",AddComm,RampInfo[%ExperimentName],":","\r")
	AddComm = ReplaceStringbyKey("Experiment Stage",AddComm,"Steps",":","\r")
	AddComm = ReplaceStringbyKey("ApproachVelocity",AddComm,num2str(ApproachVelocity),":","\r")
	AddComm = ReplaceStringbyKey("ApproachDistance",AddComm,num2str(ApproachDistance),":","\r")
	AddComm = ReplaceStringbyKey("RetractDistance",AddComm,num2str(RetractDistance),":","\r")
	AddComm = ReplaceStringbyKey("DwellTime",AddComm,num2str(ApproachDelay),":","\r")
	AddComm = ReplaceStringbyKey("Retract Start",AddComm,num2str(RetractStart),":","\r")
	AddComm = ReplaceStringbyKey("Retract End",AddComm,num2str(RetractEnd),":","\r")
	AddComm = ReplaceStringbyKey("Retract Start Voltage",AddComm,num2str(RetractStartV),":","\r")
	AddComm = ReplaceStringbyKey("Retract End Voltage",AddComm,num2str(RetractEndV),":","\r")
	AddComm = ReplaceStringbyKey("Retract Step Time",AddComm,num2str(RetractStepTime),":","\r")
	AddComm = ReplaceStringbyKey("Retract Step Delay",AddComm,num2str(RetractStepDelay),":","\r")
	AddComm = ReplaceStringbyKey("NumPtsPerSec",AddComm,num2str(sampleRate),":","\r")
	AddComm = ReplaceStringbyKey("Pull Speed (Pair)",AddComm,"Slow",":","\r")
	AddComm = ReplaceStringbyKey("Corresponding Fast Pull",AddComm,num2strlen(str2num(suffixStr)-1,4),":","\r")
	AddComm = ReplaceStringbyKey("Force Dist",AddComm,num2str(RetractDistance),":","\r")
		

	DE_SaveReg(DefVolts_slow,ZSensorVolts_slow,AdditionalNote=AddComm)
	
		
end	//DE_SlowPair
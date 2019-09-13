#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma modulename=DE_Menu_StepJump
//
Static Function Start()
	wave SJW=root:DE_CTFC:StuffToDo:StepJump:StepJumpWave
	variable/c Markers=DE_CTFCMenu#PlaceMarkers(0,SJW[%Distance_nm][0]*1e-9/GV("ZLVDTSENS"),SJW,1)
	variable startmultivolt=real(Markers)
	variable endmultivolt=imag(Markers)
		SJW[%StartingVoltage_V][0]=startmultivolt
		SJW[%EndingVoltage_V][0]=endmultivolt
	variable startrelativevolt=startmultivolt-td_rv("PIDSLoop.5.Setpoint")
	variable endrelativevolt=endmultivolt-td_rv("PIDSLoop.5.Setpoint")	

	variable outdecirate=GenerateStepJump(startrelativevolt,endrelativevolt)
	variable decirate=50/SJW[%Bandwidth_kHz][0]
	wave DefV_slow=root:DE_CTFC:StuffToDo:StepJump:DefV
	wave ZSnsr_slow=root:DE_CTFC:StuffToDo:StepJump:ZSensor
	wave CW=root:DE_CTFC:StuffToDo:StepJump:CustomWave
	IR_XSetInWavePair(1,"7","Cypher.Input.FastA",DefV_slow,"Cypher.LVDT.Z",ZSnsr_slow,"", -decirate)
	IR_xSetOutWave(2,"7","PIDSLoop.5.Setpointoffset",CW,"DE_Menu_StepJump#SJReturn()",outdecirate)
	td_SetRamp(.01, "PIDSLoop.5.Setpointoffset", 0, startrelativevolt, "", 0, 0, "", 0, 0, "DE_Menu_StepJump#SJExecute()")
end

Static Function SJExecute()
	td_WS("Event.7","Once")
end

Static Function SJReturn()
	td_SetRamp(.01, "PIDSLoop.5.Setpointoffset", 0, 0, "", 0, 0, "", 0, 0, "DE_Menu_StepJump#SJEquil()")
end

Static Function SJEquil()
	wave SJW=root:DE_CTFC:StuffToDo:StepJump:StepJumpWave
	wave DefVolts_slow=root:DE_CTFC:StuffToDo:StepJump:DefV
	wave ZSensorVolts_slow=root:DE_CTFC:StuffToDo:StepJump:ZSensor
	UpdateStepJumpStep(DefVolts_slow,ZSensorVolts_slow)
	DE_CTFCMenu#DoAPlot("StepJumpStep")
	DoUpdate/W=StepJumpStep
	variable HighVarTime,HighVarZSnsrV,TotalTime,outdecirate
	variable/c outwaveinfo
	variable decirate=50/SJW[%Bandwidth_kHz][0]

	HighVarTime=DE_Menu_StepJump#ScanSteps(DefVolts_slow)
	
	if(HighVarTime==-1)
		print "Error, no reasonable region of high variance found"
		return -1
	endif
	
	HighVarZSnsrV=ZSensorVolts_slow(HighVarTime)
	SJW[%FlickLocation_V]=HighVarZSnsrV
	outwaveinfo=DE_GenerateStepJumpequill(HighVarZSnsrV)
	wave ZsensorVolts_Equil=root:DE_CTFC:StuffToDo:StepJump:ZSensor_Equil //These are the waves that are to be read during this process. We don't adjust their size.
	wave DefVolts_Equil=root:DE_CTFC:StuffToDo:StepJump:DefV_Equil
	wave CW2=root:DE_CTFC:StuffToDo:StepJump:CustomWave2
	TotalTime=real(outwaveinfo)
	outdecirate=imag(outwaveinfo)

	IR_XSetInWavePair(1,"7","Cypher.Input.FastA",DefVolts_Equil,"Cypher.LVDT.Z",ZSensorVolts_equil,"", -decirate)
	IR_xSetOutWave(2,"7","PIDSLoop.5.Setpointoffset",CW2,"DE_Menu_StepJump#SJEquilDone()",outdecirate)
	DE_CTFCMenu#FastCaptureCheckStart(SJW,totaltime)
	
	wave SJW=root:DE_CTFC:StuffToDo:StepJump:StepJumpWave
	if(SJW[%Fast][0]==3)			//Sorts out what High bandwidth measurement we wanna make and prepares them.
		td_WriteValue("Cypher.Capture.0.Trigger", 1)
	elseif(SJW[%Fast][0]==2)

		td_ws("ARC.Events.once", "1")
	elseif(SJW[%Fast][0]==1)	
		td_ws("ARC.Events.once", "1")
	else
	endif
	td_WS("Event.7","Once")
end

Static function ScanSteps(InVoltage)

	wave InVoltage
	wave SJW=root:DE_CTFC:StuffToDo:StepJump:StepJumpWave
	duplicate/o InVoltage DeflVoltage
	Smooth/M=0 75, DeflVoltage
	make/o/n=0 SDevs
	variable DwellTimes,datarate,steptime,pausetime,n,Maxloc
	datarate=SJW[%Bandwidth_kHz]
	steptime=0.01
	pausetime=SJW[%StepTime_s]
	//datarate=str2num(RefoldSettings[%DataRate][0])
	//steptime=str2num(RefoldSettings[%RetractStepTime][0])
	//pausetime=str2num(RefoldSettings[%RetractDwellTime][0])
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

Static Function SJEquilDone()
	wave SJW=root:DE_CTFC:StuffToDo:StepJump:StepJumpWave
	wave DefVolts_slow=root:DE_CTFC:StuffToDo:StepJump:DefV
	wave ZSensorVolts_slow=root:DE_CTFC:StuffToDo:StepJump:ZSensor
	wave ZsensorVolts_Equil=root:DE_CTFC:StuffToDo:StepJump:ZSensor_Equil //These are the waves that are to be read during this process. We don't adjust their size.
	wave DefVolts_Equil=root:DE_CTFC:StuffToDo:StepJump:DefV_Equil

	UpdateStepJumpandSave(DefVolts_Equil,ZsensorVolts_Equil)
	DE_CTFCMenu#DoAPlot("StepJumpEquil")
	DoUpdate/W=StepJumpEquil
	DE_CTFCMenu#FastCaptureCheckEnd(SJW,"StepJump")

end

Static Function SJDone2()
	DE_CTFCMEnu#CheckonPostRamp("StepJump")

end
Static Function UpdateStepJumpStep(Defwave,ZWave)
	wave Defwave,ZWave
	note Defwave DE_CTFCMenu#GenericNoteFile()
	note ZWave DE_CTFCMenu#GenericNoteFile()
	duplicate/o Defwave root:DE_CTFC:StuffToDo:StepJump_StepDef
	duplicate/o ZWave root:DE_CTFC:StuffToDo:StepJump_StepZSensor

end

Static Function UpdateStepJumpandSave(Defwave,ZWave)
	wave Defwave,ZWave
	note Defwave StepJumpNoteFile()+"\r"+DE_CTFCMenu#GenericNoteFile()
	note ZWave StepJumpNoteFile()+"\r"+DE_CTFCMenu#GenericNoteFile()
	duplicate/o Defwave root:DE_CTFC:StuffToDo:StepJump_EquilDef
	duplicate/o ZWave root:DE_CTFC:StuffToDo:StepJump_EquilZSensor
	NVar LSJ= root:DE_CTFC:StuffToDo:StepJump
	variable savenum=LSJ+1
	LSJ=savenum
	wave 	DefStep= root:DE_CTFC:StuffToDo:StepJump_StepDef
	wave 	ZSnStep= root:DE_CTFC:StuffToDo:StepJump_StepZSensor
	duplicate Defwave $("root:DE_CTFC:StuffToDo:StepJump:Saves:SJEquil_D"+num2str(savenum))
	duplicate ZWave $("root:DE_CTFC:StuffToDo:StepJump:Saves:SJequil_Z"+num2str(savenum))
	duplicate DefStep $("root:DE_CTFC:StuffToDo:StepJump:Saves:SqStep_D"+num2str(savenum))
	duplicate ZSnStep $("root:DE_CTFC:StuffToDo:StepJump:Saves:SJStep_Z"+num2str(savenum))
end

Static Function/S StepJumpNoteFile()
	wave SJW=root:DE_CTFC:StuffToDo:StepJump:StepJumpWave

	NVar SjumpNum=root:DE_CTFC:StuffToDo:StepJumpRamp
	String FinalString=""
	variable Bandwidth=(SJW[%Bandwidth_kHz][0])
	variable StepSize=(SJW[%StepSize_nm][0])
	variable StepTime=(SJW[%StepTime_s][0])
	variable FlickerLocation=(SJW[%FlickLocation_V][0])
	variable FlickerSpacing=(SJW[%Flickspace_nm][0])
	variable SurfaceTime=(SJW[%SurfaceTime_s][0])
	variable JumpTime=(SJW[%JumpTime_s][0])
	variable EquilTime=(SJW[%EquilTime_s][0])
	variable startingV=SJW[%StartingVoltage_V][0]
	variable endingV=	SJW[%EndingVoltage_V][0]
//
	FinalString=	ReplaceStringByKey("Type", FinalString,"StepJump",":","\r")
	FinalString=	ReplaceStringByKey("Number", FinalString,num2str(SjumpNum),":","\r")
	FinalString=	ReplaceStringByKey("Bandwidth", FinalString,num2str(Bandwidth),":","\r")
	FinalString=	ReplaceStringByKey("StepSize", FinalString,num2str(StepSize),":","\r")
	FinalString=	ReplaceStringByKey("StepTime", FinalString,num2str(StepTime),":","\r")
	FinalString=	ReplaceStringByKey("FlickerLocation", FinalString,num2str(FlickerLocation),":","\r")
	FinalString=	ReplaceStringByKey("FlickerSpacing", FinalString,num2str(FlickerSpacing),":","\r")
	FinalString=	ReplaceStringByKey("SurfaceTime", FinalString,num2str(SurfaceTime),":","\r")
	FinalString=	ReplaceStringByKey("JumpTime", FinalString,num2str(JumpTime),":","\r")
		FinalString=	ReplaceStringByKey("EquilTime", FinalString,num2str(EquilTime),":","\r")

	FinalString=	ReplaceStringByKey("startingV", FinalString,num2str(startingV),":","\r")
		FinalString=	ReplaceStringByKey("endingV", FinalString,num2str(endingV),":","\r")


	return FinalString
end




////
////Static Function MultiRampDone2()
////
////	CheckonPostRamp("Multi")
////end
//
//
//Static Function StepOutDone()
//	wave SOW=root:DE_CTFC:StuffToDo:StepOut:StepOutWave
//
//	wave DefVolts=root:DE_CTFC:StuffToDo:MRamp:DefV
//	wave ZSensorVolts=root:DE_CTFC:StuffToDo:MRamp:ZSensor
//	UpdateMultiRampandSave(DefVolts,ZSensorVolts)
//	DoAPlot("StepOut")
//	FastCaptureCheckEnd(SOW,"StepOut")
//
//end
//
//
//Static Function StepOutDone2()
//	CheckonPostRamp("StepOut")
//end
//
Static Function GenerateStepJump(startvolt,endvolt)
	variable endvolt,startvolt
	wave SJW=root:DE_CTFC:StuffToDo:StepJump:StepJumpWave
	variable decirate,stepsize,steptime,pausetime,Zsens,datarate
	decirate=50/SJW[%Bandwidth_kHz][0]
	datarate=SJW[%Bandwidth_kHz][0]
	stepsize=(SJW[%stepsize_nm][0])
	steptime=.01
	pausetime=(SJW[%StepTime_s][0])
	Zsens=GV("ZLVDTSENS")

	variable totaldistance,steps,totalpoints,totalsteptime,slope,i,shift,s1,e1,s2,e2,constant2,corr,newrate,Dirs

	totaldistance=((endvolt-startvolt)*Zsens)
	Dirs=sign(totaldistance)
	steps=ceil(abs(totaldistance)/stepsize*1e9)
	totalsteptime=pausetime+steptime
	totalpoints=round(1e3*datarate*(steps)*(totalsteptime))
	make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:StepJump:ZSensor,root:DE_CTFC:StuffToDo:StepJump:DefV
	if(totalpoints<=50000) //checks if we exceed the limit for IR_xSetOutWave
		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:StepJump:CustomWave
		wave CW=root:DE_CTFC:StuffToDo:StepJump:CustomWave
		CW=Dirs*(steps)*stepsize*1e-9/Zsens
		i=0
		slope=Dirs*1e-9*stepsize/steptime/datarate/1e3/Zsens
		shift=0
		//
		for(i=0;i<steps;i+=1)
			
			s1=i*datarate*1e3*(totalsteptime)
			e1=s1+datarate*1e3*steptime-1
			s2=e1+1
			e2=(i+1)*datarate*1e3*(totalsteptime)-1
			constant2=Dirs*(i+1)*stepsize*1e-9/Zsens
			corr=slope*i*(e2-s2+1)
			CW[s1,e1]=slope*x-corr
			CW[s2,e2]=constant2
		endfor
		//
	else
		totalpoints=50000
		newrate=round(totalpoints/steps/totalsteptime)/1e3

		variable rdecirate=ceil(50/newrate)

		newrate=50/rdecirate

		totalpoints=round(newrate*1e3*Totalsteptime*Steps)

		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:StepJump:CustomWave
		wave CW=root:DE_CTFC:StuffToDo:StepJump:CustomWave
		CW=Dirs*(steps)*stepsize*1e-9/Zsens
		i=0
		slope=Dirs*1e-9*stepsize/steptime/newrate/1e3/Zsens
		shift=0
		for(i=0;i<steps;i+=1)
			
			s1=i*newrate*1e3*(totalsteptime)
			e1=s1+newrate*1e3*steptime-1
			s2=e1+1
			e2=(i+1)*newrate*1e3*(totalsteptime)-1
			constant2=Dirs*(i+1)*stepsize*1e-9/Zsens
			corr=slope*i*(e2-s2+1)
			CW[s1,e1]=slope*x-corr
			CW[s2,e2]=constant2
		endfor
	endif
	CW+=startvolt
	return rdecirate
End // GenerateStepJump()


Static function/C DE_GenerateStepJumpequill(position)

	variable position
	wave SJW=root:DE_CTFC:StuffToDo:StepJump:StepJumpWave

	variable start=stopmstimer(-2)
	variable SurfacePause,EquilibriumPause,datarate,TimeToStart,upper,lower,totaltime,totalpoints,outrate,slope,StartRise,Endrise,StartFall,EndFall,newrate
//	variable SurfacePause,EquilibriumPause,totalpoints,datarate,TimeToStart,slope,StartRise,Endrise,StartFall,EndFall,newrate,totaltime,outrate,upper,lower
//	//variable total3,slope3,newrate
	variable setpoint=td_rv("PIDSLoop.5.Setpoint")
	if(numtype(setpoint)==2)
	setpoint=0
	endif
	SurfacePause=(SJW[%SurfaceTime_s][0])
	EquilibriumPause=(SJW[%EquilTime_s][0])
	datarate=(SJW[%Bandwidth_kHz][0])*1e3
	TimeToStart=(SJW[%JumpTime_s][0])
	upper=position+.6e-9/GV("ZLVDTSENS")
	lower=position-.6e-9/GV("ZLVDTSENS")
	position-=setpoint-.0e-9/GV("ZLVDTSENS")
	upper-=setpoint-.0e-9/GV("ZLVDTSENS")
	lower-=setpoint-.0e-9/GV("ZLVDTSENS")
	totaltime=3*(SurfacePause+EquilibriumPause+3*TimeToStart)
	totalpoints=round(datarate*(SurfacePause+EquilibriumPause+3*TimeToStart))
	make/o/n=(3*totalpoints) root:DE_CTFC:StuffToDo:StepJump:ZSensor_Equil,root:DE_CTFC:StuffToDo:StepJump:DefV_Equil //These are the waves that are to be read during this process. We don't adjust their size.
	
	if(totalpoints<=20000) //checks if we exceed the limit for IR_xSetOutWave
		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:StepJump:CustomWave2
		wave CW=root:DE_CTFC:StuffToDo:StepJump:CustomWave2
		outrate=datarate
		slope=1/(TimeToStart*datarate-1)
		StartRise=SurfacePause*datarate
		Endrise=StartRise+TimeToStart*Datarate
		StartFall=Endrise+EquilibriumPause*datarate
		EndFall=StartFall+TimetoStart*Datarate
		CW[,StartRise-1]=0
		CW[StartRise,Endrise]=(p-StartRise)*slope
		CW[Endrise,StartFall-1]=1
		CW[StartFall,EndFall-1]=1-(x-StartFall)*slope
		CW[EndFall,]=0
	else	//If we do, run with as high a bandwidth as we can while limitting the total points to 87000
		totalpoints=20000
		newrate=round(totalpoints/(SurfacePause+EquilibriumPause+3*TimeToStart))/1e3
		variable rdecirate=ceil(50/newrate)
		newrate=50e3/rdecirate
		totalpoints=round(newrate*(SurfacePause+EquilibriumPause+3*TimeToStart))
		outrate=newrate
		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:StepJump:CustomWave2
		wave CW=root:DE_CTFC:StuffToDo:StepJump:CustomWave2
		slope=1/(TimeToStart*outrate-1)
		StartRise=SurfacePause*outrate
		Endrise=StartRise+TimeToStart*outrate
		StartFall=Endrise+EquilibriumPause*outrate
		EndFall=StartFall+TimetoStart*outrate
		CW[,StartRise-1]=0
		CW[StartRise,Endrise]=(x-StartRise)*slope
		CW[Endrise,StartFall-1]=1
		CW[StartFall,EndFall-1]=1-(x-StartFall)*slope
		CW[EndFall,]=0
//			
	endif
	make/free/n=(3*totalpoints) Brief

	Brief[0,totalpoints-1]=upper*CW[p]
	Brief[totalpoints,2*totalpoints-1]=position*CW[p-totalpoints]
	Brief[2*totalpoints,3*totalpoints-1]=lower*CW[p-2*totalpoints]
	duplicate/o Brief CW
//	killwaves Brief
return cmplx(totaltime,50000/outrate)
end

Static Function MakeWave()
	make/o/n=14 root:DE_CTFC:StuffToDo:StepJump:StepJumpWave
	wave SJW=root:DE_CTFC:StuffToDo:StepJump:StepJumpWave

	SJW={0,50,0.5,.2,0,.2,.01,.1,.5,50,0,1,0,0}
	
	SetDimLabel 0,0,Location_V,SJW
	SetDimLabel 0,1,Distance_nm,SJW
	SetDimLabel 0,2,Stepsize_nm,SJW
	SetDimLabel 0,3,Steptime_s,SJW
	SetDimLabel 0,4,FlickLocation_V,SJW
	SetDimLabel 0,5,Flickspace_nm,SJW
	SetDimLabel 0,6,SurfaceTime_S,SJW
	SetDimLabel 0,7,JumpTime_s,SJW
	SetDimLabel 0,8,EquilTime_S,SJW
	SetDimLabel 0,9,Bandwidth_kHz,SJW
	SetDimLabel 0,10,Fast,SJW
	SetDimLabel 0,11,AdjustCursors,SJW
	SetDimLabel 0,12,StartingVoltage_V,SJW
	SetDimLabel 0,13,EndingVoltage_V,SJW
end
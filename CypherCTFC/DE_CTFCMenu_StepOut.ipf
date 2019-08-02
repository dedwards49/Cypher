#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma modulename=DE_Menu_StepOut

Static Function Start()

	wave SOW=root:DE_CTFC:StuffToDo:StepOut:StepOutWave
	variable/c Markers=DE_CTFCMenu#PlaceMarkers(0,SOW[%Distance_nm][0]*1e-9/GV("ZLVDTSENS"),SOW,1)
	variable startmultivolt=real(Markers)
	variable endmultivolt=imag(Markers)
	variable startrelativevolt=startmultivolt-td_rv("PIDSLoop.5.Setpoint")
	variable endrelativevolt=endmultivolt-td_rv("PIDSLoop.5.Setpoint")	
	variable/C OutInfo=GenerateStepOut(startrelativevolt,endrelativevolt)
	variable TotalTime=real(OutInfo)
	variable outdecirate=imag(OutInfo)
	variable decirate=50/SOW[%Bandwidth_kHz][0]
	wave DefV_slow=root:DE_CTFC:StuffToDo:StepOut:DefV
	wave ZSnsr_slow=root:DE_CTFC:StuffToDo:StepOut:ZSensor

	wave CW=root:DE_CTFC:StuffToDo:StepOut:CustomWave
	IR_XSetInWavePair(1,"7","Cypher.Input.FastA",DefV_slow,"Cypher.LVDT.Z",ZSnsr_slow,"", -decirate)
	IR_xSetOutWave(2,"7","PIDSLoop.5.Setpointoffset",CW,"DE_Menu_StepOut#Return()",outdecirate)
		DE_CTFCMenu#FastCaptureCheckStart(SOW,totaltime)

	td_SetRamp(.01, "PIDSLoop.5.Setpointoffset", 0, startrelativevolt, "", 0, 0, "", 0, 0, "DE_Menu_StepOut#ExecuteStep()")

	
end

Static Function ExecuteStep()

	wave SOW=root:DE_CTFC:StuffToDo:StepOut:StepOutWave

	if(SOW[%Fast][0]==3)			//Sorts out what High bandwidth measurement we wanna make and prepares them.

		td_WriteValue("Cypher.Capture.0.Trigger", 1)
	elseif(SOW[%Fast][0]==2)

		td_ws("ARC.Events.once", "1")
	elseif(SOW[%Fast][0]==1)	

		td_ws("ARC.Events.once", "1")
	else
	endif
	td_WS("Event.7","Once")
end

Static Function Return()
	td_SetRamp(.01, "PIDSLoop.5.Setpointoffset", 0, 0, "", 0, 0, "", 0, 0, "DE_Menu_StepOut#StepDone()")


end


Static Function StepDone()
	wave SOW=root:DE_CTFC:StuffToDo:StepOut:StepOutWave

	wave DefVolts=root:DE_CTFC:StuffToDo:StepOut:DefV
	wave ZSensorVolts=root:DE_CTFC:StuffToDo:StepOut:ZSensor
	UpdateStepOutandSave(DefVolts,ZSensorVolts)
	DE_CTFCMEnu#SaveWavesOut("StepOut")
	DE_CTFCMenu#DoAPlot("StepOut")
	DE_CTFCMenu#FastCaptureCheckEnd(SOW,"StepOut")

end


Static Function StepDone2()
	DE_CTFCMenu#CheckonPostRamp("StepOut")
end

Static Function/C GenerateStepOut(startvolt,endvolt)
	variable endvolt,startvolt
	wave SOW=root:DE_CTFC:StuffToDo:StepOut:StepOutWave
	variable decirate,stepsize,steptime,pausetime,Zsens,datarate
	decirate=50/SOW[%Bandwidth_kHz][0]
	datarate=SOW[%Bandwidth_kHz][0]
	stepsize=(SOW[%stepsize_nm][0])
	steptime=.01
	pausetime=(SOW[%StepTime_s][0])
	Zsens=GV("ZLVDTSENS")

	variable totaldistance,steps,totalpoints,totalsteptime,slope,i,shift,s1,e1,s2,e2,constant2,corr,newrate,Dirs

	totaldistance=((endvolt-startvolt)*Zsens)
	Dirs=sign(totaldistance)
	steps=ceil(abs(totaldistance)/stepsize*1e9)
	totalsteptime=pausetime+steptime
	totalpoints=round(1e3*datarate*(steps)*(totalsteptime))
	make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:StepOut:ZSensor,root:DE_CTFC:StuffToDo:StepOut:DefV
	if(totalpoints<=50000) //checks if we exceed the limit for IR_xSetOutWave
		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:StepOut:CustomWave
		wave CW=root:DE_CTFC:StuffToDo:StepOut:CustomWave
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

		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:StepOut:CustomWave
		wave CW=root:DE_CTFC:StuffToDo:StepOut:CustomWave
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
	return cmplx(totalsteptime*steps,rdecirate)
End // DE_Custom2_StepOut()


Static Function MakeWave()
	make/o/n=7 root:DE_CTFC:StuffToDo:StepOut:StepOutWave
	wave SOW=root:DE_CTFC:StuffToDo:StepOut:StepOutWave

	SOW={0,50,5,.2,50,1,1}
	
	SetDimLabel 0,0,Location_V,SOW
	SetDimLabel 0,1,Distance_nm,SOW
	SetDimLabel 0,2,Stepsize_nm,SOW
	SetDimLabel 0,3,Steptime_s,SOW
	SetDimLabel 0,4,Bandwidth_kHz,SOW
	SetDimLabel 0,5,Fast,SOW
	SetDimLabel 0,6,AdjustCursors,SOW

end

Static Function UpdateStepOutandSave(Defwave,ZWave)
	wave Defwave,ZWave
	note Defwave DE_CTFCMenu#GenericNoteFile()
	note ZWave DE_CTFCMenu#GenericNoteFile()
	duplicate/o Defwave root:DE_CTFC:StuffToDo:StepOutDef
	duplicate/o ZWave root:DE_CTFC:StuffToDo:StepOutZSnsr
	NVar LSO=  root:DE_CTFC:StuffToDo:StepOut
	variable savenum=LSO+1
	LSO=savenum
	duplicate Defwave $("root:DE_CTFC:StuffToDo:StepOut:Saves:SO_D"+num2str(savenum))
	duplicate ZWave $("root:DE_CTFC:StuffToDo:StepOut:Saves:SO_Z"+num2str(savenum))
end
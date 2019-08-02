#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma modulename=DE_Menu_MultiRamp
Static Function Start()

	wave MRW=root:DE_CTFC:StuffToDo:MRamp:MRampWave
	
	variable outtime,outdecirate,decirate,startmultivolt,endmultivolt,TotalTime
	
	variable/c Markers=DE_CTFCMenu#PlaceMarkers(0,MRW[%Distance_nm][0]*1e-9/GV("ZLVDTSENS"),MRW,1)
	
	startmultivolt=real(Markers)
	endmultivolt=imag(Markers)
	MRW[%StartingVoltage_V][0]=startmultivolt
		MRW[%EndingVoltage_V][0]=endmultivolt

	variable startrelativevolt=startmultivolt-td_rv("PIDSLoop.5.Setpoint")
	variable endrelativevolt=endmultivolt-td_rv("PIDSLoop.5.Setpoint")	
	variable/C OutInfo=GenerateMultiRampOut(startrelativevolt,endrelativevolt)
	TotalTime=real(OutInfo)
	outdecirate=imag(OutInfo)
	decirate=50/MRW[%Bandwidth_kHz][0]
	wave DefVolts_slow=root:DE_CTFC:StuffToDo:MRamp:DefV
	wave ZSensorVolts_slow=root:DE_CTFC:StuffToDo:MRamp:ZSensor
	wave CW=root:DE_CTFC:StuffToDo:MRamp:CustomWave
	IR_XSetInWavePair(1,"7","Cypher.Input.FastA",DefVolts_slow,"Cypher.LVDT.Z",ZSensorVolts_slow,"", -decirate)
	IR_xSetOutWave(2,"7","PIDSLoop.5.Setpointoffset",CW,"DE_Menu_MultiRamp#RampDone()",outdecirate)
	DE_CTFCMenu#FastCaptureCheckStart(MRW,totaltime)

	td_SetRamp(.01, "PIDSLoop.5.Setpointoffset", 0, startrelativevolt, "", 0, 0, "", 0, 0, "DE_Menu_MultiRamp#ExecuteRamp()")
end



Static Function ExecuteRamp()
	wave MRW=root:DE_CTFC:StuffToDo:MRamp:MRampWave

	if(MRW[%Fast][0]==3)			//Sorts out what High bandwidth measurement we wanna make and prepares them.

		td_WriteValue("Cypher.Capture.0.Trigger", 1)
	elseif(MRW[%Fast][0]==2)

		td_ws("ARC.Events.once", "1")
	elseif(MRW[%Fast][0]==1)	

		td_ws("ARC.Events.once", "1")
	else
	endif
	td_WS("Event.7","Once")
end

Static Function RampDone()
	wave MRW=root:DE_CTFC:StuffToDo:MRamp:MRampWave
	wave DefVolts=root:DE_CTFC:StuffToDo:MRamp:DefV
	wave ZSensorVolts=root:DE_CTFC:StuffToDo:MRamp:ZSensor
	UpdateMultiRampandSave(DefVolts,ZSensorVolts)
	DE_CTFCMenu#DoAPlot("MultiRamp")
	DoUpdate/W=MultiRamp
	DE_CTFCMenu#FastCaptureCheckEnd(MRW,"Multi")
end

Static Function RampDone2()
	DE_CTFCMenu#SaveWavesOut("Multi")
	DE_CTFCMenu#CheckonPostRamp("Multi")
end

Static Function UpdateMultiRampandSave(Defwave,ZWave)
	wave Defwave,ZWave
	note Defwave  (MultiNoteFile()+"\r"+DE_CTFCMenu#GenericNoteFile())
	note ZWave (MultiNoteFile()+"\r"+DE_CTFCMenu#GenericNoteFile())
	duplicate/o Defwave root:DE_CTFC:StuffToDo:MultiDef
	duplicate/o ZWave root:DE_CTFC:StuffToDo:MultiZSensor
	NVar LMulti=  root:DE_CTFC:StuffToDo:MultiRamp
	variable savenum=LMulti+1
	LMulti=savenum
	duplicate Defwave $("root:DE_CTFC:StuffToDo:MRamp:Saves:Mramp_D"+num2str(savenum))
	duplicate ZWave $("root:DE_CTFC:StuffToDo:MRamp:Saves:Mramp_Z"+num2str(savenum))
end

Static Function/S MultiNoteFile()

	NVar MRAMPN=root:DE_CTFC:StuffToDo:MultiRamp
	wave MRW=root:DE_CTFC:StuffToDo:MRamp:MRampWave
	String FinalString=""
	variable Bandwidth=(MRW[%Bandwidth_kHz][0])
	variable RetractVelocity=(MRW[%RetractVelocity_nmps][0])
	variable ApproachVelocity=(MRW[%ApproachVelocity_nmps][0])

	variable ApproachPause=(MRW[%ApproachPause_s][0])
	variable RetractPause=(MRW[%RetractPause_s][0])
	variable Repeats=(MRW[%Repeats][0])
	variable startingV=MRW[%StartingVoltage_V][0]
	variable endingV=	MRW[%EndingVoltage_V][0]

	FinalString=	ReplaceStringByKey("Type", FinalString,"Mramp",":","\r")
	FinalString=	ReplaceStringByKey("Number", FinalString,num2str(MRAMPN),":","\r")
	FinalString=	ReplaceStringByKey("Bandwidth", FinalString,num2str(Bandwidth),":","\r")

	FinalString=	ReplaceStringByKey("RetractVelocity", FinalString,num2str(RetractVelocity),":","\r")

	FinalString=	ReplaceStringByKey("ApproachVelocity", FinalString,num2str(ApproachVelocity),":","\r")
	FinalString=	ReplaceStringByKey("ApproachPause", FinalString,num2str(ApproachPause),":","\r")
	FinalString=	ReplaceStringByKey("RetractPause", FinalString,num2str(RetractPause),":","\r")
	FinalString=	ReplaceStringByKey("ApproachPause", FinalString,num2str(ApproachPause),":","\r")
	FinalString=	ReplaceStringByKey("RetractPause", FinalString,num2str(RetractPause),":","\r")
	FinalString=	ReplaceStringByKey("Repeats", FinalString,num2str(Repeats),":","\r")
	return FinalString
end

Static Function/C GenerateMultiRampOut(startvoltage,endvoltage)
	variable startvoltage,endvoltage
	wave MRW=root:DE_CTFC:StuffToDo:MRamp:MRampWave
	variable totalpoints,slopeout,decirate,distance,outdecirate,constant2,endrmp1,endpause1,endrmp2,endpause2,slopein
	//	
	decirate=50/MRW[%Bandwidth_kHz][0]
	distance=(endvoltage-startvoltage)*gv("ZLVDTSENS")
	totalpoints=MRW[%Bandwidth_kHz][0]*(abs(distance)/(MRW[%ApproachVelocity_nmps][0])/1e-9+abs(distance)/(MRW[%RetractVelocity_nmps][0])/1e-9+(MRW[%RetractPause_s][0])+(MRW[%ApproachPause_s][0]))*1e3
	make/o/n=(MRW[%Repeats][0]*totalpoints) root:DE_CTFC:StuffToDo:MRamp:ZSensor,root:DE_CTFC:StuffToDo:MRamp:DefV
	variable point2per=round(70000/MRW[%Repeats][0])
	if(totalpoints<=point2per) //checks if we exceed the limit for IR_xSetOutWave
		outdecirate=decirate
		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:MRamp:CustomWavePiece
		wave CW=root:DE_CTFC:StuffToDo:MRamp:CustomWavePiece
		slopeout=sign(distance)/2*MRW[%RetractVelocity_nmps][0]/GV("ZLVDTSens")*1e-9/(50e3/outdecirate)  //The Sign in front tells us if we're ramping negative or positive.
		slopein=sign(distance)/2*MRW[%ApproachVelocity_nmps][0]/GV("ZLVDTSens")*1e-9/(50e3/outdecirate)  //The Sign in front tells us if we're ramping negative or positive.

		constant2=startvoltage
		endrmp1=round(50e3/outdecirate*(abs(distance)/(MRW[%RetractVelocity_nmps][0]*1e-9)))
		endpause1=endrmp1+round(50e3/outdecirate*MRW[%RetractPause_s][0])
		endrmp2=endpause1+round(50e3/outdecirate*(abs(distance)/(MRW[%ApproachVelocity_nmps][0]*1e-9)))
		endpause2=endrmp2+round(50e3/outdecirate*(MRW[%ApproachPause_s][0]))
		CW[0,endrmp1-1]=slopeout*p+constant2
		CW[endrmp1,endpause1-1]=slopeout*endrmp1+constant2
		CW[endpause1,endrmp2-1]=slopeout*endrmp1+constant2-slopein*(p-endpause1+1)
		CW[endrmp2,]=constant2

	else
		totalpoints=point2per
		outdecirate=round((50000/totalpoints)*(abs(distance)/MRW[%RetractVelocity_nmps][0]/1e-9+abs(distance)/MRW[%ApproachVelocity_nmps][0]/1e-9+ MRW[%RetractPause_s][0]+ MRW[%ApproachPause_s][0]))
		totalpoints=50000*(abs(distance)/MRW[%RetractVelocity_nmps][0]/1e-9+abs(distance)/MRW[%ApproachVelocity_nmps][0]/1e-9+ MRW[%RetractPause_s][0]+ MRW[%ApproachPause_s][0])/outdecirate
		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:MRamp:CustomWavePiece
		wave CW=root:DE_CTFC:StuffToDo:MRamp:CustomWavePiece
		slopeout=sign(distance)*MRW[%RetractVelocity_nmps][0]/GV("ZLVDTSens")*1e-9/(50e3/outdecirate)  //The Sign in front tells us if we're ramping negative or positive.
		slopein=sign(distance)*MRW[%ApproachVelocity_nmps][0]/GV("ZLVDTSens")*1e-9/(50e3/outdecirate)  //The Sign in front tells us if we're ramping negative or positive.

		constant2=startvoltage
		endrmp1=round(50e3/outdecirate*(abs(distance)/(MRW[%RetractVelocity_nmps][0]*1e-9)))
		endpause1=endrmp1+round(50e3/outdecirate*MRW[%RetractPause_s][0])
		endrmp2=endpause1+round(50e3/outdecirate*(abs(distance)/(MRW[%ApproachVelocity_nmps][0]*1e-9)))
		endpause2=endrmp2+round(50e3/outdecirate*(MRW[%ApproachPause_s][0]))
		CW[0,endrmp1-1]=slopeout*p+constant2
		CW[endrmp1,endpause1-1]=slopeout*endrmp1+constant2
		CW[endpause1,endrmp2-1]=slopeout*endrmp1+constant2-slopein*(p-endpause1+1)
		CW[endrmp2,]=constant2
	endif

	variable n=0

	String waveliststring=""
	for(n=0;n<MRW[%Repeats][0];n+=1)
		waveliststring+=GetWavesDataFolder(cw, 4 )+";"
	endfor
	Concatenate/NP /o waveliststring, cwout
	duplicate/o cwout root:DE_CTFC:StuffToDo:MRamp:CustomWave
	killwaves CW,CWOUT
	return cmplx(MRW[%Repeats][0]*totalpoints/(50e3/outdecirate),outdecirate)
End

Static Function MakeWave()
	make/o/n=12 root:DE_CTFC:StuffToDo:MRamp:MRampWave
	wave MRW=root:DE_CTFC:StuffToDo:MRamp:MRampWave

	MRW={0,30,50,50,0.5,0,5,50,0,1,0,0}
	
	SetDimLabel 0,0,Starting_V,MRW
	SetDimLabel 0,1,Distance_nm,MRW
	SetDimLabel 0,2,RetractVelocity_nmps,MRW
	SetDimLabel 0,3,ApproachVelocity_nmps,MRW
	SetDimLabel 0,4,ApproachPause_s,MRW
	SetDimLabel 0,5,RetractPause_s,MRW
	SetDimLabel 0,6,Repeats,MRW
	SetDimLabel 0,7,Bandwidth_kHz,MRW
	SetDimLabel 0,8,Fast,MRW
	SetDimLabel 0,9,AdjustCursors,MRW
	SetDimLabel 0,10,StartingVoltage_V,MRW
	SetDimLabel 0,11,EndingVoltage_V,MRW
end

#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma modulename=DE_Menu_SingleRamp
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Single Ramp Proc.
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function Start(EndString)
	string EndString
	wave SRW=root:DE_CTFC:StuffToDo:SRamp:SRampWave
	variable outtime,outdecirate,decirate
	variable/C OutInfo=GenerateSRampOut()
	outtime=real(OutInfo)
	outdecirate=imag(OutInfo)
	decirate=50/SRW[%Bandwidth_kHz][0]
	wave DefVolts_slow=root:DE_CTFC:StuffToDo:SRamp:DefV
	wave ZSensorVolts_slow=root:DE_CTFC:StuffToDo:SRamp:ZSensor
	wave CW=root:DE_CTFC:StuffToDo:SRamp:CustomWave2
	td_XSetInWavePair(0,"14","Cypher.Input.FastA",DefVolts_slow,"Cypher.LVDT.Z",ZSensorVolts_slow,"", -decirate)
	ir_xSetOutWave(0,"14","PIDSLoop.5.Setpointoffset",root:DE_CTFC:StuffToDo:SRamp:CustomWave2,"DE_Menu_SingleRamp#SRAmpDone(\""+EndString+"\")",outdecirate)
	td_WS("Event.14","Once")
end

Static Function/C GenerateSRampOut()
	wave SRW=root:DE_CTFC:StuffToDo:SRamp:SRampWave
	variable totalpoints,slope2,decirate,totaldistance,outdecirate,constant2,endrmp1,endpause1,endrmp2
	
	decirate=50/SRW[%Bandwidth_kHz][0]
	totaldistance=2*SRW[%Distance_nm][0]*1e-9
	totalpoints=SRW[%Bandwidth_kHz][0]*(2*SRW[%Distance_nm][0]/(SRW[%Velocity_nmps][0])+(SRW[%RetractPause_s][0]))*1e3

	make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:SRamp:ZSensor,root:DE_CTFC:StuffToDo:SRamp:DefV
	
	if(totalpoints<=5000) //checks if we exceed the limit for IR_xSetOutWave
		outdecirate=decirate
		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:SRamp:CustomWave2
		wave CW=root:DE_CTFC:StuffToDo:SRamp:CustomWave2
		slope2=sign(totaldistance)*SRW[%Velocity_nmps][0]/GV("ZLVDTSens")*1e-9/(50e3/outdecirate)  //The Sign in front tells us if we're ramping negative or positive.
		constant2=0
		endrmp1=round(50e3/outdecirate*(abs(totaldistance)/(SRW[%Velocity_nmps][0]*1e-9)/2))
		endpause1=endrmp1+round(50e3/outdecirate*SRW[%RetractPause_s][0])
		endrmp2=endpause1+endrmp1
		CW[0,endrmp1-1]=slope2*p+constant2
		CW[endrmp1,endpause1-1]=slope2*endrmp1+constant2
		CW[endpause1,]=slope2*endrmp1+constant2-slope2*(p-endpause1+1)

	else
		totalpoints=5000
		outdecirate=round(50000/totalpoints)*(abs(totaldistance)/SRW[%Velocity_nmps][0]/1e-9+ SRW[%RetractPause_s][0])
 
		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:SRamp:CustomWave2
		wave CW=root:DE_CTFC:StuffToDo:SRamp:CustomWave2
		slope2=sign(totaldistance)*SRW[%Velocity_nmps][0]/GV("ZLVDTSens")*1e-9/(50e3/outdecirate)  //The Sign in front tells us if we're ramping negative or positive.
		constant2=0
		endrmp1=round(50e3/outdecirate*(abs(totaldistance)/(SRW[%Velocity_nmps][0]*1e-9)/2))
		endpause1=endrmp1+round(50e3/outdecirate*SRW[%RetractPause_s][0])
		endrmp2=endpause1+endrmp1
		CW[0,endrmp1-1]=slope2*p+constant2
		CW[endrmp1,endpause1-1]=slope2*endrmp1+constant2
		CW[endpause1,]=slope2*endrmp1+constant2-slope2*(p-endpause1+1)
		
	endif
	variable offset=td_ReadValue("PIDSLoop.5.Setpoint")//This adjusts the wave to be a setrampoffset, rather than a straight setramp. 
	//	//this way I don't have to worry about it, but I honestly don't quite understand this
	CW*=-1
	if(numtype(offset)==0)		
		//FastOP CW=CW-(offset)
	else
	endif

	return cmplx(totalpoints/(50e3/outdecirate),outdecirate)

End

Static Function SRAmpDone(EndString)
	string EndString
	wave DefVolts=root:DE_CTFC:StuffToDo:SRamp:DefV
	wave ZSensorVolts=root:DE_CTFC:StuffToDo:SRamp:ZSensor
	UpdateLastRampandSave(DefVolts,ZSensorVolts)
	DE_CTFCMenu#SaveWavesOut("Ramp")
	DE_CTFCMenu#DoAPlot("SingleRamp")
	DoUpdate/W=LatestRamp
	if(cmpstr(EndString,"")==0)
		
	else
		DE_CTFCMenu#RampHandoff(EndString)
	endif
end

Static Function UpdateLastRampandSave(Defwave,ZWave)
	wave Defwave,ZWave
	note Defwave DE_CTFCMenu#GenericNoteFile()
	note ZWave DE_CTFCMenu#GenericNoteFile()
	duplicate/o Defwave root:DE_CTFC:StuffToDo:LastDef
	duplicate/o ZWave root:DE_CTFC:StuffToDo:LastZSensor
	NVar LRamp= root:DE_CTFC:StuffToDo:LastRamp
	variable savenum=LRamp+1
	LRamp=savenum
	
	duplicate Defwave $("root:DE_CTFC:StuffToDo:SRamp:Saves:Sramp_D"+num2str(savenum))
	duplicate ZWave $("root:DE_CTFC:StuffToDo:SRamp:Saves:Sramp_Z"+num2str(savenum))
end
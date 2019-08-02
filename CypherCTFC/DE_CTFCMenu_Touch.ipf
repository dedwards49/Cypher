#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma modulename=DE_Menu_Touch

Static Function Start()
	wave SW=root:DE_CTFC:StuffToDo:Touch:SurfaceWave
	
	
	variable outtime,outdecirate,decirate
	variable/C OutInfo=GenerateTouchOut()
	outtime=real(OutInfo)
	outdecirate=imag(OutInfo)
	decirate=50/SW[%Bandwidth_kHz][0]
	wave DefVolts_slow=root:DE_CTFC:StuffToDo:Touch:DefV
	wave ZSensorVolts_slow=root:DE_CTFC:StuffToDo:Touch:ZSensor
	wave CW=root:DE_CTFC:StuffToDo:Touch:CustomWave
	td_XSetInWavePair(0,"14","Cypher.Input.FastA",DefVolts_slow,"Cypher.LVDT.Z",ZSensorVolts_slow,"", -decirate)
	ir_xSetOutWave(0,"14","PIDSLoop.5.Setpointoffset",CW,"DE_Menu_Touch#TouchDone()",outdecirate)
	td_WS("Event.14","Once")

end

Static Function TouchDone()
	wave DefVolts=root:DE_CTFC:StuffToDo:Touch:DefV
	wave ZSensorVolts=root:DE_CTFC:StuffToDo:Touch:ZSensor
	UpdateTouchandSave(DefVolts,ZSensorVolts)
	SVar LTouch=root:DE_CTFC:StuffToDo:LastTouchTime
	LTouch=time()
	DE_CTFCMenu#SaveWavesOut("Touch")
	DE_CTFCMenu#DoAPlot("Touch")
	DE_CTFCMenu#CheckonPostRamp("Touch")
end


Static Function UpdateTouchandSave(Defwave,ZWave)
	wave Defwave,ZWave
	note Defwave DE_CTFCMenu#GenericNoteFile()
	note ZWave DE_CTFCMenu#GenericNoteFile()
	duplicate/o Defwave root:DE_CTFC:StuffToDo:TouchDef
	duplicate/o ZWave root:DE_CTFC:StuffToDo:TouchZSensor
	NVar Ltouch=  root:DE_CTFC:StuffToDo:LastTouch
	variable savenum=Ltouch+1
	Ltouch=savenum
	duplicate Defwave $("root:DE_CTFC:StuffToDo:Touch:Saves:Touch_D"+num2str(savenum))
	duplicate ZWave $("root:DE_CTFC:StuffToDo:Touch:Saves:Touch_Z"+num2str(savenum))
end

Static Function/C GenerateTouchOut()
	wave SW=root:DE_CTFC:StuffToDo:Touch:SurfaceWave
	variable totalpoints,slope2,decirate,totaldistance,outdecirate,constant2,endrmp1,endpause1,endrmp2
	decirate=50/SW[%Bandwidth_kHz][0]
	totaldistance=2*SW[%IndentDistance_nm][0]*1e-9
	totalpoints=SW[%Bandwidth_kHz][0]*(1e9*totaldistance/(SW[%Velocity_nmps][0])+(SW[%Pause_s][0]))*1e3

	make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:Touch:ZSensor,root:DE_CTFC:StuffToDo:Touch:DefV
	
	if(totalpoints<=5000) //checks if we exceed the limit for IR_xSetOutWave
		outdecirate=decirate
		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:Touch:CustomWave
		wave CW=root:DE_CTFC:StuffToDo:Touch:CustomWave
		slope2=sign(totaldistance)*SW[%Velocity_nmps][0]/GV("ZLVDTSens")*1e-9/(50e3/outdecirate)  //The Sign in front tells us if we're ramping negative or positive.
		constant2=0
		endrmp1=round(50e3/outdecirate*(abs(totaldistance)/(SW[%Velocity_nmps][0]*1e-9)/2))
		endpause1=endrmp1+round(50e3/outdecirate*SW[%Pause_s][0])
		endrmp2=endpause1+endrmp1
		CW[0,endrmp1-1]=slope2*p+constant2
		CW[endrmp1,endpause1-1]=slope2*endrmp1+constant2
		CW[endpause1,]=slope2*endrmp1+constant2-slope2*(p-endpause1+1)
	else
		totalpoints=5000
		outdecirate=round(50000/totalpoints)*(abs(totaldistance)/SW[%Velocity_nmps][0]/1e-9+ SW[%Pause_s][0])
		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:Touch:CustomWave
		wave CW=root:DE_CTFC:StuffToDo:Touch:CustomWave
		slope2=sign(totaldistance)*SW[%Velocity_nmps][0]/GV("ZLVDTSens")*1e-9/(50e3/outdecirate)  //The Sign in front tells us if we're ramping negative or positive.
		constant2=0
		endrmp1=round(50e3/outdecirate*(abs(totaldistance)/(SW[%Velocity_nmps][0]*1e-9)/2))
		endpause1=endrmp1+round(50e3/outdecirate*SW[%Pause_s][0])
		endrmp2=endpause1+endrmp1
		CW[0,endrmp1-1]=slope2*p+constant2
		CW[endrmp1,endpause1-1]=slope2*endrmp1+constant2
		CW[endpause1,]=slope2*endrmp1+constant2-slope2*(p-endpause1+1)
		//		
	endif
	return cmplx(totalpoints/(50e3/outdecirate),outdecirate)
End

Static Function MakeWave()
	make/o/n=4 root:DE_CTFC:StuffToDo:Touch:SurfaceWave
	wave SW=root:DE_CTFC:StuffToDo:Touch:SurfaceWave

	SW={15,400,.1,1}
	
	SetDimLabel 0,0,IndentDistance_nm,SW
	SetDimLabel 0,1,Velocity_nmps,SW
	SetDimLabel 0,2,Pause_s,SW

	SetDimLabel 0,3,Bandwidth_kHz,SW

end
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma modulename=DE_Menu_Thermal


Static Function Start()
	wave TW=root:DE_CTFC:StuffToDo:Thermal:ThermalWave

	variable outtime,outdecirate,decirate
	variable/C OutInfo=GenerateThermalOut()
	outtime=real(OutInfo)
	outdecirate=imag(OutInfo)
	decirate=50/TW[%Bandwidth_kHz][0]
	wave DefVolts_slow=root:DE_CTFC:StuffToDo:Thermal:RampDefV
	wave ZSensorVolts_slow=root:DE_CTFC:StuffToDo:Thermal:RampZSensor
	wave CW=root:DE_CTFC:StuffToDo:Thermal:CustomWave
	td_XSetInWavePair(0,"14","Cypher.Input.FastA",DefVolts_slow,"Cypher.LVDT.Z",ZSensorVolts_slow,"", -decirate)
	ir_xSetOutWave(0,"14","PIDSLoop.5.Setpointoffset",CW,"DE_CTFCMenu#ThermalRamped()",outdecirate)
	td_WS("Event.14","Once")
	//
end
//
Static Function ThermalRamped()
	wave TW=root:DE_CTFC:StuffToDo:Thermal:ThermalWave
	td_WriteValue("Cypher.Capture.0.Rate", 2)
	td_WriteValue("Cypher.Capture.0.Length", 5e6*(TW[%Time_s]))
	td_WriteValue("Cypher.Capture.0.Trigger", 1)
	td_wv("output.a",.01)
	td_SetRamp(1.1*TW[%Time_s], "output.a", 0,0, "", 0, 0, "", 0, 0, "DE_CTFCMenu#ThermalDone()")
end

Static Function ThermalDone()
	DE_MFastCap#ThermalRead("Read","HI")
		
end

Static Function ReadDone()
	wave DefVolts= root:DE_CTFC:StuffToDo:ThermalRead
	UpdateThermalandSave()	//UpdateTouchandSave(DefVolts,ZSensorVolts)
	SVar LThermal=root:DE_CTFC:StuffToDo:LastThermalTime
	LThermal=time()
	DE_CTFCMenu#DoAPlot("Thermal")
	DE_CTFCMenu#CheckonPostRamp("Thermal")
end

//
//
Static Function UpdateThermalandSave()
	wave Defwave= root:DE_CTFC:StuffToDo:ThermalRead
	note Defwave DE_CTFCMenu#GenericNoteFile()
	NVar LThermal=  root:DE_CTFC:StuffToDo:LastThermal
	variable savenum=LThermal+1
	LThermal=savenum
	duplicate Defwave $("root:DE_CTFC:StuffToDo:Thermal:Saves:Thermal_"+num2str(savenum))
end
//
Static Function/C GenerateThermalOut()
	wave TW=root:DE_CTFC:StuffToDo:Thermal:ThermalWave
	variable totalpoints,slope2,decirate,totaldistance,outdecirate,constant2,endrmp1,endpause1,endrmp2
	decirate=50/TW[%Bandwidth_kHz][0]
	totaldistance=-TW[%RetractDistance_nm][0]*1e-9
	totalpoints=TW[%Bandwidth_kHz][0]*(1e9*abs(totaldistance)/(TW[%Velocity_nmps][0]))*1e3

	make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:Thermal:RampZSensor,root:DE_CTFC:StuffToDo:Thermal:RampDefV
	//	
	if(totalpoints<=5000) //checks if we exceed the limit for IR_xSetOutWave
		outdecirate=decirate
		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:Thermal:CustomWave
		wave CW=root:DE_CTFC:StuffToDo:Thermal:CustomWave
		slope2=sign(totaldistance)*TW[%Velocity_nmps][0]/GV("ZLVDTSens")*1e-9/(50e3/outdecirate)  //The Sign in front tells us if we're ramping negative or positive.
		CW=slope2*p+constant2	
		//CW[0,endrmp1-1]=slope2*p+constant2
		//CW[endrmp1,endpause1-1]=slope2*endrmp1+constant2
		//CW[endrmp1,]=slope2*endrmp1+constant2-slope2*(p-endrmp1+1)
	else
		totalpoints=5000
		outdecirate=round(50000/abs(totalpoints))*(abs(totaldistance)/TW[%Velocity_nmps][0]/1e-9)
		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:Thermal:CustomWave
		wave CW=root:DE_CTFC:StuffToDo:Thermal:CustomWave
		slope2=sign(totaldistance)*TW[%Velocity_nmps][0]/GV("ZLVDTSens")*1e-9/(50e3/outdecirate)  //The Sign in front tells us if we're ramping negative or positive.
		constant2=0
		endrmp1=round(50e3/outdecirate*(abs(totaldistance)/(TW[%Velocity_nmps][0]*1e-9)))

		endrmp2=endpause1+endrmp1
		CW=slope2*p+constant2	

		//CW[0,endrmp1-1]=slope2*p+constant2
		//CW[endrmp1,endpause1-1]=slope2*endrmp1+constant2
		//CW[endrmp1,]=slope2*endrmp1+constant2-slope2*(p-endrmp1+1)
		//		
	endif
	return cmplx(totalpoints/(50e3/outdecirate),outdecirate)
End

Static Function MakeWave()
	make/o/n=3 root:DE_CTFC:StuffToDo:Thermal:ThermalWave
	wave TW=root:DE_CTFC:StuffToDo:Thermal:ThermalWave

	TW={15,400,1,1}
	
	SetDimLabel 0,0,RetractDistance_nm,TW
	SetDimLabel 0,1,Velocity_nmps,TW
	SetDimLabel 0,2,Time_s,TW
	SetDimLabel 0,3,Bandwidth_kHz,TW

end
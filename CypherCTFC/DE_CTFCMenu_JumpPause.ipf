#pragma rtGlobals=3		// Use modern global access method and strict wave access.
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Jump Pause Procs
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma modulename=DE_Menu_JumpPause


Static Function Start()
	wave JPW=root:DE_CTFC:StuffToDo:JumpPause:JumpPauseWave
	variable decirate,VoltageLocation,endvolt,TotalTime,outdecirate,DataLength
	variable/c outwaveinfo
	decirate=50/JPW[%Bandwidth_kHz][0]
	endvolt=td_rv("PIDSLoop.5.Setpoint")-JPW[%Location_V][0]
	endvolt=real(DE_CTFCMenu#PlaceMarkers(endvolt,0,JPW,0))
	JPW[%Location_V]=endvolt
	//	
	endvolt-=td_rv("PIDSLoop.5.Setpoint")
	outwaveinfo=GenerateJumpPause(endvolt)
	wave DefVEquil= root:DE_CTFC:StuffToDo:JumpPause:DefV
	wave ZSnsrVEquil=root:DE_CTFC:StuffToDo:JumpPause:ZSnsr //These are the waves that are to be read during this process. We don't adjust their size.
	wave OutWave=root:DE_CTFC:StuffToDo:JumpPause:JumpPauseOut

	TotalTime=real(outwaveinfo)
	outdecirate=imag(outwaveinfo)

	IR_XSetInWavePair(1,"7","Cypher.Input.FastA",DefVEquil,"Cypher.LVDT.Z",ZSnsrVEquil,"", -decirate)
	IR_xSetOutWave(2,"7","PIDSLoop.5.Setpointoffset",OutWave,"DE_Menu_JumpPause#JPDone()",outdecirate)
	
	DE_CTFCMenu#FastCaptureCheckStart(JPW,totaltime)

	td_WS("Event.7","Once")
end
//


Static Function JPDone()
	wave JPW=root:DE_CTFC:StuffToDo:JumpPause:JumpPauseWave
	wave DefVEquil= root:DE_CTFC:StuffToDo:JumpPause:DefV
	wave ZSnsrVEquil=root:DE_CTFC:StuffToDo:JumpPause:ZSnsr //These are the waves that are to be read during this process. We don't adjust their size.
	//wave OutWave=root:DE_CTFC:StuffToDo:JumpPause:JumpPauseOut
	UpdateJumpPauseandSave(DefVEquil,ZSnsrVEquil)
	DE_CTFCMenu#DoAPlot("JumpPause")
	DoUpdate/W=JumpPause
	DE_CTFCMenu#FastCaptureCheckEnd(JPW,"JumpPause")
end

Static Function JPDone2()
	DE_CTFCMenu#SaveWavesOut("JumpPause")
	DE_CTFCMenu#CheckonPostRamp("JumpPause")
end
Static Function UpdateJumpPauseandSave(Defwave,ZWave)
	wave Defwave,ZWave
	note Defwave DE_CTFCMenu#GenericNoteFile()
	note ZWave DE_CTFCMenu#GenericNoteFile()
	duplicate/o Defwave root:DE_CTFC:StuffToDo:RecentJumpDef
	duplicate/o ZWave root:DE_CTFC:StuffToDo:RecentJumpZSn
	NVar JumpPause= root:DE_CTFC:StuffToDo:JumpPause
	variable savenum=JumpPause+1
	duplicate Defwave $("root:DE_CTFC:StuffToDo:JumpPause:Saves:Jump_D"+num2str(savenum))
	duplicate ZWave $("root:DE_CTFC:StuffToDo:JumpPause:Saves:Jump_Z"+num2str(savenum))
	JumpPause=savenum

end







function/C GenerateJumpPause(position)
	variable position

	wave JPW=root:DE_CTFC:StuffToDo:JumpPause:JumpPauseWave
	variable EquilibriumPause,setpoint,datarate,TimeToStart,totaltime,totalpoints,outrate,slope,StartRise,Endrise,StartFall,EndFall,newrate
	setpoint=td_rv("PIDSLoop.5.Setpoint")

	EquilibriumPause=JPW[%Time_s][0]
	datarate=JPW[%Bandwidth_kHz][0]*1e3
	TimeToStart=0.01

	totaltime=(EquilibriumPause+2*TimeToStart)
	totalpoints=round(datarate*totaltime)
	make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:JumpPause:DefV,root:DE_CTFC:StuffToDo:JumpPause:ZSnsr //These are the waves that are to be read during this process. We don't adjust their size.
	if(totalpoints<=5000) //checks if we exceed the limit for IR_xSetOutWave
		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:JumpPause:JumpPauseOut
		wave OutWave=root:DE_CTFC:StuffToDo:JumpPause:JumpPauseOut
		outrate=newrate
		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:JumpPause:JumpPauseOut
		wave OutWave=root:DE_CTFC:StuffToDo:JumpPause:JumpPauseOut
		slope=1/(TimeToStart*outrate-1)
		StartRise=0
		Endrise=StartRise+TimeToStart*outrate
		StartFall=Endrise+EquilibriumPause*outrate
		EndFall=StartFall+TimetoStart*outrate
		OutWave[StartRise,Endrise]=(x-StartRise)*slope
		OutWave[Endrise,StartFall-1]=1
		OutWave[StartFall,EndFall-1]=1-(x-StartFall)*slope
	else	//If we do, run with as high a bandwidth as we can while limitting the total points to 87000
		totalpoints=5000
		newrate=round(totalpoints/(EquilibriumPause+2*TimeToStart))/1e3
		variable rdecirate=ceil(50/newrate)
		newrate=50e3/rdecirate
		totalpoints=round(newrate*(EquilibriumPause+2*TimeToStart))
		outrate=newrate
		make/o/n=(totalpoints) root:DE_CTFC:StuffToDo:JumpPause:JumpPauseOut
		wave OutWave=root:DE_CTFC:StuffToDo:JumpPause:JumpPauseOut
		slope=1/(TimeToStart*outrate-1)
		StartRise=0
		Endrise=StartRise+TimeToStart*outrate
		StartFall=Endrise+EquilibriumPause*outrate
		EndFall=StartFall+TimetoStart*outrate
		OutWave[StartRise,Endrise]=(x-StartRise)*slope
		OutWave[Endrise,StartFall-1]=1
		OutWave[StartFall,EndFall-1]=1-(x-StartFall)*slope

	endif
	OutWave*=position

	return cmplx(totaltime,50000/outrate)
end

Static Function MakeWave()
	make/o/n=5 root:DE_CTFC:StuffToDo:JumpPause:JumpPauseWave
	wave JPW=root:DE_CTFC:StuffToDo:JumpPause:JumpPauseWave

	JPW={0,1,50,0,1}
	
	SetDimLabel 0,0,Location_V,JPW
	SetDimLabel 0,1,Time_s,JPW
	SetDimLabel 0,2,Bandwidth_kHz,JPW
	SetDimLabel 0,3,Fast,JPW
	SetDimLabel 0,4,AdjustCursors,JPW

end
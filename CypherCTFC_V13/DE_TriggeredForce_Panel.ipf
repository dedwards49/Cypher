00#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	DE_ListWaveFunc(popstr)	

End//PopMenuProc

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function PopMenuProc1(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	

End//PopMenuProc1

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function PopMenuProc2(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	

End//PopMenuProc1

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function PopMenuProc3(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	

End//PopMenuProc1


Function PopMenuProc4(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	

End//PopMenuProc1
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function ListBoxProc(ctrlName,row,col,event) : ListBoxControl
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
					//5=cell select with shift key, 6=begin edit, 7=end
					
	switch(event)
		
		case 7:
		
		controlinfo popup0
		
		strswitch (s_value)
		
			case "Glide":
				duplicate/o root:DE_CTFC:MenuStuff:ListPullwave root:DE_CTFC:MenuStuff:Glide_Wave
			break
		
			case "Step Out":
				duplicate/o root:DE_CTFC:MenuStuff:ListPullwave root:DE_CTFC:MenuStuff:StepOut_Wave
			break
			case "MultiRamp":
				duplicate/o root:DE_CTFC:MenuStuff:ListPullwave root:DE_CTFC:MenuStuff:MultiRamp_Wave
			break
				case "MultiCTFC":
				duplicate/o root:DE_CTFC:MenuStuff:ListPullwave root:DE_CTFC:MenuStuff:MultiCTFC_Wave
			break

	
		endswitch
		
		break	
		
	endswitch				
	
	return 0
End //ListBoxProc

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function ListBoxProc1(ctrlName,row,col,event) : ListBoxControl
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
					//5=cell select with shift key, 6=begin edit, 7=end

	return 0
End //ListBoxProc
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function ListBoxProc2(ctrlName,row,col,event) : ListBoxControl
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
					//5=cell select with shift key, 6=begin edit, 7=end

	return 0
End //ListBoxProc

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function ButtonProc_1(ctrlName) : ButtonControl
	String ctrlName
	
	controlinfo popup0
	string ExpType=S_value
	controlinfo check0
	variable Existing=V_value
	wave/t wpar=root:DE_CTFC:MenuStuff:ListPullwave
	wave/t wrep=root:DE_CTFC:MenuStuff:ListRepwave
wave/t Command=root:DE_CTFC:MenuStuff:ListComwave
	strswitch(ExpType)
	
		case "Glide":
			DE_Setup("Glide",wpar,wrep)
			
			if(strsearch(tracenamelist("DE_CTFC_Control#MostRecent","",1),"Display_DefV_1",0)==-1) 

				appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_1 vs root:DE_CTFC:MenuStuff:Display_ZSensor_1
			else
			
			endif
			
			if(strsearch(tracenamelist("DE_CTFC_Control#MostRecent","",1),"Display_DefV_2",0)==-1) 
				appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_2 vs root:DE_CTFC:MenuStuff:Display_ZSensor_2
				ModifyGraph rgb(Display_DefV_2)=(0,0,0)
				ModifyGraph hideTrace(Display_DefV_2)=1
			
			else
			endif
			SetAxis/A/W=DE_CTFC_Control#MostRecent

			break
				
		case "Step Out":
			DE_Setup("Step Out",wpar,wrep)
			
			if(strsearch(tracenamelist("DE_CTFC_Control#MostRecent","",1),"Display_DefV_1",0)==-1) 
				appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_1 vs root:DE_CTFC:MenuStuff:Display_ZSensor_1
			else
			
			endif
			
			if(strsearch(tracenamelist("DE_CTFC_Control#MostRecent","",1),"Display_DefV_2",0)==-1) 
			
				appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_2 vs root:DE_CTFC:MenuStuff:Display_ZSensor_2
			else
			endif

			break
			
		case "Step Out Equil":
			DE_Setup("Step Out Equil",wpar,wrep)
			
			if(strsearch(tracenamelist("DE_CTFC_Control#MostRecent","",1),"Display_DefV_1",0)==-1) 
				appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_1 vs root:DE_CTFC:MenuStuff:Display_ZSensor_1
			else
			
			endif
			
			if(strsearch(tracenamelist("DE_CTFC_Control#MostRecent","",1),"Display_DefV_2",0)==-1) 
			
				appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_2 vs root:DE_CTFC:MenuStuff:Display_ZSensor_2
			else
			endif

			break
			
			
				case "MultiRamp":
			DE_Setup("MultiRamp",wpar,wrep)
			
			if(strsearch(tracenamelist("DE_CTFC_Control#MostRecent","",1),"Display_DefV_1",0)==-1) 
				appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_1 vs root:DE_CTFC:MenuStuff:Display_ZSensor_1
			else
			
			endif
			
			if(strsearch(tracenamelist("DE_CTFC_Control#MostRecent","",1),"Display_DefV_2",0)==-1) 
			
				appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_2 vs root:DE_CTFC:MenuStuff:Display_ZSensor_2
			else
			endif

			break
			
			case "MultiRamp Open":
			DE_Setup("MultiRamp Open",wpar,wrep)
			
			if(strsearch(tracenamelist("DE_CTFC_Control#MostRecent","",1),"Display_DefV_1",0)==-1) 
				appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_1 vs root:DE_CTFC:MenuStuff:Display_ZSensor_1
			else
			
			endif
			
			if(strsearch(tracenamelist("DE_CTFC_Control#MostRecent","",1),"Display_DefV_2",0)==-1) 
			
				appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_2 vs root:DE_CTFC:MenuStuff:Display_ZSensor_2
			else
			endif

			break
			
			case "MultiCTFC":
			DE_Setup("MultiCTFC",wpar,wrep)
			
			if(strsearch(tracenamelist("DE_CTFC_Control#MostRecent","",1),"Display_DefV_1",0)==-1) 
				appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_1 vs root:DE_CTFC:MenuStuff:Display_ZSensor_1
			else
			
			endif
			
			if(strsearch(tracenamelist("DE_CTFC_Control#MostRecent","",1),"Display_DefV_2",0)==-1) 
			
				appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_2 vs root:DE_CTFC:MenuStuff:Display_ZSensor_2
			else
			endif

			break
	
		
	endswitch
	
	controlinfo popup3	
	
	if(cmpstr(S_value,"No")==0)
		//print "DE_StartCTFC(\"Run\")"
		Command="DE_StartCTFC(\"Run\")"
	//	DE_StartCTFC("Run")
	else
		if(Existing==0)
			//print "DE_StartCTFC(\"Find\")"
			Command="DE_StartCTFC(\"Find\")"
		//	DE_StartCTFC("Find")

		else
			//print "DE_StartCTFC(\"Run\")"
			Command="DE_StartCTFC(\"Run\")"

		//	DE_StartCTFC("Run")
		endif
	endif
	

			
			
End//ButtonProc

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function ButtonProc_2(ctrlName) : ButtonControl
	String ctrlName
	NVAR RampValue=root:DE_CTFC:MenuStuff:RampVoltage
	variable finalvoltage=td_rv("arc.output.z")-RampValue
	
	if(finalvoltage<-10)
		
		td_setramp(1,"arc.output.z",0,-10,"",0,0,"",0,0,"") 
	
	elseif(finalvoltage>150)
		
		td_setramp(1,"arc.output.z",0,150,"",0,0,"",0,0,"")

	else
		
		td_setramp(1,"arc.output.z",0,finalvoltage,"",0,0,"",0,0,"") 
	
	endif

end



//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


Function ButtonProc_3(ctrlName) : ButtonControl
	String ctrlName
	ir_StopPISLoop(2)
end

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


Function ButtonProc_4(ctrlName) : ButtonControl
	String ctrlName
	String/g root:DE_CTFC:MenuStuff:Stop="Yes"	
	if(waveExists(root:DE_CTFC:MenuStuff:ListComwave)==1)
			wave/z/T T2=root:DE_CTFC:MenuStuff:ListComwave
			T2="Stopping by User Command"
			
		endif
end

Function ButtonProc_5(ctrlName) : ButtonControl
	String ctrlName
	td_stop()
	td_stopdetrend()
	td_setramp(1,"arc.output.z",0,0,"",0,0,"",0,0,"") 
	//String/g root:DE_CTFC:MenuStuff:Stop="Yes"	
	if(waveExists(root:DE_CTFC:MenuStuff:ListComwave)==1)
			wave/z/T T2=root:DE_CTFC:MenuStuff:ListComwave
			T2="Aborted by User Command"
			
		endif
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function SetVarProc_1(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

End

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function CheckBoxProc_1 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if selected, 0 if not
End
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Window DE_CTFC_Control() : Panel

	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(50,50,1500,751)
	NewDataFolder/o root:DE_CTFC
	NewDataFolder/o root:DE_CTFC:MenuStuff
	make/o/T/n=0 root:DE_CTFC:MenuStuff:ListPullwave
	make/o/n=0 root:DE_CTFC:MenuStuff:SelPullwave
	make/o/T/n=(4,2) root:DE_CTFC:MenuStuff:ListRepwave
	make/o/n=(4,2) root:DE_CTFC:MenuStuff:SelRepwave
	make/o/T/n=(1,1) root:DE_CTFC:MenuStuff:ListComwave
	make/o/n=(1,1) root:DE_CTFC:MenuStuff:SelComwave
	variable/g root:DE_CTFC:MenuStuff:RampVoltage
	root:DE_CTFC:MenuStuff:ListRepwave[0][0]= {"X Pnts","Y Pnts","Scan Size","Total Loops"}
	root:DE_CTFC:MenuStuff:ListRepwave[0][1]= {"1","1","20","10"}

	root:DE_CTFC:MenuStuff:SelRepwave[][0]=0
	root:DE_CTFC:MenuStuff:SelRepwave[][1]=2
	
	root:DE_CTFC:MenuStuff:ListComwave="Initialized"
	root:DE_CTFC:MenuStuff:SelComwave=0
	PopupMenu popup0,pos={37,14},size={216,21},proc=PopMenuProc,title="Glide"
	PopupMenu popup0,mode=2,popvalue="Glide",value= #"\"Glide;Step Out;Step Out Equil;MultiRamp;MultiRamp Open;MultiCTFC\""
	
	PopupMenu popup1,pos={37,50},size={216,21},proc=PopMenuProc1,title="Want to Repeat?"
	PopupMenu popup1,mode=2,popvalue="No",value= #"\"Yes;No;\""
	
	PopupMenu popup2,pos={37,75},size={216,21},proc=PopMenuProc2,title="Want High Bandwidth?"
	PopupMenu popup2,mode=2,popvalue="No",value= #"\"Yes;No;\""
	
	PopupMenu popup3,pos={37,100},size={216,21},proc=PopMenuProc3,title="Want Detrend?"
	PopupMenu popup3,mode=2,popvalue="No",value= #"\"Yes;No;\""
	
	PopupMenu popup4,pos={37,140},size={216,21},proc=PopMenuProc4,title="Adjust Start?"
	PopupMenu popup4,mode=2,popvalue="No",value= #"\"Yes;No;\""
	
	display/N=MostRecent/w=(50,250,700,600)/HOST=DE_CTFC_Control
	make/o/n=0 root:DE_CTFC:MenuStuff:Display_DefV_1, root:DE_CTFC:MenuStuff:Display_ZSensor_1,root:DE_CTFC:MenuStuff:Display_DefV_2, root:DE_CTFC:MenuStuff:Display_ZSensor_2
	appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_1 vs root:DE_CTFC:MenuStuff:Display_ZSensor_1
	appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_2 vs root:DE_CTFC:MenuStuff:Display_ZSensor_2
	ModifyGraph/W=DE_CTFC_Control#MostRecent rgb(Display_DefV_2)=(0,0,0)
	
	ListBox list0,pos={263,14},size={500,225},proc=ListBoxProc,listWave=root:DE_CTFC:MenuStuff:ListPullwave
	ListBox list0,selWave=root:DE_CTFC:MenuStuff:SelPullwave,editStyle= 2,userColumnResize= 1,widths={70,40,70,40}

	ListBox list1,pos={800,14},size={150,75},proc=ListBoxProc1,listWave=root:DE_CTFC:MenuStuff:ListRepwave
	ListBox list1,selWave=root:DE_CTFC:MenuStuff:SelRepwave,editStyle= 2,userColumnResize= 1
	ListBox list2,pos={800,200},size={500,50},proc=ListBoxProc2,listWave=root:DE_CTFC:MenuStuff:ListComwave
	ListBox list2,selWave=root:DE_CTFC:MenuStuff:SelComwave,editStyle= 2,userColumnResize= 1
	CheckBox check0,pos={175,106},size={40,14},value= 0,mode=0,proc=CheckBoxProc_1,Title="Use Existing?"
	Button button0,pos={60,120},size={50,20},proc=ButtonProc_1,title="Go"
	Button button1,pos={1050,535},size={100,16},proc=ButtonProc_2,title="Ramp Voltage"
	Button button2,pos={905,600},size={100,16},proc=ButtonProc_3,title="Release Clamp"
	Button button3,pos={800,400},size={50,20},proc=ButtonProc_4,title="Stop Next"
	Button button4,pos={860,400},size={50,20},proc=ButtonProc_5,title="ABORT!"

	SetVariable setvar0,pos={875,535},size={150,16},proc=SetVarProc_1,title="RampVoltage"
	SetVariable setvar0,value= root:DE_CTFC:MenuStuff:RampVoltage, limits={-10,10,0.1}
	ValDisplay valdisp0 title="Ramp",value=#"root:de_ctfc:CTFCSucc",mode=1,barmisc={0,0},limits={-1,1,0};DelayUpdate
	ValDisplay valdisp0 highColor= (0,52224,0),lowColor= (65280,0,0);DelayUpdate
	ValDisplay valdisp0 zeroColor= (65280,0,0), pos={125,625}, size={50,25}, bodyWidth= 25,zeroColor= (65280,43520,0)
	ValDisplay valdisp1 title="Data",value=#"root:de_ctfc:DataDone",mode=1,barmisc={0,0},limits={-1,1,0};DelayUpdate
	ValDisplay valdisp1 highColor= (0,52224,0),lowColor= (65280,0,0);DelayUpdate
	ValDisplay valdisp1 zeroColor= (65280,0,0),pos={250,625}, size={50,25}, bodyWidth= 25,zeroColor= (65280,43520,0)
EndMacro //DE_CTFC_Control

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DE_ListWaveFunc(popstr)	
	string popstr
	strswitch (popstr)

		case "Glide":
			if(exists("root:DE_CTFC:MenuStuff:gLIDE_Wave")==1)
				wave/t/z Par=root:DE_CTFC:MenuStuff:Glide_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:Glide_Sel_Wave
			Else
				make/t/n=(10,4) root:DE_CTFC:MenuStuff:Glide_Wave
				wave/t/z Par=root:DE_CTFC:MenuStuff:Glide_Wave
				make/n=(10,4) root:DE_CTFC:MenuStuff:Glide_Sel_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:Glide_Sel_Wave
		
				Par[0][0]={"Approach Velocity (um/s)","Surface Trigger (pN)","Surface Dwell (s)","Retract Velocity (um/s)","Molecule Force Trigger (pN)","Retract Dwell (s)","No Trigger Distance (nm)","Sample Rate (kHz)","Length (s)","Start Distance (nm)"}
				Par[0][1]={"1","250","1","0.4","80","0","40","1","4","200"}
				Par[0][2]={"Approach Distance (nm)","Approach Time (s)","Approach Delay (s)","Retract Distance (nm)","Retract Speed (um/s)","Retract Pause (s)","Data Rate (kHz)"}
				Par[0][3]={"100",".001",".001","200","0.4","0","10"}
				Sel[][0]=0
				Sel[][1]=2
				Sel[][2]=0
				Sel[][3]=2
			endif
		
			duplicate/o  root:DE_CTFC:MenuStuff:Glide_Wave root:DE_CTFC:MenuStuff:ListPullwave
			duplicate/o  root:DE_CTFC:MenuStuff:Glide_Sel_Wave root:DE_CTFC:MenuStuff:SelPullwave

			break

		case "Step Out":
			if(exists("root:DE_CTFC:MenuStuff:StepOut_Wave")==1)
				wave/t/z Par=root:DE_CTFC:MenuStuff:StepOut_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:StepOut_Sel_Wave
			Else
				make/t/n=(10,4) root:DE_CTFC:MenuStuff:StepOut_Wave
				wave/t/z Par=root:DE_CTFC:MenuStuff:StepOut_Wave
				make/n=(10,4) root:DE_CTFC:MenuStuff:StepOut_Sel_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:StepOut_Sel_Wave
		
				Par[0][0]={"Approach Velocity (um/s)","Surface Trigger (pN)","Surface Dwell (s)","Retract Velocity (um/s)","Molecule Force Trigger (pN)","Retract Dwell (s)","No Trigger Distance (nm)","Sample Rate (kHz)","Length (s)","Start Distance (nm)"}
				Par[0][1]={"1","250","1","0.4","80","0","40","1","4","200"}
				Par[0][2]={"Approach Distance (nm)","Approach Time (s)","Approach Delay (s)","Retract Step Distance (nm)","Retract Step Time (s)","Retract Step Dwell (s)","Retract Step Number","Data Rate (kHz)"}
				Par[0][3]={"100",".001",".001","5",".001",".01","10","10"}
				Sel[][0]=0
				Sel[][1]=2
				Sel[][2]=0
				Sel[][3]=2
			endif
		
			duplicate/o  root:DE_CTFC:MenuStuff:StepOut_Wave root:DE_CTFC:MenuStuff:ListPullwave
			duplicate/o  root:DE_CTFC:MenuStuff:StepOut_Sel_Wave root:DE_CTFC:MenuStuff:SelPullwave

			break
		
		case "Step Out Equil":
			if(exists("root:DE_CTFC:MenuStuff:SOEquil_Wave")==1)
				wave/t/z Par=root:DE_CTFC:MenuStuff:SOEquil_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:SOEquil_Sel_Wave
			Else
				make/t/n=(15,4) root:DE_CTFC:MenuStuff:SOEquil_Wave
				wave/t/z Par=root:DE_CTFC:MenuStuff:SOEquil_Wave
				make/n=(15,4) root:DE_CTFC:MenuStuff:SOEquil_Sel_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:SOEquil_Sel_Wave
		
				Par[0][0]={"Approach Velocity (um/s)","Surface Trigger (pN)","Surface Dwell (s)","Retract Velocity (um/s)","Molecule Force Trigger (pN)","Retract Dwell (s)","No Trigger Distance (nm)","Sample Rate (kHz)","Length (s)","Start Distance (nm)"}
				Par[0][1]={"1","250","1","0.4","80","0","40","1","4","200"}
				Par[0][2]={"Approach Distance (nm)","Approach Time (s)","Approach Delay (s)","Retract Start (nm)","Retract End (nm)","Time to Start (s)","Retract Step Size (nm)","Retract Step Time(s)", "Retract Dwell Time(s)","Surface Pause (s)","Equilibrium Pause (s)","Final Distance (nm)","Final Velocity (um/s)","Max Iterations ","Data Rate (kHz)"}
				Par[0][3]={"100",".01",".01","5","100",".1",".1",".2",".3",".1",".5","200","0.4","1","10"}
				Sel[][0]=0
				Sel[][1]=2
				Sel[][2]=0
				Sel[][3]=2
			endif
		
			duplicate/o  root:DE_CTFC:MenuStuff:SOEquil_Wave root:DE_CTFC:MenuStuff:ListPullwave
			duplicate/o  root:DE_CTFC:MenuStuff:SOEquil_Sel_Wave root:DE_CTFC:MenuStuff:SelPullwave


			break
	
	
		case "MultiRamp":
			if(exists("root:DE_CTFC:MenuStuff:MultiRamp_Wave")==1)
				wave/t/z Par=root:DE_CTFC:MenuStuff:MultiRamp_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:MultiRamp_Sel_Wave
			Else
				make/t/n=(14,4) root:DE_CTFC:MenuStuff:MultiRamp_Wave
				wave/t/z Par=root:DE_CTFC:MenuStuff:MultiRamp_Wave
				make/n=(14,4) root:DE_CTFC:MenuStuff:MultiRamp_Sel_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:MultiRamp_Sel_Wave
		
				Par[0][0]={"Approach Velocity (um/s)","Surface Trigger (pN)","Surface Dwell (s)","Retract Velocity (um/s)","Molecule Force Trigger (pN)","Retract Dwell (s)","No Trigger Distance (nm)","Sample Rate (kHz)","Length (s)","Start Distance (nm)"}
				Par[0][1]={"1","250","1","0.4","80","0","40","1","4","200"}
				Par[0][2]={"Approach Distance (nm)","Approach Time (s)","Approach Delay (s)","Retract Start (nm)","Retract End (nm)","Time to Start (s)","Retract Speed (um/s)","Approach Speed (um/s)","Surface Pause (s)","Retract Pause (s)","Final Distance (nm)","Final Velocity (um/s)","Max Iterations ","Data Rate (kHz)"}
				Par[0][3]={"100",".01",".01","5","100",".1",".1",".1","1",".5","200","0.4","1","10"}
				Sel[][0]=0
				Sel[][1]=2
				Sel[][2]=0
				Sel[][3]=2
			endif
		
			duplicate/o  root:DE_CTFC:MenuStuff:MultiRamp_Wave root:DE_CTFC:MenuStuff:ListPullwave
			duplicate/o  root:DE_CTFC:MenuStuff:MultiRamp_Sel_Wave root:DE_CTFC:MenuStuff:SelPullwave


			break
			
			
			case "MultiRamp Open":
			if(exists("root:DE_CTFC:MenuStuff:MultiRampOL_Wave")==1)
				wave/t/z Par=root:DE_CTFC:MenuStuff:MultiRampOL_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:MultiRampOL_Sel_Wave
			Else
				make/t/n=(14,4) root:DE_CTFC:MenuStuff:MultiRampOL_Wave
				wave/t/z Par=root:DE_CTFC:MenuStuff:MultiRampOL_Wave
				make/n=(14,4) root:DE_CTFC:MenuStuff:MultiRampOL_Sel_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:MultiRampOL_Sel_Wave
		
				Par[0][0]={"Approach Velocity (um/s)","Surface Trigger (pN)","Surface Dwell (s)","Retract Velocity (um/s)","Molecule Force Trigger (pN)","Retract Dwell (s)","No Trigger Distance (nm)","Sample Rate (kHz)","Length (s)","Start Distance (nm)"}
				Par[0][1]={"1","250","1","0.4","80","0","40","1","4","200"}
				Par[0][2]={"Approach Distance (nm)","Approach Time (s)","Approach Delay (s)","Retract Start (nm)","Retract End (nm)","Time to Start (s)","Retract Speed (um/s)","Approach Speed (um/s)","Surface Pause (s)","Retract Pause (s)","Final Distance (nm)","Final Velocity (um/s)","Max Iterations ","Data Rate (kHz)"}
				Par[0][3]={"100",".01",".01","5","100",".1",".1",".1",".1",".5","200","0.4","1","10"}
				Sel[][0]=0
				Sel[][1]=2
				Sel[][2]=0
				Sel[][3]=2
			endif
		
			duplicate/o  root:DE_CTFC:MenuStuff:MultiRampOL_Wave root:DE_CTFC:MenuStuff:ListPullwave
			duplicate/o  root:DE_CTFC:MenuStuff:MultiRampOL_Sel_Wave root:DE_CTFC:MenuStuff:SelPullwave


			break
			
			
			
				case "MultiCTFC":
			if(exists("root:DE_CTFC:MenuStuff:MultiCTFC_Wave")==1)
				wave/t/z Par=root:DE_CTFC:MenuStuff:MultiCTFC_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:MultiCTFC_Sel_Wave
			Else
				make/t/n=(12,4) root:DE_CTFC:MenuStuff:MultiCTFC_Wave
				wave/t/z Par=root:DE_CTFC:MenuStuff:MultiCTFC_Wave
				make/n=(12,4) root:DE_CTFC:MenuStuff:MultiCTFC_Sel_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:MultiCTFC_Sel_Wave
				Par[0][0]={"Approach Velocity (um/s)","Surface Trigger (pN)","Surface Dwell (s)","Retract Velocity (um/s)","Molecule Force Trigger (pN)","Retract Dwell (s)","No Trigger Distance (nm)","Sample Rate (kHz)","Length (s)","Start Distance (nm)"}
				Par[0][1]={"1","250","1","0.4","80","0","40","1","4","200"}
				Par[0][2]={"Approach Distance (nm)","Approach Time (s)","Approach Delay (s)","Retract Velocity (um/s)","HoldoffDistance (nm)","ForceTrigger (pN)","ExtendedDwell (s)","ApproachSpeed (um/s)","Guess Distance (nm)","LowDwell (s)","Max Iterations","Data Rate (kHz)"}
				Par[0][3]={"100",".01",".01",".4","100","50",".1",".4","30",".2","1","10"}
				Sel[][0]=0
				Sel[][1]=2
				Sel[][2]=0
				Sel[][3]=2
			endif
		
			duplicate/o  root:DE_CTFC:MenuStuff:MultiCTFC_Wave root:DE_CTFC:MenuStuff:ListPullwave
			duplicate/o  root:DE_CTFC:MenuStuff:MultiCTFC_Sel_Wave root:DE_CTFC:MenuStuff:SelPullwave


			break


	endswitch 

end //DE_ListWaveFunc


//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DE_Setup(Experiment,wpar,wrep)
	string Experiment
	wave/t/z Wpar
	wave/t/z wrep
	variable delay
	String repeat,Fast,Detrend,Adjust
	SetDataFolder root:DE_CTFC
	Make/O/T/N=(12,3) RampSettings		//Primary CTFC ramp settings
	if(str2num(wpar[5][1])==0)
	delay=1e-6
	else
	endif
	Make/O/T/N=(12,3) RepeatSettings
	controlinfo popup1	
	Repeat=S_value
	controlinfo popup2	
	Fast=S_value	
	controlinfo popup3	
	Detrend=S_value	
		controlinfo popup4	
	Adjust=S_value
strswitch(Experiment)

 	case "Glide":

	DE_MakeGlide(wpar[0][1],"Deflection",wpar[1][1],wpar[2][1],wpar[3][1],"Deflection",wpar[4][1],num2str(delay),wpar[6][1],"DE_CTFCCB_TFE()",wpar[7][1],wpar[8][1],wpar[9][1],Detrend,"Glide",wpar[0][3],wpar[1][3],wpar[2][3],wpar[3][3],wpar[4][3],wpar[5][3],wpar[6][3],Fast,Repeat,wrep[0][1],wrep[1][1],wrep[2][1],"",wrep[3][1],"0","0")
	 wave/t RampSettings,RefoldSettings
	 make/o/n=0 CustomWave1,CustomWave2
	 DE_Custom1_Glide(RampSettings,RefoldSettings,CustomWave1)
	 DE_Custom2_Glide(RampInfo,RefoldSettings,CustomWave2,customwave1)
	break
 	
 	case "Step Out":
	DE_MakeStepOut(wpar[0][1],"Deflection",wpar[1][1],wpar[2][1],wpar[3][1],"Deflection",wpar[4][1],num2str(delay),wpar[6][1],"DE_CTFCCB_TFE()",wpar[7][1],wpar[8][1],wpar[9][1],Detrend,"Step Out",wpar[0][3],wpar[1][3],wpar[2][3],wpar[3][3],wpar[4][3],wpar[5][3],wpar[6][3],wpar[7][3],Fast,Repeat,wrep[0][1],wrep[1][1],wrep[2][1],"",wrep[3][1],"0","0")
	 wave/t RampSettings,RefoldSettings
	 make/o/n=0 CustomWave1,CustomWave2
	 DE_Custom1_Glide(RampSettings,RefoldSettings,CustomWave1)
	 DE_Custom2_StepOut(RampInfo,RefoldSettings,CustomWave2,customwave1)

	break
	
	case "Step Out Equil":
	make/o/t Naming
	Naming={"SOEquil",wpar[0][3],wpar[1][3],wpar[2][3],wpar[3][3],wpar[4][3],wpar[5][3],wpar[6][3],wpar[7][3],wpar[8][3],wpar[9][3],wpar[10][3],wpar[11][3],wpar[12][3],wpar[13][3],"0",wpar[14][3],Fast}
	DE_MakeSoEquil(wpar[0][1],"Deflection",wpar[1][1],wpar[2][1],wpar[3][1],"Deflection",wpar[4][1],num2str(delay),wpar[6][1],"DE_CTFCCB_TFE()",wpar[7][1],wpar[8][1],wpar[9][1],Detrend,Naming,Repeat,wrep[0][1],wrep[1][1],wrep[2][1],"",wrep[3][1],"0","0")
	wave/t RampSettings,RefoldSettings
	make/o/n=0 CustomWave1,CustomWave2,CustomWave3,CustomWave4
	DE_Custom1_Glide(RampSettings,RefoldSettings,CustomWave1)
	//DE_Custom3_SOEquil(RefoldSettings,CustomWave3)
	DE_Custom4_SOEquil(RampSettings,RefoldSettings,CustomWave4)
	killwaves Naming
	break
	
	case "MultiRamp":
	make/o/t Naming
	Naming={"MultiRamp",wpar[0][3],wpar[1][3],wpar[2][3],wpar[3][3],wpar[4][3],wpar[5][3],wpar[6][3],wpar[7][3],wpar[8][3],wpar[9][3],wpar[10][3],wpar[11][3],wpar[12][3],"0",wpar[13][3],Fast}
	DE_MakeMultiRamp(wpar[0][1],"Deflection",wpar[1][1],wpar[2][1],wpar[3][1],"Deflection",wpar[4][1],num2str(delay),wpar[6][1],"DE_CTFCCB_TFE()",wpar[7][1],wpar[8][1],wpar[9][1],Detrend,Naming,Repeat,wrep[0][1],wrep[1][1],wrep[2][1],"",wrep[3][1],"0","0")
	 wave/t RampSettings,RefoldSettings
	 make/o/n=0 CustomWave1,CustomWave2,CustomWave3
	 DE_Custom1_Glide(RampSettings,RefoldSettings,CustomWave1)
	DE_Custom3_MultiRamp(RampSettings,RefoldSettings,CustomWave3)
		killwaves Naming

	break
	case "MultiRamp Open":
	make/o/t Naming
	Naming={"MultiRampOL",wpar[0][3],wpar[1][3],wpar[2][3],wpar[3][3],wpar[4][3],wpar[5][3],wpar[6][3],wpar[7][3],wpar[8][3],wpar[9][3],wpar[10][3],wpar[11][3],wpar[12][3],"0",wpar[13][3],Fast}
	DE_MakeMultiRampOL(wpar[0][1],"Deflection",wpar[1][1],wpar[2][1],wpar[3][1],"Deflection",wpar[4][1],num2str(delay),wpar[6][1],"DE_CTFCCB_TFE()",wpar[7][1],wpar[8][1],wpar[9][1],Detrend,Naming,Repeat,wrep[0][1],wrep[1][1],wrep[2][1],"",wrep[3][1],"0","0")
	 wave/t RampSettings,RefoldSettings
	 make/o/n=0 CustomWave1,CustomWave2,CustomWave3
	DE_Custom1_Glide(RampSettings,RefoldSettings,CustomWave1)
	DE_Custom3_MultiRampOL(RampSettings,RefoldSettings,CustomWave3)
	killwaves Naming
	break
 	
 	case "MultiCTFC":
 	make/o/t Naming
	Naming={"MultiCTFC",wpar[0][3],wpar[1][3],wpar[2][3],wpar[3][3],wpar[4][3],Adjust,wpar[5][3],wpar[6][3],wpar[7][3],wpar[8][3],wpar[9][3],wpar[10][3],"0","NaN",wpar[10][3],Fast}
	DE_MakeMultiCTFC(wpar[0][1],"Deflection",wpar[1][1],wpar[2][1],wpar[3][1],"Deflection",wpar[4][1],num2str(delay),wpar[6][1],"DE_CTFCCB_TFE()",wpar[7][1],wpar[8][1],wpar[9][1],Detrend,Naming,Repeat,wrep[0][1],wrep[1][1],wrep[2][1],"",wrep[3][1],"0","0")
	 wave/t RampSettings,RefoldSettings
	 make/o/n=0 CustomWave1,CustomWave2
	DE_Custom1_Glide(RampSettings,RefoldSettings,CustomWave1)
	killwaves Naming

 	default:
 	
 	
 endswitch
 
//DE_MakeCustom1(RampSettings,RefoldSettings)
	
end //DE_FEP_Setup
	

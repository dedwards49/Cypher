#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName =DE_TriggeredForcePanel
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

Function ListBoxProc(ctrlName,row,col,event) : ListBoxControl
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
					//5=cell select with shift key, 6=begin edit, 7=end
					
	switch(event)
		
		case 7:
		
		controlinfo/W=DE_CTFC_Control popup0
		
		strswitch (s_value)
		
			case "Simple Ramp":
				duplicate/o root:DE_CTFC:MenuStuff:ListPullwave root:DE_CTFC:MenuStuff:Simple_Wave
			break
			
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

Function ButtonProc_1(ctrlName) : ButtonControl
	String ctrlName
	
	controlinfo/W=DE_CTFC_Control popup0
	string ExpType=S_value
	controlinfo/W=DE_CTFC_Control check0
	variable Existing=V_value
	wave/t wpar=root:DE_CTFC:MenuStuff:ListPullwave
	wave/t wrep=root:DE_CTFC:MenuStuff:ListRepwave
	String Command
	strswitch(ExpType)
	
		case "Simple Ramp":
			DE_Setup("Simple Ramp",wpar,wrep)
			
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
			
		case "Kick It":
			DE_Setup("Kick It",wpar,wrep)
			
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
		case "ForceClamp":
			DE_Setup("ForceClamp",wpar,wrep)
			
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
			
		case "MBullUnfolding":
			DE_Setup("MBullUnfolding",wpar,wrep)
			
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
	
	DE_SearchPattern#MakeSpots() //This goes aheads and makes our spot wave
	//	controlinfo popup0
	//	strswitch(S_Value)
	//	case "Simple Ramp":
	//		StartSimpleRamp()
	//	break
	//	
	//	default:
	//	StartCTFC() //This goes aheads and makes our spot wave
	//	break
	//	endswitch
end	//ButtonProc

Static Function StartSimpleramp()
	String Command

	Command="DE_SimpleRamp#StartSimpleRamp()"
	UpdateCommandOut(Command,"Clear")
	DE_SimpleRamp#StartSimpleRamp()
end

Static function StartCTFC()
	String Command
	controlinfo/W=DE_CTFC_Control popup0
	string ExpType=S_value
	controlinfo/W=DE_CTFC_Control check0
	variable Existing=V_value
	controlinfo/W=DE_CTFC_Control popup3	
	if(cmpstr(S_value,"No")==0)
		Command="DE_StartCTFC(\"Run\")"
		UpdateCommandOut(Command,"Clear")
	DE_StartCTFC("Run")
	else
		if(Existing==0)
			Command="DE_StartCTFC(\"Find\")"
			UpdateCommandOut(Command,"Clear")

		DE_StartCTFC("Find")

		else
			//print "DE_StartCTFC(\"Run\")"
			Command="DE_StartCTFC(\"Run\")"
			UpdateCommandOut(Command,"Clear")

			DE_StartCTFC("Run")
		endif
	endif
End//ButtonProc

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Function ButtonProc_4(ctrlName) : ButtonControl
	String ctrlName
	String/g root:DE_CTFC:MenuStuff:Stop="Yes"	

	UpdateCommandOut("Stopping by User Command","Clear")
end

Function ButtonProc_5(ctrlName) : ButtonControl
	String ctrlName
	td_stop()
	td_stopdetrend(1)
	td_setramp(1,"arc.output.z",0,0,"",0,0,"",0,0,"") 
	//String/g root:DE_CTFC:MenuStuff:Stop="Yes"	

	UpdateCommandOut("Aborted by User Command","Clear")
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Function ButtonProc_6(ctrlName) : ButtonControl
	String ctrlName
	td_stop()
	td_stopdetrend(1)
	td_setramp(1,"arc.output.z",0,0,"",0,0,"",0,0,"") 
	//String/g root:DE_CTFC:MenuStuff:Stop="Yes"	

	UpdateCommandOut("Aborted by User Command","Clear")
end


Function SetVarProc_1(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	if(varnum<5)
		SetVariable CTFCsetvar0,value=_NUM:(5)
	endif 
	
	if(varnum/2==floor(varnum/2))
		SetVariable CTFCsetvar0,value=_NUM:(varnum+1)
	endif 

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
	make/T/o/n=(6,2) root:DE_CTFC:MenuStuff:ListCenterwave
	make/o/n=(6,2) root:DE_CTFC:MenuStuff:SelCenterwave
	
	variable/g root:DE_CTFC:MenuStuff:RampVoltage
	root:DE_CTFC:MenuStuff:ListRepwave[0][0]= {"X Pnts","Y Pnts","Scan Size (µm)","Total Loops"}
	root:DE_CTFC:MenuStuff:ListRepwave[0][1]= {"1","1","1","10"}

	root:DE_CTFC:MenuStuff:SelRepwave[][0]=0
	root:DE_CTFC:MenuStuff:SelRepwave[][1]=2
	
	root:DE_CTFC:MenuStuff:ListCenterwave[0][0]= {"Distance (nm)","Velocity (nm)","Time To Start (s)","Rate (kHz)","Bandwidth (kHz)","Set Force (pN)"}
	root:DE_CTFC:MenuStuff:ListCenterwave[0][1]= {"30","150",".01","1","0.1","40"}
	
	root:DE_CTFC:MenuStuff:SelCenterwave[][0]=0
	root:DE_CTFC:MenuStuff:SelCenterwave[][1]=2
	
	root:DE_CTFC:MenuStuff:ListComwave="Initialized"
	root:DE_CTFC:MenuStuff:SelComwave=0
	PopupMenu popup0,pos={37,14},size={216,21},proc=PopMenuProc,title="Glide"
	PopupMenu popup0,mode=2,popvalue="Glide",value= #"\"Simple Ramp;Kick It;Glide;Step Out;Step Out Equil;MultiRamp;MultiRamp Open;MultiCTFC;ForceClamp;MBullUnfolding\""
	
	PopupMenu popup1,pos={37,50},size={216,21},proc=PopMenuProc1,title="Want to Repeat?"
	PopupMenu popup1,mode=2,popvalue="No",value= #"\"Yes;No;\""
	
	PopupMenu popup2,pos={37,75},size={216,21},proc=PopMenuProc1,title="Want High Bandwidth?"
	PopupMenu popup2,mode=2,popvalue="No",value= #"\"5 MHz;2 MHz;500 kHz;No;\""
	
	PopupMenu popup3,pos={37,100},size={216,21},proc=PopMenuProc1,title="Want Detrend?"
	PopupMenu popup3,mode=2,popvalue="No",value= #"\"Yes;No;\""
	
	PopupMenu popup4,pos={37,140},size={216,21},proc=PopMenuProc1,title="Adjust Start?"
	PopupMenu popup4,mode=2,popvalue="No",value= #"\"Yes;No;\""
	
	PopupMenu popup5,pos={37,180},size={216,21},proc=PopMenuProc1,title="Center?"
	PopupMenu popup5,mode=2,popvalue="No",value= #"\"Yes;No;\""
	
	PopupMenu popup6,pos={1000,114},size={200,21},proc=PopMenuProc1,title="Adjust Centering Start?"
	PopupMenu popup6,mode=2,popvalue="No",value= #"\"Yes;No;\""
	
	PopupMenu popup7,pos={37,210},size={200,21},proc=PopMenuProc1,title="Check to Start"
	PopupMenu popup7,mode=2,popvalue="Yes",value= #"\"Yes;No;\""
	
	PopupMenu popup8,pos={1000,144},size={200,21},proc=PopMenuProc1,title="Check to StartCentering"
	PopupMenu popup8,mode=2,popvalue="Yes",value= #"\"Yes;No;\""
		
	CheckBox check1,pos={800,95},size={40,14},proc=CheckBoxProc_1,value=1,title="Local Search?"
	display/N=Smoothed/w=(600,250,1200,500)/HOST=DE_CTFC_Control
	make/o/n=0 root:DE_CTFC:MenuStuff:Display_SMDefV_1, root:DE_CTFC:MenuStuff:Display_SMZSensor_1
	appendtograph/W=DE_CTFC_Control#Smoothed root:DE_CTFC:MenuStuff:Display_SMDefV_1

	display/N=Map/w=(1220,75,1420,250)/HOST=DE_CTFC_Control
	Make/o/n=1/C root:DE_CTFC:spotswave
	Make/o/n=1 root:DE_CTFC:MenuStuff:Display_Rspotswave, root:DE_CTFC:MenuStuff:Display_Ispotswave, root:DE_CTFC:MenuStuff:Display_RNowSpot, root:DE_CTFC:MenuStuff:Display_INowSpot
	appendtograph/W=DE_CTFC_Control#Map root:DE_CTFC:MenuStuff:Display_Ispotswave vs root:DE_CTFC:MenuStuff:Display_Rspotswave
	appendtograph/W=DE_CTFC_Control#Map root:DE_CTFC:MenuStuff:Display_INowSpot vs root:DE_CTFC:MenuStuff:Display_RNowSpot
	ModifyGraph/W=DE_CTFC_Control#Map mode=3,marker=19
	ModifyGraph/W=DE_CTFC_Control#Map rgb(Display_INowSpot)=(0,0,0)

	display/N=MostRecent/w=(50,250,550,500)/HOST=DE_CTFC_Control

	make/o/n=0 root:DE_CTFC:MenuStuff:Display_DefV_1, root:DE_CTFC:MenuStuff:Display_ZSensor_1,root:DE_CTFC:MenuStuff:Display_DefV_2, root:DE_CTFC:MenuStuff:Display_ZSensor_2
	make/o/n=0 root:DE_CTFC:MenuStuff:Display_CenD_1, root:DE_CTFC:MenuStuff:Display_CenZ_1
	
	appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_1 vs root:DE_CTFC:MenuStuff:Display_ZSensor_1
	appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_DefV_2 vs root:DE_CTFC:MenuStuff:Display_ZSensor_2
	appendtograph/W=DE_CTFC_Control#MostRecent root:DE_CTFC:MenuStuff:Display_CenD_1 vs root:DE_CTFC:MenuStuff:Display_CenZ_1

	ModifyGraph/W=DE_CTFC_Control#MostRecent rgb(Display_DefV_2)=(0,0,0)
		ModifyGraph/W=DE_CTFC_Control#MostRecent rgb(Display_CenD_1)=(0,0,0)

	make/o/n=0 root:DE_CTFC:MenuStuff:Display_XRZ root:DE_CTFC:MenuStuff:Display_XRX,root:DE_CTFC:MenuStuff:Display_FitX
	make/o/n=0   root:DE_CTFC:MenuStuff:Display_YRZ, root:DE_CTFC:MenuStuff:Display_YRY,root:DE_CTFC:MenuStuff:Display_FitY

	
	display/N=CenterX/w=(50,500,500,900)/HOST=DE_CTFC_Control
	appendtograph/W=DE_CTFC_Control#CenterX root:DE_CTFC:MenuStuff:Display_XRZ vs root:DE_CTFC:MenuStuff:Display_XRX
	appendtograph/W=DE_CTFC_Control#CenterX root:DE_CTFC:MenuStuff:Display_FitX
	ModifyGraph/W=DE_CTFC_Control#CenterX mode(Display_XRZ)=3,marker(Display_XRZ)=19;DelayUpdate
	ModifyGraph/W=DE_CTFC_Control#CenterX rgb(Display_XRZ)=(14848,32256,47104),useMrkStrokeRGB(Display_XRZ)=1;DelayUpdate
	ModifyGraph/W=DE_CTFC_Control#CenterX lsize(Display_FitX)=2
	display/N=CenterY/w=(550,500,1000,900)/HOST=DE_CTFC_Control
	appendtograph/W=DE_CTFC_Control#CenterY root:DE_CTFC:MenuStuff:Display_YRZ vs root:DE_CTFC:MenuStuff:Display_YRY
	appendtograph/W=DE_CTFC_Control#CenterY root:DE_CTFC:MenuStuff:Display_FitY
	ModifyGraph/W=DE_CTFC_Control#CenterY  mode(Display_YRZ)=3,marker(Display_YRZ)=19;DelayUpdate
ModifyGraph/W=DE_CTFC_Control#CenterY rgb(Display_YRZ)=(19712,44800,18944),useMrkStrokeRGB(Display_YRZ)=1;DelayUpdate
ModifyGraph/W=DE_CTFC_Control#CenterY lsize(Display_FitY)=2

	ListBox list0,pos={263,14},size={500,225},proc=ListBoxProc,listWave=root:DE_CTFC:MenuStuff:ListPullwave
	ListBox list0,selWave=root:DE_CTFC:MenuStuff:SelPullwave,editStyle= 2,userColumnResize= 1,widths={70,40,70,40}

	ListBox list1,pos={800,14},size={150,75},proc=ListBoxProc1,listWave=root:DE_CTFC:MenuStuff:ListRepwave
	ListBox list1,selWave=root:DE_CTFC:MenuStuff:SelRepwave,editStyle= 2,userColumnResize= 1
	ListBox list2,pos={1220,14},size={220,50},proc=ListBoxProc1,listWave=root:DE_CTFC:MenuStuff:ListComwave
	ListBox list2,selWave=root:DE_CTFC:MenuStuff:SelComwave,editStyle= 2,userColumnResize= 1
	ListBox list3,pos={1000,14},size={200,100},proc=ListBoxProc1,listWave=root:DE_CTFC:MenuStuff:ListCenterwave
	ListBox list3,selWave=root:DE_CTFC:MenuStuff:SelCenterwave,editStyle= 2,userColumnResize= 1
	CheckBox check0,pos={175,106},size={40,14},value= 0,mode=0,proc=CheckBoxProc_1,Title="Use Existing?"
	CheckBox check1,pos={175,180},size={40,14},value= 0,mode=0,proc=CheckBoxProc_1,Title="Add a Ramp?"

	Button button0,pos={800,120},size={50,20},proc=ButtonProc_1,title="Go"

	Button button3,pos={860,120},size={50,20},proc=ButtonProc_4,title="Stop Next"
	Button button4,pos={920,120},size={50,20},proc=ButtonProc_5,title="ABORT!"
//	Button button5,pos={920,120},size={50,20},proc=ButtonProc_6,title="ShowCentering!"

	SetVariable CTFCsetvar0,pos={800,220},size={150,16},proc=SetVarProc_1,title="Smothing Pnts"
	SetVariable CTFCsetvar0,value=_NUM:201, limits={5,Inf,2}

EndMacro //DE_CTFC_Control

//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Static Function UpdateCommandOut(StringIn,style)
	String StringIn,style
	wave/t Command=root:DE_CTFC:MenuStuff:ListComwave
	wave Select=root:DE_CTFC:MenuStuff:SelComwave
	
	strswitch(style)						// string switch
		case "Clear":
			make/t/o/n=1 root:DE_CTFC:MenuStuff:ListComwave
			make/o/n=1 root:DE_CTFC:MenuStuff:SelComwave
			wave/t Command=root:DE_CTFC:MenuStuff:ListComwave
			wave Select=root:DE_CTFC:MenuStuff:SelComwave
			Command=StringIn
			Select=1
			Break
		case "Add":
			wave/t Command=root:DE_CTFC:MenuStuff:ListComwave
			wave Select=root:DE_CTFC:MenuStuff:SelComwave
			insertpoints (numpnts(Command)),1, Command
			insertpoints (numpnts(Select)),1, Select
			Select[numpnts(Select)-1]=1
			Command[numpnts(Command)-1]=StringIn
			Break
		case "Replace":
			wave/t Command=root:DE_CTFC:MenuStuff:ListComwave
			wave Select=root:DE_CTFC:MenuStuff:SelComwave
			Select[numpnts(Select)-1]=1
			Command[numpnts(Command)-1]=StringIn
			Break
	endswitch

end

function DE_ListWaveFunc(popstr)	
	string popstr
	strswitch (popstr)

		case "Simple Ramp":
			if(exists("root:DE_CTFC:MenuStuff:Simple_Wave")==1)
				wave/t/z Par=root:DE_CTFC:MenuStuff:Simple_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:Simple_Sel_Wave
			Else
				make/t/n=(9,2) root:DE_CTFC:MenuStuff:Simple_Wave
				wave/t/z Par=root:DE_CTFC:MenuStuff:Simple_Wave
				make/n=(9,2) root:DE_CTFC:MenuStuff:Simple_Sel_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:Simple_Sel_Wave
		
				Par[0][0]={"Approach Velocity (um/s)","Surface Trigger (pN)","Surface Dwell (s)","Retract Velocity (um/s)","Retract Distance (nm)", "Retract Dwell (s)","Sample Rate (kHz)","Length (s)","Start Distance (nm)"}
				Par[0][1]={"1","250","1","0.4","200","0","50","4","200"}
				Sel[][0]=0
				Sel[][1]=2

			endif
		
			duplicate/o root:DE_CTFC:MenuStuff:Simple_Wave root:DE_CTFC:MenuStuff:ListPullwave
			duplicate/o  root:DE_CTFC:MenuStuff:Simple_Sel_Wave root:DE_CTFC:MenuStuff:SelPullwave

			break

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
		case "Kick It":
			if(exists("root:DE_CTFC:MenuStuff:KickIt_Wave")==1)
				wave/t/z Par=root:DE_CTFC:MenuStuff:KickIt_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:KickIt_Sel_Wave
			Else
				make/t/n=(10,4) root:DE_CTFC:MenuStuff:KickIt_Wave
				wave/t/z Par=root:DE_CTFC:MenuStuff:KickIt_Wave
				make/n=(10,4) root:DE_CTFC:MenuStuff:KickIt_Sel_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:KickIt_Sel_Wave
		
				Par[0][0]={"Approach Velocity (um/s)","Surface Trigger (pN)","Surface Dwell (s)","Retract Velocity (um/s)","Molecule Force Trigger (pN)","Retract Dwell (s)","No Trigger Distance (nm)","Sample Rate (kHz)","Length (s)","Start Distance (nm)"}
				Par[0][1]={"1","250","1","0.4","80","0","40","1","4","200"}
				Par[0][2]={"Approach Distance (nm)","Approach Time (s)","Approach Delay (s)","Data Rate (kHz)"}
				Par[0][3]={"100",".001",".01","50"}
				Sel[][1]=2
				Sel[][2]=0
				Sel[][3]=2
			endif
		
			duplicate/o  root:DE_CTFC:MenuStuff:KickIt_Wave root:DE_CTFC:MenuStuff:ListPullwave
			duplicate/o  root:DE_CTFC:MenuStuff:KickIt_Sel_Wave root:DE_CTFC:MenuStuff:SelPullwave

			break

		case "Step Out":
			if(exists("root:DE_CTFC:MenuStuff:StepOut_Wave")==1)
				wave/t/z Par=root:DE_CTFC:MenuStuff:StepOut_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:StepOut_Sel_Wave
			Else
				make/t/n=(13,4) root:DE_CTFC:MenuStuff:StepOut_Wave
				wave/t/z Par=root:DE_CTFC:MenuStuff:StepOut_Wave
				make/n=(13,4) root:DE_CTFC:MenuStuff:StepOut_Sel_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:StepOut_Sel_Wave
		
				Par[0][0]={"Approach Velocity (um/s)","Surface Trigger (pN)","Surface Dwell (s)","Retract Velocity (um/s)","Molecule Force Trigger (pN)","Retract Dwell (s)","No Trigger Distance (nm)","Sample Rate (kHz)","Length (s)","Start Distance (nm)"}
				Par[0][1]={"1","250","1","0.4","80","0","40","1","4","200"}
				Par[0][2]={"Approach Distance (nm)","Approach Time (s)","Approach Delay (s)","Retract Start (nm)","Retract End (nm)","Time to Start (s)","Retract Step Size (nm)","Retract Step Time(s)", "Retract Dwell Time(s)","Final Distance (nm)","Final Velocity (um/s)","Data Rate (kHz)"}
				Par[0][3]={"100",".01",".01","5","100",".1",".1",".2",".3","200","0.4","10"}
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

		case "ForceClamp":
			if(exists("root:DE_CTFC:MenuStuff:ForceClamp_Wave")==1)
				wave/t/z Par=root:DE_CTFC:MenuStuff:ForceClamp_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:ForceClamp_Sel_Wave
			Else
				make/t/n=(12,4) root:DE_CTFC:MenuStuff:ForceClamp_Wave
				wave/t/z Par=root:DE_CTFC:MenuStuff:ForceClamp_Wave
				make/n=(12,4) root:DE_CTFC:MenuStuff:ForceClamp_Sel_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:ForceClamp_Sel_Wave
				Par[0][0]={"Approach Velocity (um/s)","Surface Trigger (pN)","Surface Dwell (s)","Retract Velocity (um/s)","Molecule Force Trigger (pN)","Retract Dwell (s)","No Trigger Distance (nm)","Sample Rate (kHz)","Length (s)","Start Distance (nm)"}
				Par[0][1]={"1","250","1","0.4","80","0","40","1","4","200"}
				Par[0][2]={"Approach Distance (nm)","Approach Time (s)","Approach Delay (s)","HoldoffDistance (nm)","ForceTrigger (pN)","Retract Velocity (um/s)","Extension Pause","Final Distance (nm)","Final Velocity (um/s)","Data Rate (kHz)"}
				Par[0][3]={"100",".01",".01","50","100",".4","1","400",".4","50"}
				Sel[][0]=0
				Sel[][1]=2
				Sel[][2]=0
				Sel[][3]=2
			endif
		
			duplicate/o  root:DE_CTFC:MenuStuff:ForceClamp_Wave root:DE_CTFC:MenuStuff:ListPullwave
			duplicate/o  root:DE_CTFC:MenuStuff:ForceClamp_Sel_Wave root:DE_CTFC:MenuStuff:SelPullwave


			break
			
			
		case "MBullUnfolding":
			if(exists("root:DE_CTFC:MenuStuff:MBull_Wave")==1)
				wave/t/z Par=root:DE_CTFC:MenuStuff:MBull_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:MBull_Sel_Wave
			Else
				make/t/n=(13,4) root:DE_CTFC:MenuStuff:MBull_Wave
				wave/t/z Par=root:DE_CTFC:MenuStuff:MBull_Wave
				make/n=(13,4) root:DE_CTFC:MenuStuff:MBull_Sel_Wave
				wave/z Sel=root:DE_CTFC:MenuStuff:MBull_Sel_Wave
		
				Par[0][0]={"Approach Velocity (um/s)","Surface Trigger (pN)","Surface Dwell (s)","Retract Velocity (um/s)","Molecule Force Trigger (pN)","Retract Dwell (s)","No Trigger Distance (nm)","Sample Rate (kHz)","Length (s)","Start Distance (nm)"}
				Par[0][1]={"1","250","1","0.4","80","0","40","1","4","200"}
				Par[0][2]={"Approach Distance (nm)","Approach Time (s)","Approach Delay (s)","Holdoff Distance (nm)","Trigger Force (pN)","Retract Speed (um/s)","Retract Pause (s)","Final Distance (nm)","Final Velocity um/s", "Data Rate (kHz)"}
				Par[0][3]={"100",".001","1","40","50","2","1","200","0.4","50"}
				Sel[][0]=0
				Sel[][1]=2
				Sel[][2]=0
				Sel[][3]=2
			endif
		
			duplicate/o  root:DE_CTFC:MenuStuff:MBull_Wave root:DE_CTFC:MenuStuff:ListPullwave
			duplicate/o  root:DE_CTFC:MenuStuff:MBull_Sel_Wave root:DE_CTFC:MenuStuff:SelPullwave

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
	
	
	Controlinfo/W=DE_CTFC_Control popup5	//First thing is to check if we want centering. Since this is the same for all experiments, we do it separately here.
	if(cmpstr(S_Value,"Yes")==0)
		DE_MakeCentering()
	endif
	
	Make/O/T/N=(12,3) RampSettings		//Primary CTFC ramp settings
	if(str2num(wpar[5][1])==0)
		delay=1e-6
	else
	endif
	Make/O/T/N=(12,3) RepeatSettings
	controlinfo/W=DE_CTFC_Control popup1	
	Repeat=S_value
	controlinfo/W=DE_CTFC_Control popup2	
	Fast=S_value	
	controlinfo/W=DE_CTFC_Control popup3	
	Detrend=S_value	
	controlinfo/W=DE_CTFC_Control popup4	
	Adjust=S_value


	strswitch(Experiment)
		
		case "Simple Ramp":
			DE_SimpleRamp#MakeSimple(wpar,wrep,Repeat,"","0","0")
			wave/t RampSettings,RefoldSettings
			make/o/n=0 CustomWave1,CustomWave2
			break

		case "Glide":

			DE_Glide#MakeGlide(wpar[0][1],"Deflection",wpar[1][1],wpar[2][1],wpar[3][1],"Deflection",wpar[4][1],num2str(delay),wpar[6][1],"DE_CTFCCB_TFE()",wpar[7][1],wpar[8][1],wpar[9][1],Detrend,"Glide",wpar[0][3],wpar[1][3],wpar[2][3],wpar[3][3],wpar[4][3],wpar[5][3],wpar[6][3],Fast,Repeat,wrep[0][1],wrep[1][1],wrep[2][1],"",wrep[3][1],"0","0")
			wave/t RampSettings,RefoldSettings
			make/o/n=0 CustomWave1,CustomWave2
			DE_Custom1_Glide(RampSettings,RefoldSettings,CustomWave1)
			DE_Glide#CustomGlide(RampSettings,RefoldSettings,CustomWave2,customwave1)
			break
			
		case "Kick It":
			DE_CTFCMenu#MakeKickIt(wpar[0][1],"Deflection",wpar[1][1],wpar[2][1],wpar[3][1],"Deflection",wpar[4][1],num2str(delay),wpar[6][1],"DE_CTFCCB_TFE()",wpar[7][1],wpar[8][1],wpar[9][1],Detrend,"KickIt",wpar[0][3],wpar[1][3],wpar[2][3],wpar[3][3],Repeat,wrep[0][1],wrep[1][1],wrep[2][1],"",wrep[3][1],"0","0")
			wave/t RampSettings,RefoldSettings
			make/o/n=0 CustomWave1
			DE_Custom1_Glide(RampSettings,RefoldSettings,CustomWave1)
			//DE_Glide#CustomGlide(RampSettings,RefoldSettings,CustomWave2,customwave1)
			break
 	
		case "Step Out":
			make/o/t Naming
			Naming={"Step Out",wpar[0][3],wpar[1][3],wpar[2][3],wpar[3][3],wpar[4][3],wpar[5][3],wpar[6][3],wpar[7][3],wpar[8][3],wpar[9][3],wpar[10][3],wpar[11][3],"NaN",Fast}
			DE_StepOut#MakeWaves(wpar[0][1],"Deflection",wpar[1][1],wpar[2][1],wpar[3][1],"Deflection",wpar[4][1],num2str(delay),wpar[6][1],"DE_CTFCCB_TFE()",wpar[7][1],wpar[8][1],wpar[9][1],Detrend,Naming,Repeat,wrep[0][1],wrep[1][1],wrep[2][1],"",wrep[3][1],"0","0")
			wave/t RampSettings,RefoldSettings
			make/o/n=0 CustomWave1,CustomWave2,CustomWave3
			DE_Custom1_Glide(RampSettings,RefoldSettings,CustomWave1)
			//DE_StepOut#Custom2(RampInfo,RefoldSettings,CustomWave2,customwave1)
			DE_StepOut#CustomRamp_Final(RampSettings,RefoldSettings,CustomWave3)

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
			
			DE_MultiRamp#MakeMultiRamp(wpar[0][1],"Deflection",wpar[1][1],wpar[2][1],wpar[3][1],"Deflection",wpar[4][1],num2str(delay),wpar[6][1],"DE_CTFCCB_TFE()",wpar[7][1],wpar[8][1],wpar[9][1],Detrend,Naming,Repeat,wrep[0][1],wrep[1][1],wrep[2][1],"",wrep[3][1],"0","0")
			wave/t RampSettings,RefoldSettings
			make/o/n=0 CustomWave1,CustomWave2,CustomWave3
			DE_Custom1_Glide(RampSettings,RefoldSettings,CustomWave1)
			DE_MultiRamp#CustomRamp3(RampSettings,RefoldSettings,CustomWave3)
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
			break
			
			case "ForceClamp":
			make/o/t Naming
			Naming={"ForceClamp",wpar[0][3],wpar[1][3],wpar[2][3],wpar[3][3],Adjust,wpar[4][3],wpar[5][3],wpar[6][3],wpar[7][3],wpar[8][3],"0",wpar[9][3],Fast}
			DE_FOrceClamp#Makewaves(wpar[0][1],"Deflection",wpar[1][1],wpar[2][1],wpar[3][1],"Deflection",wpar[4][1],num2str(delay),wpar[6][1],"DE_CTFCCB_TFE()",wpar[7][1],wpar[8][1],wpar[9][1],Detrend,Naming,Repeat,wrep[0][1],wrep[1][1],wrep[2][1],"",wrep[3][1],"0","0")
			wave/t RampSettings,RefoldSettings
			make/o/n=0 CustomWave1,CustomWave2
			DE_Custom1_Glide(RampSettings,RefoldSettings,CustomWave1)
			DE_FOrceClamp#CustomRamp_Final(RampSettings,RefoldSettings,CustomWave2)
			killwaves Naming
			break
	
		case "MBullUnfolding":
			make/o/t Naming
			Naming={"MBullUnfolding",wpar[0][3],wpar[1][3],wpar[2][3],wpar[3][3],Adjust,wpar[4][3],wpar[5][3],wpar[6][3],wpar[7][3],wpar[8][3],"NaN",wpar[9][3],Fast}
			DE_MBullUnfolding#MakeWaves(wpar[0][1],"Deflection",wpar[1][1],wpar[2][1],wpar[3][1],"Deflection",wpar[4][1],num2str(delay),wpar[6][1],"DE_CTFCCB_TFE()",wpar[7][1],wpar[8][1],wpar[9][1],Detrend,Naming,Repeat,wrep[0][1],wrep[1][1],wrep[2][1],"",wrep[3][1],"0","0")
			wave/t RampSettings,RefoldSettings
			make/o/n=0 CustomWave1,CustomWave2
			DE_Custom1_Glide(RampSettings,RefoldSettings,CustomWave1)
			DE_MBullUnfolding#CustomRamp_Final(RampSettings,RefoldSettings,CustomWave2)

			killwaves Naming
			break
	
	
		default:
 	
 	
	endswitch
 
	//DE_MakeCustom1(RampSettings,RefoldSettings)
	
end //DE_FEP_Setup
	

Function DE_MakeCentering()

	wave/T CenterList= root:DE_CTFC:MenuStuff:ListCenterwave
	make/o/T/n=(9,3) CenteringSettings
	SetDimLabel 1,0,Values,CenteringSettings
	SetDimLabel 1,1,Desc,CenteringSettings
	SetDimLabel 1,2,Units,CenteringSettings

	SetDimLabel 0,0,Distance,CenteringSettings
	SetDimLabel 0,1,Velocity,CenteringSettings
	SetDimLabel 0,2,TimetoStart,CenteringSettings
	SetDimLabel 0,3,SurfaceLocation,CenteringSettings
	SetDimLabel 0,4,CurrentOffset,CenteringSettings
	SetDimLabel 0,5,Rate,CenteringSettings
	SetDimLabel 0,6,Bandwidth,CenteringSettings
	SetDimLabel 0,7,Zeroish,CenteringSettings
	SetDimLabel 0,8,ForceSet,CenteringSettings


	CenteringSettings[0][0]= {CenterList[0][1],CenterList[1][1],CenterList[2][1],"","",CenterList[3][1],CenterList[4][1],"",CenterlIst[5][1]}
	CenteringSettings[0][1]= {"Distance","Velocity","Time to Start","Surface Location","Current offset","Rate","Bandwidth","Zero Force","Force Set"}
	CenteringSettings[0][2]= {"nm","nm/s","s","V","V","kHz","kHz","pN","pN"}
End

Static Function PlotCentering()
wave CXZ=CenteringXReadZ
wave CXX=CenteringXReadX
wave CYZ=CenteringYReadZ
wave Cyy=CenteringyReady
Display CXZ vs CXX; AppendToGraph/B=B1 CYZ vs CYy

ModifyGraph axisEnab(B1)={0.55,1}
ModifyGraph axisEnab(bottom)={0,0.45}
ModifyGraph freePos(B1)={0,left}
ModifyGraph mode=3,marker=19,useMrkStrokeRGB=1;DelayUpdate
ModifyGraph rgb($nameofwave(CXZ))=(14848,32256,47104);DelayUpdate
ModifyGraph rgb($nameofwave(CYZ))=(19712,44800,18944)
end
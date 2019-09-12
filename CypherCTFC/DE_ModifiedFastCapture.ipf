#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#pragma ModuleName = DE_MFastCap
//Setup Stream setups a stream, but does not start it. It sets up the stream which is then activated by the event. At the moment I'm not sure how to get a callback or event to conclude this. I will ask Anil.
// speed is either 0=500 kHz or 1=2 MHz. At the moment, i don't 100% understand that filters, except that I should set them as high as possible which is 500 kHz for 2 MHz and set to 250 kHz for the 500 kHz.
//Timespan is the length of the capture in time. Wave0 and Wave1 are the waves that you want the data crashed into. Be warned that wave0 and wave1 will be overwritten and resized. Currently I limit this
//to two channels for ease, but could easily write a second function for setting up 4 channels at 500 kHz

function ReadHighBandwidth(ReadFast,[Callback])
	variable ReadFast
	
	String Callback
	Wave/T RampInfo=root:DE_CTFC:RampSettings

	if(ParamisDefault(Callback)==1)
		Callback=""
	endif
	if(cmpstr(RampInfo[%CallBack][0],"DE_SimpleRamp#SimpleForceCallback()")==0)
			controlinfo/W=DE_CTFC_Control popup2
		string Fast=S_Value
		if(StringMatch(Fast,"5 MHz")==1)
				
			DE_MAPFastCaptureCallback("Read",ReadFast,Callback)
		elseif(StringMatch(Fast,"2 MHz")==1)
			ReturnStream(ReadFast,Callback)

		elseif(StringMatch(Fast,"500 kHz")==1)
			ReturnStream(ReadFast,Callback)
		endif
	elseif(cmpstr(CallBack,"")==0)
		Wave/T SlowInfo=root:DE_CTFC:RefoldSettings

		if(StringMatch(SlowInfo[%UltraFast][0],"5 MHz")==1)
				
			DE_MAPFastCaptureCallback("Read",ReadFast,Callback)
		elseif(StringMatch(SlowInfo[%UltraFast][0],"2 MHz")==1)
			ReturnStream(ReadFast,Callback)

		elseif(StringMatch(SlowInfo[%UltraFast][0],"500 kHz")==1)
			ReturnStream(ReadFast,Callback)
		endif
	else
		strswitch(CallBack)
			case "Multi":
				Wave Info=root:DE_CTFC:StuffToDo:MRamp:MRampWave
				break
			case "JumpPause":
				Wave Info=root:DE_CTFC:StuffToDo:JumpPause:JumpPauseWave
				break
			case "StepOut":
				Wave Info=root:DE_CTFC:StuffToDo:StepOut:StepOutWave
				break
			case "StepJump":
				Wave Info=root:DE_CTFC:StuffToDo:StepJump:StepJumpWave
				break
		endswitch
		
		if(Info[%Fast][0]==3)			//Sorts out what High bandwidth measurement we wanna make and prepares them.

			DE_MAPFastCaptureCallback("Read",ReadFast,Callback)
		elseif(Info[%Fast][0]==2)
	
			ReturnStream(ReadFast,Callback)	
		elseif(Info[%Fast][0]==1)	
			ReturnStream(ReadFast,Callback)
		else
		endif


	endif

end


Function SetupStream(speed,timespan,wave0,wave1,[Wave0String,Wave1String])
	variable speed, timespan
	string Wave0String,Wave1String
	wave wave0,wave1
	td_ws("Cypher.crosspoint.infastb","Defl") //We will make the deflection measurement on inFastB
	//This sets default behavior which is read Input.FastA and the Zsensor
	if( ParamIsDefault(Wave0String))
		Wave0String="Input.FastB"
	
	endif
	
	if( ParamIsDefault(Wave1String))
		Wave1String="LVDT.Z" //

	endif
	
	variable totpoints
	Variable error = 0
	if(speed==0) //Running at 500 kHz
		totpoints=timespan*5e5
		td_wv("cypher.input.fastb.filter.freq",2.5e5)
		td_wv("cypher.lvdt.z.filter.freq",5e3)
	elseif(speed==1) //Running at 2 MHz
		totpoints=timespan*2e6
		td_wv("cypher.input.fastb.filter.freq",4e5)
		td_wv("cypher.lvdt.z.filter.freq",5e3)
	else
		print "invalid capture rate"
		error+=-1
		return error
	endif
		
	if(totpoints>=4e7)//Limits us to 20 seconds of 2 MHz data at the moment until we can play with the values
		print "Total points capped"
		error+=-2
		totpoints=4e7
	endif
	
	if(speed==0) //Running at 500 kHz
		Make/O/N=(totpoints) H0, H1	// N can be arbitrary long but beware Igor memory limitations
		duplicate/o H0, wave0
		duplicate/o H1,wave1
		killwaves H0,H1
	else
		Make/O/N=(totpoints) H0, H1	// N can be arbitrary long but beware Igor memory limitations
		duplicate/o H0, wave0
		duplicate/o H1,wave1
		killwaves H0,H1

	endif
	
	
	
	
	error += td_StopStream("Cypher.Stream.0")			// stop the stream	

	error += td_ws("Cypher.Stream.0.Channel.0", Wave0String)		// only Cypher signals
	error += td_ws("Cypher.Stream.0.Channel.1", Wave1String)		// do not use "Cypher" in front of the channel names
	
	if(speed==0) //Running at 500 kHz
		error += td_ws("Cypher.Stream.0.Rate", "500 kHz")
	
	elseif(speed == 1)
		
		error += td_ws("Cypher.Stream.0.Rate", "2 MHz")
	endif
	
	error += td_ws("Cypher.Stream.0.Events", "1")

	error += td_DebugStream("Cypher.Stream.0.Channel.0", Wave0, "")
	error += td_DebugStream("Cypher.Stream.0.Channel.1", Wave1, "") 
	
	error += td_SetupStream("Cypher.Stream.0")
	
	//error+=td_ws("ARC.Events.once", "1") //Here's how you fire~~

	return error
End

Function ReturnStream(SaveFast,Callback)
	variable SaveFast
	string Callback
	Wave/Z DeflWave = root:DE_CTFC:HBDefl
	Wave/Z ZsnsrWave = root:DE_CTFC:HBZsnsr

	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T RefoldInfo=root:DE_CTFC:RefoldSettings
	//String CallBackStr, ErrorStr = ""
	String CorrectionIteration
	
	if(SaveFast==1||SaveFast==3)
							
		//MakeWaitPanel("Saving data.")
		DoUpdate
		Wave/Z DData = root:DE_CTFC:HBDefl
		Wave/Z ZData = root:DE_CTFC:HBZsnsr
		duplicate/Free ZData Z_Save
		variable Zsens=GV("ZLVDTSens")
		Fastop Z_Save=(Zsens)*ZData
		Duplicate/FREE DData,xWave
		Ax2Wave(DData,0,xWave)
		ARSaveAsForce(1 | (GV("SaveForce") & 2),"SaveForce","Time;DeflV;",Z_Save,xWave,DData,$"", $"",$"",$"")

		//KillUpdateWaitingPanel()
	
	endif	
					
					
	if(SaveFast==2||SaveFast==3)
		
		//MakeWaitPanel("Saving data.")
		note/K DeflWave "Spring Constant: "+num2str(GV("SpringConstant"))+";"
		note DeflWave "Invols: "+num2str(GV("InvOLS"))+";"
		note DeflWave "Date: "+date()+";"
		note DeflWave "Time: "+time()+";"
		note DeflWave "BaseSuffix: "+DE_PreviousForceRamp()+";"
		 
		Print "Saving Fast Capture to Disk"
		string Pathname,SaveName
		if(cmpstr(RampInfo[8][0],"DE_SimpleRamp#SimpleForceCallback()")==0)
					PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
	
					SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+".pxp"
	
	
		else
			strswitch(RefoldInfo[%ExperimentName][0])//Right now every program except Multiramp can just launch. multiRamp does it's own thing.
	
				case "Glide":
					PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
	
					SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+".pxp"
	
					break
				
				case "Step Out":
					PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
					SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+".pxp"
	
					break
							
				case "SOEquil":
					PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
					SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+".pxp"
	
					break
				
				case "MultiRamp":
					CorrectionIteration=RefoldInfo[%CurrIter]
					note DeflWave "Iteration="+CorrectionIteration+";"
					PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
					SaveName=DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+CorrectionIteration+".pxp"
	
					break
				
				case "MultiRampOL":
					CorrectionIteration=RefoldInfo[%CurrIter]
					note DeflWave "Iteration="+CorrectionIteration+";"
					PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
					SaveName=DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+CorrectionIteration+".pxp"
	
					break
				case "MBullUnfolding":
					//	CorrectionIteration=RefoldInfo[%CurrIter]
					//note DeflWave "Iteration="+CorrectionIteration+";"
					PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
					SaveName=DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+".pxp"
	
					break
				
				case "KickIt":
			
					PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
					strswitch(Callback)
						case "Multi":
							NVar Res=root:DE_CTFC:StuffToDo:MultiRamp
							SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_Multi_"+num2str(Res)+".pxp"
							break
						case "JumpPause":
							NVar Res=root:DE_CTFC:StuffToDo:JumpPause
							SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_JP_"+num2str(Res)+".pxp"
							break
						case "StepOut":
							NVar Res=root:DE_CTFC:StuffToDo:StepOut
							SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_SO_"+num2str(Res)+".pxp"
							break
						case "StepJump":
							NVar Res=root:DE_CTFC:StuffToDo:StepJump
							SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_SJ_"+num2str(Res)+".pxp"
							break
					endswitch
					break
				default:
				
	
				
			endswitch 
		endif
		//PathName="c:Test"
		NewPath/O/C FastCapturePath,PathName
		NewDataFolder/O/S HBSave
		duplicate/o DeflWave HBSaveDef
		duplicate/o ZsnsrWave HBSaveZsn

		//Save/C/P=FastCapturePath DefVFast as SaveName
		SaveData/L=1/Q/P=FastCapturePath SaveName
		SetDataFolder root:DE_CTFC
	
		//KillUpdateWaitingPanel()
	
	endif

	//KilLWindow FastCaptureData	
	if(cmpstr(RampInfo[8][0],"DE_SimpleRamp#SimpleForceCallback()")==0)
					DE_Simpleramp#Repeat()
	
		else
	strswitch(RefoldInfo[%ExperimentName][0])//Right now every program except Multiramp can just launch. multiRamp does it's own thing.

		case "Glide":
			DE_Glide#FastDone()
			break
			
		case "Step Out":
			DE_StepOut#FastDone() //Here we can just use the same reset as the glide.
			break
			
		case "SOEquil":
			DE_FastDone_SOEquil()
			break
		
		case "MultiRamp":
			DE_MultiRamp#FastDone()
			break
			
		case "MultiRampOL":
			DE_MultiRampOL#FastDone()
			break
			
		case "MBullUnfolding":
			DE_MBullUnfolding#FastDone()
			break
		case "KickIt":
			strswitch(Callback)
				case "Multi":
					DE_Menu_MultiRamp#RampDone2()

					break
				case "JumpPause":
					DE_Menu_JumpPause#JPDone2()

					break
				case "StepOut":
					DE_Menu_StepOut#StepDone2()
					break
							case "StepJump":
					DE_Menu_StepJump#SJDone2()
					break
			endswitch
			break
		default:

	
	endswitch 
	endif
End //DE_MAPFastCaptureCallback




Function DE_MAPFastCaptureCallback(Action,SaveFast,Callback)
	String Action,Callback
	variable SaveFast
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	String CallBackStr, ErrorStr = ""
	Wave DestWave = root:FastCaptureData
	
	StrSwitch (Action)
		Case "Error":		//	There was an error in fast capture setup
			print "There was a problem - check the error log."
			MasterARGhostFunc("","MAPFastCaptureGo")
			break
			
		Case "Read":	//	Read the fast capture buffer, then call this function again to tell it we're done.
			CallBackStr = "DE_MAPFastCaptureCallback(\"ReadDone\","+num2str(SaveFast)+")"
			//CallBackStr="HEYO"
			ErrorStr = num2str(td_ReadCapture("Cypher.Capture.0", DestWave, CallBackStr)) + ","
			If ( ARReportError(ErrorStr) )
				DE_MAPFastCaptureCallback("Error",SaveFast,Callback)
			EndIf
			break
			
		Case "ReadDone":	//	Fast capture read-back completed
			//	Display the data if it's not already visible
			NVAR IsFastCapture = $InitOrDefault("root:packages:MAPIsFastCapture",0)
			variable zerovolt,Pvol,rep
			wave ZSensorVolts_fast=ZSensor_fast
			wave/t RefoldSettings
			STRING CorrectionIteration
			IsFastCapture = 0
			
			if(SaveFast==1||SaveFast==3)
							
				//MakeWaitPanel("Saving data.")
				DoUpdate
				Wave/Z Data = root:FastCaptureData  
				Duplicate/FREE Data,xWave
				Ax2Wave(Data,0,xWave)
				ARSaveAsForce(1 | (GV("SaveForce") & 2),"SaveForce","Time;DeflV;",xWave,xWave,Data,$"", $"",$"",$"")
				//KillUpdateWaitingPanel()
	
			endif	
					
					
			if(SaveFast==2||SaveFast==3)
	
				//MakeWaitPanel("Saving data.")
				note/K DestWave "Spring Constant: "+num2str(GV("SpringConstant"))+";"
				note DestWave "Invols: "+num2str(GV("InvOLS"))+";"
				note DestWave "Date: "+date()+";"
				note DestWave "Time: "+time()+";"
				note DestWave "BaseSuffix: "+DE_PreviousForceRamp()+";"
	
				Print "Saving Fast Capture to Disk"
				string Pathname,SaveName
	
				strswitch(RefoldSettings[%ExperimentName][0])//Right now every program except Multiramp can just launch. multiRamp does it's own thing.
	
					case "Glide":
						PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
	
						SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+".pxp"
	
						break
				
					case "Step Out":
						PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
						SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+".pxp"
	
						break
							
					case "SOEquil":
						PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
						SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+".pxp"
	
						break
				
					case "MultiRamp":
						CorrectionIteration=RefoldSettings[%CurrIter]
						note DestWave "Iteration="+CorrectionIteration+";"
						PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
						SaveName=DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+CorrectionIteration+".pxp"
	
						break
				
					case "MultiRampOL":
						CorrectionIteration=RefoldSettings[%CurrIter]
						note DestWave "Iteration="+CorrectionIteration+";"
						PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
						SaveName=DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+"_"+CorrectionIteration+".pxp"
	
						break
						
					case "KickIt":
			
						PathName="C:Users:Asylum User:Desktop:Devin:FastCaptureData:"+DE_DateStringForSave()
						strswitch(Callback)
							case "Multi":
								NVar Res=root:DE_CTFC:StuffToDo:MultiRamp
								SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_Multi_"+num2str(Res)+".pxp"
								break
							case "JumpPause":
								NVar Res=root:DE_CTFC:StuffToDo:JumpPause
								SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_JP_"+num2str(Res)+".pxp"
								break
							case "StepOut":
								NVar Res=root:DE_CTFC:StuffToDo:StepOut
								SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_SO_"+num2str(Res)+".pxp"
								break
						endswitch
						break
				endswitch 

	
				NewPath/O/C/Q/Z FastCapturePath,PathName
				//Save/C/P=FastCapturePath DefVFast as SaveName
				SetDataFolder root:
				SaveData/L=1/Q/P=FastCapturePath SaveName
				SetDataFolder root:DE_CTFC
	
				//KillUpdateWaitingPanel()
	
			endif

			//KilLWindow FastCaptureData	
			strswitch(RefoldSettings[%ExperimentName][0])//Right now every program except Multiramp can just launch. multiRamp does it's own thing.

				case "Glide":
					DE_Glide#FastDone()
					break
			
				case "Step Out":
					DE_StepOut#FastDone()  //Here we can just use the same reset as the glide.
					break
			
				case "SOEquil":
					DE_FastDone_SOEquil()
					break
		
				case "MultiRamp":
					DE_MultiRamp#FastDone()
					break
			
				case "MultiRampOL":
					DE_MultiRampOL#FastDone()
					break
				case "MBullUnfolding":
					DE_MBullUnfolding#FastDone()
					break
				case "KickIt":
					strswitch(Callback)
						case "Multi":
							DE_Menu_MultiRamp#RampDone2()

							break
						case "JumpPause":
							DE_Menu_JumpPause#JPDone2()

							break
						case "StepOut":
							DE_Menu_StepOut#StepDone2()
							break
					endswitch
	
					break
			endswitch 


			break
			
	EndSwitch
End //DE_MAPFastCaptureCallback

Static Function ThermalRead(Action,Callback)
	String Action,Callback
//	Wave/T RampInfo=root:DE_CTFC:RampSettings
//	Wave/T RampInfo=root:DE_CTFC:RampSettings
	String CallBackStr, ErrorStr = ""
	if(WaveExists(root:DE_CTFC:StuffToDo:ThermalRead)==0)
	make/o/n=0 root:DE_CTFC:StuffToDo:ThermalRead
	endif
	//
	Wave DestWave = root:DE_CTFC:StuffToDo:ThermalRead
	
	StrSwitch (Action)
		Case "Error":		//	There was an error in fast capture setup
			print "There was a problem - check the error log."
			MasterARGhostFunc("","MAPFastCaptureGo")
			break
			
		Case "Read":	//	Read the fast capture buffer, then call this function again to tell it we're done.
			CallBackStr = "DE_MFastCap#ThermalRead(\"ReadDone\",\"\")"
			//CallBackStr="HEYO"
			ErrorStr = num2str(td_ReadCapture("Cypher.Capture.0", DestWave, CallBackStr)) + ","
			If ( ARReportError(ErrorStr) )
				ThermalRead("Error",Callback)
			EndIf
			break
			
		Case "ReadDone":	//	Fast capture read-back completed
			DE_Menu_Thermal#ReadDone()
		break
		endswitch
End //DE_MAPFastCaptureCallback
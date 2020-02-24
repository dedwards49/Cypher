#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma modulename=DE_CTFCMenu
#include ":DE_CTFCMenu_Touch"
#include ":DE_CTFCMenu_StepJump"
#Include "C:\Users\Asylum User\Desktop\Devin\Projects\Processing\Processing_Smth\DE_Filtering"
#include ":DE_CTFCMenu_Centering"
//
#include ":DE_CTFCMenu_JumpPause"
#include ":DE_CTFCMenu_MultiRamp"
#include ":DE_CTFCMenu_Thermal"
#include ":DE_CTFCMenu_StepOut"
#include ":DE_CTFCMenu_SingleRamp"


Static Function Start()
	DoWindow DE_CTFCMenu
	if(v_flag==0)
		Execute "DE_CTFCMenu()"
	else

	endif
	
	Wave DefVolts=root:DE_CTFC:DefV_Fast 
	Wave ZSensorVolts=root:DE_CTFC:ZSensor_Fast
	SVar Lcen=root:DE_CTFC:StuffToDo:LastCenteredTime
	LCen=time()
	SVar Lstart=root:DE_CTFC:StuffToDo:SeriesStartTime
	Lstart=time()
	SVar LTouch=root:DE_CTFC:StuffToDo:LastTouchTime
	LTouch=Time()
	UpdateLastInitialRampandSave(DefVolts,ZSensorVolts)
	
	wave CXRZ=root:DE_CTFC:CenteringXReadZ
	wave CYRZ=root:DE_CTFC:CenteringYReadZ
	wave CXRX=root:DE_CTFC:CenteringXReadX
	wave CYRY=root:DE_CTFC:CenteringYReadY
	DE_Menu_Centering#UpdateLastCenterandSave(CXRX,CXRZ,CYRY,CYRZ)
	DoAPlot("SingleRamp")

end
Static Function FastCaptureCheckEnd(waveIn,Callback)
	wave Wavein
	string Callback
	variable ReadFast
	DE_TestDevinWait(20000)
	if(wavein[%Fast][0]!=0)
	
		//display/N=Test DefVolts_Equil
		ReadFast=DE_CheckFast("Read 5 MHz","Read")
		//killwindow Test
		if(ReadFast!=4)
			ReadHighBandwidth(ReadFast,Callback=Callback)
							
		else
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
				default:
			endswitch
		endif
				
	else
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
			default:
		endswitch
				
	endif
	
end
Static Function FastCaptureCheckStart(wavein,totaltime)
	wave wavein
	variable totaltime

	if(wavein[%Fast][0]==3)			//Sorts out what High bandwidth measurement we wanna make and prepares them.
		//DataLength=5e6*(totaltime)
		td_WriteValue("Cypher.Capture.0.Rate", 2)
		td_WriteValue("Cypher.Capture.0.Length", 5e6*(totaltime))
		td_WriteValue("Cypher.Capture.0.Trigger", 1)
	elseif(wavein[%Fast][0]==2)
		make/o/n=1  root:DE_CTFC:HBDefl,root:DE_CTFC:HBZsnsr
		wave HBDefl= root:DE_CTFC:HBDefl
		wave HBZsnsr=root:DE_CTFC:HBZsnsr
		SetupStream(1,(totaltime),HBDefl,HBZsnsr)
		td_ws("ARC.Events.once", "1")
	elseif(wavein[%Fast][0]==1)
		make/o/n=1  root:DE_CTFC:HBDefl,root:DE_CTFC:HBZsnsr
		wave HBDefl= root:DE_CTFC:HBDefl
		wave HBZsnsr=root:DE_CTFC:HBZsnsr
		SetupStream(0,(totaltime),HBDefl,HBZsnsr)
		td_ws("ARC.Events.once", "1")
	else
	endif
end




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Controlling the stage
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function ZeroTheXYpositions()



end

Static Function ZeroTheZPosition()
	Variable Choice=DE_CTFCMenu#GeneticPopUps("ZeroZ")
	variable NewPLace
		wave JPW=root:DE_CTFC:StuffToDo:JumpPause:JumpPauseWave

	if(Choice==2)
	make/free/n=1 HoldOver
		HoldOver={1}
	
	SetDimLabel 0,0, AdjustCursors,HoldOver
	NewPLace=real(DE_CTFCMenu#PlaceMarkers(0,0,HoldOver,0))

	endif

	td_SetRamp(.01, "PIDSLoop.5.Setpoint", 0, NewPLace, "", 0, 0, "", 0, 0, "DE_CTFCMEnu#Z_Zeroed()")

end

Static Function Z_Zeroed()


print "Zerod"
end

function GeneticPopUps(Selector)
	string Selector
	Variable Collect=0
	string MessageString,TitleString
	StrSwitch(Selector)
	
		case "ZeroZ":
			MessageString="Do you want to use the current locations, or pick a location?"
			TitleString="Zero ZSensor Offset"
			Prompt Collect,MessageString,popup,"Current Location;Pick"

			break
		default:
			return -1
	endswitch
	DoPrompt TitleString,Collect
	return Collect
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Misc Naming and Saving and Displaying
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function ShowWave(WaveString)
	String WaveString
	
	StrSwitch(WaveString)
		case "CenteringWave":
			DoWindow CenterWave
			if(V_Flag==1)
				killwindow CenterWave
			endif
			edit/N=CenterWave/W=(700,50,999,250) root:DE_CTFC:StuffToDo:Centering:CenteringWave.ld
			break
		
		case "SurfaceWave":
			DoWindow SurfaceWave
			if(V_Flag==1)
				killwindow SurfaceWave
			endif
			edit/N=SurfaceWave/W=(700,50,999,250) root:DE_CTFC:StuffToDo:Touch:SurfaceWave.ld
			break
		case "SingleRamp":
			DoWindow SRampWave
			if(V_Flag==1)
				killwindow SRampWave
			endif
			edit/N=SRampWave/W=(700,50,999,250) root:DE_CTFC:StuffToDo:SRamp:SRampWave.ld
			break
		case "MultiRamp":
			DoWindow MultiRampWave
			if(V_Flag==1)
				killwindow MultiRampWave
			endif
			edit/N=MultiRampWave/W=(700,50,999,250) root:DE_CTFC:StuffToDo:MRamp:MRampWave.ld
			break
		case "JumpPause":
			DoWindow JumpPauseWave
			if(V_Flag==1)
				killwindow JumpPauseWave
			endif
			edit/N=JumpPauseWave/W=(700,50,999,250) root:DE_CTFC:StuffToDo:JumpPause:JumpPauseWave.ld
			break
		
		case "StepOut":
			DoWindow StepOutWave
			if(V_Flag==1)
				killwindow StepOutWave
			endif
			edit/N=StepOutWave/W=(700,50,999,250) root:DE_CTFC:StuffToDo:StepOut:StepOutWave.ld
			break
		case "Thermal":
		
			DoWindow ThermalWave
			if(V_Flag==1)
				killwindow ThermalWave
			endif
			edit/N=ThermalWave/W=(700,50,999,250) root:DE_CTFC:StuffToDo:Thermal:ThermalWave.ld
			break
		case "StepJump":
		
			DoWindow StepJumpWave
			if(V_Flag==1)
				killwindow StepJumpWave
			endif
			edit/N=StepJumpWave/W=(700,50,999,250) root:DE_CTFC:StuffToDo:StepJump:StepJumpWave.ld
			break

	endswitch
end



Static Function DoAPlot(WaveString)
	String WaveString
	
	strswitch(WaveString)
	
		case "SingleRamp":
			DoWindow LatestRamp
			if(V_flag==1)
				//killwindow LatestRamp
			else
				wave InitDefVolts=root:DE_CTFC:StuffToDo:InitDef
				wave InitZSensorVolts=root:DE_CTFC:StuffToDo:InitZSensor
				display/N=LatestRamp/W=(600,50,900,250) InitDefVolts vs InitZSensorVolts
				if(waveexists(root:DE_CTFC:StuffToDo:LastDef))
					wave DefVolts=root:DE_CTFC:StuffToDo:LastDef
					wave ZSensorVolts=root:DE_CTFC:StuffToDo:LastZSensor
					duplicate/o DefVolts root:DE_CTFC:StuffToDo:LastDef_Sm
					duplicate/o ZSensorVolts root:DE_CTFC:StuffToDo:LastZSensor_Sm

					wave DefVoltsSm=root:DE_CTFC:StuffToDo:LastDef_Sm
					wave ZSensorVoltsSm=root:DE_CTFC:StuffToDo:LastZSensor_Sm
					Smooth/S=2 51, DefVoltsSm,ZSensorVoltsSm

				
					appendtograph/W=LatestRamp DefVolts vs ZSensorVolts
					appendtograph/W=LatestRamp DefVoltsSm vs ZSensorVoltsSm
					ModifyGraph/W=LatestRamp rgb($nameofwave(DefVolts))=(52224,52224,52224)
					ModifyGraph/W=LatestRamp rgb($nameofwave(DefVoltsSm))=(0,0,0)

				endif
			endif
			wave TDef=root:DE_CTFC:StuffToDo:TouchDef
			wave TZsen=root:DE_CTFC:StuffToDo:TouchZSensor
			
			duplicate/o TDef  root:DE_CTFC:StuffToDo:TouchDef_Sm
			duplicate/o TZsen  root:DE_CTFC:StuffToDo:TouchZSensor_Sm
			wave TDefSm=root:DE_CTFC:StuffToDo:TouchDef_Sm
			wave TZsenSm=root:DE_CTFC:StuffToDo:TouchZSensor_Sm
			Smooth/S=2 51, TDefSm,TZsenSm
			if(waveexists(TDef)==1&&Strsearch(tracenamelist("LatestRamp",";",1),nameofwave(TDef),1)==-1)


				appendtograph/W=LatestRamp TDef vs TZsen
				appendtograph/W=LatestRamp TDefSm vs TZsenSm
				ModifyGraph/W=LatestRamp rgb($nameofwave(TDef))=(48640,55040,60160)
				ModifyGraph/W=LatestRamp rgb($nameofwave(TDefSm))=(14848,32256,47104)
			endif
			wave DefVolts=root:DE_CTFC:StuffToDo:LastDef
			wave ZSensorVolts=root:DE_CTFC:StuffToDo:LastZSensor
			duplicate/o DefVolts root:DE_CTFC:StuffToDo:LastDef_Sm
			duplicate/o ZSensorVolts root:DE_CTFC:StuffToDo:LastZSensor_Sm
			wave DefVoltsSm=root:DE_CTFC:StuffToDo:LastDef_Sm
			wave ZSensorVoltsSm=root:DE_CTFC:StuffToDo:LastZSensor_Sm
					Smooth/S=2 51, DefVoltsSm,ZSensorVoltsSm

			if(waveexists(DefVolts)==1&&Strsearch(tracenamelist("LatestRamp",";",1),nameofwave(DefVolts),1)==-1)


					appendtograph/W=LatestRamp DefVolts vs ZSensorVolts
					appendtograph/W=LatestRamp DefVoltsSm vs ZSensorVoltsSm
					ModifyGraph/W=LatestRamp rgb($nameofwave(DefVolts))=(52224,52224,52224)
					ModifyGraph/W=LatestRamp rgb($nameofwave(DefVoltsSm))=(0,0,0)
			endif
			DoWindow/F LatestRamp

			break
			
		case "MultiRamp":
			wave MDefVolts=root:DE_CTFC:StuffToDo:MultiDef
			wave MSensorVolts=root:DE_CTFC:StuffToDo:MultiZSensor
			DoWindow MultiRamp
			if(V_flag==1)
				duplicate/o MDefVolts root:DE_CTFC:StuffToDo:MultiDefSm
				wave MDefVoltsSm=root:DE_CTFC:StuffToDo:MultiDefSm
				Smooth/S=2 501, MDefVoltsSm				
			else

				duplicate/o MDefVolts root:DE_CTFC:StuffToDo:MultiDefSm
				wave MDefVoltsSm=root:DE_CTFC:StuffToDo:MultiDefSm
				Smooth/S=2 251, MDefVoltsSm
				display/N=MultiRamp/W=(600,50,900,250) MDefVolts 
				appendtograph/W=MultiRamp MDefVoltsSm
				ModifyGraph/W=MultiRamp  rgb($nameofwave(MDefVolts))=(65280,48896,48896)
			endif
			DoWindow/F MultiRamp

			break
			case "StepOut":
				wave DefVolts=root:DE_CTFC:StuffToDo:StepOutDef
				wave ZSensorVolts=root:DE_CTFC:StuffToDo:StepOutZSnsr
				DoWindow StepOut
			if(V_flag==1)
				duplicate/o DefVolts root:DE_CTFC:StuffToDo:SODefSm
				wave DefVoltsSm=root:DE_CTFC:StuffToDo:SODefSm
				Smooth/S=2 251, DefVoltsSm				
			else

				duplicate/o DefVolts root:DE_CTFC:StuffToDo:SODefSm
				wave DefVoltsSm=root:DE_CTFC:StuffToDo:SODefSm
				Smooth/S=2 251, DefVoltsSm	
				display/N=StepOut/W=(600,50,900,250) DefVolts 
				appendtograph/W=StepOut DefVoltsSm
				ModifyGraph/W=StepOut  rgb($nameofwave(DefVolts))=(65280,48896,48896)
			endif
			DoWindow/F StepOut

			break
		case "Centering":
			DoWindow Centering
			if(V_flag==1)
				//killwindow Centering
			else
				wave CXRX=root:DE_CTFC:StuffToDo:LastCXRX
				wave CXRZ=root:DE_CTFC:StuffToDo:LastCXRZ
				wave CYRY=root:DE_CTFC:StuffToDo:LastCYRY
				wave CYRZ=root:DE_CTFC:StuffToDo:LastCYRZ
	
				display/N=Centering/W=(600,50,900,250) CXRZ vs CXRX 
				AppendtoGraph/L=L1/B=B1/W=Centering CYRZ vs CYRY 
				ModifyGraph tick=2,lblPosMode=3,lblPos=30,axisEnab(bottom)={0,0.45};DelayUpdate
				ModifyGraph axisEnab(B1)={0.55,1},freePos(L1)={0,B1},freePos(B1)={0,L1}
				ModifyGraph mode=3,marker=19,useMrkStrokeRGB=1;DelayUpdate
				ModifyGraph rgb($nameofwave(CXRZ))=(19712,44800,18944);DelayUpdate
				ModifyGraph rgb($nameofwave(CYRZ))=(14848,32256,47104)
			endif
			DoWindow/F Centering

			break
		case "JumpPause":
			DoWindow JumpPause
			wave JPDefVolts= root:DE_CTFC:StuffToDo:RecentJumpDef
			wave JPSensorVolts= root:DE_CTFC:StuffToDo:RecentJumpZSn
			if(V_flag==1)
				duplicate/o JPDefVolts  root:DE_CTFC:StuffToDo:RecentJumpDefSm
				wave JPDefVoltsSm=root:DE_CTFC:StuffToDo:RecentJumpDefSm
				Smooth/S=2 251, JPDefVoltsSm	
			else
				wave JPDefVolts= root:DE_CTFC:StuffToDo:RecentJumpDef
				wave JPSensorVolts= root:DE_CTFC:StuffToDo:RecentJumpZSn
				display/N=JumpPause/W=(600,50,900,250) JPDefVolts
				duplicate/o JPDefVolts  root:DE_CTFC:StuffToDo:RecentJumpDefSm
				wave JPDefVoltsSm=root:DE_CTFC:StuffToDo:RecentJumpDefSm
				Smooth/S=2 251, JPDefVoltsSm	
				appendtograph/W=JumpPause JPDefVoltsSm
				ModifyGraph/W=JumpPause  rgb($nameofwave(JPDefVolts))=(65280,48896,48896) 
			endif
			DoWindow/F JumpPause

			break
		
		case "Touch":
			DoWindow LatestRamp 
			if(V_flag!=1)
				DoAPlot("SingleRamp")
			endif
			wave TDef=root:DE_CTFC:StuffToDo:TouchDef
			wave TZsen=root:DE_CTFC:StuffToDo:TouchZSensor
			if(Strsearch(tracenamelist("LatestRamp",";",1),nameofwave(TDef),1)==-1)

				duplicate/o TDef  root:DE_CTFC:StuffToDo:TouchDef_Sm
				duplicate/o TZsen  root:DE_CTFC:StuffToDo:TouchZSensor_Sm

				wave TDefSm=root:DE_CTFC:StuffToDo:TouchDef_Sm
				wave TZsenSm=root:DE_CTFC:StuffToDo:TouchZSensor_Sm
				Smooth/S=2 51, TDefSm,TZsenSm
				appendtograph/W=LatestRamp TDef vs TZsen
				appendtograph/W=LatestRamp TDefSm vs TZsenSm
				//(48640,55040,60160)
				ModifyGraph/W=LatestRamp rgb($nameofwave(TDef))=(48640,55040,60160)
				ModifyGraph/W=LatestRamp rgb($nameofwave(TDefSm))=(14848,32256,47104)
			endif
			DoWindow/F LatestRamp 
			break
			
		case "Thermal":
			DoWindow Thermal
			if(V_flag==1)
				//killwindow MultiRamp
			endif
			wave ThermalVolts=root:DE_CTFC:StuffToDo:ThermalRead
			display/N=Thermal/W=(600,50,900,250) ThermalVolts 
			DoWindow/F Thermal
			break
		case "StepJumpStep":
			DoWindow StepJumpStep
			wave StepJumpStepD= root:DE_CTFC:StuffToDo:StepJump_StepDef
			wave StepJumpStepZ= root:DE_CTFC:StuffToDo:StepJump_StepZSensor
			if(V_flag==1)
				duplicate/o StepJumpStepD  root:DE_CTFC:StuffToDo:StepJump_StepDefSm
				wave StepJumpStepDSm=root:DE_CTFC:StuffToDo:StepJump_StepDefSm
				Smooth/S=2 251, StepJumpStepDSm	
			else

				display/N=StepJumpStep/W=(600,50,900,250) StepJumpStepD
				duplicate/o StepJumpStepD  root:DE_CTFC:StuffToDo:StepJump_StepDefSm
				wave StepJumpStepDSm=root:DE_CTFC:StuffToDo:StepJump_StepDefSm
				Smooth/S=2 251, StepJumpStepDSm
				appendtograph/W=StepJumpStep StepJumpStepDSm
				ModifyGraph/W=StepJumpStep  rgb($nameofwave(StepJumpStepD))=(65280,48896,48896) 
			endif
			DoWindow/F StepJumpStep

			break
		case "StepJumpEquil":
					
			DoWindow StepJumpEquil
			wave StepJumpEquilD= root:DE_CTFC:StuffToDo:StepJump_EquilDef
			wave StepJumpEquilZ=root:DE_CTFC:StuffToDo:StepJump_EquilZSensor
			if(V_flag==1)
				duplicate/o StepJumpEquilD  root:DE_CTFC:StuffToDo:StepJump_EquilDefSm
				wave StepJumpEquilDSm= root:DE_CTFC:StuffToDo:StepJump_EquilDefSm
				Smooth/S=2 251, StepJumpEquilDSm	
			else

				display/N=StepJumpEquil/W=(600,50,900,250) StepJumpEquilD
				duplicate/o StepJumpEquilD  root:DE_CTFC:StuffToDo:StepJump_EquilDefSm
				wave StepJumpEquilDSm= root:DE_CTFC:StuffToDo:StepJump_EquilDefSm
				Smooth/S=2 251, StepJumpEquilDSm	
				appendtograph/W=StepJumpEquil StepJumpEquilDSm
				ModifyGraph/W=StepJumpEquil  rgb($nameofwave(StepJumpEquilD))=(65280,48896,48896) 
			endif
			DoWindow/F StepJumpEquil

			break
			//StepJumpEquil
	endswitch

end

Static Function BiggestMatchingNumber(FolderStr,MatchStr)
	String FolderStr,MatchStr
	DFREF saveDFR = GetDataFolderDFR()	
	SetDataFolder $FolderStr
	string List= ( WaveList(MatchStr+"*", ";", ""))
	print List
	string NewList= replacestring(MatchStr,List,"")
	variable len=itemsinlist(NewList)
	variable Result=str2num(stringfromlist(len-1,sortList(NewList)))
	if(numtype(Result)==2)
		Result=-1
	endif
	SetDataFolder saveDFR
	return Result
end



Static Function UpdateLastInitialRampandSave(Defwave,ZWave)
	wave Defwave,ZWave
	note Defwave DE_CTFCMenu#InitialNoteFile()+"\r"+DE_CTFCMenu#GenericNoteFile()
	note ZWave DE_CTFCMenu#InitialNoteFile()+"\r"+DE_CTFCMenu#GenericNoteFile()
	duplicate/o Defwave root:DE_CTFC:StuffToDo:InitDef
	duplicate/o ZWave root:DE_CTFC:StuffToDo:InitZSensor
	NVar InitRamp= root:DE_CTFC:StuffToDo:InitialRamp
	variable savenum=InitRamp+1
	duplicate Defwave $("root:DE_CTFC:StuffToDo:SRamp:Saves:Initramp_D"+num2str(savenum))
	duplicate ZWave $("root:DE_CTFC:StuffToDo:SRamp:Saves:Initramp_Z"+num2str(savenum))
	InitRamp=savenum
end



Static function/C PlaceMarkers(startdist,enddist,InfoWave,Both)
	variable startdist, enddist,Both
	wave InfoWave
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	Wave InitiDef= root:DE_CTFC:StuffToDo:InitDef
	Wave InitZSnsr=  root:DE_CTFC:StuffToDo:InitZSensor
	
	if(Waveexists(root:DE_CTFC:StuffToDo:RecentDef))
		wave DefVolts=root:DE_CTFC:StuffToDo:RecentDef
		wave ZSensorVolts=root:DE_CTFC:StuffToDo:RecentZSensor
	else
		wave DefVolts=root:DE_CTFC:StuffToDo:InitDef
		wave ZSensorVolts=root:DE_CTFC:StuffToDo:InitZSensor
	endif
	
	variable zerovolt,startmultivolt,endmultivolt
	zerovolt=td_rv("PIDSLoop.5.Setpoint")
	
	//zerovolt=(InitZSnsr(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
	//zerovolt is a guess where the surface is based on the most recent triggered wave.
	startmultivolt=Zerovolt-startdist
	endmultivolt=Zerovolt-enddist
	FindLevel/p/q ZSensorVolts,startmultivolt
	variable startmultipnt=v_Levelx
	FindLevel/p/q ZSensorVolts,Endmultivolt
	variable endmultipnt=v_Levelx

	DoAPlot("SingleRamp")
	Cursor/p/W=LatestRamp A  $nameofwave(DefVolts)  startmultipnt
	Cursor/p/W=LatestRamp B  $nameofwave(DefVolts)  endmultipnt

	if(Both==0)
		Cursor/K/p/W=LatestRamp B 

	endif
	if(InfoWave[%AdjustCursors]==0)
	else
	
		DE_UserCursorAdjust("LatestRamp",0)
		//startmultivolt=ZSensorVolts[pcsr(A,"LatestRamp")]
		startmultivolt=hcsr(A,"LatestRamp")
		if(Both==1)
			//endmultivolt=ZSensorVolts[pcsr(B,"LatestRamp")]
			endmultivolt=hcsr(B,"LatestRamp")

		endif
	endif
	
	return cmplx(startmultivolt,endmultivolt)
end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Wave Making and Setup
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Static Function MakeRequiredWaves()
	DE_Menu_Centering#MakeWave()
	DE_Menu_Touch#MakeWave()
	DE_CTFCMenu#MakeSRampWave()
	DE_Menu_MultiRamp#MakeWave()
	DE_Menu_JumpPause#MakeWave()
	DE_Menu_StepOut#MakeWave()
	DE_Menu_Thermal#MakeWave()
	DE_Menu_StepJump#MakeWave()
end

Static Function MakeSRampWave()
	make/o/n=4 root:DE_CTFC:StuffToDo:SRamp:SRampWave
	wave SRW=root:DE_CTFC:StuffToDo:SRamp:SRampWave


	SRW={200,400,0,1}
	
	SetDimLabel 0,0,Distance_nm,SRW
	SetDimLabel 0,1,Velocity_nmps,SRW
	SetDimLabel 0,2,RetractPause_s,SRW
	SetDimLabel 0,3,Bandwidth_kHz,SRW

end

Static Function MakeFoldersandVars()
	NewDataFolder/o root:DE_CTFC
	NewDataFolder/o root:DE_CTFC:StuffToDo
	NewDataFolder/o root:DE_CTFC:StuffToDo:SRamp
	NewDataFolder/o root:DE_CTFC:StuffToDo:SRamp:Saves
	NewDataFolder/o root:DE_CTFC:StuffToDo:Centering
	NewDataFolder/o root:DE_CTFC:StuffToDo:Centering:Saves
	NewDataFolder/o root:DE_CTFC:StuffToDo:MRamp
	NewDataFolder/o root:DE_CTFC:StuffToDo:MRamp:Saves
	NewDataFolder/o root:DE_CTFC:StuffToDo:JumpPause
	NewDataFolder/o root:DE_CTFC:StuffToDo:JumpPause:Saves
	NewDataFolder/o root:DE_CTFC:StuffToDo:StepOut
	NewDataFolder/o root:DE_CTFC:StuffToDo:StepOut:Saves
	NewDataFolder/o root:DE_CTFC:StuffToDo:StepJump
	NewDataFolder/o root:DE_CTFC:StuffToDo:StepJump:Saves
	NewDataFolder/o root:DE_CTFC:StuffToDo:Touch
	NewDataFolder/o root:DE_CTFC:StuffToDo:Touch:Saves
	NewDataFolder/o root:DE_CTFC:StuffToDo:Thermal
	NewDataFolder/o root:DE_CTFC:StuffToDo:Thermal:Saves
	string/G root:DE_CTFC:StuffToDo:LastCenteredTime="-1"
	variable/G root:DE_CTFC:StuffToDo:LastCentered=-1
	variable/G root:DE_CTFC:StuffToDo:LastRamp=-1
	string/G root:DE_CTFC:StuffToDo:SeriesStartTime="-1"
	variable/G root:DE_CTFC:StuffToDo:InitialRamp=-1
	variable/G root:DE_CTFC:StuffToDo:MultiRamp=-1
	variable/G root:DE_CTFC:StuffToDo:JumpPause=-1
	variable/G root:DE_CTFC:StuffToDo:StepOut=-1
	variable/G root:DE_CTFC:StuffToDo:StepJump=-1
	variable/G root:DE_CTFC:StuffToDo:MultiRamp=-1
	variable/G root:DE_CTFC:StuffToDo:StepOut=-1
	string/G root:DE_CTFC:StuffToDo:LastTouchTime="-1"
	variable/G root:DE_CTFC:StuffToDo:LastTouch=-1
	string/G root:DE_CTFC:StuffToDo:LastThermalTime="-1"
	variable/G root:DE_CTFC:StuffToDo:LastThermal=-1
	
	variable/G root:DE_CTFC:StuffToDo:StepJump=-1
end

Static function MakeKickIt(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,b0,b1,b2,b3,b4,c0,c1,c2,c3,c4,c5,c6,c7)
	string a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,b0,b1,b2,b3,b4,c0,c1,c2,c3,c4,c5,c6,c7
	if(DataFolderExists("root:DE_CTFC:StuffToDo")==0)
		MakeFoldersandVars()
	
	endif

	SetDataFolder root:DE_CTFC

	make/n=1/o FCD
	Make/O/T/N=(14,3) RampSettings		//Primary CTFC ramp settings
	
	RampSettings[0][0]= {a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13}
	RampSettings[0][1]= {"Approach Velocity","Surface Trigger Channel","Surface Trigger","Surface Dwell Time","Retract Velocity","Molecule Trigger Channel","Molecule Trigger","Retract Dwell Time","No Trigger Distance","DE_CTFCCB_TFE","Sample Rate","Total Time","Start Distance","Detrend"}
	RampSettings[0][2]= {"micron/s","Channel Name/Alias","pN","s","micron/s","Channel Name/Alias(No Trigger= output.Dummy)","pN","s","nm","Function to execute after ramp","kHz","s","nm","Yes/No"}
 	
	SetDimLabel 1,0,Values,RampSettings
	SetDimLabel 1,1,Desc,RampSettings
	SetDimLabel 1,2,Units,RampSettings

	SetDimLabel 0,0,ApproachVelocity,RampSettings
	SetDimLabel 0,1,SurfaceTriggerChannel,RampSettings
	SetDimLabel 0,2,SurfaceTrigger,RampSettings
	SetDimLabel 0,3,SurfaceDwellTime,RampSettings
	SetDimLabel 0,4,RetractVelocity,RampSettings
	SetDimLabel 0,5,MolecularTriggerChannel,RampSettings
	SetDimLabel 0,6,MolecularTrigger,RampSettings
	SetDimLabel 0,7,RetractDwellTime,RampSettings
	SetDimLabel 0,8,NoTriggerDistance,RampSettings
	SetDimLabel 0,9,CallBack,RampSettings
	SetDimLabel 0,10,SampleRate,RampSettings
	SetDimLabel 0,11,TotalTime,RampSettings
	SetDimLabel 0,12,StartDistance,RampSettings
	SetDimLabel 0,13,Detrend,RampSettings
	Make/O/T/N=(5,3) RefoldSettings		//Settings for ramp back to surface and final extension ramp.
	RefoldSettings[0][0]= {b0,b1,b2,b3,b4}
	RefoldSettings[0][1]= {"Experiment Name","Approach Distance","Approach Time","Approach Delay","DataRate"}
	RefoldSettings[0][2]= {"","nm","s","s","Hz"}
	
	SetDimLabel 1,0,Values,RefoldSettings
	SetDimLabel 1,1,Desc,RefoldSettings
	SetDimLabel 1,2,Units,RefoldSettings

	SetDimLabel 0,0,ExperimentName,RefoldSettings
	SetDimLabel 0,1,ApproachDistance,RefoldSettings
	SetDimLabel 0,2,ApproachTime,RefoldSettings
	SetDimLabel 0,3,ApproachDelay,RefoldSettings
	SetDimLabel 0,4,DataRate,RefoldSettings

	Make/O/T/N=(8,3) RepeatSettings			//These are the instructions that are passed forward for repeating the experiment	
	RepeatSettings[0][0]= {c0,c1,c2,c3,c4,c5,c6,c7}
	RepeatSettings[0][1]= {"Want to Repeat","X Pnts","Y Pnts","Scan Size","Total Spots","Total Loops","Current Loops","Current Spot"}
	RepeatSettings[0][2]= {"Yes/No","Integer","Integer","um","Integer","Integer","Integer","Integer"}
	
	SetDimLabel 1,0,Values,RepeatSettings
	SetDimLabel 1,1,Desc,RepeatSettings
	SetDimLabel 1,2,Units,RepeatSettings

	SetDimLabel 0,0,Repeat,RepeatSettings
	SetDimLabel 0,1,XPnts,RepeatSettings
	SetDimLabel 0,2,YPnts,RepeatSettings
	SetDimLabel 0,3,ScanSize,RepeatSettings
	SetDimLabel 0,4,TotalSpots,RepeatSettings

	SetDimLabel 0,5,TotalLoops,RepeatSettings
	SetDimLabel 0,6,CurrentLoops,RepeatSettings
	SetDimLabel 0,7,CurrentSpot,RepeatSettings

	if(cmpstr(RepeatSettings[0][0],"Yes")==0)   //Checks if we want to repeat at all
	
		RepeatSettings[4][0]=num2str(str2num(RepeatSettings[1][0])*str2num(RepeatSettings[2][0]))    //How many total spots do we want? (x-spots * y-spots)
		
		
		if(str2num(RepeatSettings[4][0])==1) //If we only want one spot, then we do nothing
											
		else
		
			pv("Scansize",str2num(RepeatSettings[3][0])*1e-6)	//sets the scan size
			SpotGrid(str2num(RepeatSettings[1][0]),str2num(RepeatSettings[2][0]))  //sets up the spot grids
			pv("ForceSpotNumber",0)  //start at spot 0
			GoToSpot()   //Go to the spot. This assumes there will be plenty of time to reach this point in the intervening keystrokes etc.
		
		endif
	
	else
		
	endif
	
end

Static Function CheckonPreRamp(ContinueString)
	string ContinueString

	controlinfo/W=DE_CTFCMenu de_ctfcmenu_check0
	
	if(v_value==1)
		DE_Menu_SingleRamp#Start(ContinueString)
	else
		RampHandoff(ContinueString)
	endif

end

Static Function RampHandoff(ContinueString)
	string ContinueString
	strswitch(ContinueString)
		case "StartCentering":
			DE_Menu_Centering#Start()

			break
		
		case "StartMulti":
			DE_Menu_MultiRamp#Start()
			break
		
		case "StartStepOut":
			DE_Menu_StepOut#Start()
			break
		case "Touch":
			DE_Menu_Touch#Start()
			break
		case "Thermal":
			DE_Menu_Thermal#Start()
			break
		case "JumpPause":
			DE_Menu_JumpPause#Start()
			break
		case "StepJump":
			DE_Menu_StepJump#Start()
			break
	endswitch
end

Static Function CheckonPostRamp(ContinueString)
	string ContinueString

	controlinfo/W=DE_CTFCMenu de_ctfcmenu_check1

	if(v_value==1)
		DE_Menu_SingleRamp#Start("")
	else
		strswitch(ContinueString)
			case "Thermal":
				td_setramp(0.05,"PIDSLoop.5.Setpointoffset",0,0,"",0,0,"",0,0,"")
				break
	
	
		endswitch
	endif
	
end


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Macro and Panel
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Static Function ButtonProc(ctrlName) : ButtonControl
	String ctrlName
	StrSwitch(ctrlName)
	
		case "DE_CTFCMenu_But0":
			//DE_Centering#StartCentering_KickIt()
			CheckonPreRamp("StartCentering")
			break
		case "DE_CTFCMenu_But1":
			DE_CTFCMenu#ShowWave("CenteringWave")
			break
		case "DE_CTFCMenu_But2":
			CheckonPreRamp("Touch")
			break
		case "DE_CTFCMenu_But3":
			DE_CTFCMenu#ShowWave("SurfaceWave")
			break
		case "DE_CTFCMenu_But4":
			DE_Menu_SingleRamp#Start("")
			break
		case "DE_CTFCMenu_But5":
			DE_CTFCMenu#ShowWave("SingleRamp")
			break
		case "DE_CTFCMenu_But6":
			//DE_CTFCMenu#StartMultiRamp()
			CheckonPreRamp("StartMulti")
			break
		case "DE_CTFCMenu_But7":
			DE_CTFCMenu#ShowWave("MultiRamp")
			break
		case "DE_CTFCMenu_But8":			
			CheckonPreRamp("JumpPause")

			break
		case "DE_CTFCMenu_But9":
			DE_CTFCMenu#ShowWave("JumpPause")
			break	
		case "DE_CTFCMenu_But10":
			CheckonPreRamp("StartStepOut")
			break
		case "DE_CTFCMenu_But11":
			DE_CTFCMenu#ShowWave("StepOut")
			break	
		case "DE_CTFCMenu_But12":
			DE_CTFCMenu#QuitThis()
			break	
		case "DE_CTFCMenu_But13":
			CheckonPreRamp("Thermal")
			break	
		case "DE_CTFCMenu_But14":
			DE_CTFCMenu#ShowWave("Thermal")
			break	
		case "DE_CTFCMenu_But15":
			CheckonPreRamp("StepJump")
			break	
		case "DE_CTFCMenu_But16":
			DE_CTFCMenu#ShowWave("StepJump")
			break	
		case "DE_CTFCMenu_But17":
			DE_CTFCMENU#DumpSave()
			break	
		case "DE_CTFCMenu_But18":
			ZeroTheZPosition()
			break	

	endswitch
end

Static Function QuitThis()

	Wave/T RepeatInfo=root:DE_CTFC:RepeatSettings
	Wave/T RampInfo=root:DE_CTFC:RampSettings
	Wave/T SlowInfo=root:DE_CTFC:RefoldSettings
	Wave/T TriggerInfo=root:DE_CTFC:TriggerSettings
	wave ZSensorVolts_fast=ZSensor_fast
	variable zerovolt,PVol,Rep
	string Command="Ramping Back"
	DE_TriggeredForcePanel#UpdateCommandOut(Command,"Replace")
	
	zerovolt=(ZSensorVolts_fast(str2num(TriggerInfo[%TriggerTime1]))-str2num(RampInfo[%SurfaceTrigger][0])*1e-12/GV("SpringConstant")/GV("ZLVDTSENS"))
	PVol=Zerovolt-str2num(RampInfo[%StartDistance][0])*1e-9/GV("ZLVDTSEns")
	rep=DE_RepCheck()
	DE_RamptoVol(PVol,"Start","DE_CB_Mol(\\\"TFE\\\","+num2str(rep)+")")
end


Static Function/S GenericNoteFile()
	SVar Lcen=root:DE_CTFC:StuffToDo:LastCenteredTime
	SVar Lstart=root:DE_CTFC:StuffToDo:SeriesStartTime
	
	NVar LcenN=root:DE_CTFC:StuffToDo:LastCentered
	NVar InitRampN=root:DE_CTFC:StuffToDo:InitialRamp
	NVar LastThermal=root:DE_CTFC:StuffToDo:LastThermal

	String FinalString=""
	FinalString=ReplaceStringByKey("Date", FinalString,date(),":","\r")
	FinalString=ReplaceStringByKey("Time", FinalString,time(),":","\r")
	FinalString=ReplaceStringByKey("Spring Constant", FinalString,num2str(GV("SpringConstant")),":","\r")
	FinalString=ReplaceStringByKey("Invols", FinalString,num2str(GV("Invols")),":","\r")
	FinalString=ReplaceStringByKey("XSensor", FinalString,num2str(td_Rv("Xsensor")),":","\r")
	FinalString=ReplaceStringByKey("YSensor", FinalString,num2str(td_Rv("Ysensor")),":","\r")
	FinalString=ReplaceStringByKey("Series Start Time", FinalString,Lstart,":","\r")
	FinalString=ReplaceStringByKey("Initial Ramp Number", FinalString,num2str(InitRampN),":","\r")

	FinalString=ReplaceStringByKey("Last Centered Time", FinalString,Lcen,":","\r")
	FinalString=ReplaceStringByKey("Last Centered ", FinalString,num2str(LcenN),":","\r")
	FinalString=ReplaceStringByKey("Last Thermal ", FinalString,num2str(LastThermal),":","\r")

	FinalString=ReplaceStringByKey("YSensor", FinalString,num2str(td_Rv("Ysensor")),":","\r")
	FinalString=ReplaceStringByKey("XLVDTSens", FinalString,num2str(GV("XLVDTSens")),":","\r")
	FinalString=ReplaceStringByKey("XLVDTOff", FinalString,num2str(GV("XLVDTOffset")),":","\r")
	FinalString=ReplaceStringByKey("YLVDTSens", FinalString,num2str(GV("YLVDTSens")),":","\r")
	FinalString=ReplaceStringByKey("YLVDTOff", FinalString,num2str(GV("YLVDTOffset")),":","\r")
	FinalString=ReplaceStringByKey("ZLVDTSens", FinalString,num2str(GV("ZLVDTSens")),":","\r")
	FinalString=ReplaceStringByKey("ZLVDTOff", FinalString,num2str(GV("ZLVDTOffset")),":","\r")
	FinalString=ReplaceStringByKey("Sum", FinalString,num2str(td_rv("Input.x")),":","\r")

	return FinalString
end

Static Function/S InitialNoteFile()
	SVar Lcen=root:DE_CTFC:StuffToDo:LastCenteredTime
	SVar Lstart=root:DE_CTFC:StuffToDo:SeriesStartTime
	
	NVar LcenN=root:DE_CTFC:StuffToDo:LastCentered
	NVar InitRampN=root:DE_CTFC:StuffToDo:InitialRamp
	NVar LastThermal=root:DE_CTFC:StuffToDo:LastThermal

	String FinalString=""
	FinalString=	ReplaceStringByKey("Type", FinalString,"Initial",":","\r")
	FinalString=	ReplaceStringByKey("Number", FinalString,num2str(InitRampN),":","\r")

	
//	FinalString=	RReplaceStringByKey("Date", FinalString,date(),":","\r")
//	FinalString=ReplaceStringByKey("Time", FinalString,time(),":","\r")
//	FinalString=ReplaceStringByKey("Spring Constant", FinalString,num2str(GV("SpringConstant")),":","\r")
//	FinalString=ReplaceStringByKey("Invols", FinalString,num2str(GV("Invols")),":","\r")
//	FinalString=ReplaceStringByKey("XSensor", FinalString,num2str(td_Rv("Xsensor")),":","\r")
//	FinalString=ReplaceStringByKey("YSensor", FinalString,num2str(td_Rv("Ysensor")),":","\r")
//	FinalString=ReplaceStringByKey("Series Start Time", FinalString,Lstart,":","\r")
//	FinalString=ReplaceStringByKey("Initial Ramp Number", FinalString,num2str(InitRampN),":","\r")
//
//	FinalString=ReplaceStringByKey("Last Centered Time", FinalString,Lcen,":","\r")
//	FinalString=ReplaceStringByKey("Last Centered ", FinalString,num2str(LcenN),":","\r")
//	FinalString=ReplaceStringByKey("Last Thermal ", FinalString,num2str(LastThermal),":","\r")
//
//	FinalString=ReplaceStringByKey("YSensor", FinalString,num2str(td_Rv("Ysensor")),":","\r")
//	FinalString=ReplaceStringByKey("XLVDTSens", FinalString,num2str(GV("XLVDTSens")),":","\r")
//	FinalString=ReplaceStringByKey("XLVDTOff", FinalString,num2str(GV("XLVDTOffset")),":","\r")
//	FinalString=ReplaceStringByKey("YLVDTSens", FinalString,num2str(GV("YLVDTSens")),":","\r")
//	FinalString=ReplaceStringByKey("YLVDTOff", FinalString,num2str(GV("YLVDTOffset")),":","\r")
//	FinalString=ReplaceStringByKey("ZLVDTSens", FinalString,num2str(GV("ZLVDTSens")),":","\r")
//	FinalString=ReplaceStringByKey("ZLVDTOff", FinalString,num2str(GV("ZLVDTOffset")),":","\r")
//	FinalString=ReplaceStringByKey("Sum", FinalString,num2str(td_rv("Input.x")),":","\r")

	return FinalString
end

Window DE_CTFCMenu() : Panel

	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(50,50,750,751)/N=DE_CTFCMenu
	DE_CTFCMenu#MakeRequiredWaves()
	TitleBox DE_CTFCMenu_Box0 pos={10,10},size={120,20},variable=root:DE_CTFC:StuffToDO:SeriesStartTime
	ValDisplay  DE_CTFCMenu_Val0 pos={150,10},title="Initial Ramp Num",size={120,20},value= root:DE_CTFC:StuffToDo:InitialRamp

	Button DE_CTFCMenu_But0 ,pos={10,30},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="ReCenter"
	Button DE_CTFCMenu_But1 ,pos={200,30},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="Show ReCenter Wave"
	TitleBox DE_CTFCMenu_Box1 pos={450,30},size={120,20},variable=root:DE_CTFC:StuffToDO:LastCenteredTime
	ValDisplay  DE_CTFCMenu_Val1 pos={550,30},title="Recenter Ramp Num",size={180,20},value= root:DE_CTFC:StuffToDo:LastCentered

	Button DE_CTFCMenu_But2 ,pos={10,60},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="Touch Off Surface"
	Button DE_CTFCMenu_But3,pos={200,60},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="Show Surface Wave"
	TitleBox DE_CTFCMenu_Box2 variable=root:DE_CTFC:StuffToDO:LastTouchTime,pos={450,60},size={120,20}
	ValDisplay  DE_CTFCMenu_Val9 pos={550,60},title="Last Touch Num",size={120,20},value= root:DE_CTFC:StuffToDo:LastTouch

	Button DE_CTFCMenu_But4 ,pos={10,150},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="Single Ramp"
	Button DE_CTFCMenu_But5,pos={200,150},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="Show Single Ramp "
	ValDisplay  DE_CTFCMenu_Val2 pos={450,150},title="Last Ramp Num",size={120,20},value= root:DE_CTFC:StuffToDo:LastRamp

	Button DE_CTFCMenu_But6 ,pos={10,180},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="MultiRamp"
	Button DE_CTFCMenu_But7,pos={200,180},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="Show Multi Ramp "
	ValDisplay  DE_CTFCMenu_Val4 pos={450,180},title="Last Multi Num",size={120,20},value= root:DE_CTFC:StuffToDo:Multiramp
	ValDisplay  DE_CTFCMenu_Val3 pos={450,180},title="Last MultiRamp Num",size={120,20},value= root:DE_CTFC:StuffToDo:MultiRamp

	Button DE_CTFCMenu_But8 ,pos={10,210},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="Jump/Pause Stage"
	Button DE_CTFCMenu_But9,pos={200,210},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="Show Jump/Pause"
	ValDisplay  DE_CTFCMenu_Val6 pos={450,210},title="Last JumpPause Num",size={180,20},value= root:DE_CTFC:StuffToDo:JumpPause
	
	Button DE_CTFCMenu_But10 ,pos={10,240},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="Step Out"
	Button DE_CTFCMenu_But11,pos={200,240},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="Show StepOut"
	Button DE_CTFCMenu_But12,pos={200,370},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="Quit"
	
	Button DE_CTFCMenu_But13 ,pos={10,90},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="Thermal"
	Button DE_CTFCMenu_But14,pos={200,90},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="Show Thermal Wave"
	TitleBox DE_CTFCMenu_Box3 variable=root:DE_CTFC:StuffToDO:LastThermalTime,pos={450,90},size={120,20}
	ValDisplay  DE_CTFCMenu_Val8 pos={550,90},title="Last Thermal Num",size={120,20},value= root:DE_CTFC:StuffToDo:LastThermal
	
	Button DE_CTFCMenu_But15 ,pos={10,270},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="Step/Pause Stage"
	Button DE_CTFCMenu_But16,pos={200,270},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="Show Step/Pause Pause"
	ValDisplay  DE_CTFCMenu_Val7 pos={450,270},title="Last JumpPause Num",size={180,20},value= root:DE_CTFC:StuffToDo:StepJump
	
	ValDisplay  DE_CTFCMenu_Val5 pos={450,240},title="Last Step Num",size={120,20},value= root:DE_CTFC:StuffToDo:StepOut
	CheckBox DE_CTFCMenu_check0 title="Ramp Before?",pos={300,10}
	CheckBox DE_CTFCMenu_check1 title="Ramp After?",pos={400,10}
	CheckBox DE_CTFCMenu_check2 title="Save Each to HD?",pos={550,10},value=1
	Button DE_CTFCMenu_But17,pos={10,370},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="DumpFolders"
	Button DE_CTFCMenu_But18,pos={50,330},size={150,20},proc=DE_CTFCMenu#ButtonProc,title="ReZero Z"

EndMacro //DE_CTFC_Control


Static Function DumpSave()
	//
	DFREf SavedDataFolder = GetDataFolderDFR()
	//
	String BasicPathStr="C:Users:Asylum User:Desktop:Devin:CTFCMEnu:"
	NewPath/Q/O/C BasicPath,BasicPathStr
	String DatePathStr=BasicPathStr+DE_DateStringForSave()+":"
	NewPath/Q/O/C DatePath,DatePathStr
	String TimePathStr=DatePathStr+DE_TimeStringForSave()+":"
	NewPath/Q/O/C TimePath,TimePathStr
	
	String BaseName=DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_Dump.pxp"
	
	SetDataFolder root:DE_CTFC:StuffToDo:SRamp:Saves
	String CurrentName="Sramp_"+Basename
	SaveData/L=1/Q/P=TimePath CurrentName
	//killwaves/a/z
	
	SetDataFolder root:DE_CTFC:StuffToDo:Centering:Saves
	CurrentName="Centering_"+Basename
	SaveData/L=1/Q/P=TimePath CurrentName
	//killwaves/a/z
	
	SetDataFolder root:DE_CTFC:StuffToDo:MRamp:Saves
	CurrentName="Mramp_"+Basename
	SaveData/L=1/Q/P=TimePath CurrentName
//	killwaves/a/z

	SetDataFolder root:DE_CTFC:StuffToDo:JumpPause:Saves
	CurrentName="JumpPause_"+Basename
	SaveData/L=1/Q/P=TimePath CurrentName
//	killwaves/a/z
	SetDataFolder root:DE_CTFC:StuffToDo:StepOut:Saves
	CurrentName="StepOut_"+Basename
	SaveData/L=1/Q/P=TimePath CurrentName
//	killwaves/a/z
	SetDataFolder root:DE_CTFC:StuffToDo:StepJump:Saves
	CurrentName="StepJump_"+Basename
	SaveData/L=1/Q/P=TimePath CurrentName
//	killwaves/a/z
	SetDataFolder root:DE_CTFC:StuffToDo:Touch:Saves
	CurrentName="Touch_"+Basename
	SaveData/L=1/Q/P=TimePath CurrentName
//	killwaves/a/z
	SetDataFolder root:DE_CTFC:StuffToDo:Thermal:Saves
	CurrentName="Thermal_"+Basename
	SaveData/L=1/Q/P=TimePath CurrentName
//	killwaves/a/z
	
	SetDataFolder SavedDataFolder
	
end


Static Function SaveWavesOut(Type)
	String Type
	//MakeWaitPanel("Saving data.")
	//Print "Saving Capture to Disk"
		controlinfo/W=DE_CTFCMenu de_ctfcmenu_check2

	if(v_value==0)
		return 0
	endif
	
	String BasicPathStr="C:Users:Asylum User:Desktop:Devin:CTFCMEnu:"
	NewPath/Q/O/C BasicPath,BasicPathStr
	String DatePathStr=BasicPathStr+DE_DateStringForSave()+":"
	NewPath/Q/O/C DatePath,DatePathStr
	//String TimePathStr=DatePathStr+DE_TimeStringForSave()+":"
	//NewPath/Q/O/C TimePath,TimePathStr
	
	
	string SaveDataPath,SaveName
	//	PathName="C:Users:Asylum User:Desktop:Devin:CTFCMEnu:"+DE_DateStringForSave()
	//				SaveName=DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FastCapture_"+DE_PreviousForceRamp()+".pxp"
	
	DFREf SavedDataFolder = GetDataFolderDFR()
	KillDataFolder/Z SaveDataFolder
	NewDataFolder/O/S SaveDataFolder
	strswitch(Type)//Right now every program except Multiramp can just launch. multiRamp does it's own thing.
		case "Ramp":
			wave DefVolts=root:DE_CTFC:StuffToDo:SRamp:DefV
			wave ZSensorVolts=root:DE_CTFC:StuffToDo:SRamp:ZSensor
			duplicate/o DefVolts Deflection
			duplicate/o ZSensorVolts ZSensor
			NVar Res= root:DE_CTFC:StuffToDo:LastRamp
			SaveDataPath=DatePathStr+"Sramp:"
			NewPath/Q/O/C SavePath,SaveDataPath

			SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"MenuRamp_"+num2str(Res)+".pxp"

			break
		case "Centering":
			wave CXRZ=root:DE_CTFC:StuffToDo:Centering:CenteringXReadZ
			wave CYRZ=root:DE_CTFC:StuffToDo:Centering:CenteringYReadZ
			wave CXRX=root:DE_CTFC:StuffToDo:Centering:CenteringXReadX
			wave CYRY=root:DE_CTFC:StuffToDo:Centering:CenteringYReadY
			duplicate/o CXRX CenterXReadX
			duplicate/o CXRZ CenterXReadZ
			duplicate/o CYRY CenterYReadY
			duplicate/o CYRZ CenterYReadZ
			NVar Res= root:DE_CTFC:StuffToDo:LastCentered
			SaveDataPath=DatePathStr+"Centering:"
			NewPath/Q/O/C SavePath,SaveDataPath

			SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"MenuCentering_"+num2str(Res)+".pxp"

			break
		case "Multi":
			wave DefVolts=root:DE_CTFC:StuffToDo:MRamp:DefV
			wave ZSensorVolts=root:DE_CTFC:StuffToDo:MRamp:ZSensor
			NVar Res=root:DE_CTFC:StuffToDo:MultiRamp
			duplicate/o DefVolts Deflection
			duplicate/o ZSensorVolts ZSensor
			SaveDataPath=DatePathStr+"MRamp:"
			NewPath/Q/O/C SavePath,SaveDataPath
			SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"Menu_Multi"+num2str(Res)+".pxp"
			break
		case "JumpPause":
			wave DefVEquil= root:DE_CTFC:StuffToDo:JumpPause:DefV
			wave ZSnsrVEquil=root:DE_CTFC:StuffToDo:JumpPause:ZSnsr //These are the waves that are to be read during this process. We don't adjust their size.
			NVar Res=root:DE_CTFC:StuffToDo:JumpPause
			duplicate/o DefVEquil DEquil
			duplicate/o ZSnsrVEquil ZEquil
			SaveDataPath=DatePathStr+"JumpPause:"
			NewPath/Q/O/C SavePath,SaveDataPath
			SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"FMenu_JP_"+num2str(Res)+".pxp"
			break
		case "StepOut":
			wave DefVolts=root:DE_CTFC:StuffToDo:StepOut:DefV
			wave ZSensorVolts=root:DE_CTFC:StuffToDo:StepOut:ZSensor
			NVar Res=root:DE_CTFC:StuffToDo:StepOut
			duplicate/o DefVolts  SO_DefV
			duplicate/o ZSensorVolts  SO_ZsnsrV
			SaveDataPath=DatePathStr+"StepOut:"
			NewPath/Q/O/C SavePath,SaveDataPath
			SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"Menu_SO_"+num2str(Res)+".pxp"
			break
		case "StepJump":
			
			wave DefVolts=root:DE_CTFC:StuffToDo:StepJump:DefV
			wave ZSensorVolts=root:DE_CTFC:StuffToDo:StepJump:ZSensor
			wave EqDVolts=root:DE_CTFC:StuffToDo:StepJump:DefV_Equil
			wave EqZVolts=root:DE_CTFC:StuffToDo:StepOut:ZSensor_Equil
			NVar Res=root:DE_CTFC:StuffToDo:StepJump
			duplicate/o DefVolts  SO_DefV
			duplicate/o ZSensorVolts  SO_ZsnsrV
			duplicate/o EqDVolts  SO_Eq_DefV
			duplicate/o EqZVolts  SO_Eq_ZsnsrV
			SaveDataPath=DatePathStr+"StepJump:"
			NewPath/Q/O/C SavePath,SaveDataPath
			NVar Res=root:DE_CTFC:StuffToDo:StepJump
			SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"Menu_SJ_"+num2str(Res)+".pxp"
			break
		case "Touch":
			
			wave DefVolts=root:DE_CTFC:StuffToDo:Touch:DefV
			wave ZSensorVolts=root:DE_CTFC:StuffToDo:Touch:ZSensor

			NVar Res=root:DE_CTFC:StuffToDo:StepJump
			duplicate/o DefVolts  Touch_DefV
			duplicate/o ZSensorVolts  Touch_ZsnsrV

			SaveDataPath=DatePathStr+"Touch:"
			NewPath/Q/O/C SavePath,SaveDataPath
			NVar Res=root:DE_CTFC:StuffToDo:LastTouch
			SaveName= DE_DateStringForSave()+"_"+DE_TimeStringForSave()+"_"+"Menu_SJ_"+num2str(Res)+".pxp"
			break
	endswitch
	SaveData/L=1/Q/P=SavePath SaveName

	SetDataFolder SavedDataFolder
end
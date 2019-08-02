#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName = DE_SearchPattern

Static function MakeSpots()
	Make/o/n=1/C spotswave
	wave/T Repeat=RepeatSettings
	if(cmpstr(Repeat[%Repeat][0],"No")==0)
		controlinfo popup0
		strswitch(S_Value)
			case "Simple Ramp":
				DE_TriggeredForcePanel#StartSimpleRamp()
				break
	
			default:
				DE_TriggeredForcePanel#StartCTFC() //This goes aheads and makes our spot wave
				break
		endswitch
		return 0
	endif
	
	if(str2num(Repeat[%XPnts][0])*str2num(Repeat[%YPnts][0])==1)
		controlinfo popup0
		strswitch(S_Value)
			case "Simple Ramp":
				DE_TriggeredForcePanel#StartSimpleRamp()
				break
	
			default:
				DE_TriggeredForcePanel#StartCTFC() //This goes aheads and makes our spot wave
				break
		endswitch
		return 0
	endif
	
	make/C/o/n=(str2num(Repeat[%XPnts][0]),str2num(Repeat[%YPnts][0])) $nameofwave(SpotsWave)/Wave=SpotWave

	controlinfo check1
	variable scansize,xstart,ystart

	if(V_value==1)//Do we want this to be a local search
		if(str2num(Repeat[%ScanSize][0])>1)
			scansize=1
		else
			scansize=str2num(Repeat[%ScanSize][0])
		endif
		
		xstart=td_rv("XSensor")-str2num(Repeat[%ScanSize][0])*1e-6/gv("xLVDTSens")/2//trying to get into V
		ystart=td_rv("YSensor")-str2num(Repeat[%ScanSize][0])*1e-6/gv("yLVDTSens")/2//trying to get into V

	else
		scansize=str2num(Repeat[%ScanSize][0])
		xstart=-str2num(Repeat[%ScanSize][0])*1e-6/gv("xLVDTSens")/2-GV("XLVDTOFfset")//trying to get into V
		ystart=-str2num(Repeat[%ScanSize][0])*1e-6/gv("yLVDTSens")/2-GV("YLVDTOFfset")//trying to get into V

	endif
	/////////////////
	xstart=.1-str2num(Repeat[%ScanSize][0])*1e-6/gv("xLVDTSens")/2//trying to get into V
	ystart=.2-str2num(Repeat[%ScanSize][0])*1e-6/gv("yLVDTSens")/2//trying to get into V
	/////////////////////
	variable xstep=str2num(Repeat[%ScanSize][0])*1e-6/gv("xLVDTSens")/str2num(Repeat[%XPnts][0])//trying to get into V/pnt
	variable ystep=str2num(Repeat[%ScanSize][0])*1e-6/gv("yLVDTSens")/str2num(Repeat[%YPnts][0])//trying to get into V/pnt

	SpotWave[][]=cmplx(xstart+xstep*p,ystart+ystep*q)
	Make/o/n=(numpnts(SpotWave)) root:DE_CTFC:MenuStuff:Display_Rspotswave
	Make/o/n=(numpnts(SpotWave)) root:DE_CTFC:MenuStuff:Display_Ispotswave
	Make/o/n=1 root:DE_CTFC:MenuStuff:Display_RNowSpot, root:DE_CTFC:MenuStuff:Display_INowSpot
	wave DI=root:DE_CTFC:MenuStuff:Display_Ispotswave
	wave DR=root:DE_CTFC:MenuStuff:Display_Rspotswave
	Make/o/n=1 root:DE_CTFC:MenuStuff:Display_RNowSpot, root:DE_CTFC:MenuStuff:Display_INowSpot

	wave NR=root:DE_CTFC:MenuStuff:Display_RNowSpot
	wave NI= root:DE_CTFC:MenuStuff:Display_INowSpot
	NR=real(SpotWave[0][0])
	NI=imag(SpotWave[0][0])
	DR=real(SpotWave[mod(p,dimsize(SpotWave,0))][floor(p/dimsize(SpotWave,0))])
	DI=imag(SpotWave[mod(p,dimsize(SpotWave,0))][floor(p/dimsize(SpotWave,0))])
	controlinfo popup0
	string callbackString
	strswitch(S_Value)
		case "Simple Ramp":
			callbackString="StartXY(\"DE_TriggeredForcePanel#StartSimpleRamp()\")"
			Withdraw(callbackString)
			break
	
		default:
			callbackString="StartXY(\"DE_TriggeredForcePanel#StartCTFC()\")"
			Withdraw(callbackString)
			break
	endswitch
	

end


function NextSpot()
	wave/C spotswave
	wave/T Repeat=RepeatSettings
	variable newx, newy,add
	string Command
	variable xspot=mod(str2num(Repeat[%CurrentSpot][0]),str2num(Repeat[%XPnts][0]))
	variable yspot=(str2num(Repeat[%CurrentSpot][0])-xspot)/str2num(Repeat[%XPnts][0])//Here we just calculate our current X and Y spots
	add=str2num(Repeat[%CurrentSpot][0])+1  //increment spot location 
	Repeat[%CurrentSpot][0]=num2str(add)   //save the new spot location
	Make/o/n=1 root:DE_CTFC:MenuStuff:Display_RNowSpot, root:DE_CTFC:MenuStuff:Display_INowSpot
	wave NR=root:DE_CTFC:MenuStuff:Display_RNowSpot
	wave NI= root:DE_CTFC:MenuStuff:Display_INowSpot

	if(xspot+1==str2num(Repeat[%xPnts][0]))
		if(yspot+1==str2num(Repeat[%yPnts][0]))
			Command="Spots Done"
			DE_TriggeredForcePanel#UpdateCommandOut(Command,"Replace")
			return 0
		else
			newx=0
			newy=yspot+1
			NR=real(spotswave[newx][newy])
			NI=imag(spotswave[newx][newy])
			MoveToXandY(newx,newy)
		endif
	else
		newx=xspot+1
		newy=yspot
		NR=real(spotswave[newx][newy])
		NI=imag(spotswave[newx][newy])
		MoveToXandY(newx,newy)
	endif

end

function MoveToXandY(newx,newy)
	variable newx,newy

	wave/C SpotWaves
	//Need to withdraw
	string callbackString="MoveXY("+num2str(newx)+","+num2str(newy)+",\"MoveDone()\")"
	Withdraw(callbackString)
end


function StartXY(callbackString)
	string callbackString
	print callbackString
	string Command="Move to first spot."
	DE_TriggeredForcePanel#UpdateCommandOut(Command,"Replace")
	wave/C SpotsWave
	td_setramp(.1,"PIDSLoop.0.SetPoint",0,real(SpotsWave[0][0]),"PIDSLoop.1.SetPoint",0,imag(SpotsWave[0][0]),"",0,0,callbackString)

end


function Withdraw(callbackString)
	string CallbackString
	
	string Command
	Command="Full withdrawn"
	DE_TriggeredForcePanel#UpdateCommandOut(Command,"Replace")
	variable Location=td_RV("Output.z")-15
	td_setramp(.1,"Output.Z",0,Location,"",0,0,"",0,0,callbackString)
end

function MoveXY(newx,newy,CallbackString)
	variable newx,newy
	string CallbackString
	
	string Command="Move to new spot."
	DE_TriggeredForcePanel#UpdateCommandOut(Command,"Replace")
	wave/C SpotsWave
	td_setramp(.1,"PIDSLoop.0.SetPoint",0,real(SpotsWave[newx][newy]),"PIDSLoop.1.SetPoint",0,imag(SpotsWave[newx][newy]),"",0,0,callbackString)

end

function MoveDone()
	DE_newSpotStart()
end


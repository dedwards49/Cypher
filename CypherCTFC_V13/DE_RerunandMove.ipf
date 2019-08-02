#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName = DE_RerunandMove		// The following procedures are in ModuleA


//The goal of CheckforRepeat is to return a number telling the program "DE_LoopRepeat", what to do.
//Here we define what to do by the case structure: "Again", simply means to run again at the same spot, 
//"Stop" means to stop, "SmallMove" tells us to iterate a small step. "LargeMove" Tells us to take a large 
//step
static Function/S SimpleCheckforRepeat()			// Semi-private
	Wave/t RampInfo=RampSettings
	Wave/t RepeatInfo=RepearSettings
	Wave/t RefoldInfo=RefoldSettings
	string Result
	
	if(str2num(RepeatInfo[%CurrentLoops][0])<str2num(RepeatInfo[%TotalLoops][0]))  //Checks if the total number of iterations at this spot has been exceeded

		Result="Again"
		
	else

		RepeatInfo[%CurrentLoops][0]="0"   //Reset the iterations

		if((str2num(RepeatInfo[%CurrentSpot][0])+1)<str2num(RepeatInfo[%TotalSpots][0]))  //Checks if the total number of spots has been exceeded
	
			Result="BigMove"
				

		else
		
			Result="Stop"
		endif
	
	endif

	return Result
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//MakeGrid is responsible for making the grid. This is called earlier, and is simple a matrix that tells
//us all the x,y voltages we want to visit
static Function/S MakeGrid(GridWave,StartX,EndX,StartY,EndY,Xspots,YSpots)			// Semi-private
	wave/C Gridwave 
	variable StartX,EndX,StartY,EndY,Xspots,YSpots
//	Wave/t RampInfo=RampSettings
//	Wave/t RepeatInfo=RepearSettings
//	Wave/t RefoldInfo=RefoldSettings
	Redimension/n=(Xspots*YSpots) Gridwave
	make/n=(Xspots*YSpots) Reals,Imags
	variable stepx=(EndX-Startx)/(Xspots-1)
	variable stepy=(Endy-Starty)/(yspots-1)
	Gridwave=cmplx(StartX+stepx*mod(p,xspots),Starty+stepy*floor(p/xspots))
	Reals=real(gridwave)
	Imags=imag(Gridwave)
	note/K Gridwave "Spot: 0"
End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static Function NextSpot(GridWave)			// Semi-private
	wave/C Gridwave
	variable current=str2num(stringbykey("Spot",note(Gridwave),":","\r"))
	variable new=current+1
	if(new>dimsize(Gridwave,0)-1)
	print "FULL"
	return -1
	endif
	
	//MovetoNextSpot(XV,YV)
	note/K Gridwave "Spot: "+num2str(new)
	//Redimension/n=(Xspots,YSpots) Gridwave

End

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static function MovetoNextSpot(XVoltage,YVoltage,Callback)
	variable XVoltage, YVoltage
	string Callback
	td_SetRamp(.1, "PIDSLoop.0.Setpoint", 0, XVoltage, "PIDSLoop.1.Setpoint", 0, YVoltage, "",0, 0,Callback)

end
//To do List:
//Add new movement commands
//start to track when the last good pull was (i.e., something triggered).

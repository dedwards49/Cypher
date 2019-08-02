#pragma rtGlobals=3		// Use modern global access method and strict wave access.
Function GoToNextForcePlot()

	ForceDisplayButtonProc("Next1ForceButton_0")

End //GoToNextForcePlot

Function GetAllForceAdhesion()


		String GraphStr = cARGFGN

	
	String FPList, DataFolderList
	GetForcePlotsList(0,FPList,DataFolderList)
	Variable A, nop = ItemsInList(FPList,";")
	for (A = 0;A < nop-1;A += 1)
		ForceDisplayButtonProc("Minu1ForceButton_0")
	endfor

	//Then select the fist one.
	//(Set Display Index to 0)
	ForceDisplaySetVarFunc("ForceDisplayIndexSetVar_0",10,"",":Variables:ForceDispVariablesWave[%ForceDisplayIndex]")
	
	
	//GetAdhesionFromForceWaves()
	GetForcePlotsList(0,FPList,DataFolderList)
	print stringfromlist(0,FPList)
	GetForcePlotsList(2,FPList,DataFolderList)
	String FPName, DataFolder
	String TraceList, TraceName
	String DisplayFolder = ""
	nop = ItemsInList(FPList,";")
	A = 1
	do 
		GoToNextForcePlot()
		GetForcePlotsList(0,FPList,DataFolderList)
		FPname = StringFromList(0,FpList,";")
		DataFolder = StringfromList(0,DataFolderList,";")
		DisplayFolder = ARGetForceFolder("Display",DataFolder,FPName)
		TraceList = ARTraceNameList(GraphStr,"*Defl*","L0","Bottom",DisplayFolder)
		TraceName = StringFromList(0,TraceList,";")
		Wave YData = TraceNameToWaveRef(GraphStr,TraceName)
		if(cmpstr(stringbykey("Pull Speed (Pair)",note(YData),":","\r"),"")==0)
		print "DELETING"
		print nameofwave(YData)
			DeleteSelectedForceCurves(1+2^2,0)
			ForceDisplaySetVarFunc("ForceDisplayIndexSetVar_0",A-1,"",":Variables:ForceDispVariablesWave[%ForceDisplayIndex]")
			
		//delete
		else
		
		A += 1
		endif
	while(A < nop)

	//OK, lets add in a little spice,
	//we would like to see our data...
	//ARHistogram(AdhesionData,"AdhesionData",0)		//make a histogram.


End //GetAllForceAdhesion
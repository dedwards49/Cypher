#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/////////////////////////////////////////////////////////////////////////
// Here's the start of my functions

// This is a super function that will take any function with an arguments list and apply it to the saved force waves
// Here are the main features...
// 1) If you include "ForceWave" or "SepWave", it will automatically put the force or separation wave into the argument of the function
// 2) You can apply your function to a subset of force waves by including a string list of force waves using the optional argument FPList.
// 2 continued... The default is to run the function on all the saved force waves
// 3) You can supply an explicit output wave name using the option arugment OutputWaveName.  The default is OutputWave
// 4) You can also put a specific destination folder for your outputs
// 5) If you have functions that output waves, use NumOutputs to define how many outputs each function should have.  
//     For example, do NumOutputs="3;2;1" for a list of functions with 3, 2 and 1 element outputs
Function ApplyFuncsToForceWaves(FunctionInputList,[FPList,OutputWaveNameList,DestFolder,NumOutputs])
	String FunctionInputList,FPList,OutputWaveNameList,DestFolder,NumOutputs

	// If I don't include a specific directory, then put it in MyForceData
	If(ParamIsDefault(DestFolder))
		DestFolder = BuildDataFolder("root:MyForceData:")
	EndIf
	
	SetDataFolder DestFolder
	
	String FPName, DataFolder, FPMasterList, DataFolderMasterList,DataFolderList=""
	GetForcePlotsList(2,FPMasterList,DataFolderMasterList)

	// If I don't include a specific list, then just include everything
	If(ParamIsDefault(FPList))
		FPList = FPMasterList
		DataFolderList = DataFolderMasterList
	EndIf
	
	// Figure out how many force pulls we are dealing with
	Variable A, nop = ItemsInList(FPList,";")

	// If we include a list of specific force pulls, then figure out what folders they are located in
	If(!ParamIsDefault(FPList))
		For (A = 0;A < nop;A += 1)
			Variable DataFolderListLoc=WhichListItem(StringFromList(A,FPList,";"), FPMasterList,";")
			DataFolderList+=StringFromList(DataFolderListLoc,DataFolderMasterList,";")+";"
		EndFor
	EndIf
	
	Variable NumFunctions=ItemsInList(FunctionInputList,";")
	
	// If we don't include a names for the output waves, just call them outputwave1,outputwave2,etc.
	If(ParamIsDefault(OutputWaveNameList))
		Variable Counter=0
		OutputWaveNameList=""
		For(Counter=0;Counter<NumFunctions;Counter+=1)
			OutputWaveNameList+= "OutputWave"+Num2Str(Counter)+";"
		EndFor
	EndIf
	
	// If I don't tell you how many outputs the functions have, just assume they all output 0 value
	If(ParamIsDefault(NumOutputs))
		Counter=0
		NumOutputs=""
		For(Counter=0;Counter<NumFunctions;Counter+=1)
			NumOutputs+= "0"+";"
		EndFor
	EndIf

	// Initialize Output Waves
	For(Counter=0;Counter<NumFunctions;Counter+=1)
		Variable NumColumns = str2num(StringFromList(Counter,NumOutputs,";"))
		Make/O/N=(nop,NumColumns) $StringFromList(Counter,OutputWaveNameList,";")
	EndFor

	// This is our master loop.  It will iterate through our list of Force Ramps and apply our functions
	for (A = 0;A < nop;A += 1)
		
		// Get name and location of force ramp
		FPName = StringFromList(A,FPList,";")
		DataFolder = StringFromList(A,DataFolderList,";")
		
		// Next lines deal with putting in the correct wave references
		String FRWaveNameKeys="Force_Ret;Force_Ext;Sep_Ret;Sep_Ext;Defl_Ret;Defl_Ext;DeflV_Ret;DeflV_Ext;ZSnsr_Ret;ZSnsr_Ext;"
		Variable NumKeys=ItemsInList(FRWaveNameKeys), KeyCounter=0
		String KeysUsed=""
		String FunctionInputListForLoop=FunctionInputList
		FunctionInputListForLoop=ReplaceString("ForceWave", FunctionInputListForLoop, "Force_Ret")
		FunctionInputListForLoop=ReplaceString("SepWave", FunctionInputListForLoop, "Sep_Ret")
		FunctionInputListForLoop=ReplaceString("FRName", FunctionInputListForLoop, "\""+FPName+"\"")
		
		For(KeyCounter=0;KeyCounter<NumKeys;KeyCounter+=1)
			String FRKey=StringFromList(KeyCounter,FRWaveNameKeys)
			String StringReplacementString=FPName+FRKey
			If(strsearch(FunctionInputListForLoop,FRKey,0,2)!=-1)
				FunctionInputListForLoop=ReplaceString(FRKey, FunctionInputListForLoop, StringReplacementString)
				KeysUsed+=FRKey+";"
			EndIf
		EndFor
		
		Variable NumKeysUsed=ItemsInList(KeysUsed), KeyUsedCounter=0
		Variable NoData=0
		
		For(KeyUsedCounter=0;KeyUsedCounter<NumKeysUsed;KeyUsedCounter+=1)
			String CurrentKey=StringFromList(KeyUsedCounter,KeysUsed)
			String FRWavePath=DestFolder+FPName+CurrentKey		
			Wave DestForceData = InitOrDefaultWave(FRWavePath,0)
			Variable KeyPrefixLength= strlen(CurrentKey)-5
			String KeyPrefix=CurrentKey[0,KeyPrefixLength]
			Wave/Z SrcForceData = $CalcForceDataType(DataFolder,FPName+KeyPrefix)
			if ((!WaveExists(SrcForceData)) || (DimSize(SrcForceData,0) == 0))
				NoData=1
				Continue		//we don't have force for this force plot
			endif
			ExtractForceSection(SrcForceData,DestForceData)
			if ((!WaveExists(DestForceData)) || (DimSize(DestForceData,0) == 0))
				NoData=1
				Continue		//we don't have force for this force plot
			endif

		EndFor
		
		Variable FunctionCounter=0
		
		
		// Now we are going to loop through all those functions and apply them to our force and separation data
		For(FunctionCounter=0;FunctionCounter<NumFunctions;FunctionCounter+=1)
			Wave OutputWave=$StringFromList(FunctionCounter,OutputWaveNameList,";")
			
			String FunctionInput=StringFromList(FunctionCounter,FunctionInputListForLoop,";")
			Variable NumberOfFunctionOutputs=str2num(StringFromList(FunctionCounter,NumOutputs,";"))
			Variable CorrectEndIndex=NumberOfFunctionOutputs-1
			String CommandString=""
			
			If(NumberOfFunctionOutputs==0)
				// Now we construct the string of the form outputwave[A]=Function(function arguments)
				CommandString = FunctionInput
				If(NoData)
					CommandString=" "
				EndIf
				// Now I use execute to actually run this string as if I typed it into the command line.  I set the dimension label with the name of the force pull
				Execute CommandString
			EndIf
			// For a single output from a wave, we can use a single line to set up everything correctly
			If(NumberOfFunctionOutputs==1)
				// Now we construct the string of the form outputwave[A]=Function(function arguments)
				CommandString = NameOfWave(OutputWave)+"["+Num2Str(A)+"]="+FunctionInput
				If(NoData)
					CommandString=NameOfWave(OutputWave)+"["+Num2Str(A)+"]=nan"
				EndIf
				// Now I use execute to actually run this string as if I typed it into the command line.  I set the dimension label with the name of the force pull
				Execute CommandString
			EndIf
			
			// For a function that returns a multiple outputs through a wave reference, we need to use a duplicate to create a local copy of the wave (TempWave)
			// Next we set the columns from TempWave into rows for the output wave.  This will provide a very useful wave to create a multidimensional output wave
			// I also preserve the dimension labels from the rows of temp wave and make them column names for output wave.  
			// This is useful to keep track of all the various outputs and keep code cleaner for functions that depend on these data.  
			If (NumberOfFunctionOutputs>1)
				Variable DimCounter=0
				String MultiOutputCommandString="Duplicate/O "+ FunctionInput+",TempWave"
				If(NoData)
					MultiOutputCommandString="Make/O/N=("+num2str(NumberOfFunctionOutputs)+") TempWave;TempWave=nan"
				EndIf
				Execute MultiOutputCommandString
				Wave TempWave=TempWave

				For (DimCounter=0;DimCounter<NumberOfFunctionOutputs;DimCounter+=1)
					String TheLabel=GetDimLabel(TempWave, 0, DimCounter)
					SetDimLabel 1,DimCounter,$TheLabel,OutputWave
					OutputWave[A][DimCounter]=TempWave[DimCounter]
				EndFor
			EndIf
			
			// Set the row label as the name of the force pull
			SetDimLabel 0,A,$FPName,OutputWave 
				
		EndFor // Function Loop
		
		// Finally, I kill the force and separation waves, to keep things clean in the My Force Folder and prevent the program from crashing when dealing with big 
		// igor experiment files.
		For(KeyUsedCounter=0;KeyUsedCounter<NumKeysUsed;KeyUsedCounter+=1)
			CurrentKey=StringFromList(KeyUsedCounter,KeysUsed)
			FRWavePath=DestFolder+FPName+CurrentKey		

			If(WaveExists($FRWavePath))
				KillWaves $FRWavePath
			EndIf 
		EndFor
		
	endfor
	
End //GetRetraceDataFromForceWaves

//The function SelectWaves will apply a function to a bunch of force waves.  If the output is 1, then it selects the wave.  If 0, it does not.  
// You can put in a list of waves and it will only apply the selection function to that wave. The default is all to search all FR pulls
Function/S SelectFRByFunction(FunctionInput,[ForceWaveList])
	String FunctionInput,ForceWaveList

	// Apply our function to all force ramps by default, and to a specific list if included in the optional function argument
	If(ParamIsDefault(ForceWaveList))
		ApplyFuncsToForceWaves(FunctionInput,OutputWaveNameList="SelectedWaves")
	Else
		ApplyFuncsToForceWaves(FunctionInput,FPList=ForceWaveList,OutputWaveNameList="SelectedWaves")
	EndIf
	// Find output wave
	Wave SelectedWaves=root:MyForceData:SelectedWaves
	// Return a list of the selected waves
	Return SelectFRByWave(SelectedWaves)
End

// This function you can select by a data wave.  
// In this case, you use a function to determine if a FR meets your criteria using existing data waves and output it to a wave for this function
//  0== not selected, 1== selected.  DimLabel should by the name of the FR
Function/S SelectFRByWave(WaveDataInput)
	Wave WaveDataInput
	
	Variable Counter=0
	Variable NumFR = DimSize(WaveDataInput,0)
	String SelectedFRList=""
	For(Counter=0;Counter<NumFR;Counter+=1)
		If(WaveDataInput[Counter]==1)
			SelectedFRList+=GetDimLabel(WaveDataInput, 0, Counter )+";"
		EndIf
	EndFor
	
	Return SelectedFRList

End

Function OffsetForceRet(ForceRetWave,NumPoints)
	Wave ForceRetWave
	Variable NumPoints
	Variable ForceWaveSize=DimSize(ForceRetWave,0)
	Duplicate/O/R=[ForceWaveSize-NumPoints,ForceWaveSize] ForceRetWave, ZeroForceDeflection
	WaveStats/Q ZeroForceDeflection
	ForceRetWave-=V_avg
	ForceRetWave*=-1

End

Function CalcForceOffset(ForceRetWave,NumPoints)
	Wave ForceRetWave
	Variable NumPoints
	Variable ForceWaveSize=DimSize(ForceRetWave,0)
	Duplicate/O/R=[ForceWaveSize-NumPoints,ForceWaveSize] ForceRetWave, ZeroForceDeflection
	WaveStats/Q ZeroForceDeflection
	Return V_avg
End

Function OffsetSepRet(SepRetWave)
	Wave SepRetWave
	Variable Offset = SepRetWave[0]
	SepRetWave-=Offset
End

Function CalcSepOffset(SepRetWave)
	Wave SepRetWave
	If (DimSize(SepRetWave,0)<1)
		Return 0
	EndIf
	Return SepRetWave[0]
End

// This is a useful utility function.  It determines the force and separation offsets.  
// The optional parm NumPoints determines how many points from the end of the force wave to average for the force offset
// The default for this is 10 points
Function/Wave OffsetStats(ForceRetWave,SepRetWave,[NumPoints,OffsetWaves])
	Wave ForceRetWave,SepRetWave
	Variable NumPoints,OffsetWaves
	
	// Set default Numpoints to 10
	If(ParamIsDefault(NumPoints))
		NumPoints =10
	EndIf
	
	// Make the output wave and use other functions to calculate the offsets
	Make/O/N=2 ForceSepOffsetStats
	ForceSepOffsetStats = {CalcForceOffset(ForceRetWave,NumPoints),CalcSepOffset(SepRetWave)}
	
	// Set row labels to keep things clean and readable
	SetDimLabel 0,0,$"Offset_Force",ForceSepOffsetStats
	SetDimLabel 0,1,$"Offset_Sep",ForceSepOffsetStats
	
	
	// OffsetWaves set to anything, then apply the additive offsets to the force and sep wave.  If offset waves set to 1, then multiply the force wave by -1
	If(!ParamIsDefault(OffsetWaves))
			Variable ForceOffset=-ForceSepOffsetStats[%$"Offset_Force"]
			Variable SepOffset=-ForceSepOffsetStats[%$"Offset_Sep"]
			FastOp ForceRetWave=(ForceOffset)+ForceRetWave
			FastOp SepRetWave=(SepOffset)+SepRetWave
			If(OffsetWaves==1)
				FastOp ForceRetWave=-1*ForceRetWave
			EndIf
	EndIf
	 
	Return ForceSepOffsetStats
	
End // OffsetStats()

Function UpdateOffsetStats(ForceRetWave,SepRetWave,FRName)
	Wave ForceRetWave,SepRetWave
	String FRName
	Variable NumPoints,OffsetWaves
	
	Duplicate/O OffsetStats(ForceRetWave,SepRetWave,OffsetWaves=0), NewOffsetStats
	
	Wave Offsets=root:MyForceData:Offsets
	Offsets[%$FRName][%Offset_Force]=-NewOffsetStats[%Offset_Force]
	Offsets[%$FRName][%Offset_Sep]=NewOffsetStats[%Offset_Sep]
	KillWaves NewOffsetStats
End

// This function calculates the rupture force, the wave index of the rupture force and the separation the rupture force happens at
Function/Wave BreakingForceStats(ForceRetWave,SepWave,StartDist,[OffsetWaves])
	Wave ForceRetWave,SepWave
	Variable StartDist,OffsetWaves
	
	// Create Duplicates that I can offset for proper measurements without messing up any subsequent operations on these waves
	Duplicate ForceRetWave,ForceRet
	Duplicate SepWave, SepRet

	If(!ParamIsDefault(OffsetWaves))
		OffsetForceRet(ForceRet,10)
		OffsetSepRet(SepRet)
		If(OffsetWaves==1)
			FastOp ForceRet=-1*ForceRet
		EndIf

	EndIf

	// Figure out the start and end index from the separation wave
	FindLevel/Q/P SepRet,StartDist
	Variable StartIndex = Floor(V_LevelX)
	Variable EndIndex = DimSize(SepWave, 0)
	
	// Create a force wave (named testwave) that only includes the segments using the indexes found above
	Duplicate/O/R=[StartIndex,EndIndex] ForceRet, TestWave
	WaveStats/Q TestWave
	Variable ForceMax=V_Min	-TestWave[numpnts(TestWave)-1]		// Uses the minimum of the segment of the force wave we are looking for
	Variable ForceMaxLoc=V_MinRowLoc+StartIndex  		// The index for this max force is 
	Variable ForceMax_Sep = SepWave[ForceMaxLoc]-SepWave[0]		// Use the index to find the separation associated with max force

	// Make the output wave and apply the appropriate labels to them.  
	Make/O/N=3 BreakForceStats
	BreakForceStats = {ForceMax,ForceMaxLoc,ForceMax_Sep}
	SetDimLabel 0,0,$"Rupture_Force",BreakForceStats
	SetDimLabel 0,1,$"Rupture_Index",BreakForceStats
	SetDimLabel 0,2,$"Rupture_Sep",BreakForceStats
	 
	 // Get rid of the temp waves to keep things clean in the data folder
	KillWaves ForceRet,SepRet,TestWave
	Return BreakForceStats
End 

Function UpdateRuptureWave(ForceWave,SepWave,StartDist,FRName)
	Wave ForceWave,SepWave
	Variable StartDist
	String FRName
	
	Wave RuptureForce=root:MyForceData:RuptureForce
	Duplicate/O BreakingForceStats(ForceWave,SepWave,StartDist), NewRuptureForce
	RuptureForce[%$FRName][%Rupture_Force]=NewRuptureForce[%Rupture_Force]
	RuptureForce[%$FRName][%Rupture_Index]=NewRuptureForce[%Rupture_Index]
	RuptureForce[%$FRName][%Rupture_Sep]=NewRuptureForce[%Rupture_Sep]
End


// Box car averages and decimates the force and separation wave with 
Function BoxCarAndDecimateFR(ForceWave,SepWave,BoxCarNumber,DecimationFactor,[SmoothMode])
	Wave ForceWave,SepWave
	Variable BoxCarNumber,DecimationFactor
	String SmoothMode
	If(ParamIsDefault(SmoothMode))
		SmoothMode="BoxCar"
	EndIf
	
	StrSwitch(SmoothMode)
		case "BoxCar":
			Smooth/B BoxCarNumber, ForceWave,SepWave
		break
		case "SavitzkyGolay":
			Variable BoxCarMod=Mod(BoxCarNumber,2)
			If(BoxCarMod==0)
				BoxCarNumber+=1
			EndIf
			
			Smooth/S=(2) BoxCarNumber, ForceWave,SepWave
		break
	EndSwitch
	
	Resample/DOWN=(DecimationFactor) ForceWave,SepWave
End

Function SetBoxCarForFrequency(TargetFrequency,ForceWave,FRName)
	Variable TargetFrequency
	Wave ForceWave
	String FRName
	
	Wave FilterAndDecimation=root:MyForceData:FilterAndDecimation

	Variable CurrentFrequency=1/Deltax(ForceWave)
	Variable FreqRatio=CurrentFrequency/TargetFrequency
	If(FreqRatio<1)
		FreqRatio=1
	EndIf
	Variable BoxCarNum=Round(FreqRatio)
	Variable Decimation=Round(BoxCarNum/2)
	If(Decimation<1)
		Decimation=1
	EndIf
	
	FilterAndDecimation[%$FRName][%NumToAverage]=BoxCarNum
	FilterAndDecimation[%$FRName][%Decimation]=Decimation
End

Function SetBoxCarForFrequencyByVelocity(TargetFrequency,TargetPullingVelocity,ForceWave,FRName)
	Variable TargetFrequency,TargetPullingVelocity
	Wave ForceWave
	String FRName
		
	Variable PullingVelocity=GetPullingVelocity(ForceWave)
	Variable VelocityLowerBound=TargetPullingVelocity*0.97
	Variable VelocityUpperBound=TargetPullingVelocity*1.03
	

	If((PullingVelocity>VelocityLowerBound)&&(PullingVelocity<VelocityUpperBound))
	
		Wave FilterAndDecimation=root:MyForceData:FilterAndDecimation

		Variable CurrentFrequency=1/Deltax(ForceWave)
		Variable FreqRatio=CurrentFrequency/TargetFrequency
		If(FreqRatio<1)
			FreqRatio=1
		EndIf
		Variable BoxCarNum=Round(FreqRatio)
		Variable Decimation=Round(BoxCarNum/2)
		If(Decimation<1)
			Decimation=1
		EndIf
	
		FilterAndDecimation[%$FRName][%NumToAverage]=BoxCarNum
		FilterAndDecimation[%$FRName][%Decimation]=Decimation
	
	EndIf
	
End

Function SetBoxToFreq_Adaptive(TargetFrequency,PullingVelocity,ForceWave,FRName,[ScaleFactor])
	Variable TargetFrequency,PullingVelocity,ScaleFactor
	Wave ForceWave
	String FRName
	
	Wave FilterAndDecimation=root:MyForceData:FilterAndDecimation
	Variable CurrentFrequency=1/Deltax(ForceWave)
	Variable FreqRatio=TargetFrequency/CurrentFrequency
	If(FreqRatio<1)
		FreqRatio=1
	EndIf
	Variable BoxCarNum=Round(FreqRatio)
	Variable Decimation=Round(BoxCarNum/2)
	If(Decimation<1)
		Decimation=1
	EndIf
	If(ParamIsDefault(ScaleFactor))
		ScaleFactor=1
	EndIf
	
	Variable TargetPullingVelocity=GetPullingVelocity(ForceWave)
	Variable RatioOfVelocity=TargetPullingVelocity/PullingVelocity
	Variable BoxCarScale=BoxCarNum*RatioOfVelocity*ScaleFactor
	
	FilterAndDecimation[%$FRName][%NumToAverage]=Round(BoxCarNum*RatioOfVelocity*ScaleFactor)
	FilterAndDecimation[%$FRName][%Decimation]=Round(Decimation*RatioOfVelocity*ScaleFactor)
End

// Detrend Fit Functions
Function/S FindDetrendFunction(ForceWave,SepWave,DetrendType,[StartIndex,EndIndex,PercentFromStart])
	Wave ForceWave,SepWave
	String DetrendType
	Variable StartIndex,EndIndex,PercentFromStart
	
	Variable NumPoints=DimSize(ForceWave,0)

	If(ParamIsDefault(StartIndex))
		StartIndex=0
	EndIf
	If(ParamIsDefault(PercentFromStart))
		PercentFromStart=70
	EndIf
	If(ParamIsDefault(EndIndex))
		EndIndex=Floor(NumPoints*PercentFromStart/100)
	EndIf

	Duplicate/O/R=[StartIndex,EndIndex] ForceWave, ForceFitWave,DetrendFitWave
	Duplicate/O/R=[StartIndex,EndIndex] SepWave, SepFitWave
	

	Strswitch(DetrendType)
	case "None":
		Return "None"
	break
	case "Sin":
		CurveFit/G/M=2/W=0/Q/N=1 sin, ForceFitWave /X=SepFitWave /D=DetrendFitWave
	
		Return num2str(K0)+"+"+num2str(K1)+"*sin("+num2str(K2)+"*x+"+num2str(K3)+")"
	break
	
	EndSwitch
	
	Return "Unknown Function Type"

End // FindDetrendFunction

Function FindAndSaveDetrendFunction(FRName,ForceWave,SepWave,DetrendFunctionType)
	String FRName
	Wave ForceWave,SepWave
	String DetrendFunctionType
	Variable StartIndex,EndIndex,PercentFromStart
	
	K0=ForceWave[0]
	K1=10e-12
	K2=2*Pi/330e-9
	K3=0
	FastOp ForceWave=-1*ForceWave
	String DetrendFunctionToSave=FindDetrendFunction(ForceWave,SepWave,DetrendFunctionType)
	
	Wave/T DetrendFunctions=root:MyForceData:DetrendFunctions
	DetrendFunctions[%$FRName][%DetrendType]=DetrendFunctionType
	DetrendFunctions[%$FRName][%DetrendFunction]=DetrendFunctionToSave
	
End
// By Name
Function ApplyDetrendFunctionByName(ForceWave,SepWave,FRName,[InvertForceData])
	Wave ForceWave,SepWave
	String FRName
	Variable InvertForceData
	
	If(ParamIsDefault(InvertForceData))
		InvertForceData=0
	EndIf

	If(InvertForceData)
		FastOp ForceWave=-1*ForceWave
	EndIf
	Wave/T DetrendFunctions=root:MyForceData:DetrendFunctions
	String DetrendFunction=DetrendFunctions[%$FRName][%DetrendFunction]
	ApplyDetrendFunction(ForceWave,SepWave,DetrendFunction)
End

Function ApplyDetrendFunction(ForceWave,SepWave,DetrendFunction)
	Wave ForceWave,SepWave
	String DetrendFunction
	String ForceWaveName=NameOfWave(ForceWave)
	String SepWaveName=NameOfWave(SepWave)
	String xReplacementString=SepWaveName+"(x)"
	
	If(!StringMatch(DetrendFunction,"None"))
		String DetrendString=ForceWaveName+"-="+"("+ReplaceString("x", DetrendFunction, xReplacementString)+")"
		Execute DetrendString
	EndIf
	
End // ApplyDetrendFunction


Function LoadCorrectedFR(ForceWave,SepWave,FRName,[Filter,Offset])
	Wave ForceWave,SepWave
	String FRName
	Variable Filter,Offset
	
	If(ParamIsDefault(Filter))
		Filter=1
	EndIf
	If(ParamIsDefault(Offset))
		Offset=1
	EndIf

	Wave Offsets=root:MyForceData:Offsets
	Wave FilterAndDecimation=root:MyForceData:FilterAndDecimation
	Variable ForceOffset=Offsets[%$FRname][%Offset_Force]
	Variable SepOffset=-Offsets[%$FRname][%Offset_Sep]
	
	ApplyDetrendFunctionByName(ForceWave,SepWave,FRName,InvertForceData=1)
	If(Filter)
		BoxCarAndDecimateFR(ForceWave,SepWave,FilterAndDecimation[%$FRName][%NumToAverage],FilterAndDecimation[%$FRName][%Decimation])
	EndIF
	If(Offset)
		FastOp ForceWave=(ForceOffset)+ForceWave
		FastOp SepWave=(SepOffset)+SepWave
	Endif
	
End // LoadCorrectedFR

// SelectByBreakingForce returns 1 if the rupture force is greater than the threshold force
Function SelectByBreakingForce(ForceRetWave,SepWave,Threshold,[StartDist])
	Wave ForceRetWave,SepWave
	Variable StartDist,Threshold

	// If no starting distance is provided then just start at 0.
	If(ParamIsDefault(StartDist))
		StartDist=0
	EndIf
	// Using breaking force stats to calculate the rupture force
	Duplicate BreakingForceStats(ForceRetWave,SepWave,StartDist), RuptureForceWave
	Variable RuptureForce=RuptureForceWave[%$"Rupture_Force"]
	If (RuptureForce>Threshold)
		Return 1
	Else 
		Return 0
	Endif
End

// Selects by rupture force range.  Looks as the rupture force in "RuptureForce" wave
// as detemined by user inputs lowforce and highforce.  
// FR List name refers the name of the force wave list in SavedFRLists
// This function will output a string list of force waves that are in range.
Function/S SelectByRFRange(LowForce,HighForce,FRListName)
	Variable LowForce, HighForce
	String FRListName
	
	Wave RuptureForce=root:MyForceData:RuptureForce
	Wave/T SavedFRLists=root:MyForceData:SavedFRLists
	String OuputFRList=""
	String FRList=SavedFRLists[%$FRListName]
	Variable NumFRList=ItemsInList(FRList)
	Variable Counter=0
	For(Counter=0;Counter<NumFRList;Counter+=1)
		String FRName=StringFromList(Counter, FRList)
		Variable RF=	RuptureForce[%$FRName][%Rupture_Force]
		If((RF>LowForce)&&(RF<HighForce))
			OuputFRList+=FRName+";"
		EndIf
	EndFor
	Return OuputFRList
End

Function GetChangeInCL(CLType,[OutputWaveName,FRList,FRListName])
	String FRList,CLType,OutputWaveName,FRListName
	Wave/T SavedFRLists=root:MyForceData:SavedFRLists
	
	If(ParamIsDefault(FRListName)&&ParamIsDefault(FRList))
		FRList=SavedFRLists[%FR_All]
	EndIf
	If(!ParamIsDefault(FRListName)&&!ParamIsDefault(FRList))
		FRList=SavedFRLists[%FR_All]
	EndIf
	If(!ParamIsDefault(FRListName)&&ParamIsDefault(FRList))
		FRList=SavedFRLists[%$FRListName]
	EndIf

	If(ParamIsDefault(OutputWaveName))
		OutputWaveName="OutputWave"
	EndIf
	
	String GMString=""
	If(StringMatch("ChangeInCL_CLSpace",CLType))
		GMString="CLSpace_Peaks"
	EndIf
	If(StringMatch("ChangeInCL_WLCFits",CLType))
		GMString="WLC_ContourLength"
	EndIf
	Make/O/N=0 OldOutputWaveCL, OutputWaveCL
	
	Variable NumFR=ItemsInList(FRList), FRCounter=0
	For(FRCounter=0;FRCounter<NumFR;FRCounter+=1)
		String FRName=StringFromList(FRCounter, FRList)
		GetMeasurement(GMString,FRList=FRName,OutputWaveName="CLWaveInfo")
		Wave CLWaveInfo=root:MyForceData:CLWaveInfo
		Sort CLWaveInfo,CLWaveInfo
		Variable NumCL=DimSize(CLWaveInfo,0)
		If(NumCL>0)
			Make/O/N=(NumCL) AddToOutputWaveCL
			AddToOutputWaveCL[0]=CLWaveInfo[0]
			Variable CLCounter=1
			For(CLCounter=1;CLCounter<NumCL;CLCounter+=1)
				AddToOutputWaveCL[CLCounter]=CLWaveInfo[CLCounter]-CLWaveInfo[CLCounter-1]
			EndFor
			
		Concatenate/O/NP=0 {AddToOutputWaveCL, OldOutputWaveCL}, OutputWaveCL
		Duplicate/O OutputWaveCL,OldOutputWaveCL

		EndIf
				
	EndFor
	
	If(!ParamIsDefault(OutputWaveName))
		Duplicate/O OutputWaveCL, $OutputWaveName
		KillWaves OutputWaveCL
	EndIf
	
End

Function BellEvansModelFitFunc(XbAndko,LoadingRate):FitFunc
	Wave XbAndko
	Variable LoadingRate
	
	Return (1.3806488e-23*298/XbAndko[0])*ln(LoadingRate*XbAndko[0]/XbAndko[1]/1.3806488e-23/298)

End

Function BellEvansModel(RuptureForce,LoadingRate,[OutputWaveName, XbGuess,koGuess])
	Wave RuptureForce,LoadingRate
	String OutputWaveName
	Variable XbGuess,koGuess
	
	Duplicate/O LoadingRate, BellEvans_Fit
	Make/D/O/N=2 XbAndko
	If(ParamIsDefault(XbGuess))
		XbGuess=1e-10
	EndIf
	If(ParamIsDefault(koGuess))
		koGuess=10e-3
	EndIf
	XbAndko[0]=XbGuess
	XbAndko[1]=koGuess
	
	FuncFit/Q/N/NTHR=0/W=2 BellEvansModelFitFunc kwCWave=XbAndko RuptureForce /X=LoadingRate /D=BellEvans_Fit
	Duplicate/O BellEvans_Fit,RuptureForce_Fit
	Duplicate/O LoadingRate, LoadingRate_Fit
	
	Variable DeltaG=-1.3806488e-23*298*ln(XbAndko[1]*6.62606957e-34/1.3806488e-23/298)
	
	If(ParamIsDefault(OutputWaveName))
		OutputWaveName="BellEvansOutputWave"
	EndIf
	Make/O/N=4 $OutputWaveName
	Wave BellEvansOutputWave=$OutputWaveName
	
	SetDimLabel 0,0,BarrierDistance,BellEvansOutputWave
	SetDimLabel 0,1,OffRate,BellEvansOutputWave
	SetDimLabel 0,2,EnergyBarrier,BellEvansOutputWave
	SetDimLabel 0,3,EnergyBarrierInKbT,BellEvansOutputWave
	 
	 BellEvansOutputWave[%BarrierDistance]=XbAndko[0]
	 BellEvansOutputWave[%OffRate]=XbAndko[1]
	 BellEvansOutputWave[%EnergyBarrier]=DeltaG
	 BellEvansOutputWave[%EnergyBarrierInKbT]=DeltaG/1.3806488e-23/298
End

// Filter out force versus loading rate data by persistence length
Function FilteredForceVsLoadingRate(LowPL,HighPL,LowCL,HighCL,FRListName,[SpecialMode])
	Variable LowPL,HighPL,LowCL,HighCL
	String FRListName,SpecialMode
	
	GetMeasurement("WLC_RuptureForce",FRListName=FRListName,SpecialMode=SpecialMode,OutputWaveName="FilteredRuptureForce")
	GetMeasurement("WLC_PersistenceLength",FRListName=FRListName,SpecialMode=SpecialMode,OutputWaveName="FilteredPL")
	GetMeasurement("WLC_LoadingRate",FRListName=FRListName,SpecialMode=SpecialMode,OutputWaveName="FilteredLoadingRate")
	GetMeasurement("WLC_ContourLength",FRListName=FRListName,SpecialMode=SpecialMode,OutputWaveName="FilteredContourLength")
	
	Wave FilteredRuptureForce=root:MyForceData:FilteredRuptureForce
	Wave FilteredPL=root:MyForceData:FilteredPL
	Wave FilteredLoadingRate=root:MyForceData:FilteredLoadingRate
	Wave FilteredContourLength=root:MyForceData:FilteredContourLength
	
	Sort FilteredPL,FilteredPL,FilteredRuptureForce,FilteredLoadingRate,FilteredContourLength
	FindLevel/Q/P FilteredPL,LowPL
	Variable StartPoint=Ceil(V_LevelX)
	DeletePoints 0, StartPoint, FilteredPL,FilteredRuptureForce,FilteredLoadingRate,FilteredContourLength
	Variable NumPointsLeft=DimSize(FilteredPL,0)
	FindLevel/Q/P FilteredPL,HighPL
	If(V_flag==0)
		Variable EndPoint=Floor(V_LevelX)
		DeletePoints EndPoint, NumPointsLeft, FilteredPL,FilteredRuptureForce,FilteredLoadingRate,FilteredContourLength
	EndIf
	
	Sort FilteredContourLength,FilteredPL,FilteredRuptureForce,FilteredLoadingRate,FilteredContourLength
	FindLevel/Q/P FilteredContourLength,LowCL
	Variable StartPointCL=Ceil(V_LevelX)
	DeletePoints 0, StartPointCL, FilteredPL,FilteredRuptureForce,FilteredLoadingRate,FilteredContourLength
	Variable NumPointsLeftCL=DimSize(FilteredContourLength,0)
	FindLevel/Q/P FilteredContourLength,HighCL
	If(V_flag==0)
		Variable EndPointCL=Floor(V_LevelX)
		DeletePoints EndPointCL, NumPointsLeftCL, FilteredPL,FilteredRuptureForce,FilteredLoadingRate,FilteredContourLength
	EndIf
	
	Sort FilteredLoadingRate,FilteredPL,FilteredRuptureForce,FilteredLoadingRate,FilteredContourLength
	FindLevel/Q/P FilteredLoadingRate,0
	If(V_flag==0)
		Variable StartPointLR=Ceil(V_LevelX)
		DeletePoints 0, StartPointLR, FilteredPL,FilteredRuptureForce,FilteredLoadingRate,FilteredContourLength
	EndIf

End

// Make a wave with the requested quantity for a list of force ramps

Function GetMeasurement(TargetMeasurement,[FRListName,FRList,OutputWaveName,SpecialMode])
	String TargetMeasurement,FRListName,FRList,OutputWaveName,SpecialMode
	Wave/T SavedFRLists=root:MyForceData:SavedFRLists
	
	If(ParamIsDefault(FRListName)&&ParamIsDefault(FRList))
		FRList=SavedFRLists[%FR_All]
	EndIf
	If(!ParamIsDefault(FRListName)&&!ParamIsDefault(FRList))
		FRList=SavedFRLists[%FR_All]
	EndIf
	If(!ParamIsDefault(FRListName)&&ParamIsDefault(FRList))
		FRList=SavedFRLists[%$FRListName]
	EndIf
	If(ParamIsDefault(OutputWaveName))
		OutputWaveName="OutputWave_GM"
	EndIf

	String SingleWaveMeasurements="Rupture_Force;Rupture_Sep;Offset_Force;Offset_Sep"
	String MultiWaveMeasurements="CLSpace_Peaks;WLC_ContourLength;WLC_RuptureForce;WLC_Offset;WLC_PersistenceLength;WLC_LoadingRate;"
	String TargetWaveName,TargetIndex,IndexName
	Variable NumItems=0,Counter=0

	// If this is a single wave measurement, use the appropriate search strategy
	If(WhichListItem(TargetMeasurement,SingleWaveMeasurements)>-1)
		Strswitch(TargetMeasurement)
			case "Rupture_Force":
			case "Rupture_Sep":
				TargetWaveName="root:MyForceData:RuptureForce"
			break
			case "Offset_Force":
			case "Offset_Sep":
				TargetWaveName="root:MyForceData:Offsets"
			break
		EndSwitch
		TargetIndex=TargetMeasurement
		NumItems=ItemsInList(FRList)
		Make/N=(NumItems) OutputWave
		Wave TargetWave=$TargetWaveName
		For(Counter=0;Counter<NumItems;Counter+=1)
			IndexName=StringFromList(Counter, FRList)
			OutputWave[Counter]=TargetWave[%$IndexName][%$TargetIndex]
			SetDimLabel 0,Counter,$IndexName,OutputWave
		EndFor
	EndIf
	
	// If this is a multi wave measurement, use the appropriate search strategy
	If(WhichListItem(TargetMeasurement,MultiWaveMeasurements)>-1)
		String TargetWavePrefix,TargetWaveSuffix
		Strswitch(TargetMeasurement)
			case "CLSpace_Peaks":
				TargetWavePrefix="root:MyForceData:CLSpace:"
				TargetWaveSuffix="_CL"
				TargetIndex="CLPeak_PeakCL"
			break
			case "WLC_ContourLength":
			case "WLC_RuptureForce":
			case "WLC_Offset":
			case "WLC_PersistenceLength":
			case "WLC_LoadingRate":
				TargetWavePrefix="root:MyForceData:WLCFits:"
				TargetWaveSuffix="_WLCF"
				TargetIndex=StringFromList(1, TargetMeasurement,"_")
			break
			case "MeanSep":
				TargetWavePrefix="root:MyForceData:Segments:"
				TargetWaveSuffix="_Seg"
				TargetIndex="MeanSep"
			break

			
		EndSwitch

		Variable NumFR=ItemsInList(FRList)
		Make/O/N=0 OutputWave
		For(Counter=0;Counter<NumFR;Counter+=1)
			Wave TestWave=$(TargetWavePrefix+StringFromList(Counter, FRList)+TargetWaveSuffix)
		 	Duplicate/O OutputWave, OldOutputWave
		 	Variable NumRows=DimSize(TestWave, 0)
		 	String FirstRowLabel=GetDimLabel(TestWave, 0, 0 )
			If((NumRows>0)&&!(StringMatch(FirstRowLabel,"None")))
				Make/O/N=(NumRows) AddToOutputWave
				AddToOutputWave=TestWave[p][%$TargetIndex]
				StrSwitch(SpecialMode)
					Case "OnlyLast":
						DeletePoints 0, NumRows-1, AddToOutputWave
					Break
					Case "BeforeLast":
						DeletePoints NumRows-1, 1, AddToOutputWave
					Break
				EndSwitch
				Concatenate/O/NP {AddToOutputWave, OldOutputWave}, OutputWave
			EndIf
		EndFor

	EndIf

	Duplicate/O OutputWave, $OutputWaveName
	KillWaves OutputWave
	
End
// Getting one of the force ramp settings from the wave note.  
// Should have things like pulling velocity, invols, spring constant, etc.
Function/S GetForceRampSetting(ForceWave,ParmString)
	Wave ForceWave
	String ParmString
	
	String NoteStr = Note(ForceWave)
	String Parm = StringByKey(ParmString,NoteStr,":","\r")
	return(Parm)
End //GetForceRampSetting

Function GetPullingVelocity(ForceWave)
	Wave ForceWave
	Variable Velocity = str2num(GetForceRampSetting(ForceWave,"Velocity"))
	Variable Velocity2 = str2num(GetForceRampSetting(ForceWave,"RetractVelocity"))
	If(Velocity > Velocity2)
		Velocity=Velocity2
	EndIf
	
	Return Velocity
End

Function GetLVDTPosition(ForceWave,XorY)
	Wave ForceWave
	String XorY
	String LVDTString=XorY+"LVDT"
	String PositionString=GetForceRampSetting(ForceWave,LVDTString)
	Return str2num(PositionString)
End

Function GetSpotPosition(ForceWave)
	Wave ForceWave
	String ParmString="ForceSpotNumber"
	String SpotPositionString=GetForceRampSetting(ForceWave,ParmString)
	Return str2num(SpotPositionString)
End

Function SelectBySpotPosition(ForceWave,TargetSpotPosition)
	Wave ForceWave
	Variable TargetSpotPosition
	Variable SpotPosition=GetSpotPosition(ForceWave)
	
	If(TargetSpotPosition==SpotPosition)
		Return 1
	EndIf
	
	Return 0
End
Function SelectByVelocityRange(ForceWave,LowerVelocity,HigherVelocity)
	Wave ForceWave
	Variable LowerVelocity,HigherVelocity
	Variable Velocity=GetPullingVelocity(ForceWave)
		
	If((Velocity>LowerVelocity)&&(Velocity<HigherVelocity))
		Return 1
	EndIf
	
	Return 0
End

// Just outputs a suffix
Function/S MeaurementSuffix(TargetMeasurement)
	String TargetMeasurement
	
	Return StringByKey(TargetMeasurement,"Rupture_Force:_RF;Rupture_Sep:_RS;Offset_Force:_OF;Offset_Sep_OS;CLSpace_Peaks:_CLSPk;WLC_ContourLength:_WLC_CL;WLC_RuptureForce:_WLC_RF;WLC_Offset:_WLC_O;WLC_PersistenceLength:_WLC_PL;WLC_LoadingRate:_WLC_LR;ChangeInCL_CLSpace:_CCL_CLS;ChangeInCL_WLCFits:_CCL_WLC")

End

// Function to display an adjustable histogram for any "GetMeasurement" parameter with a  specific FRList
// Should also add support to show multiple histograms at some point.
Function FRUHistogram(TargetMeasurement,TargetFRListName,[SpecialMode])
	String TargetMeasurement,TargetFRListName,SpecialMode
	// Add Suffix Scheme here
	String OutputWaveSuffix=MeaurementSuffix(TargetMeasurement)
	String RawDataWaveName=TargetFRListName+OutputWaveSuffix
	String FullPathDataWaveName="root:MyForceData:Analysis:"+RawDataWaveName
	String ChangeInCLStringList="ChangeInCL_CLSpace;ChangeInCL_WLCFits"
	
	StrSwitch(SpecialMode)
	Case "OnlyLast":
		FullPathDataWaveName+="_OL"
	Break
	Case "BeforeLast":
		FullPathDataWaveName+="_BL"
	Break
	EndSwitch


	If(WhichListItem(TargetMeasurement,ChangeInCLStringList)>-1)
		GetChangeInCL(TargetMeasurement,FRListName=TargetFRListName,OutputWaveName=FullPathDataWaveName)
	Else
		GetMeasurement(TargetMeasurement,FRListName=TargetFRListName,OutputWaveName=FullPathDataWaveName,SpecialMode=SpecialMode)
	EndIf

	Wave DataWave=$FullPathDataWaveName
	ARHistogram(DataWave,RawDataWaveName,1)
End

// Function to display any "Get Measurement" parameter versus another "Get Measurement Parameter"
Function FRUDisplay(TargetYMeasurement, TargetXMeasurement, TargetFRListName,[SpecialMode])
	String TargetYMeasurement, TargetXMeasurement, TargetFRListName,SpecialMode
	// Add Suffix Scheme here
	String OutputYWaveSuffix=MeaurementSuffix(TargetYMeasurement)
	String RawDataYWaveName=TargetFRListName+OutputYWaveSuffix
	String OutputXWaveSuffix=MeaurementSuffix(TargetXMeasurement)
	String RawDataXWaveName=TargetFRListName+OutputXWaveSuffix
	String FullPathYDataWaveName="root:MyForceData:Analysis:"+RawDataYWaveName
	String FullPathXDataWaveName="root:MyForceData:Analysis:"+RawDataXWaveName
	
	StrSwitch(SpecialMode)
	Case "OnlyLast":
		FullPathYDataWaveName+="_OL"
		FullPathXDataWaveName+="_OL"
		
	Break
	Case "BeforeLast":
		FullPathYDataWaveName+="_BL"
		FullPathXDataWaveName+="_BL"
	Break
	EndSwitch

	
	GetMeasurement(TargetXMeasurement,FRListName=TargetFRListName,OutputWaveName=FullPathXDataWaveName,SpecialMode=SpecialMode)
	GetMeasurement(TargetYMeasurement,FRListName=TargetFRListName,OutputWaveName=FullPathYDataWaveName,SpecialMode=SpecialMode)

	Wave DataXWave=$FullPathXDataWaveName
	Wave DataYWave=$FullPathYDataWaveName
	
	String WindowName=TargetFRListName+OutputYWaveSuffix+"vs"+OutputXWaveSuffix
	String WindowTitle=TargetYMeasurement + " vs " + TargetXMeasurement + " for "+TargetFRListName
	
	DoWindow $WindowName
	If(V_Flag==0)
		Display/N=$WindowName DataYWave vs DataXWave
		ModifyGraph mode=3
	
		DoWindow/T $WindowName,WindowTitle
		Label left TargetYMeasurement
		Label bottom TargetXMeasurement
	EndIf

	
End
// ************************************************************
// Here's the function to calculate the loading rate
Function LoadingRate(ForceWave,StartIndex,EndIndex,[FractionFromEnd,NumPointsFromEnd])
	Wave ForceWave
	Variable StartIndex,EndIndex,FractionFromEnd,NumPointsFromEnd
	
	// I'm going to set some options later to only fit to the end part of the WLC segment.  
	// Not doing that right now.  
	If(ParamIsDefault(FractionFromEnd))
		FractionFromEnd=0.33
	EndIf
	
	Variable NewStartIndex=Round(EndIndex-(EndIndex-StartIndex)*FractionFromEnd)
	If((EndIndex-NewStartIndex)<5)
		NewStartIndex=StartIndex
	EndIf
	
	Duplicate/O/R=[NewStartIndex,EndIndex] ForceWave,LoadingRateSegment,LoadingRateSegment_Fit
	CurveFit/Q line, LoadingRateSegment /D=LoadingRateSegment_Fit
	
	Return K1
	
End


// *************************************************************
// Here's the section with the fitting functions for WLC

Function WLCForceFitFunction(PCLengths,Sep):FitFunc
	Wave PCLengths
	Variable Sep
	
	Return 0.25*(1.3806488e-23*298)/PCLengths[0]*(((1-Sep/PCLengths[1])^-2)-1+4*Sep/PCLengths[1])

End //WLCFitFunction

Function ExtensibleWLCHighForce(PCAndModulus,Force):FitFunc
	Wave PCAndModulus
	Variable Force
	
	Return PCAndModulus[1]*(1-0.5*(1.3806488e-23*298/Force/PCAndModulus[0])^0.5+Force/PCAndModulus[2])-PCandModulus[3]

End

Function WLCFit(Force,Sep,Model,[CLGuess,PLGuess,StretchModulus,Offset,HoldPL,HoldCL])
	Wave Force,Sep
	String Model
	Variable CLGuess,PLGuess,StretchModulus,Offset,HoldPL,HoldCL
	
	Duplicate/O Force, WLC_Fit
	
	If(ParamIsDefault(CLGuess))
		CLGuess=350e-9
	EndIf
	If(ParamIsDefault(PLGuess))
		PLGuess=50e-9
	EndIf
	If(ParamIsDefault(StretchModulus))
		StretchModulus=0
	EndIf
	If(ParamIsDefault(Offset))
		Offset=0
	EndIf
	If(ParamIsDefault(HoldPL))
		HoldPL=0
	EndIf
	If(ParamIsDefault(HoldCL))
		HoldCL=0
	EndIf

	String HoldCode=num2str(HoldPL)+num2str(HoldCL)

	StrSwitch(Model)
		case "WLC":
			Make/D/O/N=2 WLC_Coeff
			WLC_Coeff[0]=PLGuess
			WLC_Coeff[1]=CLGuess
			FuncFit/Q/N/NTHR=0/W=2/H=HoldCode WLCForceFitFunction kwCWave=WLC_Coeff Force /X=Sep /D=WLC_Fit
			Duplicate/O WLC_Fit,ForceFit
			Duplicate/O Sep, SepFit

		break
		case "ExtensibleWLC":
			If(StretchModulus==0)
				StretchModulus=1050e-12
			EndIf
			Make/D/O/N=4 WLC_Coeff
			WLC_Coeff[0]=PLGuess
			WLC_Coeff[1]=CLGuess
			WLC_Coeff[2]=StretchModulus
			WLC_Coeff[3]=Offset
			HoldCode+="11"
			FuncFit/Q/N/NTHR=0/W=2/H=HoldCode ExtensibleWLCHighForce kwCWave=WLC_Coeff Sep /X=Force /D=WLC_Fit
			
			Duplicate/O Force,ForceFit
			Duplicate/O WLC_Fit, SepFit
		break
	EndSwitch
	
End // WLCFIt

Function WLCGuide(Model,CL,PL,[ForceWaveName,SepWaveName,StretchModulus,Offset,MaxForce])
	String Model
	Variable CL,PL
	String ForceWaveName,SepWaveName
	Variable StretchModulus,Offset,MaxForce
	If(ParamIsDefault(ForceWaveName))
		ForceWaveName="root:MyForceData:WLCGuide_Force"
	EndIf
	If(ParamIsDefault(SepWaveName))
		SepWaveName="root:MyForceData:WLCGuide_Sep"
	EndIf
	If(ParamIsDefault(StretchModulus))
		StretchModulus=1050e-12
	EndIf
	If(ParamIsDefault(Offset))
		Offset=0
	EndIf
	If(ParamIsDefault(MaxForce))
		MaxForce=200e-12
	EndIf
	
	Variable EndPoint=0
	
	StrSwitch(Model)
		case "WLC":
			EndPoint=98
			Make/D/O/N=98 $SepWaveName,$ForceWaveName
			Wave Sep = $SepWaveName
			Wave Force = $ForceWaveName
			Sep=p/100*CL
			Make/D/O/N=4 WLCGuide_Coeff
			WLCGuide_Coeff[0]=PL
			WLCGuide_Coeff[1]=CL
			Force=WLCForceFitFunction(WLCGuide_Coeff,Sep[p])
		break
		case "ExtensibleWLC":
			If(StretchModulus==0)
				StretchModulus=1000e-12
			EndIf
			EndPoint=995
			Make/D/O/N=995 $SepWaveName,$ForceWaveName
			Wave Sep = $SepWaveName
			Wave Force = $ForceWaveName
			Force=p/1000*MaxForce

			Make/D/O/N=4 WLCGuide_Coeff
			WLCGuide_Coeff[0]=PL
			WLCGuide_Coeff[1]=CL
			WLCGuide_Coeff[2]=StretchModulus
			WLCGuide_Coeff[3]=Offset

			Sep= ExtensibleWLCHighForce(WLCGuide_Coeff,Force[p])
		break
	EndSwitch
	
	FindLevel/Q/P Force, MaxForce
	If(!V_flag)
		EndPoint=Ceil(V_LevelX)
	EndIf
	Duplicate/O/R=[0,EndPoint] Force, ForceTemp, SepTemp
	Duplicate/O/R=[0,EndPoint] Sep, SepTemp

	Duplicate/O/R=[0,EndPoint] ForceTemp, Force
	Duplicate/O/R=[0,EndPoint] SepTemp, Sep
	
	Force[EndPoint]=MaxForce
	Sep[EndPoint]=Sep[V_LevelX]
	
	KillWaves ForceTemp,SepTemp
	
End // WLCGuide

Function AutoWLCFit(ForceWave,SepWave,FRName)
	Wave ForceWave,SepWave
	String FRName
	
	String FRSegmentsName="root:MyForceData:Segments:"+FRName+"_Seg"
	String WLCSegmentsName="root:MyForceData:WLCFits:"+FRname+"_WLCF"
	Wave FRSegments=$FRSegmentsname
	
	Variable SegmentCounter=0
	Variable NumSegments=DimSize(FRSegments,0)
	Variable NumWLCSegments=0

	For(SegmentCounter=0;SegmentCounter<NumSegments;SegmentCounter+=1)
		NumWLCSegments+=FRSegments[SegmentCounter][%WLC]
	EndFor

	Make/N=(NumWLCSegments,10)/O $WLCSegmentsName
	Wave WLCSegments=$WLCSegmentsName
	SetDimLabel 1,0,StartIndex,WLCSegments
 	SetDimLabel 1,1,EndIndex,WLCSegments
	SetDimLabel 1,2,ContourLength,WLCSegments
	SetDimLabel 1,3,PersistenceLength,WLCSegments
	SetDimLabel 1,4,ContourLengthGuess,WLCSegments
	SetDimLabel 1,5,PersistenceLengthGuess,WLCSegments
	SetDimLabel 1,6,StretchModulus,WLCSegments
	SetDimLabel 1,7,Offset,WLCSegments	
	SetDimLabel 1,8,RuptureForce,WLCSegments
	SetDimLabel 1,9,LoadingRate,WLCSegments

	Variable WLCSegmentCounter=0
	SegmentCounter=0
	String WLCModel="ExtensibleWLC"

	For(SegmentCounter=0;SegmentCounter<NumSegments;SegmentCounter+=1)
		If(FRSegments[SegmentCounter][%WLC])
			Variable PLGuess=50e-9
			Variable OffsetGuess=0
			Variable StretchModulusGuess=1050e-12
			
			String SegmentName=GetDimLabel(FRSegments, 0, SegmentCounter )
			String Molecule=SegmentName
			If(WhichListItem(Molecule,"Protein;NUG2;NLeC;Calmodulin;BR;")>-1)
				PLGuess=0.5e-9
				OffsetGuess=0
				StretchModulusGuess=0
				WLCModel="WLC"
			EndIf
			If(WhichListItem(Molecule,"ssRNA;B12 Riboswitch;")>-1)
				PLGuess=1e-9
				OffsetGuess=0
				StretchModulusGuess=0
				WLCModel="WLC"
			EndIf
					
			WLCSegments[WLCSegmentCounter][%StartIndex]=FRSegments[SegmentCounter][%StartIndex]
			WLCSegments[WLCSegmentCounter][%EndIndex]=FRSegments[SegmentCounter][%EndIndex]
			WLCSegments[WLCSegmentCounter][%RuptureForce]=FRSegments[SegmentCounter][%MaxForce]
			WLCSegments[WLCSegmentCounter][%LoadingRate]=LoadingRate(ForceWave,FRSegments[SegmentCounter][%StartIndex],FRSegments[SegmentCounter][%EndIndex])
			WLCSegments[WLCSegmentCounter][%PersistenceLengthGuess]=PLGuess
			WLCSegments[WLCSegmentCounter][%ContourLengthGuess]=FRSegments[SegmentCounter][%MeanCL]
			WLCSegments[WLCSegmentCounter][%Offset]=OffsetGuess
			WLCSegments[WLCSegmentCounter][%StretchModulus]=StretchModulusGuess

			SetDimLabel 0,WLCSegmentCounter,$SegmentName,WLCSegments
			WLCSegmentCounter+=1
		EndIf
	EndFor

	Variable Counter=0
	For(Counter=0;Counter<NumWLCSegments;Counter+=1)
	
		Duplicate/O/R=[WLCSegments[Counter][%StartIndex],WLCSegments[Counter][%EndIndex]] ForceWave,WLCSegmentForce_Ret
		Duplicate/O/R=[WLCSegments[Counter][%StartIndex],WLCSegments[Counter][%EndIndex]] SepWave,WLCSegmentSep_Ret
		WLCFit(WLCSegmentForce_Ret,WLCSegmentSep_Ret,WLCModel,CLGuess=WLCSegments[Counter][%ContourLengthGuess],PLGuess=WLCSegments[Counter][%PersistenceLengthGuess],StretchModulus=WLCSegments[Counter][%StretchModulus],Offset=WLCSegments[Counter][%Offset])
		Wave WLC_Coeff=root:MyForceData:WLC_Coeff
		WLCSegments[Counter][%ContourLength]=WLC_Coeff[1]
		WLCSegments[Counter][%PersistenceLength]=WLC_Coeff[0]
	EndFor
		
End //AutoWLCFit

// I've got a series of functions to do contour length transforms and then analysis
// This function transforms the force extension data into contour length space.  Potentially VERY useful.
Function MakeContourLengthWave(ForceRetWave,SepWave,[Temperature,PersistenceLength,MoleculeType,Threshold,CLName])
	Wave ForceRetWave,SepWave
	Variable PersistenceLength,Temperature,Threshold
	String MoleculeType,CLName
	
	Variable StretchModulus
	
	If(ParamIsDefault(MoleculeType))
		MoleculeType = "dsDNA"
	EndIf	
	
	Strswitch(MoleculeType)
		case "dsDNA":
			PersistenceLength = 50e-9
			StretchModulus=1050e-12
		break
		case "Protein":
		case "NUG2":
		case "NLeC":
		case "Calmodulin":
			PersistenceLength = 0.5e-9
			StretchModulus=0
		break
		case "RNA":
			PersistenceLength = 1.5e-9
			StretchModulus=0
		break

	Endswitch
	
	If(ParamIsDefault(Temperature))
		Temperature = 298
	EndIf
	If(ParamIsDefault(CLName))
		CLName = "Selected_CL"
	EndIf

	Duplicate/O SepWave, $CLName
	Wave Selected_CL=$CLName
	
	If(StretchModulus!=0)
		Selected_CL= SepWave[p]/(1-0.5*sqrt(1.3806488e-23*Temperature/ForceRetWave[p]/PersistenceLength)+ForceRetWave[p]/StretchModulus)
	Else
		Selected_CL=WLC_CL(ForceRetWave[p],SepWave[p],PersistenceLength)
	EndIf
	If(!ParamIsDefault(Threshold))
		Variable Counter=0
		Variable FWaveLength=DimSize(ForceRetWave, 0)
		For(Counter=0;Counter<FWaveLength;Counter+=1)
			If(ForceRetWave[counter]<Threshold)
				Selected_CL[Counter]=0

			EndIf
		EndFor
	EndIf

End

Function MakeWLCInterpolationWaves(PersistenceLength)
	Variable PersistenceLength
	String Suffix="_"+num2str(Floor(PersistenceLength*1e12))+"pm"
	String WLCWaveName="WLCInterpolationWave"+Suffix
	Make/O/N=(999) $WLCWaveName
	Wave WLCInterpolationWave=$WLCWaveName
	WLCInterpolationWave=WLCForceVsExtension(p,PersistenceLength,298,1000)
	SetScale/P x, 0,0.001, WLCInterpolationWave
End


// Contour length as function of everything else using a worm like chain model
Function WLC_CL(Force,Extension,PersistenceLength)
	Variable	Force,Extension, PersistenceLength
	Variable PersistenceLength_pm=Floor(PersistenceLength*1e12)
	String Suffix="_"+num2str(PersistenceLength_pm)+"pm"
	String WLCWaveName="WLCInterpolationWave"+Suffix
	If(!WaveExists($WLCWaveName))
		MakeWLCInterpolationWaves(PersistenceLength)
	EndIf
	
	Wave WLCInterpolationWave=$WLCWaveName
	FindLevel/Q WLCInterpolationWave, Force
 	Variable ExtensiondivLc=V_LevelX
 	Return Extension/ExtensiondivLc
 	
End

Function WLCForceVsExtension(Ext,Lp,T,Lc)
	Variable Ext,Lp,T,Lc
	If(Ext<Lc)
		Return (1.3806488e-23*T/Lp)*(0.25*(1-Ext/Lc)^-2-0.25+Ext/Lc)
	Else
		Return NaN
	EndIf
End


Function MakeCLHistogram(CLWave,[NumPoints,BinWidth])
	Wave CLWave
	Variable NumPoints,BinWidth

	If(ParamIsDefault(NumPoints))
		NumPoints=2
	Endif
	
	If(ParamIsDefault(BinWidth))
		BinWidth=10e-9
	Endif

	WaveStats/Q CLWave
	Variable MaxCL=V_max
	Variable NumBins = Ceil(MaxCL/BinWidth)
	
	Duplicate/O CLWave, Selected_CLHistogram
	Histogram/B={0,BinWidth,NumBins} CLWave,Selected_CLHistogram
	Selected_CLHistogram[0]=0
	
	Duplicate/O Selected_CLHistogram, Selected_CLHistogram_smth
	Smooth/B NumPoints, Selected_CLHistogram_smth
	Selected_CLHistogram_smth[0]=0
End

Function FindCLPeaks(CLHistogram,Threshold)
	Wave CLHistogram
	Variable Threshold
	
	FindLevels/Q/P/Dest=CLPeaks CLHistogram, Threshold
	FindLevels/Q/Dest=CLPeaksX CLHistogram, Threshold

	Variable NumPeaks=Floor(DimSize(CLPeaks,0)/2)
	
	Make/O/N=(NumPeaks,4) Selected_CLPeakInfo
	SetDimLabel 1,0,$"CLPeak_PeakCL",Selected_CLPeakInfo
	SetDimLabel 1,1,$"CLPeak_Index",Selected_CLPeakInfo
	SetDimLabel 1,2,$"CLPeak_StartCL",Selected_CLPeakInfo
	SetDimLabel 1,3,$"CLPeak_EndCL",Selected_CLPeakInfo
	

	Variable PeakCounter=0
	For(PeakCounter=0;PeakCounter<NumPeaks;PeakCounter+=1)
		Variable StartIndex= Floor(CLPeaks[PeakCounter*2])
		Variable EndIndex=Floor(CLPeaks[PeakCounter*2+1])
		Variable StartDist=CLPeaksX[PeakCounter*2]
		Variable EndDist=CLPeaksX[PeakCounter*2+1]
		Selected_CLPeakInfo[PeakCounter][%$"CLPeak_StartCL"]=StartDist
		Selected_CLPeakInfo[PeakCounter][%$"CLPeak_EndCL"]=EndDist

		FindPeak/Q/R=[StartIndex,EndIndex] CLHistogram
		Variable CLPeak=V_PeakLoc
		IF(NumType(CLPeak)==2)
			CLPeak=(StartDist+EndDist)/2
		EndIf
		Selected_CLPeakInfo[PeakCounter][%$"CLPeak_PeakCL"]=CLPeak
		Variable HalfMax=CLPeak/2
				
		FindPeak/Q/P/R=[StartIndex,EndIndex] CLHistogram
		Selected_CLPeakInfo[PeakCounter][%$"CLPeak_Index"]=V_PeakLoc
		
	EndFor
End

Function CLAnalysis(Force_Ret,Sep_Ret,FRName,[RemoveOldWLCSegments,MakeSegments,TypeOfMolecule,HistogramThreshold,HistogramBinWidth,HistogramAverage,PeakThreshold])
	Wave Force_Ret,Sep_Ret
	Variable HistogramThreshold,HistogramBinWidth,HistogramAverage,PeakThreshold,MakeSegments,RemoveOldWLCSegments
	String FRName,TypeOfMolecule

	String CLvsTimeName=FRName+"_CL"
	If(ParamIsDefault(HistogramThreshold))
		ControlInfo/W=ForceRampUtilities CLNumToAverage_SV
		HistogramAverage=V_value
		ControlInfo/W=ForceRampUtilities CLBinWidth_SV
		HistogramBinWidth=V_value
		ControlInfo/W=ForceRampUtilities CLThreshold_SV
		HistogramThreshold=V_value
		ControlInfo/W=ForceRampUtilities CLPeakThreshold_SV
		PeakThreshold=V_value
		ControlInfo/W=ForceRampUtilities MoleculeType_SV
		TypeOfMolecule=S_value
	Endif
	
	MakeContourLengthWave(Force_Ret,Sep_Ret,Threshold=HistogramThreshold,MoleculeType=TypeOfMolecule,CLName=CLvsTimeName)
	Wave CLvsTime=$CLvsTimeName
	MakeCLHistogram(CLvsTime,BinWidth=HistogramBinWidth,NumPoints=HistogramAverage)
	Wave Selected_CLHistogram_smth
	FindCLPeaks(Selected_CLHistogram_smth,PeakThreshold)
	
	Wave Selected_CLPeakInfo=root:MyForceData:Selected_CLPeakInfo
	Variable NumPeaks=DimSize(Selected_CLPeakInfo,0)
	Variable PeakCounter=0
	For(PeakCounter=0;PeakCounter<NumPeaks;PeakCounter+=1)
		Variable CLPeak=Round(Selected_CLPeakInfo[PeakCounter][%CLPeak_PeakCL]*1e9)
		String PeakName= num2str(CLPeak)+" nm"
		SetDimLabel 0,PeakCounter,$PeakName,Selected_CLPeakInfo 
	EndFor

	String CLWaveName=	"root:MyForceData:CLSpace:"+FRName+"_CL"
	Duplicate/O Selected_CLPeakInfo $CLWaveName
	GetForceIndicesFromCLPeak(Force_Ret,Sep_Ret,CLvsTime,Selected_CLPeakInfo)
	
		
	If(ParamIsDefault(MakeSegments))
		MakeSegments=0
	EndIf
	If(ParamIsDefault(RemoveOldWLCSegments))
		RemoveOldWLCSegments=1
	EndIf

	If(MakeSegments)
		If(RemoveOldWLCSegments)
			RemoveWLCSegments(FRName)
		EndIf

		MakeCLSegments(Force_Ret,Sep_Ret,CLvsTime,FRName,TypeOfMolecule)
	EndIf

	
	If (!StringMatch(FRName,"Selected"))
		KillWaves CLvsTime
	EndIf

End

Function RemoveWLCSegments(FRName)
	String FRName
	String SegmentWaveName="root:MyForceData:Segments:"+FRName+"_Seg"
	Wave FRSegments=$SegmentWaveName

	Variable NumSegments=DimSize(FRSegments,0)
	Variable NumWLC=0,Counter=0,WaveIndex=-1
	For(Counter=0;Counter<NumSegments;Counter+=1)
		WaveIndex+=1
		If(FRSegments[WaveIndex][%WLC])
			DeletePoints WaveIndex, 1, FRSegments
			WaveIndex-=1
		EndIf
		
	EndFor
End

Function MakeCLSegments(Force_Ret,Sep_Ret,CLWave,NameOfFR,MoleculeType)//, [SegmentMerge])
		Wave Force_Ret,Sep_Ret,CLWave
		String NameOfFR,MoleculeType
		Variable SegmentMerge
		
		//If(ParamIsDefault(SegmentMerge))
	//		SegmentMerge=1
		//EndIf

		String CLWaveName=	"root:MyForceData:CLSpace:"+NameOfFR+"_CL"

		Wave CLPeakInfo=$CLWaveName
		GetForceIndicesFromCLPeak(Force_Ret,Sep_Ret,CLWave,CLPeakInfo)

		Wave SegmentInfo=root:MyForceData:SegmentInfo
		Variable NumCLSegments=DimSize(SegmentInfo,0)
		String NewCLSegmentName=MoleculeType
		Variable CLSegmentCounter=0
		
		//If(SegmentMerge)
		//	Variable OldSegmentMin=WaveMin(SegmentInfo)
		//	Variable OldSegmentMax=WaveMax(SegmentInfo)
		//	Duplicate/O/R=[OldSegmentMin,OldSegmentMax] Force_Ret, TestForceSegment
		//	WaveStats/Q TestForceSegment
		//	Variable SegmentMin=V_minRowLoc+OldSegmentMin
		//	Variable SegmentMax=V_maxRowLoc+OldSegmentMin
		//	MakeNewSegment(SegmentMin,SegmentMax,SegmentName=NewCLSegmentName,WLC=1,FRName=NameOfFR)

		//EndIf
		
		//If(!SegmentMerge)
			For(CLSegmentCounter=0;CLSegmentCounter<NumCLSegments;CLSegmentCounter+=1)
				MakeNewSegment(SegmentInfo[CLSegmentCounter][0],SegmentInfo[CLSegmentCounter][1],SegmentName=NewCLSegmentName,WLC=1,FRName=NameOfFR,ForceData=Force_Ret,SepData=Sep_Ret,CLData=CLWave)
			EndFor
		//EndIF

End

Function GetForceIndicesFromCLPeak(ForceWave,SepWave,CLWave,CLPeakInfo,[SegmentMerge])
	Wave ForceWave,SepWave,CLWave,CLPeakInfo
	Variable SegmentMerge		
	
	If(ParamIsDefault(SegmentMerge))
		SegmentMerge=1
	EndIf

	
	Variable NumPeaks=DimSize(CLPeakInfo, 0)
	Variable PeakCounter=0
	Make/N=(0,2)/O SegmentInfo

	For(PeakCounter=0;PeakCounter<NumPeaks;PeakCounter+=1)
		String ForceSectionName=NameOfWave(ForceWave)+"_"+num2str(PeakCounter)
		String SepSectionName=NameOfWave(SepWave)+"_"+num2str(PeakCounter)
		
		Duplicate/O CLWave, PointSelector
		Variable StartCL=CLPeakInfo[PeakCounter][%$"CLPeak_StartCL"]
		Variable EndCL=CLPeakInfo[PeakCounter][%$"CLPeak_EndCL"]
		
		Variable CLWaveSize=DimSize(CLWave,0)
		PointSelector=CLThreshold(CLWave[p],StartCL,EndCL)
		FindLevels/Q/P/D=CrossingPoints PointSelector, 0.5
		If(V_Levelsfound)
			Variable NumSegments=DimSize(CrossingPoints,0)/2
			Make/O/N=(NumSegments,2)/O CurrentPeakSegmentInfo
		EndIf
		
		Variable SegmentStartIndex=DimSize(SegmentInfo,0)           
		
		If(SegmentMerge)                                                                                                                                           
			InsertPoints SegmentStartIndex, 1,SegmentInfo
			
			Variable OldSegmentMin=WaveMin(CrossingPoints)
			Variable OldSegmentMax=WaveMax(CrossingPoints)
			Duplicate/O/R=[OldSegmentMin,OldSegmentMax] ForceWave, TestForceSegment
			WaveStats/Q TestForceSegment
			Variable SegmentMin=Round(V_minRowLoc+OldSegmentMin)
			Variable SegmentMax=Round(V_maxRowLoc+OldSegmentMin)
			SegmentInfo[SegmentStartIndex][0]=SegmentMin
			SegmentInfo[SegmentStartIndex][1]=SegmentMax
		EndIf

		If(!SegmentMerge)                                                                                                                                           
			InsertPoints SegmentStartIndex, NumSegments,SegmentInfo
			Variable Counter=0
			For(Counter=0;Counter<NumSegments;Counter+=1)
				SegmentInfo[SegmentStartIndex+Counter][0]=Ceil(CrossingPoints[2*Counter])
				SegmentInfo[SegmentStartIndex+Counter][1]=Floor(CrossingPoints[2*Counter+1])
			EndFor
		EndIf
		

	EndFor
	
End

Function CLThreshold(CL,ClStart,CLEnd)
	Variable CL,ClStart,CLEnd
	
	If(CL>CLStart&&CL<CLEnd)
		Return 1
	EndIf
	
	Return 0
End

Function CLPeakToSegment(FRName,[MoleculeType])
	String FRName,MoleculeType
	
	String CLWaveName=	"root:MyForceData:CLSpace:"+FRName+"_CL"
	Wave CLPeakInfo=$CLWaveName
	
	

End

Function SegmentToWLCSegment(FRName,[MoleculeType])
	String FRName,MoleculeType

End


// SaveForceAndSep
// This function takes a force and separation wave and creates copies in the SavedFRData folder
// Using the optional parameters, you can specify a different folder and different base name.
// This should be useful for creating copies of force and separation waves when needed.
Function SaveForceAndSep(Force_Ret,Sep_Ret,[TargetFolder,NewName,Suffix])
	Wave Force_Ret,Sep_Ret
	String TargetFolder,NewName,Suffix

	If(ParamIsDefault(TargetFolder))
		TargetFolder = "root:MyForceData:SavedFRData:"
	EndIf
	
	If(ParamIsDefault(NewName))
		String FullWaveName=NameOfWave(Force_Ret)
		Variable SizeOfName = strlen(FullWaveName)-10
		NewName = FullWaveName[0,SizeOfName]
	EndIf	
	If(ParamIsDefault(Suffix))
		Suffix = "_Ret"
	EndIf

	String ForceWaveName=TargetFolder+NewName+"Force"+ Suffix
	String SepWaveName=TargetFolder+NewName+"Sep"+ Suffix

	Duplicate/O Force_Ret, $ForceWaveName
	Duplicate/O Sep_Ret, $SepWaveName
	
	Return 0

End  // SaveForceAndSep

Function DisplayCombinedFRList(FRListName,[UpdateGraph,LineUpDistance])
	String FRListName
	Variable UpdateGraph,LineUpDistance
	
	Wave/T SavedFRLists=root:MyForceData:SavedFRLists
	String FRList=SavedFRLists[%$FRListName]	
	Variable NumFR=ItemsInList(FRList)
	String DataFolderName="root:MyForceData:"+FRListName+"_SD"
	NewDataFolder/O $DataFolderName
	DataFolderName+=":"
	ApplyFuncsToForceWaves("LoadCorrectedFR(Force_Ret,Sep_Ret,FRName);SaveForceAndSep(Force_Ret,Sep_Ret,TargetFolder=\""+DataFolderName+"\")",FPList=FRList,NumOutputs="0;0")

	If(ParamIsDefault(UpdateGraph))
		SetDataFolder $DataFolderName
		
		String ForceWaveName=StringFromList(0, FRList)+"Force_Ret"
		String SepWaveName=StringFromList(0, FRList)+"Sep_Ret"
		Wave ForceWave=$ForceWaveName
		Wave SepWave=$SepWaveName
		Display ForceWave vs SepWave
		GetMeasurement("MeanSep",FRList=StringFromList(0, FRList),OutputWaveName="CLPeaks0")
		Wave CLPeaks0=CLPeaks0
		If(ParamIsDefault(LineUpDistance))
			LineUpDistance=CLPeaks0[3]
		Else
			
		EndIf
		Variable SepOffset=LineUpDistance-CLPeaks0[3]
		FastOp SepWave=SepWave+(SepOffset)


		Variable Counter=0
		For(Counter=1;Counter<NumFR;Counter+=1)
			
			GetMeasurement("MeanSep",FRList=StringFromList(Counter, FRList),OutputWaveName="CLPeaksTemp")
			Wave CLPeaksTemp=CLPeaksTemp
			SepOffset=LineUpDistance-CLPeaksTemp[3]
			ForceWaveName=StringFromList(Counter, FRList)+"Force_Ret"
			SepWaveName=StringFromList(Counter, FRList)+"Sep_Ret"
			
			Wave ForceWave=$ForceWaveName
			Wave SepWave=$SepWaveName
			FastOp SepWave=SepWave + (SepOffset)
			AppendToGraph ForceWave vs SepWave
		EndFor
		ModifyGraph mode=2

	EndIf
End

// Moves the index for the Master Force Panel by inputing the names of the target force ramp
Function GoToForceReviewWave(TargetForceWaveName)
	String TargetForceWaveName

	String FPMasterList, DataFolderMasterList
	GetForcePlotsList(2,FPMasterList,DataFolderMasterList)

	Variable TargetIndex = WhichListItem(TargetForceWaveName, FPMasterList, ";")
	Variable IndexJump = TargetIndex - GV("ForceDisplayIndex") 
	ShiftForceList(IndexJump)
End

// This function figures out all the different prefixes from the master force list.  Might upgrade this to handle a force sublist, if necessary
Function/S UniqueForceLists()
	
	String FPMasterList, DataFolderMasterList
	GetForcePlotsList(2,FPMasterList,DataFolderMasterList)

	Variable NumberOfForceRamps = ItemsInList(FPMasterList)
	Variable Counter=0
	String UniqueNamesList=""
	
	For(Counter=0;Counter<NumberOfForceRamps;Counter+=1)
		String RawName = StringFromList(Counter,FPMasterList)
		Variable SizeOfName = strlen(RawName)-5
		
		String FormattedName = RawName[0,SizeOfName]
		Variable ItemLocation=WhichListItem(FormattedName, UniqueNamesList)
		If(ItemLocation<0)
			UniqueNamesList+=FormattedName+";"
		EndIf
	EndFor
	
	Return UniqueNamesList
	
End // UniqueForceLists

// This will get all the names of the force ramps associated with a specific name prefix
// For example, if I have force ramps names Image0001, Image0002,...Image0053
// I would input ForceListByPrefix(Image) to find all of them.
// The optional parameter FRList can force it to search a specific sublist, instead of all force ramps
Function/S ForceListByPrefix(NamePrefix,[FRList])
	String NamePrefix,FRList
	
	If(ParamIsDefault(FRList))
		String FPMasterList, DataFolderMasterList
		GetForcePlotsList(2,FPMasterList,DataFolderMasterList)
		FRList = FPMasterList
	EndIf

	Variable NumberOfForceRamps = ItemsInList(FPMasterList)
	Variable Counter=0
	String OutputNamesList=""
	
	For(Counter=0;Counter<NumberOfForceRamps;Counter+=1)
		String RawName = StringFromList(Counter,FPMasterList)
		If(ForceNamePrefixMatch(NamePrefix,RawName)>0)
			OutputNamesList+=RawName+";"
		EndIf
	EndFor
	
	Return OutputNamesList

End // ForceListByPrefix

// This just tells you if a name prefix matches a wave name.  Returns 0 for no, 1 for yes
// ForceNamePrefixMatch(Image,Image0001) would return yes
// ForceNamePrefixMatch(Image,DNAPull0053) would return no
Function ForceNamePrefixMatch(NamePrefix,ForceWaveName)
	String NamePrefix,ForceWaveName
	Variable SizeOfName = strlen(ForceWaveName)-5

	String FormattedForceWaveName = ForceWaveName[0,SizeOfName]
	Return StringMatch(NamePrefix,FormattedForceWaveName)
End

// This calculates the survival distribution of the inputdata.  I should add more options for outputing to a specific name and path
Function SurvivalDistribution(InputData)
	Wave InputData
	Duplicate/O InputData, SortedInputData,SurvivalProb
	Sort SortedInputData,SortedInputData
	Variable NumPoints=DimSize(SortedInputData,0)
	SurvivalProb=1-p/NumPoints
	InsertPoints 0, 1, SortedInputData,SurvivalProb
	SortedInputData[0]=0
	SurvivalProb[0]=1
	
End // SurvivalDistribution

// Here's the user interface functions
Function/S CurrentSelectedFRName()
	Wave/T CurrentFRList
	ControlInfo/W=ForceRampUtilities CurrentFRList_ListBox
	String SelectedWaveName = CurrentFRList[V_value]
	Return SelectedWaveName
End
// A function to do all updates associated with the Rupture/Offset tab
Function UpdateRuptureOffsets(UpdateType)
	String UpdateType
	
	// Load all the important info for this wave
	Wave SelectedForce_Ret=root:MyForceData:SelectedForce_Ret
	Wave SelectedSep_Ret=root:MyForceData:SelectedSep_Ret
	Wave SelectedRuptureForce=root:MyForceData:SelectedRuptureForce
	Wave UnfilteredForce_Ret=root:MyForceData:UnfilteredForce_Ret
	Wave UnfilteredSep_Ret=root:MyForceData:UnfilteredSep_Ret
	Wave SelectedOffsets=root:MyForceData:SelectedOffsets
	String FRName=CurrentSelectedFRName()
	
	// Load relevant "global" waves
	Wave Offsets = root:MyForceData:Offsets
	Wave RuptureForce = root:MyForceData:RuptureForce
	
	// This will determine if we update the "global" waves
	Variable UpdateGlobalWaves=0
	
	strswitch(UpdateType)	
		case "None":
		break
		case "RuptureIndex":
		case "RuptureFromCursorA":
			// Find wave index associated with cursor A
			Variable NewRuptureIndex=0
			strswitch(UpdateType)	
				case "RuptureIndex":
					NewRuptureIndex=SelectedRuptureForce[%$"Rupture_Index"]
					Cursor/P A UnfilteredForce_Ret NewRuptureIndex
				break
				case "RuptureFromCursorA":
					NewRuptureIndex=pcsr(A)
				break
			endswitch
			// Update Rupture Force waves
			SelectedRuptureForce[%$"Rupture_Force"]=UnfilteredForce_Ret[NewRuptureIndex]
			SelectedRuptureForce[%$"Rupture_Index"]=NewRuptureIndex
			SelectedRuptureForce[%$"Rupture_Sep"]=UnfilteredSep_Ret[NewRuptureIndex]
			// Update the global waves
			UpdateGlobalWaves=1
		break
		case "SepOffsetFromCursorB":
			// Get new separation offset from cursor b
			Variable ChangeInSepOffset=UnfilteredSep_Ret[pcsr(B)]
			// Update selected separation offsets
			SelectedOffsets[%$"Offset_Sep"]+= ChangeInSepOffset
			SelectedSep_Ret-=ChangeInSepOffset
			UnfilteredSep_Ret-=ChangeInSepOffset
			SelectedRuptureForce[%$"Rupture_Sep"]=UnfilteredSep_Ret[SelectedRuptureForce[%$"Rupture_Index"]]

			// Update the global waves
			UpdateGlobalWaves=1
		break
		case "ForceOffsetFromMarquee":
			// Load Marquee info
			GetMarquee/K left,bottom
			// Find the start and end index associated with the separation wave
			FindLevel/Q/P SelectedSep_Ret, V_left
			Variable StartIndex=Floor(V_LevelX)
			FindLevel/Q/P SelectedSep_Ret, V_right
			Variable EndIndex=Floor(V_LevelX)
			// Find average of the force wave segment and use this as the new offset
			Duplicate/O/R=[StartIndex,EndIndex] SelectedForce_Ret,ForceOffsetWave
			WaveStats/Q ForceOffsetWave
			Variable ChangeInForceOffset=	V_avg
			// Update selected forces
			SelectedOffsets[%$"Offset_Force"]-= ChangeInForceOffset
			SelectedForce_Ret-=ChangeInForceOffset
			UnfilteredForce_Ret-=ChangeInForceOffset
			SelectedRuptureForce[%$"Rupture_Force"]-=ChangeInForceOffset
			// Update the global waves
			UpdateGlobalWaves=1		
		break
		
	endswitch
	
	If(UpdateGlobalWaves)
		// Update Rupture Force Wave
		RuptureForce[%$FRName][%$"Rupture_Force"]=SelectedRuptureForce[%$"Rupture_Force"]
		RuptureForce[%$FRName][%$"Rupture_Index"]=SelectedRuptureForce[%$"Rupture_Index"]
		RuptureForce[%$FRName][%$"Rupture_Sep"]=SelectedRuptureForce[%$"Rupture_Sep"]
		// Update offsets wave
		Offsets[%$FRName][%$"Offset_Force"]=SelectedOffsets[%$"Offset_Force"]
		Offsets[%$FRName][%$"Offset_Sep"]=SelectedOffsets[%$"Offset_Sep"]
	EndIf

End

// A function to remove artifacts from interference or drift
Function UpdateDetrend(UpdateType)
	String UpdateType
	Wave RawForceData=root:MyForceData:RawForce_Ext
	Wave RawSepData=root:MyForceData:RawSep_Ext
	ControlInfo/W=ForceRampUtilities Detrend_Popup
	String FRName=CurrentSelectedFRName()
	String DetrendFunctionType=S_value
	Wave SelectedForce_Ret=root:MyForceData:SelectedForce_Ret
	Wave UnfilteredForce_Ret=root:MyForceData:UnfilteredForce_Ret
	Wave SelectedSep_Ret=root:MyForceData:SelectedSep_Ret
	Wave SelectedForce_Ret_Backup=root:MyForceData:SelectedForce_Ret_Backup
	String DetrendFunction=""
	Wave/T CurrentDetrendFunction=root:MyForceData:CurrentDetrendFunction
	Wave/T DetrendFunctions=root:MyForceData:DetrendFunctions
	Wave Offsets=root:MyForceData:Offsets
	Variable ApplyFunction=0
	
	strswitch(UpdateType)
		case "DetrendFormula_SV":
			// Clear Any previous detrends out
			DetrendFunction=CurrentDetrendFunction[0][%DetrendFunction]
			ApplyFunction=1
			//Offsets[%$FRName][%Offset_Force]=
		break
		case "Detrend_Popup":
		break
		case "InitializeDetrend_Button":
			
			K0=Mean(RawForceData)
			K1=10e-12
			K2=2*Pi/330e-9
			K3=0
			Duplicate/O RawForceData, DetrendFitGuide
			DetrendFitGuide=K0+K1*Sin(K2*RawSepData(x)+K3)
		break
		case"FindDetrendFormula_Button":
			DetrendFunction=FindDetrendFunction(RawForceData,RawSepData,DetrendFunctionType)
			ApplyFunction=1
			If(StringMatch(DetrendFunction,"None"))
				ApplyFunction=0
			EndIf

		break
	EndSwitch
	
	If(ApplyFunction)
		// Clear any previous detrending
		DetrendFunctions[%$FRName][%DetrendFunction]=DetrendFunction
		CurrentDetrendFunction[0][%DetrendFunction]=DetrendFunction
		ApplyFuncsToForceWaves("SaveForceAndSep(ForceWave,SepWave,TargetFolder=\"root:MyForceData:\",NewName=\"DetrendTest\")",FPList=FRName)
		Wave DetrendTestForce_Ret=root:MyForceData:DetrendTestForce_Ret
		Wave DetrendTestSep_Ret=root:MyForceData:DetrendTestSep_Ret
		Wave CurrentFilterAndDecimation=root:MyForceData:CurrentFilterAndDecimation
		DetrendTestForce_Ret*=-1
		
		ApplyDetrendFunction(DetrendTestForce_Ret,DetrendTestSep_Ret,DetrendFunction)

		Variable NewOffset=CalcForceOffset(DetrendTestForce_Ret,50)
		Wave SelectedOffsets=root:MyForceData:SelectedOffsets
		SelectedOffsets[%$"Offset_Force"]=-NewOffset
		Offsets[%$FRName][%Offset_Force]=SelectedOffsets[%$"Offset_Force"]
		DetrendTestForce_Ret-=NewOffset
		DetrendTestSep_Ret-=Offsets[%$FRName][%Offset_Sep]
		
		Duplicate/O DetrendTestForce_Ret, UnfilteredForce_Ret
		Duplicate/O DetrendTestSep_Ret, UnfilteredSep_Ret
		BoxCarAndDecimateFR(DetrendTestForce_Ret,DetrendTestSep_Ret,CurrentFilterAndDecimation[0][%NumToAverage],CurrentFilterAndDecimation[0][%Decimation])
		Duplicate/O DetrendTestForce_Ret, SelectedForce_Ret
		Duplicate/O DetrendTestSep_Ret, SelectedSep_Ret
		Wave RuptureForce=root:MyForceData:RuptureForce
		Variable TargetIndex=RuptureForce[%$FRName][%Rupture_Index]
		RuptureForce[%$FRName][%Rupture_Force]=UnfilteredForce_Ret[TargetIndex]
		RuptureForce[%$FRName][%Rupture_Sep]=UnfilteredSep_Ret[TargetIndex]
		
		Wave SelectedRuptureForce=root:MyForceData:SelectedRuptureForce
		SelectedRuptureForce[%$"Rupture_Force"]=RuptureForce[%$FRName][%$"Rupture_Force"]
		SelectedRuptureForce[%$"Rupture_Sep"]=RuptureForce[%$FRName][%$"Rupture_Sep"]

	EndIf
	
End

// A function to do all updates associated with the Filters/Decimation Tab
Function UpdateFiltersDecimation(UpdateType)
	String UpdateType

	// Load unfiltered force and separation waves
	Wave UnfilteredForce_Ret=root:MyForceData:UnfilteredForce_Ret
	Wave UnfilteredSep_Ret=root:MyForceData:UnfilteredSep_Ret
	String FRName=CurrentSelectedFRName()
	Wave CurrentFilterAndDecimation=root:MyForceData:CurrentFilterAndDecimation
	Wave FilterAndDecimation=root:MyForceData:FilterAndDecimation

	// This will determine if we update the "global" waves
	Variable UpdateGlobalWaves=0
	strswitch(UpdateType)	
		case "ApplyFilterButton":
			// Overwrite Selected Force and Sep waves
			Duplicate/O UnfilteredForce_Ret,SelectedForce_Ret
			Duplicate/O UnfilteredSep_Ret,SelectedSep_Ret
			// Load filter setterings
			// Apply box car average and decimation 
			FilterAndDecimation[%$FRName][%NumToAverage]=CurrentFilterAndDecimation[0][%NumToAverage]
			FilterAndDecimation[%$FRName][%Decimation]=CurrentFilterAndDecimation[0][%Decimation]
			ControlInfo/W=ForceRampUtilities FilterType
			String FilterType=S_Value
			BoxCarAndDecimateFR(SelectedForce_Ret,SelectedSep_Ret,CurrentFilterAndDecimation[0][%NumToAverage],CurrentFilterAndDecimation[0][%Decimation],SmoothMode=FilterType)

			Variable RawFrequency=1/Deltax(UnfilteredForce_Ret)
			Variable FilteredFrequency=RawFrequency/CurrentFilterAndDecimation[0][%NumToAverage]
			SetVariable FilteredFrequency_SV,win = ForceRampUtilities,value= _NUM:FilteredFrequency

		break
		case "BoxCarAverage":
		case "DecimationSetVal":
		break
	endswitch

	If(UpdateGlobalWaves)
	EndIf

End  //UpdateFiltersDecimation

Function UpdateCLSpace(UpdateType)
	String UpdateType

	// Load unfiltered force and separation waves
	Wave UnfilteredForce_Ret=root:MyForceData:UnfilteredForce_Ret
	Wave UnfilteredSep_Ret=root:MyForceData:UnfilteredSep_Ret
	Wave SelectedForce_Ret=root:MyForceData:SelectedForce_Ret
	Wave SelectedSep_Ret=root:MyForceData:SelectedSep_Ret
	String FRName=CurrentSelectedFRName()
	
	ControlInfo/W=ForceRampUtilities CLNumToAverage_SV
	Variable HistogramAverage=V_value
	ControlInfo/W=ForceRampUtilities CLBinWidth_SV
	Variable HistogramBinWidth=V_value
	ControlInfo/W=ForceRampUtilities CLThreshold_SV
	Variable HistogramThreshold=V_value
	ControlInfo/W=ForceRampUtilities CLPeakThreshold_SV
	Variable PeakThreshold=V_value
	ControlInfo/W=ForceRampUtilities MoleculeType_SV
	String TypeOfMolecule=S_value
	
	Wave Selected_CL=root:MyForceData:Selected_CL
	Wave Selected_CLHistogram=root:MyForceData:Selected_CLHistogram
	Wave Selected_CLHistogram_smth=root:MyForceData:Selected_CLHistogram_smth
	Wave Selected_CLPeakInfo=root:MyForceData:Selected_CLPeakInfo
	
	// This will determine if we update the "global" waves
	Variable UpdateGlobalWaves=0
	// Should we update the CL displays
	Variable UpdateCLDisplays=0
	strswitch(UpdateType)	
		case "CLAnalysisButton":
			MakeContourLengthWave(SelectedForce_Ret,SelectedSep_Ret,Threshold=HistogramThreshold,MoleculeType=TypeOfMolecule)
			MakeCLHistogram(Selected_CL,BinWidth=HistogramBinWidth,NumPoints=HistogramAverage)
			UpdateCLDisplays=1
			WaveStats/Q SelectedSep_Ret
			Make/O/N=2 ThresholdGuide_Sep,ThresholdGuide_Count
			ThresholdGuide_Sep[0]=V_min
			ThresholdGuide_Sep[0]=V_max
			ThresholdGuide_Count=PeakThreshold
		break
		case "CLPeakThreshold_SV":
			ThresholdGuide_Count=PeakThreshold
		break		
		case "CLPeaksButton":
			FindCLPeaks(Selected_CLHistogram_smth,PeakThreshold)
			
			Variable NumPeaks=DimSize(Selected_CLPeakInfo,0) 
			
			Make/O/T/N=(NumPeaks) CLPeakList
			Make/O/N=(NumPeaks) CLPeakListSel
			
			Variable PeakCounter=0
			For(PeakCounter=0;PeakCounter<NumPeaks;PeakCounter+=1)
				Variable CLPeak=Round(Selected_CLPeakInfo[PeakCounter][%CLPeak_PeakCL]*1e9)
				String PeakName= num2str(CLPeak)+" nm"
				CLPeakList[PeakCounter]=PeakName
				SetDimLabel 0,PeakCounter,$PeakName,Selected_CLPeakInfo 
			EndFor
			UpdateGlobalWaves=1
		break
		case "CLPeaksListBox":
			ControlInfo/W=ForceRampUtilities CLPeaksListBox
			Duplicate/O/R=[V_Value] Selected_CLPeakInfo,Selected_CurrentCLPeak
			GetForceIndicesFromCLPeak(SelectedForce_Ret,SelectedSep_Ret,Selected_CL,Selected_CLPeakInfo)

		break
		case "ForceVsCLCheckBox":
		case "CLvsTimeCheckBox":
		case "CLHistogramCheckBox":
			UpdateCLDisplays=1
		break

	endswitch
	
	If(UpdateCLDisplays)
		ControlInfo ForceVsCLCheckBox
		Variable ShowForceVsCL=V_Value
		ControlInfo CLvsTimeCheckBox
		Variable ShowCLvsTime=V_Value
		ControlInfo CLHistogramCheckBox
		Variable ShowCLHistogram=V_Value
		
		DoWindow ForceVsCLGraph
		// If we have the graph up but it is not supposed to be up, then kill it
		If(V_Flag==1&&ShowForceVsCL==0)
			KillWindow ForceVsCLGraph
		EndIf
		// If we don't have the graph up, display it with default settings.
		If(V_Flag!=1&&ShowForceVsCL==1)
			Display/N=ForceVsCLGraph SelectedForce_Ret vs Selected_CL
			DoWindow/T ForceVsCLGraph,"Selected Force vs Contour Length"
			Label left "Force"
			Label bottom "Contour Length"
		EndIf
		

		DoWindow CLvsTimeGraph
		// If we have the graph up but it is not supposed to be up, then kill it
		If(V_Flag==1&&ShowCLvsTime==0)
			KillWindow CLvsTimeGraph
		EndIf

		// If we don't have the graph up, display it will default settings.
		If(V_Flag!=1&&ShowCLvsTime==1)
			Display/N=CLvsTimeGraph Selected_CL
			DoWindow/T CLvsTimeGraph,"Contour Length"
			Label left "Contour Length"
			Label bottom "Time"
		EndIf

		DoWindow CLHistogramGraph
		// If we have the graph up but it is not supposed to be up, then kill it
		If(V_Flag==1&&ShowCLHistogram==0)
			KillWindow CLHistogramGraph
		EndIf

		// If we don't have the graph up, display it will default settings.
		If(V_Flag!=1&&ShowCLHistogram==1)
			Display/N=CLHistogramGraph Selected_CLHistogram
			ModifyGraph rgb=(48896,59904,65280)
			AppendToGraph/C=(0,0,65280) Selected_CLHistogram_smth
			AppendToGraph/C=(0,0,0) ThresholdGuide_Count vs ThresholdGuide_Sep
			DoWindow/T CLHistogramGraph,"Contour Length Histogram"
			Label left "Count"
			Label bottom "Contour Length"
		EndIf

	EndIF

	If(UpdateGlobalWaves)
		String CLWaveName=	"root:MyForceData:CLSpace:"+FRName+"_CL"
		Duplicate/O Selected_CLPeakInfo $CLWaveName
	EndIf

End  //UpdateFiltersDecimation

Function UpdateWLCGuide(UpdateType)
	String UpdateType
	
	ControlInfo WLCGuideList
	Variable CurrentIndex_WLCGuide=V_value

	Wave WLCGuides=root:MyForceData:WLCGuides
	Wave/T WLCGuideList=root:MyForceData:WLCGuideList
	Wave WLCGuideListSel=root:MyForceData:WLCGuideListSel
	Wave WLCChoicesProperties=root:MyForceData:WLCChoicesProperties
	Wave/T WLCGuideChoicesList=root:MyForceData:WLCGuideChoicesList
	Variable NumWLCGuides=DimSize(WLCGuideList,0)
	Variable NoWLCinGuide=StringMatch(WLCGuideList[0],"None")
	ControlInfo ConstructsForWLCGuideListBox
	Variable SelectedWLCConstruct=V_value
	String SelectedConstruct=WLCGuideChoicesList[SelectedWLCConstruct]
	Wave WLCGuideCurrentSelection=root:MyForceData:WLCGuideCurrentSelection
	String FRName=CurrentSelectedFRName()

	// This will determine if we update the "global" waves
	Variable UpdateGlobalWaves=0
	// Determine which index to delete or add to.
	Variable TargetIndex=0
	
	// Should we update the CL displays
	strswitch(UpdateType)	
		case "AddToListWLCGuide":
			// If nothing is in the guide list, add something to the first element
			If(NoWLCinGuide)
				WLCGuideList[0]=SelectedConstruct
				SetDimLabel 0,0,$SelectedConstruct,WLCGuides	
				WLCGuides[0][%PersistenceLength]=WLCChoicesProperties[%$SelectedConstruct][%PersistenceLength]
				WLCGuides[0][%ContourLength]=WLCChoicesProperties[%$SelectedConstruct][%ContourLength]
			EndIf
			// We are going to add this after the currently selected molecule
			TargetIndex=CurrentIndex_WLCGuide+1
			// Add this new construct to the correct location
			If(NumWLCGuides>=1&&!NoWLCinGuide)
				InsertPoints TargetIndex,1,WLCGuideList,WLCGuideListSel,WLCGuides
				WLCGuideList[TargetIndex]=WLCGuideChoicesList[SelectedWLCConstruct]
				WLCGuideListSel[TargetIndex]=0
				ListBox WLCGuideList selrow=(TargetIndex)
				
				SetDimLabel 0,TargetIndex,$SelectedConstruct,WLCGuides	
				WLCGuides[TargetIndex][%PersistenceLength]=WLCChoicesProperties[%$SelectedConstruct][%PersistenceLength]
				WLCGuides[TargetIndex][%ContourLength]=WLCChoicesProperties[%$SelectedConstruct][%ContourLength]
			EndIf
			UpdateGlobalWaves=1
		break
		
		case "DeleteFromListWLCGuide":
			If(NoWLCinGuide)
				Break
			EndIf
			TargetIndex=CurrentIndex_WLCGuide
			If(NumWLCGuides==1&&!NoWLCInGuide)
				WLCGuideList[0]="None"
				SetDimLabel 0,0,None,WLCGuides

 				WLCGuides[%None][%PersistenceLength]=50e-9
 				WLCGuides[%None][%ContourLength]=50e-9

			EndIf
			If(NumWLCGuides>1&&!NoWLCInGuide)
				DeletePoints TargetIndex,1,WLCGuideList,WLCGuideListSel,WLCGuides
			EndIf
			UpdateGlobalWaves=1
		break
		case "WLCGuideList":
			WLCGuideCurrentSelection[%PersistenceLength]=WLCGuides[CurrentIndex_WLCGuide][%PersistenceLength]
			WLCGuideCurrentSelection[%ContourLength]=WLCGuides[CurrentIndex_WLCGuide][%ContourLength]
		break

	endswitch
	
	If(UpdateGlobalWaves)
		String WLCGuideWaveName=	"root:MyForceData:WLCGuides:"+FRName+"_WLCG"
		Duplicate/O WLCGuides $WLCGuideWaveName
	EndIf

	
End // UpdateWLCGuide

Function SegmentStats(SegmentIndex,[ForceData,SepData,CLData,FRSegments])
	Variable SegmentIndex
	Wave ForceData,SepData,CLData,FRSegments
	
	If(ParamIsDefault(FRSegments))
		Wave CurrentFRSegments=root:MyForceData:CurrentFRSegments
		Duplicate/O CurrentFRSegments,FRSegments
	EndIf
	
	If(ParamIsDefault(ForceData))
		Wave SelectedForce_Ret=root:MyForceData:SelectedForce_Ret
		Duplicate/O SelectedForce_Ret,ForceData
	EndIf
	If(ParamIsDefault(SepData))
		Wave SelectedSep_Ret=root:MyForceData:SelectedSep_Ret
		Duplicate/O SelectedSep_Ret,SepData
	EndIf
	If(ParamIsDefault(CLData))
		Wave Selected_CL=root:MyForceData:Selected_CL
		Duplicate/O Selected_CL,CLData
	EndIf
				
	Variable StartIndex = FRSegments[SegmentIndex][%StartIndex]
	Variable EndIndex = FRSegments[SegmentIndex][%EndIndex]
	// Create Segments for stats and display
	Duplicate/O/R=[StartIndex,EndIndex] ForceData,NewSegment_Force
	Duplicate/O/R=[StartIndex,EndIndex] SepData,NewSegment_Sep
	Duplicate/O/R=[StartIndex,EndIndex] CLData,NewSegment_CL
	WaveStats/Q NewSegment_Force
	FRSegments[SegmentIndex][%MinForce]=V_min
	FRSegments[SegmentIndex][%MaxForce]=V_max
	FRSegments[SegmentIndex][%MeanForce]=V_avg
	FRSegments[SegmentIndex][%StdDevForce]=V_sdev
	WaveStats/Q NewSegment_Sep
	FRSegments[SegmentIndex][%MinSep]=V_min
	FRSegments[SegmentIndex][%MaxSep]=V_max
	FRSegments[SegmentIndex][%MeanSep]=V_avg
	
	WaveStats/Q NewSegment_CL		
	FRSegments[SegmentIndex][%MinCL]=V_min
	FRSegments[SegmentIndex][%MaxCL]=V_max
	FRSegments[SegmentIndex][%MeanCL]=V_avg
	FRSegments[SegmentIndex][%StdDevCL]=V_sdev
	
	If(ParamIsDefault(FRSegments))
		Duplicate/O FRSegments,CurrentFRSegments
	EndIf

End


Function MakeNewSegment(StartIndex,EndIndex,[CalcSegmentStats,SegmentName,FRName,WLC,Flickering,ForceData,SepData,CLData])
	Variable StartIndex,EndIndex,CalcSegmentStats,WLC,Flickering
	String SegmentName,FRName
	Wave ForceData,SepData,CLData
	
	Wave/T SegmentsList=root:MyForceData:SegmentsList
	Wave SegmentsListSel=root:MyForceData:SegmentsListSel
	Wave SelectedSegment=root:MyForceData:SelectedSegment
	Wave CurrentFRSegments=root:MyForceData:CurrentFRSegments
	ControlInfo SegmentListBox
	Variable CurrentIndex_SegmentsListBox=V_value
	
	Wave UnfilteredForce_Ret=root:MyForceData:UnfilteredForce_Ret
	Wave UnfilteredSep_Ret=root:MyForceData:UnfilteredSep_Ret
	Wave SelectedForce_Ret=root:MyForceData:SelectedForce_Ret
	Wave SelectedSep_Ret=root:MyForceData:SelectedSep_Ret
	Wave Selected_CL=root:MyForceData:Selected_CL
	
	If(ParamIsDefault(FRName))
		FRName=CurrentSelectedFRName()
	EndIf

	String FRSegmentName="root:MyForceData:Segments:"+FRName+"_Seg"
	Wave FRSegments=$FRSegmentName
	
	Variable NumSegments=DimSize(FRSegments,0)

	If(ParamIsDefault(ForceData))
		Duplicate/O SelectedForce_Ret,ForceData
	EndIf
	If(ParamIsDefault(SepData))
		Duplicate/O SelectedSep_Ret,SepData
	EndIf
	If(ParamIsDefault(CLData))
		Duplicate/O Selected_CL,CLData
	EndIf
	If(ParamIsDefault(WLC))
		 WLC=0
	Endif
	If(ParamIsDefault(Flickering))
		 Flickering=0
	Endif	
	If(ParamIsDefault(SegmentName))
		SegmentName="New Segment"
	Endif
	If(ParamIsDefault(CalcSegmentStats))
		CalcSegmentStats=1
	Endif

	// For the display it will udate the segment list and then 
	If(ParamIsDefault(FRName))
		InsertPoints NumSegments,1,SegmentsList,SegmentsListSel,CurrentFRSegments
		CurrentFRSegments[NumSegments][%StartIndex]=StartIndex
		CurrentFRSegments[NumSegments][%EndIndex]=EndIndex
		CurrentFRSegments[NumSegments][%WLC]=WLC
		CurrentFRSegments[NumSegments][%Flickering]=Flickering
		SetDimLabel 0,0,$SegmentName,SelectedSegment 
		SegmentsList[NumSegments]=SegmentName  
		If(CalcSegmentStats)
			SegmentStats(NumSegments)
		EndIf
		SetDimLabel 0,NumSegments,$SegmentName,CurrentFRSegments
		Duplicate/O/R=[NumSegments] CurrentFRSegments, SelectedSegment
	EndIf
	
	If(!ParamIsDefault(FRName))
		InsertPoints NumSegments,1,FRSegments
		FRSegments[NumSegments][%StartIndex]=StartIndex
		FRSegments[NumSegments][%EndIndex]=EndIndex
		FRSegments[NumSegments][%WLC]=WLC
		FRSegments[NumSegments][%Flickering]=Flickering
		If(CalcSegmentStats)
			SegmentStats(NumSegments,ForceData=ForceData,SepData=SepData,CLData=CLData,FRSegments=FRSegments)
		EndIf
		SetDimLabel 0,NumSegments,$SegmentName,FRSegments
	EndIf
	
	
	
End // MakeNewSegement

Function UpdateSegmentation(UpdateType)
	String UpdateType
	Wave/T SegmentsList=root:MyForceData:SegmentsList
	Wave SegmentsListSel=root:MyForceData:SegmentsListSel
	Wave SelectedSegment=root:MyForceData:SelectedSegment
	Wave CurrentFRSegments=root:MyForceData:CurrentFRSegments
	ControlInfo/W=ForceRampUtilities SegmentListBox
	Variable CurrentIndex_SegmentsListBox=V_value
	Variable NumSegments=DimSize(SegmentsList,0)
	
	Wave UnfilteredForce_Ret=root:MyForceData:UnfilteredForce_Ret
	Wave UnfilteredSep_Ret=root:MyForceData:UnfilteredSep_Ret
	Wave SelectedForce_Ret=root:MyForceData:SelectedForce_Ret
	Wave SelectedSep_Ret=root:MyForceData:SelectedSep_Ret
	Wave Selected_CL=root:MyForceData:Selected_CL
	String FRName=CurrentSelectedFRName()
	
	Variable UpdateGlobalWaves=0

	strswitch(UpdateType)	
		case "CreateCLSpaceSeg_Button":
		
			Wave SegmentInfo=root:MyForceData:SegmentInfo
			Variable NumCLSegments=DimSize(SegmentInfo,0)
			ControlInfo/W=ForceRampUtilities MoleculeType_SV
			String NewCLSegmentName=S_value
			Variable CLSegmentCounter=0
			For(CLSegmentCounter=0;CLSegmentCounter<NumCLSegments;CLSegmentCounter+=1)
				//MakeCLSegments(SelectedForce_Ret,SelectedSep_Ret,Selected_CL,FRName,NewCLSegmentName)
				MakeNewSegment(SegmentInfo[CLSegmentCounter][0],SegmentInfo[CLSegmentCounter][1],SegmentName=NewCLSegmentName,WLC=1)
			EndFor
			UpdateGlobalWaves=1
		break
		case "DeleteSegmentButton":
			// Delete the appropriate segment
			If(NumSegments>1)
				DeletePoints CurrentIndex_SegmentsListBox,1,SegmentsList,SegmentsListSel,CurrentFRSegments
			EndIf
			// Shift to earlier segment
			If(CurrentIndex_SegmentsListBox>0)
				CurrentIndex_SegmentsListBox-=1
			EndIf
			Duplicate/O/R=[CurrentIndex_SegmentsListBox] CurrentFRSegments, SelectedSegment
			UpdateGlobalWaves=1
		break
		case "RecalcSegStats_Button":
			SegmentStats(CurrentIndex_SegmentsListBox)
			UpdateGlobalWaves=1

		break
		case "SegmentFromMarqueeButton":
					// Load Marquee info
			GetMarquee/K left,bottom
			// Find the start and end index associated with the separation wave
			FindLevel/Q/P SelectedSep_Ret, V_left
			Variable StartIndex=Floor(V_LevelX)
			FindLevel/Q/P SelectedSep_Ret, V_right
			Variable EndIndex=Floor(V_LevelX)
			MakeNewSegment(StartIndex,EndIndex)
			UpdateGlobalWaves=1
		break
		case "SegmentFromCursorsButton":
			MakeNewSegment(pcsr(B),pcsr(A))
			UpdateGlobalWaves=1
		break
		case "SegmentListBox":
			// Push data to display wave
			Duplicate/O/R=[CurrentIndex_SegmentsListBox] CurrentFRSegments, SelectedSegment
			// Create a copy of the segment
			Duplicate/O/R=[SelectedSegment[0][%StartIndex],SelectedSegment[0][%EndIndex]] SelectedForce_Ret,SegmentForce_Ret
			Duplicate/O/R=[SelectedSegment[0][%StartIndex],SelectedSegment[0][%EndIndex]] SelectedSep_Ret,SegmentSep_Ret
			// Find out if our segment display is up yet
			DoWindow SegmentsFR
			// If we don't have the graph up, display it with default settings.
			If(V_Flag!=1)
				Display/N=SegmentsFR UnfilteredForce_Ret vs UnfilteredSep_Ret
				ModifyGraph rgb(UnfilteredForce_Ret)=(48896,59904,65280)
				AppendToGraph/C=(0,15872,65280) SelectedForce_Ret vs SelectedSep_Ret
				AppendToGraph/C=(65500,0,0) SegmentForce_Ret vs SegmentSep_Ret
				DoWindow/T SegmentsFR,"Segments"
				Label left "Force"
				Label bottom "Separation"
			EndIf
			DoWindow/F SegmentsFR
			Cursor/P B SelectedForce_Ret SelectedSegment[0][%StartIndex]
			Cursor/P A SelectedForce_Ret SelectedSegment[0][%EndIndex]
			DoWindow/F ForceRampUtilities
			CheckBox WLCCheckBox value=SelectedSegment[0][%WLC]
			CheckBox FlickeringCheckBox value=SelectedSegment[0][%Flickering]
		break
		case "WLCCheckBox":
			ControlInfo/W=ForceRampUtilities WLCCheckBox
			Variable WLCStatus=V_Value
			SelectedSegment[0][%WLC]=WLCStatus
			CurrentFRSegments[CurrentIndex_SegmentsListBox][%WLC]=WLCStatus
			UpdateGlobalWaves=1
		break
		case "FlickeringCheckBox":
			ControlInfo/W=ForceRampUtilities FlickeringCheckBox
			Variable FlickeringStatus=V_Value
			SelectedSegment[0][%Flickering]=FlickeringStatus
			CurrentFRSegments[CurrentIndex_SegmentsListBox][%Flickering]=FlickeringStatus
			UpdateGlobalWaves=1
		break
		case "SegmentStartIndex":
			CurrentFRSegments[CurrentIndex_SegmentsListBox][%StartIndex]=SelectedSegment[0][%StartIndex]
			DoWindow/F SegmentsFR
			Cursor/P B SelectedForce_Ret SelectedSegment[0][%StartIndex]
			DoWindow/F ForceRampUtilities
		case "SegmentEndIndex":
			CurrentFRSegments[CurrentIndex_SegmentsListBox][%EndIndex]=SelectedSegment[0][%EndIndex]
			DoWindow/F SegmentsFR
			Cursor/P A SelectedForce_Ret SelectedSegment[0][%EndIndex]
			DoWindow/F ForceRampUtilities
			UpdateGlobalWaves=1
		break
		case "UpdateSegIndexFromCursorsButton":
			SelectedSegment[0][%StartIndex]=pcsr(B)
			SelectedSegment[0][%EndIndex]=pcsr(A)
			CurrentFRSegments[CurrentIndex_SegmentsListBox][%StartIndex]=SelectedSegment[0][%StartIndex]
			CurrentFRSegments[CurrentIndex_SegmentsListBox][%EndIndex]=SelectedSegment[0][%EndIndex]
			UpdateGlobalWaves=1
		break
		case "SegmentNamePopupMenu":
			ControlInfo/W=ForceRampUtilities SegmentNamePopupMenu
			String NewSegmentName=S_Value
			SetDimLabel 0,CurrentIndex_SegmentsListBox,$NewSegmentName,CurrentFRSegments
			SetDimLabel 0,0,$NewSegmentName,SelectedSegment
			SegmentsList[CurrentIndex_SegmentsListBox]=NewSegmentName
			UpdateGlobalWaves=1
		break
	endswitch

	If(UpdateGlobalWaves)
		String SegmentsWaveName="root:MyForceData:Segments:"+FRName+"_Seg"
		Duplicate/O CurrentFRSegments $SegmentsWaveName
	EndIf


End // UpdateSegmentation


Function UpdateWLCFit(UpdateType)
	String UpdateType
	Wave CurrentFRSegments=root:MyForceData:CurrentFRSegments
	Wave/T WLCFitSegmentsList=root:MyForceData:WLCFitSegmentsList
	Wave WLCFitSegmentsListSel=root:MyForceData:WLCFitSegmentsListSel
	Wave CurrentWLCSegments=root:MyForceData:CurrentWLCSegments
	Wave SelectedWLCSegment=root:MyForceData:SelectedWLCSegment
	Variable NumWLCSegments=DimSize(CurrentWLCSegments,0)
	
	Wave UnfilteredForce_Ret=root:MyForceData:UnfilteredForce_Ret
	Wave UnfilteredSep_Ret=root:MyForceData:UnfilteredSep_Ret
	Wave SelectedForce_Ret=root:MyForceData:SelectedForce_Ret
	Wave SelectedSep_Ret=root:MyForceData:SelectedSep_Ret

	ControlInfo/W=ForceRampUtilities WLCFitListBox
	Variable CurrentWLCFitIndex=V_Value
	Variable UpdateGlobalWaves=0
	String FRName=CurrentSelectedFRName()
	ControlInfo/W=ForceRampUtilities HoldPL_CB
	Variable HoldPL=V_value
	

	String WLCModel="ExtensibleWLC"
	 If(CurrentWLCSegments[CurrentWLCFitIndex][%StretchModulus]==0)
	 	WLCModel="WLC"
	 EndIf


	strswitch(UpdateType)	
		case "WLCFitListBox":
			Duplicate/O/R=[CurrentWLCFitIndex] CurrentWLCSegments, SelectedWLCSegment
			// Create a copy of the segment
			Duplicate/O/R=[SelectedWLCSegment[0][%StartIndex],SelectedWLCSegment[0][%EndIndex]] SelectedForce_Ret,WLCSegmentForce_Ret
			Duplicate/O/R=[SelectedWLCSegment[0][%StartIndex],SelectedWLCSegment[0][%EndIndex]] SelectedSep_Ret,WLCSegmentSep_Ret
			DoWindow/F WLCFitsGuide
			Cursor/P B SelectedForce_Ret SelectedWLCSegment[0][%StartIndex]
			Cursor/P A SelectedForce_Ret SelectedWLCSegment[0][%EndIndex]
			DoWindow/F ForceRampUtilities
		break
		case "StretchModulus_SV":
			CurrentWLCSegments[CurrentWLCFitIndex][%StretchModulus]=SelectedWLCSegment[0][%StretchModulus]
		break
		case "WLCFit_Offset_SV":
			CurrentWLCSegments[CurrentWLCFitIndex][%Offset]=SelectedWLCSegment[0][%Offset]
		break
		case "WLCFit_ContourLength_SV":
		case "WLCFit_PersistenceLength_SV":
		case "WLCFit_RuptureForce_SV":
		case "WLCFit_LoadingRate_SV":
		break
		case "WLC_ContourGuess_SV":
			CurrentWLCSegments[CurrentWLCFitIndex][%ContourLengthGuess]=SelectedWLCSegment[0][%ContourLengthGuess]
		break
		
		case "WLC_PersistenceGuess_SV":
			CurrentWLCSegments[CurrentWLCFitIndex][%PersistenceLengthGuess]=SelectedWLCSegment[0][%PersistenceLengthGuess]
		break
		case "WLC_SingleFit_Button":
			
			Wave WLCSegmentForce_Ret=root:MyForceData:WLCSegmentForce_Ret
			Wave WLCSegmentSep_Ret=root:MyForceData:WLCSegmentSep_Ret
			WLCFit(WLCSegmentForce_Ret,WLCSegmentSep_Ret,WLCModel,CLGuess=CurrentWLCSegments[CurrentWLCFitIndex][%ContourLengthGuess],PLGuess=CurrentWLCSegments[CurrentWLCFitIndex][%PersistenceLengthGuess],StretchModulus=CurrentWLCSegments[CurrentWLCFitIndex][%StretchModulus],Offset=CurrentWLCSegments[CurrentWLCFitIndex][%Offset],HoldPL=HoldPL)
			Wave WLC_Coeff=root:MyForceData:WLC_Coeff
			CurrentWLCSegments[CurrentWLCFitIndex][%ContourLength]=WLC_Coeff[1]
			CurrentWLCSegments[CurrentWLCFitIndex][%PersistenceLength]=WLC_Coeff[0]
			
			Duplicate/O/R=[CurrentWLCFitIndex] CurrentWLCSegments, SelectedWLCSegment
			String OutputForceName="root:MyForceData:WLCFitGuide_Force_"+num2str(CurrentWLCFitIndex)
			String OutputSepName="root:MyForceData:WLCFitGuide_Sep_"+num2str(CurrentWLCFitIndex)
			WLCGuide(WLCModel,WLC_Coeff[1],WLC_Coeff[0],ForceWaveName=OutputForceName,SepWaveName=OutputSepName,Offset=SelectedWLCSegment[0][%Offset],StretchModulus=SelectedWLCSegment[0][%StretchModulus])
			UpdateGlobalWaves=1
		break
		case "WLC_AllFit_Button":
			Variable Counter=0
			For(Counter=0;Counter<NumWLCSegments;Counter+=1)
			
				Duplicate/O/R=[CurrentWLCSegments[Counter][%StartIndex],CurrentWLCSegments[Counter][%EndIndex]] SelectedForce_Ret,WLCSegmentForce_Ret
				Duplicate/O/R=[CurrentWLCSegments[Counter][%StartIndex],CurrentWLCSegments[Counter][%EndIndex]] SelectedSep_Ret,WLCSegmentSep_Ret
				WLCFit(WLCSegmentForce_Ret,WLCSegmentSep_Ret,WLCModel,CLGuess=CurrentWLCSegments[Counter][%ContourLengthGuess],PLGuess=CurrentWLCSegments[Counter][%PersistenceLengthGuess],StretchModulus=CurrentWLCSegments[Counter][%StretchModulus],Offset=CurrentWLCSegments[Counter][%Offset])
				Wave WLC_Coeff=root:MyForceData:WLC_Coeff
				CurrentWLCSegments[Counter][%ContourLength]=WLC_Coeff[1]
				CurrentWLCSegments[Counter][%PersistenceLength]=WLC_Coeff[0]

				OutputForceName="root:MyForceData:WLCFitGuide_Force_"+num2str(Counter)
				OutputSepName="root:MyForceData:WLCFitGuide_Sep_"+num2str(Counter)
				WLCGuide(WLCModel,WLC_Coeff[1],WLC_Coeff[0],ForceWaveName=OutputForceName,SepWaveName=OutputSepName,Offset=CurrentWLCSegments[Counter][%Offset],StretchModulus=CurrentWLCSegments[Counter][%StretchModulus])
			EndFor
			UpdateGlobalWaves=1
			
		break
		case "WLC_SetAllGuesses_Button":
				Counter=0
				For(Counter=0;Counter<NumWLCSegments;Counter+=1)
					CurrentWLCSegments[Counter][%ContourLengthGuess]=SelectedWLCSegment[0][%ContourLengthGuess]
					CurrentWLCSegments[Counter][%PersistenceLengthGuess]=SelectedWLCSegment[0][%PersistenceLengthGuess]
					CurrentWLCSegments[Counter][%Offset]=SelectedWLCSegment[0][%Offset]
					CurrentWLCSegments[Counter][%StretchModulus]=SelectedWLCSegment[0][%StretchModulus]
				EndFor

		break
		case "LoadWLCSegments_Button":
			Variable SegmentCounter=0
			Variable NumSegments=DimSize(CurrentFRSegments,0)
			NumWLCSegments=0
			For(SegmentCounter=0;SegmentCounter<NumSegments;SegmentCounter+=1)
					NumWLCSegments+=CurrentFRSegments[SegmentCounter][%WLC]
			EndFor
		 	// Setup waves for the WLC Fits Tab
			Make/T/N=(NumWLCSegments)/O WLCFitSegmentsList
			Make/N=(NumWLCSegments)/O WLCFitSegmentsListSel 
			Make/N=(NumWLCSegments,10)/O CurrentWLCSegments
			SetDimLabel 1,0,StartIndex,CurrentWLCSegments
 			SetDimLabel 1,1,EndIndex,CurrentWLCSegments
			SetDimLabel 1,2,ContourLength,CurrentWLCSegments
			SetDimLabel 1,3,PersistenceLength,CurrentWLCSegments
			SetDimLabel 1,4,ContourLengthGuess,CurrentWLCSegments
			SetDimLabel 1,5,PersistenceLengthGuess,CurrentWLCSegments
			SetDimLabel 1,6,StretchModulus,CurrentWLCSegments
			SetDimLabel 1,7,Offset,CurrentWLCSegments	
			SetDimLabel 1,8,RuptureForce,CurrentWLCSegments
			SetDimLabel 1,9,LoadingRate,CurrentWLCSegments

			Variable WLCSegmentCounter=0
			SegmentCounter=0

			For(SegmentCounter=0;SegmentCounter<NumSegments;SegmentCounter+=1)
				If(CurrentFRSegments[SegmentCounter][%WLC])
					Variable PLGuess=50e-9
					Variable OffsetGuess=0
					Variable StretchModulusGuess=1050e-12
					String SegmentName=GetDimLabel(CurrentFRSegments, 0, SegmentCounter )

					String Molecule=SegmentName
					If(WhichListItem(Molecule,"Protein;NUG2;NLeC;Calmodulin;BR;")>-1)
						PLGuess=0.5e-9
						OffsetGuess=0
						StretchModulusGuess=0

					EndIf
					If(WhichListItem(Molecule,"ssRNA;B12 Riboswitch;")>-1)
						PLGuess=0.5e-9
						OffsetGuess=0
						StretchModulusGuess=0

					EndIf
					
					CurrentWLCSegments[WLCSegmentCounter][%StartIndex]=CurrentFRSegments[SegmentCounter][%StartIndex]
					CurrentWLCSegments[WLCSegmentCounter][%EndIndex]=CurrentFRSegments[SegmentCounter][%EndIndex]
					CurrentWLCSegments[WLCSegmentCounter][%RuptureForce]=CurrentFRSegments[SegmentCounter][%MaxForce]
					CurrentWLCSegments[WLCSegmentCounter][%LoadingRate]=LoadingRate(SelectedForce_Ret,CurrentFRSegments[SegmentCounter][%StartIndex],CurrentFRSegments[SegmentCounter][%EndIndex])
					CurrentWLCSegments[WLCSegmentCounter][%PersistenceLengthGuess]=PLGuess
					CurrentWLCSegments[WLCSegmentCounter][%ContourLengthGuess]=CurrentFRSegments[SegmentCounter][%MeanCL]
					CurrentWLCSegments[WLCSegmentCounter][%Offset]=OffsetGuess
					CurrentWLCSegments[WLCSegmentCounter][%StretchModulus]=StretchModulusGuess

					SetDimLabel 0,WLCSegmentCounter,$SegmentName,CurrentWLCSegments
					WLCFitSegmentsList[WLCSegmentCounter]=SegmentName
					WLCSegmentCounter+=1
				EndIf
			EndFor

			Duplicate/O/R=[0] CurrentWLCSegments, SelectedWLCSegment
			
			For(WLCSegmentCounter=0;WLCSegmentCounter<NumWLCSegments;WLCSegmentCounter+=1)
				String ForceName="WLCFitGuide_Force_"+num2str(WLCSegmentCounter)					
				String SepName="WLCFitGuide_Sep_"+num2str(WLCSegmentCounter)					
				Make/N=10/O $ForceName,$SepName
			EndFor
			UpdateGlobalWaves=1
		break
	endswitch
			// Find out if our segment display is up yet
			DoWindow WLCFitsGuide
			// If we don't have the graph up, display it with default settings.
			If(V_Flag!=1)
				Display/N=WLCFitsGuide UnfilteredForce_Ret vs UnfilteredSep_Ret
				ModifyGraph rgb(UnfilteredForce_Ret)=(48896,59904,65280)
				AppendToGraph/C=(0,15872,65280) SelectedForce_Ret vs SelectedSep_Ret
				AppendToGraph/C=(65500,0,0) WLCSegmentForce_Ret vs WLCSegmentSep_Ret
				DoWindow/T WLCFitsGuide,"WLC Fits and Guides"
				Label left "Force"
				Label bottom "Separation"
				
			For(WLCSegmentCounter=0;WLCSegmentCounter<NumWLCSegments;WLCSegmentCounter+=1)
				String ForceWLCName="WLCFitGuide_Force_"+num2str(WLCSegmentCounter)					
				String SepWLCName="WLCFitGuide_Sep_"+num2str(WLCSegmentCounter)					
				AppendToGraph/C=(0,0,0) $ForceWLCName vs $SepWLCName
			EndFor
	
			EndIf
		
	If(UpdateGlobalWaves)
		String WLCSegmentsWaveName=	"root:MyForceData:WLCFits:"+FRName+"_WLCF"
		Duplicate/O CurrentWLCSegments $WLCSegmentsWaveName
	EndIf

End // UpdateWLCFit

Function UpdateCurrentFRList(UpdateType)
	String UpdateType
	Wave CurrentFRListSel = root:MyForceData:CurrentFRListSel
	Wave/T CurrentFRList = root:MyForceData:CurrentFRList
	ControlInfo/W=ForceRampUtilities CurrentFRList_ListBox
	Variable SelectedWave = V_value
	Variable NumberOfForceWaves=DimSize(CurrentFRList, 0) 
	Wave MasterWaveList=root:MyForceData:InterestingWaves
	Wave/T SavedFRLists=root:MyForceData:SavedFRLists
	Variable Counter=0
	Variable SelectedFRList

	Variable SaveCurrentFRList=0

	strswitch(UpdateType)	
		case "DeleteFromCurrentFRList":
			String NextWave
			If (SelectedWave>NumberOfForceWaves-1)
				NextWave = CurrentFRList[SelectedWave-1]
			Else
				NextWave = CurrentFRList[SelectedWave+1]
			EndIf
			
			DeletePoints SelectedWave,1,CurrentFRListSel,CurrentFRList

			LoadDetrendAndFilters(NextWave)
			LoadRuptureAndOffsets(NextWave)

			LoadCLSpaceDisplays(NextWave)
			LoadWLCGuidesDisplays(NextWave)
			LoadSegmentationDisplays(NextWave)
			LoadWLCFits(NextWave)

			SaveCurrentFRList=1
		break
		case "AddFromMFP":
			Wave MasterWaveList=root:MyForceData:InterestingWaves

			Variable SelectedWaveIndex = GV("ForceDisplayIndex") 
			Counter=-1  //Set this to -1 so that counter=0 for first loop iteration
			Variable WaveIndex=0
			do
				Counter+=1
				WaveIndex=FindDimLabel(MasterWaveList, 0, CurrentFRList[Counter])
									
			while (WaveIndex<SelectedWaveIndex&&Counter<NumberOfForceWaves)											
			
			InsertPoints Counter,1,CurrentFRListSel,CurrentFRList
			CurrentFRList[Counter]=GetDimLabel(MasterWaveList,0,SelectedWaveIndex)
			SaveCurrentFRList=1
		break
		case "LoadFRList":
			// This finds the saved FRLists and creates a user prompt to select one of them.  
			Variable NumberOfFRLists=DimSize(SavedFRLists, 0)
			String SelectFRList=""
			For(Counter=0;Counter<NumberOfFRLists;Counter+=1)
				SelectFRList+=GetDimLabel(SavedFRLists,0,Counter)+";"
			EndFor
			Prompt SelectedFRList, "Select FR List",popup,SelectFRList
			DoPrompt "Load FR List", SelectedFRList
			
			// For some reason, selectedFRList starts at 1, not 0.  Just need to subtract off 1 to get the correct index
			SelectedFRList-=1
			SetDataFolder root:MyForceData
			String FRList=SavedFRLists[SelectedFRList]
			
			// Now set the waves for the force ramp selector to the correct size
			Variable	NumFRWaves=ItemsInList(FRList)
			Make/N=(NumFRWaves)/T/O CurrentFRList
			Make/N=(NumFRWaves)/O CurrentFRListSel

			// Now put in the names of the force ramps for this list
			CurrentFRList=StringFromList(p,FRList)
			
			DoWindow/F FRUListOperations
			Listbox ListOfFRLists_ListBox selRow=SelectedFRList
			DoWindow/F ForceRampUtilities
		break
		case "AddToFRList_Button":
			ControlInfo/W=ForceRampUtilities AddFRToFRList_Popup
			String TargetFRListName=S_Value
			String TargetFRList=SavedFRLists[%$TargetFRListName]
			
			String SelectedFRWaveName=CurrentFRList[SelectedWave]
			Variable LocationInList=WhichListItem(SelectedFRWaveName, TargetFRList )
			If(LocationInList==-1)
				String UpdatedFRList=AddListItem(SelectedFRWaveName,TargetFRList)
				SavedFRLists[%$TargetFRListName]=UpdatedFRList
			EndIf
			
		break

	EndSwitch
	
	If(SaveCurrentFRList)
		String NewFRList=""
		Variable NumFR=DimSize(CurrentFRList,0)
		For(Counter=0;Counter<NumFR;Counter+=1)
			NewFRList+=CurrentFRList[Counter]+";"
		EndFor
		// Need to insert code to select the correct list and save it.
		ControlInfo/W=FRUListOperations ListOfFRLists_ListBox
		SelectedFRList = V_value
		SavedFRLists[SelectedFRList]=NewFRList
	EndIf
	
End // UpdateCurrentFRList

Function UpdateListOfFRLists(UpdateType)
	String UpdateType
	
	Wave ListOfFRListsSel = root:MyForceData:ListOfFRListsSel
	Wave/T ListOfFRLists = root:MyForceData:ListOfFRLists
	ControlInfo/W=FRUListOperations ListOfFRLists_ListBox
	Variable SelectedFRList = V_value
	Variable NumberOfFRLists=DimSize(ListOfFRLists, 0) 
	Wave MasterWaveList=root:MyForceData:InterestingWaves
	Wave/T SavedFRLists=root:MyForceData:SavedFRLists
	Variable Counter=0
	String SelectedFRListName=ListOfFRLists[SelectedFRList]
	
	strswitch(UpdateType)
		case "NewFRListByWave_CB":
			CheckBox NewFRListByWave_CB win=FRUListOperations, value=1
			CheckBox NewFRListByStringName_CB win=FRUListOperations, value=0
			CheckBox NewFRListByFunction_CB win=FRUListOperations, value=0
			CheckBox NewFRListByDuplication_CB win=FRUListOperations, value=0
		break
		case "NewFRListByStringName_CB":
			CheckBox NewFRListByWave_CB win=FRUListOperations, value=0
			CheckBox NewFRListByStringName_CB win=FRUListOperations, value=1
			CheckBox NewFRListByFunction_CB win=FRUListOperations, value=0
			CheckBox NewFRListByDuplication_CB win=FRUListOperations, value=0
		break
		case "NewFRListByFunction_CB":
			CheckBox NewFRListByWave_CB win=FRUListOperations, value=0
			CheckBox NewFRListByStringName_CB win=FRUListOperations, value=0
			CheckBox NewFRListByFunction_CB win=FRUListOperations, value=1
			CheckBox NewFRListByDuplication_CB win=FRUListOperations, value=0
		break
		case "NewFRListByDuplication_CB":
			CheckBox NewFRListByWave_CB win=FRUListOperations, value=0
			CheckBox NewFRListByStringName_CB win=FRUListOperations, value=0
			CheckBox NewFRListByFunction_CB win=FRUListOperations, value=0
			CheckBox NewFRListByDuplication_CB win=FRUListOperations, value=1
		break

		case "ListOfFRLists_ListBox":
			LoadCurrentFRList(SelectedFRListName)
			LoadCurrentFunctionsList(SelectedFRListName)
			LoadCurrentAnalysisList(SelectedFRListName)
		break
		case "MakeNewList_Button":
			ControlInfo/W=FRUListOperations NewListName_SV
			String NewFRListName=S_value
			String NewFRList=""			
			// Create a new list by wave, if that is selected
			ControlInfo/W=FRUListOperations NewFRListByWave_CB
			If (V_value)
				ControlInfo/W=FRUListOperations NewListByWave_SV
				String FRListByWaveName=S_value
				NewFRList=SelectFRByWave($FRListByWaveName)
			EndIF

			// Create a new list by a string list, if that is selected
			ControlInfo/W=FRUListOperations NewFRListByStringName_CB
			If (V_value)
				ControlInfo/W=FRUListOperations NewListByNames_SV
				String FRListByStringList=S_value
				NewFRList=FRListByStringList
			EndIF

			// Create a new list by a function, if that is selected
			ControlInfo/W=FRUListOperations NewFRListByFunction_CB
			If (V_value)
				ControlInfo/W=FRUListOperations NewListByFunction_SV
				String FRListByFunctionName=S_value
				Make/T/O/N=1 root:MyForceData:NewFRListWave
				Wave/T NewFRListWave=root:MyForceData:NewFRListWave
				Execute "root:MyForceData:NewFRListWave[0]="+ FRListByFunctionName
				NewFRList=NewFRListWave[0]
			EndIF
			// Duplicate the current list with a new name, if that is selected
			ControlInfo/W=FRUListOperations NewFRListByDuplication_CB
			If (V_value)
				NewFRList=SavedFRLists[SelectedFRList]
			EndIF
			
			InsertPoints NumberOfFRLists,1,ListOfFRListsSel,ListOfFRLists,SavedFRLists
			ListOfFRLists[NumberOfFRLists]=NewFRListName
			SavedFRLists[NumberOfFRLists]=NewFRList
			SetDimLabel 0,NumberOfFRLists,$NewFRListName,SavedFRLists
			String FR_AllWaveName="root:MyForceData:FunctionsList:FR_All_Func"				
			String FunctionListWaveName="root:MyForceData:FunctionsList:"+NewFRListName+"_Func"
			Duplicate/O $FR_AllWaveName,$FunctionListWaveName
			FR_AllWaveName="root:MyForceData:AnalysisList:FR_All_Anly"					
			String AnalysisListWaveName="root:MyForceData:AnalysisList:"+NewFRListName+"_Anly"
			Duplicate/O $FR_AllWaveName,$AnalysisListWaveName
		break // Make New List
		case "DeleteFRList_Button":
			DeletePoints SelectedFRList,1,ListOfFRListsSel,ListOfFRLists,SavedFRLists
			FunctionListWaveName="root:MyForceData:FunctionsList:"+SelectedFRListName+"_Func"
			KillWaves $FunctionListWaveName
		break
	endswitch
End //UpdateListOfFRLists

Function UpdateAddToFRListMenu()
	Wave/T SavedFRLists=root:MyForceData:SavedFRLists
	Variable NumFRLists=DimSize(SavedFRLists, 0),Counter=0
	String FRListNames="\""
	For(Counter=0;Counter<NumFRLists;Counter+=1)
		FRListNames+=GetDimLabel(SavedFRLists, 0, Counter)+";"
	EndFor
	FRListNames+="\""
	//DoWindow/F ForceRampUtilities
	PopupMenu AddFRToFRList_Popup, value=#FRListNames
	//DoWindow/F FRUListOperations

End

Function UpdateFunctionsList(UpdateType)
	String UpdateType
	
	Wave/T ListOfFRLists = root:MyForceData:ListOfFRLists
	ControlInfo/W=FRUListOperations ListOfFRLists_ListBox
	Variable SelectedFRList = V_value
	String SelectedFRListName=ListOfFRLists[SelectedFRList]
	Wave/T SavedFRLists=root:MyForceData:SavedFRLists
	String FRNamesList=SavedFRLists[SelectedFRList]

	
	Wave/T CurrentFunctions=root:MyForceData:CurrentFunctions
	Wave/T CurrentFunctionsList=root:MyForceData:CurrentFunctionsList
	Wave CurrentFunctionsListSel=root:MyForceData:CurrentFunctionsListSel
	String FunctionsListWaveName="root:MyForceData:FunctionsList:"+SelectedFRListName+"_Func"
	Wave/T FunctionsList=$FunctionsListWaveName
	ControlInfo/W=FRUListOperations FunctionsList_ListBox
	Variable SelectedFunction = V_value
	Variable NumFunctions=DimSize(CurrentFunctionsList,0)
	
	strswitch(UpdateType)
		case "FunctionsList_ListBox":
			Duplicate/T/O/R=(SelectedFunction) FunctionsList, CurrentFunctions
		break
		case "AddToFunctionsList_Button":
			InsertPoints NumFunctions,1,CurrentFunctionsList,CurrentFunctionsListSel,FunctionsList
			CurrentFunctionsList[NumFunctions]="Offset Stats"
			FunctionsList[NumFunctions][%FunctionName]="Offset Stats"
			FunctionsList[NumFunctions][%FunctionString]="OffsetStats(ForceWave,SepWave,OffsetWaves=1)"
			FunctionsList[NumFunctions][%OutputWaveName]="OffsetsTest"
			FunctionsList[NumFunctions][%NumberOfOutputs]="2"
		break
		case "RemoveFromFunctionsList_Button":
			If(NumFunctions>1)
				DeletePoints SelectedFunction,1,CurrentFunctionsList,CurrentFunctionsListSel,FunctionsList
			EndIf
			// Shift to earlier segment
			If(SelectedFunction>0)
				SelectedFunction-=1
			EndIf
			Duplicate/T/O/R=[SelectedFunction] FunctionsList, CurrentFunctions
		break
		case "NameOfFunction_SV":
			FunctionsList[SelectedFunction][%FunctionName]=CurrentFunctions[0][%FunctionName]
			CurrentFunctionsList[SelectedFunction]=CurrentFunctions[0][%FunctionName]
		break
		case "FunctionToApply_SV":
			FunctionsList[SelectedFunction][%FunctionString]=CurrentFunctions[0][%FunctionString]
		break
		case "OutputWaveName_SV":
			FunctionsList[SelectedFunction][%OutputWaveName]=CurrentFunctions[0][%OutputWaveName]
		break
		case "NumOutputs_SV":
			FunctionsList[SelectedFunction][%NumberOfOutputs]=CurrentFunctions[0][%NumberOfOutputs]
		break
		
		case "ApplyOneFuncToFRList_Button":
			ApplyFuncsToForceWaves(CurrentFunctions[0][%FunctionString],OutputWaveNameList=CurrentFunctions[0][%OutputWaveName],NumOutputs=CurrentFunctions[0][%NumberOfOutputs],FPList=FRNamesList)
		break 
		
		case "ApplyAllFuncsToFRList_Button":
			Variable Counter=0
			String FunctionStringList="",OutputWaveStringList="",NumOutputsStringList=""
			For(Counter=0;Counter<NumFunctions;Counter+=1)
				FunctionStringList+=FunctionsList[Counter][%FunctionString]+";"
				OutputWaveStringList+=FunctionsList[Counter][%OutputWaveName]+";"
				NumOutputsStringList+=FunctionsList[Counter][%NumberOfOutputs]+";"
			EndFor
			ApplyFuncsToForceWaves(FunctionStringList,OutputWaveNameList=OutputWaveStringList,NumOutputs=NumOutputsStringList,FPList=FRNamesList)
		break
		case "FunctionPresets_Popup":
			ControlInfo/W=FRUListOperations FunctionPresets_Popup
			String FunctionFromPopUp=S_value
			strswitch(FunctionFromPopUp)
				case "Box Car Filter":
					FunctionsList[SelectedFunction][%FunctionName]="Box Car Filter"
					FunctionsList[SelectedFunction][%FunctionString]="BoxCarAndDecimateFR(ForceWave,SepWave,5,1)"
					FunctionsList[SelectedFunction][%OutputWaveName]="BoxCarFilterTest"
					FunctionsList[SelectedFunction][%NumberOfOutputs]="1"
				break
				case "Rupture Force Stats":
					FunctionsList[SelectedFunction][%FunctionName]="Rupture Force Stats"
					FunctionsList[SelectedFunction][%FunctionString]="BreakingForceStats(ForceWave,SepWave,50e-9)"
					FunctionsList[SelectedFunction][%OutputWaveName]="RuptureForceTest"
					FunctionsList[SelectedFunction][%NumberOfOutputs]="3"
				break
				case "Offset Stats":
					FunctionsList[SelectedFunction][%FunctionName]="Offset Stats"
					FunctionsList[SelectedFunction][%FunctionString]="OffsetStats(ForceWave,SepWave,OffsetWaves=1)"
					FunctionsList[SelectedFunction][%OutputWaveName]="OffsetsTest"
					FunctionsList[SelectedFunction][%NumberOfOutputs]="2"
				break
				case "Apply Detrend Function":
					FunctionsList[SelectedFunction][%FunctionName]="Apply Detrend Function"
					FunctionsList[SelectedFunction][%FunctionString]="ApplyDetrendFunctionByName(ForceWave,SepWave,FRName,InvertForceData=1)"
					FunctionsList[SelectedFunction][%OutputWaveName]="None"
					FunctionsList[SelectedFunction][%NumberOfOutputs]="0"
				break
				case "Update Offset Stats":
					FunctionsList[SelectedFunction][%FunctionName]="Update Offset Stats"
					FunctionsList[SelectedFunction][%FunctionString]="UpdateOffsetStats(ForceWave,SepWave,FRName)"
					FunctionsList[SelectedFunction][%OutputWaveName]="None"
					FunctionsList[SelectedFunction][%NumberOfOutputs]="0"
				break
				case "Update Rupture Stats":
					FunctionsList[SelectedFunction][%FunctionName]="Update Rupture Force Stats"
					FunctionsList[SelectedFunction][%FunctionString]="UpdateRuptureWave(ForceWave,SepWave,50e-9,FRName)"
					FunctionsList[SelectedFunction][%OutputWaveName]="None"
					FunctionsList[SelectedFunction][%NumberOfOutputs]="0"
				break
				case "Find and Save Detrend":
					FunctionsList[SelectedFunction][%FunctionName]="Find and Save Detrend Function"
					FunctionsList[SelectedFunction][%FunctionString]="FindAndSaveDetrendFunction(FRName,Force_Ext,Sep_Ext,\"Sin\")"
					FunctionsList[SelectedFunction][%OutputWaveName]="None"
					FunctionsList[SelectedFunction][%NumberOfOutputs]="0"
				break
				case "Load Corrected FR":
					FunctionsList[SelectedFunction][%FunctionName]="Load Corrected Force Ramp"
					FunctionsList[SelectedFunction][%FunctionString]="LoadCorrectedFR(ForceWave,SepWave,FRName)"
					FunctionsList[SelectedFunction][%OutputWaveName]="None"
					FunctionsList[SelectedFunction][%NumberOfOutputs]="0"
				break
				case "CL Analysis":
					FunctionsList[SelectedFunction][%FunctionName]="Contour Length Analysis"
					FunctionsList[SelectedFunction][%FunctionString]="CLAnalysis(Force_Ret,Sep_Ret,FRName)"
					FunctionsList[SelectedFunction][%OutputWaveName]="None"
					FunctionsList[SelectedFunction][%NumberOfOutputs]="0"
				break
				case "WLC Fit":
					FunctionsList[SelectedFunction][%FunctionName]="WLC Fit"
					FunctionsList[SelectedFunction][%FunctionString]="AutoWLCFit(ForceWave,SepWave,FRName)"
					FunctionsList[SelectedFunction][%OutputWaveName]="None"
					FunctionsList[SelectedFunction][%NumberOfOutputs]="0"
				break
				case "Set Box Car Average":
					FunctionsList[SelectedFunction][%FunctionName]="Set Box Car Average"
					FunctionsList[SelectedFunction][%FunctionString]="SetBoxCarForFrequency(2e3,ForceWave,FRName)"
					FunctionsList[SelectedFunction][%OutputWaveName]="None"
					FunctionsList[SelectedFunction][%NumberOfOutputs]="0"
				break
			EndSwitch
			Duplicate/T/O/R=[SelectedFunction] FunctionsList, CurrentFunctions
			CurrentFunctionsList[SelectedFunction]=CurrentFunctions[0][%FunctionName]

		break
	EndSwitch
	
End // UpdateFunctionList

Function UpdateAnalysisList(UpdateType)
	String UpdateType
	
	Wave/T ListOfFRLists = root:MyForceData:ListOfFRLists
	ControlInfo/W=FRUListOperations ListOfFRLists_ListBox
	Variable SelectedFRList = V_value
	String SelectedFRListName=ListOfFRLists[SelectedFRList]
	Wave/T SavedFRLists=root:MyForceData:SavedFRLists
	String FRNamesList=SavedFRLists[SelectedFRList]
	
	Wave/T CurrentAnalysis=root:MyForceData:CurrentAnalysis
	Wave/T CurrentAnalysisList=root:MyForceData:CurrentAnalysisList
	Wave CurrentAnalysisListSel=root:MyForceData:CurrentAnalysisListSel
	String AnalysisListWaveName="root:MyForceData:AnalysisList:"+SelectedFRListName+"_Anly"
	Wave/T AnalysisList=$AnalysisListWaveName
	ControlInfo/W=FRUListOperations AnalysisList_ListBox
	Variable SelectedAnalysis = V_value
	Variable NumAnalysis=DimSize(CurrentAnalysisList,0)

	
	strswitch(UpdateType)
		case "NameOfAnalysis_SV":
			CurrentAnalysisList[SelectedAnalysis]=CurrentAnalysis[0][%AnalysisName]
			AnalysisList[SelectedAnalysis][%AnalysisName]=CurrentAnalysis[0][%AnalysisName]
		break
		case "AnalysisToApply_SV":
			AnalysisList[SelectedAnalysis][%AnalysisString]=CurrentAnalysis[0][%AnalysisString]
		break
		case "AnalysisList_ListBox":
			Duplicate/T/O/R=(SelectedAnalysis) AnalysisList, CurrentAnalysis
		break
		case "AddToAnalysisList_Button":
			InsertPoints NumAnalysis,1,CurrentAnalysisList,CurrentAnalysisListSel,AnalysisList
			CurrentAnalysisList[NumAnalysis]="Rupture Force Histogram"
			AnalysisList[NumAnalysis][%AnalysisName]="Rupture Force Histogram"
			AnalysisList[NumAnalysis][%AnalysisString]="FRUHistogram(\"Rupture_Force\",\""+SelectedFRListName +"\")"
		break
		case "RemoveFromAnalysisList_Button":
			If(NumAnalysis>1)
				DeletePoints SelectedAnalysis,1,CurrentAnalysisList,CurrentAnalysisListSel,AnalysisList
			EndIf
			// Shift to earlier segment
			If(SelectedAnalysis>0)
				SelectedAnalysis-=1
			EndIf
			Duplicate/T/O/R=[SelectedAnalysis] AnalysisList, CurrentAnalysis
		break	
		case "AnalysisPresets_Popup":
			ControlInfo/W=FRUListOperations AnalysisPresets_Popup
			String FunctionFromPopUp=S_value
			strswitch(FunctionFromPopUp)
				case "Rupture Force Histogram":
					AnalysisList[SelectedAnalysis][%AnalysisName]="Rupture Force Histogram"
					AnalysisList[SelectedAnalysis][%AnalysisString]="FRUHistogram(\"Rupture_Force\",\""+SelectedFRListName +"\")"
				break
				case "Contour Length Histogram":
					AnalysisList[SelectedAnalysis][%AnalysisName]="Contour Length Histogram"
					AnalysisList[SelectedAnalysis][%AnalysisString]="FRUHistogram(\"WLC_ContourLength\",\""+SelectedFRListName +"\")"
				break
				case "Rupture Force vs Contour Length":
					AnalysisList[SelectedAnalysis][%AnalysisName]="Rupture Force vs Contour Length"
					AnalysisList[SelectedAnalysis][%AnalysisString]="FRUDisplay(\"WLC_RuptureForce\", \"WLC_ContourLength\",\""+SelectedFRListName +"\")"
				break
				case "Rupture Force vs Loading Rate":
					AnalysisList[SelectedAnalysis][%AnalysisName]="Rupture Force vs Loading Rate"
					AnalysisList[SelectedAnalysis][%AnalysisString]="FRUDisplay(\"WLC_RuptureForce\", \"WLC_LoadingRate\",\""+SelectedFRListName +"\")"
				break
			endswitch
			Duplicate/T/O/R=[SelectedAnalysis] AnalysisList, CurrentAnalysis
			CurrentAnalysisList[SelectedAnalysis]=CurrentAnalysis[0][%AnalysisName]
		break
		case "ApplyOneAnalysisToFRList_Button":
			Execute/Q AnalysisList[SelectedAnalysis][%AnalysisString]
		break	
		case "ApplyAllAnalysisToFRList_Button":
			Variable Counter=0
			For(Counter=0;Counter<NumAnalysis;Counter+=1)
				Execute/Q AnalysisList[Counter][%AnalysisString]
			EndFor
		break	

	EndSwitch

End

Function LoadDetrendAndFilters(FRName)
	String FRName
	ApplyFuncsToForceWaves("SaveForceAndSep(Force_Ext,Sep_Ext,TargetFolder=\"root:MyForceData:\",NewName=\"Raw\",Suffix=\"_Ext\")",FPList=FRName)
	ApplyFuncsToForceWaves("SaveForceAndSep(ForceWave,SepWave,TargetFolder=\"root:MyForceData:\",NewName=\"Selected\")",FPList=FRName)
	Wave SelectedForce_Ret=root:MyForceData:SelectedForce_Ret
	Wave SelectedSep_Ret=root:MyForceData:SelectedSep_Ret
	Wave RawForce_Ext=root:MyForceData:RawForce_Ext

	FastOp RawForce_Ext=-1*RawForce_Ext
	FastOp SelectedForce_Ret=-1*SelectedForce_Ret
	// Load the detrend function settings
	Wave/T CurrentDetrendFunction=root:MyForceData:CurrentDetrendFunction
	Wave/T DetrendFunctions=root:MyForceData:DetrendFunctions
	
	CurrentDetrendFunction[0][%DetrendType]=DetrendFunctions[%$FRName][%DetrendType]
	CurrentDetrendFunction[0][%DetrendGuess]=DetrendFunctions[%$FRName][%DetrendGuess]
	CurrentDetrendFunction[0][%DetrendMethod]=DetrendFunctions[%$FRName][%DetrendMethod]
	CurrentDetrendFunction[0][%DetrendFunction]=DetrendFunctions[%$FRName][%DetrendFunction]
	
	Duplicate/O SelectedForce_Ret, SelectedForce_Ret_Backup
	Duplicate/O SelectedSep_Ret, SelectedSep_Ret_Backup
	ApplyDetrendFunction(SelectedForce_Ret,SelectedSep_Ret,CurrentDetrendFunction[0][%DetrendFunction])
	
	// Create versions of these waves that will not have filtering applied to them
	Duplicate/O SelectedForce_Ret, UnfilteredForce_Ret
	Duplicate/O SelectedSep_Ret, UnfilteredSep_Ret

	// Load the Filter and Decimation Functions
	Wave CurrentFilterAndDecimation=root:MyForceData:CurrentFilterAndDecimation
	Wave FilterAndDecimation=root:MyForceData:FilterAndDecimation
	
	CurrentFilterAndDecimation[0][%NumToAverage]=FilterAndDecimation[%$FRName][%NumToAverage]
	CurrentFilterAndDecimation[0][%Decimation]=FilterAndDecimation[%$FRName][%Decimation]
	
	BoxCarAndDecimateFR(SelectedForce_Ret,SelectedSep_Ret,CurrentFilterAndDecimation[0][%NumToAverage],CurrentFilterAndDecimation[0][%Decimation])
	BoxCarAndDecimateFR(SelectedForce_Ret_Backup,SelectedSep_Ret_Backup,CurrentFilterAndDecimation[0][%NumToAverage],CurrentFilterAndDecimation[0][%Decimation])
	
	Variable RawFrequency=1/Deltax(RawForce_Ext)
	Variable FilteredFrequency=RawFrequency/CurrentFilterAndDecimation[0][%NumToAverage]
	Variable PullingVelocity=GetPullingVelocity(RawForce_Ext)

	SetVariable RawFrequency_SV,win = ForceRampUtilities, value= _NUM:RawFrequency
	SetVariable FilteredFrequency_SV,win = ForceRampUtilities, value= _NUM:FilteredFrequency
	SetVariable PullingVelocity_SV,win = ForceRampUtilities, value= _NUM:PullingVelocity

End //LoadDetrendAndFilters

Function LoadRuptureAndOffsets(FRName)
	String FRName
	Wave RFStatsWave=root:MyForceData:RuptureForce
	Wave Offsets=root:MyForceData:Offsets
	Wave Force_Ret=root:MyForceData:SelectedForce_Ret
	Wave Sep_Ret=root:MyForceData:SelectedSep_Ret
	Wave UnfilteredForce_Ret=root:MyForceData:UnfilteredForce_Ret
	Wave UnfilteredSep_Ret=root:MyForceData:UnfilteredSep_Ret

	// Here we read in the offsets for the raw force and separation waves and put them into a selected offets 
	Make/O/N=2 SelectedOffsets 
	SetDimLabel 0,0,$"Offset_Force",SelectedOffsets
	SetDimLabel 0,1,$"Offset_Sep",SelectedOffsets 
	SelectedOffsets[%$"Offset_Force"]=Offsets[%$FRName][%$"Offset_Force"]
	SelectedOffsets[%$"Offset_Sep"]=Offsets[%$FRName][%$"Offset_Sep"]
	
	Variable ForceOffset=SelectedOffsets[%$"Offset_Force"]
	Variable SepOffset=-SelectedOffsets[%$"Offset_Sep"]
	
	FastOp Force_Ret=(ForceOffset)+Force_Ret
	FastOp Sep_Ret=(SepOffset)+Sep_Ret
	FastOp UnfilteredForce_Ret=(ForceOffset)+UnfilteredForce_Ret
	FastOp UnfilteredSep_Ret=(SepOffset)+UnfilteredSep_Ret
	
	// Find out if our display of FR is up yet
	DoWindow SelectedFR
	// If we don't have the graph up, display it will default settings.
	If(V_Flag!=1)
		Display/N=SelectedFR UnfilteredForce_Ret vs UnfilteredSep_Ret
		ModifyGraph rgb(UnfilteredForce_Ret)=(48896,59904,65280)
		AppendToGraph/C=(0,15872,65280) Force_Ret vs Sep_Ret
		DoWindow/T SelectedFR,"Selected Force Ramp"
		Label left "Force"
		Label bottom "Separation"
	EndIf
	
	// Now lets get the Rupture force stats done.  First read them in and then put them into a "selected" rupture force wave
	Wave RuptureForce=root:MyForceData:RuptureForce
	Make/O/N=3 SelectedRuptureForce 
	SetDimLabel 0,0,$"Rupture_Force",SelectedRuptureForce
	SetDimLabel 0,1,$"Rupture_Index",SelectedRuptureForce 
	SetDimLabel 0,2,$"Rupture_Sep",SelectedRuptureForce 
	SelectedRuptureForce[%$"Rupture_Force"]=RuptureForce[%$FRName][%$"Rupture_Force"]
	SelectedRuptureForce[%$"Rupture_Index"]=RuptureForce[%$FRName][%$"Rupture_Index"]
	SelectedRuptureForce[%$"Rupture_Sep"]=RuptureForce[%$FRName][%$"Rupture_Sep"]

	DoWindow/F SelectedFR
	// Move cursor A to the point of rupture on the unfiltered data.
	Cursor/P A UnfilteredForce_Ret SelectedRuptureForce[%$"Rupture_Index"]
	DoWindow/F ForceRampUtilities


End // LoadRuptureAndOffsets


Function LoadCLSpaceDisplays(FRName)
	String FRName
	String CLWaveName=	"root:MyForceData:CLSpace:"+FRName+"_CL"
	Wave TargetCLWave=$CLWaveName
	If(WaveExists(TargetCLWave))
		Duplicate/O  TargetCLWave Selected_CLPeakInfo
	EndIf
	
	ControlInfo/W=ForceRampUtilities AutoCLAnalysis
	Variable AutoCalculateCL=V_value
	If(AutoCalculateCL)
		Wave Force_Ret=root:MyForceData:SelectedForce_Ret
		Wave Sep_Ret=root:MyForceData:SelectedSep_Ret
		CLAnalysis(Force_Ret,Sep_Ret,"Selected")
		Duplicate/O Selected_CLPeakInfo $CLWaveName
	EndIf
	
	Variable NumCLPeaks=DimSize(Selected_CLPeakInfo,0)
	Make/O/T/N=(NumCLPeaks) root:MyForceData:CLPeakList
	Make/O/N=(NumCLPeaks) root:MyForceData:CLPeakListSel
	Wave/T CLPeakList=root:MyForceData:CLPeakList
	Wave CLPeakListSel=root:MyForceData:CLPeakListSel
	Make/O/N=2 ThresholdGuide_Sep,ThresholdGuide_Count



	Variable SegmentCounter=0
	For(SegmentCounter=0;SegmentCounter<NumCLPeaks;SegmentCounter+=1)
		CLPeakList[SegmentCounter]=GetDimLabel(Selected_CLPeakInfo, 0, SegmentCounter )
	EndFor
	
	
End //

Function LoadWLCGuidesDisplays(FRName)
	String FRName
	String WLCGuideWaveName=	"root:MyForceData:WLCGuides:"+FRName+"_WLCG"
	If(WaveExists($WLCGuideWaveName))
		Duplicate/O  $WLCGuideWaveName WLCGuides
	EndIf

End //

Function LoadSegmentationDisplays(FRName)
	String FRName
	String SegmentsWaveName="root:MyForceData:Segments:"+FRName+"_Seg"
	Wave TargetSegments=$SegmentsWaveName
	If(WaveExists(TargetSegments))
		Duplicate/O $SegmentsWaveName CurrentFRSegments
	EndIf

	Variable NumSegments=DimSize(CurrentFRSegments,0)
	Make/O/T/N=(NumSegments) root:MyForceData:SegmentsList
	Make/O/N=(NumSegments) root:MyForceData:SegmentsListSel
	Wave/T SegmentsList=root:MyForceData:SegmentsList
	Wave SegmentsListSel=root:MyForceData:SegmentsListSel
	
	Variable SegmentCounter=0
	For(SegmentCounter=0;SegmentCounter<NumSegments;SegmentCounter+=1)
		SegmentsList[SegmentCounter]=GetDimLabel(CurrentFRSegments, 0, SegmentCounter )
	EndFor


End //

Function LoadWLCFits(FRName)
	String FRName
	String WLCSegmentsWaveName=	"root:MyForceData:WLCFits:"+FRName+"_WLCF"
	Variable NumWLCSegments=0
 	// Setup waves for the WLC Fits Tab
	Make/O/T/N=(NumWLCSegments)/O WLCFitSegmentsList
	Make/O/N=(NumWLCSegments)/O WLCFitSegmentsListSel 

	If(WaveExists($WLCSegmentsWaveName))
		Duplicate/O $WLCSegmentsWaveName CurrentWLCSegments
		NumWLCSegments=DimSize(CurrentWLCSegments,0)
	EndIf
	
	If(!WaveExists($WLCSegmentsWaveName))
		Duplicate/O $WLCSegmentsWaveName CurrentWLCSegments
		NumWLCSegments=0
		Make/N=(NumWLCSegments,8)/O CurrentWLCSegments
		SetDimLabel 1,0,StartIndex,CurrentWLCSegments
		SetDimLabel 1,1,EndIndex,CurrentWLCSegments
		SetDimLabel 1,2,ContourLength,CurrentWLCSegments
		SetDimLabel 1,3,PersistenceLength,CurrentWLCSegments
		SetDimLabel 1,4,ContourLengthGuess,CurrentWLCSegments
		SetDimLabel 1,5,PersistenceLengthGuess,CurrentWLCSegments
		SetDimLabel 1,6,StretchModulus,CurrentWLCSegments
		SetDimLabel 1,7,Offset,CurrentWLCSegments	
	EndIf

	Make/T/N=(NumWLCSegments)/O WLCFitSegmentsList
	Make/N=(NumWLCSegments)/O WLCFitSegmentsListSel 
	Variable WLCSegmentCounter=0

	Duplicate/O/R=[0] CurrentWLCSegments, SelectedWLCSegment
	DoWindow WLCFitsGuide
	Variable GraphExists=V_Flag

	For(WLCSegmentCounter=0;WLCSegmentCounter<20;WLCSegmentCounter+=1)
		String ForceWLCName="WLCFitGuide_Force_"+num2str(WLCSegmentCounter)					
		String SepWLCName="WLCFitGuide_Sep_"+num2str(WLCSegmentCounter)	
		Wave TargetWLCGuide=$ForceWLCName	
		DoWindow WLCFitsGuide
	
		If(WaveExists(TargetWLCGuide)&&(GraphExists))
			RemoveFromGraph/Z/W=WLCFitsGuide $ForceWLCName
		EndIf
	EndFor

	
	For(WLCSegmentCounter=0;WLCSegmentCounter<NumWLCSegments;WLCSegmentCounter+=1)
		String SegmentName=GetDimLabel(CurrentWLCSegments, 0, WLCSegmentCounter)
		WLCFitSegmentsList[WLCSegmentCounter]=SegmentName
		String WLCModel="ExtensibleWLC"

		String ForceName="WLCFitGuide_Force_"+num2str(WLCSegmentCounter)					
		String SepName="WLCFitGuide_Sep_"+num2str(WLCSegmentCounter)		
		If(CurrentWLCSegments[WLCSegmentCounter][%StretchModulus]==0)
			WLCModel="WLC"
		EndIf
		WLCGuide(WLCModel,CurrentWLCSegments[WLCSegmentCounter][%ContourLength],CurrentWLCSegments[WLCSegmentCounter][%PersistenceLength],ForceWaveName=ForceName,SepWaveName=SepName,Offset=CurrentWLCSegments[WLCSegmentCounter][%Offset],StretchModulus=CurrentWLCSegments[WLCSegmentCounter][%StretchModulus])
		If(GraphExists)
			AppendToGraph/W=WLCFitsGuide/C=(0,0,0) $ForceName vs $SepName
		EndIf

	EndFor

End //

Function LoadCurrentFRList(FRListName)
	String FRListName
	
	Wave/T SavedFRLists=root:MyForceData:SavedFRLists
	String FRList=SavedFRLists[%$FRListName]

	// Now set the waves for the force ramp selector to the correct size
	Variable	NumFRWaves=ItemsInList(FRList)
	Make/N=(NumFRWaves)/T/O CurrentFRList
	Make/N=(NumFRWaves)/O CurrentFRListSel
	
	// Now put in the names of the force ramps for this list
	CurrentFRList=StringFromList(p,FRList)

End // LoadCurrentFRList

Function LoadListOfFRLists()
	Wave/T SavedFRLists
	Variable NumFRLists=DimSize(SavedFRLists,0)
	Make/T/O/N=(NumFRLists) ListOfFRLists
	Make/O/N=(NumFRLists) ListOfFRListsSel
	Variable Counter=0	
	For(Counter=0;Counter<NumFRLists;Counter+=1)
		ListOfFRLists[Counter]=GetDimLabel(SavedFRLists,0,Counter)
	EndFor

End // Load ListofFRLists

Function LoadCurrentFunctionsList(FRListName)
	String FRListName
	String FunctionListWaveName="root:MyForceData:FunctionsList:"+FRListName+"_Func"
	Wave/T FunctionsList=$FunctionListWaveName
	Variable NumFunctions = DimSize(FunctionsList,0)
	Make/N=(NumFunctions)/O/T CurrentFunctionsList
	Make/N=(NumFunctions)/O CurrentFunctionsListSel
	CurrentFunctionsList=FunctionsList[p][0]
	Duplicate/O/R=(0) FunctionsList, CurrentFunctions
End

Function LoadCurrentAnalysisList(FRListName)
	String FRListName
	String AnalysisListWaveName="root:MyForceData:AnalysisList:"+FRListName+"_Anly"
	Wave/T AnalysisList=$AnalysisListWaveName
	Variable NumAnalysis = DimSize(AnalysisList,0)
	Make/N=(NumAnalysis)/O/T CurrentAnalysisList
	Make/N=(NumAnalysis)/O CurrentAnalysisListSel
	CurrentAnalysisList=AnalysisList[p][0]
	Duplicate/O/R=(0) AnalysisList, CurrentAnalysis
End


Menu "Force Ramp Utilities"
	"Initialize FRU", InitializeFRU()
	"Individual Wave Analysis", ForceRampUtilities() 
	"Force Ramp List Analysis", FRUListOperations() 
	
End

Function InitializeFRU()
	// Initialize main data folder
	String FRUFolder="root:MyForceData"
	String CLDataFolder=FRUFolder+":CLSpace"
	String WLCGuidesDataFolder=FRUFolder+":WLCGuides"
	String SegmentsDataFolder=FRUFolder+":Segments"
	String WLCFitsDataFolder=FRUFolder+":WLCFits"
	String FunctionsListFolder=FRUFolder+":FunctionsList"
	String AnalysisListFolder=FRUFolder+":AnalysisList"
	String AnalysisFolder=FRUFolder+":Analysis"
	NewDataFolder/O $FRUFolder
	NewDataFolder/O $CLDataFolder
	NewDataFolder/O $WLCGuidesDataFolder
	NewDataFolder/O $SegmentsDataFolder
	NewDataFolder/O $WLCFitsDataFolder
	NewDataFolder/O $FunctionsListFolder
	NewDataFolder/O $AnalysisListFolder
	NewDataFolder/O $AnalysisFolder

	SetDataFolder $FRUFolder
	
	// Find Force/Separation Offsets and breaking force stats
	ApplyFuncsToForceWaves("OffsetStats(ForceWave,SepWave,OffsetWaves=1);BreakingForceStats(ForceWave,SepWave,50e-9);",OutputWaveNameList="Offsets;RuptureForce",NumOutputs="2;3")		

	// Initialize the force ramp lists
	// First the master list	
	String FPMasterList, DataFolderMasterList
	GetForcePlotsList(2,FPMasterList,DataFolderMasterList)
	// Now all the sub lists
	String SubLists = "FR_All;"+UniqueForceLists()
	// How many sublists are there 
	Variable NumberOfForceLists = ItemsInList(SubLists)
	// Make a test wave with this many in it 
	Make/O/T/N=(NumberOfForceLists) SavedFRLists,FRList
	Make/O/N=(NumberOfForceLists) FRListSel
	
	Make/T/O/N=2, CurrentFunctionsList
	Make/O/N=2 CurrentFunctionsListSel
	CurrentFunctionsList={"Offset Stats","Rupture Force Stats"}
	Make/T/O/N=(1,4) CurrentFunctions
	SetDimLabel 1,0,FunctionName,CurrentFunctions
	SetDimLabel 1,1,FunctionString,CurrentFunctions
	SetDimLabel 1,2,OutputWaveName,CurrentFunctions
	SetDimLabel 1,3,NumberOfOutputs,CurrentFunctions
	 
	String DefaultFunctionsListWaveName=FunctionsListFolder+":FR_All_Func"
	Make/T/O/N=(2,4) $DefaultFunctionsListWaveName
	Wave/T DefaultFunctionsListWave=$DefaultFunctionsListWaveName
	SetDimLabel 1,0,FunctionName,DefaultFunctionsListWave
	SetDimLabel 1,1,FunctionString,DefaultFunctionsListWave
	SetDimLabel 1,2,OutputWaveName,DefaultFunctionsListWave
	SetDimLabel 1,3,NumberOfOutputs,DefaultFunctionsListWave
	DefaultFunctionsListWave={{"Offset Stats","Rupture Force Stats"},{"OffsetStats(ForceWave,SepWave,OffsetWaves=1)","BreakingForceStats(ForceWave,SepWave,50e-9)"},{"OffsetsTest","RuptureForceTest"},{"2","3"}}

	Make/T/O/N=2, CurrentAnalysisList
	Make/O/N=2 CurrentAnalysisListSel
	CurrentAnalysisList={"Rupture Force Histogram","Contour Length Histogram"}
	Make/T/O/N=(1,2) CurrentAnalysis
	SetDimLabel 1,0,AnalysisName,CurrentAnalysis
	SetDimLabel 1,1,AnalysisString,CurrentAnalysis
	 
	String DefaultAnalysisListWaveName=AnalysisListFolder+":FR_All_Anly"
	Make/T/O/N=(2,2) $DefaultAnalysisListWaveName
	Wave/T DefaultAnalysisListWave=$DefaultAnalysisListWaveName
	SetDimLabel 1,0,AnalysisName,DefaultAnalysisListWave
	SetDimLabel 1,1,AnalysisString,DefaultAnalysisListWave
	DefaultAnalysisListWave={{"Rupture Force Histogram","Contour Length Histogram"},{"FRUHistogram(\"Rupture_Force\",CurrentFRList)","FRUHistogram(\"ContourLength\",CurrentFRList)"}}
	
	// Set first list to be all the force waves and call it FR_All
	SavedFRLists[0]=FPMasterList
	SetDimLabel 0,0,$"FR_All",SavedFRLists
	
	// Set the other force wave lists to be all the different prefixes we used for the force ramps.
	Variable FRListCounter=0
	For(FRListCounter=1;FRListCounter<NumberOfForceLists;FRListCounter+=1)
		String NamePrefix=StringFromList(FRListCounter,SubLists)
		SavedFRLists[FRListCounter]=ForceListByPrefix(NamePrefix)
		SetDimLabel 0,FRListCounter,$NamePrefix,SavedFRLists
		FRList[FRListCounter]=NamePrefix
		String NewFunctionsListName=FunctionsListFolder+":"+NamePrefix+"_Func"
		Duplicate/O DefaultFunctionsListWave, $NewFunctionsListName
		String NewAnalysisListName=AnalysisListFolder+":"+NamePrefix+"_Anly"
		Duplicate/O DefaultAnalysisListWave, $NewAnalysisListName
	EndFor

	// Now set the waves for the force ramp selector to the correct size for the master force list
	Variable NumFPMasterList = ItemsInList(FPMasterList)
	Make/N=(NumFPMasterList)/T/O CurrentFRList
	Make/N=(NumFPMasterList)/O CurrentFRListSel
		
	// Now put in the names of the force ramps for the master force list
	CurrentFRList=StringFromList(p,FPMasterList)
	
	// Setup filters and detrend function waves
	Variable Counter=0
	Make/N=(NumFPMasterList,4)/T/O DetrendFunctions
	SetDimLabel 1,0,DetrendType,DetrendFunctions
	SetDimLabel 1,1,DetrendGuess,DetrendFunctions
	SetDimLabel 1,2,DetrendMethod,DetrendFunctions
	SetDimLabel 1,3,DetrendFunction,DetrendFunctions
	DetrendFunctions="None"
	
	Make/N=(NumFPMasterList,2)/O FilterAndDecimation
	SetDimLabel 1,0,NumToAverage,FilterAndDecimation
	SetDimLabel 1,1,Decimation,FilterAndDecimation
	
	FilterAndDecimation[][0]=5
	FilterAndDecimation[][1]=1

	For(Counter=0;Counter<NumFPMasterList;Counter+=1)
		String RowLabel=StringFromList(Counter,FPMasterList)
		SetDimLabel 0,Counter,$RowLabel,DetrendFunctions
		SetDimLabel 0,Counter,$RowLabel,FilterAndDecimation
	EndFor
	Duplicate/O/R=[0] DetrendFunctions, CurrentDetrendFunction
	Duplicate/O/R=[0] FilterAndDecimation, CurrentFilterAndDecimation
	
	// Load list of FR Lists
	LoadListOfFRLists()
	
	// Setup waves for Contour Length Space tab
	Make/T/N=1/O CLPeakList
	CLPeakList={"None"}
	Make/N=1/O CLPeakListSel 
	Make/N=(1,4)/O Selected_CurrentCLPeak
	

	
	// Setup waves for the WLC Guide tab.  
	Make/T/N=5/O WLCGuideChoicesList
	WLCGuideChoicesList={"ssRNA","dsDNA","Protein","NUG2","NLeC"}
	Make/N=5/O WLCGuideChoicesListSel 
	Make/O/N=(5,2) WLCChoicesProperties
	WLCChoicesProperties={{0.5e-9,50e-9,5e-9,5e-9,5e-9},{10e-9,100e-9,20e-9,28e-9,110e-9}}
	SetDimLabel 0,0,ssRNA,WLCChoicesProperties
	SetDimLabel 0,1,dsDNA,WLCChoicesProperties
	SetDimLabel 0,2,Protein,WLCChoicesProperties
	SetDimLabel 0,3,NUG2,WLCChoicesProperties
	SetDimLabel 0,4,NLeC,WLCChoicesProperties
	SetDimLabel 1,0,PersistenceLength,WLCChoicesProperties
 	SetDimLabel 1,1,ContourLength,WLCChoicesProperties
	
	Make/T/N=1/O WLCGuideList
	WLCGuideList={"None"}
	Make/N=1/O WLCGuideListSel 
	
	Make/N=2/O WLCGuideCurrentSelection
	SetDimLabel 0,0,PersistenceLength,WLCGuideCurrentSelection
 	SetDimLabel 0,1,ContourLength,WLCGuideCurrentSelection
 	WLCGuideCurrentSelection[%PersistenceLength]=50e-9
 	WLCGuideCurrentSelection[%ContourLength]=50e-9
 	
	Make/N=(1,2)/O WLCGuides
	SetDimLabel 1,0,PersistenceLength,WLCGuides
 	SetDimLabel 1,1,ContourLength,WLCGuides
  	SetDimLabel 0,0,None,WLCGuides

 	WLCGuides[%None][%PersistenceLength]=50e-9
 	WLCGuides[%None][%ContourLength]=50e-9

 	// Setup waves for the Segmentation Tab
	Make/T/N=2/O SegmentsList
	SegmentsList={"Surface Contact","Initial Retract"}
	Make/N=2/O SegmentsListSel 
	Make/N=(2,15)/O CurrentFRSegments
  	SetDimLabel 0,0,$"Surface Contact",CurrentFRSegments
  	SetDimLabel 0,1,$"Initial Retract",CurrentFRSegments
	SetDimLabel 1,0,StartIndex,CurrentFRSegments
 	SetDimLabel 1,1,EndIndex,CurrentFRSegments
	SetDimLabel 1,2,MinForce,CurrentFRSegments
	SetDimLabel 1,3,MaxForce,CurrentFRSegments
	SetDimLabel 1,4,MeanForce,CurrentFRSegments
	SetDimLabel 1,5,StdDevForce,CurrentFRSegments
	SetDimLabel 1,6,MinSep,CurrentFRSegments
	SetDimLabel 1,7,MaxSep,CurrentFRSegments
	SetDimLabel 1,8,MeanSep,CurrentFRSegments
	SetDimLabel 1,9,MinCL,CurrentFRSegments
	SetDimLabel 1,10,MaxCL,CurrentFRSegments
	SetDimLabel 1,11,MeanCL,CurrentFRSegments
	SetDimLabel 1,12,StdDevCL,CurrentFRSegments
	SetDimLabel 1,13,WLC,CurrentFRSegments
	SetDimLabel 1,14,Flickering,CurrentFRSegments
	CurrentFRSegments=0
 	CurrentFRSegments[%$"Surface Contact"][%StartIndex]=0
 	CurrentFRSegments[%$"Surface Contact"][%EndIndex]=5
 	CurrentFRSegments[%$"Initial Retract"][%StartIndex]=6
 	CurrentFRSegments[%$"Initial Retract"][%EndIndex]=10
	
	Duplicate/O/R=[1] CurrentFRSegments, SelectedSegment

 	// Setup waves for the WLC Fits Tab
	Make/T/N=1/O WLCFitSegmentsList
	WLCFitSegmentsList={"None"}
	Make/N=1/O WLCFitSegmentsListSel 
	Make/N=(1,10)/O CurrentWLCSegments
  	SetDimLabel 0,0,$"None",CurrentWLCSegments
	SetDimLabel 1,0,StartIndex,CurrentWLCSegments  
 	SetDimLabel 1,1,EndIndex,CurrentWLCSegments
	SetDimLabel 1,2,ContourLength,CurrentWLCSegments
	SetDimLabel 1,3,PersistenceLength,CurrentWLCSegments
	SetDimLabel 1,4,ContourLengthGuess,CurrentWLCSegments
	SetDimLabel 1,5,PersistenceLengthGuess,CurrentWLCSegments
	SetDimLabel 1,6,StretchModulus,CurrentWLCSegments
	SetDimLabel 1,7,Offset,CurrentWLCSegments
	SetDimLabel 1,8,RuptureForce,CurrentWLCSegments
	SetDimLabel 1,9,LoadingRate,CurrentWLCSegments
	
 	CurrentWLCSegments[%None][%StartIndex]=0
 	CurrentWLCSegments[%None][%EndIndex]=5

	Duplicate/O/R=[1] CurrentWLCSegments, SelectedWLCSegment
	
	Variable FRCounter=0
	For(FRCounter=0;FRCounter< NumFPMasterList;FRCounter+=1)
		String FRName=StringFromList(FRCounter, FPMasterList)
		String CLDataName=CLDataFolder+":"+FRName+"_CL"
		String WLCGuidesDataName=WLCGuidesDataFolder+":"+FRName+"_WLCG"
		String SegmentsDataName=SegmentsDataFolder+":"+FRName+"_Seg"
		String WLCFitsDataName=WLCFitsDataFolder+":"+FRName+"_WLCF"
		Duplicate/O Selected_CurrentCLPeak $CLDataName
		Duplicate/O WLCGuideCurrentSelection $WLCGuidesDataName
		Duplicate/O CurrentFRSegments $SegmentsDataName
		Duplicate/O CurrentWLCSegments $WLCFitsDataName
	EndFor
	UpdateAddToFRListMenu()
End

Function FRUButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	// Load the name of the button the user clicked on
	String ButtonName=ba.CtrlName

	switch( ba.eventCode )
		case 2: // mouse up
			// Apply the appropriate updates depending on which button was pushed.
			strswitch(ButtonName)
				case "FindDetrendFormula_Button":
				case "InitializeDetrend_Button":
					UpdateDetrend(ButtonName)
				break
				case "RuptureFromCursorA":
				case "ForceOffsetFromMarquee":
				case "SepOffsetFromCursorB":
					UpdateRuptureOffsets(ButtonName)
				break
				case "ApplyFilterButton":
					UpdateFiltersDecimation(ButtonName)
				break
				case "CLPeaksButton":
				case "CLAnalysisButton":
					UpdateCLSpace(ButtonName)
				break
				case "AddToListWLCGuide":
				case "DeleteFromListWLCGuide":
					UpdateWLCGuide(ButtonName)
				break
				case "DeleteSegmentButton":
				case "SegmentFromMarqueeButton":
				case "SegmentFromCursorsButton":
				case "UpdateSegIndexFromCursorsButton":
				case "RecalcSegStats_Button":
				case "CreateCLSpaceSeg_Button":
					UpdateSegmentation(ButtonName)
				break
				case "WLC_SingleFit_Button":
				case "WLC_AllFit_Button":
				case "WLC_SetAllGuesses_Button":
				case "LoadWLCSegments_Button":
					UpdateWLCFit(ButtonName)
				break
				case "DeleteFromCurrentFRList":
				case "AddFromMFP":
				case "LoadFRList":
				case "AddToFRList_Button":
					UpdateCurrentFRList(ButtonName)
				break
				case "AddToFunctionsList_Button":
				case "RemoveFromFunctionsList_Button":
				case "ApplyOneFuncToFRList_Button":
				case "ApplyAllFuncsToFRList_Button":
					UpdateFunctionsList(ButtonName)
				break
				case "MakeNewList_Button":
				case "DeleteFRList_Button":
					UpdateListOfFRLists(ButtonName)
				break
				case "AddToAnalysisList_Button":
				case "RemoveFromAnalysisList_Button":
				case "ApplyOneAnalysisToFRList_Button":
				case "ApplyAllAnalysisToFRList_Button":
					UpdateAnalysisList(ButtonName)	
				break
			Endswitch
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function FRUSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	String SVName=sva.CtrlName

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			// Determine what to update for the appropriate set variable control.
			strswitch(SVName)
				case "DetrendFormula_SV":
					UpdateDetrend(SVName)
				break
				case "RuptureIndex":
					UpdateRuptureOffsets(SVName)
				break
				case "BoxCarAverage":
				case "DecimationSetVal":
					UpdateFiltersDecimation(SVName)
				break
				case "CLPeakThreshold_SV":
					UpdateCLSpace(SVName)
				break
				case "SegmentStartIndex":
				case "SegmentEndIndex":
					UpdateSegmentation(SVName)
				break
				case "WLCFit_ContourLength_SV":
				case "WLCFit_PersistenceLength_SV":
				case "WLC_ContourGuess_SV":
				case "WLC_PersistenceGuess_SV":
				case "StretchModulus_SV":
				case "WLCFit_Offset_SV":
				case "WLCFit_RuptureForce_SV":
				case "WLCFit_LoadingRate_SV":
					UpdateWLCFit(SVName)
				break
				case "NameOfFunction_SV":
				case "FunctionToApply_SV":
				case "OutputWaveName_SV":
				case "NumOutputs_SV":
					UpdateFunctionsList(SVName)
				break
				case "NameOfAnalysis_SV":
				case "AnalysisToApply_SV":
					UpdateAnalysisList(SVName)
				break
				
			Endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function FRUListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	String LBName=lba.CtrlName
	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
			strswitch(LBName)
				case "CurrentFRList_ListBox":
					String FRName=listWave[row]
					// Move the Force Review selection to the correct wave
					// GoToForceReviewWave(FRName)
					//Update all the force ramp graphs and displays
					LoadDetrendAndFilters(FRName)
					LoadRuptureAndOffsets(FRName)

					//LoadFRDisplays(FRName)
					LoadCLSpaceDisplays(FRName)
					LoadWLCGuidesDisplays(FRName)
					LoadSegmentationDisplays(FRName)
					LoadWLCFits(FRName)
				break
				case "CLPeaksListBox":
					UpdateCLSpace(LBName)
				break
				case "WLCGuideList":
					UpdateWLCGuide(LBName)
				break
				case "SegmentListBox":
					UpdateSegmentation(LBName)
				break
				case "WLCFitListBox":
					UpdateWLCFit(LBName)
				break
				case "ListOfFRLists_ListBox":
					UpdateListOfFRLists(LBName)
				break
				case "FunctionsList_ListBox":
					UpdateFunctionsList(LBName)
				break
				case "AnalysisList_ListBox":
					UpdateAnalysisList(LBName)
				break
			Endswitch
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch
	return 0
End

Function FRUCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	String CBName=cba.CtrlName

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked

			strswitch(CBName)
				case "ForceVsCLCheckBox":
				case "CLvsTimeCheckBox":
				case "CLHistogramCheckBox":
					UpdateCLSpace(CBName)
				break
				case "WLCCheckBox":
				case "FlickeringCheckBox":
					UpdateSegmentation(CBName)
				break
				case "NewFRListByWave_CB":
				case "NewFRListByStringName_CB":
				case "NewFRListByFunction_CB":
				case "NewFRListByDuplication_CB":
					UpdateListOfFRLists(CBName)
				break
			endswitch
		break
		case -1: // control being killed
		break
	endswitch

	return 0
End



Function FRUPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	String PAName=pa.CtrlName

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			strswitch(PAName)
				case "Detrend_Popup":
					UpdateDetrend(PAName)
				break
				case "MoleculeType_SV":
					UpdateCLSpace(PAName)
				break
				case "SegmentNamePopupMenu":
					UpdateSegmentation(PAName)
				break
				case "FunctionPresets_Popup":
					UpdateFunctionsList(PAName)
				break
				case "AnalysisPresets_Popup":
					UpdateAnalysisList(PAName)
				break
				case "AddFRToFRList_Popup":
					UpdateAddToFRListMenu()
				break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Window ForceRampUtilities() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(836,103,1767,415) as "Force Ramp Utilities"
	ShowTools/A
	ListBox CurrentFRList_ListBox,pos={7,19},size={151,225},proc=FRUListBoxProc
	ListBox CurrentFRList_ListBox,listWave=root:MyForceData:CurrentFRList
	ListBox CurrentFRList_ListBox,selWave=root:MyForceData:CurrentFRListSel,row= 156
	ListBox CurrentFRList_ListBox,mode= 2,selRow= 167
	Button DeleteFromCurrentFRList,pos={167,16},size={76,26},proc=FRUButtonProc,title="Delete"
	Button DeleteFromCurrentFRList,fColor=(61440,61440,61440)
	Button AddFromMFP,pos={168,46},size={77,48},proc=FRUButtonProc,title="Add From \rMaster Force \rPanel"
	Button AddFromMFP,fColor=(61440,61440,61440)
	Button LoadFRLIst,pos={169,99},size={74,36},proc=FRUButtonProc,title="Load Force\rRamp List"
	Button LoadFRLIst,fColor=(61440,61440,61440)
	TabControl AnalysisTabs,pos={252,17},size={637,278},proc=MasterTabProc
	TabControl AnalysisTabs,labelBack=(52224,52224,52224)
	TabControl AnalysisTabs,tabLabel(0)="Filters/Decimation"
	TabControl AnalysisTabs,tabLabel(1)="Rupture/Offsets"
	TabControl AnalysisTabs,tabLabel(2)="Contour Length Space"
	TabControl AnalysisTabs,tabLabel(3)="WLC Guides",tabLabel(4)="Segmentation"
	TabControl AnalysisTabs,tabLabel(5)="WLC Fits",value= 5
	SetVariable RuptureForce,pos={276,78},size={167,16},disable=1,title="Rupture Force"
	SetVariable RuptureForce,format="%.0W1PN"
	SetVariable RuptureForce,limits={-inf,inf,0},value= root:MyForceData:SelectedRuptureForce[%Rupture_Force]
	SetVariable RuptureSep,pos={276,97},size={167,16},disable=1,title="Rupture Sep"
	SetVariable RuptureSep,format="%.0W1Pm"
	SetVariable RuptureSep,limits={-inf,inf,0},value= root:MyForceData:SelectedRuptureForce[%Rupture_Sep]
	SetVariable RuptureIndex,pos={276,116},size={167,16},disable=1,proc=FRUSetVarProc,title="Rupture Point Index"
	SetVariable RuptureIndex,value= root:MyForceData:SelectedRuptureForce[%Rupture_Index]
	SetVariable OffsetForce,pos={276,157},size={167,16},disable=1,title="Force Offset"
	SetVariable OffsetForce,format="%.0W1PN"
	SetVariable OffsetForce,limits={-inf,inf,0},value= root:MyForceData:SelectedOffsets[%Offset_Force]
	SetVariable OffsetSep,pos={275,177},size={167,16},disable=1,title="Sep Offset"
	SetVariable OffsetSep,format="%.3W1Pm"
	SetVariable OffsetSep,limits={-inf,inf,0},value= root:MyForceData:SelectedOffsets[%Offset_Sep]
	Button RuptureFromCursorA,pos={459,77},size={120,22},disable=1,proc=FRUButtonProc,title="Rupture From Cursor A"
	Button RuptureFromCursorA,fColor=(61440,61440,61440)
	Button ForceOffsetFromMarquee,pos={456,156},size={141,17},disable=1,proc=FRUButtonProc,title="Force Offset From Marquee"
	Button ForceOffsetFromMarquee,fColor=(61440,61440,61440)
	Button SepOffsetFromCursorB,pos={456,175},size={126,19},disable=1,proc=FRUButtonProc,title="Sep Offset From Cursor B"
	Button SepOffsetFromCursorB,fColor=(61440,61440,61440)
	SetVariable BoxCarAverage,pos={276,207},size={148,16},disable=1,proc=FRUSetVarProc,title="Box Car Average"
	SetVariable BoxCarAverage,limits={1,32000,1},value= root:MyForceData:CurrentFilterAndDecimation[0][%NumToAverage]
	SetVariable DecimationSetVal,pos={279,240},size={145,16},disable=1,proc=FRUSetVarProc,title="Decimation"
	SetVariable DecimationSetVal,limits={1,32000,1},value= root:MyForceData:CurrentFilterAndDecimation[0][%Decimation]
	Button ApplyFilterButton,pos={454,215},size={85,46},disable=1,proc=FRUButtonProc,title="Apply Filter"
	Button ApplyFilterButton,fColor=(61440,61440,61440)
	CheckBox AutoCLAnalysis,pos={278,69},size={184,14},disable=1,title="Automatically Calculate CL Analysis"
	CheckBox AutoCLAnalysis,value= 1
	Button CLAnalysisButton,pos={281,248},size={115,36},disable=1,proc=FRUButtonProc,title="Do CL Analysis"
	Button CLAnalysisButton,fColor=(61440,61440,61440)
	CheckBox ForceVsCLCheckBox,pos={613,89},size={136,14},disable=1,proc=FRUCheckProc,title="Force Vs Contour Length"
	CheckBox ForceVsCLCheckBox,value= 0
	CheckBox CLvsTimeCheckBox,pos={614,113},size={131,14},disable=1,proc=FRUCheckProc,title="Contour Length vs Time"
	CheckBox CLvsTimeCheckBox,value= 1
	CheckBox CLHistogramCheckBox,pos={615,138},size={141,14},disable=1,proc=FRUCheckProc,title="Contour Length Histogram"
	CheckBox CLHistogramCheckBox,value= 1
	TitleBox DisplayCLGraphs,pos={612,62},size={42,21},disable=1,title="Display"
	ListBox WLCGuideList,pos={277,58},size={133,194},disable=1,proc=FRUListBoxProc
	ListBox WLCGuideList,listWave=root:MyForceData:WLCGuideList
	ListBox WLCGuideList,selWave=root:MyForceData:WLCGuideListSel,mode= 2,selRow= 2
	ListBox SegmentListBox,pos={260,52},size={123,221},disable=1,proc=FRUListBoxProc
	ListBox SegmentListBox,listWave=root:MyForceData:SegmentsList
	ListBox SegmentListBox,selWave=root:MyForceData:SegmentsListSel,mode= 2
	ListBox SegmentListBox,selRow= 9
	ListBox WLCFitListBox,pos={263,50},size={132,228},proc=FRUListBoxProc
	ListBox WLCFitListBox,listWave=root:MyForceData:WLCFitSegmentsList
	ListBox WLCFitListBox,selWave=root:MyForceData:WLCFitSegmentsListSel,mode= 2
	ListBox WLCFitListBox,selRow= 6
	Button CLPeaksButton,pos={554,219},size={139,25},disable=1,proc=FRUButtonProc,title="CL Peaks From Threshold"
	Button CLPeaksButton,fColor=(61440,61440,61440)
	SetVariable PersLengthWLCGuide,pos={454,114},size={164,16},disable=1,proc=FRUSetVarProc,title="Persistence Length"
	SetVariable PersLengthWLCGuide,format="%.1W1Pm"
	SetVariable PersLengthWLCGuide,value= root:MyForceData:WLCGuideCurrentSelection[%PersistenceLength]
	SetVariable ContourLengthWLCGuide,pos={454,134},size={164,16},disable=1,proc=FRUSetVarProc,title="Contour Length"
	SetVariable ContourLengthWLCGuide,format="%.1W1Pm"
	SetVariable ContourLengthWLCGuide,value= root:MyForceData:WLCGuideCurrentSelection[%ContourLength]
	ListBox ConstructsForWLCGuideListBox,pos={652,72},size={142,169},disable=1
	ListBox ConstructsForWLCGuideListBox,listWave=root:MyForceData:WLCGuideChoicesList
	ListBox ConstructsForWLCGuideListBox,selWave=root:MyForceData:WLCGuideChoicesListSel
	ListBox ConstructsForWLCGuideListBox,mode= 2,selRow= 0
	Button AddToListWLCGuide,pos={533,205},size={87,22},disable=1,proc=FRUButtonProc,title="Add To List"
	Button AddToListWLCGuide,fColor=(61440,61440,61440)
	Button DeleteFromListWLCGuide,pos={445,205},size={86,22},disable=1,proc=FRUButtonProc,title="Delete From List"
	Button DeleteFromListWLCGuide,fColor=(61440,61440,61440)
	ListBox CLPeaksListBox,pos={283,91},size={112,147},disable=1,proc=FRUListBoxProc
	ListBox CLPeaksListBox,listWave=root:MyForceData:CLPeakList
	ListBox CLPeaksListBox,selWave=root:MyForceData:CLPeakListSel,mode= 2,selRow= 3
	Button SegmentFromMarqueeButton,pos={397,211},size={146,27},disable=1,proc=FRUButtonProc,title="New Segment From Marquee"
	Button SegmentFromMarqueeButton,fColor=(61440,61440,61440)
	Button SegmentFromCursorsButton,pos={397,240},size={145,28},disable=1,proc=FRUButtonProc,title="New Segment From Cursors"
	Button SegmentFromCursorsButton,fColor=(61440,61440,61440)
	Button DeleteSegmentButton,pos={401,57},size={84,29},disable=1,proc=FRUButtonProc,title="Delete Segment"
	Button DeleteSegmentButton,fColor=(61440,61440,61440)
	SetVariable MaxForceSegment,pos={690,65},size={135,16},disable=1,title="Max Force"
	SetVariable MaxForceSegment,format="%.1W1PN"
	SetVariable MaxForceSegment,limits={-inf,inf,0},value= root:MyForceData:SelectedSegment[0][%MaxForce]
	SetVariable MinForceSegment,pos={691,86},size={133,16},disable=1,title="Min Force"
	SetVariable MinForceSegment,format="%.1W1PN"
	SetVariable MinForceSegment,limits={-inf,inf,0},value= root:MyForceData:SelectedSegment[0][%MinForce]
	SetVariable MeanForceSegment,pos={691,106},size={130,16},disable=1,title="Mean Force"
	SetVariable MeanForceSegment,format="%.1W1PN"
	SetVariable MeanForceSegment,limits={-inf,inf,0},value= root:MyForceData:SelectedSegment[0][%MeanForce]
	SetVariable MaxSepSegment,pos={691,126},size={131,16},disable=1,title="Max Sep"
	SetVariable MaxSepSegment,format="%.1W1Pm"
	SetVariable MaxSepSegment,limits={-inf,inf,0},value= root:MyForceData:SelectedSegment[0][%MaxSep]
	SetVariable MeanCLSegment,pos={691,165},size={130,16},disable=1,title="Mean CL"
	SetVariable MeanCLSegment,format="%.1W1Pm"
	SetVariable MeanCLSegment,limits={-inf,inf,0},value= root:MyForceData:SelectedSegment[0][%MeanCL]
	SetVariable StdDevCLSegment,pos={691,185},size={128,16},disable=1,title="Std Dev CL"
	SetVariable StdDevCLSegment,format="%.1W1Pm"
	SetVariable StdDevCLSegment,limits={-inf,inf,0},value= root:MyForceData:SelectedSegment[0][%StdDevCL]
	SetVariable MinSepSegment,pos={691,145},size={130,16},disable=1,title="MinSep"
	SetVariable MinSepSegment,format="%.1W1Pm"
	SetVariable MinSepSegment,limits={-inf,inf,0},value= root:MyForceData:SelectedSegment[0][%MinSep]
	SetVariable PeakCLSetVar,pos={413,93},size={126,16},disable=1,title="Peak CL"
	SetVariable PeakCLSetVar,format="%.1W1Pm"
	SetVariable PeakCLSetVar,value= root:MyForceData:Selected_CurrentCLPeak[0][%CLPeak_PeakCL]
	SetVariable StartCLSetVar,pos={413,115},size={125,16},disable=1,title="Start CL"
	SetVariable StartCLSetVar,format="%.1W1Pm"
	SetVariable StartCLSetVar,value= root:MyForceData:Selected_CurrentCLPeak[0][%CLPeak_StartCL]
	SetVariable EndCLSetVar,pos={413,139},size={125,16},disable=1,title="End CL"
	SetVariable EndCLSetVar,format="%.1W1Pm"
	SetVariable EndCLSetVar,value= root:MyForceData:Selected_CurrentCLPeak[0][%CLPeak_EndCL]
	SetVariable SegmentEndIndex,pos={524,88},size={113,16},disable=1,proc=FRUSetVarProc,title="End Index"
	SetVariable SegmentEndIndex,value= root:MyForceData:SelectedSegment[0][%EndIndex]
	SetVariable SegmentStartIndex,pos={523,61},size={113,16},disable=1,proc=FRUSetVarProc,title="StartIndex"
	SetVariable SegmentStartIndex,value= root:MyForceData:SelectedSegment[0][%StartIndex]
	CheckBox WLCCheckBox,pos={693,213},size={42,14},disable=1,proc=FRUCheckProc,title="WLC"
	CheckBox WLCCheckBox,value= 1
	CheckBox FlickeringCheckBox,pos={692,231},size={63,14},disable=1,proc=FRUCheckProc,title="Flickering"
	CheckBox FlickeringCheckBox,value= 0
	Button UpdateSegIndexFromCursorsButton,pos={517,112},size={137,22},disable=1,proc=FRUButtonProc,title="Update Index From Cursors"
	Button UpdateSegIndexFromCursorsButton,fColor=(61440,61440,61440)
	PopupMenu SegmentNamePopupMenu,pos={388,153},size={164,22},disable=1,proc=FRUPopMenuProc,title="Set Segment Name"
	PopupMenu SegmentNamePopupMenu,mode=10,popvalue="Protein",value= #"\"Custom;Surface Contact;Adhesion;Initial Retract;dsDNA before OST;dsDNA OST;dsDNA after OST;NUG2;BR;Protein;ssRNA;dsDNA;Tip Disconnects From Molecule;Anomalous\""
	SetVariable WLC_PersistenceGuess_SV,pos={632,155},size={192,16},proc=FRUSetVarProc,title="Persistence Length Guess"
	SetVariable WLC_PersistenceGuess_SV,format="%.1W1Pm"
	SetVariable WLC_PersistenceGuess_SV,limits={-inf,inf,1e-09},value= root:MyForceData:SelectedWLCSegment[0][%PersistenceLengthGuess]
	SetVariable WLC_ContourGuess_SV,pos={632,133},size={192,16},proc=FRUSetVarProc,title="Contour Length Guess"
	SetVariable WLC_ContourGuess_SV,format="%.1W1Pm"
	SetVariable WLC_ContourGuess_SV,limits={-inf,inf,1e-09},value= root:MyForceData:SelectedWLCSegment[0][%ContourLengthGuess]
	SetVariable WLCFit_ContourLength_SV,pos={429,131},size={169,16},proc=FRUSetVarProc,title="Contour Length"
	SetVariable WLCFit_ContourLength_SV,format="%.1W1Pm"
	SetVariable WLCFit_ContourLength_SV,value= root:MyForceData:SelectedWLCSegment[0][%ContourLength]
	SetVariable WLCFit_PersistenceLength_SV,pos={429,151},size={169,16},proc=FRUSetVarProc,title="Persistence Length"
	SetVariable WLCFit_PersistenceLength_SV,format="%.1W1Pm"
	SetVariable WLCFit_PersistenceLength_SV,value= root:MyForceData:SelectedWLCSegment[0][%PersistenceLength]
	Button WLC_SingleFit_Button,pos={430,183},size={113,25},proc=FRUButtonProc,title="Fit Selected Segment"
	Button WLC_SingleFit_Button,fColor=(61440,61440,61440)
	Button WLC_AllFit_Button,pos={431,213},size={113,25},proc=FRUButtonProc,title="Fit All Segments"
	Button WLC_AllFit_Button,fColor=(61440,61440,61440)
	Button WLC_SetAllGuesses_Button,pos={632,184},size={141,24},proc=FRUButtonProc,title="Set Guess For All Segments"
	Button WLC_SetAllGuesses_Button,fColor=(61440,61440,61440)
	Button LoadWLCSegments_Button,pos={432,47},size={109,25},proc=FRUButtonProc,title="Load WLC Segments"
	Button LoadWLCSegments_Button,fColor=(61440,61440,61440)
	SetVariable StretchModulus_SV,pos={633,113},size={192,16},proc=FRUSetVarProc,title="Stretch Modulus"
	SetVariable StretchModulus_SV,format="%.3W1PN"
	SetVariable StretchModulus_SV,value= root:MyForceData:SelectedWLCSegment[0][%StretchModulus]
	SetVariable WLCFit_Offset_SV,pos={633,93},size={192,16},proc=FRUSetVarProc,title="Offset"
	SetVariable WLCFit_Offset_SV,format="%.1W1Pm"
	SetVariable WLCFit_Offset_SV,limits={-inf,inf,1e-09},value= root:MyForceData:SelectedWLCSegment[0][%Offset]
	Button RecalcSegStats_Button,pos={545,210},size={146,31},disable=1,proc=FRUButtonProc,title="Recalculate Segment Stats"
	Button RecalcSegStats_Button,fColor=(61440,61440,61440)
	SetVariable WLCFit_LoadingRate_SV,pos={430,112},size={169,16},proc=FRUSetVarProc,title="Loading Rate"
	SetVariable WLCFit_LoadingRate_SV,format="%.1W1PN/s"
	SetVariable WLCFit_LoadingRate_SV,value= root:MyForceData:SelectedWLCSegment[0][%LoadingRate]
	SetVariable WLCFit_RuptureForce_SV,pos={431,91},size={169,16},proc=FRUSetVarProc,title="Rupture Force"
	SetVariable WLCFit_RuptureForce_SV,format="%.1W1PN"
	SetVariable WLCFit_RuptureForce_SV,value= root:MyForceData:SelectedWLCSegment[0][%RuptureForce]
	Button AddToFRList_Button,pos={8,252},size={150,24},proc=FRUButtonProc,title="Add Selected FR to"
	Button AddToFRList_Button,fColor=(61440,61440,61440)
	PopupMenu AddFRToFRList_Popup,pos={10,278},size={169,22},proc=FRUPopMenuProc
	PopupMenu AddFRToFRList_Popup,mode=9,popvalue="GoodRSWithB12Flickering",value= #"\"FR_All;Image;RiboswitchNoB12;riboswitchwithb12;riboswitchwithcof;GoodRSnoB12;GoodRSWithB12;GoodRSNoB12Flickering;GoodRSWithB12Flickering;\""
	Button FindDetrendFormula_Button,pos={630,57},size={177,34},disable=1,proc=FRUButtonProc,title="Detrend Force vs Separation Data"
	Button FindDetrendFormula_Button,fColor=(61440,61440,61440)
	PopupMenu Detrend_Popup,pos={280,62},size={171,22},disable=1,proc=FRUPopMenuProc,title="Detrend Function Type"
	PopupMenu Detrend_Popup,mode=1,popvalue="None",value= #"\"None;Sin;2ndOrderPoly;4thOrderPoly;Linear;Auto\""
	SetVariable DetrendFormula_SV,pos={279,107},size={525,16},disable=1,proc=FRUSetVarProc,title="Detrend Formula"
	SetVariable DetrendFormula_SV,value= root:MyForceData:CurrentDetrendFunction[0][%DetrendFunction]
	Button InitializeDetrend_Button,pos={484,59},size={100,34},disable=1,proc=FRUButtonProc,title="Initial Detrend"
	Button InitializeDetrend_Button,fColor=(61440,61440,61440)
	SetVariable CLThreshold_SV,pos={409,266},size={132,16},disable=1,proc=FRUSetVarProc,title="Threshold "
	SetVariable CLThreshold_SV,format="%.1W1PN"
	SetVariable CLThreshold_SV,limits={-inf,inf,1e-12},value= _NUM:5e-12
	SetVariable CLBinWidth_SV,pos={409,243},size={133,16},disable=1,proc=FRUSetVarProc,title="Bin Width"
	SetVariable CLBinWidth_SV,format="%.1W1Pm"
	SetVariable CLBinWidth_SV,limits={-inf,inf,1e-09},value= _NUM:1e-09
	SetVariable CLNumToAverage_SV,pos={409,220},size={133,16},disable=1,proc=FRUSetVarProc,title="Histogram Averaging"
	SetVariable CLNumToAverage_SV,value= _NUM:1
	SetVariable CLPeakThreshold_SV,pos={698,223},size={132,16},disable=1,proc=FRUSetVarProc,title="Peak Threshold "
	SetVariable CLPeakThreshold_SV,limits={-inf,inf,0.2},value= _NUM:20
	PopupMenu MoleculeType_SV,pos={408,179},size={142,22},disable=1,proc=FRUPopMenuProc,title="Molecule Type"
	PopupMenu MoleculeType_SV,mode=7,popvalue="Protein",value= #"\"NUG2;dsDNA;NLeC;Calmodulin;BR;B12 Riboswitch;Protein;ssRNA;\""
	Button CreateCLSpaceSeg_Button,pos={545,242},size={145,25},disable=1,proc=FRUButtonProc,title="Create CL Space Segments"
	Button CreateCLSpaceSeg_Button,fColor=(61440,61440,61440)
	SetVariable RawFrequency_SV,pos={624,185},size={170,16},disable=1,proc=FRUSetVarProc,title="Raw Samping Rate"
	SetVariable RawFrequency_SV,format="%.2W1PHz",value= _NUM:50000
	SetVariable FilteredFrequency_SV,pos={624,212},size={170,16},disable=1,proc=FRUSetVarProc,title="Filtered Samping Rate"
	SetVariable FilteredFrequency_SV,format="%.2W1PHz",value= _NUM:100
	SetVariable PullingVelocity_SV,pos={624,241},size={170,16},disable=1,proc=FRUSetVarProc,title="Pulling Velocity"
	SetVariable PullingVelocity_SV,format="%.2W1Pm/s",value= _NUM:1.25e-08
	PopupMenu FilterType,pos={277,170},size={119,22},disable=1,proc=FRUPopMenuProc,title="Filter Type"
	PopupMenu FilterType,mode=1,popvalue="BoxCar",value= #"\"BoxCar;SavitzkyGolay\""
	CheckBox HoldPL_CB,pos={846,155},size={16,14},proc=FRUCheckProc,title=""
	CheckBox HoldPL_CB,value= 1
	CheckBox HoldCL_CB,pos={846,137},size={16,14},proc=FRUCheckProc,title=""
	CheckBox HoldCL_CB,value= 0
	CheckBox HoldSM_CB,pos={846,113},size={16,14},proc=FRUCheckProc,title=""
	CheckBox HoldSM_CB,value= 0
	CheckBox HoldOffset_CB,pos={846,94},size={16,14},proc=FRUCheckProc,title=""
	CheckBox HoldOffset_CB,value= 0
	TitleBox Hold_TB,pos={836,64},size={30,21},title="Hold"
	SetVariable StretchMod_WLCGuide,pos={454,94},size={164,16},disable=1,proc=FRUSetVarProc,title="Stretch Modulus"
	SetVariable StretchMod_WLCGuide,format="%.1W1PN"
	SetVariable StretchMod_WLCGuide,value= root:MyForceData:WLCGuideCurrentSelection[%PersistenceLength]
	SetVariable Offset_WLCGuide,pos={452,74},size={164,16},disable=1,proc=FRUSetVarProc,title="Offset"
	SetVariable Offset_WLCGuide,format="%.1W1Pm"
	SetVariable Offset_WLCGuide,value= root:MyForceData:WLCGuideCurrentSelection[%PersistenceLength]
EndMacro


Function MasterTabProc(tca) : TabControl
	STRUCT WMTabControlAction &tca

	switch( tca.eventCode )
		case 2: // mouse up
			Variable tab = tca.tab
			
			SetVariable BoxCarAverage,disable= (tab!=0)
			SetVariable DecimationSetVal,disable= (tab!=0)
			SetVariable DetrendFormula_SV,disable= (tab!=0)
			Button FindDetrendFormula_Button,disable= (tab!=0)
			PopupMenu Detrend_Popup,disable= (tab!=0)			
			Button ApplyFilterButton,disable= (tab!=0)
			Button InitializeDetrend_Button, disable=(tab!=0)
			SetVariable RawFrequency_SV,disable= (tab!=0)
			SetVariable FilteredFrequency_SV,disable= (tab!=0)
			SetVariable PullingVelocity_SV,disable= (tab!=0)
			PopupMenu FilterType,mode=1,disable= (tab!=0)


			SetVariable RuptureForce,disable= (tab!=1)
			SetVariable RuptureSep,disable= (tab!=1)
			SetVariable RuptureIndex,disable= (tab!=1)
			SetVariable OffsetForce,disable= (tab!=1)
			SetVariable OffsetSep,disable= (tab!=1)
			Button RuptureFromCursorA,disable= (tab!=1)
			Button ForceOffsetFromMarquee,disable= (tab!=1)
			Button SepOffsetFromCursorB,disable= (tab!=1)
			
			CheckBox AutoCLAnalysis, disable= (tab!=2)
			CheckBox ForceVsCLCheckBox, disable= (tab!=2)
			CheckBox CLvsTimeCheckBox, disable= (tab!=2)
			CheckBox CLHistogramCheckBox, disable= (tab!=2)
			Button CLAnalysisButton,disable= (tab!=2)
			TitleBox DisplayCLGraphs, disable=(tab!=2)
			Button CLPeaksButton, disable=(tab!=2)
			ListBox CLPeaksListBox,disable=(tab!=2)
			SetVariable PeakCLSetVar,disable= (tab!=2)
			SetVariable StartCLSetVar,disable= (tab!=2)
			SetVariable EndCLSetVar,disable= (tab!=2)
			SetVariable CLThreshold_SV,disable= (tab!=2)
			SetVariable CLBinWidth_SV,disable= (tab!=2)
			SetVariable CLNumToAverage_SV,disable= (tab!=2)
			SetVariable CLPeakThreshold_SV,disable= (tab!=2)
			PopupMenu MoleculeType_SV,disable= (tab!=2)

			ListBox WLCGuideList, disable=(tab!=3)
			ListBox ConstructsForWLCGuideListBox, disable=(tab!=3)
			SetVariable PersLengthWLCGuide, disable=(tab!=3)
			SetVariable ContourLengthWLCGuide, disable=(tab!=3)
			Button DeleteFromListWLCGuide, disable=(tab!=3)
			Button AddToListWLCGuide, disable=(tab!=3)
			SetVariable StretchMod_WLCGuide,disable=(tab!=3)
			SetVariable Offset_WLCGuide,disable=(tab!=3)

			ListBox SegmentListBox, disable=(tab!=4)
			Button DeleteSegmentButton, disable=(tab!=4)
			Button SegmentFromMarqueeButton, disable=(tab!=4)
			Button SegmentFromCursorsButton, disable=(tab!=4)
			SetVariable MaxForceSegment,disable= (tab!=4)
			SetVariable MinForceSegment,disable= (tab!=4)
			SetVariable MeanForceSegment,disable= (tab!=4)
			SetVariable MaxSepSegment,disable= (tab!=4)
			SetVariable MinSepSegment,disable= (tab!=4)
			SetVariable MeanCLSegment,disable= (tab!=4)
			SetVariable StdDevCLSegment,disable= (tab!=4)
			SetVariable SegmentStartIndex,disable= (tab!=4)
			SetVariable SegmentEndIndex,disable= (tab!=4)
			CheckBox WLCCheckBox, disable= (tab!=4)
			CheckBox FlickeringCheckBox, disable= (tab!=4)
			Button UpdateSegIndexFromCursorsButton, disable=(tab!=4)
			PopupMenu SegmentNamePopupMenu, disable=(tab!=4)
			Button RecalcSegStats_Button, disable=(tab!=4)
			Button CreateCLSpaceSeg_Button, disable=(tab!=4)

			ListBox WLCFitListBox, disable=(tab!=5)
			SetVariable WLCFit_ContourLength_SV,disable= (tab!=5)
			SetVariable WLCFit_PersistenceLength_SV,disable= (tab!=5)
			SetVariable WLC_ContourGuess_SV,disable= (tab!=5)
			SetVariable WLC_PersistenceGuess_SV,disable= (tab!=5)
			SetVariable WLCFit_Offset_SV,disable= (tab!=5)
			SetVariable StretchModulus_SV,disable= (tab!=5)
			SetVariable WLCFit_RuptureForce_SV,disable= (tab!=5)
			SetVariable WLCFit_LoadingRate_SV,disable= (tab!=5)
			Button WLC_SingleFit_Button, disable=(tab!=5)
			Button WLC_AllFit_Button, disable=(tab!=5)
			Button WLC_SetAllGuesses_Button, disable=(tab!=5)
			Button LoadWLCSegments_Button, disable=(tab!=5)
			CheckBox HoldPL_CB,disable=(tab!=5)
			CheckBox HoldCL_CB,disable=(tab!=5)
			CheckBox HoldSM_CB,disable=(tab!=5)
			CheckBox HoldOffset_CB,disable=(tab!=5)
			TitleBox Hold_TB,disable=(tab!=5)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
// ************************************************
// FRU List Operations Panel Functions
// This panel deals with applying functions to the lists of force ramps we build up.
// Some of the operations are processing and analysis of all the individual force ramps
// This would include smoothing, detrending, calculating the rupture force of an individual force extension curve, etc.
// Other operations are analysis of values extracted from the entire lists, 
// such as rupture force histograms, or rupture force versus contour length

Window FRUListOperations() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(74,77,634,631) as "FRU List Operations"
	ShowTools/A
	ListBox ListOfFRLists_ListBox,pos={12,11},size={161,354},proc=FRUListBoxProc
	ListBox ListOfFRLists_ListBox,listWave=root:MyForceData:ListOfFRLists
	ListBox ListOfFRLists_ListBox,selWave=root:MyForceData:ListOfFRListsSel,mode= 2
	ListBox ListOfFRLists_ListBox,selRow= 7
	TabControl FRULists_Tab,pos={190,12},size={365,535},proc=FRUTabProc
	TabControl FRULists_Tab,labelBack=(47872,47872,47872)
	TabControl FRULists_Tab,tabLabel(0)="Apply Functions to List"
	TabControl FRULists_Tab,tabLabel(1)="Analysis",tabLabel(2)="Make New List"
	TabControl FRULists_Tab,value= 0
	ListBox FunctionsList_ListBox,pos={201,43},size={332,284},proc=FRUListBoxProc
	ListBox FunctionsList_ListBox,listWave=root:MyForceData:CurrentFunctionsList
	ListBox FunctionsList_ListBox,selWave=root:MyForceData:CurrentFunctionsListSel
	ListBox FunctionsList_ListBox,mode= 2,selRow= 1
	SetVariable NameOfFunction_SV,pos={209,367},size={322,16},proc=FRUSetVarProc,title="Function Name"
	SetVariable NameOfFunction_SV,limits={-inf,inf,0},value= root:MyForceData:CurrentFunctions[0][%FunctionName]
	SetVariable FunctionToApply_SV,pos={212,389},size={320,16},proc=FRUSetVarProc,title="Function"
	SetVariable FunctionToApply_SV,limits={-inf,inf,0},value= root:MyForceData:CurrentFunctions[0][%FunctionString]
	SetVariable OutputWaveName_SV,pos={210,412},size={320,16},proc=FRUSetVarProc,title="Output Wave Name"
	SetVariable OutputWaveName_SV,limits={-inf,inf,0},value= root:MyForceData:CurrentFunctions[0][%OutputWaveName]
	Button AddToFunctionsList_Button,pos={209,336},size={87,27},proc=FRUButtonProc,title="Add Function"
	Button AddToFunctionsList_Button,fColor=(61440,61440,61440)
	Button RemoveFromFunctionsList_Button,pos={310,337},size={95,27},proc=FRUButtonProc,title="Remove Function"
	Button RemoveFromFunctionsList_Button,fColor=(61440,61440,61440)
	SetVariable NumOutputs_SV,pos={212,434},size={320,16},proc=FRUSetVarProc,title="Number Of Outputs"
	SetVariable NumOutputs_SV,limits={-inf,inf,0},value= root:MyForceData:CurrentFunctions[0][%NumberOfOutputs]
	Button ApplyAllFuncsToFRList_Button,pos={407,504},size={122,30},proc=FRUButtonProc,title="Apply All Functions"
	Button ApplyAllFuncsToFRList_Button,fColor=(61440,61440,61440)
	Button ApplyOneFuncToFRList_Button,pos={216,500},size={122,30},proc=FRUButtonProc,title="Apply This Function"
	Button ApplyOneFuncToFRList_Button,fColor=(61440,61440,61440)
	PopupMenu FunctionPresets_Popup,pos={213,461},size={213,22},proc=FRUPopMenuProc,title="Function Presets"
	PopupMenu FunctionPresets_Popup,mode=2,popvalue="Load Corrected FR",value= #"\"WLC Fit;Load Corrected FR;CL Analysis;Find And Save Detrend;Apply Detrend Function;Update Offset Stats;Update Rupture Stats;Box Car Filter;Rupture Force Stats;Offset Stats;Custom\""
	SetVariable NewListName_SV,pos={220,63},size={294,16},disable=1,proc=FRUSetVarProc,title="New List Name"
	SetVariable NewListName_SV,value= _STR:"BigNugHits2"
	SetVariable NewListByWave_SV,pos={207,146},size={308,16},disable=1,proc=FRUSetVarProc,title="Wave Name"
	SetVariable NewListByWave_SV,value= _STR:""
	Button FindWave_Button,pos={316,171},size={203,20},disable=1,proc=FRUButtonProc,title="Find Wave"
	Button FindWave_Button,fColor=(61440,61440,61440)
	CheckBox NewFRListByWave_CB,pos={204,123},size={98,14},disable=1,proc=FRUCheckProc,title="FR List By Wave"
	CheckBox NewFRListByWave_CB,value= 0,mode=1
	CheckBox NewFRListByStringName_CB,pos={202,207},size={119,14},disable=1,proc=FRUCheckProc,title="FR List By FR Names"
	CheckBox NewFRListByStringName_CB,value= 1,mode=1
	SetVariable NewListByNames_SV,pos={206,234},size={337,16},disable=1,proc=FRUSetVarProc,title="List Of Names"
	SetVariable NewListByNames_SV,value= _STR:"BNug2DBCO10nguL0003;BNug2DBCO10nguL0004;BNug2DBCO10nguL0008;"
	Button MakeNewList_Button,pos={206,393},size={323,40},disable=1,proc=FRUButtonProc,title="Make New List"
	Button MakeNewList_Button,fColor=(61440,61440,61440)
	CheckBox NewFRListByFunction_CB,pos={204,290},size={110,14},disable=1,proc=FRUCheckProc,title="FR List By Function"
	CheckBox NewFRListByFunction_CB,value= 0,mode=1
	SetVariable NewListByFunction_SV,pos={207,317},size={340,16},disable=1,proc=FRUSetVarProc,title="Function"
	SetVariable NewListByFunction_SV,value= _STR:"SelectByRFRange(100e-12,300e-12,\"OtherNUG2Hits\")"
	Button DeleteFRList_Button,pos={11,376},size={162,36},proc=FRUButtonProc,title="Delete FR List"
	Button DeleteFRList_Button,fColor=(61440,61440,61440)
	ListBox AnalysisList_ListBox,pos={201,43},size={332,284},disable=1,proc=FRUListBoxProc
	ListBox AnalysisList_ListBox,listWave=root:MyForceData:CurrentAnalysisList
	ListBox AnalysisList_ListBox,selWave=root:MyForceData:CurrentAnalysisListSel
	ListBox AnalysisList_ListBox,mode= 2,selRow= 0
	Button AddToAnalysisList_Button,pos={209,336},size={87,27},disable=1,proc=FRUButtonProc,title="Add Analysis"
	Button AddToAnalysisList_Button,fColor=(61440,61440,61440)
	Button RemoveFromAnalysisList_Button,pos={310,337},size={95,27},disable=1,proc=FRUButtonProc,title="Remove Analysis"
	Button RemoveFromAnalysisList_Button,fColor=(61440,61440,61440)
	SetVariable NameOfAnalysis_SV,pos={209,367},size={322,16},disable=1,proc=FRUSetVarProc,title="Analysis Name"
	SetVariable NameOfAnalysis_SV,limits={-inf,inf,0},value= root:MyForceData:CurrentAnalysis[0][%AnalysisName]
	SetVariable AnalysisToApply_SV,pos={212,389},size={320,16},disable=1,proc=FRUSetVarProc,title="Analysis"
	SetVariable AnalysisToApply_SV,limits={-inf,inf,0},value= root:MyForceData:CurrentAnalysis[0][%AnalysisString]
	PopupMenu AnalysisPresets_Popup,pos={210,427},size={254,22},disable=1,proc=FRUPopMenuProc,title="Analysis Presets"
	PopupMenu AnalysisPresets_Popup,mode=2,popvalue="Contour Length Histogram",value= #"\"Rupture Force Histogram;Contour Length Histogram;Rupture Force vs Contour Length;Rupture Force vs Loading Rate\""
	Button ApplyOneAnalysisToFRList_Button,pos={213,466},size={122,30},disable=1,proc=FRUButtonProc,title="Apply This Analysis"
	Button ApplyOneAnalysisToFRList_Button,fColor=(61440,61440,61440)
	Button ApplyAllAnalysisToFRList_Button,pos={404,470},size={122,30},disable=1,proc=FRUButtonProc,title="Apply All Analysis"
	Button ApplyAllAnalysisToFRList_Button,fColor=(61440,61440,61440)
	CheckBox NewFRListByDuplication_CB,pos={206,353},size={136,14},disable=1,proc=FRUCheckProc,title="Duplicate Current FR List"
	CheckBox NewFRListByDuplication_CB,value= 0,mode=1
EndMacro

Function FRUTabProc(tca) : TabControl
	STRUCT WMTabControlAction &tca

	switch( tca.eventCode )
		case 2: // mouse up
			Variable tab = tca.tab
			ListBox FunctionsList_ListBox,disable= (tab!=0)
			SetVariable NameOfFunction_SV,disable= (tab!=0)
			SetVariable FunctionToApply_SV,disable= (tab!=0)
			SetVariable OutputWaveName_SV,disable= (tab!=0)
			Button AddToFunctionsList_Button,disable= (tab!=0)
			Button RemoveFromFunctionsList_Button,disable= (tab!=0)
			SetVariable NumOutputs_SV,disable= (tab!=0)
			Button ApplyAllFuncsToFRList_Button,disable= (tab!=0)
			Button ApplyOneFuncToFRList_Button,disable= (tab!=0)
			PopupMenu FunctionPresets_Popup,disable= (tab!=0)

			ListBox AnalysisList_ListBox,disable= (tab!=1)
			Button AddToAnalysisList_Button,disable= (tab!=1)
			Button RemoveFromAnalysisList_Button,disable= (tab!=1)
			SetVariable NameOfAnalysis_SV,disable= (tab!=1)
			SetVariable AnalysisToApply_SV,disable= (tab!=1)
			Button ApplyOneAnalysisToFRList_Button,disable= (tab!=1)
			Button ApplyAllAnalysisToFRList_Button,disable= (tab!=1)
			PopupMenu AnalysisPresets_Popup,disable= (tab!=1)

			SetVariable NewListByNames_SV,disable= (tab!=2)
			SetVariable NewListByWave_SV,disable= (tab!=2)
			SetVariable NewListName_SV,disable= (tab!=2)
			CheckBox NewFRListByFunction_CB,disable= (tab!=2)
			SetVariable NewListByFunction_SV,disable= (tab!=2)
			CheckBox NewFRListByWave_CB,disable= (tab!=2)
			CheckBox NewFRListByStringName_CB,disable= (tab!=2)
			Button FindWave_Button,disable= (tab!=2)
			Button MakeNewList_Button,disable= (tab!=2)
			CheckBox NewFRListByDuplication_CB,disable= (tab!=2)
		break
		case -1: // control being killed
			break
	endswitch

	return 0
End


/// Here are the functions to export force ramps to external files.  

Function SaveFRListToFile(FRListName)
	String FRListName
	Wave/T SavedFRLists=root:MyForceData:SavedFRLists
	
	SaveForceRamps(SavedFRLists[%$FRListName])
End

Function SaveForceRamps(FRList)
	String FRList
	
	String ParmFolder = ARGetForceFolder("Parameters","","")
	String TempFolder = GetDF("TempRoot")

	String FMapList = "", Pname = "ForceSavePath", UserPathStr = "", JHand = "SaveForceJBar", FPName
	String DataFolderList = "", DataFolder, CtrlName, SrcFolder = "", FPList = "",DataFolderMasterList="",FPMasterList=""
	Variable FileRef, FlushIt, Index, FPIndex, IsSaveAs=0, A=0, nop
	
	SVAR/Z LastMod = $ParmFolder+"LastMod"
	Wave/T ForceLoadDirs = InitOrDefaultTextWave(ParmFolder+"ForceLoadDirs",0)
	
	GetForcePlotsList(2,FPMasterList,DataFolderMasterList)
	Variable NumFR = ItemsInList(FRList,";")

	For (A = 0;A < NumFR;A += 1)
		Variable DataFolderListLoc=WhichListItem(StringFromList(A,FRList,";"), FPMasterList,";")
		DataFolderList+=StringFromList(DataFolderListLoc,DataFolderMasterList,";")+";"
	EndFor

	nop=NumFR
	if (Nop > 10)
		InitJbar(JHand,num2str(nop),"Saving Force Data","","")
	endif
	A=0
	
	for (A = 0;A < nop;A += 1)
		Jbar(JHand,A,0,.03)
		FPName = StringFromList(A,FRList,";")
		DataFolder = StringFromList(A,DataFolderList,";")
		SrcFolder = ARGetForceFolder("",DataFolder,FPName)
		Wave/Z Raw = $SrcFolder+FPName+"Raw"
		FlushIt = !WaveExists(Raw)
		Wave/Z Data = $CompressForceData(DataFolder,FPName,TempFolder+FPName,1,0)		//new header, but no slave data types...
		if (!WaveExists(Data))
			Continue
		endif
		FPIndex = FindDimLabel(ForceLoadDirs,0,DataFolder+FPName)
		if (!IsSaveAs)		//staight save
			if (FPIndex >= 0)
				NewPath/C/O/Q/Z $PName ForceLoadDirs[FPIndex]
			elseif (!Strlen(UserPathStr))
				V_Flag = ARNewPath(Pname,CreateFlag=1,TextStr="Path for Force plot not found, please provide path")
				if (V_Flag || !SafePathInfo(PName))
					continue
				endif
				PathInfo $Pname
				UserPathStr = S_Path
			else
				//set the path
				NewPath/C/O/Q/Z $PName UserPathStr
			endif
		else		//SaveAs
			if (StringMatch(DataFolder,"Memory") || StringMatch(DataFolder,ForceSubFolderCleanUp(LastDir(UserPathStr))))
				NewPath/C/O/Q/Z $PName UserPathStr
			else
				NewPath/C/O/Q/Z $PName UserPathStr+DataFolder
			endif
		endif
		if (FPIndex < 0)
			FPIndex = DimSize(ForceLoadDirs,0)
			InsertPoints/M=0 FPIndex,1,ForceLoadDirs
			SetDimLabel 0,FPIndex,$DataFolder+FPName,ForceLoadDirs
		endif
		//this is redundant for Straight save, when the data was there, but who cares...
		PathInfo $Pname
		ForceLoadDirs[FPIndex] = s_path
		
		Save/C/O/P=$Pname Data as FPName+".ibw"

		//File footer hack
		Open/A/P=$Pname FileRef FPname+".ibw"
		TagFPFooter(FileRef,Data)
		Close(FileRef)
		KillWaves Data
		if (FlushIt)
			SafeKillWaveList(ListMultiply(SrcFolder,ARWaveList(SrcFolder,FPName+"*",";",""),";"),";")
			Wave/Z/T LookupTable = $ParmFolder+DataFolder+"LookUpTable"
			if (WaveExists(LookupTable))
				Index = FindDimLabel(LookupTable,0,FPName)
				if (Index >= 0)
					DeletePoints/M=0 Index,1,LookupTable
				endif
			endif
		endif
	endfor
	UpdateForcePlotsNumbers()
	DoWindow/K $Jhand
	GhostForceModifyPanel()
	
End
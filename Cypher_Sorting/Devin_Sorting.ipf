#pragma rtGlobals=3		// Use modern global access method and strict wave access.
// This function calculates the rupture force, the wave index of the rupture force and the separation the rupture force happens at
Static Constant cForceAnalyzeFolder = 3		//these have to be constants, or switches wont work on them.
Static Constant cForceDeleteSelectedFolder = 5
Static Constant cForceModifyFolder = 6
#include "ForceRampUtilities"

// This function calculates the rupture force, the wave index of the rupture force and the separation the rupture force happens at
//Function/Wave BreakingForceStats(ForceRetWave,SepWave,StartDist,[OffsetWaves])
//	Wave ForceRetWave,SepWave
//	Variable StartDist,OffsetWaves
//	// Create Duplicates that I can offset for proper measurements without messing up any subsequent operations on these waves
//	Duplicate ForceRetWave,ForceRet
//	Duplicate SepWave, SepRet
//	If(!ParamIsDefault(OffsetWaves))
//		OffsetForceRet(ForceRet,10)
//		OffsetSepRet(SepRet)
//		If(OffsetWaves==1)
//			FastOp ForceRet=-1*ForceRet
//		EndIf
//
//	EndIf
//
//	// Figure out the start and end index from the separation wave
//	FindLevel/Q/P SepRet,StartDist
//	Variable StartIndex = Floor(V_LevelX)
//	Variable EndIndex = DimSize(SepWave, 0)
//	
//	// Create a force wave (named testwave) that only includes the segments using the indexes found above
//	Duplicate/O/R=[StartIndex,EndIndex] ForceRet, TestWave
//	WaveStats/Q TestWave
//	Variable ForceMax=V_min-TestWave[numpnts(Testwave)-1]			// Uses the minimum of the segment of the force wave we are looking for
//	Variable ForceMaxLoc=V_minRowLoc+StartIndex  		// The index for this max force is 
//	Variable ForceMax_Sep = SepWave[ForceMaxLoc]-SepRet[0]		// Use the index to find the separation associated with max force
//
//	// Make the output wave and apply the appropriate labels to them.  
//	Make/O/N=3 BreakForceStats
//	BreakForceStats = {ForceMax,ForceMaxLoc,ForceMax_Sep}
//	SetDimLabel 0,0,$"Rupture_Force",BreakForceStats
//	SetDimLabel 0,1,$"Rupture_Index",BreakForceStats
//	SetDimLabel 0,2,$"Rupture_Sep",BreakForceStats
//	 print BreakForceStats
//	 // Get rid of the temp waves to keep things clean in the data folder
//	KillWaves ForceRet,SepRet,TestWave
//	Return BreakForceStats
//End 


Function/Wave DE_PartofPull(ForceRetWave,SepWave,StartDist,[OffsetWaves])
	Wave ForceRetWave,SepWave
	Variable StartDist,OffsetWaves
	Duplicate/O OffsetStats(ForceRetWave,SepWave), NewOffsetStats

	// Create Duplicates that I can offset for proper measurements without messing up any subsequent operations on these waves
	Duplicate/o ForceRetWave,ForceRet,ForceRetO
	Duplicate/o SepWave, SepRet,SepRetO
	variable Foff=NewOffsetStats[0]	
		variable Xoff=NewOffsetStats[1]	

//
	FastOp ForceRet=-1*ForceRet+(Foff)	
	FastOp SepRet=SepRet-(Xoff)
//	If(!ParamIsDefault(OffsetWaves))
//		OffsetForceRet(ForceRet,10)
//		OffsetSepRet(SepRet)
//		If(OffsetWaves==1)
//			FastOp ForceRet=-1*ForceRet
//		EndIf
//
//	EndIf

	// Figure out the start and end index from the separation wave
		String ParmFolder = ARGetForceFolder("Parameters","","")
					string wavefolder,datafolder
					WaveFolder = parmFolder

	Wave/Z/T MasterList = $WaveFolder+"MasterFPList"
	DataFolder = MasterList[0]+";"
	
	
	FindLevel/Q/P SepRet,StartDist
	Variable StartIndex = Floor(V_LevelX)
	Variable EndIndex = DimSize(SepWave, 0)
	
	// Create a force wave (named testwave) that only includes the segments using the indexes found above
	Duplicate/O/R=[StartIndex,EndIndex] ForceRet, TestWave
	
	WaveStats/Q TestWave
	Variable ForceMax=v_max// Uses the minimum of the segment of the force wave we are looking for
	//Variable ForceMax=NewOffsetStats[1]	
	Variable ForceMaxLoc=V_maxRowLoc  		// The index for this max force is 
	Variable ForceMax_Sep = SepWave[ForceMaxLoc]		// Use the index to find the separation associated with max force
//
//	// Make the output wave and apply the appropriate labels to them.  
	String Cfast=stringbykey("Corresponding Fast Pull",note(ForceRetWave),":","\r")
	String CSlow=stringbykey("Corresponding Slow Pull",note(ForceRetWave),":","\r")
	String BaseName, Suffix, DataType, SectionStr
	ExtractForceWaveName(NameOfWave(ForceRetWave),BaseName,Suffix,DataType,SectionStr)
	String svel=stringbykey("RetractVelocity",note(ForceRetWave),":","\r")
	Variable Decision=0
	//if(cmpstr(CFast,"")!=0)
//	Decision=3
//	endif
//	
//	if(abs(ForceMax_Sep)>=95e-9)
//	Decision=1
//
//	endif
	if(cmpstr(CSlow,"")!=0)
	Decision=2
	endif

	if(cmpstr(svel,"0.1")==0&&cmpstr(CFast,"")==0)
	Decision=1
	endif
	
	
	Make/O/N=9 PullStuff
	//CLAnalysis(ForceRet,SepRet,"Devins",TypeOfMolecule="Protein",HistogramThreshold=5e-11,HistogramBinWidth=1e-9,HistogramAverage=1,PeakThreshold=15)
	wave Selected_CLPeakInfo
	PullStuff = {str2num(Suffix),str2num(Cfast),str2num(CSlow),ForceMax,ForceMaxLoc,ForceMax_Sep,str2num(svel),Decision,dimsize(Selected_CLPeakInfo,0)}
	SetDimLabel 0,0,$"Suffix",PullStuff
	SetDimLabel 0,1,$"CFast",PullStuff
	 SetDimLabel 0,2,$"CSlow",PullStuff
	SetDimLabel 0,3,$"ForceMax",PullStuff
	SetDimLabel 0,4,$"ForceMaxLoc",PullStuff
	 SetDimLabel 0,5,$"ForceMax_Sep",PullStuff
	 	 SetDimLabel 0,6,$"Velocity",PullStuff

	SetDimLabel 0,7,$"Decision",PullStuff
	SetDimLabel 0,8,$"PeakNumber",PullStuff

	 // Get rid of the temp waves to keep things clean in the data folder
	//KillWaves ForceRet,SepRet,TestWave,NewOffsetStats
	
	Return PullStuff
End 
Function DE_DeleteSelectedForceCurves(HowMuch,WhichList,FPList, DataFolderList)
	Variable HowMuch		//passed on to KillFPList
	Variable WhichList
	String FPList, DataFolderList

	//if IsFolders, then the selection is done by the folder list.  Otherwise is it from the force plot list.

//Bit 0, ForceCurves...
//Bit 1, Stored Data...		(Not written yet)
//Bit 2, Locks

	DoWindow/K $cARGFGN

		String ParmFolder = ARGetForceFolder("Parameters","","")

	
	//GetForcePlotsList(WhichList,FPList,DataFolderList)

	Variable UpdateUndoButtons = 0


	UpdateUndoButtons = KillFPList(DataFolderList,FPList,HowMuch)
	String DataFolder
	
	Variable MergeIndex
	//String MergedList = ARC_MergeStrLists(DataFolderList,FPList,"")

	UpdateForceList()
	

	String FPName
	//Hijack DataFolder
	SVAR/Z LastParm = $ParmFolder+"LastParm"
	if (SVAR_EXISTS(LastParm))
		FPName = StringByKey("FPName",LastParm,":",";")
		DataFolder = StringByKey("DataFolder",LastParm,":",";")
		MergeIndex = ARC_FindMatchingListIndex(FPList, DataFolderList,";",FPName,DataFolder)
		if (MergeIndex > -1)
			LastParm = ""
			KillStrings/Z LastParm
			UpdateForceParmButtons()
		endif
	endif
	
	
	SVAR/Z LastMod = $ParmFolder+"LastMod"
	if (SVAR_EXISTS(LastMod))
		FPName = StringByKey("FPName",LastMod,":",";")
		DataFolder = StringByKey("DataFolder",LastMod,":",";")
		MergeIndex = ARC_FindMatchingListIndex(FPList, DataFolderList,";",FPName,DataFolder)
		if (MergeIndex > -1)
			LastMod = ""
			KillStrings/Z LastMod
			UpdateUndoButtons = 1
		endif
	endif
	if (UpdateUndoButtons)
		GhostForceModifyPanel()
	endif
	
	
	//Now try to display the next force plot...
	SelectOneForcePlot(IfNone=1)
	HotSwapForceDisplayData(2)		//hot swap will build the graph if not there...
	
	
	//now we need to update the lists of the other types:
	Variable Which, A, nop
	String WaveFolder
	
	for (Which = 3;Which < 10;Which += 1)		//input to GetForcePlotsList
		Switch (Which)
			case cForceAnalyzeFolder:
				WaveFolder = ARGetForceFolder("Data","","")
				break
				
			case cForceModifyFolder:
				WaveFolder = ARGetForceFolder("Parameters:Modify","","")
				break
				
			case cForceDeleteSelectedFolder:
				WaveFolder = ARGetForceFolder("Parameters:Delete","","")
				break
				
			case 4:
			Default:
				Continue
				break
				
		endswitch
	
	
		Wave/Z/T MasterList = $WaveFolder+"MasterFPList"
		if (!WaveExists(MasterList))
			continue
		endif
		Wave MasterBuddy = $WaveFolder+"MasterFPBuddy"
		nop = DimSize(MasterList,0)
		for (A = 0;A < nop;A += 1)
			if (MasterBuddy[A][0][0] & cDFBit)		//DataFolder
				DataFolder = MasterList[A]
			elseif (ARC_FindMatchingListIndex(FPList,DataFolderList,";",MasterList[A],DataFolder) >= 0)
				DeletePoints/M=0 A,1,MasterList,MasterBuddy
				A -= 1
				Nop -=1
			endif
		endfor
			
	endfor
	ErrorCheckFAMInput()
	GhostForceAnalyzePanel()
	
End //DeleteSelectedForceCurves

function/S DE_SearchAndDestroy(RuptureTestWave,MinForce,MaxForce)
wave RuptureTestWave
variable MinForce,MaxForce
string FPList=""
	

		String ParmFolder = ARGetForceFolder("Parameters","","")
					string wavefolder,datafolder
					DataFolder=""
					WaveFolder = parmFolder

	Wave/Z/T MasterList = $WaveFolder+"MasterFPList"
	variable A
	string FolderSingle
FolderSingle=MasterList[0]
string savenum
	for(A=0;A<dimsize(RuptureTestWave,0);A+=1)
	//for(A=0;A<10;A+=1)
	//if(isnan(RuptureTestWave[A][%CFast])!=0&&isnan(RuptureTestWave[A][%CSlow])!=0)

	//	sprintf savenum,"%04.0f",RuptureTestWave[A][%Suffix]
	//	FPList+=Basename+savenum+";"
	//		DataFolder += MasterList[0]+";"
//	if(isnan(RuptureTestWave[A][%CFast])==0&&cmpstr(num2str( RuptureTestWave[A][%Velocity]),"10")!=0)
//			sprintf savenum,"%04.0f",RuptureTestWave[A][%Suffix]
//		FPList+=Basename+savenum+";"
//			sprintf savenum,"%04.0f",RuptureTestWave[A][%Cfast]
//		FPList+=Basename+savenum+";"
//		//FPList+=Basename+num2str(RuptureTestWave[A][%CFast])+";"+Basename+num2str(RuptureTestWave[A][%CFast])+";"
//		DataFolder += MasterList[0]+";"+MasterList[0]+";"
//
//
//endif
	if(RuptureTestWave[A][%ForceMax]<MinForce||RuptureTestWave[A][%ForceMax]>MaxForce)
	print GetDimLabel(RuptureTestWave, 0, A )
		//sprintf savenum,"%04.0f",GetDimLabel(OffsetsTest, 0, 0 )
	//	FPList+=Basename+savenum+";"
FPList+=GetDimLabel(RuptureTestWave, 0, A )+";"
		//FPList+=Basename+num2str(RuptureTestWave[A][%CFast])+";"+Basename+num2str(RuptureTestWave[A][%CFast])+";"
		DataFolder += MasterList[0]+";"


endif

	endfor
	//print DataFolder
	//print FPLIST
	DE_DeleteSelectedForceCurves(5,0,FPList, DataFolder)
return FPList
end

Function GenerateRupStats()

	wave w1=offsetsTest
	make/o/n=(dimsize(w1,0)) ForceMax
	ForceMax[]=w1[p][3]
	
	Make/N=200/O ForceMax_Hist;DelayUpdate
	Histogram/P/C/Cum/B={0,20e-012,200} ForceMax,ForceMax_Hist
	display ForceMax_Hist
ModifyGraph log=1
end

Menu "Force Ramp Utilities"
	"Make Histogram", GenerateRupStats()

	
End
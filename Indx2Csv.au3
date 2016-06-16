#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\..\..\Program Files (x86)\autoit-v3.3.14.2\Icons\au3.ico
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Decode INDX records of type $I30
#AutoIt3Wrapper_Res_Description=Decode INDX records of type $I30
#AutoIt3Wrapper_Res_Fileversion=1.0.0.2
#AutoIt3Wrapper_Res_LegalCopyright=Joakim Schicht
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;Program assumes input file like IndxCarver creates.
#Include <WinAPIEx.au3>
#Include <File.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#Include <FileConstants.au3>
Global $de="|", $PrecisionSeparator=".", $PrecisionSeparator2="",$DateTimeFormat, $TimestampPrecision,$IndxEntriesCsvFile,$IndxEntriesCsv,$CurrentFileOffset,$UTCconfig,$myctredit,$SeparatorInput
Global $TimestampErrorVal = "0000-00-00 00:00:00",$ExampleTimestampVal = "01CD74B3150770B8"
Global $DoDefaultAll, $dol2t, $DoBodyfile, $DebugOutFile, $MaxRecords, $CurrentRecord, $WithQuotes, $EncodingWhenOpen = 2, $DoParseSlack=1, $DoFixups=1
Global $CheckSlack,$CheckFixups,$CheckUnicode,$checkquotes
Global $begin, $ElapsedTime, $EntryCounter, $DoScanMode1=0, $DoScanMode2=0, $DoNormalMode=1, $SectorSize=512
Global $ProgressStatus, $ProgressIndx
Global $RecordOffset,$IndxLastLsn,$FromIndxSlack,$MFTReference,$MFTReferenceSeqNo,$IndexFlags,$MFTReferenceOfParent,$MFTReferenceOfParentSeqNo
Global $Indx_CTime,$Indx_ATime,$Indx_MTime,$Indx_RTime,$Indx_AllocSize,$Indx_RealSize,$Indx_File_Flags,$Indx_ReparseTag,$Indx_FileName,$Indx_NameSpace,$SubNodeVCN,$TextInformation
Global $SkipUnicodeNames = 1 ;Will improve recovery of entries from slack
Global $_COMMON_KERNEL32DLL=DllOpen("kernel32.dll"),$outputpath=@ScriptDir,$ParserOutDir
Global $INDXsig = "494E4458", $INDX_Size = 4096, $BinaryFragment
Global $tDelta = _WinTime_GetUTCToLocalFileTimeDelta()

$Progversion = "Indx2Csv 1.0.0.2"
If $cmdline[0] > 0 Then
	$CommandlineMode = 1
	ConsoleWrite($Progversion & @CRLF)
	_GetInputParams()
	_Main()
Else
	DllCall("kernel32.dll", "bool", "FreeConsole")
	$CommandlineMode = 0

	$Form = GUICreate($Progversion, 540, 350, -1, -1)

	$LabelTimestampFormat = GUICtrlCreateLabel("Timestamp format:",20,20,90,20)
	$ComboTimestampFormat = GUICtrlCreateCombo("", 110, 20, 30, 25)
	$LabelTimestampPrecision = GUICtrlCreateLabel("Precision:",150,20,50,20)
	$ComboTimestampPrecision = GUICtrlCreateCombo("", 200, 20, 70, 25)

	$LabelPrecisionSeparator = GUICtrlCreateLabel("Precision separator:",280,20,100,20)
	$PrecisionSeparatorInput = GUICtrlCreateInput($PrecisionSeparator,380,20,15,20)
	$LabelPrecisionSeparator2 = GUICtrlCreateLabel("Precision separator2:",400,20,100,20)
	$PrecisionSeparatorInput2 = GUICtrlCreateInput($PrecisionSeparator2,505,20,15,20)

	$InputExampleTimestamp = GUICtrlCreateInput("",340,45,190,20)
	GUICtrlSetState($InputExampleTimestamp, $GUI_DISABLE)

	$Label1 = GUICtrlCreateLabel("Set decoded timestamps to specific region:",20,45,230,20)
	$Combo2 = GUICtrlCreateCombo("", 230, 45, 85, 25)

	$LabelSeparator = GUICtrlCreateLabel("Set separator:",20,70,70,20)
	$SeparatorInput = GUICtrlCreateInput($de,90,70,20,20)
	$SeparatorInput2 = GUICtrlCreateInput($de,120,70,30,20)
	GUICtrlSetState($SeparatorInput2, $GUI_DISABLE)
	$checkquotes = GUICtrlCreateCheckbox("Quotation mark", 160, 70, 90, 20)
	GUICtrlSetState($checkquotes, $GUI_UNCHECKED)
	$CheckUnicode = GUICtrlCreateCheckbox("Unicode", 255, 70, 60, 20)
	GUICtrlSetState($CheckUnicode, $GUI_UNCHECKED)
	$CheckSlack = GUICtrlCreateCheckbox("Slack", 320, 70, 60, 20)
	GUICtrlSetState($CheckSlack, $GUI_UNCHECKED)
	$CheckFixups = GUICtrlCreateCheckbox("Apply fixups", 320, 95, 75, 20)
	GUICtrlSetState($CheckFixups, $GUI_CHECKED)

	$checkl2t = GUICtrlCreateCheckbox("log2timeline", 20, 100, 130, 20)
	GUICtrlSetState($checkl2t, $GUI_UNCHECKED)
	GUICtrlSetState($checkl2t, $GUI_DISABLE)
	$checkbodyfile = GUICtrlCreateCheckbox("bodyfile", 20, 120, 130, 20)
	GUICtrlSetState($checkbodyfile, $GUI_UNCHECKED)
	GUICtrlSetState($checkbodyfile, $GUI_DISABLE)
	$checkdefaultall = GUICtrlCreateCheckbox("dump everything", 20, 140, 130, 20)
	GUICtrlSetState($checkdefaultall, $GUI_CHECKED)
	GUICtrlSetState($checkdefaultall, $GUI_DISABLE)

	$LabelBrokenData = GUICtrlCreateLabel("Broken data:",130,100,65,20)
	$CheckScanMode1 = GUICtrlCreateCheckbox("Scan mode 1", 200, 100, 80, 20)
	GUICtrlSetState($CheckScanMode1, $GUI_UNCHECKED)
	GUICtrlSetState($CheckScanMode1, $GUI_DISABLE)
	$CheckScanMode2 = GUICtrlCreateCheckbox("Scan mode 2", 200, 120, 80, 20)
	GUICtrlSetState($CheckScanMode2, $GUI_UNCHECKED)
	GUICtrlSetState($CheckScanMode2, $GUI_DISABLE)

	$LabelUsnPageSize = GUICtrlCreateLabel("INDX Size:",130,145,70,20)
	$IndxSizeInput = GUICtrlCreateInput($INDX_Size,200,145,40,20)

	$LabelTimestampError = GUICtrlCreateLabel("Timestamp ErrorVal:",290,145,100,20)
	$TimestampErrorInput = GUICtrlCreateInput($TimestampErrorVal,390,145,130,20)

	$ButtonOutput = GUICtrlCreateButton("Change Output", 420, 70, 100, 20)
	$ButtonInput = GUICtrlCreateButton("Browse INDX", 420, 95, 100, 20)
	$ButtonStart = GUICtrlCreateButton("Start Parsing", 420, 120, 100, 20)
	$myctredit = GUICtrlCreateEdit("", 0, 170, 540, 100, BitOR($ES_AUTOVSCROLL,$WS_VSCROLL))
	_GUICtrlEdit_SetLimitText($myctredit, 128000)

	_InjectTimeZoneInfo()
	_InjectTimestampFormat()
	_InjectTimestampPrecision()
	$PrecisionSeparator = GUICtrlRead($PrecisionSeparatorInput)
	$PrecisionSeparator2 = GUICtrlRead($PrecisionSeparatorInput2)
	_TranslateTimestamp()

	GUISetState(@SW_SHOW)

	While 1
		$nMsg = GUIGetMsg()
		Sleep(50)
		_TranslateSeparator()
		$PrecisionSeparator = GUICtrlRead($PrecisionSeparatorInput)
		$PrecisionSeparator2 = GUICtrlRead($PrecisionSeparatorInput2)
		_TranslateTimestamp()
		Select
			Case $nMsg = $ButtonOutput
				$newoutputpath = FileSelectFolder("Select output folder.", "",7,$outputpath)
				If Not @error then
					_DisplayInfo("New output folder: " & $newoutputpath & @CRLF)
					$ParserOutDir = $newoutputpath
				EndIf
			Case $nMsg = $ButtonInput
				$BinaryFragment = FileOpenDialog("Select INDX extracted chunk",@ScriptDir,"All (*.*)")
				If Not @error Then _DisplayInfo("Input: " & $BinaryFragment & @CRLF)
			Case $nMsg = $ButtonStart
				_Main()
			Case $nMsg = $GUI_EVENT_CLOSE
				Exit
		EndSelect
	WEnd
EndIf

Func _Main()
	Local $nBytes
	If Not FileExists($BinaryFragment) Then
		ConsoleWrite("Error could not locate input" & @CRLF)
	EndIf
	$hFile = _WinAPI_CreateFile("\\.\" & $BinaryFragment,2,2,7)
	If $hFile = 0 Then
		ConsoleWrite("CreateFile: " & _WinAPI_GetLastErrorMessage() & @CRLF)
		Exit
	EndIf

	$TimestampStart = @YEAR & "-" & @MON & "-" & @MDAY & "_" & @HOUR & "-" & @MIN & "-" & @SEC

	If Not FileExists($ParserOutDir) Then
		$ParserOutDir = @ScriptDir
	EndIf
;	ConsoleWrite("Output directory: " & $ParserOutDir & @CRLF)
	$IndxEntriesCsvFile = $ParserOutDir & "\Indx_I30_Entries_" & $TimestampStart & ".csv"
	$IndxEntriesCsv = FileOpen($IndxEntriesCsvFile, $EncodingWhenOpen)
	If @error Then
		ConsoleWrite("Error creating: " & $IndxEntriesCsvFile & @CRLF)
		If Not $CommandlineMode Then _DisplayInfo("Error creating: " & $IndxEntriesCsvFile & @CRLF)
		Return
	EndIf
;	ConsoleWrite("Created output file: " & $IndxEntriesCsvFile & @CRLF)

	$DebugOutFile = FileOpen($ParserOutDir & "\Indx_I30_Entries_" & $TimestampStart & ".log", $EncodingWhenOpen)
	If @error Then
		ConsoleWrite("Error: Could not create log file" & @CRLF)
		MsgBox(0,"Error","Could not create log file")
		Exit
	EndIf

	_DumpOutput("Input file: " & $BinaryFragment & @CRLF)
	_DumpOutput("Output directory: " & $ParserOutDir & @CRLF)
	_DumpOutput("Csv: " & $IndxEntriesCsvFile & @CRLF)

;---------------------
	If Not $CommandlineMode Then
		If Int(GUICtrlRead($checkl2t) + GUICtrlRead($checkbodyfile) + GUICtrlRead($checkdefaultall)) <> 9 Then
			_DisplayInfo("Error: Output format can only be one of the options (not more than 1)." & @CRLF)
			Return
		EndIf
		If GUICtrlRead($checkl2t) = 1 Then
			$Dol2t = True
		ElseIf GUICtrlRead($checkbodyfile) = 1 Then
			$DoBodyfile = True
		ElseIf GUICtrlRead($checkdefaultall) = 1 Then
			$DoDefaultAll = True
		EndIf
	EndIf

	If Not $CommandlineMode Then
		$TimestampErrorVal = GUICtrlRead($TimestampErrorInput)
	Else
		$TimestampErrorVal = $TimestampErrorVal
	EndIf

	If Not $CommandlineMode Then
		$INDX_Size = GUICtrlRead($IndxSizeInput)
	EndIf
	If Mod($INDX_Size,512) Then
		If Not $CommandlineMode Then
			_DisplayInfo("Error: INDX size must be a multiple of 512" & @CRLF)
			_DumpOutput("Error: INDX size must be a multiple of 512" & @CRLF)
			Return
		Else
			_DumpOutput("Error: INDX size must be a multiple of 512" & @CRLF)
			Exit
		EndIf
	EndIf

	If Not $CommandlineMode Then
		$tDelta = _GetUTCRegion(GUICtrlRead($Combo2))-$tDelta
		If @error Then
			_DisplayInfo("Error: Timezone configuration failed." & @CRLF)
			Return
		EndIf
		$tDelta = $tDelta*-1 ;Since delta is substracted from timestamp later on
	EndIf

	If $CommandlineMode Then
		$TestUnicode = $CheckUnicode
	Else
		$TestUnicode = GUICtrlRead($CheckUnicode)
	EndIf
	If $TestUnicode = 1 Then
		;$EncodingWhenOpen = 2+32 ;ucs2
		$EncodingWhenOpen = 2+128 ;utf8 w/bom
;		If Not $CommandlineMode Then _DisplayInfo("UNICODE configured" & @CRLF)
		_DumpOutput("UNICODE configured" & @CRLF)
		$SkipUnicodeNames=0
	Else
		$EncodingWhenOpen = 2
;		If Not $CommandlineMode Then _DisplayInfo("ANSI configured" & @CRLF)
		_DumpOutput("ANSI configured" & @CRLF)
		$SkipUnicodeNames=1
	EndIf

	If $CommandlineMode Then
		$DoParseSlack = $CheckSlack
	Else
		$DoParseSlack = GUICtrlRead($CheckSlack)
	EndIf
	If $DoParseSlack = 1 Then
		$DoParseSlack = 1
	Else
		$DoParseSlack = 0
	EndIf
	_DumpOutput("Scanning slack: " & $DoParseSlack & @CRLF)

	If $CommandlineMode Then
		$DoFixups = $CheckFixups
	Else
		$DoFixups = GUICtrlRead($CheckFixups)
	EndIf
	If $DoFixups = 1 Then
		$DoFixups = 1
	Else
		$DoFixups = 0
	EndIf
	_DumpOutput("Apply fixups: " & $DoFixups & @CRLF)

	If $CommandlineMode Then
		$PrecisionSeparator = $PrecisionSeparator
		$PrecisionSeparator2 = $PrecisionSeparator2
	Else
		$PrecisionSeparator = GUICtrlRead($PrecisionSeparatorInput)
		$PrecisionSeparator2 = GUICtrlRead($PrecisionSeparatorInput2)
	EndIf
	If StringLen($PrecisionSeparator) <> 1 Then
		If Not $CommandlineMode Then _DisplayInfo("Error: Precision separator not set properly" & @crlf)
		_DumpOutput("Error: Precision separator not set properly" & @crlf)
		Return
	EndIf

	If $CommandlineMode Then
		$WithQuotes = $checkquotes
	Else
		$WithQuotes = GUICtrlRead($checkquotes)
	EndIf

	If $WithQuotes = 1 Then
		$WithQuotes=1
	Else
		$WithQuotes=0
	EndIf

	If Not FileExists($BinaryFragment) Then
		If Not $CommandlineMode Then _DisplayInfo("Error: No INDX chunk chosen for input" & @CRLF)
		_DumpOutput("Error: No INDX chunk chosen for input" & @CRLF)
		Return
	EndIf

	If Not $CommandlineMode Then
		If GUICtrlRead($CheckScanMode1) = 1 And GUICtrlRead($CheckScanMode2) = 1 Then
			_DisplayInfo("Error: only 1 scan mode possible" & @CRLF)
			Return
		EndIf

		If GUICtrlRead($CheckScanMode1) = 1 Then
			$DoScanMode1 = 1
			$DoNormalMode = 0
		EndIf

		If GUICtrlRead($CheckScanMode2) = 1 Then
			$DoScanMode2 = 1
			$DoNormalMode = 0
		EndIf
	EndIf

	If $DoScanMode1=0 And $DoScanMode2=0 Then
		$DoNormalMode=1
	EndIf

	$IndxI30SqlFile = $ParserOutDir & "\Indx_I30_Entries_" & $TimestampStart & ".sql"
	FileInstall("C:\temp\import-csv-INDX-I30.sql", $IndxI30SqlFile)
	$FixedPath = StringReplace($IndxEntriesCsvFile,"\","\\")
	Sleep(500)
	_ReplaceStringInFile($IndxI30SqlFile,"__PathToCsv__",$FixedPath)
	If $TestUnicode = 1 Then _ReplaceStringInFile($IndxI30SqlFile,"latin1", "utf8")

	_DumpOutput("Normal mode: " & $DoNormalMode & @CRLF)
	_DumpOutput("Scan mode 1: " & $DoScanMode1 & @CRLF)
	_DumpOutput("Scan mode 2: " & $DoScanMode2 & @CRLF)
;----------------------------

	_WriteCSVHeaderIndxEntries()
	$InputFileSize = _WinAPI_GetFileSizeEx($hFile)
	$MaxRecords = Ceiling($InputFileSize/$INDX_Size)
	If Mod($InputFileSize,$INDX_Size) Then
		ConsoleWrite("Error: File size not a multiple of INDX size. Last page must have special buffer created." & @CRLF)
	EndIf
	$tBuffer = DllStructCreate("byte["&$INDX_Size&"]")

	$Progress = GUICtrlCreateLabel("Decoding INDX data and writing to csv", 10, 280,540,20)
	GUICtrlSetFont($Progress, 12)
	$ProgressStatus = GUICtrlCreateLabel("", 10, 275, 520, 20)
	$ElapsedTime = GUICtrlCreateLabel("", 10, 290, 520, 20)
	$ProgressIndx = GUICtrlCreateProgress(0,  315, 540, 30)
	$begin = TimerInit()

	AdlibRegister("_IndxProgress", 500)
	ConsoleWrite("Parsing input.." & @CRLF)

	For $i = 0 To $MaxRecords-1
		$CurrentRecord = $i
		_WinAPI_SetFilePointerEx($hFile, $i*$INDX_Size, $FILE_BEGIN)
		_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), $INDX_Size, $nBytes)
		$IndxRecord = DllStructGetData($tBuffer, 1)
		$CurrentFileOffset = DllCall('kernel32.dll', 'int', 'SetFilePointerEx', 'ptr', $hFile, 'int64', 0, 'int64*', 0, 'dword', 1)
		$CurrentFileOffset = $CurrentFileOffset[3]-$INDX_Size
		$RecordOffset = "0x" & Hex(Int($CurrentFileOffset))
		$ParseStatus = _ParseIndx($IndxRecord)
		_ClearVar()
	Next

	AdlibUnRegister("_IndxProgress")
	$MaxRecords = $CurrentRecord+1
	_IndxProgress()
	ProgressOff()

	If Not $CommandlineMode Then _DisplayInfo("Entries parsed: " & $EntryCounter & @CRLF)
	_DumpOutput("Pages processed: " & $MaxRecords & @CRLF)
	_DumpOutput("Entries parsed: " & $EntryCounter & @CRLF)
	If Not $CommandlineMode Then _DisplayInfo("Parsing finished in " & _WinAPI_StrFromTimeInterval(TimerDiff($begin)) & @CRLF)
	_DumpOutput("Parsing finished in " & _WinAPI_StrFromTimeInterval(TimerDiff($begin)) & @CRLF)
	_WinAPI_CloseHandle($hFile)
	FileFlush($IndxEntriesCsvFile)
	FileClose($IndxEntriesCsvFile)
	$ParserOutDir = ""
	$EntryCounter = 0
EndFunc

Func _WriteCSVHeaderIndxEntries()
	$Indx_Csv_Header = "Offset"&$de&"LastLsn"&$de&"FromIndxSlack"&$de&"FileName"&$de&"MFTReference"&$de&"MFTReferenceSeqNo"&$de&"IndexFlags"&$de&"MFTParentReference"&$de&"MFTParentReferenceSeqNo"&$de&"CTime"&$de&"ATime"&$de&"MTime"&$de&"RTime"&$de&"AllocSize"&$de&"RealSize"&$de&"FileFlags"&$de&"ReparseTag"&$de&"NameSpace"&$de&"SubNodeVCN"&$de&"TextInformation"
	FileWriteLine($IndxEntriesCsvFile, $Indx_Csv_Header & @CRLF)
EndFunc

Func _ParseCoreValidData($InputData)
	Local $LocalOffset = 1, $SubNodeVCN
;	ConsoleWrite("_ParseCoreData():" & @crlf)
;	ConsoleWrite(_HexEncode("0x"&$InputData) & @crlf)
	While 1
		$RecordOffset = "0x" & Hex(Int($CurrentFileOffset + (($LocalOffset-1)/2)))
		$MFTReference = StringMid($InputData,$LocalOffset,12)
		$MFTReference = Dec(_SwapEndian($MFTReference),2)
		$MFTReferenceSeqNo = StringMid($InputData,$LocalOffset+12,4)
		$MFTReferenceSeqNo = Dec(_SwapEndian($MFTReferenceSeqNo),2)
		$IndexEntryLength = StringMid($InputData,$LocalOffset+16,4)
		$IndexEntryLength = Dec(_SwapEndian($IndexEntryLength),2)
		$OffsetToFileName = StringMid($InputData,$LocalOffset+20,4)
		$OffsetToFileName = Dec(_SwapEndian($OffsetToFileName),2)
		$IndexFlags = StringMid($InputData,$LocalOffset+24,4)
		$IndexFlags = Dec(_SwapEndian($IndexFlags),2)
		$Padding = StringMid($InputData,$LocalOffset+28,4)
		$MFTReferenceOfParent = StringMid($InputData,$LocalOffset+32,12)
		$MFTReferenceOfParent = Dec(_SwapEndian($MFTReferenceOfParent),2)
		$MFTReferenceOfParentSeqNo = StringMid($InputData,$LocalOffset+44,4)
		$MFTReferenceOfParentSeqNo = Dec(_SwapEndian($MFTReferenceOfParentSeqNo),2)

		$Indx_CTime = StringMid($InputData, $LocalOffset + 48, 16)
		$Indx_CTime = _SwapEndian($Indx_CTime)
		$Indx_CTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_CTime)
		$Indx_CTime = _WinTime_UTCFileTimeFormat(Dec($Indx_CTime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
		If @error Then
			$Indx_CTime = $TimestampErrorVal
		ElseIf $TimestampPrecision = 2 Then
			$Indx_CTime_Core = StringMid($Indx_CTime,1,StringLen($Indx_CTime)-4)
			$Indx_CTime_Precision = StringRight($Indx_CTime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_CTime = $Indx_CTime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_CTime_tmp, 4))
			$Indx_CTime_Core = StringMid($Indx_CTime,1,StringLen($Indx_CTime)-9)
			$Indx_CTime_Precision = StringRight($Indx_CTime,8)
		Else
			$Indx_CTime_Core = $Indx_CTime
		EndIf
		;
		$Indx_ATime = StringMid($InputData, $LocalOffset + 64, 16)
		$Indx_ATime = _SwapEndian($Indx_ATime)
		$Indx_ATime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_ATime)
		$Indx_ATime = _WinTime_UTCFileTimeFormat(Dec($Indx_ATime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
		If @error Then
			$Indx_ATime = $TimestampErrorVal
		ElseIf $TimestampPrecision = 2 Then
			$Indx_ATime_Core = StringMid($Indx_ATime,1,StringLen($Indx_ATime)-4)
			$Indx_ATime_Precision = StringRight($Indx_ATime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_ATime = $Indx_ATime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_ATime_tmp, 4))
			$Indx_ATime_Core = StringMid($Indx_ATime,1,StringLen($Indx_ATime)-9)
			$Indx_ATime_Precision = StringRight($Indx_ATime,8)
		Else
			$Indx_ATime_Core = $Indx_ATime
		EndIf
		;
		$Indx_MTime = StringMid($InputData, $LocalOffset + 80, 16)
		$Indx_MTime = _SwapEndian($Indx_MTime)
		$Indx_MTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_MTime)
		$Indx_MTime = _WinTime_UTCFileTimeFormat(Dec($Indx_MTime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
		If @error Then
			$Indx_MTime = $TimestampErrorVal
		ElseIf $TimestampPrecision = 2 Then
			$Indx_MTime_Core = StringMid($Indx_MTime,1,StringLen($Indx_MTime)-4)
			$Indx_MTime_Precision = StringRight($Indx_MTime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_MTime = $Indx_MTime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_MTime_tmp, 4))
			$Indx_MTime_Core = StringMid($Indx_MTime,1,StringLen($Indx_MTime)-9)
			$Indx_MTime_Precision = StringRight($Indx_MTime,8)
		Else
			$Indx_MTime_Core = $Indx_MTime
		EndIf
		;
		$Indx_RTime = StringMid($InputData, $LocalOffset + 96, 16)
		$Indx_RTime = _SwapEndian($Indx_RTime)
		$Indx_RTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_RTime)
		$Indx_RTime = _WinTime_UTCFileTimeFormat(Dec($Indx_RTime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
		If @error Then
			$Indx_RTime = $TimestampErrorVal
		ElseIf $TimestampPrecision = 2 Then
			$Indx_RTime_Core = StringMid($Indx_RTime,1,StringLen($Indx_RTime)-4)
			$Indx_RTime_Precision = StringRight($Indx_RTime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_RTime = $Indx_RTime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_RTime_tmp, 4))
			$Indx_RTime_Core = StringMid($Indx_RTime,1,StringLen($Indx_RTime)-9)
			$Indx_RTime_Precision = StringRight($Indx_RTime,8)
		Else
			$Indx_RTime_Core = $Indx_RTime
		EndIf
		;
		$Indx_AllocSize = StringMid($InputData,$LocalOffset+112,16)
		$Indx_AllocSize = Dec(_SwapEndian($Indx_AllocSize),2)
		$Indx_RealSize = StringMid($InputData,$LocalOffset+128,16)
		$Indx_RealSize = Dec(_SwapEndian($Indx_RealSize),2)
		$Indx_File_Flags = StringMid($InputData,$LocalOffset+144,8)
		$Indx_File_Flags = _SwapEndian($Indx_File_Flags)
		$Indx_File_Flags = _File_Attributes("0x" & $Indx_File_Flags)
		$Indx_ReparseTag = StringMid($InputData,$LocalOffset+152,8)
		$Indx_ReparseTag = _SwapEndian($Indx_ReparseTag)
		$Indx_ReparseTag = _GetReparseType("0x"&$Indx_ReparseTag)
		$Indx_NameLength = StringMid($InputData,$LocalOffset+160,2)
		$Indx_NameLength = Dec($Indx_NameLength)
		$Indx_NameSpace = StringMid($InputData,$LocalOffset+162,2)
		Select
			Case $Indx_NameSpace = "00"	;POSIX
				$Indx_NameSpace = "POSIX"
			Case $Indx_NameSpace = "01"	;WIN32
				$Indx_NameSpace = "WIN32"
			Case $Indx_NameSpace = "02"	;DOS
				$Indx_NameSpace = "DOS"
			Case $Indx_NameSpace = "03"	;DOS+WIN32
				$Indx_NameSpace = "DOS+WIN32"
			Case Else
				$Indx_NameSpace = "Unknown"
		EndSelect
		$Indx_FileName = StringMid($InputData,$LocalOffset+164,$Indx_NameLength*4)
		$Indx_FileName = BinaryToString("0x"&$Indx_FileName,2)

		If $LocalOffset >= StringLen($InputData) Then ExitLoop

		If $MFTReferenceSeqNo > 0 And $MFTReferenceOfParent > 4 And $Indx_NameLength > 0  And $Indx_CTime<>$TimestampErrorVal And $Indx_ATime<>$TimestampErrorVal And $Indx_MTime<>$TimestampErrorVal And $Indx_RTime<>$TimestampErrorVal Then
			FileWriteLine($IndxEntriesCsvFile, $RecordOffset & $de & $IndxLastLsn & $de & $FromIndxSlack & $de & $Indx_FileName & $de & $MFTReference & $de & $MFTReferenceSeqNo & $de & $IndexFlags & $de & $MFTReferenceOfParent & $de & $MFTReferenceOfParentSeqNo & $de & $Indx_CTime & $de & $Indx_ATime & $de & $Indx_MTime & $de & $Indx_RTime & $de & $Indx_AllocSize & $de & $Indx_RealSize & $de & $Indx_File_Flags & $de & $Indx_ReparseTag & $de & $Indx_NameSpace & $de & $SubNodeVCN & $de & $TextInformation & @crlf)
			$LocalOffset += $IndexEntryLength*2
			$EntryCounter+=1
			_ClearVar()
			ContinueLoop
		Else
;			ConsoleWrite("Error: Validation of entry failed." & @CRLF)
			Return 0
		EndIf
		_ClearVar()
	WEnd
EndFunc

Func _ParseCoreSlackSpace($InputData,$SkeewedOffset)
	Local $LocalOffset = 1, $SubNodeVCN
	$IndxLastLsn = -1
;	ConsoleWrite("_ParseCoreSlackSpace():" & @crlf)
;	ConsoleWrite(_HexEncode("0x"&$InputData) & @crlf)
	While 1
		$FileNameHealthy=0
		$RecordOffset = "0x" & Hex(Int($CurrentFileOffset + (($SkeewedOffset+$LocalOffset-1)/2)))
		$MFTReference = StringMid($InputData,$LocalOffset,12)
		$MFTReference = Dec(_SwapEndian($MFTReference),2)
		$MFTReferenceSeqNo = StringMid($InputData,$LocalOffset+12,4)
		$MFTReferenceSeqNo = Dec(_SwapEndian($MFTReferenceSeqNo),2)
		$IndexEntryLength = StringMid($InputData,$LocalOffset+16,4)
		$IndexEntryLength = Dec(_SwapEndian($IndexEntryLength),2)
		$OffsetToFileName = StringMid($InputData,$LocalOffset+20,4)
		$OffsetToFileName = Dec(_SwapEndian($OffsetToFileName),2)
		$IndexFlags = StringMid($InputData,$LocalOffset+24,4)
		$IndexFlags = Dec(_SwapEndian($IndexFlags),2)
		$Padding = StringMid($InputData,$LocalOffset+28,4)
		$MFTReferenceOfParent = StringMid($InputData,$LocalOffset+32,12)
		$MFTReferenceOfParent = Dec(_SwapEndian($MFTReferenceOfParent),2)
		$MFTReferenceOfParentSeqNo = StringMid($InputData,$LocalOffset+44,4)
		$MFTReferenceOfParentSeqNo = Dec(_SwapEndian($MFTReferenceOfParentSeqNo),2)

		$Indx_CTime = StringMid($InputData, $LocalOffset + 48, 16)
		$Indx_CTime = _SwapEndian($Indx_CTime)
		$Indx_CTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_CTime)
		$Indx_CTime = _WinTime_UTCFileTimeFormat(Dec($Indx_CTime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
		If @error Then
			$Indx_CTime = $TimestampErrorVal
		ElseIf $TimestampPrecision = 2 Then
			$Indx_CTime_Core = StringMid($Indx_CTime,1,StringLen($Indx_CTime)-4)
			$Indx_CTime_Precision = StringRight($Indx_CTime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_CTime = $Indx_CTime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_CTime_tmp, 4))
			$Indx_CTime_Core = StringMid($Indx_CTime,1,StringLen($Indx_CTime)-9)
			$Indx_CTime_Precision = StringRight($Indx_CTime,8)
		Else
			$Indx_CTime_Core = $Indx_CTime
		EndIf
		;
		$Indx_ATime = StringMid($InputData, $LocalOffset + 64, 16)
		$Indx_ATime = _SwapEndian($Indx_ATime)
		$Indx_ATime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_ATime)
		$Indx_ATime = _WinTime_UTCFileTimeFormat(Dec($Indx_ATime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
		If @error Then
			$Indx_ATime = $TimestampErrorVal
		ElseIf $TimestampPrecision = 2 Then
			$Indx_ATime_Core = StringMid($Indx_ATime,1,StringLen($Indx_ATime)-4)
			$Indx_ATime_Precision = StringRight($Indx_ATime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_ATime = $Indx_ATime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_ATime_tmp, 4))
			$Indx_ATime_Core = StringMid($Indx_ATime,1,StringLen($Indx_ATime)-9)
			$Indx_ATime_Precision = StringRight($Indx_ATime,8)
		Else
			$Indx_ATime_Core = $Indx_ATime
		EndIf
		;
		$Indx_MTime = StringMid($InputData, $LocalOffset + 80, 16)
		$Indx_MTime = _SwapEndian($Indx_MTime)
		$Indx_MTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_MTime)
		$Indx_MTime = _WinTime_UTCFileTimeFormat(Dec($Indx_MTime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
		If @error Then
			$Indx_MTime = $TimestampErrorVal
		ElseIf $TimestampPrecision = 2 Then
			$Indx_MTime_Core = StringMid($Indx_MTime,1,StringLen($Indx_MTime)-4)
			$Indx_MTime_Precision = StringRight($Indx_MTime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_MTime = $Indx_MTime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_MTime_tmp, 4))
			$Indx_MTime_Core = StringMid($Indx_MTime,1,StringLen($Indx_MTime)-9)
			$Indx_MTime_Precision = StringRight($Indx_MTime,8)
		Else
			$Indx_MTime_Core = $Indx_MTime
		EndIf
		;
		$Indx_RTime = StringMid($InputData, $LocalOffset + 96, 16)
		$Indx_RTime = _SwapEndian($Indx_RTime)
		$Indx_RTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_RTime)
		$Indx_RTime = _WinTime_UTCFileTimeFormat(Dec($Indx_RTime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
		If @error Then
			$Indx_RTime = $TimestampErrorVal
		ElseIf $TimestampPrecision = 2 Then
			$Indx_RTime_Core = StringMid($Indx_RTime,1,StringLen($Indx_RTime)-4)
			$Indx_RTime_Precision = StringRight($Indx_RTime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_RTime = $Indx_RTime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_RTime_tmp, 4))
			$Indx_RTime_Core = StringMid($Indx_RTime,1,StringLen($Indx_RTime)-9)
			$Indx_RTime_Precision = StringRight($Indx_RTime,8)
		Else
			$Indx_RTime_Core = $Indx_RTime
		EndIf
		;
		$Indx_AllocSize = StringMid($InputData,$LocalOffset+112,16)
		$Indx_AllocSize = Dec(_SwapEndian($Indx_AllocSize),2)
		$Indx_RealSize = StringMid($InputData,$LocalOffset+128,16)
		$Indx_RealSize = Dec(_SwapEndian($Indx_RealSize),2)
		$Indx_File_Flags = StringMid($InputData,$LocalOffset+144,8)
		$Indx_File_Flags = _SwapEndian($Indx_File_Flags)
		$Indx_File_Flags = _File_Attributes("0x" & $Indx_File_Flags)
		$Indx_ReparseTag = StringMid($InputData,$LocalOffset+152,8)
		$Indx_ReparseTag = _SwapEndian($Indx_ReparseTag)
		$Indx_ReparseTag = _GetReparseType("0x"&$Indx_ReparseTag)
		$Indx_NameLength = StringMid($InputData,$LocalOffset+160,2)
		$Indx_NameLength = Dec($Indx_NameLength)
		$Indx_NameSpace = StringMid($InputData,$LocalOffset+162,2)
		Select
			Case $Indx_NameSpace = "00"	;POSIX
				$Indx_NameSpace = "POSIX"
			Case $Indx_NameSpace = "01"	;WIN32
				$Indx_NameSpace = "WIN32"
			Case $Indx_NameSpace = "02"	;DOS
				$Indx_NameSpace = "DOS"
			Case $Indx_NameSpace = "03"	;DOS+WIN32
				$Indx_NameSpace = "DOS+WIN32"
			Case Else
				$Indx_NameSpace = "Unknown"
		EndSelect
		$Indx_FileNameHex = StringMid($InputData,$LocalOffset+164,$Indx_NameLength*4)
		If $SkipUnicodeNames Then
			$NameTest = (_ValidateAnsiName($Indx_FileNameHex) And _ValidateWindowsFileName($Indx_FileNameHex))
		Else
			$NameTest = _ValidateWindowsFileName($Indx_FileNameHex)
		EndIf
		If $NameTest Then
			$Indx_FileName = BinaryToString("0x"&$Indx_FileNameHex,2)
			$FileNameHealthy = 1
		Else
;			ConsoleWrite("Error in filename: " & @CRLF)
;			ConsoleWrite("$Indx_FileNameHex: " & $Indx_FileNameHex & @CRLF)
;			ConsoleWrite("$Indx_FileName: " & $Indx_FileName & @CRLF)
		EndIf
		If $LocalOffset >= StringLen($InputData) Then ExitLoop

		$OffsetToFileName_tmp = $OffsetToFileName
		If Mod($OffsetToFileName_tmp,8) Then
			While 1
				$OffsetToFileName_tmp+=1
				If Mod($OffsetToFileName_tmp,8) = 0 Then ExitLoop
			WEnd
		EndIf

		If $FileNameHealthy And $Indx_NameLength > 0 And $Indx_CTime<>$TimestampErrorVal And $Indx_ATime<>$TimestampErrorVal And $Indx_MTime<>$TimestampErrorVal And $Indx_RTime<>$TimestampErrorVal And $Indx_NameSpace <> "Unknown" And $Indx_ReparseTag <> "UNKNOWN" And $Indx_AllocSize >= $Indx_RealSize And Mod($Indx_AllocSize,8)=0 Then
			If $MFTReferenceSeqNo = 0 Then $TextInformation &= ";Invalid MftRef and SeqNo"
			If $MFTReferenceOfParentSeqNo = 0 Then $TextInformation &= ";Invalid Parent MftRef and MftRefSeqNo"
			FileWriteLine($IndxEntriesCsvFile, $RecordOffset & $de & $IndxLastLsn & $de & $FromIndxSlack & $de & $Indx_FileName & $de & $MFTReference & $de & $MFTReferenceSeqNo & $de & $IndexFlags & $de & $MFTReferenceOfParent & $de & $MFTReferenceOfParentSeqNo & $de & $Indx_CTime & $de & $Indx_ATime & $de & $Indx_MTime & $de & $Indx_RTime & $de & $Indx_AllocSize & $de & $Indx_RealSize & $de & $Indx_File_Flags & $de & $Indx_ReparseTag & $de & $Indx_NameSpace & $de & $SubNodeVCN & $de & $TextInformation & @crlf)
			If $IndexEntryLength = 0 Then $IndexEntryLength = (32+26+$Indx_NameLength)*2
			$LocalOffset += $IndexEntryLength*2
			$EntryCounter+=1
			_ClearVar()
			ContinueLoop
		Else
#cs
			ConsoleWrite("Error: Validation of entry failed at offset: " & $RecordOffset & @CRLF)
			ConsoleWrite("$Indx_FileName: " & $Indx_FileName & @CRLF)
			ConsoleWrite("$Indx_FileNameHex: " & $Indx_FileNameHex & @CRLF)
			ConsoleWrite("$MFTReferenceSeqNo: " & $MFTReferenceSeqNo & @CRLF)
			ConsoleWrite("$MFTReferenceOfParent: " & $MFTReferenceOfParent & @CRLF)
			ConsoleWrite("$Indx_NameSpace: " & $Indx_NameSpace & @CRLF)
			ConsoleWrite(@CRLF)
#ce
			$LocalOffset += 2
		EndIf
		_ClearVar()
	WEnd
EndFunc

Func _ParseIndx($InputData)
	$LocalOffset = 3
	$IndxHdrMagic = StringMid($InputData,$LocalOffset,8)
	If $IndxHdrMagic <> $INDXsig Then Return 0
	If $DoFixups Then
		$InputData = _ApplyFixupsIndx(StringMid($InputData,3))
		If $InputData = "" Then
			ConsoleWrite("Error: Fixups failed." & @CRLF)
			Return 0
		EndIf
	EndIf
;	$TestData = _ApplyFixupsIndx(StringMid($InputData,3))
;	If $TestData <> "" Then $InputData = $TestData
	$IndxLastLsn = Dec(_SwapEndian(StringMid($InputData,$LocalOffset+16,16)),2)
;	ConsoleWrite("$IndxLastLsn: " & $IndxLastLsn & @crlf)
	If $IndxLastLsn = 0 Then
		ConsoleWrite("Error in $IndxLastLsn: " & $IndxLastLsn & @crlf)
		Return 0
	EndIf

	$IndxHeaderSize = Dec(_SwapEndian(StringMid($InputData,$LocalOffset+48,8)),2)
;	ConsoleWrite("$IndxHeaderSize: " & $IndxHeaderSize & @crlf)
	If $IndxHeaderSize = 0 Or Mod($IndxHeaderSize,8) Then
		ConsoleWrite("Error in $IndxHeaderSize: " & $IndxHeaderSize & @crlf)
		Return 0
	EndIf

	$IndxRealSizeAllEntries = Dec(_SwapEndian(StringMid($InputData,$LocalOffset+56,8)),2)
;	ConsoleWrite("$IndxRealSizeAllEntries: " & $IndxRealSizeAllEntries & @crlf)
	If $IndxRealSizeAllEntries = 0 Or Mod($IndxRealSizeAllEntries,8) Then
		ConsoleWrite("Error in $IndxRecordSize: " & $IndxRealSizeAllEntries & @crlf)
		Return 0
	EndIf

	$IndxAllocatedSize = Dec(_SwapEndian(StringMid($InputData,$LocalOffset+64,8)),2)
;	ConsoleWrite("$IndxAllocatedSize: " & $IndxAllocatedSize & @crlf)
	If $IndxAllocatedSize = 0 Or Mod($IndxAllocatedSize,8) Then
		ConsoleWrite("Error in $IndxAllocatedSize: " & $IndxAllocatedSize & @crlf)
		Return 0
	EndIf

	$IsNotLeafNode = Dec(StringMid($InputData,$LocalOffset+72,2))
	If $IsNotLeafNode > 1 Then
		ConsoleWrite("Error in $IsNotLeafNode" & @crlf)
		Return 0
	EndIf

	If Not ((24+$IndxHeaderSize) >= ($IndxRealSizeAllEntries+8)) Then
		$FromIndxSlack = 0
		_ParseCoreValidData(StringMid($InputData,$LocalOffset+48+($IndxHeaderSize*2),($IndxRealSizeAllEntries+8)*2))
		If $DoParseSlack Then
			$FromIndxSlack = 1
			_ParseCoreSlackSpace(StringMid($InputData,$LocalOffset+($IndxRealSizeAllEntries+8)*2),($IndxRealSizeAllEntries+8)*2)
		EndIf
	Else
;		ConsoleWrite("24+$IndxHeaderSize: " & 24+$IndxHeaderSize & @crlf)
;		ConsoleWrite("$IndxRealSizeAllEntries+8: " & $IndxRealSizeAllEntries+8 & @crlf)
;		ConsoleWrite("Warning: No valid data in this INDX" & @crlf)
		If $DoParseSlack Then
			$FromIndxSlack = 1
			_ParseCoreSlackSpace(StringMid($InputData,$LocalOffset+($IndxRealSizeAllEntries+8)*2),($IndxRealSizeAllEntries+8)*2)
		EndIf
	EndIf

EndFunc

Func _ApplyFixupsIndx($Entry)
;	ConsoleWrite("Starting function _StripIndxRecord()" & @crlf)
	Local $LocalAttributeOffset = 1,$IndxHdrUpdateSeqArrOffset,$IndxHdrUpdateSeqArrSize,$IndxHdrUpdSeqArr,$IndxHdrUpdSeqArrPart0,$IndxHdrUpdSeqArrPart1,$IndxHdrUpdSeqArrPart2,$IndxHdrUpdSeqArrPart3,$IndxHdrUpdSeqArrPart4,$IndxHdrUpdSeqArrPart5,$IndxHdrUpdSeqArrPart6,$IndxHdrUpdSeqArrPart7,$IndxHdrUpdSeqArrPart8
	Local $IndxRecordEnd1,$IndxRecordEnd2,$IndxRecordEnd3,$IndxRecordEnd4,$IndxRecordEnd5,$IndxRecordEnd6,$IndxRecordEnd7,$IndxRecordEnd8,$IndxRecordSize,$IndxHeaderSize,$IsNotLeafNode
;	ConsoleWrite("Unfixed INDX record:" & @crlf)
;	ConsoleWrite(_HexEncode("0x"&$Entry) & @crlf)
;	ConsoleWrite(_HexEncode("0x" & StringMid($Entry,1,4096)) & @crlf)
	$IndxHdrUpdateSeqArrOffset = Dec(_SwapEndian(StringMid($Entry,$LocalAttributeOffset+8,4)))
;	ConsoleWrite("$IndxHdrUpdateSeqArrOffset = " & $IndxHdrUpdateSeqArrOffset & @crlf)
	$IndxHdrUpdateSeqArrSize = Dec(_SwapEndian(StringMid($Entry,$LocalAttributeOffset+12,4)))
;	ConsoleWrite("$IndxHdrUpdateSeqArrSize = " & $IndxHdrUpdateSeqArrSize & @crlf)
	$IndxHdrUpdSeqArr = StringMid($Entry,1+($IndxHdrUpdateSeqArrOffset*2),$IndxHdrUpdateSeqArrSize*2*2)
;	ConsoleWrite("$IndxHdrUpdSeqArr = " & $IndxHdrUpdSeqArr & @crlf)
	$IndxHdrUpdSeqArrPart0 = StringMid($IndxHdrUpdSeqArr,1,4)
	$IndxHdrUpdSeqArrPart1 = StringMid($IndxHdrUpdSeqArr,5,4)
	$IndxHdrUpdSeqArrPart2 = StringMid($IndxHdrUpdSeqArr,9,4)
	$IndxHdrUpdSeqArrPart3 = StringMid($IndxHdrUpdSeqArr,13,4)
	$IndxHdrUpdSeqArrPart4 = StringMid($IndxHdrUpdSeqArr,17,4)
	$IndxHdrUpdSeqArrPart5 = StringMid($IndxHdrUpdSeqArr,21,4)
	$IndxHdrUpdSeqArrPart6 = StringMid($IndxHdrUpdSeqArr,25,4)
	$IndxHdrUpdSeqArrPart7 = StringMid($IndxHdrUpdSeqArr,29,4)
	$IndxHdrUpdSeqArrPart8 = StringMid($IndxHdrUpdSeqArr,33,4)
	$IndxRecordEnd1 = StringMid($Entry,1021,4)
	$IndxRecordEnd2 = StringMid($Entry,2045,4)
	$IndxRecordEnd3 = StringMid($Entry,3069,4)
	$IndxRecordEnd4 = StringMid($Entry,4093,4)
	$IndxRecordEnd5 = StringMid($Entry,5117,4)
	$IndxRecordEnd6 = StringMid($Entry,6141,4)
	$IndxRecordEnd7 = StringMid($Entry,7165,4)
	$IndxRecordEnd8 = StringMid($Entry,8189,4)
	If $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd1 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd2 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd3 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd4 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd5 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd6 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd7 OR $IndxHdrUpdSeqArrPart0 <> $IndxRecordEnd8 Then
		ConsoleWrite("Error the INDX record is corrupt" & @CRLF)
		Return ; Not really correct because I think in theory chunks of 1024 bytes can be invalid and not just everything or nothing for the given INDX record.
	Else
		$Entry = StringMid($Entry,1,1020) & $IndxHdrUpdSeqArrPart1 & StringMid($Entry,1025,1020) & $IndxHdrUpdSeqArrPart2 & StringMid($Entry,2049,1020) & $IndxHdrUpdSeqArrPart3 & StringMid($Entry,3073,1020) & $IndxHdrUpdSeqArrPart4 & StringMid($Entry,4097,1020) & $IndxHdrUpdSeqArrPart5 & StringMid($Entry,5121,1020) & $IndxHdrUpdSeqArrPart6 & StringMid($Entry,6145,1020) & $IndxHdrUpdSeqArrPart7 & StringMid($Entry,7169,1020)
	EndIf
	Return "0x"&$Entry
EndFunc

Func _SwapEndian($iHex)
	Return StringMid(Binary(Dec($iHex,2)),3, StringLen($iHex))
EndFunc

Func _HexEncode($bInput)
    Local $tInput = DllStructCreate("byte[" & BinaryLen($bInput) & "]")
    DllStructSetData($tInput, 1, $bInput)
    Local $a_iCall = DllCall("crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($tInput), _
            "dword", DllStructGetSize($tInput), _
            "dword", 11, _
            "ptr", 0, _
            "dword*", 0)

    If @error Or Not $a_iCall[0] Then
        Return SetError(1, 0, "")
    EndIf
    Local $iSize = $a_iCall[5]
    Local $tOut = DllStructCreate("char[" & $iSize & "]")
    $a_iCall = DllCall("crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($tInput), _
            "dword", DllStructGetSize($tInput), _
            "dword", 11, _
            "ptr", DllStructGetPtr($tOut), _
            "dword*", $iSize)
    If @error Or Not $a_iCall[0] Then
        Return SetError(2, 0, "")
    EndIf
    Return SetError(0, 0, DllStructGetData($tOut, 1))
EndFunc

Func _FillZero($inp)
	Local $inplen, $out, $tmp = ""
	$inplen = StringLen($inp)
	For $i = 1 To 4 - $inplen
		$tmp &= "0"
	Next
	$out = $tmp & $inp
	Return $out
EndFunc

Func _File_Attributes($FAInput)
	Local $FAOutput = ""
	If BitAND($FAInput, 0x0001) Then $FAOutput &= 'read_only+'
	If BitAND($FAInput, 0x0002) Then $FAOutput &= 'hidden+'
	If BitAND($FAInput, 0x0004) Then $FAOutput &= 'system+'
	If BitAND($FAInput, 0x0010) Then $FAOutput &= 'directory1+'
	If BitAND($FAInput, 0x0020) Then $FAOutput &= 'archive+'
	If BitAND($FAInput, 0x0040) Then $FAOutput &= 'device+'
	If BitAND($FAInput, 0x0080) Then $FAOutput &= 'normal+'
	If BitAND($FAInput, 0x0100) Then $FAOutput &= 'temporary+'
	If BitAND($FAInput, 0x0200) Then $FAOutput &= 'sparse_file+'
	If BitAND($FAInput, 0x0400) Then $FAOutput &= 'reparse_point+'
	If BitAND($FAInput, 0x0800) Then $FAOutput &= 'compressed+'
	If BitAND($FAInput, 0x1000) Then $FAOutput &= 'offline+'
	If BitAND($FAInput, 0x2000) Then $FAOutput &= 'not_indexed+'
	If BitAND($FAInput, 0x4000) Then $FAOutput &= 'encrypted+'
	If BitAND($FAInput, 0x8000) Then $FAOutput &= 'integrity_stream+'
	If BitAND($FAInput, 0x10000) Then $FAOutput &= 'virtual+'
	If BitAND($FAInput, 0x20000) Then $FAOutput &= 'no_scrub_data+'
	If BitAND($FAInput, 0x40000) Then $FAOutput &= 'ea+'
	If BitAND($FAInput, 0x10000000) Then $FAOutput &= 'directory2+'
	If BitAND($FAInput, 0x20000000) Then $FAOutput &= 'index_view+'
	$FAOutput = StringTrimRight($FAOutput, 1)
	Return $FAOutput
EndFunc

Func _SelectFragment()
	$BinaryFragment = FileOpenDialog("Select binary fragment",@ScriptDir,"All (*.*)")
	If @error Then
		ConsoleWrite("Error getting binary fragment." & @CRLF)
		Exit
	EndIf
	Return $BinaryFragment
EndFunc

Func _GetReparseType($ReparseType)
	;http://msdn.microsoft.com/en-us/library/dd541667(v=prot.10).aspx
	;http://msdn.microsoft.com/en-us/library/windows/desktop/aa365740(v=vs.85).aspx
	Select
		Case $ReparseType = '0x00000000'
			Return 'ZERO'
		Case $ReparseType = '0x80000005'
			Return 'DRIVER_EXTENDER'
		Case $ReparseType = '0x80000006'
			Return 'HSM2'
		Case $ReparseType = '0x80000007'
			Return 'SIS'
		Case $ReparseType = '0x80000008'
			Return 'WIM'
		Case $ReparseType = '0x80000009'
			Return 'CSV'
		Case $ReparseType = '0x8000000A'
			Return 'DFS'
		Case $ReparseType = '0x8000000B'
			Return 'FILTER_MANAGER'
		Case $ReparseType = '0x80000012'
			Return 'DFSR'
		Case $ReparseType = '0x80000013'
			Return 'DEDUP'
		Case $ReparseType = '0x80000014'
			Return 'NFS'
		Case $ReparseType = '0xA0000003'
			Return 'MOUNT_POINT'
		Case $ReparseType = '0xA000000C'
			Return 'SYMLINK'
		Case $ReparseType = '0xC0000004'
			Return 'HSM'
		Case $ReparseType = '0x80000015'
			Return 'FILE_PLACEHOLDER'
		Case $ReparseType = '0x80000017'
			Return 'WOF'
		Case Else
			Return 'UNKNOWN(' & $ReparseType & ')'
	EndSelect
EndFunc

; start: by Ascend4nt -----------------------------
Func _WinTime_GetUTCToLocalFileTimeDelta()
	Local $iUTCFileTime=864000000000		; exactly 24 hours from the origin (although 12 hours would be more appropriate (max variance = 12))
	$iLocalFileTime=_WinTime_UTCFileTimeToLocalFileTime($iUTCFileTime)
	If @error Then Return SetError(@error,@extended,-1)
	Return $iLocalFileTime-$iUTCFileTime	; /36000000000 = # hours delta (effectively giving the offset in hours from UTC/GMT)
EndFunc

Func _WinTime_UTCFileTimeToLocalFileTime($iUTCFileTime)
	If $iUTCFileTime<0 Then Return SetError(1,0,-1)
	Local $aRet=DllCall($_COMMON_KERNEL32DLL,"bool","FileTimeToLocalFileTime","uint64*",$iUTCFileTime,"uint64*",0)
	If @error Then Return SetError(2,@error,-1)
	If Not $aRet[0] Then Return SetError(3,0,-1)
	Return $aRet[2]
EndFunc

Func _WinTime_UTCFileTimeFormat($iUTCFileTime,$iFormat=4,$iPrecision=0,$bAMPMConversion=False)
;~ 	If $iUTCFileTime<0 Then Return SetError(1,0,"")	; checked in below call

	; First convert file time (UTC-based file time) to 'local file time'
	Local $iLocalFileTime=_WinTime_UTCFileTimeToLocalFileTime($iUTCFileTime)
	If @error Then Return SetError(@error,@extended,"")
	; Rare occassion: a filetime near the origin (January 1, 1601!!) is used,
	;	causing a negative result (for some timezones). Return as invalid param.
	If $iLocalFileTime<0 Then Return SetError(1,0,"")

	; Then convert file time to a system time array & format & return it
	Local $vReturn=_WinTime_LocalFileTimeFormat($iLocalFileTime,$iFormat,$iPrecision,$bAMPMConversion)
	Return SetError(@error,@extended,$vReturn)
EndFunc

Func _WinTime_LocalFileTimeFormat($iLocalFileTime,$iFormat=4,$iPrecision=0,$bAMPMConversion=False)
;~ 	If $iLocalFileTime<0 Then Return SetError(1,0,"")	; checked in below call

	; Convert file time to a system time array & return result
	Local $aSysTime=_WinTime_LocalFileTimeToSystemTime($iLocalFileTime)
	If @error Then Return SetError(@error,@extended,"")

	; Return only the SystemTime array?
	If $iFormat=0 Then Return $aSysTime

	Local $vReturn=_WinTime_FormatTime($aSysTime[0],$aSysTime[1],$aSysTime[2],$aSysTime[3], _
		$aSysTime[4],$aSysTime[5],$aSysTime[6],$aSysTime[7],$iFormat,$iPrecision,$bAMPMConversion)
	Return SetError(@error,@extended,$vReturn)
EndFunc

Func _WinTime_LocalFileTimeToSystemTime($iLocalFileTime)
	Local $aRet,$stSysTime,$aSysTime[8]=[-1,-1,-1,-1,-1,-1,-1,-1]

	; Negative values unacceptable
	If $iLocalFileTime<0 Then Return SetError(1,0,$aSysTime)

	; SYSTEMTIME structure [Year,Month,DayOfWeek,Day,Hour,Min,Sec,Milliseconds]
	$stSysTime=DllStructCreate("ushort[8]")

	$aRet=DllCall($_COMMON_KERNEL32DLL,"bool","FileTimeToSystemTime","uint64*",$iLocalFileTime,"ptr",DllStructGetPtr($stSysTime))
	If @error Then Return SetError(2,@error,$aSysTime)
	If Not $aRet[0] Then Return SetError(3,0,$aSysTime)
	Dim $aSysTime[8]=[DllStructGetData($stSysTime,1,1),DllStructGetData($stSysTime,1,2),DllStructGetData($stSysTime,1,4),DllStructGetData($stSysTime,1,5), _
		DllStructGetData($stSysTime,1,6),DllStructGetData($stSysTime,1,7),DllStructGetData($stSysTime,1,8),DllStructGetData($stSysTime,1,3)]
	Return $aSysTime
EndFunc

Func _WinTime_FormatTime($iYear,$iMonth,$iDay,$iHour,$iMin,$iSec,$iMilSec,$iDayOfWeek,$iFormat=4,$iPrecision=0,$bAMPMConversion=False)
	Local Static $_WT_aMonths[12]=["January","February","March","April","May","June","July","August","September","October","November","December"]
	Local Static $_WT_aDays[7]=["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

	If Not $iFormat Or $iMonth<1 Or $iMonth>12 Or $iDayOfWeek>6 Then Return SetError(1,0,"")

	; Pad MM,DD,HH,MM,SS,MSMSMSMS as necessary
	Local $sMM=StringRight(0&$iMonth,2),$sDD=StringRight(0&$iDay,2),$sMin=StringRight(0&$iMin,2)
	; $sYY = $iYear	; (no padding)
	;	[technically Year can be 1-x chars - but this is generally used for 4-digit years. And SystemTime only goes up to 30827/30828]
	Local $sHH,$sSS,$sMS,$sAMPM

	; 'Extra precision 1': +SS (Seconds)
	If $iPrecision Then
		$sSS=StringRight(0&$iSec,2)
		; 'Extra precision 2': +MSMSMSMS (Milliseconds)
		If $iPrecision>1 Then
;			$sMS=StringRight('000'&$iMilSec,4)
			$sMS=StringRight('000'&$iMilSec,3);Fixed an erronous 0 in front of the milliseconds
		Else
			$sMS=""
		EndIf
	Else
		$sSS=""
		$sMS=""
	EndIf
	If $bAMPMConversion Then
		If $iHour>11 Then
			$sAMPM=" PM"
			; 12 PM will cause 12-12 to equal 0, so avoid the calculation:
			If $iHour=12 Then
				$sHH="12"
			Else
				$sHH=StringRight(0&($iHour-12),2)
			EndIf
		Else
			$sAMPM=" AM"
			If $iHour Then
				$sHH=StringRight(0&$iHour,2)
			Else
			; 00 military = 12 AM
				$sHH="12"
			EndIf
		EndIf
	Else
		$sAMPM=""
		$sHH=StringRight(0 & $iHour,2)
	EndIf

	Local $sDateTimeStr,$aReturnArray[3]

	; Return an array? [formatted string + "Month" + "DayOfWeek"]
	If BitAND($iFormat,0x10) Then
		$aReturnArray[1]=$_WT_aMonths[$iMonth-1]
		If $iDayOfWeek>=0 Then
			$aReturnArray[2]=$_WT_aDays[$iDayOfWeek]
		Else
			$aReturnArray[2]=""
		EndIf
		; Strip the 'array' bit off (array[1] will now indicate if an array is to be returned)
		$iFormat=BitAND($iFormat,0xF)
	Else
		; Signal to below that the array isn't to be returned
		$aReturnArray[1]=""
	EndIf

	; Prefix with "DayOfWeek "?
	If BitAND($iFormat,8) Then
		If $iDayOfWeek<0 Then Return SetError(1,0,"")	; invalid
		$sDateTimeStr=$_WT_aDays[$iDayOfWeek]&', '
		; Strip the 'DayOfWeek' bit off
		$iFormat=BitAND($iFormat,0x7)
	Else
		$sDateTimeStr=""
	EndIf

	If $iFormat<2 Then
		; Basic String format: YYYYMMDDHHMM[SS[MSMSMSMS[ AM/PM]]]
		$sDateTimeStr&=$iYear&$sMM&$sDD&$sHH&$sMin&$sSS&$sMS&$sAMPM
	Else
		; one of 4 formats which ends with " HH:MM[:SS[:MSMSMSMS[ AM/PM]]]"
		Switch $iFormat
			; /, : Format - MM/DD/YYYY
			Case 2
				$sDateTimeStr&=$sMM&'/'&$sDD&'/'
			; /, : alt. Format - DD/MM/YYYY
			Case 3
				$sDateTimeStr&=$sDD&'/'&$sMM&'/'
			; "Month DD, YYYY" format
			Case 4
				$sDateTimeStr&=$_WT_aMonths[$iMonth-1]&' '&$sDD&', '
			; "DD Month YYYY" format
			Case 5
				$sDateTimeStr&=$sDD&' '&$_WT_aMonths[$iMonth-1]&' '
			Case 6
				$sDateTimeStr&=$iYear&'-'&$sMM&'-'&$sDD
				$iYear=''
			Case Else
				Return SetError(1,0,"")
		EndSwitch
		$sDateTimeStr&=$iYear&' '&$sHH&':'&$sMin
		If $iPrecision Then
			$sDateTimeStr&=':'&$sSS
;			If $iPrecision>1 Then $sDateTimeStr&=':'&$sMS
			If $iPrecision>1 Then $sDateTimeStr&=$PrecisionSeparator&$sMS
		EndIf
		$sDateTimeStr&=$sAMPM
	EndIf
	If $aReturnArray[1]<>"" Then
		$aReturnArray[0]=$sDateTimeStr
		Return $aReturnArray
	EndIf
	Return $sDateTimeStr
EndFunc
; end: by Ascend4nt ----------------------------

Func _ClearVar()
	$RecordOffset = ""
;	$IndxLastLsn = ""
;	$FromIndxSlack = ""
	$MFTReference = ""
	$MFTReferenceSeqNo = ""
	$IndexFlags = ""
	$MFTReferenceOfParent = ""
	$MFTReferenceOfParentSeqNo = ""
	$Indx_CTime = ""
	$Indx_ATime = ""
	$Indx_MTime = ""
	$Indx_RTime = ""
	$Indx_AllocSize = ""
	$Indx_RealSize = ""
	$Indx_File_Flags = ""
	$Indx_ReparseTag = ""
	$Indx_FileName = ""
	$Indx_NameSpace = ""
	$SubNodeVCN = ""
	$TextInformation = ""
EndFunc

Func _ValidateAnsiName($InputString)
;ConsoleWrite("$InputString: " & $InputString & @CRLF)
	$StringLength = StringLen($InputString)
	For $i = 1 To $StringLength Step 4
		$TestChunk = StringMid($InputString,$i,4)
		$TestChunk = Dec(_SwapEndian($TestChunk),2)
		If ($TestChunk >= 32 And $TestChunk < 127) Then
			ContinueLoop
		Else
			Return 0
		EndIf
	Next
	Return 1
EndFunc

Func _ValidateWindowsFileName($InputString)
	$StringLength = StringLen($InputString)
	For $i = 1 To $StringLength Step 4
		$TestChunk = StringMid($InputString,$i,4)
		$TestChunk = Dec(_SwapEndian($TestChunk),2)
		If ($TestChunk <> 47 And $TestChunk <> 92 And $TestChunk <> 58 And $TestChunk <> 42 And $TestChunk <> 63 And $TestChunk <> 34 And $TestChunk <> 60 And $TestChunk <> 62) Then
			ContinueLoop
		Else
			Return 0
		EndIf
	Next
	Return 1
EndFunc

Func _GetInputParams()
	Local $TimeZone, $OutputFormat, $ScanMode
	For $i = 1 To $cmdline[0]
		;ConsoleWrite("Param " & $i & ": " & $cmdline[$i] & @CRLF)
		If StringLeft($cmdline[$i],10) = "/IndxFile:" Then $BinaryFragment = StringMid($cmdline[$i],11)
		If StringLeft($cmdline[$i],12) = "/OutputPath:" Then $ParserOutDir = StringMid($cmdline[$i],13)
		If StringLeft($cmdline[$i],10) = "/TimeZone:" Then $TimeZone = StringMid($cmdline[$i],11)
		If StringLeft($cmdline[$i],14) = "/OutputFormat:" Then $OutputFormat = StringMid($cmdline[$i],15)
		If StringLeft($cmdline[$i],11) = "/Separator:" Then $SeparatorInput = StringMid($cmdline[$i],12)
		If StringLeft($cmdline[$i],15) = "/QuotationMark:" Then $checkquotes = StringMid($cmdline[$i],16)
		If StringLeft($cmdline[$i],9) = "/Unicode:" Then $CheckUnicode = StringMid($cmdline[$i],10)
		If StringLeft($cmdline[$i],7) = "/Slack:" Then $CheckSlack = StringMid($cmdline[$i],8)
		If StringLeft($cmdline[$i],8) = "/Fixups:" Then $CheckFixups = StringMid($cmdline[$i],9)
		If StringLeft($cmdline[$i],10) = "/ScanMode:" Then $ScanMode = StringMid($cmdline[$i],11)
		If StringLeft($cmdline[$i],10) = "/TSFormat:" Then $DateTimeFormat = StringMid($cmdline[$i],11)
		If StringLeft($cmdline[$i],13) = "/TSPrecision:" Then $TimestampPrecision = StringMid($cmdline[$i],14)
		If StringLeft($cmdline[$i],22) = "/TSPrecisionSeparator:" Then $PrecisionSeparator = StringMid($cmdline[$i],23)
		If StringLeft($cmdline[$i],23) = "/TSPrecisionSeparator2:" Then $PrecisionSeparator2 = StringMid($cmdline[$i],24)
		If StringLeft($cmdline[$i],12) = "/TSErrorVal:" Then $TimestampErrorVal = StringMid($cmdline[$i],13)
		If StringLeft($cmdline[$i],10) = "/IndxSize:" Then $INDX_Size = StringMid($cmdline[$i],11)
	Next

	If StringLen($ScanMode) > 0 Then
		If $ScanMode <> 0 And $ScanMode <> 1 And $ScanMode <> 2 Then
			ConsoleWrite("Error: Incorect ScanMode: " & $ScanMode & @CRLF)
			Exit
		EndIf
	Else
		$ScanMode = 0
	EndIf
	Select
		case $ScanMode = 0
			$DoNormalMode = 1
			$DoScanMode1 = 0
			$DoScanMode2 = 0
		case $ScanMode = 1
			$DoNormalMode = 0
			$DoScanMode1 = 1
			$DoScanMode2 = 0
		case $ScanMode = 2
			$DoNormalMode = 0
			$DoScanMode1 = 0
			$DoScanMode2 = 1
	EndSelect

	If StringLen($TimeZone) > 0 Then
		Select
			Case $TimeZone = "-12.00"
			Case $TimeZone = "-11.00"
			Case $TimeZone = "-10.00"
			Case $TimeZone = "-9.30"
			Case $TimeZone = "-9.00"
			Case $TimeZone = "-8.00"
			Case $TimeZone = "-7.00"
			Case $TimeZone = "-6.00"
			Case $TimeZone = "-5.00"
			Case $TimeZone = "-4.30"
			Case $TimeZone = "-4.00"
			Case $TimeZone = "-3.30"
			Case $TimeZone = "-3.00"
			Case $TimeZone = "-2.00"
			Case $TimeZone = "-1.00"
			Case $TimeZone = "0.00"
			Case $TimeZone = "1.00"
			Case $TimeZone = "2.00"
			Case $TimeZone = "3.00"
			Case $TimeZone = "3.30"
			Case $TimeZone = "4.00"
			Case $TimeZone = "4.30"
			Case $TimeZone = "5.00"
			Case $TimeZone = "5.30"
			Case $TimeZone = "5.45"
			Case $TimeZone = "6.00"
			Case $TimeZone = "6.30"
			Case $TimeZone = "7.00"
			Case $TimeZone = "8.00"
			Case $TimeZone = "8.45"
			Case $TimeZone = "9.00"
			Case $TimeZone = "9.30"
			Case $TimeZone = "10.00"
			Case $TimeZone = "10.30"
			Case $TimeZone = "11.00"
			Case $TimeZone = "11.30"
			Case $TimeZone = "12.00"
			Case $TimeZone = "12.45"
			Case $TimeZone = "13.00"
			Case $TimeZone = "14.00"
			Case Else
				$TimeZone = "0.00"
		EndSelect
	Else
		$TimeZone = "0.00"
	EndIf

	$tDelta = _GetUTCRegion($TimeZone)-$tDelta
	If @error Then
		_DisplayInfo("Error: Timezone configuration failed." & @CRLF)
	Else
		_DisplayInfo("Timestamps presented in UTC: " & $UTCconfig & @CRLF)
	EndIf
	$tDelta = $tDelta*-1

	If StringLen($BinaryFragment) > 0 Then
		If Not FileExists($BinaryFragment) Then
			ConsoleWrite("Error input INDX chunk file does not exist." & @CRLF)
			Exit
		EndIf
	EndIf
#cs
	If StringLen($OutputFormat) > 0 Then
		If $OutputFormat = "l2t" Then $checkl2t = 1
		If $OutputFormat = "bodyfile" Then $checkbodyfile = 1
		If $OutputFormat = "all" Then $checkdefaultall = 1
		If $checkl2t + $checkbodyfile = 0 Then $checkdefaultall = 1
	Else
		$checkdefaultall = 1
	EndIf
#ce
	$checkdefaultall = 1
	$DoDefaultAll = 1
	$dol2t = 0
	$DoBodyfile = 0

	If StringLen($PrecisionSeparator) <> 1 Then $PrecisionSeparator = "."
	If StringLen($SeparatorInput) <> 1 Then $SeparatorInput = "|"

	If StringLen($TimestampPrecision) > 0 Then
		Select
			Case $TimestampPrecision = "None"
				ConsoleWrite("Timestamp Precision: " & $TimestampPrecision & @CRLF)
				$TimestampPrecision = 1
			Case $TimestampPrecision = "MilliSec"
				ConsoleWrite("Timestamp Precision: " & $TimestampPrecision & @CRLF)
				$TimestampPrecision = 2
			Case $TimestampPrecision = "NanoSec"
				ConsoleWrite("Timestamp Precision: " & $TimestampPrecision & @CRLF)
				$TimestampPrecision = 3
		EndSelect
	Else
		$TimestampPrecision = 1
	EndIf

	If StringLen($DateTimeFormat) > 0 Then
		If $DateTimeFormat <> 1 And $DateTimeFormat <> 2 And $DateTimeFormat <> 3 And $DateTimeFormat <> 4 And $DateTimeFormat <> 5 And $DateTimeFormat <> 6 Then
			$DateTimeFormat = 6
		EndIf
	Else
		$DateTimeFormat = 6
	EndIf

	If StringLen($CheckSlack) > 0 Then
		If $CheckSlack <> 0 And $CheckSlack <> 1 Then
			ConsoleWrite("Error in slack configuration: " & $CheckSlack & @CRLF)
		EndIf
		$DoParseSlack = $CheckSlack
	EndIf

	If StringLen($CheckFixups) > 0 Then
		If $CheckFixups <> 0 And $CheckFixups <> 1 Then
			ConsoleWrite("Error in fixups configuration: " & $CheckFixups & @CRLF)
		EndIf
		$DoFixups = $CheckFixups
	EndIf
EndFunc

Func _DisplayInfo($DebugInfo)
	GUICtrlSetData($myctredit, $DebugInfo, 1)
EndFunc

Func _InjectTimeZoneInfo()
$Regions = "UTC: -12.00|" & _
	"UTC: -11.00|" & _
	"UTC: -10.00|" & _
	"UTC: -9.30|" & _
	"UTC: -9.00|" & _
	"UTC: -8.00|" & _
	"UTC: -7.00|" & _
	"UTC: -6.00|" & _
	"UTC: -5.00|" & _
	"UTC: -4.30|" & _
	"UTC: -4.00|" & _
	"UTC: -3.30|" & _
	"UTC: -3.00|" & _
	"UTC: -2.00|" & _
	"UTC: -1.00|" & _
	"UTC: 0.00|" & _
	"UTC: 1.00|" & _
	"UTC: 2.00|" & _
	"UTC: 3.00|" & _
	"UTC: 3.30|" & _
	"UTC: 4.00|" & _
	"UTC: 4.30|" & _
	"UTC: 5.00|" & _
	"UTC: 5.30|" & _
	"UTC: 5.45|" & _
	"UTC: 6.00|" & _
	"UTC: 6.30|" & _
	"UTC: 7.00|" & _
	"UTC: 8.00|" & _
	"UTC: 8.45|" & _
	"UTC: 9.00|" & _
	"UTC: 9.30|" & _
	"UTC: 10.00|" & _
	"UTC: 10.30|" & _
	"UTC: 11.00|" & _
	"UTC: 11.30|" & _
	"UTC: 12.00|" & _
	"UTC: 12.45|" & _
	"UTC: 13.00|" & _
	"UTC: 14.00|"
GUICtrlSetData($Combo2,$Regions,"UTC: 0.00")
EndFunc

Func _GetUTCRegion($UTCRegion)
	If $UTCRegion = "" Then Return SetError(1,0,0)

	If StringInStr($UTCRegion,"UTC:") Then
		$part1 = StringMid($UTCRegion,StringInStr($UTCRegion," ")+1)
	Else
		$part1 = $UTCRegion
	EndIf
	Global $UTCconfig = $part1
	If StringRight($part1,2) = "15" Then $part1 = StringReplace($part1,".15",".25")
	If StringRight($part1,2) = "30" Then $part1 = StringReplace($part1,".30",".50")
	If StringRight($part1,2) = "45" Then $part1 = StringReplace($part1,".45",".75")
	$DeltaTest = $part1*36000000000
	Return $DeltaTest
EndFunc

Func _TranslateSeparator()
	; Or do it the other way around to allow setting other trickier separators, like specifying it in hex
	GUICtrlSetData($SeparatorInput,StringLeft(GUICtrlRead($SeparatorInput),1))
	GUICtrlSetData($SeparatorInput2,"0x"&Hex(Asc(GUICtrlRead($SeparatorInput)),2))
EndFunc

Func _InjectTimestampFormat()
Local $Formats = "1|" & _
	"2|" & _
	"3|" & _
	"4|" & _
	"5|" & _
	"6|"
	GUICtrlSetData($ComboTimestampFormat,$Formats,"6")
EndFunc

Func _InjectTimestampPrecision()
Local $Precision = "None|" & _
	"MilliSec|" & _
	"NanoSec|"
	GUICtrlSetData($ComboTimestampPrecision,$Precision,"NanoSec")
EndFunc

Func _TranslateTimestamp()
	Local $lPrecision,$lTimestamp,$lTimestampTmp
	$DateTimeFormat = StringLeft(GUICtrlRead($ComboTimestampFormat),1)
	$lPrecision = GUICtrlRead($ComboTimestampPrecision)
	Select
		Case $lPrecision = "None"
			$TimestampPrecision = 1
		Case $lPrecision = "MilliSec"
			$TimestampPrecision = 2
		Case $lPrecision = "NanoSec"
			$TimestampPrecision = 3
	EndSelect
	$lTimestampTmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $ExampleTimestampVal)
	$lTimestamp = _WinTime_UTCFileTimeFormat(Dec($ExampleTimestampVal,2), $DateTimeFormat, $TimestampPrecision)
	If @error Then
		$lTimestamp = $TimestampErrorVal
	ElseIf $TimestampPrecision = 3 Then
		$lTimestamp = $lTimestamp & $PrecisionSeparator2 & _FillZero(StringRight($lTimestampTmp, 4))
	EndIf
	GUICtrlSetData($InputExampleTimestamp,$lTimestamp)
EndFunc

Func _IndxProgress()
    GUICtrlSetData($ProgressStatus, "Processing INDX page " & $CurrentRecord+1 & " of " & $MaxRecords & ", total entries: " & $EntryCounter)
    GUICtrlSetData($ElapsedTime, "Elapsed time = " & _WinAPI_StrFromTimeInterval(TimerDiff($begin)))
	GUICtrlSetData($ProgressIndx, 100 * ($CurrentRecord+1) / $MaxRecords)
EndFunc

Func _DumpOutput($text)
   ConsoleWrite($text)
   If $DebugOutFile Then FileWrite($DebugOutFile, $text)
EndFunc
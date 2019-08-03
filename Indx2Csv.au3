#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=C:\Program Files (x86)\AutoIt3\Icons\au3.ico
#AutoIt3Wrapper_Outfile=Indx2Csv.exe
#AutoIt3Wrapper_Outfile_x64=Indx2Csv64.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Decode INDX records
#AutoIt3Wrapper_Res_Description=Decode INDX records
#AutoIt3Wrapper_Res_Fileversion=1.0.0.14
#AutoIt3Wrapper_Res_LegalCopyright=Joakim Schicht
#AutoIt3Wrapper_AU3Check_Parameters=-w 3 -w 5
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/sf /sv /rm /pe
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
Global $de="|", $PrecisionSeparator=".", $PrecisionSeparator2="",$DateTimeFormat, $TimestampPrecision,$IndxEntriesI30CsvFile,$IndxEntriesI30Csv,$CurrentFileOffset,$UTCconfig,$myctredit,$SeparatorInput
Global $TimestampErrorVal = "0000-00-00 00:00:00",$ExampleTimestampVal = "01CD74B3150770B8", $IndxEntriesObjIdOCsvFile, $IndxEntriesObjIdOCsv, $IndxEntriesReparseRCsvFile, $IndxEntriesReparseRCsv
Global $DoDefaultAll, $Dol2t, $DoBodyfile, $hDebugOutFile, $MaxRecords, $CurrentRecord, $WithQuotes, $EncodingWhenOpen = 2, $DoParseSlack=1, $DoFixups=1
Global $CheckSlack,$CheckFixups,$CheckUnicode,$checkquotes
Global $begin, $ElapsedTime, $EntryCounter, $ScanMode, $SectorSize=512, $ExtendedNameCheckChar=1, $ExtendedNameCheckWindows=1, $ExtendedNameCheckAll=1, $ExtendedTimestampCheck=1, $StrictNameCheck=1
Global $ProgressStatus, $ProgressIndx, $IsNotLeafNode, $IndxCurrentVcn
Global $RecordOffset,$IndxLastLsn,$FromIndxSlack,$MFTReference,$MFTReferenceSeqNo,$IndexFlags,$MFTReferenceOfParent,$MFTReferenceOfParentSeqNo
Global $Indx_CTime,$Indx_ATime,$Indx_MTime,$Indx_RTime,$Indx_AllocSize,$Indx_RealSize,$Indx_File_Flags,$Indx_ReparseTag,$Indx_FileName,$Indx_NameSpace,$SubNodeVCN,$TextInformation
Global $SkipUnicodeNames = 1 ;Will improve recovery of entries from slack
Global $_COMMON_KERNEL32DLL=DllOpen("kernel32.dll"),$outputpath=@ScriptDir,$ParserOutDir
Global $INDXsig = "494E4458", $INDX_Size = 4096, $BinaryFragment, $RegExPatternHexNotNull = "[1-9a-fA-F]", $CleanUp=0, $VerifyFragment=0, $OutFragmentName="OutFragment.bin", $RebuiltFragment
Global $tDelta = _WinTime_GetUTCToLocalFileTimeDelta()
Global $TimeDiff = 5748192000000000
Global $TSCheckLow  = 112589990684262400 ;1957-10-14
Global $TSCheckHigh = 139611588448485376 ;2043-05-31
Global $CharsToGrabDate, $CharStartTime, $CharsToGrabTime

$Progversion = "Indx2Csv 1.0.0.14"
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
	GUICtrlSetState($CheckSlack, $GUI_CHECKED)
	GUICtrlSetState($CheckSlack, $GUI_DISABLE)
	$CheckFixups = GUICtrlCreateCheckbox("Apply fixups", 320, 95, 75, 20)
	GUICtrlSetState($CheckFixups, $GUI_CHECKED)
	;$CheckCleanUp = GUICtrlCreateCheckbox("CleanUp", 320, 120, 75, 20)
	;GUICtrlSetState($CheckCleanUp, $GUI_UNCHECKED)

	$checkl2t = GUICtrlCreateRadio("log2timeline", 20, 100, 110, 20)
	;$checkl2t = GUICtrlCreateCheckbox("log2timeline", 20, 100, 130, 20)
	;GUICtrlSetState($checkl2t, $GUI_UNCHECKED)
	;GUICtrlSetState($checkl2t, $GUI_DISABLE)
	$checkbodyfile = GUICtrlCreateRadio("bodyfile", 20, 120, 100, 20)
	;$checkbodyfile = GUICtrlCreateCheckbox("bodyfile", 20, 120, 130, 20)
	;GUICtrlSetState($checkbodyfile, $GUI_UNCHECKED)
	;GUICtrlSetState($checkbodyfile, $GUI_DISABLE)
	$checkdefaultall = GUICtrlCreateRadio("dump everything", 20, 140, 110, 20)
	;$checkdefaultall = GUICtrlCreateCheckbox("dump everything", 20, 140, 130, 20)
	;GUICtrlSetState($checkdefaultall, $GUI_CHECKED)
	;GUICtrlSetState($checkdefaultall, $GUI_DISABLE)

	$ComboScanMode = GUICtrlCreateCombo("", 200, 100, 35, 20)
	$LabelScanMode = GUICtrlCreateLabel("Scan mode:",130,100,60,20)

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
	_InjectScanMode()
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
				GUICtrlSetState($checkl2t, $GUI_UNCHECKED)
				GUICtrlSetState($checkbodyfile, $GUI_UNCHECKED)
				GUICtrlSetState($checkdefaultall, $GUI_UNCHECKED)
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

	If $CommandlineMode Then
		$TestUnicode = $CheckUnicode
	Else
		$TestUnicode = GUICtrlRead($CheckUnicode)
	EndIf
	ConsoleWrite("$TestUnicode: " & $TestUnicode & @CRLF)
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

	$TimestampStart = @YEAR & "-" & @MON & "-" & @MDAY & "_" & @HOUR & "-" & @MIN & "-" & @SEC

	If Not FileExists($ParserOutDir) Then
		$ParserOutDir = @ScriptDir
	EndIf

	$DebugOutFile = $ParserOutDir & "\Indx_" & $TimestampStart & ".log"
	$hDebugOutFile = FileOpen($DebugOutFile, $EncodingWhenOpen)
	If @error Then
		ConsoleWrite("Error: Could not create log file" & @CRLF)
		MsgBox(0,"Error","Could not create log file")
		Exit
	EndIf

	;$I30
	$IndxEntriesI30CsvFile = $ParserOutDir & "\Indx_I30_Entries_" & $TimestampStart & ".csv"
	$IndxEntriesI30Csv = FileOpen($IndxEntriesI30CsvFile, $EncodingWhenOpen)
	If @error Then
		ConsoleWrite("Error creating: " & $IndxEntriesI30CsvFile & @CRLF)
		If Not $CommandlineMode Then _DisplayInfo("Error creating: " & $IndxEntriesI30CsvFile & @CRLF)
		Return
	EndIf

	;$ObjId:$O
	$IndxEntriesObjIdOCsvFile = $ParserOutDir & "\Indx_ObjIdO_Entries_" & $TimestampStart & ".csv"
	$IndxEntriesObjIdOCsv = FileOpen($IndxEntriesObjIdOCsvFile, $EncodingWhenOpen)
	If @error Then
		ConsoleWrite("Error creating: " & $IndxEntriesObjIdOCsvFile & @CRLF)
		If Not $CommandlineMode Then _DisplayInfo("Error creating: " & $IndxEntriesObjIdOCsvFile & @CRLF)
		Return
	EndIf

	;$Reparse:$R
	$IndxEntriesReparseRCsvFile = $ParserOutDir & "\Indx_ReparseR_Entries_" & $TimestampStart & ".csv"
	$IndxEntriesObjIdOCsv = FileOpen($IndxEntriesReparseRCsvFile, $EncodingWhenOpen)
	If @error Then
		ConsoleWrite("Error creating: " & $IndxEntriesReparseRCsvFile & @CRLF)
		If Not $CommandlineMode Then _DisplayInfo("Error creating: " & $IndxEntriesReparseRCsvFile & @CRLF)
		Return
	EndIf

	_DumpOutput("Input file: " & $BinaryFragment & @CRLF)
	_DumpOutput("Output directory: " & $ParserOutDir & @CRLF)
	_DumpOutput("Csv: " & $IndxEntriesI30CsvFile & @CRLF)
	_DumpOutput("Csv: " & $IndxEntriesObjIdOCsvFile & @CRLF)
	_DumpOutput("Csv: " & $IndxEntriesReparseRCsvFile & @CRLF)
	_DumpOutput("StrictNameCheck: " & $StrictNameCheck & @CRLF)

;---------------------

	If Not $CommandlineMode Then
		If Int(GUICtrlRead($checkl2t) + GUICtrlRead($checkbodyfile) + GUICtrlRead($checkdefaultall)) <> 9 Then
			_DisplayInfo("Error: Output format must be set to 1 of the 3 options." & @CRLF)
			Return
		EndIf
		$Dol2t = False
		$DoBodyfile = False
		$DoDefaultAll = False
		If GUICtrlRead($checkl2t) = 1 Then
			$Dol2t = True
		ElseIf GUICtrlRead($checkbodyfile) = 1 Then
			$DoBodyfile = True
		ElseIf GUICtrlRead($checkdefaultall) = 1 Then
			$DoDefaultAll = True
		EndIf
	EndIf

	If Not $CommandlineMode Then
		If ($DateTimeFormat = 4 Or $DateTimeFormat = 5) And ($Dol2t Or $DoBodyfile) Then
			_DisplayInfo("Error: Timestamp format can't be 4 or 5 in combination with OutputFormat log2timeline and bodyfile" & @CRLF)
			Return
		EndIf
	EndIf

	If Not $CommandlineMode Then
		$de = GUICtrlRead($SeparatorInput)
	Else
		$de = $SeparatorInput
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
		$ScanMode = GUICtrlRead($ComboScanMode)
	EndIf
	;----------------------------------------
	Select
		Case $DoDefaultAll
			_DumpOutput("OutputFormat: all" & @CRLF)
			$IndxI30SqlFile = $ParserOutDir & "\Indx_I30_Entries_"&$TimestampStart&".sql"
			$IndxObjectIdSqlFile = $OutputPath & "\Indx_ObjIdO_Entries_"&$TimestampStart&".sql"
			$IndxReparseRSqlFile = $OutputPath & "\Indx_ReparseR_Entries_"&$TimestampStart&".sql"
		Case $Dol2t
			_DumpOutput("OutputFormat: log2timeline" & @CRLF)
			$IndxI30SqlFile = $ParserOutDir & "\Indx_I30_Entries_l2t_"&$TimestampStart&".sql"
			$IndxObjectIdSqlFile = $OutputPath & "\Indx_ObjIdO_Entries_l2t_"&$TimestampStart&".sql"
			$IndxReparseRSqlFile = $OutputPath & "\Indx_ReparseR_Entries_l2t_"&$TimestampStart&".sql"
		Case $DoBodyfile
			_DumpOutput("OutputFormat: bodyfile" & @CRLF)
			$IndxI30SqlFile = $ParserOutDir & "\Indx_I30_Entries_bodyfile_"&$TimestampStart&".sql"
			$IndxObjectIdSqlFile = $OutputPath & "\Indx_ObjIdO_Entries_bodyfile_"&$TimestampStart&".sql"
			$IndxReparseRSqlFile = $OutputPath & "\Indx_ReparseR_Entries_bodyfile_"&$TimestampStart&".sql"
	EndSelect

	Select
		Case $DoDefaultAll
			FileInstall(".\import-sql\import-csv-INDX-I30.sql", $IndxI30SqlFile)
			FileInstall(".\import-sql\import-csv-INDX-objido.sql", $IndxObjectIdSqlFile)
			FileInstall(".\import-sql\import-csv-INDX-reparser.sql", $IndxReparseRSqlFile)
		Case $Dol2t
			FileInstall(".\import-sql\import-csv-l2t-INDX.sql", $IndxI30SqlFile)
		Case $DoBodyfile
			FileInstall(".\import-sql\import-csv-bodyfile-INDX.sql", $IndxI30SqlFile)
	EndSelect

	$FixedPath = StringReplace($IndxEntriesI30CsvFile, "\","\\")
	Sleep(500)
	_ReplaceStringInFile($IndxI30SqlFile, "__PathToCsv__", $FixedPath)
	If $TestUnicode = 1 Then _ReplaceStringInFile($IndxI30SqlFile, "latin1", "utf8")
	_ReplaceStringInFile($IndxI30SqlFile, "__Separator__", $de)

	$FixedPath = StringReplace($IndxEntriesObjIdOCsvFile,"\","\\")
	Sleep(500)
	_ReplaceStringInFile($IndxObjectIdSqlFile,"__PathToCsv__",$FixedPath)
	If $CheckUnicode = 1 Then _ReplaceStringInFile($IndxObjectIdSqlFile,"latin1", "utf8")
	_ReplaceStringInFile($IndxObjectIdSqlFile, "__Separator__", $de)

	$FixedPath = StringReplace($IndxEntriesReparseRCsvFile,"\","\\")
	Sleep(500)
	_ReplaceStringInFile($IndxReparseRSqlFile,"__PathToCsv__",$FixedPath)
	If $CheckUnicode = 1 Then _ReplaceStringInFile($IndxReparseRSqlFile,"latin1", "utf8")
	_ReplaceStringInFile($IndxReparseRSqlFile, "__Separator__", $de)

	_SetDateTimeFormats()

	Local $TSPrecisionFormatTransform = ""
	If $TimestampPrecision > 1 Then
		$TSPrecisionFormatTransform = $PrecisionSeparator & "%f"
	EndIf

	Local $TimestampFormatTransform
	If $DoDefaultAll Or $DoBodyfile Then
		;INDX or bodyfile table


		Select
			Case $DateTimeFormat = 1
				$TimestampFormatTransform = "%Y%m%d%H%i%s" & $TSPrecisionFormatTransform
			Case $DateTimeFormat = 2
				$TimestampFormatTransform = "%m/%d/%Y %H:%i:%s" & $TSPrecisionFormatTransform
			Case $DateTimeFormat = 3
				$TimestampFormatTransform = "%d/%m/%Y %H:%i:%s" & $TSPrecisionFormatTransform
			Case $DateTimeFormat = 4 Or $DateTimeFormat = 5
				If $CommandlineMode Then
					ConsoleWrite("WARNING: Loading of sql into database with TSFormat 4 or 5 is not yet supported." & @CRLF)
				Else
					_DumpOutput("WARNING: Loading of sql into database with TSFormat 4 or 5 is not yet supported." & @CRLF)
				EndIf
			Case $DateTimeFormat = 6
				$TimestampFormatTransform = "%Y-%m-%d %H:%i:%s" & $TSPrecisionFormatTransform
		EndSelect
		_ReplaceStringInFile($IndxI30SqlFile, "__TimestampTransformationSyntax__", $TimestampFormatTransform)
		_ReplaceStringInFile($IndxObjectIdSqlFile, "__TimestampTransformationSyntax__", $TimestampFormatTransform)
		_ReplaceStringInFile($IndxReparseRSqlFile, "__TimestampTransformationSyntax__", $TimestampFormatTransform)
	EndIf

	Local $DateFormatTransform, $TimeFormatTransform
	If $Dol2t Then
		;log2timeline table
		Select
			Case $DateTimeFormat = 1
				$DateFormatTransform = "%Y%m%d"
				$TimeFormatTransform = "%H%i%s"
			Case $DateTimeFormat = 2
				$DateFormatTransform = "%m/%d/%Y"
				$TimeFormatTransform = "%H:%i:%s"
			Case $DateTimeFormat = 3
				$DateFormatTransform = "%d/%m/%Y"
				$TimeFormatTransform = "%H:%i:%s"
			Case $DateTimeFormat = 4 Or $DateTimeFormat = 5
				If $CommandlineMode Then
					ConsoleWrite("WARNING: Loading of sql into database with TSFormat 4 or 5 is not yet supported." & @CRLF)
				Else
					_DumpOutput("WARNING: Loading of sql into database with TSFormat 4 or 5 is not yet supported." & @CRLF)
				EndIf
			Case $DateTimeFormat = 6
				$DateFormatTransform = "%Y-%m-%d"
				$TimeFormatTransform = "%H:%i:%s"
		EndSelect
		_ReplaceStringInFile($IndxI30SqlFile, "__DateTransformationSyntax__", $DateFormatTransform)
		_ReplaceStringInFile($IndxI30SqlFile, "__TimeTransformationSyntax__", $TimeFormatTransform)
		_ReplaceStringInFile($IndxObjectIdSqlFile, "__DateTransformationSyntax__", $DateFormatTransform)
		_ReplaceStringInFile($IndxObjectIdSqlFile, "__TimeTransformationSyntax__", $TimeFormatTransform)
		_ReplaceStringInFile($IndxReparseRSqlFile, "__DateTransformationSyntax__", $DateFormatTransform)
		_ReplaceStringInFile($IndxReparseRSqlFile, "__TimeTransformationSyntax__", $TimeFormatTransform)
	EndIf
	;--------------------------
	#cs
	$IndxI30SqlFile = $ParserOutDir & "\Indx_I30_Entries_" & $TimestampStart & ".sql"
	FileInstall(".\import-sql\import-csv-INDX-I30.sql", $IndxI30SqlFile)
	$FixedPath = StringReplace($IndxEntriesI30CsvFile,"\","\\")
	Sleep(500)
	_ReplaceStringInFile($IndxI30SqlFile,"__PathToCsv__",$FixedPath)
	If $TestUnicode = 1 Then _ReplaceStringInFile($IndxI30SqlFile,"latin1", "utf8")

	$IndxObjectIdSqlFile = $OutputPath & "\Indx_ObjIdO_Entries_"&$TimestampStart&".sql"
	FileInstall(".\import-sql\import-csv-INDX-objido.sql", $IndxObjectIdSqlFile)
	$FixedPath = StringReplace($IndxEntriesObjIdOCsvFile,"\","\\")
	Sleep(500)
	_ReplaceStringInFile($IndxObjectIdSqlFile,"__PathToCsv__",$FixedPath)
	If $CheckUnicode = 1 Then _ReplaceStringInFile($IndxObjectIdSqlFile,"latin1", "utf8")

	$IndxReparseRSqlFile = $OutputPath & "\Indx_ReparseR_Entries_"&$TimestampStart&".sql"
	FileInstall(".\import-sql\import-csv-INDX-reparser.sql", $IndxReparseRSqlFile)
	$FixedPath = StringReplace($IndxEntriesReparseRCsvFile,"\","\\")
	Sleep(500)
	_ReplaceStringInFile($IndxReparseRSqlFile,"__PathToCsv__",$FixedPath)
	If $CheckUnicode = 1 Then _ReplaceStringInFile($IndxReparseRSqlFile,"latin1", "utf8")
	#ce
	_DumpOutput("Scan mode: " & $ScanMode & @CRLF)
;----------------------------

	_WriteCSVHeaderIndxEntries()
	_WriteIndxObjIdOModuleCsvHeader()
	_WriteIndxReparseRModuleCsvHeader()

	$InputFileSize = _WinAPI_GetFileSizeEx($hFile)
	$MaxRecords = Ceiling($InputFileSize/$INDX_Size)
	If $ScanMode=0 And Mod($InputFileSize,$INDX_Size) Then
		ConsoleWrite("Error: File size not a multiple of INDX size. Last page must have special buffer created." & @CRLF)
	EndIf

	$Progress = GUICtrlCreateLabel("Decoding INDX data and writing to csv", 10, 280,540,20)
	GUICtrlSetFont($Progress, 12)
	$ProgressStatus = GUICtrlCreateLabel("", 10, 275, 520, 20)
	$ElapsedTime = GUICtrlCreateLabel("", 10, 290, 520, 20)
	$ProgressIndx = GUICtrlCreateProgress(0,  315, 540, 30)
	$begin = TimerInit()

	AdlibRegister("_IndxProgress", 500)
	ConsoleWrite("Parsing input.." & @CRLF)

	Select
		Case $ScanMode = 0
			$tBuffer = DllStructCreate("byte["&$INDX_Size&"]")
			For $i = 0 To $MaxRecords-1
				$CurrentRecord = $i
				_WinAPI_SetFilePointerEx($hFile, $i*$INDX_Size, $FILE_BEGIN)
				_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), $INDX_Size, $nBytes)
				$IndxRecord = DllStructGetData($tBuffer, 1)
				$CurrentFileOffset = DllCall('kernel32.dll', 'int', 'SetFilePointerEx', 'ptr', $hFile, 'int64', 0, 'int64*', 0, 'dword', 1)
				$CurrentFileOffset = $CurrentFileOffset[3]-$INDX_Size
				$RecordOffset = "0x" & Hex(Int($CurrentFileOffset))
				$EntryCounter += _ParseIndx($IndxRecord)
				_ClearVar()
			Next
		Case $ScanMode > 0
			$ChunkSize = $SectorSize*100
			$tBuffer = DllStructCreate("byte[" & ($ChunkSize)+$SectorSize & "]")
			$MaxPages = Ceiling($InputFileSize/($ChunkSize))
			For $i = 0 To $MaxPages-1
;				ConsoleWrite("$i: " & $i & @CRLF)
				;$CurrentPage=$i
				_WinAPI_SetFilePointerEx($hFile, $i*($ChunkSize), $FILE_BEGIN)
				If $i = $MaxPages-1 Then $tBuffer = DllStructCreate("byte[" & ($ChunkSize)+$SectorSize & "]")
				_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), ($ChunkSize)+$SectorSize, $nBytes)
				$RawPage = DllStructGetData($tBuffer, 1)
				$CurrentFileOffset = DllCall('kernel32.dll', 'int', 'SetFilePointerEx', 'ptr', $hFile, 'int64', 0, 'int64*', 0, 'dword', 1)
				$CurrentFileOffset = $CurrentFileOffset[3]-$ChunkSize
				;$RecordOffset = "0x" & Hex(Int($CurrentFileOffset))
				$EntryCounter += _ScanModeI30ProcessPage(StringMid($RawPage,3),$i*($ChunkSize),0,$ChunkSize)
				If Not Mod($i,1000) Then
					FileFlush($IndxEntriesI30CsvFile)
				EndIf
			Next
	EndSelect

	AdlibUnRegister("_IndxProgress")
	$MaxRecords = $CurrentRecord+1
	_IndxProgress()
	ProgressOff()

	If $EntryCounter < 1 Then
		_DumpOutput("Error: No valid $I30 entries could be decoded." & @CRLF)
		If $CleanUp Then
			FileFlush($hDebugOutFile)
			FileClose($hDebugOutFile)
			FileDelete($IndxEntriesI30CsvFile)
			FileDelete($IndxEntriesObjIdOCsvFile)
			FileDelete($IndxI30SqlFile)
			FileDelete($IndxObjectIdSqlFile)
			FileDelete($DebugOutFile)
		Else
			FileMove($IndxEntriesI30CsvFile,$IndxEntriesI30CsvFile&".empty",1)
			_DumpOutput("Empty output: " & $IndxEntriesI30CsvFile & " is postfixed with .empty" & @CRLF)
			FileMove($IndxEntriesObjIdOCsvFile,$IndxEntriesObjIdOCsvFile&".empty",1)
			_DumpOutput("Empty output: " & $IndxEntriesObjIdOCsvFile & " is postfixed with .empty" & @CRLF)
			FileMove($IndxEntriesReparseRCsvFile,$IndxEntriesReparseRCsvFile&".empty",1)
			_DumpOutput("Empty output: " & $IndxEntriesReparseRCsvFile & " is postfixed with .empty" & @CRLF)
;			If (_FileCountLines($IndxEntriesObjIdOCsvFile) < 2) Then
;				FileMove($IndxEntriesObjIdOCsvFile,$IndxEntriesObjIdOCsvFile&".empty",1)
;				_DumpOutput("Empty output: " & $IndxEntriesObjIdOCsvFile & " is postfixed with .empty")
;			EndIf
		EndIf
		If Not $CommandlineMode Then
			_DisplayInfo("Error: No valid $I30 or $O entries could be decoded." & @CRLF)
			Return
		Else
			Exit(1)
		EndIf
	EndIf

	If Not $CommandlineMode Then _DisplayInfo("Entries found and decoded: " & $EntryCounter & @CRLF)
	_DumpOutput("Pages processed: " & $MaxRecords & @CRLF)
	_DumpOutput("Entries found and decoded: " & $EntryCounter & @CRLF)
	If Not $CommandlineMode Then _DisplayInfo("Parsing finished in " & _WinAPI_StrFromTimeInterval(TimerDiff($begin)) & @CRLF)
	_DumpOutput("Parsing finished in " & _WinAPI_StrFromTimeInterval(TimerDiff($begin)) & @CRLF)
	_WinAPI_CloseHandle($hFile)
	FileFlush($hDebugOutFile)
	FileClose($hDebugOutFile)
	FileFlush($IndxEntriesI30Csv)
	FileClose($IndxEntriesI30Csv)
	FileFlush($IndxEntriesObjIdOCsv)
	FileClose($IndxEntriesObjIdOCsv)
	FileFlush($IndxEntriesReparseRCsv)
	FileClose($IndxEntriesReparseRCsv)

	If $CleanUp Then
		FileDelete($IndxEntriesI30CsvFile)
		FileDelete($IndxEntriesObjIdOCsvFile)
		FileDelete($IndxI30SqlFile)
		FileDelete($IndxObjectIdSqlFile)
		FileDelete($DebugOutFile)
	Else
		If (_FileCountLines($IndxEntriesI30CsvFile) < 2) Then
			FileMove($IndxEntriesI30CsvFile,$IndxEntriesI30CsvFile&".empty",1)
			_DumpOutput("Empty output: " & $IndxEntriesI30CsvFile & " is postfixed with .empty")
		EndIf
		If (_FileCountLines($IndxEntriesObjIdOCsvFile) < 2) Then
			FileMove($IndxEntriesObjIdOCsvFile,$IndxEntriesObjIdOCsvFile&".empty",1)
			_DumpOutput("Empty output: " & $IndxEntriesObjIdOCsvFile & " is postfixed with .empty")
		EndIf
		If (_FileCountLines($IndxEntriesReparseRCsvFile) < 2) Then
			FileMove($IndxEntriesReparseRCsvFile,$IndxEntriesReparseRCsvFile&".empty",1)
			_DumpOutput("Empty output: " & $IndxEntriesReparseRCsvFile & " is postfixed with .empty")
		EndIf
	EndIf

	$ParserOutDir = ""
	$EntryCounter = 0
EndFunc

Func _ScanModeI30ProcessPage($TargetPage,$OffsetFile,$OffsetChunk,$EndOffset)
	Local $LocalEntryCounter = 0, $NextOffset = 1, $TotalSizeOfPage = StringLen($TargetPage)
	Do
;		_DumpOutput("$NextOffset: " & $NextOffset & @CRLF)
;		_DumpOutput("$NextOffset: 0x" & Hex(Int($OffsetFile + ($OffsetChunk + $NextOffset)/2)) & @CRLF)
		$SizeOfNextEntry = StringMid($TargetPage,$NextOffset+16,4)
		$SizeOfNextEntry = Dec(_SwapEndian($SizeOfNextEntry),2)
		$SizeOfNextEntry = $SizeOfNextEntry*2
		$SizeOfNextEntryTmp = $SizeOfNextEntry
		If $SizeOfNextEntryTmp < 512 Then
			;Pretend the entry is large enough to accomodate for possible longer filename
			$SizeOfNextEntryTmp = 512
		EndIf
		$NextEntry = StringMid($TargetPage,$NextOffset,$SizeOfNextEntryTmp)
		If _ScanModeI30DecodeEntry($NextEntry) Then
			$OffsetRecord = "0x" & Hex(Int($OffsetFile + ($OffsetChunk + $NextOffset)/2))
			If _NormalModeI30DecodeEntry($NextEntry, $OffsetRecord) Then
				$LocalEntryCounter += 1
			EndIf
			If $SizeOfNextEntryTmp > $SizeOfNextEntry Then
				$NextOffset+=2
			Else
				$NextOffset+=$SizeOfNextEntry
			EndIf
		Else
			If Not StringRegExp(StringMid($TargetPage,$NextOffset),$RegExPatternHexNotNull) Then
				_DumpOutput("The data on the rest of this page is just 00. Nothing to do here from offset 0x" & Hex(Int($OffsetFile + ($OffsetChunk + $NextOffset)/2)) & @CRLF)
				Return $LocalEntryCounter
			EndIf
			$NextOffset+=2
		EndIf

	Until $NextOffset > $TotalSizeOfPage Or $NextOffset/2 > $EndOffset
	Return $LocalEntryCounter
EndFunc

Func _ScanModeI30DecodeEntry($Record)

	$MFTReference = StringMid($Record,1,12)
	If $MFTReference = "FFFFFFFFFFFF" Then Return SetError(1,0,0)
	$MFTReference = Dec(_SwapEndian($MFTReference),2)
	If Not $VerifyFragment And $ScanMode < 1 Then
		If $MFTReference = 0 Then Return SetError(1,0,0)
	EndIf
	$MFTReferenceSeqNo = StringMid($Record,13,4)
	$MFTReferenceSeqNo = Dec(_SwapEndian($MFTReferenceSeqNo),2)
	If Not $VerifyFragment And $ScanMode < 1 Then
		If $MFTReferenceSeqNo = 0 Then Return SetError(2,0,0)
	EndIf
	$IndexEntryLength = StringMid($Record,17,4)
	$IndexEntryLength = Dec(_SwapEndian($IndexEntryLength),2)
	If Not $VerifyFragment And $ScanMode < 2 Then
		If ($IndexEntryLength = 0) Or ($IndexEntryLength = 0xFFFF) Then Return SetError(3,0,0)
	EndIf
	;$OffsetToFileName = StringMid($Record,21,4)
	;$OffsetToFileName = Dec(_SwapEndian($OffsetToFileName),2)
	;If $OffsetToFileName <> 82 Then Return SetError(4,0,0)
	$IndexFlags = StringMid($Record,25,4)
	$IndexFlags = Dec(_SwapEndian($IndexFlags),2)
	If Not $VerifyFragment And $ScanMode < 3 Then
		If $IndexFlags > 2 Then Return SetError(5,0,0)
	EndIf

	$Padding = StringMid($Record,29,4)
	If Not $VerifyFragment And $ScanMode < 4 Then
		If $Padding <> "0000" Then Return SetError(6,0,0)
	EndIf
	$MFTReferenceOfParent = StringMid($Record,33,12)
	$MFTReferenceOfParent = Dec(_SwapEndian($MFTReferenceOfParent),2)
	If Not $VerifyFragment And $ScanMode < 5 Then
		If $MFTReferenceOfParent < 5 Then Return SetError(7,0,0)
	EndIf
	$MFTReferenceOfParentSeqNo = StringMid($Record,45,4)
	$MFTReferenceOfParentSeqNo = Dec(_SwapEndian($MFTReferenceOfParentSeqNo),2)
	If Not $VerifyFragment And $ScanMode < 5 Then
		If $MFTReferenceOfParentSeqNo = 0 Then Return SetError(8,0,0)
	EndIf
	$CTime_Timestamp = StringMid($Record,49,16)
	If $ExtendedTimestampCheck Then
		$CTime_TimestampTmp = Dec(_SwapEndian($CTime_Timestamp),2)
		If $CTime_TimestampTmp < $TSCheckLow Or $CTime_TimestampTmp > $TSCheckHigh Then Return SetError(9,0,0) ;14 oktober 1957 - 31 mai 2043
	EndIf
	$CTime_Timestamp = _DecodeTimestamp($CTime_Timestamp)
	If $CTime_Timestamp = $TimestampErrorVal Then Return SetError(10,0,0)
	$ATime_Timestamp = StringMid($Record,65,16)
	If $ExtendedTimestampCheck Then
		$ATime_TimestampTmp = Dec(_SwapEndian($ATime_Timestamp),2)
		If $ATime_TimestampTmp < $TSCheckLow Or $ATime_TimestampTmp > $TSCheckHigh Then Return SetError(11,0,0) ;14 oktober 1957 - 31 mai 2043
	EndIf
	$ATime_Timestamp = _DecodeTimestamp($ATime_Timestamp)
	If $ATime_Timestamp = $TimestampErrorVal Then Return SetError(12,0,0)
	$MTime_Timestamp = StringMid($Record,81,16)
	If $ExtendedTimestampCheck Then
		;$MTime_TimestampTmp = Dec(_SwapEndian($MTime_Timestamp),2)
		;If $MTime_TimestampTmp < $TSCheckLow Or $MTime_TimestampTmp > $TSCheckHigh Then Return SetError(13,0,0) ;14 oktober 1957 - 31 mai 2043
	EndIf
	$MTime_Timestamp = _DecodeTimestamp($MTime_Timestamp)
	;-----------------------
	;If $MTime_Timestamp = $TimestampErrorVal Then Return SetError(14,0,0)
	;--------------------------
	$RTime_Timestamp = StringMid($Record,97,16)
	If $ExtendedTimestampCheck Then
		$RTime_TimestampTmp = Dec(_SwapEndian($RTime_Timestamp),2)
		If $RTime_TimestampTmp < $TSCheckLow Or $RTime_TimestampTmp > $TSCheckHigh Then Return SetError(15,0,0) ;14 oktober 1957 - 31 mai 2043
	EndIf
	$RTime_Timestamp = _DecodeTimestamp($RTime_Timestamp)
	If $RTime_Timestamp = $TimestampErrorVal Then Return SetError(16,0,0)
	$Indx_AllocSize = StringMid($Record,113,16)
	$Indx_AllocSize = Dec(_SwapEndian($Indx_AllocSize),2)
	If $Indx_AllocSize > 281474976710655 Then ;0xFFFFFFFFFFFF
		Return SetError(17,0,0)
	EndIf
	If $Indx_AllocSize > 0 And Mod($Indx_AllocSize,8) Then
		Return SetError(17,0,0)
	EndIf
	$Indx_RealSize = StringMid($Record,129,16)
	$Indx_RealSize = Dec(_SwapEndian($Indx_RealSize),2)
	If $Indx_RealSize > 281474976710655 Then ;0xFFFFFFFFFFFF
		Return SetError(18,0,0)
	EndIf
	If $Indx_RealSize > $Indx_AllocSize Then Return SetError(18,0,0)

	$Indx_File_Flags = StringMid($Record,145,8)
	$Indx_File_Flags = _SwapEndian($Indx_File_Flags)

	If BitAND("0x" & $Indx_File_Flags, 0x40000) Then
		$DoReparseTag=0
		$DoEaSize=1
	Else
		$DoReparseTag=1
		$DoEaSize=0
	EndIf
	$Indx_File_Flags = _File_Attributes("0x" & $Indx_File_Flags)

	Select
		Case $DoReparseTag
			$Indx_EaSize = ""
			$Indx_ReparseTag = StringMid($Record,153,8)
			$Indx_ReparseTag = _SwapEndian($Indx_ReparseTag)
			$Indx_ReparseTag = _GetReparseType("0x"&$Indx_ReparseTag)
			If StringInStr($Indx_ReparseTag,"UNKNOWN") Then Return SetError(19,0,0)
		Case $DoEaSize
			$Indx_ReparseTag = ""
			$Indx_EaSize = StringMid($Record,153,8)
			$Indx_EaSize = Dec(_SwapEndian($Indx_EaSize),2)
			If $Indx_EaSize < 8 Then Return SetError(19,0,0)
	EndSelect

	$Indx_NameLength = StringMid($Record,161,2)
	$Indx_NameLength = Dec($Indx_NameLength)
	If $Indx_NameLength = 0 Then Return SetError(20,0,0)
	$Indx_NameSpace = StringMid($Record,163,2)
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
	If $Indx_NameSpace = "Unknown" Then Return SetError(21,0,0)
	$Indx_FileName = StringMid($Record,165,$Indx_NameLength*4)
	$NameTest = 1
	Select
		Case $ExtendedNameCheckAll
;			_DumpOutput("$ExtendedNameCheckAll: " & $ExtendedNameCheckAll & @CRLF)
			$NameTest = _ValidateCharacterAndWindowsFileName($Indx_FileName)
		Case $ExtendedNameCheckChar
;			_DumpOutput("$ExtendedNameCheckChar: " & $ExtendedNameCheckChar & @CRLF)
			$NameTest = _ValidateCharacter($Indx_FileName)
		Case $ExtendedNameCheckWindows
;			_DumpOutput("$ExtendedNameCheckWindows: " & $ExtendedNameCheckWindows & @CRLF)
			$NameTest = _ValidateWindowsFileName($Indx_FileName)
	EndSelect
	If Not $NameTest Then Return SetError(22,0,0)
	$Indx_FileName = BinaryToString("0x"&$Indx_FileName,2)

	If @error Or $Indx_FileName = "" Then Return SetError(23,0,0)
	Return 1
EndFunc

Func _DecodeTimestamp($StampDecode)
	$StampDecode = _SwapEndian($StampDecode)
	$StampDecode_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $StampDecode)
	$StampDecode = _WinTime_UTCFileTimeFormat(Dec($StampDecode,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
	If @error Then
		$StampDecode = $TimestampErrorVal
	ElseIf $TimestampPrecision = 3 Then
		$StampDecode = $StampDecode & $PrecisionSeparator2 & _FillZero(StringRight($StampDecode_tmp, 4))
	EndIf
	Return $StampDecode
EndFunc

Func _NormalModeI30DecodeEntry($InputData, $OffsetRecord)
	$LocalOffset=1
	$TextInformation=""
	;$RecordOffset = "0x" & Hex(Int($CurrentFileOffset + (($LocalOffset-1)/2)))
	$RecordOffset = $OffsetRecord
	$MFTReference = StringMid($InputData,$LocalOffset,12)
	If $MFTReference = "FFFFFFFFFFFF" Then
		If $ScanMode < 1 Then Return SetError(1,0,0)
		$TextInformation &= ";MftRef"
	EndIf
	$MFTReference = Dec(_SwapEndian($MFTReference),2)
	If $MFTReference = 0 Then
		If $ScanMode < 1 Then Return SetError(1,0,0)
		$TextInformation &= ";MftRef"
	EndIf
	$MFTReferenceSeqNo = StringMid($InputData,$LocalOffset+12,4)
	$MFTReferenceSeqNo = Dec(_SwapEndian($MFTReferenceSeqNo),2)
	If $MFTReferenceSeqNo = 0 Then
		If $ScanMode < 1 Then Return SetError(2,0,0)
		If $TextInformation = "" Then $TextInformation &= ";MftRef"
		$TextInformation &= ";MftRefSeqNo"
	EndIf
	If $TextInformation = ";MftRef" Then $TextInformation &= ";MftRefSeqNo"
	$IndexEntryLength = StringMid($InputData,$LocalOffset+16,4)
	$IndexEntryLength = Dec(_SwapEndian($IndexEntryLength),2)
	If ($IndexEntryLength = 0) Or ($IndexEntryLength = 0xFFFF) Then
		If $ScanMode < 2 Then Return SetError(3,0,0)
		If $TextInformation = "" Then $TextInformation &= ";MftRef;MftRefSeqNo"
		$TextInformation &= ";IndexEntryLength"
	EndIf
	$OffsetToFileName = StringMid($InputData,$LocalOffset+20,4)
	$OffsetToFileName = Dec(_SwapEndian($OffsetToFileName),2)
	If ($OffsetToFileName = 0) Or ($OffsetToFileName = 0xFFFF) Then
		If $ScanMode < 2 Then Return SetError(4,0,0)
		If $TextInformation = "" Then $TextInformation &= ";MftRef;MftRefSeqNo;IndexEntryLength"
		$TextInformation &= ";OffsetToFileName"
	EndIf

	$IndexFlags = StringMid($InputData,$LocalOffset+24,4)
	$IndexFlags = Dec(_SwapEndian($IndexFlags),2)
	If $IndexFlags > 2 Then
		If $ScanMode < 3 Then Return SetError(5,0,0)
		If $TextInformation = "" Then $TextInformation &= ";MftRef;MftRefSeqNo;IndexEntryLength;OffsetToFileName"
		$TextInformation &= ";IndexFlags"
	EndIf

	$Padding = StringMid($InputData,$LocalOffset+28,4)
	If $Padding <> "0000" Then
		If $ScanMode < 4 Then Return SetError(6,0,0)
		If $TextInformation = "" Then $TextInformation &= ";MftRef;MftRefSeqNo;IndexEntryLength;OffsetToFileName;IndexFlags"
		$TextInformation &= ";Padding"
	EndIf
	$MFTReferenceOfParent = StringMid($InputData,$LocalOffset+32,12)
	$MFTReferenceOfParent = Dec(_SwapEndian($MFTReferenceOfParent),2)
	If $MFTReferenceOfParent < 5 Then
		If $ScanMode < 5 Then Return SetError(7,0,0)
		If $TextInformation = "" Then $TextInformation &= ";MftRef;MftRefSeqNo;IndexEntryLength;OffsetToFileName;IndexFlags;Padding"
		$TextInformation &= ";MFTReferenceOfParent"
	EndIf
	$MFTReferenceOfParentSeqNo = StringMid($InputData,$LocalOffset+44,4)
	$MFTReferenceOfParentSeqNo = Dec(_SwapEndian($MFTReferenceOfParentSeqNo),2)
	If $MFTReferenceOfParentSeqNo = 0 Then
		If $ScanMode < 5 Then Return SetError(8,0,0)
		If $TextInformation = "" Then $TextInformation &= ";MftRef;MftRefSeqNo;IndexEntryLength;OffsetToFileName;IndexFlags;Padding"
		$TextInformation &= ";MFTReferenceOfParentSeqNo"
	EndIf
	;CTime
	$Indx_CTime = StringMid($InputData, $LocalOffset + 48, 16)
	$Indx_CTime = _SwapEndian($Indx_CTime)
	If $ExtendedTimestampCheck Then
		$CTime_TimestampTmp = Dec($Indx_CTime,2)
		If $CTime_TimestampTmp < $TSCheckLow Or $CTime_TimestampTmp > $TSCheckHigh Then ;14 oktober 1957 - 31 mai 2043
			If $ScanMode < 6 Then Return SetError(9,0,0)
			If $TextInformation = "" Then $TextInformation &= ";MftRef;MftRefSeqNo;IndexEntryLength;OffsetToFileName;IndexFlags;Padding;MFTReferenceOfParent;MFTReferenceOfParentSeqNo"
			$TextInformation &= ";CTime"
		EndIf
	EndIf
	$Indx_CTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_CTime)
	$Indx_CTime = _WinTime_UTCFileTimeFormat(Dec($Indx_CTime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
	If @error Then
		$Indx_CTime = $TimestampErrorVal
	ElseIf $TimestampPrecision = 2 Then
		;$Indx_CTime_Core = StringMid($Indx_CTime,1,StringLen($Indx_CTime)-4)
		;$Indx_CTime_Precision = StringRight($Indx_CTime,3)
	ElseIf $TimestampPrecision = 3 Then
		$Indx_CTime = $Indx_CTime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_CTime_tmp, 4))
		;$Indx_CTime_Core = StringMid($Indx_CTime,1,StringLen($Indx_CTime)-9)
		;$Indx_CTime_Precision = StringRight($Indx_CTime,8)
	Else
		;$Indx_CTime_Core = $Indx_CTime
	EndIf
	If $Indx_CTime = $TimestampErrorVal Then
		If $ScanMode < 6 Then Return SetError(10,0,0)
		If $TextInformation = "" Then $TextInformation &= ";MftRef;MftRefSeqNo;IndexEntryLength;OffsetToFileName;IndexFlags;Padding;MFTReferenceOfParent;MFTReferenceOfParentSeqNo"
		$TextInformation &= ";CTime"
	EndIf
	;ATime
	$Indx_ATime = StringMid($InputData, $LocalOffset + 64, 16)
	$Indx_ATime = _SwapEndian($Indx_ATime)
	If $ExtendedTimestampCheck Then
		$ATime_TimestampTmp = Dec($Indx_ATime,2)
		If $ATime_TimestampTmp < $TSCheckLow Or $ATime_TimestampTmp > $TSCheckHigh Then ;14 oktober 1957 - 31 mai 2043
			If $ScanMode < 7 Then Return SetError(11,0,0)
			If $TextInformation = "" Then $TextInformation &= ";MftRef;MftRefSeqNo;IndexEntryLength;OffsetToFileName;IndexFlags;Padding;MFTReferenceOfParent;MFTReferenceOfParentSeqNo;CTime"
			$TextInformation &= ";ATime"
		EndIf
	EndIf
	$Indx_ATime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_ATime)
	$Indx_ATime = _WinTime_UTCFileTimeFormat(Dec($Indx_ATime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
	If @error Then
		$Indx_ATime = $TimestampErrorVal
	ElseIf $TimestampPrecision = 2 Then
		;$Indx_ATime_Core = StringMid($Indx_ATime,1,StringLen($Indx_ATime)-4)
		;$Indx_ATime_Precision = StringRight($Indx_ATime,3)
	ElseIf $TimestampPrecision = 3 Then
		$Indx_ATime = $Indx_ATime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_ATime_tmp, 4))
		;$Indx_ATime_Core = StringMid($Indx_ATime,1,StringLen($Indx_ATime)-9)
		;$Indx_ATime_Precision = StringRight($Indx_ATime,8)
	Else
		;$Indx_ATime_Core = $Indx_ATime
	EndIf
	If $Indx_ATime = $TimestampErrorVal Then
		If $ScanMode < 7 Then Return SetError(12,0,0)
		If $TextInformation = "" Then $TextInformation &= ";MftRef;MftRefSeqNo;IndexEntryLength;OffsetToFileName;IndexFlags;Padding;MFTReferenceOfParent;MFTReferenceOfParentSeqNo;CTime"
		$TextInformation &= ";ATime"
	EndIf
	;MTime
	$Indx_MTime = StringMid($InputData, $LocalOffset + 80, 16)
	$Indx_MTime = _SwapEndian($Indx_MTime)
	If $ExtendedTimestampCheck Then
		$MTime_TimestampTmp = Dec($Indx_MTime,2)
		If $MTime_TimestampTmp < $TSCheckLow Or $MTime_TimestampTmp > $TSCheckHigh Then ;14 oktober 1957 - 31 mai 2043
			If $ScanMode < 8 Then Return SetError(13,0,0)
			$TextInformation &= ";MTime"
		EndIf
	EndIf
	$Indx_MTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_MTime)
	$Indx_MTime = _WinTime_UTCFileTimeFormat(Dec($Indx_MTime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
	If @error Then
		$Indx_MTime = $TimestampErrorVal
	ElseIf $TimestampPrecision = 2 Then
		;$Indx_MTime_Core = StringMid($Indx_MTime,1,StringLen($Indx_MTime)-4)
		;$Indx_MTime_Precision = StringRight($Indx_MTime,3)
	ElseIf $TimestampPrecision = 3 Then
		$Indx_MTime = $Indx_MTime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_MTime_tmp, 4))
		;$Indx_MTime_Core = StringMid($Indx_MTime,1,StringLen($Indx_MTime)-9)
		;$Indx_MTime_Precision = StringRight($Indx_MTime,8)
	Else
		;$Indx_MTime_Core = $Indx_MTime
	EndIf
	If $Indx_MTime = $TimestampErrorVal Then
		If $ScanMode < 8 Then Return SetError(14,0,0)
		$TextInformation &= ";MTime"
	EndIf
	;RTime
	$Indx_RTime = StringMid($InputData, $LocalOffset + 96, 16)
	$Indx_RTime = _SwapEndian($Indx_RTime)
	If $ExtendedTimestampCheck Then
		$RTime_TimestampTmp = Dec($Indx_RTime,2)
		If $RTime_TimestampTmp < $TSCheckLow Or $RTime_TimestampTmp > $TSCheckHigh Then ;14 oktober 1957 - 31 mai 2043
			If $ScanMode < 9 Then Return SetError(15,0,0)
			$TextInformation &= ";RTime"
		EndIf
	EndIf
	$Indx_RTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_RTime)
	$Indx_RTime = _WinTime_UTCFileTimeFormat(Dec($Indx_RTime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
	If @error Then
		$Indx_RTime = $TimestampErrorVal
	ElseIf $TimestampPrecision = 2 Then
		;$Indx_RTime_Core = StringMid($Indx_RTime,1,StringLen($Indx_RTime)-4)
		;$Indx_RTime_Precision = StringRight($Indx_RTime,3)
	ElseIf $TimestampPrecision = 3 Then
		$Indx_RTime = $Indx_RTime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_RTime_tmp, 4))
		;$Indx_RTime_Core = StringMid($Indx_RTime,1,StringLen($Indx_RTime)-9)
		;$Indx_RTime_Precision = StringRight($Indx_RTime,8)
	Else
		;$Indx_RTime_Core = $Indx_RTime
	EndIf
	If $Indx_RTime = $TimestampErrorVal Then
		If $ScanMode < 9 Then Return SetError(16,0,0)
		$TextInformation &= ";RTime"
	EndIf
	;
	$Indx_AllocSize = StringMid($InputData,$LocalOffset+112,16)
	$Indx_AllocSize = Dec(_SwapEndian($Indx_AllocSize),2)
	If $Indx_AllocSize > 281474976710655 Then ;0xFFFFFFFFFFFF
		If $ScanMode < 10 Then Return SetError(17,0,0)
		$TextInformation &= ";AllocSize"
	EndIf
	If $Indx_AllocSize > 0 And Mod($Indx_AllocSize,8) Then
		If $ScanMode < 10 Then Return SetError(17,0,0)
		$TextInformation &= ";AllocSize"
	EndIf
	$Indx_RealSize = StringMid($InputData,$LocalOffset+128,16)
	$Indx_RealSize = Dec(_SwapEndian($Indx_RealSize),2)
	If $Indx_RealSize > 281474976710655 Then ;0xFFFFFFFFFFFF
		If $ScanMode < 11 Then Return SetError(18,0,0)
		$TextInformation &= ";RealSize"
	EndIf
	If $Indx_RealSize > $Indx_AllocSize Then
		If $ScanMode < 11 Then Return SetError(18,0,0)
		$TextInformation &= ";RealSize"
	EndIf
	#cs
	$Indx_File_Flags = StringMid($InputData,$LocalOffset+144,8)
	$Indx_File_Flags = _SwapEndian($Indx_File_Flags)
	$Indx_File_Flags = _File_Attributes("0x" & $Indx_File_Flags)
	$Indx_ReparseTag = StringMid($InputData,$LocalOffset+152,8)
	$Indx_ReparseTag = _SwapEndian($Indx_ReparseTag)
	$Indx_ReparseTag = _GetReparseType("0x"&$Indx_ReparseTag)
	If StringInStr($Indx_ReparseTag,"UNKNOWN") Then
		If $ScanMode < 13 Then Return SetError(19,0,0)
		$TextInformation &= ";ReparseTag"
	EndIf
	#ce
	;-----------------------------------------------
	$Indx_File_Flags = StringMid($InputData,$LocalOffset+144,8)
	$Indx_File_Flags = _SwapEndian($Indx_File_Flags)

	If BitAND("0x" & $Indx_File_Flags, 0x40000) Then
		$DoReparseTag=0
		$DoEaSize=1
	Else
		$DoReparseTag=1
		$DoEaSize=0
	EndIf
	$Indx_File_Flags = _File_Attributes("0x" & $Indx_File_Flags)

	Select
		Case $DoReparseTag
			$Indx_EaSize = ""
			$Indx_ReparseTag = StringMid($InputData,$LocalOffset+152,8)
			$Indx_ReparseTag = _SwapEndian($Indx_ReparseTag)
			$Indx_ReparseTag = _GetReparseType("0x"&$Indx_ReparseTag)
			If StringInStr($Indx_ReparseTag,"UNKNOWN") Then
				If $ScanMode < 13 Then Return SetError(19,0,0)
				$TextInformation &= ";ReparseTag"
			EndIf
		Case $DoEaSize
			$Indx_ReparseTag = ""
			$Indx_EaSize = StringMid($InputData,$LocalOffset+152,8)
			$Indx_EaSize = Dec(_SwapEndian($Indx_EaSize),2)
			If $Indx_EaSize < 8 Then
				If $ScanMode < 13 Then Return SetError(19,0,0)
				$TextInformation &= ";EaSize"
			EndIf
	EndSelect
	;--------------------------------------------
	$Indx_NameLength = StringMid($InputData,$LocalOffset+160,2)
	$Indx_NameLength = Dec($Indx_NameLength)
	If $Indx_NameLength = 0 Then
		If $ScanMode < 14 Then Return SetError(20,0,0)
		$TextInformation &= ";NameLength"
	EndIf
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
	If $Indx_NameSpace = "Unknown" Then
		If $ScanMode < 14 Then Return SetError(21,0,0)
		$TextInformation &= ";NameSpace"
	EndIf

	$Indx_FileName = StringMid($InputData,165,$Indx_NameLength*4)
	$NameTest = 1
	Select
		Case $ExtendedNameCheckAll
;			_DumpOutput("$ExtendedNameCheckAll: " & $ExtendedNameCheckAll & @CRLF)
			$NameTest = _ValidateCharacterAndWindowsFileName($Indx_FileName)
		Case $ExtendedNameCheckChar
;			_DumpOutput("$ExtendedNameCheckChar: " & $ExtendedNameCheckChar & @CRLF)
			$NameTest = _ValidateCharacter($Indx_FileName)
		Case $ExtendedNameCheckWindows
;			_DumpOutput("$ExtendedNameCheckWindows: " & $ExtendedNameCheckWindows & @CRLF)
			$NameTest = _ValidateWindowsFileName($Indx_FileName)
	EndSelect
	If Not $NameTest Then
		If $ScanMode < 15 Then Return SetError(22,0,0)
		$TextInformation &= ";FileName"
	EndIf
	$Indx_FileName = BinaryToString("0x"&$Indx_FileName,2)
	If @error Or $Indx_FileName = "" Then
		If $ScanMode < 15 Then Return SetError(23,0,0)
		$TextInformation &= ";FileName"
	EndIf

	If $VerifyFragment Then
		$RebuiltFragment = "0x" & StringMid($InputData,1,164+($Indx_NameLength*4))
		;ConsoleWrite(_HexEncode($RebuiltFragment) & @CRLF)
		_WriteOutputFragment()
		If @error Then
			If Not $CommandlineMode Then
				_DisplayInfo("Output fragment was verified but could not be written to: " & $ParserOutDir & "\" & $OutFragmentName & @CRLF)
				Return SetError(1)
			Else
				_DumpOutput("Output fragment was verified but could not be written to: " & $ParserOutDir & "\" & $OutFragmentName & @CRLF)
				Exit(4)
			EndIf
		Else
			ConsoleWrite("Output fragment verified and written to: " & $ParserOutDir & "\" & $OutFragmentName & @CRLF)
		EndIf
	EndIf
	Local $TextString=""
	If Not $DoDefaultAll Then
		$TextString &= " IndxLastLsn:" & $IndxLastLsn
		$TextString &= " IndexFlags:" & $IndexFlags
		$TextString &= " MftRefOfParent:" & $MFTReferenceOfParent
		$TextString &= " MftRefOfParentSeqNo:" & $MFTReferenceOfParentSeqNo
		$TextString &= " AllocSize:" & $Indx_AllocSize
		$TextString &= " RealSize:" & $Indx_RealSize
		$TextString &= " File_Flags:" & $Indx_File_Flags
		$TextString &= " ReparseTag:" & $Indx_ReparseTag
		$TextString &= " EaSize:" & $Indx_EaSize
		If $TextInformation <> "" Then
			$TextString &= " CorruptEntries:" & $TextInformation
		EndIf
	EndIf

	If $WithQuotes Then
		Select
			Case $DoDefaultAll
				FileWriteLine($IndxEntriesI30CsvFile, '"'&$RecordOffset&'"' & $de & '"'&$IndxCurrentVcn&'"' & $de & '"'&$IsNotLeafNode&'"' & $de & '"'&$IndxLastLsn&'"' & $de & '"'&1&'"' & $de & '"'&$Indx_FileName&'"' & $de & '"'&$MFTReference&'"' & $de & '"'&$MFTReferenceSeqNo&'"' & $de & '"'&$IndexFlags&'"' & $de & '"'&$MFTReferenceOfParent&'"' & $de & '"'&$MFTReferenceOfParentSeqNo&'"' & $de & '"'&$Indx_CTime&'"' & $de & '"'&$Indx_ATime&'"' & $de & '"'&$Indx_MTime&'"' & $de & '"'&$Indx_RTime&'"' & $de & '"'&$Indx_AllocSize&'"' & $de & '"'&$Indx_RealSize&'"' & $de & '"'&$Indx_File_Flags&'"' & $de & '"'&$Indx_ReparseTag&'"' & $de & '"'&$Indx_EaSize&'"' & $de & '"'&$Indx_NameSpace&'"' & $de & '"'&$SubNodeVCN&'"' & $de & '"'&$TextInformation&'"' & @crlf)
			Case $Dol2t
				FileWriteLine($IndxEntriesI30CsvFile, '"'&'"'& StringLeft($Indx_CTime,$CharsToGrabDate) &'"' & $de & '"'& StringMid($Indx_CTime,$CharStartTime,$CharsToGrabTime) &'"' & $de & '"'& $UTCconfig &'"' & $de & '"'&"C"&'"' & $de & '"'&"INDX"&'"' & $de & '"'&"I30"&'"' & $de & '"'& "" &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& $Indx_FileName &'"' & $de & '"'&$MFTReference&'"' & $de & '"'&"Offset:"&$RecordOffset&" Slack:" & 1 & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString&'"' & $de & '""' & $de & '""' & @CRLF)
				FileWriteLine($IndxEntriesI30CsvFile, '"'&'"'& StringLeft($Indx_ATime,$CharsToGrabDate) &'"' & $de & '"'& StringMid($Indx_ATime,$CharStartTime,$CharsToGrabTime) &'"' & $de & '"'& $UTCconfig &'"' & $de & '"'&"A"&'"' & $de & '"'&"INDX"&'"' & $de & '"'&"I30"&'"' & $de & '"'& "" &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& $Indx_FileName &'"' & $de & '"'&$MFTReference&'"' & $de & '"'&"Offset:"&$RecordOffset&" Slack:" & 1 & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString&'"' & $de & '""' & $de & '""' & @CRLF)
				FileWriteLine($IndxEntriesI30CsvFile, '"'&'"'& StringLeft($Indx_MTime,$CharsToGrabDate) &'"' & $de & '"'& StringMid($Indx_MTime,$CharStartTime,$CharsToGrabTime) &'"' & $de & '"'& $UTCconfig &'"' & $de & '"'&"M"&'"' & $de & '"'&"INDX"&'"' & $de & '"'&"I30"&'"' & $de & '"'& "" &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& $Indx_FileName &'"' & $de & '"'&$MFTReference&'"' & $de & '"'&"Offset:"&$RecordOffset&" Slack:" & 1 & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString&'"' & $de & '""' & $de & '""' & @CRLF)
				FileWriteLine($IndxEntriesI30CsvFile, '"'&'"'& StringLeft($Indx_RTime,$CharsToGrabDate) &'"' & $de & '"'& StringMid($Indx_RTime,$CharStartTime,$CharsToGrabTime) &'"' & $de & '"'& $UTCconfig &'"' & $de & '"'&"R"&'"' & $de & '"'&"INDX"&'"' & $de & '"'&"I30"&'"' & $de & '"'& "" &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& $Indx_FileName &'"' & $de & '"'&$MFTReference&'"' & $de & '"'&"Offset:"&$RecordOffset&" Slack:" & 1 & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString&'"' & $de & '""' & $de & '""' & @CRLF)
			Case $DoBodyfile
				FileWriteLine($IndxEntriesI30CsvFile, '""' & $de & '"'& "I30" &'"' & $de & '"'&$MFTReference&'"' & $de & '"'& "Offset:"&$RecordOffset&" Slack:" & 1 & " FileName:"&$Indx_FileName& " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& $Indx_ATime &'"' & $de & '"'& $Indx_MTime &'"' & $de & '"'& $Indx_CTime &'"' & $de & '"'& $Indx_RTime &'"' & @CRLF)
		EndSelect
	Else
		Select
			Case $DoDefaultAll
				FileWriteLine($IndxEntriesI30CsvFile, $RecordOffset & $de & $IndxCurrentVcn & $de & $IsNotLeafNode & $de & $IndxLastLsn & $de & 1 & $de & $Indx_FileName & $de & $MFTReference & $de & $MFTReferenceSeqNo & $de & $IndexFlags & $de & $MFTReferenceOfParent & $de & $MFTReferenceOfParentSeqNo & $de & $Indx_CTime & $de & $Indx_ATime & $de & $Indx_MTime & $de & $Indx_RTime & $de & $Indx_AllocSize & $de & $Indx_RealSize & $de & $Indx_File_Flags & $de & $Indx_ReparseTag & $de & $Indx_EaSize & $de & $Indx_NameSpace & $de & $SubNodeVCN & $de & $TextInformation & @crlf)
			Case $Dol2t
				FileWriteLine($IndxEntriesI30CsvFile, StringLeft($Indx_CTime,$CharsToGrabDate) & $de & StringMid($Indx_CTime,$CharStartTime,$CharsToGrabTime) & $de & $UTCconfig & $de & "C" & $de & "INDX" & $de & "I30" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & $Indx_FileName & $de & $MFTReference & $de & "Offset:"&$RecordOffset&" Slack:" & 1 & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString & $de & "" & $de & "" & @CRLF)
				FileWriteLine($IndxEntriesI30CsvFile, StringLeft($Indx_ATime,$CharsToGrabDate) & $de & StringMid($Indx_ATime,$CharStartTime,$CharsToGrabTime) & $de & $UTCconfig & $de & "A" & $de & "INDX" & $de & "I30" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & $Indx_FileName & $de & $MFTReference & $de & "Offset:"&$RecordOffset&" Slack:" & 1 & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString & $de & "" & $de & "" & @CRLF)
				FileWriteLine($IndxEntriesI30CsvFile, StringLeft($Indx_MTime,$CharsToGrabDate) & $de & StringMid($Indx_MTime,$CharStartTime,$CharsToGrabTime) & $de & $UTCconfig & $de & "M" & $de & "INDX" & $de & "I30" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & $Indx_FileName & $de & $MFTReference & $de & "Offset:"&$RecordOffset&" Slack:" & 1 & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString & $de & "" & $de & "" & @CRLF)
				FileWriteLine($IndxEntriesI30CsvFile, StringLeft($Indx_RTime,$CharsToGrabDate) & $de & StringMid($Indx_RTime,$CharStartTime,$CharsToGrabTime) & $de & $UTCconfig & $de & "R" & $de & "INDX" & $de & "I30" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & $Indx_FileName & $de & $MFTReference & $de & "Offset:"&$RecordOffset&" Slack:" & 1 & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString & $de & "" & $de & "" & @CRLF)
			Case $DoBodyfile
				FileWriteLine($IndxEntriesI30CsvFile, "" & $de & "I30" & $de & $MFTReference & $de & "Offset:"&$RecordOffset&" Slack:" & 1 & " FileName:"&$Indx_FileName& " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString & $de & "" & $de & "" & $de & "" & $de &  $Indx_ATime  & $de &  $Indx_MTime  & $de &  $Indx_CTime  & $de &  $Indx_RTime  & @CRLF)
		EndSelect
	EndIf

	Return 1
EndFunc

Func _WriteCSVHeaderIndxEntries()
	Local $a
	If $WithQuotes Then
		$a = '"'
	Else
		$a = ""
	EndIf
	If $DoDefaultAll Then
		$Indx_Csv_Header = $a&"Offset"&$a&$de&$a&"Vcn"&$a&$de&$a&"IsNotLeaf"&$a&$de&$a&"LastLsn"&$a&$de&$a&"FromIndxSlack"&$a&$de&$a&"FileName"&$a&$de&$a&"MFTReference"&$a&$de&$a&"MFTReferenceSeqNo"&$a&$de&$a&"IndexFlags"&$a&$de&$a&"MFTParentReference"&$a&$de&$a&"MFTParentReferenceSeqNo"&$a&$de&$a&"CTime"&$a&$de&$a&"ATime"&$a&$de&$a&"MTime"&$a&$de&$a&"RTime"&$a&$de&$a&"AllocSize"&$a&$de&$a&"RealSize"&$a&$de&$a&"FileFlags"&$a&$de&$a&"ReparseTag"&$a&$de&$a&"EaSize"&$a&$de&$a&"NameSpace"&$a&$de&$a&"SubNodeVCN"&$a&$de&$a&"CorruptEntries"&$a
	ElseIf $Dol2t Then
		$Indx_Csv_Header = $a&"Date"&$a&$de&$a&"Time"&$a&$de&$a&"Timezone"&$a&$de&$a&"MACB"&$a&$de&$a&"Source"&$a&$de&$a&"SourceType"&$a&$de&$a&"Type"&$a&$de&$a&"User"&$a&$de&$a&"Host"&$a&$de&$a&"Short"&$a&$de&$a&"Desc"&$a&$de&$a&"Version"&$a&$de&$a&"Filename"&$a&$de&$a&"Inode"&$a&$de&$a&"Notes"&$a&$de&$a&"Format"&$a&$de&$a&"Extra"&$a
	ElseIf $DoBodyfile Then
		$Indx_Csv_Header = $a&"MD5"&$a&$de&$a&"name"&$a&$de&$a&"inode"&$a&$de&$a&"mode_as_string"&$a&$de&$a&"UID"&$a&$de&$a&"GID"&$a&$de&$a&"size"&$a&$de&$a&"atime"&$a&$de&$a&"mtime"&$a&$de&$a&"ctime"&$a&$de&$a&"crtime"&$a
	EndIf
	FileWriteLine($IndxEntriesI30CsvFile, $Indx_Csv_Header & @CRLF)
EndFunc

Func _ParseCoreValidData($InputData,$FirstEntryOffset)
	Local $LocalOffset = 1, $SubNodeVCN, $EntryCounter=0
	$TextInformation=""
;	$IndxLastLsn = -1
;	ConsoleWrite("_ParseCoreData():" & @crlf)
;	ConsoleWrite(_HexEncode("0x"&$InputData) & @crlf)
	$SizeofIndxRecord = StringLen($InputData)
	While 1
		$RecordOffset = "0x" & Hex(Int($CurrentFileOffset + (($LocalOffset-1)/2) + $FirstEntryOffset))
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
		;$Padding = StringMid($InputData,$LocalOffset+28,4)
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
			;$Indx_CTime_Core = StringMid($Indx_CTime,1,StringLen($Indx_CTime)-4)
			;$Indx_CTime_Precision = StringRight($Indx_CTime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_CTime = $Indx_CTime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_CTime_tmp, 4))
			;$Indx_CTime_Core = StringMid($Indx_CTime,1,StringLen($Indx_CTime)-9)
			;$Indx_CTime_Precision = StringRight($Indx_CTime,8)
		Else
			;$Indx_CTime_Core = $Indx_CTime
		EndIf
		;
		$Indx_ATime = StringMid($InputData, $LocalOffset + 64, 16)
		$Indx_ATime = _SwapEndian($Indx_ATime)
		$Indx_ATime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_ATime)
		$Indx_ATime = _WinTime_UTCFileTimeFormat(Dec($Indx_ATime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
		If @error Then
			$Indx_ATime = $TimestampErrorVal
		ElseIf $TimestampPrecision = 2 Then
			;$Indx_ATime_Core = StringMid($Indx_ATime,1,StringLen($Indx_ATime)-4)
			;$Indx_ATime_Precision = StringRight($Indx_ATime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_ATime = $Indx_ATime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_ATime_tmp, 4))
			;$Indx_ATime_Core = StringMid($Indx_ATime,1,StringLen($Indx_ATime)-9)
			;$Indx_ATime_Precision = StringRight($Indx_ATime,8)
		Else
			;$Indx_ATime_Core = $Indx_ATime
		EndIf
		;
		$Indx_MTime = StringMid($InputData, $LocalOffset + 80, 16)
		$Indx_MTime = _SwapEndian($Indx_MTime)
		$Indx_MTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_MTime)
		$Indx_MTime = _WinTime_UTCFileTimeFormat(Dec($Indx_MTime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
		If @error Then
			$Indx_MTime = $TimestampErrorVal
		ElseIf $TimestampPrecision = 2 Then
			;$Indx_MTime_Core = StringMid($Indx_MTime,1,StringLen($Indx_MTime)-4)
			;$Indx_MTime_Precision = StringRight($Indx_MTime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_MTime = $Indx_MTime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_MTime_tmp, 4))
			;$Indx_MTime_Core = StringMid($Indx_MTime,1,StringLen($Indx_MTime)-9)
			;$Indx_MTime_Precision = StringRight($Indx_MTime,8)
		Else
			;$Indx_MTime_Core = $Indx_MTime
		EndIf
		;
		$Indx_RTime = StringMid($InputData, $LocalOffset + 96, 16)
		$Indx_RTime = _SwapEndian($Indx_RTime)
		$Indx_RTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_RTime)
		$Indx_RTime = _WinTime_UTCFileTimeFormat(Dec($Indx_RTime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
		If @error Then
			$Indx_RTime = $TimestampErrorVal
		ElseIf $TimestampPrecision = 2 Then
			;$Indx_RTime_Core = StringMid($Indx_RTime,1,StringLen($Indx_RTime)-4)
			;$Indx_RTime_Precision = StringRight($Indx_RTime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_RTime = $Indx_RTime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_RTime_tmp, 4))
			;$Indx_RTime_Core = StringMid($Indx_RTime,1,StringLen($Indx_RTime)-9)
			;$Indx_RTime_Precision = StringRight($Indx_RTime,8)
		Else
			;$Indx_RTime_Core = $Indx_RTime
		EndIf
		;
		$Indx_AllocSize = StringMid($InputData,$LocalOffset+112,16)
		$Indx_AllocSize = Dec(_SwapEndian($Indx_AllocSize),2)
		$Indx_RealSize = StringMid($InputData,$LocalOffset+128,16)
		$Indx_RealSize = Dec(_SwapEndian($Indx_RealSize),2)
		$Indx_File_Flags = StringMid($InputData,$LocalOffset+144,8)
		$Indx_File_Flags = _SwapEndian($Indx_File_Flags)

		If BitAND("0x" & $Indx_File_Flags, 0x40000) Then
			$DoReparseTag=0
			$DoEaSize=1
		Else
			$DoReparseTag=1
			$DoEaSize=0
		EndIf
		$Indx_File_Flags = _File_Attributes("0x" & $Indx_File_Flags)

		Select
			Case $DoReparseTag
				$Indx_EaSize = ""
				$Indx_ReparseTag = StringMid($InputData,$LocalOffset+152,8)
				$Indx_ReparseTag = _SwapEndian($Indx_ReparseTag)
				$Indx_ReparseTag = _GetReparseType("0x"&$Indx_ReparseTag)
				;If StringInStr($Indx_ReparseTag,"UNKNOWN") Then Return SetError(19,0,0)
			Case $DoEaSize
				$Indx_ReparseTag = ""
				$Indx_EaSize = StringMid($InputData,$LocalOffset+152,8)
				$Indx_EaSize = Dec(_SwapEndian($Indx_EaSize),2)
				;If $Indx_EaSize < 8 Then Return SetError(19,0,0)
		EndSelect
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

		If $LocalOffset > 180 And $EntryCounter = 0 Then
			;This INDX is most likely not $I30.
			Return 0
		EndIf

		If $LocalOffset >= $SizeofIndxRecord Then
			Return $EntryCounter
		EndIf

		If $MFTReferenceSeqNo > 0 And $MFTReferenceOfParent > 4 And $Indx_NameLength > 0 Then
			If $MFTReference > 11 And ($Indx_CTime=$TimestampErrorVal Or $Indx_ATime=$TimestampErrorVal Or $Indx_MTime=$TimestampErrorVal Or $Indx_RTime=$TimestampErrorVal) Then
				Return $EntryCounter
			EndIf

			Local $TextString=""
			If Not $DoDefaultAll Then
				$TextString &= " IndxLastLsn:" & $IndxLastLsn
				$TextString &= " IndexFlags:" & $IndexFlags
				$TextString &= " MftRefOfParent:" & $MFTReferenceOfParent
				$TextString &= " MftRefOfParentSeqNo:" & $MFTReferenceOfParentSeqNo
				$TextString &= " AllocSize:" & $Indx_AllocSize
				$TextString &= " RealSize:" & $Indx_RealSize
				$TextString &= " File_Flags:" & $Indx_File_Flags
				$TextString &= " ReparseTag:" & $Indx_ReparseTag
				$TextString &= " EaSize:" & $Indx_EaSize
			EndIf

			If $WithQuotes Then
				Select
					Case $DoDefaultAll
						FileWriteLine($IndxEntriesI30CsvFile, '"'&$RecordOffset&'"' & $de & '"'&$IndxCurrentVcn&'"' & $de & '"'&$IsNotLeafNode&'"' & $de & '"'&$IndxLastLsn&'"' & $de & '"'&$FromIndxSlack&'"' & $de & '"'&$Indx_FileName&'"' & $de & '"'&$MFTReference&'"' & $de & '"'&$MFTReferenceSeqNo&'"' & $de & '"'&$IndexFlags&'"' & $de & '"'&$MFTReferenceOfParent&'"' & $de & '"'&$MFTReferenceOfParentSeqNo&'"' & $de & '"'&$Indx_CTime&'"' & $de & '"'&$Indx_ATime&'"' & $de & '"'&$Indx_MTime&'"' & $de & '"'&$Indx_RTime&'"' & $de & '"'&$Indx_AllocSize&'"' & $de & '"'&$Indx_RealSize&'"' & $de & '"'&$Indx_File_Flags&'"' & $de & '"'&$Indx_ReparseTag&'"' & $de & '"'&$Indx_EaSize&'"' & $de & '"'&$Indx_NameSpace&'"' & $de & '"'&$SubNodeVCN&'"' & $de & '"'&$TextInformation&'"' & @crlf)
					Case $Dol2t
						FileWriteLine($IndxEntriesI30CsvFile, '"'&'"'& StringLeft($Indx_CTime,$CharsToGrabDate) &'"' & $de & '"'& StringMid($Indx_CTime,$CharStartTime,$CharsToGrabTime) &'"' & $de & '"'& $UTCconfig &'"' & $de & '"'&"C"&'"' & $de & '"'&"INDX"&'"' & $de & '"'&"I30"&'"' & $de & '"'& "" &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& $Indx_FileName &'"' & $de & '"'&$MFTReference&'"' & $de & '"'&"Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString&'"' & $de & '""' & $de & '""' & @CRLF)
						FileWriteLine($IndxEntriesI30CsvFile, '"'&'"'& StringLeft($Indx_ATime,$CharsToGrabDate) &'"' & $de & '"'& StringMid($Indx_ATime,$CharStartTime,$CharsToGrabTime) &'"' & $de & '"'& $UTCconfig &'"' & $de & '"'&"A"&'"' & $de & '"'&"INDX"&'"' & $de & '"'&"I30"&'"' & $de & '"'& "" &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& $Indx_FileName &'"' & $de & '"'&$MFTReference&'"' & $de & '"'&"Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString&'"' & $de & '""' & $de & '""' & @CRLF)
						FileWriteLine($IndxEntriesI30CsvFile, '"'&'"'& StringLeft($Indx_MTime,$CharsToGrabDate) &'"' & $de & '"'& StringMid($Indx_MTime,$CharStartTime,$CharsToGrabTime) &'"' & $de & '"'& $UTCconfig &'"' & $de & '"'&"M"&'"' & $de & '"'&"INDX"&'"' & $de & '"'&"I30"&'"' & $de & '"'& "" &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& $Indx_FileName &'"' & $de & '"'&$MFTReference&'"' & $de & '"'&"Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString&'"' & $de & '""' & $de & '""' & @CRLF)
						FileWriteLine($IndxEntriesI30CsvFile, '"'&'"'& StringLeft($Indx_RTime,$CharsToGrabDate) &'"' & $de & '"'& StringMid($Indx_RTime,$CharStartTime,$CharsToGrabTime) &'"' & $de & '"'& $UTCconfig &'"' & $de & '"'&"R"&'"' & $de & '"'&"INDX"&'"' & $de & '"'&"I30"&'"' & $de & '"'& "" &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& $Indx_FileName &'"' & $de & '"'&$MFTReference&'"' & $de & '"'&"Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString&'"' & $de & '""' & $de & '""' & @CRLF)
					Case $DoBodyfile
						FileWriteLine($IndxEntriesI30CsvFile, '""' & $de & '"'& "I30" &'"' & $de & '"'&$MFTReference&'"' & $de & '"'& "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " FileName:"&$Indx_FileName& " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& $Indx_ATime &'"' & $de & '"'& $Indx_MTime &'"' & $de & '"'& $Indx_CTime &'"' & $de & '"'& $Indx_RTime &'"' & @CRLF)
				EndSelect
			Else
				Select
					Case $DoDefaultAll
						FileWriteLine($IndxEntriesI30CsvFile, $RecordOffset & $de & $IndxCurrentVcn & $de & $IsNotLeafNode & $de & $IndxLastLsn & $de & $FromIndxSlack & $de & $Indx_FileName & $de & $MFTReference & $de & $MFTReferenceSeqNo & $de & $IndexFlags & $de & $MFTReferenceOfParent & $de & $MFTReferenceOfParentSeqNo & $de & $Indx_CTime & $de & $Indx_ATime & $de & $Indx_MTime & $de & $Indx_RTime & $de & $Indx_AllocSize & $de & $Indx_RealSize & $de & $Indx_File_Flags & $de & $Indx_ReparseTag & $de & $Indx_EaSize & $de & $Indx_NameSpace & $de & $SubNodeVCN & $de & $TextInformation & @crlf)
					Case $Dol2t
						FileWriteLine($IndxEntriesI30CsvFile, StringLeft($Indx_CTime,$CharsToGrabDate) & $de & StringMid($Indx_CTime,$CharStartTime,$CharsToGrabTime) & $de & $UTCconfig & $de & "C" & $de & "INDX" & $de & "I30" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & $Indx_FileName & $de & $MFTReference & $de & "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString & $de & "" & $de & "" & @CRLF)
						FileWriteLine($IndxEntriesI30CsvFile, StringLeft($Indx_ATime,$CharsToGrabDate) & $de & StringMid($Indx_ATime,$CharStartTime,$CharsToGrabTime) & $de & $UTCconfig & $de & "A" & $de & "INDX" & $de & "I30" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & $Indx_FileName & $de & $MFTReference & $de & "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString & $de & "" & $de & "" & @CRLF)
						FileWriteLine($IndxEntriesI30CsvFile, StringLeft($Indx_MTime,$CharsToGrabDate) & $de & StringMid($Indx_MTime,$CharStartTime,$CharsToGrabTime) & $de & $UTCconfig & $de & "M" & $de & "INDX" & $de & "I30" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & $Indx_FileName & $de & $MFTReference & $de & "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString & $de & "" & $de & "" & @CRLF)
						FileWriteLine($IndxEntriesI30CsvFile, StringLeft($Indx_RTime,$CharsToGrabDate) & $de & StringMid($Indx_RTime,$CharStartTime,$CharsToGrabTime) & $de & $UTCconfig & $de & "R" & $de & "INDX" & $de & "I30" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & $Indx_FileName & $de & $MFTReference & $de & "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString & $de & "" & $de & "" & @CRLF)
					Case $DoBodyfile
						FileWriteLine($IndxEntriesI30CsvFile, "" & $de & "I30" & $de & $MFTReference & $de & "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " FileName:"&$Indx_FileName& " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString & $de & "" & $de & "" & $de & "" & $de &  $Indx_ATime  & $de &  $Indx_MTime  & $de &  $Indx_CTime  & $de &  $Indx_RTime  & @CRLF)
				EndSelect
			EndIf
			$LocalOffset += $IndexEntryLength*2
			$EntryCounter+=1
			_ClearVar()
			ContinueLoop
		Else
			;ConsoleWrite("Error: Validation of entry failed." & @CRLF)
			Return $EntryCounter
		EndIf
		_ClearVar()
	WEnd
EndFunc

Func _ParseCoreSlackSpace($InputData,$SkeewedOffset)
	Local $LocalOffset = 1, $SubNodeVCN, $EntryCounter=0, $AllTimestampsValid=1
	$TextInformation=""
	$IndxLastLsn = -1
;	ConsoleWrite("_ParseCoreSlackSpace():" & @crlf)
;	ConsoleWrite(_HexEncode("0x"&$InputData) & @crlf)
	$SizeofIndxRecord = StringLen($InputData)
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
		$CTime_TimestampTmp = Dec($Indx_CTime,2)
		$Indx_CTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_CTime)
		$Indx_CTime = _WinTime_UTCFileTimeFormat(Dec($Indx_CTime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
		If @error Then
			$Indx_CTime = $TimestampErrorVal
		ElseIf $TimestampPrecision = 2 Then
			;$Indx_CTime_Core = StringMid($Indx_CTime,1,StringLen($Indx_CTime)-4)
			;$Indx_CTime_Precision = StringRight($Indx_CTime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_CTime = $Indx_CTime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_CTime_tmp, 4))
			;$Indx_CTime_Core = StringMid($Indx_CTime,1,StringLen($Indx_CTime)-9)
			;$Indx_CTime_Precision = StringRight($Indx_CTime,8)
		Else
			;$Indx_CTime_Core = $Indx_CTime
		EndIf
		;
		$Indx_ATime = StringMid($InputData, $LocalOffset + 64, 16)
		$Indx_ATime = _SwapEndian($Indx_ATime)
		$ATime_TimestampTmp = Dec($Indx_ATime,2)
		$Indx_ATime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_ATime)
		$Indx_ATime = _WinTime_UTCFileTimeFormat(Dec($Indx_ATime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
		If @error Then
			$Indx_ATime = $TimestampErrorVal
		ElseIf $TimestampPrecision = 2 Then
			;$Indx_ATime_Core = StringMid($Indx_ATime,1,StringLen($Indx_ATime)-4)
			;$Indx_ATime_Precision = StringRight($Indx_ATime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_ATime = $Indx_ATime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_ATime_tmp, 4))
			;$Indx_ATime_Core = StringMid($Indx_ATime,1,StringLen($Indx_ATime)-9)
			;$Indx_ATime_Precision = StringRight($Indx_ATime,8)
		Else
			;$Indx_ATime_Core = $Indx_ATime
		EndIf
		;
		$Indx_MTime = StringMid($InputData, $LocalOffset + 80, 16)
		$Indx_MTime = _SwapEndian($Indx_MTime)
		$MTime_TimestampTmp = Dec($Indx_MTime,2)
		$Indx_MTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_MTime)
		$Indx_MTime = _WinTime_UTCFileTimeFormat(Dec($Indx_MTime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
		If @error Then
			$Indx_MTime = $TimestampErrorVal
		ElseIf $TimestampPrecision = 2 Then
			;$Indx_MTime_Core = StringMid($Indx_MTime,1,StringLen($Indx_MTime)-4)
			;$Indx_MTime_Precision = StringRight($Indx_MTime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_MTime = $Indx_MTime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_MTime_tmp, 4))
			;$Indx_MTime_Core = StringMid($Indx_MTime,1,StringLen($Indx_MTime)-9)
			;$Indx_MTime_Precision = StringRight($Indx_MTime,8)
		Else
			;$Indx_MTime_Core = $Indx_MTime
		EndIf
		;
		$Indx_RTime = StringMid($InputData, $LocalOffset + 96, 16)
		$Indx_RTime = _SwapEndian($Indx_RTime)
		$RTime_TimestampTmp = Dec($Indx_RTime,2)
		$Indx_RTime_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $Indx_RTime)
		$Indx_RTime = _WinTime_UTCFileTimeFormat(Dec($Indx_RTime,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
		If @error Then
			$Indx_RTime = $TimestampErrorVal
		ElseIf $TimestampPrecision = 2 Then
			;$Indx_RTime_Core = StringMid($Indx_RTime,1,StringLen($Indx_RTime)-4)
			;$Indx_RTime_Precision = StringRight($Indx_RTime,3)
		ElseIf $TimestampPrecision = 3 Then
			$Indx_RTime = $Indx_RTime & $PrecisionSeparator2 & _FillZero(StringRight($Indx_RTime_tmp, 4))
			;$Indx_RTime_Core = StringMid($Indx_RTime,1,StringLen($Indx_RTime)-9)
			;$Indx_RTime_Precision = StringRight($Indx_RTime,8)
		Else
			;$Indx_RTime_Core = $Indx_RTime
		EndIf
		;
		$Indx_AllocSize = StringMid($InputData,$LocalOffset+112,16)
		$Indx_AllocSize = Dec(_SwapEndian($Indx_AllocSize),2)
		$Indx_RealSize = StringMid($InputData,$LocalOffset+128,16)
		$Indx_RealSize = Dec(_SwapEndian($Indx_RealSize),2)
		$Indx_File_Flags = StringMid($InputData,$LocalOffset+144,8)
		$Indx_File_Flags = _SwapEndian($Indx_File_Flags)

		If BitAND("0x" & $Indx_File_Flags, 0x40000) Then
			$DoReparseTag=0
			$DoEaSize=1
		Else
			$DoReparseTag=1
			$DoEaSize=0
		EndIf
		$Indx_File_Flags = _File_Attributes("0x" & $Indx_File_Flags)

		Select
			Case $DoReparseTag
				$Indx_EaSize = ""
				$Indx_ReparseTag = StringMid($InputData,$LocalOffset+152,8)
				$Indx_ReparseTag = _SwapEndian($Indx_ReparseTag)
				$Indx_ReparseTag = _GetReparseType("0x"&$Indx_ReparseTag)
;				If StringInStr($Indx_ReparseTag,"UNKNOWN") Then Return SetError(19,0,0)
			Case $DoEaSize
				$Indx_ReparseTag = ""
				$Indx_EaSize = StringMid($InputData,$LocalOffset+152,8)
				$Indx_EaSize = Dec(_SwapEndian($Indx_EaSize),2)
;				If $Indx_EaSize < 8 Then Return SetError(19,0,0)
		EndSelect
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
		If $StrictNameCheck Then
		;If $SkipUnicodeNames Then
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

		If $LocalOffset >= $SizeofIndxRecord Then
			Return $EntryCounter
		EndIf

		If $LocalOffset > 800 And $EntryCounter = 0 Then
			;This INDX is most likely not $I30.
			Return 0
		EndIf
		#cs
		$OffsetToFileName_tmp = $OffsetToFileName
		If Mod($OffsetToFileName_tmp,8) Then
			While 1
				$OffsetToFileName_tmp+=1
				If Mod($OffsetToFileName_tmp,8) = 0 Then ExitLoop
			WEnd
		EndIf
		#ce
		$AllTimestampsValid = 1
		If $ExtendedTimestampCheck Then
			If ($CTime_TimestampTmp < $TSCheckLow Or $CTime_TimestampTmp > $TSCheckHigh) And ($ATime_TimestampTmp < $TSCheckLow Or $ATime_TimestampTmp > $TSCheckHigh) And ($MTime_TimestampTmp < $TSCheckLow Or $MTime_TimestampTmp > $TSCheckHigh) And ($RTime_TimestampTmp < $TSCheckLow Or $RTime_TimestampTmp > $TSCheckHigh) Then
				$AllTimestampsValid = 0
			EndIf
		EndIf

		If $AllTimestampsValid And $FileNameHealthy And $Indx_NameLength > 0 And $Indx_CTime<>$TimestampErrorVal And $Indx_ATime<>$TimestampErrorVal And $Indx_MTime<>$TimestampErrorVal And $Indx_RTime<>$TimestampErrorVal And $Indx_NameSpace <> "Unknown" And $Indx_ReparseTag <> "UNKNOWN" And $Indx_AllocSize >= $Indx_RealSize And Mod($Indx_AllocSize,8)=0 Then
			If $MFTReferenceSeqNo = 0 Then $TextInformation &= ";MftRef;MftRefSeqNo"
			If $IndexFlags > 2 Then $TextInformation &= ";IndexFlags"
			If $Padding <> "0000" Then $TextInformation &= ";Padding"
			If $MFTReferenceOfParentSeqNo = 0 Then $TextInformation &= ";MftRefOfParent;MftRefOfParentSeqNo"
			If ($DoReparseTag And StringInStr($Indx_ReparseTag,"UNKNOWN")) Then $TextInformation &= ";ReparseTag"
			If ($DoEaSize And $Indx_EaSize < 8) Then $TextInformation &= ";EaSize"
			;FileWriteLine($IndxEntriesI30CsvFile, $RecordOffset & $de & $IndxCurrentVcn & $de & $IsNotLeafNode & $de & $IndxLastLsn & $de & $FromIndxSlack & $de & $Indx_FileName & $de & $MFTReference & $de & $MFTReferenceSeqNo & $de & $IndexFlags & $de & $MFTReferenceOfParent & $de & $MFTReferenceOfParentSeqNo & $de & $Indx_CTime & $de & $Indx_ATime & $de & $Indx_MTime & $de & $Indx_RTime & $de & $Indx_AllocSize & $de & $Indx_RealSize & $de & $Indx_File_Flags & $de & $Indx_ReparseTag & $de & $Indx_EaSize & $de & $Indx_NameSpace & $de & $SubNodeVCN & $de & $TextInformation & @crlf)
			Local $TextString=""
			If Not $DoDefaultAll Then
				$TextString &= " IndxLastLsn:" & $IndxLastLsn
				$TextString &= " IndexFlags:" & $IndexFlags
				$TextString &= " MftRefOfParent:" & $MFTReferenceOfParent
				$TextString &= " MftRefOfParentSeqNo:" & $MFTReferenceOfParentSeqNo
				$TextString &= " AllocSize:" & $Indx_AllocSize
				$TextString &= " RealSize:" & $Indx_RealSize
				$TextString &= " File_Flags:" & $Indx_File_Flags
				$TextString &= " ReparseTag:" & $Indx_ReparseTag
				$TextString &= " EaSize:" & $Indx_EaSize
				If $TextInformation <> "" Then
					$TextString &= " CorruptEntries:" & $TextInformation
				EndIf
			EndIf

			If $WithQuotes Then
				Select
					Case $DoDefaultAll
						FileWriteLine($IndxEntriesI30CsvFile, '"'&$RecordOffset&'"' & $de & '"'&$IndxCurrentVcn&'"' & $de & '"'&$IsNotLeafNode&'"' & $de & '"'&$IndxLastLsn&'"' & $de & '"'&$FromIndxSlack&'"' & $de & '"'&$Indx_FileName&'"' & $de & '"'&$MFTReference&'"' & $de & '"'&$MFTReferenceSeqNo&'"' & $de & '"'&$IndexFlags&'"' & $de & '"'&$MFTReferenceOfParent&'"' & $de & '"'&$MFTReferenceOfParentSeqNo&'"' & $de & '"'&$Indx_CTime&'"' & $de & '"'&$Indx_ATime&'"' & $de & '"'&$Indx_MTime&'"' & $de & '"'&$Indx_RTime&'"' & $de & '"'&$Indx_AllocSize&'"' & $de & '"'&$Indx_RealSize&'"' & $de & '"'&$Indx_File_Flags&'"' & $de & '"'&$Indx_ReparseTag&'"' & $de & '"'&$Indx_EaSize&'"' & $de & '"'&$Indx_NameSpace&'"' & $de & '"'&$SubNodeVCN&'"' & $de & '"'&$TextInformation&'"' & @crlf)
					Case $Dol2t
						FileWriteLine($IndxEntriesI30CsvFile, '"'&'"'& StringLeft($Indx_CTime,$CharsToGrabDate) &'"' & $de & '"'& StringMid($Indx_CTime,$CharStartTime,$CharsToGrabTime) &'"' & $de & '"'& $UTCconfig &'"' & $de & '"'&"C"&'"' & $de & '"'&"INDX"&'"' & $de & '"'&"I30"&'"' & $de & '"'& "" &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& $Indx_FileName &'"' & $de & '"'&$MFTReference&'"' & $de & '"'&"Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString&'"' & $de & '""' & $de & '""' & @CRLF)
						FileWriteLine($IndxEntriesI30CsvFile, '"'&'"'& StringLeft($Indx_ATime,$CharsToGrabDate) &'"' & $de & '"'& StringMid($Indx_ATime,$CharStartTime,$CharsToGrabTime) &'"' & $de & '"'& $UTCconfig &'"' & $de & '"'&"A"&'"' & $de & '"'&"INDX"&'"' & $de & '"'&"I30"&'"' & $de & '"'& "" &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& $Indx_FileName &'"' & $de & '"'&$MFTReference&'"' & $de & '"'&"Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString&'"' & $de & '""' & $de & '""' & @CRLF)
						FileWriteLine($IndxEntriesI30CsvFile, '"'&'"'& StringLeft($Indx_MTime,$CharsToGrabDate) &'"' & $de & '"'& StringMid($Indx_MTime,$CharStartTime,$CharsToGrabTime) &'"' & $de & '"'& $UTCconfig &'"' & $de & '"'&"M"&'"' & $de & '"'&"INDX"&'"' & $de & '"'&"I30"&'"' & $de & '"'& "" &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& $Indx_FileName &'"' & $de & '"'&$MFTReference&'"' & $de & '"'&"Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString&'"' & $de & '""' & $de & '""' & @CRLF)
						FileWriteLine($IndxEntriesI30CsvFile, '"'&'"'& StringLeft($Indx_RTime,$CharsToGrabDate) &'"' & $de & '"'& StringMid($Indx_RTime,$CharStartTime,$CharsToGrabTime) &'"' & $de & '"'& $UTCconfig &'"' & $de & '"'&"R"&'"' & $de & '"'&"INDX"&'"' & $de & '"'&"I30"&'"' & $de & '"'& "" &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& $Indx_FileName &'"' & $de & '"'&$MFTReference&'"' & $de & '"'&"Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString&'"' & $de & '""' & $de & '""' & @CRLF)
					Case $DoBodyfile
						FileWriteLine($IndxEntriesI30CsvFile, '""' & $de & '"'& "I30" &'"' & $de & '"'&$MFTReference&'"' & $de & '"'& "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " FileName:"&$Indx_FileName& " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& $Indx_ATime &'"' & $de & '"'& $Indx_MTime &'"' & $de & '"'& $Indx_CTime &'"' & $de & '"'& $Indx_RTime &'"' & @CRLF)
				EndSelect
			Else
				Select
					Case $DoDefaultAll
						FileWriteLine($IndxEntriesI30CsvFile, $RecordOffset & $de & $IndxCurrentVcn & $de & $IsNotLeafNode & $de & $IndxLastLsn & $de & $FromIndxSlack & $de & $Indx_FileName & $de & $MFTReference & $de & $MFTReferenceSeqNo & $de & $IndexFlags & $de & $MFTReferenceOfParent & $de & $MFTReferenceOfParentSeqNo & $de & $Indx_CTime & $de & $Indx_ATime & $de & $Indx_MTime & $de & $Indx_RTime & $de & $Indx_AllocSize & $de & $Indx_RealSize & $de & $Indx_File_Flags & $de & $Indx_ReparseTag & $de & $Indx_EaSize & $de & $Indx_NameSpace & $de & $SubNodeVCN & $de & $TextInformation & @crlf)
					Case $Dol2t
						FileWriteLine($IndxEntriesI30CsvFile, StringLeft($Indx_CTime,$CharsToGrabDate) & $de & StringMid($Indx_CTime,$CharStartTime,$CharsToGrabTime) & $de & $UTCconfig & $de & "C" & $de & "INDX" & $de & "I30" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & $Indx_FileName & $de & $MFTReference & $de & "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString & $de & "" & $de & "" & @CRLF)
						FileWriteLine($IndxEntriesI30CsvFile, StringLeft($Indx_ATime,$CharsToGrabDate) & $de & StringMid($Indx_ATime,$CharStartTime,$CharsToGrabTime) & $de & $UTCconfig & $de & "A" & $de & "INDX" & $de & "I30" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & $Indx_FileName & $de & $MFTReference & $de & "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString & $de & "" & $de & "" & @CRLF)
						FileWriteLine($IndxEntriesI30CsvFile, StringLeft($Indx_MTime,$CharsToGrabDate) & $de & StringMid($Indx_MTime,$CharStartTime,$CharsToGrabTime) & $de & $UTCconfig & $de & "M" & $de & "INDX" & $de & "I30" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & $Indx_FileName & $de & $MFTReference & $de & "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString & $de & "" & $de & "" & @CRLF)
						FileWriteLine($IndxEntriesI30CsvFile, StringLeft($Indx_RTime,$CharsToGrabDate) & $de & StringMid($Indx_RTime,$CharStartTime,$CharsToGrabTime) & $de & $UTCconfig & $de & "R" & $de & "INDX" & $de & "I30" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & $Indx_FileName & $de & $MFTReference & $de & "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString & $de & "" & $de & "" & @CRLF)
					Case $DoBodyfile
						FileWriteLine($IndxEntriesI30CsvFile, "" & $de & "I30" & $de & $MFTReference & $de & "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " FileName:"&$Indx_FileName& " MftRef:"&$MFTReference&" MftRefSeqNo:"&$MFTReferenceSeqNo & $TextString & $de & "" & $de & "" & $de & "" & $de &  $Indx_ATime  & $de &  $Indx_MTime  & $de &  $Indx_CTime  & $de &  $Indx_RTime  & @CRLF)
				EndSelect
			EndIf
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
	Local $IndxValidationTest=0, $LocalOffset = 3

	$IndxHdrMagic = StringMid($InputData,$LocalOffset,8)
	If $IndxHdrMagic <> $INDXsig Then Return 0
	If $DoFixups Then
		$InputData = _ApplyFixupsIndx(StringMid($InputData,3))
		If $InputData = "" Then
			_DumpOutput("Error: Fixups failed." & @CRLF)
			Return 0
		EndIf
	EndIf
;	$TestData = _ApplyFixupsIndx(StringMid($InputData,3))
;	If $TestData <> "" Then $InputData = $TestData
	$IndxLastLsn = Dec(_SwapEndian(StringMid($InputData,$LocalOffset+16,16)),2)
;	ConsoleWrite("$IndxLastLsn: " & $IndxLastLsn & @crlf)
;	If $IndxLastLsn = 0 Then
;		_DumpOutput("Error in $IndxLastLsn: " & $IndxLastLsn & @crlf)
;		Return 0
;	EndIf

	$IndxCurrentVcn = Dec(_SwapEndian(StringMid($InputData,$LocalOffset+32,16)),2)
;	ConsoleWrite("$IndxCurrentVcn: " & $IndxCurrentVcn & @crlf)
;	If $IndxCurrentVcn > 0xFFFFFFFFFF Then
;		_DumpOutput("Error in $IndxCurrentVcn: " & $IndxCurrentVcn & @crlf)
;		Return 0
;	EndIf

	$IndxHeaderSize = Dec(_SwapEndian(StringMid($InputData,$LocalOffset+48,8)),2)
;	ConsoleWrite("$IndxHeaderSize: " & $IndxHeaderSize & @crlf)
	If $IndxHeaderSize = 0 Or Mod($IndxHeaderSize,8) Then
		_DumpOutput("Error in $IndxHeaderSize: " & $IndxHeaderSize & @crlf)
		Return 0
	EndIf

	$IndxRealSizeAllEntries = Dec(_SwapEndian(StringMid($InputData,$LocalOffset+56,8)),2)
;	ConsoleWrite("$IndxRealSizeAllEntries: " & $IndxRealSizeAllEntries & @crlf)
	If $IndxRealSizeAllEntries = 0 Or Mod($IndxRealSizeAllEntries,8) Then
		_DumpOutput("Error in $IndxRecordSize: " & $IndxRealSizeAllEntries & @crlf)
		Return 0
	EndIf

	$IndxAllocatedSize = Dec(_SwapEndian(StringMid($InputData,$LocalOffset+64,8)),2)
;	ConsoleWrite("$IndxAllocatedSize: " & $IndxAllocatedSize & @crlf)
	If $IndxAllocatedSize = 0 Or Mod($IndxAllocatedSize,8) Then
		_DumpOutput("Error in $IndxAllocatedSize: " & $IndxAllocatedSize & @crlf)
		Return 0
	EndIf

	$IsNotLeafNode = Dec(StringMid($InputData,$LocalOffset+72,2))
	If $IsNotLeafNode > 1 Then
		_DumpOutput("Error in $IsNotLeafNode" & @crlf)
		Return 0
	EndIf
	Local $DetectedEntries = 0
	If Not ((24+$IndxHeaderSize) >= ($IndxRealSizeAllEntries+8)) Then
		$FromIndxSlack = 0
		;First try normal $I30
		$IndxValidationTest = _ParseCoreValidData(StringMid($InputData,$LocalOffset+48+($IndxHeaderSize*2),($IndxRealSizeAllEntries+8)*2),24+$IndxHeaderSize)
		If $IndxValidationTest Then
			$FromIndxSlack = 1
			$DetectedEntries += $IndxValidationTest
			$IndxValidationTest = _ParseCoreSlackSpace(StringMid($InputData,$LocalOffset+($IndxRealSizeAllEntries+8)*2),($IndxRealSizeAllEntries+8)*2)
			$DetectedEntries += $IndxValidationTest
		Else
			;Failure for $I30, so we attempt $ObjId:$O
			$IndxValidationTest = _DecodeIndxContentObjIdO(StringMid($InputData,$LocalOffset+48+($IndxHeaderSize*2),($IndxRealSizeAllEntries+8)*2),24+$IndxHeaderSize)
			If $IndxValidationTest Then
				;If success then try slack for $ObjId:$O
				$FromIndxSlack = 1
				$DetectedEntries += $IndxValidationTest
				$IndxValidationTest = _DecodeSlackIndxContentObjIdO(StringMid($InputData,$LocalOffset+($IndxRealSizeAllEntries+8)*2),($IndxRealSizeAllEntries+8)*2)
				$DetectedEntries += $IndxValidationTest
			Else
				;Failure for both $I30 and $ObjId:$O, so we attempt $Reparse:$R
				$IndxValidationTest = _Decode_Reparse_R(StringMid($InputData,$LocalOffset+48+($IndxHeaderSize*2),($IndxRealSizeAllEntries+8)*2),24+$IndxHeaderSize)
				$DetectedEntries += $IndxValidationTest
			EndIf
		EndIf
	Else
		;INDX header indicated all content was slack
		$FromIndxSlack = 1
		;First try $I30
		$IndxValidationTest = _ParseCoreSlackSpace(StringMid($InputData,$LocalOffset+($IndxRealSizeAllEntries+8)*2),($IndxRealSizeAllEntries+8)*2)
		If Not $IndxValidationTest Then
			;Failure for $I30, so awe attempt $ObjId:$O
			$DetectedEntries += $IndxValidationTest
			$IndxValidationTest = _DecodeSlackIndxContentObjIdO(StringMid($InputData,$LocalOffset+($IndxRealSizeAllEntries+8)*2),($IndxRealSizeAllEntries+8)*2)
			$DetectedEntries += $IndxValidationTest
		EndIf
	EndIf
	Return $DetectedEntries
EndFunc

Func _ApplyFixupsIndx($Entry)
;	ConsoleWrite("Starting function _StripIndxRecord()" & @crlf)
	Local $LocalAttributeOffset = 1,$IndxHdrUpdateSeqArrOffset,$IndxHdrUpdateSeqArrSize,$IndxHdrUpdSeqArr,$IndxHdrUpdSeqArrPart0,$IndxHdrUpdSeqArrPart1,$IndxHdrUpdSeqArrPart2,$IndxHdrUpdSeqArrPart3,$IndxHdrUpdSeqArrPart4,$IndxHdrUpdSeqArrPart5,$IndxHdrUpdSeqArrPart6,$IndxHdrUpdSeqArrPart7;,$IndxHdrUpdSeqArrPart8
	Local $IndxRecordEnd1,$IndxRecordEnd2,$IndxRecordEnd3,$IndxRecordEnd4,$IndxRecordEnd5,$IndxRecordEnd6,$IndxRecordEnd7,$IndxRecordEnd8;,$IndxRecordSize,$IndxHeaderSize,$IsNotLeafNode
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
	;$IndxHdrUpdSeqArrPart8 = StringMid($IndxHdrUpdSeqArr,33,4)
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
	;winnt.h
	;ntifs.h
	Select
		Case $ReparseType = '0x00000000'
			Return 'RESERVED_ZERO'
		Case $ReparseType = '0x00000001'
			Return 'RESERVED_ONE'
		Case $ReparseType = '0x00000002'
			Return 'RESERVED_TWO'
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
		Case $ReparseType = '0x80000015'
			Return 'FILE_PLACEHOLDER'
		Case $ReparseType = '0x80000017'
			Return 'WOF'
		Case $ReparseType = '0x80000018'
			Return 'WCI'
		Case $ReparseType = '0x80000019'
			Return 'GLOBAL_REPARSE'
		Case $ReparseType = '0x8000001B'
			Return 'APPEXECLINK'
		Case $ReparseType = '0x8000001E'
			Return 'HFS'
		Case $ReparseType = '0x80000020'
			Return 'UNHANDLED'
		Case $ReparseType = '0x80000021'
			Return 'ONEDRIVE'
		Case $ReparseType = '0x9000001A'
			Return 'CLOUD'
		Case $ReparseType = '0x9000101A'
			Return 'CLOUD_ROOT'
		Case $ReparseType = '0x9000201A'
			Return 'CLOUD_ON_DEMAND'
		Case $ReparseType = '0x9000301A'
			Return 'CLOUD_ROOT_ON_DEMAND'
		Case $ReparseType = '0x9000001C'
			Return 'GVFS'
		Case $ReparseType = '0xA0000003'
			Return 'MOUNT_POINT'
		Case $ReparseType = '0xA000000C'
			Return 'SYMLINK'
		Case $ReparseType = '0xA0000010'
			Return 'IIS_CACHE'
		Case $ReparseType = '0xA0000019'
			Return 'GLOBAL_REPARSE'
		Case $ReparseType = '0xA000001D'
			Return 'LX_SYMLINK'
		Case $ReparseType = '0xA000001F'
			Return 'WCI_TOMBSTONE'
		Case $ReparseType = '0xA0000022'
			Return 'GVFS_TOMBSTONE'
		Case $ReparseType = '0xC0000004'
			Return 'HSM'
		Case $ReparseType = '0xC0000014'
			Return 'APPXSTRM'
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

Func _GetInputParams()
	Local $TimeZone, $OutputFormat
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
		If StringLeft($cmdline[$i],9) = "/CleanUp:" Then $CleanUp = StringMid($cmdline[$i],10)
		If StringLeft($cmdline[$i],16) = "/VerifyFragment:" Then $VerifyFragment = StringMid($cmdline[$i],17)
		If StringLeft($cmdline[$i],17) = "/OutFragmentName:" Then $OutFragmentName = StringMid($cmdline[$i],18)
		If StringLeft($cmdline[$i],17) = "/StrictNameCheck:" Then $StrictNameCheck = StringMid($cmdline[$i],18)
	Next

	If StringLen($ScanMode) > 0 Then
		If Not StringIsDigit($ScanMode) Then
			ConsoleWrite("ScanMode was invalid: " & $ScanMode & @CRLF)
			Exit(1)
		EndIf
;		If $ScanMode > 15 Then $ScanMode = 15
	Else
		$ScanMode = 0
	EndIf

	If StringLen($StrictNameCheck) > 0 Then
		If Not StringIsDigit($StrictNameCheck) Then
			ConsoleWrite("StrictNameCheck was invalid: " & $StrictNameCheck & @CRLF)
			Exit(1)
		EndIf
		$StrictNameCheck = 1
	Else
		$StrictNameCheck = 0
	EndIf

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
		ConsoleWrite("Error: Timezone configuration failed." & @CRLF)
	Else
		;ConsoleWrite("Timestamps presented in UTC: " & $UTCconfig & @CRLF)
	EndIf
	$tDelta = $tDelta*-1

	If StringLen($BinaryFragment) > 0 Then
		If Not FileExists($BinaryFragment) Then
			ConsoleWrite("Error input INDX chunk file does not exist." & @CRLF)
			Exit(1)
		EndIf
;		ConsoleWrite("$BinaryFragment: " & $BinaryFragment & @CRLF)
	EndIf

	If StringLen($OutputFormat) > 0 Then
		If $OutputFormat = "l2t" Then $Dol2t = True
		If $OutputFormat = "bodyfile" Then $DoBodyfile = True
		If $OutputFormat = "all" Then $DoDefaultAll = True
		If $Dol2t = False And $DoBodyfile = False Then $DoDefaultAll = True
	Else
		$DoDefaultAll = True
	EndIf

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

	If ($DateTimeFormat = 4 Or $DateTimeFormat = 5) And ($checkl2t + $checkbodyfile > 0) Then
		ConsoleWrite("Error: TSFormat can't be 4 or 5 in combination with OutputFormat l2t and bodyfile" & @CRLF)
		Exit(1)
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

	If StringLen($VerifyFragment) > 0 Then
		If $VerifyFragment <> 1 Then
			$VerifyFragment = 0
		EndIf
	EndIf

	If StringLen($OutFragmentName) > 0 Then
		If StringInStr($OutFragmentName,"\") Then
			ConsoleWrite("Error: OutFragmentName must be a filename and not a path." & @CRLF)
			Exit(1)
		EndIf
	EndIf

	If StringLen($CleanUp) > 0 Then
		If $CleanUp <> 1 Then
			$CleanUp = 0
		EndIf
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
	$UTCconfig = $part1
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
   If $hDebugOutFile Then FileWrite($hDebugOutFile, $text)
EndFunc

Func _ValidateCharacter($InputString)
;ConsoleWrite("$InputString: " & $InputString & @CRLF)
	$StringLength = StringLen($InputString)
	For $i = 1 To $StringLength Step 4
		$TestChunk = StringMid($InputString,$i,4)
		$TestChunk = Dec(_SwapEndian($TestChunk),2)
		If ($TestChunk > 31 And $TestChunk < 256) Then
			ContinueLoop
		Else
			Return 0
		EndIf
	Next
	Return 1
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

Func _ValidateCharacterAndWindowsFileName($InputString)
;ConsoleWrite("$InputString: " & $InputString & @CRLF)
	$StringLength = StringLen($InputString)
	For $i = 1 To $StringLength Step 4
		$TestChunk = StringMid($InputString,$i,4)
		$TestChunk = Dec(_SwapEndian($TestChunk),2)
		If ($TestChunk > 31 And $TestChunk < 256) Then
			If ($TestChunk <> 47 And $TestChunk <> 92 And $TestChunk <> 58 And $TestChunk <> 42 And $TestChunk <> 63 And $TestChunk <> 34 And $TestChunk <> 60 And $TestChunk <> 62) Then
				ContinueLoop
			Else
				Return 0
			EndIf
			ContinueLoop
		Else
			Return 0
		EndIf
	Next
	Return 1
EndFunc

Func _WriteOutputFragment()
	Local $nBytes, $Offset

	$Size = BinaryLen($RebuiltFragment)
	$Size2 = $Size
	If Mod($Size,0x8) Then
		ConsoleWrite("SizeOf $RebuiltFragment: " & $Size & @CRLF)
		While 1
			$RebuiltFragment &= "00"
			$Size2 += 1
			If Mod($Size2,0x8) = 0 Then ExitLoop
		WEnd
		ConsoleWrite("Corrected SizeOf $RebuiltFragment: " & $Size2 & @CRLF)
	EndIf

	Local $tBuffer = DllStructCreate("byte[" & $Size2 & "]")
	DllStructSetData($tBuffer,1,$RebuiltFragment)
	If @error Then Return SetError(1)
	Local $OutFile = $ParserOutDir & "\" & $OutFragmentName
	If Not FileExists($OutFile) Then
		$Offset = 0
	Else
		$Offset = FileGetSize($OutFile)
	EndIf
	Local $hFileOut = _WinAPI_CreateFile("\\.\" & $OutFile,3,6,7)
	If Not $hFileOut Then Return SetError(1)
	_WinAPI_SetFilePointerEx($hFileOut, $Offset, $FILE_BEGIN)
	If Not _WinAPI_WriteFile($hFileOut, DllStructGetPtr($tBuffer), DllStructGetSize($tBuffer), $nBytes) Then Return SetError(1)
	_WinAPI_CloseHandle($hFileOut)
EndFunc

Func _InjectScanMode()
	Local $ScanModes = "0|" & _
		"1|" & _
		"2|" & _
		"3|" & _
		"4|" & _
		"5|" & _
		"6|" & _
		"7|" & _
		"8|" & _
		"9|" & _
		"10|" & _
		"11|" & _
		"12|" & _
		"13|" & _
		"14|" & _
		"15|"
	GUICtrlSetData($ComboScanMode,$ScanModes,"0")
EndFunc

Func _DecodeIndxContentObjIdO($InputData,$FirstEntryOffset)
	Local $Indx_DataOffset, $Indx_DataSize, $Indx_Padding1, $Indx_IndexEntrySize, $Indx_IndexKeySize, $Indx_Flags, $Indx_Padding2, $Indx_GUIDObjectId, $Indx_MftRef, $Indx_MftRefSeqNo
	Local $Indx_GUIDBirthVolumeId, $Indx_GUIDBirthObjectId, $Indx_GUIDDomainId, $EntryCounter=0, $LocalOffset=1, $TextInformation

	;ConsoleWrite("_DecodeIndxContentObjIdO():" & @crlf)
	;ConsoleWrite(_HexEncode("0x"&$InputData) & @crlf)
	$SizeofIndxRecord = StringLen($InputData)
	While 1
		;$RecordOffset = "0x" & Hex(Int($SourceFileOffset + (($LocalOffset-1)/2) + $FirstEntryOffset))
		$RecordOffset = "0x" & Hex(Int($CurrentFileOffset + (($LocalOffset-1)/2) + $FirstEntryOffset))

		$Indx_DataOffset = StringMid($InputData, $LocalOffset, 4)
		$Indx_DataOffset = Dec(_SwapEndian($Indx_DataOffset),2)

		$Indx_DataSize = StringMid($InputData, $LocalOffset + 4, 4)
		$Indx_DataSize = Dec(_SwapEndian($Indx_DataSize),2)

		If $Indx_DataOffset = 0 Or $Indx_DataSize = 0 Then
			ConsoleWrite("Error: Invalid DataOffset or DataSize" & @crlf)
			;ConsoleWrite(_HexEncode("0x"&StringMid($InputData, $LocalOffset)) & @crlf)
			Return $EntryCounter
		EndIf

		;Padding 4 bytes
		$Indx_Padding1 = StringMid($InputData, $LocalOffset + 8, 8)
		$Indx_Padding1 = Dec(_SwapEndian($Indx_Padding1),2)
		If $Indx_Padding1 <> 0 Then
			ConsoleWrite("Error: Invalid Padding1" & @crlf)
			Return 0
		EndIf

		$Indx_IndexEntrySize = StringMid($InputData, $LocalOffset + 16, 4)
		$Indx_IndexEntrySize = Dec(_SwapEndian($Indx_IndexEntrySize),2)
		If $Indx_IndexEntrySize = 0 Then
			ConsoleWrite("Error: Invalid IndexEntrySize" & @crlf)
			Return 0
		EndIf

		$Indx_IndexKeySize = StringMid($InputData, $LocalOffset + 20, 4)
		$Indx_IndexKeySize = Dec(_SwapEndian($Indx_IndexKeySize),2)

		;1=Entry has subnodes, 2=Last entry
		$Indx_Flags = StringMid($InputData, $LocalOffset + 24, 4)
		If Dec(_SwapEndian($Indx_Flags),2) > 2 Then
			ConsoleWrite("Error: Invalid Flags" & @crlf)
			Return 0
		EndIf
		$Indx_Flags = "0x" & _SwapEndian($Indx_Flags)

		;Padding 2 bytes
		$Indx_Padding2 = StringMid($InputData, $LocalOffset + 28, 4)
		$Indx_Padding2 = Dec(_SwapEndian($Indx_Padding2),2)
		If $Indx_Padding2 <> 0 Then
			ConsoleWrite("Error: Invalid Padding2" & @crlf)
			Return 0
		EndIf

		$Indx_GUIDObjectId = StringMid($InputData, $LocalOffset + 32, 32)
		If $Indx_GUIDObjectId = "00000000000000000000000000000000" Then
			ConsoleWrite("Error: Invalid GUIDObjectId" & @crlf)
			Return 0
		EndIf

		;Decode guid
		$Indx_GUIDObjectId_Version = Dec(StringMid($Indx_GUIDObjectId,15,1))
		If $Indx_GUIDObjectId_Version = 0 Or $Indx_GUIDObjectId_Version > 4 Then
			ConsoleWrite("Error: Invalid ObjectId_Version: " & $Indx_GUIDObjectId_Version & @crlf)
			Return 0
		EndIf
		$Indx_GUIDObjectId_Timestamp = StringMid($Indx_GUIDObjectId,1,14) & "0" & StringMid($Indx_GUIDObjectId,16,1)
		$Indx_GUIDObjectId_TimestampDec = Dec(_SwapEndian($Indx_GUIDObjectId_Timestamp),2)
		$Indx_GUIDObjectId_Timestamp = _DecodeTimestampFromGuid($Indx_GUIDObjectId_Timestamp)
		$Indx_GUIDObjectId_ClockSeq = StringMid($Indx_GUIDObjectId,17,4)
		$Indx_GUIDObjectId_ClockSeq = Dec($Indx_GUIDObjectId_ClockSeq)
		$Indx_GUIDObjectId_Node = StringMid($Indx_GUIDObjectId,21,12)
		$Indx_GUIDObjectId_Node = _DecodeMacFromGuid($Indx_GUIDObjectId_Node)
		$Indx_GUIDObjectId = _HexToGuidStr($Indx_GUIDObjectId,1)

		$Indx_MftRef = StringMid($InputData, $LocalOffset + 64, 12)
		$Indx_MftRef = Dec(_SwapEndian($Indx_MftRef),2)
		If $Indx_MftRef = 0 Then
			ConsoleWrite("Error: Invalid MftRef" & @crlf)
			Return 0
		EndIf

		$Indx_MftRefSeqNo = StringMid($InputData, $LocalOffset + 76, 4)
		$Indx_MftRefSeqNo = Dec(_SwapEndian($Indx_MftRefSeqNo),2)
		If $Indx_MftRefSeqNo = 0 Then
			ConsoleWrite("Error: Invalid MftRefSeqNo" & @crlf)
			Return 0
		EndIf

		$Indx_GUIDBirthVolumeId = StringMid($InputData, $LocalOffset + 80, 32)
		;Decode guid
		$Indx_GUIDBirthVolumeId_Version = Dec(StringMid($Indx_GUIDBirthVolumeId,15,1))
		$Indx_GUIDBirthVolumeId_Timestamp = StringMid($Indx_GUIDBirthVolumeId,1,14) & "0" & StringMid($Indx_GUIDBirthVolumeId,16,1)
		$Indx_GUIDBirthVolumeId_TimestampDec = Dec(_SwapEndian($Indx_GUIDBirthVolumeId_Timestamp),2)
		$Indx_GUIDBirthVolumeId_Timestamp = _DecodeTimestampFromGuid($Indx_GUIDBirthVolumeId_Timestamp)
		$Indx_GUIDBirthVolumeId_ClockSeq = StringMid($Indx_GUIDBirthVolumeId,17,4)
		$Indx_GUIDBirthVolumeId_ClockSeq = Dec($Indx_GUIDBirthVolumeId_ClockSeq)
		$Indx_GUIDBirthVolumeId_Node = StringMid($Indx_GUIDBirthVolumeId,21,12)
		$Indx_GUIDBirthVolumeId_Node = _DecodeMacFromGuid($Indx_GUIDBirthVolumeId_Node)
		$Indx_GUIDBirthVolumeId = _HexToGuidStr($Indx_GUIDBirthVolumeId,1)

		$Indx_GUIDBirthObjectId = StringMid($InputData, $LocalOffset + 112, 32)
		;Decode guid
		$Indx_GUIDBirthObjectId_Version = Dec(StringMid($Indx_GUIDBirthObjectId,15,1))
		$Indx_GUIDBirthObjectId_Timestamp = StringMid($Indx_GUIDBirthObjectId,1,14) & "0" & StringMid($Indx_GUIDBirthObjectId,16,1)
		$Indx_GUIDBirthObjectId_TimestampDec = Dec(_SwapEndian($Indx_GUIDBirthObjectId_Timestamp),2)
		$Indx_GUIDBirthObjectId_Timestamp = _DecodeTimestampFromGuid($Indx_GUIDBirthObjectId_Timestamp)
		$Indx_GUIDBirthObjectId_ClockSeq = StringMid($Indx_GUIDBirthObjectId,17,4)
		$Indx_GUIDBirthObjectId_ClockSeq = Dec($Indx_GUIDBirthObjectId_ClockSeq)
		$Indx_GUIDBirthObjectId_Node = StringMid($Indx_GUIDBirthObjectId,21,12)
		$Indx_GUIDBirthObjectId_Node = _DecodeMacFromGuid($Indx_GUIDBirthObjectId_Node)
		$Indx_GUIDBirthObjectId = _HexToGuidStr($Indx_GUIDBirthObjectId,1)

		$Indx_GUIDDomainId = StringMid($InputData, $LocalOffset + 144, 32)
		;Decode guid
		$Indx_GUIDDomainId_Version = Dec(StringMid($Indx_GUIDDomainId,15,1))
		$Indx_GUIDDomainId_Timestamp = StringMid($Indx_GUIDDomainId,1,14) & "0" & StringMid($Indx_GUIDDomainId,16,1)
		$Indx_GUIDDomainId_TimestampDec = Dec(_SwapEndian($Indx_GUIDDomainId_Timestamp),2)
		$Indx_GUIDDomainId_Timestamp = _DecodeTimestampFromGuid($Indx_GUIDDomainId_Timestamp)
		$Indx_GUIDDomainId_ClockSeq = StringMid($Indx_GUIDDomainId,17,4)
		$Indx_GUIDDomainId_ClockSeq = Dec($Indx_GUIDDomainId_ClockSeq)
		$Indx_GUIDDomainId_Node = StringMid($Indx_GUIDDomainId,21,12)
		$Indx_GUIDDomainId_Node = _DecodeMacFromGuid($Indx_GUIDDomainId_Node)
		$Indx_GUIDDomainId = _HexToGuidStr($Indx_GUIDDomainId,1)

		Local $TextString
		If Not $DoDefaultAll Then
			$TextString &= " ObjectId:" & $Indx_GUIDObjectId
			If $Indx_GUIDObjectId_Version = 1 Then
				$TextString &= " ObjectId_Timestamp:" & $Indx_GUIDObjectId_Timestamp
			EndIf
			$TextString &= " ObjectId_Node:" & $Indx_GUIDObjectId_Node
			$TextString &= " BirthVolumeId:" & $Indx_GUIDBirthVolumeId
			If $Indx_GUIDBirthVolumeId_Version = 1 Then
				$TextString &= " BirthVolumeId_Timestamp:" & $Indx_GUIDBirthVolumeId_Timestamp
			EndIf
			$TextString &= " BirthObjectId:" & $Indx_GUIDBirthObjectId
			If $Indx_GUIDBirthObjectId_Version = 1 Then
				$TextString &= " BirthObjectId_Timestamp:" & $Indx_GUIDBirthObjectId_Timestamp
			EndIf
		EndIf
		If $WithQuotes Then
			Select
				Case $DoDefaultAll
					FileWriteLine($IndxEntriesObjIdOCsvFile, '"'&$RecordOffset&'"' & $de & '"'&$IndxCurrentVcn&'"' & $de & '"'&$IsNotLeafNode&'"' & $de & '"'&$IndxLastLsn&'"' & $de & '"'&$FromIndxSlack&'"' & $de & '"'&$Indx_DataOffset&'"' & $de & '"'&$Indx_DataSize&'"' & $de & '"'&$Indx_Padding1&'"' & $de & '"'&$Indx_IndexEntrySize&'"' & $de & '"'&$Indx_IndexKeySize&'"' & $de & '"'&$Indx_Flags&'"' & $de & '"'&$Indx_Padding2&'"' & $de & '"'&$Indx_MftRef&'"' & $de & '"'&$Indx_MftRefSeqNo&'"' & $de & '"'&$Indx_GUIDObjectId&'"' & $de & '"'&$Indx_GUIDObjectId_Version&'"' & $de & '"'&$Indx_GUIDObjectId_Timestamp&'"' & $de & '"'&$Indx_GUIDObjectId_TimestampDec&'"' & $de & '"'&$Indx_GUIDObjectId_ClockSeq&'"' & $de & '"'&$Indx_GUIDObjectId_Node&'"' & $de & '"'&$Indx_GUIDBirthVolumeId&'"' & $de & '"'&$Indx_GUIDBirthVolumeId_Version&'"' & $de & '"'&$Indx_GUIDBirthVolumeId_Timestamp&'"' & $de & '"'&$Indx_GUIDBirthVolumeId_TimestampDec&'"' & $de & '"'&$Indx_GUIDBirthVolumeId_ClockSeq&'"' & $de & '"'&$Indx_GUIDBirthVolumeId_Node&'"' & $de & '"'&$Indx_GUIDBirthObjectId&'"' & $de & '"'&$Indx_GUIDBirthObjectId_Version&'"' & $de & '"'&$Indx_GUIDBirthObjectId_Timestamp&'"' & $de & '"'&$Indx_GUIDBirthObjectId_TimestampDec&'"' & $de & '"'&$Indx_GUIDBirthObjectId_ClockSeq&'"' & $de & '"'&$Indx_GUIDBirthObjectId_Node&'"' & $de & '"'&$Indx_GUIDDomainId&'"' & $de & '"'&$Indx_GUIDDomainId_Version&'"' & $de & '"'&$Indx_GUIDDomainId_Timestamp&'"' & $de & '"'&$Indx_GUIDDomainId_TimestampDec&'"' & $de & '"'&$Indx_GUIDDomainId_ClockSeq&'"' & $de & '"'&$Indx_GUIDDomainId_Node&'"' & $de & '"'&$TextInformation&'"' & @crlf)
				Case $Dol2t
					FileWriteLine($IndxEntriesObjIdOCsvFile, '"'&'"'& StringLeft($Indx_GUIDObjectId_Timestamp,$CharsToGrabDate) &'"' & $de & '"'& StringMid($Indx_GUIDObjectId_Timestamp,$CharStartTime,$CharsToGrabTime) &'"' & $de & '"'& $UTCconfig &'"' & $de & '"'&"MACB"&'"' & $de & '"'&"INDX"&'"' & $de & '"'&"ObjId:O"&'"' & $de & '"'& "" &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& "" &'"' & $de & '"'&$Indx_MftRef&'"' & $de & '"'&"Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$Indx_MftRef&" MftRefSeqNo:"&$Indx_MftRefSeqNo & $TextString&'"' & $de & '""' & $de & '""' & @CRLF)
				Case $DoBodyfile
					FileWriteLine($IndxEntriesObjIdOCsvFile, '""' & $de & '"'& "ObjId:O" &'"' & $de & '"'&$Indx_MftRef&'"' & $de & '"'& "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$Indx_MftRef&" MftRefSeqNo:"&$Indx_MftRefSeqNo & $TextString &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& "" &'"' & $de & '"'& "" &'"' & $de & '"'& "" &'"' & $de & '"'& "" &'"' & @CRLF)
			EndSelect
		Else
			Select
				Case $DoDefaultAll
					FileWriteLine($IndxEntriesObjIdOCsvFile, $RecordOffset & $de & $IndxCurrentVcn & $de & $IsNotLeafNode & $de & $IndxLastLsn & $de & $FromIndxSlack & $de & $Indx_DataOffset & $de & $Indx_DataSize & $de & $Indx_Padding1 & $de & $Indx_IndexEntrySize & $de & $Indx_IndexKeySize & $de & $Indx_Flags & $de & $Indx_Padding2 & $de & $Indx_MftRef & $de & $Indx_MftRefSeqNo & $de & $Indx_GUIDObjectId & $de & $Indx_GUIDObjectId_Version & $de & $Indx_GUIDObjectId_Timestamp & $de & $Indx_GUIDObjectId_TimestampDec & $de & $Indx_GUIDObjectId_ClockSeq & $de & $Indx_GUIDObjectId_Node & $de & $Indx_GUIDBirthVolumeId & $de & $Indx_GUIDBirthVolumeId_Version & $de & $Indx_GUIDBirthVolumeId_Timestamp & $de & $Indx_GUIDBirthVolumeId_TimestampDec & $de & $Indx_GUIDBirthVolumeId_ClockSeq & $de & $Indx_GUIDBirthVolumeId_Node & $de & $Indx_GUIDBirthObjectId & $de & $Indx_GUIDBirthObjectId_Version & $de & $Indx_GUIDBirthObjectId_Timestamp & $de & $Indx_GUIDBirthObjectId_TimestampDec & $de & $Indx_GUIDBirthObjectId_ClockSeq & $de & $Indx_GUIDBirthObjectId_Node & $de & $Indx_GUIDDomainId & $de & $Indx_GUIDDomainId_Version & $de & $Indx_GUIDDomainId_Timestamp & $de & $Indx_GUIDDomainId_TimestampDec & $de & $Indx_GUIDDomainId_ClockSeq & $de & $Indx_GUIDDomainId_Node & $de & $TextInformation & @crlf)
				Case $Dol2t
					FileWriteLine($IndxEntriesObjIdOCsvFile, StringLeft($Indx_GUIDObjectId_Timestamp,$CharsToGrabDate) & $de & StringMid($Indx_GUIDObjectId_Timestamp,$CharStartTime,$CharsToGrabTime) & $de & $UTCconfig & $de & "MACB" & $de & "INDX" & $de & "ObjId:O" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & $Indx_MftRef & $de & "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$Indx_MftRef&" MftRefSeqNo:"&$Indx_MftRefSeqNo & $TextString & $de & "" & $de & "" & @CRLF)
				Case $DoBodyfile
					FileWriteLine($IndxEntriesObjIdOCsvFile, "" & $de & "ObjId:O" & $de & $Indx_MftRef & $de & "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$Indx_MftRef&" MftRefSeqNo:"&$Indx_MftRefSeqNo & $TextString & $de & "" & $de & "" & $de & "" & $de &  ""  & $de &  ""  & $de &  ""  & $de &  ""  & @CRLF)
			EndSelect
		EndIf
		$EntryCounter += 1
		$LocalOffset += 176
		If $LocalOffset >= $SizeofIndxRecord Then
			Return $EntryCounter
		EndIf
	WEnd
	Return 1
EndFunc

Func _DecodeSlackIndxContentObjIdO($InputData,$FirstEntryOffset)
	Local $Indx_DataOffset, $Indx_DataSize, $Indx_Padding1, $Indx_IndexEntrySize, $Indx_IndexKeySize, $Indx_Flags, $Indx_Padding2, $Indx_GUIDObjectId, $Indx_MftRef, $Indx_MftRefSeqNo
	Local $Indx_GUIDBirthVolumeId, $Indx_GUIDBirthObjectId, $Indx_GUIDDomainId, $EntryCounter=0, $LocalOffset=1, $TextInformation, $NullGuid = "{00000000-0000-0000-0000-000000000000}"
	Local $IndxLastLsn = -1, $RegExPatternHexNotFourNulls = "[0]{4}", $GuidProbablyBad=0

	;ConsoleWrite("_DecodeSlackIndxContentObjIdO():" & @crlf)
	;ConsoleWrite(_HexEncode("0x"&$InputData) & @crlf)
	$SizeofIndxRecord = StringLen($InputData)
	While 1
		$TextInformation = ""
		$GuidProbablyBad = 0

		If $LocalOffset + 176 >= $SizeofIndxRecord Then
			Return $EntryCounter
		EndIf

		;$RecordOffset = "0x" & Hex(Int($SourceFileOffset + (($LocalOffset-1)/2) + $FirstEntryOffset))
		$RecordOffset = "0x" & Hex(Int($CurrentFileOffset + (($LocalOffset-1)/2) + $FirstEntryOffset))

		$Indx_DataOffset = StringMid($InputData, $LocalOffset, 4)
		$Indx_DataOffset = Dec(_SwapEndian($Indx_DataOffset),2)

		$Indx_DataSize = StringMid($InputData, $LocalOffset + 4, 4)
		$Indx_DataSize = Dec(_SwapEndian($Indx_DataSize),2)

;		If $Indx_DataOffset = 0 Or $Indx_DataSize = 0 Then
;			ConsoleWrite("Error: Invalid DataOffset or DataSize" & @crlf)
			;ConsoleWrite(_HexEncode("0x"&StringMid($InputData, $LocalOffset)) & @crlf)
;			Return $EntryCounter
;		EndIf

		;Padding 4 bytes
		$Indx_Padding1 = StringMid($InputData, $LocalOffset + 8, 8)
		$Indx_Padding1 = Dec(_SwapEndian($Indx_Padding1),2)
;		If $Indx_Padding1 <> 0 Then
;			ConsoleWrite("Error: Invalid Padding1" & @crlf)
;			Return 0
;		EndIf

		$Indx_IndexEntrySize = StringMid($InputData, $LocalOffset + 16, 4)
		$Indx_IndexEntrySize = Dec(_SwapEndian($Indx_IndexEntrySize),2)
;		If $Indx_IndexEntrySize = 0 Then
;			ConsoleWrite("Error: Invalid IndexEntrySize" & @crlf)
;			Return 0
;		EndIf

		$Indx_IndexKeySize = StringMid($InputData, $LocalOffset + 20, 4)
		$Indx_IndexKeySize = Dec(_SwapEndian($Indx_IndexKeySize),2)

		;1=Entry has subnodes, 2=Last entry
		$Indx_Flags = StringMid($InputData, $LocalOffset + 24, 4)
		$Indx_Flags = "0x" & _SwapEndian($Indx_Flags)
;		If $Indx_Flags > 0x0002 Then
;			ConsoleWrite("Error: Invalid Flags" & @crlf)
;			Return 0
;		EndIf


		;Padding 2 bytes
		$Indx_Padding2 = StringMid($InputData, $LocalOffset + 28, 4)
		$Indx_Padding2 = Dec(_SwapEndian($Indx_Padding2),2)
;		If $Indx_Padding2 <> 0 Then
;			ConsoleWrite("Error: Invalid Padding2" & @crlf)
;			Return 0
;		EndIf

		$Indx_GUIDObjectId = StringMid($InputData, $LocalOffset + 32, 32)
;		If $Indx_GUIDObjectId = "00000000000000000000000000000000" Then
;			ConsoleWrite("Error: Invalid GUIDObjectId" & @crlf)
;			Return 0
;		EndIf
		If StringRegExp($Indx_GUIDObjectId,$RegExPatternHexNotFourNulls) Then
			$GuidProbablyBad = 1
		Else
			$GuidProbablyBad = 0
		EndIf
		;Decode guid
		$Indx_GUIDObjectId_Version = Dec(StringMid($Indx_GUIDObjectId,15,1))
		$Indx_GUIDObjectId_Timestamp = StringMid($Indx_GUIDObjectId,1,14) & "0" & StringMid($Indx_GUIDObjectId,16,1)
		$Indx_GUIDObjectId_TimestampDec = Dec(_SwapEndian($Indx_GUIDObjectId_Timestamp),2)
		$Indx_GUIDObjectId_Timestamp = _DecodeTimestampFromGuid($Indx_GUIDObjectId_Timestamp)
		$Indx_GUIDObjectId_ClockSeq = StringMid($Indx_GUIDObjectId,17,4)
		$Indx_GUIDObjectId_ClockSeq = Dec($Indx_GUIDObjectId_ClockSeq)
		$Indx_GUIDObjectId_Node = StringMid($Indx_GUIDObjectId,21,12)
		$Indx_GUIDObjectId_Node = _DecodeMacFromGuid($Indx_GUIDObjectId_Node)
		$Indx_GUIDObjectId = _HexToGuidStr($Indx_GUIDObjectId,1)

		$Indx_MftRef = StringMid($InputData, $LocalOffset + 64, 12)
		$Indx_MftRef = Dec(_SwapEndian($Indx_MftRef),2)
;		If $Indx_MftRef = 0 Then
;			ConsoleWrite("Error: Invalid MftRef" & @crlf)
;			Return 0
;		EndIf

		$Indx_MftRefSeqNo = StringMid($InputData, $LocalOffset + 76, 4)
		$Indx_MftRefSeqNo = Dec(_SwapEndian($Indx_MftRefSeqNo),2)
;		If $Indx_MftRefSeqNo = 0 Then
;			ConsoleWrite("Error: Invalid MftRefSeqNo" & @crlf)
;			Return 0
;		EndIf

		$Indx_GUIDBirthVolumeId = StringMid($InputData, $LocalOffset + 80, 32)
		;Decode guid
		$Indx_GUIDBirthVolumeId_Version = Dec(StringMid($Indx_GUIDBirthVolumeId,15,1))
		$Indx_GUIDBirthVolumeId_Timestamp = StringMid($Indx_GUIDBirthVolumeId,1,14) & "0" & StringMid($Indx_GUIDBirthVolumeId,16,1)
		$Indx_GUIDBirthVolumeId_TimestampDec = Dec(_SwapEndian($Indx_GUIDBirthVolumeId_Timestamp),2)
		$Indx_GUIDBirthVolumeId_Timestamp = _DecodeTimestampFromGuid($Indx_GUIDBirthVolumeId_Timestamp)
		$Indx_GUIDBirthVolumeId_ClockSeq = StringMid($Indx_GUIDBirthVolumeId,17,4)
		$Indx_GUIDBirthVolumeId_ClockSeq = Dec($Indx_GUIDBirthVolumeId_ClockSeq)
		$Indx_GUIDBirthVolumeId_Node = StringMid($Indx_GUIDBirthVolumeId,21,12)
		$Indx_GUIDBirthVolumeId_Node = _DecodeMacFromGuid($Indx_GUIDBirthVolumeId_Node)
		$Indx_GUIDBirthVolumeId = _HexToGuidStr($Indx_GUIDBirthVolumeId,1)

		$Indx_GUIDBirthObjectId = StringMid($InputData, $LocalOffset + 112, 32)
		;Decode guid
		$Indx_GUIDBirthObjectId_Version = Dec(StringMid($Indx_GUIDBirthObjectId,15,1))
		$Indx_GUIDBirthObjectId_Timestamp = StringMid($Indx_GUIDBirthObjectId,1,14) & "0" & StringMid($Indx_GUIDBirthObjectId,16,1)
		$Indx_GUIDBirthObjectId_TimestampDec = Dec(_SwapEndian($Indx_GUIDBirthObjectId_Timestamp),2)
		$Indx_GUIDBirthObjectId_Timestamp = _DecodeTimestampFromGuid($Indx_GUIDBirthObjectId_Timestamp)
		$Indx_GUIDBirthObjectId_ClockSeq = StringMid($Indx_GUIDBirthObjectId,17,4)
		$Indx_GUIDBirthObjectId_ClockSeq = Dec($Indx_GUIDBirthObjectId_ClockSeq)
		$Indx_GUIDBirthObjectId_Node = StringMid($Indx_GUIDBirthObjectId,21,12)
		$Indx_GUIDBirthObjectId_Node = _DecodeMacFromGuid($Indx_GUIDBirthObjectId_Node)
		$Indx_GUIDBirthObjectId = _HexToGuidStr($Indx_GUIDBirthObjectId,1)

		$Indx_GUIDDomainId = StringMid($InputData, $LocalOffset + 144, 32)
		;Decode guid
		$Indx_GUIDDomainId_Version = Dec(StringMid($Indx_GUIDDomainId,15,1))
		$Indx_GUIDDomainId_Timestamp = StringMid($Indx_GUIDDomainId,1,14) & "0" & StringMid($Indx_GUIDDomainId,16,1)
		$Indx_GUIDDomainId_TimestampDec = Dec(_SwapEndian($Indx_GUIDDomainId_Timestamp),2)
		$Indx_GUIDDomainId_Timestamp = _DecodeTimestampFromGuid($Indx_GUIDDomainId_Timestamp)
		$Indx_GUIDDomainId_ClockSeq = StringMid($Indx_GUIDDomainId,17,4)
		$Indx_GUIDDomainId_ClockSeq = Dec($Indx_GUIDDomainId_ClockSeq)
		$Indx_GUIDDomainId_Node = StringMid($Indx_GUIDDomainId,21,12)
		$Indx_GUIDDomainId_Node = _DecodeMacFromGuid($Indx_GUIDDomainId_Node)
		$Indx_GUIDDomainId = _HexToGuidStr($Indx_GUIDDomainId,1)

		If $LocalOffset > 352 And $EntryCounter = 0 Then
			;This INDX is most likely not $O.
			Return 0
		EndIf

		If $LocalOffset >= $SizeofIndxRecord Then
			Return $EntryCounter
		EndIf

		Local $TextString

		If Mod($Indx_DataOffset,8) = 0 And $Indx_DataOffset < 64 And Mod($Indx_DataSize,8) = 0 And $Indx_DataSize < 128 And $Indx_Padding1 = 0 And Mod($Indx_IndexEntrySize,8) = 0 And $Indx_IndexEntrySize < 128 And Mod($Indx_IndexKeySize,16) = 0 And $Indx_IndexKeySize < 17 And $Indx_Flags < 0x0003 And $Indx_Padding2 = 0 And $Indx_GUIDObjectId <> $NullGuid And $GuidProbablyBad = 0 And $Indx_MftRef > 0 And $Indx_MftRefSeqNo > 0 Then
			;If $Indx_DataOffset = 0 Then $TextInformation &= ";DataOffset"
			;If $Indx_DataSize = 0 Then $TextInformation &= ";DataSize"
			;If $Indx_Padding1 > 0 Then $TextInformation &= ";Padding1"
			;If $Indx_IndexEntrySize = 0 Then $TextInformation &= ";IndexEntrySize"
			;If $Indx_IndexKeySize = 0 Then $TextInformation &= ";IndexKeySize"

			If Not $DoDefaultAll Then
				$TextString &= " ObjectId:" & $Indx_GUIDObjectId
				If $Indx_GUIDObjectId_Version = 1 Then
					$TextString &= " ObjectId_Timestamp:" & $Indx_GUIDObjectId_Timestamp
				EndIf
				$TextString &= " ObjectId_Node:" & $Indx_GUIDObjectId_Node
				$TextString &= " BirthVolumeId:" & $Indx_GUIDBirthVolumeId
				If $Indx_GUIDBirthVolumeId_Version = 1 Then
					$TextString &= " BirthVolumeId_Timestamp:" & $Indx_GUIDBirthVolumeId_Timestamp
				EndIf
				$TextString &= " BirthObjectId:" & $Indx_GUIDBirthObjectId
				If $Indx_GUIDBirthObjectId_Version = 1 Then
					$TextString &= " BirthObjectId_Timestamp:" & $Indx_GUIDBirthObjectId_Timestamp
				EndIf
			EndIf
			If $WithQuotes Then
				Select
					Case $DoDefaultAll
						FileWriteLine($IndxEntriesObjIdOCsvFile, '"'&$RecordOffset&'"' & $de & '"'&$IndxCurrentVcn&'"' & $de & '"'&$IsNotLeafNode&'"' & $de & '"'&$IndxLastLsn&'"' & $de & '"'&$FromIndxSlack&'"' & $de & '"'&$Indx_DataOffset&'"' & $de & '"'&$Indx_DataSize&'"' & $de & '"'&$Indx_Padding1&'"' & $de & '"'&$Indx_IndexEntrySize&'"' & $de & '"'&$Indx_IndexKeySize&'"' & $de & '"'&$Indx_Flags&'"' & $de & '"'&$Indx_Padding2&'"' & $de & '"'&$Indx_MftRef&'"' & $de & '"'&$Indx_MftRefSeqNo&'"' & $de & '"'&$Indx_GUIDObjectId&'"' & $de & '"'&$Indx_GUIDObjectId_Version&'"' & $de & '"'&$Indx_GUIDObjectId_Timestamp&'"' & $de & '"'&$Indx_GUIDObjectId_TimestampDec&'"' & $de & '"'&$Indx_GUIDObjectId_ClockSeq&'"' & $de & '"'&$Indx_GUIDObjectId_Node&'"' & $de & '"'&$Indx_GUIDBirthVolumeId&'"' & $de & '"'&$Indx_GUIDBirthVolumeId_Version&'"' & $de & '"'&$Indx_GUIDBirthVolumeId_Timestamp&'"' & $de & '"'&$Indx_GUIDBirthVolumeId_TimestampDec&'"' & $de & '"'&$Indx_GUIDBirthVolumeId_ClockSeq&'"' & $de & '"'&$Indx_GUIDBirthVolumeId_Node&'"' & $de & '"'&$Indx_GUIDBirthObjectId&'"' & $de & '"'&$Indx_GUIDBirthObjectId_Version&'"' & $de & '"'&$Indx_GUIDBirthObjectId_Timestamp&'"' & $de & '"'&$Indx_GUIDBirthObjectId_TimestampDec&'"' & $de & '"'&$Indx_GUIDBirthObjectId_ClockSeq&'"' & $de & '"'&$Indx_GUIDBirthObjectId_Node&'"' & $de & '"'&$Indx_GUIDDomainId&'"' & $de & '"'&$Indx_GUIDDomainId_Version&'"' & $de & '"'&$Indx_GUIDDomainId_Timestamp&'"' & $de & '"'&$Indx_GUIDDomainId_TimestampDec&'"' & $de & '"'&$Indx_GUIDDomainId_ClockSeq&'"' & $de & '"'&$Indx_GUIDDomainId_Node&'"' & $de & '"'&$TextInformation&'"' & @crlf)
					Case $Dol2t
						FileWriteLine($IndxEntriesObjIdOCsvFile, '"'&'"'& StringLeft($Indx_GUIDObjectId_Timestamp,$CharsToGrabDate) &'"' & $de & '"'& StringMid($Indx_GUIDObjectId_Timestamp,$CharStartTime,$CharsToGrabTime) &'"' & $de & '"'& $UTCconfig &'"' & $de & '"'&"MACB"&'"' & $de & '"'&"INDX"&'"' & $de & '"'&"ObjId:O"&'"' & $de & '"'& "" &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& "" &'"' & $de & '"'&$Indx_MftRef&'"' & $de & '"'&"Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$Indx_MftRef&" MftRefSeqNo:"&$Indx_MftRefSeqNo & $TextString&'"' & $de & '""' & $de & '""' & @CRLF)
					Case $DoBodyfile
						FileWriteLine($IndxEntriesObjIdOCsvFile, '""' & $de & '"'& "ObjId:O" &'"' & $de & '"'&$Indx_MftRef&'"' & $de & '"'& "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$Indx_MftRef&" MftRefSeqNo:"&$Indx_MftRefSeqNo & $TextString &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& "" &'"' & $de & '"'& "" &'"' & $de & '"'& "" &'"' & $de & '"'& "" &'"' & @CRLF)
				EndSelect
			Else
				Select
					Case $DoDefaultAll
						FileWriteLine($IndxEntriesObjIdOCsvFile, $RecordOffset & $de & $IndxCurrentVcn & $de & $IsNotLeafNode & $de & $IndxLastLsn & $de & $FromIndxSlack & $de & $Indx_DataOffset & $de & $Indx_DataSize & $de & $Indx_Padding1 & $de & $Indx_IndexEntrySize & $de & $Indx_IndexKeySize & $de & $Indx_Flags & $de & $Indx_Padding2 & $de & $Indx_MftRef & $de & $Indx_MftRefSeqNo & $de & $Indx_GUIDObjectId & $de & $Indx_GUIDObjectId_Version & $de & $Indx_GUIDObjectId_Timestamp & $de & $Indx_GUIDObjectId_TimestampDec & $de & $Indx_GUIDObjectId_ClockSeq & $de & $Indx_GUIDObjectId_Node & $de & $Indx_GUIDBirthVolumeId & $de & $Indx_GUIDBirthVolumeId_Version & $de & $Indx_GUIDBirthVolumeId_Timestamp & $de & $Indx_GUIDBirthVolumeId_TimestampDec & $de & $Indx_GUIDBirthVolumeId_ClockSeq & $de & $Indx_GUIDBirthVolumeId_Node & $de & $Indx_GUIDBirthObjectId & $de & $Indx_GUIDBirthObjectId_Version & $de & $Indx_GUIDBirthObjectId_Timestamp & $de & $Indx_GUIDBirthObjectId_TimestampDec & $de & $Indx_GUIDBirthObjectId_ClockSeq & $de & $Indx_GUIDBirthObjectId_Node & $de & $Indx_GUIDDomainId & $de & $Indx_GUIDDomainId_Version & $de & $Indx_GUIDDomainId_Timestamp & $de & $Indx_GUIDDomainId_TimestampDec & $de & $Indx_GUIDDomainId_ClockSeq & $de & $Indx_GUIDDomainId_Node & $de & $TextInformation & @crlf)
					Case $Dol2t
						FileWriteLine($IndxEntriesObjIdOCsvFile, StringLeft($Indx_GUIDObjectId_Timestamp,$CharsToGrabDate) & $de & StringMid($Indx_GUIDObjectId_Timestamp,$CharStartTime,$CharsToGrabTime) & $de & $UTCconfig & $de & "MACB" & $de & "INDX" & $de & "ObjId:O" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & $Indx_MftRef & $de & "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$Indx_MftRef&" MftRefSeqNo:"&$Indx_MftRefSeqNo & $TextString & $de & "" & $de & "" & @CRLF)
					Case $DoBodyfile
						FileWriteLine($IndxEntriesObjIdOCsvFile, "" & $de & "ObjId:O" & $de & $Indx_MftRef & $de & "Offset:"&$RecordOffset&" Slack:" & $FromIndxSlack & " MftRef:"&$Indx_MftRef&" MftRefSeqNo:"&$Indx_MftRefSeqNo & $TextString & $de & "" & $de & "" & $de & "" & $de &  ""  & $de &  ""  & $de &  ""  & $de &  ""  & @CRLF)
				EndSelect
			EndIf
			$EntryCounter += 1
			;We can jump by fixed size since all entries in this index are of fixed size. In $I30 this is different because filename length varies.
			$LocalOffset += 176
		Else
			$LocalOffset += 2
		EndIf

	WEnd
	Return 1
EndFunc

Func _HexToGuidStr($input,$mode)
	;{4b-2b-2b-2b-6b}
	Local $OutStr
	If Not StringLen($input) = 32 Then Return $input
	If $mode Then $OutStr = "{"
	$OutStr &= _SwapEndian(StringMid($input,1,8)) & "-"
	$OutStr &= _SwapEndian(StringMid($input,9,4)) & "-"
	$OutStr &= _SwapEndian(StringMid($input,13,4)) & "-"
	$OutStr &= StringMid($input,17,4) & "-"
	$OutStr &= StringMid($input,21,12)
	If $mode Then $OutStr &= "}"
	Return $OutStr
EndFunc

Func _WriteIndxObjIdOModuleCsvHeader()
	Local $a
	If $WithQuotes Then
		$a = '"'
	Else
		$a = ""
	EndIf
	If $DoDefaultAll Then
		$Indx_Csv_Header = $a&"Offset"&$a&$de&$a&"Vcn"&$a&$de&$a&"IsNotLeaf"&$a&$de&$a&"LastLsn"&$a&$de&$a&"FromIndxSlack"&$a&$de&$a&"DataOffset"&$a&$de&$a&"DataSize"&$a&$de&$a&"Padding1"&$a&$de&$a&"IndexEntrySize"&$a&$de&$a&"IndexKeySize"&$a&$de&$a&"Flags"&$a&$de&$a&"Padding2"&$a&$de&$a&"MftRef"&$a&$de&$a&"MftRefSeqNo"&$a&$de&$a&"ObjectId"&$a&$de&$a&"ObjectId_Version"&$a&$de&$a&"ObjectId_Timestamp"&$a&$de&$a&"ObjectId_TimestampDec"&$a&$de&$a&"ObjectId_ClockSeq"&$a&$de&$a&"ObjectId_Node"&$a&$de&$a&"BirthVolumeId"&$a&$de&$a&"BirthVolumeId_Version"&$a&$de&$a&"BirthVolumeId_Timestamp"&$a&$de&$a&"BirthVolumeId_TimestampDec"&$a&$de&$a&"BirthVolumeId_ClockSeq"&$a&$de&$a&"BirthVolumeId_Node"&$a&$de&$a&"BirthObjectId"&$a&$de&$a&"BirthObjectId_Version"&$a&$de&$a&"BirthObjectId_Timestamp"&$a&$de&$a&"BirthObjectId_TimestampDec"&$a&$de&$a&"BirthObjectId_ClockSeq"&$a&$de&$a&"BirthObjectId_Node"&$a&$de&$a&"DomainId"&$a&$de&$a&"DomainId_Version"&$a&$de&$a&"DomainId_Timestamp"&$a&$de&$a&"DomainId_TimestampDec"&$a&$de&$a&"DomainId_ClockSeq"&$a&$de&$a&"DomainId_Node"&$a&$de&$a&"TextInformation"&$a
	ElseIf $Dol2t Then
		$Indx_Csv_Header = $a&"Date"&$a&$de&$a&"Time"&$a&$de&$a&"Timezone"&$a&$de&$a&"MACB"&$a&$de&$a&"Source"&$a&$de&$a&"SourceType"&$a&$de&$a&"Type"&$a&$de&$a&"User"&$a&$de&$a&"Host"&$a&$de&$a&"Short"&$a&$de&$a&"Desc"&$a&$de&$a&"Version"&$a&$de&$a&"Filename"&$a&$de&$a&"Inode"&$a&$de&$a&"Notes"&$a&$de&$a&"Format"&$a&$de&$a&"Extra"&$a
	ElseIf $DoBodyfile Then
		$Indx_Csv_Header = $a&"MD5"&$a&$de&$a&"name"&$a&$de&$a&"inode"&$a&$de&$a&"mode_as_string"&$a&$de&$a&"UID"&$a&$de&$a&"GID"&$a&$de&$a&"size"&$a&$de&$a&"atime"&$a&$de&$a&"mtime"&$a&$de&$a&"ctime"&$a&$de&$a&"crtime"&$a
	EndIf
	FileWriteLine($IndxEntriesObjIdOCsvFile, $Indx_Csv_Header & @CRLF)
EndFunc

Func _DecodeMacFromGuid($Input)
	If StringLen($Input) <> 12 Then Return SetError(1)
	Local $Mac = StringMid($Input,1,2) & "-" & StringMid($Input,3,2) & "-" & StringMid($Input,5,2) & "-" & StringMid($Input,7,2) & "-" & StringMid($Input,9,2) & "-" & StringMid($Input,11,2)
	Return $Mac
EndFunc

Func _DecodeTimestampFromGuid($StampDecode)
	$StampDecode = _SwapEndian($StampDecode)
	$StampDecode_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $StampDecode)
	$StampDecode = _WinTime_UTCFileTimeFormat(Dec($StampDecode,2) - $tDelta - $TimeDiff, $DateTimeFormat, $TimestampPrecision)
	If @error Then
		$StampDecode = $TimestampErrorVal
	ElseIf $TimestampPrecision = 3 Then
		$StampDecode = $StampDecode & $PrecisionSeparator2 & _FillZero(StringRight($StampDecode_tmp, 4))
	EndIf
	Return $StampDecode
EndFunc

Func _Decode_Reparse_R($InputData, $FirstEntryOffset)
	Local $EntryCounter=0
	$StartOffset = 1
	$InputDataSize = StringLen($InputData)

	;ConsoleWrite("_Decode_Reparse_R():" & @CRLF)
	;ConsoleWrite(_HexEncode("0x"&$InputData) & @CRLF)

	Do
		$RecordOffset = "0x" & Hex(Int($CurrentFileOffset + (($StartOffset-1)/2) + $FirstEntryOffset))

		$DataOffset = StringMid($InputData, $StartOffset, 4)
		$DataOffset = Dec(_SwapEndian($DataOffset),2)

		$DataSize = StringMid($InputData, $StartOffset + 4, 4)
		$DataSize = Dec(_SwapEndian($DataSize),2)

		If $DataOffset = 0 Then
			ConsoleWrite("Error: Invalid DataOffset" & @crlf)
			;ConsoleWrite(_HexEncode("0x"&StringMid($InputData, $StartOffset)) & @crlf)
			Return $EntryCounter
		EndIf

		;Padding 4 bytes
		$Padding1 = StringMid($InputData, $StartOffset + 8, 8)
		$Padding1 = Dec(_SwapEndian($Padding1),2)
		If $Padding1 <> 0 Then
			ConsoleWrite("Error: Invalid Padding1" & @crlf)
			Return $EntryCounter
		EndIf

		$IndexEntrySize = StringMid($InputData, $StartOffset + 16, 4)
		$IndexEntrySize = Dec(_SwapEndian($IndexEntrySize),2)
		If $IndexEntrySize = 0 Then ExitLoop

		$IndexKeySize = StringMid($InputData, $StartOffset + 20, 4)
		$IndexKeySize = Dec(_SwapEndian($IndexKeySize),2)

		$Flags = StringMid($InputData, $StartOffset + 24, 4)
;		If Dec(_SwapEndian($Flags),2) > 2 Then
;			ConsoleWrite("Error: Invalid Flags" & @crlf)
;			Return 0
;		EndIf
		$Flags = "0x" & _SwapEndian($Flags)

		;Padding 2 bytes
		$Padding2 = StringMid($InputData, $StartOffset + 28, 4)
		$Padding2 = Dec(_SwapEndian($Padding2),2)
		If $Padding2 <> 0 Then
			ConsoleWrite("Error: Invalid Padding2" & @crlf)
			Return $EntryCounter
		EndIf

		$KeyReparseTag = StringMid($InputData, $StartOffset + 32, 8)
		$KeyReparseTag = "0x" & _SwapEndian($KeyReparseTag)
		$KeyReparseTag = _GetReparseType($KeyReparseTag)
		If StringInStr($KeyReparseTag, "UNKNOWN") Then
			ConsoleWrite("Error: Invalid KeyReparseTag: " & $KeyReparseTag & @crlf)
			Return $EntryCounter
		EndIf

		$KeyMftRefOfReparsePoint = StringMid($InputData, $StartOffset + 40, 12)
		$KeyMftRefOfReparsePoint = Dec(_SwapEndian($KeyMftRefOfReparsePoint),2)
		If $KeyMftRefOfReparsePoint = 0 Then
			ConsoleWrite("Error: Invalid MftRef: " & $KeyMftRefOfReparsePoint & @crlf)
			Return $EntryCounter
		EndIf

		$KeyMftRefSeqNoOfReparsePoint = StringMid($InputData, $StartOffset + 52, 4)
		$KeyMftRefSeqNoOfReparsePoint = Dec(_SwapEndian($KeyMftRefSeqNoOfReparsePoint),2)
		If $KeyMftRefSeqNoOfReparsePoint = 0x0 Or $KeyMftRefSeqNoOfReparsePoint = 0xFFFF Then
			ConsoleWrite("Error: Invalid MftRefSeqNo: " & $KeyMftRefSeqNoOfReparsePoint & @crlf)
			Return $EntryCounter
		EndIf
		#cs
		ConsoleWrite(@CRLF)
		ConsoleWrite(_HexEncode("0x"&StringMid($InputData, $StartOffset, $IndexEntrySize*2)) & @CRLF)
		ConsoleWrite("$EntryCounter: " & $EntryCounter & @CRLF)
		ConsoleWrite("$DataOffset: " & $DataOffset & @CRLF)
		ConsoleWrite("$DataSize: " & $DataSize & @CRLF)
		ConsoleWrite("$IndexEntrySize: " & $IndexEntrySize & @CRLF)
		ConsoleWrite("$IndexKeySize: " & $IndexKeySize & @CRLF)
		ConsoleWrite("$Flags: " & $Flags & @CRLF)
		ConsoleWrite("$KeyReparseTag: " & $KeyReparseTag & @CRLF)
		ConsoleWrite("$KeyMftRefOfReparsePoint: " & $KeyMftRefOfReparsePoint & @CRLF)
		ConsoleWrite("$KeyMftRefSeqNoOfReparsePoint: " & $KeyMftRefSeqNoOfReparsePoint & @CRLF)
		#ce
		;Padding 4 bytes
		$Padding3 = StringMid($InputData, $StartOffset + 56, 8)
		$Padding3 = Dec(_SwapEndian($Padding3),2)
		If $Padding3 <> 0 Then
			ConsoleWrite("Error: Invalid Padding3" & @crlf)
			Return $EntryCounter
		EndIf

		If $WithQuotes Then
			Select
				Case $DoDefaultAll
					FileWriteLine($IndxEntriesReparseRCsvFile, '"'&$RecordOffset&'"'&$de&'"'&$IndxCurrentVcn&'"'&$de&'"'&$IsNotLeafNode&'"'&$de&'"'&$IndxLastLsn&'"'&$de&'"'&$FromIndxSlack&'"'&$de&'"'&$DataOffset&'"'&$de&'"'&$DataSize&'"'&$de&'"'&$Padding1&'"'&$de&'"'&$IndexEntrySize&'"'&$de&'"'&$IndexKeySize&'"'&$de&'"'&$Flags&'"'&$de&'"'&$Padding2&'"'&$de&'"'&$KeyMftRefOfReparsePoint&'"'&$de&'"'&$KeyMftRefSeqNoOfReparsePoint&'"'&$de&'"'&$KeyReparseTag&'"'&@crlf)
				Case $Dol2t
					FileWriteLine($IndxEntriesReparseRCsvFile, '"'&'"'& "" &'"' & $de & '"'& "" &'"' & $de & '"'& "" &'"' & $de & '"'&"MACB"&'"' & $de & '"'&"INDX"&'"' & $de & '"'&"Reparse:R"&'"' & $de & '"'& "" &'"' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& "" &'"' & $de & '"'&$KeyMftRefOfReparsePoint&'"' & $de & '"'&"Offset:"&$RecordOffset&" ReparseTag:"&$KeyReparseTag&" MftRefOfReparsePoint:"&$KeyMftRefOfReparsePoint&" MftRefSeqNoOfReparsePoint:"&$KeyMftRefSeqNoOfReparsePoint&'"' & $de & '""' & $de & '""' & @CRLF)
				Case $DoBodyfile
					FileWriteLine($IndxEntriesReparseRCsvFile, '""' & $de & '"'& "Reparse:R" &'"' & $de & '"'&$KeyMftRefOfReparsePoint&'"' & $de & '"'&"Reparse:R"&'"' & $de & '""' & $de & '""' & $de & '""' & $de & '"'& "" &'"' & $de & '"'& "" &'"' & $de & '"'& "" &'"' & $de & '"'& "" &'"' & @CRLF)
			EndSelect
		Else
			Select
				Case $DoDefaultAll
					FileWriteLine($IndxEntriesReparseRCsvFile, $RecordOffset&$de&$IndxCurrentVcn&$de&$IsNotLeafNode&$de&$IndxLastLsn&$de&$FromIndxSlack&$de&$DataOffset&$de&$DataSize&$de&$Padding1&$de&$IndexEntrySize&$de&$IndexKeySize&$de&$Flags&$de&$Padding2&$de&$KeyMftRefOfReparsePoint&$de&$KeyMftRefSeqNoOfReparsePoint&$de&$KeyReparseTag&@crlf)
				Case $Dol2t
					FileWriteLine($IndxEntriesReparseRCsvFile, "" & $de & "" & $de & "" & $de & "MACB" & $de & "INDX" & $de & "Reparse:R" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & "" & $de & $KeyMftRefOfReparsePoint & $de & "Offset:"&$RecordOffset&" ReparseTag:"&$KeyReparseTag&" MftRefOfReparsePoint:"&$KeyMftRefOfReparsePoint&" MftRefSeqNoOfReparsePoint:"&$KeyMftRefSeqNoOfReparsePoint & $de & "" & $de & "" & @CRLF)
				Case $DoBodyfile
					FileWriteLine($IndxEntriesReparseRCsvFile, "" & $de & "Reparse:R" & $de & $KeyMftRefOfReparsePoint & $de & "Reparse:R" & $de & "" & $de & "" & $de & "" & $de &  ""  & $de &  ""  & $de &  ""  & $de &  ""  & @CRLF)
			EndSelect
		EndIf

		$EntryCounter+=1
		$StartOffset += $IndexEntrySize*2
	Until $StartOffset >= $InputDataSize
	Return $EntryCounter
EndFunc

Func _WriteIndxReparseRModuleCsvHeader()
	Local $a
	If $WithQuotes Then
		$a = '"'
	Else
		$a = ""
	EndIf
	If $DoDefaultAll Then
		$Indx_Csv_Header = $a&"Offset"&$a&$de&$a&"Vcn"&$a&$de&$a&"IsNotLeaf"&$a&$de&$a&"LastLsn"&$a&$de&$a&"FromIndxSlack"&$a&$de&$a&"DataOffset"&$a&$de&$a&"DataSize"&$a&$de&$a&"Padding1"&$a&$de&$a&"IndexEntrySize"&$a&$de&$a&"IndexKeySize"&$a&$de&$a&"Flags"&$a&$de&$a&"Padding2"&$a&$de&$a&"MftRef"&$a&$de&$a&"MftRefSeqNo"&$a&$de&$a&"KeyReparseTag"&$a
	ElseIf $Dol2t Then
		$Indx_Csv_Header = $a&"Date"&$a&$de&$a&"Time"&$a&$de&$a&"Timezone"&$a&$de&$a&"MACB"&$a&$de&$a&"Source"&$a&$de&$a&"SourceType"&$a&$de&$a&"Type"&$a&$de&$a&"User"&$a&$de&$a&"Host"&$a&$de&$a&"Short"&$a&$de&$a&"Desc"&$a&$de&$a&"Version"&$a&$de&$a&"Filename"&$a&$de&$a&"Inode"&$a&$de&$a&"Notes"&$a&$de&$a&"Format"&$a&$de&$a&"Extra"&$a
	ElseIf $DoBodyfile Then
		$Indx_Csv_Header = $a&"MD5"&$a&$de&$a&"name"&$a&$de&$a&"inode"&$a&$de&$a&"mode_as_string"&$a&$de&$a&"UID"&$a&$de&$a&"GID"&$a&$de&$a&"size"&$a&$de&$a&"atime"&$a&$de&$a&"mtime"&$a&$de&$a&"ctime"&$a&$de&$a&"crtime"&$a
	EndIf
	FileWriteLine($IndxEntriesReparseRCsvFile, $Indx_Csv_Header & @CRLF)
EndFunc

Func _SetDateTimeFormats()
	Select
		Case $DateTimeFormat = 1
			$CharsToGrabDate = 8
			$CharStartTime = 9
			$CharsToGrabTime = 6
		Case $DateTimeFormat = 2
			$CharsToGrabDate = 10
			$CharStartTime = 11
			$CharsToGrabTime = 8
		Case $DateTimeFormat = 3
			$CharsToGrabDate = 10
			$CharStartTime = 11
			$CharsToGrabTime = 8
		Case $DateTimeFormat = 6
			$CharsToGrabDate = 10
			$CharStartTime = 11
			$CharsToGrabTime = 8
	EndSelect
EndFunc
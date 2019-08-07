This is a parser for INDX records of type $I30, $O ($ObjId) and $R ($Reparse). 
For $I30 this is the $INDEX_ALLOCATION attribute for directories which is an index with certain values from the $STANDARD_INFORMATION and $FILE_NAME attributes of all subitems (items within a folder).
For $ObjId there is an $O index (in $INDEX_ALLOCATION and/or $INDEX_ROOT) that holds data for all files on the volume that contain an $ObjectId attribute in their MFT record. In order to scan for this, make sure Scan mode = 0.
For $Reparse there is an $R index (in $INDEX_ALLOCATION and/or $INDEX_ROOT) that holds data for all files on the volume that contain an $REPARSE_POINT attribute in their MFT record. In order to scan for this, make sure Scan mode = 0.

On NTFS there are various types of INDX present in addition to $I30:
$INDEX_ALLOCATION:$SDH for $Secure. This is MftRef 9 and is the security descriptor hash index.
$INDEX_ALLOCATION:$SII for $Secure. This is MftRef 9 and is the security id index.
$INDEX_ALLOCATION:$O for $Quota. This is usually but not always for MftRef 24.
$INDEX_ALLOCATION:$Q for $Quota. This is usually but not always for MftRef 24.
$INDEX_ALLOCATION:$O for $ObjId. This is usually but not always for MftRef 25 and is for the index that holds information about all files that have the $OBJECT_ID attribute present.
$INDEX_ALLOCATION:$R for $Reparse. This is usually but not always for MftRef 26 and is for the index that holds information about all files that have the $REPARSE_POINT attribute present.

What input?
For best results, use IndxCarver to extract the INDX records. That tool will filter output into 3, which makes sense. That is 1 for false positive, 1 for records with fixups applied, and 1 for records without fixups applied. This way it is also easier to distinguish them.

What does it decode?
As much as possible. That is all the members within any INDX entry, plus some more.

Command line mode
No parameters supplied will by default launch GUI. The valid parameters are:

/IndxFile:
The input file with INDX records (as extracted with IndxCarver).
/OutputPath:
Optionally specify output dir. Default is current directory.
/TimeZone:
A string value for the timezone. See notes further down for valid values.
/Fixups:
Boolean value to apply fixups. Default is 1. Can be 0 or 1.
/Separator:
The separator to use in the csv. Default is |
/Unicode:
Boolean value for decoding unicode strings. Default is 0. Can be 0 or 1. Output quality may get severely reduced if this is set in combination with a set /Slack param.
/Slack:
Boolean value for scanning slack space. Default is 0. Can be 0 or 1.
/TSFormat:
An integer from 1 - 6 for specifying the timestamp format. Start the gui to see what they mean. Default is 6.
/TSPrecision:
What precision to use in the timestamp. Valid values are None, MilliSec and NanoSec. Default is NanoSec.
/TSPrecisionSeparator:
The separator to put in the separation of the precision. Default is ".". Start the gui to see what it means.
/TSPrecisionSeparator2:
The separator to put in between MilliSec and NanoSec in the precision of timestamp. Default is empty/nothing. Start the gui to see what it means.
/TSErrorVal:
A custom error value to put with errors in timestamp decode. Default value is '0000-00-00 00:00:00', which is compatible with MySql, and represents and invalid timestamp value for NTFS.
/IndxSize:
The size of the INDX records. Default is 4096.
/VerifyFragment:
Boolean value for activating a simple validation on a fragment only, and not full parser. Can be 0 or 1. Will by default write fixed fragment to OutFragment.bin unless otherwise specified in /OutFragmentName:
/OutFragmentName:
The output filename to write the fixed fragment to, if /VerifyFragment: is set to 1. If omitted, the default filename is OutFragment.bin.
/CleanUp:
Boolean value for cleaning up all output if no entries could be decoded. Default value is 1. Can be 0 or 1. This setting makes the most sense if program is run in loop in batch or similar.
/ScanMode:
An integer indicating the depth level of scan mode. 0 is normal mode without any scanning and is the default value. 1 is light level scanning. 15 is deepest level
/QuotationMark:
Boolean value for activation of quotation mark surrounding all values in output.
/OutputFormat:
Format of the csv output. Can be all, l2t or bodyfile. Default is all.
/StrictNameCheck:
Boolean value for applying extended name check with I30 entries in slack. Useful for unicode mode with many false positives in slack. Default is 1. 

Examples:
Indx2Csv.exe /IndxFile:c:\temp\chunk.wfixups.INDX
Indx2Csv.exe /IndxFile:c:\temp\chunk.wfixups.INDX /OutputPath:e:\temp
Indx2Csv.exe /IndxFile:c:\temp\chunk.wfixups.INDX /OutputPath:e:\temp /OutputFormat:l2t
Indx2Csv.exe /IndxFile:c:\temp\chunk.wfixups.INDX /OutputPath:e:\temp /Unicode:1 /StrictNameCheck:1
Indx2Csv.exe /IndxFile:c:\temp\chunk.wfixups.INDX /TimeZone:2.00 /TSFormat:1 /TSPrecision:NanoSec /Unicode:1
Indx2Csv.exe /IndxFile:c:\temp\chunk.wofixups.INDX /Fixups:0 /TimeZone:-5.00 /TSFormat:1 /TSPrecision:MilliSec
Indx2Csv.exe /IndxFile:c:\temp\chunk.wofixups.INDX /Fixups:0 /TSFormat:1 /TSPrecision:MilliSec /Slack:1 /Unicode:0
Indx2Csv.exe /IndxFile:C:\temp\fragment.bin /ScanMode:10 /VerifyFragment:1 /OutputPath:e:\I30Output /OutFragmentName:FragmentCollection.bin /CleanUp:1
Indx2Csv.exe /IndxFile:e:\I30Output\FragmentCollection.bin /OutputPath:e:\I30Output /ScanMode:10 /Fixups:0

Timestamp explanation
CTime -> File Create Time.
ATime -> File Modified Time.
MTime -> MFT Entry modified Time.
RTime -> File Last Access Time.

The available TimeZone's to use are:
-12.00
-11.00
-10.00
-9.30
-9.00
-8.00
-7.00
-6.00
-5.00
-4.30
-4.00
-3.30
-3.00
-2.00
-1.00
0.00
1.00
2.00
3.00
3.30
4.00
4.30
5.00
5.30
5.45
6.00
6.30
7.00
8.00
8.45
9.00
9.30
10.00
10.30
11.00
11.30
12.00
12.45
13.00
14.00

Error levels
The current exit (error) codes have been implemented in commandline mode, which makes it more suited for batch scripting.
1. No valid entries could be decoded. Empty output.
4. Failure in writing fixed fragment to output. Validation of fragment succeeded though.

Thus if you get %ERRORLEVEL% == 1 it means nothing was decoded, and if you get %ERRORLEVEL% == 4 then valid records where detected but could not be written to separate output (only used with /VerifyFragment: and /OutFragmentName:).

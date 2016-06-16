This is a parser for INDX records of type $I30. Specifically this is the $INDEX_ALLOCATION attribute for directories which is an index with certain values from the $STANDARD_INFORMATION and $FILE_NAME attributes of all subitems (items within a folder).

On NTFS there are various types of INDX present in addition to $I30:
$INDEX_ALLOCATION:$SDH for $Secure. This is MftRef 9 and is the security descriptor hash index.
$INDEX_ALLOCATION:$SII for $Secure. This is MftRef 9 and is the security id index.
$INDEX_ALLOCATION:$O for $Quota. This is for MftRef 24.
$INDEX_ALLOCATION:$Q for $Quota. This is for MftRef 24.
$INDEX_ALLOCATION:$O for $ObjId. This is for MftRef 25 and is for the index that holds information about all files that have the $OBJECT_ID attribute present.
$INDEX_ALLOCATION:$R for $Reparse. This is for MftRef 26 and is for the index that holds information about all files that have the $REPARSE_POINT attribute present.

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


Examples:
Indx2Csv.exe /IndxFile:c:\temp\chunk.wfixups.INDX
Indx2Csv.exe /IndxFile:c:\temp\chunk.wfixups.INDX /OutputPath:e:\temp
Indx2Csv.exe /IndxFile:c:\temp\chunk.wfixups.INDX /TimeZone:2.00 /TSFormat:1 /TSPrecision:NanoSec /Unicode:1
Indx2Csv.exe /IndxFile:c:\temp\chunk.wofixups.INDX /Fixups:0 /TimeZone:-5.00 /TSFormat:1 /TSPrecision:MilliSec
Indx2Csv.exe /IndxFile:c:\temp\chunk.wofixups.INDX /Fixups:0 /TSFormat:1 /TSPrecision:MilliSec /Slack:1 /Unicode:0

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

Changelog

v1.0.0.2
Added MySql support and a schema for INDX_I30 table.
Added missing TextInformation variable in csv in the core module (though not actually used there).

v1.0.0.1
Removed timestamp added to output directory.
Added all output files with prefix Indx_I30_Entries_.
Added timestamp into output file names.

v1.0.0.0
Initial version.
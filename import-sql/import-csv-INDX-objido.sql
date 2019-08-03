LOAD DATA LOCAL INFILE "__PathToCsv__"
INTO TABLE INDX_OBJIDO
CHARACTER SET 'latin1'
COLUMNS TERMINATED BY '__Separator__'
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(`Offset`, `Vcn`, `IsNotLeaf`, `LastLsn`, `FromIndxSlack`, `DataOffset`, `DataSize`, `Padding1`, `IndexEntrySize`, `IndexKeySize`, `Flags`, `Padding2`, @MftRef, @MftRefSeqNo, `ObjectId`, `ObjectId_Version`, @ObjectId_Timestamp, `ObjectId_TimestampDec`, `ObjectId_ClockSeq`, `ObjectId_Node`, `BirthVolumeId`, `BirthVolumeId_Version`, @BirthVolumeId_Timestamp, `BirthVolumeId_TimestampDec`, `BirthVolumeId_ClockSeq`, `BirthVolumeId_Node`, `BirthObjectId`, `BirthObjectId_Version`, @BirthObjectId_Timestamp, `BirthObjectId_TimestampDec`, `BirthObjectId_ClockSeq`, `BirthObjectId_Node`, `DomainId`, `DomainId_Version`, @DomainId_Timestamp, `DomainId_TimestampDec`, `DomainId_ClockSeq`, `DomainId_Node`, `TextInformation`)
SET 
MftRef = nullif(@MftRef,''),
MftRefSeqNo = nullif(@MftRefSeqNo,''),
ObjectId_Timestamp = STR_TO_DATE(@ObjectId_Timestamp, '__TimestampTransformationSyntax__'),
BirthVolumeId_Timestamp = STR_TO_DATE(@BirthVolumeId_Timestamp, '__TimestampTransformationSyntax__'),
BirthObjectId_Timestamp = STR_TO_DATE(@BirthObjectId_Timestamp, '__TimestampTransformationSyntax__'),
DomainId_Timestamp = STR_TO_DATE(@DomainId_Timestamp, '__TimestampTransformationSyntax__')
;
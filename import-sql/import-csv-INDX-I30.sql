LOAD DATA LOCAL INFILE "__PathToCsv__"
INTO TABLE INDX_I30
CHARACTER SET 'latin1'
COLUMNS TERMINATED BY '__Separator__'
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(`Offset`, `Vcn`, `IsNotLeaf`, @LastLsn, @FromIndxSlack, `FileName`, @MFTReference, @MFTReferenceSeqNo, @IndexFlags, @MFTParentReference, @MFTParentReferenceSeqNo, @CTime, @ATime, @MTime, @RTime, @AllocSize, @RealSize, `FileFlags`, `ReparseTag`, @EaSize, `NameSpace`, @`SubNodeVCN`, @`CorruptEntries`)
SET 
LastLsn = nullif(@LastLsn,''),
FromIndxSlack = nullif(@FromIndxSlack,''),
MFTReference = nullif(@MFTReference,''),
MFTReferenceSeqNo = nullif(@MFTReferenceSeqNo,''),
IndexFlags = nullif(@IndexFlags,''),
MFTParentReference = nullif(@MFTParentReference,''),
MFTParentReferenceSeqNo = nullif(@MFTParentReferenceSeqNo,''),
`CTime` = STR_TO_DATE(@CTime, '__TimestampTransformationSyntax__'),
`ATime` = STR_TO_DATE(@ATime, '__TimestampTransformationSyntax__'),
`MTime` = STR_TO_DATE(@MTime, '__TimestampTransformationSyntax__'),
`RTime` = STR_TO_DATE(@RTime, '__TimestampTransformationSyntax__'),
AllocSize = nullif(@AllocSize,''),
RealSize = nullif(@RealSize,''),
EaSize = nullif(@EaSize,''),
SubNodeVCN = nullif(@SubNodeVCN,''),
CorruptEntries = nullif(@CorruptEntries,'')
;
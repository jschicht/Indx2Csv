LOAD DATA INFILE "__PathToCsv__"
INTO TABLE INDX_I30
CHARACTER SET 'latin1'
COLUMNS TERMINATED BY '|'
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(`Offset`, @LastLsn, @FromIndxSlack, `FileName`, @MFTReference, @MFTReferenceSeqNo, @IndexFlags, @MFTParentReference, @MFTParentReferenceSeqNo, CTime, ATime, MTime, RTime, @AllocSize, @RealSize, `FileFlags`, `ReparseTag`, `NameSpace`, @`SubNodeVCN`, @`TextInformation`)
SET 
LastLsn = nullif(@LastLsn,''),
FromIndxSlack = nullif(@FromIndxSlack,''),
MFTReference = nullif(@MFTReference,''),
MFTReferenceSeqNo = nullif(@MFTReferenceSeqNo,''),
IndexFlags = nullif(@IndexFlags,''),
MFTParentReference = nullif(@MFTParentReference,''),
MFTParentReferenceSeqNo = nullif(@MFTParentReferenceSeqNo,''),
AllocSize = nullif(@AllocSize,''),
RealSize = nullif(@RealSize,''),
SubNodeVCN = nullif(@SubNodeVCN,''),
TextInformation = nullif(@TextInformation,'')
;
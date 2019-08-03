LOAD DATA LOCAL INFILE "__PathToCsv__"
INTO TABLE INDX_REPARSER
CHARACTER SET 'latin1'
COLUMNS TERMINATED BY '__Separator__'
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(`Offset`, `Vcn`, `IsNotLeaf`, `LastLsn`, `FromIndxSlack`, `DataOffset`, `DataSize`, `Padding1`, `IndexEntrySize`, `IndexKeySize`, `Flags`, `Padding2`, @MftRef, @MftRefSeqNo, `KeyReparseTag`)
SET 
MftRef = nullif(@MftRef,''),
MftRefSeqNo = nullif(@MftRefSeqNo,'')
;

CREATE TABLE INDX_REPARSER(
	`Id`							INT(11) NOT NULL AUTO_INCREMENT
	,`Offset`						VARCHAR(18) NULL DEFAULT NULL
	,`LastLsn`						BIGINT NULL DEFAULT NULL
	,`FromIndxSlack`				TINYINT(1) NULL DEFAULT NULL
	,`DataOffset`					SMALLINT(5) NULL DEFAULT NULL
	,`DataSize`						SMALLINT(5) NULL DEFAULT NULL
	,`Padding1`						INT(11) NULL DEFAULT NULL
	,`IndexEntrySize`				SMALLINT(5) NULL DEFAULT NULL
	,`IndexKeySize`					SMALLINT(5) NULL DEFAULT NULL
	,`Flags`						VARCHAR(6) NULL DEFAULT NULL
	,`Padding2`						SMALLINT(5) NULL DEFAULT NULL
	,`MftRef`						BIGINT  NOT NULL
	,`MftRefSeqNo`					SMALLINT(5)  NOT NULL
	,`KeyReparseTag`				VARCHAR(32) NULL DEFAULT NULL
	,PRIMARY KEY (Id)
);
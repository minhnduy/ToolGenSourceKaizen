-- test store 

--format 
--	System_SP_Select       [SPCode], [TableName], [ColumnName], [ColumnAlias], [ColumnQuery]
--  System_sp_tablelinks   [SPCode], [TableName], [TableAlias], [Order], [JointTable], [JointTableColumn], [LinkedTableColumn], [JointType], [ExtraConditions], [CustomQuery], [IsRequired]

EXEC KAIZEN_STORE 
@ClauseSelect = N'ao.*,cs."ShiftName"',
@ClauseFrom = N'*Att_Overtime ao*INNER JOIN Hre_Profile hp ON ao."ProfileID" = hp.ID*LEFT JOIN "Cat_Shift" cs ON ao."ShiftID" = cs."ID" AND cs."IsDelete" IS NULL',
@SpCode = 'MIN_TST_SP1',
@CheckStore = 1


('MIN_TST_SP1','Att_Overtime','IsEmergency','IsEmergency',NULL),




SELECT * FROM  System_SP_SelectColumns where SPCode ='MIN_TST_SP1'
SELECT * FROM  System_SP_TableLinks  where SPCode ='MIN_TST_SP1'

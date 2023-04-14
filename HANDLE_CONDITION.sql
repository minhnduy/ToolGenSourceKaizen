
-- handle condition clause => format  TableAlias.ColumnName
CREATE OR ALTER PROCEDURE HANDLE_CONDITION
	@strCondition nvarchar(max) = NULL
AS
BEGIN
	
	declare @len_str int = 0
	declare @and_index int = 0

	select @and_index = CHARINDEX(N' AND ', upper(@strCondition));
	select @len_str = len(@strCondition);

	declare @tableResult table(
		TableAlias nvarchar(max),
		ColumnName nvarchar(max)
	)

	declare @table_alias nvarchar(max),
			@column_name nvarchar(max);

	declare @endStrIndex int = @and_index;
	if @and_index = 0 
		set @endStrIndex = @len_str + 1

	
	declare @valueStr nvarchar(max)
	-- condition don
	select @valueStr = SUBSTRING(@strCondition, 0, @endStrIndex)
	select @valueStr = REPLACE(@valueStr, ' ','')
	
	IF OBJECT_ID('tempdb..#TABLE_CONDITION') IS NOT NULL
		DROP TABLE #TABLE_CONDITION
	select 
		StrCondition
	into 
		#TABLE_CONDITION
	from
		(
			select value as StrCondition From string_split(@valueStr, N'=')
		) A

	declare @valueLoop nvarchar(max)
	declare cur_condition cursor for
	select * from #TABLE_CONDITION

	open cur_condition;
	fetch next from cur_condition into @valueLoop
	
	while @@FETCH_STATUS = 0
	begin
		select @table_alias = null, @column_name = null;
		exec GET_COLUMN_TABLE_ALIAS
			@pStrSelect = @valueLoop,		
			@pTableAlias = @table_alias out,
			@pColumnName = @column_name out
		insert into @tableResult(TableAlias, ColumnName)
		values( @table_alias, @column_name)
		fetch next from cur_condition into @valueLoop
	end
	close cur_condition
	deallocate cur_condition
    DROP TABLE #TABLE_CONDITION
	select * from @tableResult
END

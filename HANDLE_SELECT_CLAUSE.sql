CREATE OR ALTER procedure HANDLE_SELECT_CLAUSE
	@selectClause nvarchar(max) = NULL
AS
begin
	declare @tableResult table
	(
		TableAlias nvarchar(max),
		ColumnName nvarchar(max),
		ColumnAlias nvarchar(max),
		SubQuery nvarchar(max)
	)
	Declare 
		@TableAlias nvarchar(max),
		@ColumnName nvarchar(max),
		@ColumnAlias nvarchar(max),
		@SubQuery nvarchar(max)

	IF OBJECT_ID('tempdb..#tableSelect') IS NOT NULL
	DROP TABLE #tableSelect
	select 
		querySelectClause
	into 
		#tableSelect
	from
		(
			select value as querySelectClause From string_split(@selectClause, ',')
		) A
	where querySelectClause <> '' and querySelectClause is not null

	declare @value_str_select nvarchar(max)
	declare cur_select cursor
	for select querySelectClause from #tableSelect
	open cur_select
	fetch next from cur_select into @value_str_select

	while @@FETCH_STATUS = 0
	begin
		select				
			@TableAlias = NULL , 
			@ColumnName = NULL , 
			@ColumnAlias = NULL , 
			@SubQuery = NULL;
			
		exec HANDLE_SELECT_CLAUSE_SUB
			@strSelect = @value_str_select,
			@table_alias = @TableAlias OUTPUT, 
			@column_name = @ColumnName OUTPUT, 
			@column_alias = @ColumnAlias OUTPUT, 
			@sub_query = @SubQuery OUTPUT

	
		insert into @tableResult(TableAlias,ColumnName,ColumnAlias,SubQuery)
		values (@TableAlias,@ColumnName,@ColumnAlias,@SubQuery)

		fetch next from cur_select into @value_str_select
	end
	close cur_select
	deallocate cur_select

	select * from @tableResult
	DROP TABLE #tableSelect

end

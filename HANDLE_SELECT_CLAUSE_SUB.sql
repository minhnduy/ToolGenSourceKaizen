--handle select clause
CREATE OR ALTER procedure HANDLE_SELECT_CLAUSE_SUB
 	@strSelect nvarchar(max) = NULL,
	@table_alias nvarchar(max) = NULL OUTPUT, 
	@column_name nvarchar(max) = NULL OUTPUT, 
	@column_alias nvarchar(max) = NULL OUTPUT, 
	@sub_query nvarchar(max) = NULL OUTPUT

as
begin
	declare @len_str int = 0
	declare @as_index int = 0
	declare @check_sub bit = 0
	declare @local_value nvarchar(max) = null

	-- declare @column_name nvarchar(max) = null
	-- declare @column_alias nvarchar(max) = null
	-- declare @table_alias nvarchar(max) = null
	-- declare @sub_query nvarchar(max) = null

	declare @before_as nvarchar(max) = null
	declare @after_as nvarchar(max) = null

	SELECT @strSelect = REPLACE(@strSelect,'"','')

	if (select count(value) from string_split(@strSelect,N'.')) > 2
	begin
		set @check_sub = 1
	end
	-- xu ly 1
	begin
		select @as_index = CHARINDEX(N' AS ', upper(@strSelect));
		select @len_str = len(@strSelect);
	
		-- sub query
		if @check_sub = 1
		begin
			select @sub_query = SUBSTRING(@strSelect, 0, @as_index)
			select @column_alias = SUBSTRING(@strSelect, @as_index + 4, @len_str)
			select top 1 @local_value = value from string_split(@sub_query, N' ') where value <> N'' and value is not null and CHARINDEX(N'.',@sub_query) <> 0
			exec GET_COLUMN_TABLE_ALIAS
				@pStrSelect = @local_value,		
				@pTableAlias = @table_alias out,
				@pColumnName = @column_name out
		end
		-- non sub query
		else
		begin
			-- neu co as
			if @as_index > 0 
			begin
				declare @valueStr nvarchar(max)
				select @column_alias = SUBSTRING(@strSelect, @as_index + 4, @len_str)
				select @valueStr = SUBSTRING(@strSelect, 0, @as_index)

				exec GET_COLUMN_TABLE_ALIAS
					@pStrSelect = @valueStr,		
					@pTableAlias = @table_alias out,
					@pColumnName = @column_name out
			end
			-- neu khong co as
			if @as_index = 0
			begin
				exec GET_COLUMN_TABLE_ALIAS
					@pStrSelect = @strSelect,		
					@pTableAlias = @table_alias out,
					@pColumnName = @column_name out
			end
		end;
	end
	--select @table_alias as TableAlias, @column_name as ColumnName, @column_alias as ColumnAlias, @sub_query as SubQuery

end
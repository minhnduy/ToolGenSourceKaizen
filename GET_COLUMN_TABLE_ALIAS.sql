
CREATE OR ALTER procedure GET_COLUMN_TABLE_ALIAS
@pStrSelect nvarchar(max)= NULL,
@pTableAlias nvarchar(max) output,
@pColumnName nvarchar(max) output
as
begin
	declare @value nvarchar(max)
	declare @index int = 0
	
	declare cur_select_split cursor for
	select value from string_split(@pStrSelect, '.') where value <> N'' and value is not NULL
	open cur_select_split
	fetch next from cur_select_split into @value

	while @@FETCH_STATUS = 0
	begin
		if @index = 0
			set @pTableAlias = @value
		else 
			set @pColumnName = @value
		set @index = @index + 1;
		fetch next from cur_select_split into @value
	end
	close cur_select_split
	deallocate cur_select_split
end
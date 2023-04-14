CREATE OR ALTER PROCEDURE HANDLE_FROM_CLAUSE
	@queryFrom nvarchar(max) = NULL
AS
BEGIN
	-- init varliable
	begin
		declare
			@countTableFrom1 int = 0

		-- khai bao bien cho cong loop tai tableFrom1
		declare @valueTableFrom1 nvarchar(max) = ''

		declare @tableResult_FromClause table
		(
			jointype nvarchar(max),
			tableName nvarchar(max),
			tableAlias nvarchar(max),
			condition nvarchar(max),
			subQuery nvarchar(max)
		)
		
		declare 
			@jointype nvarchar(max),
			@tableName nvarchar(max),
			@tableAlias nvarchar(max),
			@condition nvarchar(max),
			@subQuery nvarchar(max)
	end

	-- split line with * character
		-- list line insert to table ##TABLE_FROM_CLAUSE_TMP line
	begin
		IF OBJECT_ID('tempdb..#TABLE_FROM_CLAUSE_TMP') IS NOT NULL
			DROP TABLE #TABLE_FROM_CLAUSE_TMP
		select 
			queryClauseFrom
		into 
			#TABLE_FROM_CLAUSE_TMP
		from
			(
				select value as queryClauseFrom From string_split(@queryFrom, N'*')
			) A
	end
		
	-- khai bao loop cho tableFrom1 line
	declare cur_tableFrom1 cursor
		for select 	queryClauseFrom from #TABLE_FROM_CLAUSE_TMP where queryClauseFrom <> NUll or queryClauseFrom <> N'' or REPLACE(queryClauseFrom,' ','') <> N''
	   
	--while loop in ##TABLE_FROM_CLAUSE_TMP line 
	begin

		open cur_tableFrom1;
		FETCH NEXT FROM cur_tableFrom1     -- read first line
		  INTO @valueTableFrom1

		while @@FETCH_STATUS = 0
		begin
			----first line
			if @countTableFrom1 = 0
			begin
				declare @valueTableNameFirst nvarchar(max), @valueTableAlias nvarchar(max)
				IF OBJECT_ID('tempdb..#TABLE_FROM_CLAUSE_FIRST_LINE') IS NOT NULL
				DROP TABLE #TABLE_FROM_CLAUSE_FIRST_LINE
				select 
					queryClauseFrom
				into 
					#TABLE_FROM_CLAUSE_FIRST_LINE
				from
					(
						select value as queryClauseFrom From string_split(@valueTableFrom1, N' ') 
					) A
				where queryClauseFrom is not null and queryClauseFrom <> N''
				declare @strFirstLine nvarchar(max)
				declare @countFirstLine int = 0
				declare cur_first_line cursor
				for select * from #TABLE_FROM_CLAUSE_FIRST_LINE

				open cur_first_line
				fetch next from cur_first_line into @strFirstLine
				while @@FETCH_STATUS = 0
				begin
					if @countFirstLine = 0
						set @valueTableNameFirst = @strFirstLine
					else
						set @valueTableAlias = @strFirstLine
					set @countFirstLine = @countFirstLine + 1;
					fetch next from cur_first_line into @strFirstLine
				end
				close cur_first_line
				deallocate cur_first_line

				insert into @tableResult_FromClause (tableAlias, tableName)
				values( @valueTableAlias, @valueTableNameFirst)
				DROP TABLE #TABLE_FROM_CLAUSE_FIRST_LINE

			end;

			-- orther line
			if @countTableFrom1 > 0
			begin
				-- call handle from clause
				-- returns the processed table from the from clause
				exec [HANDLE_FROM_CLAUSE_SUB]
						@prString = @valueTableFrom1

				select	@jointype = NULL,
						@tableName = NULL,
						@tableAlias = NULL,
						@condition = NULL,
						@subQuery = NULL;

				exec [HANDLE_FROM_CLAUSE_SUB]
						@prString = @valueTableFrom1,
						@pJoinType   =	@jointype output,
						@pTableName  =	@tableName output,
						@pTableAlias =	@tableAlias output,
						@pSubQuery   =	@subQuery output,
						@pCondition  =	@condition output

				insert into @tableResult_FromClause (jointype ,tableName ,tableAlias ,condition ,subQuery)
				values(@jointype,@tableName,@tableAlias,@condition,@subQuery)

			end
			set @countTableFrom1 = @countTableFrom1 + 1
			FETCH NEXT FROM cur_tableFrom1     -- read NEXT line
			INTO @valueTableFrom1
		end
		close cur_tableFrom1
		deallocate cur_tableFrom1
	end

	select * from @tableResult_FromClause
	
	--DROP TABLE TEMP
	DROP TABLE #TABLE_FROM_CLAUSE_TMP
END
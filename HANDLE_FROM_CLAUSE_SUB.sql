
CREATE OR ALTER procedure [dbo].[HANDLE_FROM_CLAUSE_SUB]
	@prString nvarchar(max) = NULL,
	@pJoinType nvarchar(max) = NULL output,
	@pTableName nvarchar(max) = NULL output,
	@pTableAlias nvarchar(max) = NULL output,
	@pSubQuery nvarchar(max) = NULL output,
	@pCondition nvarchar(max) = NULL output

as 
begin
	-- declare
	-- 	@pJoinType nvarchar(max),
	-- 	@pTableName nvarchar(max),
	-- 	@pTableAlias nvarchar(max),
	-- 	@pSubQuery nvarchar(max),
	-- 	@pCondition nvarchar(max)
	SELECT @prString = REPLACE(@prString,N'"',N'')
	-- sub query => split with '$' => split index 0 , 2 with space
	if @prString like '%$%'
	begin
		IF OBJECT_ID('tempdb..#TABLE_FUNC_1') IS NOT NULL
		DROP TABLE #TABLE_FUNC_1
		select 
			queryClauseFrom
		into 
			#TABLE_FUNC_1
		from
			(
				select value as queryClauseFrom From string_split(@prString, '$')
			) A
		declare @countFunc1 int = 0;

		declare cur_Funcloop1 cursor
		for select queryClauseFrom from #TABLE_FUNC_1 where queryClauseFrom  is not null and queryClauseFrom <> '' and REPLACE(queryClauseFrom,' ','') <> ''  and upper(queryClauseFrom) <> 'JOIN'

		declare @strLoop1 nvarchar(max) 

		open cur_Funcloop1
		fetch next from cur_Funcloop1 into @strLoop1
		while @@FETCH_STATUS = 0
		begin
			if @countFunc1 = 0
			begin
				select top 1 @pJoinType = value from string_split(@strLoop1, ' ') where value <> '' and value is not null
			end
			else
			begin
				if @countFunc1 = 1
				begin
                    -- sub query
					set @pSubQuery = @strLoop1;

                    declare @strSub nvarchar(max)
                    declare @checkFrom bit = 0

                    declare cur_sub_loop cursor
                    for select value from string_split(@strLoop1, ' ') where value <> '' and value is not null

                    open cur_sub_loop
                    fetch next from cur_sub_loop into @strSub
                    while @@FETCH_STATUS = 0
                    begin
                        if @checkFrom = 1
                        begin
                            set @pTableName = @strSub
                            set @checkFrom = 0;
                        end
                        if upper(@strSub) = 'FROM'
                            set @checkFrom = 1                   
                        
                        fetch next from cur_sub_loop into @strSub
                    end
                    close cur_sub_loop
                    deallocate cur_sub_loop


				end
				else
				begin
					if @countFunc1 = 2
					begin
						IF OBJECT_ID('tempdb..#TABLE_IN_LOOP_1') IS NOT NULL
						DROP TABLE #TABLE_IN_LOOP_1
						select 
							querySub
						into 
							#TABLE_IN_LOOP_1
						from
							(
								select value as querySub From string_split(@strLoop1, ' ')
							) A
						declare @countFuncInside int = 0;
						declare @valueInside nvarchar(max) =''
					
						declare cur_index_sub cursor
						for select querySub from #TABLE_IN_LOOP_1 where querySub is not null and querySub <> ''
					
						open cur_index_sub
						fetch next from cur_index_sub into @valueInside
						while @@FETCH_STATUS = 0
						begin
							if @countFuncInside = 0
							begin 
								set @pTableAlias = @valueInside
							end
							else
							begin
								if upper(@valueInside) <> 'ON'
									set @pCondition = concat(@pCondition,' ',@valueInside)
							end
						
							set @countFuncInside = @countFuncInside + 1
							fetch next from cur_index_sub into @valueInside
						end
						close cur_index_sub              -- Đóng Cursor
						deallocate cur_index_sub         -- Giải phóng tài nguyên

						DROP TABLE #TABLE_IN_LOOP_1
					end
				end
			end			

			set @countFunc1 = @countFunc1 + 1;
			fetch next from cur_Funcloop1 into @strLoop1
		end	
		close cur_Funcloop1              -- Đóng Cursor
		deallocate cur_Funcloop1         -- Giải phóng tài nguyên

		DROP TABLE #TABLE_FUNC_1
	end
	-- non sub query => split with space
	else
	begin
		IF OBJECT_ID('tempdb..#TABLE_FUNC_2') IS NOT NULL
		DROP TABLE #TABLE_FUNC_2
		select 
			queryClauseFrom
		into 
			#TABLE_FUNC_2
		from
			(
				select value as queryClauseFrom From string_split(@prString, ' ')
			) A

		declare @countFunc2 int = 0;
		declare @valueFunc2 nvarchar(max);

		declare cur_FuncLoop2 cursor
		for select queryClauseFrom from #TABLE_FUNC_2 where queryClauseFrom  is not null and queryClauseFrom <> '' and REPLACE(queryClauseFrom,' ','') <> '' and upper(queryClauseFrom) <> 'JOIN'
		open cur_FuncLoop2
		fetch next from cur_FuncLoop2 into @valueFunc2

		while @@FETCH_STATUS = 0
		begin
			if @countfunc2 = 0
				set @pJoinType = @valueFunc2
			if @countFunc2 = 1
				set @pTableName = @valueFunc2
			if @countFunc2 = 2
				set @pTableAlias = @valueFunc2
			if @countFunc2 > 2 and upper(@valueFunc2) <> 'ON' 
				set @pCondition = concat(@pCondition , ' ' , @valueFunc2)
			set @countFunc2 = @countFunc2 + 1;
			fetch next from cur_FuncLoop2 into @valueFunc2
		end
	
		close cur_FuncLoop2              -- Đóng Cursor
		deallocate cur_FuncLoop2         -- Giải phóng tài nguyên
		DROP TABLE #TABLE_FUNC_2
	
	end

end

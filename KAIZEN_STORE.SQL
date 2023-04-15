
CREATE OR ALTER PROCEDURE [dbo].[KAIZEN_STORE](
	@ClauseSelect nvarchar(max) = NULL,
	@ClauseFrom nvarchar(max) = NULL,
	@SpCode nvarchar(16) = 'TEST_STORE'		
	)
AS
BEGIN
	BEGIN TRY
		-- xu ly 1 cau select
		begin
			declare @tableSelect_1 table(
				TableAlias nvarchar(10),
				TableName nvarchar(max),
				ColumnName nvarchar(max),
				ColumnAlias nvarchar(max),
				SubQuery   nvarchar(max),
				QueryResult nvarchar(max)
			)
			insert into @tableSelect_1(TableAlias,ColumnName,ColumnAlias,SubQuery)   
			exec HANDLE_SELECT_CLAUSE
				@selectClause =@ClauseSelect
		end

		-- xu ly 1 cau from
		begin 
			declare @tableFrom_1 table(
				JoinType nvarchar(max),
				TableName nvarchar(max),
				TableNameConvert nvarchar(max),
				TableAlias nvarchar(max),
				Condition nvarchar(max),
				SubQuery nvarchar(max),
				LinkTable nvarchar(max),
				LinkTableField nvarchar(max),
				FieldJoin nvarchar(max),
				IndexJoin int,
				QueryResult nvarchar(max)
			)
			insert into @tableFrom_1(JoinType,TableName,TableAlias,Condition,SubQuery)
			exec HANDLE_FROM_CLAUSE
			@queryFrom = @ClauseFrom
			update @tableFrom_1
			set TableAlias = (select REPLACE(TableAlias,' ','')),
				TableName = (select REPLACE(TableName,' ',''))
			update @tableFrom_1
			set TableNameConvert = CONCAT(TableName,'_',TableAlias)
			where SubQuery is not null
		end

		-- xu ly from 2
		begin
			declare @table_main nvarchar(max)
			select top 1 @table_main = TableAlias from @tableFrom_1

			update @tableFrom_1
			set IndexJoin = 0
			where TableAlias = @table_main

	
			declare @tableResult table(
				TableAlias nvarchar(max),
				ColumnName nvarchar(max)
			)
			declare @table_alias nvarchar(max),
					@table_name nvarchar(max),
					@condition  nvarchar(max);

			declare cur_join cursor for
			select TableAlias,TableName, Condition from @tableFrom_1 where IndexJoin is null
			open cur_join;
			fetch next from cur_join 
			into @table_alias,
				@table_name ,
				@condition  

			while @@FETCH_STATUS = 0
			begin		
				declare @lop_table_alias nvarchar(max),
						@lop_column_name nvarchar(max)

				delete @tableResult;
				insert into @tableResult
				EXEC HANDLE_CONDITION @strCondition = @condition
		
				select @lop_table_alias = null, @lop_column_name = null;
		
				declare cur_join_in cursor for
				select * from @tableResult
				open cur_join_in;

				fetch next from cur_join_in into @lop_table_alias,@lop_column_name
				while @@FETCH_STATUS = 0
				begin
			
					if @lop_table_alias = @table_alias
					begin
						update @tableFrom_1
						set FieldJoin = @lop_column_name
						where TableAlias = @table_alias
					end
					else 
					begin
						declare @tableJoinLink nvarchar(max)
						select @tableJoinLink = case when TableNameConvert is not null then TableNameConvert else TableName end from @tableFrom_1 where TableAlias = @lop_table_alias
						update @tableFrom_1
						set LinkTableField = @lop_column_name,
							LinkTable = @tableJoinLink
						where TableAlias = @table_alias
					end

					fetch next from cur_join_in into @lop_table_alias,@lop_column_name
				end
				close cur_join_in
				deallocate cur_join_in
		
				fetch next from cur_join 
				into @table_alias,
					@table_name ,
					@condition  
			end
			close cur_join
			deallocate cur_join
		end 

		-- xu ly them vao table select column
		begin
			-- truong hop table main
			insert into @tableSelect_1 (TableAlias, ColumnName)
			select TableAlias , FieldJoin
			from @tableFrom_1
			-- truong hop la table link
			insert into @tableSelect_1 (TableAlias, ColumnName)
			select fr2.TableAlias , fr1.LinkTableField
			from @tableFrom_1 fr1
			inner join @tableFrom_1 fr2 
			on fr1.LinkTable = (case when fr2.TableNameConvert is not null then fr2.TableNameConvert else fr2.TableName end)


		end

		----handle select all from table name
		begin
			declare @tableAlias$slt_all nvarchar(10)
			declare cur_slt_all cursor for select TableAlias from @tableSelect_1 where ColumnName ='*'
			open cur_slt_all;
			fetch next from cur_slt_all into @tableAlias$slt_all;
			while @@FETCH_STATUS = 0
			begin
				declare @tableName$slt_all nvarchar(max) = null;
				select top 1 @tableName$slt_all = TableName from @tableFrom_1 where TableAlias = @tableAlias$slt_all

				-- xoa dong select *
				delete @tableSelect_1 where TableAlias = @tableAlias$slt_all and ColumnName = '*'

				insert into @tableSelect_1 (TableAlias, ColumnName)
				select @tableAlias$slt_all
					, COLUMN_NAME
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = @tableName$slt_all		

				fetch next from cur_slt_all into @tableAlias$slt_all;
			end
			close cur_slt_all;
			deallocate cur_slt_all;
		end

		-- xu ly field 
		begin
			declare @tableColumnTmp table(
				TableAlias nvarchar(max),
				ColumnName nvarchar(max)
			)
			declare @tableColumn table(
				TableAlias nvarchar(max),
				ColumnName nvarchar(max)
			)
			--from clause
			begin
				declare @valueLoopFrom nvarchar(max)
				declare cur_from_column cursor
				for select Condition from @tableFrom_1 where Condition is not null
				open cur_from_column
				fetch next from cur_from_column into @valueLoopFrom
				while @@FETCH_STATUS = 0
				begin		
					insert into @tableColumnTmp(TableAlias,ColumnName)
					EXEC HANDLE_CONDITION @strCondition= @valueLoopFrom
					fetch next from cur_from_column into @valueLoopFrom
				end
				close cur_from_column
				deallocate cur_from_column;
			end
			--select clause
			begin
				insert into @tableColumnTmp(TableAlias,ColumnName)
				select TableAlias, ColumnName from @tableSelect_1
			end
			insert into @tableColumn
			select distinct TableAlias, ColumnName from @tableColumnTmp
		end

		-- xu ly them field tai sub query
		begin

			IF OBJECT_ID('tempdb..#TABLE_SUB_QUERY') IS NOT NULL
				DROP TABLE #TABLE_SUB_QUERY
			select 
				TableAlias,
				TableName,
				SubQuery
			into 
				#TABLE_SUB_QUERY
			from
				(
					select TableAlias,TableName,SubQuery From @tableFrom_1
				) A
			where SubQuery is not null
		
			declare 
				@vTableAlias nvarchar(max),
				@vTableName	 nvarchar(max),
				@vSubQuery	 nvarchar(max),
				@resultSubString varchar(max),
				@resultSelect nvarchar(max)
			declare cur_sub_query cursor for select * from #TABLE_SUB_QUERY
			open cur_sub_query
			fetch next from cur_sub_query 
			into @vTableAlias,
				 @vTableName,	
				 @vSubQuery;
			while @@FETCH_STATUS = 0
			begin
				set @resultSubString = '';
	
				SELECT @resultSubString = STUFF(
								(   SELECT ',' + CONVERT(NVARCHAR(20), ColumnName) 
									FROM @tableColumn 
									WHERE TableAlias = @vTableAlias 
									FOR xml path('')
								)
								, 1
								, 1
								, '')
		
				update @tableFrom_1
				set SubQuery = concat('Select ',@resultSubString,' From ',@vTableName,' Where IsDelete Is NULL')
				where TableAlias = @vTableAlias

				fetch next from cur_sub_query 
				into @vTableAlias,
					 @vTableName,	
					 @vSubQuery;
			end
			close cur_sub_query;
			deallocate cur_sub_query;

			DROP TABLE #TABLE_SUB_QUERY
		end

		-- update index join
		begin
			update @tableFrom_1
			set IndexJoin = 1
			where TableAlias 
			in ( select TableAlias from @tableFrom_1 where LinkTable in (select case when TableNameConvert is not null then TableNameConvert else TableName end from @tableFrom_1 where IndexJoin = 0))

			update @tableFrom_1
			set IndexJoin = 2
			where TableAlias 
			in ( select TableAlias from @tableFrom_1 where LinkTable in (select case when TableNameConvert is not null then TableNameConvert else TableName end from @tableFrom_1 where IndexJoin = 1))

			update @tableFrom_1
			set IndexJoin = 3
			where TableAlias 
			in ( select TableAlias from @tableFrom_1 where LinkTable in (select case when TableNameConvert is not null then TableNameConvert else TableName end from @tableFrom_1 where IndexJoin = 2))

			update @tableFrom_1
			set IndexJoin = 4
			where TableAlias 
			in ( select TableAlias from @tableFrom_1 where LinkTable in (select case when TableNameConvert is not null then TableNameConvert else TableName end from @tableFrom_1 where IndexJoin = 3))
		end

		-- xu ly cau insert vao table System_SP_Select
		begin
			declare @tableSelect_2 table(
				TableAlias nvarchar(10),
				TableName nvarchar(max),
				ColumnName nvarchar(max),
				ColumnAlias nvarchar(max),
				SubQuery   nvarchar(max),
				QueryResult nvarchar(max)
			)
			insert into @tableSelect_2 (TableAlias, TableName, ColumnName, ColumnAlias, SubQuery, QueryResult)
			select sl.TableAlias,
				case when fr.TableNameConvert is not null then fr.TableNameConvert else fr.TableName end as TableName,
				sl.ColumnName,
				case when sl.ColumnAlias is not null then sl.ColumnAlias else sl.ColumnName end as ColumnAlias,
				sl.SubQuery,
				NULL
			from @tableSelect_1 sl
			left join @tableFrom_1 fr on upper(replace(sl.TableAlias,' ','')) = upper(replace(fr.TableAlias,' ',''))

			update @tableSelect_2
			set 
				--INSERT INTO [dbo].[System_SP_SelectColumns]([SPCode], [TableName], [ColumnName], [ColumnAlias], [ColumnQuery])
				--('TEST_STORE','','tempFormCompSalary  ','tempFormCompSalary  ',NULL)
				--VALUES ('GET_TAMUSERPCPT','Att_TamScanLogRegister','*','',NULL)
				QueryResult = CONCAT('(''',@SpCode,''',''',TableName,''',''',ColumnName,''',''',ColumnAlias,''',',(case when SubQuery is not null then concat('''',SubQuery,'''') else 'NULL' end),')')
		end

		-- xu ly cau inert vao table system_sp_tablelinks
		begin
			update @tableFrom_1
			set 
				--([SPCode], [TableName], [TableAlias], [Order], [JointTable], [JointTableColumn], [LinkedTableColumn], [JointType], [ExtraConditions], [CustomQuery], [IsRequired])	VALUES  
				--('GET_TAMUSERPCPT','Att_TamScanLogRegister','at',0,NULL,NULL,NULL,NULL,NULL,NULL,1)
				QueryResult = CONCAT('(''',@SpCode,''','''
					,(case when fr.TableNameConvert is not null then fr.TableNameConvert else fr.TableName end),''','''
					,fr.TableAlias,''','
					,fr.IndexJoin,','''
					,fr.LinkTable,''','''
					,fr.FieldJoin,''','''
					,fr.LinkTableField,''','''
					,fr.JoinType,''','
					,'NULL,'
					,(case when fr.SubQuery is not null then concat('''',fr.SubQuery,'''') else 'NULL' end),','
					,'NULL)')
			from @tableFrom_1 fr
		end

		SELECT * FROM @tableFrom_1
		SELECT * FROM @tableSelect_2

		print 'success'
	END TRY
	BEGIN CATCH
		SELECT  
        ERROR_NUMBER() AS ErrorNumber  
        ,ERROR_SEVERITY() AS ErrorSeverity  
        ,ERROR_STATE() AS ErrorState  
        ,ERROR_PROCEDURE() AS ErrorProcedure  
        ,ERROR_LINE() AS ErrorLine  
        ,ERROR_MESSAGE() AS ErrorMessage; 
	END CATCH
END
# ToolGenSourceKaizen USER GUIDE
# Format câu query trước khi sử dụng
## From clause:
##### Thay thế ký tự xuống dòng = \*   
  EX:  
     FROM Att_TamScanLogRegister al  
     INNER JOIN "Hre_Profile" hp ON al.ProfileID = hp.Id AND hp."IsDelete" IS NULL  
     ...  
  => Att_TamScanLogRegister al\*INNER JOIN "Hre_Profile" hp ON al.ProfileID = hp.Id AND hp."IsDelete" IS NULL\*...  
##### Nếu trong câu có Sub query dạng LEFT JOIN (SELECT FIELD1, FIELD2 FROM TABLE A WHERE ISDELETE IS NULL) ON ...  
  => Tiến hành thay thế (, ) thành $  
  EX: LEFT JOIN (SELECT FIELD1, FIELD2 FROM TABLE A WHERE ISDELETE IS NULL) ON ...  
  ==> LEFT JOIN $SELECT FIELD1, FIELD2 FROM TABLE A WHERE ISDELETE IS NULL$ ON ...  
## Select clause:  
##### Xóa bỏ ký tự Xuống dòng  
# Các case chưa hỗ trợ  
### Có extracondition cho mệnh đề from  
*Chưa tiến viết xong phần này*   ==> đã hỗ trọ case như sau  
1. nếu có nhiều điều kiện dạng ON .(1). AND .(2). AND .(3). ...  
=>  AND .(2). AND .(3). ...  sẽ tự convert thành extracondition  
2. nếu có 2 điều kiện dạng ON .(1). AND .(2).  
=> *2.1 nếu .(2). là điều kiện isdelete is null  
  *2.1.1 TH đang là câu sub query sẽ loại bỏ điều kiện này  
  *2.1.2 TH không phải trên thì thêm vào extraCondition bình thường  
3. Trường hợp có nhiều hơn 2 'AND' trong condition thì sẽ bỏ trực tiếp vào extracondition không quan tâm có phải sub query hay không  
4. *HIỆN TẠI CHỈ HỖ TRỌ CHO ĐIỀU KIỆN NỐ NHAU BẰNG CHỮ AND*

### Chưa hỗ trợ cho câu có kết kiểu OUTER APPLY  
*Hiện tại chỉ đang hỗ trợ cho kiểu INNER JOIN, LEFT JOIN, RIGHT JOIN*  
*Tool chạy bằng cơm sẽ làm bước này*  
### Hiện tại chỉ hỗ trợ cho sub query tại From dưới dạng một Table duy nhất  
EX:  
  Dạng đang hỗ trợ:  
    TableA a Join ( Select * From TableA Where...)   
  Dạng chưa hỗ trợ  
    TableA a Join ( Select * From (Select a.Id From TableA a Left Join TableB b On a.Id=b.Id) Where...)   
*Tool chạy bằng cơm sẽ làm dạng chưa hỗ trợ*  
### Với những field sử dụng trong mệnh đề Where thì chưa hỗ trợ tự động thêm vào SubQuery trong mệnh đề From  
*Tool chạy bằng cơm sẽ làm bước này*

## Cài đặt  
  1. EXECUTE file HANDLE_CONDITION.sql  
  2. EXECUTE file HANDLE_FROM_CLAUSE_SUB.sql  
  3. EXECUTE file HANDLE_FROM_CLAUSE.sql  
  4. EXECUTE file GET_COLUMN_TABLE_ALIAS.sql  
  5. EXECUTE file HANDLE_SELECT_CLAUSE_SUB.sql  
  6. EXECUTE file HANDLE_SELECT_CLAUSE.sql  
  7. EXECUTE file KAIZEN_STORE.sql  
  
## Sử Dụng
  EXEC [KAIZEN_STORE]  
	@ClauseSelect = 'Mệnh đề Select sau khi chỉnh sửa như hướng dẫn ở trên',  
	@ClauseFrom = 'Mệnh đề From sau khi chỉnh sửa như hướng dẫn ở trên',  
	@SpCode = 'Tên Store'  

#### Câu insert sinh ra sẽ có dạng như sau:  
--	System_SP_Select       [SPCode], [TableName], [ColumnName], [ColumnAlias], [ColumnQuery]  
--  System_sp_Tablelinks   [SPCode], [TableName], [TableAlias], [Order], [JointTable], [JointTableColumn], [LinkedTableColumn], [JointType], [ExtraConditions], [CustomQuery], [IsRequired]  

## Test : run test.sql

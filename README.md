# ToolGenSourceKaizen
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
## Các case chưa hỗ trợ có extracondition cho mệnh đề from  
EX: TableA a Join TableB b On a.Field1 = b.Field1 AND a.Field2 = b.Field2
##Test : run test.sql

CREATE PROCEDURE [dbo].[hrm_hr_sp_get_ContractList]
@IsNewestContract BIT = NULL,
@ProfileName NVARCHAR(100) = NULL,
@CodeEmp NVARCHAR(MAX) = NULL,
@strOrgIds VARCHAR(MAX) = NULL,
@JobTitleId UNIQUEIDENTIFIER = NULL,
@PositionID UNIQUEIDENTIFIER = NULL,
@Code NVARCHAR(100) = NULL,
@ContractNo NVARCHAR(100) = NULL,
@ContractTypeID VARCHAR(MAX) = NULL,
@dateFrom DATETIME = NULL,
@dateTo DATETIME = NULL,
@strEmpTypeID VARCHAR(MAX) = NULL,
@IDNo NVARCHAR(100) = NULL,
@Gender NVARCHAR(100) = NULL,
@status NVARCHAR(100) = NULL,
@WorkPlaceID VARCHAR(MAX) = NULL,
@PayrollGroupID VARCHAR(MAX) = NULL,
@isLastContract BIT = NULL,
@timesContract INT = NULL,
@dateEndFrom DATETIME = NULL,
@dateEndTo DATETIME = NULL,
@isProfileWorking BIT = NULL,
@dateStartFrom DATETIME = NULL,
@dateStartTo DATETIME = NULL,
@strClassRateID VARCHAR(MAX) = NULL,
@isNotSign BIT = NULL,
@isCheckFromDashBoard BIT = NULL,
@StatusSyn NVARCHAR(200) = NULL,
@strAbilitiTitleID VARCHAR(MAX) = NULL,
@isOrgEffective BIT = NULL,
@strEmpGroupID VARCHAR(MAX) = NULL,
@strIDs VARCHAR(MAX) = NULL,
@DateCreateFrom DATETIME = NULL,
@DateCreateTo DATETIME = NULL,
@TerminateDateFrom DATETIME = NULL,
@TerminateDateTo DATETIME = NULL,
@CodeEmpClient NVARCHAR(MAX) = NULL,
@strUnitStructureIDs NVARCHAR(MAX) = NULL,
@TypeContract NVARCHAR(MAX) = NULL,
@ContractStatus NVARCHAR(MAX) = NULL,
@dateHireFrom DATETIME = NULL,
@dateHireTo DATETIME = NULL,
@isCreateTemplate BIT = NULL,
@isCreateDynamicGrid BIT = NULL,
@ExportID UNIQUEIDENTIFIER = NULL,
@ExcelType NVARCHAR(100) = NULL,
@DateCreate DATETIME = NULL,
@UserCreate NVARCHAR(200) = NULL,
@isRar BIT = NULL,
@StrCompanyID VARCHAR(MAX) = NULL,
@IsShowContractWithoutKPI BIT = NULL,
@NationnalGroupIDs VARCHAR(MAX) = NULL,
@ProfileIDs VARCHAR(MAX)= NULL,
@AssessmentStatus VARCHAR(MAX)= NULL,
@IsIncludeWorkingEmp bit = null,
@IsStopWorking bit = null,
@ProvinceIDs VARCHAR(MAX)= NULL,
@CountryIDs VARCHAR(MAX)= NULL,
@StatusCancelDigiSigna NVARCHAR(200) = NULL,
@PageIndex INT = 1,
@PageSize INT = 50,
@Username NVARCHAR(50) = 'hanh.nguyen',
@fieldSort VARCHAR(50) = 'id'
AS
BEGIN
SET NOCOUNT ON;

-----------------------------------------------------
--- Prepare Data Parameter
-----------------------------------------------------

DECLARE @DefinePermission NVARCHAR(MAX)
= N''
+ N'       create table #tblPermission (id uniqueidentifier primary key ) 
INSERT INTO #tblPermission EXEC Get_Data_Permission_Contract_New @Username, ''Hre_Contract'' ';

DECLARE @DefineEnum NVARCHAR(MAX)
= N''
+ N'	     select EnumKey, EnumTranslate into #tblEnumGenderViewNew from dbo.GetEnumValueNew (''Gender'', @UserName)
select EnumKey, EnumTranslate into #tblEnumChairmanGenderView from dbo.GetEnumValueNew (''Gender'', @UserName)
select EnumKey, EnumTranslate into #tblEnumPITFormulaTypeView from dbo.GetEnumValueNew (''PITFormulaType'', @UserName)
select EnumKey, EnumTranslate into #tblEnumStatusView from dbo.GetEnumValueNew (''ContractSearchStatus'', @UserName)
select EnumKey, EnumTranslate into #tblEnumUnitTypeView from dbo.GetEnumValueNew (''UnitType'', @UserName)
select EnumKey, EnumTranslate into #tblEnumTypeContractView from dbo.GetEnumValueNew (''TypeContract'', @UserName)
select EnumKey, EnumTranslate into #tblEnumTypeOfPass from dbo.GetEnumValueNew (''TypeOfPass'', @UserName)
select EnumKey, EnumTranslate into #tblEnumStatusSynView from dbo.GetEnumValueNew (''ProfileStatusSyn'', @UserName)
select EnumKey, EnumTranslate into #tblEnumContractView from dbo.GetEnumValueNew (''ContractEvaType'', @UserName)
select EnumKey, EnumTranslate into #tblEnumStatusEvaluationView from dbo.GetEnumValueNew (''StatusEvaluation'', @UserName)
select EnumKey, EnumTranslate into #tblEnumContractStatusView from dbo.GetEnumValueNew (''ContractStatus'', @UserName)
select EnumKey, EnumTranslate into #tblEnumLaborType from dbo.GetEnumValueNew (''LaborType'', @UserName)

select EnumKey, EnumTranslate into #tblEnumWorkTimeInWeekType from dbo.GetEnumValueNew (''WorkTimeInWeekType'', @UserName)
select EnumKey, EnumTranslate into #tblEnumCalendarWorkType from dbo.GetEnumValueNew (''CalendarWorkType'', @UserName)
select EnumKey, EnumTranslate into #tblEnumWeeklyLeaveDayType from dbo.GetEnumValueNew (''WeeklyLeaveDayType'', @UserName)
select EnumKey, EnumTranslate into #tblEnumSignatureDigitalStatus from dbo.GetEnumValueNew (''SignatureDigitalStatus'', @UserName)
select EnumKey, EnumTranslate into #tblUnitType from dbo.GetEnumValueNew (''UnitType'', @UserName)
select * into #tblGradeFormCompSalary from dbo.GetEnumValueNew (''GradeFormCompSalary'', @UserName)
select * into #tblEnumStatusCancelDigitalSignature from dbo.GetEnumValueNew (''EnumStatusCancelDigitalSignature'', @UserName)


-- search phong ban theo cach nay de tang toc do search
IF(@strOrgIds IS NOT NULL)
BEGIN
select Id INTO #OrgIdFilter FROM split_to_int(ISNULL(@strOrgIds, NULL))
END

SELECT ID, Code, OrgStructureOtherName, DateUpdate INTO #OrgstructureDistince FROM Cat_OrgStructure WHERE isdelete IS NULL 
;with summaryOrg as 
(	
select *, ROW_NUMBER() over( partition by (code) order by Dateupdate desc) as sb2 from #OrgstructureDistince
)
select * INTO #tblOrgDistince from summaryOrg where sb2 =1

;WITH summaryProfileQualification AS
(
SELECT hc.ID,hc.QualificationName,hc.FieldOfTraining, hc.TrainingPlace,hc.isqualificationmain ,hc.ProfileID, ROW_NUMBER() OVER(PARTITION BY hc.ProfileID
ORDER BY hc.GraduationDate DESC) AS rk FROM Hre_ProfileQualification hc
	WHERE hc.IsDelete IS NULL and hc.isqualificationmain = 1
)
select * into #tblProfileQualification from summaryProfileQualification where rk = 1
			 
;WITH summaryContractExtend AS
(
SELECT hc.EmployeeGroupSecondDetailID, hc.EmployeeGroupFirstDetailID,hc.id, hc.isdelete,hc.ProfileSingID,hc.ContractID,hc.WorkPlaceID, hc.AbilityTileID, hc.Note2 ,hc.Note, ROW_NUMBER() OVER(PARTITION BY hc.ContractID
ORDER BY hc.DateStart DESC) AS rk FROM Hre_ContractExtend hc
	WHERE hc.IsDelete IS NULL 
)
select * into #tblContractExtend  from summaryContractExtend where rk = 1

;WITH summaryEvaluationDocument AS
(
SELECT hed.id, hed.isdelete, hed.ObjectID,hed.EvaluationType,hed.Status, ROW_NUMBER() OVER(PARTITION BY hed.ObjectID
ORDER BY hed.DateUpdate DESC) AS rk FROM Hre_EvaluationDocument hed
	WHERE hed.IsDelete IS NULL 
)
select * into #tblEvaluationDocument from summaryEvaluationDocument where rk = 1
select id, isdelete,UsualAllowanceName, IsInsurrance into #Cat_UsualAllowance from "Cat_UsualAllowance" where isdelete is null
select id, isdelete,CurrencyName, Code into #Cat_Currency from "Cat_Currency" where isdelete is null

;WITH summaryTax AS
(
SELECT st.PITCode,st."ProfileID",st.PITFormulaID,st."DateEffective",ROW_NUMBER() OVER(PARTITION BY st.ProfileID
ORDER BY st.DateEffective DESC) AS rk FROM Sal_Tax st
	WHERE st.IsDelete IS NULL 
)
select * into #tblSalTax  from summaryTax where rk = 1
';

DECLARE @PrepareVariable NVARCHAR(MAX)
= N''
-- CHARINDEX -----------
+ N' DECLARE @CodeEmpWhere NVARCHAR(max)
IF(@CodeEmp IS NOT NULL)
BEGIN
SET @CodeEmpWhere = '','' + @CodeEmp + '',''
END

DECLARE @CodeEmpClientWhere NVARCHAR(MAX)
IF(@CodeEmpClient IS NOT NULL)
BEGIN
SET @CodeEmpClientWhere = '','' + @CodeEmpClient + '',''
END
			 
DECLARE @strContractTypeIDWhere NVARCHAR(MAX)
IF(@ContractTypeID IS NOT NULL)
BEGIN
SET @strContractTypeIDWhere = '','' + @ContractTypeID + '',''
END
			 
DECLARE @WorkPlaceIDWhere NVARCHAR(MAX)
IF(@WorkPlaceID IS NOT NULL)
BEGIN
SET @WorkPlaceIDWhere = '','' + @WorkPlaceID + '',''
END

DECLARE @PayrollGroupIDWhere NVARCHAR(MAX)
IF(@PayrollGroupID IS NOT NULL)
BEGIN
SET @PayrollGroupIDWhere = '','' + @PayrollGroupID + '',''
END
			 
DECLARE @strClassRateIDWhere NVARCHAR(MAX)
IF(@strClassRateID IS NOT NULL)
BEGIN
SET @strClassRateIDWhere = '','' + @strClassRateID + '',''
END
			 
DECLARE @strEmpGroupIDWhere NVARCHAR(MAX)
IF(@strEmpGroupID IS NOT NULL)
BEGIN
SET @strEmpGroupIDWhere = '','' + @strEmpGroupID + '',''
END
			 
DECLARE @strEmpTypeIDWhere NVARCHAR(MAX)
IF(@strEmpTypeID IS NOT NULL)
BEGIN
SET @strEmpTypeIDWhere = '','' + @strEmpTypeID + '',''
END
			 
DECLARE @strAbilitiTitleIDWhere NVARCHAR(MAX)
IF(@strAbilitiTitleID IS NOT NULL)
BEGIN
SET @strAbilitiTitleIDWhere = '','' + @strAbilitiTitleID + '',''
END

DECLARE @StatusWhere VARCHAR(max)
IF(@Status IS NOT NULL)
BEGIN
SET @StatusWhere = '','' + @Status + '',''
END
			 
DECLARE @TypeContractWhere VARCHAR(max)
IF(@TypeContract IS NOT NULL)
BEGIN
SET @TypeContractWhere = '','' + @TypeContract + '',''
END
			 
DECLARE @StatusSynWhere VARCHAR(max)
IF(@StatusSyn IS NOT NULL)
BEGIN
SET @StatusSynWhere = '','' + @StatusSyn + '',''
END 
			 
DECLARE @ContractStatusWhere VARCHAR(max)
IF(@ContractStatus IS NOT NULL)
BEGIN
SET @ContractStatusWhere = '','' + @ContractStatus + '',''
END
DECLARE @GenderWhere VARCHAR(max)
IF(@Gender IS NOT NULL)
BEGIN
SET @GenderWhere = '','' + @Gender + '',''
END
DECLARE @AssessmentStatusWhere VARCHAR(max)
IF(@AssessmentStatus IS NOT NULL)
BEGIN
SET @AssessmentStatusWhere = '','' + @AssessmentStatus + '',''
END
DECLARE @StatusCancelDigiSignaWhere VARCHAR(max)
IF(@StatusCancelDigiSigna IS NOT NULL)
BEGIN
SET @StatusCancelDigiSignaWhere = '','' + @StatusCancelDigiSigna + '',''
END 


';
------------- 
IF @isLastContract = 1
BEGIN
SET @PrepareVariable
= @PrepareVariable
+ N' CREATE TABLE #TEMP (id uniqueidentifier primary key)
		INSERT INTO #TEMP SELECT t.id
		from hre_contract t
		join ( 
			select ProfileID, max(datestart) datestart -- son.vo - 20160818 - 0072444
			from hre_contract where isdelete is null
			group by ProfileID 
		) i
		on i.ProfileID = t.ProfileID and i.datestart = t.datestart and t.isdelete is null';
END;

IF @IsNewestContract = 1
BEGIN--
SET @PrepareVariable
= @PrepareVariable
+ N'	;WITH summaryContractExtend2 AS
(
SELECT hc.ContractID,hc.DateStart, ROW_NUMBER() OVER(PARTITION BY hc.ContractID
ORDER BY hc.DateStart DESC) AS rk FROM Hre_ContractExtend hc
WHERE hc.IsDelete IS NULL and hc.Status=''E_APPROVED''
)
select * into #tblContractExtend2 from summaryContractExtend2 where rk = 1

;WITH summaryContract AS
(
SELECT hc.ID,hc.ProfileID,TerminateDate,DateStart, ROW_NUMBER() OVER(PARTITION BY hc.ProfileID
ORDER BY hc.DateStart DESC) AS rk FROM Hre_Contract hc
WHERE hc.IsDelete IS NULL and hc.Status=''E_APPROVED'' 
)
select * into #tblContract from summaryContract hw where rk = 1  and TerminateDate is null 

select distinct(hct.ID) into #TEMP2  from #tblContract hct
left join #tblContractExtend2 hce on hce.ContractID = hct.ID
outer apply(
select top (1) ID from Hre_WorkHistory hw1 where hw1.ProfileID = hct.ProfileID and hw1.Status= ''E_APPROVED''
and hw1.DateEffective = hce.DateStart and hw1.IsDelete is null 
order by hw1.DateEffective
) WorkHistoryExtend
outer apply(
select top (1) ID from Hre_WorkHistory hw1 where hw1.ProfileID = hct.ProfileID and hw1.Status= ''E_APPROVED''
and hw1.DateEffective = hct.DateStart and hw1.IsDelete is null 
order by hw1.DateEffective
) WorkHistoryContract
where ((hce.ContractID is null and WorkHistoryContract.ID is null) or (hce.ContractID is not null and WorkHistoryExtend.ID is null))
';
END;

-----------------------------------------------------
--- From Clause
-----------------------------------------------------

DECLARE @ClauseFrom NVARCHAR(MAX)
= N'' + N' FROM Hre_Contract hct WITH (INDEX(IDX_HRE_CONTRACT))' + CHAR(10)
+ N'	JOIN Hre_Profile hp WITH (NOLOCK) ON hct."ProfileID" = hp.id
left JOIN (select id, isdelete, AbilityTitleVNI,AbilityTitleEng from "Cat_AbilityTile") catat  ON hct."AbilityTileID" = catat.id AND catat."IsDelete" IS NULL
left JOIN Cat_OrgStructure co  ON hct."OrgStructureID" = co.id AND co."IsDelete" IS NULL
JOIN Cat_ContractType cc  ON hct."ContractTypeID" = cc.id AND cc."IsDelete" IS NULL
--LEFT JOIN (select id, isdelete, ProvinceName, ProvinceNameEN, CountryID from "Cat_Province") cap1 ON cap1.ProvinceName = hp.IDPlaceOfIssue AND cap1."IsDelete" IS NULL
LEFT JOIN Cat_IDCardIssuePlace cai ON cai.IDCardIssuePlaceName = hp.IDCardPlaceOfIssue AND cai."IsDelete" IS NULL
LEFT JOIN Cat_PassportIssuePlace capp ON capp.PassportIssuePlaceName = hp.PassportPlaceOfIssue  AND capp."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, ObjectID,EvaluationType,Status  from #tblEvaluationDocument) hed ON hed.ObjectID = hct.ID AND hed."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, WorkPlaceName, [Address], [Description], Code, ProvinceID from "Cat_WorkPlace" ) cwp ON cwp.id = hct."WorkPlaceID" AND cwp."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, ProvinceName, CountryID from "Cat_Province") cpow on cpow.ID = cwp.ProvinceID AND cpow."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, CountryName from "Cat_Country") ctow on ctow.ID = cpow.CountryID and ctow."IsDelete" IS NULL
left join (select id, isdelete,ProfileID, UserInfoName from Sys_UserInfo) sui   ON hct."UserApproveIDEva" = sui.id AND sui."IsDelete" IS NULL
left join (select id, isdelete,ProfileID, UserInfoName from Sys_UserInfo) sui2  ON hct."UserApproveIDEva2" = sui2.id AND sui2."IsDelete" IS NULL
left join (select id, isdelete,ProfileID, UserInfoName from Sys_UserInfo) sui3  ON hct."UserApproveIDEva3" = sui3.id AND sui3."IsDelete" IS NULL
left join (select id, isdelete,ProfileID, UserInfoName from Sys_UserInfo) sui4  ON hct."UserApproveIDEva4" = sui4.id AND sui4."IsDelete" IS NULL
OUTER APPLY (
	SELECT	TOP(1) doc.DeclineReason
	FROM	Hre_EvaluationDocument doc
	WHERE	IsDelete IS NULL 
			AND doc.ObjectID = hct.ID
			and doc.EvaluationType =''E_EvaluateExpiredContract''
	ORDER BY doc.DateCreate DESC
	) doc
JOIN #tblPermission fcP ON fcP.Id = hct.id ' + CHAR(10);

-----------------------------------------------------
--- Where Clause
-----------------------------------------------------

DECLARE @ClauseWhere NVARCHAR(MAX) = N' WHERE ' + CHAR(10) + N' hct.IsDelete IS NULL
AND ((hp.StatusSyn <> ''E_WAITING_APPROVE'' and hp.StatusSyn <> ''E_WAITING'') OR hp.StatusSyn IS NULL)
';

IF @isLastContract = 1
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND hct.id in (SELECT id FROM #TEMP) ';

IF @IsNewestContract = 1
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND hct.id in (SELECT id FROM #TEMP2) ';

IF @strOrgIds IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (co.OrderNumber in (select Id FROM #OrgIdFilter)) ';

IF @ProfileName IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10) + N' AND (lower(hp.ProfileName) like ''%'' + lower(@ProfileName) + ''%'') ';

IF @CodeEmp IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10)
+ N' and (hp.CodeEmp like ''%'' + @CodeEmp+ ''%'' OR CHARINDEX('','' + hp.CodeEmp + '','', @CodeEmpWhere) > 0) ';

IF @PositionID IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.PositionID = @PositionId) ';

IF @JobTitleId IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.JobTitleID = @JobTitleId) ';

IF @Status IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10) + N' AND (CHARINDEX('','' + hct."status" + '','', @StatusWhere) > 0) ';

IF @Gender IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10) + N' AND (CHARINDEX('','' + hp."Gender" + '','', @GenderWhere) > 0) ';

IF @DateCreateFrom IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10) + N' AND (convert(varchar(10), hct.DateCreate, 120) >= @DateCreateFrom) ';

IF @DateCreateTo IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10) + N' AND (convert(varchar(10), hct.DateCreate, 120) <= @DateCreateTo) ';

IF @Code IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.Code like ''%'' + @Code+ ''%'') ';

IF @IDNo IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND ((hp."IDNo" like ''%'' + @IDNo + ''%'') or (hct."E_IDNo" is not null and dbo.VnrDecrypt(hct.E_IDNo) like ''%'' + @IDNo + ''%'')) ';

IF @ContractNo IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.ContractNo like ''%'' + @ContractNo + ''%'') ';

IF @ContractTypeID IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10)
+ N' AND (CHARINDEX('','' + CAST(hct.ContractTypeID as VARCHAR(100)) + '','', @strContractTypeIDWhere) > 0) ';

IF @strClassRateID IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10)
+ N' AND (CHARINDEX('','' + CAST(hct.ClassRateID as VARCHAR(100)) + '','', @strClassRateIDWhere) > 0) ';

IF @WorkPlaceID IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10)
+ N' AND (CHARINDEX('','' + CAST(hct."WorkPlaceID" as VARCHAR(100)) + '','', @WorkPlaceIDWhere) > 0) ';

IF @strEmpGroupID IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10)
+ N' AND (CHARINDEX('','' + CAST(hct.EmployeeGroupID as VARCHAR(100)) + '','', @strEmpGroupIDWhere) > 0) ';

IF @strEmpTypeID IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10)
+ N' AND (CHARINDEX('','' + CAST(hct.EmployeeTypeID as VARCHAR(100)) + '','', @strEmpTypeIDWhere) > 0) ';

IF @strAbilitiTitleID IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10)
+ N' AND (CHARINDEX('','' + CAST(hct.AbilityTileID as VARCHAR(100)) + '','', @strAbilitiTitleIDWhere) > 0) ';

IF @dateFrom IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.DateSigned >= @dateFrom) ';

IF @dateTo IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.DateSigned <= @dateTo) ';

IF @timesContract IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct."TimesContract"= @timesContract) ';

IF @dateStartFrom IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.datestart >= @dateStartFrom) ';

IF @dateStartTo IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.datestart <= @dateStartTo) ';

IF @dateEndFrom IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.dateend >= @dateEndFrom) ';
IF @dateEndTo IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.dateend <= @dateEndTo) ';

IF @DateCreateFrom IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.datecreate >= @DateCreateFrom) ';

IF @DateCreateTo IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.datecreate <= @DateCreateTo) ';

IF @UserCreate IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.UserCreate = @UserCreate) ';

IF @isCheckFromDashBoard = 1
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.NoPrint is null or hct.NoPrint = 0) ';

IF @isNotSign = 1
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.NoPrint is null or hct.NoPrint = 0) ';

IF @StatusSyn IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10) + N' AND (CHARINDEX('','' + hp.StatusSyn + '','', @StatusSynWhere) > 0) ';

IF @isOrgEffective = 1
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct."OrgStructureID" = hp."OrgStructureID") ';

IF @TerminateDateFrom IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.TerminateDate >= @TerminateDateFrom) ';

IF @TerminateDateTo IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.TerminateDate <= @TerminateDateTo) ';

IF @CodeEmpClient IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10)
+ N' AND (hp.CodeEmpClient like ''%'' + @CodeEmpClient+ ''%'' OR CHARINDEX('','' + hp.CodeEmpClient + '','', @CodeEmpClientWhere) > 0) ';

IF @ContractStatus IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10)
+ N' AND (CHARINDEX('','' + hct.ContractStatus + '','', @ContractStatusWhere) > 0) ';

IF @TypeContract IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10) + N' AND (CHARINDEX('','' + cc."Type" + '','', @TypeContractWhere) > 0) ';

IF @strUnitStructureIDs IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10)
+ N' AND (hct.UnitStructureID in (SELECT orgId FROM GetOrgTableIds(@strUnitStructureIDs))) ';

IF @dateHireFrom IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hp.DateHire >= @dateHireFrom) ';

IF @dateHireTo IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hp.DateHire <= @dateHireTo) ';

IF @StrCompanyID IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10) + N' AND (hct.CompanyID in (SELECT orgId FROM GetOrgTableIds(@StrCompanyID))) ';

IF @PayrollGroupID IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10) + N' AND (hct.PayrollGroupID in (SELECT orgId FROM GetOrgTableIds(@PayrollGroupID))) ';

IF @IsShowContractWithoutKPI = 1
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND (hct.PerformanceID is null) ';


IF @ProfileIDs IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10) + N' AND (hp.ID in (SELECT orgId FROM GetOrgTableIds(@ProfileIDs))) ';

IF @NationnalGroupIDs IS NOT NULL
SET @ClauseWhere = @ClauseWhere + CHAR(10)
+ N' AND (hp.NationalityGroupID in (SELECT orgId FROM GetOrgTableIds(@NationnalGroupIDs))) '
IF @AssessmentStatus IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10)
+ N' AND hed.EvaluationType = ''E_EvaluateExpiredContract'' AND (CHARINDEX('','' + hed.Status + '','', @AssessmentStatusWhere) > 0) ';

if @IsIncludeWorkingEmp = 1 
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND hp.DateQuit is null or (hp.DateQuit is not null and hp.DateQuit > GETDATE()) ';

if @IsStopWorking = 1 
SET @ClauseWhere = @ClauseWhere + CHAR(10) + N' AND hp.StatusSyn <> ''E_HIRE'' and (hp.DateQuit is not null and hp.DateQuit <= GETDATE()) ';

IF @ProvinceIDs IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10) + N' AND (cpow.ID in (SELECT orgID FROM GetOrgTableIds(@ProvinceIDs)))';

IF @StatusCancelDigiSigna IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(20)
+ N' AND (CHARINDEX('','' + hct.StatusCancelDigitalSignature + '','', @StatusCancelDigiSignaWhere) > 0) ';

 print(@ClauseWhere)
IF @CountryIDs IS NOT NULL
SET @ClauseWhere
= @ClauseWhere + CHAR(10) + N' AND (ctow.ID in (SELECT orgID FROM GetOrgTableIds(@CountryIDs)))';
-----------------------------------------------------
--- Select Clause
-----------------------------------------------------
---DEFINE 
DECLARE @DefineQuery VARCHAR(MAX)
= N''
+ N'
-- lay du lieu dem so luong nhan vien ra ngoai
 

CASE WHEN LEN(cast(hp.DayOfBirth AS NVARCHAR(10)))=1 THEN ''0''+ cast(hp.DayOfBirth AS NVARCHAR(10))
ELSE 
cast(hp.DayOfBirth AS NVARCHAR(10))
END + ''/'' + CASE 
WHEN LEN(cast(hp.MonthOfBirth AS NVARCHAR(10)))=1 THEN ''0''+cast(hp.MonthOfBirth AS NVARCHAR(10))
ELSE
cast(hp.MonthOfBirth AS NVARCHAR(10))
End + ''/'' + cast(hp.YearOfBirth AS NVARCHAR(10)) as DOfBirth,
CONVERT(varchar(10),Day(getdate())) AS "DateSign",
CONVERT(varchar(10),month(getdate())) AS MonthSign,
CONVERT(varchar(10),year(getdate())) AS YearSign,
';
DECLARE @ClauseSelect NVARCHAR(MAX)
= N'' + N' SELECT 
' + @DefineQuery + N'
@TotalRow as TotalRow ' 
+ N',
--BeginDynamic--
	 caex.CurrencyName AS CurrencyExtraIncomeName,
	 caad.CurrencyName AS CurrentcyAdvanceSalaryName,
	 cacs.CurrencyName AS CurrencyContractSalaryName,
cnea.NameEntityName as DigitalSignatureCodeName,
(SELECT STUFF((SELECT '','' + cne.EnumTranslate from #tblGradeFormCompSalary cne
WHERE cne.EnumKey in (
(select ID FROM SPLIT_To_VARCHAR(hct.tempFormCompSalary))
)
FOR XML PATH('''')), 1, 1, '''') AS [Output]) as FormCompSalaryView,
hct.tempFormCompSalary,
hct.JobLevel,
hct.LevelAgencyID,
hct.CooperationRate,
hct.FileAttachmentSal,
hct.ExtraIncome,
hct.AdvanceSalary,
hct.ContractSalary,
hct.E_ExtraIncome,
hct.E_AdvanceSalary,
hct.E_ContractSalary,
hct.ReEvaluatateRemark,
doc.DeclineReason AS ReasonRefusalApplication,
hpreject.ProfileName as UserRejectName,
hpcancel.ProfileName as UserCancelName,
ccnew."ContractTypeName" as NewNextContractTypeName,
unitnew.EnumTranslate AS "UnitTimeNextContractTypeName",
slary.SalaryClassName as SalaryClassNameTL,
cct.ContractTypeName as ContractTypeNameNext,
cne4.NameEntityName as TermsOfContractName,
cawt.WorkPlaceName as WorkPlaceTranslateName,
exPro.ProfileName as ExProfileSingName,
exPro.NameEnglish as ExProfileSingNameEN,
exPos.PositionName as ExPositionSingName,
exPos.PositionEngName as ExPositionSingNameEN, 
exwl.WorkPlaceName as ExWorkPlaceTranslateName,
cat2.AbilityTitleVNI as ExAbilityTitleVNI,
cat2.AbilityTitleEng as ExAbilityTitleEng,
cp2.ProvinceName as ProfilePProvinceName,
cp2.ProvinceNameEN as ProfilePProvinceNameEN,
cd2.DistrictName as ProfilePDistrictName,
cd2.DistrictNameEN as ProfilePDistrictNameEN,
cv2.VillageName as ProfileVillageName,
cv2.VillageNameEN as ProfileVillageNameEN,

----
Conttype.Code as ContractTypeCodeView,
cpg.PayrollGroupName as PayrollGroupName,
cpg.Code as PayrollGroupCode,
(select count(ID) as ContractCount from Hre_Contract hct WITH (NOLOCK)
where hct."ProfileID" = hct.ProfileID and hct."IsDelete" is null) as ContractCount,
(select count(ID) as RewardCount from Hre_Reward hr WITH (NOLOCK)
where hct."ProfileID" = hr.ProfileID and hr."IsDelete" is null And (hr.DateOfEffective between hct.DateStart and hct.DateEnd or ((hr.DateOfEffective >= hct.DateStart and hct.DateEnd is null)))) RewardCount,
(select count(ID) as CountDiscipline from Hre_Discipline hd WITH (NOLOCK)
where hct."ProfileID" = hd.ProfileID and hd."IsDelete" is null And (hd.DateOfEffective between hct.DateStart and hct.DateEnd or ((hd.DateOfEffective >= hct.DateStart and hct.DateEnd is null)))) CountDiscipline,
cne.OtherName as AnotherNameofAcademicLevel,
ccp."CompanyName",
ccp."CompanyNameEN",
ccp."AddressVN" as "AddressVN_Company", 
ccp."AddressEN" as "AddressEN_Company",
ccp."Phone",
ccp."Image",
ccp."Image" as"CompanyLogo",
ccp.ShortName,
ccp."ChairmanNameVN",
ccp."ChairmanNameEN",
ccp."ChairmanNationalityVN",
ccp."ChairmanNationalityEN",
ccp."ChairmanJobtitileVN",
ccp."ChairmanJobtitleEN",
ccp."ChairmanPositionVN",
ccp."ChairmanPositionEN",
ccp."ChairmanGender",
ccp."ProfileNameSing",
ccp.Code as "Code_Company",
cgv.EnumTranslate as "ChairmanGenderView",
ccp."DateOfBirthSing",
ccp."PlaceOfBirthSing",
ccp."PositionNameSing",
ccp."JobTitleNameSing",
ccp."IDNoSing",
ccp."IDDateOfIssueSing",
ccp."IDPlaceOfIssueSing",
ccp."PAddressSing",
Temp.PITCode,
ptv.EnumTranslate as "PITCodeView",
cou.E_COMPANY,
cou.E_BRANCH,
cou.E_UNIT,
cou.E_DIVISION,
cou.E_DEPARTMENT,
cou.E_TEAM,
cou.E_SECTION,
cou.E_OU_L8,
cou.E_OU_L9,
cou.E_OU_L10,
cou.E_OU_L11,
cou.E_OU_L12,
cou.E_COMPANY_CODE,
cou.E_BRANCH_CODE,
cou.E_UNIT_CODE,
cou.E_DIVISION_CODE,
cou.E_DEPARTMENT_CODE,
cou.E_TEAM_CODE,
cou.E_SECTION_CODE,
cou.E_OU_L8_CODE,
cou.E_OU_L9_CODE,
cou.E_OU_L10_CODE,
cou.E_OU_L11_CODE,
cou.E_OU_L12_CODE,
cou.OrgParent1,
cou.OrgParent2,
cou.OrgParentCode1,
cou.OrgParentCode2,
cou.OrgParentEN1,
cou.OrgParentEN2,
cou.E_COMPANY_E,
cou.E_BRANCH_E,
cou.E_UNIT_E,
cou.E_DIVISION_E,
cou.E_DEPARTMENT_E,
cou.E_TEAM_E ,
cou.E_SECTION_E, 
	case
when contractPos.PositionName is not null and cou.E_DIVISION is not null  then  contractPos.PositionName + '' - '' + cou.E_DIVISION 
when contractPos.PositionName is null and cou.E_DIVISION is null  then  csc1."SalaryClassName" + '' - '' + cou.E_DEPARTMENT
when contractPos.PositionName is null and cou.E_DIVISION is not null then csc1."SalaryClassName" + '' - '' + cou.E_DIVISION
when contractPos.PositionName is not null and cou.E_DIVISION is null then contractPos.PositionName + '' - '' + cou.E_DEPARTMENT
end as PositionOrgStructure,
crio."RegionName",
cc1."CurrencyName" as "CurrencySalName",
cc2."CurrencyName" AS "CurenncyInsName",
cc3."CurrencyName" AS "CurenncyAllowance1Name",
cc4."CurrencyName" AS "CurenncyAllowance2Name",
cc5."CurrencyName" AS "CurenncyAllowance3Name",
cc6."CurrencyName" AS "CurenncyOAllowanceName",
cc7."CurrencyName" AS "CurenncyAllowance4Name",


sv.EnumTranslate as "StatusView",
hp1.ProfileName AS ProfileSingName,
hp1.NameEnglish AS ProfileSingNameEN,
hp1."DateOfBirth" as "ProfileSingDateOfBirth",
hp1."IDNo" as "ProfileSingIDNo",
hp1."IDPlaceOfIssue" as "ProfileSingIDPlaceOfIssue",
hp1."IDDateOfIssue" as "ProfileSingIDDateOfIssue",
hp1."PAddress" as "ProfileSingPAddress",
hp1."Gender" AS "ProfileSignGender",
cq."QualificationName",
cq."QualificationName" as "QualificationNameContract",
cq.Code as "QualificationCodeContract",
csc1."SalaryClassName" as "ClassRateName",
csc1."SalaryClassName",
csct1."SalaryClassTypeName",
csr1."SalaryRankName" AS "RankRateName",
csr1.Rate as "RankRateIDRate",
csr1.SalaryMin, 
csr1.SalaryMax,
csr1.code as PayRankCode,
cua1."UsualAllowanceName" AS "AllowanceID1Name",
cua2."UsualAllowanceName" AS "AllowanceID2Name",
cua3."UsualAllowanceName" AS "AllowanceID3Name",
cua4."UsualAllowanceName" AS "AllowanceID4Name",
cua5."UsualAllowanceName" AS "AllowanceID5Name",
cua6."UsualAllowanceName" AS "AllowanceID6Name",
cua7."UsualAllowanceName" AS "AllowanceID7Name",
cua8."UsualAllowanceName" AS "AllowanceID8Name",
cua9."UsualAllowanceName" AS "AllowanceID9Name",
cua10."UsualAllowanceName" AS "AllowanceID10Name",
cua11."UsualAllowanceName" AS "AllowanceID11Name",
cua12."UsualAllowanceName" AS "AllowanceID12Name",
cua13."UsualAllowanceName" AS "AllowanceID13Name",
cua14."UsualAllowanceName" AS "AllowanceID14Name",
cua15."UsualAllowanceName" AS "AllowanceID15Name",

hce.Note2 As ContractExtendNote2,hce.Note As ContractExtendNote,

cua1.IsInsurrance as "IsInsurranceAllowance1",
cua2.IsInsurrance as "IsInsurranceAllowance2",
cua3.IsInsurrance as "IsInsurranceAllowance3",
cua4.IsInsurrance as "IsInsurranceAllowance4",
cua5.IsInsurrance as "IsInsurranceAllowance5",
cua6.IsInsurrance as "IsInsurranceAllowance6",
cua7.IsInsurrance as "IsInsurranceAllowance7",
cua8.IsInsurrance as "IsInsurranceAllowance8",
cua9.IsInsurrance as "IsInsurranceAllowance9",
cua10.IsInsurrance as "IsInsurranceAllowance10",
cua11.IsInsurrance as "IsInsurranceAllowance11",
cua12.IsInsurrance as "IsInsurranceAllowance12",
cua13.IsInsurrance as "IsInsurranceAllowance13",
cua14.IsInsurrance as "IsInsurranceAllowance14",
cua15.IsInsurrance as "IsInsurranceAllowance15",
cne3."NameEntityName" AS "VehicleName",
cne2.NameEntityName as "CostSourceName",		 
cne1.NameEntityName AS "GraduatedLevelName",
cne."NameEntityName" AS "EducationLevelName",
cne10.NameEntityName AS "NationalityGroup",
cwp."WorkPlaceName",
cwp.[Address] as "AddressWorkPlace",
cwp.[Description] as "DescriptionWorkPlace",
EmployeeGroup.NameEntityName as "EmployeeGroupName",		 
cne5.NameEntityName as "ReasonChangeSalaryName",
cne6.NameEntityName as "ReasonChangeSalaryName2",
cne7.NameEntityName as "DelegationReasonName",
cne50.NameEntityName as "DelegationReasonName2",
cet.EmployeeTypeName,
cpf.PITFormulaName,
ccy."CountryName" AS "NationalityName",
ccy."CountryNameES" as "NationalityNameEn",
ccy1.CountryName as "TCountryName",
ccy2.CountryName as "PCountryName",
cp1.ProvinceName as "TProvinceName",
cp2.ProvinceName as "PProvinceName",
cd1.DistrictName as "TDistrictName",
cd2.DistrictName as "PDistrictName",
cv1.VillageName as "TVillageName",
cv2.VillageName as "PVillageName",
co1.OrgStructureName as OrgStructureParent,
co1.OrgStructureName as "ParentIDOrgStructureName",		 
coio.Info1,
coio.Info2,
coio.Info3,
coio.Info4,
coio.Info5,
coio.Info6,
coio.Info7,
coio.Info8,
coio.Info9,
coio.Info10,
coio.Info11,
coio.Info12,
coio.Info13,
coio.Info14,
cj1."Jobtitlename" as "ProfileSingJobtitlename",
cj1."JobtitlenameEn" as "ProfileSingJobtitlenameEN",
cp11.Positionname as "PositionProfileSign",
cp11.PositionEngName AS "PositionEngNameProfileSign",
ccty."CountryName" AS "ProfileSingNationalityName",
ccty."CountryNameES" AS "ProfileSingNationalityNameEN",
cpprosing.ProvinceName as ProfileSingPProvinceName,
cdprosing.DistrictName as ProfileSingPDistrictName,
cvprosing.VillageName as ProfileSingPVillageName, 
cmibranch.BillingAddress as "BranchBillingAddress",
cmibranch.TelePhone as "BranchTelePhone",
orgCompany.BillingAddress,
orgCompany.TelePhone as "TelePhoneOrg", 
Delegate.NoDecision as "DelegateCompanyNoDecision",
DelegatePro.ProfileName as "DelegateCompanyProfileName",
DelegatePro.IDNo as "DelegateCompanyIDNo",
DelegatePro.IDDateOfIssue as "DelegateCompanyIDDateOfIssue",
DelegatePro.IDPlaceOfIssue as "DelegateCompanyIDPlaceOfIssue",
DelegatePos.PositionName as "DelegateCompanyPositionName",
hp2."ProfileName" AS "Supervisor",
hp2."ProfileName" AS "SupervisorName", 
highSup.profilename as "HighSupervisorName",
crr.ResignReasonName,
cga.GradeAttendanceName,
cga.Code as GradeAttendanceCode,
performanceTemplate.TemplateName,
egv.EnumTranslate as "GenderView",
utv.EnumTranslate as "UnitTimeView",
tcv.EnumTranslate as "TypeView",
tcv.EnumTranslate as "TypeContractType",
ssv.EnumTranslate as "StatusSynView",
csv.EnumTranslate AS "ContractStatusView",
sev.EnumTranslate AS "StatusEvaluationView",
contractJob.JobTitleName,
contractJob.Code as JobTitleCode,
ccc1.CostCentreName,
cw1.WorkPlaceName,
contractJob.JobTitleNameEn,
contractPos.PositionName,
contractPos.Code AS "PositionCode",
contractPos.NumberOfChangeJobDescription,
contractPos."EffectiveDateOfDescription",
cwp.Code as WorkPlaceCode,		 
cust.UnitName,
cust.UnitCode,
lt.EnumTranslate as LaborTypeView,
EnumWorkTimeInWeekType.EnumTranslate as WorkTimeInWeekView,
EnumCalendarWorkType.EnumTranslate as CalendarWorkView,
EnumWeeklyLeaveDayType.EnumTranslate as WeeklyLeaveDayView,
contractpos.PositionEngName,
cpt.PositionOtherName,
cpt.Requirement as PositionRequirement,
cpt.Permission as PositionPermission,
cpt.TaskShortTerm as PositionTaskShortTerm,
cpt.TaskLongTerm as PositionTaskLongTerm, 
hpmi.LastNameEN,
hpmi.FirstNameEN,
hpmi.MiddleNameEN,
contractJob."Notes" as "NotesJobTitle",
cn.NameEntityName as DistributionChannelName,
cn1.NameEntityName as MarketDomainName,
cn2.NameEntityName as RegionMarketName,
cn3.NameEntityName as MarketAreaName,
cn4.NameEntityName as OriginalDistributorName,
curkpi.CurrencyName as CurrencyKPIName,
kpirank.KPIRankName,
hpmiProvince.ProvinceName as ProvinceBirthName,
hpmiDistrict.DistrictName as DistrictBirthName,
hpmiVillage.VillageName as VillageBirthName,
cuap.UsualAllowanceGroupName,
scv.EnumTranslate as ContractEvaType,
tofp.EnumTranslate as ''TypeOfPassView'',
SignatureDigitalStatus.EnumTranslate as ''StatusEmailSignatureDigitalView'',
curtotal.currencyname as TotalSalaryCurrencyName,
curtotal2.currencyname as TotalAllowanceCurrencyName,
		 
contractTCountry.countryName as ContractTCountryName,
contractTProvince.ProvinceName as ContractTProvinceName,
contractTDistrict.DistrictName as ContractTDistrictName,
contractTVillage.VillageName as ContractTAVillageName,
ccp.Note as CompanyNote,
E_COMPANYOther.OrgStructureOtherName as E_COMPANYOrgStructureOtherName,
E_BRANCHOther.OrgStructureOtherName as E_BRANCHOrgStructureOtherName,
E_UNITOther.OrgStructureOtherName as E_UNITOrgStructureOtherName,
E_DIVISIONOther.OrgStructureOtherName as E_DIVISIONOrgStructureOtherName,
E_DEPARTMENTOther.OrgStructureOtherName as E_DEPARTMENTOrgStructureOtherName,
E_TEAMOther.OrgStructureOtherName as E_TEAMOrgStructureOtherName,
E_SECTIONOther.OrgStructureOtherName as E_SECTIONOrgStructureOtherName,
proqua.QualificationName as QualificationNameMain,
proqua.TrainingPlace as TrainingPlaceMain,
proqua.FieldOfTraining as FieldOfTrainingMain,
ttProSal.CurrencyName AS TotalProbationaryCurrencyName,
dbo.fcDocsothanhchu(hct.TotalProbationarySalary)  as TotalProbationarySalaryFormat,
dbo.fcDocsothanhchu_EN(hct.TotalProbationarySalary)  as TotalProbationarySalaryFormatEN,
dbo.fcDocsothanhchu(hct.TotalSalary)  as TotalSalaryFormat,
dbo.fcDocsothanhchu_EN(hct.TotalSalary)  as TotalSalaryFormatEN,
--cap1.ProvinceNameEN as IDPlaceOfIssueNameEng,
cai.IDCardIssuePlaceEngName as IDCardPlaceOfIssueNameEng,
capp.PassportIssuePlaceEngName as PassportPlaceOfIssueNameEng,
cc.ValueTime,
cc.UnitTime,
cc.Type,
sui.UserInfoName as UserApproveIDEvaName,
sui2.UserInfoName as UserApproveIDEva2Name,
sui3.UserInfoName as UserApproveIDEva3Name,
sui4.UserInfoName as UserApproveIDEva4Name,
hct.DateEndProbation as ContractDateEndProbation,
hp.StatusSyn,
hct.DecisionNo,
hct.VNSalary,
hct.TermsOfContractID,
hct.VNENSalary,
hct.JapanSalary,
hct.JapanVNSalary,
hct.TextLink,
hct.ContractEvaType,
hct.TypeOfPass,
hct.GradeAttendanceID,
hct."WorkPlaceID",
hct."PayrollGroupID",
hct.ID,
hct.E_IDNo,
hct.E_PassportNo,
hct.DateStartProbation,
hct.DateEndProbation,
hct.ProbationTimeUnit,
hct.ProbationTime,
utv3.EnumTranslate as ProbationTimeUnitName,
hct.NewNextContractTypeID,
hct.DateStartNextContractType,
hct.DateEndNextContractType,
hct.DurationNextContractType,
hct.UnitTimeNextContractType,
hp.E_IDCard as E_ProfileIDCard,
hct.Note,
hct.Code,
hct.Status,
hct.ContractTypeID,
hct."ContractNo",
hct."DateSigned",
hct."DateStart",
hct."DateEnd",
hct."JobTitleID",
hct.DateOfContractEva,
hct.EvaluationResult,
hct.ContractResult,
hct.Behaviour,
hct.Competence,
hct.DateStartNextContract,
hct."DateEndNextContract",
hct."NextContractTypeID",
hct."Remark",
hct."RankDetailForNextContract",
hct."PositionID",
hct."ProfileID",
hct.EmployeeGroupID,
hct."DateCreate",
hct."DateUpdate",
hct."IPCreate",
hct.StatusEvaluation,
hct."IPUpdate",
hct."FollowNo",
hct."ProfileSingID",
hct."PersonalRate",
hct."FormPaySalary",
hct."QualificationID",
hct."HourWorkInMonth",
hct."DateAuthorize",
hct."ClassRateID",
hct."RankRateID",
hct."SalaryClassTypeID",
hct."DateExtend",
hct.Duration,
	hct.Duration as DurationContract,
hct."CurenncyID", 
hct."CurenncyID1", 
hct."CurenncyID2",
hct."CurenncyID3", 
hct."CurenncyIDSalary", 
hct."CurenncyID5", 
hct."CurenncyID4",


hct."AllowanceID1",
hct."AllowanceID2",
hct.ContractStatus,
hct."AllowanceID3",
hct."AllowanceID4",
hct."AllowanceID5",
hct."AllowanceID6",
hct."AllowanceID7",
hct."AllowanceID8",
hct."AllowanceID9",
hct."AllowanceID10",
hct."AllowanceID11",
hct."AllowanceID12",
hct."AllowanceID13",
hct."AllowanceID14",
hct."AllowanceID15",

hct.NoPrint,
hct.Salary,
hct.NextSalary,
hct.NextInsuranceAmount,
hct."InsuranceAmount",
hct."Allowance1",
hct."Allowance2",
hct."Allowance3",
hct."Allowance4",
hct."Allowance",
hct.Allowance5,
hct.Allowance6,
hct.Allowance7,
hct.Allowance8,
hct.Allowance9,
hct.Allowance10,
hct.Allowance11,
hct.Allowance12,
hct.Allowance13,
hct.Allowance14,
hct.Allowance15, 

hct.E_Salary,
hct.E_NextSalary,
hct.E_NextInsuranceAmount,
hct.E_InsuranceAmount,
hct.E_Allowance,
hct.E_Allowance1,
hct.E_Allowance2,
hct.E_Allowance3,
hct.E_Allowance4,
hct.E_Allowance5,
hct.E_Allowance6,
hct.E_Allowance7,
hct.E_Allowance8,
hct.E_Allowance9,
hct.E_Allowance10,
hct.E_Allowance11,
hct.E_Allowance12,
hct.E_Allowance13,
hct.E_Allowance14,
hct.E_Allowance15,

hct.UserCreate,		
hct.IsNotSignContinue,
hct.TerminateDate,		
hct.CompanyID,
hct.ReasonChangeSalaryID,
hct.ReasonChangeSalaryID2,
hct.DelegationReasonID,
hct.DelegationReasonID2,
hct."TimesContract",
hct.EmployeeTypeID,
hct."AbilityTileID",
hct.DelegateCompanyID,
hct.OrgStructureID,
hct.EvaPerformanceTemplateID,
hct.WorkMorningTimeStart,
hct.WorkMorningTimeEnd,
hct.WorkAfternoonTimeStart,
hct.WorkAfternoonTimeEnd,
hct.AttachFile as Attachment,
cc.ContractTypeName, 
cc.Code AS "ContractTypeCode",
cc.Description AS "ContractTypeDescription",
cc.ExportID,
cc.Description, 
co.OrgStructureName,
co."AddressDetail",
co."Code" AS "OrgStructureCode",
co.OrgStructureOtherName,
co.OrgStructureNameEN,
co.OrgFullName,
catat.AbilityTitleVNI,
catat.AbilityTitleEng,
hp.CostSourceID,
hp.RegionID,
hp.EducationLevelID,
hp."CodeEmpClient",
hp.DatehireNew,		 
hp.DateApplyAttendanceCode,
hp."OrgStructureID" as ProfileOrgStructureID,
hp.Gender,
hp.GraduatedLevelID,
hp.CodeEmp, 
hp.ProfileName, 
hp.PlaceOfBirth,
hp.IDPlaceOfIssue,
hp.IDDateOfIssue,
hp."DateOfBirth",
hp.IDNo,
hp.PAddress,
hp.DateHire,
hp.DateEndProbation as ProfileDateEndProbation,
hp.DateOfEffect,
hp.NameEnglish,
hp."PassportDateOfIssue",
hp."PassportDateOfExpiry",
hp.SocialInsNo,
hp.PlaceOfBirth as ProfilePlaceOfBirth,
dbo.fChuyenCoDauThanhKhongDau(hp.PAddress) as ProfilePAddressEN,
hp.SocialInsIssuePlace,
hp.SocialInsIssueDate,
hp.CodeTax,
hp.Permission,
hp.TaskShortTerm,
hp.TaskLongTerm,
hp.SikillLevel,
hp.AddressSecondaryEmergency,
hp.idcard as ProfileIDCard,
hp.IDCardDateOfIssue as ProfileIDCardDateOfIssue,
hp.IDCardPlaceOfIssue as ProfileIDCardPlaceOfIssue,
hp."Email",
hp."MonthOfBirth",
hp."YearOfBirth",
hp."Cellphone",
hp.DateQuit,
hp.PAddress as "ProfilePAddress",
hp.IDNo as "ProfileIDNo",
hp.IDDateOfIssue as "ProfileIDDateOfIssue",
hp.IDPlaceOfIssue as "ProfileIDPlaceOfIssue",
hp."SupervisorID",
hp."HighSupervisorID",
hp.ResReasonID,
hp."NationalityID",
hp.PCountryID,
hp.PProvinceID,
hp.PDistrictID,
hp.VillageID,
hp."VehicleID",
co.ParentID,
co.ID as CoID,
hp.DayOfBirth,
hp.EthnicID,
hp.UnitStructureID,
hct.DayOfAnnualLeave,
hct.ProbationSalary,
hct.E_ProbationSalary,
hct.LaborType,
hp.ProbationTime as ProfileProbationTime,
hp.ProfileMoreInfoID,
hct.DistributionChannelID,
hct.MarketDomainID,
hct.RegionMarketID,
hct.MarketAreaID,
hct.OriginalDistributorID,
hct.OtherDistributors,
hct.KPIRankID,
hct.CurrencyKPIID,
hct.KPIAmount,
hct.E_KPIAmount,
hct.SalaryPaidByTheFormOf,
hct.CoefficientOfWorkmanship,
hct.UsualAllowanceGroupID,
hp.DateSenior,
hp.SalaryClassID,
case
when hct.PerformanceID is not null then CAST(1 AS BIT)
else CAST(0 AS BIT)
end as IsHasKPISetEmbedded,
hct.TotalSalaryCurrencyID,
hct.TotalAllowanceCurrencyID,
hct.PassportPlaceOfIssue,
hct.PassportNo as ContractPassportNo,
hct.PassportPlaceOfIssue as ContractPassportPlaceOfIssue,
hct.PassportNo,
hct.TAddress, 
hct.TAddressEN, 
hct.PAddressEN, 
hct.TAddress as ContractTAddress, 
hct.TCountryID,
hct.TProvinceID,
hct.TDistrictID,
hct.TAVillageID,
hct.WorkTimeInWeek,
hct.CalendarWork,
hct.WeeklyLeaveDay,
(case when ISNULL(CAST(dbo.VnrDecrypt(hct.E_TotalSalary) as float),null) = 0 then null else ISNULL(CAST(dbo.VnrDecrypt(hct.E_TotalSalary) as float),null ) end) as TotalSalary,
(case when ISNULL(CAST(dbo.VnrDecrypt(hct.E_TotalAllowance) as float),null) = 0 then null else ISNULL(CAST(dbo.VnrDecrypt(hct.E_TotalAllowance) as float),null ) end) as TotalAllowance,
hct.E_TotalSalary,
hct.E_TotalAllowance,
hct.E_TotalProbationarySalary,
hct.TotalProbationSalCurrencyID,
hct.StatusEmailSignatureDigital,
(case when ISNULL(CAST(dbo.VnrDecrypt(hct.E_TotalProbationarySalary) as float),null) = 0 then null else ISNULL(CAST(dbo.VnrDecrypt(hct.E_TotalProbationarySalary) as float),null ) end) as TotalProbationarySalary,
cpow.ProvinceName as ProvinceOfWork,
ctow.CountryName as CountryOfWork,
hct.ReasonReject,
hct.UserRejectID,
hct.DateReject,
hct.CancelReason,
hct.DateCancel,
hct.UserCancelID,
hct.BenefitLevel,
contractPosParent.PositionName as HeadPositionName,
cegsd2.EmpGroupSecondDetailName,
cegfd1.EmpGroupFirstDetailName,
cegsd4.EmpGroupSecondDetailName as EmpGroupSecondDetailNameContractExtand,
cegfd3.EmpGroupFirstDetailName as EmpGroupFirstDetailNameContractExtand,
cpPlaceOfIssue.ProvinceName AS PlaceOfIssueIDView,
cpIDCardIssuePlace.IDCardIssuePlaceName AS IDCardIssuePlaceIDView,
cpPassportPlace.PassportIssuePlaceName AS PassportPlaceIDView,
hct.StatusCancelDigitalSignature,
hct.ReasonCancel,
hct.PersonCancellationID,
PersonCancellation.ProfileName as "PersonCancellationName",
statusCancelDigitalSignature.EnumTranslate as "StatusCancelDigitalSignatureView",
cal.LevelAgencyName,
(COALESCE(hct.TAddress + '', '','''') 
+ COALESCE(cv1.VillageName + '', '','''')
+ COALESCE(cd1.DistrictName + '', '','''')
+ COALESCE(cp1.ProvinceName + '', '','''')
+ COALESCE(ccy1.CountryName + '''','''')) as FullTAddress,
(COALESCE(hct.PAddress + '', '','''') 
+ COALESCE(cv22.VillageName + '', '','''')
+ COALESCE(cd2.DistrictName + '', '','''')
+ COALESCE(cp2.ProvinceName + '', '','''')
+ COALESCE(ccy2.CountryName + '''','''')) as FullPAddress,

(COALESCE(hct.TAddressEN + '', '','''') 
+ COALESCE(cv1.VillageName + '', '','''')
+ COALESCE(cd1.DistrictName + '', '','''')
+ COALESCE(cp1.ProvinceName + '', '','''')
+ COALESCE(ccy1.CountryName + '''','''')) as FullTAddressEN,
(COALESCE(hct.PAddressEN + '', '','''') 
+ COALESCE(cv22.VillageName + '', '','''')
+ COALESCE(cd2.DistrictName + '', '','''')
+ COALESCE(cp2.ProvinceName + '', '','''')
+ COALESCE(ccy2.CountryName + '''','''')) as FullPAddressEN,


hct.DigitalSignatureCodeID,
cn5.NameEntityName as CostSourceIDName

' + @ClauseFrom +'
LEFT JOIN (SELECT id, IsDelete, LevelAgencyName FROM Cat_LevelAgency) cal ON cal.id = hct.LevelAgencyID AND cal."IsDelete" IS NULL
 LEFT JOIN (select id, isdelete,CurrencyName from "Cat_Currency") caex ON caex.id = hct.CurrencyExtraIncomeID AND caex."IsDelete" IS NULL
  LEFT JOIN (select id, isdelete,CurrencyName from "Cat_Currency") caad ON caad.id = hct.CurrentcyAdvanceSalaryID AND caad."IsDelete" IS NULL
  LEFT JOIN (select id, isdelete,CurrencyName from "Cat_Currency") cacs ON cacs.id = hct.CurrencyContractSalaryID AND cacs."IsDelete" IS NULL

LEFT JOIN (select id, isdelete,ContractTypeName from Cat_ContractType ) ccnew ON hct."NewNextContractTypeID" = ccnew.id AND ccnew."IsDelete" IS NULL
LEFT JOIN #tblUnitType unitnew ON unitnew.EnumKey = hct."UnitTimeNextContractType"
LEFT JOIN #Cat_Currency ttProSal ON ttProSal.id = hct.TotalProbationSalCurrencyID AND ttProSal."IsDelete" IS NULL
LEFT JOIN (select ID, IsDelete, Code FROM Cat_ContractType ) Conttype ON Conttype.ID = hct.ContractTypeID AND Conttype.IsDelete IS NULL
LEFT JOIN Cat_Company ccp ON ccp.id = hct."CompanyID" AND ccp."IsDelete" IS NULL		 
--lay thông tin lương "Sal_Tax" gần nhất theo ngày hiệu lực
LEFT JOIN #tblSalTax "Temp" ON hct."ProfileID" = "Temp"."ProfileID"
LEFT JOIN (select id, isdelete,PITFormulaName from Cat_PITFormula ) cpf on cpf.Id="Temp".PITFormulaID AND cpf."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, NameEntityName, Code from "Cat_NameEntity") cne4 ON cne4.id = hct.TermsOfContractID AND cne4."IsDelete" IS NULL
LEFT JOIN #Cat_Currency cc1 ON cc1.id = hct."CurenncyID" AND cc1."IsDelete" IS NULL
LEFT JOIN #Cat_Currency cc2 ON cc2.id = hct."CurenncyID1" AND cc2."IsDelete" IS NULL
LEFT JOIN #Cat_Currency cc3 ON cc3.id = hct."CurenncyID2" AND cc3."IsDelete" IS NULL
LEFT JOIN #Cat_Currency cc4 ON cc4.id = hct."CurenncyID3" AND cc4."IsDelete" IS NULL
LEFT JOIN #Cat_Currency cc5 ON cc5.id = hct."CurenncyIDSalary" AND cc5."IsDelete" IS NULL
LEFT JOIN #Cat_Currency cc6 ON cc6.id = hct."CurenncyID5" AND cc6."IsDelete" IS NULL
LEFT JOIN #Cat_Currency cc7 ON cc7.id = hct."CurenncyID4" AND cc7."IsDelete" IS NULL

left join (select E_COMPANY, E_BRANCH, E_UNIT, E_DIVISION, E_DEPARTMENT, E_TEAM, E_SECTION, E_OU_L8, E_OU_L9, E_OU_L10,
E_OU_L11, E_OU_L12, E_COMPANY_CODE, E_BRANCH_CODE, E_UNIT_CODE, E_DIVISION_CODE, E_DEPARTMENT_CODE, E_TEAM_CODE, E_SECTION_CODE, E_OU_L8_CODE,
E_OU_L9_CODE, E_OU_L10_CODE, E_OU_L11_CODE, E_OU_L12_CODE,OrgstructureID, IsDelete,
OrgParent1,OrgParent2,OrgParentCode1,OrgParentCode2,OrgParentEN1,OrgParentEN2, E_COMPANY_E, E_BRANCH_E, E_UNIT_E, E_DIVISION_E, E_DEPARTMENT_E,
E_TEAM_E , E_SECTION_E from Cat_OrgUnit ) cou ON hct.OrgstructureID = cou.OrgstructureID AND cou."IsDelete" IS NULL
left join #tblOrgDistince E_COMPANYOther on E_COMPANYOther.Code = cou.E_COMPANY_CODE
left join #tblOrgDistince E_BRANCHOther on E_BRANCHOther.Code = cou.E_BRANCH_CODE
left join #tblOrgDistince E_UNITOther on E_UNITOther.Code = cou.E_UNIT_CODE
left join #tblOrgDistince E_DIVISIONOther on E_DIVISIONOther.Code = cou.E_DIVISION_CODE
left join #tblOrgDistince E_DEPARTMENTOther on E_DEPARTMENTOther.Code = cou.E_DEPARTMENT_CODE
left join #tblOrgDistince E_TEAMOther on E_TEAMOther.Code = cou.E_TEAM_CODE
left join #tblOrgDistince E_SECTIONOther on E_SECTIONOther.Code = cou.E_SECTION_CODE
--thong tin nguoi ky
LEFT JOIN (select id, isdelete, ProfileName,JobTitleID,PositionID,NationalityID, NameEnglish,"DateOfBirth","IDNo","IDPlaceOfIssue",
"IDDateOfIssue",PAddress, YearOfBirth, gender,PprovinceID,PdistrictID,TAVillageID,VillageID, TAddress 
from "Hre_Profile" WITH (NOLOCK)) hp1 ON hp1.id = hct."ProfileSingID" AND hp1."IsDelete" IS NULL
LEFT JOIN (select id, isdelete,QualificationName, Code from "Cat_Qualification" ) cq ON cq.id = hct."QualificationID" AND cq."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, SalaryClassName from "Cat_SalaryClass" ) csc1 ON csc1.id = hct."ClassRateID" AND csc1."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, SalaryClassTypeName from "Cat_SalaryClassType" ) csct1 ON csct1.id = hct."SalaryClassTypeID" AND csct1."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, SalaryRankName, SalaryMin, SalaryMax, Rate, code from "Cat_SalaryRank") csr1 ON csr1.id = hct."RankRateID" AND csr1."IsDelete" IS NULL
LEFT JOIN #Cat_UsualAllowance cua1 ON cua1.id = hct."AllowanceID1" AND cua1."IsDelete" IS NULL
LEFT JOIN #Cat_UsualAllowance cua2 ON cua2.id = hct."AllowanceID2" AND cua2."IsDelete" IS NULL
LEFT JOIN #Cat_UsualAllowance cua3 ON cua3.id = hct."AllowanceID3" AND cua3."IsDelete" IS NULL
LEFT JOIN #Cat_UsualAllowance cua4 ON cua4.id = hct."AllowanceID4" AND cua4."IsDelete" IS NULL
LEFT JOIN #Cat_UsualAllowance cua5 ON cua5.id = hct."AllowanceID5" AND cua5."IsDelete" IS NULL
LEFT JOIN #Cat_UsualAllowance cua6 ON cua6.id = hct."AllowanceID6" AND cua6."IsDelete" IS NULL
LEFT JOIN #Cat_UsualAllowance cua7 ON cua7.id = hct."AllowanceID7" AND cua7."IsDelete" IS NULL
LEFT JOIN #Cat_UsualAllowance cua8 ON cua8.id = hct."AllowanceID8" AND cua8."IsDelete" IS NULL
LEFT JOIN #Cat_UsualAllowance cua9 ON cua9.id = hct."AllowanceID9" AND cua9."IsDelete" IS NULL
LEFT JOIN #Cat_UsualAllowance cua10 ON cua10.id = hct."AllowanceID10" AND cua10."IsDelete" IS NULL
LEFT JOIN #Cat_UsualAllowance cua11 ON cua11.id = hct."AllowanceID11" AND cua11."IsDelete" IS NULL
LEFT JOIN #Cat_UsualAllowance cua12 ON cua12.id = hct."AllowanceID12" AND cua12."IsDelete" IS NULL
LEFT JOIN #Cat_UsualAllowance cua13 ON cua13.id = hct."AllowanceID13" AND cua13."IsDelete" IS NULL
LEFT JOIN #Cat_UsualAllowance cua14 ON cua14.id = hct."AllowanceID14" AND cua14."IsDelete" IS NULL
LEFT JOIN #Cat_UsualAllowance cua15 ON cua15.id = hct."AllowanceID15" AND cua15."IsDelete" IS NULL

LEFT JOIN (select NameEntityName, id, IsDelete, OtherName from "Cat_NameEntity" ) cne ON cne.id=hp."EducationLevelID" AND cne."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, NameEntityName from "Cat_NameEntity" ) cne1 on cne1.ID=hp.GraduatedLevelID AND cne1."IsDelete" IS NULL
LEFT JOIN (select NameEntityName, id, IsDelete from "Cat_NameEntity" ) cne2 ON cne2.id = hp."CostSourceID" AND cne2."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, NameEntityName from "Cat_NameEntity" ) cne3 ON cne3.id = hp."VehicleID" AND cne3."IsDelete" IS NULL		
LEFT JOIN (select id, isdelete, PayrollGroupName, Code from "Cat_PayrollGroup" ) cpg ON cpg.id = hct."PayrollGroupID" AND cpg."IsDelete" IS NULL
LEFT JOIN (select RegionName, id, IsDelete from "Cat_Region" ) crio on hp.RegionID = crio.ID AND crio."IsDelete" IS NULL
LEFT JOIN (select NameEntityName, id, IsDelete from "Cat_NameEntity" ) EmployeeGroup ON EmployeeGroup.id = hct.EmployeeGroupID and EmployeeGroup."IsDelete" IS NULL		
LEFT JOIN (select id, isdelete, NameEntityName from "Cat_NameEntity" ) cne5 ON cne5.id = hct.ReasonChangeSalaryID AND cne5."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, NameEntityName from "Cat_NameEntity" ) cne6 ON cne6.id = hct.ReasonChangeSalaryID2 AND cne6."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, NameEntityName from "Cat_NameEntity" ) cne7 ON cne7.id = hct.DelegationReasonID AND cne7."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, NameEntityName from "Cat_NameEntity") cne50  ON cne50.id = hct.DelegationReasonID2 AND cne50."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, EmployeeTypeName from Cat_EmployeeType ) cet ON cet.id = hct.EmployeeTypeID AND cet."IsDelete" IS NULL
left join (select id, isdelete, ProfileName from "Hre_Profile" WITH (NOLOCK)) hp2 on hp2.ID = hp."SupervisorID" and hp2."IsDelete" IS NULL
left join (select id, isdelete, ProfileName from "Hre_Profile" WITH (NOLOCK)) highSup on highSup.ID = hp."highSupervisorID" and highSup."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, ResignReasonName from Cat_ResignReason ) crr ON hp.ResReasonID=crr.ID AND crr."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, CountryName, "CountryNameES" from "Cat_Country" ) ccy ON hp."NationalityID" = ccy.id AND ccy."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, CountryName, "CountryNameES" from "Cat_Country" ) ccy1 on ccy1.ID = hct.TCountryID AND ccy1."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, CountryName, "CountryNameES" from "Cat_Country" ) ccy2 on ccy2.ID = hct.PCountryID AND ccy2."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, ProvinceName from "Cat_Province") cp1 on cp1.ID = hct.TProvinceID AND cp1."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, DistrictName from "Cat_District" ) cd1 on cd1.ID = hct.TDistrictID AND cd1."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, VillageName from "Cat_Village" ) cv1 on cv1.ID = hct.TAVillageID AND cv1."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, OrgStructureName, code, OrderNumber from "Cat_OrgStructure" ) co1 ON co.ParentID = co1.id AND co1."IsDelete" IS NULL		 
left join (select id, isdelete, orgstructureid ,Info1,Info2,Info3,Info4,Info5,Info6,Info7,Info8,Info9,Info10,Info11,Info12,Info13,
Info14 from Cat_OtherInfoOrg ) coio on coio.orgstructureid = co.ID and coio.isdelete is null
LEFT JOIN (select id, isdelete, JobTitleName, "JobtitleNameEn" from "Cat_JobTitle" ) cj1 ON hp1.JobTitleID = cj1.id AND cj1."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, PositionName, PositionEngName from "Cat_Position" ) cp11 ON hp1.PositionID = cp11.id AND cp11."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, CountryName, "CountryNameES" from "Cat_Country" ) ccty ON hp1.NationalityID = ccty.ID AND ccty."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, ProvinceName from "Cat_Province" ) cpprosing on cpprosing.ID = hp1.PprovinceID AND cpprosing."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, DistrictName from "Cat_District" ) cdprosing on cdprosing.ID = hp1.PdistrictID AND cdprosing."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, VillageName from "Cat_Village" ) cvprosing on cvprosing.ID = hp1.VillageID AND cvprosing."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, "BillingAddress",TelePhone,OrgStructureID from Cat_OrgMoreInfor ) cmibranch 
on cmibranch.OrgStructureID = (dbo.GETNEARESTPARENTID (hct.OrgStructureID,''E_BRANCH'')) AND cmibranch."IsDelete" IS NULL 
LEFT JOIN (select id, isdelete, "BillingAddress",TelePhone, OrgStructureID from Cat_OrgMoreInfor ) orgCompany 
on orgCompany.OrgStructureID = (dbo.GETNEARESTPARENTID (hct.OrgStructureID,''E_COMPANY'')) AND orgCompany."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, CompanyID, ProfileID, NoDecision from Cat_DelegateCompany ) Delegate 
ON Delegate.id = hct.DelegateCompanyID AND Delegate."IsDelete" IS NULL
left join (select id, isdelete, profileName, IDno, idplaceofissue, iddateofissue, positionid from hre_profile WITH (NOLOCK)) DelegatePro 
on DelegatePro.id = Delegate.ProfileID and DelegatePro.isdelete is null
LEFT JOIN (select id, isdelete, PositionName from "Cat_Position" ) DelegatePos ON DelegatePro.PositionID = DelegatePos.id 
AND DelegatePos."IsDelete" IS NULL		
LEFT JOIN (select id, isdelete, GradeAttendanceName, Code from Cat_GradeAttendance ) cga on cga.ID = hct.GradeAttendanceID AND cga.IsDelete is null
LEFT JOIN (select id, isdelete, TemplateName from eva_performanceTemplate WITH (NOLOCK)) performanceTemplate on performanceTemplate.id = hct.EvaPerformanceTemplateID and performanceTemplate.isdelete is null
LEFT JOIN (select id, isdelete, JobTitleName,Notes,JobTitleNameEn,Code from Cat_JobTitle ) contractJob on contractJob.id = hct.JobTitleID and contractJob.isdelete is null
LEFT JOIN (select id, isdelete, CostCentreName from Cat_CostCentre ) ccc1 on ccc1.id = hct.CostCentreID and ccc1.isdelete is null
LEFT JOIN (select id, isdelete, WorkPlaceName from Cat_WorkPlace ) cw1 on cw1.id = hct.WorkPlaceID  and cw1.isdelete is null
LEFT JOIN(select id, isdelete, PositionName, Code, PositionEngName, NumberOfChangeJobDescription,"EffectiveDateOfDescription",ParentPositionID from Cat_Position ) contractPos on contractPos.id = hct.PositionID and contractPos.isdelete is null		
LEFT JOIN(select id, isdelete, PositionName from Cat_Position ) contractPosParent on contractPosParent.id = contractPos.ParentPositionID and contractPosParent.isdelete is null		
LEFT JOIN (select id, isdelete, UnitName, UnitCode from Cat_UnitStructure ) cust on cust.id = hct.UnitStructureID AND cust.IsDelete Is NULL 
LEFT JOIN (select id,NationalityGroupID, isdelete, ProfileName,PositionID from "Hre_Profile" WITH (NOLOCK)) hpl ON hpl.id = hct.ProfileID AND hpl."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, PositionOtherName, Requirement,Permission,TaskLongTerm,TaskShortTerm from "Cat_Position") cpt ON hpl.PositionID = cpt.id AND cpt."IsDelete" IS NULL
LEFT JOIN "Hre_ProfileMoreInfo" hpmi ON hpmi.id=hp.ProfileMoreInfoID AND hpmi."IsDelete" IS NULL
left join (select id, isdelete, NameEntityName from "Cat_NameEntity") cne10 on cne10.ID = hpl.NationalityGroupID and cne10."IsDelete" IS NULL 
LEFT JOIN #Cat_Currency curkpi ON curkpi.id = hct.CurrencyKPIID AND curkpi."IsDelete" IS NULL
LEFT JOIN (select id, isdelete,KPIRankName from cat_kpirank) kpirank ON kpirank.id = hct.kpirankID AND kpirank."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, NameEntityName from "Cat_NameEntity") cn ON cn.id = hct."DistributionChannelID"AND cn."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, NameEntityName from "Cat_NameEntity") cn1 ON cn1.id = hct."MarketDomainID" AND cn1."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, NameEntityName from "Cat_NameEntity") cn2 ON cn2.id = hct."RegionMarketID" AND cn2."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, NameEntityName from "Cat_NameEntity") cn3 ON cn3.id = hct."MarketAreaID" AND cn3."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, NameEntityName from "Cat_NameEntity") cn4 ON cn4.id = hct."OriginalDistributorID" AND cn4."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, ProvinceName from dbo.Cat_Province) hpmiProvince ON hpmiProvince.id = hpmi.ProvinceBirthCertificateID AND hpmiProvince."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, DistrictName from dbo.Cat_District) hpmiDistrict ON hpmiDistrict.id = hpmi.DistrictBirthCertificateID AND hpmiDistrict."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, VillageName from dbo.Cat_Village) hpmiVillage ON hpmiVillage.id = hpmi.VillageBirthCertificateID AND hpmiVillage."IsDelete" IS NULL
LEFT JOIN (select UsualAllowanceGroupName, id, IsDelete from "Cat_UsualAllowanceGroup") cuap ON cuap.id = hct.UsualAllowanceGroupID AND cuap."IsDelete" IS NULL
LEFT JOIN #Cat_Currency curtotal ON curtotal.id = hct.TotalSalaryCurrencyID AND curtotal."IsDelete" IS NULL

LEFT JOIN #Cat_Currency curtotal2 ON curtotal2.id = hct.TotalAllowanceCurrencyID AND curtotal2."IsDelete" IS NULL
-- get enum
Left JOIN #tblEnumChairmanGenderView cgv ON cgv.EnumKey = ccp."ChairmanGender"
Left JOIN #tblEnumPITFormulaTypeView ptv ON ptv.EnumKey = "Temp".PITCode
Left JOIN #tblEnumStatusView sv ON sv.EnumKey = hct."Status"
Left JOIN #tblEnumContractView scv ON scv.EnumKey = hct.ContractEvaType
Left JOIN #tblEnumTypeOfPass tofp ON tofp.EnumKey = hct.TypeOfPass
Left JOIN #tblEnumUnitTypeView utv ON utv.EnumKey = hct.UnitTime
Left JOIN #tblEnumUnitTypeView utv3 ON utv3.EnumKey = hct.ProbationTimeUnit
Left JOIN #tblEnumTypeContractView tcv ON tcv.EnumKey = cc.Type
Left JOIN #tblEnumGenderViewNew egv ON egv.EnumKey = hp."Gender"
Left JOIN #tblEnumStatusSynView ssv ON ssv.EnumKey = hp.StatusSyn
LEFT JOIN #tblEnumContractStatusView csv ON csv.EnumKey = hct."ContractStatus"
left join #tblEnumStatusEvaluationView sev ON sev.EnumKey = hct."StatusEvaluation"
LEFT JOIN #tblEnumWorkTimeInWeekType EnumWorkTimeInWeekType ON EnumWorkTimeInWeekType.EnumKey = hct."WorkTimeInWeek"
LEFT JOIN #tblEnumCalendarWorkType EnumCalendarWorkType ON EnumCalendarWorkType.EnumKey = hct."CalendarWork"
LEFT JOIN #tblEnumWeeklyLeaveDayType EnumWeeklyLeaveDayType ON EnumWeeklyLeaveDayType.EnumKey = hct."WeeklyLeaveDay"
LEFT JOIN #tblEnumSignatureDigitalStatus SignatureDigitalStatus ON SignatureDigitalStatus.EnumKey = hct."StatusEmailSignatureDigital"
Left JOIN #tblEnumLaborType lt ON lt.EnumKey = hct.LaborType
LEFT JOIN (select id, isdelete, CountryName from "Cat_Country") contractTCountry ON contractTCountry.ID = hct.TCountryID AND contractTCountry."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, ProvinceName from "Cat_Province") contractTProvince ON contractTProvince.ID = hct.TProvinceID AND contractTProvince."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, DistrictName from "Cat_District") contractTDistrict ON contractTDistrict.ID = hct.TDistrictID AND contractTDistrict."IsDelete" IS NULL 
LEFT JOIN (select id, isdelete, VillageName from "Cat_Village") contractTVillage ON contractTVillage.ID = hct.TAVillageID AND contractTVillage."IsDelete" IS NULL
 
LEFT JOIN (select id, isdelete, OriginID,WorkPlaceName  from "Cat_WorkPlace_Translate") cawt ON cawt.OriginID = hct.WorkPlaceID AND cawt."IsDelete" IS NULL
LEFT JOIN (select id, isdelete,ProfileSingID,ContractID,WorkPlaceID, AbilityTileID, Note2 ,Note, EmployeeGroupSecondDetailID, EmployeeGroupFirstDetailID from #tblContractExtend) hce ON hce.ContractID = hct.ID AND hce."IsDelete" IS NULL
LEFT JOIN (select id, isdelete,ProfileName,NameEnglish,PositionID from Hre_Profile) exPro ON exPro.ID = hce.ProfileSingID AND exPro."IsDelete" IS NULL
LEFT JOIN (select id, isdelete,PositionName,PositionEngName  from Cat_Position) exPos ON exPos.ID = exPro.PositionID AND exPos."IsDelete" IS NULL
LEFT JOIN (select id, isdelete,WorkPlaceName, OriginID  from "Cat_WorkPlace_Translate") exwl ON exwl.OriginID = hce.WorkPlaceID AND exwl."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, AbilityTitleVNI,AbilityTitleEng from Cat_AbilityTile) cat2 ON cat2.id = hce."AbilityTileID" AND cat2."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, ProvinceName, ProvinceNameEN from "Cat_Province") cp2 on cp2.ID = hct.PProvinceID AND cp2."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, DistrictName, DistrictNameEN from "Cat_District") cd2 on cd2.ID = hct.PDistrictID AND cd2."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, VillageName,VillageNameEN from "Cat_Village") cv2 on cv2.ID = hp.VillageID AND cv2."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, OriginID,SalaryClassName  from "Cat_SalaryClass_Translate") slary ON slary.OriginID = hp.SalaryClassID AND slary."IsDelete" IS NULL
LEFT JOIN (select id, isdelete,ProfileID from Sys_UserInfo) ssreject ON ssreject.id = hct.UserRejectID AND ssreject."IsDelete" IS NULL
LEFT JOIN (select id, isdelete,ProfileName from Hre_Profile) hpreject ON hpreject.id = ssreject.ProfileID AND hpreject."IsDelete" IS NULL
LEFT JOIN (select id, isdelete,ProfileID from Sys_UserInfo) sscancel ON sscancel.id = hct.UserCancelID AND sscancel."IsDelete" IS NULL
LEFT JOIN (select id, isdelete,ProfileName from Hre_Profile) hpcancel ON hpcancel.id = sscancel.ProfileID AND hpcancel."IsDelete" IS NULL
left join (select id, isdelete,ContractTypeName from Cat_ContractType) cct  ON hct."NextContractTypeID" = cct.id AND cct."IsDelete" IS NULL
left join Cat_EmpGroupSecondDetail cegsd2  ON hct."EmployeeGroupSecondDetailID" = cegsd2.id AND cegsd2."IsDelete" IS NULL
left join Cat_EmpGroupFirstDetail cegfd1  ON hct."EmployeeGroupFirstDetailID" = cegfd1.id AND cegfd1."IsDelete" IS NULL
LEFT JOIN Cat_Province cpPlaceOfIssue ON cpPlaceOfIssue.id = hct.PlaceOfIssueID AND cpPlaceOfIssue."IsDelete" IS NULL
LEFT JOIN Cat_IDCardIssuePlace cpIDCardIssuePlace ON cpIDCardIssuePlace.id = hct.IDCardIssuePlaceID AND cpIDCardIssuePlace."IsDelete" IS NULL
LEFT JOIN Cat_PassportIssuePlace cpPassportPlace ON cpPassportPlace.id = hct.PassportPlaceID AND cpPassportPlace."IsDelete" IS NULL
left join Cat_EmpGroupSecondDetail cegsd4  ON hce."EmployeeGroupSecondDetailID" = cegsd4.id AND cegsd4."IsDelete" IS NULL
left join Cat_EmpGroupFirstDetail cegfd3  ON hce."EmployeeGroupFirstDetailID" = cegfd3.id AND cegfd3."IsDelete" IS NULL
LEFT JOIN (select id, isdelete,ProfileName from Hre_Profile) PersonCancellation ON PersonCancellation.id = hct.PersonCancellationID AND PersonCancellation."IsDelete" IS NULL
LEFT JOIN #tblEnumStatusCancelDigitalSignature statusCancelDigitalSignature ON statusCancelDigitalSignature.EnumKey = hct."StatusCancelDigitalSignature"
left join #tblProfileQualification proqua on proqua.ProfileID = hct.ProfileID
LEFT JOIN (select id, isdelete, VillageName,VillageNameEN from "Cat_Village") cv22 on cv22.ID = hct.PVillageID AND cv22."IsDelete" IS NULL
LEFT JOIN Cat_NameEntity cnea ON cnea.id = hct.DigitalSignatureCodeID AND cnea."IsDelete" IS NULL
LEFT JOIN (select id, isdelete, NameEntityName from "Cat_NameEntity" where IsDelete  IS NULL ) cn5  ON cn5.id = hct."CostSourceID"
'+ @ClauseWhere
+ N' 

order by hct.DateUpdate DESC
OFFSET ((@PageIndex - 1) * (@PageSize)) ROWS FETCH NEXT @PageSize ROWS ONLY 
-- drop temp table
drop table #tblPermission
drop table #tblEnumGenderViewNew
drop table #tblEnumChairmanGenderView
drop table #tblEnumTypeOfPass
drop table #tblEnumPITFormulaTypeView
drop table #tblEnumContractView
drop table #tblEnumUnitTypeView
drop table #tblEnumTypeContractView
drop table #tblEnumStatusSynView
drop table #tblEnumStatusEvaluationView
drop table #tblEnumStatusView
drop table #tblEnumContractStatusView
drop table #tblProfileQualification
drop table #tblContractExtend
drop table #tblEnumLaborType
drop table #tblEnumWorkTimeInWeekType
drop table #tblEnumCalendarWorkType
drop table #tblEnumWeeklyLeaveDayType
drop table  #tblEnumSignatureDigitalStatus
drop table #tblUnitType
drop table #OrgstructureDistince
drop table #tblOrgDistince
drop table #tblEvaluationDocument
IF(@IsNewestContract IS NOT NULL)
BEGIN
drop table #tblContractExtend2
drop table #tblContract
drop table #TEMP2
END
IF(@strOrgIds IS NOT NULL)
BEGIN
drop table #OrgIdFilter
END
drop table #tblSalTax
';

IF @isLastContract = 1
SET @ClauseSelect = @ClauseSelect + N' DROP TABLE #TEMP ';
-----------------------------------------------------
--- SQL Execute Query
-----------------------------------------------------

DECLARE @ParamDefinition NVARCHAR(MAX)
= N''
+ N' @IsNewestContract bit = NULL,
@ProfileName nvarchar(100) = null,
@CodeEmp nvarchar(max) = NULL,
@strOrgIds varchar(max)= NULL,
@JobTitleId UNIQUEIDENTIFIER = NULL,
@PositionID UNIQUEIDENTIFIER = NULL, 
@Code nvarchar(100) = NULL,
@ContractNo nvarchar(100) = NULL,
@ContractTypeID varchar(max) = NULL,
@dateFrom datetime = NULL,
@dateTo datetime = NULL,
@strEmpTypeID varchar(max)= NULL,
@IDNo nvarchar(100) = NULL ,
@Gender NVARCHAR(100) = NULL ,
@status NVARCHAR(100) = NULL ,
@WorkPlaceID varchar(max) = NULL,
@PayrollGroupID varchar(max) = NULL,
@isLastContract bit = NULL,
@timesContract int = NULL,
@dateEndFrom datetime = NULL,
@dateEndTo datetime = NULL,
@isProfileWorking bit = NULL,
@dateStartFrom datetime = NULL,
@dateStartTo datetime = NULL,
@strClassRateID varchar(max) = NULL,
@isNotSign bit = null,
@isCheckFromDashBoard bit = NULL,
@StatusSyn nvarchar(200) = NULL,
@strAbilitiTitleID varchar(max)=null,
@isOrgEffective bit = null,
@strEmpGroupID varchar(max) = NULL,
@strIDs varchar(max) = NULL,
@DateCreateFrom datetime = NULL,
@DateCreateTo datetime = NULL,
@TerminateDateFrom datetime = null,
@TerminateDateTo datetime = null,
@CodeEmpClient NVARCHAR(max) = NULL,
@strUnitStructureIDs nvarchar (max) = NULL,
@TypeContract NVARCHAR(max) = NULL,
@ContractStatus NVARCHAR(max) = NULL,
@dateHireFrom datetime = NULL,
@dateHireTo datetime = NULL,
@isCreateTemplate bit = NULL,
@isCreateDynamicGrid bit = NULL,
@ExportID uniqueidentifier = NULL,
@ExcelType NVARCHAR(100) = NULL, 
@DateCreate datetime = NULL,
@UserCreate nvarchar(200)=null,
@isRar bit = NULL,
@StrCompanyID varchar(max)= NULL,
@IsShowContractWithoutKPI BIT = NULL,
@NationnalGroupIDs VARCHAR(MAX) = NULL,
@ProfileIDs VARCHAR(MAX) = NULL,
@AssessmentStatus VARCHAR(MAX)= NULL,
@IsIncludeWorkingEmp bit = null,
@IsStopWorking bit = null,
@ProvinceIDs VARCHAR(MAX) = NULL,
@CountryIDs VARCHAR(MAX) = NULL,
@StatusCancelDigiSigna NVARCHAR(200) = NULL,
@PageIndex int = 1,
@PageSize int = 50,
@Username nvarchar(50),
@fieldSort varchar(50) ';

DECLARE @PrepareQuery NVARCHAR(MAX)
= N'' + @DefinePermission + CHAR(10) + @DefineEnum + CHAR(10) + @PrepareVariable;

DECLARE @QueryTotalRow NVARCHAR(MAX)
= N'' + N' declare @TotalRow int = (SELECT COUNT(*) as totalRow' + CHAR(10) + @ClauseFrom + CHAR(10)
+ @ClauseWhere + N' )';

DECLARE @SqlQuery NVARCHAR(MAX) = N'' + @PrepareQuery + CHAR(10) + @QueryTotalRow + @ClauseSelect;

PRINT @ParamDefinition;
DECLARE @SqlPrint AS NVARCHAR(MAX) = @SqlQuery;
WHILE LEN(@SqlPrint) > 2000
BEGIN
PRINT (SUBSTRING(@SqlPrint, 0, 2000));
SET @SqlPrint = SUBSTRING(@SqlPrint, 2000, LEN(@SqlPrint));
END;
PRINT @SqlPrint;

EXEC sp_executesql @SqlQuery,
@ParamDefinition,
@IsNewestContract,
@ProfileName,
@CodeEmp,
@strOrgIds,
@JobTitleId,
@PositionID,
@Code,
@ContractNo,
@ContractTypeID,
@dateFrom,
@dateTo,
@strEmpTypeID,
@IDNo,
@Gender,
@status,
@WorkPlaceID,
@PayrollGroupID,
@isLastContract,
@timesContract,
@dateEndFrom,
@dateEndTo,
@isProfileWorking,
@dateStartFrom,
@dateStartTo,
@strClassRateID,
@isNotSign,
@isCheckFromDashBoard,
@StatusSyn,
@strAbilitiTitleID,
@isOrgEffective,
@strEmpGroupID,
@strIDs,
@DateCreateFrom,
@DateCreateTo,
@TerminateDateFrom,
@TerminateDateTo,
@CodeEmpClient,
@strUnitStructureIDs,
@TypeContract,
@ContractStatus,
@dateHireFrom,
@dateHireTo,
@isCreateTemplate,
@isCreateDynamicGrid,
@ExportID,
@ExcelType,
@DateCreate,
@UserCreate,
@isRar,
@StrCompanyID,
@IsShowContractWithoutKPI,
@NationnalGroupIDs,
@ProfileIDs,
@AssessmentStatus,
@IsIncludeWorkingEmp,
@IsStopWorking,
@ProvinceIDs,
@CountryIDs,
@StatusCancelDigiSigna,
@PageIndex,
@PageSize,
@Username,
@fieldSort
END
GO --END--
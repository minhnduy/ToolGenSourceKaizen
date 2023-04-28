
CREATE PROCEDURE [dbo].[hrm_att_sp_get_Overtime]
			 @ProfileName nvarchar(100) = NULL,
			 @CodeEmp nvarchar(max) = NULL, 
			 @DateStart DATETIME = NULL,
			 @DateEnd DATETIME = NULL,
			 @OvertimeTypeId varchar(max) = NULL,
			 @Status NVARCHAR(max) = NULL,
			 @OrgStructureID varchar(max)= NULL,
			 @JobtitleID varchar(4000) = NULL,
			 @UserID uniqueidentifier= NULL,
			 @ain_WorkPlaceID varchar(4000) = NULL,
			 @PositionId varchar(4000) = NULL,
			 @a bit = null,
			 @b bit = null,
			 @ExportId uniqueidentifier= NULL,
			 @MealRegisted NVARCHAR(max) =null,
			 @CarRegisted NVARCHAR(max) =null,
			 @Durationtype NVARCHAR(max) = NULL,
			 @FormCode NVARCHAR(100) = NULL,
			 @FormName NVARCHAR(100) = NULL,
			 @CostCentreID uniqueidentifier = NULL,
			 @EmployeeGroupID uniqueidentifier = NULL,
			 @EmployeeTypeID uniqueidentifier = NULL,
			 @UnitStructureID NVARCHAR(MAX) = NULL,
			 @AttGradeID NVARCHAR(MAX) = NULL,
			 @TaxType NVARCHAR(100) = NULL,
			 @MethodPayment NVARCHAR(200) = NULL,
			 @UserCreate varchar(400)= NULL,
			 @DateStartConfirm DATETIME = NULL,
			 @DateEndConfirm DATETIME = NULL,
			 @CompanyIDs varchar(max) = NULL,
			 @IsExplanatory bit = null,
			 @IsNotCheckInOut bit = null,
			 @ProfileIDs VARCHAR(MAX) = null,
			 @PageIndex int = 1,
			 @PageSize int = 50,
			 @UserName NVARCHAR(50) = 'hanh.nguyen',
			 @fieldSort varchar(50) = 'id'
AS
BEGIN
	SET NOCOUNT ON;
	--Prepair paramater
	DECLARE @DefinePermission NVARCHAR(MAX) = N''
		+ N' CREATE TABLE #tblPermission (id UNIQUEIDENTIFIER PRIMARY KEY ) 
			INSERT INTO #tblPermission EXEC Get_Data_Permission_New @Username, ''Att_Overtime'' '
	DECLARE @DefineEnum NVARCHAR(MAX) = N''
		+ N' SELECT * INTO #tblEnumStatusView FROM dbo.GetEnumValueNew (''OvertimeStatus'', @UserName)
			 SELECT * INTO #tblEnumDurationTypeView FROM dbo.GetEnumValueNew (''OvertimeDurationType'', @UserName)
			 SELECT * INTO #tblEnumMethodPaymentView FROM dbo.GetEnumValueNew (''MethodPayment'', @UserName)
			 SELECT * INTO #tblEnumStatusCancelView FROM dbo.GetEnumValueNew (''LeaveDayCancelStatus'', @UserName)
			 SELECT * INTO #tblTaxType FROM dbo.GetEnumValueNew (''TaxType'', @UserName)
			 SELECT * INTO #tblRegisOvertimeType FROM dbo.GetEnumValueNew (''RegisOvertimeType'', @UserName)
			 SELECT * INTO #tblEnumStatusComment FROM dbo.GetEnumValueNew (''StatusComment'', @UserName)
			 SELECT * INTO #tblEnumStatusSendMailComment FROM dbo.GetEnumValueNew (''StatusComment'', @UserName)
			 CREATE TABLE #tblCompanyID (Id UNIQUEIDENTIFIER PRIMARY KEY ) 
			if (@CompanyIDs is not null)
				insert into #tblCompanyID select * from dbo.SPLIT_To_VARCHAR(@CompanyIDs)

			 -- search phong ban theo cach nay de tang toc do search
			 IF(@OrgStructureID IS NOT NULL)
			 BEGIN
			 	SELECT Id INTO #OrgIdFilter FROM split_to_int(ISNULL(@OrgStructureID, NULL))
			 END

			 IF @ain_WorkPlaceID IS NOT NULL
			 BEGIN
				SELECT orgId INTO #WorkPlaceFilter FROM GetOrgTableIds(ISNULL(@ain_WorkPlaceID, NULL))
			 END

			 IF @JobtitleID IS NOT NULL
			 BEGIN
				SELECT orgId INTO #JobtitleFilter FROM GetOrgTableIds(ISNULL(@JobtitleID, NULL))
			 END

			 IF @PositionId IS NOT NULL
			 BEGIN
				SELECT orgId INTO #PositionFilter FROM GetOrgTableIds(ISNULL(@PositionId, NULL))
			 END

			 IF @UnitStructureID IS NOT NULL
			 BEGIN
				SELECT orgId INTO #UnitStructureFilter FROM GetOrgTableIds(ISNULL(@UnitStructureID, NULL))
			 END

			 CREATE TABLE #AttGradeFilter (orgId UNIQUEIDENTIFIER PRIMARY KEY )
			 IF @AttGradeID IS NOT NULL
			 BEGIN
				INSERT INTO #AttGradeFilter SELECT orgId FROM GetOrgTableIds(ISNULL(@AttGradeID, NULL))
			 END
			 IF @ProfileIDs IS NOT NULL
			 BEGIN
				SELECT orgId INTO #ProfileIDsFilter FROM GetOrgTableIds(ISNULL(@ProfileIDs, NULL))
			 END
			 '
	-- Get AttGrade new 
	DECLARE @DefineAttGrade NVARCHAR(MAX) = ''
	SET @DefineAttGrade = N'
		SELECT ag.MonthStart,ag.MonthEnd,ag.ProfileID,ag.GradeAttendanceID, cg.GradeAttendanceName
		INTO #tblTempGrade
		FROM Att_Grade ag
		LEFT JOIN Cat_GradeAttendance cg ON cg.ID = ag.GradeAttendanceID AND cg.IsDelete IS NULL
		WHERE ag.IsDelete is null;
		WITH sumary AS
		(
		 SELECT tis.ProfileID, tis.GradeAttendanceID, tis.GradeAttendanceName, ROW_NUMBER() OVER(PARTITION BY tis.ProfileID
		 ORDER BY tis.MonthStart DESC) AS rk
		 FROM #tblTempGrade tis
		)

	'
	
	DECLARE @queryGrade NVARCHAR(MAX) = 
	'SELECT ProfileID, GradeAttendanceName 
		INTO #tblTempGradeResult
		FROM sumary sm
		WHERE rk = 1
		'
	
	IF(@AttGradeID is not null)
	BEGIN
		SET @queryGrade = @queryGrade + ' AND GradeAttendanceID IN (SELECT orgId FROM #AttGradeFilter);'
	END



	--Mệnh đề FROM
	DECLARE @ClauseFrom NVARCHAR(MAX) = N''
		+ N' FROM Att_Overtime ao WITH (NOLOCK) ' + CHAR(10)
		+ N'	JOIN Hre_Profile hp WITH (NOLOCK)ON ao."ProfileID" = hp.ID
				LEFT JOIN Cat_OrgStructure corg ON ao."OrgStructureID" = corg.ID AND corg."IsDelete" IS NULL
				JOIN #tblPermission fcP ON fcP.Id = ao.ProfileID ' + CHAR(10)
	-- Mệnh đề FROM main
	DECLARE @ClauseFromMain NVARCHAR(MAX) = N''
		+ N' FROM Att_Overtime ao' + CHAR(10)
		+ N'	JOIN Hre_Profile hp WITH (NOLOCK) ON ao."ProfileID" = hp.ID
				LEFT JOIN "Cat_Shift" cs ON ao."ShiftID" = cs."ID" AND cs."IsDelete" IS NULL
				LEFT JOIN "Cat_OvertimeType" co ON ao."OvertimeTypeID" = co."ID" AND co."IsDelete" IS NULL
				LEFT JOIN "Sys_UserInfo" su1 ON ao."UserApproveID" = su1."ID" AND su1."IsDelete" IS NULL
				LEFT JOIN "Hre_Profile" hp1 WITH (NOLOCK) ON hp1.id = su1.ProfileID AND hp1."IsDelete" IS NULL
				LEFT JOIN "Sys_UserInfo" su2 WITH (NOLOCK) ON ao."UserApproveID2" = su2."ID" AND su2."IsDelete" IS NULL
				LEFT JOIN "Hre_Profile" hp2 WITH (NOLOCK) ON hp2.id = su2.ProfileID AND hp2."IsDelete" IS NULL
				LEFT JOIN "Sys_UserInfo" su5 WITH (NOLOCK) ON ao."UserApproveID4" = su5."ID" AND su5."IsDelete" IS NULL
				LEFT JOIN "Hre_Profile" hp5 WITH (NOLOCK) ON hp5.id = su5.ProfileID AND hp5."IsDelete" IS NULL
				LEFT JOIN "Sys_UserInfo" su3 WITH (NOLOCK) ON ao."UserApproveID3" = su3."ID" AND su3."IsDelete" IS NULL
				LEFT JOIN Sys_UserInfo su4 WITH (NOLOCK) ON ao.UserRejectID = su4.Id AND su4."IsDelete" IS NULL
				LEFT JOIN Sys_UserInfo su6 WITH (NOLOCK) ON ao.UserCreate = su6.UserLogin AND su6."IsDelete" IS NULL
				LEFT JOIN "Hre_Profile" hp3 WITH (NOLOCK) ON hp3.id = su3.ProfileID AND hp3."IsDelete" IS NULL
				LEFT JOIN "Cat_OrgStructure" corg ON ao."OrgStructureID" = corg."ID" AND corg."IsDelete" IS NULL
				LEFT JOIN "Cat_OrgUnit" cou ON ao."OrgStructureID" = cou."OrgStructureID" AND cou."IsDelete" IS NULL
				LEFT JOIN "Cat_WorkPlace" cwp ON ao."WorkPlaceID" = cwp."ID" AND cwp."IsDelete" IS NULL
				LEFT JOIN "Cat_Position" cp ON ao."PositionID" = cp.id AND cp."IsDelete" IS NULL
				LEFT JOIN "Hre_Profile" hp4 WITH (NOLOCK) ON hp4.ID = ao.UserSubmit AND hp4."IsDelete" IS NULL
				LEFT JOIN Can_Menu cm ON cm.ID = ao.MenuID and cm.IsDelete IS NULL
				LEFT JOIN Can_Menu cm1 ON cm1.ID = ao.MenuID and cm1.IsDelete IS NULL
				LEFT JOIN Can_Food cf ON cf.ID = ao.FoodID and cf.IsDelete IS NULL
				LEFT JOIN Can_Food cf1 ON cf1.ID = ao.FoodID and cf1.IsDelete IS NULL
				LEFT JOIN Cat_WorkPlace cw1 ON cw1.ID = ao.OvertimePlaceID and cw1.IsDelete IS NULL
				LEFT JOIN "Cat_OrgStructure" cosorg ON ao."OrgStructureCostID" = cosorg."ID" AND corg."IsDelete" IS NULL
				LEFT JOIN "Cat_JobTitle" cj ON cj."ID" = ao."JobTitleID" AND cj."IsDelete" IS NULL
				LEFT JOIN Cat_UnitStructure cus ON ao.UnitStructureId = cus.ID and cus.IsDelete IS NULL
				LEFT JOIN (SELECT ID, WorkDate, ProfileID, FirstInTime, LastOutTime, IsDelete FROM Att_WorkDay WITH (NOLOCK)) awd ON ao.ProfileID = awd.ProfileID AND ao.WorkDateRoot = awd.WorkDate AND awd.IsDelete IS NULL
				LEFT JOIN (SELECT ID, CostCentreName, Code, IsDelete FROM Cat_CostCentre) ccc ON ao.CostCentreID = ccc.ID AND ccc.IsDelete IS NULL
				LEFT JOIN (SELECT ID, EmployeeTypeName, IsDelete FROM Cat_EmployeeType) cet ON ao.EmployeeTypeID = cet.ID and cet.IsDelete IS NULL
				LEFT JOIN (SELECT ID, Code, JobTypeName, IsDelete FROM Cat_JobType) cjt ON ao.JobTypeID = cjt.ID and cjt.IsDelete IS NULL
				LEFT JOIN #tblEnumStatusView tt ON tt.EnumKey = ao.Status
				LEFT JOIN #tblEnumDurationTypeView drtt ON drtt.EnumKey = ao.DurationType
				LEFT JOIN #tblEnumMethodPaymentView mtpm ON mtpm.EnumKey = ao.MethodPayment
				LEFT JOIN #tblTaxType tax ON tax.EnumKey = ao.TaxType
				left join Cat_Company cc on ao.CompanyID= cc.ID and cc.IsDelete is null
				LEFT JOIN (SELECT ID, Status, RecordID FROM Att_RequestCancel WHERE IsDelete IS NULL AND Status <> ''E_REJECTED'') rqc ON rqc.RecordID = ao.ID
				LEFT JOIN #tblEnumStatusCancelView rqt ON rqt.EnumKey = rqc.Status
				LEFT JOIN (SELECT ID, ShopGroupName,Code, IsDelete FROM Cat_ShopGroup) csg ON csg.ID = ao.BusinessUnitTypeID AND csg."IsDelete" IS NULL
				LEFT JOIN (SELECT ID, ShopName,Code, IsDelete FROM Cat_Shop) cshop ON cshop.ID = ao.BusinessUnitID AND cshop."IsDelete" IS NULL
				LEFT JOIN "Cat_WorkPlace" wpt ON ao."WorkPlaceTransID" = wpt."ID" AND wpt."IsDelete" IS NULL
				LEFT JOIN "Cat_Company" cpt ON ao."CompanyTransID" = cpt."ID" AND cpt."IsDelete" IS NULL
				LEFT JOIN (SELECT ID, ProfileID FROM Sys_UserInfo WHERE IsDelete IS NULL ) su7 ON su7.ID=ao.UserProcessApproveID
				LEFT JOIN (SELECT ID, ProfileName FROM Hre_Profile WHERE IsDelete IS NULL ) hp9 ON hp9.ID=su7.ProfileID
				LEFT JOIN (SELECT ID, ProfileID FROM Sys_UserInfo WHERE IsDelete IS NULL ) su8 ON su8.ID=ao.UserProcessApproveID2
				LEFT JOIN (SELECT ID, ProfileName FROM Hre_Profile WHERE IsDelete IS NULL ) hp10 ON hp10.ID=su8.ProfileID
				LEFT JOIN (SELECT ID, ProfileID FROM Sys_UserInfo WHERE IsDelete IS NULL ) su9 ON su9.ID=ao.UserProcessApproveID3
				LEFT JOIN (SELECT ID, ProfileName FROM Hre_Profile WHERE IsDelete IS NULL ) hp11 ON hp11.ID=su9.ProfileID
				LEFT JOIN (SELECT ID, ProfileID FROM Sys_UserInfo WHERE IsDelete IS NULL ) su10 ON su10.ID=ao.UserProcessApproveID4
				LEFT JOIN (SELECT ID, ProfileName FROM Hre_Profile WHERE IsDelete IS NULL ) hp12 ON hp12.ID=su10.ProfileID
				LEFT JOIN Cat_OvertimeReason cor ON cor.ID = ao.ReasonOT2ID AND cor."IsDelete" IS NULL
				LEFT JOIN Cat_NameEntity cn ON cn.ID = ao.DistributionChannelID AND cn."IsDelete" IS NULL
				LEFT JOIN #tblRegisOvertimeType rot ON rot.EnumKey = ao.Type
				LEFT JOIN #tblEnumStatusComment escm ON escm.EnumKey = ao.StatusComment
				LEFT JOIN #tblEnumStatusSendMailComment essm ON essm.EnumKey = ao.CommentSendMailStatus
				LEFT JOIN Cat_OvertimeReasonDetail cord ON cord.ID = ao.OvertimeReasonDetailID AND cord."IsDelete" IS NULL
				LEFT JOIN Att_OvertimePlan aop ON aop.ProfileID = ao.ProfileID AND aop.WorkDateRoot = ao.WorkDateRoot AND aop.DurationType = ao.DurationType AND aop.IsDelete IS NULL AND aop.Status NOT IN (SELECT ID FROM SPLIT_To_VARCHAR(''E_CANCEL,E_REJECTED''))
				LEFT JOIN #tblEnumDurationTypeView drtt2 ON drtt2.EnumKey = aop.DurationType
				LEFT JOIN #tblEnumMethodPaymentView mtpm2 ON mtpm2.EnumKey = aop.MethodPayment
				LEFT JOIN "Sys_UserInfo" aopsu1 ON aop."UserApproveID" = aopsu1."ID" AND aopsu1."IsDelete" IS NULL
				LEFT JOIN "Hre_Profile" aophp1 WITH (NOLOCK) ON aophp1.id = aopsu1.ProfileID AND aophp1."IsDelete" IS NULL
				LEFT JOIN "Sys_UserInfo" aopsu2 WITH (NOLOCK) ON aop."UserApproveID2" = aopsu2."ID" AND aopsu2."IsDelete" IS NULL
				LEFT JOIN "Hre_Profile" aophp2 WITH (NOLOCK) ON aophp2.id = aopsu2.ProfileID AND aophp2."IsDelete" IS NULL
				LEFT JOIN "Sys_UserInfo" aopsu3 WITH (NOLOCK) ON aop."UserApproveID3" = aopsu3."ID" AND aopsu3."IsDelete" IS NULL
				LEFT JOIN "Hre_Profile" aophp3 WITH (NOLOCK) ON aophp3.id = aopsu3.ProfileID AND aophp3."IsDelete" IS NULL
				LEFT JOIN "Sys_UserInfo" aopsu4 WITH (NOLOCK) ON aop."UserApproveID4" = aopsu4."ID" AND aopsu4."IsDelete" IS NULL
				LEFT JOIN "Hre_Profile" aophp4 WITH (NOLOCK) ON aophp4.id = aopsu4.ProfileID AND aophp4."IsDelete" IS NULL

				JOIN #tblPermission fcP ON fcP.Id = ao.ProfileID ' + CHAR(10)
	--Mệnh đề WHERE
	DECLARE @ClauseWhere NVARCHAR(MAX) = N' WHERE ' + CHAR(10)
		+ N' ao.IsDelete IS NULL '
		+ N'AND hp.ID NOT IN (SELECT ID from Hre_Profile where StatusSyn = ''E_WAITING'' OR StatusSyn = ''E_UNHIRE'' OR StatusSyn = ''E_WAITING_APPROVE'')'
	IF @ProfileName IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (LOWER(hp.ProfileName) LIKE ''%'' + lower(@ProfileName) + ''%'') '
	IF @JobtitleID IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.JobTitleID IN (SELECT orgId FROM #JobtitleFilter)) '
	IF @PositionId IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.PositionID IN (SELECT orgId FROM #PositionFilter)) '
	IF @UserCreate IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.UserCreate IN (SELECT ID FROM SPLIT_To_VARCHAR(@UserCreate))) '
	IF @DateStart IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.WorkDateRoot >= @DateStart) '
	IF @DateEnd IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.WorkDateRoot <= @DateEnd) '
	IF @DateStartConfirm IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.WorkDateConfirm >= @DateStartConfirm) '
	IF @DateEndConfirm IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.WorkDateConfirm <= @DateEndConfirm) '
	IF @CodeEmp IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND ((LOWER(hp.CodeEmp) LIKE ''%'' + LOWER(@CodeEmp) + ''%'') 
				 OR (hp.CodeEmp IN (SELECT ID FROM SPLIT_To_VARCHAR(@CodeEmp))))'
	IF @Status IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.Status IN (SELECT ID FROM SPLIT_To_VARCHAR(@Status))) '
	IF @OrgStructureID IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (corg.OrderNumber IN (SELECT Id FROM #OrgIdFilter)) '
	IF @DurationType IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.DurationType IN (SELECT ID FROM SPLIT_To_VARCHAR(@DurationType))) '
	IF @OvertimeTypeId IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.OvertimeTypeID IN (SELECT ID FROM SPLIT_To_VARCHAR(@OvertimeTypeId))) '
	IF @UserID IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND ((ao.UserApproveID = @UserID) OR (ao.UserApproveID2 = @UserID) OR (ao.UserApproveID3 = @UserID)) '
	IF @FormCode IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (LOWER(ao.FormCode) LIKE ''%'' + LOWER(@FormCode) + ''%'') '
	IF @FormName IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (LOWER(ao.FormName) LIKE ''%'' + LOWER(@FormName) + ''%'') '
	IF @ain_WorkPlaceID IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.WorkPlaceID IN (SELECT orgId FROM #WorkPlaceFilter)) '
	'IF @MealRegisted = ''E_YES'' AND (ao.IsMealRegistration = 1)
	IF  @MealRegisted = ''E_NO'' AND (ao.IsMealRegistration IS NULL OR ao.IsMealRegistration = 0) '
	ELSE
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
		+ N' AND (ao.IsMealRegistration IS NOT NULL OR ao.IsMealRegistration IS NULL) '
	
	IF @CarRegisted = 'E_YES'
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.IsCarRegistration = 1) '
	IF @CarRegisted = 'E_NO'
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.IsCarRegistration IS NULL OR ao.IsCarRegistration = 0) '
	ELSE
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.IsCarRegistration IS NOT NULL OR ao.IsCarRegistration IS NULL) '
	IF @CostCentreID IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.CostCentreID = @CostCentreID) '
	IF @EmployeeGroupID IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.EmployeeGroupID = @EmployeeGroupID) '
	IF @EmployeeTypeID IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.EmployeeTypeID = @EmployeeTypeID) '
	IF @TaxType IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.TaxType = @TaxType) '
	IF @MethodPayment IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.MethodPayment IN (SELECT ID FROM SPLIT_To_VARCHAR( @MethodPayment))) '
	IF @UnitStructureID IS NOT NULL 
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.UnitStructureID IN (SELECT orgId FROM #UnitStructureFilter))'
	IF @IsExplanatory IS NOT NULL and @IsExplanatory = 1
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.IsExplanatory = @IsExplanatory)'
			IF @IsNotCheckInOut IS NOT NULL and @IsNotCheckInOut = 1
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.IsNotCheckInOut = @IsNotCheckInOut)'
	--Add clause from for profile grade new
	IF @AttGradeID IS NOT NULL
	BEGIN
		SET @ClauseFrom = @ClauseFrom + CHAR(10)
				+ N' JOIN #tblTempGradeResult tgrs ON ao.ProfileID = tgrs.ProfileID'
	END
	--SET @ClauseFrom = @ClauseFrom + CHAR(10)
	--			+ N' JOIN #tblTempGradeResult tgrs ON ao.ProfileID = tgrs.ProfileID'
	SET @ClauseFromMain = @ClauseFromMain + CHAR(10)
		+ N' JOIN #tblTempGradeResult tgrs ON ao.ProfileID = tgrs.ProfileID'
	IF @CompanyIDs IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + ' and (ao.CompanyID in (select id from #tblCompanyID)) '
	IF @ProfileIDs IS NOT NULL
		SET @ClauseWhere = @ClauseWhere + CHAR(10)
			+ N' AND (ao.ProfileID IN (SELECT orgId FROM #ProfileIDsFilter)) '

	DECLARE @ClauseSelect NVARCHAR(MAX) = N''
	+ N' SELECT
			@TotalRow as TotalRow,
			ao.DistributionChannelID,
			cn.NameEntityName as NameDistributionChannel,
			ao."ID",
			ao.IsEmergency,
			ao."WorkDate",
			ao.DistributionChannelID,
			cn.NameEntityName as NameDistributionChannel,
			ao."AnalyseHour",
			ao."RegisterHours",
			ao."ApproveHours",
			ao.ConfirmHours,
			ao."Status",
			ao."MethodPayment",
			ao."ReasonOT",
			ao."OvertimeTypeID",
			ao."ShiftID",
			ao."InTime",
			ao."OutTime",
			ao."UserApproveID",
			ao."UserApproveID2",
			ao."UserApproveID3",
			ao."UserApproveID4",
			ao."IsConvertData",
			cs."ShiftName",
			hp."ProfileName",
			ao."ProfileID",
			hp."CodeEmp",
			hp."DateHire",
			ao."TaxType",
			co."OvertimeTypeName",
			co."Code" as "OvertimeTypeCode",
			hp1."ProfileName" AS "UserApproveName1", 
			hp2."ProfileName" AS "UserApproveName2",
			hp3."ProfileName" AS "UserApproveName3",
			hp5."ProfileName" AS "UserApproveName4",
			corg."Code" as "OrgStructureCode",
			ao."UserUpdate",
			CASE WHEN ao."IsNonOvertime" = ''1'' THEN N''X'' ELSE N'''' END AS "udIsNonOvertime",
			ao."Status" as "StatusTranslate",
			su4.UserInfoName AS UserReject,
			su6.UserLogin AS UserCreate,
			ao.DateRequest,
			ao.DateApprove,
			ao.DateReject,
			ao.DeclineReason,
			ao.ConfirmReason,
			ao.SendEmailStatus,
			ao.UserCreate,
			ao.DateCreate,
			ao.PositionID,
			ao."JobTitleID",
			ao.UserUpdate,
			ao.DateUpdate,
			ao."WorkDateRoot",
			cou.E_COMPANY,
			cou.E_BRANCH,
			cou.E_UNIT,
			cou.E_DIVISION,
			cou.E_DEPARTMENT,
			cou.E_TEAM,
			cou.E_SECTION,
 cou.E_COMPANY_CODE,
			cou.E_BRANCH_CODE,
			cou.E_UNIT_CODE,
			cou.E_DIVISION_CODE,
			cou.E_DEPARTMENT_CODE,
			cou.E_TEAM_CODE,
			cou.E_SECTION_CODE,
			cus.UnitName,
			hp.DateApplyAttendanceCode,
			hp4.ProfileName AS "UserSubmitName",
			ao.MenuID,
			ao.Menu2ID,
			ao.FoodID,ao.Food2ID,
			ao.OvertimePlaceID,
			ao.Note,
			cw1.WorkPlaceName as OvertimePlaceName,
			cm.MenuName,
			cm1.MenuName as MenuName2,
			cf.FoodName,
			cf1.FoodName as FoodName2,
			hp.CodeEmpClient,
			cosorg.OrgStructureName AS OrgStructureNameCost,
			ao.FormCode,
			ao.FormName,
			corg."OrgStructureName",
			ao.IsMealRegistration,
			cp."PositionName",cwp.WorkPlaceName,cj.JobTitleName,
			ao.IsCarRegistration,
			ao.DurationType,
			ao.IsPayback,
			ao.PaybackDurationID,
			ao.WorkPlaceID,
			ao.PayrollGroupID,
			ao.ApproveComment,
			ao.ApproveComment1,
			ao.ApproveComment2,
			ao.ApproveComment3,
			ao.ApproveComment4,
			ao.WorkDateConfirm,
			ao.OrgStructureID,
			tt.EnumTranslate AS StatusView,
			drtt.EnumTranslate AS DurationTypeView,
			mtpm.EnumTranslate AS MethodPaymentView,
			tax.EnumTranslate AS TaxTypeView,
			CAST(CAST(awd.FirstInTime AS TIME(0)) AS VARCHAR(8)) AS InTimeView,
			CAST(CAST(awd.LastOutTime AS TIME(0)) AS VARCHAR(8)) AS OutTimeView,
			awd.FirstInTime AS InTimeDateView,
			awd.LastOutTime AS OutTimeDateView,
			ccc.Code AS CodeCostCentre,
			cet.EmployeeTypeName,
			tgrs.GradeAttendanceName,
			cjt.Code AS CodeJobType,
			cjt.JobTypeName,
			ao.IsOvertimeBreak,
			ao.AdditionalHours,
			ao.IsNotCheckInOut,
			ao.TakenCompLeaveHours,
			ao.Notes,
			cc.CompanyName,
			ao.TimeLogStartOT,
			ao.TimeLogEndOT,
			ao.TimeLogStartShift,
			ao.TimeLogEndShift,
			ao.IsFreeOfCharge,
			ao.AdditionalHours,
			rqt.EnumTranslate AS CancelationStatus,
			ao.IsExplanatory,
			ao.IsNotCheckInOut,
			csg.ShopGroupName AS BusinessUnitTypeView,
			cshop.ShopName AS BusinessUnitView,
			ao.BreakRegisterHours,
			ao.BreakConfirmHours,
			wpt.WorkPlaceName AS WorkPlaceTransName,
			hp9.ProfileName AS UserProcessApproveName,
			hp10.ProfileName AS UserProcessApprove2Name,
			hp11.ProfileName AS UserProcessApprove3Name,
			hp12.ProfileName AS UserProcessApprove4Name,
			csg.Code AS BusinessUnitTypeCodeView,
			cshop.Code AS BusinessUnitCodeView,
			ao.FileAttach,
			cpt.CompanyName AS CompanyTransName,
			ao.OvertimePlanID,
			cor.OvertimeReasonName AS ReasonNameOT2,
			ao.Type,
			rot.EnumTranslate AS TypeView,
			escm.EnumTranslate AS StatusComment,
			essm.EnumTranslate AS CommentSendMailStatus,
			cord.OvertimeReasonDetailName,
			ao.ReasonOT2ID,
			ao.OvertimeReasonDetailID,
			--(SELECT STUFF((SELECT '', '' + hpc1.ProfileName from Hre_Profile hpc1
			--WHERE hpc1.ID in ((select orgId FROM GetOrgTableIds(ISNULL(ao.UserComment1, NULL))))
			--AND IsDelete is null
			--FOR XML PATH('''')), 1, 1, '''') AS [Output]) as UserComment1View,
			-- (SELECT STUFF((SELECT '', '' + hpc2.ProfileName from Hre_Profile hpc2
			--WHERE hpc2.ID in ((select orgId FROM GetOrgTableIds(ISNULL(ao.UserComment2, NULL))))
			--AND IsDelete is null
			--FOR XML PATH('''')), 1, 1, '''') AS [Output]) as UserComment2View,
			-- (SELECT STUFF((SELECT '', '' + hpc3.ProfileName from Hre_Profile hpc3
			--WHERE hpc3.ID in ((select orgId FROM GetOrgTableIds(ISNULL(ao.UserComment3, NULL))))
			--AND IsDelete is null
			--FOR XML PATH('''')), 1, 1, '''') AS [Output]) as UserComment3View,
			-- (SELECT STUFF((SELECT '', '' + hpc4.ProfileName from Hre_Profile hpc4
			--WHERE hpc4.ID in ((select orgId FROM GetOrgTableIds(ISNULL(ao.UserComment4, NULL))))
			--AND IsDelete is null
			--FOR XML PATH('''')), 1, 1, '''') AS [Output]) as UserComment4View,
			ao.UserComment1,
			ao.UserComment2,
			ao.UserComment3,
			ao.UserComment4,
			aop.DayType AS DayTypeOTP,
			drtt2.EnumTranslate AS DurationTypeOTPView,
			aop.TimeFrom AS TimeFromOTP,
			aop.TimeTo AS TimeToOTP,
			aop.RegisterHours  AS RegisterHoursOTP,
			aop.OvertimeHour AS OvertimeHourOTP,
			mtpm2.EnumTranslate AS MethodPaymentOTP,
			aophp1."ProfileName" AS "UserApproveNameOTP1", 
			aophp3."ProfileName" AS "UserApproveNameOTP2",
			aophp4."ProfileName" AS "UserApproveNameOTP3",
			aophp2."ProfileName" AS "UserApproveNameOTP4",
			aop.ReasonOT AS ReasonOTP
	'
	+ @ClauseFromMain
	+ @ClauseWhere +N' 

	ORDER BY ao.DateUpdate DESC
	OFFSET ((@PageIndex - 1) * (@PageSize)) ROWS FETCH NEXT @PageSize ROWS ONLY
	DROP TABLE #tblPermission
	DROP TABLE #tblEnumStatusView
	DROP TABLE #tblEnumDurationTypeView
	DROP TABLE #tblEnumMethodPaymentView
	DROP TABLE #tblEnumStatusCancelView
	DROP TABLE #tblTaxType
	DROP TABLE #tblRegisOvertimeType
	DROP TABLE #tblCompanyID
	DROP TABLE #tblEnumStatusComment
	IF @OrgStructureID IS NOT NULL
		DROP TABLE #OrgIdFilter
	IF @ain_WorkPlaceID IS NOT NULL
		DROP TABLE #WorkPlaceFilter
	IF @UnitStructureID IS NOT NULL
		DROP TABLE #UnitStructureFilter
	IF @JobtitleID IS NOT NULL
		DROP TABLE #JobtitleFilter
	IF @PositionId IS NOT NULL
		DROP TABLE #PositionFilter
		
	--IF @AttGradeID IS NOT NULL
	--BEGIN
		
	--END
	DROP TABLE #AttGradeFilter
	DROP TABLE #tblTempGrade
	DROP TABLE #tblTempGradeResult
	IF @ProfileIDs IS NOT NULL
		DROP TABLE #ProfileIDsFilter
	'

	DECLARE @ParamDefinition NVARCHAR(MAX) = N''
		+ N' @ProfileName nvarchar(100) = NULL,
			 @CodeEmp nvarchar(max) = NULL, 
			 @DateStart DATETIME = NULL,
			 @DateEnd DATETIME = NULL,
			 @OvertimeTypeId varchar(max) = NULL,
			 @Status NVARCHAR(max) = NULL,
			 @OrgStructureID varchar(max)= NULL,
			 @JobtitleID uniqueidentifier= NULL,
			 @UserID uniqueidentifier= NULL,
			 @ain_WorkPlaceID varchar(4000) = NULL,
			 @PositionId varchar(4000) = NULL,
			 @a bit = null,
			 @b bit = null,
			 @ExportId uniqueidentifier= NULL,
			 @MealRegisted NVARCHAR(max) =null,
			 @CarRegisted NVARCHAR(max) =null,
			 @Durationtype NVARCHAR(max) = null,
			 @FormCode NVARCHAR(100) = NULL,
			 @FormName NVARCHAR(100) = NULL,
			 @CostCentreID uniqueidentifier = NULL,
			 @EmployeeGroupID uniqueidentifier = NULL,
			 @EmployeeTypeID uniqueidentifier = NULL,
			 @UnitStructureID NVARCHAR(MAX) = NULL,
			 @AttGradeID NVARCHAR(MAX) = NULL,
			 @TaxType NVARCHAR(100) = NULL,
			 @MethodPayment NVARCHAR(200) = NULL,
			 @UserCreate varchar(4000) = NULL,
			 @DateStartConfirm DATETIME = NULL,
			 @DateEndConfirm DATETIME = NULL,
			 @CompanyIDs varchar(max) = NULL,
			 @IsExplanatory bit = null,
			 @IsNotCheckInOut bit = null,
			 @ProfileIDs VARCHAR(MAX) = null,
			 @PageIndex int = 1,
			 @PageSize int = 50,
			 @UserName NVARCHAR(50) = NULL,
			 @fieldSort varchar(50) = NULL '
	DECLARE @PrepareQuery NVARCHAR(MAX) = N''
		+ @DefinePermission + CHAR(10)
		+ @DefineEnum + CHAR(10)
		+ @DefineAttGrade + CHAR(10)
		+ @queryGrade + CHAR(10)

	DECLARE @QueryTotalRow NVARCHAR(MAX) = N''
		+ N' DECLARE @TotalRow int = (SELECT COUNT(ao.ID) as totalRow' + CHAR(10)
		+ @ClauseFromMain + CHAR(10)
		+ @ClauseWhere
		+ N' )'

	DECLARE @SqlQuery NVARCHAR(MAX) = N''
		+ @PrepareQuery + CHAR(10)
		+ @QueryTotalRow
		+ @ClauseSelect
	PRINT @ParamDefinition

	DECLARE @SqlPrint AS NVARCHAR(max) = @SqlQuery;
	WHILE LEN(@SqlPrint) > 2000
	BEGIN
		PRINT(SUBSTRING(@SqlPrint, 0, 2000))
		SET @SqlPrint = SUBSTRING(@SqlPrint, 2000, LEN(@SqlPrint));
	END
	print @SqlPrint

	EXEC SP_EXECUTESQL @SqlQuery, @ParamDefinition,
		@ProfileName,
		@CodeEmp,
		@DateStart,
		@DateEnd,
		@OvertimeTypeId,
		@Status,
		@OrgStructureID,
		@JobtitleID,
		@UserID,
		@ain_WorkPlaceID,
		@PositionId,
		@a,
		@b,
		@ExportId,
		@MealRegisted,
		@CarRegisted,
		@Durationtype,
		@FormCode,
		@FormName,
		@CostCentreID,
		@EmployeeGroupID,
		@EmployeeTypeID,
		@UnitStructureID,
		@AttGradeID,
		@TaxType,
		@MethodPayment,
		@UserCreate,
		@DateStartConfirm,
		@DateEndConfirm,
		@CompanyIDs,
		@IsExplanatory,
		@IsNotCheckInOut,
		@ProfileIDs,
		@PageIndex,
		@PageSize,
		@UserName,
		@fieldSort
END

GO --END--
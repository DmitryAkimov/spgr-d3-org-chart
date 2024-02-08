#
#
#

$server = 'SQL-01';
$database = 'Reporting';
$csvPath = 'C:\dev\spgr-d3-org-chart\data';


function GetSqlDataSet ([string] $sql , [string] $csvExportPath ) {
    try {
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $sqlConnection.ConnectionString = "Server=$server;Database=$database;Integrated Security=True"
        
        $sqlCommand = New-Object System.Data.SqlClient.SqlCommand
        $sqlCommand.CommandText = $sql
        $sqlCommand.Connection = $sqlConnection
        
        $sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $sqlAdapter.SelectCommand = $sqlCommand
        
        $ds = New-Object System.Data.DataSet
        $sqlAdapter.Fill($ds)
        $sqlConnection.Close();
        
        if($csvExportPath -ne $null) {
            $ds.Tables[0] | Export-CSV -Path "$csvExportPath" -notypeinformation -Encoding UTF8 -Force
        }
        
        return $ds;
    }        
    catch { $Error; break;}        
}

    #--------------------------------------------------------------------------
    #  MAIN
    #--------------------------------------------------------------------------
    CLS;

    #--------------------------------------------------------------------------
    # Подразделения
    #--------------------------------------------------------------------------
    $sql = "
    SELECT 
	    [Код_] as id
	    , IIF( [РодительКод] = 0x0, '', CONVERT (nvarchar(100), [РодительКод], 2)) as parentId
	    ,[Подразделение] as department
	    ,[v1СЗУП_РуководителиПодразделений].ФИО as manager
	    ,[v1СЗУП_РуководителиПодразделений].КодФизЛица as managerEid
        ,[СтруктураПредприятия].Уровень as level
    FROM
	    [fn1СЗУП_СтруктураПредприятия] (default) [СтруктураПредприятия]
	    LEFT JOIN [v1СЗУП_РуководителиПодразделений] ON [СтруктураПредприятия].Код=v1СЗУП_РуководителиПодразделений.СтруктураПредприятияКод
    ORDER BY
	    [Путь]
    ";
    $ds = GetSqlDataSet -sql $sql  -csvExportPath "$csvPath\departments.csv"
    $count = $ds.Tables.Rows.Count;
    Write-Host "Подразделения =  $count";
    
    #--------------------------------------------------------------------------
    #  Сотрудники
    #--------------------------------------------------------------------------
    $sql = "
        SELECT 
            [КодФизлица] as id
            ,CONVERT(nvarchar(100), [ПодразделениеКод], 2) as parentId
	        ,[ФИО] as [name]
            ,[Подразделение] as department
            ,[Должность] as title
            ,[СборЗагрузки] as isTimesheet
            ,[Филиал] as branch
            ,N'https://bitrix.spgr.ru/company/personal/user/' + CONVERT(nvarchar, vBITRIX_users.ID) + '/' as bitrixUserUrl
			,ДРСИ.РаботаетДистанционно as worksRemotely
            ,ДРСИ.[СГ_РежимДистанционнойРаботы] as remoteWorkMode
            ,AdUsers.PhysicalDeliveryOfficeName as physicalDeliveryOfficeName
        FROM
            [v1СЗУП_КлассификаторСотрудников_Текущий] КЛС
            LEFT JOIN vBITRIX_users ON КЛС.КодФизлица=vBITRIX_users.EMPLOYEE_ID
			LEFT JOIN [v1СЗУП_ДистанционнаяРаботаСотрудниковИнтервальный] ДРСИ ON КЛС.ФизЛицоКод = ДРСИ.ФизЛицоКод AND GETDATE() BETWEEN ДРСИ.[ДатаНачала] AND ДРСИ.[ДатаОкончания]
            LEFT JOIN AdUsers ON AdUsers.EmployeeId=КЛС.КодФизлица
        ORDER BY
            [Подразделение]
            ,[ФИО]
        ";

    $ds = GetSqlDataSet -sql $sql -csvExportPath "$csvPath\staff.csv";
    $count = $ds.Tables.Rows.Count;
    Write-Host "Сотрудники = $count" ;
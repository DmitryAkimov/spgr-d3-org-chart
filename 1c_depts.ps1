#
#
#

$server = 'SQL-01';
$database = 'Reporting';
$csvPath = 'C:\dev\spgr-d3-org-chart\data';


function GetSqlDataSet ([string] $sql , [string] $csvExportPath ) {
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

    #--------------------------------------------------------------------------
    #  MAIN
    #--------------------------------------------------------------------------
    cls;
    $sql = "
    SELECT 
	    [Код_] as id
	    , IIF( [РодительКод] = 0x0, '', CONVERT (nvarchar(100), [РодительКод], 2)) as parentId
	    ,[Подразделение] as department
	    ,[v1СЗУП_РуководителиПодразделений].ФИО as manager
	    ,[v1СЗУП_РуководителиПодразделений].КодФизЛица as managerEid
    FROM
	    [fn1СЗУП_СтруктураПредприятия] (default) [СтруктураПредприятия]
	    LEFT JOIN [v1СЗУП_РуководителиПодразделений] ON [СтруктураПредприятия].Код=v1СЗУП_РуководителиПодразделений.СтруктураПредприятияКод
    ORDER BY
	    [Путь]
    ";
    $ds = GetSqlDataSet -sql $sql  -csvExportPath "$csvPath\departments.csv"
    #$ds.Tables[0] | Export-CSV "$csvPath\departments.csv" -notypeinformation -Encoding UTF8 -Force

    $row_count_sql = $DataSet_dept.Tables.Rows.Count
    for ($i = 0; $i -lt $row_count_sql; $i++) {

        # присваиваем данные столбцов переменным
        $departmentId = $ds.Tables.Rows[$i].id;
        Write-Host "$i = $departmentId";
        #$departmentId = 'A2CF00505601289111E8FEE8322D2240';
        $sql = "SELECT * FROM (
                SELECT
	                'department' as [class]
	                ,Код_ as id
	                ,IIF ([Уровень]=0, NULL, CONVERT(nvarchar(100),РодительКод,2)) as parentId
	                ,Подразделение as [name]
	                ,РУК.ФИО as title
	                ,NULL as isManager
                FROM 
	                [dbo].[fn1СЗУП_СтруктураПредприятия] (0x$departmentId ) СТР
                    LEFT JOIN [v1СЗУП_РуководителиПодразделений] РУК ON РУК.СтруктураПредприятияКод=СТР.Код
	                UNION ALL
                SELECT
	                'employee' as class
	                ,КЛС.КодФизЛица as id
	                ,CONVERT(nvarchar(100), КЛС.ПодразделениеКод, 2) as parentId
	                ,КЛС.ФИО as [name]
	                ,КЛС.Должность as title
	                ,IIF ( КЛС.КодФизЛица=РУК.КодФизЛица, 1, null ) as isManager
                FROM 
	                v1СЗУП_КлассификаторСотрудников_Текущий КЛС
	                LEFT JOIN v1СЗУП_РуководителиПодразделений РУК ON РУК.СтруктураПредприятияКод=КЛС.ПодразделениеКод
                WHERE 
	                [ПодразделениеКод] IN (SELECT [Код] FROM [dbo].[fn1СЗУП_СтруктураПредприятия] ( 0x$departmentId ) ) 
                    AND (РУК.КодФизЛица IS NULL OR КЛС.КодФизЛица<>РУК.КодФизЛица)
                ) as SRC ORDER BY class, name
               ";
        #Write-Host $sql;
        #GetSqlDataSet -sql $sql -csvExportPath "$csvPath\$departmentId.csv"
    }
    #--------------------------------------------------------------------------
    #  все люди
    #--------------------------------------------------------------------------
    $sql = "
        SELECT 
          [КодФизлица] as id
          ,CONVERT(nvarchar(100), [ПодразделениеКод], 2) as parentId
	      ,[ФИО] as [name]
          ,[Подразделение] as department
          ,[Должность] as titel
          ,[СборЗагрузки] as isTimesheet
	      ,[Филиал] as branch
        FROM
	        [v1СЗУП_КлассификаторСотрудников_Текущий]
        ";

    GetSqlDataSet -sql $sql -csvExportPath "$csvPath\staff.csv"
 

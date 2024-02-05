#
#
#

$server = 'SQL-01';
$database = 'Reporting';
$csvPath = 'C:\dev\spgr-d3-org-chart\data';


function GetSqlDataSet ([string] $sql ) {
    $SqlConnection_dept = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection_dept.ConnectionString = "Server=$server;Database=$database;Integrated Security=True"
    $SqlCmd_dept = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd_dept.CommandText = $sql
    $SqlCmd_dept.Connection = $SqlConnection_dept
    $SqlAdapter_dept = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter_dept.SelectCommand = $SqlCmd_dept
    $DataSet_dept = New-Object System.Data.DataSet
    $SqlAdapter_dept.Fill($DataSet_dept)
    $SqlConnection_dept.Close();
    return $DataSet_dept;
}
    cls;
    $sql = "
    SELECT 
	    [Код_] as id
	    , IIF( [РодительКод] = 0x0, '', CONVERT (nvarchar(100), [РодительКод], 2)) as parentId
	    ,[Подразделение] as department
	    ,[v1СЗУП_РуководителиПодразделений].ФИО as manager
	    ,dbo.fnShortFio([v1СЗУП_РуководителиПодразделений].ФИО) as manager_io
    FROM
	    [fn1СЗУП_СтруктураПредприятия] (default) [СтруктураПредприятия]
	    LEFT JOIN [v1СЗУП_РуководителиПодразделений] ON [СтруктураПредприятия].Код=v1СЗУП_РуководителиПодразделений.СтруктураПредприятияКод
    ORDER BY
	    [Путь]
    ";
    $ds = GetSqlDataSet($sql);
    $ds.Tables[0] | Export-CSV "$csvPath\departments.csv" -notypeinformation -Encoding UTF8 -Force

    $row_count_sql = $DataSet_dept.Tables.Rows.Count
    for ($i = 0; $i -lt $row_count_sql; $i++) {

        # присваиваем данные столбцов переменным
        $departmentId = $ds.Tables.Rows[$i].id;
        Write-Host "$i = $departmentId";
        #$departmentId = '0xA2CF00505601289111E8FEE8322D2240';
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
        $dsDept = GetSqlDataSet($sql);
        $dsDept.Tables[0] | Export-CSV "$csvPath\$departmentId.csv" -notypeinformation -Encoding UTF8 -Force
    }



 

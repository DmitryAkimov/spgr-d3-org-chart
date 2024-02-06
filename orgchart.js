//
// Всё взято отсюда https://github.com/bumbeishvili/org-chart?tab=readme-ov-file
//
//=============================================================================

var chart = null;
var chartDetails = null;
var departments; // массив подразделений
var staff; // массив сотрудников
var rootDepartmentId = null ;
//=============================================================================
// Возвращает короткое фио 'Васильев Иван Петрович' -> 'Васильев И.П.';
function shortFio (source) {
    return source.replace(/(.+) (.).+ (.).+/, '$1 $2. $3.');
}
//=============================================================================
function isEmpty( val ) {
    // test results
    //---------------
    // []        true, empty array
    // {}        true, empty object
    // null      true
    // undefined true
    // ""        true, empty string
    // ''        true, empty string
    // 0         false, number
    // true      false, boolean
    // false     false, boolean
    // Date      false
    // function  false

    if (val === undefined)
        return true;

    if (typeof (val) == 'function' || typeof (val) == 'number' || typeof (val) == 'boolean' || Object.prototype.toString.call(val) === '[object Date]')
        return false;

    if (val == null || val.length === 0)        // null or 0 length array
        return true;

    if (typeof (val) == "object") {
        // empty object

        var r = true;

        for (var f in val)
            r = false;

        return r;
    }

    return false;
}
//=============================================================================
function nodeContent(d, i, arr, state) {
//     return `
//     <a href = "department.html?id=${d.data.id}">
//     <div class="department depth${d.depth}" style="height:${d.height}px;width:${d.width}px;">
          
//           <div style="padding:5px; text-align:center">
//                <div class="name"> ${d.data.department} </div>
//                <div class="manager"> ${d.depth > 1 ? shortFio(d.data.manager) : d.data.manager}</div>

//           </div>     
//   </div>
//   </a>
//     `;
    if (d.data.class=="department") {return `
            <div class="card ${d.depth == 0 ? 'text-bg-success' : ''}" style="height:${d.height}px;width:${d.width}px;" > 
    
                <div class="card-header">
                    ${d.data.department}
                </div>
                <div class="card-body">
                    <div class="manager"> ${d.depth > 1 ? shortFio(d.data.manager) : d.data.manager}</div>
                    <!-- <div class=""> ${d.data.id} </div> -->
                </div>
            </div> `;}
    else if (d.data.class=="employee") {return `
            <div " style="height:${d.height}px;width:${d.width}px;" > ${d.data.name}</div>
        `
        };
    };
//=============================================================================
function nodeHeight (d) {
   // console.log (d);
   if (d.depth==0) return 150
   else return 100;
}
// function cloneData (data) {
//     return  {
//         id: data.id,
//         parentId: data.parentId,
//         department: data.department,
//         manager: data.manager
//     }
// }
//=============================================================================
function filterDepartments (arr, rootDeptId) {
    let filteredDept = departments.filter (dept => dept.parentId==rootDeptId );
    filteredDept.forEach ( dept => {
        arr.push (dept );
        filterDepartments(arr, dept.id);
    });

    // departments.forEach( dept => {
    //     if ( dept.id==rootDepartmentId  ) {
    //         let root = { ...dept };
    //         root.parentId = "";
    //         arr.push(  root  );
    //         document.title = root.department;
    //         //staff.filter ( employee => employee.parentId==dept.id).forEach (employee => arr.push(employee));
    //         //filterDepartments (arr, dept.id);
    //     }

    //     else if ( dept.parentId==rootDeptId ) {
    //         arr.push(  dept  );
    //         // фильтруем сотрудников департамента и добавляем к массиву
    //         //staff.filter ( employee => employee.parentId==dept.id).forEach (employee => arr.push(employee));
    //         //let stf = staff.filter ( employee => employee.parentId==dept.id);
    //         //arr = arr.concat (stf);
    //         //if (dept.id != rootDeptId) {   filterDepartments (arr, dept.id); }
    //         filterDepartments (arr, dept.id);
    //     };
    // }); 
    // let filteredStaff = [];
    // arr.forEach (dept => {
    //     if (dept.class=="department"){
    //         staff.filter ( employee => employee.parentId==dept.id && employee.id!=dept.managerEid).forEach (employee => filteredStaff.push(employee));  
    //     }
    // })
    // return arr;
}
//=============================================================================
function filterStaff (data) {
    let filteredStaff = [];
    data.forEach(dept => {
        if (dept.class=="department"){
            staff
                .filter ( employee => employee.parentId==dept.id && employee.id!=dept.managerEid)
                .forEach( employee => data.push(employee));
        }
    }); 
}

//=============================================================================
// function detailOrgchart(rootNodeData){
//     let data = [];
//     root = cloneData(rootNodeData);
//     root.parentId = '';
//     data.push ( root );
//     filterDepartments(data, rootNodeData );
//     chartDetails = new d3.OrgChart()
//     .container(".chart-container-details")
//     .data(data)
//     .nodeHeight(nodeHeight)
//     .nodeContent(nodeContent)
//     .duration(500)
// //    .onNodeClick((d) => {       d._expanded = true; chart.render();console.log(d);} )
//     .render();
// }
//=============================================================================
function onNodeClick (d){
    if (d.data.class=="department") {
        if (d.depth > 0) {
            window.open(`index.html?id=${d.data.id}`, '_blank') ;
        }
    }
}
//=============================================================================
function mainOrgchart(rootDepartmentId=null){
    var data = [];
    chart = new d3.OrgChart()
    .container(".chart-container")
    .duration(500)
    .nodeHeight(nodeHeight)
    .nodeContent(nodeContent)
    .onNodeClick(onNodeClick)

    if ( isEmpty (rootDepartmentId)) {
        data = departments;
         chart   
            .compact(false)

    }
    else {
        filterDepartments(data, rootDepartmentId );

        // добавляем корневой элемент
        departments.filter (dept => dept.id==rootDepartmentId ).forEach (dept => {
            let root = { ...dept };
            root.parentId = "";
            data.push(  root  );
            document.title = root.department; 
        });
        filterStaff(data);
        chart 
            .compact(true)
    }
    chart
        .data(data)
        .render();
}
//=============================================================================
// main
//=============================================================================
rootDepartmentId = window.location.search.replace( '?id=', '');
d3
    .csv ('./data/staff.csv')
    .then ( (data) => {
        data.forEach( item => item.class = 'employee');
        staff = data;
        d3.csv('./data/departments.csv')
        .then((data) => {
            data.forEach( item => item.class = 'department');
            departments = data;
            mainOrgchart(rootDepartmentId);
        })
});

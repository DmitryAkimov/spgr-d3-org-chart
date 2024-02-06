//
// Всё взято отсюда https://github.com/bumbeishvili/org-chart?tab=readme-ov-file
//
//=============================================================================

var chart = null;
var chartDetails = null;
var departments; // массив подразделений
var staff; // массив сотрудников

//=============================================================================
// Возвращает короткое фио 'Васильев Иван Петрович' -> 'Васильев И.П.';
function shortFio (source) {
    return source.replace(/(.+) (.).+ (.).+/, '$1 $2. $3.');
}
//=============================================================================
function renderNode(d, i, arr, state) {
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
function cloneData (data) {
    return  {
        id: data.id,
        parentId: data.parentId,
        department: data.department,
        manager: data.manager
    }
}
//=============================================================================
function filterDepartments (arr, rootNodeData) {
    departments.forEach(element => {
        if ( element.parentId==rootNodeData.id ) {
            arr.push(  element );
            filterDepartments (arr, element);
        };
    }); 
}
//=============================================================================
function filterStaff (data) {
    let filteredStaff = [];
    data.forEach(dept => {
        stf = staff.filter ( employee => employee.parentId==dept.id);
        filteredStaff = filteredStaff.concat (stf);
    }); 
    data = data.concat (filteredStaff);
}

//=============================================================================
function detailOrgchart(rootNodeData){
    let data = [];
    root = cloneData(rootNodeData);
    root.parentId = '';
    data.push ( root );
    filterDepartments(data, rootNodeData );
    chartDetails = new d3.OrgChart()
    .container(".chart-container-details")
    .data(data)
    .nodeHeight(nodeHeight)
    .nodeContent(renderNode)
    .duration(500)
//    .onNodeClick((d) => {       d._expanded = true; chart.render();console.log(d);} )
    .render();
}
//=============================================================================
function mainOrgchart(rootNodeData=null){
    if (rootNodeData===null) {
        data = departments;
        chart = new d3.OrgChart()
        .container(".chart-container")
        .compact(false)
        .data(data)
        .nodeHeight(nodeHeight)
        .nodeContent(renderNode)
        .duration(500)
        .onNodeClick((d) => { if (rootNodeData===null) mainOrgchart (d.data); } )
        .render();
    }
    else {
        let data = [];
        root = cloneData(rootNodeData);
        root.parentId = '';
        data.push ( root );
        filterDepartments(data, rootNodeData );
        filterStaff(data);
        chart
        .data(data)
        .render();
    }

}
//=============================================================================
// main
//=============================================================================
d3
    .csv ('./data/staff.csv')
    .then ( (data) => {
        data.forEach( item => item.class = 'employee');
        staff = data;
        d3.csv('./data/departments.csv')
        .then((data) => {
            data.forEach( item => item.class = 'department');
            departments = data;
            mainOrgchart();
        })
});

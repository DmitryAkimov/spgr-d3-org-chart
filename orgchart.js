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
function filterChart(value) {
    // Get input value
    if (isEmpty(value)) {return;}

    // Clear previous higlighting
    chart.clearHighlighting();

    // Get chart nodes
    const data = chart.data();

    // Mark all previously expanded nodes for collapse
    data.forEach((d) => (d._expanded = false));

    // Loop over data and check if input value matches any name
    data.forEach((d) => {
      if (value != '' && d.name.toLowerCase().includes(value.toLowerCase())) {
        // If matches, mark node as highlighted
        d._highlighted = true;
        d._expanded = true;
      }
    });

    // Update data and rerender graph
    chart.data(data).render().fit();

    console.log('filtering chart', e.srcElement.value);
  }
//=============================================================================
function nodeContent(d, i, arr, state) {
    var nodeClass = "";
    if (d.data.class=="department") {
        hSize = d.depth==0 ? 5 : 7;
        
        if (d.data.level==0) {
            nodeClass = "text-bg-success"; // ГК Спектрум - самый высокий root
        }
        else if (d.depth == 0 ) {
            nodeClass = "bg-warning-subtle"; // первый элемент на детальной диаграмме
        }
        else {
            nodeClass = ""; // обычное подразделение
        }

        return `
            <div class="card text-center department ${nodeClass}" style="height:${d.height}px;width:${d.width}px;" > 
    
                <div class="card-header">
                    <span>${d.data.department}</span>
                </div>
                <div class="card-body">
                    
                    <h${hSize} class="manager text-truncate"> ${d.depth > 1 ? shortFio(d.data.manager) : d.data.manager}</${hSize}>
                    <!-- <div class=""> ${d.data.id} </div> -->
                    
                </div>
            </div> `
            ;}

    else if (d.data.class=="employee") {
        let branchClass = "bg-secondary";
        switch (String(d.data.branch).toUpperCase()) {
            case "МСК":
                branchClass="bg-success-subtle"; break;
            case "СПБ":
                branchClass="bg-primary-subtle"; break;
            case "НСК":
                branchClass="bg-warning-subtle"; break;
          }
        branchClass += " text-secondary";
        return `
            <div class="card text-center employee rounded-4 position-relative" style="height:${d.height}px;width:${d.width}px;" data-bs-toggle="tooltip" data-bs-title="Tooltip on top">
                <div class="position-absolute top-50 start-50 translate-middle w-100"> 
                    <div class="name text-truncate mx-2">  ${d.data.name} </div>
                    <div class="title fst-italic text-body-secondary text-truncate mt-1 mx-2">  ${d.data.title} </div>
                </div>

                <div class="badge position-absolute ${branchClass} top-100 start-100 translate-middle"  style="width:3.5em;">${d.data.branch}</div>
                
             </div>
        `
        };
    };
//=============================================================================
function nodeHeight (d) {
    if (d.data.class=="department") {
        if (d.depth==0) return 100
        else return 100;
    }
    else if (d.data.class=="employee") {
        return 50;
    }
}

//=============================================================================
function nodeWidth (d) {
    if (d.data.class=="department") {
        if (d.depth==0) return 350
        else return 250;
    }
    else if (d.data.class=="employee") {
        return 200;
    }
}
//=============================================================================
function filterDepartments (arr, rootDeptId) {
    let filteredDept = departments.filter (dept => dept.parentId==rootDeptId );
    filteredDept.forEach ( dept => {
        arr.push (dept );
        filterDepartments(arr, dept.id);
    });
  
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
function onNodeClick (d){
    if (d.data.class=="department") {
        if (d.depth > 0) {
            window.open(`index.html?id=${d.data.id}`, '_blank') ;
        }
    } else if (d.data.class=="employee" && "bitrixUserUrl" in d.data) {
        window.open(`${d.data.bitrixUserUrl}`, '_blank') ;
    }

}
//=============================================================================
function drawOrgchart(rootDepartmentId=null){
    var data = [];
    chart = new d3.OrgChart()
    .container(".chart-container")
    .duration(500)
    .nodeHeight(nodeHeight)
    .nodeWidth(nodeWidth)
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
// инициализируем подсказки https://getbootstrap.com/docs/5.3/components/tooltips/
const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl))
//
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
            drawOrgchart(rootDepartmentId);
        })
});
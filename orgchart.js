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
function testExpand() {
    let deptId = "A2CF00505601289111E8FEE79511A735";
    chart.data().forEach (item => {
        if (item.class=="department" && item.id==deptId) {

        }
    });
    chart.setExpanded(deptId).setCentered(deptId).render()
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
    let upLink =""
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
        if (d.data.level!=0 && d.depth==0) {
            upLink = `
                <div class="position-absolute top-50 start-100 translate-middle mx-4">
                    <a href="/?id=${d.data.rawParentId}" class="h1" title="Перейти на уровень выше">
                        <i class="bi bi-arrow-up-circle-fill text-secondary"></i>
                    </a>
                </div>
            `;
        }
        return `
            <div class="card text-center department ${nodeClass}" style="height:${d.height}px;width:${d.width}px; id="d_${d.data.id}" > 
                
                <div class="card-header" style="min-height:3.5em;" >
                    <span >${d.data.department}</span> ${upLink}
                </div>
                <div class="card-body position-relative">
                    <div class="position-absolute top-50 start-50 translate-middle w-100"> 
                    <h${hSize} class="manager text-truncate"> ${d.depth > 1 ? shortFio(d.data.manager) : d.data.manager}</${hSize}>
                    <!-- <div class=""> ${d.data.id} </div> -->
                    </div>
                </div>
            </div> `
            ;}

    else if (d.data.class=="employee") {
        let branchClass = "bg-secondary-subtle";
        let remotelySvg = ""
        switch (String(d.data.branch).toUpperCase()) {
            case "МСК":
                branchClass="bg-success-subtle"; break;
            case "СПБ":
                branchClass="bg-primary-subtle"; break;
            case "НСК":
                branchClass="bg-warning-subtle"; break;
          }
        branchClass += " text-secondary";
        tooltip = `${d.data.name}\n${d.data.title}\n${d.data.branch}\n${d.data.physicalDeliveryOfficeName}\n${d.data.id}\n`;
        if ("worksRemotely" in d.data && String(d.data.worksRemotely).toUpperCase()=="TRUE") {
            tooltip += `\nДистанционно ${String(d.data.remoteWorkMode)}`;
            remotelySvg =`
            <div  class="homeuser position-absolute top-0 start-100 translate-middle" style="width:2em;">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 576 512"><!--!Font Awesome Free 6.5.1 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2024 Fonticons, Inc.--><path opacity="0.5" d="M575.8 255.5c0 18-15 32.1-32 32.1h-32l.7 160.2c.2 35.5-28.5 64.3-64 64.3H128.1c-35.3 0-64-28.7-64-64V287.6H32c-18 0-32-14-32-32.1c0-9 3-17 10-24L266.4 8c7-7 15-8 22-8s15 2 21 7L564.8 231.5c8 7 12 15 11 24zM352 224a64 64 0 1 0 -128 0 64 64 0 1 0 128 0zm-96 96c-44.2 0-80 35.8-80 80c0 8.8 7.2 16 16 16H384c8.8 0 16-7.2 16-16c0-44.2-35.8-80-80-80H256z"/></svg>
            </div>`;
        }
        return `
            <div class="card text-center employee rounded-4 position-relative ${nodeClass}" style="height:${d.height}px;width:${d.width}px;" data-bs-toggle="tooltip" title="${tooltip}" data-bs-placement="top">
                <div class="position-absolute top-50 start-50 translate-middle w-100"> 
                    <div class="name text-truncate mx-2">  ${d.data.name} </div>
                    <div class="title fst-italic text-body-secondary text-truncate mt-1 mx-2">  ${d.data.title} </div>
                </div>

                <div class="badge position-absolute ${branchClass} top-100 start-100 translate-middle"  style="width:3.5em;">${d.data.branch}</div>
                ${remotelySvg}
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
            //window.open(`/?id=${d.data.id}`) ;
            document.location.href = `/?id=${d.data.id}`;
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
            data.forEach( item => { item.class = 'department'; item.rawParentId=item.parentId });
            departments = data;
            drawOrgchart(rootDepartmentId);
        })
});
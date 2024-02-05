//
// Всё взято отсюда https://github.com/bumbeishvili/org-chart?tab=readme-ov-file
//
//=============================================================================

var chart;

//=============================================================================
// Возвращает короткое фио 'Васильев Иван Петрович' -> 'Васильев И.П.';
function shortFio (source) {
    return source.replace(/(.+) (.).+ (.).+/, '$1 $2. $3.');
}
//=============================================================================
function renderDept(d, i, arr, state) {
    return `
    <a href = "department.html?id=${d.data.id}">
    <div class="department depth${d.depth}" style="height:${d.height}px;width:${d.width}px;">
          
          <div style="padding:5px; text-align:center">
               <div class="name"> ${d.data.department} </div>
               <div class="manager"> ${d.depth > 1 ? shortFio(d.data.manager) : d.data.manager}</div>

          </div>     
  </div>
  </a>
`
};
//=============================================================================
function nodeHeight (d) {
   // console.log (d);
   if (d.depth==0) return 150
   else return 100;
}
//=============================================================================
// main
//=============================================================================
d3
    //.csv( "dpt.csv" )  //  "https://raw.githubusercontent.com/bumbeishvili/sample-data/main/org.csv"
    .csv('./data/departments.csv')
    .then((data) => {
        chart = new d3.OrgChart()
            .container(".chart-container")
            .compact(false)
            .data(data)
            .nodeHeight(nodeHeight)
            .nodeContent(renderDept)
            .duration(500)
            .render();
    });

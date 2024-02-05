//
// Всё взято отсюда https://github.com/bumbeishvili/org-chart?tab=readme-ov-file
//
//=============================================================================

var chart;

//=============================================================================
function renderDept(d, i, arr, state) {
    return `
    <div class="department depth${d.depth}" style="height:${d.height}px;width:${d.width}px;">
          
          <div style="padding:20px; text-align:center">
               <div class="name"> ${d.data.department} </div>
               <!--<div class="name"> Руководитель Ф.И. </div> -->

          </div>     
  </div>
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
    .csv('departments.csv')
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

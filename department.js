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
function renderNode(d, i, arr, state) {
    if (d.data.class=="department"){
        return `
        <div class="${d.data.class}  ${d.depth==0 ? 'depth0' : ''}" style="height:${d.height}px;width:${d.width}px;">
            
            <div style="padding:5px; text-align:center">
                <div class="name"> ${d.data.name} </div>
                <div class="manager"> ${d.data.title}</div>
            </div>     
        </div>
        `}
    else {return `
            <div class="${d.data.class} style="height:${d.height}px;width:${d.width}px;> 
            <div style="padding:5px; text-align:center">
                <div class="name"> ${d.data.name} </div>
                <div class="title"> ${d.data.title}</div>
            </div>  
            </div>`;}
};
//=============================================================================
function nodeHeight (d) {
   // console.log (d);
//    if (d.depth==0) return 150
//    else return 100;
    return (d.data.class=="department") ? 100 : 75;
}
//=============================================================================
// main
//=============================================================================
const departmentId =  window.location.search.replace( '?id=', ''); 
d3
    //.csv( "dpt.csv" )  //  "https://raw.githubusercontent.com/bumbeishvili/sample-data/main/org.csv"
    .csv(`./data/${departmentId}.csv`)
    .then((data) => {
        //console.log(data);
        chart = new d3.OrgChart()
            .container(".chart-container")
            .compact(true)
            .data(data)
            .nodeHeight(nodeHeight)
            .nodeContent(renderNode)
            .duration(500)
            .render();
    });

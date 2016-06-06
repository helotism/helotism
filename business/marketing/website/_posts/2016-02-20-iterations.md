---
layout: post
title:  "Roadmap"
date:   2016-02-20 00:00:00
permalink: /roadmap.html
---

<link rel="stylesheet" type="text/css" href="/business/marketing/website/assets/DataTables/datatables.min.css"/>

<script src="{{ "/business/marketing/website/assets/DataTables/datatables.min.js" | prepend: site.baseurl }}"></script>
<script src="{{ "/business/marketing/website/assets/js/d3.v3.min.js" | prepend: site.baseurl }}"></script>

<script>


$(document).ready(function() {
    d3.text('{{ "/business/planning/roadmap.csv" | prepend: site.baseurl }}', function (datasetText) {
  var rows = d3.csv.parseRows(datasetText);

  var tbl = d3.select("#roadmapcontainer")
    .append("table")
    .attr("class", "display")
    .attr("id","tableID");


// headers
  tbl.append("thead").append("tr")
    .selectAll("th")
    .data(rows[0])
    .enter().append("th")
    .text(function(d) {
        return d;
    });

   // data
    tbl.append("tbody")
    .selectAll("tr").data(rows.slice(1))
    .enter().append("tr")

    .selectAll("td")
    .data(function(d){return d;})
    .enter().append("td")
    .text(function(d){return d;})
        $('#tableID').dataTable( {
      paging: false,
      responsive: true,
    columnDefs: [
        { responsivePriority: 0, targets: 0 },
        { responsivePriority: 2, targets: -1 },
        { "visible": false, targets: -2 },
        { "visible": false, targets: -3 },
        { "visible": false, targets: -4 },
        { "visible": false, targets: 2 },
        { "visible": false, targets: 3 }
    ]
    } );
    });
});

</script>



<div id="roadmapcontainer"></div>

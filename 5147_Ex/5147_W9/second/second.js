window.onload = function() {

    const svgCanvas = d3.select("svg")
        .attr("width", 960)
        .attr("height", 540)
        .attr("class", "svgCanvas");

    svgCanvas.append("rect")
        .attr("x", 100)
        .attr("y", 100)
        .attr("width", 100)
        .attr("height", 50);
}
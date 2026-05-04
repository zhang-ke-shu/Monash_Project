// window.onload = function() {
 
//     d3.csv("third.csv").then(function(d) {
//         console.log(d);
//     });
// }
window.onload = function() {
 
    const svgCanvas = d3.select("svg")
        .attr("width", 960)
        .attr("height", 540)
        .attr("class", "svgCanvas");
 
    d3.csv("third.csv").then(function(d) {
        console.log(d);
        
        let minValue = Infinity;
        let maxValue = -1;
        d.forEach(function(thisD) {
            let thisValue = thisD["value"];
            minValue = Math.min(minValue, thisValue);
            maxValue = Math.max(maxValue, thisValue);
        });

        // create a function to scale the data to the range of values for the color
        let value2range = d3.scaleLinear()
            .domain([minValue, maxValue])
            .range([0.5, 1]);
 
        let range2color = d3.interpolateBlues;

        svgCanvas.selectAll("circle")
            .data(d)
            .join("circle")
            .attr("cx", function(thisElement, index) {
                return 150 + index * 150;
            })
            .attr("cy", 300)
            .attr("r", function(thisElement) {
                return thisElement["value"];
            })
            .attr("fill", function(thisElement) {
                return range2color(value2range(thisElement["value"])); // map the color to the value
            })
            .on("mouseover", function() {
                svgCanvas.selectAll("circle")
                    .attr("opacity", 0.5); // grey out all circles
                d3.select(this) // highlight the circle the mouse is hovering on
                    .attr("opacity", 1);
            })
            .on("mouseout", function() {
                // restore all circles to normal mode
                svgCanvas.selectAll("circle")
                    .attr("opacity", 1);
            });

        // add a label above  
        svgCanvas.selectAll("text")
            .data(d)
            .join("text")
            .attr("x", function(thisElement, index) {
                return 150 + index * 150;
            })
            .attr("y", 300 - 35)
            .attr("text-anchor", "middle")
            .text(function(thisElement) {
                return thisElement["title"] + ": " + thisElement["value"]
            }); 
    });
}
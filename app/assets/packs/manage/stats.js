
const d3Selection = require('d3-selection');
import bar from 'britecharts/dist/umd/bar.min';
import heatmap from 'britecharts/dist/umd/heatmap.min';
import { map } from 'lodash';



// function getLegendChart(target, dataset, optionalColorSchema) {
//   var legendChart = legend(),
//   legendContainer = d3Selection.select(target + '-legend'),
//   containerWidth = legendContainer.node() ? legendContainer.node().getBoundingClientRect().width : false;

//   if (containerWidth) {
//     // d3Selection.select(target + '-legend').remove();

//     legendChart
//     .width(containerWidth*0.8)
//     .height(200)
//     .numberFormat('.2s');

//     if (optionalColorSchema) {
//       legendChart.colorSchema(optionalColorSchema);
//     }

//     legendContainer.datum(dataset).call(legendChart);

//     return legendChart;
//   }
// }

export function createHeatmapChart(elt, data) {
  const hmChart = heatmap(),
    hmContainer = d3Selection.select(elt)

  hmChart
    .boxSize(30);

  hmContainer.datum(data).call(hmChart);
}

export function createBarChart(elt, data) {

  const barChart = bar(),
    barContainer = d3Selection.select(elt),
    containerWidth = barContainer.node() ? barContainer.node().getBoundingClientRect().width : false

  console.log({
    containerWidth
  });
  
  barChart
    .width(containerWidth)
    .enableLabels(true)
    .labelsNumberFormat('.2s')
    .height(300);

  barContainer.datum(data).call(barChart);
}


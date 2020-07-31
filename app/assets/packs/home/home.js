
const d3Selection = require('d3-selection');
import donut from 'britecharts/dist/umd/donut.min';
import legend from 'britecharts/dist/umd/legend.min';
import { map } from 'lodash';


function datasetForData(data) {
  var i = 0
  return map(data, (v, k) => {
    return {
      name: k,
      quantity: v,
      id: i++
    }
  });
}

function getLegendChart(target, dataset, optionalColorSchema) {
  var legendChart = legend(),
  legendContainer = d3Selection.select(target + '-legend'),
  containerWidth = legendContainer.node() ? legendContainer.node().getBoundingClientRect().width : false;

  if (containerWidth) {
    // d3Selection.select(target + '-legend').remove();

    legendChart
    .width(containerWidth*0.8)
    .height(200)
    .numberFormat('.2s');

    if (optionalColorSchema) {
      legendChart.colorSchema(optionalColorSchema);
    }

    legendContainer.datum(dataset).call(legendChart);

    return legendChart;
  }
}

function createDonutChart(elt, data) {
  const dataset = datasetForData(data)

  const donutChart = donut(),
    donutContainer = d3Selection.select(elt),
    containerWidth = donutContainer.node() ? donutContainer.node().getBoundingClientRect().width : false,
    legendChart = getLegendChart(elt, dataset)

  console.log({
    containerWidth
  });
  
  donutChart
    .isAnimated(true)
    .highlightSliceById(2)
    .width(containerWidth)
    .height(containerWidth)
    .externalRadius(containerWidth/2.5)
    .internalRadius(containerWidth/5)
    .on('customMouseOver', function(d) {
      console.log(d.data);
      window.lg = legendChart
      legendChart.highlight(d.data.id);
    })
    .on('customMouseOut', function() {
      legendChart.clearHighlight();
    });
  donutContainer.datum(dataset).call(donutChart);
}

document.addEventListener('DOMContentLoaded', () => {
  if (document.querySelectorAll("#persp-chart").length > 0) {
    createDonutChart('#persp-chart', persp)
  }
})

$(document).ready(function(){

    new Chartist.Line('#my-chart', {
        labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
        series: [
            gon.chart_year[2016],
            gon.chart_year[2017],
        ]
    }, {
        fullWidth: true,
        chartPadding: {
            right: 40
        }
    });
})
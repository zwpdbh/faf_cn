import * as echarts from 'echarts';

export default {
  mounted() {
    this.chart = echarts.init(this.el, null, { renderer: 'svg' });
    this.setupChart();
    
    // Handle window resize
    this.resizeHandler = () => this.chart.resize();
    window.addEventListener('resize', this.resizeHandler);
    
    // Listen for chart data events from server
    this.handleEvent('chart-data', (payload) => {
      this.updateChart(payload);
    });
    
    // Initial render
    this.updateChart({ time: [], mass: [], energy: [], build_power: [], show_mass: true, show_energy: true, show_build_power: true });
  },
  
  setupChart() {
    const option = {
      title: {
        text: 'Eco Over Time',
        left: 'center',
        textStyle: { fontSize: 16, fontWeight: 'bold' }
      },
      tooltip: {
        trigger: 'axis',
        axisPointer: { type: 'cross' },
        formatter: function(params) {
          let result = `<strong>Time: ${params[0].axisValue}s</strong><br/>`;
          params.forEach(param => {
            result += `${param.marker} ${param.seriesName}: ${Math.round(param.value)}<br/>`;
          });
          return result;
        }
      },
      legend: {
        data: ['Mass', 'Energy', 'Build Power'],
        bottom: 0,
        show: false
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '10%',
        top: '15%',
        containLabel: true
      },
      xAxis: {
        type: 'category',
        name: 'Time (seconds)',
        nameLocation: 'middle',
        nameGap: 30,
        boundaryGap: false,
        data: []
      },
      yAxis: {
        type: 'value',
        name: 'Amount'
      },
      series: [
        {
          name: 'Mass',
          type: 'line',
          smooth: true,
          symbol: 'none',
          data: [],
          lineStyle: { color: '#10b981', width: 3 },
          itemStyle: { color: '#10b981' },
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(16, 185, 129, 0.3)' },
              { offset: 1, color: 'rgba(16, 185, 129, 0.05)' }
            ])
          }
        },
        {
          name: 'Energy',
          type: 'line',
          smooth: true,
          symbol: 'none',
          data: [],
          lineStyle: { color: '#f59e0b', width: 2 },
          itemStyle: { color: '#f59e0b' }
        },
        {
          name: 'Build Power',
          type: 'line',
          smooth: true,
          symbol: 'none',
          data: [],
          lineStyle: { color: '#3b82f6', width: 2, type: 'dashed' },
          itemStyle: { color: '#3b82f6' }
        }
      ],
      animation: false
    };
    
    this.chart.setOption(option);
  },
  
  updateChart(data) {
    const timeData = data.time || [];
    const massData = data.mass || [];
    const energyData = data.energy || [];
    const buildPowerData = data.build_power || [];
    const showMass = data.show_mass !== false;
    const showEnergy = data.show_energy !== false;
    const showBuildPower = data.show_build_power !== false;
    

    
    // If no data, show default sample data
    if (timeData.length === 0) {
      this.chart.setOption({
        xAxis: { data: [1, 2, 3, 4, 5] },
        series: [
          { name: 'Mass', data: [650, 654, 658, 662, 666] },
          { name: 'Energy', data: [2500, 2500, 2500, 2500, 2500] },
          { name: 'Build Power', data: [10, 10, 10, 10, 10] }
        ]
      });
      return;
    }
    
    // Update with real data
    this.chart.setOption({
      xAxis: { data: timeData },
      series: [
        { name: 'Mass', data: showMass ? massData : [] },
        { name: 'Energy', data: showEnergy ? energyData : [] },
        { name: 'Build Power', data: showBuildPower ? buildPowerData : [] }
      ]
    });
  },
  
  destroyed() {
    window.removeEventListener('resize', this.resizeHandler);
    if (this.chart) {
      this.chart.dispose();
    }
  }
};

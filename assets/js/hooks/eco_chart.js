import * as echarts from 'echarts';

export default {
  mounted() {
    this.chart = echarts.init(this.el, null, {
      renderer: 'svg'
    });
    
    this.updateChart();
    
    // Handle window resize
    this.resizeHandler = () => this.chart.resize();
    window.addEventListener('resize', this.resizeHandler);
  },
  
  updated() {
    this.updateChart();
  },
  
  updateChart() {
    // Parse data from data attributes
    const timeData = JSON.parse(this.el.dataset.time || '[]');
    const massData = JSON.parse(this.el.dataset.mass || '[]');
    const energyData = JSON.parse(this.el.dataset.energy || '[]');
    const buildPowerData = JSON.parse(this.el.dataset.buildPower || '[]');
    
    const option = {
      title: {
        text: 'Eco Prediction',
        left: 'center',
        textStyle: {
          fontSize: 18,
          fontWeight: 'bold'
        }
      },
      tooltip: {
        trigger: 'axis',
        axisPointer: {
          type: 'cross'
        },
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
        bottom: 0
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
        data: timeData,
        axisLine: {
          lineStyle: {
            color: '#666'
          }
        }
      },
      yAxis: {
        type: 'value',
        name: 'Amount',
        axisLine: {
          lineStyle: {
            color: '#666'
          }
        },
        splitLine: {
          lineStyle: {
            color: '#eee'
          }
        }
      },
      series: [
        {
          name: 'Mass',
          type: 'line',
          smooth: true,
          symbol: 'none',
          data: massData,
          lineStyle: {
            color: '#10b981',
            width: 3
          },
          itemStyle: {
            color: '#10b981'
          },
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
          data: energyData,
          lineStyle: {
            color: '#f59e0b',
            width: 2
          },
          itemStyle: {
            color: '#f59e0b'
          }
        },
        {
          name: 'Build Power',
          type: 'line',
          smooth: true,
          symbol: 'none',
          data: buildPowerData,
          lineStyle: {
            color: '#3b82f6',
            width: 2,
            type: 'dashed'
          },
          itemStyle: {
            color: '#3b82f6'
          }
        }
      ],
      animation: true,
      animationDuration: 500
    };
    
    this.chart.setOption(option);
  },
  
  destroyed() {
    window.removeEventListener('resize', this.resizeHandler);
    if (this.chart) {
      this.chart.dispose();
    }
  }
};

import * as echarts from 'echarts';

export default {
  mounted() {
    console.log('[EcoChart] mounted', { width: this.el.clientWidth, height: this.el.clientHeight });
    
    // Check if element has dimensions
    if (this.el.clientWidth === 0 || this.el.clientHeight === 0) {
      console.error('[EcoChart] Chart container has no dimensions!');
    }
    
    this.chart = echarts.init(this.el, null, {
      renderer: 'svg'
    });
    
    console.log('[EcoChart] echarts initialized');
    
    this.setupChart();
    this.updateChart();
    
    // Force a resize after a short delay to ensure container has dimensions
    setTimeout(() => {
      console.log('[EcoChart] resizing chart');
      this.chart.resize();
    }, 100);
    
    // Handle window resize
    this.resizeHandler = () => this.chart.resize();
    window.addEventListener('resize', this.resizeHandler);
  },
  
  updated() {
    console.log('[EcoChart] updated', {
      time: this.el.dataset.time,
      mass: this.el.dataset.mass,
      energy: this.el.dataset.energy,
      buildPower: this.el.dataset.buildPower
    });
    this.updateChart();
  },
  
  setupChart() {
    const option = {
      title: {
        text: 'Eco Over Time',
        left: 'center',
        textStyle: {
          fontSize: 16,
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
        bottom: 0,
        show: false  // We use custom legend
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
      animation: false  // We handle animation manually for real-time
    };
    
    this.chart.setOption(option);
  },
  
  updateChart() {
    // Parse data from data attributes
    const timeData = JSON.parse(this.el.dataset.time || '[]');
    const massData = JSON.parse(this.el.dataset.mass || '[]');
    const energyData = JSON.parse(this.el.dataset.energy || '[]');
    const buildPowerData = JSON.parse(this.el.dataset.buildPower || '[]');
    
    console.log('[EcoChart] Raw dataset:', {
      time: this.el.dataset.time,
      mass: this.el.dataset.mass,
      energy: this.el.dataset.energy,
      buildPower: this.el.dataset.buildPower
    });
    
    console.log('[EcoChart] Parsed data:', { 
      timeData, massData, energyData, buildPowerData,
      timeDataLength: timeData.length,
      massDataLength: massData.length,
      firstMass: massData[0],
      firstTime: timeData[0]
    });
    
    // Parse visibility toggles
    const showMass = this.el.dataset.showMass === 'true';
    const showEnergy = this.el.dataset.showEnergy === 'true';
    const showBuildPower = this.el.dataset.showBuildPower === 'true';
    
    console.log('[EcoChart] visibility:', { showMass, showEnergy, showBuildPower });
    
    // DEBUG: If no data, use fixed data for comparison
    if (timeData.length === 0) {
      console.log('[EcoChart] No data, using fixed test data');
      this.chart.setOption({
        xAxis: { data: [1, 2, 3, 4, 5] },
        series: [
          { name: 'Mass', type: 'line', data: [100, 150, 200, 250, 300] },
          { name: 'Energy', type: 'line', data: [1000, 1100, 1200, 1300, 1400] },
          { name: 'Build Power', type: 'line', data: [10, 15, 20, 25, 30] }
        ]
      });
      return;
    }
    
    const option = {
      xAxis: {
        data: timeData
      },
      series: [
        {
          name: 'Mass',
          type: 'line',
          data: showMass ? massData : [],
          lineStyle: { opacity: showMass ? 1 : 0 },
          areaStyle: { opacity: showMass ? 1 : 0 }
        },
        {
          name: 'Energy',
          type: 'line',
          data: showEnergy ? energyData : [],
          lineStyle: { opacity: showEnergy ? 1 : 0 }
        },
        {
          name: 'Build Power',
          type: 'line',
          data: showBuildPower ? buildPowerData : [],
          lineStyle: { opacity: showBuildPower ? 1 : 0 }
        }
      ]
    };
    
    console.log('[EcoChart] calling setOption with dynamic data:', option);
    this.chart.setOption(option);
    console.log('[EcoChart] setOption done');
  },
  
  destroyed() {
    window.removeEventListener('resize', this.resizeHandler);
    if (this.chart) {
      this.chart.dispose();
    }
  }
};

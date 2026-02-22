import * as echarts from 'echarts';

export default {
  mounted() {
    requestAnimationFrame(() => {
      this.initChart();
    });
  },

  updated() {
    if (this.chart) {
      this.renderChart();
    } else {
      this.initChart();
    }
  },

  initChart() {
    try {
      const rect = this.el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) {
        setTimeout(() => this.initChart(), 100);
        return;
      }

      if (this.chart) {
        this.chart.dispose();
      }

      this.chart = echarts.init(this.el, null, {
        renderer: 'canvas',
        useDirtyRect: false
      });

      this.resizeHandler = () => {
        if (this.chart) this.chart.resize();
      };
      window.addEventListener('resize', this.resizeHandler);

      this.renderChart();
    } catch (error) {
      console.error('EcoChart: Failed to initialize:', error);
    }
  },

  renderChart() {
    if (!this.chart) return;

    try {
      const view = this.el.dataset.view || 'mass';
      const massIncome = parseFloat(this.el.dataset.massIncome) || 10;
      const energyIncome = parseFloat(this.el.dataset.energyIncome) || 100;
      const completionTime = parseInt(this.el.dataset.completionTime) || 300;
      const goalMass = parseInt(this.el.dataset.goalMass) || 1000;
      const goalEnergy = parseInt(this.el.dataset.goalEnergy) || 5000;

      if (view === 'mass') {
        this.setupMassChart(massIncome, completionTime, goalMass, goalEnergy);
      } else {
        this.setupEnergyChart(energyIncome, completionTime, goalEnergy, goalMass);
      }
    } catch (error) {
      console.error('EcoChart: Failed to render:', error);
    }
  },

  setupMassChart(income, completionTime, goalMass, goalEnergy) {
    const { timeData, valueData } = this.generateData(income, completionTime);
    
    // Ensure Y-axis includes the goal value
    const maxDataValue = Math.max(...valueData, goalMass);
    const yAxisMax = Math.ceil(maxDataValue * 1.1); // Add 10% padding

    const option = {
      title: {
        text: 'Goal Mass: ' + goalMass.toLocaleString(),
        subtext: 'Goal Energy: ' + goalEnergy.toLocaleString(),
        left: 'center',
        top: 5,
        textStyle: {
          color: '#3b82f6',
          fontSize: 14,
          fontWeight: 'bold'
        },
        subtextStyle: {
          color: '#eab308',
          fontSize: 12
        }
      },
      tooltip: {
        trigger: 'axis',
        backgroundColor: 'rgba(255, 255, 255, 0.95)',
        borderColor: '#e5e7eb',
        textStyle: { color: '#374151' },
        formatter: (params) => {
          const time = parseInt(params[0].axisValue);
          const value = Math.round(params[0].value).toLocaleString();
          return `<div style="font-weight:600">${this.formatTime(time)}</div>
                  <div style="color:#3b82f6">Mass: ${value}</div>`;
        }
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '10%',
        top: '20%',
        containLabel: true
      },
      xAxis: {
        type: 'category',
        name: 'Time',
        nameLocation: 'middle',
        nameGap: 25,
        boundaryGap: false,
        data: timeData,
        axisLine: { lineStyle: { color: '#d1d5db' } },
        axisLabel: {
          color: '#6b7280',
          formatter: (value) => this.formatTime(parseInt(value)),
          interval: Math.floor(timeData.length / 6)
        }
      },
      yAxis: {
        type: 'value',
        name: 'Accumulated Mass',
        nameLocation: 'middle',
        nameGap: 45,
        nameTextStyle: { color: '#6b7280' },
        min: 0,
        max: yAxisMax,
        axisLine: { show: false },
        axisTick: { show: false },
        axisLabel: {
          color: '#6b7280',
          formatter: (value) => this.formatValue(value)
        },
        splitLine: { lineStyle: { color: '#f3f4f6', type: 'dashed' } }
      },
      series: [{
        name: 'Mass',
        type: 'line',
        smooth: true,
        symbol: 'none',
        data: valueData,
        lineStyle: { color: '#3b82f6', width: 3 },
        itemStyle: { color: '#3b82f6' },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(59, 130, 246, 0.3)' },
            { offset: 1, color: 'rgba(59, 130, 246, 0.05)' }
          ])
        },
        markLine: {
          silent: true,
          symbol: ['none', 'arrow'],
          symbolSize: 8,
          lineStyle: { color: '#3b82f6', type: 'dashed', width: 2 },
          label: {
            formatter: 'Goal Mass: {c}',
            position: 'end',
            color: '#3b82f6',
            fontWeight: 'bold'
          },
          data: [{ yAxis: goalMass }]
        }
      }],
      animation: true,
      animationDuration: 600
    };

    this.chart.setOption(option, true);
    this.chart.resize();
  },

  setupEnergyChart(income, completionTime, goalEnergy, goalMass) {
    const { timeData, valueData } = this.generateData(income, completionTime);
    
    // Ensure Y-axis includes the goal value
    const maxDataValue = Math.max(...valueData, goalEnergy);
    const yAxisMax = Math.ceil(maxDataValue * 1.1); // Add 10% padding

    const option = {
      title: {
        text: 'Goal Energy: ' + goalEnergy.toLocaleString(),
        subtext: 'Goal Mass: ' + goalMass.toLocaleString(),
        left: 'center',
        top: 5,
        textStyle: {
          color: '#eab308',
          fontSize: 14,
          fontWeight: 'bold'
        },
        subtextStyle: {
          color: '#3b82f6',
          fontSize: 12
        }
      },
      tooltip: {
        trigger: 'axis',
        backgroundColor: 'rgba(255, 255, 255, 0.95)',
        borderColor: '#e5e7eb',
        textStyle: { color: '#374151' },
        formatter: (params) => {
          const time = parseInt(params[0].axisValue);
          const value = Math.round(params[0].value).toLocaleString();
          return `<div style="font-weight:600">${this.formatTime(time)}</div>
                  <div style="color:#eab308">Energy: ${value}</div>`;
        }
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '10%',
        top: '20%',
        containLabel: true
      },
      xAxis: {
        type: 'category',
        name: 'Time',
        nameLocation: 'middle',
        nameGap: 25,
        boundaryGap: false,
        data: timeData,
        axisLine: { lineStyle: { color: '#d1d5db' } },
        axisLabel: {
          color: '#6b7280',
          formatter: (value) => this.formatTime(parseInt(value)),
          interval: Math.floor(timeData.length / 6)
        }
      },
      yAxis: {
        type: 'value',
        name: 'Accumulated Energy',
        nameLocation: 'middle',
        nameGap: 50,
        nameTextStyle: { color: '#6b7280' },
        min: 0,
        max: yAxisMax,
        axisLine: { show: false },
        axisTick: { show: false },
        axisLabel: {
          color: '#6b7280',
          formatter: (value) => this.formatValue(value)
        },
        splitLine: { lineStyle: { color: '#f3f4f6', type: 'dashed' } }
      },
      series: [{
        name: 'Energy',
        type: 'line',
        smooth: true,
        symbol: 'none',
        data: valueData,
        lineStyle: { color: '#eab308', width: 3 },
        itemStyle: { color: '#eab308' },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(234, 179, 8, 0.3)' },
            { offset: 1, color: 'rgba(234, 179, 8, 0.05)' }
          ])
        },
        markLine: {
          silent: true,
          symbol: ['none', 'arrow'],
          symbolSize: 8,
          lineStyle: { color: '#eab308', type: 'dashed', width: 2 },
          label: {
            formatter: 'Goal Energy: {c}',
            position: 'end',
            color: '#eab308',
            fontWeight: 'bold'
          },
          data: [{ yAxis: goalEnergy }]
        }
      }],
      animation: true,
      animationDuration: 600
    };

    this.chart.setOption(option, true);
    this.chart.resize();
  },

  generateData(income, completionTime) {
    const timeData = [];
    const valueData = [];
    const numPoints = Math.min(100, Math.max(20, completionTime));
    const step = completionTime / numPoints;

    for (let i = 0; i <= numPoints; i++) {
      const t = Math.round(i * step);
      timeData.push(t);
      valueData.push(Math.round(income * t));
    }

    if (timeData[timeData.length - 1] !== completionTime) {
      timeData.push(completionTime);
      valueData.push(Math.round(income * completionTime));
    }

    return { timeData, valueData };
  },

  formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    if (secs === 0) return `${mins}m`;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  },

  formatValue(value) {
    if (value >= 1000000) return (value / 1000000).toFixed(1) + 'M';
    if (value >= 1000) return (value / 1000).toFixed(1) + 'k';
    return value;
  },

  destroyed() {
    window.removeEventListener('resize', this.resizeHandler);
    if (this.chart) {
      this.chart.dispose();
      this.chart = null;
    }
  }
};

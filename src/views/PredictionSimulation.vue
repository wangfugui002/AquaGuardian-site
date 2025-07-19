<template>
  <div class="prediction-simulation-container">
    <prediction-simulation-header title="预测模拟"></prediction-simulation-header>
    
    <div class="prediction-simulation-content">
      <!-- 仅当不是预警分析时显示地图 -->
      <template v-if="activeFeature !== 'warning'">
      <div id="prediction-map" class="prediction-map"></div>
      </template>
      
      <!-- 左侧功能栏 -->
      <div class="left-sidebar">
        <h3 class="sidebar-title">功能设置</h3>
        <div class="sidebar-menu">
          <div class="menu-item" @click="toggleWarningMenu">
            <div class="menu-icon">
              <i class="feature-icon warning-icon"></i>
            </div>
            <span class="menu-text">预警分析</span>
            <span class="simple-arrow" :class="{ open: showWarningMenu }"></span>
          </div>
          <div v-if="showWarningMenu" class="submenu">
            <div class="submenu-item" @click="selectSubWarning('level')">
              <span>水位预警</span>
            </div>
            <div class="submenu-item" @click="selectSubWarning('env')">
              <span>环境预警</span>
            </div>
          </div>
          <div class="menu-item" @click="activateFeature('flood')">
            <div class="menu-icon">
              <i class="feature-icon flood-icon"></i>
            </div>
            <span class="menu-text">水库淹没模拟</span>
          </div>
          <div class="menu-item" @click="activateFeature('pollution')">
            <div class="menu-icon">
              <i class="feature-icon pollution-icon"></i>
            </div>
            <span class="menu-text">污染物扩散模拟</span>
          </div>
        </div>
      </div>

      <!-- 右侧控制栏已移除 -->
      
    </div>
  </div>
</template>

<script>
import { onMounted, onUnmounted, ref, nextTick, watch } from 'vue'
import L from 'leaflet'
import * as EsriLeaflet from 'esri-leaflet'
import PredictionSimulationHeader from '../components/PredictionSimulationHeader.vue'
import axios from 'axios'
import * as echarts from 'echarts'

export default {
  name: 'PredictionSimulation',
  components: {
    PredictionSimulationHeader
  },
  setup() {
    let map = null;
    const activeFeature = ref(null);
    let reservoirLayer = null;
    const showTrendDetail = ref(false);
    const showReservoirDetail = ref(false);
    const showMonitoringDetail = ref(false);
    const showWarningDetail = ref(false);
    const echartsRef = ref(null);
    const monitoringChartRef = ref(null);
    let chartInstance = null;
    let monitoringChartInstance = null;
    
    // 水库淹没模拟相关状态
    const floodParams = ref({
      selectedReservoir: '',
      bufferDistance: 1000, // 缓冲区距离
      simWaterLevel: 105, // 模拟水位
      duration: 24, // 模拟持续时间
      rainfall: 10, // 降雨量
      overlayLayers: { // 新增叠加分析图层状态
        resident: false,
        road: false,
        farmland: false
      }
    });
    
    const floodResults = ref({
      area: 0,
      maxDepth: 0,
      affectedSettlements: 0,
      affectedPopulation: 0,
      affectedFarmland: 0,
      impactLevel: 'low',
      impactAnalysis: ''
    });
    
    const floodSimulationActive = ref(false);
    const activeTab = ref('depth');
    const depthChartRef = ref(null);
    const timeChartRef = ref(null);
    let depthChartInstance = null;
    let timeChartInstance = null;
    const toggleReservoirDetail = () => {
      showReservoirDetail.value = !showReservoirDetail.value;
    };

    // 水位趋势图数据（示例）
    const trendOption = {
      backgroundColor: '#11233b',
      tooltip: { trigger: 'axis' },
      legend: {
        data: ['历史水位', '预测水位', '警戒水位'],
        textStyle: { color: '#fff' },
        top: 10
      },
      grid: { left: 40, right: 20, top: 50, bottom: 40 },
      xAxis: {
        type: 'category',
        data: ['07-01','07-02','07-03','07-04','07-05','07-06','07-07','07-08','07-09','07-10','07-11','07-12'],
        axisLine: { lineStyle: { color: '#4bbfff' } },
        axisLabel: { color: '#fff' }
      },
      yAxis: {
        type: 'value',
        name: '水位 (m)',
        min: 94,
        max: 114,
        axisLine: { lineStyle: { color: '#4bbfff' } },
        axisLabel: { color: '#fff' },
        splitLine: { lineStyle: { color: '#223a5b' } }
      },
      series: [
        {
          name: '历史水位',
          type: 'line',
          data: [95.5,96.2,97.1,97.8,98.6,99.3,100.1,101.2,102.3,103.5,104.8,105.02],
          lineStyle: { color: '#4bbfff' },
          itemStyle: { color: '#4bbfff' },
          symbol: 'circle',
          symbolSize: 7
        },
        {
          name: '预测水位',
          type: 'line',
          data: [null,null,null,null,null,null,null,null,null,103.5,107.2,112.5],
          lineStyle: { color: '#ff5c5c', type: 'dashed' },
          itemStyle: { color: '#ff5c5c' },
          symbol: 'circle',
          symbolSize: 7
        },
        {
          name: '警戒水位',
          type: 'line',
          data: [110.8,110.8,110.8,110.8,110.8,110.8,110.8,110.8,110.8,110.8,110.8,110.8],
          lineStyle: { color: '#ffb74d', type: 'dotted' },
          itemStyle: { color: '#ffb74d' },
          symbol: 'none'
        }
      ]
    };

    // 水位监测点数据
    const monitoringOption = {
      backgroundColor: '#fff',
      tooltip: {
        trigger: 'axis',
        axisPointer: {
          type: 'shadow'
        }
      },
      legend: {
        data: ['当前水位 (m)', '警戒水位 (m)'],
        textStyle: { color: '#333' },
        top: 0,
        right: 10
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '3%',
        top: '15%',
        containLabel: true
      },
      xAxis: {
        type: 'category',
        data: ['主坝', '北岸', '南岸', '泄洪道', '入库口'],
        axisLine: { lineStyle: { color: '#666' } },
        axisLabel: { color: '#333' }
      },
      yAxis: {
        type: 'value',
        name: '水位 (m)',
        min: 0,
        max: 120,
        axisLine: { lineStyle: { color: '#666' } },
        axisLabel: { color: '#333' },
        splitLine: { lineStyle: { color: '#eee' } }
      },
      series: [
        {
          name: '当前水位 (m)',
          type: 'bar',
          barWidth: '40%',
          data: [
            { value: 102.5, itemStyle: { color: '#D68E5E' } }, // 主坝
            { value: 100.2, itemStyle: { color: '#D68E5E' } }, // 北岸
            { value: 99.8, itemStyle: { color: '#49C7D2' } },  // 南岸
            { value: 104.3, itemStyle: { color: '#D25F5F' } }, // 泄洪道
            { value: 103.7, itemStyle: { color: '#D68E5E' } }  // 入库口
          ]
        },
        {
          name: '警戒水位 (m)',
          type: 'line',
          markLine: {
            silent: true,
            lineStyle: {
              color: '#F4A460',
              type: 'dashed'
            },
            data: [
              { yAxis: 110 }
            ]
          },
          data: [110, 110, 110, 110, 110],
          lineStyle: { color: '#F4A460', type: 'dashed', width: 2 },
          symbol: 'none'
        }
      ]
    };

    // 初始化地图
    const initMap = () => {
      map = L.map('prediction-map', {
        backgroundColor: '#ffffff', // 设置地图背景色为白色
        zoomControl: false // 先禁用默认缩放控件
      }).setView([39.9042, 116.4074], 10);
      
      // 不加载任何要素图层
      // loadReservoirs(); 已移除
      
      // 在自定义位置添加缩放控件
      setTimeout(() => {
        L.control.zoom({ position: 'topleft' }).addTo(map);
      }, 200);
    }

    // 切换趋势分析详情显示
    const toggleTrendDetail = async () => {
      showTrendDetail.value = !showTrendDetail.value;
      if (showTrendDetail.value) {
        await nextTick();
        // 日志输出容器宽高
        console.log('echartsRef:', echartsRef.value, 'width:', echartsRef.value?.offsetWidth, 'height:', echartsRef.value?.offsetHeight);
        if (!chartInstance) {
          chartInstance = echarts.init(echartsRef.value);
        }
        chartInstance.setOption(trendOption);
        chartInstance.resize();
      }
    };

    // 切换监测点数据显示
    const toggleMonitoringDetail = async () => {
      showMonitoringDetail.value = !showMonitoringDetail.value;
      if (showMonitoringDetail.value) {
        await nextTick();
        if (!monitoringChartInstance) {
          console.log('Initializing monitoring chart...');
          monitoringChartInstance = echarts.init(monitoringChartRef.value);
        }
        monitoringChartInstance.setOption(monitoringOption);
        monitoringChartInstance.resize();
      }
    };

    // 切换预警分析详情显示
    const toggleWarningDetail = () => {
      showWarningDetail.value = !showWarningDetail.value;
    };
    
    // 水库淹没模拟相关方法
    const runFloodSimulation = () => {
      if (!floodParams.value.selectedReservoir) {
        alert('请先选择水库');
        return;
      }
      
      // 模拟计算淹没结果
      const baseArea = 50 + Math.random() * 100;
      const baseDepth = 2 + Math.random() * 5;
      const waterLevelFactor = (floodParams.value.simWaterLevel - 100) / 20;
      const rainfallFactor = floodParams.value.rainfall / 50;
      
      floodResults.value = {
        area: baseArea * (1 + waterLevelFactor + rainfallFactor),
        maxDepth: baseDepth * (1 + waterLevelFactor),
        affectedSettlements: Math.floor(5 + Math.random() * 15),
        affectedPopulation: Math.floor(1000 + Math.random() * 5000),
        affectedFarmland: baseArea * 0.3 * (1 + waterLevelFactor),
        impactLevel: getImpactLevel(waterLevelFactor + rainfallFactor),
        impactAnalysis: generateImpactAnalysis(waterLevelFactor + rainfallFactor)
      };
      
      floodSimulationActive.value = true;
      
      // 初始化图表
      nextTick(() => {
        initFloodCharts();
      });
    };
    
    const resetFloodParams = () => {
      floodParams.value = {
        selectedReservoir: '',
        bufferDistance: 1000, // 缓冲区距离
        simWaterLevel: 105, // 模拟水位
        duration: 24, // 模拟持续时间
        rainfall: 10, // 降雨量
        overlayLayers: { // 重置叠加分析图层状态
          resident: false,
          road: false,
          farmland: false
        }
      };
      floodSimulationActive.value = false;
    };
    
    const getImpactLevel = (factor) => {
      if (factor < 0.5) return 'low';
      if (factor < 1.0) return 'medium';
      return 'high';
    };
    
    const getImpactLevelClass = (level) => {
      switch (level) {
        case 'low': return 'impact-low';
        case 'medium': return 'impact-medium';
        case 'high': return 'impact-high';
        default: return 'impact-low';
      }
    };
    
    const getImpactLevelText = (level) => {
      switch (level) {
        case 'low': return '低风险';
        case 'medium': return '中风险';
        case 'high': return '高风险';
        default: return '低风险';
      }
    };
    
    const generateImpactAnalysis = (factor) => {
      if (factor < 0.5) {
        return '当前淹没情况对周边环境影响较小，主要影响低洼农田和部分道路。建议加强监测，做好防洪准备。';
      } else if (factor < 1.0) {
        return '淹没范围较大，可能影响部分居民区和重要基础设施。需要启动应急预案，组织人员疏散。';
      } else {
        return '淹没情况严重，可能造成重大损失。建议立即启动最高级别应急响应，全面组织救援和疏散工作。';
      }
    };
    
    const initFloodCharts = async () => {
      // 深度分布图表
      if (activeTab.value === 'depth' && depthChartRef.value) {
        if (!depthChartInstance) {
          depthChartInstance = echarts.init(depthChartRef.value);
        }
        
        const depthOption = {
          backgroundColor: '#fff',
          tooltip: { trigger: 'axis' },
          legend: { data: ['淹没深度分布'], textStyle: { color: '#333' } },
          grid: { left: '3%', right: '4%', bottom: '3%', top: '15%', containLabel: true },
          xAxis: {
            type: 'category',
            data: ['0-1m', '1-2m', '2-3m', '3-4m', '4-5m', '5m以上'],
            axisLine: { lineStyle: { color: '#666' } },
            axisLabel: { color: '#333' }
          },
          yAxis: {
            type: 'value',
            name: '面积 (km²)',
            axisLine: { lineStyle: { color: '#666' } },
            axisLabel: { color: '#333' },
            splitLine: { lineStyle: { color: '#eee' } }
          },
          series: [{
            name: '淹没深度分布',
            type: 'bar',
            data: [
              { value: floodResults.value.area * 0.3, itemStyle: { color: '#91cc75' } },
              { value: floodResults.value.area * 0.25, itemStyle: { color: '#fac858' } },
              { value: floodResults.value.area * 0.2, itemStyle: { color: '#ee6666' } },
              { value: floodResults.value.area * 0.15, itemStyle: { color: '#73c0de' } },
              { value: floodResults.value.area * 0.08, itemStyle: { color: '#3ba272' } },
              { value: floodResults.value.area * 0.02, itemStyle: { color: '#fc8452' } }
            ]
          }]
        };
        
        depthChartInstance.setOption(depthOption);
        depthChartInstance.resize();
      }
      
      // 时间演变图表
      if (activeTab.value === 'time' && timeChartRef.value) {
        if (!timeChartInstance) {
          timeChartInstance = echarts.init(timeChartRef.value);
        }
        
        const timeData = [];
        const areaData = [];
        const depthData = [];
        
        for (let i = 0; i <= floodParams.value.duration; i += 2) {
          timeData.push(i);
          const progress = i / floodParams.value.duration;
          areaData.push(floodResults.value.area * progress);
          depthData.push(floodResults.value.maxDepth * progress);
        }
        
        const timeOption = {
          backgroundColor: '#fff',
          tooltip: { trigger: 'axis' },
          legend: { data: ['淹没面积', '最大深度'], textStyle: { color: '#333' } },
          grid: { left: '3%', right: '4%', bottom: '3%', top: '15%', containLabel: true },
          xAxis: {
            type: 'category',
            data: timeData,
            name: '时间 (小时)',
            axisLine: { lineStyle: { color: '#666' } },
            axisLabel: { color: '#333' }
          },
          yAxis: [
            {
              type: 'value',
              name: '面积 (km²)',
              axisLine: { lineStyle: { color: '#666' } },
              axisLabel: { color: '#333' },
              splitLine: { lineStyle: { color: '#eee' } }
            },
            {
              type: 'value',
              name: '深度 (m)',
              axisLine: { lineStyle: { color: '#666' } },
              axisLabel: { color: '#333' },
              splitLine: { show: false }
            }
          ],
          series: [
            {
              name: '淹没面积',
              type: 'line',
              data: areaData,
              lineStyle: { color: '#91cc75' },
              itemStyle: { color: '#91cc75' }
            },
            {
              name: '最大深度',
              type: 'line',
              yAxisIndex: 1,
              data: depthData,
              lineStyle: { color: '#ee6666' },
              itemStyle: { color: '#ee6666' }
            }
          ]
        };
        
        timeChartInstance.setOption(timeOption);
        timeChartInstance.resize();
      }
    };

    // 激活功能
    const activateFeature = (feature) => {
      activeFeature.value = feature;
      // 关闭所有详情
      showTrendDetail.value = false;
      showReservoirDetail.value = false;
      showMonitoringDetail.value = false;
      showWarningDetail.value = false;
      // 不再弹窗提示
      // if (feature === 'warning') {
      //   // 预警分析功能
      //   // alert('预警分析功能已启动');
      // } else if (feature === 'flood') {
      //   alert('水库淹没模拟功能已启动');
      // } else if (feature === 'pollution') {
      //   alert('污染物扩散模拟功能已启动');
      // }
    };

    // 新增：预警分析子菜单显示状态
    const showWarningMenu = ref(false);
    // 新增：当前选中的预警子功能
    const selectedSubWarning = ref(null);

    // 切换预警分析子菜单
    const toggleWarningMenu = () => {
      showWarningMenu.value = !showWarningMenu.value;
      // 切换时不激活主功能，避免地图切换
    };
    // 选择子功能
    const selectSubWarning = (type) => {
      selectedSubWarning.value = type;
      activeFeature.value = 'warning'; // 激活主功能（如需）
    };

    onMounted(() => {
      // 确保地图容器已渲染后再初始化地图
      setTimeout(() => {
        initMap();
      }, 100);
    })
    
    // 监听activeTab变化，重新渲染图表
    watch(activeTab, () => {
      if (floodSimulationActive.value) {
        nextTick(() => {
          initFloodCharts();
        });
      }
    });

    onUnmounted(() => {
      // 组件卸载时移除地图以避免内存泄漏
      if (map) {
        map.remove();
      }
      if (reservoirLayer) {
        reservoirLayer.remove();
      }
      if (chartInstance) {
        chartInstance.dispose();
        chartInstance = null;
      }
      if (monitoringChartInstance) {
        monitoringChartInstance.dispose();
        monitoringChartInstance = null;
      }
    })

    return {
      activeFeature,
      activateFeature,
      showTrendDetail,
      toggleTrendDetail,
      echartsRef,
      showReservoirDetail,
      toggleReservoirDetail,
      showMonitoringDetail,
      toggleMonitoringDetail,
      monitoringChartRef,
      showWarningDetail,
      toggleWarningDetail,
      // 水库淹没模拟相关
      floodParams,
      floodResults,
      floodSimulationActive,
      activeTab,
      depthChartRef,
      timeChartRef,
      runFloodSimulation,
      resetFloodParams,
      getImpactLevelClass,
      getImpactLevelText,
      // 预警分析子菜单相关
      showWarningMenu,
      toggleWarningMenu,
      selectedSubWarning,
      selectSubWarning
    }
  }
}
</script>

<style scoped>
.prediction-simulation-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  width: 100%;
  position: relative;
}

.prediction-simulation-content {
  flex: 1;
  overflow: hidden;
  position: relative;
}

.prediction-map {
  width: 100%;
  height: calc(100vh - 72px); /* 减去Header的高度 */
  background-color: #ffffff; /* 确保地图容器背景也是白色 */
}

/* 左侧功能栏样式 */
.left-sidebar {
  position: absolute;
  top: 20px;
  left: 20px;
  width: 180px;
  background-color: rgba(255, 255, 255, 0.9);
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.15);
  padding: 15px;
  z-index: 1000;
}

/* 缩放控件微调到功能栏右侧 */
:deep(.leaflet-top.leaflet-left .leaflet-control-zoom) {
  margin-left: 210px !important; /* 180px宽度+30px间距 */
  margin-top: 30px !important;
  z-index: 1100;
}

.sidebar-title {
  font-size: 16px;
  font-weight: bold;
  margin-top: 0;
  margin-bottom: 15px;
  text-align: center;
  color: #333;
  padding-bottom: 10px;
  border-bottom: 1px solid #eee;
}

.sidebar-menu {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.menu-item {
  display: flex;
  align-items: center;
  cursor: pointer;
  padding: 10px;
  border-radius: 6px;
  transition: background-color 0.3s;
}

.menu-item:hover {
  background-color: rgba(0, 0, 0, 0.05);
}

.menu-icon {
  margin-right: 10px;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.menu-text {
  font-size: 14px;
  color: #333;
}

/* 功能图标样式 */
.feature-icon {
  display: block;
  width: 20px;
  height: 20px;
  background-size: contain;
  background-position: center;
  background-repeat: no-repeat;
}

.warning-icon {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%23f44336'%3E%3Cpath d='M12 5.99L19.53 19H4.47L12 5.99M12 2L1 21h22L12 2zm1 14h-2v2h2v-2zm0-6h-2v4h2v-4z'/%3E%3C/svg%3E");
}

.flood-icon {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%232196f3'%3E%3Cpath d='M12,3L2,12h3v8h14v-8h3L12,3z M12,16c-1.1,0-2-0.9-2-2c0-1.1,2-4,2-4s2,2.9,2,4C14,15.1,13.1,16,12,16z'/%3E%3C/svg%3E");
}

.pollution-icon {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%234caf50'%3E%3Cpath d='M19.35,10.04C18.67,6.59,15.64,4,12,4C9.11,4,6.6,5.64,5.35,8.04C2.34,8.36,0,10.91,0,14c0,3.31,2.69,6,6,6h13 c2.76,0,5-2.24,5-5C24,12.36,21.95,10.22,19.35,10.04z'/%3E%3C/svg%3E");
}

/* 右侧预警分析状态栏样式 */
.right-statusbar {
  position: absolute;
  top: 20px;
  right: 20px;
  width: 420px;
  background: rgba(255,255,255,0.97);
  border-radius: 10px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.13);
  padding: 18px 18px 10px 18px;
  z-index: 1200;
  display: flex;
  flex-direction: column;
  gap: 18px;
}
.status-section {
  border-bottom: 1px solid #eee;
  padding-bottom: 10px;
  margin-bottom: 10px;
}
.status-section:last-child {
  border-bottom: none;
  margin-bottom: 0;
}
.status-title {
  font-size: 16px;
  font-weight: bold;
  color: #1976d2;
  margin-bottom: 6px;
}
.status-content {
  font-size: 14px;
  color: #333;
}

.status-title.clickable {
  cursor: pointer;
  user-select: none;
  display: flex;
  align-items: center;
}
.arrow {
  display: inline-block;
  margin-left: 8px;
  width: 0;
  height: 0;
  border-left: 6px solid transparent;
  border-right: 6px solid transparent;
  border-top: 8px solid #1976d2;
  transition: transform 0.2s;
}
.arrow.open {
  transform: rotate(180deg);
}
.trend-detail {
  background: #fff;
  border-radius: 8px;
  padding: 16px 12px 12px 12px;
  margin-top: 12px;
}
.trend-chart {
  width: 100%;
  height: 220px;
  min-height: 220px;
  margin-bottom: 18px;
}
.trend-data-row {
  display: flex;
  gap: 18px;
  margin-bottom: 12px;
}
.trend-data-block {
  background: #f5f7fa;
  border-radius: 6px;
  padding: 12px 18px;
  color: #1976d2;
  margin-bottom: 10px;
  min-width: 120px;
}
.trend-data-label {
  font-size: 13px;
  color: #666;
  margin-bottom: 4px;
}
.trend-data-value {
  font-size: 28px;
  font-weight: bold;
  color: #1976d2;
  margin-bottom: 2px;
}
.trend-data-value.highlight {
  color: #ff9800;
}
.trend-data-sub {
  font-size: 13px;
  color: #888;
}
/* 重新设计的水库基本信息样式 */
.reservoir-section-title {
  color: #2196F3;
}
.reservoir-container {
  background: #fff;
  border-radius: 8px;
  margin-top: 12px;
  padding: 0;
}
.reservoir-header {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding: 8px 15px;
}
.reservoir-title {
  font-size: 18px;
  font-weight: 500;
  color: #2196F3;
}
.refresh-btn {
  background: transparent;
  color: #2196F3;
  border: none;
  font-size: 14px;
  padding: 6px 12px;
  cursor: pointer;
  display: flex;
  align-items: center;
}
.refresh-btn:hover {
  background: #f5f5f5;
  border-radius: 4px;
}
.reservoir-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0;
  border-radius: 0 0 8px 8px;
  overflow: hidden;
}
.reservoir-card {
  background: #fff;
  padding: 15px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: flex-start;
  min-height: 90px;
}
.card-label {
  font-size: 14px;
  color: #888;
  margin-bottom: 8px;
}
.card-value {
  font-size: 24px;
  font-weight: bold;
  color: #2196F3;
  line-height: 1.2;
}
.unit {
  font-size: 16px;
  font-weight: normal;
}
.monitoring-detail {
  background: #fff;
  border-radius: 8px;
  padding: 10px;
  margin-top: 12px;
}
.monitoring-chart {
  width: 100%;
  height: 280px;
}
.warning-detail {
  background: #fff;
  border-radius: 8px;
  margin-top: 12px;
}
.warning-header {
  display: flex;
  justify-content: flex-end;
  padding: 12px 16px;
}
.report-btn {
  background: #eaf6fa;
  color: #2196F3;
  border: none;
  border-radius: 4px;
  padding: 8px 18px;
  cursor: pointer;
  font-size: 14px;
  display: flex;
  align-items: center;
}
.report-btn:hover {
  background: #d0eaf7;
}
.report-icon {
  display: inline-block;
  width: 16px;
  height: 16px;
  margin-right: 5px;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%232196F3'%3E%3Cpath d='M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6zm-1 1.5V8H8.5V3.5h4.5zM19 20H5V4h7v5h7v11z'/%3E%3C/svg%3E");
  background-size: contain;
}
.warning-table {
  width: 100%;
  font-size: 13px;
}
.table-header {
  display: flex;
  background-color: #f5f7fa;
  color: #1976D2;
  font-weight: bold;
  font-size: 14px;
}
.table-row {
  display: flex;
  border-bottom: 1px solid #e0e6ed;
  background: #fff;
}
.table-row:last-child {
  border-bottom: none;
}
.table-cell {
  padding: 10px 18px;
  flex: 1 1 150px;
  min-width: 150px;
  display: flex;
  align-items: center;
  color: #333;
  text-align: left;
  word-break: break-all;
}
.status-tag {
  padding: 3px 8px;
  border-radius: 3px;
  font-size: 12px;
}
.status-tag.notice {
  color: #ff8c38;
}
.status-tag.normal {
  color: #49c7d2;
}
.status-tag.warning {
  color: #ff5252;
}
.flood-simulation-panel {
  position: absolute;
  top: 20px;
  right: 20px;
  width: 360px;
  background: rgba(255,255,255,0.97);
  border-radius: 10px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.13);
  padding: 18px 18px 10px 18px;
  z-index: 1200;
  display: flex;
  flex-direction: column;
  gap: 0;
  max-height: calc(100vh - 40px);
  overflow-y: auto;
}
.flood-section {
  padding: 18px 0 10px 0;
}
.flood-section-header {
  display: flex;
  align-items: center;
  font-size: 18px;
  font-weight: bold;
  color: #1976d2;
  margin-bottom: 8px;
}
.flood-icon {
  font-size: 22px;
  margin-right: 8px;
}
.flood-title {
  font-size: 18px;
}
.flood-section-content {
  font-size: 14px;
  color: #333;
  min-height: 32px;
}
.flood-divider {
  height: 1px;
  background: #e0e6ed;
  margin: 0 0 0 0;
  width: 100%;
}
.flood-form {
  display: flex;
  flex-direction: column;
  gap: 15px;
}
.form-group {
  display: flex;
  flex-direction: column;
}
.form-group label {
  font-size: 14px;
  color: #555;
  margin-bottom: 8px;
}
.flood-select, .flood-slider {
  width: 100%;
  padding: 10px;
  border: 1px solid #ccc;
  border-radius: 6px;
  font-size: 14px;
  color: #333;
  background-color: #fff;
  box-sizing: border-box;
}
.flood-select:focus, .flood-slider:focus {
  outline: none;
  border-color: #2196F3;
  box-shadow: 0 0 5px rgba(33, 150, 243, 0.3);
}
.slider-container {
  display: flex;
  align-items: center;
  gap: 10px;
}
.slider-value {
  font-size: 14px;
  color: #333;
  font-weight: bold;
}
.form-actions {
  display: flex;
  justify-content: space-between;
  margin-top: 20px;
}
.btn-run, .btn-reset {
  flex: 1;
  padding: 10px 15px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: bold;
  cursor: pointer;
  transition: background-color 0.3s;
}
.btn-run {
  background-color: #4CAF50;
  color: #fff;
}
.btn-run:hover {
  background-color: #45a049;
}
.btn-reset {
  background-color: #f44336;
  color: #fff;
}
.btn-reset:hover {
  background-color: #d32f2f;
}
.flood-result-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 15px;
  padding: 15px;
  background: #f5f7fa;
  border-radius: 8px;
  margin-top: 15px;
}
.stat-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  background: #fff;
  border-radius: 6px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}
.stat-label {
  font-size: 13px;
  color: #888;
}
.stat-value {
  font-size: 18px;
  font-weight: bold;
  color: #2196F3;
}
.no-result-message {
  text-align: center;
  color: #888;
  padding: 20px;
}
.flood-analysis {
  background: #fff;
  border-radius: 8px;
  padding: 15px;
  margin-top: 15px;
}
.analysis-tabs {
  display: flex;
  border-bottom: 1px solid #eee;
  margin-bottom: 15px;
}
.tab {
  padding: 10px 20px;
  cursor: pointer;
  font-size: 15px;
  font-weight: bold;
  color: #555;
  border-bottom: 2px solid transparent;
  transition: all 0.3s ease;
}
.tab.active {
  color: #2196F3;
  border-bottom-color: #2196F3;
}
.tab:hover {
  color: #2196F3;
}
.tab-content {
  display: flex;
  flex-direction: column;
  gap: 15px;
}
.chart-container {
  width: 100%;
  height: 300px;
  background: #f5f7fa;
  border-radius: 8px;
  padding: 15px;
  box-sizing: border-box;
}
.impact-analysis {
  padding: 15px;
  background: #f5f7fa;
  border-radius: 8px;
  margin-top: 15px;
}
.impact-level {
  font-size: 18px;
  font-weight: bold;
  color: #2196F3;
  margin-bottom: 10px;
  padding: 10px 15px;
  border-radius: 6px;
  background-color: #eaf6fa;
  display: flex;
  align-items: center;
  gap: 10px;
}
.impact-level.impact-low {
  color: #4CAF50;
  background-color: #e8f5e9;
}
.impact-level.impact-medium {
  color: #FFC107;
  background-color: #fff3cd;
}
.impact-level.impact-high {
  color: #F44336;
  background-color: #ffebee;
}
.impact-label {
  font-size: 16px;
  font-weight: bold;
}
.impact-value {
  font-size: 24px;
  font-weight: bold;
  color: #2196F3;
}
.impact-detail {
  font-size: 14px;
  color: #333;
  margin-bottom: 15px;
  line-height: 1.6;
}
.btn-report {
  background: #2196F3;
  color: #fff;
  border: none;
  border-radius: 6px;
  padding: 10px 20px;
  font-size: 14px;
  font-weight: bold;
  cursor: pointer;
  transition: background-color 0.3s;
}
.btn-report:hover {
  background: #1976D2;
}
.submenu {
  margin-left: 24px;
  margin-bottom: 10px;
  border-left: 2px solid #e0e6ed;
  padding-left: 10px;
}
.submenu-item {
  padding: 6px 0;
  cursor: pointer;
  color: #1976d2;
  font-size: 15px;
  transition: color 0.2s;
}
.submenu-item:hover {
  color: #1565c0;
}
.collapse-arrow {
  display: inline-block;
  margin-left: 8px;
  width: 0;
  height: 0;
  border-left: 6px solid transparent;
  border-right: 6px solid transparent;
  border-top: 8px solid #1976d2;
  transition: transform 0.2s;
}
.collapse-arrow.open {
  transform: rotate(180deg);
}
.simple-arrow {
  display: inline-block;
  margin-left: 8px;
  width: 0;
  height: 0;
  border-top: 6px solid transparent;
  border-bottom: 6px solid transparent;
  border-left: 8px solid #1976d2;
  transition: transform 0.2s;
  vertical-align: middle;
}
.simple-arrow.open {
  transform: rotate(90deg);
}
</style> 
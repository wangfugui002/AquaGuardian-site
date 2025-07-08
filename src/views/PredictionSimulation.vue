<template>
  <div class="prediction-simulation-container">
    <prediction-simulation-header title="预测模拟"></prediction-simulation-header>
    
    <div class="prediction-simulation-content">
      <div id="prediction-map" class="prediction-map"></div>
      
      <!-- 左侧功能栏 -->
      <div class="left-sidebar">
        <h3 class="sidebar-title">功能设置</h3>
        <div class="sidebar-menu">
          <div class="menu-item" @click="activateFeature('warning')">
            <div class="menu-icon">
              <i class="feature-icon warning-icon"></i>
            </div>
            <span class="menu-text">预警分析</span>
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

      <!-- 右侧预警分析状态栏，仅在激活预警分析时显示 -->
      <div v-if="activeFeature === 'warning'" class="right-statusbar">
        <div class="status-section">
          <div class="status-title clickable" @click="toggleTrendDetail">
            水位变化趋势分析
            <span class="arrow" :class="{open: showTrendDetail}"></span>
          </div>
          <div v-if="showTrendDetail" class="trend-detail">
            <!-- ECharts 图表 -->
            <div ref="echartsRef" class="trend-chart"></div>
            <div class="trend-data-row">
              <div class="trend-data-block">
                <div class="trend-data-label">当前水位</div>
                <div class="trend-data-value">105.02 m</div>
                <div class="trend-data-sub">警戒水位: 110.8 m</div>
              </div>
              <div class="trend-data-block">
                <div class="trend-data-label">24小时变化</div>
                <div class="trend-data-value highlight">+2.3 m</div>
                <div class="trend-data-sub">上升速度: 0.1 m/h</div>
              </div>
            </div>
            <div class="trend-data-block">
              <div class="trend-data-label">预测峰值</div>
              <div class="trend-data-value">112.5 m</div>
            </div>
          </div>
        </div>
        <div class="status-section">
          <div class="status-title clickable reservoir-section-title" @click="toggleReservoirDetail">
            水库基本信息
            <span class="arrow" :class="{open: showReservoirDetail}"></span>
          </div>
          <div v-if="showReservoirDetail" class="reservoir-container">
            <div class="reservoir-header">
              <button class="refresh-btn">刷新</button>
            </div>
            <div class="reservoir-grid">
              <div class="reservoir-card">
                <div class="card-label">水库名称</div>
                <div class="card-value">官厅水库</div>
              </div>
              <div class="reservoir-card">
                <div class="card-label">蓄水面积</div>
                <div class="card-value">230 <span class="unit">km<sup>2</sup></span></div>
              </div>
              <div class="reservoir-card">
                <div class="card-label">总库容</div>
                <div class="card-value">4.16亿 <span class="unit">m<sup>3</sup></span></div>
              </div>
              <div class="reservoir-card">
                <div class="card-label">汛限水位</div>
                <div class="card-value">105.5 <span class="unit">m</span></div>
              </div>
              <div class="reservoir-card">
                <div class="card-label">当前蓄水量</div>
                <div class="card-value">3.84亿 <span class="unit">m<sup>3</sup></span></div>
              </div>
              <div class="reservoir-card">
                <div class="card-label">警戒水位</div>
                <div class="card-value">110.8 <span class="unit">m</span></div>
              </div>
            </div>
          </div>
        </div>
        <div class="status-section">
          <div class="status-title clickable" @click="toggleMonitoringDetail">
            水位监测点数据
            <span class="arrow" :class="{open: showMonitoringDetail}"></span>
          </div>
          <div v-if="showMonitoringDetail" class="monitoring-detail">
            <div class="monitoring-chart" ref="monitoringChartRef"></div>
          </div>
        </div>
        <div class="status-section">
          <div class="status-title clickable" @click="toggleWarningDetail">
            预警分析详情
            <span class="arrow" :class="{open: showWarningDetail}"></span>
          </div>
          <div v-if="showWarningDetail" class="warning-detail">
            <div class="warning-header">
              <button class="report-btn">
                <i class="report-icon"></i>
                生成报告
              </button>
            </div>
            <div class="warning-table">
              <div class="table-header">
                <div class="table-cell">监测点</div>
                <div class="table-cell">当前水位 (m)</div>
                <div class="table-cell">警戒水位 (m)</div>
                <div class="table-cell">水位差 (m)</div>
                <div class="table-cell">状态</div>
              </div>
              <div class="table-row">
                <div class="table-cell">主坝监测点</div>
                <div class="table-cell">102.6</div>
                <div class="table-cell">110.8</div>
                <div class="table-cell">+8.2</div>
                <div class="table-cell"><span class="status-tag notice">关注</span></div>
              </div>
              <div class="table-row">
                <div class="table-cell">北岸监测点</div>
                <div class="table-cell">101.3</div>
                <div class="table-cell">109.5</div>
                <div class="table-cell">+8.2</div>
                <div class="table-cell"><span class="status-tag notice">关注</span></div>
              </div>
              <div class="table-row">
                <div class="table-cell">南岸监测点</div>
                <div class="table-cell">100.8</div>
                <div class="table-cell">108.2</div>
                <div class="table-cell">+7.4</div>
                <div class="table-cell"><span class="status-tag normal">正常</span></div>
              </div>
              <div class="table-row">
                <div class="table-cell">泄洪道监测点</div>
                <div class="table-cell">104.2</div>
                <div class="table-cell">112.0</div>
                <div class="table-cell">+7.8</div>
                <div class="table-cell"><span class="status-tag warning">警告</span></div>
              </div>
              <div class="table-row">
                <div class="table-cell">入库口监测点</div>
                <div class="table-cell">105.1</div>
                <div class="table-cell">111.5</div>
                <div class="table-cell">+6.4</div>
                <div class="table-cell"><span class="status-tag notice">关注</span></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 右侧水库淹没模拟控制栏 -->
      <div v-if="activeFeature === 'flood'" class="flood-simulation-panel">
        <div class="flood-section">
          <div class="flood-section-header">
            <span class="flood-icon">⚙️</span>
            <span class="flood-title">模拟参数设置</span>
          </div>
          <div class="flood-section-content">
            <form class="flood-form">
              <div class="form-group">
                <label for="reservoir">选择水库</label>
                <select id="reservoir" v-model="floodParams.selectedReservoir" class="flood-select">
                  <option value="" disabled>请选择水库</option>
                  <option value="guanting">官厅水库</option>
                  <option value="miyun">密云水库</option>
                  <option value="huairou">怀柔水库</option>
                </select>
              </div>
              
              <div class="form-group">
                <label for="waterLevel">水位高度 (米)</label>
                <div class="slider-container">
                  <input type="range" id="waterLevel" v-model="floodParams.waterLevel" min="100" max="120" step="0.5" class="flood-slider" />
                  <span class="slider-value">{{ floodParams.waterLevel }}m</span>
                </div>
              </div>
              
              <div class="form-group">
                <label for="floodDuration">模拟持续时间 (小时)</label>
                <div class="slider-container">
                  <input type="range" id="floodDuration" v-model="floodParams.duration" min="1" max="72" step="1" class="flood-slider" />
                  <span class="slider-value">{{ floodParams.duration }}h</span>
                </div>
              </div>
              
              <div class="form-group">
                <label for="rainfall">降雨量 (mm/h)</label>
                <div class="slider-container">
                  <input type="range" id="rainfall" v-model="floodParams.rainfall" min="0" max="50" step="1" class="flood-slider" />
                  <span class="slider-value">{{ floodParams.rainfall }}mm/h</span>
                </div>
              </div>
              
              <div class="form-actions">
                <button type="button" class="btn-run" @click="runFloodSimulation">运行模拟</button>
                <button type="button" class="btn-reset" @click="resetFloodParams">重置参数</button>
              </div>
            </form>
          </div>
        </div>
        <div class="flood-divider"></div>
        <div class="flood-section">
          <div class="flood-section-header">
            <span class="flood-icon">📊</span>
            <span class="flood-title">模拟结果统计</span>
          </div>
          <div class="flood-section-content">
            <div v-if="floodSimulationActive" class="flood-result-stats">
              <div class="stat-row">
                <div class="stat-label">淹没面积</div>
                <div class="stat-value">{{ floodResults.area.toFixed(2) }} km²</div>
              </div>
              <div class="stat-row">
                <div class="stat-label">最大淹没深度</div>
                <div class="stat-value">{{ floodResults.maxDepth.toFixed(2) }} m</div>
              </div>
              <div class="stat-row">
                <div class="stat-label">受影响居民点</div>
                <div class="stat-value">{{ floodResults.affectedSettlements }}</div>
              </div>
              <div class="stat-row">
                <div class="stat-label">受影响人口估计</div>
                <div class="stat-value">{{ floodResults.affectedPopulation.toLocaleString() }} 人</div>
              </div>
              <div class="stat-row">
                <div class="stat-label">受影响耕地面积</div>
                <div class="stat-value">{{ floodResults.affectedFarmland.toFixed(2) }} km²</div>
              </div>
            </div>
            <div v-else class="no-result-message">
              请先运行模拟以查看结果
            </div>
          </div>
        </div>
        <div class="flood-divider"></div>
        <div class="flood-section">
          <div class="flood-section-header">
            <span class="flood-icon">📈</span>
            <span class="flood-title">模拟分析</span>
          </div>
          <div class="flood-section-content">
            <div v-if="floodSimulationActive" class="flood-analysis">
              <div class="analysis-tabs">
                <div class="tab" :class="{ 'active': activeTab === 'depth' }" @click="activeTab = 'depth'">深度分布</div>
                <div class="tab" :class="{ 'active': activeTab === 'time' }" @click="activeTab = 'time'">时间演变</div>
                <div class="tab" :class="{ 'active': activeTab === 'impact' }" @click="activeTab = 'impact'">影响评估</div>
              </div>
              
              <div class="tab-content">
                <!-- 深度分布图表 -->
                <div v-if="activeTab === 'depth'" class="chart-container" ref="depthChartRef"></div>
                
                <!-- 时间演变图表 -->
                <div v-if="activeTab === 'time'" class="chart-container" ref="timeChartRef"></div>
                
                <!-- 影响评估 -->
                <div v-if="activeTab === 'impact'" class="impact-analysis">
                  <div class="impact-level" :class="getImpactLevelClass(floodResults.impactLevel)">
                    <span class="impact-label">影响等级：</span>
                    <span class="impact-value">{{ getImpactLevelText(floodResults.impactLevel) }}</span>
                  </div>
                  <div class="impact-detail">{{ floodResults.impactAnalysis }}</div>
                  <button class="btn-report">生成分析报告</button>
                </div>
              </div>
            </div>
            <div v-else class="no-result-message">
              请先运行模拟以查看分析结果
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { onMounted, onUnmounted, ref, nextTick } from 'vue'
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

    // 加载水库GeoJSON并添加Marker
    const loadReservoirs = async () => {
      try {
        const res = await axios.get('/Beijing-GeoJson/北京市水库.json');
        const geojson = res.data;
        const icon = L.icon({
          iconUrl: '/icons/水库.png',
          iconSize: [32, 32],
          iconAnchor: [16, 16],
          popupAnchor: [0, -16]
        });
        reservoirLayer = L.geoJSON(geojson, {
          pointToLayer: (feature, latlng) => {
            return L.marker(latlng, { icon });
          },
          onEachFeature: (feature, layer) => {
            if (feature.properties && feature.properties.name) {
              layer.bindPopup('水库名称：' + feature.properties.name);
            }
          }
        });
        reservoirLayer.addTo(map);
      } catch (e) {
        console.error('水库数据加载失败', e);
      }
    };

    // 初始化地图
    const initMap = () => {
      map = L.map('prediction-map', {
        backgroundColor: '#ffffff', // 设置地图背景色为白色
        zoomControl: false // 先禁用默认缩放控件
      }).setView([39.9042, 116.4074], 10);
      
      // 添加空白底图
      L.tileLayer('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQAAAAEAAQMAAABmvDolAAAAA1BMVEX///+nxBvIAAAAH0lEQVQYGe3BAQ0AAADCIPunNsc3YAAAAAAAAAAAADwDc3oAAUWMHvMAAAAASUVORK5CYII=', {
        minZoom: 1,
        maxZoom: 19,
        attribution: ''
      }).addTo(map);
      
      // 添加ArcGIS MapServer服务
      const beijingMapLayer = EsriLeaflet.dynamicMapLayer({
        url: 'https://localhost:6443/arcgis/rest/services/beijingshuikuditu/北京地图/MapServer',
        opacity: 0.7,
        useCors: false // 如果遇到跨域问题，尝试设置为false
      }).addTo(map);
      
      // 在自定义位置添加缩放控件
      setTimeout(() => {
        L.control.zoom({ position: 'topleft' }).addTo(map);
      }, 200);

      // 加载水库图层
      loadReservoirs();
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

    // 激活功能
    const activateFeature = (feature) => {
      activeFeature.value = feature;
      // 关闭所有详情
      showTrendDetail.value = false;
      showReservoirDetail.value = false;
      showMonitoringDetail.value = false;
      showWarningDetail.value = false;
      
      if (feature === 'warning') {
        // 预警分析功能
        // alert('预警分析功能已启动');
      } else if (feature === 'flood') {
        alert('水库淹没模拟功能已启动');
      } else if (feature === 'pollution') {
        alert('污染物扩散模拟功能已启动');
      }
    };

    onMounted(() => {
      // 确保地图容器已渲染后再初始化地图
      setTimeout(() => {
        initMap();
      }, 100);
    })

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
      toggleWarningDetail
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
  display: flex;
  flex-direction: column;
  gap: 0;
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
.impact-level.low {
  color: #4CAF50;
  background-color: #e8f5e9;
}
.impact-level.medium {
  color: #FFC107;
  background-color: #fff3cd;
}
.impact-level.high {
  color: #F44336;
  background-color: #ffebee;
}
.impact-level.extreme {
  color: #E53935;
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
</style> 
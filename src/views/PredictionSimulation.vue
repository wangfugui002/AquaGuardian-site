<template>
  <div class="prediction-simulation-container">
    <prediction-simulation-header title="预警分析"></prediction-simulation-header>
    
    <div class="prediction-simulation-content">
      <!-- 显示地图 (现在无论什么功能都会显示地图) -->
      <div id="prediction-map" class="prediction-map"></div>
      
      <!-- 图层控制面板 -->
      <div class="control-panel" v-if="activeFeature === 'warning' || activeFeature === 'waterLevelWarning' || activeFeature === 'environmentWarning'">
        <h3>图层控制</h3>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="warningLayers.district" @change="toggleWarningLayer('district')">
            区县边界
          </label>
          <div class="layer-color-control">
            <div class="color-preview" :style="{ backgroundColor: layerColors.district }"></div>
        </div>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="warningLayers.waterLine" @change="toggleWarningLayer('waterLine')">
            水系线数据
          </label>
          <div class="layer-color-control">
            <div class="color-preview" :style="{ backgroundColor: layerColors.waterLine }"></div>
        </div>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="warningLayers.reservoir" @change="toggleWarningLayer('reservoir')">
            北京市水库面
          </label>
          <div class="layer-color-control">
            <div class="color-preview" :style="{ backgroundColor: layerColors.reservoir }"></div>
      </div>
      </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="warningLayers.monitoringPoints" @change="toggleWarningLayer('monitoringPoints')">
            监测点
          </label>
          <div class="layer-color-control">
            <div class="color-preview point-preview" :style="{ backgroundColor: layerColors.monitoringPoints }"></div>
          </div>
              </div>
            </div>
            

      

      

      
      <!-- 右侧控制栏已移除 -->
      
    </div>
    
    <!-- 水位分析结果模态框 -->
    <div v-if="showAnalysisModal" class="analysis-modal">
      <div ref="analysisModalRef" class="analysis-modal-content" @click.stop @mousedown="startDrag">
        <div class="analysis-modal-header">
          <div class="drag-handle">
            <div class="drag-dots">
              <span></span><span></span><span></span>
              <span></span><span></span><span></span>
            </div>
          </div>
          <h3>{{ analysisData?.pointName }} - 水位预警分析结果</h3>
          <button class="close-btn" @click="closeAnalysisModal">&times;</button>
        </div>
        
        <div class="analysis-modal-body" v-if="analysisData">
          <!-- 状态指示器 -->
          <div class="status-display-section">
            <div class="status-indicator" :class="analysisData.statusClass">
              {{ analysisData.status }}
            </div>
          </div>
          
          <!-- 水位对比表格 -->
          <div class="water-level-comparison">
            <h5>水位对比分析</h5>
            <div class="comparison-table">
              <div class="comparison-row header">
                <div class="label">项目</div>
                <div class="value">水位(米)</div>
                <div class="difference">与当前水位差值</div>
              </div>
              <div class="comparison-row current-row">
                <div class="label">当前水位</div>
                <div class="value current">{{ analysisData.inputValue }}</div>
                <div class="difference">-</div>
              </div>
              <div class="comparison-row">
                <div class="label">汛限水位</div>
                <div class="value limit">{{ analysisData.floodLimit }}</div>
                <div class="difference" :class="analysisData.inputValue >= analysisData.floodLimit ? 'above' : 'below'">
                  {{ analysisData.inputValue >= analysisData.floodLimit ? '+' : '-' }}{{ Math.abs(analysisData.inputValue - analysisData.floodLimit).toFixed(2) }}米
                </div>
              </div>
              <div class="comparison-row">
                <div class="label">历史最高水位</div>
                <div class="value max">{{ analysisData.maxLevel }}</div>
                <div class="difference" :class="analysisData.inputValue >= analysisData.maxLevel ? 'above' : 'below'">
                  {{ analysisData.inputValue >= analysisData.maxLevel ? '+' : '-' }}{{ Math.abs(analysisData.inputValue - analysisData.maxLevel).toFixed(2) }}米
                </div>
              </div>
              <div class="comparison-row" v-if="analysisData.avgLevel">
                <div class="label">多年平均水位</div>
                <div class="value avg">{{ analysisData.avgLevel }}</div>
                <div class="difference" :class="analysisData.inputValue >= analysisData.avgLevel ? 'above' : 'below'">
                  {{ analysisData.inputValue >= analysisData.avgLevel ? '+' : '-' }}{{ Math.abs(analysisData.inputValue - analysisData.avgLevel).toFixed(2) }}米
                </div>
              </div>
            </div>
          </div>
          
          <!-- 分析总结 -->
          <div class="analysis-summary">
            <h5>分析结论</h5>
            <div class="summary-content">
              {{ analysisData.summary }}
            </div>
            
            <!-- 预案按钮 -->
            <div class="emergency-plan-section" v-if="analysisData.status === '警戒' || analysisData.status === '危险'">
              <button 
                v-if="analysisData.status === '警戒'" 
                class="emergency-plan-btn warning-plan"
                @click="showEmergencyPlan('warning')"
              >
                <i class="plan-icon">⚠️</i>
                <span>警戒水位预案</span>
                <i class="arrow-icon">→</i>
              </button>
              
              <button 
                v-if="analysisData.status === '危险'" 
                class="emergency-plan-btn danger-plan"
                @click="showEmergencyPlan('danger')"
              >
                <i class="plan-icon">🚨</i>
                <span>危险水位预案</span>
                <i class="arrow-icon">→</i>
              </button>
            </div>
          </div>
        </div>
        
        <div class="analysis-modal-footer">
          <button class="btn-close" @click="closeAnalysisModal">关闭</button>
        </div>
      </div>
    </div>
    
    <!-- 应急预案模态框 -->
    <div v-if="showPlanModal" class="analysis-modal plan-modal">
      <div ref="planModalRef" class="analysis-modal-content" @click.stop @mousedown="startPlanDrag">
        <div class="analysis-modal-header">
          <div class="drag-handle">
            <div class="drag-dots">
              <span></span><span></span><span></span>
              <span></span><span></span><span></span>
            </div>
          </div>
          <h3>{{ planData?.title }}</h3>
          <button class="close-btn" @click="closePlanModal">&times;</button>
        </div>
        
        <div class="analysis-modal-body" v-if="planData" style="contain: layout style;">
          <!-- 预案信息显示 -->
          <div class="plan-info-section">
            <div class="plan-status-indicator" :class="planData.type === 'warning' ? 'status-warning' : 'status-danger'">
              {{ planData.type === 'warning' ? '警戒水位预案' : '危险水位预案' }}
            </div>
          </div>
          
          <!-- 当前水位信息 -->
          <div class="current-level-info">
            <h5>当前状况</h5>
            <div class="level-info-content">
              <p><strong>水库名称：</strong>{{ planData.reservoirName }}</p>
              <p><strong>当前水位：</strong>{{ planData.currentLevel }}米</p>
              <p><strong>预警等级：</strong>{{ planData.type === 'warning' ? '二级（警戒）' : '一级（危险）' }}</p>
            </div>
          </div>
          
          <!-- 应急措施列表 -->
          <div class="emergency-measures">
            <h5>应急措施</h5>
            <div class="measures-list">
              <div 
                v-for="(measure, index) in planData.measures" 
                :key="`measure-${index}`" 
                class="measure-item"
                :class="planData.type === 'warning' ? 'warning-measure' : 'danger-measure'"
                style="contain: layout style;"
              >
                <div class="measure-number">{{ index + 1 }}</div>
                <div class="measure-content">{{ measure }}</div>
              </div>
            </div>
          </div>
        </div>
        
        <div class="analysis-modal-footer">
          <button class="btn-close" @click="closePlanModal">关闭</button>
        </div>
      </div>
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
    const showAnalysisModal = ref(false);
    const analysisData = ref(null);
    const analysisModalRef = ref(null);
    
    // 预案模态框相关状态
    const showPlanModal = ref(false);
    const planData = ref(null);
    const planModalRef = ref(null);
    
    // 拖拽相关状态
    const isDragging = ref(false);
    const dragOffset = ref({ x: 0, y: 0 });
    const modalPosition = ref({ x: 0, y: 0 });
    const planDragOffset = ref({ x: 0, y: 0 });
    const planModalPosition = ref({ x: 0, y: 0 });

    const echartsRef = ref(null);
    const monitoringChartRef = ref(null);
    let chartInstance = null;
    let monitoringChartInstance = null;
    
    // 预警分析相关状态
    const warningLayers = ref({
      district: true,
      waterLine: true,
      reservoir: true,
      monitoringPoints: true
    });
    
    // 图层颜色配置（与地图编辑页面保持一致）
    const layerColors = ref({
      district: '#b3e5fc',
      waterLine: '#64B5F6',
      reservoir: '#26C6DA',
      monitoringPoints: '#2196F3'
    });
    
    // 地图图层
    let mapLayers = {
      district: null,
      waterLine: null,
      reservoir: null,
      monitoringPoints: null
    };
    
    // 区县标注图层
    let districtLabels = [];
    
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
      }).setView([39.9042, 116.4074], 9); // 修正了北京的中心点和默认缩放级别
      
      // 删除在线底图，只显示GeoJSON数据
      
      // 在自定义位置添加缩放控件
      setTimeout(() => {
        L.control.zoom({ position: 'topleft' }).addTo(map);
      }, 200);
    }
    
    // 加载预警分析图层
    const loadWarningLayers = async () => {
      try {
        // 加载区县界
        if (warningLayers.value.district) {
          const districtResponse = await fetch('./Beijing-GeoJson-Tzy/北京区县界.json');
          const districtData = await districtResponse.json();
          
          // 清除之前的标注
          districtLabels.forEach(label => {
            if (map && map.hasLayer(label)) {
              map.removeLayer(label);
            }
          });
          districtLabels = [];
          
          mapLayers.district = L.geoJSON(districtData, {
            style: {
              fillColor: layerColors.value.district,
              weight: 2.5,
                opacity: 0.8,
              color: layerColors.value.district,
              fillOpacity: 0.5,
              dashArray: '5, 8'
            },
            onEachFeature: (feature, layer) => {
              if (feature.properties) {
              const districtName = feature.properties.name || 
                                  feature.properties.NAME || 
                                  feature.properties.Name ||
                                  '未命名区县';
              layer.bindPopup(`<b>区县名称:</b> ${districtName}`);
              
              // 添加区县名称标注
              try {
                // 计算多边形的中心点
                const center = layer.getBounds().getCenter();
                
                // 创建标注
                const label = L.divIcon({
                  className: 'district-label',
                  html: `<div>${districtName}</div>`,
                  iconSize: [80, 30],
                  iconAnchor: [40, 15]
                });
                
                  // 将标注添加到地图并保存到数组中
                  const labelMarker = L.marker(center, {
                  icon: label,
                  interactive: false, // 使标注不响应鼠标事件
                  zIndexOffset: 1000  // 确保标注显示在区县上面
                }).addTo(map);
                  
                  districtLabels.push(labelMarker);
              } catch (err) {
                console.error('添加区县标注失败:', err, districtName);
              }
              }
            }
          }).addTo(map);
          
          // 确保区县边界在最底层
          mapLayers.district.bringToBack();
        }
        
        // 加载水系线
        if (warningLayers.value.waterLine) {
          const waterLineResponse = await fetch('./Beijing-GeoJson-Tzy/北京市_水系线数据.json');
          const waterLineData = await waterLineResponse.json();
          
          mapLayers.waterLine = L.geoJSON(waterLineData, {
            style: {
              color: layerColors.value.waterLine,
              weight: 2.5,
              opacity: 0.9
            }
          }).addTo(map);
          
          // 确保水系线在区县边界之上
          if (mapLayers.district && map.hasLayer(mapLayers.district)) {
            mapLayers.waterLine.bringToBack();
            mapLayers.district.bringToBack();
          }
        }
        
        // 加载水库
        if (warningLayers.value.reservoir) {
          const reservoirResponse = await fetch('./Beijing-GeoJson-Tzy/北京市水库面.geojson');
          const reservoirData = await reservoirResponse.json();
          
          mapLayers.reservoir = L.geoJSON(reservoirData, {
            style: {
              fillColor: layerColors.value.reservoir,
              weight: 1.5,
              opacity: 0.9,
              color: layerColors.value.reservoir,
              fillOpacity: 0.8
            },
            onEachFeature: (feature, layer) => {
              if (feature.properties) {
                const reservoirName = feature.properties.name || 
                                     feature.properties.NAME || 
                                     feature.properties.Name ||
                                     '未命名水库';
                
                // 水库详细信息
                const reservoirInfo = {
                  '白河堡水库': {
                    '汛限水位': '592.6米',
                    '当前水位': '591.64米',
                    '历史最高水位': '599.13米',
                    '最低水位': '578米',
                    '多年平均水位': '591.6米'
                  },
                  '密云水库': {
                    '汛限水位': '152米',
                    '当前水位': '154.79米',
                    '历史最高水位': '155.59米',
                    '最低水位': '126.0米',
                    '多年平均水位': '151.8米'
                  },
                  '官厅水库': {
                    '汛限水位': '476米',
                    '当前水位': '478.23米',
                    '历史最高水位': '497.0米',
                    '最低水位': '471.47米'
                  },
                  '怀柔水库': {
                    '汛限水位': '58米',
                    '当前水位': '57.26米',
                    '历史最高水位': '62.13米'
                  },
                  '半城子水库': {
                    '汛限水位': '255米',
                    '当前水位': '253.98米',
                    '历史最高水位': '255米'
                  },
                  '北台上水库': {
                    '汛限水位': '85米',
                    '当前水位': '84.34米',
                    '历史最高水位': '84.8米'
                  },
                  '崇青水库': {
                    '汛限水位': '71.5米',
                    '当前水位': '67.41米',
                    '历史最高水位': '71.5米'
                  },
                  '大宁水库': {
                    '汛限水位': '48米',
                    '当前水位': '47.96米',
                    '历史最高水位': '59.29米'
                  },
                  '大水峪水库': {
                    '汛限水位': '166.4米',
                    '当前水位': '166.45米',
                    '历史最高水位': '168.9米'
                  },
                  '海子水库': {
                    '汛限水位': '106.5米',
                    '当前水位': '105.87米',
                    '历史最高水位': '108.5米'
                  },
                  '黄松峪水库': {
                    '汛限水位': '203.0米',
                    '当前水位': '200.57米',
                    '历史最高水位': '203.0米'
                  },
                  '沙厂水库': {
                    '汛限水位': '165.5米',
                    '当前水位': '163.28米',
                    '历史最高水位': '165.5米'
                  },
                  '十三陵水库': {
                    '汛限水位': '93.0米',
                    '当前水位': '91.23米',
                    '历史最高水位': '91.81米'
                  },
                  '桃峪口水库': {
                    '汛限水位': '67.7米',
                    '当前水位': '64.59米',
                    '历史最高水位': '70.23米'
                  },
                  '西峪水库': {
                    '汛限水位': '213.5米',
                    '当前水位': '212.51米',
                    '历史最高水位': '213.5米'
                  },
                  '遥桥峪水库': {
                    '汛限水位': '464.0米',
                    '当前水位': '461.34米',
                    '历史最高水位': '464.0米'
                  },
                  '斋堂水库': {
                    '汛限水位': '453.0米',
                    '当前水位': '451.27米',
                    '历史最高水位': '461.56米'
                  },
                  '珠窝水库': {
                    '汛限水位': '348.4米',
                    '当前水位': '346.69米',
                    '历史最高水位': '352.5米'
                  }
                };
                
                // 构建弹窗内容
                let popupContent = `<b>水库名称:</b> ${reservoirName}`;
                
                // 如果有该水库的详细信息，则添加到弹窗中
                if (reservoirInfo[reservoirName]) {
                  popupContent += '<br><br><b>水位信息:</b><br>';
                  const info = reservoirInfo[reservoirName];
                  popupContent += `汛限水位: ${info['汛限水位']}<br>`;
                  popupContent += `当前水位: ${info['当前水位']}<br>`;
                  popupContent += `历史最高水位: ${info['历史最高水位']}<br>`;
                  if (info['最低水位']) {
                    popupContent += `最低水位: ${info['最低水位']}<br>`;
                  }
                  if (info['多年平均水位']) {
                    popupContent += `多年平均水位: ${info['多年平均水位']}`;
                  }
                }
                
                // 绑定弹窗显示水库信息
                layer.bindPopup(popupContent);
                
                // 添加点击事件，在控制台输出水库名称
                layer.on('click', (e) => {
                  console.log('点击水库:', reservoirName);
                  // 可以在这里添加更多交互功能
                });
              }
            }
          }).addTo(map);
          
          // 确保水库在水系线之上，区县边界在最底层
          if (mapLayers.waterLine && map.hasLayer(mapLayers.waterLine)) {
            mapLayers.reservoir.bringToBack();
            mapLayers.waterLine.bringToBack();
          }
          if (mapLayers.district && map.hasLayer(mapLayers.district)) {
            mapLayers.district.bringToBack();
          }
        }
        
        // 加载监测点
        if (warningLayers.value.monitoringPoints) {
          const monitoringResponse = await fetch('./Beijing-GeoJson-Tzy/监测点.geojson');
          const monitoringData = await monitoringResponse.json();
          
          mapLayers.monitoringPoints = L.geoJSON(monitoringData, {
            pointToLayer: (feature, latlng) => L.circleMarker(latlng, {
              radius: 8,
              fillColor: layerColors.value.monitoringPoints,
              color: '#fff',
              weight: 2,
              opacity: 1,
              fillOpacity: 0.95
            }),
            onEachFeature: (feature, layer) => {
              if (feature.properties) {
                const pointName = feature.properties.name || 
                                 feature.properties.NAME || 
                                 feature.properties.Name ||
                                 '未命名监测点';
                
                // 水库详细信息
                const reservoirInfo = {
                  '白河堡水库': {
                    '汛限水位': '592.6米',
                    '当前水位': '591.64米',
                    '历史最高水位': '599.13米',
                    '最低水位': '578米',
                    '多年平均水位': '591.6米'
                  },
                  '密云水库': {
                    '汛限水位': '152米',
                    '当前水位': '154.79米',
                    '历史最高水位': '155.59米',
                    '最低水位': '126.0米',
                    '多年平均水位': '151.8米'
                  },
                  '官厅水库': {
                    '汛限水位': '476米',
                    '当前水位': '478.23米',
                    '历史最高水位': '497.0米',
                    '最低水位': '471.47米'
                  },
                  '怀柔水库': {
                    '汛限水位': '58米',
                    '当前水位': '57.26米',
                    '历史最高水位': '62.13米'
                  },
                  '半城子水库': {
                    '汛限水位': '255米',
                    '当前水位': '253.98米',
                    '历史最高水位': '255米'
                  },
                  '北台上水库': {
                    '汛限水位': '85米',
                    '当前水位': '84.34米',
                    '历史最高水位': '84.8米'
                  },
                  '崇青水库': {
                    '汛限水位': '71.5米',
                    '当前水位': '67.41米',
                    '历史最高水位': '71.5米'
                  },
                  '大宁水库': {
                    '汛限水位': '48米',
                    '当前水位': '47.96米',
                    '历史最高水位': '59.29米'
                  },
                  '大水峪水库': {
                    '汛限水位': '166.4米',
                    '当前水位': '166.45米',
                    '历史最高水位': '168.9米'
                  },
                  '海子水库': {
                    '汛限水位': '106.5米',
                    '当前水位': '105.87米',
                    '历史最高水位': '108.5米'
                  },
                  '黄松峪水库': {
                    '汛限水位': '203.0米',
                    '当前水位': '200.57米',
                    '历史最高水位': '203.0米'
                  },
                  '沙厂水库': {
                    '汛限水位': '165.5米',
                    '当前水位': '163.28米',
                    '历史最高水位': '165.5米'
                  },
                  '十三陵水库': {
                    '汛限水位': '93.0米',
                    '当前水位': '91.23米',
                    '历史最高水位': '91.81米'
                  },
                  '桃峪口水库': {
                    '汛限水位': '67.7米',
                    '当前水位': '64.59米',
                    '历史最高水位': '70.23米'
                  },
                  '西峪水库': {
                    '汛限水位': '213.5米',
                    '当前水位': '212.51米',
                    '历史最高水位': '213.5米'
                  },
                  '遥桥峪水库': {
                    '汛限水位': '464.0米',
                    '当前水位': '461.34米',
                    '历史最高水位': '464.0米'
                  },
                  '斋堂水库': {
                    '汛限水位': '453.0米',
                    '当前水位': '451.27米',
                    '历史最高水位': '461.56米'
                  },
                  '珠窝水库': {
                    '汛限水位': '348.4米',
                    '当前水位': '346.69米',
                    '历史最高水位': '352.5米'
                  }
                };
                
                // 使用自定义弹窗内容，包含事件处理
                const popupContent = document.createElement('div');
                popupContent.innerHTML = `
                  <div class="monitoring-popup">
                    <div class="popup-header">
                      <h4>${pointName}</h4>
                    </div>
                    ${reservoirInfo[pointName] ? `
                      <div class="popup-section">
                        <h5>基本信息</h5>
                        <div class="info-grid">
                          <div class="info-item">
                            <span class="label">汛限水位:</span>
                            <span class="value">${reservoirInfo[pointName]['汛限水位']}</span>
                          </div>
                          <div class="info-item">
                            <span class="label">当前水位:</span>
                            <span class="value" id="current-level-${pointName}">${reservoirInfo[pointName]['当前水位']}</span>
                          </div>
                          <div class="info-item">
                            <span class="label">历史最高:</span>
                            <span class="value">${reservoirInfo[pointName]['历史最高水位']}</span>
                          </div>
                          ${reservoirInfo[pointName]['最低水位'] ? `
                          <div class="info-item">
                            <span class="label">最低水位:</span>
                            <span class="value">${reservoirInfo[pointName]['最低水位']}</span>
                          </div>
                          ` : ''}
                          ${reservoirInfo[pointName]['多年平均水位'] ? `
                          <div class="info-item">
                            <span class="label">多年平均:</span>
                            <span class="value">${reservoirInfo[pointName]['多年平均水位']}</span>
                          </div>
                          ` : ''}
                        </div>
                      </div>
                      
                      <div class="popup-section">
                        <div class="section-header">
                          <div class="section-icon">⚠️</div>
                          <h5>预警分析</h5>
                        </div>
                        <div class="warning-input-container">
                          <div class="input-group">
                            <input 
                              type="number" 
                              id="water-level-input-${pointName}" 
                              placeholder="请输入当前水位" 
                              step="0.01"
                              class="modern-input"
                            >
                          </div>
                          <button id="warning-btn-${pointName}" class="modern-warning-btn">
                            <span class="btn-icon">🔍</span>
                            <span class="btn-text">预警分析</span>
                          </button>
                        </div>
                      </div>
                    ` : ''}
                  </div>
                `;
                
                // 绑定弹窗
                layer.bindPopup(popupContent);
                
                // 添加弹窗打开后的事件监听
                layer.on('popupopen', (e) => {
                  const warningBtn = document.getElementById(`warning-btn-${pointName}`);
                  const waterLevelInput = document.getElementById(`water-level-input-${pointName}`);
                  const currentLevelElement = document.getElementById(`current-level-${pointName}`);
                  
                  if (warningBtn && waterLevelInput && reservoirInfo[pointName]) {
                    // 添加输入事件监听器，实时更新当前水位显示
                    waterLevelInput.addEventListener('input', (e) => {
                      const inputValue = parseFloat(e.target.value);
                      if (!isNaN(inputValue) && currentLevelElement) {
                        currentLevelElement.textContent = `${inputValue}米`;
                      } else if (e.target.value === '' && currentLevelElement) {
                        // 当输入框为空时，恢复显示原始水位
                        currentLevelElement.textContent = reservoirInfo[pointName]['当前水位'];
                      }
                    });
                    warningBtn.onclick = () => {
                      const inputValue = parseFloat(waterLevelInput.value);
                      if (isNaN(inputValue)) {
                        alert('请输入有效的水位数值');
                        return;
                      }
                      
                      // 显示加载进度条
                      warningBtn.innerHTML = `
                        <div class="loading-progress">
                          <div class="progress-bar">
                            <div class="progress-fill"></div>
                          </div>
                          <span class="loading-text">分析中...</span>
                        </div>
                      `;
                      warningBtn.disabled = true;
                      warningBtn.style.backgroundColor = '#999';
                      
                      // 关闭当前弹窗
                      map.closePopup();
                      
                      // 模拟加载过程
                      setTimeout(() => {
                      // 更新水库信息数据中的当前水位
                      reservoirInfo[pointName]['当前水位'] = `${inputValue}米`;
                      
                      // 实时更新弹窗中显示的当前水位
                      const currentLevelElement = document.getElementById(`current-level-${pointName}`);
                      if (currentLevelElement) {
                        currentLevelElement.textContent = `${inputValue}米`;
                      }
                      
                      const floodLimit = parseFloat(reservoirInfo[pointName]['汛限水位'].replace('米', ''));
                      const maxLevel = parseFloat(reservoirInfo[pointName]['历史最高水位'].replace('米', ''));
                        const avgLevel = reservoirInfo[pointName]['多年平均水位'] ? parseFloat(reservoirInfo[pointName]['多年平均水位'].replace('米', '')) : null;
                      
                      let newColor = '#FF5722'; // 默认橙色
                        let status = '';
                        let statusClass = '';
                      
                      // 停止之前的闪烁效果
                      if (layer.blinkInterval) {
                        clearInterval(layer.blinkInterval);
                        layer.blinkInterval = null;
                      }
                      
                      if (inputValue < floodLimit) {
                        newColor = '#2196F3'; // 蓝色
                          status = '正常';
                          statusClass = 'status-normal';
                        // 停止闪烁效果
                        layer.setStyle({
                          fillColor: newColor,
                          color: '#fff',
                          weight: 2,
                          opacity: 1,
                          fillOpacity: 0.95
                        });
                      } else if (inputValue >= floodLimit && inputValue < maxLevel) {
                        newColor = '#FFC107'; // 黄色
                          status = '警戒';
                          statusClass = 'status-warning';
                        // 停止闪烁效果
                        layer.setStyle({
                          fillColor: newColor,
                          color: '#fff',
                          weight: 2,
                          opacity: 1,
                          fillOpacity: 0.95
                        });
                      } else if (inputValue >= maxLevel) {
                        newColor = '#F44336'; // 红色
                          status = '危险';
                          statusClass = 'status-danger';
                        // 开始闪烁效果
                        let isVisible = true;
                        const blinkInterval = setInterval(() => {
                          isVisible = !isVisible;
                          layer.setStyle({
                            fillColor: newColor,
                            color: '#fff',
                            weight: 2,
                            opacity: isVisible ? 1 : 0.3,
                            fillOpacity: isVisible ? 0.95 : 0.3
                          });
                        }, 500); // 每500毫秒闪烁一次
                        
                        // 存储闪烁定时器，以便后续停止
                        layer.blinkInterval = blinkInterval;
                      }
                      
                        // 生成分析摘要和建议措施
                        const generateAnalysisSummary = (currentLevel, floodLimit, maxLevel, avgLevel, status) => {
                          let summary = '';
                          
                          if (status === '正常') {
                            const diffFromLimit = (floodLimit - currentLevel).toFixed(2);
                            summary = `当前水位${currentLevel}米低于汛限水位${floodLimit}米，水库运行状态正常。未超过汛限水位，与汛限水位相差${diffFromLimit}米。`;
                            
                            if (avgLevel) {
                              const diffFromAvg = (currentLevel - avgLevel).toFixed(2);
                              if (currentLevel < avgLevel) {
                                summary += `水位低于多年平均值${avgLevel}米${Math.abs(diffFromAvg)}米，建议适当蓄水。`;
                              } else {
                                summary += `水位高于多年平均值${avgLevel}米${diffFromAvg}米，但仍处于安全范围内。`;
                              }
                            }
                          } else if (status === '警戒') {
                            const overLimit = (currentLevel - floodLimit).toFixed(2);
                            const diffFromMax = (maxLevel - currentLevel).toFixed(2);
                            
                            summary = `当前水位${currentLevel}米已超过汛限水位${floodLimit}米，需要密切关注水位变化。超过汛限水位${overLimit}米，与最高水位差${diffFromMax}米。`;
                            
                            if (avgLevel) {
                              const diffFromAvg = (currentLevel - avgLevel).toFixed(2);
                              summary += `与平均水位差${diffFromAvg}米。`;
                            }
                            
                            if (currentLevel > maxLevel * 0.95) {
                              summary += `水位接近历史最高值，存在较大风险。`;
                            }
                          } else if (status === '危险') {
                            const overLimit = (currentLevel - floodLimit).toFixed(2);
                            const overMax = (currentLevel - maxLevel).toFixed(2);
                            
                            summary = `当前水位${currentLevel}米已超过历史最高水位${maxLevel}米，情况危急！超过汛限水位${overLimit}米，超过最高水位${overMax}米。`;
                            
                            if (avgLevel) {
                              const diffFromAvg = (currentLevel - avgLevel).toFixed(2);
                              summary += `与平均水位差${diffFromAvg}米。`;
                            }
                            
                            summary += `需要立即采取紧急措施，防止水库溃坝等重大事故。`;
                          }
                          
                          return summary;
                        };
                        
                        const generateRecommendations = (currentLevel, floodLimit, maxLevel, status) => {
                          let recommendations = [];
                          
                          if (status === '正常') {
                            recommendations = [
                              '继续正常监测水位变化',
                              '保持水库日常运行管理',
                              '定期检查水库设施设备',
                              '做好防汛物资储备'
                            ];
                          } else if (status === '警戒') {
                            recommendations = [
                              '加强水位监测频率（每小时一次）',
                              '启动防汛应急预案',
                              '检查泄洪设施是否正常',
                              '通知下游地区做好防洪准备',
                              '准备应急抢险队伍和物资'
                            ];
                          } else if (status === '危险') {
                            recommendations = [
                              '立即启动最高级别应急响应',
                              '紧急泄洪降低水位',
                              '疏散下游危险区域人员',
                              '通知相关部门启动应急预案',
                              '24小时不间断监测水位',
                              '准备抢险救援队伍待命'
                            ];
                          }
                          
                          return recommendations;
                        };
                        
                        // 准备分析结果数据并显示在模态框中
                        analysisData.value = {
                          pointName: pointName,
                          inputValue: inputValue,
                          status: status,
                          statusClass: statusClass,
                          floodLimit: floodLimit,
                          maxLevel: maxLevel,
                          avgLevel: avgLevel,
                          reservoirInfo: reservoirInfo[pointName],
                          summary: generateAnalysisSummary(inputValue, floodLimit, maxLevel, avgLevel, status)
                        };
                        
                        // 显示分析结果模态框
                        showAnalysisModal.value = true;
                        
                        // 设置初始位置，避免与预案窗口重叠
                        nextTick(() => {
                          if (analysisModalRef.value) {
                            const leftOffset = showPlanModal.value ? -250 : 0;
                            analysisModalRef.value.style.transform = `translate(${leftOffset}px, 0)`;
                            modalPosition.value = { x: leftOffset, y: 0 };
                          }
                        });
                        
                        // 恢复按钮状态
                        warningBtn.innerHTML = `
                          <span class="btn-icon">🔍</span>
                          <span class="btn-text">预警分析</span>
                        `;
                        warningBtn.disabled = false;
                        warningBtn.style.backgroundColor = '#2196F3';
                        
                        console.log(`监测点 ${pointName} 颜色已更新为: ${newColor}, 输入水位: ${inputValue}米, 状态: ${status}`);
                      }, 1000); // 1秒的加载时间，与进度条动画匹配
                    };
                  }
                });
              }
            }
          }).addTo(map);
          
          // 确保监测点在最上层
          mapLayers.monitoringPoints.bringToFront();
        }
        
        // 调整地图视图以适应所有图层
          const activeLayers = [];
          Object.values(mapLayers).forEach(layer => {
            if (layer) {
              activeLayers.push(layer);
            }
          });
          
          if (activeLayers.length > 0) {
            const group = L.featureGroup(activeLayers);
            map.fitBounds(group.getBounds());
        }
      } catch (error) {
        console.error('加载预警分析图层失败:', error);
      }
    };
    
    // 切换预警分析图层
    const toggleWarningLayer = (layerName) => {
      if (warningLayers.value[layerName]) {
        // 如果图层已被激活但尚未加载，则加载它
        if (!mapLayers[layerName]) {
          loadWarningLayers();
        } else {
          // 图层已存在，添加到地图并设置正确的层级顺序
          mapLayers[layerName].addTo(map);
          
          // 设置图层层级顺序：区县边界在最底层，监测点在最上层
          if (layerName === 'district') {
            // 区县边界放在最底层
            mapLayers[layerName].bringToBack();
            
            // 同时显示标注
            districtLabels.forEach(label => {
              if (!map.hasLayer(label)) {
                label.addTo(map);
              }
            });
          } else if (layerName === 'waterLine') {
            // 水系线放在区县边界之上
            if (mapLayers.district && map.hasLayer(mapLayers.district)) {
              mapLayers[layerName].bringToBack();
              mapLayers.district.bringToBack();
            }
          } else if (layerName === 'reservoir') {
            // 水库放在水系线之上
            if (mapLayers.waterLine && map.hasLayer(mapLayers.waterLine)) {
              mapLayers[layerName].bringToBack();
              mapLayers.waterLine.bringToBack();
            }
            if (mapLayers.district && map.hasLayer(mapLayers.district)) {
              mapLayers.district.bringToBack();
            }
          } else if (layerName === 'monitoringPoints') {
            // 监测点放在最上层
            mapLayers[layerName].bringToFront();
          }
          
          // 如果是监测点图层，重新加载以确保正确显示
          if (layerName === 'monitoringPoints') {
            loadWarningLayers();
          }
        }
      } else if (mapLayers[layerName]) {
        // 图层已被禁用且已加载，从地图移除
        map.removeLayer(mapLayers[layerName]);
        
        // 如果是区县图层，同时隐藏标注
        if (layerName === 'district') {
          districtLabels.forEach(label => {
            if (map.hasLayer(label)) {
              map.removeLayer(label);
            }
          });
        }
      }
    };

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

    // 关闭分析模态框
    const closeAnalysisModal = () => {
      showAnalysisModal.value = false;
      analysisData.value = null;
      // 重置模态框位置
      modalPosition.value = { x: 0, y: 0 };
      if (analysisModalRef.value) {
        analysisModalRef.value.style.transform = 'translate(0, 0)';
      }
      
      // 如果预案窗口还开着，将其居中
      if (showPlanModal.value && planModalRef.value) {
        nextTick(() => {
          planModalRef.value.style.transform = 'translate(0, 0)';
          planModalPosition.value = { x: 0, y: 0 };
        });
      }
    };

    // 拖拽功能
    const startDrag = (e) => {
      // 只有点击头部区域才能拖拽
      if (!e.target.closest('.analysis-modal-header')) {
        return;
      }
      
      isDragging.value = true;
      const rect = analysisModalRef.value.getBoundingClientRect();
      dragOffset.value = {
        x: e.clientX - rect.left,
        y: e.clientY - rect.top
      };
      
      document.addEventListener('mousemove', onDrag);
      document.addEventListener('mouseup', stopDrag);
      e.preventDefault();
    };

    const onDrag = (e) => {
      if (!isDragging.value) return;
      
      const newX = e.clientX - dragOffset.value.x;
      const newY = e.clientY - dragOffset.value.y;
      
      // 限制拖拽范围，确保模态框不会完全移出视窗
      const modalWidth = analysisModalRef.value.offsetWidth;
      const modalHeight = analysisModalRef.value.offsetHeight;
      const windowWidth = window.innerWidth;
      const windowHeight = window.innerHeight;
      
      const constrainedX = Math.max(-modalWidth + 100, Math.min(windowWidth - 100, newX));
      const constrainedY = Math.max(0, Math.min(windowHeight - 100, newY));
      
      modalPosition.value = { x: constrainedX, y: constrainedY };
      analysisModalRef.value.style.transform = `translate(${constrainedX}px, ${constrainedY}px)`;
    };

    const stopDrag = () => {
      isDragging.value = false;
      document.removeEventListener('mousemove', onDrag);
      document.removeEventListener('mouseup', stopDrag);
    };

    // 关闭预案模态框
    const closePlanModal = () => {
      showPlanModal.value = false;
      planData.value = null;
      // 重置预案模态框位置
      planModalPosition.value = { x: 0, y: 0 };
      if (planModalRef.value) {
        planModalRef.value.style.transform = 'translate(0, 0)';
      }
      
      // 如果分析窗口还开着，将其居中
      if (showAnalysisModal.value && analysisModalRef.value) {
        nextTick(() => {
          analysisModalRef.value.style.transform = 'translate(0, 0)';
          modalPosition.value = { x: 0, y: 0 };
        });
      }
    };

    // 预案模态框拖拽功能
    const startPlanDrag = (e) => {
      // 只有点击头部区域才能拖拽
      if (!e.target.closest('.analysis-modal-header')) {
        return;
      }
      
      isDragging.value = true;
      const rect = planModalRef.value.getBoundingClientRect();
      planDragOffset.value = {
        x: e.clientX - rect.left,
        y: e.clientY - rect.top
      };
      
      document.addEventListener('mousemove', onPlanDrag);
      document.addEventListener('mouseup', stopPlanDrag);
      e.preventDefault();
    };

    const onPlanDrag = (e) => {
      if (!isDragging.value) return;
      
      const newX = e.clientX - planDragOffset.value.x;
      const newY = e.clientY - planDragOffset.value.y;
      
      // 限制拖拽范围，确保模态框不会完全移出视窗
      const modalWidth = planModalRef.value.offsetWidth;
      const modalHeight = planModalRef.value.offsetHeight;
      const windowWidth = window.innerWidth;
      const windowHeight = window.innerHeight;
      
      const constrainedX = Math.max(-modalWidth + 100, Math.min(windowWidth - 100, newX));
      const constrainedY = Math.max(0, Math.min(windowHeight - 100, newY));
      
      planModalPosition.value = { x: constrainedX, y: constrainedY };
      planModalRef.value.style.transform = `translate(${constrainedX}px, ${constrainedY}px)`;
    };

    const stopPlanDrag = () => {
      isDragging.value = false;
      document.removeEventListener('mousemove', onPlanDrag);
      document.removeEventListener('mouseup', stopPlanDrag);
    };

    // 显示应急预案
    const showEmergencyPlan = (planType) => {
      const reservoirName = analysisData.value?.pointName || '未知水库';
      const currentLevel = analysisData.value?.inputValue || 0;
      const maxLevel = analysisData.value?.maxLevel || 0;
      
      let planTitle = '';
      let planMeasures = [];
      
      // 根据不同水库和预警级别设置具体预案
      const getReservoirPlans = (reservoir, type, currentLevel, maxLevel) => {
        // 检查是否超过历史最高水位3米
        const isOverMax3M = currentLevel > maxLevel + 3;
        
        const plans = {
          '密云水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游乡镇、北京市水务局滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启泄洪闸，控制下泄≤100m³/s',
              '保证下游河道不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知密云区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '洪水预警升级至最高级别',
              '自泄洪闸全开，逐级增大至1120m³/s（建库以来最大泄量）',
              '提前48h完成密云、怀柔、顺义、通州4区20余万人避险转移',
              '下游潮白河沿线堤防24h巡查、桥梁封闭、泵站预排',
              '启动国家级应急响应，请求中央支援',
              '建立跨省市联合指挥部，协调京津冀三地联动',
              '启用备用泄洪通道和应急溢洪道',
              '组织武警、消防、解放军等专业救援力量进驻',
              '启动直升机空中监测和救援',
              '建立临时医疗救治点和物资储备中心',
              '实施交通管制，确保救援通道畅通',
              '启动卫星通信和应急通信系统',
              '组织专家团队现场评估大坝安全状况',
              '准备启用下游蓄滞洪区进行分洪',
              '启动媒体24小时滚动播报，发布紧急通告'
            ] : [
              '开启全部泄洪闸，最大下泄500m³/s',
              '提前24小时组织下游密云、怀柔等区县人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          },
          '十三陵水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游昌平区防汛指挥部滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启溢洪道，控制下泄≤15m³/s',
              '保证下游东沙河不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知昌平区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '启动特级应急响应（最高级别）',
              '溢洪道全开，下泄30m³/s，启用备用溢洪道',
              '提前36h封闭东沙河沿线道路、转移昌平区沿河5村2000余人',
              '抢险队伍300人、砂石料5000t现场待命',
              '启动国家级应急响应，请求中央支援',
              '建立昌平区应急指挥部，协调全区力量',
              '启用直升机空中监测和救援',
              '组织武警、消防等专业救援力量进驻',
              '建立临时医疗救治点和物资储备中心',
              '实施交通管制，确保救援通道畅通',
              '启动卫星通信和应急通信系统',
              '组织专家团队现场评估大坝安全状况',
              '启动媒体24小时滚动播报，发布紧急通告',
              '协调周边水库联合调度，减轻压力',
              '准备启用下游蓄滞洪区进行分洪'
            ] : [
              '溢洪道全开，下泄25m³/s',
              '提前24小时组织东沙河沿线人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          },
          '官厅水库': {
            warning: [
              '加密大坝、泄洪闸巡检',
              '向永定河流域防汛指挥部和京津冀三地防指滚动通报',
              '启动二级应急响应',
              '每2小时向各级防汛部门报告水情',
              '检查泄洪设施运行状态',
              '通知下游永定河沿线做好防洪准备',
              '协调河北省张家口市联防联控',
              '准备应急抢险物资和队伍',
              '加强气象水文监测'
            ],
            danger: isOverMax3M ? [
              '京津冀三地联动特级响应（最高级别）',
              '最大下泄3500m³/s，启用所有泄洪设施',
              '永定河泛区、三角淀蓄滞洪区提前分洪',
              '固安、大兴等6乡镇2.1万人提前48h转移',
              '启动国家级应急响应，请求中央支援',
              '建立京津冀三地联合指挥部，协调三省力量',
              '启用备用泄洪通道和应急溢洪道',
              '组织武警、消防、解放军等专业救援力量进驻',
              '启动直升机空中监测和救援',
              '建立跨省市临时医疗救治点和物资储备中心',
              '实施跨省市交通管制，确保救援通道畅通',
              '启动卫星通信和应急通信系统',
              '组织国家级专家团队现场评估大坝安全状况',
              '启动媒体24小时滚动播报，发布紧急通告',
              '协调周边水库联合调度，减轻压力',
              '准备启用更多下游蓄滞洪区进行分洪',
              '建立跨省市应急物资调配机制'
            ] : [
              '开启全部泄洪孔，最大下泄3500m³/s',
              '下游永定河泛区、三角淀蓄滞洪区做好分洪准备',
              '提前48小时组织河北固安、北京大兴等6个乡镇2.1万人转移',
              '启动一级（最高级）应急响应',
              '实施24小时现场指挥',
              '协调京津冀三省市联合调度',
              '启动流域性应急广播系统',
              '建立跨省市医疗救援体系',
              '请求水利部和国家防总支援',
              '向国务院和相关省市政府紧急报告'
            ]
          },
          '海子水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游平谷区防汛指挥部滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启泄洪闸，控制下泄≤50m³/s',
              '保证下游河道不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知平谷区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '启动特级应急响应（最高级别）',
              '立即预腾库容，加大下泄削峰',
              '重点河段拉警戒线、设警示标志',
              '加密监测（小时级）',
              '断电时启用备用电源+移动发电机保障闸门启闭',
              '启动国家级应急响应，请求中央支援',
              '建立平谷区应急指挥部，协调全区力量',
              '启用备用泄洪通道和应急溢洪道',
              '组织武警、消防等专业救援力量进驻',
              '启动直升机空中监测和救援',
              '建立临时医疗救治点和物资储备中心',
              '实施交通管制，确保救援通道畅通',
              '启动卫星通信和应急通信系统',
              '组织专家团队现场评估大坝安全状况',
              '启动媒体24小时滚动播报，发布紧急通告',
              '协调周边水库联合调度，减轻压力',
              '准备启用下游蓄滞洪区进行分洪'
            ] : [
              '开启全部泄洪闸，最大下泄200m³/s',
              '提前24小时组织下游平谷区人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          },
          '白河堡水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游乡镇、北京市水务局、官厅水库管理处滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启泄洪洞，控制下泄≤20m³/s',
              '保证下游河道不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知延庆区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '启动特级应急响应（最高级别）',
              '泄洪洞与输水洞全开，最大下泄80m³/s，启用备用泄洪设施',
              '提前12小时组织白河峡谷及张山营镇5个险村680人转移',
              '请求市防指调派武警水电部队进驻坝区抢险',
              '启动一级（最高级）应急响应，实施24小时不间断监测',
              '启动国家级应急响应，请求中央支援',
              '建立延庆区应急指挥部，协调全区力量',
              '启用备用泄洪通道和应急溢洪道',
              '组织武警、消防等专业救援力量进驻',
              '启动直升机空中监测和救援',
              '建立临时医疗救治点和物资储备中心',
              '实施交通管制，确保救援通道畅通',
              '启动卫星通信和应急通信系统',
              '组织专家团队现场评估大坝安全状况',
              '启动媒体24小时滚动播报，发布紧急通告',
              '协调周边水库联合调度，减轻压力',
              '准备启用下游蓄滞洪区进行分洪'
            ] : [
              '泄洪洞与输水洞全开，最大下泄60m³/s',
              '提前12小时组织白河峡谷及张山营镇5个险村680人转移',
              '请求市防指调派武警水电部队进驻坝区抢险',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          },
          '怀柔水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游怀柔区防汛指挥部滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启泄洪闸，控制下泄≤30m³/s',
              '保证下游河道不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知怀柔区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '启动特级应急响应（最高级别）',
              '泄洪闸全开，最大下泄150m³/s，启用备用泄洪设施',
              '提前24小时组织怀柔区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测，协调下游河道清障',
              '启动国家级应急响应，请求中央支援',
              '建立怀柔区应急指挥部，协调全区力量',
              '启用备用泄洪通道和应急溢洪道',
              '组织武警、消防等专业救援力量进驻',
              '启动直升机空中监测和救援',
              '建立临时医疗救治点和物资储备中心',
              '实施交通管制，确保救援通道畅通',
              '启动卫星通信和应急通信系统',
              '组织专家团队现场评估大坝安全状况',
              '启动媒体24小时滚动播报，发布紧急通告',
              '协调周边水库联合调度，减轻压力',
              '准备启用下游蓄滞洪区进行分洪'
            ] : [
              '开启全部泄洪闸，最大下泄100m³/s',
              '提前24小时组织怀柔区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          },
          '北台上水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游怀柔区防汛指挥部滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启泄洪闸，控制下泄≤20m³/s',
              '保证下游河道不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知怀柔区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '启动特级应急响应（最高级别）',
              '泄洪闸全开，最大下泄80m³/s，启用备用泄洪设施',
              '提前24小时组织怀柔区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测，协调下游河道清障',
              '启动国家级应急响应，请求中央支援',
              '建立怀柔区应急指挥部，协调全区力量',
              '启用备用泄洪通道和应急溢洪道',
              '组织武警、消防等专业救援力量进驻',
              '启动直升机空中监测和救援',
              '建立临时医疗救治点和物资储备中心',
              '实施交通管制，确保救援通道畅通',
              '启动卫星通信和应急通信系统',
              '组织专家团队现场评估大坝安全状况',
              '启动媒体24小时滚动播报，发布紧急通告',
              '协调周边水库联合调度，减轻压力',
              '准备启用下游蓄滞洪区进行分洪'
            ] : [
              '开启全部泄洪闸，最大下泄60m³/s',
              '提前24小时组织怀柔区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          },
          '崇青水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游房山区防汛指挥部滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启泄洪闸，控制下泄≤25m³/s',
              '保证下游河道不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知房山区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '启动特级应急响应（最高级别）',
              '泄洪闸全开，最大下泄100m³/s，启用备用泄洪设施',
              '提前24小时组织房山区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测，协调下游河道清障',
              '启动国家级应急响应，请求中央支援',
              '建立房山区应急指挥部，协调全区力量',
              '启用备用泄洪通道和应急溢洪道',
              '组织武警、消防等专业救援力量进驻',
              '启动直升机空中监测和救援',
              '建立临时医疗救治点和物资储备中心',
              '实施交通管制，确保救援通道畅通',
              '启动卫星通信和应急通信系统',
              '组织专家团队现场评估大坝安全状况',
              '启动媒体24小时滚动播报，发布紧急通告',
              '协调周边水库联合调度，减轻压力',
              '准备启用下游蓄滞洪区进行分洪'
            ] : [
              '开启全部泄洪闸，最大下泄80m³/s',
              '提前24小时组织房山区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          },
          '大宁水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游丰台区防汛指挥部滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启泄洪闸，控制下泄≤30m³/s',
              '保证下游河道不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知丰台区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '启动特级应急响应（最高级别）',
              '泄洪闸全开，最大下泄120m³/s，启用备用泄洪设施',
              '提前24小时组织丰台区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测，协调下游河道清障',
              '启动国家级应急响应，请求中央支援',
              '建立丰台区应急指挥部，协调全区力量',
              '启用备用泄洪通道和应急溢洪道',
              '组织武警、消防等专业救援力量进驻',
              '启动直升机空中监测和救援',
              '建立临时医疗救治点和物资储备中心',
              '实施交通管制，确保救援通道畅通',
              '启动卫星通信和应急通信系统',
              '组织专家团队现场评估大坝安全状况',
              '启动媒体24小时滚动播报，发布紧急通告',
              '协调周边水库联合调度，减轻压力',
              '准备启用下游蓄滞洪区进行分洪'
            ] : [
              '开启全部泄洪闸，最大下泄100m³/s',
              '提前24小时组织丰台区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          },
          '大水峪水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游怀柔区防汛指挥部滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启泄洪闸，控制下泄≤25m³/s',
              '保证下游河道不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知怀柔区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '启动特级应急响应（最高级别）',
              '泄洪闸全开，最大下泄100m³/s，启用备用泄洪设施',
              '提前24小时组织怀柔区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测，协调下游河道清障',
              '启动国家级应急响应，请求中央支援',
              '建立怀柔区应急指挥部，协调全区力量',
              '启用备用泄洪通道和应急溢洪道',
              '组织武警、消防等专业救援力量进驻',
              '启动直升机空中监测和救援',
              '建立临时医疗救治点和物资储备中心',
              '实施交通管制，确保救援通道畅通',
              '启动卫星通信和应急通信系统',
              '组织专家团队现场评估大坝安全状况',
              '启动媒体24小时滚动播报，发布紧急通告',
              '协调周边水库联合调度，减轻压力',
              '准备启用下游蓄滞洪区进行分洪'
            ] : [
              '开启全部泄洪闸，最大下泄80m³/s',
              '提前24小时组织怀柔区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          },
          '黄松峪水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游平谷区防汛指挥部滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启泄洪闸，控制下泄≤20m³/s',
              '保证下游河道不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知平谷区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '启动特级应急响应（最高级别）',
              '泄洪闸全开，最大下泄80m³/s，启用备用泄洪设施',
              '提前24小时组织平谷区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测，协调下游河道清障',
              '启动国家级应急响应，请求中央支援',
              '建立平谷区应急指挥部，协调全区力量',
              '启用备用泄洪通道和应急溢洪道',
              '组织武警、消防等专业救援力量进驻',
              '启动直升机空中监测和救援',
              '建立临时医疗救治点和物资储备中心',
              '实施交通管制，确保救援通道畅通',
              '启动卫星通信和应急通信系统',
              '组织专家团队现场评估大坝安全状况',
              '启动媒体24小时滚动播报，发布紧急通告',
              '协调周边水库联合调度，减轻压力',
              '准备启用下游蓄滞洪区进行分洪'
            ] : [
              '开启全部泄洪闸，最大下泄60m³/s',
              '提前24小时组织平谷区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          },
          '沙厂水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游密云区防汛指挥部滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启泄洪闸，控制下泄≤25m³/s',
              '保证下游河道不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知密云区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '启动特级应急响应（最高级别）',
              '泄洪闸全开，最大下泄100m³/s，启用备用泄洪设施',
              '提前24小时组织密云区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测，协调下游河道清障',
              '启动国家级应急响应，请求中央支援',
              '建立密云区应急指挥部，协调全区力量',
              '启用备用泄洪通道和应急溢洪道',
              '组织武警、消防等专业救援力量进驻',
              '启动直升机空中监测和救援',
              '建立临时医疗救治点和物资储备中心',
              '实施交通管制，确保救援通道畅通',
              '启动卫星通信和应急通信系统',
              '组织专家团队现场评估大坝安全状况',
              '启动媒体24小时滚动播报，发布紧急通告',
              '协调周边水库联合调度，减轻压力',
              '准备启用下游蓄滞洪区进行分洪'
            ] : [
              '开启全部泄洪闸，最大下泄80m³/s',
              '提前24小时组织密云区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          },
          '桃峪口水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游昌平区防汛指挥部滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启泄洪闸，控制下泄≤20m³/s',
              '保证下游河道不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知昌平区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '泄洪闸全开，最大下泄80m³/s',
              '提前24小时组织昌平区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测，协调下游河道清障'
            ] : [
              '开启全部泄洪闸，最大下泄60m³/s',
              '提前24小时组织昌平区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          },
          '西峪水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游平谷区防汛指挥部滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启泄洪闸，控制下泄≤20m³/s',
              '保证下游河道不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知平谷区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '启动特级应急响应（最高级别）',
              '泄洪闸全开，最大下泄80m³/s，启用备用泄洪设施',
              '提前24小时组织平谷区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测，协调下游河道清障',
              '启动国家级应急响应，请求中央支援',
              '建立平谷区应急指挥部，协调全区力量',
              '启用备用泄洪通道和应急溢洪道',
              '组织武警、消防等专业救援力量进驻',
              '启动直升机空中监测和救援',
              '建立临时医疗救治点和物资储备中心',
              '实施交通管制，确保救援通道畅通',
              '启动卫星通信和应急通信系统',
              '组织专家团队现场评估大坝安全状况',
              '启动媒体24小时滚动播报，发布紧急通告',
              '协调周边水库联合调度，减轻压力',
              '准备启用下游蓄滞洪区进行分洪'
            ] : [
              '开启全部泄洪闸，最大下泄60m³/s',
              '提前24小时组织平谷区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          },
          '遥桥峪水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游密云区防汛指挥部滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启泄洪闸，控制下泄≤20m³/s',
              '保证下游河道不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知密云区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '泄洪闸全开，最大下泄80m³/s',
              '提前24小时组织密云区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测，协调下游河道清障'
            ] : [
              '开启全部泄洪闸，最大下泄60m³/s',
              '提前24小时组织密云区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          },
          '斋堂水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游门头沟区防汛指挥部滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启泄洪闸，控制下泄≤20m³/s',
              '保证下游河道不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知门头沟区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '泄洪闸全开，最大下泄80m³/s',
              '提前24小时组织门头沟区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测，协调下游河道清障'
            ] : [
              '开启全部泄洪闸，最大下泄60m³/s',
              '提前24小时组织门头沟区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          },
          '珠窝水库': {
            warning: [
              '加密大坝巡查（2小时一次）',
              '向下游门头沟区防汛指挥部滚动报送水情',
              '启动二级应急响应',
              '视雨情提前6小时开启泄洪闸，控制下泄≤20m³/s',
              '保证下游河道不超警戒流量',
              '加强气象监测和预报',
              '检查泄洪设施运行状态',
              '通知门头沟区防汛指挥部',
              '准备应急抢险物资和队伍'
            ],
            danger: isOverMax3M ? [
              '泄洪闸全开，最大下泄80m³/s',
              '提前24小时组织门头沟区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测，协调下游河道清障'
            ] : [
              '开启全部泄洪闸，最大下泄60m³/s',
              '提前24小时组织门头沟区沿河人员转移',
              '启动一级（最高级）应急响应',
              '实施24小时不间断监测',
              '协调下游河道清障和分洪准备',
              '启动应急广播和预警信号',
              '建立现场指挥部',
              '联系医疗救援和后勤保障队伍',
              '向市委市政府紧急报告'
            ]
          }
        };
        
        return plans[reservoir]?.[type] || [];
      };
      
      if (planType === 'warning') {
        planTitle = `${reservoirName} - 警戒水位应急预案`;
        planMeasures = getReservoirPlans(reservoirName, 'warning', currentLevel, maxLevel);
      } else if (planType === 'danger') {
        planTitle = `${reservoirName} - 危险水位应急预案`;
        planMeasures = getReservoirPlans(reservoirName, 'danger', currentLevel, maxLevel);
      }
      
      // 如果没有找到对应水库的预案，使用通用预案
      if (planMeasures.length === 0) {
        if (planType === 'warning') {
          planMeasures = [
            '立即启动二级应急响应',
            '加强水位监测，每30分钟上报一次水位数据',
            '检查并准备启用泄洪设施',
            '通知下游相关部门和居民做好防洪准备',
            '调度应急抢险队伍和物资到位',
            '密切关注天气变化，做好预测预报',
            '按规定向上级部门报告水情险情',
            '准备启动下一级应急响应措施'
          ];
        } else {
          planMeasures = [
            '立即启动一级（最高级）应急响应',
            '紧急开启所有泄洪设施，最大流量泄洪',
            '立即疏散下游危险区域所有人员',
            '24小时不间断监测水位变化',
            '启动应急抢险救援队伍，现场待命',
            '立即向省市防汛指挥部报告紧急情况',
            '协调周边水库联合调度，减轻压力',
            '准备水库大坝抢险应急措施',
            '启动媒体预警，发布紧急通告',
            '联系武警、消防等专业救援力量'
          ];
        }
      }
      
      // 设置预案数据并显示模态框
      planData.value = {
        title: planTitle,
        type: planType,
        reservoirName: reservoirName,
        currentLevel: currentLevel,
        measures: planMeasures
      };
      
      showPlanModal.value = true;
      
      // 使用 requestAnimationFrame 优化位置设置，减少卡顿
      requestAnimationFrame(() => {
        if (planModalRef.value) {
          const rightOffset = showAnalysisModal.value ? 250 : 0;
          planModalRef.value.style.transform = `translate(${rightOffset}px, 0)`;
          planModalPosition.value = { x: rightOffset, y: 0 };
        }
      });
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
      
      // 如果是预警分析相关功能，加载地图图层
      if (feature === 'warning' || feature === 'waterLevelWarning' || feature === 'environmentWarning') {
        // 清除现有图层
        Object.values(mapLayers).forEach(layer => {
          if (layer) {
            map.removeLayer(layer);
          }
        });
        
        // 重新加载图层
        loadWarningLayers();
      }
    };

    onMounted(() => {
      // 确保地图容器已渲染后再初始化地图
      setTimeout(() => {
        initMap();
        // 自动激活水位预警功能
        activateFeature('waterLevelWarning');
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
      // 清除所有图层
      Object.values(mapLayers).forEach(layer => {
        if (layer) {
          layer.remove();
        }
      });
      // 清除区县标注
      districtLabels.forEach(label => {
        if (label) {
          label.remove();
        }
      });
      districtLabels = [];
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
      // 预警分析子菜单

      // 预警分析相关
      warningLayers,
      layerColors,
      toggleWarningLayer,
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
      // 分析模态框相关
      showAnalysisModal,
      analysisData,
      analysisModalRef,
      closeAnalysisModal,
      showEmergencyPlan,
      startDrag,
      // 预案模态框相关
      showPlanModal,
      planData,
      planModalRef,
      closePlanModal,
      startPlanDrag

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

/* 缩放控件位置调整 */
:deep(.leaflet-top.leaflet-left .leaflet-control-zoom) {
  margin-left: 20px !important;
  margin-top: 20px !important;
  z-index: 1100;
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
/* 删除了折叠栏相关样式 */

/* 预警分析面板样式 */
/* .warning-panel {
  position: absolute;
  top: 20px;
  right: 20px;
  width: 300px;
  background-color: rgba(255, 255, 255, 0.9);
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.15);
  padding: 15px;
  z-index: 1000;
}

.panel-header {
  border-bottom: 1px solid #eee;
  padding-bottom: 10px;
  margin-bottom: 15px;
}

.panel-title {
  font-size: 18px;
  font-weight: bold;
  margin: 0;
  color: #1976d2;
}

.layer-controls {
  margin-top: 15px;
}

.layer-controls h4 {
  font-size: 16px;
  margin-bottom: 10px;
  color: #333;
} */

/* 图层控制面板样式（与地图编辑页面保持一致） */
.control-panel {
  position: absolute;
  top: 32px;
  right: 32px;
  background: rgba(255,255,255,0.97);
  border-radius: 16px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.10);
  padding: 20px 28px 20px 24px;
  z-index: 1000;
  min-width: 220px;
  max-width: 360px;
  width: auto;
  font-size: 16px;
}

.layer-control {
  margin-bottom: 8px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.layer-color-control {
  display: flex;
  align-items: center;
  gap: 8px;
}

.color-preview {
  width: 20px;
  height: 20px;
  border-radius: 4px;
  border: 2px solid #ddd;
  cursor: pointer;
  transition: border-color 0.2s;
}

.color-preview:hover {
  border-color: #999;
}

.color-preview.point-preview {
  border-radius: 50%;
}

/* 区县名称标注样式 */
:deep(.district-label) {
  background: transparent;
  border: none;
}

:deep(.district-label div) {
  color: #1976D2;
  font-weight: bold;
  font-size: 12px;
  text-align: center;
  white-space: nowrap;
  pointer-events: none;
  text-shadow: 
    -1px -1px 0 #fff,
    -1px 1px 0 #fff,
    1px -1px 0 #fff,
    1px 1px 0 #fff;
}





/* 监测点弹窗样式 */
.monitoring-popup {
  min-width: 320px;
  max-width: 400px;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: white;
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.12);
  overflow: hidden;
  border: 1px solid rgba(0, 0, 0, 0.08);
  padding: 20px;
}

.popup-header {
  border-bottom: 2px solid #1976d2;
  padding-bottom: 12px;
  margin-bottom: 16px;
  text-align: center;
}

.popup-header h4 {
  margin: 0;
  color: #1976d2;
  font-size: 18px;
  font-weight: 700;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
  letter-spacing: 0.5px;
}

.popup-section {
  margin-bottom: 16px;
}

.popup-section h5 {
  margin: 0 0 8px 0;
  font-size: 14px;
  color: #333;
  font-weight: 600;
}

.info-grid {
  display: grid;
  gap: 8px;
  background: #f8f9fa;
  border-radius: 12px;
  padding: 12px;
  border: 1px solid #e9ecef;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  background: white;
  border-radius: 8px;
  border: 1px solid #f0f0f0;
  transition: all 0.2s ease;
}

.info-item:hover {
  border-color: #1976d2;
  box-shadow: 0 2px 8px rgba(25, 118, 210, 0.1);
  transform: translateY(-1px);
}

.info-item .label {
  font-size: 13px;
  color: #555;
  flex: 1;
  font-weight: 500;
}

.info-item .value {
  font-size: 13px;
  color: #1976d2;
  font-weight: 600;
  flex: 1;
  text-align: right;
}

/* 现代化预警分析输入样式 */
.warning-input-container {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 16px;
}

.input-group {
  position: relative;
  display: flex;
  align-items: center;
  background: #f8f9fa;
  border: 2px solid #e9ecef;
  border-radius: 12px;
  padding: 4px;
  transition: all 0.3s ease;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  flex-direction: row; /* 确保水平排列 */
}

.input-group:focus-within {
  border-color: #1976d2;
  background: white;
  box-shadow: 0 4px 16px rgba(25, 118, 210, 0.15);
  transform: translateY(-1px);
}

/* 移除图标样式 */

.modern-input {
  flex: 1;
  border: none;
  background: transparent;
  padding: 8px 12px;
  font-size: 14px;
  color: #333;
  outline: none;
  font-weight: 500;
  height: 32px; /* 确保与单位标签高度一致 */
  box-sizing: border-box;
  display: inline-block; /* 确保内联显示 */
}

.modern-input::placeholder {
  color: #999;
  font-weight: 400;
}

.input-unit {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 32px;
  margin-right: 8px;
  background: rgba(25, 118, 210, 0.1);
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  color: #1976d2;
  flex-shrink: 0;
  align-self: center; /* 确保与输入框垂直居中对齐 */
  display: inline-block; /* 确保内联显示 */
}

.modern-warning-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 12px 20px;
  background: linear-gradient(135deg, #1976d2, #2196F3);
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 12px rgba(25, 118, 210, 0.3);
  position: relative;
  overflow: hidden;
}

.modern-warning-btn::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
  transition: left 0.5s;
}

.modern-warning-btn:hover::before {
  left: 100%;
}

.modern-warning-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(25, 118, 210, 0.4);
  background: linear-gradient(135deg, #1565c0, #1976d2);
}

.modern-warning-btn:active {
  transform: translateY(0);
  box-shadow: 0 2px 8px rgba(25, 118, 210, 0.3);
}

.modern-warning-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

.modern-warning-btn:disabled::before {
  display: none;
}

.btn-icon {
  font-size: 16px;
  line-height: 1;
}

.btn-text {
  font-weight: 600;
  letter-spacing: 0.5px;
}

/* 加载进度条样式 */
.loading-progress {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  width: 100%;
}

.progress-bar {
  width: 100%;
  height: 4px;
  background: rgba(255, 255, 255, 0.3);
  border-radius: 2px;
  overflow: hidden;
  position: relative;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #4CAF50, #8BC34A);
  border-radius: 2px;
  width: 0%;
  animation: progressAnimation 1s ease-in-out forwards;
}

@keyframes progressAnimation {
  0% {
    width: 0%;
  }
  100% {
    width: 100%;
  }
}

.loading-text {
  font-size: 12px;
  color: white;
  font-weight: 500;
}

/* 弹窗标题样式 */
.section-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 16px;
  padding-bottom: 8px;
  border-bottom: 2px solid #f0f0f0;
}

.section-icon {
  font-size: 18px;
  line-height: 1;
}

.section-header h5 {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: #1976d2;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

/* 保留原有样式作为备用 */
.warning-input {
  display: flex;
  gap: 8px;
  margin-bottom: 12px;
}

.warning-input input {
  flex: 1;
  padding: 6px 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 12px;
}

.warning-input input:focus {
  outline: none;
  border-color: #1976d2;
  box-shadow: 0 0 0 2px rgba(25, 118, 210, 0.2);
}

.warning-btn {
  padding: 6px 12px;
  background: #1976d2;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  transition: background-color 0.2s;
  white-space: nowrap;
}

.warning-btn:hover {
  background: #1565c0;
}

.warning-btn:disabled {
  background: #999;
  cursor: not-allowed;
}

.analysis-result {
  margin-top: 12px;
  padding: 12px;
  background: #f8f9fa;
  border-radius: 6px;
  border-left: 3px solid #1976d2;
}

.analysis-content {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.status-display {
  text-align: center;
  margin-bottom: 8px;
}

.status-indicator {
  display: inline-block;
  padding: 4px 12px;
  border-radius: 12px;
  font-weight: bold;
  font-size: 12px;
}

.status-normal {
  background: #e8f5e9;
  color: #2e7d32;
}

.status-warning {
  background: #fff3cd;
  color: #f57c00;
}

.status-danger {
  background: #ffebee;
  color: #c62828;
}

.water-level-comparison h6,
.analysis-summary h6,
.recommendations h6 {
  margin: 0 0 6px 0;
  font-size: 12px;
  color: #333;
  font-weight: 600;
}

.comparison-grid {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.comparison-row {
  display: flex;
  align-items: center;
  padding: 2px 0;
  font-size: 11px;
}

.comparison-row .label {
  flex: 1;
  color: #666;
}

.comparison-row .value {
  flex: 1;
  font-weight: 500;
  text-align: center;
}

.comparison-row .value.current {
  color: #1976d2;
}

.comparison-row .value.limit {
  color: #ff9800;
}

.comparison-row .value.max {
  color: #f44336;
}

.comparison-row .value.avg {
  color: #4caf50;
}



/* 水位对比表格样式 */
.water-level-comparison {
  margin: 16px 0;
  background: #f8f9fa;
  border-radius: 6px;
  padding: 12px;
}

.water-level-comparison h5 {
  margin: 0 0 10px 0;
  color: #1976d2;
  font-size: 14px;
  font-weight: 600;
}

.comparison-table {
  background: white;
  border-radius: 6px;
  overflow: hidden;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.comparison-row {
  display: flex;
  align-items: center;
  padding: 8px 12px;
  border-bottom: 1px solid #eee;
}

.comparison-row:last-child {
  border-bottom: none;
}

.comparison-row.header {
  background: #1976d2;
  color: white;
  font-weight: 600;
  font-size: 14px;
}

.comparison-row.current-row {
  background: #e3f2fd;
  font-weight: 600;
}

.comparison-row .label {
  flex: 2;
  font-size: 13px;
}

.comparison-row .value {
  flex: 1;
  text-align: center;
  font-weight: 500;
  font-size: 13px;
}

.comparison-row .difference {
  flex: 1.5;
  text-align: right;
  font-weight: 600;
  font-size: 13px;
}



.comparison-row .difference.above {
  color: #f44336;
}

.comparison-row .difference.below {
  color: #4caf50;
}

/* 应急预案按钮样式 */
.emergency-plan-section {
  margin-top: 16px;
  display: flex;
  justify-content: center;
}

.emergency-plan-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 18px;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 3px 8px rgba(0, 0, 0, 0.15);
  position: relative;
  overflow: hidden;
  min-width: 160px;
  justify-content: center;
}

.emergency-plan-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.25);
}

.emergency-plan-btn:active {
  transform: translateY(0);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

.emergency-plan-btn.warning-plan {
  background: #ff9800; /* 简化渐变，减少计算 */
  color: white;
}

.emergency-plan-btn.warning-plan:hover {
  background: #f57c00; /* 简化渐变，减少计算 */
}

.emergency-plan-btn.danger-plan {
  background: #f44336; /* 简化渐变，减少计算 */
  color: white;
  /* 移除动画，减少卡顿 */
}

.emergency-plan-btn.danger-plan:hover {
  background: #d32f2f; /* 简化渐变，减少计算 */
}

@keyframes dangerPulse {
  0%, 100% {
    box-shadow: 0 4px 12px rgba(244, 67, 54, 0.3);
  }
  50% {
    box-shadow: 0 4px 20px rgba(244, 67, 54, 0.6);
  }
}

.plan-icon {
  font-size: 20px;
  font-style: normal;
}

.emergency-plan-btn span {
  flex: 1;
  text-align: center;
  letter-spacing: 0.5px;
}

.arrow-icon {
  font-size: 18px;
  font-style: normal;
  transition: transform 0.3s ease;
}

.emergency-plan-btn:hover .arrow-icon {
  transform: translateX(4px);
}

/* 预案模态框特有样式 */
.plan-info-section {
  margin-bottom: 16px;
  text-align: center;
}

.plan-status-indicator {
  display: inline-block;
  padding: 8px 16px;
  border-radius: 20px;
  font-size: 14px;
  font-weight: 600;
  color: white;
}

.plan-status-indicator.status-warning {
  background: #ff9800; /* 简化渐变，减少计算 */
}

.plan-status-indicator.status-danger {
  background: #f44336; /* 简化渐变，减少计算 */
}

.current-level-info {
  background: #f8f9fa;
  border-radius: 6px;
  padding: 12px;
  margin-bottom: 16px;
}

.current-level-info h5 {
  margin: 0 0 8px 0;
  color: #1976d2;
  font-size: 14px;
  font-weight: 600;
}

.level-info-content p {
  margin: 4px 0;
  font-size: 13px;
  color: #333;
}

.level-info-content strong {
  color: #1976d2;
}

.emergency-measures h5 {
  margin: 0 0 12px 0;
  color: #1976d2;
  font-size: 14px;
  font-weight: 600;
}

.measures-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.measure-item {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 6px;
  background: white;
  border-left: 3px solid;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.measure-item.warning-measure {
  border-left-color: #ff9800;
}

.measure-item.danger-measure {
  border-left-color: #f44336;
}

.measure-number {
  flex-shrink: 0;
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  font-size: 11px;
  font-weight: 600;
  color: white;
}

.warning-measure .measure-number {
  background: #ff9800;
}

.danger-measure .measure-number {
  background: #f44336;
}

.measure-content {
  flex: 1;
  font-size: 13px;
  line-height: 1.4;
  color: #333;
}

.summary-text {
  font-size: 11px;
  line-height: 1.4;
  color: #333;
  background: white;
  padding: 8px;
  border-radius: 4px;
  border-left: 2px solid #1976d2;
}

.recommendation-items {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.recommendation-item {
  font-size: 11px;
  line-height: 1.3;
  color: #333;
  padding-left: 8px;
  border-left: 2px solid #ff9800;
  background: white;
  padding: 6px 8px;
  border-radius: 4px;
}

/* 分析弹窗样式 */
.analysis-modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: transparent;
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 10000;
  pointer-events: none;
  /* 移除动画，减少卡顿 */
  opacity: 1;
}

/* 预案模态框特殊定位 */
.analysis-modal.plan-modal {
  z-index: 10001;
  /* 添加硬件加速，减少卡顿 */
  transform: translateZ(0);
  will-change: transform;
}

.analysis-modal-content {
  background: white;
  border-radius: 8px;
  width: 450px;
  max-width: 85vw;
  max-height: 70vh;
  overflow-y: auto;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25);
  /* 移除动画，减少卡顿 */
  position: relative;
  cursor: move;
  pointer-events: auto;
  border: 2px solid rgba(25, 118, 210, 0.2);
  /* 添加硬件加速 */
  transform: translateZ(0);
  will-change: transform;
}

.analysis-modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid #eee;
  background: #1976d2; /* 简化渐变，减少计算 */
  color: white;
  border-radius: 8px 8px 0 0;
  cursor: move;
  user-select: none;
  position: relative;
  /* 添加硬件加速 */
  transform: translateZ(0);
}

.analysis-modal-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  flex: 1;
  text-align: center;
}

/* 拖拽手柄样式 */
.drag-handle {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
}

.drag-dots {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 2px;
  width: 16px;
  height: 12px;
}

.drag-dots span {
  width: 3px;
  height: 3px;
  background: rgba(255, 255, 255, 0.7);
  border-radius: 50%;
  transition: background 0.2s ease;
}

.analysis-modal-header:hover .drag-dots span {
  background: rgba(255, 255, 255, 0.9);
}

.analysis-modal-body {
  padding: 16px 20px;
  /* 添加性能优化 */
  contain: layout style;
  will-change: auto;
}

.close-btn {
  background: none;
  border: none;
  color: white;
  font-size: 24px;
  cursor: pointer;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: background-color 0.2s;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.2);
}

.analysis-modal-body {
  padding: 24px;
}

.status-display-section {
  text-align: center;
  margin-bottom: 24px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

.status-indicator {
  padding: 8px 16px;
  border-radius: 20px;
  font-weight: bold;
  font-size: 14px;
}

.status-normal {
  background: #e8f5e9;
  color: #2e7d32;
}

.status-warning {
  background: #fff3cd;
  color: #f57c00;
}

.status-danger {
  background: #ffebee;
  color: #c62828;
}

.water-level-comparison {
  margin-bottom: 24px;
}

.water-level-comparison h5 {
  margin: 0 0 16px 0;
  font-size: 16px;
  color: #333;
  font-weight: 600;
}

.comparison-item {
  display: flex;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #f0f0f0;
}

.comparison-item:last-child {
  border-bottom: none;
}

.comparison-item .label {
  flex: 1;
  font-size: 14px;
  color: #666;
}

.comparison-item .value {
  flex: 1;
  font-size: 16px;
  font-weight: 600;
  text-align: center;
}

.comparison-item .value.current {
  color: #1976d2;
}

.comparison-item .value.limit {
  color: #ff9800;
}

.comparison-item .value.max {
  color: #f44336;
}

.comparison-item .value.avg {
  color: #4caf50;
}

.comparison-item .difference {
  flex: 1;
  font-size: 14px;
  font-weight: 600;
  text-align: right;
}

.comparison-item .difference.above {
  color: #f44336;
}

.comparison-item .difference.below {
  color: #4caf50;
}

.analysis-summary {
  margin-bottom: 24px;
}

.analysis-summary h5 {
  margin: 0 0 12px 0;
  font-size: 16px;
  color: #333;
  font-weight: 600;
}

.summary-content {
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
  font-size: 14px;
  line-height: 1.6;
  color: #333;
  border-left: 4px solid #1976d2;
}

.recommendations {
  margin-bottom: 24px;
}

.recommendations h5 {
  margin: 0 0 12px 0;
  font-size: 16px;
  color: #333;
  font-weight: 600;
}

.recommendation-list {
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
  border-left: 4px solid #ff9800;
}

.recommendation-item {
  margin-bottom: 8px;
  font-size: 14px;
  line-height: 1.5;
  color: #333;
}

.recommendation-item:last-child {
  margin-bottom: 0;
}

.analysis-modal-footer {
  padding: 16px 24px;
  border-top: 1px solid #eee;
  text-align: center;
}

.btn-close {
  background: #1976d2;
  color: white;
  border: none;
  padding: 12px 32px;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.2s;
}

.btn-close:hover {
  background: #1565c0;
}

/* 移除动画关键帧，减少CSS计算 */

/* 子菜单样式 */
.submenu {
  margin-left: 20px;
  margin-top: 5px;
  margin-bottom: 5px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.submenu-item {
  display: flex;
  align-items: center;
  padding: 8px 10px;
  border-radius: 6px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.submenu-item:hover {
  background-color: rgba(0, 0, 0, 0.05);
}

/* 子菜单图标样式 */
.submenu-icon {
  width: 18px;
  height: 18px;
  margin-right: 10px;
  background-position: center;
  background-repeat: no-repeat;
  background-size: contain;
}

/* 水位预警图标 */
.water-level-icon {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%230288d1'%3E%3Cpath d='M12 3.77L11.25 4.61C11.25 4.61 9.97 6.06 8.68 7.94C7.39 9.82 6 12.07 6 14.23C6 17.88 8.69 21 12 21C15.31 21 18 17.88 18 14.23C18 12.07 16.61 9.82 15.32 7.94C14.03 6.06 12.75 4.61 12.75 4.61L12 3.77M12 6.9C12.44 7.42 12.84 7.85 13.68 9.07C14.89 10.83 16 13.07 16 14.23C16 16.9 14.22 18.97 12 18.97C9.78 18.97 8 16.9 8 14.23C8 13.07 9.11 10.83 10.32 9.07C11.16 7.85 11.56 7.42 12 6.9M11.5 14C12.03 14 12.5 13.58 12.5 13L12.5 10C12.5 9.42 12.03 9 11.5 9C10.97 9 10.5 9.42 10.5 10L10.5 13C10.5 13.58 10.97 14 11.5 14M15 14.5C15.28 14.5 15.5 14.28 15.5 14C15.5 13.72 15.28 13.5 15 13.5L14 13.5C13.72 13.5 13.5 13.72 13.5 14C13.5 14.28 13.72 14.5 14 14.5L15 14.5Z'/%3E%3C/svg%3E");
}

/* 环境预警图标 */
.environment-icon {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%2343a047'%3E%3Cpath d='M15 6.94L13.11 5.05L10.5 7.67L8.89 6.06L7 7.94L10.5 11.44L15 6.94M12 2C8.14 2 5 5.14 5 9C5 10.04 5.19 11.03 5.54 11.95L12 23L18.46 11.95C18.81 11.03 19 10.04 19 9C19 5.14 15.86 2 12 2M14.57 14H9.43L7.96 11.23C7.68 10.64 7.5 9.85 7.5 9C7.5 6.5 9.5 4.5 12 4.5S16.5 6.5 16.5 9C16.5 9.85 16.32 10.64 16.04 11.23L14.57 14Z'/%3E%3C/svg%3E");
}

.submenu-text {
  font-size: 13px;
  color: #555;
}

</style> 
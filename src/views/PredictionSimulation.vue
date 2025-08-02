<template>
  <div class="prediction-simulation-container">
    <prediction-simulation-header title="预测模拟"></prediction-simulation-header>
    
    <div class="prediction-simulation-content">
      <!-- 显示地图 (现在无论什么功能都会显示地图) -->
      <div id="prediction-map" class="prediction-map"></div>
      
      <!-- 图层控制面板 (水平排列在地图上方) -->
      <div class="layer-controls-horizontal" v-if="activeFeature === 'warning' || activeFeature === 'waterLevelWarning' || activeFeature === 'environmentWarning'">
        <div class="layer-item">
          <input type="checkbox" id="district-layer" v-model="warningLayers.district" @change="toggleWarningLayer('district')">
          <label for="district-layer">区县界</label>
        </div>
        <div class="layer-item">
          <input type="checkbox" id="waterArea-layer" v-model="warningLayers.waterArea" @change="toggleWarningLayer('waterArea')">
          <label for="waterArea-layer">水系面</label>
        </div>
        <div class="layer-item">
          <input type="checkbox" id="waterLine-layer" v-model="warningLayers.waterLine" @change="toggleWarningLayer('waterLine')">
          <label for="waterLine-layer">水系线</label>
        </div>
        <div class="layer-item">
          <input type="checkbox" id="reservoir-layer" v-model="warningLayers.reservoir" @change="toggleWarningLayer('reservoir')">
          <label for="reservoir-layer">水库</label>
        </div>
      </div>
      
      <!-- 水位预案按钮 (右上角) -->
      <div class="water-level-plan-button" v-if="activeFeature === 'waterLevelWarning'" @click="openWaterLevelPlan">
        <span class="plan-icon"></span>
        <span class="plan-text">水位预案</span>
      </div>
      
      <!-- 水位预案弹窗 -->
      <div class="modal-overlay" v-if="showWaterLevelPlanModal" @click.self="showWaterLevelPlanModal = false">
        <div class="water-level-plan-modal">
          <div class="modal-header">
            <h3>水位预案管理</h3>
            <button class="close-button" @click="showWaterLevelPlanModal = false">&times;</button>
          </div>
          <div class="modal-body">
            <div class="plan-tabs">
              <div 
                class="plan-tab" 
                :class="{'active': waterLevelPlanType === 'normal'}"
                @click="waterLevelPlanType = 'normal'"
              >
                正常水位
              </div>
              <div 
                class="plan-tab" 
                :class="{'active': waterLevelPlanType === 'warning'}"
                @click="waterLevelPlanType = 'warning'"
              >
                警戒水位
              </div>
              <div 
                class="plan-tab" 
                :class="{'active': waterLevelPlanType === 'danger'}"
                @click="waterLevelPlanType = 'danger'"
              >
                危险水位
              </div>
            </div>
            
            <div class="plan-content">
              <div v-if="waterLevelPlanType === 'normal'">
                <h4>正常水位预案 <span class="water-level-value">≤ 107m</span></h4>
                <ul class="plan-list">
                  <li>每日常规监测水位变化</li>
                  <li>监控系统正常运行维护</li>
                  <li>定期巡查水库周边区域</li>
                  <li>进行常规水质检测</li>
                  <li>确保泄洪设备处于良好状态</li>
                </ul>
                <div class="plan-remark">
                  <strong>备注：</strong>正常水位时，各系统保持常规监测频率，每日记录水位变化情况。
                </div>
              </div>
              
              <div v-if="waterLevelPlanType === 'warning'">
                <h4>警戒水位预案 <span class="water-level-value warning">107m ~ 110.8m</span></h4>
                <ul class="plan-list warning">
                  <li><strong>加强监测：</strong>提高监测频率至每4小时一次</li>
                  <li><strong>启动预警：</strong>向管理部门及相关人员发送预警信息</li>
                  <li><strong>泄洪准备：</strong>检查泄洪设备，准备必要时开启泄洪</li>
                  <li><strong>人员准备：</strong>应急队伍进入准备状态</li>
                  <li><strong>交通管制：</strong>准备对低洼地区道路实施交通管制</li>
                </ul>
                <div class="plan-actions">
                  <button class="plan-action-btn">发送预警信息</button>
                  <button class="plan-action-btn">查看受影响区域</button>
                </div>
              </div>
              
              <div v-if="waterLevelPlanType === 'danger'">
                <h4>危险水位预案 <span class="water-level-value danger">> 110.8m</span></h4>
                <ul class="plan-list danger">
                  <li><strong>全面监测：</strong>提高监测频率至每小时一次</li>
                  <li><strong>启动应急响应：</strong>立即启动应急响应机制</li>
                  <li><strong>强制泄洪：</strong>开启泄洪设施，控制水位上涨</li>
                  <li><strong>人员疏散：</strong>组织下游及低洼地区人员疏散</li>
                  <li><strong>全面交通管制：</strong>对受影响区域实施交通管制</li>
                  <li><strong>救援队伍：</strong>调动专业救援队伍待命</li>
                </ul>
                <div class="plan-actions">
                  <button class="plan-action-btn danger">启动紧急响应</button>
                  <button class="plan-action-btn danger">发布疏散通知</button>
                  <button class="plan-action-btn">模拟淹没范围</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- 左侧功能栏 -->
      <div class="left-sidebar">
        <h3 class="sidebar-title">功能设置</h3>
        <div class="sidebar-menu">
          <!-- 预警分析菜单项 -->
          <div class="menu-item" @click="toggleWarningMenu">
            <div class="menu-icon">
              <i class="feature-icon warning-icon"></i>
            </div>
            <span class="menu-text">预警分析</span>
            <i class="menu-arrow" :class="{'menu-arrow-expanded': showWarningSubmenu}"></i>
          </div>
          
          <!-- 预警分析子菜单 -->
          <div class="submenu" v-if="showWarningSubmenu">
            <div class="submenu-item" @click.stop="activateFeature('waterLevelWarning')">
              <div class="submenu-icon water-level-icon"></div>
              <span class="submenu-text">水位预警</span>
            </div>
            <div class="submenu-item" @click.stop="activateFeature('environmentWarning')">
              <div class="submenu-icon environment-icon"></div>
              <span class="submenu-text">环境预警</span>
            </div>
          </div>
          
          <!-- 其他功能项 -->
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
      
      <!-- 湖泊污染扩散模拟面板（仅污染物扩散模拟时显示，且变量隔离） -->
      <div v-if="activeFeature === 'pollution' && pollutionScope.showLakeSimulation" class="control-panel">
        <h3>图层控制</h3>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="pollutionScope.layers.districts" @change="pollutionScope.toggleLayer('districts')">
            区县边界
          </label>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="pollutionScope.layers.waterLines" @change="pollutionScope.toggleLayer('waterLines')">
            水系线数据
          </label>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="pollutionScope.layers.waterAreas" @change="pollutionScope.toggleLayer('waterAreas')">
            水系面数据
          </label>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="pollutionScope.layers.reservoirs" @change="pollutionScope.toggleLayer('reservoirs')">
            水库数据
          </label>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="pollutionScope.layers.settlements" @change="pollutionScope.toggleLayer('settlements')">
            居民地地名
          </label>
        </div>
        <div class="simulation-control">
          <h4>模拟功能</h4>
          <button @click="pollutionScope.showLakeSimulation = !pollutionScope.showLakeSimulation" class="simulation-btn">
            {{ pollutionScope.showLakeSimulation ? '隐藏' : '显示' }}湖泊污染模拟
          </button>
          <p v-if="pollutionScope.showLakeSimulation" class="simulation-hint">
            💡 点击地图上的湖泊多边形来选择要模拟的湖泊
          </p>
        </div>
      </div>
      <LakePollutionSimulationPrediction 
        v-if="activeFeature === 'pollution' && pollutionScope.showLakeSimulation"
        ref="pollutionScope.lakeSimulationRef"
        :map="map"
        :water-areas-layer="pollutionScope.baseWaterAreasLayer"
      />
    </div>
  </div>
</template>

<script>
import { onMounted, onUnmounted, ref, nextTick, watch, reactive } from 'vue'
import L from 'leaflet'
import * as EsriLeaflet from 'esri-leaflet'
import PredictionSimulationHeader from '../components/PredictionSimulationHeader.vue'
import axios from 'axios'
import * as echarts from 'echarts'
import LakePollutionSimulationPrediction from '../components/LakePollutionSimulationPrediction.vue'

export default {
  name: 'PredictionSimulation',
  components: {
    PredictionSimulationHeader,
    LakePollutionSimulationPrediction
  },
  setup() {
    const map = ref(null);
    const activeFeature = ref(null);
    let reservoirLayer = null;
    const showTrendDetail = ref(false);
    const showReservoirDetail = ref(false);
    const showMonitoringDetail = ref(false);
    const showWarningDetail = ref(false);
    const showWarningSubmenu = ref(false); // 预警分析子菜单显示状态
    const echartsRef = ref(null);
    const monitoringChartRef = ref(null);
    let chartInstance = null;
    let monitoringChartInstance = null;
    
    // 预警分析相关状态
    const warningLayers = ref({
      district: true,
      waterArea: true,
      waterLine: true,
      reservoir: true
    });
    
    // 地图图层
    const mapLayers = reactive({
      district: null,
      waterArea: null,
      waterLine: null,
      reservoir: null
    });
    
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
      map.value = L.map('prediction-map', {
        backgroundColor: '#ffffff', // 设置地图背景色为白色
        zoomControl: false // 先禁用默认缩放控件
      }).setView([39.9042, 116.4074], 9); // 修正了北京的中心点和默认缩放级别
      
      // 删除在线底图，只显示GeoJSON数据
      
      // 在自定义位置添加缩放控件
      setTimeout(() => {
        L.control.zoom({ position: 'topleft' }).addTo(map.value);
      }, 200);
    }
    
    // 加载预警分析图层
    const loadWarningLayers = async () => {
      try {
        // 加载区县界
        if (warningLayers.value.district) {
          const districtResponse = await fetch('./Beijing-GeoJson-Jx/北京区县界2.json');
          const districtData = await districtResponse.json();
          
          // 检查GeoJSON数据结构
          console.log("区县数据结构:", districtData.features[0]);
          
          // 预定义区县颜色数组
          const districtColors = [
            '#E3F2FD', '#E8F5E9', '#FFF8E1', '#FCE4EC', '#F3E5F5',
            '#E8EAF6', '#E0F2F1', '#F1F8E9', '#FFF3E0', '#EFEBE9',
            '#E0F7FA', '#FAFAFA', '#F1F3F4', '#E1F5FE', '#E8F5E9',
            '#FFFDE7', '#FBE9E7', '#F9FBE7', '#E0F7FA', '#F3E5F5'
          ];
          
          let colorIndex = 0;
          
          mapLayers.district = L.geoJSON(districtData, {
            style: (feature) => {
              // 为每个区县分配不同颜色
              const color = districtColors[colorIndex % districtColors.length];
              colorIndex++;
              
              return {
                color: '#666', // 边界颜色改为更柔和的灰色
                weight: 1.5,   // 边界宽度略微调小
                opacity: 0.8,
                fillColor: color,
                fillOpacity: 0.4 // 降低填充不透明度
              };
            },
            onEachFeature: (feature, layer) => {
              // 检查每个区县的属性
              console.log("区县属性:", feature.properties);
              
              // 尝试获取区县名称 (检查可能的属性名)
              const districtName = feature.properties.name || 
                                  feature.properties.NAME || 
                                  feature.properties.Name ||
                                  feature.properties.district ||
                                  feature.properties.DISTRICT ||
                                  feature.properties.District ||
                                  feature.properties.xzqmc ||
                                  feature.properties.XZQMC ||
                                  '未命名区县';
              
              // 添加悬停弹窗
              layer.bindPopup(`<b>区县名称:</b> ${districtName}`);
              
              // 添加区县名称标注
              try {
                // 计算多边形的中心点
                const center = layer.getBounds().getCenter();
                console.log(`为区县 ${districtName} 添加标注, 中心点:`, center);
                
                // 创建标注
                const label = L.divIcon({
                  className: 'district-label',
                  html: `<div>${districtName}</div>`,
                  iconSize: [80, 30],
                  iconAnchor: [40, 15]
                });
                
                // 将标注添加到地图
                L.marker(center, {
                  icon: label,
                  interactive: false, // 使标注不响应鼠标事件
                  zIndexOffset: 1000  // 确保标注显示在区县上面
                }).addTo(map.value);
              } catch (err) {
                console.error('添加区县标注失败:', err, districtName);
              }
              
              // 添加鼠标悬停效果
              layer.on({
                mouseover: (e) => {
                  const layer = e.target;
                  layer.setStyle({
                    weight: 4,
                    opacity: 1
                  });
                  layer.bringToFront();
                },
                mouseout: (e) => {
                  mapLayers.district.resetStyle(e.target);
                }
              });
            }
          }).addTo(map.value);
        }
        
        // 加载水系面
        if (warningLayers.value.waterArea) {
          const waterAreaResponse = await fetch('./Beijing-GeoJson-Jx/北京市_水系面数据2.json');
          const waterAreaData = await waterAreaResponse.json();
          
          mapLayers.waterArea = L.geoJSON(waterAreaData, {
            style: {
              color: '#1E90FF',
              weight: 1,
              opacity: 0.8,
              fillColor: '#1E90FF',
              fillOpacity: 0.3
            }
          }).addTo(map.value);
        }
        
        // 加载水系线
        if (warningLayers.value.waterLine) {
          const waterLineResponse = await fetch('./Beijing-GeoJson-Jx/水系线数据.json');
          const waterLineData = await waterLineResponse.json();
          
          mapLayers.waterLine = L.geoJSON(waterLineData, {
            style: {
              color: '#4169E1',
              weight: 2,
              opacity: 0.8
            }
          }).addTo(map.value);
        }
        
        // 加载水库
        if (warningLayers.value.reservoir) {
          const reservoirResponse = await fetch('./Beijing-GeoJson-Jx/北京市水库2.json');
          const reservoirData = await reservoirResponse.json();
          
          mapLayers.reservoir = L.geoJSON(reservoirData, {
            style: {
              color: '#0000CD',
              weight: 2,
              opacity: 0.8,
              fillColor: '#0000CD',
              fillOpacity: 0.4
            },
            onEachFeature: (feature, layer) => {
              if (feature.properties && feature.properties.name) {
                layer.bindPopup(`<b>水库名称:</b> ${feature.properties.name}`);
              }
            }
          }).addTo(map.value);
        }
        
        // 调整地图视图以适应所有图层
        if (mapLayers.district || mapLayers.waterArea || mapLayers.waterLine || mapLayers.reservoir) {
          const activeLayers = [];
          Object.values(mapLayers).forEach(layer => {
            if (layer) {
              activeLayers.push(layer);
            }
          });
          
          if (activeLayers.length > 0) {
            const group = L.featureGroup(activeLayers);
            map.value.fitBounds(group.getBounds());
          }
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
          // 图层已存在，添加到地图
          mapLayers[layerName].addTo(map.value);
        }
      } else if (mapLayers[layerName]) {
        // 图层已被禁用且已加载，从地图移除
        map.value.removeLayer(mapLayers[layerName]);
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
    
    // 切换预警分析子菜单
    const toggleWarningMenu = (event) => {
      showWarningSubmenu.value = !showWarningSubmenu.value;
      event.stopPropagation(); // 阻止事件冒泡
      
      // 如果展开子菜单，同时激活预警分析功能
      if (showWarningSubmenu.value) {
        activateFeature('warning');
      }
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
    
    // 打开水位预案弹窗
    const showWaterLevelPlanModal = ref(false);
    const waterLevelPlanType = ref('normal'); // 'normal', 'warning', 'danger'
    
    const openWaterLevelPlan = () => {
      showWaterLevelPlanModal.value = true;
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

    // 独立作用域：污染物扩散模拟相关
    const pollutionScope = (() => {
      const showLakeSimulation = ref(false)
      const lakeSimulationRef = ref(null)
      const baseWaterAreasLayer = ref(null)
      // 加载Beijing-GeoJson/北京市_水系面数据.json
      const loadBaseWaterAreasLayer = async () => {
        const response = await fetch('/Beijing-GeoJson/北京市_水系面数据.json')
        const data = await response.json()
        baseWaterAreasLayer.value = L.geoJSON(data)
      }
      loadBaseWaterAreasLayer()
      // 图层状态
      const layers = reactive({
        districts: true,
        waterLines: true,
        waterAreas: true,
        reservoirs: true,
        settlements: false
      })
      // 切换图层显示
      const toggleLayer = (layerType) => {
        const layer = mapLayers[layerType]
        if (layer) {
          if (layers[layerType]) {
            layer.addTo(map.value)
            if (layerType === 'waterAreas') {
              layer.bringToFront()
            }
          } else {
            map.value.removeLayer(layer)
          }
        }
      }
      return {
        showLakeSimulation,
        layers,
        toggleLayer,
        lakeSimulationRef,
        baseWaterAreasLayer
      }
    })();

    // 修改activateFeature方法，支持污染物扩散模拟
    const activateFeature = (feature) => {
      activeFeature.value = feature;
      // 关闭所有详情
      showTrendDetail.value = false;
      showReservoirDetail.value = false;
      showMonitoringDetail.value = false;
      showWarningDetail.value = false;
      // 切换到预警分析相关功能时，加载地图图层
      if (feature === 'warning' || feature === 'waterLevelWarning' || feature === 'environmentWarning') {
        // 清除现有图层
        Object.values(mapLayers).forEach(layer => {
          if (layer) {
            map.value.removeLayer(layer);
          }
        });
        // 重新加载图层
        loadWarningLayers();
      }
      // 切换到污染物扩散模拟时，清除预警分析图层（如有必要）
      if (feature === 'pollution') {
        Object.values(mapLayers).forEach(layer => {
          if (layer) {
            map.value.removeLayer(layer);
          }
        });
        pollutionScope.showLakeSimulation.value = true;
      } else {
        pollutionScope.showLakeSimulation.value = false;
      }
    }

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
      if (map.value) {
        map.value.remove();
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
      showWarningSubmenu,
      toggleWarningMenu,
      // 预警分析相关
      warningLayers,
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
      // 水位预案相关
      showWaterLevelPlanModal,
      waterLevelPlanType,
      openWaterLevelPlan,
      // 独立作用域：污染物扩散模拟相关
      pollutionScope,
      map,
      mapLayers,
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

/* 新的水平图层控制面板样式 */
.layer-controls-horizontal {
  display: flex;
  position: absolute;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  background-color: rgba(255, 255, 255, 0.9);
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.15);
  padding: 10px 20px;
  z-index: 1000;
  gap: 20px;
}

.layer-item {
  display: flex;
  align-items: center;
  margin-bottom: 0;
  white-space: nowrap;
}

.layer-item input[type="checkbox"] {
  margin-right: 8px;
}

.layer-item label {
  font-size: 14px;
  color: #333;
  cursor: pointer;
}

/* 区县名称标注样式 */
:deep(.district-label) {
  background: transparent;
  border: none;
}

:deep(.district-label div) {
  color: #000;
  font-weight: normal;
  font-size: 14px;
  text-align: center;
  white-space: nowrap;
  pointer-events: none;
}

/* 菜单箭头图标 */
.menu-arrow {
  margin-left: auto;
  width: 0;
  height: 0;
  border-left: 5px solid transparent;
  border-right: 5px solid transparent;
  border-top: 5px solid #333;
  transition: transform 0.3s ease;
}

.menu-arrow-expanded {
  transform: rotate(180deg);
}

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

/* 水位预案按钮样式 */
.water-level-plan-button {
  position: absolute;
  top: 20px;
  right: 20px;
  background-color: #2196F3;
  color: white;
  border-radius: 4px;
  padding: 10px 15px;
  display: flex;
  align-items: center;
  cursor: pointer;
  box-shadow: 0 2px 5px rgba(0,0,0,0.2);
  transition: background-color 0.3s;
  z-index: 1000;
}

.water-level-plan-button:hover {
  background-color: #1976D2;
}

.plan-icon {
  display: inline-block;
  width: 18px;
  height: 18px;
  margin-right: 8px;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%23ffffff'%3E%3Cpath d='M14,2H6C4.9,2 4,2.9 4,4v16c0,1.1 0.9,2 2,2h12c1.1,0 2-0.9 2-2V8L14,2zM12,10v3c0,0.55-0.45,1-1,1H9v3H7v-7h4V10zM13,9V3.5L18.5,9H13z'/%3E%3C/svg%3E");
  background-size: contain;
  background-repeat: no-repeat;
  background-position: center;
}

.plan-text {
  font-size: 14px;
  font-weight: 500;
}

/* 水位预案弹窗样式 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 2000;
}

.water-level-plan-modal {
  background-color: white;
  border-radius: 8px;
  width: 700px;
  max-width: 90%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px 20px;
  border-bottom: 1px solid #e0e6ed;
}

.modal-header h3 {
  margin: 0;
  color: #1976D2;
  font-size: 18px;
}

.close-button {
  background: transparent;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #666;
  padding: 0 5px;
}

.modal-body {
  padding: 20px;
}

.plan-tabs {
  display: flex;
  border-bottom: 1px solid #e0e6ed;
  margin-bottom: 20px;
}

.plan-tab {
  padding: 10px 20px;
  cursor: pointer;
  font-weight: 500;
  border-bottom: 2px solid transparent;
  transition: all 0.3s;
}

.plan-tab:hover {
  color: #1976D2;
}

.plan-tab.active {
  color: #1976D2;
  border-bottom-color: #1976D2;
}

.plan-content h4 {
  margin-top: 0;
  margin-bottom: 15px;
  color: #333;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.water-level-value {
  font-size: 14px;
  background-color: #E8F5E9;
  color: #4CAF50;
  padding: 4px 10px;
  border-radius: 4px;
}

.water-level-value.warning {
  background-color: #FFF3E0;
  color: #FF9800;
}

.water-level-value.danger {
  background-color: #FFEBEE;
  color: #F44336;
}

.plan-list {
  list-style-type: none;
  padding: 0;
  margin: 0 0 20px 0;
}

.plan-list li {
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
  color: #555;
}

.plan-list li:last-child {
  border-bottom: none;
}

.plan-list.warning li {
  padding: 10px 0;
}

.plan-list.danger li {
  padding: 10px 0;
}

.plan-remark {
  background-color: #F5F5F5;
  padding: 15px;
  border-radius: 4px;
  color: #666;
  font-size: 14px;
}

.plan-actions {
  margin-top: 20px;
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.plan-action-btn {
  background-color: #2196F3;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 10px 15px;
  cursor: pointer;
  font-weight: 500;
  transition: background-color 0.3s;
}

.plan-action-btn:hover {
  background-color: #1976D2;
}

.plan-action-btn.danger {
  background-color: #F44336;
}

.plan-action-btn.danger:hover {
  background-color: #D32F2F;
}
</style> 
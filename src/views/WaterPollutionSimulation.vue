<template>
  <div class="container">
    <water-pollution-header :title="systemTitle"></water-pollution-header>
    
    <div class="map-container">
      <div id="map" style="width: 100%; height: 100%;"></div>
      
      <!-- 左侧图层控制面板 -->
      <div class="layer-control-panel">
        <h3>图层控制</h3>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.districts" @change="toggleLayer('districts')">
            区县边界
          </label>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.waterLines" @change="toggleLayer('waterLines')">
            水系线数据
          </label>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.waterAreas" @change="toggleLayer('waterAreas')">
            水系面数据
          </label>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.reservoirs" @change="toggleLayer('reservoirs')">
            水库数据
          </label>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.settlements" @change="toggleLayer('settlements')">
            居民地地名
          </label>
        </div>
      </div>
      
      <!-- 右侧模拟控制面板 -->
      <div class="simulation-panel">
        <h4>模拟功能</h4>
        <button @click="showLakeSimulation = !showLakeSimulation" class="simulation-btn">
          {{ showLakeSimulation ? '隐藏' : '显示' }}湖泊污染模拟
        </button>
        <p v-if="showLakeSimulation" class="simulation-hint">
          💡 点击地图上的湖泊多边形来选择要模拟的湖泊
        </p>
        
        <div class="simulation-divider"></div>
        
        <button @click="showRiverSimulation = !showRiverSimulation" class="simulation-btn river-btn">
          {{ showRiverSimulation ? '隐藏' : '显示' }}河流污染模拟
        </button>
        <p v-if="showRiverSimulation" class="simulation-hint">
          💡 点击地图上的河流线条来选择要模拟的河流
        </p>
      </div>
      
      <!-- 湖泊污染扩散模拟面板 -->
      <LakePollutionSimulation 
        v-if="showLakeSimulation && layers.waterAreas"
        ref="lakeSimulationRef"
        :map="map"
        :water-areas-layer="layerObjects.waterAreas"
        @simulation-update="onSimulationUpdate"
      />
      
      <!-- 河流污染扩散模拟面板 -->
      <RiverPollutionSimulation 
        v-if="showRiverSimulation && layers.waterLines"
        ref="riverSimulationRef"
        :map="map"
        :water-lines-layer="layerObjects.waterLines"
        @simulation-update="onRiverSimulationUpdate"
      />
      
      <!-- 数据信息面板 -->
      <div class="data-info">
        <h4>数据统计</h4>
        <p>区县数量: {{ dataStats.districts }}</p>
        <p>水系线条: {{ dataStats.waterLines }}</p>
        <p>水系面积: {{ dataStats.waterAreas }}</p>
        <p>水库数量: {{ dataStats.reservoirs }}</p>
        <p>居民地数量: {{ dataStats.settlements }}</p>
      </div>
      
      <!-- 加载提示 -->
      <div v-if="loading" class="loading">
        正在加载地理数据...
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, reactive, watch } from 'vue'
import L from 'leaflet'
import LakePollutionSimulation from '../components/LakePollutionSimulation.vue'
import RiverPollutionSimulation from '../components/RiverPollutionSimulation.vue'
import WaterPollutionHeader from '../components/WaterPollutionHeader.vue'

export default {
  name: 'WaterPollutionSimulation',
  components: {
    LakePollutionSimulation,
    RiverPollutionSimulation,
    WaterPollutionHeader
  },
  setup() {
    const map = ref(null)
    const loading = ref(true)
    const showLakeSimulation = ref(false)
    const showRiverSimulation = ref(false)
    const systemTitle = ref('水污染扩散模拟')
    
    // 图层状态
    const layers = reactive({
      districts: true,
      waterLines: true,
      waterAreas: true,
      reservoirs: true,
      settlements: false
    })
    
    // 图层对象
    const layerObjects = reactive({
      districts: null,
      waterLines: null,
      waterAreas: null,
      reservoirs: null,
      settlements: null
    })
    
    // 湖泊模拟组件引用
    const lakeSimulationRef = ref(null)
    // 河流模拟组件引用
    const riverSimulationRef = ref(null)
    
    // 管理图层层级
    const manageLayerZIndex = () => {
      try {
        if (showRiverSimulation.value && layerObjects.waterLines && map.value) {
          // 河流模拟激活时，将水系线图层置顶
          if (map.value.hasLayer(layerObjects.waterLines)) {
            layerObjects.waterLines.bringToFront()
            console.log('水系线图层已置顶')
          }
        } else if (showLakeSimulation.value && layerObjects.waterAreas && map.value) {
          // 湖泊模拟激活时，将水系面图层置顶
          if (map.value.hasLayer(layerObjects.waterAreas)) {
            layerObjects.waterAreas.bringToFront()
            console.log('水系面图层已置顶')
          }
        }
      } catch (error) {
        console.error('管理图层层级时出错:', error)
      }
    }
    
    // 数据统计
    const dataStats = reactive({
      districts: 0,
      waterLines: 0,
      waterAreas: 0,
      reservoirs: 0,
      settlements: 0
    })
    
    // 初始化地图
    const initMap = () => {
      map.value = L.map('map').setView([39.9042, 116.4074], 10)
      
      // 添加OpenStreetMap底图
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors'
      }).addTo(map.value)
    }
    
    // 加载GeoJSON数据
    const loadGeoJSONData = async () => {
      try {
        const dataFiles = {
          districts: '/Beijing-GeoJson/北京区县界.json',
          waterLines: '/Beijing-GeoJson/北京市_水系线数据.json',
          waterAreas: '/Beijing-GeoJson/北京市_水系面数据.json',
          reservoirs: '/Beijing-GeoJson/北京市水库.json',
          settlements: '/Beijing-GeoJson/居民地地名.json'
        }
        
        for (const [key, filePath] of Object.entries(dataFiles)) {
          try {
            const response = await fetch(filePath)
            const data = await response.json()
            
            // 创建图层
            const layer = L.geoJSON(data, {
              style: getLayerStyle(key),
              onEachFeature: (feature, layer) => {
                if (feature.properties) {
                  layer.bindPopup(getPopupContent(key, feature.properties))
                }
                
                // 为水系面数据添加点击事件
                if (key === 'waterAreas') {
                  layer.on('click', (e) => {
                    console.log('点击湖泊:', feature.properties)
                    // 阻止事件冒泡，避免触发地图点击事件
                    e.originalEvent.stopPropagation()
                    if (showLakeSimulation.value && lakeSimulationRef.value && typeof lakeSimulationRef.value.onLakeSelect === 'function') {
                      try {
                        lakeSimulationRef.value.onLakeSelect(feature)
                      } catch (error) {
                        console.error('调用湖泊选择函数时出错:', error)
                      }
                    }
                  })
                }
                
                // 为水系线数据添加点击事件
                if (key === 'waterLines') {
                  layer.on('click', (e) => {
                    console.log('点击河流:', feature.properties)
                    // 阻止事件冒泡，避免触发地图点击事件
                    e.originalEvent.stopPropagation()
                    if (showRiverSimulation.value && riverSimulationRef.value && typeof riverSimulationRef.value.onRiverSelect === 'function') {
                      try {
                        riverSimulationRef.value.onRiverSelect(feature)
                      } catch (error) {
                        console.error('调用河流选择函数时出错:', error)
                      }
                    }
                  })
                }
              }
            })
            
            layerObjects[key] = layer
            
            // 更新统计信息
            if (data.features) {
              dataStats[key] = data.features.length
            }
            
            // 如果图层开启，添加到地图
            if (layers[key]) {
              layer.addTo(map.value)
              // 自动将水系面图层和水系线图层置顶
              if (key === 'waterAreas' || key === 'waterLines') {
                layer.bringToFront()
              }
            }
            
          } catch (error) {
            console.error(`加载${key}数据失败:`, error)
          }
        }
        
        loading.value = false
      } catch (error) {
        console.error('加载数据失败:', error)
        loading.value = false
      }
    }
    
    // 获取图层样式
    const getLayerStyle = (layerType) => {
      const styles = {
        districts: {
          fillColor: 'transparent',
          weight: 2.5,
          opacity: 0.8,
          color: '#ffffff',
          fillOpacity: 0,
          dashArray: '5, 8'
        },
        waterLines: {
          color: '#64B5F6',
          weight: 2.5,
          opacity: 0.9
        },
        waterAreas: {
          fillColor: '#29B6F6',
          weight: 1.5,
          opacity: 0.9,
          color: '#0288D1',
          fillOpacity: 0.7
        },
        reservoirs: {
          fillColor: '#26C6DA',
          weight: 1.5,
          opacity: 0.9,
          color: '#00ACC1',
          fillOpacity: 0.8
        },
        settlements: {
          radius: 6,
          fillColor: '#FFF176',
          color: '#ffffff',
          weight: 1.5,
          opacity: 1,
          fillOpacity: 0.9
        }
      }
      
      return styles[layerType] || {}
    }
    
    // 获取弹窗内容 - 只显示真实存在的属性名
    const getPopupContent = (layerType, properties) => {
      const content = {
        districts: `<strong>区县:</strong> ${properties.name || properties.NAME || '未知'}<br>
                   <strong>代码:</strong> ${properties.code || properties.CODE || properties.adcode || '未知'}`,
        waterLines: `<strong>水系线:</strong> ${properties.name || properties.NAME || '未知'}<br>
                     <strong>类型:</strong> ${properties.fclass || properties.FCLASS || '未知'}`,
        waterAreas: `<strong>水系面:</strong> ${properties.name || properties.NAME || '未知'}<br>
                     <strong>类型:</strong> ${properties.fclass || properties.FCLASS || '未知'}<br>
                     <strong>OSM ID:</strong> ${properties.osm_id || properties.OSM_ID || '未知'}`,
        reservoirs: `<strong>水库:</strong> ${properties.name || properties.NAME || '未知'}<br>
                    <strong>类型:</strong> ${properties.fclass || properties.FCLASS || '未知'}<br>
                    <strong>OSM ID:</strong> ${properties.osm_id || properties.OSM_ID || '未知'}`,
        settlements: `<strong>居民地:</strong> ${properties.name || properties.NAME || '未知'}<br>
                      <strong>类型:</strong> ${properties.fclass || properties.FCLASS || '未知'}`
      }
      return content[layerType] || '无详细信息'
    }
    
    // 切换图层显示
    const toggleLayer = (layerType) => {
      const layer = layerObjects[layerType]
      if (layer) {
        if (layers[layerType]) {
          layer.addTo(map.value)
          // 切换湖泊模拟时自动将水系面图层置顶
          if (layerType === 'waterAreas') {
            layer.bringToFront()
          }
        } else {
          map.value.removeLayer(layer)
        }
      }
    }
    
    // 处理湖泊模拟更新
    const onSimulationUpdate = (data) => {
      console.log('湖泊模拟数据更新:', data)
    }
    
    // 处理河流模拟更新
    const onRiverSimulationUpdate = (data) => {
      console.log('河流模拟数据更新:', data)
    }
    
    // 监听模拟状态变化，管理图层层级
    watch([showRiverSimulation, showLakeSimulation], () => {
      // 延迟执行，确保组件已加载
      setTimeout(() => {
        try {
          manageLayerZIndex()
        } catch (error) {
          console.error('管理图层层级时出错:', error)
        }
      }, 100)
    })
    
    // 确保模拟状态独立
    const ensureSimulationIndependence = () => {
      // 如果河流模拟激活，确保湖泊模拟关闭
      if (showRiverSimulation.value && showLakeSimulation.value) {
        showLakeSimulation.value = false
        console.log('关闭湖泊模拟，保持河流模拟独立')
      }
    }
    
    onMounted(() => {
      initMap()
      loadGeoJSONData()
    })
    
    return {
      loading,
      layers,
      layerObjects,
      map,
      dataStats,
      showLakeSimulation,
      showRiverSimulation,
      lakeSimulationRef,
      riverSimulationRef,
      systemTitle,
      toggleLayer,
      manageLayerZIndex,
      ensureSimulationIndependence,
      onSimulationUpdate,
      onRiverSimulationUpdate
    }
  }
}
</script>

<style scoped>
.container {
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.map-container {
  flex: 1;
  position: relative;
  background: #f5f5f5;
}

.layer-control-panel {
  position: absolute;
  top: 20px;
  left: 20px;
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  z-index: 1000;
  max-width: 280px;
  max-height: 40vh;
  overflow-y: auto;
}

.simulation-panel {
  position: absolute;
  top: 20px;
  right: 20px;
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  z-index: 1000;
  max-width: 280px;
}

.control-panel h3 {
  margin: 0 0 15px 0;
  color: #333;
  font-size: 1.2rem;
}

.layer-control {
  margin-bottom: 10px;
}

.layer-control label {
  display: flex;
  align-items: center;
  cursor: pointer;
  font-size: 0.9rem;
  color: #555;
}

.layer-control input[type="checkbox"] {
  margin-right: 8px;
}

.simulation-panel h4 {
  margin: 0 0 10px 0;
  color: #333;
  font-size: 1rem;
}

.simulation-divider {
  height: 1px;
  background: linear-gradient(90deg, transparent, #ddd, transparent);
  margin: 15px 0;
}

.river-btn {
  background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%) !important;
}

.river-btn:hover {
  box-shadow: 0 4px 12px rgba(76, 175, 80, 0.4) !important;
}

.simulation-control h4 {
  margin: 0 0 10px 0;
  color: #333;
  font-size: 1rem;
}

.simulation-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9rem;
  transition: all 0.3s ease;
}

.simulation-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.simulation-hint {
  margin: 10px 0 0 0;
  font-size: 0.8rem;
  color: #666;
  background: #f8f9fa;
  padding: 8px;
  border-radius: 4px;
  border-left: 3px solid #667eea;
}

.data-info {
  position: absolute;
  bottom: 20px;
  left: 20px;
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  z-index: 1000;
  max-width: 250px;
}

.data-info h4 {
  margin: 0 0 15px 0;
  color: #333;
  font-size: 1.1rem;
}

.data-info p {
  margin: 5px 0;
  font-size: 0.9rem;
  color: #666;
}

.loading {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: rgba(0, 0, 0, 0.8);
  color: white;
  padding: 20px 40px;
  border-radius: 8px;
  z-index: 2000;
  font-size: 1.1rem;
}

@media (max-width: 768px) {
  .layer-control-panel {
    top: 10px;
    left: 10px;
    max-width: 250px;
    padding: 15px;
  }
  
  .simulation-panel {
    top: 10px;
    right: 10px;
    max-width: 250px;
    padding: 15px;
  }
  
  .data-info {
    max-width: 200px;
    padding: 15px;
    bottom: 10px;
    left: 10px;
  }
  
  .layer-control-panel h3 {
    font-size: 1rem;
  }
  
  .simulation-panel h4 {
    font-size: 0.9rem;
  }
  
  .data-info h4 {
    font-size: 1rem;
  }
}
</style> 
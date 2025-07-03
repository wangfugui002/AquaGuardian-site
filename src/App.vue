<template>
  <div class="container">
    <header class="header">
      <h1>北京水污染模拟系统</h1>
    </header>
    
    <div class="map-container">
      <div id="map" style="width: 100%; height: 100%;"></div>
      
      <!-- 控制面板 -->
      <div class="control-panel">
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
        
        <!-- 模拟控制 -->
        <div class="simulation-control">
          <h4>模拟功能</h4>
          <button @click="showLakeSimulation = !showLakeSimulation" class="simulation-btn">
            {{ showLakeSimulation ? '隐藏' : '显示' }}湖泊污染模拟
          </button>
          <p v-if="showLakeSimulation" class="simulation-hint">
            💡 点击地图上的湖泊多边形来选择要模拟的湖泊
          </p>
        </div>
      </div>
      
      <!-- 湖泊污染扩散模拟面板 -->
      <LakePollutionSimulation 
        v-if="showLakeSimulation && layers.waterAreas"
        ref="lakeSimulationRef"
        :map="map"
        :water-areas-layer="layerObjects.waterAreas"
        @simulation-update="onSimulationUpdate"
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
import { ref, onMounted, reactive } from 'vue'
import L from 'leaflet'
import LakePollutionSimulation from './components/LakePollutionSimulation.vue'

export default {
  name: 'App',
  components: {
    LakePollutionSimulation
  },
  setup() {
    const map = ref(null)
    const loading = ref(true)
    const showLakeSimulation = ref(false)
    
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
                    console.log('点击湖泊:', feature.properties) // 调试输出
                    if (showLakeSimulation.value && lakeSimulationRef.value) {
                      lakeSimulationRef.value.onLakeSelect(feature)
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
              // 自动将水系面图层置顶
              if (key === 'waterAreas') {
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
          fillColor: '#3498db',
          weight: 2,
          opacity: 1,
          color: '#2980b9',
          fillOpacity: 0.1
        },
        waterLines: {
          color: '#3498db',
          weight: 3,
          opacity: 0.8
        },
        waterAreas: {
          fillColor: '#3498db',
          weight: 2,
          opacity: 1,
          color: '#2980b9',
          fillOpacity: 0.3
        },
        reservoirs: {
          fillColor: '#e74c3c',
          weight: 2,
          opacity: 1,
          color: '#c0392b',
          fillOpacity: 0.6
        },
        settlements: {
          fillColor: '#f39c12',
          weight: 1,
          opacity: 1,
          color: '#e67e22',
          fillOpacity: 0.8
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
    
    // 处理模拟更新
    const onSimulationUpdate = (data) => {
      console.log('模拟数据更新:', data)
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
      lakeSimulationRef,
      toggleLayer,
      onSimulationUpdate
    }
  }
}
</script> 
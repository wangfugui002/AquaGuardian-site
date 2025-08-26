<template>
  <div class="container">
    <page-header :title="systemTitle"></page-header>
    
    <div class="map-container">
      <div id="map" style="width: 100%; height: 100%;"></div>
      
      <!-- 测试内容 - 确保Vue应用正常工作 -->
      <div class="test-content" style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); z-index: 1000;">
        <h2>Vue应用测试</h2>
        <p>如果您看到这个内容，说明Vue应用正在正常工作！</p>
        <p>当前时间: {{ currentTime }}</p>
        <button @click="refreshTime">刷新时间</button>
      </div>
      
      <!-- 图层控制面板 -->
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
            <input type="checkbox" v-model="layers.waterAreas" @change="toggleLayer('waterAreas')">
            水系面数据
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
            <input type="checkbox" v-model="layers.reservoirs" @change="toggleLayer('reservoirs')">
            水库数据
          </label>
        </div>
      </div>
      
      <!-- 地图服务信息面板 -->
      <div class="service-info-panel">
        <h4>地图服务信息</h4>
        <div class="info-item">
          <span class="info-label">服务站点:</span>
          <span class="info-value">yzcm.dev.local:6443</span>
        </div>
        <div class="info-item">
          <span class="info-label">服务软件:</span>
          <span class="info-value">GeoScene</span>
        </div>
        <div class="info-item">
          <span class="info-label">服务类型:</span>
          <span class="info-value">要素服务 (FeatureServer)</span>
        </div>
      </div>
      
      <!-- 加载提示 -->
      <div v-if="loading" class="loading">
        正在加载地图数据...
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, reactive } from 'vue'
import L from 'leaflet'
import PageHeader from '../components/Header.vue'

export default {
  name: 'Home',
  components: {
    PageHeader
  },
  setup() {
    const map = ref(null)
    const loading = ref(true)
    const systemTitle = ref('环境风险分析与模拟系统')
    const currentTime = ref(new Date().toLocaleString())
    
    // 刷新时间函数
    const refreshTime = () => {
      currentTime.value = new Date().toLocaleString()
    }
    
    // 图层状态管理
    const layers = reactive({
      districts: true,
      waterAreas: true,
      waterLines: true,
      reservoirs: true
    })
    
    // 图层对象存储
    const layerObjects = reactive({
      districts: null,
      waterAreas: null,
      waterLines: null,
      reservoirs: null
    })
    
    // 切换图层显示
    const toggleLayer = (layerType) => {
      const layer = layerObjects[layerType]
      if (layer) {
        if (layers[layerType]) {
          layer.addTo(map.value)
        } else {
          map.value.removeLayer(layer)
        }
      }
    }
    
    // 初始化地图
    const initMap = () => {
      map.value = L.map('map', {
        zoomControl: false,
        attributionControl: false
      }).setView([39.9042, 116.4074], 10)
      
      try {
        // 首先加载基础底图
        loadBaseMap()
        
        // 加载北京区县界数据
        const districtUrl = 'https://yzcm.dev.local/sever/rest/services/Hosted/北京区县界/FeatureServer'
        loadDistrictData(districtUrl)
        
        // 加载水系面数据
        const waterAreaUrl = 'https://yzcm.dev.local/sever/rest/services/Hosted/北京市_水系面数据/FeatureServer'
        loadWaterAreaData(waterAreaUrl)
        
        // 加载水系线数据
        const waterLineUrl = 'https://yzcm.dev.local/sever/rest/services/Hosted/北京市_水系线数据/FeatureServer'
        loadWaterLineData(waterLineUrl)
        
        // 加载水库数据
        const reservoirUrl = 'https://yzcm.dev.local/sever/rest/services/Hosted/北京市水库/FeatureServer'
        loadReservoirData(reservoirUrl)
        
      } catch (error) {
        console.error('地图初始化失败:', error)
        loadFallbackMap()
      }
    }
    
    // 加载区县界数据
    const loadDistrictData = async (url) => {
      try {
        const queryUrl = `${url}/0/query?where=1%3D1&outFields=*&returnGeometry=true&f=geojson`
        
        const response = await fetch(queryUrl)
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        
        const data = await response.json()
        
        // 创建区县界GeoJSON图层
        const districtLayer = L.geoJSON(data, {
          style: {
            fillColor: '#ffffff',
            weight: 2,
            opacity: 0.8,
            color: '#333333',
            fillOpacity: 0.1
          },
          onEachFeature: (feature, layer) => {
            if (feature.properties) {
              layer.bindPopup(getDistrictPopupContent(feature.properties))
            }
          }
        })
        
        layerObjects.districts = districtLayer
        districtLayer.addTo(map.value)
        console.log('北京区县界数据加载成功')
        
      } catch (error) {
        console.error('区县界数据加载失败:', error)
      }
    }
    
    // 加载水系线数据
    const loadWaterLineData = async (url) => {
      try {
        const queryUrl = `${url}/0/query?where=1%3D1&outFields=*&returnGeometry=true&f=geojson`
        
        const response = await fetch(queryUrl)
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        
        const data = await response.json()
        
        // 创建水系线GeoJSON图层
        const waterLineLayer = L.geoJSON(data, {
          style: {
            color: '#0066cc',
            weight: 2,
            opacity: 0.8
          },
          onEachFeature: (feature, layer) => {
            if (feature.properties) {
              layer.bindPopup(getWaterLinePopupContent(feature.properties))
            }
          }
        })
        
        layerObjects.waterLines = waterLineLayer
        waterLineLayer.addTo(map.value)
        console.log('水系线数据加载成功')
        loading.value = false
        
      } catch (error) {
        console.error('水系线数据加载失败:', error)
        loading.value = false
      }
    }
    
    // 加载水系面数据
    const loadWaterAreaData = async (url) => {
      try {
        const queryUrl = `${url}/0/query?where=1%3D1&outFields=*&returnGeometry=true&f=geojson`
        
        const response = await fetch(queryUrl)
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        
        const data = await response.json()
        
        // 创建水系面GeoJSON图层
        const waterAreaLayer = L.geoJSON(data, {
          style: {
            fillColor: '#29B6F6',
            weight: 1,
            opacity: 0.9,
            color: '#0288D1',
            fillOpacity: 0.6
          },
          onEachFeature: (feature, layer) => {
            if (feature.properties) {
              layer.bindPopup(getWaterAreaPopupContent(feature.properties))
            }
          }
        })
        
        layerObjects.waterAreas = waterAreaLayer
        waterAreaLayer.addTo(map.value)
        console.log('水系面数据加载成功')
        
      } catch (error) {
        console.error('水系面数据加载失败:', error)
      }
    }
    
    // 加载水库数据
    const loadReservoirData = async (url) => {
      try {
        const queryUrl = `${url}/0/query?where=1%3D1&outFields=*&returnGeometry=true&f=geojson`
        
        const response = await fetch(queryUrl)
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        
        const data = await response.json()
        
        // 创建水库GeoJSON图层
        const reservoirLayer = L.geoJSON(data, {
          style: {
            fillColor: '#26C6DA',
            weight: 1.5,
            opacity: 0.9,
            color: '#00ACC1',
            fillOpacity: 0.8
          },
          onEachFeature: (feature, layer) => {
            if (feature.properties) {
              layer.bindPopup(getReservoirPopupContent(feature.properties))
            }
          }
        })
        
        layerObjects.reservoirs = reservoirLayer
        reservoirLayer.addTo(map.value)
        console.log('水库数据加载成功')
        loading.value = false
        
      } catch (error) {
        console.error('水库数据加载失败:', error)
        loading.value = false
      }
    }
    
    // 获取区县界弹窗内容
    const getDistrictPopupContent = (properties) => {
      const name = properties.name || properties.NAME || properties.Name || '未知'
      return `<div style="font-size: 12px;"><strong>区县:</strong> ${name}</div>`
    }
    
    // 获取水系线弹窗内容
    const getWaterLinePopupContent = (properties) => {
      const name = properties.name || properties.NAME || properties.Name || '未知'
      return `<div style="font-size: 12px;"><strong>水系线:</strong> ${name}</div>`
    }
    
    // 获取水系面弹窗内容
    const getWaterAreaPopupContent = (properties) => {
      const name = properties.name || properties.NAME || properties.Name || '未知'
      return `<div style="font-size: 12px;"><strong>水系面:</strong> ${name}</div>`
    }
    
    // 获取水库弹窗内容
    const getReservoirPopupContent = (properties) => {
      const name = properties.name || properties.NAME || properties.Name || '未知'
      return `<div style="font-size: 12px;"><strong>水库:</strong> ${name}</div>`
    }
    
    // 加载基础底图
    const loadBaseMap = () => {
      try {
        // 使用OpenStreetMap作为基础底图
        const baseLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '© OpenStreetMap contributors',
          maxZoom: 18
        })
        
        baseLayer.addTo(map.value)
        console.log('基础底图加载成功')
        
      } catch (error) {
        console.error('基础底图加载失败:', error)
      }
    }
    
    // 备用地图加载方案
    const loadFallbackMap = () => {
      try {
        // 如果WMS服务无法加载，使用OpenStreetMap作为备用
        const fallbackLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '© OpenStreetMap contributors',
          maxZoom: 18
        })
        
        fallbackLayer.addTo(map.value)
        console.log('使用备用地图服务')
        loading.value = false
      } catch (error) {
        console.error('备用地图加载也失败:', error)
        loading.value = false
      }
    }
    
    onMounted(() => {
      initMap()
    })
    
    return {
      loading,
      map,
      systemTitle,
      layers,
      toggleLayer,
      currentTime,
      refreshTime
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
  background: white;
}

#map {
  width: 100%;
  height: 100%;
}

.layer-control-panel {
  position: absolute;
  top: 20px;
  left: 20px;
  background: white;
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  z-index: 1000;
  max-width: 200px;
}

.layer-control-panel h3 {
  margin: 0 0 10px 0;
  color: #333;
  font-size: 1rem;
}

.layer-control {
  display: flex;
  align-items: center;
  margin-bottom: 8px;
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

.service-info-panel {
  position: absolute;
  bottom: 20px;
  left: 20px;
  background: white;
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  z-index: 1000;
  max-width: 280px;
}

.service-info-panel h4 {
  margin: 0 0 10px 0;
  color: #333;
  font-size: 0.95rem;
}

.info-item {
  margin-bottom: 8px;
  font-size: 0.8rem;
  line-height: 1.3;
}

.info-label {
  font-weight: bold;
  color: #555;
  margin-right: 6px;
  display: inline-block;
  min-width: 65px;
}

.info-value {
  color: #333;
  word-break: break-all;
  display: inline-block;
  max-width: 200px;
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
  .loading {
    padding: 15px 30px;
    font-size: 1rem;
  }
  .layer-control-panel {
    top: 10px;
    left: 10px;
    max-width: 200px;
    padding: 12px;
  }
  
  .service-info-panel {
    max-width: 240px;
    padding: 12px;
    bottom: 10px;
    left: 10px;
  }
  
  .layer-control-panel h3 {
    font-size: 0.9rem;
  }
  
  .service-info-panel h4 {
    font-size: 0.9rem;
  }
  
  .layer-control {
    font-size: 0.8rem;
  }
  
  .info-item {
    font-size: 0.75rem;
  }
  
  .info-label {
    min-width: 60px;
  }
  
  .info-value {
    max-width: 170px;
  }
}
</style> 
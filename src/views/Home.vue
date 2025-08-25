<template>
  <div class="container">
    <page-header :title="systemTitle"></page-header>
    
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
          <div class="layer-color-control">
            <div class="color-preview" :style="{ backgroundColor: layerColors.districts }" @click="showColorPicker('districts')"></div>
            <input type="color" v-model="layerColors.districts" @change="updateLayerColor('districts')" class="color-input" data-layer="districts" />
          </div>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.waterLines" @change="toggleLayer('waterLines')">
            水系线数据
          </label>
          <div class="layer-color-control">
            <div class="color-preview" :style="{ backgroundColor: layerColors.waterLines }" @click="showColorPicker('waterLines')"></div>
            <input type="color" v-model="layerColors.waterLines" @change="updateLayerColor('waterLines')" class="color-input" data-layer="waterLines" />
          </div>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.waterAreas" @change="toggleLayer('waterAreas')">
            水系面数据
          </label>
          <div class="layer-color-control">
            <div class="color-preview" :style="{ backgroundColor: layerColors.waterAreas }" @click="showColorPicker('waterAreas')"></div>
            <input type="color" v-model="layerColors.waterAreas" @change="updateLayerColor('waterAreas')" class="color-input" data-layer="waterAreas" />
          </div>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.reservoirs" @change="toggleLayer('reservoirs')">
            水库数据
          </label>
          <div class="layer-color-control">
            <div class="color-preview" :style="{ backgroundColor: layerColors.reservoirs }" @click="showColorPicker('reservoirs')"></div>
            <input type="color" v-model="layerColors.reservoirs" @change="updateLayerColor('reservoirs')" class="color-input" data-layer="reservoirs" />
          </div>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.settlements" @change="toggleLayer('settlements')">
            居民地地名
          </label>
          <div class="layer-color-control">
            <div class="color-preview point-preview" :style="{ backgroundColor: layerColors.settlements }" @click="showColorPicker('settlements')"></div>
            <input type="color" v-model="layerColors.settlements" @change="updateLayerColor('settlements')" class="color-input" data-layer="settlements" />
          </div>
        </div>
      </div>
      

      
      <!-- 服务信息面板 -->
      <div class="data-info">
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
          <span class="info-value">地图服务 (MapServer)</span>
        </div>
        <div class="info-item">
          <span class="info-label">协议支持:</span>
          <span class="info-value">REST / SOAP</span>
        </div>
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
    
    // 图层状态
    const layers = reactive({
      districts: true,
      waterLines: true,
      waterAreas: true,
      reservoirs: true,
      settlements: false
    })
    
    // 图层颜色配置
    const layerColors = reactive({
      districts: '#ffffff',
      waterLines: '#64B5F6',
      waterAreas: '#29B6F6',
      reservoirs: '#26C6DA',
      settlements: '#FFF176'
    })
    
    // 图层对象
    const layerObjects = reactive({
      districts: null,
      waterLines: null,
      waterAreas: null,
      reservoirs: null,
      settlements: null
    })
    
    
    // 数据统计
    const dataStats = reactive({
      districts: 0,
      waterLines: 0,
      waterAreas: 0,
      reservoirs: 0,
      settlements: 0
    })
    
    // 初始化地图 - 使用REST服务
    const initMap = () => {
      map.value = L.map('map', {
        zoomControl: false,
        attributionControl: false
      }).setView([39.9042, 116.4074], 10)
      
      // 使用提供的REST URL加载地图服务
      const restUrl = 'https://yzcm.dev.local:6443/geoscene/rest/services/地图/MapServer'
      
      try {
        // 创建WMS图层
        const wmsLayer = L.tileLayer.wms(restUrl, {
          layers: '0', // 图层索引，通常从0开始
          format: 'image/png',
          transparent: true,
          version: '1.3.0',
          crs: L.CRS.EPSG3857, // 使用Web墨卡托投影
          maxZoom: 18,
          minZoom: 1
        })
        
        wmsLayer.addTo(map.value)
        
        // 添加错误处理
        wmsLayer.on('tileerror', function(e) {
          console.error('地图瓦片加载失败:', e)
          // 如果WMS加载失败，尝试使用备用方案
          loadFallbackMap()
        })
        
        wmsLayer.on('load', function() {
          console.log('地图服务加载成功')
          loading.value = false
        })
        
        // 设置超时处理
        setTimeout(() => {
          if (loading.value) {
            console.log('地图加载超时，尝试备用方案')
            loadFallbackMap()
          }
        }, 10000) // 10秒超时
        
      } catch (error) {
        console.error('地图初始化失败:', error)
        loadFallbackMap()
      }
    }
    
    // 备用地图加载方案
    const loadFallbackMap = () => {
      try {
        // 如果REST服务无法加载，使用OpenStreetMap作为备用
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
    
    // 加载GeoJSON数据 - 保留作为叠加图层
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
    
    // 获取图层样式 - 与WaterPollutionSimulation.vue保持一致的颜色配置
    const getLayerStyle = (layerType) => {
      const styles = {
        districts: {
          fillColor: layerColors.districts,
          weight: 2.5,
          opacity: 0.8,
          color: layerColors.districts,
          fillOpacity: 0.5,
          dashArray: '5, 8'
        },
        waterLines: {
          color: layerColors.waterLines,
          weight: 2.5,
          opacity: 0.9
        },
        waterAreas: {
          fillColor: layerColors.waterAreas,
          weight: 1.5,
          opacity: 0.9,
          color: '#0288D1',
          fillOpacity: 0.7
        },
        reservoirs: {
          fillColor: layerColors.reservoirs,
          weight: 1.5,
          opacity: 0.9,
          color: '#00ACC1',
          fillOpacity: 0.8
        },
        settlements: {
          radius: 6,
          fillColor: layerColors.settlements,
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
          // 自动将水系面图层和水系线图层置顶
          if (layerType === 'waterAreas' || layerType === 'waterLines') {
            layer.bringToFront()
          }
        } else {
          map.value.removeLayer(layer)
        }
      }
    }
    
    // 更新图层颜色
    const updateLayerColor = (layerType) => {
      const layer = layerObjects[layerType]
      if (layer && layers[layerType]) {
        // 重新设置图层样式
        layer.setStyle(getLayerStyle(layerType))
      }
    }
    
    // 显示颜色选择器
    const showColorPicker = (layerType) => {
      const colorInput = document.querySelector(`input[data-layer="${layerType}"]`)
      if (colorInput) {
        colorInput.click()
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
      systemTitle,
      layerColors,
      toggleLayer,
      updateLayerColor,
      showColorPicker
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
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  z-index: 1000;
  max-width: 280px;
}

.layer-control-panel h3 {
  margin: 0 0 15px 0;
  color: #333;
  font-size: 1.2rem;
}

.layer-control {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.layer-control:last-child {
  border-bottom: none;
}

.layer-control label {
  display: flex;
  align-items: center;
  cursor: pointer;
  font-size: 0.9rem;
  color: #555;
  flex: 1;
}

.layer-control input[type="checkbox"] {
  margin-right: 8px;
}

.layer-color-control {
  position: relative;
  display: flex;
  align-items: center;
}

.color-preview {
  width: 20px;
  height: 20px;
  border: 2px solid #ddd;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s ease;
  margin-left: 8px;
}

.color-preview:hover {
  border-color: #999;
  transform: scale(1.1);
}

.color-preview.point-preview {
  border-radius: 50%;
}

.color-input {
  width: 24px;
  height: 24px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  opacity: 0;
  position: absolute;
  pointer-events: none;
}

.data-info {
  position: absolute;
  bottom: 20px;
  left: 20px;
  background: white;
  padding: 15px;
  border-radius: 6px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  z-index: 1000;
  max-width: 280px;
}

.data-info h4 {
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

.info-value:hover {
  text-decoration: underline;
  color: #007bff;
}

@media (max-width: 768px) {
  .layer-control-panel {
    top: 10px;
    left: 10px;
    max-width: 250px;
    padding: 15px;
  }
  
  .data-info {
    max-width: 240px;
    padding: 12px;
    bottom: 10px;
    left: 10px;
  }
  
  .layer-control-panel h3 {
    font-size: 1rem;
  }
  
  .data-info h4 {
    font-size: 0.9rem;
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
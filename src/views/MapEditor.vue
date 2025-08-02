<template>
  <div class="map-editor-container">
    <map-editor-header title="电子地图编辑"></map-editor-header>
    
    <div class="map-editor-content">
      <div id="editor-map" class="editor-map" :class="{ 
        'zoom-in-cursor': activeMapTool === 'zoomIn',
        'zoom-out-cursor': activeMapTool === 'zoomOut',
        'grab-cursor': activeMapTool === 'pan',
        'grabbing-cursor': isPanning,
        'pointer-cursor': activeMapTool === 'selectFeature',
        'info-cursor': activeMapTool === 'identifyFeature'
      }"></div>
      <!-- 图层控制面板 -->
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
            水库(面)
          </label>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.reservoirPoints" @change="toggleLayer('reservoirPoints')">
            水库(点)
          </label>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.settlements" @change="toggleLayer('settlements')">
            居民地地名
          </label>
        </div>
      </div>
      <!-- 水库图片控制面板 -->
      <div v-if="showReservoirImgPanel" class="reservoir-img-panel">
        <span class="img-panel-close" @click="showReservoirImgPanel = false">×</span>
        <img :src="reservoirImgUrl" :alt="reservoirImgName" class="reservoir-img-main" onerror="this.style.display='none'" />
        <div class="reservoir-img-title">{{ reservoirImgName }}</div>
      </div>
      <!-- 自定义工具栏 -->
      <div class="custom-toolbar">
        <img src="/icons/打开mxd.png" alt="打开mxd" title="打开mxd" @click="openMxdFile" />
        <img src="/icons/放大.png" alt="放大" title="放大" @click="activateZoomIn" :class="{ 'active-tool': activeMapTool === 'zoomIn' }" />
        <img src="/icons/缩小.png" alt="缩小" title="缩小" @click="activateZoomOut" :class="{ 'active-tool': activeMapTool === 'zoomOut' }" />
        <img src="/icons/全图.png" alt="全图" title="全图" @click="viewFullExtent" />
        <img src="/icons/手.png" alt="平移" title="平移" @click="activatePan" :class="{ 'active-tool': activeMapTool === 'pan' }" />
        <img src="/icons/选择要素.png" alt="选择要素" title="选择要素" @click="activateSelectFeature" :class="{ 'active-tool': activeMapTool === 'selectFeature' }" />
        <!-- 新增：查询按钮 -->
        <img src="/icons/查询.png" alt="查询" title="查询" @click="activateQuery" :class="{ 'active-tool': activeMapTool === 'query' }" />
        <!-- 新增：渲染按钮 -->
        <img src="/icons/渲染.png" alt="渲染" title="渲染" @click="activateRender" :class="{ 'active-tool': activeMapTool === 'render' }" />
        <img src="/icons/识别要素.png" alt="识别要素" title="识别要素" @click="activateIdentifyFeature" :class="{ 'active-tool': activeMapTool === 'identifyFeature' }" />
        <img 
          src="/icons/左箭头.png" 
          alt="返回上一视图" 
          title="返回上一视图" 
          @click="goToPreviousView" 
          :class="{ 'disabled-tool': !canGoBack }"
        />
        <img 
          src="/icons/右箭头.png" 
          alt="转至下一视图" 
          title="转至下一视图" 
          @click="goToNextView" 
          :class="{ 'disabled-tool': !canGoForward }"
        />
      </div>
      <!-- 查询弹窗 -->
      <div v-if="activeMapTool === 'query'" class="search-bar-modal">
        <div class="search-bar-container">
          <input
            v-model="searchText"
            @keyup.enter="handleSearch"
            class="search-input"
            placeholder="请输入水库名称，如：怀柔水库"
            autofocus
          />
          <button class="search-btn" @click="handleSearch">查询</button>
          <span class="search-close" @click="activeMapTool = ''">×</span>
        </div>
        <div v-if="searchError" class="search-error">{{ searchError }}</div>
      </div>
      <!-- 加载提示 -->
      <div class="loading-overlay" v-if="loading">
        <div class="loading-spinner"></div>
        <div class="loading-text">正在加载地理数据...</div>
      </div>
      <!-- MXD文件选择输入框（隐藏） -->
      <input 
        type="file" 
        ref="mxdFileInput"
        style="display: none"
        @change="handleMxdFileSelected"
        accept=".mxd"
      />
      <!-- MXD图层控制面板 -->
      <div v-if="showMxdPanel" class="mxd-control-panel">
        <div class="mxd-panel-header">
          <h3>{{ currentMxdFile ? currentMxdFile.name : 'MXD文档' }}</h3>
          <span class="mxd-close-btn" @click="showMxdPanel = false">×</span>
        </div>
        <div class="mxd-panel-content">
          <!-- MXD文档图层列表 -->
          <div class="mxd-layer-list">
            <div class="mxd-layer-group">
              <div class="mxd-layer-group-header">
                <img class="folder-icon" src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiIgZmlsbD0iY3VycmVudENvbG9yIiBjbGFzcz0iYmkgYmktZm9sZGVyMi1vcGVuIiB2aWV3Qm94PSIwIDAgMTYgMTYiPgogIDxwYXRoIGQ9Ik0xIDMuNUExLjUgMS41IDAgMCAxIDIuNSAyaDIuNzY0Yy4wNTggMCAuMTE1LjAxNy4xNjcuMDQ4LjA1Mi4wMzEuMS4wNzQuMTM0LjEyNkw2LjcwNyAzLjVIMTMuNWEuNSA1IDAgMCAxIDAgMUg2LjcwN2wtMS4xNDMgMS4zNTJBLjUuNSAwIDAgMSA1LjIzNiA2SDIuNUEuNS41IDAgMCAxIDIgNS41VjR6TTIuNSAzaDIuNzY0Yy4wNTggMCAuMTE1LjAxNy4xNjcuMDQ4LjA1Mi4wMzEuMS4wNzQuMTM0LjEyNkw2LjcwNyA0LjVIMTMuNWEuNS41IDAgMCAxIC41LjV2N2ExLjUgMS41IDAgMCAxLTEuNSAxLjVoLTlBMS41IDEuNSAwIDAgMSAyIDEyVjYuNWguNVYxMmExIDEgMCAwIDAgMSAxaDlhMSAxIDAgMCAwIDEtMVY1aC05LjVhLjUuNSAwIDAgMS0uNDI4LS4yMzJsLTEuMjQxLTEuNTM4QTEuNSAxLjUgMCAwIDAgLjk1IDNIMi41eiIvPgo8L3N2Zz4=" />
                <span>图展</span>
              </div>
              <div class="mxd-layer-items">
                <div v-for="layer in mockMxdLayerData.slice(1)" 
                     :key="layer.id" 
                     class="mxd-layer-item" 
                     :style="{ marginLeft: '20px' }">
                  <input 
                    type="checkbox" 
                    :id="'mxd-layer-' + layer.id" 
                    v-model="layer.visible"
                    @change="toggleMxdLayer(layer)"
                  >
                  <label :for="'mxd-layer-' + layer.id" class="layer-label">
                    <span class="layer-icon" :style="getLayerIconStyle(layer)"></span>
                    <span class="layer-name">{{ layer.name }}</span>
                  </label>
                </div>
                <div v-if="mockMxdLayerData[0].children && mockMxdLayerData[0].children.length" 
                     class="mxd-layer-item">
                  <input 
                    type="checkbox" 
                    :id="'mxd-layer-beijing-resident-places'" 
                    v-model="mockMxdLayerData[0].children[0].visible"
                    @change="toggleMxdLayer(mockMxdLayerData[0].children[0])"
                  >
                  <label :for="'mxd-layer-beijing-resident-places'" class="layer-label">
                    <span class="layer-icon point-icon"></span>
                    <span class="layer-name">居民地地名</span>
                  </label>
                </div>
              </div>
            </div>
          </div>
          
          <!-- MXD文档属性 -->
          <div class="mxd-properties">
            <h4>文档属性</h4>
            <div class="mxd-property-item">
              <span>文件大小:</span>
              <span>592.00 KB</span>
            </div>
            <div class="mxd-property-item">
              <span>修改日期:</span>
              <span>2025/4/11 17:16:19</span>
            </div>
            <div class="mxd-property-item">
              <span>图层数量:</span>
              <span>8</span>
            </div>
          </div>
        </div>
      </div>
      <!-- 渲染对话框 -->
      <div v-if="activeMapTool === 'render'" class="render-modal">
        <div class="render-modal-content">
          <div class="render-modal-header">
            <span>水库点分级渲染</span>
            <span class="render-modal-close" @click="activeMapTool = ''">×</span>
          </div>
          <div class="render-modal-body">
            <div class="render-row">
              <label>字段：</label>
              <select v-model="renderField" class="render-select">
                <option v-for="f in reservoirPointFields" :key="f" :value="f">{{ f }}</option>
              </select>
            </div>
            <div class="render-row">
              <label>条件：</label>
              <select v-model="renderOp" class="render-select">
                <option value=">">大于</option>
                <option value="<">小于</option>
                <option value=">=">大于等于</option>
                <option value="<=">小于等于</option>
                <option value="==">等于</option>
                <option value="range">区间</option>
              </select>
              <input v-model="renderValue1" class="render-input" placeholder="数值" type="number" />
              <span v-if="renderOp==='range'"> - </span>
              <input v-if="renderOp==='range'" v-model="renderValue2" class="render-input" placeholder="数值" type="number" />
            </div>
            <div class="render-row">
              <label>颜色：</label>
              <input v-model="renderColor" class="render-color" type="color" />
              <span class="render-color-label">满足条件</span>
              <input v-model="renderElseColor" class="render-color" type="color" />
              <span class="render-color-label">不满足</span>
            </div>
            <div class="render-row">
              <button class="render-btn" @click="handleRender">渲染</button>
            </div>
            <div v-if="renderError" class="render-error">{{ renderError }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue'
import * as L from 'leaflet'
import MapEditorHeader from '../components/MapEditorHeader.vue'
import 'leaflet/dist/leaflet.css'

const map = ref(null)
const loading = ref(true)

// 图层状态
const layers = reactive({
  districts: true,
  waterLines: true,
  waterAreas: true,
  reservoirs: true,
  settlements: true,
  reservoirPoints: false
})

// 图层对象
const layerObjects = reactive({
  districts: null,
  waterLines: null,
  waterAreas: null,
  reservoirs: null,
  settlements: null,
  reservoirPoints: null
})

// 初始化地图
const initMap = () => {
  map.value = L.map('editor-map', {
    zoomControl: false,
    attributionControl: false
  }).setView([39.9042, 116.4074], 10)
  // 不加载任何在线底图
}

// 加载GeoJSON数据（Beijing-GeoJson-Tzy目录）
const loadGeoJSONData = async () => {
  const dataFiles = {
    districts: '/Beijing-GeoJson-Tzy/北京区县界.json',
    waterLines: '/Beijing-GeoJson-Tzy/北京市_水系线数据.json',
    waterAreas: '/Beijing-GeoJson-Tzy/北京市_水系面数据.geojson',
    reservoirs: '/Beijing-GeoJson-Tzy/水库面数据.geojson', // 优化：确保水库面数据路径正确
    settlements: '/Beijing-GeoJson-Tzy/居民地地名.json',
    reservoirPoints: '/Beijing-GeoJson-Tzy/水库点数据.geojson' // 优化：确保水库点数据路径正确
  }
  for (const [key, filePath] of Object.entries(dataFiles)) {
    try {
      const response = await fetch(filePath)
      const data = await response.json()
      // 优化：区分点和面类型
      let layer
      if (key === 'reservoirPoints') {
        layer = L.geoJSON(data, {
          pointToLayer: (feature, latlng) => L.circleMarker(latlng, getLayerStyle(key)),
          onEachFeature: (feature, lyr) => {
            if (feature.properties) {
              lyr.bindPopup(getPopupContent(key, feature.properties))
              // 移除点击时弹图片面板的逻辑
            }
          }
        })
      } else if (key === 'reservoirs') {
        layer = L.geoJSON(data, {
          style: getLayerStyle(key),
          onEachFeature: (feature, lyr) => {
            if (feature.properties) {
              lyr.bindPopup(getPopupContent(key, feature.properties))
            }
          }
        })
      } else if (key === 'settlements') {
        layer = L.geoJSON(data, {
          pointToLayer: (feature, latlng) => L.circleMarker(latlng, getLayerStyle(key)),
          onEachFeature: (feature, lyr) => {
            if (feature.properties) {
              lyr.bindPopup(getPopupContent(key, feature.properties))
            }
          }
        })
      } else {
        layer = L.geoJSON(data, {
          style: getLayerStyle(key),
          onEachFeature: (feature, lyr) => {
            if (feature.properties) {
              lyr.bindPopup(getPopupContent(key, feature.properties))
            }
          }
        })
      }
      layerObjects[key] = layer
      if (layers[key]) {
        layer.addTo(map.value)
        if (key === 'waterAreas' || key === 'reservoirs') {
          layer.bringToFront()
        }
      }
    } catch (error) {
      console.error(`加载${key}数据失败:`, error)
    }
  }
  loading.value = false
}

// 图层样式
const getLayerStyle = (layerType) => {
  const styles = {
    districts: {
      fillColor: '#b3e5fc', // 淡蓝色
      weight: 2.5,
      opacity: 0.8,
      color: '#0288D1', // 蓝色边线
      fillOpacity: 0.5,
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
    },
    reservoirPoints: {
      radius: 7,
      fillColor: '#1976D2',
      color: '#fff',
      weight: 2,
      opacity: 1,
      fillOpacity: 0.95
    }
  }
  return styles[layerType] || {}
}

// 弹窗内容
const getPopupContent = (layerType, properties) => {
  let html = '<div class="popup-content">'
  for (const [key, value] of Object.entries(properties)) {
    html += `<div><strong>${key}:</strong> ${value !== null && value !== undefined ? value : '未知'}</div>`
  }
  // 仅水库点/面显示图片
  if (layerType === 'reservoirPoints' || layerType === 'reservoirs') {
    const name = properties.库名 || properties.name || properties.NAME
    if (name) {
      html += `
        <div class="popup-img-block">
          <img class='popup-reservoir-img' src="/reservoir-images/${name}.jpg" alt="${name}" onerror="this.style.display='none'" />
          <div class='popup-img-title'>${name}</div>
          <div class='popup-img-divider'></div>
        </div>
      `
    }
  }
  html += '</div>'
  return html
}

// 切换图层显示
const toggleLayer = (layerType) => {
  const layer = layerObjects[layerType]
  if (layer) {
    if (layers[layerType]) {
      if (!map.value.hasLayer(layer)) {
        layer.addTo(map.value)
        if (layerType === 'waterAreas' || layerType === 'reservoirs') {
          layer.bringToFront()
        }
      }
    } else {
      if (map.value.hasLayer(layer)) {
        map.value.removeLayer(layer)
      }
    }
  }
}

// 新增：查询和渲染工具激活方法
const activateQuery = () => {
  activeMapTool.value = 'query'
}
const activateRender = () => {
  activeMapTool.value = 'render'
}

// 新增：activeMapTool变量
const activeMapTool = ref('')

const searchText = ref('')
const searchError = ref('')

// 查询并定位水库点（成功时显示图片面板）
const handleSearch = () => {
  searchError.value = ''
  if (!searchText.value.trim()) {
    searchError.value = '请输入水库名称'
    return
  }
  const layer = layerObjects.reservoirPoints
  if (!layer) {
    searchError.value = '水库点图层未加载'
    return
  }
  let found = false
  layer.eachLayer(l => {
    const props = l.feature && l.feature.properties
    if (props && (props.库名 === searchText.value.trim() || props.name === searchText.value.trim() || props.NAME === searchText.value.trim())) {
      found = true
      map.value.setView(l.getLatLng(), 14, { animate: true })
      l.openPopup()
      // 高亮效果
      if (l.setStyle) {
        l.setStyle({ color: '#ff0000', fillColor: '#ffcccc', weight: 4 })
        setTimeout(() => layer.resetStyle && layer.resetStyle(l), 2000)
      }
      // 查询到后显示图片面板
      const name = props.库名 || props.name || props.NAME
      if (name) {
        reservoirImgUrl.value = `/reservoir-images/${name}.jpg`
        reservoirImgName.value = name
        showReservoirImgPanel.value = true
      } else {
        showReservoirImgPanel.value = false
      }
    }
  })
  if (!found) {
    searchError.value = '未找到对应水库点'
    showReservoirImgPanel.value = false
  }
}

const showReservoirImgPanel = ref(false)
const reservoirImgUrl = ref('')
const reservoirImgName = ref('')

// 渲染对话框相关
const reservoirPointFields = ref([
  '库名','多年平均水位','多年平均蓄水量','多年日平均入库流量','多年日平均出库流量','总库容','汛限水位'
])
const renderField = ref('多年平均水位')
const renderOp = ref('>')
const renderValue1 = ref('')
const renderValue2 = ref('')
const renderColor = ref('#ff4d4f')
const renderElseColor = ref('#1976d2')
const renderError = ref('')

const handleRender = () => {
  renderError.value = ''
  const layer = layerObjects.reservoirPoints
  if (!layer) {
    renderError.value = '水库点图层未加载'
    return
  }
  if (!renderField.value) {
    renderError.value = '请选择字段'
    return
  }
  let v1 = parseFloat(renderValue1.value)
  let v2 = parseFloat(renderValue2.value)
  if (renderOp.value === 'range' && (isNaN(v1) || isNaN(v2))) {
    renderError.value = '请输入区间数值'
    return
  }
  if (renderOp.value !== 'range' && isNaN(v1)) {
    renderError.value = '请输入数值'
    return
  }
  layer.eachLayer(l => {
    const props = l.feature && l.feature.properties
    let val = parseFloat(props[renderField.value])
    let match = false
    if (!isNaN(val)) {
      switch (renderOp.value) {
        case '>': match = val > v1; break
        case '<': match = val < v1; break
        case '>=': match = val >= v1; break
        case '<=': match = val <= v1; break
        case '==': match = val === v1; break
        case 'range': match = val >= Math.min(v1,v2) && val <= Math.max(v1,v2); break
      }
    }
    l.setStyle({
      fillColor: match ? renderColor.value : renderElseColor.value,
      color: match ? renderColor.value : renderElseColor.value,
      fillOpacity: 0.95,
      opacity: 1,
      weight: 2
    })
  })
}

onMounted(() => {
  initMap()
  loadGeoJSONData()
})
</script>

<style scoped>
.map-editor-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  width: 100%;
  background: #ffffff; /* 确保容器没有背景 */
}

.map-editor-content {
  flex: 1;
  overflow: hidden;
  position: relative;
  background-color: #f5f5f5; /* 替换原来的背景色 */
}

.editor-map {
  width: 100%;
  height: calc(100vh - 72px);
  z-index: 1; /* 确保地图在最底层 */
}

/* 移除可能导致紫色方块的背景样式 */
body {
  background: #ffffff; /* 替换渐变背景 */
}

#app {
  background: #ffffff; /* 确保app容器没有背景 */
}

.control-panel {
  position: absolute;
  top: 32px;
  right: 32px;
  background: rgba(255,255,255,0.97);
  border-radius: 16px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.10);
  padding: 20px 28px 20px 24px;
  z-index: 1000;
  min-width: 180px;
  max-width: 320px;
  width: auto;
  font-size: 16px;
}
.layer-control {
  margin-bottom: 8px;
}
.loading {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: rgba(255,255,255,0.95);
  padding: 16px 32px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  font-size: 18px;
  z-index: 2000;
}
.custom-toolbar {
  position: absolute;
  top: 120px;
  left: 18px;
  display: flex;
  flex-direction: column;
  align-items: center;
  background: rgba(255,255,255,0.95);
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.10);
  padding: 10px 6px;
  z-index: 1200;
  gap: 10px;
}
.custom-toolbar img {
  width: 32px;
  height: 32px;
  margin: 0 0 2px 0;
  cursor: pointer;
  object-fit: contain;
  transition: background 0.2s;
  border-radius: 6px;
}
.custom-toolbar img:hover {
  background: #e6f7ff;
}
.custom-toolbar img.active-tool {
  background: #1890ff;
  filter: brightness(1.2);
}
.custom-toolbar img.disabled-tool {
  opacity: 0.4;
  cursor: default;
  filter: grayscale(100%);
}
.custom-toolbar img.disabled-tool:hover {
  background: transparent;
}

/* 放大镜鼠标样式 */
.zoom-in-cursor {
  cursor: zoom-in !important;
}

/* 缩小镜鼠标样式 */
.zoom-out-cursor {
  cursor: zoom-out !important;
}

/* 平移鼠标样式 - 准备抓取 */
.grab-cursor {
  cursor: grab !important;
}

/* 平移鼠标样式 - 抓取中 */
.grabbing-cursor {
  cursor: grabbing !important;
}

/* 选择要素鼠标样式 */
.pointer-cursor {
  cursor: pointer !important;
}

/* 识别要素鼠标样式 */
.info-cursor {
  cursor: help !important;
}

/* MXD文件处理相关样式 */
.mxd-loading-toast,
.mxd-success-toast,
.mxd-error-toast {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  padding: 15px 25px;
  border-radius: 8px;
  z-index: 2000;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 3px 10px rgba(0, 0, 0, 0.2);
  animation: fadeIn 0.3s ease;
  font-weight: 500;
}

.mxd-loading-toast {
  background-color: #ffffff;
  color: #333;
  display: flex;
  flex-direction: column;
}

.mxd-success-toast {
  background-color: #4caf50;
  color: white;
}

.mxd-error-toast {
  background-color: #f44336;
  color: white;
}

.spinner {
  border: 3px solid rgba(0, 0, 0, 0.1);
  border-radius: 50%;
  border-top: 3px solid #2196F3;
  width: 30px;
  height: 30px;
  margin-bottom: 10px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* MXD控制面板样式 */
.mxd-control-panel {
  position: absolute;
  top: 10px;
  right: 10px;
  width: 280px;
  background-color: #fff;
  border-radius: 4px;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
  z-index: 1000;
  overflow: hidden;
  max-height: calc(100vh - 100px);
  display: flex;
  flex-direction: column;
}

.mxd-panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px;
  background-color: #f0f0f0;
  border-bottom: 1px solid #ccc;
}

.mxd-panel-header h3 {
  margin: 0;
  font-size: 16px;
}

.mxd-close-btn {
  cursor: pointer;
  font-size: 20px;
  line-height: 1;
}

.mxd-panel-content {
  padding: 10px;
  overflow-y: auto;
}

.mxd-layer-group {
  margin-bottom: 15px;
}

.mxd-layer-group-header {
  display: flex;
  align-items: center;
  margin-bottom: 8px;
  font-weight: bold;
}

.folder-icon {
  width: 16px;
  height: 16px;
  margin-right: 5px;
}

.mxd-layer-items {
  margin-left: 5px;
}

.mxd-layer-item {
  display: flex;
  align-items: center;
  margin-bottom: 6px;
}

.mxd-layer-item input {
  margin-right: 8px;
}

.layer-label {
  display: flex;
  align-items: center;
  cursor: pointer;
}

.layer-icon {
  margin-right: 5px;
}

.point-icon {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: #ff7800;
  border: 1px solid #000;
  display: inline-block;
  margin-right: 5px;
}

.layer-name {
  font-size: 14px;
}

.group-name {
  font-weight: 600;
}

.disabled {
  color: #999;
  cursor: not-allowed;
}

.mxd-properties {
  margin-top: 15px;
  padding-top: 15px;
  border-top: 1px solid #eee;
}

.mxd-properties h4 {
  margin: 0 0 10px;
  font-size: 14px;
}

.mxd-property-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 5px;
  font-size: 12px;
}

/* 要素属性面板样式 */
.feature-properties-panel {
  position: absolute;
  bottom: 20px;
  right: 20px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.15);
  width: 300px;
  max-height: 400px;
  overflow-y: auto;
  z-index: 1000;
  display: none;
}

.properties-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 15px;
  background: #f0f0f0;
  border-top-left-radius: 8px;
  border-top-right-radius: 8px;
  border-bottom: 1px solid #ddd;
}

.properties-header h3 {
  margin: 0;
  font-size: 16px;
  color: #333;
}

.close-btn {
  cursor: pointer;
  font-size: 20px;
  color: #666;
}

.properties-content {
  padding: 10px 15px;
}

.property-item {
  margin-bottom: 8px;
  display: flex;
  justify-content: space-between;
}

.property-name {
  font-weight: bold;
  color: #555;
  margin-right: 10px;
}

.property-value {
  color: #333;
}

/* 弹出框样式 */
.popup-content {
  font-size: 12px;
  max-height: 200px;
  overflow-y: auto;
}

.popup-content div {
  margin-bottom: 5px;
}

.search-bar-modal {
  position: absolute;
  top: 40px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 2001;
  background: rgba(255,255,255,0.98);
  border-radius: 12px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.13);
  padding: 18px 24px 12px 18px;
  min-width: 320px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}
.search-bar-container {
  display: flex;
  align-items: center;
  width: 100%;
}
.search-input {
  flex: 1;
  padding: 7px 12px;
  font-size: 15px;
  border: 1px solid #d0d0d0;
  border-radius: 6px;
  outline: none;
  margin-right: 10px;
}
.search-btn {
  background: #1890ff;
  color: #fff;
  border: none;
  border-radius: 6px;
  padding: 7px 18px;
  font-size: 15px;
  cursor: pointer;
  margin-right: 8px;
  transition: background 0.2s;
}
.search-btn:hover {
  background: #40a9ff;
}
.search-close {
  font-size: 22px;
  color: #888;
  cursor: pointer;
  margin-left: 2px;
  user-select: none;
}
.search-error {
  color: #f5222d;
  margin-top: 8px;
  font-size: 14px;
}
.popup-img-block {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin: 12px 0 4px 0;
}
.popup-reservoir-img {
  max-width: 220px;
  max-height: 120px;
  border-radius: 8px;
  box-shadow: 0 2px 12px #bbb;
  margin-bottom: 6px;
  transition: transform 0.25s cubic-bezier(.4,2,.6,1.2), box-shadow 0.2s;
  cursor: pointer;
}
.popup-reservoir-img:hover {
  transform: scale(1.08);
  box-shadow: 0 6px 24px #888;
}
.popup-img-title {
  font-size: 15px;
  color: #333;
  font-weight: 500;
  margin-bottom: 4px;
  letter-spacing: 1px;
}
.popup-img-divider {
  width: 80%;
  height: 1px;
  background: #ececec;
  margin: 6px 0 0 0;
  border-radius: 1px;
}
.reservoir-img-panel {
  position: absolute;
  top: 220px;
  right: 32px;
  min-width: 240px;
  max-width: 320px;
  background: rgba(255,255,255,0.98);
  border-radius: 14px;
  box-shadow: 0 4px 18px rgba(0,0,0,0.13);
  padding: 18px 18px 12px 18px;
  display: flex;
  flex-direction: column;
  align-items: center;
  z-index: 1201;
}
.img-panel-close {
  position: absolute;
  top: 8px;
  right: 12px;
  font-size: 22px;
  color: #888;
  cursor: pointer;
  user-select: none;
}
.reservoir-img-main {
  max-width: 220px;
  max-height: 120px;
  border-radius: 8px;
  box-shadow: 0 2px 12px #bbb;
  margin-bottom: 8px;
  margin-top: 8px;
  transition: transform 0.25s cubic-bezier(.4,2,.6,1.2), box-shadow 0.2s;
  cursor: pointer;
}
.reservoir-img-main:hover {
  transform: scale(1.08);
  box-shadow: 0 6px 24px #888;
}
.reservoir-img-title {
  font-size: 16px;
  color: #222;
  font-weight: 500;
  margin-bottom: 2px;
  letter-spacing: 1px;
  text-align: center;
}
.render-modal {
  position: absolute;
  top: 60px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 2002;
  background: rgba(255,255,255,0.99);
  border-radius: 14px;
  box-shadow: 0 4px 18px rgba(0,0,0,0.13);
  min-width: 340px;
  max-width: 420px;
  padding: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
}
.render-modal-content {
  width: 100%;
  padding: 18px 24px 18px 24px;
}
.render-modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 18px;
  font-weight: 600;
  color: #222;
  margin-bottom: 12px;
}
.render-modal-close {
  font-size: 22px;
  color: #888;
  cursor: pointer;
  user-select: none;
}
.render-modal-body {
  width: 100%;
}
.render-row {
  display: flex;
  align-items: center;
  margin-bottom: 14px;
}
.render-row label {
  min-width: 54px;
  color: #555;
  font-size: 15px;
  margin-right: 8px;
}
.render-select {
  min-width: 120px;
  font-size: 15px;
  padding: 4px 8px;
  border-radius: 6px;
  border: 1px solid #d0d0d0;
  margin-right: 10px;
}
.render-input {
  width: 70px;
  font-size: 15px;
  padding: 4px 8px;
  border-radius: 6px;
  border: 1px solid #d0d0d0;
  margin-right: 10px;
}
.render-color {
  width: 32px;
  height: 32px;
  border: none;
  border-radius: 6px;
  margin-right: 6px;
  box-shadow: 0 1px 4px #eee;
}
.render-color-label {
  font-size: 13px;
  color: #888;
  margin-right: 12px;
}
.render-btn {
  background: #1890ff;
  color: #fff;
  border: none;
  border-radius: 6px;
  padding: 7px 24px;
  font-size: 16px;
  cursor: pointer;
  transition: background 0.2s;
}
.render-btn:hover {
  background: #40a9ff;
}
.render-error {
  color: #f5222d;
  margin-top: 8px;
  font-size: 14px;
}
</style> 
<template>
  <div class="map-editor-container">
    <map-editor-header title="电子地图编辑"></map-editor-header>
    
    <div class="map-editor-content">
      <div id="editor-map" class="editor-map"></div>
      <!-- 自定义工具栏 -->
      <div class="custom-toolbar">
        <img src="/icons/打开mxd.png" alt="打开mxd" title="打开mxd" @click="openMxdFile" />
        <img src="/icons/放大.png" alt="放大" title="放大" @click="zoomIn" />
        <img src="/icons/缩小.png" alt="缩小" title="缩小" @click="zoomOut" />
        <img src="/icons/全图.png" alt="全图" title="全图" @click="viewFullExtent" />
        <img src="/icons/手.png" alt="平移" title="平移" />
        <img src="/icons/选择要素.png" alt="选择要素" title="选择要素" />
        <img src="/icons/识别要素.png" alt="识别要素" title="识别要素" />
        <img src="/icons/左箭头.png" alt="返回上一视图" title="返回上一视图" />
        <img src="/icons/右箭头.png" alt="转至下一视图" title="转至下一视图" />
      </div>
      <!-- 加载提示 -->
      <div class="loading-overlay" v-if="loading">
        <div class="loading-spinner"></div>
        <div class="loading-text">加载MXD文件中...</div>
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
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, reactive } from 'vue'
import * as L from 'leaflet'
import MapEditorHeader from '../components/MapEditorHeader.vue'
import 'leaflet/dist/leaflet.css'

const map = ref(null)
const loading = ref(false)
const mxdFileInput = ref(null)
const currentMxdFile = ref(null)
const showMxdPanel = ref(false)

// MXD图层
const mxdLayers = ref([]);
// MXD图层对象
const mxdLayerObjects = ref({});

// 模拟MXD文件中的图层数据
const mockMxdLayerData = [
  {
    id: 'mxd-main-group',
    name: '图层',
    type: 'group',
    visible: true,
    children: [
      {
        id: 'beijing-resident-places',
        name: '居民地地名',
        type: 'point',
        visible: true
      }
    ]
  },
  {
    id: 'beijing-water-lines',
    name: '北京市_水系线数据',
    type: 'line',
    visible: true
  },
  {
    id: 'beijing-water-areas',
    name: '北京市_水系面数据',
    type: 'polygon',
    visible: true
  },
  {
    id: 'beijing-reservoirs',
    name: '北京市水库',
    type: 'polygon',
    visible: true
  },
  {
    id: 'beijing-districts',
    name: '北京区县界',
    type: 'polygon',
    visible: true
  }
];
    
    // 初始化地图
    const initMap = () => {
  if (map.value) return; // 防止重复初始化
  
  // 创建地图实例
  map.value = L.map('editor-map', {
    center: [39.9042, 116.4074], // 北京市中心坐标
    zoom: 11,
    zoomControl: false, // 禁用默认缩放控件
    layers: [], // 初始不加载任何图层
    minZoom: 3,  // 允许更小的缩放级别
    maxZoom: 19, // 允许更大的缩放级别
    preferCanvas: true // 使用Canvas渲染，提高性能
  });
  
  // 添加底图
  const baseLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap contributors',
    maxZoom: 19, 
    minZoom: 3,
    subdomains: ['a', 'b', 'c'], // 使用多个子域名减轻服务器负担
    crossOrigin: true,
    detectRetina: true // 支持Retina显示器
  }).addTo(map.value);
  
  // 监听瓦片加载错误，尝试重新加载
  baseLayer.on('tileerror', function(error) {
    console.warn('地图瓦片加载失败，尝试重新加载', error);
    setTimeout(() => {
      error.tile.src = error.tile.src.replace(/&rand=\d+/, '') + '&rand=' + Math.random();
    }, 1000);
  });
  
  // 备选地图源（如果OpenStreetMap不可用）
  const backupBaseLayer = L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; OpenStreetMap contributors, &copy; CARTO',
    subdomains: 'abcd',
    maxZoom: 20
  });
  
  // 如果主地图源出现问题，切换到备用地图源
  setTimeout(() => {
    const container = document.getElementById('editor-map');
    // 检查是否有灰色瓦片（加载失败的标志）
    const grayTiles = container.querySelectorAll('img.leaflet-tile[src*="openstreetmap"][style*="visibility: hidden"]');
    if (grayTiles.length > 5) {
      console.log('检测到多个地图瓦片加载失败，切换到备用地图源');
      map.value.removeLayer(baseLayer);
      backupBaseLayer.addTo(map.value);
    }
  }, 5000);
  
  // 添加缩放控件（位置：右上角）
  L.control.zoom({
    position: 'topright'
  }).addTo(map.value);
  
  // 添加比例尺
  L.control.scale({
    position: 'bottomleft',
    imperial: false // 只显示公制单位
  }).addTo(map.value);
  
  console.log('地图初始化完成，当前中心点:', map.value.getCenter());
};

// 地图缩放功能
const zoomIn = () => {
  if (map.value) {
    map.value.zoomIn();
  }
};

const zoomOut = () => {
  if (map.value) {
    map.value.zoomOut();
  }
};

// 处理地图全图显示
const viewFullExtent = () => {
  if (!map.value) return;
  
  // 如果有图层，则适应所有图层的范围
  if (Object.keys(mxdLayerObjects.value).length > 0) {
    try {
      const visibleLayers = Object.values(mxdLayerObjects.value).filter(layer => 
        map.value.hasLayer(layer));
      
      if (visibleLayers.length > 0) {
        const group = L.featureGroup(visibleLayers);
        const bounds = group.getBounds();
        if (bounds.isValid()) {
          map.value.fitBounds(bounds, { padding: [50, 50], maxZoom: 12 });
          return;
        }
      }
    } catch (e) {
      console.warn('获取图层范围失败:', e);
    }
  }
  
  // 如果没有图层或获取范围失败，则返回北京市中心视图
  map.value.setView([39.9042, 116.4074], 10);
};

// 从MXD文件中加载图层到地图
const loadMxdLayersToMap = () => {
  console.log('处理MXD文件图层...');
  
  // 清除旧的MXD图层
  clearMxdLayers();
  
  // 扁平化图层数据，提取所有可视化图层（非组）
  const flattenLayers = [];
  const processMxdData = (layers, parentVisible = true) => {
    layers.forEach(layer => {
      if (layer.type === 'group') {
        // 递归处理子图层，传递父图层的可见性
        if (layer.children && layer.children.length > 0) {
          processMxdData(layer.children, parentVisible && layer.visible);
        }
        flattenLayers.push({ ...layer, isGroup: true }); // 保留组信息
      } else {
        // 图层的实际可见性受父图层影响
        flattenLayers.push({ 
          ...layer, 
          effectiveVisible: parentVisible && layer.visible 
        });
      }
    });
  };
  processMxdData(mockMxdLayerData);
  mxdLayers.value = flattenLayers;
  
  // 创建一个加载进度跟踪器
  let layersToLoad = 0;
  let layersLoaded = 0;
  
  // 遍历模拟的图层数据并添加到地图
  mxdLayers.value.forEach(layerData => {
    // 跳过组图层
    if (layerData.isGroup) return;
    
    layersToLoad++;
    let layer;
    
    switch(layerData.type) {
      case 'point':
        layer = loadGeoJsonLayer('居民地地名.json', 'point');
        break;
      case 'polygon':
        if (layerData.id === 'beijing-water-areas') {
          layer = loadGeoJsonLayer('北京市_水系面数据.json', 'polygon');
        } else if (layerData.id === 'beijing-reservoirs') {
          layer = loadGeoJsonLayer('北京市水库.json', 'polygon');
        } else if (layerData.id === 'beijing-districts') {
          layer = loadGeoJsonLayer('北京区县界.json', 'polygon');
        }
        break;
      case 'line':
        layer = loadGeoJsonLayer('北京市_水系线数据.json', 'line');
        break;
      case 'basemap':
        // 底图已经添加，无需处理
        layersToLoad--;
        return;
      default:
        console.log(`未处理的图层类型: ${layerData.type}`);
        layersToLoad--;
        return;
    }
    
    if (layer) {
      mxdLayerObjects.value[layerData.id] = layer;
      if (layerData.effectiveVisible) {
        layer.addTo(map.value);
      }
      
      // 监听图层加载完成事件
      if (layer.on) {
        layer.on('add', () => {
          layersLoaded++;
          if (layersLoaded >= layersToLoad) {
            console.log('所有图层加载完成');
            loading.value = false;
          }
        });
      } else {
        // 如果图层不支持事件，假设它已经加载完成
        layersLoaded++;
      }
    }
  });

  // 显示MXD图层控制面板
  showMxdPanel.value = true;
  
  // 如果没有图层需要加载，直接标记为加载完成
  if (layersToLoad === 0) {
    loading.value = false;
  }
  
  // 防止无限等待，设置一个超时
      setTimeout(() => {
    if (loading.value) {
      console.log('图层加载超时，强制完成');
      loading.value = false;
    }
  }, 5000);
};

// 清除MXD图层
const clearMxdLayers = () => {
  // 从地图中移除所有图层
  Object.values(mxdLayerObjects.value).forEach(layer => {
    if (map.value.hasLayer(layer)) {
      map.value.removeLayer(layer);
    }
  });
  
  // 清空图层对象记录
  mxdLayerObjects.value = {};
  console.log('清除所有MXD图层');
};

// 切换MXD图层显示/隐藏
const toggleMxdLayer = (layer) => {
  // 如果是组图层，需要更新其所有子图层的显示状态
  if (layer.isGroup) {
    // 获取该组下所有子图层
    const childLayers = mxdLayers.value.filter(l => 
      !l.isGroup && l.id.startsWith(layer.id + '-') || 
      (layer.children && layer.children.some(child => child.id === l.id))
    );
    
    // 更新所有子图层的可见性状态
    childLayers.forEach(childLayer => {
      childLayer.visible = layer.visible;
      childLayer.effectiveVisible = layer.visible;
      toggleMxdLayer(childLayer); // 递归处理子图层
    });
    return;
  }
  
  const leafletLayer = mxdLayerObjects.value[layer.id];
  if (leafletLayer) {
    if (layer.visible) {
      leafletLayer.addTo(map.value);
      console.log(`显示图层: ${layer.name}`);
    } else {
      map.value.removeLayer(leafletLayer);
      console.log(`隐藏图层: ${layer.name}`);
    }
  }
};

// 加载GeoJSON图层
const loadGeoJsonLayer = (filename, type) => {
  console.log(`加载GeoJSON图层: ${filename}`);
  
  // 创建一个空的GeoJSON图层
  const layer = L.geoJSON(null, {
    style: () => {
      // 根据类型设置不同的样式
      if (type === 'polygon') {
        return { 
          color: filename.includes('水') ? '#3388ff' : '#33cc33',
          weight: 2,
          opacity: 0.8,
          fillOpacity: 0.4
        };
      } else if (type === 'line') {
        return {
          color: '#3388ff',
          weight: 2,
          opacity: 0.8
        };
      }
    },
    pointToLayer: (feature, latlng) => {
      // 创建点图层
      return L.circleMarker(latlng, {
        radius: 4,
        fillColor: '#ff7800',
        color: '#000',
        weight: 1,
        opacity: 1,
        fillOpacity: 0.8
      });
    },
    onEachFeature: (feature, layer) => {
      // 添加弹出信息
      if (feature.properties && (feature.properties.name || feature.properties.NAME)) {
        layer.bindPopup(feature.properties.name || feature.properties.NAME);
      }
    }
  });
  
  // 异步加载GeoJSON数据
  fetch(`/Beijing-GeoJson/${filename}`)
    .then(response => response.json())
    .then(data => {
      // 检查GeoJSON的投影系统
      const crs = data.crs || { type: 'name', properties: { name: 'EPSG:4326' } };
      console.log(`GeoJSON数据 ${filename} 的投影系统:`, crs);
      
      layer.addData(data);
      console.log(`成功加载GeoJSON数据: ${filename}`);
      
      // 适应加载图层的视图
      if (map.value && layer.getBounds) {
        try {
          // 获取图层范围
          const bounds = layer.getBounds();
          if (bounds.isValid()) {
            // 如果是第一个加载的图层，适应视图
            if (Object.keys(mxdLayerObjects.value).length === 1) {
              map.value.fitBounds(bounds, { padding: [50, 50] });
              console.log(`适应图层 ${filename} 的视图范围`);
            }
          }
        } catch (e) {
          console.warn(`无法获取图层 ${filename} 的范围`, e);
        }
      }
    })
    .catch(error => {
      console.error(`加载GeoJSON数据失败: ${filename}`, error);
    });
  
  return layer;
};

// 打开mxd文件
const openMxdFile = () => {
  // 触发隐藏的文件输入框点击
  mxdFileInput.value.click();
}

// 处理选择的mxd文件
const handleMxdFileSelected = (event) => {
  const file = event.target.files[0];
  if (!file) return;
  
  currentMxdFile.value = file;
  
  // 创建加载提示
  const loadingToast = document.createElement('div');
  loadingToast.className = 'mxd-loading-toast';
  loadingToast.innerHTML = `<div class="spinner"></div><p>正在加载 ${file.name}...</p>`;
  document.body.appendChild(loadingToast);
  
  // 读取文件内容（如果需要）
  const reader = new FileReader();
  reader.onload = (e) => {
    try {
      // 这里处理mxd文件
      console.log('MXD文件已加载:', file.name);
      
      // 由于浏览器不能直接处理mxd文件(ArcGIS专用格式)，这里模拟处理完成
      setTimeout(() => {
        // 移除加载提示
        document.body.removeChild(loadingToast);
        
        // 创建成功提示
        const successToast = document.createElement('div');
        successToast.className = 'mxd-success-toast';
        successToast.textContent = `MXD文件 "${file.name}" 已成功加载`;
        document.body.appendChild(successToast);
        
        // 3秒后移除成功提示
        setTimeout(() => {
          document.body.removeChild(successToast);
        }, 3000);
        
        // 加载MXD图层到地图上
        loadMxdLayersToMap();
      }, 1500); // 模拟处理时间
    } catch (error) {
      console.error('加载MXD文件失败:', error);
      // 移除加载提示
      document.body.removeChild(loadingToast);
      
      // 创建错误提示
      const errorToast = document.createElement('div');
      errorToast.className = 'mxd-error-toast';
      errorToast.textContent = '加载MXD文件失败，请检查文件格式是否正确';
      document.body.appendChild(errorToast);
      
      // 3秒后移除错误提示
      setTimeout(() => {
        document.body.removeChild(errorToast);
      }, 3000);
    }
  };
  
  reader.onerror = () => {
    console.error('读取文件失败');
    // 移除加载提示
    document.body.removeChild(loadingToast);
    
    // 创建错误提示
    const errorToast = document.createElement('div');
    errorToast.className = 'mxd-error-toast';
    errorToast.textContent = '读取文件失败，请重试';
    document.body.appendChild(errorToast);
    
    // 3秒后移除错误提示
    setTimeout(() => {
      document.body.removeChild(errorToast);
    }, 3000);
  };
  
  // 开始读取文件 - 只是为了获取文件信息，不实际处理mxd内容
  // 因为浏览器无法直接处理mxd文件，这里只是读取文件作为模拟
  reader.readAsDataURL(file);
  
  // 重置文件输入，允许重新选择同一个文件
  event.target.value = '';
}

// 获取图层图标样式
const getLayerIconStyle = (layer) => {
  switch (layer.type) {
    case 'point':
      return {
        backgroundColor: '#ff7800',
        borderRadius: '50%',
        width: '10px',
        height: '10px',
        display: 'inline-block'
      };
    case 'line':
      return {
        backgroundColor: '#3388ff',
        width: '10px',
        height: '2px',
        display: 'inline-block'
      };
    case 'polygon':
      return {
        backgroundColor: layer.id.includes('water') ? '#3388ff' : '#33cc33',
        width: '10px',
        height: '10px',
        display: 'inline-block'
      };
    default:
      return {};
  }
};

onMounted(() => {
  setTimeout(() => {
    initMap()
  }, 100)
})
onUnmounted(() => {
  if (map.value) {
    map.value.remove()
  }
})
</script>

<style scoped>
.map-editor-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  width: 100%;
}

.map-editor-content {
  flex: 1;
  overflow: hidden;
  position: relative;
}

.editor-map {
  width: 100%;
  height: calc(100vh - 72px);
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
</style> 
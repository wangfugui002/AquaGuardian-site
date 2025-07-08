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
    </div>
  </div>
</template>

<script>
import { onMounted, onUnmounted, ref } from 'vue'
import L from 'leaflet'
import * as EsriLeaflet from 'esri-leaflet'
import PredictionSimulationHeader from '../components/PredictionSimulationHeader.vue'

export default {
  name: 'PredictionSimulation',
  components: {
    PredictionSimulationHeader
  },
  setup() {
    let map = null;
    const activeFeature = ref(null);
    
    // 初始化地图
    const initMap = () => {
      map = L.map('prediction-map', {
        backgroundColor: '#ffffff', // 设置地图背景色为白色
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
      
      // 这里可以添加预测模拟相关的功能
    }
    
    // 激活功能
    const activateFeature = (feature) => {
      activeFeature.value = feature;
      console.log(`已激活功能: ${feature}`);
      
      // 根据选择的功能执行相应的操作
      switch(feature) {
        case 'warning':
          // 预警分析功能
          alert('预警分析功能已启动');
          break;
        case 'flood':
          // 水库淹没模拟功能
          alert('水库淹没模拟功能已启动');
          break;
        case 'pollution':
          // 污染物扩散模拟功能
          alert('污染物扩散模拟功能已启动');
          break;
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
    })
    
    return {
      activeFeature,
      activateFeature
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
</style> 
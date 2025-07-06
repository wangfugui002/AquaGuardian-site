<template>
  <div class="prediction-simulation-container">
    <prediction-simulation-header title="预测模拟"></prediction-simulation-header>
    
    <div class="prediction-simulation-content">
      <div id="prediction-map" class="prediction-map"></div>
    </div>
  </div>
</template>

<script>
import { onMounted, onUnmounted } from 'vue'
import L from 'leaflet'
import PredictionSimulationHeader from '../components/PredictionSimulationHeader.vue'

export default {
  name: 'PredictionSimulation',
  components: {
    PredictionSimulationHeader
  },
  setup() {
    let map = null;
    
    // 初始化地图
    const initMap = () => {
      map = L.map('prediction-map').setView([39.9042, 116.4074], 10);
      
      // 添加OpenStreetMap底图
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors'
      }).addTo(map);
      
      // 这里可以添加预测模拟相关的功能
    }
    
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
    
    return {}
  }
}
</script>

<style scoped>
.prediction-simulation-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  width: 100%;
}

.prediction-simulation-content {
  flex: 1;
  overflow: hidden;
}

.prediction-map {
  width: 100%;
  height: calc(100vh - 72px); /* 减去Header的高度 */
}
</style> 
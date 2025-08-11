<template>
  <div class="statistics-analysis-container">
    <statistics-analysis-header title="统计分析"></statistics-analysis-header>
    
    <div class="statistics-analysis-content">
      <div id="statistics-map" class="statistics-map"></div>
    </div>
  </div>
</template>

<script>
import { onMounted, onUnmounted } from 'vue'
import L from 'leaflet'
import StatisticsAnalysisHeader from '../components/StatisticsAnalysisHeader.vue'

export default {
  name: 'StatisticsAnalysis',
  components: {
    StatisticsAnalysisHeader
  },
  setup() {
    let map = null;
    
    // 初始化地图
    const initMap = () => {
      map = L.map('statistics-map').setView([39.9042, 116.4074], 10);
      
      // 添加OpenStreetMap底图
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors'
      }).addTo(map);
      
      // 这里可以添加统计分析相关的功能
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
.statistics-analysis-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  width: 100%;
}

.statistics-analysis-content {
  flex: 1;
  overflow: hidden;
}

.statistics-map {
  width: 100%;
  height: calc(100vh - 72px); /* 减去Header的高度 */
}
</style> 
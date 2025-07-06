<template>
  <div class="data-management-container">
    <data-management-header title="数据管理"></data-management-header>
    
    <div class="data-management-content">
      <div id="data-map" class="data-map"></div>
    </div>
  </div>
</template>

<script>
import { onMounted, onUnmounted } from 'vue'
import L from 'leaflet'
import DataManagementHeader from '../components/DataManagementHeader.vue'

export default {
  name: 'DataManagement',
  components: {
    DataManagementHeader
  },
  setup() {
    let map = null;
    
    // 初始化地图
    const initMap = () => {
      map = L.map('data-map').setView([39.9042, 116.4074], 10);
      
      // 添加OpenStreetMap底图
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors'
      }).addTo(map);
      
      // 这里可以添加数据管理相关的功能
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
.data-management-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  width: 100%;
}

.data-management-content {
  flex: 1;
  overflow: hidden;
}

.data-map {
  width: 100%;
  height: calc(100vh - 72px); /* 减去Header的高度 */
}
</style> 
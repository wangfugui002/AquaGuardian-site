<template>
  <div class="map-editor-container">
    <map-editor-header title="电子地图编辑"></map-editor-header>
    
    <div class="map-editor-content">
      <div id="editor-map" class="editor-map"></div>
    </div>
  </div>
</template>

<script>
import { onMounted, onUnmounted } from 'vue'
import L from 'leaflet'
import MapEditorHeader from '../components/MapEditorHeader.vue'

export default {
  name: 'MapEditor',
  components: {
    MapEditorHeader
  },
  setup() {
    let map = null;
    
    // 初始化地图
    const initMap = () => {
      map = L.map('editor-map').setView([39.9042, 116.4074], 10);
      
      // 添加OpenStreetMap底图
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors'
      }).addTo(map);
      
      // 加载北京市各类数据...
      // 这里可以通过fetch加载各类GeoJSON数据
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
.map-editor-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  width: 100%;
}

.map-editor-content {
  flex: 1;
  overflow: hidden;
}

.editor-map {
  width: 100%;
  height: calc(100vh - 72px); /* 减去Header的高度 */
}
</style> 
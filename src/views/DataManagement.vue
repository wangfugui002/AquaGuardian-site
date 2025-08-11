<template>
  <div class="data-management-container">
    <data-management-header title="数据管理"></data-management-header>
    <div class="data-management-main">
      <div class="data-management-sidebar">
        <div class="sidebar-box" :class="{active: activeBox==='waterSituation'}" @click="activeBox='waterSituation'">水情管理</div>
        <div class="sidebar-box" :class="{active: activeBox==='sectionMonitor'}" @click="activeBox='sectionMonitor'">监测断面管理</div>
      </div>
      <div class="data-management-content">
        <!-- 水情管理 -->
        <div v-if="activeBox==='waterSituation'" class="water-situation-panel">
          <water-situation-list />
        </div>
        
        <!-- 监测断面管理 -->
        <div v-else-if="activeBox==='sectionMonitor'" class="section-monitor-panel">
          <section-monitor-list />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import DataManagementHeader from '../components/DataManagementHeader.vue'
import WaterSituationList from './waterSituation/List.vue'
import SectionMonitorList from './sectionMonitor/List.vue'

export default {
  name: 'DataManagement',
  components: {
    DataManagementHeader,
    WaterSituationList,
    SectionMonitorList
  },
  setup() {
    const activeBox = ref('waterSituation')
    
    return {
      activeBox
    }
  }
}
</script>

<style scoped>
.data-management-container {
  width: 100%;
  height: 100vh;
  display: flex;
  flex-direction: column;
  background-color: #f5f5f5;
}

.data-management-main {
  flex: 1;
  display: flex;
  overflow: hidden;
}

.data-management-sidebar {
  width: 200px;
  background: white;
  border-right: 1px solid #e0e0e0;
  padding: 20px 0;
  box-shadow: 2px 0 4px rgba(0,0,0,0.1);
}

.sidebar-box {
  padding: 15px 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  border-left: 4px solid transparent;
  font-size: 16px;
  color: #666;
}

.sidebar-box:hover {
  background-color: #f8f9fa;
  color: #333;
}

.sidebar-box.active {
  background-color: #e3f2fd;
  color: #1976d2;
  border-left-color: #1976d2;
  font-weight: 500;
}

.data-management-content {
  flex: 1;
  overflow: auto;
  padding: 0;
}

.water-situation-panel,
.section-monitor-panel {
  height: 100%;
  overflow: auto;
}
</style> 
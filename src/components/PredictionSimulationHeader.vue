<template>
  <header class="header">
    <div class="header-content">
      <div class="logo-container">
        <!-- 返回按钮 -->
        <router-link to="/" class="back-button" title="返回主页">
          <img src="/icons/返回 (2).png" alt="返回" width="32" height="32" />
        </router-link>
      </div>
      <h1 class="title">{{ title }}</h1>
      
      <!-- 前四个功能图标 - 紧跟标题 -->
      <div class="title-icons">
        <router-link to="/map-editor" class="action-icon" title="电子地图编辑">
          <img src="/icons/地图编辑.png" alt="电子地图编辑" width="32" height="32" />
        </router-link>
        <router-link to="/data-management" class="action-icon" title="数据管理">
          <img src="/icons/数据管理.png" alt="数据管理" width="32" height="32" />
        </router-link>
        <router-link to="/statistics-analysis" class="action-icon" title="统计分析">
          <img src="/icons/统计分析.png" alt="统计分析" width="32" height="32" />
        </router-link>
        <router-link to="/prediction-simulation" class="action-icon" title="预警分析">
          <img src="/icons/水位预警.png" alt="预警分析" width="32" height="32" />
        </router-link>
        <router-link to="/water-pollution-simulation" class="action-icon" title="水污染扩散模拟">
          <img src="/icons/预测模拟.png" alt="水污染扩散模拟" width="32" height="32" />
        </router-link>
      </div>
      
      <div class="header-actions">
        <!-- 第六个功能图标 - 系统设置 -->
        <div class="action-icon" title="系统设置">
          <img src="/icons/设置.png" alt="系统设置" width="32" height="32" />
        </div>
      </div>
    </div>
  </header>
</template>

<script>
export default {
  name: 'PredictionSimulationHeader',
  props: {
    title: {
      type: String,
      default: '预警分析'
    }
  }
}
</script>

<style scoped>
.header {
  background: linear-gradient(135deg, #1a2a6c 0%, #2a5298 50%, #4389a2 100%);
  padding: 1rem 2rem;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  margin-bottom: 0;
  text-align: center;
  position: relative;
  z-index: 1000;
}

.header-content {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  max-width: 1200px;
  margin: 0 auto;
}

.logo-container {
  margin-right: 0.7rem;
  display: flex;
  align-items: center;
}

.back-button {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0.3rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.back-button:hover {
  transform: translateX(-3px);
}

.title {
  margin: 0;
  color: white;
  font-size: 1.8rem;
  font-weight: 600;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
  letter-spacing: 1px;
}

.title-icons {
  display: flex;
  align-items: center;
  margin-left: 3rem;
}

.header-actions {
  margin-left: auto;
  display: flex;
  align-items: center;
}

.action-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-left: 1.5rem;
  cursor: pointer;
  opacity: 0.8;
  transition: all 0.2s ease;
}

.title-icons .action-icon {
  margin-left: 1.5rem;
}

.title-icons .action-icon:first-child {
  margin-left: 0;
}

.action-icon:hover {
  opacity: 1;
  transform: translateY(-2px);
}

@media (max-width: 768px) {
  .header {
    padding: 0.8rem 1rem;
  }
  
  .title {
    font-size: 1.4rem;
  }
  
  .title-icons {
    margin-left: 1rem;
  }

  .title-icons .action-icon {
    margin-left: 0.8rem;
  }

  .action-icon {
    margin-left: 0.8rem;
  }
}
</style> 
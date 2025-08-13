<template>
  <header class="header">
    <div class="header-content">
      <div class="logo-container">
        <!-- 水滴图标 -->
        <div class="logo-icon">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="48" height="48">
            <path fill="#29b6f6" d="M400,320c0,88.37-55.63,144-144,144S112,408.37,112,320c0-94.83,103.23-222.85,134.89-259.88a12,12,0,0,1,18.22,0C296.77,97.15,400,225.17,400,320Z"/>
            <path fill="#0288d1" d="M344,328a72,72,0,0,1-72,72"/>
            <path fill="#ffffff" opacity="0.6" d="M216,196a20,20,0,1,1,20-20A20,20,0,0,1,216,196Z"/>
          </svg>
        </div>
      </div>
      <router-link to="/" class="title-link">
      <h1 class="title">{{ title }}</h1>
      </router-link>
      
      <!-- 前五个功能图标 - 紧跟标题 -->
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
        <!-- 第五个功能图标 - 系统设置 -->
        <div class="action-icon" title="系统设置">
          <img src="/icons/设置.png" alt="系统设置" width="32" height="32" />
        </div>
      </div>
    </div>
  </header>
</template>

<script>
export default {
  name: 'PageHeader',
  props: {
    title: {
      type: String,
      default: '环境风险分析与模拟系统'
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

.logo-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0.3rem;
}

.title {
  margin: 0;
  color: white;
  font-size: 1.8rem;
  font-weight: 600;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
  letter-spacing: 1px;
}

.title-link {
  text-decoration: none;
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
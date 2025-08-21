<template>
  <div class="statistics-analysis-header">
    <div class="header-content">
      <h1 class="page-title">{{ title }}</h1>
      <div class="header-description">
        <p>提供全面的水情和环境数据统计分析功能</p>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'StatisticsAnalysisHeader',
  props: {
    title: {
      type: String,
      default: '统计分析'
    }
  }
}
</script>

<style scoped>
.statistics-analysis-header {
  background: linear-gradient(135deg, #1976d2 0%, #42a5f5 100%);
  color: white;
  padding: 2rem;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
}

.page-title {
  margin: 0 0 0.5rem 0;
  font-size: 2.5rem;
  font-weight: 300;
  letter-spacing: 1px;
}

.header-description {
  margin: 0;
}

.header-description p {
  margin: 0;
  font-size: 1.1rem;
  opacity: 0.9;
  font-weight: 300;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .statistics-analysis-header {
    padding: 1.5rem;
  }
  
  .page-title {
    font-size: 2rem;
  }
  
  .header-description p {
    font-size: 1rem;
  }
}
</style> 
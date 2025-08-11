import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'

// 导入页面组件
const MapEditor = () => import('../views/MapEditor.vue')
const DataManagement = () => import('../views/DataManagement.vue')
const StatisticsAnalysis = () => import('../views/StatisticsAnalysis.vue')
const PredictionSimulation = () => import('../views/PredictionSimulation.vue')
const WaterPollutionSimulation = () => import('../views/WaterPollutionSimulation.vue')

// 定义路由
const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/map-editor',
    name: 'MapEditor',
    component: MapEditor
  },
  {
    path: '/data-management',
    name: 'DataManagement',
    component: DataManagement
  },
  {
    path: '/statistics-analysis',
    name: 'StatisticsAnalysis',
    component: StatisticsAnalysis
  },
  {
    path: '/prediction-simulation',
    name: 'PredictionSimulation',
    component: PredictionSimulation
  },
  {
    path: '/water-pollution-simulation',
    name: 'WaterPollutionSimulation',
    component: WaterPollutionSimulation
  }
]

// 创建路由实例
const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router 
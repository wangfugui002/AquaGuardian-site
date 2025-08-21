<template>
  <div class="statistics-analysis-container">
    <statistics-analysis-header title="统计分析"></statistics-analysis-header>
    
    <div class="statistics-analysis-main">
      <div class="statistics-sidebar">
        <div class="sidebar-box" :class="{active: activeBox==='waterStatistics'}" @click="activeBox='waterStatistics'">水情统计</div>
        <div class="sidebar-box" :class="{active: activeBox==='waterComparison'}" @click="activeBox='waterComparison'">水情对比</div>
        <div class="sidebar-box" :class="{active: activeBox==='environmentStatistics'}" @click="activeBox='environmentStatistics'">环境统计</div>
        <div class="sidebar-box" :class="{active: activeBox==='environmentComparison'}" @click="activeBox='environmentComparison'">环境对比</div>
      </div>
      
      <div class="statistics-content">
        <!-- 水情统计 -->
        <div v-if="activeBox==='waterStatistics'" class="water-statistics-panel">
          <div class="panel-header">
            <h2>水情统计</h2>
            <div class="header-actions">
              <el-select v-model="selectedReservoir" placeholder="选择水库" style="width: 200px; margin-right: 10px;">
                <el-option 
                  v-for="reservoir in reservoirList" 
                  :key="reservoir" 
                  :label="reservoir" 
                  :value="reservoir" 
                />
              </el-select>
              <el-date-picker
                v-model="selectedDate"
                type="date"
                placeholder="选择日期"
                value-format="YYYY-MM-DD"
                :disabled-date="disableUnavailableDates"
                style="width: 180px; margin-right: 10px;"
              />
              <el-button type="primary" @click="applySelectedWaterStats">查询</el-button>
            </div>
          </div>
          
          <div class="statistics-cards">
            <el-card class="stat-card">
              <div class="stat-value">{{ (waterStats.avgWaterLevel || 0).toFixed(2) }}</div>
              <div class="stat-label">库水位(米)</div>
            </el-card>
            <el-card class="stat-card">
              <div class="stat-value">{{ (waterStats.totalStorage || 0).toFixed(0) }}</div>
              <div class="stat-label">蓄水量(万立方米)</div>
            </el-card>
            <el-card class="stat-card">
              <div class="stat-value">{{ (waterStats.avgInflow || 0).toFixed(2) }}</div>
              <div class="stat-label">日均入库流量(立方米/秒)</div>
            </el-card>
            <el-card class="stat-card">
              <div class="stat-value">{{ (waterStats.avgOutflow || 0).toFixed(2) }}</div>
              <div class="stat-label">日均出库流量(立方米/秒)</div>
            </el-card>
          </div>
          
          <div class="chart-container">
            <h3>水库水位分布</h3>
            <div id="water-level-chart" class="chart"></div>
          </div>
        </div>
        
        <!-- 水情对比 -->
        <div v-else-if="activeBox==='waterComparison'" class="water-comparison-panel">
          <div class="panel-header">
            <h2>水情对比</h2>
            <div class="header-actions">
              <el-select v-model="selectedReservoirs" multiple collapse-tags placeholder="选择水库(至少2个)" style="width: 380px; margin-right: 10px;">
                <el-option 
                  v-for="reservoir in reservoirList" 
                  :key="reservoir" 
                  :label="reservoir" 
                  :value="reservoir" 
                />
              </el-select>
              <el-select v-model="comparisonIndicator" placeholder="选择对比指标" style="width: 150px; margin-right: 10px;">
                <el-option label="库水位" value="waterLevel" />
                <el-option label="蓄水量" value="storage" />
                <el-option label="入库流量" value="avgInflow" />
                <el-option label="出库流量" value="avgOutflow" />
              </el-select>
              <el-button type="primary" @click="refreshComparisonData">刷新对比</el-button>
            </div>
          </div>
          
          <div class="chart-container">
            <h3>水库指标对比分析</h3>
            <div id="water-comparison-chart" class="chart"></div>
          </div>
        </div>
        
        <!-- 环境统计 -->
        <div v-else-if="activeBox==='environmentStatistics'" class="environment-statistics-panel">
          <div class="panel-header">
            <h2>环境统计</h2>
            <div class="header-actions">
              <el-select v-model="selectedMonitorPoint" placeholder="选择监测点" style="width: 200px; margin-right: 10px;">
                <el-option 
                  v-for="point in monitorPointList" 
                  :key="point" 
                  :label="point" 
                  :value="point" 
                />
              </el-select>
              <el-date-picker
                v-model="selectedEnvMonth"
                type="month"
                placeholder="选择月份"
                value-format="YYYY-MM"
                :disabled-date="disableUnavailableEnvMonths"
                style="width: 180px; margin-right: 10px;"
              />
              <el-button type="primary" @click="applySelectedEnvironmentStats">查询</el-button>
            </div>
          </div>
          
          <div class="statistics-cards">
            <el-card class="stat-card">
              <div class="stat-value">{{ formatNumber(envDisplayStats.ammoniaNitrogen, 2) }}</div>
              <div class="stat-label">氨氮(mg/L)</div>
            </el-card>
            <el-card class="stat-card">
              <div class="stat-value">{{ formatNumber(envDisplayStats.permanganateIndex, 2) }}</div>
              <div class="stat-label">高锰酸盐(mg/L)</div>
            </el-card>
            <el-card class="stat-card">
              <div class="stat-value">{{ formatNumber(envDisplayStats.cod, 2) }}</div>
              <div class="stat-label">化学需氧量(mg/L)</div>
            </el-card>
            <el-card class="stat-card">
              <div class="stat-value">{{ formatNumber(envDisplayStats.flow, 2) }}</div>
              <div class="stat-label">流量(m³/s)</div>
            </el-card>
            <el-card class="stat-card">
              <div class="stat-value">{{ formatNumber(envDisplayStats.depth, 2) }}</div>
              <div class="stat-label">水深(m)</div>
            </el-card>
            <el-card class="stat-card">
              <div class="stat-value">{{ formatNumber(envDisplayStats.totalNitrogen, 2) }}</div>
              <div class="stat-label">总氮(mg/L)</div>
            </el-card>
            <el-card class="stat-card">
              <div class="stat-value">{{ formatNumber(envDisplayStats.totalPhosphorus, 2) }}</div>
              <div class="stat-label">总磷(mg/L)</div>
            </el-card>
          </div>
          
          <div class="chart-container">
            <h3>水质指标分布</h3>
            <div id="water-quality-chart" class="chart"></div>
          </div>
        </div>
        
        <!-- 环境对比 -->
        <div v-else-if="activeBox==='environmentComparison'" class="environment-comparison-panel">
          <div class="panel-header">
            <h2>环境对比</h2>
            <div class="header-actions">
              <el-select v-model="selectedMonitorPoints" multiple collapse-tags placeholder="选择监测点(至少2个)" style="width: 380px; margin-right: 10px;">
                <el-option 
                  v-for="point in monitorPointList" 
                  :key="point" 
                  :label="point" 
                  :value="point" 
                />
              </el-select>
              <el-select v-model="comparisonEnvironmentIndicator" placeholder="选择对比指标" style="width: 150px; margin-right: 10px;">
                <el-option label="氨氮" value="ammoniaNitrogen" />
                <el-option label="COD" value="cod" />
                <el-option label="总氮" value="totalNitrogen" />
                <el-option label="总磷" value="totalPhosphorus" />
              </el-select>
              <el-button type="primary" @click="refreshEnvironmentComparison">刷新对比</el-button>
            </div>
          </div>
          
          <div class="chart-container">
            <h3>监测点指标对比分析</h3>
            <div id="environment-comparison-chart" class="chart"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive, onMounted, watch } from 'vue'
import { ElMessage } from 'element-plus'
import StatisticsAnalysisHeader from '../components/StatisticsAnalysisHeader.vue'
import axios from 'axios'
import * as echarts from 'echarts'

export default {
  name: 'StatisticsAnalysis',
  components: {
    StatisticsAnalysisHeader
  },
  setup() {
    const activeBox = ref('waterStatistics')
    const selectedReservoir = ref('')
    const selectedDate = ref(null)
    const selectedReservoirDates = ref(new Set())
    const selectedReservoirs = ref([])
    const comparisonIndicator = ref('waterLevel')
    const comparisonMonitorPoint1 = ref('')
    const comparisonMonitorPoint2 = ref('')
    const comparisonEnvironmentIndicator = ref('ammoniaNitrogen')
    const selectedMonitorPoints = ref([])
    const selectedMonitorPoint = ref('')
    const selectedEnvMonth = ref(null)
    const selectedMonitorPointMonths = ref(new Set())
    const envDisplayStats = reactive({
      ammoniaNitrogen: 0,
      permanganateIndex: 0,
      cod: 0,
      flow: 0,
      depth: 0,
      totalNitrogen: 0,
      totalPhosphorus: 0
    })
    
    // 统计数据（用于面板展示）
    const waterStats = reactive({
      totalReservoirs: 0,
      avgWaterLevel: 0,
      totalStorage: 0,
      avgInflow: 0,
      avgOutflow: 0
    })
    
    const environmentStats = reactive({
      totalMonitorPoints: 0,
      avgOxygen: 0,
      avgCOD: 0,
      avgTotalNitrogen: 0
    })
    
    // 水库和监测点列表
    const reservoirList = ref([])
    const monitorPointList = ref([])
    
    // 存储原始数据用于对比
    const waterDataList = ref([])
    const environmentDataList = ref([])
    
    // 图表实例
    let waterLevelChart = null
    let waterComparisonChart = null
    let waterQualityChart = null
    let environmentComparisonChart = null
    
    // 工具：格式化日期为 YYYY-MM-DD
    const pad2 = (n) => String(n).padStart(2, '0')
    const formatDate = (dateObj) => {
      const y = dateObj.getFullYear()
      const m = pad2(dateObj.getMonth() + 1)
      const d = pad2(dateObj.getDate())
      return `${y}-${m}-${d}`
    }
    
    // 将任意输入归一化为 YYYY-MM-DD（尽量不受时区/格式影响）
    const normalizeToDayString = (input) => {
      if (!input) return ''
      if (typeof input === 'string') {
        const match = input.match(/(\d{4})[-\/.](\d{1,2})[-\/.](\d{1,2})/)
        if (match) {
          const y = Number(match[1])
          const m = Number(match[2])
          const d = Number(match[3])
          return `${y}-${pad2(m)}-${pad2(d)}`
        }
        const parsed = new Date(input)
        if (!isNaN(parsed)) return formatDate(parsed)
        return ''
      }
      if (input instanceof Date) return formatDate(input)
      return ''
    }
    
    // 禁用没有数据的日期
    const disableUnavailableDates = (date) => {
      if (!(selectedReservoirDates.value instanceof Set)) return false
      if (selectedReservoirDates.value.size === 0) return false
      const str = formatDate(date)
      return !selectedReservoirDates.value.has(str)
    }
    
    // 根据选择更新统计卡片
    const updateSelectedWaterStats = () => {
      if (!selectedReservoir.value || !selectedDate.value) {
        waterStats.avgWaterLevel = 0
        waterStats.totalStorage = 0
        waterStats.avgInflow = 0
        waterStats.avgOutflow = 0
        return
      }
      const dayData = waterDataList.value.filter(item => 
        item.reservoirName === selectedReservoir.value && normalizeToDayString(item.date) === selectedDate.value
      )
      if (dayData.length === 0) {
        waterStats.avgWaterLevel = 0
        waterStats.totalStorage = 0
        waterStats.avgInflow = 0
        waterStats.avgOutflow = 0
        return
      }
      const average = (arr, key) => arr.reduce((s, it) => s + (Number(it[key]) || 0), 0) / arr.length
      waterStats.avgWaterLevel = average(dayData, 'waterLevel')
      waterStats.totalStorage = average(dayData, 'storage')
      waterStats.avgInflow = average(dayData, 'avgInflow')
      waterStats.avgOutflow = average(dayData, 'avgOutflow')
    }
    
    // 手动触发选中条件的统计刷新
    const applySelectedWaterStats = () => {
      updateSelectedWaterStats()
    }
    
    // 当选择的水库变化时，刷新可选日期集合并默认选择最近日期
    const refreshSelectedReservoirDates = () => {
      if (!selectedReservoir.value) {
        selectedReservoirDates.value = new Set()
        return
      }
      const dates = waterDataList.value
        .filter(item => item.reservoirName === selectedReservoir.value)
        .map(item => normalizeToDayString(item.date))
        .filter(Boolean)
      const set = new Set(dates)
      selectedReservoirDates.value = set
      // 如果当前选中的日期不在集合中，则选择最大（最近）日期
      if (!selectedDate.value || !set.has(selectedDate.value)) {
        const sorted = Array.from(set).sort()
        selectedDate.value = sorted[sorted.length - 1] || ''
      }
    }
    
    // 获取水情统计数据
    const fetchWaterStatistics = async () => {
      try {
        const response = await axios.get('/api/waterSituation/list', {
          params: { page: 1, pageSize: 1000 }
        })
        const waterData = response.data.list || []
        waterDataList.value = waterData
        
        if (waterData.length > 0) {
          waterStats.totalReservoirs = new Set(waterData.map(item => item.reservoirName)).size
          reservoirList.value = [...new Set(waterData.map(item => item.reservoirName))]
          if (!selectedReservoir.value && reservoirList.value.length > 0) {
            selectedReservoir.value = reservoirList.value[0]
          }
          refreshSelectedReservoirDates()
          updateSelectedWaterStats()
          
          const waterLevelDistribution = waterData.map(item => ({
            reservoirName: item.reservoirName,
            waterLevel: item.waterLevel || 0
          }))
          renderWaterLevelChart(waterLevelDistribution)
        } else {
          waterStats.totalReservoirs = 0
          waterStats.avgWaterLevel = 0
          waterStats.totalStorage = 0
          waterStats.avgInflow = 0
          waterStats.avgOutflow = 0
          reservoirList.value = []
          selectedReservoir.value = ''
          selectedDate.value = ''
          selectedReservoirDates.value = new Set()
          renderWaterLevelChart([])
        }
      } catch (error) {
        console.error('获取水情统计数据失败:', error)
        ElMessage.error('获取水情统计数据失败，请检查数据管理页面是否有数据')
        waterStats.totalReservoirs = 0
        waterStats.avgWaterLevel = 0
        waterStats.totalStorage = 0
        waterStats.avgInflow = 0
        waterStats.avgOutflow = 0
        reservoirList.value = []
        selectedReservoir.value = ''
        selectedDate.value = ''
        selectedReservoirDates.value = new Set()
        renderWaterLevelChart([])
      }
    }
    
    // 工具：格式化月份 YYYY-MM
    const formatYearMonth = (dateObj) => {
      const y = dateObj.getFullYear()
      const m = pad2(dateObj.getMonth() + 1)
      return `${y}-${m}`
    }
    const normalizeToYearMonthString = (item) => {
      // 环境数据按年/月字段
      if (item && (item.year != null) && (item.month != null)) {
        return `${item.year}-${pad2(item.month)}`
      }
      return ''
    }
    const disableUnavailableEnvMonths = (date) => {
      if (!(selectedMonitorPointMonths.value instanceof Set)) return false
      if (selectedMonitorPointMonths.value.size === 0) return false
      const ym = formatYearMonth(date)
      return !selectedMonitorPointMonths.value.has(ym)
    }
    const getValueByAliases = (obj, aliases = []) => {
      if (!obj || typeof obj !== 'object') return 0
      const normalizeKey = (s) => String(s).toLowerCase().replace(/[_\-]/g, '')
      const normalizedMap = new Map(
        Object.entries(obj).map(([k, v]) => [normalizeKey(k), v])
      )
      for (const key of aliases) {
        // 先尝试精确键
        if (obj[key] != null && obj[key] !== '') {
          const num = Number(obj[key])
          if (!isNaN(num)) return num
        }
        // 再尝试归一化匹配（忽略大小写和下划线/连字符）
        const nk = normalizeKey(key)
        if (normalizedMap.has(nk)) {
          const num = Number(normalizedMap.get(nk))
          if (!isNaN(num)) return num
        }
      }
      return 0
    }
    const updateSelectedEnvironmentStats = () => {
      if (!selectedMonitorPoint.value || !selectedEnvMonth.value) {
        envDisplayStats.ammoniaNitrogen = 0
        envDisplayStats.permanganateIndex = 0
        envDisplayStats.cod = 0
        envDisplayStats.flow = 0
        envDisplayStats.depth = 0
        envDisplayStats.totalNitrogen = 0
        envDisplayStats.totalPhosphorus = 0
        return
      }
      const monthData = environmentDataList.value.filter(item => 
        item.monitorPointName === selectedMonitorPoint.value && normalizeToYearMonthString(item) === selectedEnvMonth.value
      )
      if (monthData.length === 0) {
        envDisplayStats.ammoniaNitrogen = 0
        envDisplayStats.permanganateIndex = 0
        envDisplayStats.cod = 0
        envDisplayStats.flow = 0
        envDisplayStats.depth = 0
        envDisplayStats.totalNitrogen = 0
        envDisplayStats.totalPhosphorus = 0
        return
      }
      const averageByAliases = (aliases) => monthData.reduce((s, it) => s + getValueByAliases(it, aliases), 0) / monthData.length
      envDisplayStats.ammoniaNitrogen = averageByAliases(['oxygen','ammoniaNitrogen','nh3n','ammonia'])
      envDisplayStats.permanganateIndex = averageByAliases(['potassiumPermanganate','potassium_permanganate','permanganateIndex','kmno4','codmn'])
      envDisplayStats.cod = averageByAliases(['cod'])
      envDisplayStats.flow = averageByAliases(['flow','flowRate'])
      envDisplayStats.depth = averageByAliases(['depth','waterDepth'])
      envDisplayStats.totalNitrogen = averageByAliases(['totalNitrogen'])
      envDisplayStats.totalPhosphorus = averageByAliases(['totalPhosphorus'])
    }
    const refreshSelectedMonitorPointMonths = () => {
      if (!selectedMonitorPoint.value) {
        selectedMonitorPointMonths.value = new Set()
        return
      }
      const months = environmentDataList.value
        .filter(item => item.monitorPointName === selectedMonitorPoint.value)
        .map(normalizeToYearMonthString)
        .filter(Boolean)
      const set = new Set(months)
      selectedMonitorPointMonths.value = set
      if (!selectedEnvMonth.value || !set.has(selectedEnvMonth.value)) {
        const sorted = Array.from(set).sort()
        selectedEnvMonth.value = sorted[sorted.length - 1] || null
      }
    }
    const applySelectedEnvironmentStats = () => {
      updateSelectedEnvironmentStats()
    }
    const formatNumber = (val, digits = 2) => {
      const num = Number(val)
      if (isNaN(num)) return '0.00'
      return num.toFixed(digits)
    }

    // 获取环境统计数据
    const fetchEnvironmentStatistics = async () => {
      try {
        // 从现有的监测断面管理API获取数据列表
        const response = await axios.get('/api/sectionMonitor/list', {
          params: {
            page: 1,
            pageSize: 1000 // 获取足够多的数据进行统计
          }
        })
        
        const environmentData = response.data.list || []
        environmentDataList.value = environmentData // 保存原始数据用于对比
        
        if (environmentData.length > 0) {
          // 计算统计数据
          environmentStats.totalMonitorPoints = new Set(environmentData.map(item => item.monitorPointName)).size
          environmentStats.avgOxygen = environmentData.reduce((sum, item) => sum + (item.ammoniaNitrogen || 0), 0) / environmentData.length
          environmentStats.avgCOD = environmentData.reduce((sum, item) => sum + (item.cod || 0), 0) / environmentData.length
          environmentStats.avgTotalNitrogen = environmentData.reduce((sum, item) => sum + (item.totalNitrogen || 0), 0) / environmentData.length
          
          // 获取监测点列表
          monitorPointList.value = [...new Set(environmentData.map(item => item.monitorPointName))]
          if (!selectedMonitorPoint.value && monitorPointList.value.length > 0) {
            selectedMonitorPoint.value = monitorPointList.value[0]
          }
          refreshSelectedMonitorPointMonths()
          updateSelectedEnvironmentStats()
          
          // 生成水质指标分布数据
          const waterQualityDistribution = environmentData.map(item => ({
            monitorPointName: item.monitorPointName,
            ammoniaNitrogen: (item.ammoniaNitrogen || item.oxygen || 0),
            cod: item.cod || 0,
            totalNitrogen: item.totalNitrogen || 0,
            totalPhosphorus: item.totalPhosphorus || 0
          }))
          
          // 渲染水质指标图表
          renderWaterQualityChart(waterQualityDistribution)
        } else {
          // 如果没有数据，显示默认值
          environmentStats.totalMonitorPoints = 0
          environmentStats.avgOxygen = 0
          environmentStats.avgCOD = 0
          environmentStats.avgTotalNitrogen = 0
          monitorPointList.value = []
          selectedMonitorPoint.value = ''
          selectedEnvMonth.value = null
          selectedMonitorPointMonths.value = new Set()
          envDisplayStats.ammoniaNitrogen = 0
          envDisplayStats.permanganateIndex = 0
          envDisplayStats.cod = 0
          envDisplayStats.flow = 0
          envDisplayStats.depth = 0
          envDisplayStats.totalNitrogen = 0
          envDisplayStats.totalPhosphorus = 0
          renderWaterQualityChart([])
        }
      } catch (error) {
        console.error('获取环境统计数据失败:', error)
        ElMessage.error('获取环境统计数据失败，请检查数据管理页面是否有数据')
        
        // 显示默认值
        environmentStats.totalMonitorPoints = 0
        environmentStats.avgOxygen = 0
        environmentStats.avgCOD = 0
        environmentStats.avgTotalNitrogen = 0
        monitorPointList.value = []
        selectedMonitorPoint.value = ''
        selectedEnvMonth.value = null
        selectedMonitorPointMonths.value = new Set()
        envDisplayStats.ammoniaNitrogen = 0
        envDisplayStats.permanganateIndex = 0
        envDisplayStats.cod = 0
        envDisplayStats.flow = 0
        envDisplayStats.depth = 0
        envDisplayStats.totalNitrogen = 0
        envDisplayStats.totalPhosphorus = 0
        renderWaterQualityChart([])
      }
    }
    
    // 渲染水位分布图表
    const renderWaterLevelChart = (data) => {
      if (!waterLevelChart) {
        waterLevelChart = echarts.init(document.getElementById('water-level-chart'))
      }
      
      if (!data || data.length === 0) {
        // 显示无数据提示
        waterLevelChart.setOption({
          title: {
            text: '水库水位分布',
            left: 'center'
          },
          graphic: {
            type: 'text',
            left: 'center',
            top: 'middle',
            style: {
              text: '暂无数据',
              fontSize: 16,
              fill: '#999'
            }
          }
        })
        return
      }
      
      const option = {
        title: {
          text: '水库水位分布',
          left: 'center'
        },
        tooltip: {
          trigger: 'axis'
        },
        xAxis: {
          type: 'category',
          data: data.map(item => item.reservoirName),
          axisLabel: {
            rotate: 45,
            interval: 0
          }
        },
        yAxis: {
          type: 'value',
          name: '水位(米)'
        },
        series: [{
          data: data.map(item => item.waterLevel),
          type: 'bar',
          itemStyle: {
            color: '#409EFF'
          }
        }]
      }
      
      waterLevelChart.setOption(option)
    }
    
    // 渲染水质指标图表
    const renderWaterQualityChart = (data) => {
      const container = document.getElementById('water-quality-chart')
      if (!container) {
        // 面板未渲染，跳过初始化
        return
      }
      if (!waterQualityChart) {
        waterQualityChart = echarts.init(container)
      }
      
      if (!data || data.length === 0) {
        // 显示无数据提示
        waterQualityChart.setOption({
          title: {
            text: '水质指标分布',
            left: 'center'
          },
          graphic: {
            type: 'text',
            left: 'center',
            top: 'middle',
            style: {
              text: '暂无数据',
              fontSize: 16,
              fill: '#999'
            }
          }
        })
        return
      }
      
      const option = {
        title: {
          text: '水质指标分布',
          left: 'center'
        },
        tooltip: {
          trigger: 'axis'
        },
        legend: {
          data: ['氨氮', 'COD', '总氮', '总磷'],
          top: 30
        },
        xAxis: {
          type: 'category',
          data: data.map(item => item.monitorPointName),
          axisLabel: {
            rotate: 45,
            interval: 0
          }
        },
        yAxis: {
          type: 'value',
          name: '浓度(mg/L)'
        },
        series: [
          {
            name: '氨氮',
            type: 'line',
            data: data.map(item => item.ammoniaNitrogen),
            itemStyle: { color: '#409EFF' }
          },
          {
            name: 'COD',
            type: 'line',
            data: data.map(item => item.cod),
            itemStyle: { color: '#E6A23C' }
          },
          {
            name: '总氮',
            type: 'line',
            data: data.map(item => item.totalNitrogen),
            itemStyle: { color: '#F56C6C' }
          },
          {
            name: '总磷',
            type: 'line',
            data: data.map(item => item.totalPhosphorus),
            itemStyle: { color: '#909399' }
          }
        ]
      }
      
      waterQualityChart.setOption(option)
    }
    
    // 刷新水情数据
    const refreshWaterData = () => {
      fetchWaterStatistics()
    }
    
    // 刷新环境数据
    const refreshEnvironmentData = () => {
      fetchEnvironmentStatistics()
    }
    
    // 刷新对比数据
    const refreshComparisonData = () => {
      if (selectedReservoirs.value.length >= 2 && comparisonIndicator.value) {
        // 实现水库对比逻辑（多水库）
        renderWaterComparisonChart()
      } else {
        ElMessage.warning('请至少选择两个水库，并选择对比指标')
      }
    }
    
    // 刷新环境对比数据
    const refreshEnvironmentComparison = () => {
      if (selectedMonitorPoints.value.length >= 2 && comparisonEnvironmentIndicator.value) {
        // 实现环境对比逻辑（多监测点）
        renderEnvironmentComparisonChart()
      } else {
        ElMessage.warning('请至少选择两个监测点，并选择对比指标')
      }
    }
    
    // 渲染水库对比图表（支持2个及以上水库）
    const renderWaterComparisonChart = () => {
      if (!waterComparisonChart) {
        waterComparisonChart = echarts.init(document.getElementById('water-comparison-chart'))
      }
      
      if (!waterDataList.value || waterDataList.value.length === 0) {
        waterComparisonChart.setOption({
          title: {
            text: '水库指标对比分析',
            left: 'center'
          },
          graphic: {
            type: 'text',
            left: 'center',
            top: 'middle',
            style: {
              text: '暂无数据',
              fontSize: 16,
              fill: '#999'
            }
          }
        })
        return
      }
      
      if (!selectedReservoirs.value || selectedReservoirs.value.length < 2) {
        ElMessage.warning('请至少选择两个水库')
        return
      }
      
      // 指标标签
      const indicatorLabels = {
        waterLevel: '库水位(米)',
        storage: '蓄水量(万立方米)',
        avgInflow: '入库流量(立方米/秒)',
        avgOutflow: '出库流量(立方米/秒)'
      }
      
      // 为每个已选水库收集数据
      const selected = selectedReservoirs.value
      const dataByReservoir = selected.map(name => ({
        name,
        data: waterDataList.value.filter(item => item.reservoirName === name)
      }))
      
      // 统一时间轴（日期）
      const dates = [...new Set([].concat(...dataByReservoir.map(d => d.data.map(item => item.date))))].sort()
      
      // 颜色调色板
      const palette = ['#409EFF','#E6A23C','#67C23A','#F56C6C','#909399','#9C27B0','#00BCD4','#8D6E63','#EC407A','#26A69A']
      
      // 动态系列
      const series = dataByReservoir.map((d, idx) => ({
        name: d.name,
        type: 'line',
        data: dates.map(date => {
          const item = d.data.find(x => normalizeToDayString(x.date) === date)
          return item ? (item[comparisonIndicator.value] || 0) : 0
        }),
        itemStyle: { color: palette[idx % palette.length] },
        lineStyle: { width: 3 },
        symbol: idx % 2 === 0 ? 'circle' : 'diamond',
        symbolSize: 6
      }))
      
      const option = {
        title: {
          text: `${selected.join('、')} - ${indicatorLabels[comparisonIndicator.value]}`,
          left: 'center'
        },
        tooltip: {
          trigger: 'axis',
          formatter: function(params) {
            let result = params[0].axisValue + '<br/>'
            params.forEach(param => {
              result += param.marker + param.seriesName + ': ' + param.value + '<br/>'
            })
            return result
          }
        },
        legend: {
          data: selected,
          top: 30
        },
        xAxis: {
          type: 'category',
          data: dates,
          axisLabel: {
            rotate: 45,
            interval: 0
          }
        },
        yAxis: {
          type: 'value',
          name: indicatorLabels[comparisonIndicator.value]
        },
        series
      }
      
      waterComparisonChart.setOption(option)
    }
    
    // 渲染环境对比图表
    const renderEnvironmentComparisonChart = () => {
      if (!environmentComparisonChart) {
        environmentComparisonChart = echarts.init(document.getElementById('environment-comparison-chart'))
      }
      
      if (!environmentDataList.value || environmentDataList.value.length === 0) {
        environmentComparisonChart.setOption({
          title: {
            text: '监测点指标对比分析',
            left: 'center'
          },
          graphic: {
            type: 'text',
            left: 'center',
            top: 'middle',
            style: {
              text: '暂无数据',
              fontSize: 16,
              fill: '#999'
            }
          }
        })
        return
      }
      
      // 校验至少两个监测点
      if (!selectedMonitorPoints.value || selectedMonitorPoints.value.length < 2) {
        ElMessage.warning('请至少选择两个监测点')
        return
      }
      
      // 获取指标标签
      const indicatorLabels = {
        ammoniaNitrogen: '氨氮(mg/L)',
        cod: 'COD(mg/L)',
        totalNitrogen: '总氮(mg/L)',
        totalPhosphorus: '总磷(mg/L)'
      }
      
      // 为每个监测点收集数据
      const selected = selectedMonitorPoints.value
      const dataByPoint = selected.map(name => ({
        name,
        data: environmentDataList.value.filter(item => item.monitorPointName === name)
      }))
      
      // 统一时间轴（年-月）
      const dates = [...new Set([].concat(...dataByPoint.map(d => d.data.map(item => `${item.year}-${item.month}`))))].sort()
      
      // 颜色调色板
      const palette = ['#409EFF','#E6A23C','#67C23A','#F56C6C','#909399','#9C27B0','#00BCD4','#8D6E63','#EC407A','#26A69A']
      
      // 动态系列
      const series = dataByPoint.map((d, idx) => ({
        name: d.name,
        type: 'line',
        data: dates.map(date => {
          const item = d.data.find(x => `${x.year}-${x.month}` === date)
          return item ? (item[comparisonEnvironmentIndicator.value] || 0) : 0
        }),
        itemStyle: { color: palette[idx % palette.length] },
        lineStyle: { width: 3 },
        symbol: idx % 2 === 0 ? 'circle' : 'diamond',
        symbolSize: 6
      }))
      
      const option = {
        title: {
          text: `${selected.join('、')} - ${indicatorLabels[comparisonEnvironmentIndicator.value]}`,
          left: 'center'
        },
        tooltip: {
          trigger: 'axis',
          formatter: function(params) {
            let result = params[0].axisValue + '<br/>'
            params.forEach(param => {
              result += param.marker + param.seriesName + ': ' + param.value + '<br/>'
            })
            return result
          }
        },
        legend: {
          data: selected,
          top: 30
        },
        xAxis: {
          type: 'category',
          data: dates,
          axisLabel: {
            rotate: 45,
            interval: 0
          }
        },
        yAxis: {
          type: 'value',
          name: indicatorLabels[comparisonEnvironmentIndicator.value]
        },
        series
      }
      
      environmentComparisonChart.setOption(option)
    }
    
    // 监听侧边栏切换
    watch(activeBox, (newVal) => {
      if (newVal === 'waterStatistics') {
        fetchWaterStatistics()
      } else if (newVal === 'environmentStatistics') {
        fetchEnvironmentStatistics()
      }
    })
    watch(selectedReservoir, () => {
      refreshSelectedReservoirDates()
      updateSelectedWaterStats()
    })
    watch(selectedDate, () => {
      updateSelectedWaterStats()
    })
    watch(selectedMonitorPoint, () => {
      refreshSelectedMonitorPointMonths()
      updateSelectedEnvironmentStats()
    })
    watch(selectedEnvMonth, () => {
      updateSelectedEnvironmentStats()
    })

    onMounted(() => {
      fetchWaterStatistics()
      fetchEnvironmentStatistics()
    })
    
    return {
      activeBox,
      selectedReservoir,
      selectedDate,
      selectedReservoirs,
      comparisonIndicator,
      comparisonMonitorPoint1,
      comparisonMonitorPoint2,
      comparisonEnvironmentIndicator,
      selectedMonitorPoints,
      waterStats,
      environmentStats,
      reservoirList,
      monitorPointList,
      disableUnavailableDates,
      applySelectedWaterStats,
      refreshWaterData,
      refreshEnvironmentData,
      refreshComparisonData,
      refreshEnvironmentComparison,
      selectedMonitorPoint,
      selectedEnvMonth,
      disableUnavailableEnvMonths,
      applySelectedEnvironmentStats,
      envDisplayStats,
      formatNumber
    }
  }
}
</script>

<style scoped>
.statistics-analysis-container {
  width: 100%;
  height: 100vh;
  display: flex;
  flex-direction: column;
  background-color: #f5f5f5;
}

.statistics-analysis-main {
  flex: 1;
  display: flex;
  overflow: hidden;
}

.statistics-sidebar {
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

.statistics-content {
  flex: 1;
  overflow: auto;
  padding: 2rem;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 2px solid #e0e0e0;
}

.panel-header h2 {
  margin: 0;
  color: #333;
  font-size: 1.8rem;
}

.header-actions {
  display: flex;
  align-items: center;
}

.statistics-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.stat-card {
  text-align: center;
  padding: 1.5rem;
  transition: transform 0.3s ease;
}

.stat-card:hover {
  transform: translateY(-5px);
}

.stat-value {
  font-size: 2.5rem;
  font-weight: bold;
  color: #1976d2;
  margin-bottom: 0.5rem;
}

.stat-label {
  font-size: 1rem;
  color: #666;
}

.chart-container {
  background: white;
  border-radius: 8px;
  padding: 1.5rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  margin-bottom: 2rem;
}

.chart-container h3 {
  margin: 0 0 1rem 0;
  color: #333;
  text-align: center;
}

.chart {
  width: 100%;
  height: 400px;
}

.water-statistics-panel,
.water-comparison-panel,
.environment-statistics-panel,
.environment-comparison-panel {
  height: 100%;
  overflow: auto;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .statistics-cards {
    grid-template-columns: 1fr;
  }
  
  .panel-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }
  
  .header-actions {
    width: 100%;
    justify-content: space-between;
  }
}
</style> 
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
                v-model="selectedDateRange"
                type="daterange"
                range-separator="至"
                start-placeholder="开始日期"
                end-placeholder="结束日期"
                value-format="YYYY-MM-DD"
                :disabled-date="disableUnavailableDates"
                style="width: 280px; margin-right: 10px;"
              />
              <el-select 
                v-model="selectedCharts" 
                multiple 
                collapse-tags 
                placeholder="选择显示表格(至少1个)" 
                style="width: 280px; margin-right: 10px;"
              >
                <el-option label="水位分布" value="waterLevel" />
                <el-option label="蓄水量变化" value="waterStorage" />
                <el-option label="日均入库流量变化" value="waterInflow" />
                <el-option label="日均出库流量变化" value="waterOutflow" />
              </el-select>
              <el-button type="primary" @click="applySelectedWaterStats">查询</el-button>
            </div>
          </div>
          
          <div class="water-statistics-cards">
            <div class="water-stat-circle">
              <div class="stat-circle-bg">
                <div class="stat-circle-value">{{ (waterStats.avgWaterLevel || 0).toFixed(2) }}</div>
              </div>
              <div class="stat-circle-label">
                <div>库水位</div>
                <div class="unit-text">(米)</div>
              </div>
            </div>
            <div class="water-stat-circle">
              <div class="stat-circle-bg">
                <div class="stat-circle-value">{{ (waterStats.totalStorage || 0).toFixed(0) }}</div>
              </div>
              <div class="stat-circle-label">
                <div>蓄水量</div>
                <div class="unit-text">(万立方米)</div>
              </div>
            </div>
            <div class="water-stat-circle">
              <div class="stat-circle-bg">
                <div class="stat-circle-value">{{ (waterStats.avgInflow || 0).toFixed(2) }}</div>
              </div>
              <div class="stat-circle-label">
                <div>日均入库流量</div>
                <div class="unit-text">(立方米/秒)</div>
              </div>
            </div>
            <div class="water-stat-circle">
              <div class="stat-circle-bg">
                <div class="stat-circle-value">{{ (waterStats.avgOutflow || 0).toFixed(2) }}</div>
              </div>
              <div class="stat-circle-label">
                <div>日均出库流量</div>
                <div class="unit-text">(立方米/秒)</div>
              </div>
            </div>
            <div class="water-stat-circle">
              <div class="stat-circle-bg">
                <div class="stat-circle-value">{{ (waterStats.totalCapacity || 0).toFixed(0) }}</div>
              </div>
              <div class="stat-circle-label">
                <div>总库容</div>
                <div class="unit-text">(万立方米)</div>
              </div>
            </div>
            <div class="water-stat-circle">
              <div class="stat-circle-bg">
                <div class="stat-circle-value">{{ (waterStats.floodLevel || 0).toFixed(2) }}</div>
              </div>
              <div class="stat-circle-label">
                <div>汛限水位</div>
                <div class="unit-text">(米)</div>
              </div>
            </div>
          </div>
          
          <!-- 提示用户选择表格 -->
          <div v-if="selectedCharts.length === 0" class="chart-selection-tip">
            <el-empty 
              description="请选择要显示的表格" 
              :image-size="120"
            >
              <template #description>
                <div class="tip-content">
                  <p>请在上方选择要显示的表格类型</p>
                  <p>选择完成后，对应的图表将自动显示</p>
                </div>
              </template>
            </el-empty>
          </div>
          
          <div class="chart-container" v-if="selectedCharts.includes('waterLevel')">
            <h3>水位分布</h3>
            <div id="water-level-chart" class="chart"></div>
          </div>
          
          <div class="chart-container" v-if="selectedCharts.includes('waterStorage')">
            <h3>蓄水量变化</h3>
            <div id="water-storage-chart" class="chart"></div>
          </div>
          
          <div class="chart-container" v-if="selectedCharts.includes('waterInflow')">
            <h3>日均入库流量变化</h3>
            <div id="water-inflow-chart" class="chart"></div>
          </div>
          
          <div class="chart-container" v-if="selectedCharts.includes('waterOutflow')">
            <h3>日均出库流量变化</h3>
            <div id="water-outflow-chart" class="chart"></div>
          </div>
        </div>
        
        <!-- 水情对比 -->
        <div v-else-if="activeBox==='waterComparison'" class="water-comparison-panel">
          <div class="panel-header">
            <h2>水情对比</h2>
            <div class="header-actions">
              <el-select v-model="selectedReservoirs" multiple collapse-tags placeholder="选择水库(至少2个)" style="width: 320px; margin-right: 10px;">
                <el-option 
                  v-for="reservoir in reservoirList" 
                  :key="reservoir" 
                  :label="reservoir" 
                  :value="reservoir" 
                />
              </el-select>
              <el-date-picker
                v-model="selectedComparisonDateRange"
                type="daterange"
                range-separator="至"
                start-placeholder="开始日期"
                end-placeholder="结束日期"
                value-format="YYYY-MM-DD"
                :disabled-date="disableUnavailableComparisonDates"
                style="width: 240px; margin-right: 10px;"
              />
              <el-select 
                v-model="selectedComparisonCharts" 
                multiple 
                collapse-tags 
                placeholder="选择显示表格(至少1个)" 
                style="width: 240px; margin-right: 10px;"
              >
                <el-option label="水位对比" value="waterLevel" />
                <el-option label="蓄水量对比" value="storage" />
                <el-option label="入库流量对比" value="avgInflow" />
                <el-option label="出库流量对比" value="avgOutflow" />
              </el-select>
              <el-button type="primary" @click="refreshComparisonData">刷新</el-button>
            </div>
          </div>
          
          <!-- 提示用户选择表格 -->
          <div v-if="selectedComparisonCharts.length === 0" class="chart-selection-tip">
            <el-empty 
              description="请选择要显示的对比表格" 
              :image-size="120"
            >
              <template #description>
                <div class="tip-content">
                  <p>请在上方选择要显示的对比表格类型</p>
                  <p>选择完成后，对应的对比图表将自动显示</p>
                </div>
              </template>
            </el-empty>
          </div>
          
          <div class="chart-container" v-if="selectedComparisonCharts.includes('waterLevel')">
            <h3>水位对比</h3>
            <div id="water-level-comparison-chart" class="chart"></div>
          </div>
          
          <div class="chart-container" v-if="selectedComparisonCharts.includes('storage')">
            <h3>蓄水量对比</h3>
            <div id="water-storage-comparison-chart" class="chart"></div>
          </div>
          
          <div class="chart-container" v-if="selectedComparisonCharts.includes('avgInflow')">
            <h3>入库流量对比</h3>
            <div id="water-inflow-comparison-chart" class="chart"></div>
          </div>
          
          <div class="chart-container" v-if="selectedComparisonCharts.includes('avgOutflow')">
            <h3>出库流量对比</h3>
            <div id="water-outflow-comparison-chart" class="chart"></div>
          </div>
        </div>
        
        <!-- 环境统计 -->
        <div v-else-if="activeBox==='environmentStatistics'" class="environment-statistics-panel">
          <div class="panel-header">
            <h2>环境统计</h2>
            <div class="header-actions">
              <el-select v-model="selectedMonitorPoint" placeholder="选择监测点" style="width: 180px; margin-right: 10px;">
                <el-option 
                  v-for="point in monitorPointList" 
                  :key="point" 
                  :label="point" 
                  :value="point" 
                />
              </el-select>
              <el-date-picker
                v-model="selectedEnvDateRange"
                type="monthrange"
                range-separator="至"
                start-placeholder="开始月份"
                end-placeholder="结束月份"
                value-format="YYYY-MM"
                :disabled-date="disableUnavailableEnvDates"
                style="width: 240px; margin-right: 10px;"
              />
              <el-select 
                v-model="selectedEnvironmentCharts" 
                multiple 
                collapse-tags 
                placeholder="选择显示内容(至少1个)" 
                style="width: 240px; margin-right: 10px;"
              >
                <el-option label="氨氮" value="ammoniaNitrogen" />
                <el-option label="高锰酸盐" value="permanganateIndex" />
                <el-option label="化学需氧量" value="cod" />
                <el-option label="流量" value="flow" />
                <el-option label="水深" value="depth" />
                <el-option label="总氮" value="totalNitrogen" />
                <el-option label="总磷" value="totalPhosphorus" />
              </el-select>
              <el-button type="primary" @click="applySelectedEnvironmentStats">
                查询
              </el-button>
            </div>
          </div>
          
          <div class="environment-statistics-cards">
            <div class="environment-stat-circle">
              <div class="stat-circle-bg">
                <div class="stat-circle-value">{{ formatNumber(envDisplayStats.ammoniaNitrogen, 2) }}</div>
              </div>
              <div class="stat-circle-label">
                <div>氨氮</div>
                <div class="unit-text">(mg/L)</div>
              </div>
            </div>
            <div class="environment-stat-circle">
              <div class="stat-circle-bg">
                <div class="stat-circle-value">{{ formatNumber(envDisplayStats.permanganateIndex, 2) }}</div>
              </div>
              <div class="stat-circle-label">
                <div>高锰酸盐</div>
                <div class="unit-text">(mg/L)</div>
              </div>
            </div>
            <div class="environment-stat-circle">
              <div class="stat-circle-bg">
                <div class="stat-circle-value">{{ formatNumber(envDisplayStats.cod, 2) }}</div>
              </div>
              <div class="stat-circle-label">
                <div>化学需氧量</div>
                <div class="unit-text">(mg/L)</div>
              </div>
            </div>
            <div class="environment-stat-circle">
              <div class="stat-circle-bg">
                <div class="stat-circle-value">{{ formatNumber(envDisplayStats.flow, 2) }}</div>
              </div>
              <div class="stat-circle-label">
                <div>流量</div>
                <div class="unit-text">(m³/s)</div>
              </div>
            </div>
            <div class="environment-stat-circle">
              <div class="stat-circle-bg">
                <div class="stat-circle-value">{{ formatNumber(envDisplayStats.depth, 2) }}</div>
              </div>
              <div class="stat-circle-label">
                <div>水深</div>
                <div class="unit-text">(m)</div>
              </div>
            </div>
            <div class="environment-stat-circle">
              <div class="stat-circle-bg">
                <div class="stat-circle-value">{{ formatNumber(envDisplayStats.totalNitrogen, 2) }}</div>
              </div>
              <div class="stat-circle-label">
                <div>总氮</div>
                <div class="unit-text">(mg/L)</div>
              </div>
            </div>
            <div class="environment-stat-circle">
              <div class="stat-circle-bg">
                <div class="stat-circle-value">{{ formatNumber(envDisplayStats.totalPhosphorus, 2) }}</div>
              </div>
              <div class="stat-circle-label">
                <div>总磷</div>
                <div class="unit-text">(mg/L)</div>
              </div>
            </div>
          </div>
          

          
          <!-- 提示用户选择表格 -->
          <div v-if="selectedEnvironmentCharts.length === 0" class="chart-selection-tip">
            <el-empty 
              description="请选择要显示的指标" 
              :image-size="120"
            >
              <template #description>
                <div class="tip-content">
                  <p>请在上方选择要显示的指标类型</p>
                  <p>选择完成后，对应的指标图表将自动显示</p>
                </div>
              </template>
            </el-empty>
          </div>
          
          <div class="chart-container ammonia-nitrogen-chart" v-if="selectedEnvironmentCharts.includes('ammoniaNitrogen')">
            <h3>氨氮指标分布</h3>
            <div id="ammonia-nitrogen-chart" class="chart"></div>
          </div>
          
          <div class="chart-container permanganate-index-chart" v-if="selectedEnvironmentCharts.includes('permanganateIndex')">
            <h3>高锰酸盐指标分布</h3>
            <div id="permanganate-index-chart" class="chart"></div>
          </div>
          
          <div class="chart-container cod-chart" v-if="selectedEnvironmentCharts.includes('cod')">
            <h3>化学需氧量指标分布</h3>
            <div id="cod-chart" class="chart"></div>
          </div>
          
          <div class="chart-container flow-chart" v-if="selectedEnvironmentCharts.includes('flow')">
            <h3>流量指标分布</h3>
            <div id="flow-chart" class="chart"></div>
          </div>
          
          <div class="chart-container depth-chart" v-if="selectedEnvironmentCharts.includes('depth')">
            <h3>水深指标分布</h3>
            <div id="depth-chart" class="chart"></div>
          </div>
          
          <div class="chart-container total-nitrogen-chart" v-if="selectedEnvironmentCharts.includes('totalNitrogen')">
            <h3>总氮指标分布</h3>
            <div id="total-nitrogen-chart" class="chart"></div>
          </div>
          
          <div class="chart-container total-phosphorus-chart" v-if="selectedEnvironmentCharts.includes('totalPhosphorus')">
            <h3>总磷指标分布</h3>
            <div id="total-phosphorus-chart" class="chart"></div>
          </div>
        </div>
        
        <!-- 环境对比 -->
        <div v-else-if="activeBox==='environmentComparison'" class="environment-comparison-panel">
          <div class="panel-header">
            <h2>环境对比</h2>
            <div class="header-actions">
            <el-select v-model="selectedMonitorPoints" multiple collapse-tags placeholder="选择监测点(至少2个)" style="width: 240px; margin-right: 10px;">
              <el-option 
                v-for="point in monitorPointList" 
                :key="point" 
                :value="point" 
              />
            </el-select>
              <el-date-picker
                v-model="selectedEnvComparisonDateRange"
                type="monthrange"
                range-separator="至"
                start-placeholder="开始月份"
                end-placeholder="结束月份"
                value-format="YYYY-MM"
                :disabled-date="disableUnavailableEnvComparisonDates"
              style="width: 240px; margin-right: 10px;"
              />
              <el-select 
                v-model="selectedEnvironmentComparisonCharts" 
                multiple 
                collapse-tags 
                placeholder="选择显示指标(至少1个)" 
              style="width: 280px; margin-right: 10px;"
              >
                <el-option label="氨氮" value="ammoniaNitrogen" />
                <el-option label="高锰酸盐" value="permanganateIndex" />
                <el-option label="化学需氧量" value="cod" />
                <el-option label="流量" value="flow" />
                <el-option label="水深" value="depth" />
                <el-option label="总氮" value="totalNitrogen" />
                <el-option label="总磷" value="totalPhosphorus" />
              </el-select>
              <el-button type="primary" @click="refreshEnvironmentComparison">
                刷新
              </el-button>
            </div>
          </div>
          

          
          <!-- 提示用户选择表格 -->
          <div v-if="selectedEnvironmentComparisonCharts.length === 0" class="chart-selection-tip">
            <el-empty 
              description="请选择要显示的对比指标" 
              :image-size="120"
            >
              <template #description>
                <div class="tip-content">
                  <p>请在上方选择要显示的对比指标类型</p>
                  <p>选择完成后，对应的对比图表将自动显示</p>
                </div>
              </template>
            </el-empty>
          </div>
          
          <div class="chart-container environment-ammonia-nitrogen-chart" v-if="selectedEnvironmentComparisonCharts.includes('ammoniaNitrogen')">
            <h3>氨氮指标对比分析</h3>
            <div id="environment-ammonia-nitrogen-chart" class="chart"></div>
          </div>
          
          <div class="chart-container environment-permanganate-index-chart" v-if="selectedEnvironmentComparisonCharts.includes('permanganateIndex')">
            <h3>高锰酸盐指标对比分析</h3>
            <div id="environment-permanganate-index-chart" class="chart"></div>
          </div>
          
          <div class="chart-container environment-cod-chart" v-if="selectedEnvironmentComparisonCharts.includes('cod')">
            <h3>化学需氧量指标对比分析</h3>
            <div id="environment-cod-chart" class="chart"></div>
          </div>
          
          <div class="chart-container environment-flow-chart" v-if="selectedEnvironmentComparisonCharts.includes('flow')">
            <h3>流量指标对比分析</h3>
            <div id="environment-flow-chart" class="chart"></div>
          </div>
          
          <div class="chart-container environment-depth-chart" v-if="selectedEnvironmentComparisonCharts.includes('depth')">
            <h3>水深指标对比分析</h3>
            <div id="environment-depth-chart" class="chart"></div>
          </div>
          
          <div class="chart-container environment-total-nitrogen-chart" v-if="selectedEnvironmentComparisonCharts.includes('totalNitrogen')">
            <h3>总氮指标对比分析</h3>
            <div id="environment-total-nitrogen-chart" class="chart"></div>
          </div>
          
          <div class="chart-container environment-total-phosphorus-chart" v-if="selectedEnvironmentComparisonCharts.includes('totalPhosphorus')">
            <h3>总磷指标对比分析</h3>
            <div id="environment-total-phosphorus-chart" class="chart"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive, onMounted, onUnmounted, onBeforeUnmount, watch, nextTick } from 'vue'
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
    const selectedDateRange = ref([])
    const selectedReservoirDates = ref(new Set())
    const selectedReservoirs = ref([])
    const selectedComparisonDateRange = ref([])
    const selectedComparisonReservoirDates = ref(new Set())
    const selectedComparisonCharts = ref([]) // 默认不显示任何对比表格
    const selectedCharts = ref([]) // 默认不显示任何表格
    const selectedEnvironmentCharts = ref([]) // 默认不显示任何环境统计表格
    const selectedEnvironmentComparisonCharts = ref([]) // 默认不显示任何环境对比表格
    const comparisonIndicator = ref('waterLevel')
    const comparisonMonitorPoint1 = ref('')
    const comparisonMonitorPoint2 = ref('')
    const comparisonEnvironmentIndicator = ref('ammoniaNitrogen')
    const selectedMonitorPoints = ref([])
    const selectedMonitorPoint = ref('')
    const selectedEnvMonth = ref(null)
    const selectedEnvDateRange = ref([])
    const selectedEnvComparisonDateRange = ref([])
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
      avgOutflow: 0,
      totalCapacity: 0,    // 总库容（万立方米）
      floodLevel: 0        // 汛限水位（米）
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
    let waterStorageChart = null
    let waterInflowChart = null
    let waterOutflowChart = null
    let waterComparisonChart = null
    let waterLevelComparisonChart = null
    let waterStorageComparisonChart = null
    let waterInflowComparisonChart = null
    let waterOutflowComparisonChart = null
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
    
    // 禁用水情对比没有数据的日期
    const disableUnavailableComparisonDates = (date) => {
      if (!(selectedComparisonReservoirDates.value instanceof Set)) return false
      if (selectedComparisonReservoirDates.value.size === 0) return false
      const str = formatDate(date)
      return !selectedComparisonReservoirDates.value.has(str)
    }

    // 禁用环境统计没有数据的月份
    const disableUnavailableEnvDates = (date) => {
      if (!(selectedMonitorPointMonths.value instanceof Set)) return false
      if (selectedMonitorPointMonths.value.size === 0) return false
      const str = formatYearMonth(date)
      return !selectedMonitorPointMonths.value.has(str)
    }

    // 禁用环境对比没有数据的月份
    const disableUnavailableEnvComparisonDates = (date) => {
      if (!(selectedMonitorPointMonths.value instanceof Set)) return false
      if (selectedMonitorPointMonths.value.size === 0) return false
      const str = formatYearMonth(date)
      return !selectedMonitorPointMonths.value.has(str)
    }
    
    // 根据选择更新统计卡片
    const updateSelectedWaterStats = async () => {
      if (!selectedReservoir.value || !selectedDateRange.value || selectedDateRange.value.length !== 2) {
        waterStats.avgWaterLevel = 0
        waterStats.totalStorage = 0
        waterStats.avgInflow = 0
        waterStats.avgOutflow = 0
        return
      }
      
      try {
        // 从水情管理页面获取数据
        const waterResponse = await axios.get('/api/waterSituation/list', {
          params: { page: 1, pageSize: 99999 }
        })
        
        const waterData = waterResponse.data.list || []
        const [startDate, endDate] = selectedDateRange.value
        
        // 查找指定水库和日期范围内的数据
        const selectedData = waterData.filter(item => {
          if (item.reservoirName !== selectedReservoir.value) return false
          
          // 标准化日期格式进行比较
          const itemDateStr = normalizeToDayString(item.date)
          const startDateStr = normalizeToDayString(startDate)
          const endDateStr = normalizeToDayString(endDate)
          
          return itemDateStr >= startDateStr && itemDateStr <= endDateStr
        })
        
        if (selectedData.length > 0) {
          // 计算平均值
          const levels = selectedData.map(item => Number(item.waterLevel) || 0).filter(level => level > 0)
          const storages = selectedData.map(item => Number(item.storage) || 0).filter(storage => storage > 0)
          const inflows = selectedData.map(item => Number(item.avgInflow) || 0).filter(inflow => inflow > 0)
          const outflows = selectedData.map(item => Number(item.avgOutflow) || 0).filter(outflow => outflow > 0)
          
          waterStats.avgWaterLevel = levels.length > 0 ? levels.reduce((a, b) => a + b, 0) / levels.length : 0
          waterStats.totalStorage = storages.length > 0 ? Math.max(...storages) : 0
          waterStats.avgInflow = inflows.length > 0 ? inflows.reduce((a, b) => a + b, 0) / inflows.length : 0
          waterStats.avgOutflow = outflows.length > 0 ? outflows.reduce((a, b) => a + b, 0) / outflows.length : 0
          
          // 获取总库容和汛限水位（从水情数据中获取）
          const capacityData = selectedData.map(item => Number(item.totalCapacity) || 0)
          const floodLevelData = selectedData.map(item => Number(item.floodLevel) || 0)
          
          // 使用最大值作为显示值（因为总库容和汛限水位通常是固定值）
          // 注意：不过滤掉 0 值，因为这些可能是有效的数据
          waterStats.totalCapacity = capacityData.length > 0 ? Math.max(...capacityData) : 0
          waterStats.floodLevel = floodLevelData.length > 0 ? Math.max(...floodLevelData) : 0
          
          console.log('总库容和汛限水位数据获取结果:', {
            selectedDataLength: selectedData.length,
            capacityData: capacityData,
            floodLevelData: floodLevelData,
            totalCapacity: waterStats.totalCapacity,
            floodLevel: waterStats.floodLevel,
            sampleData: selectedData.slice(0, 3).map(item => ({
              reservoirName: item.reservoirName,
              totalCapacity: item.totalCapacity,
              floodLevel: item.floodLevel,
              rawTotalCapacity: item.totalCapacity,
              rawFloodLevel: item.floodLevel
            })),
            allCapacityValues: capacityData,
            allFloodLevelValues: floodLevelData
          })
          
          // 使用统一的图表渲染函数
          await renderSelectedCharts()
        } else {
          waterStats.avgWaterLevel = 0
          waterStats.totalStorage = 0
          waterStats.avgInflow = 0
          waterStats.avgOutflow = 0
          waterStats.totalCapacity = 0
          waterStats.floodLevel = 0
          
          // 使用统一的图表渲染函数
          await renderSelectedCharts()
        }
        
        console.log('更新水情统计数据:', {
          selectedReservoir: selectedReservoir.value,
          selectedDateRange: selectedDateRange.value,
          foundData: selectedData.length,
          stats: waterStats
        })
        
      } catch (error) {
        console.error('获取月度统计数据失败:', error)
        waterStats.avgWaterLevel = 0
        waterStats.totalStorage = 0
        waterStats.avgInflow = 0
        waterStats.avgOutflow = 0
        waterStats.totalCapacity = 0
        waterStats.floodLevel = 0
      }
    }
    
    // 手动触发选中条件的统计刷新
    const applySelectedWaterStats = async () => {
      console.log('手动触发查询:', {
        reservoir: selectedReservoir.value,
        dateRange: selectedDateRange.value,
        selectedCharts: selectedCharts.value
      })
      
      // 先更新统计数据
      await updateSelectedWaterStats()
      
      // 然后重新渲染选择的图表
      await renderSelectedCharts()
    }
    
    // 清理被删除的图表实例
    const cleanupRemovedCharts = (oldCharts, newCharts) => {
      console.log('清理被删除的图表实例:', { old: oldCharts, new: newCharts })
      
      // 找出被删除的图表
      const removedCharts = oldCharts.filter(chart => !newCharts.includes(chart))
      console.log('被删除的图表:', removedCharts)
      
      // 清理被删除的图表实例
      removedCharts.forEach(chartType => {
        switch (chartType) {
          case 'waterLevel':
            if (waterLevelChart) {
              try {
                waterLevelChart.dispose()
                waterLevelChart = null
                console.log('已清理水位图表实例')
              } catch (error) {
                console.warn('清理水位图表时出错:', error)
              }
            }
            break
          case 'waterStorage':
            if (waterStorageChart) {
              try {
                waterStorageChart.dispose()
                waterStorageChart = null
                console.log('已清理蓄水量图表实例')
              } catch (error) {
                console.warn('清理蓄水量图表时出错:', error)
              }
            }
            break
          case 'waterInflow':
            if (waterInflowChart) {
              try {
                waterInflowChart.dispose()
                waterInflowChart = null
                console.log('已清理入库流量图表实例')
              } catch (error) {
                console.warn('清理入库流量图表时出错:', error)
              }
            }
            break
          case 'waterOutflow':
            if (waterOutflowChart) {
              try {
                waterOutflowChart.dispose()
                waterOutflowChart = null
                console.log('已清理出库流量图表实例')
              } catch (error) {
                console.warn('清理出库流量图表时出错:', error)
              }
            }
            break
        }
      })
    }
    
    // 渲染选择的图表
    const renderSelectedCharts = async () => {
      console.log('开始渲染选择的图表:', {
        selectedCharts: selectedCharts.value,
        selectedReservoir: selectedReservoir.value,
        selectedDateRange: selectedDateRange.value,
        totalDataCount: waterDataList.value.length
      })
      
      // 根据选择的水库和日期范围过滤数据
      let filteredData = waterDataList.value
      
      if (selectedReservoir.value) {
        filteredData = filteredData.filter(item => item.reservoirName === selectedReservoir.value)
        console.log('按水库过滤后数据:', filteredData.length, '条')
      }
      
      if (selectedDateRange.value && selectedDateRange.value.length === 2) {
        const [startDate, endDate] = selectedDateRange.value
        filteredData = filteredData.filter(item => {
          const itemDateStr = normalizeToDayString(item.date)
          const startDateStr = normalizeToDayString(startDate)
          const endDateStr = normalizeToDayString(endDate)
          return itemDateStr >= startDateStr && itemDateStr <= endDateStr
        })
        console.log('按日期范围过滤后数据:', filteredData.length, '条')
      }
      
      console.log('最终过滤后的数据:', {
        count: filteredData.length,
        sampleData: filteredData.slice(0, 3).map(item => ({
          reservoir: item.reservoirName,
          date: item.date,
          waterLevel: item.waterLevel,
          storage: item.storage,
          avgInflow: item.avgInflow,
          avgOutflow: item.avgOutflow
        }))
      })
      
      // 等待DOM更新完成
      await nextTick()
      
      // 根据选择渲染对应的图表，使用过滤后的数据
      if (selectedCharts.value.includes('waterLevel')) {
        console.log('渲染水位分布图表，数据条数:', filteredData.length)
        renderWaterLevelChart(filteredData)
      }
      if (selectedCharts.value.includes('waterStorage')) {
        console.log('渲染蓄水量变化图表，数据条数:', filteredData.length)
        renderWaterStorageChart(filteredData)
      }
      if (selectedCharts.value.includes('waterInflow')) {
        console.log('渲染入库流量图表，数据条数:', filteredData.length)
        renderWaterInflowChart(filteredData)
      }
      if (selectedCharts.value.includes('waterOutflow')) {
        console.log('渲染出库流量图表，数据条数:', filteredData.length)
        renderWaterOutflowChart(filteredData)
      }
    }
    
    // 当选择的水库变化时，刷新可选日期集合并默认选择最近日期
    const refreshSelectedReservoirDates = async () => {
      if (!selectedReservoir.value) {
        selectedReservoirDates.value = new Set()
        return
      }
      
      try {
        // 重新获取该水库的数据以确保日期列表是最新的
        const waterResponse = await axios.get('/api/waterSituation/list', {
          params: { page: 1, pageSize: 99999 }
        })
        
        const waterData = waterResponse.data.list || []
        const reservoirData = waterData.filter(item => item.reservoirName === selectedReservoir.value)
        
        const dates = reservoirData
          .map(item => normalizeToDayString(item.date))
          .filter(Boolean)
        
        const set = new Set(dates)
        selectedReservoirDates.value = set
        
        console.log('刷新水库可选日期:', {
          reservoir: selectedReservoir.value,
          availableDates: Array.from(set),
          currentSelectedDate: selectedDate.value
        })
        
        // 如果当前选中的日期范围不在集合中，则选择最近的时间段
        if (!selectedDateRange.value || selectedDateRange.value.length !== 2) {
          const sorted = Array.from(set).sort()
          if (sorted.length >= 2) {
            // 选择最近的两个日期作为默认范围
            selectedDateRange.value = [sorted[sorted.length - 2], sorted[sorted.length - 1]]
          } else if (sorted.length === 1) {
            // 如果只有一个日期，使用同一天作为开始和结束
            selectedDateRange.value = [sorted[0], sorted[0]]
          } else {
            selectedDateRange.value = []
          }
        }
        
        // 无论日期是否变化，切换水库后都要更新统计数据
        await updateSelectedWaterStats()
      } catch (error) {
        console.error('刷新水库可选日期失败:', error)
        selectedReservoirDates.value = new Set()
      }
    }
    
    // 当选择的水库变化时，刷新水情对比可选日期集合并默认选择最近日期
    const refreshSelectedComparisonReservoirDates = async () => {
      if (!selectedReservoirs.value || selectedReservoirs.value.length === 0) {
        selectedComparisonReservoirDates.value = new Set()
        return
      }
      
      try {
        // 重新获取所有水情数据以确保日期列表是最新的
        const waterResponse = await axios.get('/api/waterSituation/list', {
          params: { page: 1, pageSize: 99999 }
        })
        
        const waterData = waterResponse.data.list || []
        
        // 收集所有选中水库的日期
        const allDates = new Set()
        selectedReservoirs.value.forEach(reservoirName => {
          const reservoirData = waterData.filter(item => item.reservoirName === reservoirName)
          const dates = reservoirData
            .map(item => normalizeToDayString(item.date))
            .filter(Boolean)
          dates.forEach(date => allDates.add(date))
        })
        
        selectedComparisonReservoirDates.value = allDates
        
        console.log('刷新水情对比可选日期:', {
          reservoirs: selectedReservoirs.value,
          availableDates: Array.from(allDates),
          currentSelectedDateRange: selectedComparisonDateRange.value
        })
        
        // 如果当前选中的日期范围不在集合中，则选择最近的时间段
        if (!selectedComparisonDateRange.value || selectedComparisonDateRange.value.length !== 2) {
          const sorted = Array.from(allDates).sort()
          if (sorted.length >= 2) {
            // 选择最近的两个日期作为默认范围
            selectedComparisonDateRange.value = [sorted[sorted.length - 2], sorted[sorted.length - 1]]
          } else if (sorted.length === 1) {
            // 如果只有一个日期，使用同一天作为开始和结束
            selectedComparisonDateRange.value = [sorted[0], sorted[0]]
          } else {
            selectedComparisonDateRange.value = []
          }
        }
      } catch (error) {
        console.error('刷新水情对比可选日期失败:', error)
        selectedComparisonReservoirDates.value = new Set()
      }
    }
    
    // 获取水情统计数据
    const fetchWaterStatistics = async () => {
      try {
        console.log('开始获取水情统计数据...')
        
        const waterResponse = await axios.get('/api/waterSituation/list', {
          params: {
            pageSize: 99999
          }
        })
        
        if (waterResponse.data && waterResponse.data.list) {
          // 确保数据完整性，特别是数值字段
          const processedData = waterResponse.data.list.map(item => ({
            ...item,
            avgInflow: item.avgInflow !== null && item.avgInflow !== undefined ? Number(item.avgInflow) : null,
            avgOutflow: item.avgOutflow !== null && item.avgOutflow !== undefined ? Number(item.avgOutflow) : null,
            waterLevel: item.waterLevel !== null && item.waterLevel !== undefined ? Number(item.waterLevel) : null,
            storage: item.storage !== null && item.storage !== undefined ? Number(item.storage) : null,
            yoyIncrease: item.yoyIncrease !== null && item.yoyIncrease !== undefined ? Number(item.yoyIncrease) : null,
            totalCapacity: item.totalCapacity !== null && item.totalCapacity !== undefined ? Number(item.totalCapacity) : null,
            floodLevel: item.floodLevel !== null && item.floodLevel !== undefined ? Number(item.floodLevel) : null
          }))
          
          waterDataList.value = processedData
          console.log('获取到水情数据:', waterDataList.value.length, '条')
          console.log('数据完整性检查:', {
            avgInflowValid: processedData.every(item => item.avgInflow !== null && !isNaN(item.avgInflow)),
            avgOutflowValid: processedData.every(item => item.avgOutflow !== null && !isNaN(item.avgOutflow)),
            totalCapacityValid: processedData.every(item => item.totalCapacity !== null && !isNaN(item.totalCapacity)),
            floodLevelValid: processedData.every(item => item.floodLevel !== null && !isNaN(item.floodLevel))
          })
          
          // 检查总库容和汛限水位数据
          const sampleData = processedData.slice(0, 3)
          console.log('总库容和汛限水位数据样本:', sampleData.map(item => ({
            reservoirName: item.reservoirName,
            totalCapacity: item.totalCapacity,
            floodLevel: item.floodLevel,
            date: item.date
          })))
          
          // 提取水库列表
          const reservoirs = [...new Set(waterDataList.value.map(item => item.reservoirName))]
          reservoirList.value = reservoirs
          console.log('提取到水库列表:', reservoirs.length, '个')
          
          // 初始化选择的水库和日期范围
          if (reservoirs.length > 0 && !selectedReservoir.value) {
            selectedReservoir.value = reservoirs[0]
            console.log('自动选择第一个水库:', selectedReservoir.value)
          }
          
          // 初始化日期范围
          if (waterDataList.value.length > 0 && (!selectedDateRange.value || selectedDateRange.value.length === 0)) {
            const dates = [...new Set(waterDataList.value.map(item => item.date))].sort()
            if (dates.length >= 2) {
              selectedDateRange.value = [dates[0], dates[dates.length - 1]]
              console.log('自动设置日期范围:', selectedDateRange.value)
            }
          }
          
          // 更新统计数据
          updateSelectedWaterStats()
          
          // 不自动渲染图表，等待用户选择表格
          console.log('水情数据获取完成，等待用户选择要显示的表格...')
        }
      } catch (error) {
        console.error('获取水情统计数据失败:', error)
        ElMessage.error('获取水情统计数据失败，请检查后端服务是否正常')
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
    const updateSelectedEnvironmentStats = async () => {
      console.log('开始更新环境统计数据:', {
        selectedMonitorPoint: selectedMonitorPoint.value,
        selectedEnvDateRange: selectedEnvDateRange.value,
        environmentDataListLength: environmentDataList.value.length
      })
      
      if (!selectedMonitorPoint.value || !selectedEnvDateRange.value || selectedEnvDateRange.value.length !== 2) {
        console.warn('环境统计数据更新失败：缺少必要的选择参数')
        envDisplayStats.ammoniaNitrogen = 0
        envDisplayStats.permanganateIndex = 0
        envDisplayStats.cod = 0
        envDisplayStats.flow = 0
        envDisplayStats.depth = 0
        envDisplayStats.totalNitrogen = 0
        envDisplayStats.totalPhosphorus = 0
        return
      }
      
      try {
        // 从监测断面管理页面获取环境数据
        const envResponse = await axios.get('/api/sectionMonitor/list', {
          params: { page: 1, pageSize: 10000 }
        })
        
        const envData = envResponse.data.list || []
        const [startMonth, endMonth] = selectedEnvDateRange.value
        
        // 过滤指定月份范围内的数据
        const dateRangeData = envData.filter(item => {
          const itemMonth = `${item.year}-${String(item.month).padStart(2, '0')}`
          return item.monitorPointName === selectedMonitorPoint.value &&
                 itemMonth >= startMonth &&
                 itemMonth <= endMonth
        })
        
        console.log('环境统计数据过滤结果:', {
          totalData: envData.length,
          selectedMonitorPoint: selectedMonitorPoint.value,
          dateRange: [startMonth, endMonth],
          filteredData: dateRangeData.length,
          sampleData: dateRangeData.slice(0, 3)
        })
        
        if (dateRangeData.length > 0) {
          // 计算日期范围内的平均值
          const sum = dateRangeData.reduce((acc, item) => {
            acc.ammoniaNitrogen += Number(item.oxygen) || 0
            acc.permanganateIndex += Number(item.potassiumPermanganate) || 0
            acc.cod += Number(item.cod) || 0
            acc.flow += Number(item.flow) || 0
            acc.depth += Number(item.waterDepth) || 0
            acc.totalNitrogen += Number(item.totalNitrogen) || 0
            acc.totalPhosphorus += Number(item.totalPhosphorus) || 0
            return acc
          }, {
            ammoniaNitrogen: 0,
            permanganateIndex: 0,
            cod: 0,
            flow: 0,
            depth: 0,
            totalNitrogen: 0,
            totalPhosphorus: 0
          })
          
          const count = dateRangeData.length
          envDisplayStats.ammoniaNitrogen = sum.ammoniaNitrogen / count
          envDisplayStats.permanganateIndex = sum.permanganateIndex / count
          envDisplayStats.cod = sum.cod / count
          envDisplayStats.flow = sum.flow / count
          envDisplayStats.depth = sum.depth / count
          envDisplayStats.totalNitrogen = sum.totalNitrogen / count
          envDisplayStats.totalPhosphorus = sum.totalPhosphorus / count
        } else {
          envDisplayStats.ammoniaNitrogen = 0
          envDisplayStats.permanganateIndex = 0
          envDisplayStats.cod = 0
          envDisplayStats.flow = 0
          envDisplayStats.depth = 0
          envDisplayStats.totalNitrogen = 0
          envDisplayStats.totalPhosphorus = 0
        }
      } catch (error) {
        console.error('获取环境统计数据失败:', error)
        envDisplayStats.ammoniaNitrogen = 0
        envDisplayStats.permanganateIndex = 0
        envDisplayStats.cod = 0
        envDisplayStats.flow = 0
        envDisplayStats.depth = 0
        envDisplayStats.totalNitrogen = 0
        envDisplayStats.totalPhosphorus = 0
      }
    }

    // 更新环境对比统计数据
    const updateSelectedEnvironmentComparisonStats = async () => {
      if (!selectedMonitorPoints.value || selectedMonitorPoints.value.length < 2 || 
          !selectedEnvComparisonDateRange.value || selectedEnvComparisonDateRange.value.length !== 2) {
        return
      }
      
      try {
        // 从监测断面管理页面获取环境数据
        const envResponse = await axios.get('/api/sectionMonitor/list', {
          params: { page: 1, pageSize: 10000 }
        })
        
        const envData = envResponse.data.list || []
        const [startMonth, endMonth] = selectedEnvComparisonDateRange.value
        
        // 过滤指定月份范围内的数据
        const dateRangeData = envData.filter(item => {
          const itemMonth = `${item.year}-${String(item.month).padStart(2, '0')}`
          return selectedMonitorPoints.value.includes(item.monitorPointName) &&
                 itemMonth >= startMonth &&
                 itemMonth <= endMonth
        })
        
        console.log('环境对比数据过滤结果:', {
          selectedPoints: selectedMonitorPoints.value,
          dateRange: selectedEnvComparisonDateRange.value,
          filteredDataCount: dateRangeData.length
        })
        
      } catch (error) {
        console.error('获取环境对比统计数据失败:', error)
      }
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
      
      // 设置默认月份范围 - 使用数据中的第一条记录作为开始月份
      if (!selectedEnvDateRange.value || selectedEnvDateRange.value.length !== 2) {
        if (months.length > 0) {
          // 使用该监测点的第一条数据作为开始月份
          const sortedMonths = Array.from(months).sort()
          const firstMonth = sortedMonths[0]
          
          // 设置默认月份范围：从第一条数据到当前月份
          const today = new Date()
          const currentMonth = formatYearMonth(today)
          
          selectedEnvDateRange.value = [firstMonth, currentMonth]
          console.log('使用监测点数据中的第一条记录设置月份范围:', selectedEnvDateRange.value)
        } else {
          // 如果没有数据，使用默认的3个月范围
        const today = new Date()
        const threeMonthsAgo = new Date(today.getFullYear(), today.getMonth() - 2, 1)
        selectedEnvDateRange.value = [
          formatYearMonth(threeMonthsAgo),
          formatYearMonth(today)
        ]
        }
      }
    }
    const applySelectedEnvironmentStats = async () => {
      console.log('手动点击查询按钮，强制刷新环境统计数据和图表...')
      
      try {
        // 强制重新获取环境数据
        await fetchEnvironmentStatistics()
        
        // 更新统计数据
        await updateSelectedEnvironmentStats()
        
        // 如果有选择的图表，则重新渲染
        if (selectedEnvironmentCharts.value.length > 0) {
          console.log('强制重新渲染选择的环境统计图表...')
          await renderSelectedEnvironmentCharts()
        }
        
        ElMessage.success('环境统计数据已刷新')
      } catch (error) {
        console.error('刷新环境统计数据失败:', error)
        ElMessage.error('刷新环境统计数据失败，请重试')
      }
    }
    const formatNumber = (val, digits = 2) => {
      const num = Number(val)
      if (isNaN(num)) return '0.00'
      return num.toFixed(digits)
    }

    // 获取环境统计数据
    const fetchEnvironmentStatistics = async () => {
      try {
        // 检查环境面板是否已激活
        if (activeBox.value !== 'environmentStatistics' && activeBox.value !== 'environmentComparison') {
          console.log('环境面板未激活，跳过数据获取')
          return
        }
        
        console.log('开始获取环境统计数据...')
        
        const envResponse = await axios.get('/api/sectionMonitor/list', {
          params: {
            pageSize: 99999
          }
        })
        
        if (envResponse.data && envResponse.data.list) {
          environmentDataList.value = envResponse.data.list
          console.log('获取到环境数据:', environmentDataList.value.length, '条')
          
          // 提取监测点列表
          const monitorPoints = [...new Set(environmentDataList.value.map(item => item.monitorPointName))]
          monitorPointList.value = monitorPoints
          console.log('提取到监测点列表:', monitorPoints.length, '个')
          
          // 初始化选择的监测点
          if (monitorPoints.length > 0 && !selectedMonitorPoint.value) {
            selectedMonitorPoint.value = monitorPoints[0]
            console.log('自动选择第一个监测点:', selectedMonitorPoint.value)
          }
          
          // 设置默认月份范围 - 使用数据中的第一条记录作为开始月份
          if (!selectedEnvDateRange.value || selectedEnvDateRange.value.length !== 2) {
            if (environmentDataList.value.length > 0) {
              // 找到第一条数据的年月
              const firstData = environmentDataList.value[0]
              const firstMonth = `${firstData.year}-${String(firstData.month).padStart(2, '0')}`
              
              // 设置默认月份范围：从第一条数据到当前月份
              const today = new Date()
              const currentMonth = formatYearMonth(today)
              
              selectedEnvDateRange.value = [firstMonth, currentMonth]
              console.log('使用数据中的第一条记录设置月份范围:', selectedEnvDateRange.value)
            } else {
              // 如果没有数据，使用默认的3个月范围
            const today = new Date()
            const threeMonthsAgo = new Date(today.getFullYear(), today.getMonth() - 2, 1)
            selectedEnvDateRange.value = [
              formatYearMonth(threeMonthsAgo),
              formatYearMonth(today)
            ]
            console.log('设置默认月份范围:', selectedEnvDateRange.value)
            }
          }
          
          // 更新环境统计数据
          await updateSelectedEnvironmentStats()
          
          // 渲染环境对比图表
          renderEnvironmentComparisonChart()
        }
      } catch (error) {
        console.error('获取环境统计数据失败:', error)
        ElMessage.error('获取环境统计数据失败，请检查后端服务是否正常')
      }
    }
    
    // 渲染水位分布图表
    const renderWaterLevelChart = (data) => {
      // 检查DOM元素是否存在
      const container = document.getElementById('water-level-chart')
      if (!container) {
        console.warn('水位分布图表容器不存在，跳过图表初始化')
        return
      }
      
      // 检查容器是否仍然在DOM中
      if (!document.contains(container)) {
        console.warn('水位分布图表容器已从DOM中移除，跳过图表初始化')
        return
      }
      
      try {
        // 检查图表实例是否仍然有效，无效需要重新创建
        if (!waterLevelChart || !waterLevelChart.getDom || !waterLevelChart.getDom() || !document.contains(waterLevelChart.getDom())) {
          if (waterLevelChart) {
            try {
              waterLevelChart.dispose()
            } catch (error) {
              console.warn('清理旧的水位图表实例时出错:', error)
            }
          }
          waterLevelChart = echarts.init(container)
          console.log('重新初始化水位图表实例')
        }
        
        if (!data || data.length === 0) {
          // 显示无数据提示
          waterLevelChart.setOption({
            title: {
              text: getWaterLevelChartTitle(),
              left: 'center'
            },
            xAxis: {
              type: 'category',
              data: [],
              axisLabel: {
                rotate: 45,
                interval: 0
              }
            },
            yAxis: {
              type: 'value',
              name: '库水位'
            },
            series: [{
              name: '水位',
              type: 'line',
              data: [],
              smooth: true
            }],
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
        
        // 按日期排序
        const sortedData = data.sort((a, b) => new Date(a.date) - new Date(b.date))
        
        // 准备图表数据
        const dates = sortedData.map(item => {
          const date = new Date(item.date)
          return `${date.getMonth() + 1}/${date.getDate()}`
        })
        const waterLevelValues = sortedData.map(item => Number(item.waterLevel) || 0)
        
        const option = {
          title: {
            text: getWaterLevelChartTitle(),
            left: 'center'
          },
          tooltip: {
            trigger: 'axis',
            formatter: function(params) {
              const dataIndex = params[0].dataIndex
              const originalDate = sortedData[dataIndex].date
              return `${originalDate}<br/>水位: ${params[0].value} 米`
            }
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
            name: '库水位'
          },
          series: [{
            name: '水位',
            type: 'line',
            data: waterLevelValues,
            smooth: true,
            lineStyle: {
              color: '#409EFF',
              width: 3
            },
            itemStyle: {
              color: '#409EFF'
            },
            areaStyle: {
              color: {
                type: 'linear',
                x: 0, y: 0, x2: 0, y2: 1,
                colorStops: [
                  { offset: 0, color: 'rgba(64, 158, 255, 0.3)' },
                  { offset: 1, color: 'rgba(64, 158, 255, 0.1)' }
                ]
              }
            }
          }]
        }
        
        waterLevelChart.setOption(option, true) // 第二个参数true表示完全替换配置
      } catch (error) {
        console.error('初始化水位分布图表时出错:', error)
        // 清理图表实例
        if (waterLevelChart) {
          try {
            waterLevelChart.dispose()
          } catch (disposeError) {
            console.warn('清理水位图表时出错:', disposeError)
          }
          waterLevelChart = null
        }
      }
    }
    
    // 更新水位分布图表
    const updateWaterLevelChart = (data) => {
      // 检查DOM元素是否存在
      const container = document.getElementById('water-level-chart')
      if (!container) {
        console.warn('水位分布图表容器不存在，跳过图表更新')
        return
      }
      
      // 检查容器是否仍然在DOM中
      if (!document.contains(container)) {
        console.warn('水位分布图表容器已从DOM中移除，跳过图表更新')
        return
      }
      
      try {
        // 检查图表实例是否仍然有效，如果无效则重新创建
        if (!waterLevelChart || !waterLevelChart.getDom || !waterLevelChart.getDom() || !document.contains(waterLevelChart.getDom())) {
          if (waterLevelChart) {
            try {
              waterLevelChart.dispose()
            } catch (error) {
              console.warn('清理旧的水位图表实例时出错:', error)
            }
          }
          waterLevelChart = echarts.init(container)
          console.log('重新初始化水位图表实例')
        }
        
        if (!data || data.length === 0) {
          // 清空图表
          const emptyOption = {
            title: { 
              text: getWaterLevelChartTitle(),
              left: 'center'
            },
            xAxis: {
              type: 'category',
              data: [],
              axisLabel: {
                rotate: 45,
                interval: 0
              }
            },
            yAxis: {
              type: 'value',
              name: '库水位'
            },
            series: [{ 
              name: '水位',
              type: 'line',
              data: [],
              smooth: true
            }]
          }
          waterLevelChart.setOption(emptyOption, true) // 第二个参数true表示完全替换配置
          return
        }
        
        // 按日期排序
        const sortedData = data.sort((a, b) => new Date(a.date) - new Date(b.date))
        
        // 准备图表数据
        const dates = sortedData.map(item => {
          const date = new Date(item.date)
          return `${date.getMonth() + 1}/${date.getDate()}`
        })
        const waterLevels = sortedData.map(item => Number(item.waterLevel) || 0)
        
        const option = {
          title: {
            text: getWaterLevelChartTitle(),
            left: 'center'
          },
          tooltip: {
            trigger: 'axis',
            formatter: function(params) {
              const dataIndex = params[0].dataIndex
              const originalDate = sortedData[dataIndex].date
              return `${originalDate}<br/>水位: ${params[0].value} 米`
            }
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
            name: '库水位'
          },
          series: [{
            name: '水位',
            type: 'line',
            data: waterLevels,
            smooth: true,
            lineStyle: {
              color: '#409EFF',
              width: 3
            },
            itemStyle: {
              color: '#409EFF'
            },
            areaStyle: {
              color: {
                type: 'linear',
                x: 0, y: 0, x2: 0, y2: 1,
                colorStops: [
                  { offset: 0, color: 'rgba(64, 158, 255, 0.3)' },
                  { offset: 1, color: 'rgba(64, 158, 255, 0.1)' }
                ]
              }
            }
          }]
        }
        
        waterLevelChart.setOption(option, true) // 第二个参数true表示完全替换配置
      } catch (error) {
        console.error('更新水位分布图表时出错:', error)
        // 清理图表实例
        if (waterLevelChart) {
          try {
            waterLevelChart.dispose()
          } catch (disposeError) {
            console.warn('清理水位图表时出错:', disposeError)
          }
          waterLevelChart = null
        }
      }
    }
    
    // 生成水位分布图表的标题
    const getWaterLevelChartTitle = () => {
      console.log('生成标题 - 当前状态:', {
        selectedReservoir: selectedReservoir.value,
        selectedDateRange: selectedDateRange.value,
        reservoirListLength: reservoirList.value.length
      })
      
      if (!selectedReservoir.value) {
        console.log('标题: 水库水位分布')
        return '水库水位分布'
      }
      
      if (!selectedDateRange.value || selectedDateRange.value.length !== 2) {
        console.log('标题:', `${selectedReservoir.value}水位分布`)
        return `${selectedReservoir.value}水位分布`
      }
      
      const [startDate, endDate] = selectedDateRange.value
      if (!startDate || !endDate) {
        console.log('标题:', `${selectedReservoir.value}水位分布`)
        return `${selectedReservoir.value}水位分布`
      }
      
      // 格式化日期显示
      const formatDate = (dateStr) => {
        if (!dateStr) return ''
        const date = new Date(dateStr)
        if (isNaN(date.getTime())) return dateStr
        return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
      }
      
      const formattedStartDate = formatDate(startDate)
      const formattedEndDate = formatDate(endDate)
      
      const title = `${selectedReservoir.value}水位分布（${formattedStartDate} 至 ${formattedEndDate}）`
      console.log('标题:', title)
      return title
    }
    
    // 生成蓄水量变化图表的标题
    const getWaterStorageChartTitle = () => {
      if (!selectedReservoir.value) {
        return '水库蓄水量变化'
      }
      
      if (!selectedDateRange.value || selectedDateRange.value.length !== 2) {
        return `${selectedReservoir.value}蓄水量变化`
      }
      
      const [startDate, endDate] = selectedDateRange.value
      if (!startDate || !endDate) {
        return `${selectedReservoir.value}蓄水量变化`
      }
      
      // 格式化日期显示
      const formatDate = (dateStr) => {
        if (!dateStr) return ''
        const date = new Date(dateStr)
        if (isNaN(date.getTime())) return dateStr
        return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
      }
      
      const formattedStartDate = formatDate(startDate)
      const formattedEndDate = formatDate(endDate)
      
      const title = `${selectedReservoir.value}蓄水量变化（${formattedStartDate} 至 ${formattedEndDate}）`
      return title
    }
    
    // 生成日均入库流量变化图表的标题
    const getWaterInflowChartTitle = () => {
      if (!selectedReservoir.value) {
        return '日均入库流量变化'
      }
      
      if (!selectedDateRange.value || selectedDateRange.value.length !== 2) {
        return `${selectedReservoir.value}日均入库流量变化`
      }
      
      const [startDate, endDate] = selectedDateRange.value
      if (!startDate || !endDate) {
        return `${selectedReservoir.value}日均入库流量变化`
      }
      
      // 格式化日期显示
      const formatDate = (dateStr) => {
        if (!dateStr) return ''
        const date = new Date(dateStr)
        if (isNaN(date.getTime())) return dateStr
        return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
      }
      
      const formattedStartDate = formatDate(startDate)
      const formattedEndDate = formatDate(endDate)
      
      const title = `${selectedReservoir.value}日均入库流量变化（${formattedStartDate} 至 ${formattedEndDate}）`
      return title
    }
    
    // 生成日均出库流量变化图表的标题
    const getWaterOutflowChartTitle = () => {
      if (!selectedReservoir.value) {
        return '日均出库流量变化'
      }
      
      if (!selectedDateRange.value || selectedDateRange.value.length !== 2) {
        return `${selectedReservoir.value}日均出库流量变化`
      }
      
      const [startDate, endDate] = selectedDateRange.value
      if (!startDate || !endDate) {
        return `${selectedReservoir.value}日均出库流量变化`
      }
      
      // 格式化日期显示
      const formatDate = (dateStr) => {
        if (!dateStr) return ''
        const date = new Date(dateStr)
        if (isNaN(date.getTime())) return dateStr
        return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
      }
      
      const formattedStartDate = formatDate(startDate)
      const formattedEndDate = formatDate(endDate)
      
      const title = `${selectedReservoir.value}日均出库流量变化（${formattedStartDate} 至 ${formattedEndDate}）`
      return title
    }
    
    // 渲染水质指标图表
    const renderWaterQualityChart = (data) => {
      // 检查DOM元素是否存在
      const container = document.getElementById('water-quality-chart')
      if (!container) {
        // 面板未渲染，跳过初始化
        return
      }
      
      // 检查容器是否仍然在DOM中
      if (!document.contains(container)) {
        console.warn('水质图表容器已从DOM中移除，跳过图表初始化')
        return
      }
      
      try {
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
      } catch (error) {
        console.error('初始化水质图表时出错:', error)
        // 清理图表实例
        if (waterQualityChart) {
          try {
            waterQualityChart.dispose()
          } catch (disposeError) {
            console.warn('清理水质图表时出错:', disposeError)
          }
          waterQualityChart = null
        }
      }
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
    const refreshComparisonData = async () => {
      if (selectedReservoirs.value.length >= 2) {
        try {
          console.log('开始获取水情对比数据:', {
            selectedReservoirs: selectedReservoirs.value
          })
          
          // 从水情管理页面获取多个水库的对比数据，使用更大的pageSize
          const allWaterData = await axios.get('/api/waterSituation/list', {
            params: { page: 1, pageSize: 99999 }
          })
          
          const waterData = allWaterData.data.list || []
          console.log('获取到的原始水情数据:', {
            totalCount: waterData.length,
            sampleData: waterData.slice(0, 3).map(item => ({
              reservoir: item.reservoirName,
              date: item.date,
              waterLevel: item.waterLevel,
              storage: item.storage,
              avgInflow: item.avgInflow,
              avgOutflow: item.avgOutflow
            }))
          })
          
          // 为每个选中的水库收集数据，并根据日期范围过滤
          let filteredWaterData = waterData
          
          // 如果选择了日期范围，则过滤数据
          if (selectedComparisonDateRange.value && selectedComparisonDateRange.value.length === 2) {
            const [startDate, endDate] = selectedComparisonDateRange.value
            filteredWaterData = waterData.filter(item => {
              const itemDateStr = normalizeToDayString(item.date)
              const startDateStr = normalizeToDayString(startDate)
              const endDateStr = normalizeToDayString(endDate)
              return itemDateStr >= startDateStr && itemDateStr <= endDateStr
            })
            console.log('按日期范围过滤后的数据:', {
              originalCount: waterData.length,
              filteredCount: filteredWaterData.length,
              dateRange: selectedComparisonDateRange.value
            })
          }
          
          const comparisonData = selectedReservoirs.value.map(reservoirName => {
            const reservoirData = filteredWaterData.filter(item => item.reservoirName === reservoirName)
            console.log(`水库 ${reservoirName} 的数据:`, {
              count: reservoirData.length,
              sampleData: reservoirData.slice(0, 2).map(item => ({
                date: item.date,
                waterLevel: item.waterLevel,
                storage: item.storage,
                avgInflow: item.avgInflow,
                avgOutflow: item.avgOutflow
              }))
            })
            
            return reservoirData.map(item => ({
              ...item,
              reservoirName: reservoirName,
              date: item.date,
              // 保留原始数据，不强制转换为0
              waterLevel: item.waterLevel !== null && item.waterLevel !== undefined ? Number(item.waterLevel) : null,
              storage: item.storage !== null && item.storage !== undefined ? Number(item.storage) : null,
              avgInflow: item.avgInflow !== null && item.avgInflow !== undefined ? Number(item.avgInflow) : null,
              avgOutflow: item.avgOutflow !== null && item.avgOutflow !== undefined ? Number(item.avgOutflow) : null
            }))
          })
          
          // 创建对比专用的数据列表，不覆盖原有的 waterDataList
          const comparisonWaterData = comparisonData.flat()
          console.log('对比数据准备完成:', {
            totalCount: comparisonWaterData.length,
            reservoirs: selectedReservoirs.value,
            indicator: comparisonIndicator.value
          })
          
          // 渲染对比图表，传入对比数据
          await renderSelectedComparisonCharts(comparisonWaterData)
        } catch (error) {
          console.error('获取水情对比数据失败:', error)
          ElMessage.error('获取水情对比数据失败，请检查后端服务是否正常')
        }
      } else {
        ElMessage.warning('请至少选择两个水库，并选择对比指标')
      }
    }
    
    // 刷新环境对比数据
    const refreshEnvironmentComparison = async () => {
      if (selectedMonitorPoints.value.length >= 2 && comparisonEnvironmentIndicator.value) {
        try {
          // 从监测断面管理页面获取多个监测点的对比数据
          const allEnvData = await axios.get('/api/sectionMonitor/list', {
            params: { page: 1, pageSize: 10000 }
          })
          
          const envData = allEnvData.data.list || []
          
          // 如果有月份范围选择，则过滤数据
          let filteredEnvData = envData
          if (selectedEnvComparisonDateRange.value && selectedEnvComparisonDateRange.value.length === 2) {
            const [startMonth, endMonth] = selectedEnvComparisonDateRange.value
            filteredEnvData = envData.filter(item => {
              const itemMonth = `${item.year}-${String(item.month).padStart(2, '0')}`
              return itemMonth >= startMonth && itemMonth <= endMonth
            })
            console.log('环境对比数据按月份范围过滤:', {
              monthRange: selectedEnvComparisonDateRange.value,
              originalCount: envData.length,
              filteredCount: filteredEnvData.length
            })
          }
          
          const comparisonData = selectedMonitorPoints.value.map(monitorPointName => {
            const pointData = filteredEnvData.filter(item => item.monitorPointName === monitorPointName)
            return pointData.map(item => ({
              ...item,
              monitorPointName: monitorPointName,
              year: Number(item.year) || 0,
              month: Number(item.month) || 0,
              ammoniaNitrogen: Number(item.oxygen) || 0,        // 氨氮对应oxygen
              cod: Number(item.cod) || 0,                       // COD对应cod
              totalNitrogen: Number(item.totalNitrogen) || 0,   // 总氮对应totalNitrogen
              totalPhosphorus: Number(item.totalPhosphorus) || 0, // 总磷对应totalPhosphorus
              oxygen: Number(item.oxygen) || 0,                 // 溶解氧对应oxygen
              flow: Number(item.flow) || 0,                     // 流量对应flow
              depth: Number(item.waterDepth) || 0               // 水深对应waterDepth
            }))
          })
          
          // 更新环境数据列表用于对比
          environmentDataList.value = comparisonData.flat()
          
          renderEnvironmentComparisonChart()
        } catch (error) {
          console.error('获取环境对比数据失败:', error)
          ElMessage.error('获取环境对比数据失败，请检查后端服务是否正常')
        }
      } else {
        ElMessage.warning('请至少选择两个监测点，并选择对比指标')
      }
    }
    
    // 渲染水库对比图表（支持2个及以上水库）
    const renderWaterComparisonChart = (comparisonData = null) => {
      // 检查DOM元素是否存在
      const container = document.getElementById('water-comparison-chart')
      if (!container) {
        console.warn('水库对比图表容器不存在，跳过图表初始化')
        return
      }
      
      // 检查容器是否仍然在DOM中
      if (!document.contains(container)) {
        console.warn('水库对比图表容器已从DOM中移除，跳过图表初始化')
        return
      }
      
      try {
        if (!waterComparisonChart) {
          waterComparisonChart = echarts.init(container)
        }
        
        // 使用传入的对比数据，如果没有则使用全局数据
        const dataToUse = comparisonData || waterDataList.value
        
        if (!dataToUse || dataToUse.length === 0) {
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
        
        console.log('开始渲染水库对比图表:', {
          dataCount: dataToUse.length,
          selectedReservoirs: selectedReservoirs.value,
          sampleData: dataToUse.slice(0, 3).map(item => ({
            reservoir: item.reservoirName,
            date: item.date,
            waterLevel: item.waterLevel,
            storage: item.storage,
            avgInflow: item.avgInflow,
            avgOutflow: item.avgOutflow
          }))
        })
        
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
          data: dataToUse.filter(item => item.reservoirName === name)
        }))
        
        console.log('按水库分组的数据:', dataByReservoir.map(d => ({
          reservoir: d.name,
          count: d.data.length,
          sampleValues: d.data.slice(0, 2).map(item => ({
            waterLevel: item.waterLevel,
            storage: item.storage,
            avgInflow: item.avgInflow,
            avgOutflow: item.avgOutflow
          }))
        })))
        
        // 统一时间轴（日期）
        const dates = [...new Set([].concat(...dataByReservoir.map(d => d.data.map(item => item.date))))].sort()
        
        // 颜色调色板
        const palette = ['#409EFF','#E6A23C','#67C23A','#F56C6C','#909399','#9C27B0','#00BCD4','#8D6E63','#EC407A','#26A69A']
        
        // 动态系列 - 为每个水库创建水位系列
        const series = dataByReservoir.map((d, idx) => ({
          name: d.name,
          type: 'line',
          data: dates.map(date => {
            const item = d.data.find(x => normalizeToDayString(x.date) === normalizeToDayString(date))
            const value = item ? item.waterLevel : null
            console.log(`水库 ${d.name} 日期 ${date} 的水位值:`, value)
            return value !== null && value !== undefined ? Number(value) : 0
          }),
          itemStyle: { color: palette[idx % palette.length] },
          lineStyle: { width: 3 },
          symbol: idx % 2 === 0 ? 'circle' : 'diamond',
          symbolSize: 6
        }))
        
        console.log('生成的图表系列数据:', series.map(s => ({
          name: s.name,
          dataCount: s.data.length,
          sampleData: s.data.slice(0, 5)
        })))
        
        const option = {
          title: {
            text: `${selected.join('、')} - 库水位对比`,
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
            name: '库水位'
          },
          series: series
        }
        
        waterComparisonChart.setOption(option)
        console.log('水库对比图表渲染完成')
      } catch (error) {
        console.error('初始化水库对比图表时出错:', error)
        // 清理图表实例
        if (waterComparisonChart) {
          try {
            waterComparisonChart.dispose()
          } catch (disposeError) {
            console.warn('清理水库对比图表时出错:', disposeError)
          }
          waterComparisonChart = null
        }
      }
    }
    
    // 渲染选择的水情对比图表
    const renderSelectedComparisonCharts = async (comparisonData = null) => {
      console.log('开始渲染选择的水情对比图表:', {
        selectedComparisonCharts: selectedComparisonCharts.value,
        selectedReservoirs: selectedReservoirs.value,
        selectedComparisonDateRange: selectedComparisonDateRange.value,
        totalDataCount: comparisonData ? comparisonData.length : waterDataList.value.length
      })
      
      // 使用传入的对比数据，如果没有则使用全局数据
      const dataToUse = comparisonData || waterDataList.value
      
      if (!dataToUse || dataToUse.length === 0) {
        console.warn('没有数据可渲染')
        return
      }
      
      if (!selectedReservoirs.value || selectedReservoirs.value.length < 2) {
        console.warn('请至少选择两个水库')
        return
      }
      
      // 等待DOM更新完成
      await nextTick()
      
      // 根据选择渲染对应的图表
      if (selectedComparisonCharts.value.includes('waterLevel')) {
        console.log('渲染水库水位对比图表')
        renderWaterLevelComparisonChart(dataToUse)
      }
      if (selectedComparisonCharts.value.includes('storage')) {
        console.log('渲染水库蓄水量对比图表')
        renderWaterStorageComparisonChart(dataToUse)
      }
      if (selectedComparisonCharts.value.includes('avgInflow')) {
        console.log('渲染入库流量对比图表')
        renderWaterInflowComparisonChart(dataToUse)
      }
      if (selectedComparisonCharts.value.includes('avgOutflow')) {
        console.log('渲染出库流量对比图表')
        renderWaterOutflowComparisonChart(dataToUse)
      }
    }
    
    // 渲染水库水位对比图表
    const renderWaterLevelComparisonChart = (data) => {
      const container = document.getElementById('water-level-comparison-chart')
      if (!container || !document.contains(container)) {
        console.warn('水库水位对比图表容器不存在，跳过图表初始化')
        return
      }
      
      try {
        if (!waterLevelComparisonChart) {
          waterLevelComparisonChart = echarts.init(container)
        }
        
        // 为每个已选水库收集数据
        const selected = selectedReservoirs.value
        const dataByReservoir = selected.map(name => ({
          name,
          data: data.filter(item => item.reservoirName === name)
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
            const item = d.data.find(x => normalizeToDayString(x.date) === normalizeToDayString(date))
            const value = item ? item.waterLevel : null
            return value !== null && value !== undefined ? Number(value) : 0
          }),
          itemStyle: { color: palette[idx % palette.length] },
          lineStyle: { width: 3 },
          symbol: idx % 2 === 0 ? 'circle' : 'diamond',
          symbolSize: 6,
          smooth: true
        }))
        
        const option = {
          title: {
            text: `${selected.join('、')} - 库水位对比`,
            left: 'center'
          },
          tooltip: {
            trigger: 'axis',
            formatter: function(params) {
              let result = params[0].axisValue + '<br/>'
              params.forEach(param => {
                result += param.marker + param.seriesName + ': ' + param.value + ' 米<br/>'
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
            name: '库水位'
          },
          series: series
        }
        
        waterLevelComparisonChart.setOption(option)
        console.log('水库水位对比图表渲染完成')
      } catch (error) {
        console.error('初始化水库水位对比图表时出错:', error)
        if (waterLevelComparisonChart) {
          try {
            waterLevelComparisonChart.dispose()
          } catch (disposeError) {
            console.warn('清理水库水位对比图表时出错:', disposeError)
          }
          waterLevelComparisonChart = null
        }
      }
    }
    
    // 渲染水库蓄水量对比图表
    const renderWaterStorageComparisonChart = (data) => {
      const container = document.getElementById('water-storage-comparison-chart')
      if (!container || !document.contains(container)) {
        console.warn('水库蓄水量对比图表容器不存在，跳过图表初始化')
        return
      }
      
      try {
        if (!waterStorageComparisonChart) {
          waterStorageComparisonChart = echarts.init(container)
        }
        
        // 为每个已选水库收集数据
        const selected = selectedReservoirs.value
        const dataByReservoir = selected.map(name => ({
          name,
          data: data.filter(item => item.reservoirName === name)
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
            const item = d.data.find(x => normalizeToDayString(x.date) === normalizeToDayString(date))
            const value = item ? item.storage : null
            return value !== null && value !== undefined ? Number(value) : 0
          }),
          itemStyle: { color: palette[idx % palette.length] },
          lineStyle: { width: 3 },
          symbol: idx % 2 === 0 ? 'circle' : 'diamond',
          symbolSize: 6,
          smooth: true
        }))
        
        const option = {
          title: {
            text: `${selected.join('、')} - 蓄水量对比`,
            left: 'center'
          },
          tooltip: {
            trigger: 'axis',
            formatter: function(params) {
              let result = params[0].axisValue + '<br/>'
              params.forEach(param => {
                result += param.marker + param.seriesName + ': ' + param.value + ' 万立方米<br/>'
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
            name: '蓄水量(万立方米)'
          },
          series: series
        }
        
        waterStorageComparisonChart.setOption(option)
        console.log('水库蓄水量对比图表渲染完成')
      } catch (error) {
        console.error('初始化水库蓄水量对比图表时出错:', error)
        if (waterStorageComparisonChart) {
          try {
            waterStorageComparisonChart.dispose()
          } catch (disposeError) {
            console.warn('清理水库蓄水量对比图表时出错:', disposeError)
          }
          waterStorageComparisonChart = null
        }
      }
    }
    
    // 渲染入库流量对比图表
    const renderWaterInflowComparisonChart = (data) => {
      const container = document.getElementById('water-inflow-comparison-chart')
      if (!container || !document.contains(container)) {
        console.warn('入库流量对比图表容器不存在，跳过图表初始化')
        return
      }
      
      try {
        if (!waterInflowComparisonChart) {
          waterInflowComparisonChart = echarts.init(container)
        }
        
        // 为每个已选水库收集数据
        const selected = selectedReservoirs.value
        const dataByReservoir = selected.map(name => ({
          name,
          data: data.filter(item => item.reservoirName === name)
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
            const item = d.data.find(x => normalizeToDayString(x.date) === normalizeToDayString(date))
            const value = item ? item.avgInflow : null
            return value !== null && value !== undefined ? Number(value) : 0
          }),
          itemStyle: { color: palette[idx % palette.length] },
          lineStyle: { width: 3 },
          symbol: idx % 2 === 0 ? 'circle' : 'diamond',
          symbolSize: 6,
          smooth: true
        }))
        
        const option = {
          title: {
            text: `${selected.join('、')} - 入库流量对比`,
            left: 'center'
          },
          tooltip: {
            trigger: 'axis',
            formatter: function(params) {
              let result = params[0].axisValue + '<br/>'
              params.forEach(param => {
                result += param.marker + param.seriesName + ': ' + param.value + ' 立方米/秒<br/>'
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
            name: '入库流量(立方米/秒)'
          },
          series: series
        }
        
        waterInflowComparisonChart.setOption(option)
        console.log('入库流量对比图表渲染完成')
      } catch (error) {
        console.error('初始化入库流量对比图表时出错:', error)
        if (waterInflowComparisonChart) {
          try {
            waterInflowComparisonChart.dispose()
          } catch (disposeError) {
            console.warn('清理入库流量对比图表时出错:', disposeError)
          }
          waterInflowComparisonChart = null
        }
      }
    }
    
    // 渲染出库流量对比图表
    const renderWaterOutflowComparisonChart = (data) => {
      const container = document.getElementById('water-outflow-comparison-chart')
      if (!container || !document.contains(container)) {
        console.warn('出库流量对比图表容器不存在，跳过图表初始化')
        return
      }
      
      try {
        if (!waterOutflowComparisonChart) {
          waterOutflowComparisonChart = echarts.init(container)
        }
        
        // 为每个已选水库收集数据
        const selected = selectedReservoirs.value
        const dataByReservoir = selected.map(name => ({
          name,
          data: data.filter(item => item.reservoirName === name)
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
            const item = d.data.find(x => normalizeToDayString(x.date) === normalizeToDayString(date))
            const value = item ? item.avgOutflow : null
            return value !== null && value !== undefined ? Number(value) : 0
          }),
          itemStyle: { color: palette[idx % palette.length] },
          lineStyle: { width: 3 },
          symbol: idx % 2 === 0 ? 'circle' : 'diamond',
          symbolSize: 6,
          smooth: true
        }))
        
        const option = {
          title: {
            text: `${selected.join('、')} - 出库流量对比`,
            left: 'center'
          },
          tooltip: {
            trigger: 'axis',
            formatter: function(params) {
              let result = params[0].axisValue + '<br/>'
              params.forEach(param => {
                result += param.marker + param.seriesName + ': ' + param.value + ' 立方米/秒<br/>'
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
            name: '出库流量(立方米/秒)'
          },
          series: series
        }
        
        waterOutflowComparisonChart.setOption(option)
        console.log('出库流量对比图表渲染完成')
      } catch (error) {
        console.error('初始化出库流量对比图表时出错:', error)
        if (waterOutflowComparisonChart) {
          try {
            waterOutflowComparisonChart.dispose()
          } catch (disposeError) {
            console.warn('清理出库流量对比图表时出错:', disposeError)
          }
          waterOutflowComparisonChart = null
        }
      }
    }
    
    // 渲染环境对比图表

    
    // 渲染蓄水量变化图表
    const renderWaterStorageChart = (data) => {
      // 检查DOM元素是否存在
      const container = document.getElementById('water-storage-chart')
      if (!container) {
        console.warn('蓄水量图表容器不存在，跳过图表初始化')
        return
      }
      
      // 检查容器是否仍然在DOM中
      if (!document.contains(container)) {
        console.warn('蓄水量图表容器已从DOM中移除，跳过图表初始化')
        return
      }
      
      try {
        // 检查图表实例是否仍然有效，如果无效则重新创建
        if (!waterStorageChart || !waterStorageChart.getDom || !waterStorageChart.getDom() || !document.contains(waterStorageChart.getDom())) {
          if (waterStorageChart) {
            try {
              waterStorageChart.dispose()
            } catch (error) {
              console.warn('清理旧的蓄水量图表实例时出错:', error)
            }
          }
          waterStorageChart = echarts.init(container)
          console.log('重新初始化蓄水量图表实例')
        }
        
        if (!data || data.length === 0) {
          // 显示无数据提示
          waterStorageChart.setOption({
            title: {
              text: getWaterStorageChartTitle(),
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
        
        // 按日期排序
        const sortedData = data.sort((a, b) => new Date(a.date) - new Date(b.date))
        
        // 准备图表数据
        const dates = sortedData.map(item => {
          const date = new Date(item.date)
          return `${date.getMonth() + 1}/${date.getDate()}`
        })
        const storageValues = sortedData.map(item => Number(item.storage) || 0)
        
        const option = {
          title: {
            text: getWaterStorageChartTitle(),
            left: 'center'
          },
          tooltip: {
            trigger: 'axis',
            formatter: function(params) {
              const dataIndex = params[0].dataIndex
              const originalDate = sortedData[dataIndex].date
              return `${originalDate}<br/>蓄水量: ${params[0].value} 万立方米`
            }
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
            name: '蓄水量(万立方米)',
            nameLocation: 'middle',
            nameGap: 40
          },
          series: [{
            name: '蓄水量',
            type: 'line',
            data: storageValues,
            smooth: true,
            lineStyle: {
              color: '#67C23A',
              width: 3
            },
            itemStyle: {
              color: '#67C23A'
            },
            areaStyle: {
              color: {
                type: 'linear',
                x: 0, y: 0, x2: 0, y2: 1,
                colorStops: [
                  { offset: 0, color: 'rgba(103, 194, 58, 0.3)' },
                  { offset: 1, color: 'rgba(103, 194, 58, 0.1)' }
                ]
              }
            }
          }]
        }
        
        waterStorageChart.setOption(option, true)
      } catch (error) {
        console.error('初始化蓄水量图表时出错:', error)
        // 清理图表实例
        if (waterStorageChart) {
          try {
            waterStorageChart.dispose()
          } catch (disposeError) {
            console.warn('清理蓄水量图表时出错:', disposeError)
          }
          waterStorageChart = null
        }
      }
    }
    
    // 渲染日均入库流量变化图表
    const renderWaterInflowChart = (data) => {
      // 检查DOM元素是否存在
      const container = document.getElementById('water-inflow-chart')
      if (!container) {
        console.warn('入库流量图表容器不存在，跳过图表初始化')
        return
      }
      
      // 检查容器是否仍然在DOM中
      if (!document.contains(container)) {
        console.warn('入库流量图表容器已从DOM中移除，跳过图表初始化')
        return
      }
      
      try {
        if (!waterInflowChart) {
          waterInflowChart = echarts.init(container)
        }
        
        if (!data || data.length === 0) {
          // 显示无数据提示
          waterInflowChart.setOption({
            title: {
              text: getWaterInflowChartTitle(),
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
        
        // 按日期排序
        const sortedData = data.sort((a, b) => new Date(a.date) - new Date(b.date))
        
        // 准备图表数据
        const dates = sortedData.map(item => {
          const date = new Date(item.date)
          return `${date.getMonth() + 1}/${date.getDate()}`
        })
        const inflowValues = sortedData.map(item => Number(item.avgInflow) || 0)
        
        const option = {
          title: {
            text: getWaterInflowChartTitle(),
            left: 'center'
          },
          tooltip: {
            trigger: 'axis',
            formatter: function(params) {
              const dataIndex = params[0].dataIndex
              const originalDate = sortedData[dataIndex].date
              return `${originalDate}<br/>日均入库流量: ${params[0].value} 立方米/秒`
            }
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
            name: '日均入库流量(立方米/秒)',
            nameLocation: 'middle',
            nameGap: 40
          },
          series: [{
            name: '日均入库流量',
            type: 'line',
            data: inflowValues,
            smooth: true,
            lineStyle: {
              color: '#E6A23C',
              width: 3
            },
            itemStyle: {
              color: '#E6A23C'
            },
            areaStyle: {
              color: {
                type: 'linear',
                x: 0, y: 0, x2: 0, y2: 1,
                colorStops: [
                  { offset: 0, color: 'rgba(230, 162, 60, 0.3)' },
                  { offset: 1, color: 'rgba(230, 162, 60, 0.1)' }
                ]
              }
            }
          }]
        }
        
        waterInflowChart.setOption(option, true)
      } catch (error) {
        console.error('初始化入库流量图表时出错:', error)
        // 清理图表实例
        if (waterInflowChart) {
          try {
            waterInflowChart.dispose()
          } catch (disposeError) {
            console.warn('清理入库流量图表时出错:', disposeError)
          }
          waterInflowChart = null
        }
      }
    }
    
    // 渲染日均出库流量变化图表
    const renderWaterOutflowChart = (data) => {
      // 检查DOM元素是否存在
      const container = document.getElementById('water-outflow-chart')
      if (!container) {
        console.warn('出库流量图表容器不存在，跳过图表初始化')
        return
      }
      
      // 检查容器是否仍然在DOM中
      if (!document.contains(container)) {
        console.warn('出库流量图表容器已从DOM中移除，跳过图表初始化')
        return
      }
      
      try {
        if (!waterOutflowChart) {
          waterOutflowChart = echarts.init(container)
        }
        
        if (!data || data.length === 0) {
          // 显示无数据提示
          waterOutflowChart.setOption({
            title: {
              text: getWaterOutflowChartTitle(),
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
        
        // 按日期排序
        const sortedData = data.sort((a, b) => new Date(a.date) - new Date(b.date))
        
        // 准备图表数据
        const dates = sortedData.map(item => {
          const date = new Date(item.date)
          return `${date.getMonth() + 1}/${date.getDate()}`
        })
        const outflowValues = sortedData.map(item => Number(item.avgOutflow) || 0)
        
        const option = {
          title: {
            text: getWaterOutflowChartTitle(),
            left: 'center'
          },
          tooltip: {
            trigger: 'axis',
            formatter: function(params) {
              const dataIndex = params[0].dataIndex
              const originalDate = sortedData[dataIndex].date
              return `${originalDate}<br/>日均出库流量: ${params[0].value} 立方米/秒`
            }
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
            name: '日均出库流量(立方米/秒)',
            nameLocation: 'middle',
            nameGap: 40
          },
          series: [{
            name: '日均出库流量',
            type: 'line',
            data: outflowValues,
            smooth: true,
            lineStyle: {
              color: '#F56C6C',
              width: 3
            },
            itemStyle: {
              color: '#F56C6C'
            },
            areaStyle: {
              color: {
                type: 'linear',
                x: 0, y: 0, x2: 0, y2: 1,
                colorStops: [
                  { offset: 0, color: 'rgba(245, 108, 108, 0.3)' },
                  { offset: 1, color: 'rgba(245, 108, 108, 0.1)' }
                ]
              }
            }
          }]
        }
        
        waterOutflowChart.setOption(option, true)
      } catch (error) {
        console.error('初始化出库流量图表时出错:', error)
        // 清理图表实例
        if (waterOutflowChart) {
          try {
            waterOutflowChart.dispose()
          } catch (disposeError) {
            console.warn('清理出库流量图表时出错:', disposeError)
          }
          waterOutflowChart = null
        }
      }
    }
    
    // 更新蓄水量变化图表
    const updateWaterStorageChart = (data) => {
      // 检查DOM元素是否存在
      const container = document.getElementById('water-storage-chart')
      if (!container) {
        console.warn('蓄水量图表容器不存在，跳过图表更新')
        return
      }
      
      // 检查容器是否仍然在DOM中
      if (!document.contains(container)) {
        console.warn('蓄水量图表容器已从DOM中移除，跳过图表更新')
        return
      }
      
      try {
        if (!waterStorageChart) {
          waterStorageChart = echarts.init(container)
        }
        
        if (!data || data.length === 0) {
          // 清空图表
          const emptyOption = {
            title: { 
              text: getWaterStorageChartTitle(),
              left: 'center'
            },
            series: [{ 
              type: 'line',
              data: [] 
            }]
          }
          waterStorageChart.setOption(emptyOption, true)
          return
        }
        
        // 按日期排序
        const sortedData = data.sort((a, b) => new Date(a.date) - new Date(b.date))
        
        // 准备图表数据
        const dates = sortedData.map(item => {
          const date = new Date(item.date)
          return `${date.getMonth() + 1}/${date.getDate()}`
        })
        const storageValues = sortedData.map(item => Number(item.storage) || 0)
        
        const option = {
          title: {
            text: getWaterStorageChartTitle(),
            left: 'center'
          },
          tooltip: {
            trigger: 'axis',
            formatter: function(params) {
              const dataIndex = params[0].dataIndex
              const originalDate = sortedData[dataIndex].date
              return `${originalDate}<br/>蓄水量: ${params[0].value} 万立方米`
            }
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
            name: '蓄水量(万立方米)',
            nameLocation: 'middle',
            nameGap: 40
          },
          series: [{
            name: '蓄水量',
            type: 'line',
            data: storageValues,
            smooth: true,
            lineStyle: {
              color: '#67C23A',
              width: 3
            },
            itemStyle: {
              color: '#67C23A'
            },
            areaStyle: {
              color: {
                type: 'linear',
                x: 0, y: 0, x2: 0, y2: 1,
                colorStops: [
                  { offset: 0, color: 'rgba(103, 194, 58, 0.3)' },
                  { offset: 1, color: 'rgba(103, 194, 58, 0.1)' }
                ]
              }
            }
          }]
        }
        
        waterStorageChart.setOption(option, true)
      } catch (error) {
        console.error('更新蓄水量图表时出错:', error)
        // 清理图表实例
        if (waterStorageChart) {
          try {
            waterStorageChart.dispose()
          } catch (disposeError) {
            console.warn('清理蓄水量图表时出错:', disposeError)
          }
          waterStorageChart = null
        }
      }
    }
    
    // 更新日均入库流量变化图表
    const updateWaterInflowChart = (data) => {
      // 检查DOM元素是否存在
      const container = document.getElementById('water-inflow-chart')
      if (!container) {
        console.warn('入库流量图表容器不存在，跳过图表更新')
        return
      }
      
      // 检查容器是否仍然在DOM中
      if (!document.contains(container)) {
        console.warn('入库流量图表容器已从DOM中移除，跳过图表更新')
        return
      }
      
      try {
        if (!waterInflowChart) {
          waterInflowChart = echarts.init(container)
        }
        
        if (!data || data.length === 0) {
          // 清空图表
          const emptyOption = {
            title: { 
              text: getWaterInflowChartTitle(),
              left: 'center'
            },
            series: [{ 
              type: 'line',
              data: [] 
            }]
          }
          waterInflowChart.setOption(emptyOption, true)
          return
        }
        
        // 按日期排序
        const sortedData = data.sort((a, b) => new Date(a.date) - new Date(b.date))
        
        // 准备图表数据
        const dates = sortedData.map(item => {
          const date = new Date(item.date)
          return `${date.getMonth() + 1}/${date.getDate()}`
        })
        const inflowValues = sortedData.map(item => Number(item.avgInflow) || 0)
        
        const option = {
          title: {
            text: getWaterInflowChartTitle(),
            left: 'center'
          },
          tooltip: {
            trigger: 'axis',
            formatter: function(params) {
              const dataIndex = params[0].dataIndex
              const originalDate = sortedData[dataIndex].date
              return `${originalDate}<br/>日均入库流量: ${params[0].value} 立方米/秒`
            }
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
            name: '日均入库流量(立方米/秒)',
            nameLocation: 'middle',
            nameGap: 40
          },
          series: [{
            name: '日均入库流量',
            type: 'line',
            data: inflowValues,
            smooth: true,
            lineStyle: {
              color: '#E6A23C',
              width: 3
            },
            itemStyle: {
              color: '#E6A23C'
            },
            areaStyle: {
              color: {
                type: 'linear',
                x: 0, y: 0, x2: 0, y2: 1,
                colorStops: [
                  { offset: 0, color: 'rgba(230, 162, 60, 0.3)' },
                  { offset: 1, color: 'rgba(230, 162, 60, 0.1)' }
                ]
              }
            }
          }]
        }
        
        waterInflowChart.setOption(option, true)
      } catch (error) {
        console.error('更新入库流量图表时出错:', error)
        // 清理图表实例
        if (waterInflowChart) {
          try {
            waterInflowChart.dispose()
          } catch (disposeError) {
            console.warn('清理入库流量图表时出错:', disposeError)
          }
          waterInflowChart = null
        }
      }
    }
    
    // 更新日均出库流量变化图表
    const updateWaterOutflowChart = (data) => {
      // 检查DOM元素是否存在
      const container = document.getElementById('water-outflow-chart')
      if (!container) {
        console.warn('出库流量图表容器不存在，跳过图表更新')
        return
      }
      
      // 检查容器是否仍然在DOM中
      if (!document.contains(container)) {
        console.warn('出库流量图表容器已从DOM中移除，跳过图表更新')
        return
      }
      
      try {
        if (!waterOutflowChart) {
          waterOutflowChart = echarts.init(container)
        }
        
        if (!data || data.length === 0) {
          // 清空图表
          const emptyOption = {
            title: { 
              text: getWaterOutflowChartTitle(),
              left: 'center'
            },
            series: [{ 
              type: 'line',
              data: [] 
            }]
          }
          waterOutflowChart.setOption(emptyOption, true)
          return
        }
        
        // 按日期排序
        const sortedData = data.sort((a, b) => new Date(a.date) - new Date(b.date))
        
        // 准备图表数据
        const dates = sortedData.map(item => {
          const date = new Date(item.date)
          return `${date.getMonth() + 1}/${date.getDate()}`
        })
        const outflowValues = sortedData.map(item => Number(item.avgOutflow) || 0)
        
        const option = {
          title: {
            text: getWaterOutflowChartTitle(),
            left: 'center'
          },
          tooltip: {
            trigger: 'axis',
            formatter: function(params) {
              const dataIndex = params[0].dataIndex
              const originalDate = sortedData[dataIndex].date
              return `${originalDate}<br/>日均出库流量: ${params[0].value} 立方米/秒`
            }
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
            name: '日均出库流量(立方米/秒)',
            nameLocation: 'middle',
            nameGap: 40
          },
          series: [{
            name: '日均出库流量',
            type: 'line',
            data: outflowValues,
            smooth: true,
            lineStyle: {
              color: '#F56C6C',
              width: 3
            },
            itemStyle: {
              color: '#F56C6C'
            },
            areaStyle: {
              color: {
                type: 'linear',
                x: 0, y: 0, x2: 0, y2: 1,
                colorStops: [
                  { offset: 0, color: 'rgba(245, 108, 108, 0.3)' },
                  { offset: 1, color: 'rgba(245, 108, 108, 0.1)' }
                ]
              }
            }
          }]
        }
        
        waterOutflowChart.setOption(option, true)
      } catch (error) {
        console.error('更新出库流量图表时出错:', error)
        // 清理图表实例
        if (waterOutflowChart) {
          try {
            waterOutflowChart.dispose()
          } catch (disposeError) {
            console.warn('清理出库流量图表时出错:', disposeError)
          }
          waterOutflowChart = null
        }
      }
    }
    
    // 监听面板切换，自动获取对应数据
    watch(activeBox, async (newPanel) => {
      console.log('面板切换到:', newPanel)
      
      if (newPanel === 'environmentStatistics') {
        // 切换到环境统计面板时，清空表格选择，要求用户重新选择
        console.log('切换到环境统计面板，清空表格选择，等待用户重新选择...')
        selectedEnvironmentCharts.value = []
        
        // 获取环境数据
        if (environmentDataList.value.length === 0) {
          console.log('切换到环境面板，开始获取环境数据...')
          await fetchEnvironmentStatistics()
        } else {
          console.log('环境数据已存在，确保监测点和日期范围已设置...')
          
          // 确保监测点已选择
          if (!selectedMonitorPoint.value && monitorPointList.value.length > 0) {
            selectedMonitorPoint.value = monitorPointList.value[0]
            console.log('自动选择第一个监测点:', selectedMonitorPoint.value)
          }
          
          // 确保日期范围已设置 - 使用数据中的第一条记录作为开始月份
          if (!selectedEnvDateRange.value || selectedEnvDateRange.value.length !== 2) {
            if (environmentDataList.value.length > 0) {
              // 找到第一条数据的年月
              const firstData = environmentDataList.value[0]
              const firstMonth = `${firstData.year}-${String(firstData.month).padStart(2, '0')}`
              
              // 设置默认月份范围：从第一条数据到当前月份
              const today = new Date()
              const currentMonth = formatYearMonth(today)
              
              selectedEnvDateRange.value = [firstMonth, currentMonth]
              console.log('使用数据中的第一条记录设置月份范围:', selectedEnvDateRange.value)
            } else {
              // 如果没有数据，使用默认的3个月范围
            const today = new Date()
            const threeMonthsAgo = new Date(today.getFullYear(), today.getMonth() - 2, 1)
            selectedEnvDateRange.value = [
              formatYearMonth(threeMonthsAgo),
              formatYearMonth(today)
            ]
            console.log('设置默认月份范围:', selectedEnvDateRange.value)
            }
          }
          
          // 确保环境统计数据是最新的
          await updateSelectedEnvironmentStats()
        }
      } else if (newPanel === 'environmentComparison') {
        // 切换到环境对比面板时，清空表格选择，要求用户重新选择
        console.log('切换到环境对比面板，清空表格选择，等待用户重新选择...')
        selectedEnvironmentComparisonCharts.value = []
        
        // 获取环境数据
        if (environmentDataList.value.length === 0) {
          console.log('切换到环境对比面板，开始获取环境数据...')
          await fetchEnvironmentStatistics()
        } else {
          console.log('环境数据已存在，确保环境对比参数已设置...')
          
          // 不设置默认日期范围，让用户手动选择
          console.log('环境对比面板等待用户手动选择日期范围...')
          
          // 确保环境对比数据是最新的
          await updateSelectedEnvironmentComparisonStats()
        }
      } else if (newPanel === 'waterComparison') {
        // 切换到水情对比面板时，清空表格选择，要求用户重新选择
        console.log('切换到水情对比面板，清空表格选择，等待用户重新选择...')
        selectedComparisonCharts.value = []
        
        // 确保有水情数据
        if (waterDataList.value.length === 0) {
          console.log('切换到水情对比面板，开始获取水情数据...')
          await fetchWaterStatistics()
        } else {
          console.log('水情数据已存在，但表格选择已清空，等待用户重新选择...')
        }
      } else if (newPanel === 'waterStatistics') {
        // 切换到水情统计面板时，清空表格选择，要求用户重新选择
        console.log('切换到水情统计面板，清空表格选择，等待用户重新选择...')
        
        // 清空表格选择，强制用户重新选择
        selectedCharts.value = []
        
        // 确保有水情数据
        if (waterDataList.value.length === 0) {
          console.log('水情数据为空，重新获取数据...')
          await fetchWaterStatistics()
        } else {
          console.log('水情数据已存在，检查数据完整性...')
          
          // 检查数据完整性，特别是 avgInflow 和 avgOutflow 字段
          const hasValidData = waterDataList.value.every(item => 
            item.avgInflow !== null && 
            item.avgInflow !== undefined && 
            !isNaN(Number(item.avgInflow)) &&
            item.avgOutflow !== null && 
            item.avgOutflow !== undefined && 
            !isNaN(Number(item.avgOutflow))
          )
          
          if (!hasValidData) {
            console.log('检测到数据不完整，重新获取数据...')
            await fetchWaterStatistics()
          } else {
            console.log('数据完整，但表格选择已清空，等待用户重新选择...')
            // 不自动渲染图表，等待用户选择表格
          }
        }
      }
    })
    
    // 添加数据恢复机制，定期检查数据完整性
    let dataIntegrityCheckInterval
    onMounted(() => {
      // 每30秒检查一次数据完整性
      dataIntegrityCheckInterval = setInterval(() => {
        if (activeBox.value === 'waterStatistics' && waterDataList.value.length > 0) {
          const hasValidData = waterDataList.value.every(item => 
            item.avgInflow !== null && 
            item.avgInflow !== undefined && 
            !isNaN(Number(item.avgInflow)) &&
            item.avgOutflow !== null && 
            item.avgOutflow !== undefined && 
            !isNaN(Number(item.avgOutflow))
          )
          
          if (!hasValidData) {
            console.log('定期检查发现数据不完整，自动恢复...')
            fetchWaterStatistics()
          }
        }
      }, 30000)
    })
    
    onBeforeUnmount(() => {
      if (dataIntegrityCheckInterval) {
        clearInterval(dataIntegrityCheckInterval)
      }
    })
    
    // 监听水情统计表格选择变化，自动更新图表
    watch(selectedCharts, async (newCharts, oldCharts) => {
      console.log('水情统计表格选择变化:', { old: oldCharts, new: newCharts })
      
      // 如果当前在水情统计面板且有数据，则更新图表
      if (activeBox.value === 'waterStatistics' && waterDataList.value.length > 0) {
        if (newCharts.length === 0) {
          console.log('用户清空了所有表格选择，清理图表实例')
          // 清理所有图表实例
          cleanupRemovedCharts(oldCharts, [])
        } else {
          console.log('用户选择了表格，开始渲染图表...')
          // 清理被删除的图表实例
          cleanupRemovedCharts(oldCharts, newCharts)
          
          // 等待DOM更新完成
          await nextTick()
          
          // 等待新选择的图表容器准备好
          await waitForChartContainers()
          
          // 使用统一的图表渲染函数
          await renderSelectedCharts()
        }
      }
    })
    
    // 监听水情对比表格选择变化
    watch(selectedComparisonCharts, async (newCharts, oldCharts) => {
      console.log('水情对比表格选择变化:', { old: oldCharts, new: newCharts })
      
      // 如果当前在水情对比面板且有数据，则更新图表
      if (activeBox.value === 'waterComparison' && waterDataList.value.length > 0) {
        if (newCharts.length === 0) {
          console.log('用户清空了所有对比表格选择，清理图表实例')
          // 清理所有对比图表实例
          cleanupRemovedComparisonCharts(oldCharts, [])
        } else {
          console.log('用户选择了对比表格，开始渲染图表...')
          // 清理被删除的对比图表实例
          cleanupRemovedComparisonCharts(oldCharts, newCharts)
          
          // 等待DOM更新完成
          await nextTick()
          
          // 渲染选择的对比图表
          await renderSelectedComparisonCharts()
        }
      }
    })
    
    // 监听环境统计表格选择变化
    watch(selectedEnvironmentCharts, async (newCharts, oldCharts) => {
      console.log('环境统计表格选择变化:', { old: oldCharts, new: newCharts })
      
      // 如果当前在环境统计面板，则更新图表
      if (activeBox.value === 'environmentStatistics') {
        if (newCharts.length === 0) {
          console.log('用户清空了所有环境统计表格选择，清理图表实例')
          // 清理所有环境统计图表实例
          cleanupRemovedEnvironmentCharts(oldCharts, [])
        } else {
          console.log('用户选择了环境统计表格，自动更新数据并渲染图表...')
          // 清理被删除的环境统计图表实例
          cleanupRemovedEnvironmentCharts(oldCharts, newCharts)
          
          // 先更新统计数据
          await updateSelectedEnvironmentStats()
          
          // 等待DOM更新完成
          await nextTick()
          
          // 渲染选择的环境统计图表
          await renderSelectedEnvironmentCharts()
        }
      }
    })
    
    // 监听环境对比表格选择变化
    watch(selectedEnvironmentComparisonCharts, async (newCharts, oldCharts) => {
      console.log('环境对比表格选择变化:', { old: oldCharts, new: newCharts })
      
      // 如果当前在环境对比面板且有数据，则更新图表
      if (activeBox.value === 'environmentComparison' && environmentDataList.value.length > 0) {
        if (newCharts.length === 0) {
          console.log('用户清空了所有环境对比表格选择，清理图表实例')
          // 清理所有环境对比图表实例
          cleanupRemovedEnvironmentComparisonCharts(oldCharts, [])
        } else {
          console.log('用户选择了环境对比表格，自动更新数据并渲染图表...')
          // 清理被删除的环境对比图表实例
          cleanupRemovedEnvironmentComparisonCharts(oldCharts, newCharts)
          
          // 先更新对比数据
          await updateSelectedEnvironmentComparisonStats()
          
          // 等待DOM更新完成
          await nextTick()
          
          // 渲染选择的环境对比图表
          await renderSelectedEnvironmentComparisonCharts()
        }
      }
    })
    
    watch(selectedReservoir, async (newVal, oldVal) => {
      console.log('水库选择变化:', { old: oldVal, new: newVal })
      await refreshSelectedReservoirDates()
    })
    watch(selectedDateRange, async (newVal, oldVal) => {
      console.log('日期范围选择变化:', { old: oldVal, new: newVal })
      await updateSelectedWaterStats()
    })
    watch(selectedReservoirs, async (newVal, oldVal) => {
      console.log('水情对比水库选择变化:', { old: oldVal, new: newVal })
      await refreshSelectedComparisonReservoirDates()
    })
    watch(selectedComparisonDateRange, async (newVal, oldVal) => {
      console.log('水情对比日期范围选择变化:', { old: oldVal, new: newVal })
      // 当日期范围变化时，自动刷新对比数据
      if (activeBox.value === 'waterComparison' && selectedReservoirs.value.length >= 2) {
        await refreshComparisonData()
      }
    })
    watch(selectedComparisonCharts, async (newCharts, oldCharts) => {
      console.log('水情对比表格选择变化:', { old: oldCharts, new: newCharts })
      // 当表格选择变化时，自动刷新对比数据
      if (activeBox.value === 'waterComparison' && selectedReservoirs.value.length >= 2) {
        await refreshComparisonData()
      }
    })
    watch(selectedMonitorPoint, async () => {
      console.log('监测点选择变化，自动更新数据和图表...')
      refreshSelectedMonitorPointMonths()
      await updateSelectedEnvironmentStats()
      
      // 如果有选择的图表且在环境统计面板，则自动重新渲染图表
      if (activeBox.value === 'environmentStatistics' && selectedEnvironmentCharts.value.length > 0) {
        console.log('监测点变化，重新渲染环境统计图表...')
        await renderSelectedEnvironmentCharts()
      }
    })
    watch(selectedEnvDateRange, async () => {
      console.log('环境统计日期范围变化，自动更新数据和图表...')
      await updateSelectedEnvironmentStats()
      
      // 如果有选择的图表且在环境统计面板，则自动重新渲染图表
      if (activeBox.value === 'environmentStatistics' && selectedEnvironmentCharts.value.length > 0) {
        console.log('日期范围变化，重新渲染环境统计图表...')
        await renderSelectedEnvironmentCharts()
      }
    })

    watch(selectedEnvComparisonDateRange, async () => {
      console.log('环境对比日期范围变化，自动更新数据...')
      await updateSelectedEnvironmentComparisonStats()
      
      // 如果有选择的图表且在环境对比面板，则自动重新渲染图表
      if (activeBox.value === 'environmentComparison' && selectedEnvironmentComparisonCharts.value.length > 0) {
        console.log('日期范围变化，重新渲染环境对比图表...')
        await renderSelectedEnvironmentComparisonCharts()
      }
    })

    // 监听环境对比监测点选择变化
    watch(selectedMonitorPoints, async () => {
      console.log('环境对比监测点选择变化，自动更新数据...')
      await updateSelectedEnvironmentComparisonStats()
      
      // 如果有选择的图表且在环境对比面板，则自动重新渲染图表
      if (activeBox.value === 'environmentComparison' && selectedEnvironmentComparisonCharts.value.length > 0) {
        console.log('监测点变化，重新渲染环境对比图表...')
        await renderSelectedEnvironmentComparisonCharts()
      }
    })

    // 监听环境对比指标选择变化
    watch(comparisonEnvironmentIndicator, async () => {
      console.log('环境对比指标选择变化，自动更新数据...')
      await updateSelectedEnvironmentComparisonStats()
      
      // 如果有选择的图表且在环境对比面板，则自动重新渲染图表
      if (activeBox.value === 'environmentComparison' && selectedEnvironmentComparisonCharts.value.length > 0) {
        console.log('对比指标变化，重新渲染环境对比图表...')
        await renderSelectedEnvironmentComparisonCharts()
      }
    })

    onMounted(async () => {
      try {
        // 确保所有面板的初始状态下都没有选择任何表格
        selectedCharts.value = []
        selectedComparisonCharts.value = []
        selectedEnvironmentCharts.value = []
        selectedEnvironmentComparisonCharts.value = []
        console.log('组件挂载完成，所有面板初始状态下无表格选择，等待用户选择...')
        
        // 只获取水情统计数据（因为默认面板是水情统计）
        fetchWaterStatistics()
        
        // 延迟获取环境统计数据，等待用户切换到环境面板时再获取
        console.log('环境统计数据将在用户切换到环境面板时获取')
        
      } catch (error) {
        console.error('组件挂载时出错:', error)
        // 即使出错也尝试获取水情数据
        fetchWaterStatistics()
      }
    })
    
    // 等待图表容器准备好的函数
    const waitForChartContainers = async () => {
      const maxAttempts = 50 // 最大尝试次数
      const interval = 50 // 每次检查间隔50ms
      let attempts = 0
      
      while (attempts < maxAttempts) {
        // 根据选择的表格检查对应的容器
        const containers = {}
        
        if (selectedCharts.value.includes('waterLevel')) {
          containers.waterLevel = document.getElementById('water-level-chart')
        }
        if (selectedCharts.value.includes('waterStorage')) {
          containers.waterStorage = document.getElementById('water-storage-chart')
        }
        if (selectedCharts.value.includes('waterInflow')) {
          containers.waterInflow = document.getElementById('water-inflow-chart')
        }
        if (selectedCharts.value.includes('waterOutflow')) {
          containers.waterOutflow = document.getElementById('water-outflow-chart')
        }
        
        // 检查所有选择的容器是否都存在
        const allContainersExist = Object.values(containers).every(container => container !== null)
        
        if (allContainersExist) {
          console.log('选择的图表容器已准备好:', Object.keys(containers))
          return true
        }
        
        console.log(`等待图表容器准备... 尝试 ${attempts + 1}/${maxAttempts}`)
        console.log('容器状态:', containers)
        
        // 等待一段时间后再次检查
        await new Promise(resolve => setTimeout(resolve, interval))
        attempts++
      }
      
      console.warn('等待图表容器超时，强制初始化')
      return false
    }

    // 清理被删除的环境统计图表实例
    const cleanupRemovedEnvironmentCharts = (oldCharts, newCharts) => {
      console.log('清理被删除的环境统计图表实例:', { old: oldCharts, new: newCharts })
      
      // 找出被删除的图表
      const removedCharts = oldCharts.filter(chart => !newCharts.includes(chart))
      console.log('被删除的环境统计图表:', removedCharts)
      
      // 清理被删除的图表实例
      removedCharts.forEach(chartType => {
        const chartId = getEnvironmentChartId(chartType)
        const chartElement = document.getElementById(chartId)
        
        if (chartElement) {
          // 清空图表容器内容
          chartElement.innerHTML = ''
          console.log(`已清理环境统计图表容器: ${chartId}`)
        }
      })
    }

    // 清理被删除的环境对比图表实例
    const cleanupRemovedEnvironmentComparisonCharts = (oldCharts, newCharts) => {
      console.log('清理被删除的环境对比图表实例:', { old: oldCharts, new: newCharts })
      
      // 找出被删除的图表
      const removedCharts = oldCharts.filter(chart => !newCharts.includes(chart))
      console.log('被删除的环境对比图表:', removedCharts)
      
      // 清理被删除的图表实例
      removedCharts.forEach(chartType => {
        const chartId = getEnvironmentComparisonChartId(chartType)
        const chartElement = document.getElementById(chartId)
        
        if (chartElement) {
          // 清空图表容器内容
          chartElement.innerHTML = ''
          console.log(`已清理环境对比图表容器: ${chartId}`)
        }
      })
    }

    // 获取环境统计图表ID
    const getEnvironmentChartId = (chartType) => {
      const chartIdMap = {
        'ammoniaNitrogen': 'ammonia-nitrogen-chart',
        'permanganateIndex': 'permanganate-index-chart',
        'cod': 'cod-chart',
        'flow': 'flow-chart',
        'depth': 'depth-chart',
        'totalNitrogen': 'total-nitrogen-chart',
        'totalPhosphorus': 'total-phosphorus-chart'
      }
      return chartIdMap[chartType] || chartType
    }

    // 获取环境对比图表ID
    const getEnvironmentComparisonChartId = (chartType) => {
      const chartIdMap = {
        'ammoniaNitrogen': 'environment-ammonia-nitrogen-chart',
        'permanganateIndex': 'environment-permanganate-index-chart',
        'cod': 'environment-cod-chart',
        'flow': 'environment-flow-chart',
        'depth': 'environment-depth-chart',
        'totalNitrogen': 'environment-total-nitrogen-chart',
        'totalPhosphorus': 'environment-total-phosphorus-chart'
      }
      return chartIdMap[chartType] || chartType
    }

    // 渲染选择的环境统计图表
    const renderSelectedEnvironmentCharts = async () => {
      console.log('开始渲染选择的环境统计图表:', {
        selectedCharts: selectedEnvironmentCharts.value,
        selectedMonitorPoint: selectedMonitorPoint.value,
        selectedEnvDateRange: selectedEnvDateRange.value,
        totalDataCount: environmentDataList.value.length
      })

      // 等待DOM更新完成
      await nextTick()

      // 根据选择的指标渲染对应的图表
      for (const chartType of selectedEnvironmentCharts.value) {
        const chartId = getEnvironmentChartId(chartType)
        const chartElement = document.getElementById(chartId)
        
        if (chartElement) {
          console.log(`渲染环境统计图表: ${chartType}, 容器ID: ${chartId}`)
          
          // 渲染实际的ECharts图表
          await renderEnvironmentChart(chartType, chartId)
        } else {
          console.warn(`环境统计图表容器未找到: ${chartId}`)
        }
      }
    }

    // 渲染选择的环境对比图表
    const renderSelectedEnvironmentComparisonCharts = async () => {
      console.log('开始渲染选择的环境对比图表:', {
        selectedCharts: selectedEnvironmentComparisonCharts.value,
        selectedMonitorPoints: selectedMonitorPoints.value,
        selectedEnvComparisonDateRange: selectedEnvComparisonDateRange.value,
        comparisonEnvironmentIndicator: comparisonEnvironmentIndicator.value,
        totalDataCount: environmentDataList.value.length
      })

      // 等待DOM更新完成
      await nextTick()

      // 根据选择的图表类型渲染对应的图表
      for (const chartType of selectedEnvironmentComparisonCharts.value) {
        const chartId = getEnvironmentComparisonChartId(chartType)
        const chartElement = document.getElementById(chartId)
        
        if (chartElement) {
          console.log(`渲染环境对比图表: ${chartType}, 容器ID: ${chartId}`)
          
          // 渲染实际的对比图表
          await renderEnvironmentComparisonChart(chartType, chartId)
        } else {
          console.warn(`环境对比图表容器未找到: ${chartId}`)
        }
      }
    }

    // 获取环境统计图表标题
    const getEnvironmentChartTitle = (chartType) => {
      const titleMap = {
        'ammoniaNitrogen': '氨氮指标分布',
        'permanganateIndex': '高锰酸盐指标分布',
        'cod': '化学需氧量指标分布',
        'flow': '流量指标分布',
        'depth': '水深指标分布',
        'totalNitrogen': '总氮指标分布',
        'totalPhosphorus': '总磷指标分布'
      }
      return titleMap[chartType] || chartType
    }

    // 获取环境对比图表标题
    const getEnvironmentComparisonChartTitle = (chartType) => {
      const titleMap = {
        'ammoniaNitrogen': '氨氮指标对比分析',
        'permanganateIndex': '高锰酸盐指标对比分析',
        'cod': '化学需氧量指标对比分析',
        'flow': '流量指标对比分析',
        'depth': '水深指标对比分析',
        'totalNitrogen': '总氮指标对比分析',
        'totalPhosphorus': '总磷指标对比分析'
      }
      return titleMap[chartType] || chartType
    }

    // 渲染环境对比图表
    const renderEnvironmentComparisonChart = async (chartType, chartId) => {
      try {
        // 获取环境数据
        if (!selectedMonitorPoints.value || selectedMonitorPoints.value.length < 2 || 
            !selectedEnvComparisonDateRange.value || selectedEnvComparisonDateRange.value.length !== 2) {
          console.warn('环境对比图表渲染失败：缺少必要的选择参数')
          return
        }

        // 从监测断面管理页面获取环境数据
        const envResponse = await axios.get('/api/sectionMonitor/list', {
          params: { page: 1, pageSize: 10000 }
        })
        
        const envData = envResponse.data.list || []
        const [startMonth, endMonth] = selectedEnvComparisonDateRange.value
        
        // 过滤指定月份范围内的数据
        const dateRangeData = envData.filter(item => {
          const itemMonth = `${item.year}-${String(item.month).padStart(2, '0')}`
          return itemMonth >= startMonth && itemMonth <= endMonth
        })

        console.log('环境对比图表数据过滤结果:', {
          totalData: envData.length,
          selectedMonitorPoints: selectedMonitorPoints.value,
          dateRange: [startMonth, endMonth],
          filteredData: dateRangeData.length,
          sampleData: dateRangeData.slice(0, 3)
        })

        if (dateRangeData.length === 0) {
          console.warn('环境对比图表渲染失败：没有找到符合条件的数据')
          return
        }

        console.log(`渲染${getEnvironmentComparisonChartTitle(chartType)}对比图表，数据条数: ${dateRangeData.length}`)

        // 根据图表类型准备数据
        let chartData = []
        let yAxisName = ''
        let unit = ''

        switch (chartType) {
          case 'ammoniaNitrogen':
            chartData = selectedMonitorPoints.value.map(monitorPoint => {
              const pointData = dateRangeData.filter(item => item.monitorPointName === monitorPoint)
              return {
                name: monitorPoint,
                data: pointData.map(item => ({
                  date: `${item.year}-${String(item.month).padStart(2, '0')}`,
                  value: Number(item.oxygen) || 0
                }))
              }
            })
            yAxisName = '氨氮含量'
            unit = 'mg/L'
            break
          case 'permanganateIndex':
            chartData = selectedMonitorPoints.value.map(monitorPoint => {
              const pointData = dateRangeData.filter(item => item.monitorPointName === monitorPoint)
              return {
                name: monitorPoint,
                data: pointData.map(item => ({
                  date: `${item.year}-${String(item.month).padStart(2, '0')}`,
                  value: Number(item.potassiumPermanganate) || 0
                }))
              }
            })
            yAxisName = '高锰酸盐指数'
            unit = 'mg/L'
            break
          case 'cod':
            chartData = selectedMonitorPoints.value.map(monitorPoint => {
              const pointData = dateRangeData.filter(item => item.monitorPointName === monitorPoint)
              return {
                name: monitorPoint,
                data: pointData.map(item => ({
                  date: `${item.year}-${String(item.month).padStart(2, '0')}`,
                  value: Number(item.cod) || 0
                }))
              }
            })
            yAxisName = '化学需氧量'
            unit = 'mg/L'
            break
          case 'flow':
            chartData = selectedMonitorPoints.value.map(monitorPoint => {
              const pointData = dateRangeData.filter(item => item.monitorPointName === monitorPoint)
              return {
                name: monitorPoint,
                data: pointData.map(item => ({
                  date: `${item.year}-${String(item.month).padStart(2, '0')}`,
                  value: Number(item.flow) || 0
                }))
              }
            })
            yAxisName = '流量'
            unit = 'm³/s'
            break
          case 'depth':
            chartData = selectedMonitorPoints.value.map(monitorPoint => {
              const pointData = dateRangeData.filter(item => item.monitorPointName === monitorPoint)
              return {
                name: monitorPoint,
                data: pointData.map(item => ({
                  date: `${item.year}-${String(item.month).padStart(2, '0')}`,
                  value: Number(item.waterDepth) || 0
                }))
              }
            })
            yAxisName = '水深'
            unit = 'm'
            break
          case 'totalNitrogen':
            chartData = selectedMonitorPoints.value.map(monitorPoint => {
              const pointData = dateRangeData.filter(item => item.monitorPointName === monitorPoint)
              return {
                name: monitorPoint,
                data: pointData.map(item => ({
                  date: `${item.year}-${String(item.month).padStart(2, '0')}`,
                  value: Number(item.totalNitrogen) || 0
                }))
              }
            })
            yAxisName = '总氮'
            unit = 'mg/L'
            break
          case 'totalPhosphorus':
            chartData = selectedMonitorPoints.value.map(monitorPoint => {
              const pointData = dateRangeData.filter(item => item.monitorPointName === monitorPoint)
              return {
                name: monitorPoint,
                data: pointData.map(item => ({
                  date: `${item.year}-${String(item.month).padStart(2, '0')}`,
                  value: Number(item.totalPhosphorus) || 0
                }))
              }
            })
            yAxisName = '总磷'
            unit = 'mg/L'
            break
          default:
            console.warn(`未知的环境对比图表类型: ${chartType}`)
            return
        }

        // 按月份排序并去重
        const allDates = [...new Set(dateRangeData.map(item => `${item.year}-${String(item.month).padStart(2, '0')}`))]
        allDates.sort()

        // 创建ECharts图表
        const chart = echarts.init(document.getElementById(chartId))
        
        const option = {
          title: {
            text: `${getEnvironmentComparisonChartTitle(chartType)}（${startMonth} 至 ${endMonth}）`,
            left: 'center',
            textStyle: {
              fontSize: 16,
              fontWeight: 'bold'
            }
          },
          tooltip: {
            trigger: 'axis',
            formatter: function(params) {
              let result = `${params[0].name}<br/>`
              params.forEach(param => {
                result += `${param.seriesName}: ${param.value} ${unit}<br/>`
              })
              return result
            }
          },
          legend: {
            data: selectedMonitorPoints.value,
            top: '10%'
          },
          xAxis: {
            type: 'category',
            data: allDates,
            axisLabel: {
              rotate: 45
            }
          },
          yAxis: {
            type: 'value',
            name: yAxisName,
            nameLocation: 'middle',
            nameGap: 50,
            axisLabel: {
              formatter: `{value} ${unit}`
            }
          },
          series: chartData.map((pointData, index) => ({
            name: pointData.name,
            type: 'line',
            data: allDates.map(date => {
              const dataPoint = pointData.data.find(item => item.date === date)
              return dataPoint ? dataPoint.value : 0
            }),
            smooth: true,
            lineStyle: {
              width: 3
            },
            itemStyle: {
              color: getComparisonChartColor(index)
            }
          })),
          grid: {
            left: '10%',
            right: '10%',
            bottom: '15%',
            top: '20%'
          }
        }

        chart.setOption(option)
        console.log(`${getEnvironmentComparisonChartTitle(chartType)}对比图表渲染完成`)

      } catch (error) {
        console.error(`渲染环境对比图表失败: ${chartType}`, error)
        // 显示错误信息
        const chartElement = document.getElementById(chartId)
        if (chartElement) {
          chartElement.innerHTML = `
            <div style="display: flex; align-items: center; justify-content: center; height: 100%; color: #f56c6c;">
              <div style="text-align: center;">
                <h4>${getEnvironmentComparisonChartTitle(chartType)}</h4>
                <p>图表渲染失败，请重试</p>
                <p style="font-size: 12px; color: #999;">${error.message}</p>
              </div>
            </div>
          `
        }
      }
    }

    // 获取对比图表的颜色
    const getComparisonChartColor = (index) => {
      const colors = [
        '#E74C3C', '#9B59B6', '#F39C12', '#3498DB', 
        '#1ABC9C', '#2ECC71', '#E67E22', '#95A5A6'
      ]
      return colors[index % colors.length]
    }

    // 渲染环境统计图表
    const renderEnvironmentChart = async (chartType, chartId) => {
      try {
        // 获取环境数据
        if (!selectedMonitorPoint.value || !selectedEnvDateRange.value || selectedEnvDateRange.value.length !== 2) {
          console.warn('环境统计图表渲染失败：缺少必要的选择参数')
          return
        }

        // 从监测断面管理页面获取环境数据
        const envResponse = await axios.get('/api/sectionMonitor/list', {
          params: { page: 1, pageSize: 10000 }
        })
        
        const envData = envResponse.data.list || []
        const [startMonth, endMonth] = selectedEnvDateRange.value
        
        // 过滤指定月份范围内的数据
        const dateRangeData = envData.filter(item => {
          const itemMonth = `${item.year}-${String(item.month).padStart(2, '0')}`
          return item.monitorPointName === selectedMonitorPoint.value &&
                 itemMonth >= startMonth &&
                 itemMonth <= endMonth
        })

        console.log('环境统计图表数据过滤结果:', {
          totalData: envData.length,
          selectedMonitorPoint: selectedMonitorPoint.value,
          dateRange: [startMonth, endMonth],
          filteredData: dateRangeData.length,
          sampleData: dateRangeData.slice(0, 3)
        })

        if (dateRangeData.length === 0) {
          console.warn('环境统计图表渲染失败：没有找到符合条件的数据')
          return
        }

        console.log(`渲染${getEnvironmentChartTitle(chartType)}图表，数据条数: ${dateRangeData.length}`)

        // 根据图表类型准备数据和颜色配置
        let chartData = []
        let yAxisName = ''
        let unit = ''
        let chartColors = {}

        switch (chartType) {
          case 'ammoniaNitrogen':
            chartData = dateRangeData.map(item => ({
              date: `${item.year}-${String(item.month).padStart(2, '0')}`,
              value: Number(item.oxygen) || 0
            }))
            yAxisName = '氨氮含量'
            unit = 'mg/L'
            chartColors = {
              lineColor: '#E74C3C',      // 红色
              areaStartColor: 'rgba(231, 76, 60, 0.4)',
              areaEndColor: 'rgba(231, 76, 60, 0.1)'
            }
            break
          case 'permanganateIndex':
            chartData = dateRangeData.map(item => ({
              date: `${item.year}-${String(item.month).padStart(2, '0')}`,
              value: Number(item.potassiumPermanganate) || 0
            }))
            yAxisName = '高锰酸盐指数'
            unit = 'mg/L'
            chartColors = {
              lineColor: '#9B59B6',      // 紫色
              areaStartColor: 'rgba(155, 89, 182, 0.4)',
              areaEndColor: 'rgba(155, 89, 182, 0.1)'
            }
            break
          case 'cod':
            chartData = dateRangeData.map(item => ({
              date: `${item.year}-${String(item.month).padStart(2, '0')}`,
              value: Number(item.cod) || 0
            }))
            yAxisName = '化学需氧量'
            unit = 'mg/L'
            chartColors = {
              lineColor: '#F39C12',      // 橙色
              areaStartColor: 'rgba(243, 156, 18, 0.4)',
              areaEndColor: 'rgba(243, 156, 18, 0.1)'
            }
            break
          case 'flow':
            chartData = dateRangeData.map(item => ({
              date: `${item.year}-${String(item.month).padStart(2, '0')}`,
              value: Number(item.flow) || 0
            }))
            yAxisName = '流量'
            unit = 'm³/s'
            chartColors = {
              lineColor: '#3498DB',      // 蓝色
              areaStartColor: 'rgba(52, 152, 219, 0.4)',
              areaEndColor: 'rgba(52, 152, 219, 0.1)'
            }
            break
          case 'depth':
            chartData = dateRangeData.map(item => ({
              date: `${item.year}-${String(item.month).padStart(2, '0')}`,
              value: Number(item.waterDepth) || 0
            }))
            yAxisName = '水深'
            unit = 'm'
            chartColors = {
              lineColor: '#1ABC9C',      // 青色
              areaStartColor: 'rgba(26, 188, 156, 0.4)',
              areaEndColor: 'rgba(26, 188, 156, 0.1)'
            }
            break
          case 'totalNitrogen':
            chartData = dateRangeData.map(item => ({
              date: `${item.year}-${String(item.month).padStart(2, '0')}`,
              value: Number(item.totalNitrogen) || 0
            }))
            yAxisName = '总氮'
            unit = 'mg/L'
            chartColors = {
              lineColor: '#2ECC71',      // 绿色
              areaStartColor: 'rgba(46, 204, 113, 0.4)',
              areaEndColor: 'rgba(46, 204, 113, 0.1)'
            }
            break
          case 'totalPhosphorus':
            chartData = dateRangeData.map(item => ({
              date: `${item.year}-${String(item.month).padStart(2, '0')}`,
              value: Number(item.totalPhosphorus) || 0
            }))
            yAxisName = '总磷'
            unit = 'mg/L'
            chartColors = {
              lineColor: '#E67E22',      // 深橙色
              areaStartColor: 'rgba(230, 126, 34, 0.4)',
              areaEndColor: 'rgba(230, 126, 34, 0.1)'
            }
            break
          default:
            console.warn(`未知的环境统计图表类型: ${chartType}`)
            return
        }

        // 按月份排序
        chartData.sort((a, b) => a.date.localeCompare(b.date))

        // 创建ECharts图表
        const chart = echarts.init(document.getElementById(chartId))
        
        const option = {
          title: {
            text: `${selectedMonitorPoint.value}${getEnvironmentChartTitle(chartType)}（${startMonth} 至 ${endMonth}）`,
            left: 'center',
            textStyle: {
              fontSize: 16,
              fontWeight: 'bold'
            }
          },
          tooltip: {
            trigger: 'axis',
            formatter: function(params) {
              const data = params[0]
              return `${data.name}<br/>${yAxisName}: ${data.value} ${unit}`
            }
          },
          xAxis: {
            type: 'category',
            data: chartData.map(item => item.date),
            axisLabel: {
              rotate: 45
            }
          },
          yAxis: {
            type: 'value',
            name: yAxisName,
            nameLocation: 'middle',
            nameGap: 50,
            axisLabel: {
              formatter: `{value} ${unit}`
            }
          },
          series: [{
            name: yAxisName,
            type: 'line',
            data: chartData.map(item => item.value),
            smooth: true,
            lineStyle: {
              width: 3,
              color: chartColors.lineColor
            },
            itemStyle: {
              color: chartColors.lineColor
            },
            areaStyle: {
              color: {
                type: 'linear',
                x: 0, y: 0, x2: 0, y2: 1,
                colorStops: [{
                  offset: 0, color: chartColors.areaStartColor
                }, {
                  offset: 1, color: chartColors.areaEndColor
                }]
              }
            }
          }],
          grid: {
            left: '10%',
            right: '10%',
            bottom: '15%',
            top: '15%'
          }
        }

        chart.setOption(option)
        console.log(`${getEnvironmentChartTitle(chartType)}图表渲染完成`)

      } catch (error) {
        console.error(`渲染环境统计图表失败: ${chartType}`, error)
        // 显示错误信息
        const chartElement = document.getElementById(chartId)
        if (chartElement) {
          chartElement.innerHTML = `
            <div style="display: flex; align-items: center; justify-content: center; height: 100%; color: #f56c6c;">
              <div style="text-align: center;">
                <h4>${getEnvironmentChartTitle(chartType)}</h4>
                <p>图表渲染失败，请重试</p>
                <p style="font-size: 12px; color: #999;">${error.message}</p>
              </div>
            </div>
          `
        }
      }
    }
    
    // 组件卸载时清理图表实例
    onUnmounted(() => {
      console.log('组件卸载，清理图表实例')
      
      // 清理图表实例
      if (waterLevelChart) {
        try {
          // 检查图表实例是否仍然有效
          if (waterLevelChart.getDom && waterLevelChart.getDom()) {
            waterLevelChart.dispose()
          }
        } catch (error) {
          console.warn('清理水位图表时出错:', error)
        }
        waterLevelChart = null
      }
      
      if (waterStorageChart) {
        try {
          if (waterStorageChart.getDom && waterStorageChart.getDom()) {
            waterStorageChart.dispose()
          }
        } catch (error) {
          console.warn('清理蓄水量图表时出错:', error)
        }
        waterStorageChart = null
      }

      if (waterInflowChart) {
        try {
          if (waterInflowChart.getDom && waterInflowChart.getDom()) {
            waterInflowChart.dispose()
          }
        } catch (error) {
          console.warn('清理入库流量图表时出错:', error)
        }
        waterInflowChart = null
      }

      if (waterOutflowChart) {
        try {
          if (waterOutflowChart.getDom && waterOutflowChart.getDom()) {
            waterOutflowChart.dispose()
          }
        } catch (error) {
          console.warn('清理出库流量图表时出错:', error)
        }
        waterOutflowChart = null
      }
      
      if (waterComparisonChart) {
        try {
          // 检查图表实例是否仍然有效
          if (waterComparisonChart.getDom && waterComparisonChart.getDom()) {
            waterComparisonChart.dispose()
          }
        } catch (error) {
          console.warn('清理水库对比图表时出错:', error)
        }
        waterComparisonChart = null
      }
      
      if (waterQualityChart) {
        try {
          // 检查图表实例是否仍然有效
          if (waterQualityChart.getDom && waterQualityChart.getDom()) {
            waterQualityChart.dispose()
          }
        } catch (error) {
          console.warn('清理水质图表时出错:', error)
        }
        waterQualityChart = null
      }
      
      if (environmentComparisonChart) {
        try {
          // 检查图表实例是否仍然有效
          if (environmentComparisonChart.getDom && environmentComparisonChart.getDom()) {
            environmentComparisonChart.dispose()
          }
        } catch (error) {
          console.warn('清理环境对比图表时出错:', error)
        }
        environmentComparisonChart = null
      }
      
      // 清理水情对比图表实例
      if (waterLevelComparisonChart) {
        try {
          if (waterLevelComparisonChart.getDom && waterLevelComparisonChart.getDom()) {
            waterLevelComparisonChart.dispose()
          }
        } catch (error) {
          console.warn('清理水库水位对比图表时出错:', error)
        }
        waterLevelComparisonChart = null
      }
      
      if (waterStorageComparisonChart) {
        try {
          if (waterStorageComparisonChart.getDom && waterStorageComparisonChart.getDom()) {
            waterStorageComparisonChart.dispose()
          }
        } catch (error) {
          console.warn('清理水库蓄水量对比图表时出错:', error)
        }
        waterStorageComparisonChart = null
      }
      
      if (waterInflowComparisonChart) {
        try {
          if (waterInflowComparisonChart.getDom && waterInflowComparisonChart.getDom()) {
            waterInflowComparisonChart.dispose()
          }
        } catch (error) {
          console.warn('清理入库流量对比图表时出错:', error)
        }
        waterInflowComparisonChart = null
      }
      
      if (waterOutflowComparisonChart) {
        try {
          if (waterOutflowComparisonChart.getDom && waterOutflowComparisonChart.getDom()) {
            waterOutflowComparisonChart.dispose()
          }
        } catch (error) {
          console.warn('清理出库流量对比图表时出错:', error)
        }
        waterOutflowComparisonChart = null
      }
      
      // 不要清空响应式数据，只清理图表实例
      // 这样可以保持数据在面板切换时的持久性
      console.log('图表实例清理完成，数据保持持久化')
    })
    
    return {
      activeBox,
      selectedReservoir,
      selectedDate,
      selectedDateRange,
      selectedReservoirs,
      selectedComparisonDateRange,
      selectedComparisonCharts,
      selectedCharts,
      selectedEnvironmentCharts,
      selectedEnvironmentComparisonCharts,
      comparisonMonitorPoint1,
      comparisonMonitorPoint2,
      comparisonEnvironmentIndicator,
      selectedMonitorPoints,
      waterStats,
      environmentStats,
      reservoirList,
      monitorPointList,
      disableUnavailableDates,
      disableUnavailableComparisonDates,
      applySelectedWaterStats,
      renderSelectedCharts,
      renderSelectedComparisonCharts,
      renderSelectedEnvironmentCharts,
      renderSelectedEnvironmentComparisonCharts,
      refreshWaterData,
      refreshEnvironmentData,
      refreshComparisonData,
      refreshEnvironmentComparison,
      selectedMonitorPoint,
      selectedEnvMonth,
      selectedEnvDateRange,
      selectedEnvComparisonDateRange,
      disableUnavailableEnvMonths,
      disableUnavailableEnvDates,
      disableUnavailableEnvComparisonDates,
      applySelectedEnvironmentStats,
      updateSelectedEnvironmentComparisonStats,
      envDisplayStats,
      formatNumber,
      getWaterLevelChartTitle,
      getWaterStorageChartTitle,
      getWaterInflowChartTitle,
      getWaterOutflowChartTitle
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
  background: #f5f5f5;
  min-height: 100vh;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  padding: 20px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.panel-header h2 {
  margin: 0;
  color: #333;
  font-size: 1.8rem;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.header-actions .el-select {
  min-width: 200px;
}

.header-actions .el-date-picker {
  min-width: 280px;
}

/* 表格选择器样式优化 */
.header-actions .el-select[data-chart-selector] {
  background: #f8f9fa;
  border: 1px solid #e9ecef;
}

.header-actions .el-select[data-chart-selector] .el-input__inner {
  background: transparent;
}

.statistics-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

/* 水情统计圆形卡片样式 */
.water-statistics-cards {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1.5rem;
  margin-bottom: 2rem;
  padding: 20px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  flex-wrap: wrap;
}

.water-stat-circle {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-width: 0;
}

.stat-circle-bg {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 1rem;
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);
  position: relative;
}

.water-stat-circle:nth-child(1) .stat-circle-bg {
  background: #b8d4f0;
}

.water-stat-circle:nth-child(2) .stat-circle-bg {
  background: #d4b8e8;
}

.water-stat-circle:nth-child(3) .stat-circle-bg {
  background: #b8d8f0;
}

.water-stat-circle:nth-child(4) .stat-circle-bg {
  background: #b8e8d4;
}

.water-stat-circle:nth-child(5) .stat-circle-bg {
  background: #e8d4b8;
}

.water-stat-circle:nth-child(6) .stat-circle-bg {
  background: #d4b8e8;
}

/* 环境统计圆形卡片样式 */
.environment-statistics-cards {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1.5rem;
  margin-bottom: 2rem;
  padding: 20px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  flex-wrap: wrap;
}

.environment-stat-circle {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-width: 0;
  min-width: 140px;
}

.environment-stat-circle .stat-circle-bg {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 1rem;
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);
  position: relative;
}

.environment-stat-circle:nth-child(1) .stat-circle-bg {
  background: #f0b8b8;
}

.environment-stat-circle:nth-child(2) .stat-circle-bg {
  background: #b8e8e0;
}

.environment-stat-circle:nth-child(3) .stat-circle-bg {
  background: #e8b8d4;
}

.environment-stat-circle:nth-child(4) .stat-circle-bg {
  background: #b8d4f0;
}

.environment-stat-circle:nth-child(5) .stat-circle-bg {
  background: #e8b8e8;
}

.environment-stat-circle:nth-child(6) .stat-circle-bg {
  background: #b8c8f0;
}

.environment-stat-circle:nth-child(7) .stat-circle-bg {
  background: #b8e8b8;
}

.stat-circle-value {
  font-size: 1.8rem;
  font-weight: bold;
  color: white;
  text-shadow: 0 2px 4px rgba(0,0,0,0.3);
  white-space: nowrap;
  text-align: center;
}

.stat-circle-label {
  font-size: 0.9rem;
  color: #666;
  text-align: center;
  line-height: 1.3;
  max-width: 120px;
  word-wrap: break-word;
}

.stat-circle-label .unit-text {
  font-size: 0.8rem;
  color: #999;
  margin-top: 0.2rem;
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
  border: 1px solid #e9ecef;
  border-left: 4px solid #ddd;
  transition: all 0.3s ease;
}

.chart-container:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.15);
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

/* 环境统计图表彩色边框样式 */
.ammonia-nitrogen-chart {
  border-left-color: #E74C3C !important; 
}

.permanganate-index-chart {
  border-left-color: #9B59B6 !important;
}

.cod-chart {
  border-left-color: #F39C12 !important;
}

.flow-chart {
  border-left-color: #3498DB !important;
}

.depth-chart {
  border-left-color: #1ABC9C !important;
}

.total-nitrogen-chart {
  border-left-color: #2ECC71 !important;
}

.total-phosphorus-chart {
  border-left-color: #E67E22 !important;
}

/* 环境对比图表彩色边框样式 */
.environment-ammonia-nitrogen-chart {
  border-left-color: #E74C3C !important;
}

.environment-permanganate-index-chart {
  border-left-color: #9B59B6 !important;
}

.environment-cod-chart {
  border-left-color: #F39C12 !important;
}

.environment-flow-chart {
  border-left-color: #3498DB !important;
}

.environment-depth-chart {
  border-left-color: #1ABC9C !important;
}

.environment-total-nitrogen-chart {
  border-left-color: #2ECC71 !important;
}

.environment-total-phosphorus-chart {
  border-left-color: #E67E22 !important;
}



.chart-selection-tip {
  background: white;
  border-radius: 8px;
  padding: 3rem 1.5rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  margin-bottom: 2rem;
  border: 1px solid #e9ecef;
  text-align: center;
}

.tip-content p {
  margin: 0.5rem 0;
  color: #666;
  font-size: 1rem;
}

.tip-content p:first-child {
  font-weight: 500;
  color: #333;
}

.water-statistics-panel,
.water-comparison-panel,
.environment-statistics-panel,
.environment-comparison-panel {
  height: 100%;
  overflow: auto;
  margin-bottom: 20px;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .statistics-cards {
    grid-template-columns: 1fr;
  }
  
  .water-statistics-cards {
    flex-direction: column;
    gap: 1.5rem;
  }
  
  .environment-statistics-cards {
    flex-direction: column;
    gap: 1rem;
  }
  
  .water-stat-circle .stat-circle-bg {
    width: 100px;
    height: 100px;
  }
  
  .environment-stat-circle .stat-circle-bg {
    width: 80px;
    height: 80px;
  }
  
  .stat-circle-value {
    font-size: 1.5rem;
  }
  
  .stat-circle-label {
    font-size: 0.8rem;
    max-width: 100px;
  }
  
  .environment-stat-circle {
    min-width: 120px;
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
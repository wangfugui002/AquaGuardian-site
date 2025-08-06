<template>
  <div class="river-simulation-panel" v-if="panelVisible">
    <div class="panel-header">
      <h3>河流污染扩散模拟</h3>
      <button @click="togglePanel" class="close-btn">×</button>
    </div>
    
    <div class="panel-content">
      <!-- 步骤1: 选择河流 -->
      <div class="step-section">
        <h4>1. 选择河流</h4>
        <div class="river-selection">
          <div class="selection-info">
            <p v-if="!selectedRiver" class="selection-hint">
              💡 请点击地图上的河流线条来选择河流
            </p>
            <p v-else class="selected-river">
              ✅ 已选择: <strong>{{ selectedRiverName }}</strong>
            </p>
          </div>
          <button @click="clearRiverSelection" class="clear-btn" v-if="selectedRiver">
            清除选择
          </button>
        </div>
      </div>

      <!-- 步骤2: 选择污染源位置 -->
      <div class="step-section">
        <h4>2. 选择污染源位置</h4>
        <div class="pollution-source-selection">
          <div class="selection-info">
            <p v-if="!selectedRiver" class="selection-hint">
              ⚠️ 请先选择河流
            </p>
            <p v-else-if="!pollutionSourcePosition" class="selection-hint">
              💡 请点击河流上的任意位置来设置污染源起始点
            </p>
            <p v-else class="selected-source">
              ✅ 污染源位置: <strong>{{ pollutionSourcePosition?.lat?.toFixed(6) || '0.000000' }}, {{ pollutionSourcePosition?.lng?.toFixed(6) || '0.000000' }}</strong>
            </p>
          </div>
          <button @click="clearPollutionSource" class="clear-btn" v-if="pollutionSourcePosition">
            重新选择
          </button>
        </div>
      </div>

      <!-- 步骤3: 设置污染物参数 -->
      <div class="step-section">
        <h4>3. 设置污染物参数</h4>
        <div class="param-group">
          <label>污染物类型:</label>
          <select v-model="pollutantType" @change="onPollutantChange" class="form-select">
            <option v-for="item in pollutantOptions" :key="item.value" :value="item.value">
              {{ item.label }}
            </option>
          </select>
        </div>
        <div class="param-group">
          <label>污染物质量 (kg):</label>
          <input type="number" v-model="pollutantMass" min="0.1" max="10000" step="0.1" class="form-input">
        </div>
        <div class="param-group">
          <label>衰减系数 (d⁻¹):</label>
          <input type="number" v-model="decayRate" min="0" max="10" step="0.001" class="form-input">
        </div>
      </div>

      <!-- 步骤4: 设置河流参数 -->
      <div class="step-section">
        <h4>4. 设置河流参数</h4>
        <div class="param-group">
          <label>河流宽度 (m):</label>
          <input type="number" v-model="riverWidth" min="1" max="500" step="1" class="form-input">
        </div>
        <div class="param-group">
          <label>河流深度 (m):</label>
          <input type="number" v-model="riverDepth" min="0.5" max="20" step="0.1" class="form-input">
        </div>
        <div class="param-group">
          <label>流速 (m/s):</label>
          <input type="number" v-model="flowVelocity" min="0.1" max="10" step="0.1" class="form-input">
        </div>
        <div class="param-group">
          <label>纵向弥散系数 (m²/s):</label>
          <input type="number" v-model="longitudinalDiffusion" min="0.1" max="100" step="0.1" class="form-input">
        </div>
        <div class="param-group">
          <label>横向弥散系数 (m²/s):</label>
          <input type="number" v-model="transverseDiffusion" min="0.1" max="100" step="0.1" class="form-input">
        </div>
      </div>

      <!-- 步骤5: 设置模拟参数 -->
      <div class="step-section">
        <h4>5. 设置模拟参数</h4>
        <div class="param-group">
          <label>网格间距 (m):</label>
          <input type="number" v-model="gridSpacing" min="5" max="100" step="5" class="form-input">
        </div>
        <div class="param-group">
          <label>模拟时长 (小时):</label>
          <input type="number" v-model="simulationHours" min="0.5" max="24" step="0.5" class="form-input">
        </div>
        <div class="param-group">
          <label>时间步长 (分钟):</label>
          <input type="number" v-model="timeStep" min="1" max="60" step="1" class="form-input">
        </div>
      </div>

      <!-- 操作按钮 -->
      <div class="action-buttons">
        <button @click="generateGrid" :disabled="!selectedRiver || !pollutionSourcePosition || gridLoading" class="btn btn-primary">
          {{ gridLoading ? '生成中...' : '生成网格' }}
        </button>
        <button @click="startSimulation" :disabled="!gridGenerated || simulationLoading" class="btn btn-success">
          {{ simulationLoading ? '计算中...' : '开始模拟' }}
        </button>
        <button @click="clearSimulation" class="btn btn-warning">清除模拟</button>
      </div>

      <!-- 进度条 -->
      <div v-if="gridLoading || simulationLoading" class="progress-section">
        <div class="progress">
          <div class="progress-bar" :style="{ width: progressPercentage + '%' }"></div>
        </div>
        <p class="progress-text">{{ progressText }}</p>
      </div>

      <!-- 时间控制 -->
      <div v-if="simulationResult" class="time-control">
        <h4>时间控制</h4>
        <div class="time-control-buttons">
          <button @click="togglePlayPause" class="play-pause-btn" :class="{ 'playing': isPlaying }">
            {{ isPlaying ? '⏸️ 暂停' : '▶️ 播放' }}
          </button>
          <button @click="resetAnimation" class="reset-btn">🔄 重置</button>
        </div>
        <div class="speed-control">
          <label>播放速度: {{ speedMultiplier.toFixed(1) }}x</label>
          <div class="speed-buttons">
            <button @click="changeSpeed(0.1)" class="speed-btn" :class="{ 'active': speedMultiplier === 0.1 }">0.1x</button>
            <button @click="changeSpeed(0.2)" class="speed-btn" :class="{ 'active': speedMultiplier === 0.2 }">0.2x</button>
            <button @click="changeSpeed(0.5)" class="speed-btn" :class="{ 'active': speedMultiplier === 0.5 }">0.5x</button>
            <button @click="changeSpeed(1.0)" class="speed-btn" :class="{ 'active': speedMultiplier === 1.0 }">1.0x</button>
            <button @click="changeSpeed(2.0)" class="speed-btn" :class="{ 'active': speedMultiplier === 2.0 }">2.0x</button>
          </div>
        </div>
        <input 
          type="range" 
          v-model="currentTimeIndex" 
          :min="0" 
          :max="(timeSteps?.length || 1) - 1" 
          step="1" 
          @input="onTimeChange"
          class="time-slider">
        <div class="time-info">
          <span>当前时间: {{ currentTimeDisplay }}</span>
          <span>最大浓度: {{ maxConcentration.toFixed(6) }} mg/L</span>
        </div>
      </div>

      <!-- 模拟结果 -->
      <div v-if="simulationResult && simulationResult.gridPoints" class="step-section">
        <h4>模拟结果</h4>
        <div class="results-container">
          <div class="result-item">
            <h5>模拟完成</h5>
            <p>网格点数: {{ simulationResult?.gridPoints?.length || 0 }}</p>
            <p>时间步数: {{ simulationResult?.timeSteps?.length || 0 }}</p>
            <p>最大浓度: {{ simulationResult?.maxConcentration?.toFixed(6) || '0.000000' }} mg/L</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import L from 'leaflet'

export default {
  name: 'RiverPollutionSimulation',
  props: {
    map: {
      type: Object,
      required: true
    },
    'water-lines-layer': {
      type: Object,
      required: true
    }
  },
  emits: ['simulation-update'],
  setup(props, { emit }) {
    // 面板状态
    const panelVisible = ref(true)
    

    
    // 河流选择
    const selectedRiver = ref(null)
    const selectedRiverName = computed(() => {
      if (!selectedRiver.value) return ''
      return selectedRiver.value.properties?.name || 
             selectedRiver.value.properties?.NAME || 
             '未知河流'
    })
    
    // 污染源位置
    const pollutionSourcePosition = ref(null)
    const pollutionSourceMarker = ref(null)
    
    // 污染物参数
    const pollutantType = ref('organic')
    const pollutantMass = ref(100)
    const decayRate = ref(0.1)
    
    // 河流参数
    const riverWidth = ref(50)
    const riverDepth = ref(3)
    const flowVelocity = ref(1.5)
    const longitudinalDiffusion = ref(10)
    const transverseDiffusion = ref(5)
    
    // 模拟参数
    const gridSpacing = ref(20)
    const simulationHours = ref(6)
    const timeStep = ref(10)
    
    // 网格和模拟状态
    const gridLoading = ref(false)
    const simulationLoading = ref(false)
    const gridGenerated = ref(false)
    const progressPercentage = ref(0)
    const progressText = ref('')
    
    // 模拟结果
    const simulationResult = ref(null)
    const timeSteps = ref([])
    const currentTimeIndex = ref(0)
    const currentTimeDisplay = ref('')
    const maxConcentration = ref(0)
    
    // 播放控制
    const isPlaying = ref(false)
    const animationInterval = ref(null)
    const animationSpeed = ref(500) // 播放速度（毫秒），初始为500ms（0.2倍速）
    const speedMultiplier = ref(0.2) // 速度倍数
    
    // 图层引用
    const gridLayer = ref(null)
    const pollutionLayer = ref(null)
    const riverHighlightLayer = ref(null)
    
    // 河流边界
    const selectedRiverBounds = ref(null)
    const selectedRiverGeometry = ref(null)
    
    // 污染物选项
    const pollutantOptions = [
      { value: 'organic', label: '有机污染物' },
      { value: 'inorganic', label: '无机污染物' },
      { value: 'heavy_metal', label: '重金属' },
      { value: 'nutrient', label: '营养盐' },
      { value: 'pesticide', label: '农药' }
    ]
    
    // 计算是否可以开始模拟
    const canStartSimulation = computed(() => {
      return selectedRiver.value && 
             pollutionSourcePosition.value && 
             !simulationLoading.value
    })
    
    // 切换面板显示
    const togglePanel = () => {
      panelVisible.value = !panelVisible.value
    }
    

    
    // 清除河流选择
    const clearRiverSelection = () => {
      // 清除点击事件监听器
      if (props.map && props.map._riverPollutionSourceClickHandler) {
        props.map.off('click', props.map._riverPollutionSourceClickHandler)
      }
      
      selectedRiver.value = null
      selectedRiverBounds.value = null
      selectedRiverGeometry.value = null
      
      // 清除高亮图层
      if (riverHighlightLayer.value && props.map.hasLayer(riverHighlightLayer.value)) {
        props.map.removeLayer(riverHighlightLayer.value)
      }
      
      // 清除污染源
      clearPollutionSource()
      
      // 清除模拟
      clearSimulation()
    }
    
    // 清除污染源
    const clearPollutionSource = () => {
      pollutionSourcePosition.value = null
      if (pollutionSourceMarker.value) {
        props.map.removeLayer(pollutionSourceMarker.value)
        pollutionSourceMarker.value = null
      }
    }
    
    // 河流选择处理
    const onRiverSelect = (riverFeature) => {
      // 清除之前的点击事件监听器
      if (props.map && props.map._riverPollutionSourceClickHandler) {
        props.map.off('click', props.map._riverPollutionSourceClickHandler)
      }
      
      selectedRiver.value = riverFeature
      selectedRiverGeometry.value = riverFeature.geometry
      console.log('选择河流:', riverFeature.properties)
      
      // 计算河流边界
      if (riverFeature.geometry.type === 'LineString') {
        const coordinates = riverFeature.geometry.coordinates
        console.log('河流坐标数量:', coordinates.length)
        console.log('河流坐标范围:', coordinates.slice(0, 3), '...', coordinates.slice(-3))
        
        const lats = coordinates.map(coord => coord[1])
        const lngs = coordinates.map(coord => coord[0])
        
        const minLat = Math.min(...lats)
        const maxLat = Math.max(...lats)
        const minLng = Math.min(...lngs)
        const maxLng = Math.max(...lngs)
        
        console.log('坐标范围:', { minLat, maxLat, minLng, maxLng })
        
        selectedRiverBounds.value = L.latLngBounds([
          [minLat, minLng],
          [maxLat, maxLng]
        ])
        
        console.log('河流边界:', selectedRiverBounds.value)
      } else {
        console.error('河流几何类型不是LineString:', riverFeature.geometry.type)
      }
      
      // 高亮显示选中的河流
      highlightSelectedRiver(riverFeature)
      
      // 清除之前的污染源和网格
      clearPollutionSource()
      clearSimulation()
      
      // 设置污染源选择模式
      setupPollutionSourceSelection()
    }
    
    // 高亮显示选中的河流
    const highlightSelectedRiver = (feature) => {
      console.log('开始高亮河流:', feature)
      
      // 清除之前的高亮
      if (riverHighlightLayer.value && props.map.hasLayer(riverHighlightLayer.value)) {
        props.map.removeLayer(riverHighlightLayer.value)
      }
      
      // 创建高亮图层
      riverHighlightLayer.value = L.geoJSON(feature, {
        style: {
          color: '#ff6b6b',
          weight: 4,
          opacity: 1,
          fillOpacity: 0
        }
      })
      
      props.map.addLayer(riverHighlightLayer.value)
      console.log('河流高亮图层已添加')
      
      // 定位到河流边界，添加一些边距
      if (selectedRiverBounds.value) {
        const bounds = selectedRiverBounds.value
        console.log('定位到河流边界:', bounds)
        const padding = [50, 50] // 上下左右各50像素的边距
        props.map.fitBounds(bounds, { padding })
        console.log('地图已定位到河流')
      } else {
        console.error('河流边界为空，无法定位')
      }
    }
    
    // 设置污染源选择模式
    const setupPollutionSourceSelection = () => {
      console.log('设置河流污染源选择模式')
      
      // 移除之前的事件监听
      if (props.map._riverPollutionSourceClickHandler) {
        console.log('移除之前的河流污染源事件监听器')
        props.map.off('click', props.map._riverPollutionSourceClickHandler)
      }
      
      // 添加新的点击事件监听
      props.map._riverPollutionSourceClickHandler = (e) => {
        console.log('地图被点击:', e.latlng)
        const clickedPoint = e.latlng
        
        // 检查点击位置是否在河流附近（使用更大的容差便于选择）
        if (selectedRiver.value && isPointNearRiverForSelection(clickedPoint, selectedRiver.value.geometry)) {
          console.log('点击位置在河流附近，设置污染源')
          setPollutionSource(clickedPoint)
        } else {
          console.log('点击位置距离河流太远')
          alert('请点击河流附近的位置来设置污染源！')
        }
      }
      
      props.map.on('click', props.map._riverPollutionSourceClickHandler)
      console.log('河流污染源选择事件监听器已添加')
    }
    

    
    // 检查点是否在河流附近
    const isPointNearRiver = (point, riverGeometry) => {
      // 减小容差，使网格更紧密地围绕河流
      const tolerance = 0.002 // 约200米
      
      if (riverGeometry.type === 'LineString') {
        const coordinates = riverGeometry.coordinates
        
        // 优化：如果坐标点太多，进行采样以减少计算量
        const maxCoordinates = 50 // 减少到50个坐标点
        let sampledCoordinates = coordinates
        
        if (coordinates.length > maxCoordinates) {
          const step = Math.floor(coordinates.length / maxCoordinates)
          sampledCoordinates = []
          for (let i = 0; i < coordinates.length; i += step) {
            sampledCoordinates.push(coordinates[i])
          }
          // 确保包含最后一个点
          if (sampledCoordinates[sampledCoordinates.length - 1] !== coordinates[coordinates.length - 1]) {
            sampledCoordinates.push(coordinates[coordinates.length - 1])
          }
        }
        
        let minDistance = Infinity
        
        // 计算点到线段的最短距离
        for (let i = 0; i < sampledCoordinates.length - 1; i++) {
          const p1 = sampledCoordinates[i]
          const p2 = sampledCoordinates[i + 1]
          
          const distance = pointToLineDistance(
            point.lat, point.lng,
            p1[1], p1[0],
            p2[1], p2[0]
          )
          
          minDistance = Math.min(minDistance, distance)
          
          // 如果已经找到足够近的点，提前退出
          if (minDistance < tolerance * 0.3) {
            break
          }
        }
        
        return minDistance < tolerance
      }
      return false
    }
    
    // 计算点到线段的距离
    const pointToLineDistance = (px, py, x1, y1, x2, y2) => {
      const A = px - x1
      const B = py - y1
      const C = x2 - x1
      const D = y2 - y1
      
      const dot = A * C + B * D
      const lenSq = C * C + D * D
      
      if (lenSq === 0) {
        // 线段长度为0，计算点到点的距离
        return Math.sqrt((px - x1) * (px - x1) + (py - y1) * (py - y1))
      }
      
      let param = dot / lenSq
      
      let xx, yy
      if (param < 0) {
        xx = x1
        yy = y1
      } else if (param > 1) {
        xx = x2
        yy = y2
      } else {
        xx = x1 + param * C
        yy = y1 + param * D
      }
      
      const dx = px - xx
      const dy = py - yy
      return Math.sqrt(dx * dx + dy * dy)
    }
    
    // 检查点是否在河流附近（用于污染源选择，使用更大的容差）
    const isPointNearRiverForSelection = (point, riverGeometry) => {
      // 使用更大的容差，便于污染源选择
      const tolerance = 0.005 // 约500米
      
      if (riverGeometry.type === 'LineString') {
        const coordinates = riverGeometry.coordinates
        
        // 优化：如果坐标点太多，进行采样以减少计算量
        const maxCoordinates = 50
        let sampledCoordinates = coordinates
        
        if (coordinates.length > maxCoordinates) {
          const step = Math.floor(coordinates.length / maxCoordinates)
          sampledCoordinates = []
          for (let i = 0; i < coordinates.length; i += step) {
            sampledCoordinates.push(coordinates[i])
          }
          // 确保包含最后一个点
          if (sampledCoordinates[sampledCoordinates.length - 1] !== coordinates[coordinates.length - 1]) {
            sampledCoordinates.push(coordinates[coordinates.length - 1])
          }
        }
        
        let minDistance = Infinity
        
        // 计算点到线段的最短距离
        for (let i = 0; i < sampledCoordinates.length - 1; i++) {
          const p1 = sampledCoordinates[i]
          const p2 = sampledCoordinates[i + 1]
          
          const distance = pointToLineDistance(
            point.lat, point.lng,
            p1[1], p1[0],
            p2[1], p2[0]
          )
          
          minDistance = Math.min(minDistance, distance)
          
          // 如果已经找到足够近的点，提前退出
          if (minDistance < tolerance * 0.5) {
            break
          }
        }
        
        return minDistance < tolerance
      }
      return false
    }
    
    // 设置污染源
    const setPollutionSource = (position) => {
      pollutionSourcePosition.value = position
      
      // 清除之前的标记
      if (pollutionSourceMarker.value) {
        props.map.removeLayer(pollutionSourceMarker.value)
      }
      
      // 创建新的污染源标记
      pollutionSourceMarker.value = L.marker(position, {
        icon: L.divIcon({
          className: 'pollution-source-marker',
          html: '⚠️',
          iconSize: [30, 30],
          iconAnchor: [15, 15]
        })
      }).addTo(props.map)
      
      console.log('设置污染源位置:', position)
    }
    
    // 污染物类型变化处理
    const onPollutantChange = () => {
      // 根据污染物类型设置默认参数
      const defaultParams = {
        organic: { mass: 100, decay: 0.1 },
        inorganic: { mass: 50, decay: 0.05 },
        heavy_metal: { mass: 10, decay: 0.001 },
        nutrient: { mass: 200, decay: 0.2 },
        pesticide: { mass: 5, decay: 0.01 }
      }
      
      const params = defaultParams[pollutantType.value]
      if (params) {
        pollutantMass.value = params.mass
        decayRate.value = params.decay
      }
    }
    
    // 开始模拟
    const startSimulation = async () => {
      if (!gridGenerated.value) {
        alert('请先生成网格')
        return
      }
      
      simulationLoading.value = true
      progressPercentage.value = 0
      progressText.value = '正在计算扩散...'
      
      try {
        console.log('开始创建一维河流扩散模型，参数:', {
          Ex: longitudinalDiffusion.value,
          vx: flowVelocity.value,
          H: riverDepth.value,
          W: riverWidth.value,
          K1: decayRate.value / (24 * 3600),
          m: pollutantMass.value * 1000
        })
        
        // 创建一维河流扩散模型
        const riverModel = new RiverDiffusionModel(
          longitudinalDiffusion.value,
          flowVelocity.value,
          riverDepth.value,
          riverWidth.value,
          decayRate.value / (24 * 3600), // 转换为秒
          pollutantMass.value * 1000 // 转换为克
        )
        
        console.log('河流扩散模型创建成功')
        
        // 隐藏网格点图层，避免影响扩散效果显示
        if (gridLayer.value && props.map.hasLayer(gridLayer.value)) {
          console.log('隐藏网格点图层')
          props.map.removeLayer(gridLayer.value)
        }
        
        // 创建新的扩散效果显示图层
        pollutionLayer.value = L.layerGroup()
        props.map.addLayer(pollutionLayer.value)
        
        // 计算时间步长
        const totalMinutes = simulationHours.value * 60
        const timeStepsCount = Math.floor(totalMinutes / timeStep.value)
        timeSteps.value = []
        
        for (let i = 0; i <= timeStepsCount; i++) {
          timeSteps.value.push(i * timeStep.value)
        }
        
        // 重新创建网格点用于显示扩散效果
        const sourceLat = pollutionSourcePosition.value.lat
        const sourceLng = pollutionSourcePosition.value.lng
        
        // 生成一维网格点
        const gridPoints = generateGridPoints()
        
        // 找到污染源在河流上的位置
        let sourceDistance = 0
        const riverCoordinates = selectedRiverGeometry.value.coordinates
        
        // 计算污染源到河流起点的距离
        for (let i = 0; i < riverCoordinates.length - 1; i++) {
          const p1 = riverCoordinates[i]
          const p2 = riverCoordinates[i + 1]
          
          // 计算污染源到当前线段的距离
          const distance = pointToLineDistance(
            sourceLat, sourceLng,
            p1[1], p1[0],
            p2[1], p2[0]
          )
          
          if (distance < 0.001) { // 污染源在河流上
            // 计算到河流起点的距离
            let accumulatedDistance = 0
            for (let j = 0; j < i; j++) {
              const pj1 = riverCoordinates[j]
              const pj2 = riverCoordinates[j + 1]
              
              const lat1 = pj1[1], lng1 = pj1[0]
              const lat2 = pj2[1], lng2 = pj2[0]
              
              const R = 6371000
              const dLat = (lat2 - lat1) * Math.PI / 180
              const dLng = (lng2 - lng1) * Math.PI / 180
              const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
                        Math.sin(dLng/2) * Math.sin(dLng/2)
              const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
              accumulatedDistance += R * c
            }
            
            // 加上当前线段的部分距离
            const p1_lat = p1[1], p1_lng = p1[0]
            const p2_lat = p2[1], p2_lng = p2[0]
            
            const R = 6371000
            const dLat = (p2_lat - p1_lat) * Math.PI / 180
            const dLng = (p2_lng - p1_lng) * Math.PI / 180
            const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                      Math.cos(p1_lat * Math.PI / 180) * Math.cos(p2_lat * Math.PI / 180) *
                      Math.sin(dLng/2) * Math.sin(dLng/2)
            const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
            const segmentLength = R * c
            
            // 计算污染源在线段上的位置
            const sourceToP1 = pointToLineDistance(sourceLat, sourceLng, p1_lat, p1_lng, p2_lat, p2_lng)
            const segmentProgress = sourceToP1 / segmentLength
            sourceDistance = accumulatedDistance + segmentProgress * segmentLength
            break
          }
        }
        
        console.log('污染源在河流上的距离:', sourceDistance, '米')
        
        // 为每个网格点计算相对于污染源的距离（只考虑下游方向）
        gridPoints.forEach(point => {
          const relativeDistance = point.distance - sourceDistance
          // 只考虑下游方向的点（相对距离为正）
          point.sourceDistance = relativeDistance >= 0 ? relativeDistance : -1
        })
        
        // 计算每个时间步的浓度
        console.log('开始计算河流扩散，网格点数:', gridPoints.length, '时间步数:', timeSteps.value.length)
        
        // 预计算河流边界，用于快速过滤
        const riverBounds = selectedRiverBounds.value
        const riverTolerance = 0.005 // 约500米
        
        // 优化：减少计算量，增加计算间隔
        const calculationInterval = Math.max(1, Math.floor(timeSteps.value.length / 50)) // 最多计算50个时间步
        
        for (let t = 0; t < timeSteps.value.length; t += calculationInterval) {
          const time = timeSteps.value[t] * 60 // 转换为秒
          
          // 添加计算限制，避免栈溢出
          if (t % (calculationInterval * 5) === 0) {
            console.log(`计算进度: ${t}/${timeSteps.value.length}`)
          }
          
          for (let i = 0; i < gridPoints.length; i++) {
            try {
              const point = gridPoints[i]
              
              // 使用一维距离计算浓度（只考虑下游方向）
              const distance = point.sourceDistance
              if (distance < 0 || distance > 5000) { // 上游或5公里外直接设为0
                point.concentrations.push(0)
                continue
              }
              
              const concentration = riverModel.calculate(time, distance)
              point.concentrations.push(concentration)
            } catch (error) {
              console.error(`计算网格点 ${i} 浓度时出错:`, error)
              point.concentrations.push(0)
            }
          }
          
          // 更新进度
          progressPercentage.value = Math.round((t + 1) / timeSteps.value.length * 100)
          
          // 添加延迟，避免阻塞UI
          if (t % (calculationInterval * 10) === 0) {
            await new Promise(resolve => setTimeout(resolve, 10))
          }
        }
        
        // 填充剩余时间步的浓度（使用插值或复制）
        for (let t = 0; t < timeSteps.value.length; t++) {
          if (t % calculationInterval !== 0) {
            const prevIndex = Math.floor(t / calculationInterval) * calculationInterval
            const nextIndex = Math.min(prevIndex + calculationInterval, timeSteps.value.length - 1)
            
            for (let i = 0; i < gridPoints.length; i++) {
              const point = gridPoints[i]
              
              // 检查点是否在下游方向
              if (point.sourceDistance < 0) {
                gridPoints[i].concentrations[t] = 0
                continue
              }
              
              const prevConcentration = gridPoints[i].concentrations[Math.floor(t / calculationInterval)] || 0
              const nextConcentration = gridPoints[i].concentrations[Math.min(Math.floor(t / calculationInterval) + 1, gridPoints[i].concentrations.length - 1)] || 0
              
              // 简单线性插值
              const ratio = (t % calculationInterval) / calculationInterval
              const interpolatedConcentration = prevConcentration * (1 - ratio) + nextConcentration * ratio
              gridPoints[i].concentrations[t] = interpolatedConcentration
            }
          }
        }
        
        // 保存模拟结果
        simulationResult.value = {
          gridPoints: gridPoints,
          timeSteps: timeSteps.value,
          maxConcentration: Math.max(...gridPoints.flatMap(p => p.concentrations))
        }
        
        maxConcentration.value = simulationResult.value.maxConcentration
        currentTimeIndex.value = 0
        currentTimeDisplay.value = formatTime(timeSteps.value[0])
        
        // 更新地图显示
        updateMapDisplay(0)
        
        progressPercentage.value = 100
        progressText.value = '模拟计算完成'
        
        setTimeout(() => {
          simulationLoading.value = false
        }, 1000)
        
      } catch (error) {
        console.error('河流模拟计算失败:', error)
        alert('河流模拟计算失败')
        simulationLoading.value = false
      }
    }
    
    // 更新地图显示
    const updateMapDisplay = (timeIndex) => {
      if (!simulationResult.value) return
      
      const time = timeSteps.value[timeIndex]
      const gridPoints = simulationResult.value.gridPoints
      
      // 清除之前的扩散效果
      pollutionLayer.value.clearLayers()
      
      // 创建颜色映射函数
      const maxConc = simulationResult.value.maxConcentration
      const getColor = (concentration) => {
        if (concentration <= 0) return '#ffffff'
        const ratio = concentration / maxConc
        if (ratio < 0.2) return '#4CAF50'
        if (ratio < 0.4) return '#8BC34A'
        if (ratio < 0.6) return '#FFC107'
        if (ratio < 0.8) return '#FF9800'
        return '#F44336'
      }
      
      // 添加扩散效果圆圈（只显示下游方向）
      gridPoints.forEach(point => {
        const concentration = point.concentrations[timeIndex] || 0
        // 只显示下游方向的点且浓度大于0
        if (concentration > 0 && point.sourceDistance >= 0) {
          const circle = L.circleMarker([point.lat, point.lng], {
            radius: 4,
            fillColor: getColor(concentration),
            color: getColor(concentration),
            weight: 1,
            opacity: 0.8,
            fillOpacity: 0.7
          }).addTo(pollutionLayer.value)
          
          // 添加浓度信息
          circle.bindTooltip(`浓度: ${concentration.toFixed(6)} mg/L<br>距离污染源: ${point.sourceDistance.toFixed(0)}m`)
        }
      })
    }
    
    // 播放/暂停控制
    const togglePlayPause = () => {
      if (isPlaying.value) {
        pauseAnimation()
      } else {
        startAnimation()
      }
    }
    
    // 改变播放速度
    const changeSpeed = (multiplier) => {
      speedMultiplier.value = multiplier
      // 基础速度是100ms，根据倍数调整
      animationSpeed.value = Math.round(100 / multiplier)
      
      // 如果正在播放，重新启动动画以应用新速度
      if (isPlaying.value) {
        pauseAnimation()
        startAnimation()
      }
    }
    
    // 开始播放动画
    const startAnimation = () => {
      if (!simulationResult.value || timeSteps.value.length === 0) return
      
      isPlaying.value = true
      animationInterval.value = setInterval(() => {
        if (currentTimeIndex.value >= timeSteps.value.length - 1) {
          // 播放完毕，重置到开始
          currentTimeIndex.value = 0
        } else {
          currentTimeIndex.value++
        }
        
        currentTimeDisplay.value = formatTime(timeSteps.value[currentTimeIndex.value])
        updateMapDisplay(currentTimeIndex.value)
      }, animationSpeed.value)
    }
    
    // 暂停动画
    const pauseAnimation = () => {
      isPlaying.value = false
      if (animationInterval.value) {
        clearInterval(animationInterval.value)
        animationInterval.value = null
      }
    }
    
    // 重置动画
    const resetAnimation = () => {
      pauseAnimation()
      currentTimeIndex.value = 0
      currentTimeDisplay.value = formatTime(timeSteps.value[0])
      updateMapDisplay(0)
    }
    
    // 时间变化处理
    const onTimeChange = () => {
      if (simulationResult.value) {
        currentTimeDisplay.value = formatTime(timeSteps.value[currentTimeIndex.value])
        updateMapDisplay(currentTimeIndex.value)
      }
    }
    
    // 格式化时间显示
    const formatTime = (minutes) => {
      const hours = Math.floor(minutes / 60)
      const mins = minutes % 60
      return `${hours}小时${mins}分钟`
    }
    
    // 生成网格
    const generateGrid = async () => {
      if (!selectedRiverGeometry.value) {
        alert('请先选择河流')
        return
      }
      
      console.log('开始生成河流网格，河流几何:', selectedRiverGeometry.value)
      console.log('河流边界:', selectedRiverBounds.value)
      
      gridLoading.value = true
      progressPercentage.value = 0
      progressText.value = '正在生成网格...'
      
      try {
        // 生成网格点
        const gridPoints = generateGridPoints()
        console.log('生成的网格点数量:', gridPoints.length)
        
        if (gridPoints.length === 0) {
          alert('未生成任何网格点，请检查河流几何数据')
          gridLoading.value = false
          return
        }
        
        // 创建网格图层
        createGridLayer(gridPoints)
        
        gridGenerated.value = true
        progressPercentage.value = 100
        progressText.value = '网格生成完成'
        
        setTimeout(() => {
          gridLoading.value = false
        }, 1000)
        
      } catch (error) {
        console.error('生成网格失败:', error)
        alert('生成网格失败: ' + error.message)
        gridLoading.value = false
      }
    }
    
    // 生成一维河流网格点（考虑流向）
    const generateGridPoints = () => {
      const points = []
      const riverGeometry = selectedRiverGeometry.value
      
      console.log('生成一维河流网格点，河流几何:', riverGeometry)
      
      if (riverGeometry.type !== 'LineString') {
        console.error('河流几何类型不是LineString')
        return points
      }
      
      const coordinates = riverGeometry.coordinates
      console.log('河流坐标数量:', coordinates.length)
      
      // 计算河流总长度和累积距离
      let totalLength = 0
      const segmentLengths = []
      const cumulativeDistances = [0] // 每个坐标点的累积距离
      
      for (let i = 0; i < coordinates.length - 1; i++) {
        const p1 = coordinates[i]
        const p2 = coordinates[i + 1]
        
        // 计算两点间的距离（米）
        const lat1 = p1[1], lng1 = p1[0]
        const lat2 = p2[1], lng2 = p2[0]
        
        const R = 6371000 // 地球半径（米）
        const dLat = (lat2 - lat1) * Math.PI / 180
        const dLng = (lng2 - lng1) * Math.PI / 180
        const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                  Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
                  Math.sin(dLng/2) * Math.sin(dLng/2)
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
        const distance = R * c
        
        segmentLengths.push(distance)
        totalLength += distance
        cumulativeDistances.push(totalLength)
      }
      
      console.log('河流总长度:', totalLength, '米')
      
      // 根据网格间距计算网格点数量
      const gridSpacingMeters = Math.max(gridSpacing.value, 50) // 最小50米间距
      const numGridPoints = Math.floor(totalLength / gridSpacingMeters) + 1
      
      console.log('网格间距:', gridSpacingMeters, '米，网格点数量:', numGridPoints)
      
      // 沿河流流向生成一维网格点（从上游到下游）
      for (let i = 0; i < numGridPoints; i++) {
        const targetDistance = i * gridSpacingMeters
        
        if (targetDistance > totalLength) {
          break // 超出河流范围
        }
        
        // 找到目标距离所在的线段
        let segmentIndex = 0
        for (let j = 0; j < cumulativeDistances.length - 1; j++) {
          if (targetDistance >= cumulativeDistances[j] && targetDistance <= cumulativeDistances[j + 1]) {
            segmentIndex = j
            break
          }
        }
        
        // 在当前线段上插值计算网格点位置
        const segmentStartDistance = cumulativeDistances[segmentIndex]
        const segmentEndDistance = cumulativeDistances[segmentIndex + 1]
        const segmentProgress = (targetDistance - segmentStartDistance) / (segmentEndDistance - segmentStartDistance)
        
        const p1 = coordinates[segmentIndex]
        const p2 = coordinates[segmentIndex + 1]
        
        // 线性插值计算网格点坐标
        const lat = p1[1] + (p2[1] - p1[1]) * segmentProgress
        const lng = p1[0] + (p2[0] - p1[0]) * segmentProgress
        
        points.push({
          lat: lat,
          lng: lng,
          distance: targetDistance, // 沿河流的距离（从上游到下游）
          segmentIndex: segmentIndex,
          concentrations: []
        })
      }
      
      console.log(`一维河流网格生成完成: 网格点数量 ${points.length}`)
      return points
    }
    
    // 创建网格图层
    const createGridLayer = (gridPoints) => {
      // 清除之前的网格图层
      if (gridLayer.value && props.map.hasLayer(gridLayer.value)) {
        props.map.removeLayer(gridLayer.value)
      }
      
      gridLayer.value = L.layerGroup()
      
      // 添加网格点标记
      gridPoints.forEach((point, index) => {
        // 再次确认点是否在河流附近（双重检查）
        const pointLatLng = L.latLng(point.lat, point.lng)
        if (isPointNearRiver(pointLatLng, selectedRiverGeometry.value)) {
          const marker = L.circleMarker([point.lat, point.lng], {
            radius: 2,
            fillColor: '#4CAF50',
            color: '#4CAF50',
            weight: 1,
            opacity: 0.8,
            fillOpacity: 0.6
          })
          
          marker.bindPopup(`网格点 ${index + 1}<br>坐标: ${point.lat.toFixed(6)}, ${point.lng.toFixed(6)}`)
          gridLayer.value.addLayer(marker)
        }
      })
      
      props.map.addLayer(gridLayer.value)
    }
    
    // 清除模拟
    const clearSimulation = () => {
      // 停止动画
      pauseAnimation()
      
      // 清除网格图层
      if (gridLayer.value && props.map.hasLayer(gridLayer.value)) {
        props.map.removeLayer(gridLayer.value)
        gridLayer.value = null
      }
      
      // 清除污染扩散图层
      if (pollutionLayer.value && props.map.hasLayer(pollutionLayer.value)) {
        props.map.removeLayer(pollutionLayer.value)
        pollutionLayer.value = null
      }
      
      // 重置状态
      gridGenerated.value = false
      simulationResult.value = null
      timeSteps.value = []
      currentTimeIndex.value = 0
      currentTimeDisplay.value = ''
      maxConcentration.value = 0
    }
    
    // 组件卸载时清理
    onUnmounted(() => {
      try {
        // 停止动画
        pauseAnimation()
        
        // 清理污染源标记
        if (pollutionSourceMarker.value && props.map) {
          props.map.removeLayer(pollutionSourceMarker.value)
        }
        
        // 清理网格图层
        if (gridLayer.value && props.map) {
          props.map.removeLayer(gridLayer.value)
        }
        
        // 清理污染扩散图层
        if (pollutionLayer.value && props.map) {
          props.map.removeLayer(pollutionLayer.value)
        }
        
        // 清理河流高亮图层
        if (riverHighlightLayer.value && props.map) {
          props.map.removeLayer(riverHighlightLayer.value)
        }
        
        // 清理地图点击事件监听器
        if (props.map && props.map._riverPollutionSourceClickHandler) {
          props.map.off('click', props.map._riverPollutionSourceClickHandler)
        }
      } catch (error) {
        console.error('清理河流模拟组件时出错:', error)
      }
    })
    
    return {
      panelVisible,
      selectedRiver,
      selectedRiverName,
      pollutionSourcePosition,
      pollutantType,
      pollutantMass,
      decayRate,
      riverWidth,
      riverDepth,
      flowVelocity,
      longitudinalDiffusion,
      transverseDiffusion,
      gridSpacing,
      simulationHours,
      timeStep,
      gridLoading,
      simulationLoading,
      gridGenerated,
      progressPercentage,
      progressText,
      simulationResult,
      timeSteps,
      currentTimeIndex,
      currentTimeDisplay,
      maxConcentration,
      isPlaying,
      speedMultiplier,
      pollutantOptions,
      canStartSimulation,
      togglePanel,
      clearRiverSelection,
      clearPollutionSource,
      onRiverSelect,
      highlightSelectedRiver,
      setupPollutionSourceSelection,
      isPointNearRiverForSelection,
      onPollutantChange,
      generateGrid,
      startSimulation,
      clearSimulation,
      togglePlayPause,
      resetAnimation,
      changeSpeed,
      onTimeChange
    }
  }
}

// 河流一维扩散模型
class RiverDiffusionModel {
  constructor(Ex, vx, H, W, K1, m) {
    this.Ex = Ex // 纵向弥散系数
    this.vx = vx // 流速
    this.H = H   // 水深
    this.W = W   // 河宽
    this.K1 = K1 // 一级降解系数
    this.m = m   // 污染物质量
    
    // 预计算常数
    this.constant = m / (H * W * Math.sqrt(4 * Math.PI * Ex))
  }
  
  // 一维河流扩散方程（只向下游扩散）
  calculate(t, x) {
    if (t <= 0 || x < 0) return 0
    
    try {
      // 添加数值稳定性检查
      if (t < 0.001 || this.Ex <= 0) {
        return 0
      }
      
      // 计算污染物在时间t后的理论位置
      const expectedPosition = this.vx * t
      
      // 只在下游方向计算浓度（x >= 0，且距离污染源不会太远）
      if (x < 0 || x > expectedPosition + 3 * Math.sqrt(4 * this.Ex * t)) {
        return 0
      }
      
      // 一维对流扩散方程解析解（只考虑下游扩散）
      const part1 = this.constant / Math.sqrt(t)
      const part2 = Math.pow(x - this.vx * t, 2) / (4 * this.Ex * t)
      const part3 = Math.exp(-this.K1 * t)
      
      const concentration = part3 * part1 * Math.exp(-part2)
      
      // 添加数值范围检查
      if (isNaN(concentration) || !isFinite(concentration)) {
        return 0
      }
      
      // 保留6位小数，小于阈值设为0
      const result = Math.round(concentration * 1000000) / 1000000
      return result < 0.000001 ? 0 : result
    } catch (error) {
      console.error('一维河流扩散计算出错:', error, { t, x })
      return 0
    }
  }
}
</script>

<style scoped>
.river-simulation-panel {
  position: absolute;
  top: 20px;
  right: 20px;
  width: 350px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-radius: 10px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  z-index: 1000;
  max-height: 80vh;
  overflow-y: auto;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #eee;
  background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
  color: white;
  border-radius: 12px 12px 0 0;
  cursor: default;
}

.panel-header h3 {
  margin: 0;
  font-size: 1.3rem;
}

.close-btn {
  background: none;
  border: none;
  color: white;
  font-size: 1.5rem;
  cursor: pointer;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: background-color 0.2s;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.2);
}

.panel-content {
  padding: 20px;
}

.step-section {
  margin-bottom: 25px;
  padding: 15px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background: #fafafa;
}

.step-section h4 {
  margin: 0 0 15px 0;
  color: #2E7D32;
  font-size: 1.1rem;
  display: flex;
  align-items: center;
}

.step-section h4::before {
  content: '';
  width: 8px;
  height: 8px;
  background: #4CAF50;
  border-radius: 50%;
  margin-right: 10px;
}

.selection-info {
  margin-bottom: 10px;
}

.selection-hint {
  margin: 0;
  color: #666;
  font-size: 0.9rem;
}

.selected-river,
.selected-source {
  margin: 0;
  color: #2E7D32;
  font-size: 0.9rem;
}

.clear-btn {
  background: #f44336;
  color: white;
  border: none;
  padding: 5px 10px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8rem;
  transition: background-color 0.2s;
}

.clear-btn:hover {
  background: #d32f2f;
}

.param-group {
  margin-bottom: 15px;
}

.param-group label {
  display: block;
  margin-bottom: 5px;
  color: #333;
  font-weight: 500;
  font-size: 0.9rem;
}

.form-select,
.form-input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.9rem;
  transition: border-color 0.2s;
}

.form-select:focus,
.form-input:focus {
  outline: none;
  border-color: #4CAF50;
  box-shadow: 0 0 0 2px rgba(76, 175, 80, 0.2);
}

.action-buttons {
  display: flex;
  gap: 10px;
  margin-top: 15px;
  flex-wrap: wrap;
}

.btn {
  flex: 1;
  padding: 12px 20px;
  border: none;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  min-width: 80px;
}

.btn-primary {
  background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%);
  color: white;
}

.btn-primary:hover:not(:disabled) {
  box-shadow: 0 4px 12px rgba(33, 150, 243, 0.4);
  transform: translateY(-2px);
}

.btn-success {
  background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
  color: white;
}

.btn-success:hover:not(:disabled) {
  box-shadow: 0 4px 12px rgba(76, 175, 80, 0.4);
  transform: translateY(-2px);
}

.btn-warning {
  background: linear-gradient(135deg, #FF9800 0%, #F57C00 100%);
  color: white;
}

.btn-warning:hover:not(:disabled) {
  box-shadow: 0 4px 12px rgba(255, 152, 0, 0.4);
  transform: translateY(-2px);
}

.btn:disabled {
  background: #ccc;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

.progress-section {
  margin-top: 15px;
  padding: 15px;
  background: #f5f5f5;
  border-radius: 6px;
}

.progress {
  width: 100%;
  height: 8px;
  background: #e0e0e0;
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 10px;
}

.progress-bar {
  height: 100%;
  background: linear-gradient(90deg, #4CAF50, #45a049);
  transition: width 0.3s ease;
}

.progress-text {
  margin: 0;
  text-align: center;
  color: #2E7D32;
  font-weight: 500;
}

.time-control {
  margin-top: 20px;
  padding: 15px;
  background: #f9f9f9;
  border-radius: 6px;
  border: 1px solid #e0e0e0;
}

.time-control h4 {
  margin: 0 0 15px 0;
  color: #2E7D32;
  font-size: 1.1rem;
}

.time-slider {
  width: 100%;
  margin: 10px 0;
}

.time-control-buttons {
  display: flex;
  gap: 10px;
  margin-bottom: 15px;
}

.play-pause-btn,
.reset-btn {
  flex: 1;
  padding: 8px 12px;
  border: none;
  border-radius: 6px;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 500;
}

.play-pause-btn {
  background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
  color: white;
}

.play-pause-btn:hover {
  box-shadow: 0 4px 12px rgba(76, 175, 80, 0.4);
  transform: translateY(-2px);
}

.play-pause-btn.playing {
  background: linear-gradient(135deg, #FF9800 0%, #F57C00 100%);
}

.reset-btn {
  background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%);
  color: white;
}

.reset-btn:hover {
  box-shadow: 0 4px 12px rgba(33, 150, 243, 0.4);
  transform: translateY(-2px);
}

.speed-control {
  margin: 15px 0;
  padding: 10px;
  background: #f8f9fa;
  border-radius: 6px;
  border: 1px solid #e9ecef;
}

.speed-control label {
  display: block;
  margin-bottom: 8px;
  font-size: 0.9rem;
  color: #495057;
  font-weight: 500;
}

.speed-buttons {
  display: flex;
  gap: 5px;
  flex-wrap: wrap;
}

.speed-btn {
  flex: 1;
  min-width: 50px;
  padding: 6px 8px;
  border: 1px solid #dee2e6;
  border-radius: 4px;
  background: white;
  color: #495057;
  font-size: 0.8rem;
  cursor: pointer;
  transition: all 0.2s ease;
  font-weight: 500;
}

.speed-btn:hover {
  background: #e9ecef;
  border-color: #adb5bd;
}

.speed-btn.active {
  background: linear-gradient(135deg, #6c757d 0%, #495057 100%);
  color: white;
  border-color: #495057;
}

.time-info {
  display: flex;
  justify-content: space-between;
  margin-top: 10px;
  font-size: 0.9rem;
  color: #666;
}

.simulation-status {
  text-align: center;
  padding: 15px;
  background: #e8f5e8;
  border-radius: 6px;
  border: 1px solid #4CAF50;
}

.simulation-status p {
  margin: 5px 0;
  color: #2E7D32;
  font-weight: 500;
}

.progress-bar {
  width: 100%;
  height: 8px;
  background: #e0e0e0;
  border-radius: 4px;
  overflow: hidden;
  margin: 10px 0;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #4CAF50, #45a049);
  transition: width 0.3s ease;
}

.results-container {
  max-height: 200px;
  overflow-y: auto;
}

.result-item {
  padding: 10px;
  margin-bottom: 10px;
  background: #f5f5f5;
  border-radius: 4px;
  border-left: 4px solid #4CAF50;
}

.result-item h5 {
  margin: 0 0 5px 0;
  color: #2E7D32;
  font-size: 0.9rem;
}

.result-item p {
  margin: 3px 0;
  font-size: 0.8rem;
  color: #666;
}

/* 污染源标记样式 */
:global(.pollution-source-marker) {
  background: #f44336;
  border: 2px solid white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

@media (max-width: 768px) {
  .river-simulation-panel {
    width: 280px;
    max-height: 90vh;
  }
  
  .panel-header {
    padding: 15px;
  }
  
  .panel-header h3 {
    font-size: 1.1rem;
  }
  
  .panel-content {
    padding: 15px;
  }
  
  .step-section {
    padding: 12px;
    margin-bottom: 20px;
  }
  
  .simulation-controls {
    flex-direction: column;
  }
}
</style> 
<template>
  <div class="lake-simulation-panel" v-if="panelVisible">
    <div class="panel-header">
      <h3>湖泊污染扩散模拟</h3>
      <button @click="togglePanel" class="close-btn">×</button>
    </div>
    
    <div class="panel-content">
      <!-- 步骤1: 选择湖泊 -->
      <div class="step-section">
        <h4>1. 选择湖泊</h4>
        <div class="lake-selection">
          <div class="selection-info">
            <p v-if="!selectedLake" class="selection-hint">
              💡 请点击地图上的湖泊多边形来选择湖泊
            </p>
            <p v-else class="selected-lake">
              ✅ 已选择: <strong>{{ selectedLakeName }}</strong>
            </p>
          </div>
          <button @click="clearLakeSelection" class="clear-btn" v-if="selectedLake">
            清除选择
          </button>
        </div>
      </div>

      <!-- 步骤2: 选择污染源位置 -->
      <div class="step-section">
        <h4>2. 选择污染源位置</h4>
        <div class="pollution-source-selection">
          <div class="selection-info">
            <p v-if="!selectedLake" class="selection-hint">
              ⚠️ 请先选择湖泊
            </p>
            <p v-else-if="!pollutionSourcePosition" class="selection-hint">
              💡 请点击湖泊内的任意位置来设置污染源起始点
            </p>
            <p v-else class="selected-source">
              ✅ 污染源位置: <strong>{{ pollutionSourcePosition.lat.toFixed(6) }}, {{ pollutionSourcePosition.lng.toFixed(6) }}</strong>
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

      <!-- 步骤4: 设置湖泊参数 -->
      <div class="step-section">
        <h4>4. 设置湖泊参数</h4>
        <div class="param-group">
          <label>平均深度 (m):</label>
          <input type="number" v-model="lakeDepth" min="1" max="100" step="0.1" class="form-input">
        </div>
        <div class="param-group">
          <label>纵向流速 (m/s):</label>
          <input type="number" v-model="longitudinalVelocity" min="0" max="5" step="0.01" class="form-input">
        </div>
        <div class="param-group">
          <label>横向流速 (m/s):</label>
          <input type="number" v-model="transverseVelocity" min="0" max="5" step="0.01" class="form-input">
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
        <button @click="generateGrid" :disabled="!selectedLake || !pollutionSourcePosition || gridLoading" class="btn btn-primary">
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
        <input 
          type="range" 
          v-model="currentTimeIndex" 
          :min="0" 
          :max="timeSteps.length - 1" 
          step="1" 
          @input="onTimeChange"
          class="time-slider">
        <div class="time-info">
          <span>当前时间: {{ currentTimeDisplay }}</span>
          <span>最大浓度: {{ maxConcentration.toFixed(6) }} mg/L</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive, computed, watch } from 'vue'
import L from 'leaflet'

export default {
  name: 'LakePollutionSimulation',
  props: {
    map: {
      type: Object,
      required: true
    },
    'water-areas-layer': {
      type: Object,
      required: true
    }
  },
  emits: ['simulation-update', 'close'],
  setup(props, { emit }) {
    // 面板状态
    const panelVisible = ref(true)
    
    // 湖泊选择
    const selectedLake = ref(null)
    const selectedLakeName = ref('')
    const selectedLakeFeature = ref(null)
    const lakeOptions = ref([])
    
    // 污染源位置选择
    const pollutionSourcePosition = ref(null)
    const pollutionSourceMarker = ref(null)
    
    // 污染物参数
    const pollutantType = ref(0)
    const pollutantMass = ref(2000)
    const decayRate = ref(0.001)
    
    const pollutantOptions = [
      { value: 0, label: '硝基苯', k: 0.15 },
      { value: 1, label: '苯酚', k: 0.15 },
      { value: 2, label: '氨氮', k: 0.18 },
      { value: 3, label: '石油类', k: 0 }
    ]
    
    // 湖泊参数
    const lakeDepth = ref(1.0)
    const longitudinalVelocity = ref(0.005)
    const transverseVelocity = ref(0.002)
    const longitudinalDiffusion = ref(0.05)
    const transverseDiffusion = ref(0.025)
    
    // 模拟参数
    const gridSpacing = ref(25)
    const simulationHours = ref(2)
    const timeStep = ref(5)
    
    // 状态控制
    const gridLoading = ref(false)
    const simulationLoading = ref(false)
    const gridGenerated = ref(false)
    const progressPercentage = ref(0)
    const progressText = ref('')
    
    // 模拟结果
    const simulationResult = ref(null)
    const currentTimeIndex = ref(0)
    const timeSteps = ref([])
    const currentTimeDisplay = ref('')
    const maxConcentration = ref(0)
    
    // 图层管理
    const gridLayer = ref(null)
    const pollutionLayer = ref(null)
    const selectedLakeGeometry = ref(null)
    const selectedLakeBounds = ref(null)
    
    // 方法
    const togglePanel = () => {
      panelVisible.value = false
      emit('close')
    }
    
    const onPollutantChange = (value) => {
      const pollutant = pollutantOptions.find(p => p.value === value)
      if (pollutant) {
        decayRate.value = pollutant.k
      }
    }
    
    const onLakeSelect = (feature) => {
      if (!feature) return
      
      console.log('选择湖泊:', feature.properties) // 调试输出
      
      // 清除之前的模拟
      clearSimulation()
      
      // 设置选中的湖泊信息 - 使用真实存在的属性名
      selectedLake.value = feature.properties.osm_id || feature.properties.OSM_ID || feature.properties.id
      selectedLakeName.value = feature.properties.name || feature.properties.NAME || '未命名湖泊'
      selectedLakeFeature.value = feature
      selectedLakeGeometry.value = feature.geometry
      selectedLakeBounds.value = L.geoJSON(feature).getBounds()
      
      // 高亮显示选中的湖泊
      highlightSelectedLake(feature)
      
      // 清除之前的污染源位置
      clearPollutionSource()
      
      // 添加地图点击事件监听，用于选择污染源位置
      setupPollutionSourceSelection()
    }
    
    const setupPollutionSourceSelection = () => {
      console.log('设置污染源选择模式')
      
      // 移除之前的事件监听
      if (props.map._pollutionSourceClickHandler) {
        console.log('移除之前的事件监听器')
        props.map.off('click', props.map._pollutionSourceClickHandler)
      }
      
      // 添加新的点击事件监听
      props.map._pollutionSourceClickHandler = (e) => {
        console.log('地图被点击:', e.latlng)
        const clickedPoint = e.latlng
        
        // 检查点击位置是否在选中的湖泊内
        if (isPointInLake(clickedPoint)) {
          console.log('点击位置在湖泊内，设置污染源')
          setPollutionSource(clickedPoint)
        } else {
          console.log('点击位置在湖泊外')
          alert('请点击湖泊内的位置来设置污染源！')
        }
      }
      
      props.map.on('click', props.map._pollutionSourceClickHandler)
      console.log('污染源选择事件监听器已添加')
    }
    
    const clearLakeSelection = () => {
      selectedLake.value = null
      selectedLakeName.value = ''
      selectedLakeFeature.value = null
      selectedLakeGeometry.value = null
      selectedLakeBounds.value = null
      
      // 清除污染源位置
      clearPollutionSource()
      
      // 清除高亮图层
      if (gridLayer.value && props.map.hasLayer(gridLayer.value)) {
        props.map.removeLayer(gridLayer.value)
      }
      
      // 清除模拟结果
      clearSimulation()
    }
    
    const clearPollutionSource = () => {
      pollutionSourcePosition.value = null
      
      // 清除污染源标记
      if (pollutionSourceMarker.value && props.map.hasLayer(pollutionSourceMarker.value)) {
        props.map.removeLayer(pollutionSourceMarker.value)
      }
    }
    
    const setPollutionSource = (latlng) => {
      console.log('开始设置污染源位置:', latlng)
      
      // 清除之前的污染源标记
      clearPollutionSource()
      
      // 设置新的污染源位置
      pollutionSourcePosition.value = latlng
      console.log('污染源位置已设置:', pollutionSourcePosition.value)
      
      // 创建污染源标记 - 使用circleMarker确保跟随地图缩放
      pollutionSourceMarker.value = L.circleMarker(latlng, {
        radius: 3, // 半径3像素，最小化
        fillColor: '#e74c3c',
        color: '#c0392b',
        weight: 1,
        opacity: 0.8,
        fillOpacity: 0.8
      })
      
      // 添加弹窗信息
      pollutionSourceMarker.value.bindPopup(`
        <strong>污染源位置</strong><br>
        纬度: ${latlng.lat.toFixed(6)}<br>
        经度: ${latlng.lng.toFixed(6)}
      `)
      
      // 添加到地图
      props.map.addLayer(pollutionSourceMarker.value)
      console.log('污染源标记已添加到地图')
    }
    
    const highlightSelectedLake = (feature) => {
      // 清除之前的高亮
      if (gridLayer.value && props.map.hasLayer(gridLayer.value)) {
        props.map.removeLayer(gridLayer.value)
      }
      
      // 创建高亮图层
      gridLayer.value = L.geoJSON(feature, {
        style: {
          fillColor: '#ff6b6b',
          weight: 2,
          opacity: 1,
          color: '#ff4757',
          fillOpacity: 0.3
        }
      })
      
      props.map.addLayer(gridLayer.value)
      props.map.fitBounds(selectedLakeBounds.value)
    }
    
    const generateGrid = async () => {
      if (!selectedLakeGeometry.value) {
        alert('请先选择湖泊')
        return
      }
      
      console.log('开始生成网格，湖泊几何:', selectedLakeGeometry.value)
      console.log('湖泊边界:', selectedLakeBounds.value)
      
      gridLoading.value = true
      progressPercentage.value = 0
      progressText.value = '正在生成网格...'
      
      try {
        // 生成网格点
        const gridPoints = generateGridPoints()
        console.log('生成的网格点数量:', gridPoints.length)
        
        if (gridPoints.length === 0) {
          alert('未生成任何网格点，请检查湖泊几何数据')
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
    
    const generateGridPoints = () => {
      const points = []
      const bounds = selectedLakeBounds.value
      
      console.log('生成网格点，边界:', bounds)
      
      // 计算网格范围
      const minLat = bounds.getSouth()
      const maxLat = bounds.getNorth()
      const minLng = bounds.getWest()
      const maxLng = bounds.getEast()
      
      console.log('网格范围:', { minLat, maxLat, minLng, maxLng })
      
      // 转换为投影坐标（简化处理，使用经纬度差值）
      const latStep = gridSpacing.value / 111000 // 大约1度=111km
      const lngStep = gridSpacing.value / (111000 * Math.cos((minLat + maxLat) / 2 * Math.PI / 180))
      
      console.log('网格步长:', { latStep, lngStep, gridSpacing: gridSpacing.value })
      
      let totalPoints = 0
      let validPoints = 0
      
      // 生成网格点，严格限制在多边形边界内
      for (let lat = minLat; lat <= maxLat; lat += latStep) {
        for (let lng = minLng; lng <= maxLng; lng += lngStep) {
          totalPoints++
          const point = L.latLng(lat, lng)
          
          // 严格检查点是否在湖泊边界内
          if (isPointInLake(point)) {
            validPoints++
            points.push({
              lat: lat,
              lng: lng,
              x: (lng - minLng) * 111000 * Math.cos(lat * Math.PI / 180),
              y: (lat - minLat) * 111000,
              concentrations: []
            })
          }
        }
      }
      
      console.log(`网格生成完成: 总点数 ${totalPoints}, 有效点数 ${validPoints}`)
      return points
    }
    
    const isPointInLake = (point) => {
      try {
        // 首先进行边界框快速检查
        if (selectedLakeBounds.value) {
          const inBounds = selectedLakeBounds.value.contains(point)
          if (!inBounds) {
            return false // 不在边界框内，肯定不在多边形内
          }
        }
        
        // 如果有几何数据，进行精确的多边形内点检查
        if (selectedLakeGeometry.value) {
          const lakeGeoJSON = L.geoJSON(selectedLakeGeometry.value)
          const layers = lakeGeoJSON.getLayers()
          
          // 检查点是否在任何一个多边形内
          const result = layers.some(layer => {
            if (layer instanceof L.Polygon) {
              // 使用射线法进行精确检查
              return isPointInPolygon(point, layer.getLatLngs()[0])
            }
            return false
          })
          
          return result
        }
        
        // 如果没有几何数据，使用边界框检查
        if (selectedLakeBounds.value) {
          return selectedLakeBounds.value.contains(point)
        }
        
        return false // 没有边界信息，默认不在湖泊内
      } catch (error) {
        console.error('检查点是否在湖泊内时出错:', error)
        return false // 出错时默认不在湖泊内，确保安全
      }
    }
    
    // 射线法检查点是否在多边形内
    const isPointInPolygon = (point, polygon) => {
      try {
        const x = point.lng
        const y = point.lat
        let inside = false
        
        for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
          const xi = polygon[i].lng
          const yi = polygon[i].lat
          const xj = polygon[j].lng
          const yj = polygon[j].lat
          
          if (((yi > y) !== (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
            inside = !inside
          }
        }
        
        return inside
      } catch (error) {
        console.error('射线法计算出错:', error)
        return false
      }
    }
    
    const createGridLayer = (gridPoints) => {
      // 清除之前的网格图层
      if (pollutionLayer.value && props.map.hasLayer(pollutionLayer.value)) {
        props.map.removeLayer(pollutionLayer.value)
      }
      
      // 创建新的网格图层
      pollutionLayer.value = L.layerGroup()
      
      gridPoints.forEach((point, index) => {
        // 再次确认点是否在湖泊内（双重检查）
        const pointLatLng = L.latLng(point.lat, point.lng)
        if (isPointInLake(pointLatLng)) {
          const marker = L.circleMarker([point.lat, point.lng], {
            radius: 2, // 从3减小到2
            fillColor: '#3498db',
            color: '#2980b9',
            weight: 0.5, // 从1减小到0.5
            opacity: 0.6, // 从0.8减小到0.6
            fillOpacity: 0.4 // 从0.6减小到0.4
          })
          
          marker.bindPopup(`网格点 ${index + 1}<br>坐标: ${point.lat.toFixed(6)}, ${point.lng.toFixed(6)}`)
          pollutionLayer.value.addLayer(marker)
        }
      })
      
      props.map.addLayer(pollutionLayer.value)
    }
    
    const startSimulation = async () => {
      if (!gridGenerated.value) {
        alert('请先生成网格')
        return
      }
      
      simulationLoading.value = true
      progressPercentage.value = 0
      progressText.value = '正在计算扩散...'
      
      try {
        console.log('开始创建扩散模型，参数:', {
          Ex: longitudinalDiffusion.value,
          Ey: transverseDiffusion.value,
          vx: longitudinalVelocity.value,
          vy: transverseVelocity.value,
          H: lakeDepth.value,
          K1: decayRate.value / (24 * 3600),
          m: pollutantMass.value * 1000
        })
        
        // 创建湖泊扩散模型
        const lakeModel = new LakeDiffusionModel(
          longitudinalDiffusion.value,
          transverseDiffusion.value,
          longitudinalVelocity.value,
          transverseVelocity.value,
          lakeDepth.value,
          decayRate.value / (24 * 3600), // 转换为秒
          pollutantMass.value * 1000 // 转换为克
        )
        
        console.log('扩散模型创建成功')
        
        // 隐藏湖泊边界高亮图层，避免影响扩散效果显示
        if (gridLayer.value && props.map.hasLayer(gridLayer.value)) {
          console.log('隐藏湖泊边界高亮图层')
          props.map.removeLayer(gridLayer.value)
        }
        
        // 隐藏网格点图层，避免影响扩散效果显示
        if (pollutionLayer.value && props.map.hasLayer(pollutionLayer.value)) {
          console.log('隐藏网格点图层')
          props.map.removeLayer(pollutionLayer.value)
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
        
        // 生成新的网格点
        const gridPoints = generateGridPoints().map(point => {
          // 计算相对于污染源的距离（米）
          const latDiff = point.lat - sourceLat
          const lngDiff = point.lng - sourceLng
          
          // 转换为米制坐标（简化处理）
          const x = lngDiff * 111000 * Math.cos(sourceLat * Math.PI / 180)
          const y = latDiff * 111000
          
          return {
            lat: point.lat,
            lng: point.lng,
            x: x,
            y: y,
            concentrations: []
          }
        })
        
        // 计算每个时间步的浓度
        console.log('开始计算扩散，网格点数:', gridPoints.length, '时间步数:', timeSteps.value.length)
        
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
              
              // 检查点是否在湖泊边界内
              const pointLatLng = L.latLng(point.lat, point.lng)
              if (!isPointInLake(pointLatLng)) {
                // 如果点不在湖泊内，浓度为0
                point.concentrations.push(0)
                continue
              }
              
              // 快速距离检查，减少计算量
              const distance = Math.sqrt(point.x * point.x + point.y * point.y)
              if (distance > 400) { // 400米外直接设为0
                point.concentrations.push(0)
                continue
              }
              
              const concentration = lakeModel.calculateEnhanced(time, point.x, point.y)
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
              
              // 检查点是否在湖泊边界内
              const pointLatLng = L.latLng(point.lat, point.lng)
              if (!isPointInLake(pointLatLng)) {
                // 如果点不在湖泊内，浓度为0
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
        console.error('模拟计算失败:', error)
        alert('模拟计算失败')
        simulationLoading.value = false
      }
    }
    
    const updateMapDisplay = (timeIndex) => {
      if (!simulationResult.value) return
      
      const time = timeSteps.value[timeIndex]
      const gridPoints = simulationResult.value.gridPoints
      
      // 清除之前的扩散效果
      pollutionLayer.value.clearLayers()
      
      // 重新创建扩散效果显示
      gridPoints.forEach((point, index) => {
        const concentration = point.concentrations[timeIndex]
        
        // 检查点是否在湖泊边界内且浓度大于阈值
        const pointLatLng = L.latLng(point.lat, point.lng)
        if (concentration > 0.001 && isPointInLake(pointLatLng)) {
          const color = getConcentrationColor(concentration, maxConcentration.value)
          const circle = L.circleMarker([point.lat, point.lng], {
            radius: 3, // 减小半径避免过于密集
            fillColor: color,
            color: color,
            weight: 1,
            opacity: 0.7,
            fillOpacity: Math.min(0.8, concentration / maxConcentration.value * 0.7 + 0.1)
          })
          
          // 添加弹窗信息
          circle.bindPopup(`
            网格点 ${index + 1}<br>
            坐标: ${point.lat.toFixed(6)}, ${point.lng.toFixed(6)}<br>
            时间: ${formatTime(time)}<br>
            浓度: ${concentration.toFixed(6)} mg/L
          `)
          
          pollutionLayer.value.addLayer(circle)
        }
      })
    }
    
    const getConcentrationColor = (concentration, maxConcentration) => {
      if (concentration <= 0) return '#3498db' // 蓝色（无污染）
      
      const ratio = concentration / maxConcentration
      
      // 优化颜色阈值，在保持效果的同时减少计算复杂度
      if (ratio >= 0.4) return '#8e44ad' // 紫色（极高浓度）
      if (ratio >= 0.25) return '#e74c3c' // 红色（高浓度）
      if (ratio >= 0.15) return '#e67e22' // 橙色（中高浓度）
      if (ratio >= 0.06) return '#f1c40f' // 黄色（中浓度）
      if (ratio >= 0.015) return '#2ecc71' // 绿色（低浓度）
      return '#3498db' // 蓝色（极低浓度）
    }
    
    const formatTime = (minutes) => {
      const hours = Math.floor(minutes / 60)
      const mins = minutes % 60
      return `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}`
    }
    
    const onTimeChange = (event) => {
      const index = parseInt(event.target.value)
      currentTimeIndex.value = index
      currentTimeDisplay.value = formatTime(timeSteps.value[index])
      updateMapDisplay(index)
    }
    
    const clearSimulation = () => {
      // 清除模拟结果
      simulationResult.value = null
      currentTimeIndex.value = 0
      timeSteps.value = []
      
      // 清除图层
      if (pollutionLayer.value && props.map.hasLayer(pollutionLayer.value)) {
        props.map.removeLayer(pollutionLayer.value)
      }
      if (gridLayer.value && props.map.hasLayer(gridLayer.value)) {
        props.map.removeLayer(gridLayer.value)
      }
      
      // 重置状态
      gridGenerated.value = false
    }
    
    // 初始化湖泊选项
    const initializeLakeOptions = () => {
      if (props['water-areas-layer']) {
        const features = props['water-areas-layer'].toGeoJSON().features
        lakeOptions.value = features.map((feature, index) => ({
          id: feature.properties.osm_id || feature.properties.OSM_ID || index + 1,
          name: feature.properties.name || feature.properties.NAME || `湖泊${index + 1}`
        }))
      }
    }
    
    // 监听水系面图层变化
    watch(() => props['water-areas-layer'], () => {
      initializeLakeOptions()
    }, { immediate: true })
    
    return {
      // 状态
      panelVisible,
      selectedLake,
      selectedLakeName,
      lakeOptions,
      pollutionSourcePosition,
      pollutantType,
      pollutantMass,
      decayRate,
      pollutantOptions,
      lakeDepth,
      longitudinalVelocity,
      transverseVelocity,
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
      currentTimeIndex,
      timeSteps,
      currentTimeDisplay,
      maxConcentration,
      
      // 方法
      togglePanel,
      onPollutantChange,
      onLakeSelect,
      clearLakeSelection,
      clearPollutionSource,
      generateGrid,
      startSimulation,
      clearSimulation,
      onTimeChange
    }
  }
}

// 湖泊二维扩散模型
class LakeDiffusionModel {
  constructor(Ex, Ey, vx, vy, H, K1, m) {
    this.Ex = Ex // 纵向弥散系数
    this.Ey = Ey // 横向弥散系数
    this.vx = vx // 纵向流速
    this.vy = vy // 横向流速
    this.H = H   // 水深
    this.K1 = K1 // 一级降解系数
    this.m = m   // 污染物质量
    
    // 预计算常数
    this.constant = m / (2 * Math.PI * H * Math.sqrt(Ex * Ey))
  }
  
  // 基础扩散计算
  calculate(t, x, y) {
    if (t <= 0) return 0
    
    try {
      // 添加数值稳定性检查
      if (t < 0.001 || this.Ex <= 0 || this.Ey <= 0) {
        return 0
      }
      
      // 二维扩散方程解析解
      const part1 = this.constant / (t * Math.sqrt(t))
      const part2 = Math.pow(x - this.vx * t, 2) / (4 * this.Ex * t)
      const part3 = Math.pow(y - this.vy * t, 2) / (4 * this.Ey * t)
      const part4 = Math.exp(-this.K1 * t)
      
      const concentration = part4 * part1 * Math.exp(-part2 - part3)
      
      // 添加数值范围检查
      if (isNaN(concentration) || !isFinite(concentration)) {
        return 0
      }
      
      // 保留6位小数，小于阈值设为0
      const result = Math.round(concentration * 1000000) / 1000000
      return result < 0.000001 ? 0 : result
    } catch (error) {
      console.error('基础扩散计算出错:', error, { t, x, y })
      return 0
    }
  }
  
  // 增强扩散效果，确保高浓度区域明显
  calculateEnhanced(t, x, y) {
    if (t <= 0) return 0
    
    try {
      // 计算基础浓度
      const baseConcentration = this.calculate(t, x, y)
      
      // 计算到污染源的距离
      const distance = Math.sqrt(x * x + y * y)
      
      // 简化增强逻辑，减少计算量但保持效果
      if (distance < 150) { // 150米内增强效果
        const enhancement = Math.exp(-distance / 80) // 距离越近增强越明显
        const enhancedConcentration = baseConcentration * (1 + enhancement * 3.0) // 适中的增强倍数
        
        // 添加数值范围检查
        if (isNaN(enhancedConcentration) || !isFinite(enhancedConcentration)) {
          return baseConcentration
        }
        
        return enhancedConcentration
      }
      
      return baseConcentration
    } catch (error) {
      console.error('计算增强浓度时出错:', error, { t, x, y })
      return 0
    }
  }
}
</script>

<style scoped>
.lake-simulation-panel {
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
  padding: 15px 20px;
  border-bottom: 1px solid #eee;
}

.panel-header h3 {
  margin: 0;
  color: #2c3e50;
  font-size: 16px;
}

.close-btn {
  background: none;
  border: none;
  font-size: 20px;
  cursor: pointer;
  color: #7f8c8d;
}

.close-btn:hover {
  color: #e74c3c;
}

.panel-content {
  padding: 20px;
}

.step-section {
  margin-bottom: 25px;
}

.step-section h4 {
  margin: 0 0 15px 0;
  color: #34495e;
  font-size: 14px;
  font-weight: 600;
}

.param-group {
  margin-bottom: 15px;
}

.param-group label {
  display: block;
  margin-bottom: 5px;
  color: #7f8c8d;
  font-size: 12px;
}

.form-select,
.form-input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.form-select:focus,
.form-input:focus {
  outline: none;
  border-color: #3498db;
  box-shadow: 0 0 0 2px rgba(52, 152, 219, 0.2);
}

.lake-selection {
  margin-bottom: 15px;
}

.selection-info {
  margin-bottom: 10px;
}

.selection-hint {
  color: #7f8c8d;
  font-size: 12px;
  margin: 0;
  padding: 8px;
  background: #f8f9fa;
  border-radius: 4px;
  border-left: 3px solid #3498db;
}

.selected-lake {
  color: #27ae60;
  font-size: 12px;
  margin: 0;
  padding: 8px;
  background: #e8f5e8;
  border-radius: 4px;
  border-left: 3px solid #27ae60;
}

.selected-source {
  color: #e74c3c;
  font-size: 12px;
  margin: 0;
  padding: 8px;
  background: #fdf2f2;
  border-radius: 4px;
  border-left: 3px solid #e74c3c;
}

.clear-btn {
  background: #e74c3c;
  color: white;
  border: none;
  padding: 6px 12px;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  transition: background 0.3s ease;
}

.clear-btn:hover {
  background: #c0392b;
}

.action-buttons {
  display: flex;
  gap: 10px;
  margin-top: 20px;
}

.btn {
  flex: 1;
  padding: 10px 15px;
  border: none;
  border-radius: 4px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-primary {
  background: #3498db;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #2980b9;
}

.btn-success {
  background: #2ecc71;
  color: white;
}

.btn-success:hover:not(:disabled) {
  background: #27ae60;
}

.btn-warning {
  background: #f39c12;
  color: white;
}

.btn-warning:hover:not(:disabled) {
  background: #e67e22;
}

.progress-section {
  margin-top: 20px;
}

.progress {
  width: 100%;
  height: 8px;
  background: #f1f1f1;
  border-radius: 4px;
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  background: linear-gradient(90deg, #3498db, #2ecc71);
  transition: width 0.3s ease;
}

.progress-text {
  margin: 10px 0 0 0;
  text-align: center;
  color: #7f8c8d;
  font-size: 12px;
}

.time-control {
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #eee;
}

.time-control h4 {
  margin: 0 0 15px 0;
  color: #34495e;
  font-size: 14px;
  font-weight: 600;
}

.time-slider {
  width: 100%;
  margin: 10px 0;
}

.time-info {
  display: flex;
  justify-content: space-between;
  margin-top: 10px;
  font-size: 12px;
  color: #7f8c8d;
}

/* 滚动条样式 */
.lake-simulation-panel::-webkit-scrollbar {
  width: 6px;
}

.lake-simulation-panel::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 3px;
}

.lake-simulation-panel::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 3px;
}

.lake-simulation-panel::-webkit-scrollbar-thumb:hover {
  background: #a8a8a8;
}
</style> 
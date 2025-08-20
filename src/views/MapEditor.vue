<template>
  <div class="map-editor-container">
    <map-editor-header title="电子地图"></map-editor-header>
    
    <div class="map-editor-content">
      <div id="editor-map" class="editor-map" :class="{ 
        'zoom-in-cursor': activeMapTool === 'zoomIn',
        'zoom-out-cursor': activeMapTool === 'zoomOut',
        'grab-cursor': activeMapTool === 'pan',
        'grabbing-cursor': isPanning,
        'pointer-cursor': activeMapTool === 'selectFeature',
        'info-cursor': activeMapTool === 'identifyFeature',
        'rectangle-drawing': activeMapTool === 'rectangleZoom',
        'drawing-mode': isDrawing
      }"></div>
      <!-- 图层控制面板 -->
      <div class="control-panel" :class="{ 'panel-hidden': !showControlPanel }">
        <div class="panel-header">
          <h3>图层控制</h3>
          <button class="panel-toggle-btn" @click="toggleControlPanel">
            {{ showControlPanel ? '∧' : '∨' }}
          </button>
        </div>
        <div class="panel-content" v-show="showControlPanel">
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.districts" @change="toggleLayer('districts')">
            行政区划
          </label>
          <div class="layer-color-control">
            <div class="color-preview" :style="{ backgroundColor: layerColors.districts }" @click="showColorPicker('districts')"></div>
            <input type="color" v-model="layerColors.districts" @change="updateLayerColor('districts')" class="color-input" data-layer="districts" />
          </div>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.waterLines" @change="toggleLayer('waterLines')">
            河流
          </label>
          <div class="layer-color-control">
            <div class="color-preview" :style="{ backgroundColor: layerColors.waterLines }" @click="showColorPicker('waterLines')"></div>
            <input type="color" v-model="layerColors.waterLines" @change="updateLayerColor('waterLines')" class="color-input" data-layer="waterLines" />
          </div>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.beijingReservoirs" @change="toggleLayer('beijingReservoirs')">
            水库
          </label>
          <div class="layer-color-control">
            <div class="color-preview" :style="{ backgroundColor: layerColors.beijingReservoirs }" @click="showColorPicker('beijingReservoirs')"></div>
            <input type="color" v-model="layerColors.beijingReservoirs" @change="updateLayerColor('beijingReservoirs')" class="color-input" data-layer="beijingReservoirs" />
          </div>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.monitoringPoints" @change="toggleLayer('monitoringPoints')">
            监测点
          </label>
          <div class="layer-color-control">
            <div class="color-preview point-preview" :style="{ backgroundColor: layerColors.monitoringPoints }" @click="showColorPicker('monitoringPoints')"></div>
            <input type="color" v-model="layerColors.monitoringPoints" @change="updateLayerColor('monitoringPoints')" class="color-input" data-layer="monitoringPoints" />
          </div>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.settlements" @change="toggleLayer('settlements')">
            居民点
          </label>
          <div class="layer-color-control">
            <div class="color-preview point-preview" :style="{ backgroundColor: layerColors.settlements }" @click="showColorPicker('settlements')"></div>
            <input type="color" v-model="layerColors.settlements" @change="updateLayerColor('settlements')" class="color-input" data-layer="settlements" />
          </div>
        </div>
        </div>
      </div>
      <!-- 水库图片控制面板 -->
      <div v-if="showReservoirImgPanel" class="reservoir-img-panel">
        <span class="img-panel-close" @click="showReservoirImgPanel = false"></span>
        <img v-if="reservoirImgUrl" :src="reservoirImgUrl" :alt="reservoirImgName" class="reservoir-img-main" onerror="this.style.display='none'" />
        <div class="reservoir-img-title">{{ getPanelTitle() }}</div>
        
        <!-- 水库详细信息 -->
        <div v-if="currentQueryLayer === 'beijingReservoirs' && reservoirDetails[reservoirImgName]" class="reservoir-details">
          <div class="details-title">水库详细信息</div>
          <div class="details-table">
            <div class="detail-row">
              <span class="detail-label">中文名：</span>
              <span class="detail-value">{{ reservoirDetails[reservoirImgName]['中文名'] }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">面积：</span>
              <span class="detail-value">{{ reservoirDetails[reservoirImgName].面积 }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">所属地区：</span>
              <span class="detail-value">{{ reservoirDetails[reservoirImgName].所属地区 }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">平均水深：</span>
              <span class="detail-value">{{ reservoirDetails[reservoirImgName].平均水深 }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">建库时间：</span>
              <span class="detail-value">{{ reservoirDetails[reservoirImgName].建库时间 }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">水系：</span>
              <span class="detail-value">{{ reservoirDetails[reservoirImgName].水系 }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">投用时间：</span>
              <span class="detail-value">{{ reservoirDetails[reservoirImgName].投用时间 }}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">库容：</span>
              <span class="detail-value">{{ reservoirDetails[reservoirImgName].库容 }}</span>
            </div>
          </div>
          
          <!-- 功能按钮区域 -->
          <div class="reservoir-buttons">
            <button class="reservoir-btn reservoir-params-btn" @click="showReservoirParamsPanel = true">
              <span class="btn-icon">📊</span>
              水库参数
            </button>
            <button class="reservoir-btn flood-history-btn" @click="showFloodHistoryPanel = true">
              <span class="btn-icon">📚</span>
              防洪历史
            </button>
            <!-- 密云水库视频搜索按钮 -->
            <button v-if="reservoirImgName === '密云水库'" class="reservoir-btn search-video-btn" @click="searchReservoirVideo">
              <span class="btn-icon">🔍</span>
              搜索视频
            </button>
          </div>
        </div>
        
        <!-- 监测点详细信息 -->
        <div v-if="currentQueryLayer === 'monitoringPoints' && currentReservoirProps" class="monitoring-point-details">
          <div class="details-table">
            <div class="detail-row">
              <span class="detail-label">监测点名称：</span>
              <span class="detail-value">{{ currentReservoirProps.name || currentReservoirProps.库名 || currentReservoirProps.NAME || '未知' }}</span>
            </div>
            <div class="detail-row" v-if="currentReservoirProps.年平均氨氮">
              <span class="detail-label">年平均氨氮：</span>
              <span class="detail-value">{{ currentReservoirProps.年平均氨氮 }} mg/L</span>
            </div>
            <div class="detail-row" v-if="currentReservoirProps.年平均高猛酸盐">
              <span class="detail-label">年平均高猛酸盐：</span>
              <span class="detail-value">{{ currentReservoirProps.年平均高猛酸盐 }} mg/L</span>
            </div>
            <div class="detail-row" v-if="currentReservoirProps.年平均化学需氧量">
              <span class="detail-label">年平均化学需氧量：</span>
              <span class="detail-value">{{ currentReservoirProps.年平均化学需氧量 }} mg/L</span>
            </div>
            <div class="detail-row" v-if="currentReservoirProps.年平均流量">
              <span class="detail-label">年平均流量：</span>
              <span class="detail-value">{{ currentReservoirProps.年平均流量 }} m³/s</span>
            </div>
            <div class="detail-row" v-if="currentReservoirProps.年平均水深">
              <span class="detail-label">年平均水深：</span>
              <span class="detail-value">{{ currentReservoirProps.年平均水深 }} m</span>
            </div>
            <div class="detail-row" v-if="currentReservoirProps.年平均总氮">
              <span class="detail-label">年平均总氮：</span>
              <span class="detail-value">{{ currentReservoirProps.年平均总氮 }} mg/L</span>
            </div>
            <div class="detail-row" v-if="currentReservoirProps.年平均总磷">
              <span class="detail-label">年平均总磷：</span>
              <span class="detail-value">{{ currentReservoirProps.年平均总磷 }} mg/L</span>
            </div>
          </div>
        </div>
      </div>
      
      <!-- 水库参数面板 -->
      <div v-if="showReservoirParamsPanel" class="reservoir-params-panel">
        <span class="params-panel-close" @click="showReservoirParamsPanel = false">×</span>
        <div class="params-title">{{ getParamsPanelTitle() }}</div>
        <div class="params-content">
          <div v-if="currentReservoirProps" class="params-table">
            <!-- 根据图层类型显示不同的参数 -->
            <div v-if="currentQueryLayer === 'beijingReservoirs'">
              <!-- 水库参数字段 -->
              <div v-for="field in getReservoirParamFields()" :key="field.key" class="param-row">
                <span class="param-label">{{ field.label }}：</span>
                <span class="param-value">{{ formatReservoirParamValue(field.key, currentReservoirProps[field.key]) }}</span>
              </div>
            </div>
            <div v-else-if="currentQueryLayer === 'monitoringPoints'">
              <!-- 监测点参数字段 -->
              <div v-for="(value, key) in currentReservoirProps" :key="key" class="param-row">
                <span class="param-label">{{ getMonitoringPointDisplayName(key) }}：</span>
                <span class="param-value">{{ formatMonitoringPointValue(key, value) }}</span>
              </div>
            </div>
          </div>
          <div v-else class="no-data">
            <p>暂无水库参数数据</p>
          </div>
        </div>
      </div>
      
      <!-- 防洪历史面板 -->
      <div v-if="showFloodHistoryPanel" class="flood-history-panel">
        <span class="history-panel-close" @click="showFloodHistoryPanel = false">×</span>
        <div class="history-title">防洪历史</div>
        <div class="history-content">
          <!-- 怀柔水库防洪历史 -->
          <div v-if="reservoirImgName === '怀柔水库'" class="history-section">
            <h4>历史防洪表现</h4>
            <p>怀柔水库自建成至1985年（27年间），有14年入库洪峰流量大于150立方米/秒，10年大于350立方米/秒，6年大于450立方米/秒。其中1972年入库洪峰流量达4245立方米/秒，为历史最大洪峰，比1939年洪峰2400立方米/秒多1845立方米/秒，但未发生洪水灾害。</p>
          </div>
          <div v-if="reservoirImgName === '怀柔水库'" class="history-section">
            <h4>2023年防洪总结</h4>
            <p>2023年8月21日，水利部召开"23·7"海河流域特大洪水防御新闻发布会。密云、怀柔水库累计拦蓄洪水14.68亿立方米，降低了潮白河水位，为北运河以西分洪创造了有利条件。</p>
          </div>
          <div v-if="reservoirImgName === '怀柔水库'" class="history-section">
            <h4>2024年蓄水情况</h4>
            <p>2024年6月12日，北京市利用南水北调配套密云水库调蓄工程进行反向调水，密云水库、怀柔水库、大宁调节池、十三陵水库累计蓄水约8亿立方米。</p>
          </div>
          <div v-if="reservoirImgName === '怀柔水库'" class="history-section">
            <h4>2024年泄洪情况</h4>
            <p>2024年7月26日12时起，怀柔水库开始向怀河有序泄洪，采用预泄方式，在确保下游安全的前提下，考虑上游来水情况。</p>
          </div>
          
          <!-- 密云水库防洪历史 -->
          <div v-if="reservoirImgName === '密云水库'" class="history-section">
            <h4>水库概况</h4>
            <p>密云水库是北京市最大的水库，总库容43.75亿立方米，是北京市重要的饮用水源地，承担着防洪、供水、生态等多重功能。</p>
          </div>
          <div v-if="reservoirImgName === '密云水库'" class="history-section">
            <h4>防洪功能</h4>
            <p>密云水库是潮白河流域的重要防洪工程，通过拦蓄洪水，有效保护下游北京城区和周边地区的防洪安全。水库建成以来，在多次大洪水期间发挥了重要的防洪作用。</p>
          </div>
          <div v-if="reservoirImgName === '密云水库'" class="history-section">
            <h4>2023年防洪表现</h4>
            <p>在2023年"23·7"海河流域特大洪水防御中，密云水库与怀柔水库协同作战，累计拦蓄洪水14.68亿立方米，为保障北京城市防洪安全做出了重要贡献。</p>
          </div>
          <div v-if="reservoirImgName === '密云水库'" class="history-section">
            <h4>供水保障</h4>
            <p>密云水库是北京市重要的饮用水源地，通过南水北调工程，为北京市提供优质的水源保障，确保城市供水安全。</p>
          </div>
          
          <!-- 北台上水库防洪历史 -->
          <div v-if="reservoirImgName === '北台上水库'" class="history-section">
            <h4>水库概况</h4>
            <p>北台上水库位于北京市怀柔区，是一座中型水库，总库容1.2亿立方米，主要承担防洪、供水、灌溉等综合功能。</p>
          </div>
          <div v-if="reservoirImgName === '北台上水库'" class="history-section">
            <h4>防洪功能</h4>
            <p>北台上水库是潮白河流域的重要防洪工程，通过拦蓄洪水，有效保护下游地区的防洪安全，在多次洪水期间发挥了重要作用。</p>
          </div>
          <div v-if="reservoirImgName === '北台上水库'" class="history-section">
            <h4>供水作用</h4>
            <p>北台上水库为周边地区提供农业灌溉用水和生态补水，是区域水资源调配的重要组成部分。</p>
          </div>
          <div v-if="reservoirImgName === '北台上水库'" class="history-section">
            <h4>生态价值</h4>
            <p>北台上水库周边生态环境良好，是重要的湿地生态系统，为野生动植物提供了良好的栖息环境。</p>
          </div>
          
          <!-- 十三陵水库防洪历史 -->
          <div v-if="reservoirImgName === '十三陵水库'" class="history-section">
            <h4>水库概况</h4>
            <p>十三陵水库位于北京市昌平区，是一座中型水库，总库容2.8亿立方米，主要承担防洪、供水、灌溉等综合功能，是温榆河流域的重要水利工程。</p>
          </div>
          <div v-if="reservoirImgName === '十三陵水库'" class="history-section">
            <h4>防洪功能</h4>
            <p>十三陵水库是温榆河流域的重要防洪工程，通过拦蓄洪水，有效保护下游北京城区和周边地区的防洪安全，在多次洪水期间发挥了重要作用。</p>
          </div>
          <div v-if="reservoirImgName === '十三陵水库'" class="history-section">
            <h4>供水作用</h4>
            <p>十三陵水库为昌平区及周边地区提供农业灌溉用水和生态补水，是区域水资源调配的重要组成部分，保障了区域供水安全。</p>
          </div>
          <div v-if="reservoirImgName === '十三陵水库'" class="history-section">
            <h4>旅游价值</h4>
            <p>十三陵水库周边环境优美，是重要的旅游休闲场所，与明十三陵景区相呼应，形成了独特的人文景观。</p>
          </div>
          
          <!-- 官厅水库防洪历史 -->
          <div v-if="reservoirImgName === '官厅水库'" class="history-section">
            <h4>水库概况</h4>
            <p>官厅水库位于北京市延庆区，是一座大型水库，总库容41.6亿立方米，是北京市最大的水库之一，主要承担防洪、供水、发电等综合功能，是永定河流域的重要水利工程。</p>
          </div>
          <div v-if="reservoirImgName === '官厅水库'" class="history-section">
            <h4>防洪功能</h4>
            <p>官厅水库是永定河流域的重要防洪工程，通过拦蓄洪水，有效保护下游北京城区和周边地区的防洪安全，在多次特大洪水期间发挥了关键作用。</p>
          </div>
          <div v-if="reservoirImgName === '官厅水库'" class="history-section">
            <h4>供水作用</h4>
            <p>官厅水库为北京市提供重要的饮用水源，通过南水北调工程，为北京城市供水系统提供补充水源，保障了首都供水安全。</p>
          </div>
          <div v-if="reservoirImgName === '官厅水库'" class="history-section">
            <h4>发电功能</h4>
            <p>官厅水库建有水力发电站，为北京市提供清洁能源，是北京市重要的可再生能源基地之一。</p>
          </div>
          
          <!-- 崇青水库防洪历史 -->
          <div v-if="reservoirImgName === '崇青水库'" class="history-section">
            <h4>水库概况</h4>
            <p>崇青水库位于北京市怀柔区，是一座小型水库，总库容0.8亿立方米，主要承担防洪、灌溉、生态补水等综合功能，是潮白河流域的重要水利工程。</p>
          </div>
          <div v-if="reservoirImgName === '崇青水库'" class="history-section">
            <h4>防洪功能</h4>
            <p>崇青水库是潮白河流域的重要防洪工程，通过拦蓄洪水，有效保护下游地区的防洪安全，在多次洪水期间发挥了重要作用。</p>
          </div>
          <div v-if="reservoirImgName === '崇青水库'" class="history-section">
            <h4>灌溉作用</h4>
            <p>崇青水库为周边农田提供灌溉用水，保障了农业生产的稳定，是区域农业发展的重要水源保障。</p>
          </div>
          <div v-if="reservoirImgName === '崇青水库'" class="history-section">
            <h4>生态价值</h4>
            <p>崇青水库周边生态环境良好，为野生动植物提供了良好的栖息环境，是重要的生态保护区域。</p>
          </div>
          
          <!-- 斋堂水库防洪历史 -->
          <div v-if="reservoirImgName === '斋堂水库'" class="history-section">
            <h4>水库概况</h4>
            <p>斋堂水库位于北京市门头沟区，是一座中型水库，总库容1.5亿立方米，主要承担防洪、供水、灌溉等综合功能，是永定河流域的重要水利工程。</p>
          </div>
          <div v-if="reservoirImgName === '斋堂水库'" class="history-section">
            <h4>防洪功能</h4>
            <p>斋堂水库是永定河流域的重要防洪工程，通过拦蓄洪水，有效保护下游门头沟区和周边地区的防洪安全，在多次洪水期间发挥了重要作用。</p>
          </div>
          <div v-if="reservoirImgName === '斋堂水库'" class="history-section">
            <h4>供水作用</h4>
            <p>斋堂水库为门头沟区及周边地区提供生活用水和农业灌溉用水，是区域水资源调配的重要组成部分。</p>
          </div>
          <div v-if="reservoirImgName === '斋堂水库'" class="history-section">
            <h4>生态保护</h4>
            <p>斋堂水库周边生态环境优美，是重要的生态保护区域，为野生动植物提供了良好的栖息环境。</p>
          </div>
        </div>
      </div>
      
      <!-- 自定义工具栏 -->
      <div class="custom-toolbar">
        <img src="/icons/打开mxd.png" alt="打开mxd" title="打开mxd" @click="openMxdFile" />
        <div class="zoom-dropdown-container">
          <img src="/icons/放大.png" alt="放大" title="放大" @click="toggleZoomMenu" :class="{ 'active-tool': activeMapTool === 'zoomIn' || activeMapTool === 'rectangleZoom' }" />
          <div v-if="showZoomDropdown" class="zoom-dropdown">
            <div class="zoom-option" @click="activateZoomIn">
              <span>按点放大</span>
            </div>
            <div class="zoom-option" @click="activateRectangleZoom">
              <span>拉框放大</span>
            </div>
          </div>
        </div>
        
        <!-- 取消绘制按钮 -->
        <div v-if="isDrawing" class="cancel-drawing-btn" @click="cancelDrawing">
          <span>❌</span>
        </div>
        <div class="zoom-dropdown-container zoom-out-container">
          <img src="/icons/缩小.png" alt="缩小" title="缩小" @click="toggleZoomOutMenu" :class="{ 'active-tool': activeMapTool === 'zoomOut' || activeMapTool === 'rectangleZoomOut' }" />
          <div v-if="showZoomOutDropdown" class="zoom-dropdown">
            <div class="zoom-option" @click="activateZoomOut">
              <span>按点缩小</span>
            </div>
            <div class="zoom-option" @click="activateRectangleZoomOut">
              <span>拉框缩小</span>
            </div>
          </div>
        </div>
        <img src="/icons/全图.png" alt="全图" title="全图" @click="viewFullExtent" />
        <img src="/icons/手.png" alt="平移" title="平移" @click="activatePan" :class="{ 'active-tool': activeMapTool === 'pan' }" />
        <img src="/icons/选择要素.png" alt="选择要素" title="选择要素" @click="activateSelectFeature" :class="{ 'active-tool': activeMapTool === 'selectFeature' }" />
        <!-- 新增：查询按钮 -->
        <img src="/icons/查询.png" alt="查询" title="查询" @click="activateQuery" :class="{ 'active-tool': activeMapTool === 'query' }" />
        <!-- 新增：渲染按钮 -->
        <img src="/icons/渲染.png" alt="水库监测数据可视化渲染" title="水库监测数据可视化渲染" @click="activateRender" :class="{ 'active-tool': activeMapTool === 'render' }" />
        <img src="/icons/识别要素.png" alt="识别要素" title="识别要素" @click="activateIdentifyFeature" :class="{ 'active-tool': activeMapTool === 'identifyFeature' }" />
        <img 
          src="/icons/标注.png" 
          alt="标注" 
          title="标注" 
          @click="activateAnnotation" 
        />
        <img 
          src="/icons/左箭头.png" 
          alt="返回上一视图" 
          title="返回上一视图" 
          @click="goToPreviousView" 
          :class="{ 'disabled-tool': !canGoBack }"
        />
        <img 
          src="/icons/右箭头.png" 
          alt="转至下一视图" 
          title="转至下一视图" 
          @click="goToNextView" 
          :class="{ 'disabled-tool': !canGoForward }"
        />

      </div>

      
      <!-- 查询弹窗 -->
      <div v-if="activeMapTool === 'query'" class="search-bar-modal" ref="queryPopup">
        <div class="search-bar-container">
          <div class="search-header" @mousedown="startQueryPopupDrag" @touchstart="startQueryPopupDrag">
            <h3>图层查询</h3>
            <div class="search-header-controls">
              <span class="search-reset" @click="resetQueryPopupPosition" title="重置位置">↺</span>
              <span class="search-close" @click="activeMapTool = ''">×</span>
            </div>
          </div>
          
          <!-- 图层选择 -->
          <div class="layer-selection">
            <label class="layer-selection-label">选择查询图层：</label>
            <select v-model="selectedQueryLayer" class="layer-select-dropdown">
              <option value="monitoringPoints">监测点</option>
              <option value="beijingReservoirs">水库</option>
              <option value="settlements">居民点</option>
              <option value="districts">行政区划</option>
              <option value="waterLines">河流</option>
            </select>
          </div>
          
          <!-- 查询输入 -->
          <div class="search-input-container">
            <input
              v-model="searchText"
              @keyup.enter="handleSearch"
              class="search-input"
              :placeholder="getSearchPlaceholder()"
              autofocus
            />
            <button class="search-btn" @click="handleSearch">查询</button>
          </div>
        </div>
        <div v-if="searchError" class="search-error">{{ searchError }}</div>
      </div>
      <!-- 加载提示 -->
      <div class="loading-overlay" v-if="loading">
        <div class="loading-spinner"></div>
        <div class="loading-text">正在加载地理数据...</div>
        <div class="loading-progress">
          <div class="progress-bar">
            <div class="progress-fill" :style="{ width: loadingProgress + '%' }"></div>
          </div>
          <div class="progress-text">{{ loadingProgress }}%</div>
        </div>
        <button @click="forceCloseLoading" class="force-close-btn">跳过加载</button>
      </div>
      <!-- MXD文件选择输入框（隐藏） -->
      <input 
        type="file" 
        ref="mxdFileInput"
        style="display: none"
        @change="handleMxdFileSelected"
        accept=".mxd"
      />
      <!-- MXD图层控制面板 -->
      <div v-if="showMxdPanel" class="mxd-control-panel">
        <div class="mxd-panel-header">
          <h3>{{ currentMxdFile ? currentMxdFile.name : 'MXD文档' }}</h3>
          <span class="mxd-close-btn" @click="showMxdPanel = false">×</span>
        </div>
        <div class="mxd-panel-content">
          <!-- MXD文档图层列表 -->
          <div class="mxd-layer-list">
            <div class="mxd-layer-group">
              <div class="mxd-layer-group-header">
                <img class="folder-icon" src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiIgZmlsbD0iY3VycmVudENvbG9yIiBjbGFzcz0iYmkgYmkgZm9sZGVyMi1vcGVuIiB2aWV3Qm94PSIwIDAgMTYgMTYiPgogIDxwYXRoIGQ9Ik0xIDMuNUExLjUgMS41IDAgMCAxIDIuNSAyaDIuNzY0Yy4wNTggMCAuMTE1LjAxNy4xNjcuMDQ4LjA1Mi4wMzEuMS4wNzQuMTM0LjEyNkw2LjcwNyAzLjVIMTMuNWEuNSA1IDAgMCAxIDAgMUg2LjcwN2wtMS4xNDMgMS4zNTJBLjUuNSAwIDAgMSA1LjIzNiA2SDIuNUEuNS41IDAgMCAxIDIgNS41VjR6TTIuNSAzaDIuNzY0Yy4wNTggMCAuMTE1LjAxNy4xNjcuMDQ4LjA1Mi4wMzEuMS4wNzQuMTM0LjEyNkw2LjcwNyA0LjVIMTMuNWEuNS41IDAgMCAxIC41LjV2N2ExLjUgMS41IDAgMCAxLTEuNSAxLjVoLTlBMS41IDEuNSAwIDAgMSAyIDEyVjYuNWguNVYxMmExIDEgMCAwIDAgMSAxaDlhMSAxIDAgMCAwIDEtMVY1aC05LjVhLjUuNSAwIDAgMS0uNDI4LS4yMzJsLTEuMjQxLTEuNTM4QTEuNSAxLjUgMCAwIDAgLjk1IDNIMi41eiIvPgogPC9zdmc+" />
                <span>图展</span>
              </div>
              <div class="mxd-layer-items">
                <div v-for="layer in mockMxdLayerData.slice(1)" 
                     :key="layer.id" 
                     class="mxd-layer-item" 
                     :style="{ marginLeft: '20px' }">
                  <input 
                    type="checkbox" 
                    :id="'mxd-layer-' + layer.id" 
                    v-model="layer.visible"
                    @change="toggleMxdLayer(layer)"
                  >
                  <label :for="'mxd-layer-' + layer.id" class="layer-label">
                    <span class="layer-icon" :style="getLayerIconStyle(layer)"></span>
                    <span class="layer-name">{{ layer.name }}</span>
                  </label>
                </div>
                <div v-if="mockMxdLayerData[0].children && mockMxdLayerData[0].children.length" 
                     class="mxd-layer-item">
                  <input 
                    type="checkbox" 
                    :id="'mxd-layer-beijing-resident-places'" 
                    v-model="mockMxdLayerData[0].children[0].visible"
                    @change="toggleMxdLayer(mockMxdLayerData[0].children[0])"
                  >
                  <label :for="'mxd-layer-beijing-resident-places'" class="layer-label">
                    <span class="layer-icon point-icon"></span>
                    <span class="layer-name">居民地地名</span>
                  </label>
                </div>
              </div>
            </div>
          </div>
          
          <!-- MXD文档属性 -->
          <div class="mxd-properties">
            <h4>文档属性</h4>
            <div class="mxd-property-item">
              <span>文件大小:</span>
              <span>592.00 KB</span>
            </div>
            <div class="mxd-property-item">
              <span>修改日期:</span>
              <span>2025/4/11 17:16:19</span>
            </div>
            <div class="mxd-property-item">
              <span>图层数量:</span>
              <span>8</span>
            </div>
          </div>
        </div>
      </div>
      <!-- 渲染对话框 -->
      <div v-if="activeMapTool === 'render'" class="render-modal">
        <div class="render-modal-content">
          <div class="render-modal-header">
            <span>数据分级渲染</span>
            <span class="render-modal-close" @click="activeMapTool = ''">×</span>
          </div>
          <div class="render-modal-body">
            <div class="render-row">
              <label>图层：</label>
              <select v-model="selectedRenderLayer" class="render-select" @change="onLayerChange">
                <option value="monitoringPoints">监测点</option>
                <option value="beijingReservoirs">水库</option>
              </select>
            </div>
            <div class="render-row">
              <label>字段：</label>
              <select v-model="renderField" class="render-select" @change="onFieldChange">
                <option v-for="field in currentLayerFieldsWithUnits" :key="field.value" :value="field.value">{{ field.label }}</option>
              </select>
            </div>
            <div class="render-row">
              <label>分级：</label>
              <select v-model="gradeCount" class="render-select" @change="onGradeCountChange">
                <option v-for="n in 6" :key="n" :value="n">{{ n }}级</option>
              </select>
            </div>
            
            <!-- 分级预览 -->
            <div class="grade-preview" v-if="gradeRanges.length > 0">
              <h4>分级预览</h4>
              <div class="grade-preview-items">
                <div v-for="(grade, index) in gradeRanges" :key="index" class="grade-preview-item">
                  <div class="grade-color-preview" :style="{ backgroundColor: grade.color }"></div>
                  <div class="grade-range-text">
                    <span class="grade-level">第{{ index + 1 }}级</span>
                    <span class="grade-value">{{ grade.min }} - {{ grade.max }}</span>
                  </div>
                </div>
              </div>
            </div>
            
            <div class="render-row">
              <button class="render-btn" @click="handleNaturalBreaksRender">渲染</button>
              <button class="render-reset-btn" @click="resetRender">重置</button>
            </div>
            <div v-if="renderError" class="render-error">{{ renderError }}</div>
          </div>
        </div>
      </div>
      
      <!-- 图例显示 -->
      <div v-if="showLegend" class="legend-panel">
        <div class="legend-header">
          <h4>{{ legendTitle }}</h4>
          <span class="legend-close" @click="showLegend = false">×</span>
        </div>
        <div class="legend-content">
          <div v-for="(grade, index) in legendGrades" :key="index" class="legend-item">
            <div class="legend-color" :style="{ backgroundColor: grade.color }"></div>
            <div class="legend-text">
              <span class="legend-range">{{ grade.min }} - {{ grade.max }}</span>
              <span class="legend-count">({{ grade.count }}个)</span>
            </div>
          </div>
        </div>
      </div>
      
      <!-- 标注控制面板 -->
      <div v-if="annotationSystem.isActive" class="annotation-control-panel" ref="annotationControlPanel">
        <div class="annotation-panel-header" @mousedown="startPanelDrag" @touchstart="startPanelDrag">
          <h4>标注控制</h4>
          <div class="annotation-panel-controls">
            <span class="annotation-panel-reset" @click="resetPanelPosition" title="重置位置">🔄</span>
            <span class="annotation-panel-close" @click="annotationSystem.isActive = false">×</span>
          </div>
        </div>
        <div class="annotation-panel-content">
          <!-- 图层和字段选择 -->
          <div class="annotation-section">
            <h5>图层和字段选择</h5>
            <div class="control-item">
              <label>选择图层:</label>
              <select v-model="annotationSystem.selectedLayer" @change="onAnnotationLayerChange" class="annotation-select">
                <option value="monitoringPoints">监测点</option>
                <option value="beijingReservoirs">水库</option>
                <option value="settlements">居民点</option>
                <option value="districts">行政区划</option>
                <option value="waterLines">河流</option>
              </select>
            </div>
            <div class="control-item">
              <label>选择字段:</label>
              <select v-model="annotationSystem.selectedField" @change="onAnnotationFieldChange" class="annotation-select">
                <option v-for="field in annotationSystem.availableFields" :key="field.value" :value="field.value">
                  {{ field.label }}
                </option>
              </select>
            </div>
            <div class="control-item">
              <button @click="generateFieldAnnotations" class="annotation-btn">生成字段标注</button>
            </div>
          </div>
          
          <!-- 标注显示控制 -->
          <div class="annotation-section">
            <h5>显示控制</h5>
            <div class="control-item">
              <label>
                <input type="checkbox" v-model="annotationSystem.showAutoLabels" @change="updateAnnotationDisplay">
                显示自动标注
              </label>
            </div>
            <div class="control-item">
              <label>
                <input type="checkbox" v-model="annotationSystem.showManualLabels">
                显示手动标注
              </label>
            </div>
            <div class="control-item">
              <label>
                <input type="checkbox" v-model="annotationSystem.overlapAvoidance" @change="updateAnnotationDisplay">
                重叠避让
              </label>
            </div>
          </div>
          
          <!-- 缩放控制 -->
          <div class="annotation-section">
            <h5>缩放控制</h5>
            <div class="control-item">
              <label>最小缩放:</label>
              <input type="number" v-model="annotationSystem.minZoom" min="1" max="20" @change="updateAnnotationVisibility">
            </div>
            <div class="control-item">
              <label>最大缩放:</label>
              <input type="number" v-model="annotationSystem.maxZoom" min="1" max="20" @change="updateAnnotationVisibility">
            </div>
          </div>
          
          <!-- 样式设置 -->
          <div class="annotation-section">
            <h5>样式设置</h5>
            <div class="control-item">
              <label>字体大小:</label>
              <input type="number" v-model="annotationSystem.currentStyle.fontSize" min="8" max="32" @change="updateAnnotationStyle">
            </div>
            <div class="control-item">
              <label>字体:</label>
              <select v-model="annotationSystem.currentStyle.fontFamily" @change="updateAnnotationStyle">
                <option value="Arial">Arial</option>
                <option value="Times New Roman">Times New Roman</option>
                <option value="Microsoft YaHei">微软雅黑</option>
                <option value="SimSun">宋体</option>
              </select>
            </div>
            <div class="control-item">
              <label>文字颜色:</label>
              <input type="color" v-model="annotationSystem.currentStyle.color" @change="updateAnnotationStyle">
            </div>
            <div class="control-item">
              <label>背景颜色:</label>
              <input type="color" v-model="annotationSystem.currentStyle.backgroundColor" @change="updateAnnotationStyle">
            </div>
            <div class="control-item">
              <label>边框颜色:</label>
              <input type="color" v-model="annotationSystem.currentStyle.borderColor" @change="updateAnnotationStyle">
            </div>
            <div class="control-item">
              <label>边框宽度:</label>
              <input type="number" v-model="annotationSystem.currentStyle.borderWidth" min="0" max="5" @change="updateAnnotationStyle">
            </div>
            <div class="control-item">
              <label>圆角:</label>
              <input type="number" v-model="annotationSystem.currentStyle.borderRadius" min="0" max="20" @change="updateAnnotationStyle">
            </div>
            <div class="control-item">
              <label>
                <input type="checkbox" v-model="annotationSystem.currentStyle.shadow" @change="updateAnnotationStyle">
                阴影效果
              </label>
            </div>
          </div>
          
          <!-- 操作按钮 -->
          <div class="annotation-section">
            <h5>操作</h5>
            <div class="control-item">
              <button @click="generateAutoAnnotations" class="annotation-btn">生成自动标注</button>
            </div>
            <div class="control-item">
              <button @click="clearAllAnnotations" class="annotation-btn annotation-btn-danger">清除所有标注</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, reactive, computed, nextTick } from 'vue'
import * as L from 'leaflet'
import MapEditorHeader from '../components/MapEditorHeader.vue'
import 'leaflet/dist/leaflet.css'

const map = ref(null)
const loading = ref(true)
const loadingProgress = ref(0)
const annotationControlPanel = ref(null)
const queryPopup = ref(null)

// 控制面板状态
const showControlPanel = ref(true)

// 图层状态
const layers = reactive({
  districts: true,
  waterLines: true,
  beijingReservoirs: true,
  settlements: false, // 默认不打开居民地图层
  monitoringPoints: true // 默认打开监测点图层
})

// 图层颜色配置
const layerColors = reactive({
  districts: '#b3e5fc',
  waterLines: '#64B5F6',
  beijingReservoirs: '#26C6DA',
  settlements: '#FFF176',
  monitoringPoints: '#FF5722'
})

// 图层对象
const layerObjects = reactive({
  districts: null,
  waterLines: null,
  beijingReservoirs: null,
  settlements: null,
  monitoringPoints: null
})

// 初始化地图
const initMap = () => {
  console.log('开始初始化地图...')
  
  try {
    // 检查地图容器是否存在
    const mapContainer = document.getElementById('editor-map')
    if (!mapContainer) {
      console.error('地图容器不存在')
      return
    }
    
    map.value = L.map('editor-map', {
      zoomControl: false,
      attributionControl: false,
      // 性能优化设置
      preferCanvas: true, // 使用Canvas渲染，提高性能
      updateWhenZooming: false, // 缩放时不更新瓦片，减少卡顿
      updateWhenIdle: true, // 空闲时更新瓦片
      keepBuffer: 2, // 保持缓冲区大小
      maxZoom: 18, // 设置最大缩放级别
      minZoom: 5, // 设置最小缩放级别
      // 平移优化设置
      inertia: true, // 启用惯性平移
      inertiaDeceleration: 3000, // 惯性减速度
      inertiaMaxSpeed: 3000, // 最大惯性速度
      // 渲染优化
      renderer: L.canvas({ padding: 0.5 }) // 使用Canvas渲染器
    }).setView([39.9042, 116.4074], 10)
    
    console.log('地图对象创建成功:', map.value)
    
    // 添加简单底图（如果网络有问题，使用备用方案）
    try {
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        // 瓦片加载优化
        updateWhenIdle: true,
        updateWhenZooming: false,
        keepBuffer: 2,
        maxNativeZoom: 18,
        maxZoom: 18
      }).addTo(map.value)
      console.log('底图添加成功')
    } catch (error) {
      console.log('底图加载失败，使用空白地图:', error)
    }
    
    // 优化地图事件监听器，减少频繁触发
    let moveEndTimeout
    map.value.on('move', () => {
      // 使用防抖处理move事件，避免频繁触发
      clearTimeout(moveEndTimeout)
      moveEndTimeout = setTimeout(() => {
        if (map.value) {
          const center = map.value.getCenter()
          const zoom = map.value.getZoom()
          addToHistory(center, zoom)
        }
      }, 100) // 100ms防抖
    })
    
    // 初始化历史记录
    addToHistory([39.9042, 116.4074], 10)
    
    // 设置地图事件监听器
    setupMapEventListeners()
    
    console.log('地图初始化完成')
    
  } catch (error) {
    console.error('地图初始化失败:', error)
    // 如果地图初始化失败，显示错误信息
    showZoomMessage('❌ 地图初始化失败，请刷新页面重试', 'warning')
  }
}

// 加载GeoJSON数据（Beijing-GeoJson-Tzy目录）
const loadGeoJSONData = async () => {
  console.log('开始加载地理数据...')
  
  // 设置更短的超时时间（5秒）
  const timeout = 5000
  const timeoutId = setTimeout(() => {
    console.log('数据加载超时，强制关闭加载状态')
    loading.value = false
    showBasicMap()
  }, timeout)
  
  const dataFiles = {
    districts: './Beijing-GeoJson-Tzy/北京区县界.json',
    waterLines: './Beijing-GeoJson-Tzy/北京市_水系线数据.json',
    beijingReservoirs: './Beijing-GeoJson-Tzy/北京市水库面.geojson',
    settlements: './Beijing-GeoJson-Tzy/居民地地名.json',
    monitoringPoints: './Beijing-GeoJson-Tzy/监测点.geojson'
  }
  
  let loadedCount = 0
  const totalFiles = Object.keys(dataFiles).length
  let hasSuccess = false
  
  for (const [key, filePath] of Object.entries(dataFiles)) {
    try {
      console.log(`正在加载${key}数据:`, filePath)
      
      // 设置单个请求的超时时间（3秒）
      const response = await Promise.race([
        fetch(filePath),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('请求超时')), 3000)
        )
      ])
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }
      
      const data = await response.json()
      console.log(`${key}数据加载成功，要素数量:`, data.features ? data.features.length : '未知')
      
      // 创建图层
      const layer = createGeoJSONLayer(key, data)
      if (layer) {
        layerObjects[key] = layer
        hasSuccess = true
        
        if (layers[key]) {
          layer.addTo(map.value)
          if (key === 'beijingReservoirs') {
            layer.bringToFront()
          }
        }
      }
      
      loadedCount++
      // 更新加载进度
      loadingProgress.value = Math.round((loadedCount / totalFiles) * 100)
      console.log(`进度: ${loadedCount}/${totalFiles} (${loadingProgress.value}%)`)
      
    } catch (error) {
      console.error(`加载${key}数据失败:`, error)
      loadedCount++
      // 即使失败也要更新进度
      loadingProgress.value = Math.round((loadedCount / totalFiles) * 100)
    }
  }
  
  // 清理超时定时器
  clearTimeout(timeoutId)
  
  // 关闭加载状态
  loading.value = false
  console.log('数据加载完成，成功加载的图层数量:', Object.keys(layerObjects).length)
  
  // 如果没有成功加载任何图层，显示基本地图
  if (!hasSuccess) {
    console.warn('所有数据加载失败，显示基本地图')
    showBasicMap()
  } else {
    // 预计算地图完整边界
    try {
      calculateFullMapBounds()
    } catch (error) {
      console.error('计算地图边界失败:', error)
    }
  }
}

// 创建GeoJSON图层的辅助函数
const createGeoJSONLayer = (key, data) => {
  try {
    const commonOptions = {
      renderer: L.canvas({ padding: 0.5 }),
      interactive: true,
      smoothFactor: 1,
      simplifyTolerance: 0.5
    }
    
    let layer
    if (key === 'monitoringPoints') {
      layer = L.geoJSON(data, {
        ...commonOptions,
        pointToLayer: (feature, latlng) => L.circleMarker(latlng, getLayerStyle(key)),
        onEachFeature: (feature, lyr) => {
          if (feature.properties) {
            lyr.bindPopup(getPopupContent(key, feature.properties))
          }
        }
      })
    } else if (key === 'beijingReservoirs') {
      layer = L.geoJSON(data, {
        ...commonOptions,
        style: getLayerStyle(key),
        onEachFeature: (feature, lyr) => {
          if (feature.properties) {
            lyr.bindPopup(getPopupContent('reservoirArea', feature.properties))
          }
        }
      })
    } else if (key === 'settlements') {
      layer = L.geoJSON(data, {
        ...commonOptions,
        pointToLayer: (feature, latlng) => L.circleMarker(latlng, getLayerStyle(key)),
        onEachFeature: (feature, lyr) => {
          if (feature.properties) {
            lyr.bindPopup(getPopupContent(key, feature.properties))
          }
        }
      })
    } else {
      layer = L.geoJSON(data, {
        ...commonOptions,
        style: getLayerStyle(key),
        onEachFeature: (feature, lyr) => {
          if (feature.properties) {
            lyr.bindPopup(getPopupContent(key, feature.properties))
          }
        }
      })
    }
    
    return layer
  } catch (error) {
    console.error(`创建${key}图层失败:`, error)
    return null
  }
}

// 显示基本地图的函数
const showBasicMap = () => {
  if (!map.value) return
  
  console.log('显示基本地图')
  
  // 添加北京市中心标记
  const beijingCenter = [39.9042, 116.4074]
  L.marker(beijingCenter).addTo(map.value)
    .bindPopup('北京市中心')
    .openPopup()
  
  // 添加北京市边界矩形
  const beijingBounds = L.latLngBounds(
    [39.4, 115.7], // 西南角
    [40.4, 117.4]  // 东北角
  )
  L.rectangle(beijingBounds, {
    color: '#1890ff',
    weight: 2,
    fillOpacity: 0.1
  }).addTo(map.value)
  
  // 设置地图视图到北京市范围
  map.value.fitBounds(beijingBounds)
  
  // 显示提示信息
  showZoomMessage('✅ 地图已加载完成，可以正常使用', 'success')
}

// 图层样式
const getLayerStyle = (layerType) => {
  const styles = {
    districts: {
      fillColor: layerColors.districts,
      weight: 2.5,
      opacity: 0.8,
      color: layerColors.districts,
      fillOpacity: 0.5,
      dashArray: '5, 8'
    },
    waterLines: {
      color: layerColors.waterLines,
      weight: 2.5,
      opacity: 0.9
    },
    beijingReservoirs: {
      fillColor: layerColors.beijingReservoirs,
      weight: 1.5,
      opacity: 0.9,
      color: layerColors.beijingReservoirs,
      fillOpacity: 0.8
    },
    settlements: {
      radius: 6,
      fillColor: layerColors.settlements,
      color: '#ffffff',
      weight: 1.5,
      opacity: 1,
      fillOpacity: 0.9
    },
    monitoringPoints: {
      radius: 8,
      fillColor: layerColors.monitoringPoints,
      color: '#fff',
      weight: 2,
      opacity: 1,
      fillOpacity: 0.95
    }
  }
  return styles[layerType] || {}
}

// 弹窗内容
const getPopupContent = (layerType, properties) => {
  let html = '<div class="popup-content">'
  
  // 定义需要过滤的字段
  const excludedFields = ['Id', 'Shape__']
  
  // 如果是水库面数据，添加额外的过滤字段
  if (layerType === 'reservoirArea') {
    excludedFields.push('osm_id', 'code', 'fclass', 'name', 'FID_1', 'F11')
  }
  
  // 监测点字段中文名称映射
  const monitoringPointFieldNames = {
    'name': '水库名',
    'NAME': '水库名',
    '年平均氨氮': '年平均氨氮',
    '年平均高猛酸盐': '年平均高猛酸盐',
    '年平均化学需氧量': '年平均化学需氧量',
    '年平均流量': '年平均流量',
    '年平均水深': '年平均水深',
    '年平均总氮': '年平均总氮',
    '年平均总磷': '年平均总磷'
  }
  
  // 水库面字段单位映射
  const reservoirFieldUnits = {
    '库名': '',
    '多年平均库水位': 'm',
    '多年平均蓄水量': '万m³',
    '多年日平均入库流量': 'm³/s',
    '多年日平均出库流量': 'm³/s',
    '总库容': '万m³',
    '汛限水位': 'm'
  }
  
  // 水库面字段中文名称映射
  const reservoirFieldNames = {
    '库名': '水库名称',
    '多年平均库水位': '多年平均库水位',
    '多年平均蓄水量': '多年平均蓄水量',
    '多年日平均入库流量': '多年日平均入库流量',
    '多年日平均出库流量': '多年日平均出库流量',
    '总库容': '总库容',
    '汛限水位': '汛限水位'
  }
  
  // 如果是水库面图层，优先显示重要信息
  if (layerType === 'reservoirArea') {
    const name = properties.name || properties.库名 || properties.NAME
    if (name) {
      html += `<div style="font-size: 18px; font-weight: bold; color: #2c3e50; margin-bottom: 15px; text-align: center; border-bottom: 2px solid #3498db; padding-bottom: 8px;">🏞️ ${name}</div>`
    }
    
    // 按重要性排序显示字段
    const importantFields = ['总库容', '多年平均库水位', '多年平均蓄水量', '汛限水位']
    for (const field of importantFields) {
      if (properties[field] && properties[field] !== 0) {
        const unit = reservoirFieldUnits[field] || ''
        const fieldName = reservoirFieldNames[field] || field
        const icon = field === '总库容' ? '📊' : field === '多年平均库水位' ? '🌊' : field === '多年平均蓄水量' ? '💧' : '⚠️'
        html += `<div style="margin: 8px 0; padding: 5px; background: #f8f9fa; border-radius: 4px;"><strong>${icon} ${fieldName}:</strong> <span style="color: #e74c3c; font-weight: bold;">${properties[field]}${unit ? ` ${unit}` : ''}</span></div>`
      }
    }
    
    // 显示其他字段
    for (const [key, value] of Object.entries(properties)) {
      if (excludedFields.includes(key) || importantFields.includes(key)) {
        continue
      }
      
      if (value !== null && value !== undefined && value !== 0) {
        const unit = reservoirFieldUnits[key] || ''
        const fieldName = reservoirFieldNames[key] || key
        html += `<div style="margin: 5px 0;"><strong>${fieldName}:</strong> ${value}${unit ? ` ${unit}` : ''}</div>`
      }
    }
    
    // 添加防洪历史提示
    if (name && ['怀柔水库', '密云水库', '北台上水库', '十三陵水库', '官厅水库', '崇青水库', '斋堂水库'].includes(name)) {
      html += `<div style="margin-top: 10px; padding: 8px; background: #e8f4fd; border-left: 4px solid #3498db; border-radius: 4px;"><strong>📚 防洪历史:</strong> 该水库有详细的防洪历史记录，请查看右侧面板。</div>`
    }
  } else if (layerType === 'monitoringPoints') {
    // 监测点图层的特殊处理
    for (const [key, value] of Object.entries(properties)) {
      // 跳过需要过滤的字段
      if (excludedFields.includes(key)) {
        continue
      }
      
      // 获取字段的中文名称
      const fieldName = monitoringPointFieldNames[key] || key
      
      // 根据字段选择单位映射
      const unit = fieldUnits[key] || ''
      
      const displayValue = value !== null && value !== undefined ? value : '未知'
      html += `<div><strong>${fieldName}:</strong> ${displayValue}${unit ? ` ${unit}` : ''}</div>`
    }
  } else {
    // 其他图层的原有逻辑
    for (const [key, value] of Object.entries(properties)) {
      // 跳过需要过滤的字段
      if (excludedFields.includes(key)) {
        continue
      }
      
      // 根据图层类型选择单位映射
      let unit = ''
      if (layerType === 'reservoirArea') {
        unit = reservoirFieldUnits[key] || ''
      } else {
        unit = fieldUnits[key] || ''
      }
      
      const displayValue = value !== null && value !== undefined ? value : '未知'
      html += `<div><strong>${key}:</strong> ${displayValue}${unit ? ` ${unit}` : ''}</div>`
    }
  }
  
  html += '</div>'
  return html
}

// 切换图层显示
const toggleLayer = (layerType) => {
  const layer = layerObjects[layerType]
  if (layer) {
    if (layers[layerType]) {
      if (!map.value.hasLayer(layer)) {
        layer.addTo(map.value)
        if (layerType === 'waterAreas' || layerType === 'reservoirs') {
          layer.bringToFront()
        }
      }
    } else {
      if (map.value.hasLayer(layer)) {
        map.value.removeLayer(layer)
      }
    }
    
    // 图层状态改变后，重新计算完整边界
    setTimeout(() => {
      calculateFullMapBounds()
    }, 100)
  }
}

// 地图工具激活方法
const activateZoomIn = () => {
  resetToolState()
  activeMapTool.value = 'zoomIn'
  showZoomDropdown.value = false
  console.log('激活按点放大模式，等待用户单击')
  console.log('当前activeMapTool值:', activeMapTool.value)
  
  // 强制更新DOM，确保CSS类正确应用
  nextTick(() => {
    const mapElement = document.getElementById('editor-map')
    if (mapElement) {
      console.log('地图容器CSS类:', mapElement.className)
      console.log('是否包含zoom-in-cursor类:', mapElement.classList.contains('zoom-in-cursor'))
      console.log('当前鼠标样式:', getComputedStyle(mapElement).cursor)
    }
  })
  
  // 禁用地图拖拽，避免鼠标样式冲突
  if (map.value) {
    map.value.dragging.disable()
    console.log('已禁用地图拖拽功能')
  }
  
  // 强制设置鼠标样式
  setTimeout(() => {
    forceSetZoomCursor()
    // 添加CSS类以支持样式
    const mapElement = document.getElementById('editor-map')
    if (mapElement) {
      mapElement.classList.add('zoom-in-cursor')
    }
  }, 100)
  
  showZoomMessage('🔍 请在地图上单击进行放大', 'info')
}

const activateZoomOut = () => {
  resetToolState()
  activeMapTool.value = 'zoomOut'
  showZoomOutDropdown.value = false
  console.log('激活按点缩小模式，等待用户单击')
  console.log('当前activeMapTool值:', activeMapTool.value)
  
  // 强制更新DOM，确保CSS类正确应用
  nextTick(() => {
    const mapElement = document.getElementById('editor-map')
    if (mapElement) {
      console.log('地图容器CSS类:', mapElement.className)
      console.log('是否包含zoom-out-cursor类:', mapElement.classList.contains('zoom-out-cursor'))
      console.log('当前鼠标样式:', getComputedStyle(mapElement).cursor)
    }
  })
  
  // 禁用地图拖拽，避免鼠标样式冲突
  if (map.value) {
    map.value.dragging.disable()
    console.log('已禁用地图拖拽功能')
  }
  
  // 强制设置鼠标样式
  setTimeout(() => {
    forceSetZoomOutCursor()
    // 添加CSS类以支持样式
    const mapElement = document.getElementById('editor-map')
    if (mapElement) {
      mapElement.classList.add('zoom-out-cursor')
    }
  }, 100)
  
  showZoomMessage('🔍 请在地图上单击进行缩小', 'info')
}

// 激活拉框缩小模式
const activateRectangleZoomOut = () => {
  console.log('=== 激活拉框缩小模式 ===')
  console.log('激活前的状态:', { 
    activeMapTool: activeMapTool.value, 
    zoomMode: zoomMode.value,
    isDrawing: isDrawing.value 
  })
  
  resetToolState()
  activeMapTool.value = 'rectangleZoomOut'
  showZoomOutDropdown.value = false
  
  console.log('激活后的状态:', { 
    activeMapTool: activeMapTool.value, 
    zoomMode: zoomMode.value,
    isDrawing: isDrawing.value 
  })
  
  // 设置绘制模式
  zoomMode.value = 'rectangle'
  console.log('设置zoomMode为rectangle后的状态:', { 
    activeMapTool: activeMapTool.value, 
    zoomMode: zoomMode.value,
    isDrawing: isDrawing.value 
  })
  
  // 开始绘制模式
  startDrawingMode()
}

const activatePan = () => {
  resetToolState()
  activeMapTool.value = 'pan'
  console.log('激活平移模式')
  
  if (map.value) {
    // 激活平移模式
    map.value.dragging.enable()
    
    // 应用平移性能优化
    optimizePanPerformance()
    
    // 优化鼠标样式和CSS类
    const mapElement = document.getElementById('editor-map')
    if (mapElement) {
      mapElement.style.cursor = 'grab'
      mapElement.classList.add('panning')
    }
    
    console.log('平移模式已激活，性能优化已应用')
  }
}

// 控制面板切换
const toggleControlPanel = () => {
  showControlPanel.value = !showControlPanel.value
}

// 鼠标样式控制
const isPanning = ref(false)

// 监听地图拖动事件
const setupMapEventListeners = () => {
  if (map.value) {
    console.log('设置地图事件监听器')
    
    // 优化拖拽事件监听器，减少性能开销
    let dragStartTime
    map.value.on('dragstart', () => {
      isPanning.value = true
      dragStartTime = Date.now()
      console.log('开始拖拽')
    })
    
    map.value.on('drag', () => {
      // 拖拽过程中不执行复杂操作，只更新状态
      if (!isPanning.value) {
        isPanning.value = true
      }
    })
    
    map.value.on('dragend', () => {
      isPanning.value = false
      const dragDuration = Date.now() - dragStartTime
      console.log(`拖拽结束，持续时间: ${dragDuration}ms`)
      
      // 拖拽结束后延迟执行复杂操作
      setTimeout(() => {
        if (map.value) {
          // 可以在这里添加拖拽完成后的操作
        }
      }, 50)
    })
    
    // 添加地图点击事件监听器
    map.value.on('click', handleMapClick)
    console.log('地图点击事件监听器已绑定')
    
    // 优化地图移动事件
    let moveTimeout
    map.value.on('move', () => {
      // 使用节流处理move事件，避免频繁触发
      if (!moveTimeout) {
        moveTimeout = setTimeout(() => {
          moveTimeout = null
          // 这里可以添加移动过程中的操作
        }, 16) // 约60fps的刷新率
      }
    })
    
    // 监听缩放变化，控制标注显示
    map.value.on('zoomend', () => {
      updateAnnotationVisibility()
      // 缩放完成后优化所有可见标注的渲染
      setTimeout(() => {
        annotationSystem.annotations.forEach(annotation => {
          if (annotation.isVisible && annotation.layer) {
            optimizeAnnotationRendering(annotation)
          }
        })
      }, 100)
    })
    
    // 监听地图大小变化，重新定位标注
    map.value.on('resize', () => {
      console.log('地图大小变化，重新定位标注')
      setTimeout(() => {
        repositionAnnotations()
      }, 100)
    })
    
    console.log('地图事件监听器设置完成，性能优化已应用')
  } else {
    console.error('地图未初始化，无法设置事件监听器')
  }
}

const activateSelectFeature = () => {
  resetToolState()
  activeMapTool.value = 'selectFeature'
  console.log('激活要素选择模式')
  
  // 设置选择要素的鼠标样式
  const mapElement = document.getElementById('editor-map')
  if (mapElement) {
    mapElement.style.cursor = 'pointer'
    console.log('已设置选择要素鼠标样式为pointer')
  }
  
  // 显示提示信息
  showZoomMessage('👆 请点击地图上的要素进行选择', 'info')
}

const activateIdentifyFeature = () => {
  resetToolState()
  activeMapTool.value = 'identifyFeature'
  console.log('激活要素识别模式')
  
  // 设置识别要素的鼠标样式
  const mapElement = document.getElementById('editor-map')
  if (mapElement) {
    mapElement.style.cursor = 'help'
    console.log('已设置识别要素鼠标样式为help')
  }
  
  // 显示提示信息
  showZoomMessage('❓ 请点击地图上的要素进行识别', 'info')
}

// 全图视图
const viewFullExtent = () => {
  if (map.value) {
    console.log('执行全图视图功能')
    
    // 优先使用预计算的完整边界
    if (fullMapBounds.value) {
      console.log('使用预计算的完整边界:', fullMapBounds.value)
      
      // 使用智能全图显示函数
      showOptimalFullExtent(fullMapBounds.value, '预计算边界')
      return
    }
    
    // 如果没有预计算的边界，实时计算
    console.log('没有预计算的边界，实时计算...')
    
    // 计算所有可见图层的边界范围
    const allBounds = []
    
    // 遍历所有可见的图层，收集边界信息
    Object.keys(layers).forEach(layerKey => {
      if (layers[layerKey] && layerObjects[layerKey]) {
        const layer = layerObjects[layerKey]
        if (layer && layer.getBounds) {
          try {
            const bounds = layer.getBounds()
            if (bounds && bounds.isValid && bounds.isValid()) {
              console.log(`${layerKey}图层边界:`, bounds)
              allBounds.push(bounds)
            }
          } catch (error) {
            console.log(`获取${layerKey}图层边界失败:`, error)
          }
        }
      }
    })
    
    console.log('收集到的边界数量:', allBounds.length)
    
    if (allBounds.length > 0) {
      // 合并所有边界
      let combinedBounds = allBounds[0]
      for (let i = 1; i < allBounds.length; i++) {
        combinedBounds = combinedBounds.extend(allBounds[i])
      }
      
      console.log('合并后的边界:', combinedBounds)
      
      // 检查边界是否有效
      if (combinedBounds && combinedBounds.isValid && combinedBounds.isValid()) {
        // 使用智能全图显示函数
        showOptimalFullExtent(combinedBounds, '实时计算边界')
      } else {
        console.log('合并后的边界无效，回退到默认视图')
        fallbackToDefaultView()
      }
    } else {
      console.log('没有有效的边界，回退到默认视图')
      fallbackToDefaultView()
    }
  }
}

// 智能全图显示函数
const showOptimalFullExtent = (bounds, source) => {
  if (!map.value || !bounds) return
  
  console.log(`使用${source}显示全图:`, bounds)
  
  // 获取地图容器尺寸
  const mapContainer = document.getElementById('editor-map')
  const containerWidth = mapContainer ? mapContainer.offsetWidth : 800
  const containerHeight = mapContainer ? mapContainer.offsetHeight : 600
  
  // 计算边界的经纬度范围
  const southWest = bounds.getSouthWest()
  const northEast = bounds.getNorthEast()
  const latDiff = Math.abs(northEast.lat - southWest.lat)
  const lngDiff = Math.abs(northEast.lng - southWest.lng)
  
  console.log('边界范围:', {
    latDiff: latDiff.toFixed(6),
    lngDiff: lngDiff.toFixed(6),
    containerSize: `${containerWidth}x${containerHeight}`
  })
  
  // 根据边界大小动态调整边距和缩放级别
  let padding, maxZoom, minZoom
  
  if (latDiff < 0.1 && lngDiff < 0.1) {
    // 小范围：增加边距，限制最大缩放
    padding = [80, 80]
    maxZoom = 16
    minZoom = 10
    console.log('小范围边界，使用大边距和高缩放')
  } else if (latDiff < 0.5 && lngDiff < 0.5) {
    // 中等范围：适中边距和缩放
    padding = [60, 60]
    maxZoom = 14
    minZoom = 8
    console.log('中等范围边界，使用适中边距和缩放')
  } else if (latDiff < 2.0 && lngDiff < 2.0) {
    // 大范围：小边距，限制缩放
    padding = [40, 40]
    maxZoom = 12
    minZoom = 6
    console.log('大范围边界，使用小边距和限制缩放')
  } else {
    // 超大范围：最小边距，严格限制缩放
    padding = [20, 20]
    maxZoom = 10
    minZoom = 5
    console.log('超大范围边界，使用最小边距和严格限制缩放')
  }
  
  // 计算合适的缩放级别
  const optimalZoom = calculateOptimalZoom(bounds, containerWidth, containerHeight, padding)
  console.log('计算的最佳缩放级别:', optimalZoom)
  
  // 使用fitBounds显示完整范围
  map.value.fitBounds(bounds, {
    padding: padding,
    maxZoom: Math.min(maxZoom, optimalZoom),
    minZoom: minZoom,
    animate: true,
    duration: 0.8
  })
  
  // 显示成功消息
  showFullExtentMessage(`✅ 已显示${source}全图视图 (缩放: ${Math.min(maxZoom, optimalZoom)})`)
  
  // 添加到历史记录
  setTimeout(() => {
    const center = map.value.getCenter()
    const zoom = map.value.getZoom()
    addToHistory(center, zoom)
  }, 1000)
}

// 计算最佳缩放级别
const calculateOptimalZoom = (bounds, containerWidth, containerHeight, padding) => {
  if (!bounds || !containerWidth || !containerHeight) return 10
  
  // 获取边界的经纬度范围
  const southWest = bounds.getSouthWest()
  const northEast = bounds.getNorthEast()
  const latDiff = Math.abs(northEast.lat - southWest.lat)
  const lngDiff = Math.abs(northEast.lng - southWest.lng)
  
  // 考虑边距后的可用容器尺寸
  const availableWidth = containerWidth - (padding[1] * 2)
  const availableHeight = containerHeight - (padding[0] * 2)
  
  // 计算经纬度到像素的比例
  const latPixels = availableHeight / latDiff
  const lngPixels = availableWidth / lngDiff
  
  // 取较小的比例，确保地图完全显示
  const pixelsPerDegree = Math.min(latPixels, lngPixels)
  
  // 根据像素密度计算合适的缩放级别
  // 每度约111km，假设标准屏幕96dpi
  const metersPerPixel = 111000 / pixelsPerDegree
  const zoom = Math.log2(156543.03392 / metersPerPixel)
  
  // 限制缩放级别范围
  const clampedZoom = Math.max(5, Math.min(18, Math.round(zoom)))
  
  console.log('缩放计算详情:', {
    latDiff: latDiff.toFixed(6),
    lngDiff: lngDiff.toFixed(6),
    availableSize: `${availableWidth}x${availableHeight}`,
    pixelsPerDegree: pixelsPerDegree.toFixed(2),
    metersPerPixel: metersPerPixel.toFixed(2),
    calculatedZoom: zoom.toFixed(2),
    finalZoom: clampedZoom
  })
  
  return clampedZoom
}

// 回退到默认视图
const fallbackToDefaultView = () => {
  if (map.value) {
    console.log('使用默认北京市视图范围')
    
    // 北京市的默认视图范围
    const beijingBounds = L.latLngBounds(
      [39.4, 115.7], // 西南角
      [40.4, 117.4]  // 东北角
    )
    
    console.log('默认边界范围:', beijingBounds)
    
    // 使用智能全图显示函数显示默认视图
    showOptimalFullExtent(beijingBounds, '北京市默认')
  }
}

// 强制关闭加载状态
const forceCloseLoading = () => {
  console.log('用户强制关闭加载状态并显示基本地图')
  loading.value = false
  loadingProgress.value = 0
  
  // 显示基本地图
  showBasicMap()
}

// 预计算地图完整边界
const fullMapBounds = ref(null)

const calculateFullMapBounds = () => {
  console.log('开始预计算地图完整边界')
  
  const allBounds = []
  
  // 遍历所有图层，收集边界信息
  Object.keys(layerObjects).forEach(layerKey => {
    const layer = layerObjects[layerKey]
    if (layer && layer.getBounds) {
      try {
        const bounds = layer.getBounds()
        if (bounds && bounds.isValid && bounds.isValid()) {
          console.log(`${layerKey}图层边界:`, bounds)
          allBounds.push(bounds)
        }
      } catch (error) {
        console.log(`预计算${layerKey}图层边界失败:`, error)
      }
    }
  })
  
  if (allBounds.length > 0) {
    // 合并所有边界
    let combinedBounds = allBounds[0]
    for (let i = 1; i < allBounds.length; i++) {
      combinedBounds = combinedBounds.extend(allBounds[i])
    }
    
    // 验证合并后的边界
    if (combinedBounds && combinedBounds.isValid && combinedBounds.isValid()) {
      // 检查边界是否合理
      const southWest = combinedBounds.getSouthWest()
      const northEast = combinedBounds.getNorthEast()
      const latDiff = Math.abs(northEast.lat - southWest.lat)
      const lngDiff = Math.abs(northEast.lng - southWest.lng)
      
      // 如果边界过大或过小，进行调整
      if (latDiff > 10 || lngDiff > 10) {
        console.log('边界过大，使用北京市范围')
        fullMapBounds.value = L.latLngBounds(
          [39.4, 115.7], // 西南角
          [40.4, 117.4]  // 东北角
        )
      } else if (latDiff < 0.01 || lngDiff < 0.01) {
        console.log('边界过小，扩展范围')
        const center = combinedBounds.getCenter()
        const expandedBounds = L.latLngBounds(
          [center.lat - 0.1, center.lng - 0.1],
          [center.lat + 0.1, center.lng + 0.1]
        )
        fullMapBounds.value = expandedBounds
      } else {
        fullMapBounds.value = combinedBounds
      }
      
      console.log('预计算完成，最终边界:', fullMapBounds.value)
      console.log('边界范围:', {
        latDiff: latDiff.toFixed(6),
        lngDiff: lngDiff.toFixed(6)
      })
    } else {
      console.log('合并后的边界无效，使用默认边界')
      fullMapBounds.value = L.latLngBounds(
        [39.4, 115.7], // 西南角
        [40.4, 117.4]  // 东北角
      )
    }
  } else {
    console.log('没有有效的边界，使用默认边界')
    fullMapBounds.value = L.latLngBounds(
      [39.4, 115.7], // 西南角
      [40.4, 117.4]  // 东北角
    )
  }
}

// 显示全图视图提示信息
const showFullExtentMessage = (message) => {
  // 创建提示元素
  const messageDiv = document.createElement('div')
  messageDiv.className = 'full-extent-message'
  messageDiv.textContent = message
  
  // 添加到地图容器
  const mapContainer = document.getElementById('editor-map')
  if (mapContainer) {
    mapContainer.appendChild(messageDiv)
    
    // 2秒后自动移除
    setTimeout(() => {
      if (messageDiv.parentNode) {
        messageDiv.parentNode.removeChild(messageDiv)
      }
    }, 2000)
  }
}

// 历史视图函数
const goToPreviousView = () => {
  if (canGoBack.value && currentViewIndex.value > 0) {
    currentViewIndex.value--
    const view = viewHistory.value[currentViewIndex.value]
    if (map.value && view) {
      map.value.setView(view.center, view.zoom, { animate: true })
    }
    updateNavigationButtons()
  }
}

const goToNextView = () => {
  if (canGoForward.value && currentViewIndex.value < viewHistory.value.length - 1) {
    currentViewIndex.value++
    const view = viewHistory.value[currentViewIndex.value]
    if (map.value && view) {
      map.value.setView(view.center, view.zoom, { animate: true })
    }
    updateNavigationButtons()
  }
}

const updateNavigationButtons = () => {
  canGoBack.value = currentViewIndex.value > 0
  canGoForward.value = currentViewIndex.value < viewHistory.value.length - 1
}

const addToHistory = (center, zoom) => {
  // 移除当前位置之后的历史记录
  viewHistory.value = viewHistory.value.slice(0, currentViewIndex.value + 1)
  // 添加新的视图
  viewHistory.value.push({ center, zoom })
  currentViewIndex.value = viewHistory.value.length - 1
  updateNavigationButtons()
}

// MXD文件处理
const openMxdFile = () => {
  mxdFileInput.value.click()
}

const handleMxdFileSelected = (event) => {
  const file = event.target.files[0]
  if (file) {
    currentMxdFile.value = file
    showMxdPanel.value = true
    // 这里可以添加MXD文件解析逻辑
  }
}

// MXD图层控制
const toggleMxdLayer = (layer) => {
  // 这里可以添加图层显示/隐藏逻辑
  console.log('Toggle MXD layer:', layer.name, layer.visible)
}

const getLayerIconStyle = (layer) => {
  const styles = {
    point: { backgroundColor: '#ff7800' },
    line: { backgroundColor: '#0066ff' },
    polygon: { backgroundColor: '#00ff00' }
  }
  return styles[layer.type] || { backgroundColor: '#999' }
}

// 图层颜色控制函数
const showColorPicker = (layerType) => {
  // 触发颜色选择器
  const colorInput = document.querySelector(`input[data-layer="${layerType}"]`)
  if (colorInput) {
    colorInput.click()
  }
}

const updateLayerColor = (layerType) => {
  const layer = layerObjects[layerType]
  if (layer && layers[layerType]) {
    // 更新图层样式
    const newStyle = getUpdatedLayerStyle(layerType)
    layer.setStyle(newStyle)
  }
}

const getUpdatedLayerStyle = (layerType) => {
  const baseStyles = {
    districts: {
      fillColor: layerColors.districts,
      weight: 2.5,
      opacity: 0.8,
      color: layerColors.districts,
      fillOpacity: 0.5,
      dashArray: '5, 8'
    },
    waterLines: {
      color: layerColors.waterLines,
      weight: 2.5,
      opacity: 0.9
    },
    waterAreas: {
      fillColor: layerColors.waterAreas,
      weight: 1.5,
      opacity: 0.9,
      color: layerColors.waterAreas,
      fillOpacity: 0.7
    },
    reservoirs: {
      fillColor: layerColors.reservoirs,
      weight: 1.5,
      opacity: 0.9,
      color: layerColors.reservoirs,
      fillOpacity: 0.8
    },
    settlements: {
      radius: 6,
      fillColor: layerColors.settlements,
      color: '#ffffff',
      weight: 1.5,
      opacity: 1,
      fillOpacity: 0.9
    },
    reservoirPoints: {
      radius: 7,
      fillColor: layerColors.reservoirPoints,
      color: '#fff',
      weight: 2,
      opacity: 1,
      fillOpacity: 0.95
    }
  }
  return baseStyles[layerType] || {}
}

// 查询和渲染工具激活方法
const activateQuery = () => {
  resetToolState()
  activeMapTool.value = 'query'
  console.log('激活查询模式')
  
  // 设置查询模式的鼠标样式
  const mapElement = document.getElementById('editor-map')
  if (mapElement) {
    mapElement.style.cursor = 'default'
    console.log('已设置查询模式鼠标样式为default')
  }
  
  // 显示提示信息
  showZoomMessage('🔍 请在地图上点击要素进行查询', 'info')
}

const activateRender = () => {
  resetToolState()
  activeMapTool.value = 'render'
  console.log('激活渲染模式')
  
  // 设置渲染模式的鼠标样式
  const mapElement = document.getElementById('editor-map')
  if (mapElement) {
    mapElement.style.cursor = 'default'
    console.log('已设置渲染模式鼠标样式为default')
  }
  
  // 显示提示信息
  showZoomMessage('🎨 请在地图上点击要素进行渲染', 'info')
}

const activateAnnotation = () => {
  resetToolState()
  activeMapTool.value = 'annotation'
  annotationSystem.isActive = true
  console.log('激活标注模式')
  
  // 初始化标注系统
  if (annotationSystem.availableFields.length === 0) {
    updateAvailableFields()
  }
  
  // 确保没有自动生成的标注
  clearAutoAnnotations()
  
  // 设置标注模式的鼠标样式
  const mapElement = document.getElementById('editor-map')
  if (mapElement) {
    mapElement.style.cursor = 'crosshair'
    console.log('已设置标注模式鼠标样式为crosshair')
  }
  
  // 显示提示信息
  showZoomMessage('📍 请在地图上点击位置进行标注，或使用控制面板管理字段标注', 'info')
}

// 标注系统相关变量
const annotationSystem = reactive({
  isActive: false,
  annotations: [],
  autoAnnotations: [],
  manualAnnotations: [],
  currentStyle: {
    fontSize: 16,
    fontFamily: 'Arial, sans-serif',
    color: '#000000',
    backgroundColor: 'transparent',
    borderColor: '#000000',
    borderWidth: 0,
    padding: 0,
    borderRadius: 0,
    shadow: false
  },
  showAutoLabels: true,
  showManualLabels: true,
  minZoom: 1,
  maxZoom: 20,
  overlapAvoidance: true,
  selectedLayer: 'monitoringPoints',
  selectedField: '年平均氨氮',
  availableFields: [
    { value: '年平均氨氮', label: '年平均氨氮' },
    { value: '年平均高猛酸盐', label: '年平均高猛酸盐' },
    { value: '年平均化学需氧量', label: '年平均化学需氧量' },
    { value: '年平均流量', label: '年平均流量' },
    { value: '年平均水深', label: '年平均水深' },
    { value: '年平均总氮', label: '年平均总氮' },
    { value: '年平均总磷', label: '年平均总磷' }
  ]
})

// 标注处理函数
const handleAnnotation = (latlng) => {
  if (!map.value) {
    console.error('地图未初始化')
    return
  }
  
  try {
    console.log('开始添加标注，位置:', latlng)
    
    // 创建手动标注
    const manualAnnotation = createManualAnnotation(latlng)
    annotationSystem.manualAnnotations.push(manualAnnotation)
    annotationSystem.annotations.push(manualAnnotation)
    
    // 显示成功消息
    showZoomMessage('✅ 手动标注添加成功', 'success')
    
    // 更新标注显示
    updateAnnotationDisplay()
    
  } catch (error) {
    console.error('添加标注失败:', error)
    showZoomMessage('❌ 添加标注失败', 'warning')
  }
}

// 创建手动标注
const createManualAnnotation = (latlng) => {
  const annotation = {
    id: 'manual_' + Date.now(),
    type: 'manual',
    latlng: latlng,
    text: '新标注',
    style: { ...annotationSystem.currentStyle },
    isEditing: false,
    isVisible: true,
    layer: null
  }
  
  // 创建标注图层
  annotation.layer = createAnnotationLayer(annotation)
  
  return annotation
}

// 创建自动标注
const createAutoAnnotation = (feature, layer) => {
  const props = feature.properties
  const latlng = layer.getLatLng ? layer.getLatLng() : layer.getBounds().getCenter()
  
  // 根据选择的字段生成标注文本
  let labelText = ''
  const selectedField = annotationSystem.selectedField
  
  // 只有在明确选择了字段且字段值存在时才生成标注
  if (selectedField && props[selectedField] !== undefined && props[selectedField] !== null) {
    // 显示字段值
    const fieldValue = props[selectedField]
    
    // 如果是数值字段，添加单位
    if (typeof fieldValue === 'number' || !isNaN(parseFloat(fieldValue))) {
      const unit = getFieldUnit(selectedField)
      labelText = `${fieldValue}${unit ? ` ${unit}` : ''}`
    } else {
      labelText = fieldValue.toString()
    }
    
    // 创建标注对象（不在这里创建图层，让updateAnnotationDisplay处理）
    const annotation = {
      id: 'auto_' + Date.now() + '_' + Math.random(),
      type: 'auto',
      latlng: latlng,
      text: labelText,
      style: { ...annotationSystem.currentStyle },
      isVisible: true,
      layer: null,
      feature: feature,
      sourceLayer: layer
    }
    
    return annotation
  }
  
  // 如果没有选择字段或字段值不存在，返回null
  return null
}

// 获取字段单位
const getFieldUnit = (fieldName) => {
  const unitMap = {
    '年平均氨氮': 'mg/L',
    '年平均高猛酸盐': 'mg/L',
    '年平均化学需氧量': 'mg/L',
    '年平均流量': 'm³/s',
    '年平均水深': 'm',
    '年平均总氮': 'mg/L',
    '年平均总磷': 'mg/L',
    '多年平均库水位': 'm',
    '多年平均蓄水量': '万m³',
    '多年日平均入库流量': 'm³/s',
    '多年日平均出库流量': 'm³/s',
    '总库容': '万m³',
    '汛限水位': 'm'
  }
  return unitMap[fieldName] || ''
}

// 使标注弹窗可拖拽
const makeAnnotationPopupDraggable = (annotationId) => {
  const popupElement = document.querySelector(`[data-annotation-id="${annotationId}"]`)
  if (!popupElement) return
  
  const popupContainer = popupElement.closest('.leaflet-popup')
  if (!popupContainer) return
  
  let isDragging = false
  let startX, startY, startLeft, startTop
  
  // 添加拖拽样式
  popupContainer.style.cursor = 'move'
  popupContainer.style.userSelect = 'none'
  
  // 鼠标按下事件
  const onMouseDown = (e) => {
    // 只允许通过标题栏拖拽
    if (!e.target.closest('.annotation-popup-header')) return
    
    isDragging = true
    startX = e.clientX
    startY = e.clientY
    
    const rect = popupContainer.getBoundingClientRect()
    startLeft = rect.left
    startTop = rect.top
    
    // 添加拖拽时的样式
    popupContainer.style.transition = 'none'
    popupContainer.style.zIndex = '10000'
    
    // 阻止默认行为
    e.preventDefault()
    e.stopPropagation()
  }
  
  // 鼠标移动事件
  const onMouseMove = (e) => {
    if (!isDragging) return
    
    const deltaX = e.clientX - startX
    const deltaY = e.clientY - startY
    
    const newLeft = startLeft + deltaX
    const newTop = startTop + deltaY
    
    // 限制弹窗不超出视口边界
    const maxLeft = window.innerWidth - popupContainer.offsetWidth
    const maxTop = window.innerHeight - popupContainer.offsetHeight
    
    const clampedLeft = Math.max(0, Math.min(newLeft, maxLeft))
    const clampedTop = Math.max(0, Math.min(newTop, maxTop))
    
    popupContainer.style.left = clampedLeft + 'px'
    popupContainer.style.top = clampedTop + 'px'
    
    // 阻止默认行为
    e.preventDefault()
    e.stopPropagation()
  }
  
  // 鼠标松开事件
  const onMouseUp = (e) => {
    if (!isDragging) return
    
    isDragging = false
    
    // 恢复样式
    popupContainer.style.transition = 'all 0.3s ease'
    popupContainer.style.zIndex = '1000'
    
    // 阻止默认行为
    e.preventDefault()
    e.stopPropagation()
  }
  
  // 触摸事件处理（移动设备支持）
  const onTouchStart = (e) => {
    if (!e.target.closest('.annotation-popup-header')) return
    
    isDragging = true
    const touch = e.touches[0]
    startX = touch.clientX
    startY = touch.clientY
    
    const rect = popupContainer.getBoundingClientRect()
    startLeft = rect.left
    startTop = rect.top
    
    popupContainer.style.transition = 'none'
    popupContainer.style.zIndex = '10000'
    
    e.preventDefault()
    e.stopPropagation()
  }
  
  const onTouchMove = (e) => {
    if (!isDragging) return
    
    const touch = e.touches[0]
    const deltaX = touch.clientX - startX
    const deltaY = touch.clientY - startY
    
    const newLeft = startLeft + deltaX
    const newTop = startTop + deltaY
    
    const maxLeft = window.innerWidth - popupContainer.offsetWidth
    const maxTop = window.innerHeight - popupContainer.offsetHeight
    
    const clampedLeft = Math.max(0, Math.min(newLeft, maxLeft))
    const clampedTop = Math.max(0, Math.min(newTop, maxTop))
    
    popupContainer.style.left = clampedLeft + 'px'
    popupContainer.style.top = clampedTop + 'px'
    
    e.preventDefault()
    e.stopPropagation()
  }
  
  const onTouchEnd = (e) => {
    if (!isDragging) return
    
    isDragging = false
    popupContainer.style.transition = 'all 0.3s ease'
    popupContainer.style.zIndex = '1000'
    
    e.preventDefault()
    e.stopPropagation()
  }
  
  // 绑定事件监听器
  popupContainer.addEventListener('mousedown', onMouseDown)
  document.addEventListener('mousemove', onMouseMove)
  document.addEventListener('mouseup', onMouseUp)
  
  // 触摸事件监听器
  popupContainer.addEventListener('touchstart', onTouchStart, { passive: false })
  document.addEventListener('touchmove', onTouchMove, { passive: false })
  document.addEventListener('touchend', onTouchEnd, { passive: false })
  
  // 清理函数
  const cleanup = () => {
    popupContainer.removeEventListener('mousedown', onMouseDown)
    document.removeEventListener('mousemove', onMouseMove)
    document.removeEventListener('mouseup', onMouseUp)
    popupContainer.removeEventListener('touchstart', onTouchStart)
    document.removeEventListener('touchmove', onTouchMove)
    document.removeEventListener('touchend', onTouchEnd)
  }
  
  // 存储清理函数，以便后续清理
  popupContainer._dragCleanup = cleanup
}

// 关闭标注弹窗
const closeAnnotationPopup = (annotationId) => {
  const annotation = annotationSystem.annotations.find(a => a.id === annotationId)
  if (annotation && annotation.layer) {
    // 清理拖拽事件
    const popupElement = document.querySelector(`[data-annotation-id="${annotationId}"]`)
    if (popupElement) {
      const popupContainer = popupElement.closest('.leaflet-popup')
      if (popupContainer && popupContainer._dragCleanup) {
        popupContainer._dragCleanup()
        delete popupContainer._dragCleanup
      }
    }
    
    annotation.layer.closePopup()
  }
}

// 控制面板拖拽相关变量
const isPanelDragging = ref(false)
const panelDragStart = reactive({
  x: 0,
  y: 0,
  left: 0,
  top: 0
})

// 查询弹窗拖拽相关变量
const isQueryPopupDragging = ref(false)
const queryPopupDragStart = reactive({
  x: 0,
  y: 0,
  left: 0,
  top: 0
})

// 开始拖拽控制面板
const startPanelDrag = (e) => {
  // 防止在关闭按钮上拖拽
  if (e.target.closest('.annotation-panel-close')) return
  
  isPanelDragging.value = true
  
  // 记录起始位置
  if (e.type === 'mousedown') {
    panelDragStart.x = e.clientX
    panelDragStart.y = e.clientY
  } else if (e.type === 'touchstart') {
    panelDragStart.x = e.touches[0].clientX
    panelDragStart.y = e.touches[0].clientY
  }
  
  const panel = annotationControlPanel.value
  if (panel) {
    // 移除transform属性，使用绝对定位
    panel.style.transform = 'none'
    panel.style.transition = 'none'
    panel.style.zIndex = '10000'
    
    // 获取当前面板的实际位置
    const rect = panel.getBoundingClientRect()
    panelDragStart.left = rect.left
    panelDragStart.top = rect.top
    
    // 设置初始位置
    panel.style.left = rect.left + 'px'
    panel.style.top = rect.top + 'px'
    
    // 添加拖拽状态的CSS类
    panel.classList.add('dragging')
  }
  
  // 绑定拖拽事件
  if (e.type === 'mousedown') {
    document.addEventListener('mousemove', onPanelDrag)
    document.addEventListener('mouseup', stopPanelDrag)
  } else if (e.type === 'touchstart') {
    document.addEventListener('touchmove', onPanelDrag, { passive: false })
    document.addEventListener('touchend', stopPanelDrag)
  }
  
  e.preventDefault()
  e.stopPropagation()
}

// 控制面板拖拽过程
const onPanelDrag = (e) => {
  if (!isPanelDragging.value) return
  
  const panel = annotationControlPanel.value
  if (!panel) return
  
  let clientX, clientY
  if (e.type === 'mousemove') {
    clientX = e.clientX
    clientY = e.clientY
  } else if (e.type === 'touchmove') {
    clientX = e.touches[0].clientX
    clientY = e.touches[0].clientY
  }
  
  // 计算新位置
  const deltaX = clientX - panelDragStart.x
  const deltaY = clientY - panelDragStart.y
  
  const newLeft = panelDragStart.left + deltaX
  const newTop = panelDragStart.top + deltaY
  
  // 限制边界，防止拖拽超出视口
  const maxLeft = window.innerWidth - panel.offsetWidth
  const maxTop = window.innerHeight - panel.offsetHeight
  
  const clampedLeft = Math.max(0, Math.min(newLeft, maxLeft))
  const clampedTop = Math.max(0, Math.min(newTop, maxTop))
  
  // 应用新位置
  panel.style.left = clampedLeft + 'px'
  panel.style.top = clampedTop + 'px'
  
  e.preventDefault()
  e.stopPropagation()
}

// 停止拖拽控制面板
const stopPanelDrag = (e) => {
  if (!isPanelDragging.value) return
  
  isPanelDragging.value = false
  
  const panel = annotationControlPanel.value
  if (panel) {
    // 恢复样式
    panel.style.transition = 'all 0.3s ease'
    panel.style.zIndex = '2000'
    
    // 移除拖拽状态的CSS类
    panel.classList.remove('dragging')
    
    // 保持当前位置，不恢复transform
    // 这样可以避免面板跳回中心位置
  }
  
  // 移除事件监听器
  document.removeEventListener('mousemove', onPanelDrag)
  document.removeEventListener('mouseup', stopPanelDrag)
  document.removeEventListener('touchmove', onPanelDrag)
  document.removeEventListener('touchend', stopPanelDrag)
  
  e.preventDefault()
  e.stopPropagation()
}

// 重置控制面板位置
const resetPanelPosition = () => {
  const panel = annotationControlPanel.value
  if (panel) {
    // 移除拖拽状态
    panel.classList.remove('dragging')
    
    // 恢复transform居中定位
    panel.style.left = ''
    panel.style.top = ''
    panel.style.transform = 'translate(-50%, -50%)'
    panel.style.transition = 'all 0.3s ease'
    
    // 恢复默认z-index
    panel.style.zIndex = '2000'
  }
}

// 开始拖拽查询弹窗
const startQueryPopupDrag = (e) => {
  // 防止在关闭按钮上拖拽
  if (e.target.closest('.search-close')) return
  
  isQueryPopupDragging.value = true
  
  // 记录起始位置
  if (e.type === 'mousedown') {
    queryPopupDragStart.x = e.clientX
    queryPopupDragStart.y = e.clientY
  } else if (e.type === 'touchstart') {
    queryPopupDragStart.x = e.touches[0].clientX
    queryPopupDragStart.y = e.touches[0].clientY
  }
  
  const popup = queryPopup.value
  if (popup) {
    // 移除transform属性，使用绝对定位
    popup.style.transform = 'none'
    popup.style.transition = 'none'
    popup.style.zIndex = '10000'
    
    // 获取当前弹窗的实际位置
    const rect = popup.getBoundingClientRect()
    queryPopupDragStart.left = rect.left
    queryPopupDragStart.top = rect.top
    
    // 设置初始位置
    popup.style.left = rect.left + 'px'
    popup.style.top = rect.top + 'px'
    
    // 添加拖拽状态的CSS类
    popup.classList.add('dragging')
  }
  
  // 绑定拖拽事件
  if (e.type === 'mousedown') {
    document.addEventListener('mousemove', onQueryPopupDrag)
    document.addEventListener('mouseup', stopQueryPopupDrag)
  } else if (e.type === 'touchstart') {
    document.addEventListener('touchmove', onQueryPopupDrag, { passive: false })
    document.addEventListener('touchend', stopQueryPopupDrag)
  }
  
  e.preventDefault()
  e.stopPropagation()
}

// 查询弹窗拖拽过程
const onQueryPopupDrag = (e) => {
  if (!isQueryPopupDragging.value) return
  
  const popup = queryPopup.value
  if (!popup) return
  
  let clientX, clientY
  if (e.type === 'mousemove') {
    clientX = e.clientX
    clientY = e.clientY
  } else if (e.type === 'touchmove') {
    clientX = e.touches[0].clientX
    clientY = e.touches[0].clientY
  }
  
  // 计算新位置
  const deltaX = clientX - queryPopupDragStart.x
  const deltaY = clientY - queryPopupDragStart.y
  
  const newLeft = queryPopupDragStart.left + deltaX
  const newTop = queryPopupDragStart.top + deltaY
  
  // 限制边界，防止拖拽超出视口
  const maxLeft = window.innerWidth - popup.offsetWidth
  const maxTop = window.innerHeight - popup.offsetHeight
  
  const clampedLeft = Math.max(0, Math.min(newLeft, maxLeft))
  const clampedTop = Math.max(0, Math.min(newTop, maxTop))
  
  // 应用新位置
  popup.style.left = clampedLeft + 'px'
  popup.style.top = clampedTop + 'px'
  
  e.preventDefault()
  e.stopPropagation()
}

// 停止拖拽查询弹窗
const stopQueryPopupDrag = (e) => {
  if (!isQueryPopupDragging.value) return
  
  isQueryPopupDragging.value = false
  
  const popup = queryPopup.value
  if (popup) {
    // 恢复样式
    popup.style.transition = 'all 0.3s ease'
    popup.style.zIndex = '2001'
    
    // 移除拖拽状态的CSS类
    popup.classList.remove('dragging')
    
    // 保持当前位置，不恢复transform
  }
  
  // 移除事件监听器
  document.removeEventListener('mousemove', onQueryPopupDrag)
  document.removeEventListener('mouseup', stopQueryPopupDrag)
  document.removeEventListener('touchmove', onQueryPopupDrag)
  document.removeEventListener('touchend', stopQueryPopupDrag)
  
  e.preventDefault()
  e.stopPropagation()
}

// 重置查询弹窗位置
const resetQueryPopupPosition = () => {
  const popup = queryPopup.value
  if (popup) {
    // 移除拖拽状态
    popup.classList.remove('dragging')
    
    // 恢复transform居中定位
    popup.style.left = ''
    popup.style.top = ''
    popup.style.transform = 'translateX(-50%)'
    popup.style.transition = 'all 0.3s ease'
    
    // 恢复默认z-index
    popup.style.zIndex = '2001'
  }
}

// 创建标注图层
const createAnnotationLayer = (annotation) => {
  console.log('创建标注图层:', annotation.text, '位置:', annotation.latlng)
  
  const { fontSize, fontFamily, color, backgroundColor, borderColor, borderWidth, padding, borderRadius, shadow } = annotation.style
  
  // 计算标注文本的宽度
  const tempDiv = document.createElement('div')
  tempDiv.style.fontSize = fontSize + 'px'
  tempDiv.style.fontFamily = fontFamily
  tempDiv.style.visibility = 'hidden'
  tempDiv.style.position = 'absolute'
  tempDiv.style.whiteSpace = 'nowrap'
  tempDiv.textContent = annotation.text
  document.body.appendChild(tempDiv)
  const textWidth = tempDiv.offsetWidth
  document.body.removeChild(tempDiv)
  
  const icon = L.divIcon({
    className: 'annotation-label',
    html: `
      <div class="annotation-text" 
           style="
             font-size: ${fontSize}px;
             font-family: ${fontFamily};
             color: ${color};
             background-color: transparent;
             border: none;
             padding: 0;
             border-radius: 0;
             box-shadow: none;
             white-space: nowrap;
             cursor: pointer;
             user-select: none;
             font-weight: 700;
             letter-spacing: 0.3px;
             text-shadow: 
               2px 2px 0px rgba(255,255,255,1),
               1px 1px 0px rgba(255,255,255,1),
               -1px -1px 0px rgba(255,255,255,1),
               -2px -2px 0px rgba(255,255,255,1);
             line-height: 1.2;
             position: relative;
             z-index: 1000;
             display: block;
             width: ${textWidth}px;
             height: ${fontSize}px;
             text-align: center;
           "
           data-annotation-id="${annotation.id}"
      >
        ${annotation.text}
      </div>
    `,
    iconSize: [textWidth, fontSize],
    iconAnchor: [textWidth / 2, fontSize / 2],
    // 添加更多配置确保标注位置准确
    popupAnchor: [0, -fontSize / 2]
  })
  
  const marker = L.marker(annotation.latlng, { 
    icon,
    // 添加更多配置确保标注位置准确
    interactive: true,
    keyboard: false,
    title: annotation.text
  }).addTo(map.value)
  
  console.log('标注图层已添加到地图:', marker)
  
  // 绑定事件
  marker.on('click', () => handleAnnotationClick(annotation))
  marker.on('dblclick', () => handleAnnotationDoubleClick(annotation))
  
  return marker
}

// 处理标注点击
const handleAnnotationClick = (annotation) => {
  if (annotation.type === 'manual') {
    // 手动标注点击事件
    showAnnotationPopup(annotation)
  } else {
    // 自动标注点击事件 - 高亮对应要素
    highlightFeature(annotation)
  }
}

// 处理标注双击
const handleAnnotationDoubleClick = (annotation) => {
  if (annotation.type === 'manual') {
    // 进入编辑模式
    enterEditMode(annotation)
  }
}

// 显示标注弹窗
const showAnnotationPopup = (annotation) => {
  const content = `
    <div class="annotation-popup" data-annotation-id="${annotation.id}">
      <div class="annotation-popup-header" data-annotation-id="${annotation.id}">
        <h4>标注信息</h4>
        <span class="annotation-popup-close" onclick="window.closeAnnotationPopup('${annotation.id}')">×</span>
      </div>
      <div class="annotation-popup-content">
        <p><strong>类型:</strong> ${annotation.type === 'manual' ? '手动标注' : '自动标注'}</p>
        <p><strong>文本:</strong> ${annotation.text}</p>
        <p><strong>位置:</strong> ${annotation.latlng.lat.toFixed(6)}, ${annotation.latlng.lng.toFixed(6)}</p>
        <p><strong>时间:</strong> ${new Date().toLocaleString()}</p>
        ${annotation.type === 'manual' ? `
          <div class="annotation-actions">
            <button onclick="window.editAnnotation('${annotation.id}')">编辑</button>
            <button onclick="window.deleteAnnotation('${annotation.id}')">删除</button>
          </div>
        ` : ''}
      </div>
    </div>
  `
  
  const popup = annotation.layer.bindPopup(content, {
    closeButton: false,
    className: 'draggable-annotation-popup',
    maxWidth: 300,
    autoPan: false
  }).openPopup()
  
  // 添加拖拽功能
  setTimeout(() => {
    makeAnnotationPopupDraggable(annotation.id)
  }, 100)
}

// 高亮要素
const highlightFeature = (annotation) => {
  if (annotation.sourceLayer) {
    // 保存原始样式
    if (!annotation.originalStyle) {
      annotation.originalStyle = annotation.sourceLayer.options
    }
    
    // 应用高亮样式
    annotation.sourceLayer.setStyle({
      color: '#ff0000',
      fillColor: '#ffcccc',
      weight: 3,
      fillOpacity: 0.8
    })
    
    // 3秒后恢复原样式
    setTimeout(() => {
      if (annotation.sourceLayer && annotation.originalStyle) {
        annotation.sourceLayer.setStyle(annotation.originalStyle)
      }
    }, 3000)
  }
}

// 进入编辑模式
const enterEditMode = (annotation) => {
  annotation.isEditing = true
  
  // 创建编辑输入框
  const input = document.createElement('input')
  input.type = 'text'
  input.value = annotation.text
  input.className = 'annotation-edit-input'
  input.style.cssText = `
    position: absolute;
    z-index: 10000;
    font-size: ${annotation.style.fontSize}px;
    font-family: ${annotation.style.fontFamily};
    color: ${annotation.style.color};
    background-color: ${annotation.style.backgroundColor};
    border: 2px solid #1890ff;
    border-radius: 4px;
    padding: 4px;
    outline: none;
  `
  
  // 定位输入框
  const mapElement = document.getElementById('editor-map')
  const mapRect = mapElement.getBoundingClientRect()
  const latlng = annotation.latlng
  const point = map.value.latLngToLayerPoint(latlng)
  
  input.style.left = (mapRect.left + point.x - 50) + 'px'
  input.style.top = (mapRect.top + point.y - 15) + 'px'
  
  // 添加到页面
  document.body.appendChild(input)
  input.focus()
  
  // 绑定事件
  input.addEventListener('blur', () => {
    finishEdit(annotation, input.value)
  })
  
  input.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
      finishEdit(annotation, input.value)
    }
  })
}

// 完成编辑
const finishEdit = (annotation, newText) => {
  annotation.text = newText
  annotation.isEditing = false
  
  // 移除输入框
  const input = document.querySelector('.annotation-edit-input')
  if (input) {
    input.remove()
  }
  
  // 更新标注显示
  updateAnnotationDisplay()
  
  showZoomMessage('✅ 标注编辑完成', 'success')
}

// 删除标注
const deleteAnnotation = (annotationId) => {
  const index = annotationSystem.annotations.findIndex(a => a.id === annotationId)
  if (index > -1) {
    const annotation = annotationSystem.annotations[index]
    
    // 移除图层
    if (annotation.layer) {
      map.value.removeLayer(annotation.layer)
    }
    
    // 从数组中移除
    annotationSystem.annotations.splice(index, 1)
    
    // 从对应数组中移除
    if (annotation.type === 'manual') {
      const manualIndex = annotationSystem.manualAnnotations.findIndex(a => a.id === annotationId)
      if (manualIndex > -1) {
        annotationSystem.manualAnnotations.splice(manualIndex, 1)
      }
    } else {
      const autoIndex = annotationSystem.autoAnnotations.findIndex(a => a.id === annotationId)
      if (autoIndex > -1) {
        annotationSystem.autoAnnotations.splice(autoIndex, 1)
      }
    }
    
    showZoomMessage('✅ 标注删除成功', 'success')
  }
}

// 生成自动标注
const generateAutoAnnotations = () => {
  if (!annotationSystem.showAutoLabels) return
  
  // 调用字段标注生成函数
  generateFieldAnnotations()
}

// 更新标注显示
const updateAnnotationDisplay = () => {
  console.log('开始更新标注显示，当前标注数量:', annotationSystem.annotations.length)
  
  // 清除所有标注
  annotationSystem.annotations.forEach(annotation => {
    if (annotation.layer) {
      map.value.removeLayer(annotation.layer)
      annotation.layer = null
    }
  })
  
  // 重新创建标注
  annotationSystem.annotations.forEach(annotation => {
    if (annotation.isVisible) {
      console.log('创建标注:', annotation.text, '位置:', annotation.latlng)
      annotation.layer = createAnnotationLayer(annotation)
      // 优化标注渲染
      optimizeAnnotationRendering(annotation)
    }
  })
  
  console.log('标注显示更新完成，当前可见标注数量:', 
    annotationSystem.annotations.filter(a => a.isVisible && a.layer).length)
  
  // 应用重叠避让
  if (annotationSystem.overlapAvoidance) {
    applyOverlapAvoidance()
  }
}

// 优化标注渲染
const optimizeAnnotationRendering = (annotation) => {
  if (annotation.layer && annotation.layer.getElement) {
    const element = annotation.layer.getElement()
    if (element) {
      // 确保标注清晰显示
      element.style.imageRendering = 'crisp-edges'
      element.style.imageRendering = '-webkit-optimize-contrast'
      element.style.imageRendering = 'optimize-contrast'
      
      // 设置高DPI支持
      element.style.transform = 'translateZ(0)'
      element.style.backfaceVisibility = 'hidden'
      
      // 确保文本清晰
      const textElement = element.querySelector('.annotation-text')
      if (textElement) {
        textElement.style.textRendering = 'optimizeLegibility'
        textElement.style.webkitFontSmoothing = 'antialiased'
        textElement.style.mozOsxFontSmoothing = 'grayscale'
      }
    }
  }
}

// 重新定位标注
const repositionAnnotations = () => {
  console.log('开始重新定位标注，当前标注数量:', annotationSystem.annotations.length)
  
  annotationSystem.annotations.forEach(annotation => {
    if (annotation.isVisible && annotation.layer && annotation.latlng) {
      try {
        // 重新设置标注位置
        annotation.layer.setLatLng(annotation.latlng)
        console.log(`重新定位标注: ${annotation.text} 到位置:`, annotation.latlng)
      } catch (error) {
        console.error(`重新定位标注失败: ${annotation.text}`, error)
      }
    }
  })
  
  console.log('标注重新定位完成')
}

// 处理窗口大小变化
const handleWindowResize = () => {
  console.log('窗口大小变化，重新调整地图和标注')
  
  // 延迟执行，等待DOM更新完成
  setTimeout(() => {
    if (map.value) {
      // 触发地图重新计算
      map.value.invalidateSize()
      
      // 重新定位标注
      repositionAnnotations()
      
      console.log('地图和标注调整完成')
    }
  }, 200)
}

// 应用重叠避让
const applyOverlapAvoidance = () => {
  const annotations = annotationSystem.annotations.filter(a => a.isVisible)
  const tolerance = 5 // 重叠容差
  
  for (let i = 0; i < annotations.length; i++) {
    for (let j = i + 1; j < annotations.length; j++) {
      const a1 = annotations[i]
      const a2 = annotations[j]
      
      // 检查是否重叠
      if (isOverlapping(a1, a2, tolerance)) {
        // 调整位置避免重叠
        adjustAnnotationPosition(a1, a2)
      }
    }
  }
}

// 检查标注是否重叠
const isOverlapping = (a1, a2, tolerance) => {
  const point1 = map.value.latLngToLayerPoint(a1.latlng)
  const point2 = map.value.latLngToLayerPoint(a2.latlng)
  
  const distance = Math.sqrt(
    Math.pow(point1.x - point2.x, 2) + Math.pow(point1.y - point2.y, 2)
  )
  
  return distance < tolerance
}

// 调整标注位置避免重叠
const adjustAnnotationPosition = (a1, a2) => {
  const offset = 20 // 偏移距离
  
  // 计算偏移方向
  const dx = a2.latlng.lng - a1.latlng.lng
  const dy = a2.latlng.lat - a1.latlng.lat
  
  // 应用偏移
  a2.latlng.lng += dx > 0 ? offset / 100000 : -offset / 100000
  a2.latlng.lat += dy > 0 ? offset / 100000 : -offset / 100000
  
  // 更新图层位置
  if (a2.layer) {
    a2.layer.setLatLng(a2.latlng)
  }
}

// 根据缩放级别控制标注显示
const updateAnnotationVisibility = () => {
  if (!map.value) return
  
  const currentZoom = map.value.getZoom()
  const shouldShow = currentZoom >= annotationSystem.minZoom && currentZoom <= annotationSystem.maxZoom
  
  console.log(`缩放级别检查: 当前=${currentZoom}, 最小=${annotationSystem.minZoom}, 最大=${annotationSystem.maxZoom}, 应该显示=${shouldShow}`)
  
  annotationSystem.annotations.forEach(annotation => {
    annotation.isVisible = shouldShow
    if (annotation.layer) {
      if (shouldShow) {
        annotation.layer.addTo(map.value)
        // 在缩放后重新优化渲染
        optimizeAnnotationRendering(annotation)
      } else {
        console.log(`隐藏标注: ${annotation.text} (缩放级别: ${currentZoom})`)
        map.value.removeLayer(annotation.layer)
      }
    }
  })
}

// 标注样式设置
const updateAnnotationStyle = () => {
  annotationSystem.annotations.forEach(annotation => {
    annotation.style = { ...annotationSystem.currentStyle }
  })
  updateAnnotationDisplay()
}

// 清除所有标注
const clearAllAnnotations = () => {
  if (confirm('确定要清除所有标注吗？此操作不可撤销。')) {
    // 清理所有拖拽事件
    annotationSystem.annotations.forEach(annotation => {
      const popupElement = document.querySelector(`[data-annotation-id="${annotation.id}"]`)
      if (popupElement) {
        const popupContainer = popupElement.closest('.leaflet-popup')
        if (popupContainer && popupContainer._dragCleanup) {
          popupContainer._dragCleanup()
          delete popupContainer._dragCleanup
        }
      }
    })
    
    // 清除所有标注图层
    annotationSystem.annotations.forEach(annotation => {
      if (annotation.layer) {
        map.value.removeLayer(annotation.layer)
      }
    })
    
    // 清空数组
    annotationSystem.annotations = []
    annotationSystem.autoAnnotations = []
    annotationSystem.manualAnnotations = []
    
    // 重置标注系统状态
    annotationSystem.selectedLayer = 'monitoringPoints'
    annotationSystem.selectedField = '年平均氨氮'
    updateAvailableFields()
    
    showZoomMessage('✅ 所有标注已清除', 'success')
  }
}

// 全局函数（供HTML调用）
window.editAnnotation = (annotationId) => {
  const annotation = annotationSystem.annotations.find(a => a.id === annotationId)
  if (annotation) {
    enterEditMode(annotation)
  }
}

window.deleteAnnotation = (annotationId) => {
  deleteAnnotation(annotationId)
}

window.closeAnnotationPopup = (annotationId) => {
  closeAnnotationPopup(annotationId)
}



// 新增：activeMapTool变量
const activeMapTool = ref('')

// 放大功能相关变量
const showZoomDropdown = ref(false)
const showZoomOutDropdown = ref(false)
const zoomMode = ref('') // 'rectangle'
const isDrawing = ref(false)
const drawLayer = ref(null)

// 放大菜单相关函数
const toggleZoomMenu = () => {
  console.log('切换放大菜单，当前状态:', showZoomDropdown.value)
  showZoomDropdown.value = !showZoomDropdown.value
  // 关闭缩小菜单
  showZoomOutDropdown.value = false
  console.log('放大菜单新状态:', showZoomDropdown.value, '缩小菜单已关闭')
}

// 缩小菜单相关函数
const toggleZoomOutMenu = () => {
  console.log('切换缩小菜单，当前状态:', showZoomOutDropdown.value)
  
  // 切换缩小菜单状态
  showZoomOutDropdown.value = !showZoomOutDropdown.value
  
  // 关闭放大菜单
  showZoomDropdown.value = false
  
  console.log('缩小菜单新状态:', showZoomOutDropdown.value, '放大菜单已关闭')
  
  // 调试：检查DOM元素
  nextTick(() => {
    const zoomOutDropdown = document.querySelector('.zoom-dropdown-container.zoom-out-container .zoom-dropdown')
    console.log('缩小下拉菜单DOM元素:', zoomOutDropdown)
    if (zoomOutDropdown) {
      console.log('缩小下拉菜单样式:', getComputedStyle(zoomOutDropdown))
      console.log('缩小下拉菜单位置:', zoomOutDropdown.getBoundingClientRect())
      console.log('缩小下拉菜单可见性:', zoomOutDropdown.style.display, zoomOutDropdown.style.visibility, zoomOutDropdown.style.opacity)
    } else {
      console.log('❌ 缩小下拉菜单DOM元素未找到')
    }
    
    // 检查容器状态
    const container = document.querySelector('.zoom-dropdown-container.zoom-out-container')
    if (container) {
      console.log('缩小容器状态:', container)
      console.log('容器内子元素数量:', container.children.length)
    }
  })
}

// 点击外部关闭放大菜单
const closeZoomMenu = () => {
  showZoomDropdown.value = false
}

// 点击外部关闭缩小菜单
const closeZoomOutMenu = () => {
  console.log('关闭缩小菜单')
  showZoomOutDropdown.value = false
}







// 监听点击事件
onMounted(() => {
  document.addEventListener('click', (e) => {
    // 检查放大下拉菜单
    const zoomDropdown = document.querySelector('.zoom-dropdown-container:not(.zoom-out-container)')
    if (zoomDropdown && !zoomDropdown.contains(e.target)) {
      closeZoomMenu()
    }
    
    // 检查缩小下拉菜单
    const zoomOutDropdown = document.querySelector('.zoom-dropdown-container.zoom-out-container')
    if (zoomOutDropdown && !zoomOutDropdown.contains(e.target)) {
      closeZoomOutMenu()
    }
  })
})

// 定义缩放方法
const zoomMethods = {
  // 拉框放大 - 绘制矩形框进行放大
  rectangleZoom: (geometry) => {
    console.log('执行拉框放大，geometry:', geometry)
    console.log('地图对象:', map.value)
    console.log('几何对象类型:', geometry ? geometry.constructor.name : 'null')
    
    if (!map.value) {
      console.error('地图未初始化')
      showZoomMessage('❌ 地图未初始化', 'warning')
      return
    }
    
    if (!geometry) {
      console.error('几何对象为空')
      showZoomMessage('❌ 绘制的区域无效，请重新绘制', 'warning')
      return
    }
    
    try {
      // 检查几何对象是否有getBounds方法
      if (typeof geometry.getBounds !== 'function') {
        console.error('几何对象没有getBounds方法:', geometry)
        showZoomMessage('❌ 绘制的区域类型不支持，请重新绘制', 'warning')
        return
      }
      
      const bounds = geometry.getBounds()
      console.log('获取到的边界:', bounds)
      
      if (!bounds) {
        console.error('无法获取边界')
        showZoomMessage('❌ 无法获取绘制区域的边界，请重新绘制', 'warning')
        return
      }
      
      // 检查边界是否有效
      if (isValidZoomBounds(bounds)) {
        console.log('边界验证通过，执行放大')
        
        // 执行放大操作
        map.value.fitBounds(bounds, { 
          padding: [50, 50],
          maxZoom: Math.min(map.value.getMaxZoom(), 18), // 限制最大缩放级别
          animate: true
        })
        
        showZoomMessage('✅ 拉框放大成功', 'success')
        
        // 添加到历史记录
        setTimeout(() => {
          const center = map.value.getCenter()
          const zoom = map.value.getZoom()
          addToHistory(center, zoom)
        }, 300)
        
      } else {
        console.log('边界验证失败')
        showZoomMessage('⚠️ 绘制的区域无效，请重新绘制', 'warning')
      }
      
    } catch (error) {
      console.error('拉框放大过程中出错:', error)
      showZoomMessage('❌ 放大失败，请重新绘制', 'warning')
    }
  },
  
  // 拉框缩小 - 绘制矩形框进行缩小
  rectangleZoomOut: (geometry) => {
    console.log('执行拉框缩小，geometry:', geometry)
    console.log('地图对象:', map.value)
    console.log('几何对象类型:', geometry ? geometry.constructor.name : 'null')
    
    if (!map.value) {
      console.error('地图未初始化')
      showZoomMessage('❌ 地图未初始化', 'warning')
      return
    }
    
    if (!geometry) {
      console.error('几何对象为空')
      showZoomMessage('❌ 绘制的区域无效，请重新绘制', 'warning')
      return
    }
    
    try {
      // 检查几何对象是否有getBounds方法
      if (typeof geometry.getBounds !== 'function') {
        console.error('几何对象没有getBounds方法:', geometry)
        showZoomMessage('❌ 绘制的区域类型不支持，请重新绘制', 'warning')
        return
      }
      
      const bounds = geometry.getBounds()
      console.log('获取到的边界:', bounds)
      
      if (!bounds) {
        console.error('无法获取边界')
        showZoomMessage('❌ 无法获取绘制区域的边界，请重新绘制', 'warning')
        return
      }
      
      // 检查边界是否有效
      if (isValidZoomBounds(bounds)) {
        console.log('边界验证通过，执行缩小')
        
        // 获取当前地图状态
        const currentCenter = map.value.getCenter()
        const currentZoom = map.value.getZoom()
        
        // 计算绘制区域的中心点
        const rectCenter = bounds.getCenter()
        
        // 计算新的缩放级别 - 缩小1-2级
        const newZoom = Math.max(
          map.value.getMinZoom(), 
          currentZoom - 1.5
        )
        
        // 执行缩小操作 - 移动到绘制区域中心并缩小
        map.value.setView(rectCenter, newZoom, { 
          animate: true,
          duration: 0.8
        })
        
        showZoomMessage(`✅ 拉框缩小成功 (缩放: ${currentZoom.toFixed(1)} → ${newZoom.toFixed(1)})`, 'success')
        
        // 添加到历史记录
        setTimeout(() => {
          const center = map.value.getCenter()
          const zoom = map.value.getZoom()
          addToHistory(center, zoom)
        }, 300)
        
      } else {
        console.log('边界验证失败')
        showZoomMessage('⚠️ 绘制的区域无效，请重新绘制', 'warning')
      }
      
    } catch (error) {
      console.error('拉框缩小过程中出错:', error)
      showZoomMessage('❌ 缩小失败，请重新绘制', 'warning')
    }
  }
}

// 检查缩放边界是否有效
const isValidZoomBounds = (bounds) => {
  if (!bounds || !map.value) return false
  
  try {
    // 检查边界是否有效
    if (!bounds.isValid || !bounds.isValid()) {
      console.log('边界对象无效')
      return false
    }
    
    // 获取边界的西南角和东北角
    const southWest = bounds.getSouthWest()
    const northEast = bounds.getNorthEast()
    
    if (!southWest || !northEast) {
      console.log('无法获取边界坐标')
      return false
    }
    
    // 检查坐标是否有效
    if (isNaN(southWest.lat) || isNaN(southWest.lng) || 
        isNaN(northEast.lat) || isNaN(northEast.lng)) {
      console.log('边界坐标包含无效值')
      return false
    }
    
    // 检查边界大小是否合理
    const latDiff = Math.abs(northEast.lat - southWest.lat)
    const lngDiff = Math.abs(northEast.lng - southWest.lng)
    
    if (latDiff < 0.0001 || lngDiff < 0.0001) {
      console.log('边界太小:', { latDiff, lngDiff })
      return false
    }
    
    // 检查是否超出合理的地理范围（防止过度放大或缩小）
    if (latDiff > 10 || lngDiff > 10) {
      console.log('边界太大:', { latDiff, lngDiff })
      return false
    }
    
    console.log('边界验证通过:', { latDiff, lngDiff })
    return true
    
  } catch (error) {
    console.error('边界验证出错:', error)
    return false
  }
}

// 处理地图点击事件
const handleMapClick = (e) => {
  console.log('地图点击事件触发:', e.latlng)
  console.log('当前激活工具:', activeMapTool.value)
  console.log('事件类型:', e.type)
  console.log('事件目标:', e.target)
  
  // 根据当前激活的工具执行相应操作
  switch (activeMapTool.value) {
    case 'zoomIn':
      console.log('执行按点放大，点击位置:', e.latlng)
      handlePointZoom(e.latlng)
      break
    case 'zoomOut':
      console.log('执行按点缩小，点击位置:', e.latlng)
      handlePointZoomOut(e.latlng)
      break
    case 'selectFeature':
      console.log('执行要素选择，点击位置:', e.latlng)
      // 这里可以添加要素选择逻辑
      break
    case 'identifyFeature':
      console.log('执行要素识别，点击位置:', e.latlng)
      // 这里可以添加要素识别逻辑
      break
    case 'annotation':
      console.log('执行标注功能，点击位置:', e.latlng)
      handleAnnotation(e.latlng)
      break
    default:
      console.log('当前工具不处理点击事件:', activeMapTool.value)
      break
  }
}

// 重置工具状态
const resetToolState = () => {
  console.log('重置工具状态')
  
  // 如果之前是按点放大或缩小模式，恢复地图拖拽功能
  if ((activeMapTool.value === 'zoomIn' || activeMapTool.value === 'zoomOut' || activeMapTool.value === 'rectangleZoomOut') && map.value) {
    map.value.dragging.enable()
    console.log('已恢复地图拖拽功能')
  }
  
  // 不要重置activeMapTool，只重置菜单状态
  // activeMapTool.value = ''
  showZoomDropdown.value = false
  showZoomOutDropdown.value = false
  
  // 恢复默认鼠标样式
  const mapElement = document.getElementById('editor-map')
  if (mapElement) {
    // 根据当前工具类型设置相应的鼠标样式
    if (activeMapTool.value === 'selectFeature') {
      mapElement.style.cursor = 'pointer'
    } else if (activeMapTool.value === 'identifyFeature') {
      mapElement.style.cursor = 'help'
    } else {
      mapElement.style.cursor = 'default'
    }
    
    // 移除平移相关的CSS类
    mapElement.classList.remove('panning')
    // 移除缩放相关的CSS类
    mapElement.classList.remove('zoom-in-cursor', 'zoom-out-cursor')
    
    // 恢复所有Leaflet元素的默认鼠标样式
    const leafletElements = mapElement.querySelectorAll('.leaflet-pane, .leaflet-overlay-pane, .leaflet-tile-pane, .leaflet-marker-pane, .leaflet-tooltip-pane, .leaflet-popup-pane')
    leafletElements.forEach(element => {
      element.style.cursor = ''
    })
    
    // 恢复所有子元素的默认鼠标样式
    const allChildren = mapElement.querySelectorAll('*')
    allChildren.forEach(child => {
      if (child.style && !child.classList.contains('custom-toolbar') && !child.classList.contains('control-panel')) {
        child.style.cursor = ''
      }
    })
    
    // 移除鼠标移动监听器
    const mouseMoveHandler = (e) => {
      if (activeMapTool.value === 'zoomIn') {
        const target = e.target
        if (target && target.style) {
          target.style.cursor = 'zoom-in'
        }
      }
    }
    const mouseMoveHandlerOut = (e) => {
      if (activeMapTool.value === 'zoomOut') {
        const target = e.target
        if (target && target.style) {
          target.style.cursor = 'zoom-out'
        }
      }
    }
    mapElement.removeEventListener('mousemove', mouseMoveHandler)
    mapElement.removeEventListener('mousemove', mouseMoveHandlerOut)
    
    console.log('已恢复鼠标样式，已移除鼠标移动监听器，已移除平移CSS类')
  }
}

// 强制设置放大镜鼠标样式
const forceSetZoomCursor = () => {
  const mapElement = document.getElementById('editor-map')
  if (mapElement) {
    console.log('强制设置放大镜鼠标样式')
    
    // 设置地图容器的鼠标样式
    mapElement.style.cursor = 'zoom-in'
    
    // 查找并设置所有Leaflet相关元素的鼠标样式
    const leafletElements = mapElement.querySelectorAll('.leaflet-pane, .leaflet-overlay-pane, .leaflet-tile-pane, .leaflet-marker-pane, .leaflet-tooltip-pane, .leaflet-popup-pane')
    leafletElements.forEach(element => {
      element.style.cursor = 'zoom-in'
      console.log('设置Leaflet元素鼠标样式:', element.className)
    })
    
    // 设置地图容器的所有子元素的鼠标样式
    const allChildren = mapElement.querySelectorAll('*')
    allChildren.forEach(child => {
      if (child.style && !child.classList.contains('custom-toolbar') && !child.classList.contains('control-panel')) {
        child.style.cursor = 'zoom-in'
      }
    })
    
    // 添加鼠标移动监听器，确保在地图区域内始终保持放大镜样式
    const mouseMoveHandler = (e) => {
      if (activeMapTool.value === 'zoomIn') {
        const target = e.target
        if (target && target.style) {
          target.style.cursor = 'zoom-in'
        }
      }
    }
    
    // 移除之前的监听器（如果存在）
    mapElement.removeEventListener('mousemove', mouseMoveHandler)
    mapElement.addEventListener('mousemove', mouseMoveHandler)
    
    console.log('放大镜鼠标样式设置完成，已添加鼠标移动监听器')
  }
}

// 强制设置缩小镜鼠标样式
const forceSetZoomOutCursor = () => {
  const mapElement = document.getElementById('editor-map')
  if (mapElement) {
    console.log('强制设置缩小镜鼠标样式')
    
    // 设置地图容器的鼠标样式
    mapElement.style.cursor = 'zoom-out'
    
    // 查找并设置所有Leaflet相关元素的鼠标样式
    const leafletElements = mapElement.querySelectorAll('.leaflet-pane, .leaflet-overlay-pane, .leaflet-tile-pane, .leaflet-marker-pane, .leaflet-tooltip-pane, .leaflet-popup-pane')
    leafletElements.forEach(element => {
      element.style.cursor = 'zoom-out'
      console.log('设置Leaflet元素鼠标样式:', element.className)
    })
    
    // 设置地图容器的所有子元素的鼠标样式
    const allChildren = mapElement.querySelectorAll('*')
    allChildren.forEach(child => {
      if (child.style && !child.classList.contains('custom-toolbar') && !child.classList.contains('control-panel')) {
        child.style.cursor = 'zoom-out'
      }
    })
    
    // 添加鼠标移动监听器，确保在地图区域内始终保持缩小镜样式
    const mouseMoveHandler = (e) => {
      if (activeMapTool.value === 'zoomOut') {
        const target = e.target
        if (target && target.style) {
          target.style.cursor = 'zoom-out'
        }
      }
    }
    
    // 移除之前的监听器（如果存在）
    mapElement.removeEventListener('mousemove', mouseMoveHandler)
    mapElement.addEventListener('mousemove', mouseMoveHandler)
    
    console.log('缩小镜鼠标样式设置完成，已添加鼠标移动监听器')
  }
}





// 平移性能优化函数
const optimizePanPerformance = () => {
  if (map.value) {
    console.log('=== 应用平移性能优化 ===')
    
    // 优化地图选项
    map.value.options.inertia = true
    map.value.options.inertiaDeceleration = 3000
    map.value.options.inertiaMaxSpeed = 3000
    map.value.options.updateWhenZooming = false
    map.value.options.updateWhenIdle = true
    map.value.options.keepBuffer = 2
    
    // 优化瓦片图层
    const tileLayers = map.value._tileLayers
    if (tileLayers) {
      Object.values(tileLayers).forEach(layer => {
        if (layer.options) {
          layer.options.updateWhenIdle = true
          layer.options.updateWhenZooming = false
          layer.options.keepBuffer = 2
        }
      })
    }
    
    // 优化GeoJSON图层
    Object.values(layerObjects).forEach(layer => {
      if (layer && layer.setStyle) {
        layer.setStyle({
          smoothFactor: 1,
          simplifyTolerance: 0.5
        })
      }
    })
    
    console.log('平移性能优化已应用')
  }
}



// 处理按点放大
const handlePointZoom = (latlng) => {
  if (!map.value) {
    console.error('地图未初始化')
    return
  }
  
  try {
    console.log('开始按点放大，目标位置:', latlng)
    
    // 获取当前缩放级别
    const currentZoom = map.value.getZoom()
    const maxZoom = map.value.getMaxZoom()
    
    if (currentZoom < maxZoom) {
      // 先移动到目标位置，然后放大
      map.value.setView(latlng, currentZoom + 1, { 
        animate: true,
        duration: 0.5
      })
      
      showZoomMessage('✅ 按点放大成功', 'success')
      
      // 添加到历史记录
      setTimeout(() => {
        const center = map.value.getCenter()
        const zoom = map.value.getZoom()
        addToHistory(center, zoom)
      }, 600)
      
    } else {
      // 如果已经是最大缩放级别，只移动到目标位置
      map.value.setView(latlng, currentZoom, { 
        animate: true,
        duration: 0.5
      })
      
      showZoomMessage('⚠️ 已达到最大缩放级别，已移动到目标位置', 'warning')
      
      // 添加到历史记录
      setTimeout(() => {
        const center = map.value.getCenter()
        const zoom = map.value.getZoom()
        addToHistory(center, zoom)
      }, 600)
    }
    
    // 按点放大完成后，恢复地图拖拽功能并重置工具状态
    setTimeout(() => {
      if (map.value) {
        map.value.dragging.enable()
        console.log('按点放大完成，已恢复地图拖拽功能')
      }
      resetToolState()
    }, 1000)
    
  } catch (error) {
    console.error('按点放大失败:', error)
    showZoomMessage('❌ 按点放大失败', 'warning')
    
    // 出错时也要恢复地图拖拽功能
    if (map.value) {
      map.value.dragging.enable()
    }
    resetToolState()
  }
}

// 处理按点缩小
const handlePointZoomOut = (latlng) => {
  if (!map.value) {
    console.error('地图未初始化')
    return
  }
  
  try {
    console.log('开始按点缩小，目标位置:', latlng)
    
    // 获取当前缩放级别
    const currentZoom = map.value.getZoom()
    const minZoom = map.value.getMinZoom()
    
    if (currentZoom > minZoom) {
      // 先移动到目标位置，然后缩小
      map.value.setView(latlng, currentZoom - 1, { 
        animate: true,
        duration: 0.5
      })
      
      showZoomMessage('✅ 按点缩小成功', 'success')
      
      // 添加到历史记录
      setTimeout(() => {
        const center = map.value.getCenter()
        const zoom = map.value.getZoom()
        addToHistory(center, zoom)
      }, 600)
      
    } else {
      // 如果已经是最小缩放级别，只移动到目标位置
      map.value.setView(latlng, currentZoom, { 
        animate: true,
        duration: 0.5
      })
      
      showZoomMessage('⚠️ 已达到最小缩放级别，已移动到目标位置', 'warning')
      
      // 添加到历史记录
      setTimeout(() => {
        const center = map.value.getCenter()
        const zoom = map.value.getZoom()
        addToHistory(center, zoom)
      }, 600)
    }
    
    // 按点缩小完成后，恢复地图拖拽功能并重置工具状态
    setTimeout(() => {
      if (map.value) {
        map.value.dragging.enable()
        console.log('按点缩小完成，已恢复地图拖拽功能')
      }
      resetToolState()
    }, 1000)
    
  } catch (error) {
    console.error('按点缩小失败:', error)
    showZoomMessage('❌ 按点缩小失败', 'warning')
    
    // 出错时也要恢复地图拖拽功能
    if (map.value) {
      map.value.dragging.enable()
    }
    resetToolState()
  }
}

// 显示缩放提示信息
const showZoomMessage = (message, type = 'info') => {
  // 创建提示元素
  const messageDiv = document.createElement('div')
  messageDiv.className = `zoom-message zoom-message-${type}`
  messageDiv.textContent = message
  
  // 添加到地图容器
  const mapContainer = document.getElementById('editor-map')
  if (mapContainer) {
    mapContainer.appendChild(messageDiv)
    
    // 3秒后自动移除
    setTimeout(() => {
      if (messageDiv.parentNode) {
        messageDiv.parentNode.removeChild(messageDiv)
      }
    }, 3000)
  }
}

// 键盘事件处理
const handleKeyDown = (e) => {
  if (e.key === 'Escape' && isDrawing.value) {
    finishDrawing()
    showZoomMessage('❌ 已取消绘制', 'warning')
  }
  
  // F键显示全图
  if (e.key === 'f' || e.key === 'F') {
    e.preventDefault()
    viewFullExtent()
  }
}

// 放大功能相关函数
const activateRectangleZoom = () => {
  console.log('激活矩形框放大模式')
  console.log('当前地图状态:', { 
    map: !!map.value, 
    activeMapTool: activeMapTool.value,
    zoomMode: zoomMode.value 
  })
  
  if (!map.value) {
    console.error('地图未初始化，无法启动绘制模式')
    showZoomMessage('❌ 地图未初始化', 'warning')
    return
  }
  
  resetToolState()
  activeMapTool.value = 'rectangleZoom'
  zoomMode.value = 'rectangle'
  showZoomDropdown.value = false
  showZoomOutDropdown.value = false
  
  console.log('启动绘制模式前的状态:', { 
    activeMapTool: activeMapTool.value,
    zoomMode: zoomMode.value 
  })
  
  startDrawingMode()
}



const startDrawingMode = () => {
  console.log('开始绘制模式:', { 
    map: !!map.value, 
    zoomMode: zoomMode.value,
    isDrawing: isDrawing.value 
  })
  
  if (!map.value) {
    console.error('地图未初始化')
    showZoomMessage('❌ 地图未初始化', 'warning')
    return
  }
  
  try {
    // 先清理之前的绘制状态，但不重置activeMapTool
    isDrawing.value = false
    zoomMode.value = ''
    
    // 重新启用地图拖拽功能
    if (map.value) {
      map.value.dragging.enable()
    }
    
    // 清除绘制图层
    if (drawLayer.value) {
      map.value.removeLayer(drawLayer.value)
      drawLayer.value = null
    }
    
    // 移除地图事件监听器
    map.value.off('mousedown')
    map.value.off('mousemove')
    map.value.off('mouseup')
    
    // 移除键盘事件监听器
    document.removeEventListener('keydown', handleKeyDown)
    
    // 重新绑定地图点击事件监听器
    if (map.value) {
      map.value.off('click')
      map.value.on('click', handleMapClick)
    }
    
    isDrawing.value = true
    console.log('isDrawing设置为true')
    
    // 禁用地图拖拽功能，让鼠标事件能够用于绘制
    map.value.dragging.disable()
    
    // 暂时移除地图点击事件监听器，避免与绘制事件冲突
    map.value.off('click')
    // 同时移除按点放大和缩小的点击事件监听器
    map.value.off('click', handleMapClick)
    
    // 清除之前的绘制图层
    if (drawLayer.value) {
      map.value.removeLayer(drawLayer.value)
    }
    
    // 创建新的绘制图层
    drawLayer.value = L.layerGroup().addTo(map.value)
    
    console.log('绘制图层创建成功:', drawLayer.value)
    
    // 显示绘制提示
    const modeName = getZoomModeName()
    showZoomMessage(`开始${modeName}绘制，按ESC键取消`, 'info')
    
    // 设置矩形绘制工具
    console.log('当前zoomMode:', zoomMode.value)
    
    if (zoomMode.value === 'rectangle') {
      console.log('设置矩形绘制')
      setupRectangleDrawing()
    } else {
      console.error('未知的绘制模式:', zoomMode.value)
      // 强制设置为矩形模式
      zoomMode.value = 'rectangle'
      setupRectangleDrawing()
    }
    
    // 添加ESC键取消绘制功能
    document.addEventListener('keydown', handleKeyDown)
    
  } catch (error) {
    console.error('启动绘制模式失败:', error)
    showZoomMessage('❌ 启动绘制模式失败', 'warning')
    finishDrawing()
  }
}

// 获取缩放模式的中文名称
const getZoomModeName = () => {
  const modeNames = {
    'rectangle': activeMapTool.value === 'rectangleZoomOut' ? '矩形框缩小' : '矩形框放大'
  }
  return modeNames[zoomMode.value] || '未知'
}

// 取消绘制
const cancelDrawing = () => {
  finishDrawing()
  showZoomMessage('❌ 已取消绘制', 'warning')
}

const setupRectangleDrawing = () => {
  console.log('设置矩形绘制模式')
  console.log('当前激活工具:', activeMapTool.value)
  console.log('当前缩放模式:', zoomMode.value)
  
  let startPoint = null
  let rectangle = null
  
  const onMouseDown = (e) => {
    console.log('矩形绘制 - 鼠标按下事件触发')
    console.log('当前isDrawing状态:', isDrawing.value)
    console.log('当前activeMapTool:', activeMapTool.value)
    console.log('当前zoomMode:', zoomMode.value)
    
    if (!isDrawing.value) {
      console.log('isDrawing为false，退出')
      return
    }
    
    startPoint = e.latlng
    console.log('开始绘制矩形，起始点:', startPoint)
    
    // 创建矩形对象
    try {
      rectangle = L.rectangle([startPoint, startPoint], { 
        color: '#ff0000', 
        weight: 2,
        fillColor: '#ff0000',
        fillOpacity: 0.2
      }).addTo(drawLayer.value)
      
      console.log('矩形对象已创建:', rectangle)
      console.log('矩形类型:', rectangle.constructor.name)
      
    } catch (error) {
      console.error('创建矩形对象失败:', error)
      showZoomMessage('❌ 创建绘制区域失败', 'warning')
      finishDrawing()
      return
    }
  }
  
  const onMouseMove = (e) => {
    if (!isDrawing.value || !startPoint || !rectangle) return
    
    try {
      const currentPoint = e.latlng
      rectangle.setBounds([startPoint, currentPoint])
      console.log('更新矩形，当前点:', currentPoint)
    } catch (error) {
      console.error('更新矩形失败:', error)
    }
  }
  
  const onMouseUp = (e) => {
    if (!isDrawing.value || !startPoint || !rectangle) {
      console.log('绘制条件不满足:', { isDrawing: isDrawing.value, startPoint: !!startPoint, rectangle: !!rectangle })
      return
    }
    
    console.log('完成矩形绘制')
    
    try {
      // 检查矩形是否太小
      const bounds = rectangle.getBounds()
      console.log('矩形边界:', bounds)
      
      if (!bounds) {
        console.error('无法获取矩形边界')
        showZoomMessage('❌ 无法获取绘制区域边界', 'warning')
        finishDrawing()
        return
      }
      
      // 计算矩形大小
      const southWest = bounds.getSouthWest()
      const northEast = bounds.getNorthEast()
      
      if (!southWest || !northEast) {
        console.error('边界坐标无效')
        showZoomMessage('❌ 边界坐标无效', 'warning')
        finishDrawing()
        return
      }
      
      const latDiff = Math.abs(northEast.lat - southWest.lat)
      const lngDiff = Math.abs(northEast.lng - southWest.lng)
      
      console.log('矩形尺寸:', { latDiff, lngDiff })
      
      if (latDiff < 0.0001 || lngDiff < 0.0001) {
        console.log('矩形太小，重新绘制')
        showZoomMessage('⚠️ 绘制的区域太小，请重新绘制', 'warning')
        finishDrawing()
        return
      }
      
      // 根据当前工具类型调用相应的缩放方法
      console.log('绘制完成，当前工具类型:', activeMapTool.value)
      console.log('矩形对象:', rectangle)
      
      if (activeMapTool.value === 'rectangleZoomOut') {
        console.log('✅ 调用缩小方法，矩形对象:', rectangle)
        zoomMethods.rectangleZoomOut(rectangle)
        // 缩小完成后重置状态
        setTimeout(() => {
          console.log('缩小完成，重置状态')
          activeMapTool.value = ''
          finishDrawing()
        }, 100)
      } else if (activeMapTool.value === 'rectangleZoom') {
        console.log('✅ 调用放大方法，矩形对象:', rectangle)
        zoomMethods.rectangleZoom(rectangle)
        // 放大完成后重置状态
        setTimeout(() => {
          console.log('放大完成，重置状态')
          activeMapTool.value = ''
          finishDrawing()
        }, 100)
      } else {
        console.log('❌ 未知的工具类型:', activeMapTool.value)
        console.log('当前activeMapTool值:', activeMapTool.value)
        console.log('当前zoomMode值:', zoomMode.value)
        showZoomMessage('❌ 未知的缩放模式', 'warning')
        finishDrawing()
      }
      
    } catch (error) {
      console.error('处理矩形绘制完成时出错:', error)
      showZoomMessage('❌ 处理绘制结果失败', 'warning')
      finishDrawing()
    }
  }
  
  console.log('绑定矩形绘制事件监听器')
  
  try {
    // 先移除所有事件监听器，避免冲突
    map.value.off('mousedown')
    map.value.off('mousemove')
    map.value.off('mouseup')
    
    // 绑定矩形绘制事件
    map.value.on('mousedown', onMouseDown)
    map.value.on('mousemove', onMouseMove)
    map.value.on('mouseup', onMouseUp)
    
    console.log('矩形绘制事件监听器绑定完成')
    
  } catch (error) {
    console.error('绑定事件监听器失败:', error)
    showZoomMessage('❌ 设置绘制模式失败', 'warning')
    finishDrawing()
  }
}





const finishDrawing = () => {
  console.log('finishDrawing被调用，当前activeMapTool:', activeMapTool.value)
  isDrawing.value = false
  // 不要立即重置activeMapTool，让缩放方法执行完成后再重置
  // activeMapTool.value = ''
  zoomMode.value = ''
  
  // 重新启用地图拖拽功能
  if (map.value) {
    map.value.dragging.enable()
  }
  
  // 清除绘制图层
  if (drawLayer.value) {
    map.value.removeLayer(drawLayer.value)
    drawLayer.value = null
  }
  
  // 移除地图事件监听器
  map.value.off('mousedown')
  map.value.off('mousemove')
  map.value.off('mouseup')
  
  // 移除键盘事件监听器
  document.removeEventListener('keydown', handleKeyDown)
  
  // 重新绑定地图点击事件监听器
  if (map.value) {
    map.value.off('click')
    map.value.on('click', handleMapClick)
    console.log('地图点击事件监听器已重新绑定，支持按点放大和缩小功能')
  }
  
  console.log('绘制模式已清理，地图点击事件已重新绑定')
}

const searchText = ref('')
const searchError = ref('')
const selectedQueryLayer = ref('monitoringPoints')

// 获取搜索占位符
const getSearchPlaceholder = () => {
  const placeholders = {
    monitoringPoints: '请输入水库名称',
    beijingReservoirs: '请输入水库名称',
    settlements: '请输入居民点名称',
    districts: '请输入行政区划名称',
    waterLines: '请输入河流名称'
  }
  return placeholders[selectedQueryLayer.value] || '请输入查询内容'
}

// 查询并定位要素
const handleSearch = () => {
  console.log('handleSearch函数被调用')
  searchError.value = ''
  if (!searchText.value.trim()) {
    searchError.value = '请输入查询内容'
    return
  }
  
  const layerKey = selectedQueryLayer.value
  console.log('选择的图层:', layerKey)
  const layer = layerObjects[layerKey]
  console.log('图层对象:', layer)
  if (!layer) {
    searchError.value = `${getLayerDisplayName(layerKey)}图层未加载`
    return
  }
  
  console.log('开始查询，搜索文本:', searchText.value.trim())
  
  // 设置当前查询的图层类型
  currentQueryLayer.value = layerKey
  
  let found = false
  let checkedCount = 0
  let sampleProps = null
  
  // 确保图层有要素
  if (!layer.getLayers || layer.getLayers().length === 0) {
    searchError.value = `${getLayerDisplayName(layerKey)}图层没有数据`
    return
  }
  
  // 获取图层的所有要素
  const layers = layer.getLayers ? layer.getLayers() : []
  console.log(`图层${layerKey}有${layers.length}个要素`)
  
  layers.forEach((l, index) => {
    const props = l.feature && l.feature.properties
    if (props) {
      checkedCount++
      // 保存第一个要素的属性作为样本
      if (!sampleProps) {
        sampleProps = props
      }
      
      // 根据图层类型进行不同的查询逻辑
      let isMatch = false
      const searchValue = searchText.value.trim()
      
      // 调试信息：打印前几个要素的属性
      if (checkedCount <= 3) {
        console.log(`要素${checkedCount}的属性:`, props)
      }
      
      switch (layerKey) {
        case 'monitoringPoints':
          // 监测点图层查询逻辑，支持水库名称查询
          isMatch = (props.name && (props.name === searchValue || props.name.includes(searchValue))) ||
                   (props.NAME && (props.NAME === searchValue || props.NAME.includes(searchValue))) ||
                   (props.库名 && (props.库名 === searchValue || props.库名.includes(searchValue)))
          break
        case 'beijingReservoirs':
          // 水库面数据使用 name 字段
          isMatch = (props.name && (props.name === searchValue || props.name.includes(searchValue))) ||
                   (props.库名 && (props.库名 === searchValue || props.库名.includes(searchValue))) ||
                   (props.NAME && (props.NAME === searchValue || props.NAME.includes(searchValue)))
          break
        case 'settlements':
          isMatch = (props.NAME && (props.NAME === searchValue || props.NAME.includes(searchValue)))
          break
        case 'districts':
          isMatch = (props.NAME && (props.NAME === searchValue || props.NAME.includes(searchValue)))
          break
        case 'waterLines':
          isMatch = (props.name && (props.name === searchValue || props.name.includes(searchValue)))
          break
        default:
          console.log('未知的图层类型:', layerKey)
          break
      }
      
      // 调试：打印匹配结果
      if (checkedCount <= 5) {
        console.log(`要素${checkedCount}匹配结果:`, isMatch, '搜索值:', searchValue, '属性:', props)
      }
      
      if (isMatch) {
        console.log('找到匹配的要素:', props)
        found = true
        
        // 获取要素的中心点并跳转
        const bounds = l.getBounds ? l.getBounds() : null
        if (bounds) {
          map.value.fitBounds(bounds, { padding: [50, 50] })
        } else {
          const latlng = l.getLatLng ? l.getLatLng() : null
          if (latlng) {
            map.value.setView(latlng, 14, { animate: true })
          }
        }
        
        // 移除重复的属性表显示，只保留高亮效果
        // l.openPopup()  // 注释掉这行，避免显示重复的属性表信息
        
        // 高亮效果
        if (l.setStyle) {
          l.setStyle({ color: '#ff0000', fillColor: '#ffcccc', weight: 4 })
          setTimeout(() => layer.resetStyle && layer.resetStyle(l), 2000)
        }
        
        // 移除查询结果信息显示，只保留地图定位和面板信息
        // 不再在查询弹窗中显示重复的要素信息
        searchError.value = ''  // 清空查询结果信息
        
        // 调试信息：确保面板状态正确设置
        console.log('查询成功，面板状态:', {
          showReservoirImgPanel: showReservoirImgPanel.value,
          showFloodHistoryPanel: showFloodHistoryPanel.value,
          reservoirImgName: reservoirImgName.value,
          reservoirImgUrl: reservoirImgUrl.value
        })
        
        // 如果是水库面图层，显示水库详细信息
        if (layerKey === 'beijingReservoirs') {
          const name = props.name || props.库名 || props.NAME
          if (name) {
            console.log('显示水库面板:', name)
            reservoirImgUrl.value = `/reservoir-images/${name}.jpg`
            reservoirImgName.value = name
            
            // 保存水库的属性数据，用于水库参数面板显示
            currentReservoirProps.value = props
            console.log('保存水库属性数据:', props)
            
            // 强制刷新面板显示
            showReservoirImgPanel.value = false
            nextTick(() => {
              showReservoirImgPanel.value = true
            })
            
            // 检查是否有防洪历史数据的水库
            if (name === '怀柔水库' || name === '密云水库' || name === '北台上水库' || name === '十三陵水库' || name === '官厅水库' || name === '崇青水库' || name === '斋堂水库') {
              console.log('水库支持防洪历史:', name)
              // 不自动显示防洪历史面板，等待用户点击按钮
            } else {
              showFloodHistoryPanel.value = false
            }
          }
        } else if (layerKey === 'monitoringPoints') {
          // 监测点图层，显示监测点属性数据
          const name = props.name || props.库名 || props.NAME
          if (name) {
            console.log('显示监测点面板:', name)
            reservoirImgName.value = name
            
            // 保存监测点的属性数据，用于参数面板显示
            currentReservoirProps.value = props
            console.log('保存监测点属性数据:', props)
            
            // 显示监测点面板（复用水库面板的样式，但显示监测点数据）
            showReservoirImgPanel.value = false
            nextTick(() => {
              showReservoirImgPanel.value = true
            })
          }
        } else {
          // 其他图层不显示水库详细信息和防洪历史
          showReservoirImgPanel.value = false
          showFloodHistoryPanel.value = false
        }
      }
    }
  })
  
  if (!found) {
    // 简化错误信息，只显示基本的未找到提示
    searchError.value = `未找到对应的${getLayerDisplayName(layerKey)}`
    showReservoirImgPanel.value = false
    showFloodHistoryPanel.value = false
  }
}

// 获取图层显示名称
const getLayerDisplayName = (layerKey) => {
  const names = {
    monitoringPoints: '水库监测点',
    beijingReservoirs: '水库',
    settlements: '居民点',
    districts: '行政区划',
    waterLines: '河流'
  }
  return names[layerKey] || '要素'
}

// 获取属性显示名称（将英文属性名转换为中文）
const getPropertyDisplayName = (key) => {
  const nameMap = {
    'name': '名称',
    'NAME': '名称',
    '库名': '库名',
    'area': '面积',
    'AREA': '面积',
    '面积': '面积',
    'region': '所属地区',
    'REGION': '所属地区',
    '所属地区': '所属地区',
    'depth': '平均水深',
    'DEPTH': '平均水深',
    '平均水深': '平均水深',
    'buildTime': '建库时间',
    'BUILD_TIME': '建库时间',
    '建库时间': '建库时间',
    'waterSystem': '水系',
    'WATER_SYSTEM': '水系',
    '水系': '水系',
    'useTime': '投用时间',
    'USE_TIME': '投用时间',
    '投用时间': '投用时间',
    'capacity': '库容',
    'CAPACITY': '库容',
    '库容': '库容',
    'maxFloodYear': '最大洪峰年份',
    'MAX_FLOOD_YEAR': '最大洪峰年份',
    '最大洪峰年份': '最大洪峰年份',
    'maxFloodFlow': '最大洪峰流量',
    'MAX_FLOOD_FLOW': '最大洪峰流量',
    '最大洪峰流量': '最大洪峰流量',
    'type': '类型',
    'TYPE': '类型',
    '类型': '类型',
    'status': '状态',
    'STATUS': '状态',
    '状态': '状态',
    'description': '描述',
    'DESCRIPTION': '描述',
    '描述': '描述'
  }
  return nameMap[key] || key
}

// 格式化属性值显示
const formatPropertyValue = (value) => {
  if (value === null || value === undefined || value === '') {
    return '暂无数据'
  }
  if (typeof value === 'number') {
    // 如果是数字，添加适当的单位
    if (value > 1000000) {
      return (value / 1000000).toFixed(2) + '百万'
    } else if (value > 1000) {
      return (value / 1000).toFixed(2) + '千'
    }
    return value.toString()
  }
  return value.toString()
}

// 获取水库参数字段配置
const getReservoirParamFields = () => {
  return [
    { key: '库名', label: '库名' },
    { key: '多年平均库水位', label: '多年平均库水位' },
    { key: '多年平均蓄水量', label: '多年平均蓄水量' },
    { key: '多年日平均入库径流', label: '多年日平均入库径流' },
    { key: '多年日平均出库径流', label: '多年日平均出库径流' },
    { key: '总库容', label: '总库容' },
    { key: '汛限水位', label: '汛限水位' }
  ]
}

// 格式化水库参数值（添加单位）
const formatReservoirParamValue = (key, value) => {
  if (value === null || value === undefined || value === '') {
    return '暂无数据'
  }
  
  // 根据字段类型添加对应单位
  switch (key) {
    case '库名':
      return value.toString()
    case '多年平均库水位':
    case '汛限水位':
      return value.toString() + ' 米'
    case '多年平均蓄水量':
    case '总库容':
      return value.toString() + ' 万立方米'
    case '多年日平均入库径流':
    case '多年日平均出库径流':
      return value.toString() + ' m³/s'
    default:
      return value.toString()
  }
}

// 获取面板标题
const getPanelTitle = () => {
  // 根据当前查询的图层类型返回不同的标题
  if (currentQueryLayer.value === 'monitoringPoints') {
    return '监测点信息'
  } else if (currentQueryLayer.value === 'beijingReservoirs') {
    return `${reservoirImgName.value} - 水库信息`
  } else {
    return reservoirImgName.value
  }
}

// 获取参数面板标题
const getParamsPanelTitle = () => {
  if (currentQueryLayer.value === 'monitoringPoints') {
    return '监测点参数详情'
  } else if (currentQueryLayer.value === 'beijingReservoirs') {
    return '水库参数详情'
  } else {
    return '参数详情'
  }
}

// 获取监测点参数显示名称
const getMonitoringPointDisplayName = (key) => {
  const nameMap = {
    'name': '监测点名称',
    'NAME': '监测点名称',
    '库名': '监测点名称',
    '年平均氨氮': '年平均氨氮',
    '年平均高猛酸盐': '年平均高猛酸盐',
    '年平均化学需氧量': '年平均化学需氧量',
    '年平均流量': '年平均流量',
    '年平均水深': '年平均水深',
    '年平均总氮': '年平均总氮',
    '年平均总磷': '年平均总磷',
    'type': '类型',
    'TYPE': '类型',
    'status': '状态',
    'STATUS': '状态',
    'description': '描述',
    'DESCRIPTION': '描述'
  }
  return nameMap[key] || key
}

// 格式化监测点参数值
const formatMonitoringPointValue = (key, value) => {
  if (value === null || value === undefined || value === '') {
    return '暂无数据'
  }
  
  // 根据字段类型添加对应单位
  switch (key) {
    case '年平均氨氮':
    case '年平均高猛酸盐':
    case '年平均化学需氧量':
    case '年平均总氮':
    case '年平均总磷':
      return value.toString() + ' mg/L'
    case '年平均流量':
      return value.toString() + ' m³/s'
    case '年平均水深':
      return value.toString() + ' m'
    default:
      return value.toString()
  }
}



// 搜索水库视频（备用方案）
const searchReservoirVideo = () => {
  if (reservoirImgName.value === '密云水库') {
    // 使用百度视频搜索页面
    const searchUrl = `https://v.baidu.com/search?word=密云水库`
    window.open(searchUrl, '_blank', 'width=1000,height=700')
  }
}

const showReservoirImgPanel = ref(false)
const reservoirImgUrl = ref('')
const reservoirImgName = ref('')
const showFloodHistoryPanel = ref(false)
const showReservoirParamsPanel = ref(false)
const currentReservoirProps = ref(null) // 存储当前查询到的水库属性数据
const currentQueryLayer = ref('') // 存储当前查询的图层类型

// 历史视图相关
const viewHistory = ref([])
const currentViewIndex = ref(-1)
const canGoBack = ref(false)
const canGoForward = ref(false)

// MXD文件相关
const showMxdPanel = ref(false)
const currentMxdFile = ref(null)
const mxdFileInput = ref(null)

// 模拟MXD图层数据
const mockMxdLayerData = ref([
  {
    id: 'group-1',
    name: '图展',
    type: 'group',
    visible: true,
    children: [
      {
        id: 'beijing-resident-places',
        name: '居民点',
        type: 'point',
        visible: true
      }
    ]
  },
  {
    id: 'layer-1',
    name: '行政区划',
    type: 'polygon',
    visible: true
  },
  {
    id: 'layer-2',
    name: '河流',
    type: 'line',
    visible: true
  },
  {
    id: 'layer-3',
    name: '水系面数据',
    type: 'polygon',
    visible: true
  },
  {
    id: 'layer-4',
    name: '水库数据',
    type: 'polygon',
    visible: true
  }
])

// 水库详细信息数据
const reservoirDetails = {
  '怀柔水库': {
    中文名: '怀柔水库',
    面积: '12 km²',
    所属地区: '北京',
    平均水深: '6.00米',
    建库时间: '1958年3月',
    水系: '海河支流潮白河支流怀河水系',
    投用时间: '1958年7月20日',
    库容: '1亿立方米',
    最大洪峰年份: '1972年',
    最大洪峰流量: '4245立方米/秒'
  },
  '密云水库': {
    中文名: '密云水库',
    面积: '188 km²',
    所属地区: '北京',
    平均水深: '30米',
    建库时间: '1958年9月',
    水系: '海河支流潮白河水系',
    投用时间: '1960年9月',
    库容: '43.75亿立方米',
    最大洪峰年份: '1976年',
    最大洪峰流量: '3670立方米/秒'
  },
  '北台上水库': {
    中文名: '北台上水库',
    面积: '8.5 km²',
    所属地区: '北京',
    平均水深: '12米',
    建库时间: '1973年',
    水系: '海河支流潮白河水系',
    投用时间: '1975年',
    库容: '1.2亿立方米',
    最大洪峰年份: '1980年',
    最大洪峰流量: '850立方米/秒'
  },
  '十三陵水库': {
    中文名: '十三陵水库',
    面积: '15.2 km²',
    所属地区: '北京',
    平均水深: '18米',
    建库时间: '1958年',
    水系: '海河支流温榆河水系',
    投用时间: '1960年',
    库容: '2.8亿立方米',
    最大洪峰年份: '1975年',
    最大洪峰流量: '1200立方米/秒'
  },
  '官厅水库': {
    中文名: '官厅水库',
    面积: '280 km²',
    所属地区: '北京',
    平均水深: '25米',
    建库时间: '1951年',
    水系: '海河支流永定河水系',
    投用时间: '1954年',
    库容: '41.6亿立方米',
    最大洪峰年份: '1963年',
    最大洪峰流量: '3200立方米/秒'
  },
  '崇青水库': {
    中文名: '崇青水库',
    面积: '6.8 km²',
    所属地区: '北京',
    平均水深: '10米',
    建库时间: '1976年',
    水系: '海河支流潮白河水系',
    投用时间: '1978年',
    库容: '0.8亿立方米',
    最大洪峰年份: '1982年',
    最大洪峰流量: '650立方米/秒'
  },
  '斋堂水库': {
    中文名: '斋堂水库',
    面积: '12.5 km²',
    所属地区: '北京',
    平均水深: '15米',
    建库时间: '1974年',
    水系: '海河支流永定河水系',
    投用时间: '1976年',
    库容: '1.5亿立方米',
    最大洪峰年份: '1981年',
    最大洪峰流量: '950立方米/秒'
  },
  '桃峪口水库': {
    中文名: '桃峪口水库',
    面积: '8.2 km²',
    所属地区: '北京',
    平均水深: '12米',
    建库时间: '1975年',
    水系: '海河支流潮白河水系',
    投用时间: '1977年',
    库容: '1.0亿立方米',
    最大洪峰年份: '1983年',
    最大洪峰流量: '780立方米/秒'
  },
  '沙厂水库': {
    中文名: '沙厂水库',
    面积: '6.5 km²',
    所属地区: '北京',
    平均水深: '14米',
    建库时间: '1976年',
    水系: '海河支流潮白河水系',
    投用时间: '1978年',
    库容: '0.9亿立方米',
    最大洪峰年份: '1984年',
    最大洪峰流量: '620立方米/秒'
  },
  '海子水库': {
    中文名: '海子水库',
    面积: '5.8 km²',
    所属地区: '北京',
    平均水深: '11米',
    建库时间: '1977年',
    水系: '海河支流潮白河水系',
    投用时间: '1979年',
    库容: '0.7亿立方米',
    最大洪峰年份: '1985年',
    最大洪峰流量: '580立方米/秒'
  },
  '白河堡水库': {
    中文名: '白河堡水库',
    面积: '7.2 km²',
    所属地区: '北京',
    平均水深: '13米',
    建库时间: '1978年',
    水系: '海河支流潮白河水系',
    投用时间: '1980年',
    库容: '1.1亿立方米',
    最大洪峰年份: '1986年',
    最大洪峰流量: '720立方米/秒'
  },
  '遥桥峪水库': {
    中文名: '遥桥峪水库',
    面积: '4.6 km²',
    所属地区: '北京',
    平均水深: '9米',
    建库时间: '1979年',
    水系: '海河支流潮白河水系',
    投用时间: '1981年',
    库容: '0.5亿立方米',
    最大洪峰年份: '1987年',
    最大洪峰流量: '450立方米/秒'
  },
  '黄松峪水库': {
    中文名: '黄松峪水库',
    面积: '3.8 km²',
    所属地区: '北京',
    平均水深: '8米',
    建库时间: '1980年',
    水系: '海河支流潮白河水系',
    投用时间: '1982年',
    库容: '0.4亿立方米',
    最大洪峰年份: '1988年',
    最大洪峰流量: '380立方米/秒'
  }
}

// 渲染对话框相关
const selectedRenderLayer = ref('monitoringPoints')

// 监测点图层字段
const monitoringPointFields = ref([
  '年平均氨氮','年平均高猛酸盐','年平均化学需氧量','年平均流量','年平均水深','年平均总氮','年平均总磷'
])

// 水库面图层字段
const reservoirFields = ref([
  '多年平均库水位','多年平均蓄水量','多年日平均入库流量','多年日平均出库流量','总库容','汛限水位'
])

// 字段单位映射
const fieldUnits = {
  // 监测点字段单位
  '年平均氨氮': 'mg/L',
  '年平均高猛酸盐': 'mg/L',
  '年平均化学需氧量': 'mg/L',
  '年平均流量': 'm³/s',
  '年平均水深': 'm',
  '年平均总氮': 'mg/L',
  '年平均总磷': 'mg/L',
  // 水库面字段单位
  '多年平均库水位': 'm',
  '多年平均蓄水量': '万m³',
  '多年日平均入库流量': 'm³/s',
  '多年日平均出库流量': 'm³/s',
  '总库容': '万m³',
  '汛限水位': 'm'
}

// 当前选中图层的字段选项
const currentLayerFieldsWithUnits = computed(() => {
  const fields = selectedRenderLayer.value === 'monitoringPoints' ? monitoringPointFields.value : reservoirFields.value
  return fields.map(field => {
    const unit = fieldUnits[field] || ''
    return {
      value: field,
      label: unit ? `${field} (${unit})` : field
    }
  })
})

const renderField = ref('年平均氨氮')
const renderError = ref('')
const gradeCount = ref(3)

// 自然断点法分级结果
const gradeRanges = ref([])

// 图例显示相关
const showLegend = ref(false)
const legendTitle = ref('')
const legendGrades = ref([])

// 预设颜色方案（1-6级）
const colorSchemes = {
  1: ['#ff4d4f'],
  2: ['#ff4d4f', '#52c41a'],
  3: ['#ff4d4f', '#ffd700', '#52c41a'],
  4: ['#ff4d4f', '#ff7a45', '#ffd700', '#52c41a'],
  5: ['#ff4d4f', '#ff7a45', '#ffd700', '#73d13d', '#52c41a'],
  6: ['#ff4d4f', '#ff7a45', '#ffd700', '#bae637', '#73d13d', '#52c41a']
}

// 图层切换处理函数
const onLayerChange = () => {
  // 根据图层类型设置默认字段
  if (selectedRenderLayer.value === 'monitoringPoints') {
    renderField.value = '年平均氨氮'
  } else if (selectedRenderLayer.value === 'beijingReservoirs') {
    renderField.value = '总库容'
  }
  // 清除之前的分级结果
  gradeRanges.value = []
  showLegend.value = false
}

// 字段变化处理函数
const onFieldChange = () => {
  // 清除之前的分级结果
  gradeRanges.value = []
  showLegend.value = false
}

// 分级个数变化处理函数
const onGradeCountChange = () => {
  // 清除之前的分级结果
  gradeRanges.value = []
  showLegend.value = false
}

// 自然断点法算法实现
const jenksNaturalBreaks = (data, numClasses) => {
  if (data.length === 0 || numClasses <= 0 || numClasses > data.length) {
    return []
  }
  
  // 对数据进行排序
  const sortedData = [...data].sort((a, b) => a - b)
  
  // 如果分级数等于数据长度，每个数据点一个级别
  if (numClasses >= data.length) {
    return sortedData.map((value, index) => ({
      min: value,
      max: value,
      color: colorSchemes[Math.min(numClasses, 6)][index] || '#999999'
    }))
  }
  
  // 计算初始断点（等间距）
  const min = sortedData[0]
  const max = sortedData[sortedData.length - 1]
  const step = (max - min) / numClasses
  
  let breakpoints = [min]
  for (let i = 1; i < numClasses; i++) {
    breakpoints.push(min + i * step)
  }
  breakpoints.push(max)
  
  // 优化断点位置
  let improved = true
  let iterations = 0
  const maxIterations = 100
  
  while (improved && iterations < maxIterations) {
    improved = false
    iterations++
    
    // 为每个数据点分配级别
    const classAssignments = sortedData.map(value => {
      for (let i = 0; i < breakpoints.length - 1; i++) {
        if (value >= breakpoints[i] && value <= breakpoints[i + 1]) {
          return i
        }
      }
      return numClasses - 1
    })
    
    // 计算每个级别的平均值
    const classMeans = new Array(numClasses).fill(0)
    const classCounts = new Array(numClasses).fill(0)
    
    sortedData.forEach((value, index) => {
      const classIndex = classAssignments[index]
      classMeans[classIndex] += value
      classCounts[classIndex]++
    })
    
    // 更新断点
    const newBreakpoints = [min]
    for (let i = 0; i < numClasses - 1; i++) {
      if (classCounts[i] > 0 && classCounts[i + 1] > 0) {
        const newBreakpoint = (classMeans[i] + classMeans[i + 1]) / 2
        newBreakpoints.push(newBreakpoint)
      } else {
        newBreakpoints.push(breakpoints[i + 1])
      }
    }
    newBreakpoints.push(max)
    
    // 检查是否有改进
    let hasImprovement = false
    for (let i = 0; i < newBreakpoints.length; i++) {
      if (Math.abs(newBreakpoints[i] - breakpoints[i]) > 0.001) {
        hasImprovement = true
        break
      }
    }
    
    if (hasImprovement) {
      breakpoints = newBreakpoints
      improved = true
    }
  }
  
  // 构建分级结果
  const result = []
  for (let i = 0; i < numClasses; i++) {
    result.push({
      min: breakpoints[i],
      max: breakpoints[i + 1],
      color: colorSchemes[numClasses][i] || '#999999'
    })
  }
  
  return result
}

// 数据分级渲染处理
const handleNaturalBreaksRender = () => {
  renderError.value = ''
  const layer = layerObjects[selectedRenderLayer.value]
  if (!layer) {
    renderError.value = `${selectedRenderLayer.value === 'monitoringPoints' ? '监测点' : '水库'}图层未加载`
    return
  }
  if (!renderField.value) {
    renderError.value = '请选择字段'
    return
  }
  
  try {
    // 收集图层数据
    const dataValues = []
    const layerFeatures = []
    
    layer.eachLayer(l => {
      const props = l.feature && l.feature.properties
      if (props && props[renderField.value] !== undefined && props[renderField.value] !== null) {
        const value = parseFloat(props[renderField.value])
        if (!isNaN(value)) {
          dataValues.push(value)
          layerFeatures.push(l)
        }
      }
    })
    
    if (dataValues.length === 0) {
      renderError.value = '所选字段没有有效的数值数据'
      return
    }
    
    // 使用自然断点法计算分级
    gradeRanges.value = jenksNaturalBreaks(dataValues, gradeCount.value)
    
    if (gradeRanges.value.length === 0) {
      renderError.value = '分级计算失败'
      return
    }
    
    // 统计每个级别的要素数量
    const gradeCounts = new Array(gradeCount.value).fill(0)
    
    // 应用分级渲染
    layerFeatures.forEach(l => {
      const props = l.feature.properties
      const value = parseFloat(props[renderField.value])
      
      // 找到对应的级别
      let gradeIndex = -1
      for (let i = 0; i < gradeRanges.value.length; i++) {
        const grade = gradeRanges.value[i]
        if (value >= grade.min && value <= grade.max) {
          gradeIndex = i
          gradeCounts[i]++
          break
        }
      }
      
      // 应用样式
      if (gradeIndex >= 0) {
        const grade = gradeRanges.value[gradeIndex]
        if (selectedRenderLayer.value === 'monitoringPoints') {
          l.setStyle({
            fillColor: grade.color,
            color: grade.color,
            fillOpacity: 0.95,
            opacity: 1,
            weight: 2
          })
        } else if (selectedRenderLayer.value === 'beijingReservoirs') {
          l.setStyle({
            fillColor: grade.color,
            color: grade.color,
            fillOpacity: 0.8,
            opacity: 0.9,
            weight: 1.5
          })
        }
      }
    })
    
    // 更新图例
    legendTitle.value = `${renderField.value} 分级`
    legendGrades.value = gradeRanges.value.map((grade, index) => ({
      ...grade,
      count: gradeCounts[index]
    }))
    
    // 显示图例
    showLegend.value = true
    
    renderError.value = `✅ 分级渲染完成，共${dataValues.length}个要素`
    
  } catch (error) {
    console.error('分级渲染失败:', error)
    renderError.value = '分级渲染失败: ' + error.message
  }
}

// 重置渲染
const resetRender = () => {
  const layer = layerObjects[selectedRenderLayer.value]
  if (layer) {
    layer.resetStyle()
  }
  // 清除分级结果和图例
  gradeRanges.value = []
  showLegend.value = false
  renderError.value = ''
}

onMounted(() => {
  console.log('MapEditor组件已挂载，开始初始化...')
  
  // 初始化地图
  initMap()
  
  // 加载地理数据
  loadGeoJSONData()
  
  // 初始化渲染相关设置
  selectedRenderLayer.value = 'monitoringPoints'
  renderField.value = '年平均氨氮'
  gradeCount.value = 3
  gradeRanges.value = []
  showLegend.value = false
  
  // 初始化标注系统
  annotationSystem.isActive = false
  annotationSystem.annotations = []
  annotationSystem.autoAnnotations = []
  annotationSystem.manualAnnotations = []
  updateAvailableFields()
  
  // 应用全局性能优化
  nextTick(() => {
    // 检查地图容器状态
    const mapElement = document.getElementById('editor-map')
    if (mapElement) {
      console.log('地图容器状态检查:')
      console.log('地图容器元素:', mapElement)
      console.log('地图容器CSS类:', mapElement.className)
      console.log('地图容器样式:', mapElement.style.cssText)
      console.log('地图容器尺寸:', mapElement.offsetWidth, 'x', mapElement.offsetHeight)
      console.log('地图容器位置:', mapElement.offsetLeft, mapElement.offsetTop)
      console.log('地图容器z-index:', getComputedStyle(mapElement).zIndex)
      
      // 应用CSS性能优化
      mapElement.style.willChange = 'transform'
      mapElement.style.transform = 'translateZ(0)'
    }
    
    // 应用全局性能优化设置
    if (map.value) {
      // 设置全局性能选项
      map.value.options.preferCanvas = true
      map.value.options.updateWhenZooming = false
      map.value.options.updateWhenIdle = true
      map.value.options.keepBuffer = 2
      
      console.log('全局性能优化已应用')
    }
  })
  
  // 添加窗口大小变化监听器
  window.addEventListener('resize', handleWindowResize)
  
  // 备用机制：如果8秒后还在加载，强制关闭并显示基本地图
  setTimeout(() => {
    if (loading.value) {
      console.log('备用机制：强制关闭加载状态并显示基本地图')
      loading.value = false
      showBasicMap()
    }
  }, 8000)
})

// 组件卸载时清理资源
onUnmounted(() => {
  console.log('MapEditor组件卸载，开始清理资源...')
  
  // 移除窗口大小变化监听器
  window.removeEventListener('resize', handleWindowResize)
  
  // 清理查询弹窗拖拽事件监听器
  document.removeEventListener('mousemove', onQueryPopupDrag)
  document.removeEventListener('mouseup', stopQueryPopupDrag)
  document.removeEventListener('touchmove', onQueryPopupDrag)
  document.removeEventListener('touchend', stopQueryPopupDrag)
  
  // 清理地图事件监听器
  if (map.value) {
    map.value.off('resize')
    map.value.off('zoomend')
    map.value.off('move')
    map.value.off('moveend')
    map.value.off('dragstart')
    map.value.off('drag')
    map.value.off('dragend')
    map.value.off('click')
    
    // 销毁地图
    map.value.remove()
    map.value = null
  }
  
  // 清理标注系统
  if (annotationSystem.annotations.length > 0) {
    annotationSystem.annotations.forEach(annotation => {
      if (annotation.layer) {
        try {
          map.value?.removeLayer(annotation.layer)
        } catch (error) {
          console.log('清理标注图层时出错:', error)
        }
      }
    })
    annotationSystem.annotations = []
    annotationSystem.autoAnnotations = []
    annotationSystem.manualAnnotations = []
  }
  
  console.log('MapEditor组件资源清理完成')
})

// 图层变化处理函数
const onAnnotationLayerChange = () => {
  // 根据选择的图层更新可用字段
  updateAvailableFields()
  
  // 设置默认字段
  if (annotationSystem.availableFields.length > 0) {
    annotationSystem.selectedField = annotationSystem.availableFields[0].value
  }
  
  // 清除现有自动标注
  clearAutoAnnotations()
  
  // 不自动生成标注，等待用户手动点击"生成字段标注"按钮
  console.log('图层已切换，请手动点击"生成字段标注"按钮')
}

// 字段变化处理函数
const onAnnotationFieldChange = () => {
  // 清除现有自动标注
  clearAutoAnnotations()
  
  // 不自动生成标注，等待用户手动点击"生成字段标注"按钮
  console.log('字段已切换，请手动点击"生成字段标注"按钮')
}

// 更新可用字段
const updateAvailableFields = () => {
  const layerKey = annotationSystem.selectedLayer
  
  if (layerKey === 'monitoringPoints') {
    annotationSystem.availableFields = [
      { value: '年平均氨氮', label: '年平均氨氮 (mg/L)' },
      { value: '年平均高猛酸盐', label: '年平均高猛酸盐 (mg/L)' },
      { value: '年平均化学需氧量', label: '年平均化学需氧量 (mg/L)' },
      { value: '年平均流量', label: '年平均流量 (m³/s)' },
      { value: '年平均水深', label: '年平均水深 (m)' },
      { value: '年平均总氮', label: '年平均总氮 (mg/L)' },
      { value: '年平均总磷', label: '年平均总磷 (mg/L)' }
    ]
  } else if (layerKey === 'beijingReservoirs') {
    annotationSystem.availableFields = [
      { value: '库名', label: '库名' },
      { value: '多年平均库水位', label: '多年平均库水位 (m)' },
      { value: '多年平均蓄水量', label: '多年平均蓄水量 (万m³)' },
      { value: '多年日平均入库流量', label: '多年日平均入库流量 (m³/s)' },
      { value: '多年日平均出库流量', label: '多年日平均出库流量 (m³/s)' },
      { value: '总库容', label: '总库容 (万m³)' },
      { value: '汛限水位', label: '汛限水位 (m)' }
    ]
  } else if (layerKey === 'settlements') {
    annotationSystem.availableFields = [
      { value: 'NAME', label: '居民点名称' }
    ]
  } else if (layerKey === 'districts') {
    annotationSystem.availableFields = [
      { value: 'NAME', label: '行政区划名称' }
    ]
  } else if (layerKey === 'waterLines') {
    annotationSystem.availableFields = [
      { value: 'name', label: '河流名称' }
    ]
  }
}

// 清除自动标注
const clearAutoAnnotations = () => {
  console.log('清除自动标注被调用，当前自动标注数量:', annotationSystem.autoAnnotations.length)
  console.log('调用栈:', new Error().stack)
  
  annotationSystem.autoAnnotations.forEach(annotation => {
    if (annotation.layer) {
      console.log('移除标注图层:', annotation.text)
      map.value.removeLayer(annotation.layer)
    }
  })
  annotationSystem.autoAnnotations = []
  
  // 从总标注数组中移除自动标注
  const beforeCount = annotationSystem.annotations.length
  annotationSystem.annotations = annotationSystem.annotations.filter(
    annotation => annotation.type !== 'auto'
  )
  const afterCount = annotationSystem.annotations.length
  console.log(`总标注数组从 ${beforeCount} 减少到 ${afterCount}`)
}

// 生成字段标注
const generateFieldAnnotations = () => {
  console.log('开始生成字段标注...')
  
  if (!annotationSystem.showAutoLabels) {
    console.log('自动标注已禁用')
    return
  }
  
  // 检查是否选择了字段
  if (!annotationSystem.selectedField) {
    console.warn('请先选择要标注的字段')
    showZoomMessage('⚠️ 请先选择要标注的字段', 'warning')
    return
  }
  
  // 获取当前选中的图层
  const layer = layerObjects[annotationSystem.selectedLayer]
  if (!layer) {
    console.warn('选择的图层未加载:', annotationSystem.selectedLayer)
    showZoomMessage('❌ 选择的图层未加载', 'warning')
    return
  }
  
  console.log('选择的图层:', annotationSystem.selectedLayer)
  console.log('选择的字段:', annotationSystem.selectedField)
  console.log('图层对象:', layer)
  
  // 清除之前的自动标注
  clearAutoAnnotations()
  
  // 为每个要素生成标注
  let annotationCount = 0
  layer.eachLayer(l => {
    const feature = l.feature
    if (feature && feature.properties) {
      console.log('处理要素:', feature.properties)
      const annotation = createAutoAnnotation(feature, l)
      if (annotation) {
        // 直接创建标注图层并添加到地图
        annotation.layer = createAnnotationLayer(annotation)
        annotationSystem.autoAnnotations.push(annotation)
        annotationSystem.annotations.push(annotation)
        annotationCount++
        console.log('创建标注成功:', annotation)
      }
    }
  })
  
  console.log('生成的标注数量:', annotationCount)
  console.log('当前标注数组:', annotationSystem.annotations)
  
  // 显示生成结果
  if (annotationCount > 0) {
    showZoomMessage(`✅ 成功生成 ${annotationCount} 个字段标注`, 'success')
  } else {
    showZoomMessage('⚠️ 未找到可标注的字段数据', 'warning')
  }
  
  // 不再调用updateAnnotationDisplay，避免重复处理
  console.log('标注生成完成，直接显示在地图上')
}
</script>

<style scoped>
.map-editor-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  width: 100%;
  background: #ffffff; /* 确保容器没有背景 */
}

.map-editor-content {
  flex: 1;
  overflow: hidden;
  position: relative;
  background-color: #ffffff; /* 设置为白色背景 */
}

.editor-map {
  width: 100%;
  height: calc(100vh - 72px);
  z-index: 1; /* 确保地图在最底层 */
  background-color: #ffffff; /* 确保地图容器背景为白色 */
  position: relative; /* 确保定位正确 */
  cursor: default; /* 设置默认鼠标样式 */
}

/* 确保页面背景为白色 */
body {
  background: #ffffff !important;
}

#app {
  background: #ffffff !important;
}

.map-editor-container {
  background: #ffffff !important;
}

.control-panel {
  position: absolute;
  top: 32px;
  right: 32px;
  background: rgba(255,255,255,0.97);
  border-radius: 16px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.10);
  padding: 20px 28px 20px 24px;
  z-index: 1000;
  min-width: 220px;
  max-width: 360px;
  width: auto;
  font-size: 16px;
  transition: all 0.3s ease;
}

.control-panel.panel-hidden {
  min-width: auto;
  max-width: auto;
  width: auto;
  padding: 12px 16px;
}

.control-panel.panel-hidden .panel-header h3 {
  display: none;
}

.control-panel.panel-hidden .panel-header {
  justify-content: center;
  margin-bottom: 0;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.panel-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
}

.panel-toggle-btn {
  background: transparent;
  color: #333;
  border: none;
  border-radius: 6px;
  padding: 8px 12px;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.2s;
  min-width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.panel-toggle-btn:hover {
  background: rgba(0, 0, 0, 0.1);
  color: #000;
}

.panel-content {
  transition: opacity 0.3s ease;
}
.layer-control {
  margin-bottom: 8px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.layer-color-control {
  display: flex;
  align-items: center;
  gap: 8px;
}

.color-preview {
  width: 20px;
  height: 20px;
  border-radius: 4px;
  border: 2px solid #ddd;
  cursor: pointer;
  transition: border-color 0.2s;
}

.color-preview:hover {
  border-color: #999;
}

.color-preview.point-preview {
  border-radius: 50%;
}

.color-input {
  width: 24px;
  height: 24px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  opacity: 0;
  position: absolute;
  pointer-events: none;
}
.loading {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: rgba(255,255,255,0.95);
  padding: 16px 32px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  font-size: 18px;
  z-index: 2000;
}
.custom-toolbar {
  position: absolute;
  top: 120px;
  left: 18px;
  display: flex;
  flex-direction: column;
  align-items: center;
  background: rgba(255,255,255,0.95);
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.10);
  padding: 10px 6px;
  z-index: 1200;
  gap: 10px;
}
.custom-toolbar img {
  width: 32px;
  height: 32px;
  margin: 0 0 2px 0;
  cursor: pointer;
  object-fit: contain;
  transition: background 0.2s;
  border-radius: 6px;
}
.custom-toolbar img:hover {
  background: #e6f7ff;
}
.custom-toolbar img.active-tool {
  background: #1890ff;
  filter: brightness(1.2);
}
.custom-toolbar img.disabled-tool {
  opacity: 0.4;
  cursor: default;
  filter: grayscale(100%);
}
.custom-toolbar img.disabled-tool:hover {
  background: transparent;
}

/* 取消绘制按钮样式 */
.cancel-drawing-btn {
  width: 32px;
  height: 32px;
  background: #ff4d4f;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  margin: 2px 0;
  transition: background 0.2s;
  color: white;
  font-size: 14px;
}

.cancel-drawing-btn:hover {
  background: #ff7875;
}

/* 放大下拉菜单样式 */
.zoom-dropdown-container {
  position: relative;
  display: inline-block;
  margin-right: 8px;
  /* 确保容器正确定位 */
  z-index: 1000;
}

/* 缩小下拉菜单的特殊定位 */
.zoom-dropdown-container.zoom-out-container .zoom-dropdown {
  left: 100% !important;
  right: auto !important;
  margin-left: 8px !important;
  margin-right: 0 !important;
  /* 确保缩小下拉菜单正确显示 */
  background: #ffffff !important;
  border: 1px solid #d0d0d0 !important;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15) !important;
  /* 防止白框问题 */
  min-width: 140px !important;
  z-index: 1001 !important;
  padding: 4px 0 !important;
  border-radius: 8px !important;
}

/* 缩小下拉菜单的箭头样式 */
.zoom-dropdown-container.zoom-out-container .zoom-dropdown::before {
  left: -6px !important;
  right: auto !important;
  top: 12px !important;
  width: 0 !important;
  height: 0 !important;
  border-top: 6px solid transparent !important;
  border-bottom: 6px solid transparent !important;
  border-left: none !important;
  border-right: 6px solid #ffffff !important;
}

.zoom-dropdown-container.zoom-out-container .zoom-dropdown::after {
  left: -7px !important;
  right: auto !important;
  top: 12px !important;
  width: 0 !important;
  height: 0 !important;
  border-top: 6px solid transparent !important;
  border-bottom: 6px solid transparent !important;
  border-left: none !important;
  border-right: 6px solid #d0d0d0 !important;
}



.zoom-dropdown {
  position: absolute;
  top: 0;
  left: 100%;
  background: #ffffff;
  border: 1px solid #d0d0d0;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  min-width: 140px;
  z-index: 1001;
  margin-left: 8px;
  padding: 4px 0;
  /* 防止意外的白色框 */
  overflow: hidden;
  max-height: 200px;
}

/* 隐藏状态的下拉菜单 */
.zoom-dropdown.hidden {
  display: none !important;
  visibility: hidden !important;
  opacity: 0 !important;
  pointer-events: none !important;
}

/* 确保缩小下拉菜单正确显示 */
.zoom-dropdown-container.zoom-out-container .zoom-dropdown {
  display: block !important;
  visibility: visible !important;
  opacity: 1 !important;
  pointer-events: auto !important;
  /* 强制覆盖默认样式 */
  background: #ffffff !important;
  border: 1px solid #d0d0d0 !important;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15) !important;
}

.zoom-dropdown::before {
  content: '';
  position: absolute;
  left: -6px;
  top: 12px;
  width: 0;
  height: 0;
  border-top: 6px solid transparent;
  border-bottom: 6px solid transparent;
  border-right: 6px solid #ffffff;
}

.zoom-dropdown::after {
  content: '';
  position: absolute;
  left: -7px;
  top: 12px;
  width: 0;
  height: 0;
  border-top: 6px solid transparent;
  border-bottom: 6px solid transparent;
  border-right: 6px solid #d0d0d0;
}

.zoom-option {
  padding: 8px 16px;
  cursor: pointer;
  transition: background-color 0.2s ease;
  font-size: 14px;
  color: #333;
  white-space: nowrap;
}

.zoom-option:hover {
  background: #f0f8ff;
}

.zoom-option:first-child {
  border-top-left-radius: 8px;
  border-top-right-radius: 8px;
}

.zoom-option:last-child {
  border-bottom-left-radius: 8px;
  border-bottom-right-radius: 8px;
}

/* 放大镜鼠标样式 */
.zoom-in-cursor {
  cursor: zoom-in !important;
}

/* 确保地图容器在按点放大模式下能正确显示鼠标样式 */
.editor-map.zoom-in-cursor {
  cursor: zoom-in !important;
}

/* 强制覆盖Leaflet的鼠标样式 */
.editor-map.zoom-in-cursor .leaflet-pane,
.editor-map.zoom-in-cursor .leaflet-overlay-pane,
.editor-map.zoom-in-cursor .leaflet-tile-pane,
.editor-map.zoom-in-cursor .leaflet-marker-pane,
.editor-map.zoom-in-cursor .leaflet-tooltip-pane,
.editor-map.zoom-in-cursor .leaflet-popup-pane {
  cursor: zoom-in !important;
}

/* 确保地图容器内的所有元素都显示放大镜鼠标 */
.editor-map.zoom-in-cursor * {
  cursor: zoom-in !important;
}

/* 排除工具栏和控制面板 */
.editor-map.zoom-in-cursor .custom-toolbar,
.editor-map.zoom-in-cursor .control-panel,
.editor-map.zoom-in-cursor .custom-toolbar *,
.editor-map.zoom-in-cursor .control-panel * {
  cursor: default !important;
}

/* 缩小镜鼠标样式 */
.zoom-out-cursor {
  cursor: zoom-out !important;
}

/* 确保地图容器在按点缩小模式下能正确显示鼠标样式 */
.editor-map.zoom-out-cursor {
  cursor: zoom-out !important;
}

/* 强制覆盖Leaflet的鼠标样式 */
.editor-map.zoom-out-cursor .leaflet-pane,
.editor-map.zoom-out-cursor .leaflet-overlay-pane,
.editor-map.zoom-out-cursor .leaflet-tile-pane,
.editor-map.zoom-out-cursor .leaflet-marker-pane,
.editor-map.zoom-out-cursor .leaflet-tooltip-pane,
.editor-map.zoom-out-cursor .leaflet-popup-pane {
  cursor: zoom-out !important;
}

/* 确保地图容器内的所有元素都显示缩小镜鼠标 */
.editor-map.zoom-out-cursor * {
  cursor: zoom-out !important;
}

/* 排除工具栏和控制面板 */
.editor-map.zoom-out-cursor .custom-toolbar,
.editor-map.zoom-out-cursor .control-panel,
.editor-map.zoom-out-cursor .custom-toolbar *,
.editor-map.zoom-out-cursor .control-panel * {
  cursor: default !important;
}

/* 平移鼠标样式 - 准备抓取 */
.grab-cursor {
  cursor: grab !important;
}

/* 平移鼠标样式 - 抓取中 */
.grabbing-cursor {
  cursor: grabbing !important;
}

/* 平移性能优化样式 */
.editor-map.panning {
  /* 平移时禁用一些CSS动画，提高性能 */
  transition: none !important;
  animation: none !important;
}

.editor-map.panning * {
  /* 平移时禁用子元素的动画 */
  transition: none !important;
  animation: none !important;
}

/* 平移时的图层优化 */
.editor-map.panning .leaflet-pane {
  /* 平移时简化图层渲染 */
  will-change: transform;
  transform: translateZ(0);
}

/* 选择要素鼠标样式 */
.pointer-cursor {
  cursor: pointer !important;
}

/* 识别要素鼠标样式 */
.info-cursor {
  cursor: help !important;
}

/* MXD文件处理相关样式 */
.mxd-loading-toast,
.mxd-success-toast,
.mxd-error-toast {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  padding: 15px 25px;
  border-radius: 8px;
  z-index: 2000;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 3px 10px rgba(0, 0, 0, 0.2);
  animation: fadeIn 0.3s ease;
  font-weight: 500;
}

.mxd-loading-toast {
  background-color: #ffffff;
  color: #333;
  display: flex;
  flex-direction: column;
}

.mxd-success-toast {
  background-color: #4caf50;
  color: white;
}

.mxd-error-toast {
  background-color: #f44336;
  color: white;
}

.spinner {
  border: 3px solid rgba(0, 0, 0, 0.1);
  border-radius: 50%;
  border-top: 3px solid #2196F3;
  width: 30px;
  height: 30px;
  margin-bottom: 10px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* MXD控制面板样式 */
.mxd-control-panel {
  position: absolute;
  top: 10px;
  right: 10px;
  width: 280px;
  background-color: #fff;
  border-radius: 4px;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
  z-index: 1000;
  overflow: hidden;
  max-height: calc(100vh - 100px);
  display: flex;
  flex-direction: column;
}

.mxd-panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px;
  background-color: #f0f0f0;
  border-bottom: 1px solid #ccc;
}

.mxd-panel-header h3 {
  margin: 0;
  font-size: 16px;
}

.mxd-close-btn {
  cursor: pointer;
  font-size: 20px;
  line-height: 1;
}

.mxd-panel-content {
  padding: 10px;
  overflow-y: auto;
}

.mxd-layer-group {
  margin-bottom: 15px;
}

.mxd-layer-group-header {
  display: flex;
  align-items: center;
  margin-bottom: 8px;
  font-weight: bold;
}

.folder-icon {
  width: 16px;
  height: 16px;
  margin-right: 5px;
}

.mxd-layer-items {
  margin-left: 5px;
}

.mxd-layer-item {
  display: flex;
  align-items: center;
  margin-bottom: 6px;
}

.mxd-layer-item input {
  margin-right: 8px;
}

.layer-label {
  display: flex;
  align-items: center;
  cursor: pointer;
}

.layer-icon {
  margin-right: 5px;
}

.point-icon {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: #ff7800;
  border: 1px solid #000;
  display: inline-block;
  margin-right: 5px;
}

.layer-name {
  font-size: 14px;
}

.group-name {
  font-weight: 600;
}

.disabled {
  color: #999;
  cursor: not-allowed;
}

.mxd-properties {
  margin-top: 15px;
  padding-top: 15px;
  border-top: 1px solid #eee;
}

.mxd-properties h4 {
  margin: 0 0 10px;
  font-size: 14px;
}

.mxd-property-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 5px;
  font-size: 12px;
}

/* 要素属性面板样式 */
.feature-properties-panel {
  position: absolute;
  bottom: 20px;
  right: 20px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.15);
  width: 300px;
  max-height: 400px;
  overflow-y: auto;
  z-index: 1000;
  display: none;
}

.properties-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 15px;
  background: #f0f0f0;
  border-top-left-radius: 8px;
  border-top-right-radius: 8px;
  border-bottom: 1px solid #ddd;
}

.properties-header h3 {
  margin: 0;
  font-size: 16px;
  color: #333;
}

.close-btn {
  cursor: pointer;
  font-size: 20px;
  color: #666;
}

.properties-content {
  padding: 10px 15px;
}

.property-item {
  margin-bottom: 8px;
  display: flex;
  justify-content: space-between;
}

.property-name {
  font-weight: bold;
  color: #555;
  margin-right: 10px;
}

.property-value {
  color: #333;
}

/* 弹出框样式 */
.popup-content {
  font-size: 12px;
  max-height: 200px;
  overflow-y: auto;
}

.popup-content div {
  margin-bottom: 5px;
}

.search-bar-modal {
  position: absolute;
  top: 40px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 2001;
  background: rgba(255,255,255,0.98);
  border-radius: 12px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.13);
  padding: 20px 24px 16px 20px;
  min-width: 400px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.search-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  margin-bottom: 16px;
  cursor: move;
  user-select: none;
}

.search-header h3 {
  margin: 0;
  font-size: 18px;
  color: #333;
  font-weight: 600;
}

.search-header-controls {
  display: flex;
  align-items: center;
  gap: 8px;
}

.layer-selection {
  width: 100%;
  margin-bottom: 16px;
}

.layer-selection-label {
  display: block;
  font-size: 14px;
  color: #666;
  margin-bottom: 8px;
  font-weight: 500;
}

.layer-select-dropdown {
  width: 100%;
  padding: 8px 12px;
  font-size: 14px;
  border: 1px solid #d0d0d0;
  border-radius: 6px;
  background: #ffffff;
  color: #333;
  cursor: pointer;
  outline: none;
  transition: all 0.2s;
}

.layer-select-dropdown:hover {
  border-color: #40a9ff;
}

.layer-select-dropdown:focus {
  border-color: #1890ff;
  box-shadow: 0 0 0 2px rgba(24, 144, 255, 0.2);
}

.layer-select-dropdown option {
  padding: 8px 12px;
  background: #ffffff;
  color: #333;
}

.search-input-container {
  display: flex;
  align-items: center;
  width: 100%;
}
.search-input {
  flex: 1;
  padding: 7px 12px;
  font-size: 15px;
  border: 1px solid #d0d0d0;
  border-radius: 6px;
  outline: none;
  margin-right: 10px;
}
.search-btn {
  background: #1890ff;
  color: #fff;
  border: none;
  border-radius: 6px;
  padding: 7px 18px;
  font-size: 15px;
  cursor: pointer;
  margin-right: 8px;
  transition: background 0.2s;
}
.search-btn:hover {
  background: #40a9ff;
}
.search-reset {
  font-size: 18px;
  color: #888;
  cursor: pointer;
  user-select: none;
  transition: color 0.2s;
}

.search-reset:hover {
  color: #1890ff;
}

.search-close {
  font-size: 22px;
  color: #888;
  cursor: pointer;
  margin-left: 2px;
  user-select: none;
}
.search-error {
  color: #f5222d;
  margin-top: 8px;
  font-size: 14px;
}

/* 查询弹窗拖拽状态 */
.search-bar-modal.dragging {
  transform: none !important;
  transition: none !important;
}
.popup-img-block {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin: 12px 0 4px 0;
}
.popup-reservoir-img {
  max-width: 220px;
  max-height: 120px;
  border-radius: 8px;
  box-shadow: 0 2px 12px #bbb;
  margin-bottom: 6px;
  transition: transform 0.25s cubic-bezier(.4,2,.6,1.2), box-shadow 0.2s;
  cursor: pointer;
}
.popup-reservoir-img:hover {
  transform: scale(1.08);
  box-shadow: 0 6px 24px #888;
}
.popup-img-title {
  font-size: 15px;
  color: #333;
  font-weight: 500;
  margin-bottom: 4px;
  letter-spacing: 1px;
}
.popup-img-divider {
  width: 80%;
  height: 1px;
  background: #ececec;
  margin: 6px 0 0 0;
  border-radius: 1px;
}
.reservoir-img-panel {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  min-width: 280px;
  max-width: 360px;
  background: rgba(255,255,255,0.98);
  border-radius: 14px;
  box-shadow: 0 4px 18px rgba(0,0,0,0.13);
  padding: 18px 18px 12px 18px;
  display: flex;
  flex-direction: column;
  align-items: center;
  z-index: 9999;
}
.img-panel-close {
  position: absolute;
  top: 8px;
  right: 12px;
  font-size: 22px;
  color: #888;
  cursor: pointer;
  user-select: none;
}
.reservoir-img-main {
  max-width: 220px;
  max-height: 120px;
  border-radius: 8px;
  box-shadow: 0 2px 12px #bbb;
  margin-bottom: 8px;
  margin-top: 8px;
  transition: transform 0.25s cubic-bezier(.4,2,.6,1.2), box-shadow 0.2s;
  cursor: pointer;
}
.reservoir-img-main:hover {
  transform: scale(1.08);
  box-shadow: 0 6px 24px #888;
}
.reservoir-img-title {
  font-size: 16px;
  color: #222;
  font-weight: 500;
  margin-bottom: 8px;
  letter-spacing: 1px;
  text-align: center;
}

/* 水库详细信息样式 */
.reservoir-details {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #e8e8e8;
}

.details-title {
  font-size: 14px;
  color: #333;
  font-weight: 600;
  margin-bottom: 8px;
  text-align: center;
}

.details-table {
  font-size: 12px;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 4px;
  padding: 2px 0;
}

.detail-label {
  color: #666;
  font-weight: 500;
  min-width: 70px;
}

.detail-value {
  color: #333;
  text-align: right;
  flex: 1;
  margin-left: 8px;
}

/* 水库功能按钮样式 */
.reservoir-buttons {
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid #e8e8e8;
  display: flex;
  gap: 12px;
  justify-content: center;
}

.reservoir-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  background: #f0f0f0;
  color: #333;
}

.reservoir-btn:hover {
  background: #e0e0e0;
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.reservoir-params-btn {
  background: #e6f7ff;
  color: #1890ff;
  border: 1px solid #91d5ff;
}

.reservoir-params-btn:hover {
  background: #bae7ff;
  border-color: #69c0ff;
}

.flood-history-btn {
  background: #f6ffed;
  color: #52c41a;
  border: 1px solid #b7eb8f;
}



.search-video-btn {
  background: #f0f5ff;
  color: #2f54eb;
  border: 1px solid #adc6ff;
}

.search-video-btn:hover {
  background: #d6e4ff;
  border-color: #85a5ff;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(47, 84, 235, 0.3);
}

.flood-history-btn:hover {
  background: #d9f7be;
  border-color: #95de64;
}

.btn-icon {
  font-size: 16px;
}
.render-modal {
  position: absolute;
  top: 60px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 2002;
  background: rgba(255,255,255,0.99);
  border-radius: 14px;
  box-shadow: 0 4px 18px rgba(0,0,0,0.13);
  min-width: 340px;
  max-width: 420px;
  padding: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
}
.render-modal-content {
  width: 100%;
  padding: 18px 24px 18px 24px;
}
.render-modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 18px;
  font-weight: 600;
  color: #222;
  margin-bottom: 12px;
}
.render-modal-close {
  font-size: 22px;
  color: #888;
  cursor: pointer;
  user-select: none;
}
.render-modal-body {
  width: 100%;
}
.render-row {
  display: flex;
  align-items: center;
  margin-bottom: 14px;
}
.render-row label {
  min-width: 54px;
  color: #555;
  font-size: 15px;
  margin-right: 8px;
}
.render-select {
  min-width: 120px;
  font-size: 15px;
  padding: 4px 8px;
  border-radius: 6px;
  border: 1px solid #d0d0d0;
  margin-right: 10px;
}
.render-input {
  width: 70px;
  font-size: 15px;
  padding: 4px 8px;
  border-radius: 6px;
  border: 1px solid #d0d0d0;
  margin-right: 10px;
}
.render-color {
  width: 32px;
  height: 32px;
  border: none;
  border-radius: 6px;
  margin-right: 6px;
  box-shadow: 0 1px 4px #eee;
}
.render-color-label {
  font-size: 13px;
  color: #888;
  margin-right: 12px;
}


/* 绘制模式样式 */
.drawing-mode {
  cursor: crosshair !important;
}

.rectangle-drawing {
  cursor: crosshair !important;
}

.render-btn {
  background: #1890ff;
  color: #fff;
  border: none;
  border-radius: 6px;
  padding: 7px 24px;
  font-size: 16px;
  cursor: pointer;
  transition: background 0.2s;
}
.render-btn:hover {
  background: #40a9ff;
}
.render-error {
  color: #f5222d;
  margin-top: 8px;
  font-size: 14px;
}

/* 分级预览样式 */
.grade-preview {
  margin: 16px 0;
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #e9ecef;
}

.grade-preview h4 {
  margin: 0 0 12px 0;
  font-size: 16px;
  color: #333;
  font-weight: 600;
}

.grade-preview-items {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.grade-preview-item {
  display: flex;
  align-items: center;
  padding: 8px;
  background: white;
  border-radius: 6px;
  border: 1px solid #e9ecef;
}

.grade-color-preview {
  width: 24px;
  height: 24px;
  border-radius: 4px;
  margin-right: 12px;
  border: 2px solid #fff;
  box-shadow: 0 1px 3px rgba(0,0,0,0.2);
}

.grade-range-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.grade-level {
  font-size: 12px;
  color: #666;
  font-weight: 500;
}

.grade-value {
  font-size: 14px;
  color: #333;
  font-weight: 600;
}

.render-reset-btn {
  background: #6c757d;
  color: #fff;
  border: none;
  border-radius: 6px;
  padding: 7px 16px;
  font-size: 14px;
  cursor: pointer;
  transition: background 0.2s;
  margin-left: 8px;
}

.render-reset-btn:hover {
  background: #5a6268;
}

/* 全图视图提示信息样式 */
.full-extent-message {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 15px 25px;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
  z-index: 2000;
  pointer-events: none;
  animation: fullExtentMessageFadeIn 0.3s ease;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
  border: 1px solid rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(10px);
  text-align: center;
  min-width: 200px;
}

.full-extent-message::before {
  content: '🗺️';
  display: block;
  font-size: 24px;
  margin-bottom: 8px;
}

/* 缩放提示信息样式 */
.zoom-message {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  padding: 12px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  z-index: 2000;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  animation: zoomMessageFadeIn 0.3s ease;
}

.zoom-message-success {
  background: #f6ffed;
  color: #52c41a;
  border: 1px solid #b7eb8f;
}

.zoom-message-warning {
  background: #fffbe6;
  color: #faad14;
  border: 1px solid #ffe58f;
}

.zoom-message-info {
  background: #e6f7ff;
  color: #1890ff;
  border: 1px solid #91d5ff;
}

@keyframes fullExtentMessageFadeIn {
  from {
    opacity: 0;
    transform: translate(-50%, -50%) scale(0.8);
  }
  to {
    opacity: 1;
    transform: translate(-50%, -50%) scale(1);
  }
}

@keyframes zoomMessageFadeIn {
  from {
    opacity: 0;
    transform: translate(-50%, -50%) scale(0.8);
  }
  to {
    opacity: 1;
    transform: translate(-50%, -50%) scale(1);
  }
}

/* 加载提示样式 */
.loading-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(255, 255, 255, 0.9);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 2000;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 16px;
}

.loading-text {
  font-size: 16px;
  color: #333;
  font-weight: 500;
  margin-bottom: 16px;
}

.loading-progress {
  margin-bottom: 16px;
  width: 200px;
}

.progress-bar {
  width: 100%;
  height: 8px;
  background: #e9ecef;
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 8px;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #1890ff, #40a9ff);
  border-radius: 4px;
  transition: width 0.3s ease;
}

.progress-text {
  font-size: 14px;
  color: #666;
  text-align: center;
  font-weight: 500;
}

.force-close-btn {
  margin-top: 16px;
  padding: 8px 16px;
  background: #ff4d4f;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  transition: background 0.2s;
}

.force-close-btn:hover {
  background: #ff7875;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* 标注标记样式 */
.annotation-label {
  background: transparent !important;
  border: none !important;
}

.annotation-text {
  transition: all 0.2s;
  background: rgba(255, 255, 255, 0.1) !important;
  backdrop-filter: blur(2px);
  border: 1px solid rgba(0, 0, 0, 0.3) !important;
  border-radius: 4px;
  padding: 4px 8px;
  font-weight: 600;
  letter-spacing: 0.5px;
  text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.8);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.annotation-text:hover {
  transform: scale(1.05);
  box-shadow: 0 4px 8px rgba(0,0,0,0.4) !important;
  background: rgba(255, 255, 255, 0.2) !important;
}

/* 标注弹窗样式 */
.annotation-popup {
  text-align: left;
  min-width: 280px;
  max-width: 350px;
  background: rgba(255, 255, 255, 0.98);
  border-radius: 8px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  overflow: hidden;
}

.annotation-popup-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 12px 16px;
  cursor: move;
  user-select: none;
  display: flex;
  justify-content: space-between;
  align-items: center;
  position: relative;
}

.annotation-popup-header::before {
  content: '📍';
  margin-right: 8px;
  font-size: 16px;
}

.annotation-popup-header h4 {
  margin: 0;
  color: white;
  font-size: 16px;
  font-weight: 600;
  flex: 1;
}

.annotation-popup-close {
  cursor: pointer;
  font-size: 20px;
  color: rgba(255, 255, 255, 0.8);
  padding: 2px 6px;
  border-radius: 4px;
  transition: all 0.2s;
  line-height: 1;
}

.annotation-popup-close:hover {
  color: white;
  background: rgba(255, 255, 255, 0.2);
}

.annotation-popup-content {
  padding: 16px;
  background: white;
}

.annotation-popup-content p {
  margin: 8px 0;
  color: #555;
  font-size: 14px;
  line-height: 1.5;
  display: flex;
  align-items: center;
}

.annotation-popup-content p strong {
  color: #333;
  min-width: 60px;
  margin-right: 8px;
}

.annotation-popup button {
  background: #1890ff;
  color: white;
  border: none;
  border-radius: 6px;
  padding: 8px 16px;
  margin-top: 12px;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.2s;
  font-weight: 500;
}

.annotation-popup button:hover {
  background: #40a9ff;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(24, 144, 255, 0.3);
}

.annotation-actions {
  margin-top: 16px;
  display: flex;
  gap: 12px;
  justify-content: center;
  padding-top: 12px;
  border-top: 1px solid #f0f0f0;
}

.annotation-actions button:last-child {
  background: #ff4d4f;
}

.annotation-actions button:last-child:hover {
  background: #ff7875;
  box-shadow: 0 4px 12px rgba(255, 77, 79, 0.3);
}

/* 可拖拽弹窗样式 */
.draggable-annotation-popup {
  cursor: default;
}

.draggable-annotation-popup .leaflet-popup-content-wrapper {
  background: transparent;
  box-shadow: none;
  border-radius: 0;
}

.draggable-annotation-popup .leaflet-popup-tip {
  display: none;
}

.draggable-annotation-popup .leaflet-popup-close-button {
  display: none;
}

/* 拖拽时的视觉反馈 */
.annotation-popup-header:active {
  background: linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%);
  transform: scale(0.98);
}

/* 拖拽时的光标样式 */
.annotation-popup-header:hover {
  background: linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%);
}

/* 弹窗拖拽时的阴影效果 */
.draggable-annotation-popup.leaflet-popup {
  transition: box-shadow 0.3s ease;
}

.draggable-annotation-popup.leaflet-popup:hover {
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
}

/* 移动设备优化 */
@media (max-width: 768px) {
  .annotation-popup {
    min-width: 250px;
    max-width: 300px;
  }
  
  .annotation-popup-header {
    padding: 10px 14px;
  }
  
  .annotation-popup-content {
    padding: 14px;
  }
  
  .annotation-popup-content p {
    font-size: 13px;
  }
  
  .annotation-actions {
    flex-direction: column;
    gap: 8px;
  }
  
  .annotation-popup button {
    width: 100%;
    padding: 10px 16px;
  }
}

/* 标注编辑输入框样式 */
.annotation-edit-input {
  box-shadow: 0 4px 12px rgba(0,0,0,0.3);
  border-radius: 4px;
  min-width: 100px;
}

/* 标注控制面板样式 */
.annotation-control-panel {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: rgba(255,255,255,0.98);
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.2);
  padding: 0;
  z-index: 2000;
  min-width: 350px;
  max-width: 500px;
  max-height: 80vh;
  overflow: hidden;
  border: 1px solid rgba(0,0,0,0.1);
  cursor: default;
  user-select: none;
  transition: all 0.3s ease;
}

/* 拖拽状态下的面板样式 */
.annotation-control-panel.dragging {
  transform: none !important;
  transition: none !important;
}

.annotation-panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 20px 15px 20px;
  border-bottom: 1px solid #e8e8e8;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-top-left-radius: 12px;
  border-top-right-radius: 12px;
  cursor: move;
  user-select: none;
  position: relative;
}

.annotation-panel-controls {
  display: flex;
  align-items: center;
  gap: 12px;
}

.annotation-panel-header::before {
  content: '🎛️';
  margin-right: 8px;
  font-size: 16px;
}

.annotation-panel-header h4 {
  margin: 0;
  font-size: 18px;
  color: white;
  font-weight: 600;
  flex: 1;
}

.annotation-panel-close {
  cursor: pointer;
  font-size: 20px;
  color: rgba(255, 255, 255, 0.8);
  padding: 4px 8px;
  border-radius: 4px;
  transition: all 0.2s;
  line-height: 1;
}

.annotation-panel-close:hover {
  background: rgba(255, 255, 255, 0.2);
  color: white;
}

.annotation-panel-reset {
  cursor: pointer;
  font-size: 16px;
  color: rgba(255, 255, 255, 0.8);
  padding: 4px 6px;
  border-radius: 4px;
  transition: all 0.2s;
  line-height: 1;
}

.annotation-panel-reset:hover {
  background: rgba(255, 255, 255, 0.2);
  color: white;
  transform: rotate(180deg);
}

/* 拖拽时的视觉反馈 */
.annotation-panel-header:active {
  background: linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%);
  transform: scale(0.98);
}

.annotation-panel-header:hover {
  background: linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%);
}

/* 拖拽时的面板样式 */
.annotation-control-panel.dragging {
  box-shadow: 0 12px 40px rgba(0,0,0,0.3);
  transform: scale(1.02);
}

/* 标注标签样式 */
.annotation-label {
  background: transparent !important;
  border: none !important;
}

.annotation-text {
  font-family: Arial, sans-serif !important;
  font-weight: 700 !important;
  text-rendering: optimizeLegibility !important;
  -webkit-font-smoothing: antialiased !important;
  -moz-osx-font-smoothing: grayscale !important;
  transform: translateZ(0) !important;
  backface-visibility: hidden !important;
  perspective: 1000px !important;
}

/* 确保标注在地图上层显示 */
.leaflet-marker-icon.annotation-label {
  z-index: 1000 !important;
}

/* 移动设备优化 */
@media (max-width: 768px) {
  .annotation-control-panel {
    min-width: 300px;
    max-width: 90vw;
    max-height: 70vh;
  }
  
  .annotation-panel-header {
    padding: 16px 16px 12px 16px;
  }
  
  .annotation-panel-header h4 {
    font-size: 16px;
  }
  
  .annotation-panel-content {
    padding: 16px;
    max-height: calc(70vh - 70px);
  }
  
  .annotation-section {
    padding: 12px;
  }
  
  .control-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
  
  .control-item label {
    min-width: auto;
    margin-bottom: 4px;
  }
}

.annotation-panel-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding: 20px;
  max-height: calc(80vh - 80px);
  overflow-y: auto;
}

.annotation-section {
  border: 1px solid #e9ecef;
  border-radius: 8px;
  padding: 15px;
  background: #f8f9fa;
}

.annotation-section h5 {
  margin: 0 0 15px 0;
  font-size: 16px;
  color: #333;
  font-weight: 600;
}

.control-item {
  display: flex;
  align-items: center;
  margin-bottom: 12px;
  gap: 10px;
}

.control-item:last-child {
  margin-bottom: 0;
}

.control-item label {
  min-width: 80px;
  font-size: 14px;
  color: #555;
  font-weight: 500;
}

.control-item input[type="checkbox"] {
  margin: 0;
}

.control-item input[type="number"],
.control-item input[type="color"],
.control-item select {
  padding: 6px 8px;
  border: 1px solid #d0d0d0;
  border-radius: 4px;
  font-size: 14px;
  min-width: 80px;
}

.control-item input[type="color"] {
  width: 40px;
  height: 32px;
  padding: 2px;
}

.annotation-btn {
  background: #1890ff;
  color: white;
  border: none;
  border-radius: 6px;
  padding: 8px 16px;
  font-size: 14px;
  cursor: pointer;
  transition: background 0.2s;
  width: 100%;
}

.annotation-btn:hover {
  background: #40a9ff;
}

.annotation-btn-danger {
  background: #ff4d4f;
}

.annotation-btn-danger:hover {
  background: #ff7875;
}

/* 水库参数面板样式 */
.reservoir-params-panel {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 400px;
  max-height: 500px;
  background: rgba(255,255,255,0.98);
  border-radius: 14px;
  box-shadow: 0 4px 18px rgba(0,0,0,0.13);
  padding: 18px 18px 12px 18px;
  display: flex;
  flex-direction: column;
  z-index: 9999;
  overflow-y: auto;
}

.params-panel-close {
  position: absolute;
  top: 8px;
  right: 12px;
  font-size: 22px;
  color: #888;
  cursor: pointer;
  user-select: none;
}

.params-title {
  font-size: 18px;
  color: #222;
  font-weight: 600;
  margin-bottom: 16px;
  text-align: center;
  padding-right: 20px;
}

.params-content {
  flex: 1;
}

.params-table {
  font-size: 14px;
}

.param-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 12px;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.param-row:last-child {
  border-bottom: none;
}

.param-label {
  color: #666;
  font-weight: 500;
  min-width: 100px;
}

.param-value {
  color: #333;
  text-align: right;
  flex: 1;
  margin-left: 12px;
  font-weight: 500;
  word-break: break-word;
  max-width: 200px;
}

.no-data {
  text-align: center;
  color: #999;
  padding: 40px 0;
}

.no-data p {
  margin: 0;
  font-size: 14px;
}

/* 防洪历史面板样式 */
.flood-history-panel {
  position: fixed;
  top: 50%;
  right: 32px;
  transform: translateY(-50%);
  width: 320px;
  max-height: 400px;
  background: rgba(255,255,255,0.98);
  border-radius: 14px;
  box-shadow: 0 4px 18px rgba(0,0,0,0.13);
  padding: 18px 18px 12px 18px;
  display: flex;
  flex-direction: column;
  z-index: 9999;
  overflow-y: auto;
}

.history-panel-close {
  position: absolute;
  top: 8px;
  right: 12px;
  font-size: 22px;
  color: #888;
  cursor: pointer;
  user-select: none;
}

.history-title {
  font-size: 18px;
  color: #222;
  font-weight: 600;
  margin-bottom: 16px;
  text-align: center;
  padding-right: 20px;
}

.history-content {
  flex: 1;
}

.history-section {
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 1px solid #f0f0f0;
}

.history-section:last-child {
  border-bottom: none;
  margin-bottom: 0;
}

.history-section h4 {
  font-size: 14px;
  color: #1890ff;
  font-weight: 600;
  margin: 0 0 8px 0;
}

.history-section p {
  font-size: 12px;
  color: #666;
  line-height: 1.6;
  margin: 0;
  text-align: justify;
}

/* 图例显示样式 */
.legend-panel {
  position: fixed;
  bottom: 20px;
  right: 20px;
  background: rgba(255,255,255,0.95);
  border-radius: 12px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.15);
  padding: 16px;
  z-index: 1200;
  min-width: 220px;
  max-width: 280px;
  max-height: 400px;
  overflow-y: auto;
  border: 1px solid rgba(0,0,0,0.1);
}

.legend-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 1px solid #e8e8e8;
}

.legend-header h4 {
  margin: 0;
  font-size: 16px;
  color: #333;
  font-weight: 600;
}

.legend-close {
  cursor: pointer;
  font-size: 18px;
  color: #888;
  padding: 4px;
  border-radius: 4px;
  transition: all 0.2s;
}

.legend-close:hover {
  background: rgba(0,0,0,0.1);
  color: #333;
}

.legend-content {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.legend-item {
  display: flex;
  align-items: center;
  padding: 8px;
  background: #f8f9fa;
  border-radius: 6px;
  border: 1px solid #e9ecef;
  transition: all 0.2s;
}

.legend-item:hover {
  background: #e9ecef;
  transform: translateX(2px);
}

.legend-color {
  width: 24px;
  height: 24px;
  border-radius: 4px;
  margin-right: 12px;
  border: 2px solid #fff;
  box-shadow: 0 1px 3px rgba(0,0,0,0.2);
  flex-shrink: 0;
}

.legend-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
  flex: 1;
}

.legend-range {
  font-size: 14px;
  color: #333;
  font-weight: 600;
}

.legend-count {
  font-size: 12px;
  color: #666;
  font-weight: 500;
}

/* 标注控制面板样式 */
.annotation-select {
  width: 100%;
  padding: 8px 12px;
  font-size: 14px;
  border: 1px solid #d0d0d0;
  border-radius: 6px;
  background: #ffffff;
  color: #333;
  cursor: pointer;
  outline: none;
  transition: all 0.2s;
}

.annotation-select:hover {
  border-color: #40a9ff;
}

.annotation-select:focus {
  border-color: #1890ff;
  box-shadow: 0 0 0 2px rgba(24, 144, 255, 0.2);
}

.annotation-select option {
  padding: 8px 12px;
  background: #ffffff;
  color: #333;
}
</style>
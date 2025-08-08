<template>
  <div class="map-editor-container">
    <map-editor-header title="电子地图编辑"></map-editor-header>
    
    <div class="map-editor-content">
      <div id="editor-map" class="editor-map" :class="{ 
        'zoom-in-cursor': activeMapTool === 'zoomIn',
        'zoom-out-cursor': activeMapTool === 'zoomOut',
        'grab-cursor': activeMapTool === 'pan',
        'grabbing-cursor': isPanning,
        'pointer-cursor': activeMapTool === 'selectFeature',
        'info-cursor': activeMapTool === 'identifyFeature'
      }"></div>
      <!-- 图层控制面板 -->
      <div class="control-panel">
        <h3>图层控制</h3>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.districts" @change="toggleLayer('districts')">
            区县边界
          </label>
          <div class="layer-color-control">
            <div class="color-preview" :style="{ backgroundColor: layerColors.districts }" @click="showColorPicker('districts')"></div>
            <input type="color" v-model="layerColors.districts" @change="updateLayerColor('districts')" class="color-input" data-layer="districts" />
          </div>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.waterLines" @change="toggleLayer('waterLines')">
            水系线数据
          </label>
          <div class="layer-color-control">
            <div class="color-preview" :style="{ backgroundColor: layerColors.waterLines }" @click="showColorPicker('waterLines')"></div>
            <input type="color" v-model="layerColors.waterLines" @change="updateLayerColor('waterLines')" class="color-input" data-layer="waterLines" />
          </div>
        </div>
        <div class="layer-control">
          <label>
            <input type="checkbox" v-model="layers.beijingReservoirs" @change="toggleLayer('beijingReservoirs')">
            北京市水库面
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
            居民地地名
          </label>
          <div class="layer-color-control">
            <div class="color-preview point-preview" :style="{ backgroundColor: layerColors.settlements }" @click="showColorPicker('settlements')"></div>
            <input type="color" v-model="layerColors.settlements" @change="updateLayerColor('settlements')" class="color-input" data-layer="settlements" />
          </div>
        </div>
      </div>
      <!-- 水库图片控制面板 -->
      <div v-if="showReservoirImgPanel" class="reservoir-img-panel">
        <span class="img-panel-close" @click="showReservoirImgPanel = false">×</span>
        <img :src="reservoirImgUrl" :alt="reservoirImgName" class="reservoir-img-main" onerror="this.style.display='none'" />
        <div class="reservoir-img-title">{{ reservoirImgName }}</div>
        
        <!-- 水库详细信息 -->
        <div v-if="reservoirDetails[reservoirImgName]" class="reservoir-details">
          <div class="details-title">水库详细信息</div>
          <div class="details-table">
            <div class="detail-row">
              <span class="detail-label">中文名：</span>
              <span class="detail-value">{{ reservoirDetails[reservoirImgName].中文名 }}</span>
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
        <img src="/icons/放大.png" alt="放大" title="放大" @click="activateZoomIn" :class="{ 'active-tool': activeMapTool === 'zoomIn' }" />
        <img src="/icons/缩小.png" alt="缩小" title="缩小" @click="activateZoomOut" :class="{ 'active-tool': activeMapTool === 'zoomOut' }" />
        <img src="/icons/全图.png" alt="全图" title="全图" @click="viewFullExtent" />
        <img src="/icons/手.png" alt="平移" title="平移" @click="activatePan" :class="{ 'active-tool': activeMapTool === 'pan' }" />
        <img src="/icons/选择要素.png" alt="选择要素" title="选择要素" @click="activateSelectFeature" :class="{ 'active-tool': activeMapTool === 'selectFeature' }" />
        <!-- 新增：查询按钮 -->
        <img src="/icons/查询.png" alt="查询" title="查询" @click="activateQuery" :class="{ 'active-tool': activeMapTool === 'query' }" />
        <!-- 新增：渲染按钮 -->
        <img src="/icons/渲染.png" alt="渲染" title="渲染" @click="activateRender" :class="{ 'active-tool': activeMapTool === 'render' }" />
        <img src="/icons/识别要素.png" alt="识别要素" title="识别要素" @click="activateIdentifyFeature" :class="{ 'active-tool': activeMapTool === 'identifyFeature' }" />
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
      <div v-if="activeMapTool === 'query'" class="search-bar-modal">
        <div class="search-bar-container">
          <input
            v-model="searchText"
            @keyup.enter="handleSearch"
            class="search-input"
            placeholder="请输入监测点名称，如：白河堡水库"
            autofocus
          />
          <button class="search-btn" @click="handleSearch">查询</button>
          <span class="search-close" @click="activeMapTool = ''">×</span>
        </div>
        <div v-if="searchError" class="search-error">{{ searchError }}</div>
      </div>
      <!-- 加载提示 -->
      <div class="loading-overlay" v-if="loading">
        <div class="loading-spinner"></div>
        <div class="loading-text">正在加载地理数据...</div>
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
                <img class="folder-icon" src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiIgZmlsbD0iY3VycmVudENvbG9yIiBjbGFzcz0iYmkgYmktZm9sZGVyMi1vcGVuIiB2aWV3Qm94PSIwIDAgMTYgMTYiPgogIDxwYXRoIGQ9Ik0xIDMuNUExLjUgMS41IDAgMCAxIDIuNSAyaDIuNzY0Yy4wNTggMCAuMTE1LjAxNy4xNjcuMDQ4LjA1Mi4wMzEuMS4wNzQuMTM0LjEyNkw2LjcwNyAzLjVIMTMuNWEuNSA1IDAgMCAxIDAgMUg2LjcwN2wtMS4xNDMgMS4zNTJBLjUuNSAwIDAgMSA1LjIzNiA2SDIuNUEuNS41IDAgMCAxIDIgNS41VjR6TTIuNSAzaDIuNzY0Yy4wNTggMCAuMTE1LjAxNy4xNjcuMDQ4LjA1Mi4wMzEuMS4wNzQuMTM0LjEyNkw2LjcwNyA0LjVIMTMuNWEuNS41IDAgMCAxIC41LjV2N2ExLjUgMS41IDAgMCAxLTEuNSAxLjVoLTlBMS41IDEuNSAwIDAgMSAyIDEyVjYuNWguNVYxMmExIDEgMCAwIDAgMSAxaDlhMSAxIDAgMCAwIDEtMVY1aC05LjVhLjUuNSAwIDAgMS0uNDI4LS4yMzJsLTEuMjQxLTEuNTM4QTEuNSAxLjUgMCAwIDAgLjk1IDNIMi41eiIvPgo8L3N2Zz4=" />
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
            <span>水库点分级渲染</span>
            <span class="render-modal-close" @click="activeMapTool = ''">×</span>
          </div>
          <div class="render-modal-body">
            <div class="render-row">
              <label>字段：</label>
              <select v-model="renderField" class="render-select" @change="updateGradeRanges">
                <option v-for="f in monitoringPointFields" :key="f" :value="f">{{ f }}</option>
              </select>
            </div>
            
            <!-- 分级设置 -->
            <div class="grade-settings">
              <h4>分级设置</h4>
              
              <!-- 红色区间 -->
              <div class="grade-row">
                <label class="grade-label">红色区间：</label>
                <input v-model="gradeRanges.red.min" class="grade-input" placeholder="最小值" type="number" />
                <span class="grade-separator">至</span>
                <input v-model="gradeRanges.red.max" class="grade-input" placeholder="最大值" type="number" />
                <input v-model="gradeRanges.red.color" class="grade-color" type="color" />
                <span class="grade-color-label">红色</span>
              </div>
              
              <!-- 黄色区间 -->
              <div class="grade-row">
                <label class="grade-label">黄色区间：</label>
                <input v-model="gradeRanges.yellow.min" class="grade-input" placeholder="最小值" type="number" />
                <span class="grade-separator">至</span>
                <input v-model="gradeRanges.yellow.max" class="grade-input" placeholder="最大值" type="number" />
                <input v-model="gradeRanges.yellow.color" class="grade-color" type="color" />
                <span class="grade-color-label">黄色</span>
              </div>
              
              <!-- 绿色区间 -->
              <div class="grade-row">
                <label class="grade-label">绿色区间：</label>
                <input v-model="gradeRanges.green.min" class="grade-input" placeholder="最小值" type="number" />
                <span class="grade-separator">至</span>
                <input v-model="gradeRanges.green.max" class="grade-input" placeholder="最大值" type="number" />
                <input v-model="gradeRanges.green.color" class="grade-color" type="color" />
                <span class="grade-color-label">绿色</span>
              </div>
              
              <!-- 默认颜色 -->
              <div class="grade-row">
                <label class="grade-label">默认颜色：</label>
                <input v-model="gradeRanges.default.color" class="grade-color" type="color" />
                <span class="grade-color-label">超出范围</span>
              </div>
            </div>
            
            <div class="render-row">
              <button class="render-btn" @click="handleGradeRender">分级渲染</button>
              <button class="render-reset-btn" @click="resetRender">重置</button>
            </div>
            <div v-if="renderError" class="render-error">{{ renderError }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue'
import * as L from 'leaflet'
import MapEditorHeader from '../components/MapEditorHeader.vue'
import 'leaflet/dist/leaflet.css'

const map = ref(null)
const loading = ref(true)

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
  map.value = L.map('editor-map', {
    zoomControl: false,
    attributionControl: false
  }).setView([39.9042, 116.4074], 10)
  
  // 添加地图事件监听器
  map.value.on('moveend', () => {
    const center = map.value.getCenter()
    const zoom = map.value.getZoom()
    addToHistory(center, zoom)
  })
  
  // 初始化历史记录
  addToHistory([39.9042, 116.4074], 10)
  
  // 设置地图事件监听器
  setupMapEventListeners()
  
  // 不加载任何在线底图
}

// 加载GeoJSON数据（Beijing-GeoJson-Tzy目录）
const loadGeoJSONData = async () => {
  const dataFiles = {
    districts: '/Beijing-GeoJson-Tzy/北京区县界.json',
    waterLines: '/Beijing-GeoJson-Tzy/北京市_水系线数据.json',
    beijingReservoirs: '/Beijing-GeoJson-Tzy/北京市水库面.geojson',
    settlements: '/Beijing-GeoJson-Tzy/居民地地名.json',
    monitoringPoints: '/Beijing-GeoJson-Tzy/监测点.geojson'
  }
  for (const [key, filePath] of Object.entries(dataFiles)) {
    try {
      const response = await fetch(filePath)
      const data = await response.json()
      // 优化：区分点和面类型
      let layer
      if (key === 'monitoringPoints') {
        layer = L.geoJSON(data, {
          pointToLayer: (feature, latlng) => L.circleMarker(latlng, getLayerStyle(key)),
          onEachFeature: (feature, lyr) => {
            if (feature.properties) {
              lyr.bindPopup(getPopupContent(key, feature.properties))
            }
          }
        })
      } else if (key === 'beijingReservoirs') {
        layer = L.geoJSON(data, {
          style: getLayerStyle(key),
          onEachFeature: (feature, lyr) => {
            if (feature.properties) {
              lyr.bindPopup(getPopupContent(key, feature.properties))
            }
          }
        })
      } else if (key === 'settlements') {
        layer = L.geoJSON(data, {
          pointToLayer: (feature, latlng) => L.circleMarker(latlng, getLayerStyle(key)),
          onEachFeature: (feature, lyr) => {
            if (feature.properties) {
              lyr.bindPopup(getPopupContent(key, feature.properties))
            }
          }
        })
      } else {
        layer = L.geoJSON(data, {
          style: getLayerStyle(key),
          onEachFeature: (feature, lyr) => {
            if (feature.properties) {
              lyr.bindPopup(getPopupContent(key, feature.properties))
            }
          }
        })
      }
      layerObjects[key] = layer
      if (layers[key]) {
        layer.addTo(map.value)
        if (key === 'beijingReservoirs') {
          layer.bringToFront()
        }
      }
    } catch (error) {
      console.error(`加载${key}数据失败:`, error)
    }
  }
  loading.value = false
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
  for (const [key, value] of Object.entries(properties)) {
    html += `<div><strong>${key}:</strong> ${value !== null && value !== undefined ? value : '未知'}</div>`
  }
  // 删除水库点/面弹窗中的图片显示
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
  }
}

// 地图工具激活方法
const activateZoomIn = () => {
  activeMapTool.value = 'zoomIn'
  // 直接执行放大操作
  if (map.value) {
    map.value.zoomIn()
  }
}

const activateZoomOut = () => {
  activeMapTool.value = 'zoomOut'
  // 直接执行缩小操作
  if (map.value) {
    map.value.zoomOut()
  }
}

const activatePan = () => {
  activeMapTool.value = 'pan'
  // 激活平移模式
  if (map.value) {
    map.value.dragging.enable()
  }
}

// 鼠标样式控制
const isPanning = ref(false)

// 监听地图拖动事件
const setupMapEventListeners = () => {
  if (map.value) {
    map.value.on('dragstart', () => {
      isPanning.value = true
    })
    map.value.on('dragend', () => {
      isPanning.value = false
    })
  }
}

const activateSelectFeature = () => {
  activeMapTool.value = 'selectFeature'
}

const activateIdentifyFeature = () => {
  activeMapTool.value = 'identifyFeature'
}

// 全图视图
const viewFullExtent = () => {
  if (map.value) {
    // 设置到北京市的完整视图
    map.value.setView([39.9042, 116.4074], 10, { animate: true })
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
  activeMapTool.value = 'query'
}
const activateRender = () => {
  activeMapTool.value = 'render'
}

// 新增：activeMapTool变量
const activeMapTool = ref('')

const searchText = ref('')
const searchError = ref('')

// 查询并定位监测点
const handleSearch = () => {
  searchError.value = ''
  if (!searchText.value.trim()) {
    searchError.value = '请输入监测点名称'
    return
  }
  const layer = layerObjects.monitoringPoints
  if (!layer) {
    searchError.value = '监测点图层未加载'
    return
  }
  let found = false
  layer.eachLayer(l => {
    const props = l.feature && l.feature.properties
    if (props && (props.name === searchText.value.trim() || props.NAME === searchText.value.trim())) {
      found = true
      map.value.setView(l.getLatLng(), 14, { animate: true })
      l.openPopup()
      // 高亮效果
      if (l.setStyle) {
        l.setStyle({ color: '#ff0000', fillColor: '#ffcccc', weight: 4 })
        setTimeout(() => layer.resetStyle && layer.resetStyle(l), 2000)
      }
      // 查询到后显示图片面板
      const name = props.name || props.NAME
      if (name) {
        // 确保图片路径正确
        reservoirImgUrl.value = `/reservoir-images/${name}.jpg`
        reservoirImgName.value = name
        showReservoirImgPanel.value = true
        
        // 如果是怀柔水库、密云水库、北台上水库、十三陵水库、官厅水库、崇青水库或斋堂水库，同时显示防洪历史面板
        if (name === '怀柔水库' || name === '密云水库' || name === '北台上水库' || name === '十三陵水库' || name === '官厅水库' || name === '崇青水库' || name === '斋堂水库') {
          showFloodHistoryPanel.value = true
        } else {
          showFloodHistoryPanel.value = false
        }
      } else {
        showReservoirImgPanel.value = false
        showFloodHistoryPanel.value = false
      }
    }
  })
  if (!found) {
    searchError.value = '未找到对应监测点'
    showReservoirImgPanel.value = false
  }
}

const showReservoirImgPanel = ref(false)
const reservoirImgUrl = ref('')
const reservoirImgName = ref('')
const showFloodHistoryPanel = ref(false)

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
        name: '居民地地名',
        type: 'point',
        visible: true
      }
    ]
  },
  {
    id: 'layer-1',
    name: '区县边界',
    type: 'polygon',
    visible: true
  },
  {
    id: 'layer-2',
    name: '水系线数据',
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
    name: '水库面数据',
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
const monitoringPointFields = ref([
  'name','年平均氨氮','年平均高猛酸盐','年平均化学需氧量','年平均流量','年平均水深','年平均总氮','年平均总磷'
])
const renderField = ref('年平均氨氮')
const renderError = ref('')

// 分级渲染设置
const gradeRanges = reactive({
  red: { min: '', max: '', color: '#ff4d4f' },
  yellow: { min: '', max: '', color: '#ffd700' },
  green: { min: '', max: '', color: '#52c41a' },
  default: { color: '#d9d9d9' }
})

// 更新分级区间（根据字段自动设置默认值）
const updateGradeRanges = () => {
  const field = renderField.value
  if (field === '年平均氨氮') {
    gradeRanges.red.min = '10'
    gradeRanges.red.max = '50'
    gradeRanges.yellow.min = '5'
    gradeRanges.yellow.max = '10'
    gradeRanges.green.min = '0'
    gradeRanges.green.max = '5'
  } else if (field === '年平均高猛酸盐') {
    gradeRanges.red.min = '80'
    gradeRanges.red.max = '120'
    gradeRanges.yellow.min = '60'
    gradeRanges.yellow.max = '80'
    gradeRanges.green.min = '40'
    gradeRanges.green.max = '60'
  } else if (field === '年平均化学需氧量') {
    gradeRanges.red.min = '300'
    gradeRanges.red.max = '400'
    gradeRanges.yellow.min = '200'
    gradeRanges.yellow.max = '300'
    gradeRanges.green.min = '100'
    gradeRanges.green.max = '200'
  } else {
    // 其他字段使用通用默认值
    gradeRanges.red.min = '50'
    gradeRanges.red.max = '100'
    gradeRanges.yellow.min = '20'
    gradeRanges.yellow.max = '50'
    gradeRanges.green.min = '0'
    gradeRanges.green.max = '20'
  }
}

// 分级渲染处理
const handleGradeRender = () => {
  renderError.value = ''
  const layer = layerObjects.monitoringPoints
  if (!layer) {
    renderError.value = '监测点图层未加载'
    return
  }
  if (!renderField.value) {
    renderError.value = '请选择字段'
    return
  }
  
  // 验证输入
  const ranges = [gradeRanges.red, gradeRanges.yellow, gradeRanges.green]
  for (let range of ranges) {
    if (range.min === '' || range.max === '') {
      renderError.value = '请填写完整的分级区间'
      return
    }
    const min = parseFloat(range.min)
    const max = parseFloat(range.max)
    if (isNaN(min) || isNaN(max)) {
      renderError.value = '请输入有效的数值'
      return
    }
    if (min >= max) {
      renderError.value = '最小值必须小于最大值'
      return
    }
  }
  
  // 执行分级渲染
  layer.eachLayer(l => {
    const props = l.feature && l.feature.properties
    let val = parseFloat(props[renderField.value])
    let color = gradeRanges.default.color
    
    if (!isNaN(val)) {
      // 检查是否在红色区间
      if (val >= parseFloat(gradeRanges.red.min) && val <= parseFloat(gradeRanges.red.max)) {
        color = gradeRanges.red.color
      }
      // 检查是否在黄色区间
      else if (val >= parseFloat(gradeRanges.yellow.min) && val <= parseFloat(gradeRanges.yellow.max)) {
        color = gradeRanges.yellow.color
      }
      // 检查是否在绿色区间
      else if (val >= parseFloat(gradeRanges.green.min) && val <= parseFloat(gradeRanges.green.max)) {
        color = gradeRanges.green.color
      }
    }
    
    l.setStyle({
      fillColor: color,
      color: color,
      fillOpacity: 0.95,
      opacity: 1,
      weight: 2
    })
  })
}

// 重置渲染
const resetRender = () => {
  const layer = layerObjects.monitoringPoints
  if (layer) {
    layer.resetStyle()
  }
}

onMounted(() => {
  initMap()
  loadGeoJSONData()
  updateGradeRanges() // 初始化分级区间
})
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

/* 放大镜鼠标样式 */
.zoom-in-cursor {
  cursor: zoom-in !important;
}

/* 缩小镜鼠标样式 */
.zoom-out-cursor {
  cursor: zoom-out !important;
}

/* 平移鼠标样式 - 准备抓取 */
.grab-cursor {
  cursor: grab !important;
}

/* 平移鼠标样式 - 抓取中 */
.grabbing-cursor {
  cursor: grabbing !important;
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
  padding: 18px 24px 12px 18px;
  min-width: 320px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}
.search-bar-container {
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
  position: absolute;
<<<<<<< HEAD
  top: 220px;
  right: 32px;
  min-width: 240px;
  max-width: 320px;
=======
  top: 280px;
  left: 80px;
  min-width: 280px;
  max-width: 360px;
>>>>>>> origin/main
  background: rgba(255,255,255,0.98);
  border-radius: 14px;
  box-shadow: 0 4px 18px rgba(0,0,0,0.13);
  padding: 18px 18px 12px 18px;
  display: flex;
  flex-direction: column;
  align-items: center;
  z-index: 1201;
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

/* 分级渲染样式 */
.grade-settings {
  margin: 16px 0;
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #e9ecef;
}

.grade-settings h4 {
  margin: 0 0 12px 0;
  font-size: 16px;
  color: #333;
  font-weight: 600;
}

.grade-row {
  display: flex;
  align-items: center;
  margin-bottom: 12px;
  flex-wrap: wrap;
}

.grade-label {
  min-width: 80px;
  color: #555;
  font-size: 14px;
  margin-right: 8px;
}

.grade-input {
  width: 80px;
  font-size: 14px;
  padding: 4px 8px;
  border-radius: 4px;
  border: 1px solid #d0d0d0;
  margin-right: 8px;
}

.grade-separator {
  color: #666;
  font-size: 14px;
  margin: 0 8px;
}

.grade-color {
  width: 32px;
  height: 32px;
  border: none;
  border-radius: 4px;
  margin-right: 6px;
  box-shadow: 0 1px 4px #eee;
}

.grade-color-label {
  font-size: 12px;
  color: #888;
  margin-right: 12px;
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

/* 防洪历史面板样式 */
.flood-history-panel {
  position: absolute;
  bottom: 32px;
  right: 32px;
  width: 320px;
  max-height: 400px;
  background: rgba(255,255,255,0.98);
  border-radius: 14px;
  box-shadow: 0 4px 18px rgba(0,0,0,0.13);
  padding: 18px 18px 12px 18px;
  display: flex;
  flex-direction: column;
  z-index: 1201;
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
</style> 
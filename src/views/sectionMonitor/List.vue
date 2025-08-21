<template>
  <div class="section-monitor-list">
    <div class="page-header">
      <h2>监测断面管理</h2>
      <div class="header-actions">
        <el-button type="primary" @click="showImportDialog = true">
          <el-icon><Upload /></el-icon>
          数据导入
        </el-button>
        <el-button type="success" @click="showExportDialog = true">
          <el-icon><Download /></el-icon>
          数据导出
        </el-button>
                 <el-button type="primary" @click="handleAdd">
          <el-icon><Plus /></el-icon>
          新增监测断面
        </el-button>
      </div>
    </div>

    <!-- 搜索栏 -->
    <div class="search-bar">
      <el-form :model="searchForm" inline>
        <el-form-item label="监测点名称">
          <el-input v-model="searchForm.monitorPointName" placeholder="请输入监测点名称" clearable @keyup.enter="handleSearch" @clear="handleSearch" />
        </el-form-item>
        <el-form-item label="水库名称">
          <el-input v-model="searchForm.reservoirName" placeholder="请输入水库名称" clearable @keyup.enter="handleSearch" @clear="handleSearch" />
        </el-form-item>
        
        <!-- 动态筛选字段 -->
        <template v-for="field in activeFilterFields" :key="field.value">
          <el-form-item :label="field.label">
            <el-input-number 
              v-model="searchForm[field.value + 'Min']" 
              :placeholder="'最小值'" 
              :min="field.min"
              :max="field.max"
              :step="field.step"
              style="width: 120px;"
              clearable
              @clear="checkAndRemoveField(field.value)"
            />
            <span style="margin: 0 8px;">-</span>
            <el-input-number 
              v-model="searchForm[field.value + 'Max']" 
              :placeholder="'最大值'" 
              :min="field.min"
              :max="field.max"
              :step="field.step"
              style="width: 120px;"
              clearable
              @clear="checkAndRemoveField(field.value)"
            />
            <span style="margin-left: 8px; color: #909399; font-size: 12px;">({{ field.unit }})</span>
            <el-button 
              type="text" 
              size="small" 
              style="margin-left: 8px;"
              @click="removeFilterField(field.value)"
            >
              <el-icon><Close /></el-icon>
            </el-button>
          </el-form-item>
        </template>
        
        <!-- 添加筛选字段下拉框 -->
        <el-form-item label="添加筛选">
          <el-select v-model="selectedField" placeholder="请选择查询字段" @change="handleFieldChange" clearable>
            <el-option 
              v-for="field in availableFilterFields" 
              :key="field.value" 
              :label="field.label" 
              :value="field.value" 
            />
          </el-select>
        </el-form-item>
        
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="resetSearch">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 数据表格 -->
    <div class="table-container">
      <el-table :data="tableData" v-loading="loading" border style="width: 100%">
        <el-table-column prop="monitorPointName" label="监测点名称" />
        <el-table-column prop="reservoirName" label="水库名称" />
        <el-table-column prop="year" label="年份" />
        <el-table-column prop="month" label="月份" />
        <el-table-column prop="oxygen" label="氨氮(mg/L)" />
        <el-table-column prop="potassiumPermanganate" label="高锰酸盐指数(mg/L)" />
        <el-table-column prop="cod" label="化学需氧量(mg/L)" />
        <el-table-column prop="flow" label="流量(m³/s)" />
        <el-table-column prop="waterDepth" label="水深(m)" />
        <el-table-column prop="totalNitrogen" label="总氮(mg/L)" />
        <el-table-column prop="totalPhosphorus" label="总磷(mg/L)" />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="scope">
            <el-button size="small" @click="handleEdit(scope.row)">编辑</el-button>
            <el-button size="small" type="danger" @click="handleDelete(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

         <!-- 分页 -->
     <div class="pagination-container">
       <el-pagination
         v-model:current-page="currentPage"
         v-model:page-size="pageSize"
         :page-sizes="[10, 20, 50, 100]"
         :total="total"
         layout="total, sizes, prev, pager, next, jumper"
         @size-change="handleSizeChange"
         @current-change="handleCurrentChange"
       />
     </div>

     <!-- 新增/编辑对话框 -->
     <el-dialog
       v-model="showAddDialog"
       :title="isEdit ? '编辑监测断面' : '新增监测断面'"
       width="600px"
       :close-on-click-modal="false"
     >
       <el-form
         ref="formRef"
         :model="form"
         :rules="rules"
         label-width="120px"
         style="max-width: 500px;"
       >
         <el-form-item label="监测点名称" prop="monitorPointName">
           <el-input v-model="form.monitorPointName" placeholder="请输入监测点名称" />
         </el-form-item>
         <el-form-item label="水库名称" prop="reservoirName">
           <el-input v-model="form.reservoirName" placeholder="请输入水库名称" />
         </el-form-item>
         <el-form-item label="年份" prop="year">
           <el-input-number v-model="form.year" :min="1900" :max="2100" style="width: 100%;" />
         </el-form-item>
         <el-form-item label="月份" prop="month">
           <el-input-number v-model="form.month" :min="1" :max="12" style="width: 100%;" />
         </el-form-item>
         <el-form-item label="溶解氧(mg/L)" prop="oxygen">
           <el-input-number v-model="form.oxygen" :min="0" :step="0.1" style="width: 100%;" />
         </el-form-item>
         <el-form-item label="高锰酸盐指数(mg/L)" prop="potassiumPermanganate">
           <el-input-number v-model="form.potassiumPermanganate" :min="0" :step="0.1" style="width: 100%;" />
         </el-form-item>
         <el-form-item label="化学需氧量(mg/L)" prop="cod">
           <el-input-number v-model="form.cod" :min="0" :step="0.1" style="width: 100%;" />
         </el-form-item>
         <el-form-item label="流量(m³/s)" prop="flow">
           <el-input-number v-model="form.flow" :min="0" :step="0.1" style="width: 100%;" />
         </el-form-item>
         <el-form-item label="水深(m)" prop="waterDepth">
           <el-input-number v-model="form.waterDepth" :min="0" :step="0.1" style="width: 100%;" />
         </el-form-item>
         <el-form-item label="总氮(mg/L)" prop="totalNitrogen">
           <el-input-number v-model="form.totalNitrogen" :min="0" :step="0.1" style="width: 100%;" />
         </el-form-item>
         <el-form-item label="总磷(mg/L)" prop="totalPhosphorus">
           <el-input-number v-model="form.totalPhosphorus" :min="0" :step="0.1" style="width: 100%;" />
         </el-form-item>
       </el-form>
       <template #footer>
         <span class="dialog-footer">
           <el-button @click="showAddDialog = false">取消</el-button>
           <el-button type="primary" @click="handleSubmit">确定</el-button>
         </span>
       </template>
     </el-dialog>

     <!-- 数据导入对话框 -->
     <el-dialog
       v-model="showImportDialog"
       title="数据导入"
       width="600px"
       :close-on-click-modal="false"
     >
       <div style="text-align: center; padding: 20px;">
         <el-upload
           class="upload-demo"
           drag
           action="#"
           :auto-upload="false"
           :on-change="handleFileChange"
           :show-file-list="false"
           accept=".xlsx,.xls"
         >
           <el-icon class="el-icon--upload"><upload-filled /></el-icon>
           <div class="el-upload__text">
             将文件拖到此处，或<em>点击上传</em>
           </div>
           <template #tip>
             <div class="el-upload__tip">
               只能上传 xlsx/xls 文件，且不超过 10MB
             </div>
           </template>
         </el-upload>
         <div style="margin-top: 20px;">
           <el-button type="primary" @click="downloadTemplate">下载模板</el-button>
         </div>
       </div>
       <template #footer>
         <span class="dialog-footer">
           <el-button @click="showImportDialog = false">取消</el-button>
         </span>
       </template>
     </el-dialog>

     <!-- 数据导出对话框 -->
     <el-dialog
       v-model="showExportDialog"
       title="数据导出"
       width="400px"
       :close-on-click-modal="false"
     >
       <div style="text-align: center; padding: 20px;">
         <el-button type="primary" @click="handleExport">导出Excel</el-button>
       </div>
       <template #footer>
         <span class="dialog-footer">
           <el-button @click="showExportDialog = false">取消</el-button>
         </span>
       </template>
     </el-dialog>
   </div>
 </template>

<script setup>
import { ref, reactive, onMounted, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Upload, Download, Plus, UploadFilled, Close } from '@element-plus/icons-vue'
import axios from 'axios'

// 响应式数据
const loading = ref(false)
const tableData = ref([])
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)
const showAddDialog = ref(false)
const showImportDialog = ref(false)
const showExportDialog = ref(false)
const selectedField = ref('')
const formRef = ref(null)
const isEdit = ref(false)

// 表单数据
const form = reactive({
  id: null,
  monitorPointName: '',
  reservoirName: '',
  year: new Date().getFullYear(),
  month: new Date().getMonth() + 1,
  oxygen: null,
  potassiumPermanganate: null,
  cod: null,
  flow: null,
  waterDepth: null,
  totalNitrogen: null,
  totalPhosphorus: null
})

// 表单验证规则
const rules = {
  monitorPointName: [
    { required: true, message: '请输入监测点名称', trigger: 'blur' }
  ],
  reservoirName: [
    { required: true, message: '请输入水库名称', trigger: 'blur' }
  ],
  year: [
    { required: true, message: '请输入年份', trigger: 'blur' }
  ],
  month: [
    { required: true, message: '请输入月份', trigger: 'blur' }
  ]
}

// 搜索表单
const searchForm = reactive({
  monitorPointName: '',
  reservoirName: '',
  yearMin: null,
  yearMax: null,
  monthMin: null,
  monthMax: null,
  oxygenMin: null,
  oxygenMax: null,
  potassiumPermanganateMin: null,
  potassiumPermanganateMax: null,
  codMin: null,
  codMax: null,
  flowMin: null,
  flowMax: null,
  waterDepthMin: null,
  waterDepthMax: null,
  totalNitrogenMin: null,
  totalNitrogenMax: null,
  totalPhosphorusMin: null,
  totalPhosphorusMax: null
})

// 可用的筛选字段
const availableFilterFields = reactive([
  { label: '年份', value: 'year', min: 1900, max: 2100, step: 1, unit: '年' },
  { label: '月份', value: 'month', min: 1, max: 12, step: 1, unit: '月' },
  { label: '溶解氧', value: 'oxygen', min: 0, max: 100, step: 0.1, unit: 'mg/l' },
  { label: '高锰酸盐', value: 'potassiumPermanganate', min: 0, max: 100, step: 0.1, unit: 'mg/l' },
  { label: '化学需氧量', value: 'cod', min: 0, max: 100, step: 0.1, unit: 'mg/l' },
  { label: '流量', value: 'flow', min: 0, max: 1000, step: 0.1, unit: 'm³/s' },
  { label: '水深', value: 'waterDepth', min: 0, max: 10, step: 0.1, unit: 'm' },
  { label: '总氮', value: 'totalNitrogen', min: 0, max: 100, step: 0.1, unit: 'mg/l' },
  { label: '总磷', value: 'totalPhosphorus', min: 0, max: 10, step: 0.1, unit: 'mg/l' }
])

// 当前激活的筛选字段
const activeFilterFields = ref([])

// 方法
const fetchList = async () => {
  loading.value = true
  try {
    const params = {
      page: currentPage.value,
      pageSize: pageSize.value,
      monitorPointName: searchForm.monitorPointName,
      reservoirName: searchForm.reservoirName,
      ...searchForm // 将所有搜索参数传递给后端
    }
    const response = await axios.get('http://localhost:8080/api/sectionMonitor/list', { params })
    tableData.value = response.data.list
    total.value = response.data.total
  } catch (error) {
    console.error('获取数据失败:', error)
    if (error.response) {
      ElMessage.error(`获取数据失败: ${error.response.status} - ${JSON.stringify(error.response.data)}`)
    } else if (error.request) {
      ElMessage.error('网络连接失败，请检查后端服务是否启动')
    } else {
      ElMessage.error('获取数据失败: ' + error.message)
    }
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  currentPage.value = 1
  fetchList()
}

const resetSearch = () => {
  Object.keys(searchForm).forEach(key => {
    searchForm[key] = key === 'monitorPointName' || key === 'reservoirName' ? '' : null
  })
  activeFilterFields.value = [] // 重置激活的筛选字段
  selectedField.value = ''
  currentPage.value = 1
  fetchList()
}

const handleFieldChange = (value) => {
  if (value && !activeFilterFields.value.some(field => field.value === value)) {
    const newField = availableFilterFields.find(field => field.value === value)
    if (newField) {
      activeFilterFields.value.push(newField)
      selectedField.value = '' // 清空下拉框
    }
  }
}

const handleSizeChange = (val) => {
  pageSize.value = val
  fetchList()
}

const handleCurrentChange = (val) => {
  currentPage.value = val
  fetchList()
}

const handleAdd = () => {
  resetForm()
  showAddDialog.value = true
}

const handleEdit = (row) => {
  isEdit.value = true
  Object.assign(form, row)
  showAddDialog.value = true
}

const handleSubmit = async () => {
  try {
    await formRef.value.validate()
    
    // 检查监测点名称是否重复
    if (!isEdit.value) {
      const checkResponse = await axios.get('http://localhost:8080/api/sectionMonitor/checkMonitorPointName', {
        params: {
          monitorPointName: form.monitorPointName,
          reservoirName: form.reservoirName
        }
      })
      if (checkResponse.data) {
        ElMessage.error('该监测点名称已存在')
        return
      }
    }
    
    if (isEdit.value) {
      await axios.post('http://localhost:8080/api/sectionMonitor/update', form)
      ElMessage.success('更新成功')
    } else {
      await axios.post('http://localhost:8080/api/sectionMonitor/create', form)
      ElMessage.success('添加成功')
    }
    
    showAddDialog.value = false
    resetForm()
    fetchList()
  } catch (error) {
    console.error('提交失败:', error)
    if (error.response) {
      ElMessage.error(`提交失败: ${error.response.data.message || '未知错误'}`)
    } else {
      ElMessage.error('提交失败: ' + error.message)
    }
  }
}

const resetForm = () => {
  form.id = null
  form.monitorPointName = ''
  form.reservoirName = ''
  form.year = new Date().getFullYear()
  form.month = new Date().getMonth() + 1
  form.oxygen = null
  form.potassiumPermanganate = null
  form.cod = null
  form.flow = null
  form.waterDepth = null
  form.totalNitrogen = null
  form.totalPhosphorus = null
  isEdit.value = false
  formRef.value?.clearValidate()
}

const handleFileChange = async (file) => {
  try {
    const formData = new FormData()
    formData.append('file', file.raw)
    
    const response = await axios.post('http://localhost:8080/api/sectionMonitor/batchImport', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
    
    if (response.data.success) {
      const result = response.data
      const importedCount = result.importedData ? result.importedData.length : 0
      const skippedCount = result.skippedReservoirs ? result.skippedReservoirs.length : 0
      
      if (skippedCount > 0) {
        // 有跳过的情况，显示详细信息
        ElMessage({
          message: `导入完成！成功导入 ${importedCount} 条数据，跳过 ${skippedCount} 条重复数据。${result.message}`,
          type: 'warning',
          duration: 6000
        })
      } else {
        // 全部成功导入
        ElMessage.success(`导入成功！共导入 ${importedCount} 条数据`)
      }
      
      showImportDialog.value = false
      fetchList()
    } else {
      ElMessage.warning(response.data.message || '部分数据导入成功')
    }
  } catch (error) {
    console.error('导入失败:', error)
    ElMessage.error('导入失败: ' + (error.response?.data?.message || error.message))
  }
}

const downloadTemplate = async () => {
  try {
    const response = await axios.get('http://localhost:8080/api/sectionMonitor/template', {
      responseType: 'blob'
    })
    
    const blob = new Blob([response.data], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = '监测断面数据模板.xlsx'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    
    ElMessage.success('模板下载成功')
  } catch (error) {
    console.error('下载失败:', error)
    ElMessage.error('模板下载失败')
  }
}

const handleExport = async () => {
  try {
    const response = await axios.post('http://localhost:8080/api/sectionMonitor/export', {
      monitorPointName: searchForm.monitorPointName,
      reservoirName: searchForm.reservoirName,
      ...searchForm // 将所有搜索参数传递给后端
    }, {
      responseType: 'blob'
    })
    
    const blob = new Blob([response.data], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = '监测断面数据.xlsx'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    
    ElMessage.success('导出成功')
    showExportDialog.value = false
  } catch (error) {
    console.error('导出失败:', error)
    ElMessage.error('导出失败: ' + (error.response?.data?.message || error.message))
  }
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm('确定要删除这条记录吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    await axios.delete(`http://localhost:8080/api/sectionMonitor/delete/${row.id}`)
    ElMessage.success('删除成功')
    fetchList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 添加新的筛选字段
const addFilterField = () => {
  if (selectedField.value && !activeFilterFields.value.some(f => f.value === selectedField.value)) {
    const field = availableFilterFields.find(f => f.value === selectedField.value)
    if (field) {
      activeFilterFields.value.push({
        label: field.label,
        value: field.value,
        min: field.min,
        max: field.max,
        step: field.step,
        unit: field.unit
      })
      selectedField.value = '' // 清空下拉框
    }
  }
}

// 移除筛选字段
const removeFilterField = (fieldValue) => {
  activeFilterFields.value = activeFilterFields.value.filter(f => f.value !== fieldValue)
  // Clear the values in searchForm when the field is removed
  searchForm[fieldValue + 'Min'] = null
  searchForm[fieldValue + 'Max'] = null
}

// 检查并移除字段
const checkAndRemoveField = (fieldValue) => {
  if (searchForm[fieldValue + 'Min'] === null && searchForm[fieldValue + 'Max'] === null) {
    removeFilterField(fieldValue)
  }
}

// 生命周期
onMounted(() => {
  fetchList()
})

// 监听搜索表单变化，自动移除无值的筛选字段
watch(searchForm, (newVal) => {
  activeFilterFields.value.forEach(field => {
    const minValue = newVal[field.value + 'Min']
    const maxValue = newVal[field.value + 'Max']
    if (minValue === null && maxValue === null) {
      removeFilterField(field.value)
    }
  })
}, { deep: true })
</script>

<style scoped>
.section-monitor-list {
  padding: 20px;
  background: #f5f5f5;
  min-height: 100vh;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.page-header h2 {
  margin: 0;
  color: #333;
  font-size: 24px;
}

.header-actions {
  display: flex;
  gap: 10px;
}

.search-bar {
  background: white;
  padding: 20px;
  border-radius: 8px;
  margin-bottom: 20px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.search-bar .el-form-item {
  margin-bottom: 15px;
}

.search-bar .el-form-item__label {
  font-weight: 500;
  color: #333;
}

.table-container {
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  margin-bottom: 20px;
}

.pagination-container {
  display: flex;
  justify-content: center;
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

/* 表格容器 */
.table-container {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  overflow: hidden;
}

/* 表格标头美化 */
:deep(.el-table) {
  border-radius: 8px;
  overflow: hidden;
  width: 100% !important;
}

:deep(.el-table__header) {
  background: #f5f7fa;
}

:deep(.el-table__header th) {
  background: #f5f7fa !important;
  color: #606266 !important;
  font-weight: 700 !important;
  font-size: 13px !important;
  padding: 12px 8px !important;
  border-bottom: 1px solid #ebeef5 !important;
  text-align: center !important;
  white-space: nowrap !important;
  overflow: visible !important;
  text-overflow: clip !important;
  min-width: 80px !important;
  max-width: none !important;
  width: auto !important;
  box-sizing: border-box !important;
}

:deep(.el-table__header th:hover) {
  background: #e4e7ed !important;
}

:deep(.el-table__body td) {
  padding: 10px 8px !important;
  text-align: center !important;
  border-bottom: 1px solid #ebeef5 !important;
  white-space: nowrap !important;
  overflow: visible !important;
  text-overflow: clip !important;
  width: auto !important;
  box-sizing: border-box !important;
}

:deep(.el-table__body tr:hover > td) {
  background-color: #f5f7fa !important;
}

:deep(.el-table__body tr:nth-child(even)) {
  background-color: #fafafa;
}

/* 操作列样式 */
:deep(.el-table__body td:last-child) {
  text-align: center !important;
}

:deep(.el-table__body td:last-child .el-button) {
  margin: 0 4px;
  padding: 6px 12px;
  font-size: 12px;
}

/* 强制表格列自适应 */
:deep(.el-table__body-wrapper) {
  overflow-x: auto !important;
}

:deep(.el-table__header-wrapper) {
  overflow: visible !important;
}

/* 确保列内容不被截断 */
:deep(.el-table .cell) {
  white-space: nowrap !important;
  overflow: visible !important;
  text-overflow: clip !important;
}

/* 启用列宽调整的视觉提示 */
/* 移除自定义光标，使用 Element Plus 默认的列边缘光标 */
</style> 

<template>
  <div class="water-situation-list">
    <div class="page-header">
      <h2>水情管理</h2>
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
          新增水情
        </el-button>
      </div>
    </div>

    <!-- 搜索栏 -->
    <div class="search-bar">
      <el-form :model="searchForm" inline>
        <el-form-item label="库名">
          <el-input v-model="searchForm.reservoirName" placeholder="请输入库名" clearable @keyup.enter="handleSearch" @clear="handleSearch" />
        </el-form-item>
        <el-form-item label="日期">
          <el-date-picker
            v-model="searchForm.date"
            type="date"
            placeholder="选择日期"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
            clearable
            @change="handleSearch"
          />
        </el-form-item>
        
        <!-- 动态筛选字段 -->
        <template v-for="field in activeFilterFields" :key="field.value">
          <el-form-item :label="field.label">
            <el-input-number 
              v-model="searchForm[field.value + 'Min']" 
              :placeholder="'最小值'" 
              :min="0" 
              :step="field.step"
              style="width: 120px;"
              clearable
              @clear="checkAndRemoveField(field.value)"
            />
            <span style="margin: 0 8px;">-</span>
            <el-input-number 
              v-model="searchForm[field.value + 'Max']" 
              :placeholder="'最大值'" 
              :min="0" 
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
        <el-table-column prop="reservoirName" label="库名" />
        <el-table-column prop="date" label="日期" />
        <el-table-column prop="waterLevel" label="库水位(米)" />
        <el-table-column prop="storage" label="蓄水量(万立方米)" />
        <el-table-column prop="avgInflow" label="日平均入库流量(立方米/秒)" />
        <el-table-column prop="avgOutflow" label="日平均出库流量(立方米/秒)" />
        <el-table-column prop="yoyIncrease" label="比去年同期增减(万立方米)" />
        <el-table-column prop="totalCapacity" label="总库容(万立方米)" />
        <el-table-column prop="floodLevel" label="汛限水位(米)" />
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
      :title="isEdit ? '编辑水情' : '新增水情'"
      width="700px"
      :close-on-click-modal="false"
    >
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="140px"
      >
        <el-form-item label="库名" prop="reservoirName">
          <el-input v-model="form.reservoirName" placeholder="请输入库名" />
        </el-form-item>
        <el-form-item label="日期" prop="date">
          <el-date-picker
            v-model="form.date"
            type="datetime"
            placeholder="选择日期时间"
            format="YYYY-MM-DD HH:mm:ss"
            value-format="YYYY-MM-DD HH:mm:ss"
            style="width: 100%;"
          />
        </el-form-item>
        <el-form-item label="库水位(米)" prop="waterLevel">
          <el-input-number v-model="form.waterLevel" :min="0" :step="0.1" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="蓄水量(万立方米)" prop="storage">
          <el-input-number v-model="form.storage" :min="0" :step="1000" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="日平均入库流量(立方米/秒)" prop="avgInflow">
          <el-input-number v-model="form.avgInflow" :min="0" :step="0.1" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="日平均出库流量(立方米/秒)" prop="avgOutflow">
          <el-input-number v-model="form.avgOutflow" :min="0" :step="0.1" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="比去年同期增减(万立方米)" prop="yoyIncrease">
          <el-input-number v-model="form.yoyIncrease" :step="1000" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="总库容(万立方米)" prop="totalCapacity">
          <el-input-number v-model="form.totalCapacity" :min="0" :step="1000" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="汛限水位(米)" prop="floodLevel">
          <el-input-number v-model="form.floodLevel" :min="0" :step="0.1" style="width: 100%;" />
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
  reservoirName: '',
  date: '',
  waterLevel: null,
  storage: null,
  avgInflow: null,
  avgOutflow: null,
  yoyIncrease: null,
  totalCapacity: null,
  floodLevel: null
})

// 表单验证规则
const rules = {
  reservoirName: [
    { required: true, message: '请输入库名', trigger: 'blur' }
  ],
  date: [
    { required: true, message: '请选择日期', trigger: 'blur' }
  ]
}

// 搜索表单
const searchForm = reactive({
  reservoirName: '',
  date: '',
  waterLevelMin: null,
  waterLevelMax: null,
  storageMin: null,
  storageMax: null,
  avgInflowMin: null,
  avgInflowMax: null,
  avgOutflowMin: null,
  avgOutflowMax: null,
  yoyIncreaseMin: null,
  yoyIncreaseMax: null,
  totalCapacityMin: null,
  totalCapacityMax: null,
  floodLevelMin: null,
  floodLevelMax: null
})

// 可用的筛选字段
const availableFilterFields = ref([
  { label: '库水位', value: 'waterLevel', min: null, max: null, step: 0.1, unit: '米' },
  { label: '蓄水量', value: 'storage', min: null, max: null, step: 1000, unit: '万立方米' },
  { label: '日平均入库流量', value: 'avgInflow', min: null, max: null, step: 0.1, unit: '立方米/秒' },
  { label: '日平均出库流量', value: 'avgOutflow', min: null, max: null, step: 0.1, unit: '立方米/秒' },
  { label: '比去年同期增减', value: 'yoyIncrease', min: null, max: null, step: 1000, unit: '万立方米' },
  { label: '总库容', value: 'totalCapacity', min: null, max: null, step: 1000, unit: '万立方米' },
  { label: '汛限水位', value: 'floodLevel', min: null, max: null, step: 0.1, unit: '米' }
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
      reservoirName: searchForm.reservoirName,
      date: searchForm.date,
      ...Object.fromEntries(activeFilterFields.value.map(field => [field.value + 'Min', searchForm[field.value + 'Min']])),
      ...Object.fromEntries(activeFilterFields.value.map(field => [field.value + 'Max', searchForm[field.value + 'Max']]))
    }
            const response = await axios.get('/api/waterSituation/list', { params })
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
    searchForm[key] = key === 'date' ? '' : null
  })
  activeFilterFields.value = []
  selectedField.value = ''
  currentPage.value = 1
  fetchList()
}

const handleFieldChange = (value) => {
  if (value && !activeFilterFields.value.some(field => field.value === value)) {
    const newField = availableFilterFields.value.find(field => field.value === value)
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
  // 确保编辑时的日期格式正确
  if (form.date) {
    form.date = setDefaultTime(form.date)
  }
  showAddDialog.value = true
}

const handleSubmit = async () => {
  try {
    await formRef.value.validate()
    
    // 确保日期有时间组件
    if (form.date) {
      form.date = setDefaultTime(form.date)
    }
    
    // 检查库名是否重复
    if (!isEdit.value) {
              const checkResponse = await axios.get('/api/waterSituation/checkReservoirName', {
        params: {
          reservoirName: form.reservoirName
        }
      })
      if (checkResponse.data) {
        ElMessage.error('该库名已存在')
        return
      }
    }
    
    if (isEdit.value) {
              await axios.post('/api/waterSituation/update', form)
      ElMessage.success('更新成功')
    } else {
              await axios.post('/api/waterSituation/create', form)
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
  form.reservoirName = ''
  form.date = ''
  form.waterLevel = null
  form.storage = null
  form.avgInflow = null
  form.avgOutflow = null
  form.yoyIncrease = null
  form.totalCapacity = null
  form.floodLevel = null
  isEdit.value = false
  formRef.value?.clearValidate()
}

// 设置默认时间
const setDefaultTime = (date) => {
  if (date && !date.includes(':')) {
    return date + ' 00:00:00'
  }
  return date
}

const handleFileChange = async (file) => {
  try {
    const formData = new FormData()
    formData.append('file', file.raw)
    
            const response = await axios.post('/api/waterSituation/batchImport', formData, {
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
            const response = await axios.get('/api/waterSituation/template/download', {
      responseType: 'blob'
    })
    
    const blob = new Blob([response.data], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = '水情数据模板.xlsx'
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
    const params = {
      reservoirName: searchForm.reservoirName,
      date: searchForm.date,
      ...Object.fromEntries(activeFilterFields.value.map(field => [field.value + 'Min', searchForm[field.value + 'Min']])),
      ...Object.fromEntries(activeFilterFields.value.map(field => [field.value + 'Max', searchForm[field.value + 'Max']]))
    }
    
            const response = await axios.get('/api/waterSituation/export', {
      params,
      responseType: 'blob'
    })
    
    const blob = new Blob([response.data], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = '水情数据.xlsx'
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
    
            await axios.delete(`/api/waterSituation/delete/${row.id}`)
    ElMessage.success('删除成功')
    fetchList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 动态筛选字段相关方法
const addFilterField = () => {
  if (selectedField.value && !activeFilterFields.value.some(field => field.value === selectedField.value)) {
    const newField = availableFilterFields.value.find(field => field.value === selectedField.value)
    if (newField) {
      activeFilterFields.value.push(newField)
      selectedField.value = '' // 清空下拉框
    }
  }
}

const removeFilterField = (fieldValue) => {
  activeFilterFields.value = activeFilterFields.value.filter(field => field.value !== fieldValue)
  // Clear the values in searchForm when the field is removed
  searchForm[fieldValue + 'Min'] = null
  searchForm[fieldValue + 'Max'] = null
}

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
.water-situation-list {
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

/* 表单样式优化 */
:deep(.el-form-item__label) {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  min-width: 120px;
}

:deep(.el-dialog) {
  max-width: 90vw;
}

:deep(.el-form) {
  max-width: 100%;
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
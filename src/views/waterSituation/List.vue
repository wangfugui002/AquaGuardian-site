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
        <el-form-item label="查询字段">
          <el-select v-model="selectedField" placeholder="请选择查询字段" @change="handleFieldChange" clearable>
            <el-option label="库水位" value="waterLevel" />
            <el-option label="蓄水量" value="storage" />
            <el-option label="日平均入库流量" value="avgInflow" />
            <el-option label="日平均出库流量" value="avgOutflow" />
            <el-option label="比去年同期增减" value="yoyIncrease" />
            <el-option label="总库容" value="totalCapacity" />
            <el-option label="汛限水位" value="floodLevel" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="selectedField" :label="getFieldLabel(selectedField)">
          <el-input-number 
            v-model="searchForm[selectedField + 'Min']" 
            :placeholder="'最小值'" 
            :min="0" 
            :step="getFieldStep(selectedField)"
            style="width: 120px;"
            clearable
          />
          <span style="margin: 0 8px;">-</span>
          <el-input-number 
            v-model="searchForm[selectedField + 'Max']" 
            :placeholder="'最大值'" 
            :min="0" 
            :step="getFieldStep(selectedField)"
            style="width: 120px;"
            clearable
          />
          <span style="margin-left: 8px; color: #909399; font-size: 12px;">({{ getFieldUnit(selectedField) }})</span>
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
        <el-table-column prop="reservoirName" label="库名" width="120" />
        <el-table-column prop="date" label="日期" width="120" />
        <el-table-column prop="waterLevel" label="库水位(米)" width="120" />
        <el-table-column prop="storage" label="蓄水量(万立方米)" width="140" />
        <el-table-column prop="avgInflow" label="日平均入库流量(立方米/秒)" width="180" />
        <el-table-column prop="avgOutflow" label="日平均出库流量(立方米/秒)" width="180" />
        <el-table-column prop="yoyIncrease" label="比去年同期增减(万立方米)" width="180" />
        <el-table-column prop="totalCapacity" label="总库容(万立方米)" width="140" />
        <el-table-column prop="floodLevel" label="汛限水位(米)" width="120" />
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
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Upload, Download, Plus, UploadFilled } from '@element-plus/icons-vue'
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

// 方法
const fetchList = async () => {
  loading.value = true
  try {
    const params = {
      page: currentPage.value,
      pageSize: pageSize.value,
      reservoirName: searchForm.reservoirName,
      date: searchForm.date,
      waterLevelMin: searchForm.waterLevelMin,
      waterLevelMax: searchForm.waterLevelMax,
      storageMin: searchForm.storageMin,
      storageMax: searchForm.storageMax,
      avgInflowMin: searchForm.avgInflowMin,
      avgInflowMax: searchForm.avgInflowMax,
      avgOutflowMin: searchForm.avgOutflowMin,
      avgOutflowMax: searchForm.avgOutflowMax,
      yoyIncreaseMin: searchForm.yoyIncreaseMin,
      yoyIncreaseMax: searchForm.yoyIncreaseMax,
      totalCapacityMin: searchForm.totalCapacityMin,
      totalCapacityMax: searchForm.totalCapacityMax,
      floodLevelMin: searchForm.floodLevelMin,
      floodLevelMax: searchForm.floodLevelMax
    }
    const response = await axios.get('http://localhost:8080/api/waterSituation/list', { params })
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
  selectedField.value = ''
  currentPage.value = 1
  fetchList()
}

const handleFieldChange = (value) => {
  selectedField.value = value
}

const getFieldLabel = (field) => {
  switch (field) {
    case 'waterLevel':
      return '库水位(米)'
    case 'storage':
      return '蓄水量(万立方米)'
    case 'avgInflow':
      return '日平均入库流量(立方米/秒)'
    case 'avgOutflow':
      return '日平均出库流量(立方米/秒)'
    case 'yoyIncrease':
      return '比去年同期增减(万立方米)'
    case 'totalCapacity':
      return '总库容(万立方米)'
    case 'floodLevel':
      return '汛限水位(米)'
    default:
      return ''
  }
}

const getFieldStep = (field) => {
  switch (field) {
    case 'waterLevel':
      return 0.1
    case 'storage':
      return 1000
    case 'avgInflow':
      return 0.1
    case 'avgOutflow':
      return 0.1
    case 'yoyIncrease':
      return 1000
    case 'totalCapacity':
      return 1000
    case 'floodLevel':
      return 0.1
    default:
      return 1
  }
}

const getFieldUnit = (field) => {
  switch (field) {
    case 'waterLevel':
      return '米'
    case 'storage':
      return '万立方米'
    case 'avgInflow':
      return '立方米/秒'
    case 'avgOutflow':
      return '立方米/秒'
    case 'yoyIncrease':
      return '万立方米'
    case 'totalCapacity':
      return '万立方米'
    case 'floodLevel':
      return '米'
    default:
      return ''
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
      const checkResponse = await axios.get('http://localhost:8080/api/waterSituation/checkReservoirName', {
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
      await axios.post('http://localhost:8080/api/waterSituation/update', form)
      ElMessage.success('更新成功')
    } else {
      await axios.post('http://localhost:8080/api/waterSituation/create', form)
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
    
    const response = await axios.post('http://localhost:8080/api/waterSituation/batchImport', formData, {
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
    const response = await axios.get('http://localhost:8080/api/waterSituation/template/download', {
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
      waterLevelMin: searchForm.waterLevelMin,
      waterLevelMax: searchForm.waterLevelMax,
      storageMin: searchForm.storageMin,
      storageMax: searchForm.storageMax,
      avgInflowMin: searchForm.avgInflowMin,
      avgInflowMax: searchForm.avgInflowMax,
      avgOutflowMin: searchForm.avgOutflowMin,
      avgOutflowMax: searchForm.avgOutflowMax,
      yoyIncreaseMin: searchForm.yoyIncreaseMin,
      yoyIncreaseMax: searchForm.yoyIncreaseMax,
      totalCapacityMin: searchForm.totalCapacityMin,
      totalCapacityMax: searchForm.totalCapacityMax,
      floodLevelMin: searchForm.floodLevelMin,
      floodLevelMax: searchForm.floodLevelMax
    }
    
    const response = await axios.get('http://localhost:8080/api/waterSituation/export', {
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
    
    await axios.delete(`http://localhost:8080/api/waterSituation/delete/${row.id}`)
    ElMessage.success('删除成功')
    fetchList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 生命周期
onMounted(() => {
  fetchList()
})
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
</style> 
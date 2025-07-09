<template>
  <div class="data-management-container">
    <data-management-header title="数据管理"></data-management-header>
    <div class="data-management-main">
      <div class="data-management-sidebar">
        <div class="sidebar-box" :class="{active: activeBox==='attr'}" @click="activeBox='attr'">属性数据</div>
        <div class="sidebar-box" :class="{active: activeBox==='import'}" @click="activeBox='import'">数据导入</div>
        <div class="sidebar-box" :class="{active: activeBox==='export'}" @click="activeBox='export'">数据导出</div>
      </div>
      <div class="data-management-content">
        <div v-if="activeBox==='attr'" class="attr-panel">
          <h2 class="attr-title">水库数据管理</h2>
          <div class="attr-toolbar">
            <label>水库名称</label>
            <input class="attr-input" placeholder="请输入水库名称" />
            <label>所在地区</label>
            <input class="attr-input" placeholder="请输入所在地区" />
            <button class="attr-btn attr-btn-primary">查询</button>
            <button class="attr-btn">重置</button>
            <button class="attr-btn attr-btn-add" @click="showAddDialog=true">新增水库</button>
          </div>
          <div class="attr-table-wrap">
            <table class="attr-table">
              <thead>
                <tr>
                  <th>水库名称</th>
                  <th>所在地区</th>
                  <th>库容(万立方米)</th>
                  <th>水位(米)</th>
                  <th>水库类型</th>
                  <th>用途</th>
                  <th>负责人</th>
                  <th>状态</th>
                  <th>操作</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td colspan="9" style="text-align:center;color:#bbb;">No Data</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="attr-pagination">
            <span>Total 0</span>
            <select class="attr-page-select"><option>10/page</option></select>
            <button class="attr-page-btn" disabled>&lt;</button>
            <span class="attr-page-num">1</span>
            <button class="attr-page-btn" disabled>&gt;</button>
          </div>
        </div>
        <div v-else-if="activeBox==='import'" class="import-panel">
          <h2 class="import-title">数据导入</h2>
          <div class="import-card">
            <div class="import-upload-area">
              <div class="import-upload-box">
                <div class="import-upload-icon">
                  <svg width="64" height="64" viewBox="0 0 64 64"><path d="M32 12v28M32 12l-8 8M32 12l8 8" stroke="#b0b7c3" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/><rect x="12" y="44" width="40" height="8" rx="4" fill="#b0b7c3" opacity=".2"/></svg>
                </div>
                <div class="import-upload-text">将文件拖拽到此处，或<span class="import-upload-link">点击上传</span></div>
              </div>
              <div class="import-upload-tip">支持 .xlsx、.xls、.csv 格式文件，文件大小不超过 10MB</div>
            </div>
            <div class="import-template-area">
              <div class="import-template-title">模板下载</div>
              <div class="import-template-desc">请下载并使用标准模板文件进行数据填写：</div>
              <button class="import-template-btn">↓ 下载导入模板</button>
            </div>
          </div>
        </div>
        <div v-else-if="activeBox==='export'" class="export-panel">
          <h2 class="export-title">数据导出</h2>
          <div class="export-card">
            <div class="export-row">
              <label class="export-label">导出内容</label>
              <div class="export-checkbox-group">
                <label class="export-checkbox"><input type="checkbox" v-model="exportContent.base" /> 基本信息</label>
                <label class="export-checkbox"><input type="checkbox" v-model="exportContent.water" /> 水质数据</label>
                <label class="export-checkbox"><input type="checkbox" v-model="exportContent.risk" /> 风险评估</label>
              </div>
            </div>
            <div class="export-row">
              <label class="export-label">时间范围</label>
              <input class="export-input" type="date" placeholder="开始日期" style="width:140px;" />
              <span style="margin:0 8px;">至</span>
              <input class="export-input" type="date" placeholder="结束日期" style="width:140px;" />
            </div>
            <div class="export-row">
              <label class="export-label">水库选择</label>
              <select class="export-input" style="width:220px;"><option>请选择水库</option></select>
            </div>
            <div class="export-row">
              <label class="export-label">文件格式</label>
              <label class="export-radio"><input type="radio" name="format" checked /> Excel (xlsx)</label>
              <label class="export-radio"><input type="radio" name="format" /> CSV</label>
            </div>
            <div class="export-actions">
              <button class="export-btn">↓ 开始导出</button>
            </div>
          </div>
        </div>
        <div v-else class="empty-panel"></div>
        <!-- 新增水库弹窗 -->
        <div v-if="showAddDialog" class="dialog-mask">
          <div class="dialog-box">
            <div class="dialog-header">
              <span class="dialog-title">新增水库</span>
              <span class="dialog-close" @click="showAddDialog=false">×</span>
            </div>
            <form class="dialog-form">
              <div class="dialog-row">
                <label class="dialog-label required">水库名称</label>
                <input class="dialog-input" placeholder="请输入水库名称" />
              </div>
              <div class="dialog-row">
                <label class="dialog-label">所在地区</label>
                <input class="dialog-input" placeholder="请输入所在地区" />
              </div>
              <div class="dialog-row">
                <label class="dialog-label required">库容</label>
                <div class="dialog-group">
                  <button type="button" class="dialog-btn">-</button>
                  <input class="dialog-input short" placeholder="请输入库容" />
                  <button type="button" class="dialog-btn">+</button>
                  <span class="dialog-unit">万立方米</span>
                </div>
              </div>
              <div class="dialog-row">
                <label class="dialog-label">水位</label>
                <div class="dialog-group">
                  <button type="button" class="dialog-btn">-</button>
                  <input class="dialog-input short" placeholder="请输入水位" />
                  <button type="button" class="dialog-btn">+</button>
                  <span class="dialog-unit">米</span>
                </div>
              </div>
              <div class="dialog-row">
                <label class="dialog-label required">水库类型</label>
                <select class="dialog-input">
                  <option value="">请选择水库类型</option>
                  <option>大型</option>
                  <option>中型</option>
                  <option>小型</option>
                </select>
              </div>
              <div class="dialog-row">
                <label class="dialog-label">用途</label>
                <input class="dialog-input" placeholder="请输入用途" />
              </div>
              <div class="dialog-row">
                <label class="dialog-label">负责人</label>
                <input class="dialog-input" placeholder="请输入负责人姓名" />
              </div>
              <div class="dialog-row">
                <label class="dialog-label">联系电话</label>
                <input class="dialog-input" placeholder="请输入联系电话" />
              </div>
              <div class="dialog-row">
                <label class="dialog-label required">建设日期</label>
                <input class="dialog-input" type="date" />
              </div>
              <div class="dialog-row">
                <label class="dialog-label">最后维护日期</label>
                <input class="dialog-input" type="date" />
              </div>
              <div class="dialog-row">
                <label class="dialog-label required">状态</label>
                <select class="dialog-input">
                  <option>正常</option>
                  <option>维护</option>
                  <option>停用</option>
                </select>
              </div>
              <div class="dialog-actions">
                <button type="button" class="dialog-btn-primary" @click.prevent="showAddDialog=false">保存</button>
                <button type="button" class="dialog-btn" @click.prevent="showAddDialog=false">取消</button>
              </div>
            </form>
          </div>
        </div>
        <!-- 弹窗结束 -->
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import DataManagementHeader from '../components/DataManagementHeader.vue'
import L from 'leaflet'

export default {
  name: 'DataManagement',
  components: { DataManagementHeader },
  setup() {
    let map = null;
    const activeBox = ref('attr');
    const showAddDialog = ref(false);
    // 导出内容复选框绑定
    const exportContent = ref({
      base: true,
      water: false,
      risk: false
    });
    
    // 初始化地图
    const initMap = () => {
      map = L.map('data-map').setView([39.9042, 116.4074], 10);
      
      // 添加OpenStreetMap底图
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors'
      }).addTo(map);
      
      // 这里可以添加数据管理相关的功能
    }
    
    return { activeBox, showAddDialog, exportContent };
  }
}
</script>

<style scoped>
.data-management-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  width: 100%;
}
.data-management-main {
  display: flex;
  flex: 1;
  height: 100%;
}
.data-management-sidebar {
  width: 180px;
  background: transparent;
  padding: 30px 0 0 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 24px;
  min-width: 140px;
}
.sidebar-box {
  width: 110px;
  background: #fff;
  color: #222;
  font-size: 16px;
  font-weight: bold;
  text-align: center;
  padding: 12px 0;
  border-radius: 14px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.08);
  letter-spacing: 1px;
  margin-bottom: 8px;
  transition: box-shadow 0.2s, background 0.2s, color 0.2s;
  border: none;
  cursor: pointer;
}
.sidebar-box.active {
  color: #1976d2;
  box-shadow: 0 4px 16px rgba(25,118,210,0.10);
  background: #f5faff;
}
.data-management-content {
  flex: 1;
  overflow: auto;
  background: #fff;
  padding: 0 0 0 0;
  min-width: 0;
}
.attr-panel {
  padding: 32px 24px 0 24px;
}
.attr-title {
  font-size: 28px;
  font-weight: bold;
  margin-bottom: 32px;
}
.attr-toolbar {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 24px;
}
.attr-input {
  height: 36px;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  padding: 0 12px;
  font-size: 15px;
  background: #fff;
}
.attr-btn {
  height: 36px;
  padding: 0 18px;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  background: #fff;
  color: #222;
  font-size: 15px;
  cursor: pointer;
  transition: background 0.2s, color 0.2s;
}
.attr-btn-primary {
  background: #1976d2;
  color: #fff;
  border: none;
}
.attr-btn-add {
  background: #42b983;
  color: #fff;
  border: none;
  margin-left: auto;
}
.attr-table-wrap {
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.04);
  margin-bottom: 18px;
  overflow-x: auto;
}
.attr-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 15px;
  background: #fff;
}
.attr-table th, .attr-table td {
  border: 1px solid #f0f0f0;
  padding: 12px 8px;
  text-align: center;
}
.attr-table th {
  background: #f8fafd;
  color: #222;
  font-weight: bold;
}
.attr-pagination {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 15px;
  color: #888;
  margin-bottom: 32px;
}
.attr-page-select {
  height: 32px;
  border-radius: 6px;
  border: 1px solid #e0e0e0;
  padding: 0 8px;
  font-size: 15px;
}
.attr-page-btn {
  height: 32px;
  width: 32px;
  border-radius: 6px;
  border: 1px solid #e0e0e0;
  background: #fff;
  color: #888;
  font-size: 18px;
  cursor: pointer;
}
.attr-page-btn:disabled {
  color: #ccc;
  cursor: not-allowed;
}
.attr-page-num {
  font-size: 16px;
  color: #1976d2;
  font-weight: bold;
}
.empty-panel {
  width: 100%;
  height: 100%;
  background: #fff;
}
.dialog-mask {
  position: fixed;
  left: 0; top: 0; right: 0; bottom: 0;
  background: rgba(0,0,0,0.12);
  z-index: 2000;
  display: flex;
  align-items: center;
  justify-content: center;
}
.dialog-box {
  background: #fff;
  border-radius: 10px;
  box-shadow: 0 4px 32px rgba(0,0,0,0.13);
  width: 600px;
  max-width: 96vw;
  padding: 32px 36px 24px 36px;
  position: relative;
}
.dialog-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24px;
}
.dialog-title {
  font-size: 22px;
  font-weight: bold;
}
.dialog-close {
  font-size: 28px;
  color: #888;
  cursor: pointer;
  transition: color 0.2s;
}
.dialog-close:hover {
  color: #f44336;
}
.dialog-form {
  display: flex;
  flex-direction: column;
  gap: 18px;
}
.dialog-row {
  display: flex;
  align-items: center;
  gap: 12px;
}
.dialog-label {
  width: 100px;
  text-align: right;
  color: #222;
  font-size: 16px;
}
.dialog-label.required::before {
  content: '*';
  color: #f44336;
  margin-right: 4px;
}
.dialog-input {
  flex: 1;
  height: 36px;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  padding: 0 12px;
  font-size: 15px;
  background: #fff;
}
.dialog-input.short {
  width: 120px;
  min-width: 80px;
  flex: none;
}
.dialog-group {
  display: flex;
  align-items: center;
  gap: 6px;
}
.dialog-unit {
  color: #888;
  font-size: 15px;
  margin-left: 4px;
}
.dialog-btn {
  height: 32px;
  min-width: 32px;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  background: #f8fafd;
  color: #222;
  font-size: 18px;
  cursor: pointer;
  transition: background 0.2s, color 0.2s;
  padding: 0 10px;
}
.dialog-btn-primary {
  background: #1976d2;
  color: #fff;
  border: none;
  margin-right: 12px;
}
.dialog-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 18px;
}
.import-panel {
  padding: 32px 24px 0 24px;
}
.import-title {
  font-size: 28px;
  font-weight: bold;
  margin-bottom: 32px;
}
.import-card {
  background: #fff;
  border-radius: 10px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.07);
  padding: 36px 32px 32px 32px;
  max-width: 800px;
  margin: 0 auto;
}
.import-upload-area {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 32px;
}
.import-upload-box {
  border: 1.5px dashed #b0b7c3;
  border-radius: 8px;
  width: 420px;
  height: 180px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: #fafdff;
  margin-bottom: 12px;
  transition: border-color 0.2s;
}
.import-upload-icon {
  margin-bottom: 12px;
}
.import-upload-text {
  color: #888;
  font-size: 17px;
}
.import-upload-link {
  color: #1976d2;
  cursor: pointer;
  margin-left: 4px;
}
.import-upload-tip {
  color: #999;
  font-size: 14px;
  margin-top: 2px;
}
.import-template-area {
  background: #f6f8fa;
  border-radius: 8px;
  padding: 24px 24px 18px 24px;
  margin-top: 18px;
}
.import-template-title {
  font-size: 18px;
  font-weight: bold;
  margin-bottom: 8px;
}
.import-template-desc {
  color: #444;
  font-size: 15px;
  margin-bottom: 14px;
}
.import-template-btn {
  background: #1976d2;
  color: #fff;
  border: none;
  border-radius: 6px;
  padding: 8px 22px;
  font-size: 15px;
  font-weight: bold;
  cursor: pointer;
  transition: background 0.2s;
}
.import-template-btn:hover {
  background: #1256a3;
}
.export-panel {
  padding: 32px 24px 0 24px;
}
.export-title {
  font-size: 28px;
  font-weight: bold;
  margin-bottom: 32px;
}
.export-card {
  background: #fff;
  border-radius: 10px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.07);
  padding: 36px 32px 32px 32px;
  max-width: 800px;
  margin: 0 auto;
}
.export-row {
  display: flex;
  align-items: center;
  gap: 18px;
  margin-bottom: 22px;
}
.export-label {
  width: 90px;
  font-size: 16px;
  color: #222;
  font-weight: bold;
  text-align: right;
}
.export-checkbox-group {
  display: flex;
  gap: 12px;
}
.export-checkbox {
  font-size: 15px;
  color: #222;
  display: flex;
  align-items: center;
  gap: 4px;
}
.export-input {
  height: 36px;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  padding: 0 12px;
  font-size: 15px;
  background: #fff;
}
.export-radio {
  font-size: 15px;
  color: #222;
  margin-right: 18px;
  display: flex;
  align-items: center;
  gap: 4px;
}
.export-actions {
  margin-top: 18px;
  display: flex;
  justify-content: flex-start;
}
.export-btn {
  background: #1976d2;
  color: #fff;
  border: none;
  border-radius: 6px;
  padding: 10px 32px;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  transition: background 0.2s;
}
.export-btn:hover {
  background: #1256a3;
}
</style> 
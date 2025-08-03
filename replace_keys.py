# -*- coding: utf-8 -*-
import json

file_path = 'Beijing-GeoJson-Tzy/水库面数据.geojson'

with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

for feature in data['features']:
    props = feature['properties']
    if '年平均' in props:
        props['年平均氨氮'] = props.pop('年平均')

with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print('字段批量替换完成！') 
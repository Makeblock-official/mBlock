# -*- coding: utf-8 -*-
# Author: kun.z

import xlrd
import json

def read_xlsx(file= '../src/locale/locale.xlsx',by_name=u'locale'):
    workbook = xlrd.open_workbook(file)
    booksheet = workbook.sheet_by_name(by_name)
    p = list()
    col = list()
    ret = {}
    for rowidx in range(booksheet.nrows):
        # print rowidx
        if rowidx == 1:
            continue
        for colidx in range(booksheet.ncols):
            cel = booksheet.cell(rowidx, colidx)
            val = cel.value

            if (type(val) == unicode):
                val = val.encode('utf-8')
            if (type(val) == str):
                val = val.strip()
            # print val

            if colidx == 0:
                continue
            if rowidx == 0:
                col.append(val)
                p.append({})
            else:
                celzero = booksheet.cell(rowidx, 0)
                valzero = celzero.value
                if (type(valzero) == unicode):
                    valzero = valzero.encode('utf-8')
                if (type(valzero) == str):
                    valzero = valzero.strip()
                p[colidx-1][valzero] = val
    ret['colume'] = col
    ret['row'] = p
    return ret

def store(file_name, measurements):
    file = "../locales/%s.json" % file_name
    with open(file, 'w') as f:
        f.write(json.dumps(measurements, ensure_ascii=False))

def main():
    xlsx_list = read_xlsx()
    for idx in range(len(xlsx_list['colume'])):
        if xlsx_list['colume'][idx] == '':
            continue
        store(xlsx_list['colume'][idx], xlsx_list['row'][idx])
    return

if __name__ == '__main__':
    main()
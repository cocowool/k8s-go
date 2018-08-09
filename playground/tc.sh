#!/bin/bash
icourse=('tencent.' 'cloudedu')
x=${icourse[0]}
y=${icourse[1]}
i=${#x}
e=${#y}
unset icourse
echo ${icourse:0:8}$i$e

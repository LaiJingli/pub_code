#!/bin/sh

######################
#为防止同一sql脚本在线上重复执行，在sql脚本在线上执行后自动移动到executed_history目录。
#
######################

input_sql_name=$1

###svn服务器路径
svn_server=http://svn.github.com
##svn服务器发布源
svn_sql_path=/wei-doc/平台组/系统文档/发布文档/

root_path=/backup/autoshell/chroot/svn_doc_working_copy/

echo
echo "$input_sql_name 已经执行，为防止同一sql脚本在线上重复执行，现将该sql脚本自动移动到executed_history目录。"
cd $root_path
 
##本条命令只在初始化的时候执行一次
#svn co $svn_server$svn_sql_path

cd 发布文档 
##svn move
svn up >/dev/null
svn mv $(date +%Y)/$input_sql_name  $(date +%Y)_executed_history
svn ci -m"$input_sql_name 已经执行，为防止同一sql脚本在线上重复执行，现将该sql脚本自动移动到executed_history目录。"

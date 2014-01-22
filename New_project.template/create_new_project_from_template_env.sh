#!/bin/sh

######################
#
#用于初始化一个项目的发布脚本配置,只运行一次
#
######################


###定义项目名称(目标服务器/var/www下的web发布项目名称)
project_name=Projectname

##svn服务器发布源名称
svn_project_name=Projectname


##上次发布版本号
last_revision_code=4166
last_revision_conf=4166


##web目标服务器内网ip后缀(192.168.0.x),ip_suffix格式：如果有多个ip，中间用空格分隔，写法为ip_suffix="56 57 58 59"
#ip_suffix="15 16 17 11 12"

##mysql主库ip地址，账号密码请手工修改auto_release_Hogwarts_dev.sh


##项目的发布脚本目录
root_dir=/backup/autoshell/chroot/
script_dir=$root_dir$project_name/auto_shell/
if [ ! -d $script_dir ];then
	mkdir -p $script_dir
fi

log_dir=$root_dir$project_name/logs/
last_revision_conf_log=last_revision_conf_$project_name.log
last_revision_code_log=last_revision_code_$project_name.log
tmp_current_revision_code_log=tmp_current_revision_code_$project_name.log
if [ ! -d $log_dir ];then
	mkdir -p $log_dir
fi

echo 开始进行初始化项目:$project_name

##初始化上次发布版本号
echo $last_revision_code > $log_dir$last_revision_code_log
echo $last_revision_conf > $log_dir$last_revision_conf_log
echo                     > $log_dir$tmp_current_revision_code_log

##清理上次运行产生的垃圾文件
#rm -fr $root_dir$project_name

##将发布脚本复制到新的项目下
cp ./auto* $script_dir

##重命名发布脚本的名字
rename Hogwarts  $project_name ${script_dir}*

##修改发布脚本中的project_name
sed -i "s/Hogwarts/$project_name/g" ${script_dir}auto_release_$project_name*

##修改发布脚本中的svn_project_name
sed -i "s/hogwarts.new/$svn_project_name/g" ${script_dir}auto_release_$project_name*


echo 始化项目:$project_name完成
echo 项目脚本路径:$root_dir$project_name

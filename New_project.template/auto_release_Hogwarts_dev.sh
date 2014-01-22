#!/bin/sh

#####################################################################################################
#平台发布脚本
#功能：从svn导出指定版本号的代码、sql脚本文件、配置文件一起发布到目标服务器
#
#by Lai
#
#2013-1-15
#####################################################################################################

###定义项目名称(目标服务器/var/www下的web发布项目名称)
project_name=Hogwarts

###发布机器上待发布项目路径
root_path=/backup/autoshell/chroot/$project_name/
auto_path=/backup/autoshell/chroot/$project_name/auto_shell/
 log_path=/backup/autoshell/chroot/$project_name/logs/
code_path=/backup/autoshell/chroot/$project_name/release_code_$project_name/
conf_path=/backup/autoshell/chroot/$project_name/release_conf_$project_name/
 sql_path=/backup/autoshell/chroot/$project_name/release_sql_$project_name/
 doc_path=/backup/autoshell/chroot/$project_name/release_doc_$project_name/
###创建发布机待发布项目路径
for path in $root_path $auto_path $log_path $code_path $conf_path $sql_path $doc_path;do
	if [ ! -d $path ];then
		mkdir -p $path
		echo "$path not exist,create it: mkdir -p $path"
	fi
done


###svn服务器路径
svn_server=http://svn.github.com
##svn服务器发布源
svn_code_path=/hogwarts.new/release/
svn_conf_path=/wei-doc/平台组/系统文档/发布文档/平台配置文件/production/$project_name/
 svn_sql_path=/wei-doc/平台组/系统文档/发布文档/$(date +%Y)/
 svn_doc_path=/wei-doc/平台组/系统文档/发布文档/$(date +%Y)/
svn_exclude_conf_file=exclude_conf_file_list_for_$project_name.txt


###定义目标服务器路径
user=www@
ip_prefix=192.168.0.
##ip_suffix格式：如果有多个ip，中间用空格分隔，写法为ip_suffix="56 57 58 59"
ip_suffix="203"
desdir=/var/www/$project_name


###定义该项目对应的mysql主库地址及用户名密码
mysql_db=mydb
mysql_ip=192.168.0.100
mysql_connect_cmd="/usr/local/mysql/bin/mysql -udb_release -prelease684 -h$mysql_ip $mysql_db"

rsync_cmd="sshpass -p 123456 rsync -vzrtopg "

###定义日志格式
today=$(date +%Y%m%d)
log_time="$(date +%Y'年'%m'月'%d'日'%H':'%M':'%S)"
svn_export_code_log=${log_path}${today}_auto_svn_export_code_${project_name}.log
svn_export_conf_log=${log_path}${today}_auto_svn_export_conf_${project_name}.log
     rsync_code_log=${log_path}${today}_auto_rsync_code_${project_name}.log
     rsync_conf_log=${log_path}${today}_auto_rsync_conf_${project_name}.log
history_release_revision_log=${log_path}history_release_revision_log_${project_name}.log
   mysql_script_log=${log_path}${today}_mysql_script_op.log
 tmp_rsync_code_log=${log_path}${today}_tmp_rsync_code.log
 tmp_rsync_conf_log=${log_path}${today}_tmp_rsync_conf.log
  tmp_code_diff_log=${log_path}${today}_code_diff.log
  tmp_conf_diff_log=${log_path}${today}_conf_diff.log
##每次清空tmp log文件
cat /dev/null > $tmp_rsync_code_log
cat /dev/null > $tmp_rsync_conf_log
##定义删除30天之前log
one_month_ago=$(date  -d "30 day ago"  +%Y%m%d)


###定义记录最近一次该项目发布版本号文件的绝对路径
last_revision_code_log=${log_path}last_revision_code_${project_name}.log
last_revision_conf_log=${log_path}last_revision_conf_${project_name}.log
 last_revision_sql_log=${log_path}last_revision_sql_${project_name}.log
tmp_current_revision_code_log=${log_path}tmp_current_revision_code_${project_name}.log

###定义发布报告邮件相关信息
release_user=`echo $1`
receipt_user=362560701@qq.com
receipt_user_ops_hogwarts=362560701@qq.com

mail_tittle="【线上发布报告】_${project_name}_by_${release_user}_${today} --"
mail_tittle_notify="【通知:线上${project_name}有发布文档需要执行】_${project_name}_by_${release_user}_${today} --"
mail_report_log=$log_path${today}_mail_report_${project_name}.log
###生成发布报告的头部信息
echo
echo 发布项目名:$project_name                |tee     $mail_report_log
echo 源svn路径 :$svn_server$svn_code_path    |tee -a  $mail_report_log
echo 目标服务器:$ip_prefix$ip_suffix:$desdir |tee -a  $mail_report_log
echo 目标数据库:$mysql_ip $mysql_db          |tee -a  $mail_report_log
echo
echo 发布执行人:$release_user                >> $mail_report_log
echo 发布执行时间:$log_time                  >> $mail_report_log





###########发布类型选择
echo -e "\033[31m\033[01m 0、请选择发布类型\033[0m"
echo "[1] > 手工执行发布文档:如修改crontab、NFS mount、修改nginx配置文件、手工执行脚本等非重复性非常规性操作."
echo "[2] > 完全自动发布流程:包括执行sql脚本、发布配置文件、发布普通code、执行redis操作,共4种自动发布操作."
echo -en "\033[31m\033[01m请选择发布类型:\033[0m"
#read input_release_type_select
input_release_type_select=2
echo 系统自动选择 2
##判断输入是否合法
until [ "$input_release_type_select" = "1" ] || [ "$input_release_type_select" = "2" ];do
	echo -en "\033[31m\033[01m输入不合法,请重新输入:\033[0m"
	read input_release_type_select
done
if   [ "$input_release_type_select" = "1" ] ;then
        ###获取用户输入发布文档
        #进入存放目录并下载指定发布文档
        cd   $doc_path
        echo 注意:发布文档必须存放在$svn_server$svn_doc_path
        echo 请从下面文件列表中选择你要执行的发布文档：
        /usr/bin/svn  --force export $svn_server$svn_doc_path
        echo  -en "\033[31m\033[01m请从上边列表中选择要执行的发布文档:\033[0m"
        read input_doc_name
        #进入doc存放目录并下载指定sql脚本
        /usr/bin/svn  --force export $svn_server$svn_doc_path$input_doc_name
        ##判断输入是否合法
        until [ -f "$doc_path$input_doc_name" ];do
                echo -en "\033[33m\033[01m你输入的发布文档不存在\033[0m, \033[31m\033[01m请重新选择正确的发布文档名称(退出请输入exit):\033[0m"
                read input_doc_name
                ##重新下载用户输入的sql脚本
                /usr/bin/svn  --force export $svn_server$svn_doc_path$input_doc_name
                ##是否退出发布
                if [ "$input_doc_name" = "exit" ];then
                        exit
                fi
        done

        ####编码转换，目前已知编码UTF8、ISO-8859(GBK)
        input_doc_file_type=`file -b $doc_path$input_doc_name|awk '{print $1}'`
        if [ "$input_doc_file_type" = "ISO-8859" ];then
                echo "$input_doc_name 编码为：`file -b $doc_path$input_doc_name|awk '{print $1}'`(GBK),开始转换为UTF8编码"
                iconv -f gbk -tutf8 $doc_path$input_doc_name -o $doc_path$input_doc_name.utf8
                mv $doc_path$input_doc_name      $doc_path$input_doc_name.gbk
                mv $doc_path$input_doc_name.utf8 $doc_path$input_doc_name
        elif [ "$input_doc_file_type" = "UTF-8" ];then
                echo "$input_doc_name 已经是UTF8编码,不需要转码"
        else
                ##输入错误，棕色提示
                echo -e "\033[33m\033[01m$input_doc_name 既不是UTF8编码，也不是ISO-8859(GBK)编码，为保证含有中文的sql语句正常执行，请修改$input_doc_name为UTF8或者ISO-8859(GBK)编码\033[0m"
                echo 退出发布...
                exit
        fi

	###将需要手工执行的发布文档附件发送给ops和hogwarts
	echo -----------------------------------------                 >> $mail_report_log
	echo "Hi,ops
    本邮件的附件需要ops手工执行,请按照附件操作执行，完成后全部回复本邮件通知hogwarts.详细发布文档见附件《$input_doc_name》"   >> $mail_report_log
	echo "附件《$input_doc_name》内容全文如下:"  >> $mail_report_log 
	cat  $doc_path$input_doc_name                >> $mail_report_log
	cat $mail_report_log |/usr/local/mutt/bin/mutt -a $doc_path$input_doc_name -s $mail_tittle_notify $receipt_user_ops_hogwarts
	echo "《发布文档执行通知》已经邮件给$receipt_user_ops_hogwarts,请等待ops执行发布文档!"
	echo 退出发布...
	exit


elif [ "$input_release_type_select" = "2" ] ;then
################################################################ 本分支到程序结尾 #####################################################################3


##########################判断此次发布是否要执行sql脚本
##设置sql执行成功与否标志,发送邮件sql附件用
is_sql_exec_ok=0
echo -en "\033[31m\033[01m 1、此次发布是否要执行sql脚本(yes/no):\033[0m"
#read input_sql_or_no
input_sql_or_no=no
echo 系统自动选择 no
##判断输入是否合法
until [ "$input_sql_or_no" = "yes" ] || [ "$input_sql_or_no" = "no" ];do
	echo -en "\033[31m\033[01m请输入yes或者no:\033[0m"
	read input_sql_or_no
done
###发布是否要执行sql脚本处理
if [ "$input_sql_or_no" = "yes" ];then
	###获取用户输入sql脚本名称
	#进入sql存放目录并下载指定sql脚本
	cd   $sql_path
	echo 注意:sql脚本必须存放在$svn_server$svn_sql_path
	echo 请从下面文件列表中选择你要执行的sql脚本：
	/usr/bin/svn  --force export $svn_server$svn_sql_path|grep sql
	echo  -en "\033[31m\033[01m请从上边列表中选择要执行sql脚本:\033[0m"
	read input_sql_name
	#进入sql存放目录并下载指定sql脚本
	/usr/bin/svn  --force export $svn_server$svn_sql_path$input_sql_name
	##判断输入是否合法
	until [ -f "$sql_path$input_sql_name" ];do
		echo -en "\033[33m\033[01m你输入的sql脚本不存在\033[0m, \033[31m\033[01m请重新选择正确的sql脚本名称(退出请输入exit):\033[0m"
		read input_sql_name
		##重新下载用户输入的sql脚本
		/usr/bin/svn  --force export $svn_server$svn_sql_path$input_sql_name
		##是否退出发布
		if [ "$input_sql_name" = "exit" ];then
			exit
		fi
	done

	
	####sql脚本编码转换，目前sql脚本已知编码UTF8、ISO-8859(GBK)
	input_sql_file_type=`file -b $sql_path$input_sql_name|awk '{print $1}'`
	if [ "$input_sql_file_type" = "ISO-8859" ];then
		echo "$input_sql_name 编码为：`file -b $sql_path$input_sql_name|awk '{print $1}'`(GBK),开始转换为UTF8编码"
		iconv -f gbk -tutf8 $sql_path$input_sql_name -o $sql_path$input_sql_name.utf8
		mv $sql_path$input_sql_name  $sql_path$input_sql_name.gbk
		mv $sql_path$input_sql_name.utf8 $sql_path$input_sql_name
	elif [ "$input_sql_file_type" = "UTF-8" ];then
		echo "$input_sql_name 已经是UTF8编码,不需要转码"
	else
		##输入错误，棕色提示
		echo -e "\033[33m\033[01m$input_sql_name 既不是UTF8编码，也不是ISO-8859(GBK)编码，为保证含有中文的sql语句正常执行，请修改$input_sql_name为UTF8或者ISO-8859(GBK)编码\033[0m"
		echo 退出发布...
		exit
	fi

	##执行sql脚本前,判断sql脚本中是否含有drop操作
	is_drop=`cat $sql_path$input_sql_name|grep -iE "drop table|drop database|select \*"|wc -l`
	if [ "$is_drop" -eq 0 ];then
		##输入正确，绿色提示
		echo -e "\033[32m\033[01m$svn_server$svn_sql_path$input_sql_name 存在且不含drop操作或者select *,该sql脚本可以执行\033[0m"
	else
		##输入错误，闪烁提示
		echo -e "\033[33m\033[05m$svn_server$svn_sql_path$input_sql_name 含有drop table或者drop database或者select *操作\033[0m,退出发布流程。"
		exit 
	fi

        ##执行sql脚本前,强制判断sql脚本中必须含有use db操作
        is_use_db=`cat $sql_path$input_sql_name|grep -v \#|grep -iE "use "|wc -l`
        if [ "$is_use_db" -eq 0 ];then
                ##输入错误，闪烁提示
                echo -e "\033[33m\033[05m$svn_server$svn_sql_path$input_sql_name 不含有use_db操作，请确保脚本中含有use dbname的语句\033[0m,退出发布流程。"
                exit 
        else
		#echo $is_use_db
                ##输入正确，绿色提示
                echo -e "\033[32m\033[01m$svn_server$svn_sql_path$input_sql_name 存在且含有use_db操作,该sql脚本可以执行\033[0m"
        fi




	##向用户确认是否要执行sql脚本
	echo -en "\033[31m\033[01m请确认是否要在$mysql_ip的$mysql_db主库上执行sql脚本(yes/no):\033[0m"
	read input_confirm
	##判断输入是否合法
	until [ "$input_confirm" = "yes" ] || [ "$input_confirm" = "no" ];do
        	echo -en "\033[31m\033[01m请输入yes或者no:\033[0m"
        	read input_confirm
	done

	if [ "$input_confirm" = "yes" ];then
		##执行sql脚本导入及结果
		$mysql_connect_cmd <$sql_path$input_sql_name   2>$mysql_script_log
		##判断sql执行是否成功，即执行sql log是否为空文件,失败exit
		if [ -s "$mysql_script_log" ];then
			##错误，闪烁提示
			echo -e "\033[33m\033[05m  no null,sql执行失败,失败原因:\033[0m"
			echo `cat $mysql_script_log`
			echo "请查找错误原因，发布终止!"
   			exit
		else
			echo sql脚本执行成功!
   			is_sql_exec_ok=1
			###为防止在线上重复执行同一sql脚本，转移已经执行过的sql
			${auto_path}auto_release_svn_executed_sql_mv.sh $input_sql_name		

			echo "##############################################################" >> $mail_report_log
   			echo "一、sql脚本执行结果:成功"                                           >> $mail_report_log
   			echo "成功执行sql脚本:$svn_server$svn_sql_path$input_sql_name"        >> $mail_report_log 
			echo "该sql脚本内容见附件《$input_sql_name》"                           >> $mail_report_log 
			echo "该sql脚本 $input_sql_name 前30行如下:"                          >> $mail_report_log
			head -n 30 $sql_path$input_sql_name                                   >> $mail_report_log
			echo " "                                                              >> $mail_report_log
		fi
	else
		echo “你输入no，不执行sql脚本”
		exit
	fi
##如果不执行sql
else
	echo "没有sql脚本要执行，检查是否有配置文件要发布..."
	echo "" >> $mail_report_log
	echo "一、本次没有sql脚本要执行。" >> $mail_report_log
fi








##########################每次发布配置文件和code前，下载最新配置文件列表，即代码中线上线下环境中不同的文件，如数据库配置文件
cd $auto_path
#echo "Downloading 配置文件列表 from $svn_server$svn_conf_path$svn_exclude_conf_file"
/usr/bin/svn --force  export        $svn_server$svn_conf_path$svn_exclude_conf_file >/dev/null
cp $auto_path$svn_exclude_conf_file $auto_path$svn_exclude_conf_file.svn
exclude_conf_file=$auto_path$svn_exclude_conf_file
###删除配置文件列表中每行结尾的空格，防止发布时配置文件被发布
sed -i 's/[ ]*$//g'  $exclude_conf_file





####################################判断此次发布是否有配置文件发布的辑处理
echo -en "\033[31m\033[01m 2、此次发布是否要发布配置文件(yes/no):\033[0m"
read input_conf_file
##判断输入是否合法
until [ "$input_conf_file" = "yes" ] || [ "$input_conf_file" = "no" ];do
        echo -en "\033[31m\033[01m请输入yes或者no:\033[0m"
        read input_conf_file
done
###发布是否要有配置文件被发布的处理
if [ "$input_conf_file" = "yes" ];then
	##查询svn版本库该项目的最高版本号
	biggest_revision_conf=`/usr/bin/svn info $svn_server$svn_conf_path|grep "Revision:"|awk '{print $2}'`
	##查询上次发布版本号
	last_revision_conf=`cat   $last_revision_conf_log`
	##向用户提示上次发布和当前最高版本号
	echo 上次发布conf版本号: $last_revision_conf
	echo 当前最高conf版本号: $biggest_revision_conf

        ###列举本次配置文件和上次发布版本的区别
        echo  "当前配置文件和上次发布版本的diff信息($biggest_revision_conf:$last_revision_conf):"
	svn diff -r $last_revision_conf:$biggest_revision_conf  $svn_server$svn_conf_path|grep -viE "*pass*|*User*"|tee  $tmp_conf_diff_log

	##询问用户是否发布配置文件
	echo -en "\033[31m\033[01m请确认要发布包含以上区别的配置文件(yes/no):\033[0m"
	read input_conf_file_confirm
	##判断输入是否合法
	until [ "$input_conf_file_confirm" = "yes" ] || [ "$input_conf_file_confirm" = "no" ];do
		echo -en "\033[31m\033[01m请输入yes或者no:\033[0m"
		read input_conf_file_confirm
	done

	if [ "$input_conf_file_confirm" = "yes" ];then
		##绿色提示
                echo -e "\033[32m\033[01m你输入yes，开始导出配置文件、执行配置文件发布\033[0m"
		######conf file export from svn and rsync to server
		echo "exporting $project_name conf file from svn..."
		echo "###############################################################################################################"   |tee -a $svn_export_conf_log
		echo "$log_time Begin to export $project_name conf file from $svn_server$svn_conf_path to $conf_path$today/$project_name"|tee -a $svn_export_conf_log
		#导出最新版本的conf
		/usr/bin/svn  --force export                                 $svn_server$svn_conf_path    $conf_path$today/$project_name  >>     $svn_export_conf_log
		echo "$log_time export conf file of $project_name finished"|tee -a $svn_export_conf_log

		###调用rsync命令同步代码到目标服务器
		cd $root_path
		echo "###############################################################################################################" |tee -a $rsync_conf_log
		for suffix in $ip_suffix ;do
			host=$ip_prefix$suffix
        		##从发布机同步除排除的配置文件之外的代码到目标服务器
        		echo "$log_time Begin to rsync from release_conf_${project_name}/$(date +%Y%m%d)/$project_name/ to $user$host:$desdir" |tee -a $rsync_conf_log
         	 echo " rsync -vzrtopg release_conf_${project_name}/$(date +%Y%m%d)/$project_name/  $user$host:$desdir"|tee -a $rsync_conf_log  $tmp_rsync_conf_log
			$rsync_cmd  -e "ssh -o StrictHostKeyChecking=no" release_conf_${project_name}/$(date +%Y%m%d)/$project_name/  $user$host:$desdir|grep -v /$ |tee -a $rsync_conf_log  $tmp_rsync_conf_log
        		echo "$log_time rsync conf file to $host finished" |tee -a $rsync_conf_log
			echo
			echo "-------------------------------------------------------------------------------------------------------"
		done
		##发布配置文件完成后，更新上次发布的版本号文件$last_revision_conf
		echo $biggest_revision_conf > $last_revision_conf_log
		echo " " >> $mail_report_log
		echo  "二、配置文件发布执行结果:成功" >> $mail_report_log
		###上次发布版本号、本次发布版本号和最高版本号log
		echo 本次发布配置文件版本号信息：                                  >> $mail_report_log
		echo $project_name上次配置文件发布版本号: $last_revision_conf      >> $mail_report_log
		echo $project_name当前配置文件最高版本号: $biggest_revision_conf   >> $mail_report_log
		echo  "本次发布了那些配置文件："  >> $mail_report_log
		cat   $tmp_rsync_conf_log         >> $mail_report_log
		echo  "当前配置文件和上次发布版本的diff信息($biggest_revision_conf:$last_revision_conf):"           >> $mail_report_log
		cat  $tmp_conf_diff_log             >> $mail_report_log
		echo " "                            >> $mail_report_log
	fi
##如果不发布配置文件，则直接发布代码
else
        echo "没有配置文件要发布,检查是否有代码要发布..."
	echo "" >> $mail_report_log
	echo "二、本次没有配置文件要发布。" >> $mail_report_log
fi







###########################################判断此次是否要发布普通代码code
##设置code同步成功与否标志，发送邮件diff附件用
is_code_rsync_ok=0
##获取用户输入
echo -en "\033[31m\033[01m 3、此次发布是否发布代码code(yes/no):\033[0m"
read input_code_or_no
##判断输入是否合法
until [ "$input_code_or_no" = "yes" ] || [ "$input_code_or_no" = "no" ];do
         echo -en "\033[31m\033[01m请输入yes或者no:\033[0m"
         read input_code_or_no
done

if [ "$input_code_or_no" = yes ];then
############获取用户输入版本号部分的处理
	##查询svn版本库该项目的最高版本号
	biggest_revision_code=`/usr/bin/svn info $svn_server$svn_code_path|grep "Revision:"|awk '{print $2}'`
	##查询上次发布版本号
	last_revision_code=`cat   $last_revision_code_log`
	tmp_current_revision_code=`cat $tmp_current_revision_code_log`
	##向用户提示上次发布和当前最高版本号
	echo $project_name上次发布code版本号: $last_revision_code
	echo $project_name当前最高code版本号: $biggest_revision_code
	echo -e "\033[32m\033[01m$project_name测试通过可以发布的code版本号:\033[0m $tmp_current_revision_code"
	##获取用户输入
        #echo  -en "\033[31m\033[01m请输入要发布$project_name项目的Release版本号: \033[0m"
        #read input_revison_code
        ##判断输入是否合法
        #until [ "$input_revison_code" -ge "$last_revision_code" ] && [ "$input_revison_code" -le "$biggest_revision_code" ];do 
        #        echo -en "\033[31m\033[01m只有版本号大于等于上次发布版本号且小于等于版本库最高版本号时才执行发布,请重新输入：\033[0m"
        #        read input_revison_code
        #done
	
	##判断测试是否提供了可以发布的版本号
	if [ "$tmp_current_revision_code" = "" ];then
		echo 目前没有测试通过可以上线的新版本，如要发布代码，请联系测试童鞋！
		echo 退出本项目的发布...
		exit
	fi	

	##获取用户输入确认
	echo -en "\033[31m\033[01m 是否要发布以上测试通过的版本号:$tmp_current_revision_code(yes/no):\033[0m"
	read input_release_code_or_not
	##判断输入是否合法
	until [ "$input_release_code_or_not" = "yes" ] || [ "$input_release_code_or_not" = "no" ];do
        	echo -en "\033[31m\033[01m请输入yes或者no:\033[0m"
        	read input_release_code_or_not
	done

	if [ "$input_release_code_or_not" = "yes" ];then
        	current_revision_code=`echo $tmp_current_revision_code`
		#current_revision_code=`echo $input_revison_code`
        	##绿色提示
		echo -e "\033[32m\033[01m你要发布的code版本号是:$current_revision_code \033[0m"


		######code export from svn and rsync to server
		###导出指定版本code
		echo "exporting $project_name release code from svn..."
		echo "###############################################################################################################" |tee -a $svn_export_code_log
		echo "$log_time Begin to export $project_name code from $svn_server$svn_code_path to $code_path$today/$project_name  " |tee -a $svn_export_code_log
		/usr/bin/svn  -r $current_revision_code --force export  $svn_server$svn_code_path    $code_path$today/$project_name    >> $svn_export_code_log
		echo "$log_time export code of $project_name finished" |tee -a $svn_export_code_log

		###调用rsync命令同步代码到目标服务器
		cd $root_path
		echo "###############################################################################################################" |tee -a $rsync_code_log
		for suffix in $ip_suffix ;do
			host=$ip_prefix$suffix
			##从发布机同步除排除的配置文件之外的代码到目标服务器
			echo "$log_time Begin to rsync from release_code_${project_name}/$(date +%Y%m%d)/$project_name/ to $user$host:$desdir" |tee -a $rsync_code_log
			echo "本次code发布了那些文件：" |tee -a $rsync_code_log
	 		echo " rsync -vzrtopg  --exclude-from=$exclude_conf_file release_code_${project_name}/$(date +%Y%m%d)/$project_name/  $user$host:$desdir"|tee -a $rsync_code_log $tmp_rsync_code_log
			$rsync_cmd  -e "ssh -o StrictHostKeyChecking=no" --exclude-from=$exclude_conf_file release_code_${project_name}/$(date +%Y%m%d)/$project_name/  $user$host:$desdir|grep -v /$ |tee -a $rsync_code_log $tmp_rsync_code_log 
			echo "$log_time rsync code to $host finished" |tee -a $rsync_code_log
			echo
			echo "-------------------------------------------------------------------------------------------------------"
		done

		##发布完成后，更新上次发布的版本号文件$last_revision_code
		echo $current_revision_code > $last_revision_code_log
		##清空测试提供的版本号
		echo > $tmp_current_revision_code_log
		##更新history_release_revision_log
		echo  "$log_time  $current_revision_code  $release_user">>$history_release_revision_log

		is_code_rsync_ok=1
		##发布邮件log
		echo ""                                                    >> $mail_report_log
		echo "三、code发布执行结果:成功" >> $mail_report_log
  	        ###上次发布版本号、本次发布版本号和最高版本号log
        	echo $project_name上次发布版本号: $last_revision_code      >> $mail_report_log
		echo "$project_name本次发布的测试通过的code版本号: $tmp_current_revision_code"	>> $mail_report_log
		echo $project_name当前最高版本号: $biggest_revision_code   >> $mail_report_log

		echo ""                                                    >> $mail_report_log 
		echo "##############################################################" >> $mail_report_log
		echo "本次code发布了那些文件："  >> $mail_report_log
		cat  $tmp_rsync_code_log >> $mail_report_log
	
		echo " " >> $mail_report_log
		echo "##############################################################" >> $mail_report_log
		last_revision_code=`expr $last_revision_code + 1`
		echo "本次code发布解决了jira上的那些问题:" >> $mail_report_log
		jira_issue_id_set=`svn log -r $last_revision_code:$current_revision_code  $svn_server$svn_code_path|grep -v ^r|grep -v ^-|grep -v ^$|grep -v ^Merged|awk '{print $1}'|sort|uniq`
		issue_conuter=0
		for jira_issue_id in $jira_issue_id_set;do
			issue_conuter=$[$issue_conuter+1]
			#echo -n "$issue_conuter、"|tee -a $mail_report_tester_log
			jira_info=`mysql -uproxy -p'test' -P22 -h12.65.148.6 jira -e "select pkey,REPORTER,ASSIGNEE,SUMMARY,DESCRIPTION  from jiraissue where pkey='$jira_issue_id'  limit 1;"`
			issue_info_sum=`echo $jira_info|awk '{print "问题号:http://192.168.1.121:8085/browse/"$6;print "报告人:"$7;print "经办人:"$8;print "问题摘要:"$9;print "问题描述:"$10}'`
			echo $issue_info_sum >> $mail_report_log
		done

		echo " " >> $mail_report_log
		echo "##############################################################" >> $mail_report_log
		echo "本次code发布和上次发布($last_revision_code:$current_revision_code)svn log信息:" >> $mail_report_log
		svn log -r $last_revision_code:$current_revision_code  $svn_server$svn_code_path >> $mail_report_log

		echo " " >> $mail_report_log
		echo "##############################################################" >> $mail_report_log
		echo "本次code发布和上次发布($last_revision_code:$current_revision_code)代码的diff信息(最多显示50行diff信息，要查看所有diff信息，请查看附件《${today}_code_diff.log》)：" >> $mail_report_log
		svn diff -r $last_revision_code:$current_revision_code  $svn_server$svn_code_path >  $tmp_code_diff_log
		cat $tmp_code_diff_log |head -n 50 >> $mail_report_log
	else
		echo "你确认不发布测试通过的code,检查是否redis操作要执行..."
		echo "" >> $mail_report_log
		echo "三、本次没有代码要发布。" >> $mail_report_log
	fi
##如果不发布代码
else
        echo "没有代码code要发布，检查是否redis操作要执行..."
	echo "" >> $mail_report_log
	echo "三、本次没有代码要发布。" >> $mail_report_log
fi
 




###########################################删除指定天数之前的log
echo "删除14天之前的log and code"
##删除14天之前的svn导出log、rsync同步log
find $log_path -mtime +14  -name "201*" -exec rm -fr {} \;
##删除14天之前从svn导出的代码
history_date=$(date +%Y%m%d -d '14 days ago')
rm -fr  $code_path$history_date



##########################################生成发布报告,发报告邮件通知
##发送邮件
if   [ "$is_sql_exec_ok" = "1" ] && [ "$is_code_rsync_ok" = "1" ];then
	cat $mail_report_log |/usr/local/mutt/bin/mutt -a $sql_path$input_sql_name -a $tmp_code_diff_log -s $mail_tittle $receipt_user
	echo  发布报告已发送到$receipt_user
elif [ "$is_sql_exec_ok" = "1" ] && [ "$is_code_rsync_ok" = "0" ];then
	cat $mail_report_log |/usr/local/mutt/bin/mutt -a $sql_path$input_sql_name -s $mail_tittle $receipt_user
	echo  发布报告已发送到$receipt_user
elif [ "$is_sql_exec_ok" = "0" ] && [ "$is_code_rsync_ok" = "1" ];then
	cat $mail_report_log |/usr/local/mutt/bin/mutt -a $tmp_code_diff_log -s $mail_tittle $receipt_user
	echo  发布报告已发送到$receipt_user
else
	cat $mail_report_log |/usr/local/mutt/bin/mutt -s $mail_tittle $receipt_user
	echo  发布报告已发送到$receipt_user
fi

echo 发布完成.
echo

fi
#end of file

#!/bin/sh

######################
#运维人员填写回滚版本号
#
######################

##防止用户ctrl+c 中断程序
trap 'echo;echo -e "\033[31m\033[01m警告:用户不能通过 Ctrl-C 强制终止程序的运行!请严格按照系统提示操作\033[0m"' INT


release_user=`echo $1`

###定义项目名称(目标服务器/var/www下的web发布项目名称)
project_name=Hogwarts

###svn服务器路径
svn_server=http://svn.githum.com
##svn服务器发布源
svn_code_path=/hogwarts.new/release/


###定义该项目对应redis地址及端口号
redis_cmd_6379="/usr/local/bin/redis-cli -h 192.168.0.11 -p 6379"


log_time="$(date +%Y'年'%m'月'%d'日'%H':'%M':'%S)"
today=$(date +%Y%m%d)
log_path=/backup/autoshell/chroot/$project_name/logs/
  history_release_revision_log=${log_path}history_release_revision_log_${project_name}.log
#last_last_release_revision_log=${log_path}last_last_release_revision_${project_name}.log
        last_revision_code_log=${log_path}last_revision_code_${project_name}.log
 tmp_current_revision_code_log=${log_path}tmp_current_revision_code_${project_name}.log
 #tmp_last_release_revision_log=${log_path}tmp_last_release_revision_${project_name}.log
receipt_user=362560701@qq.com
mail_tittle="【通知:线上${project_name}有回滚代码可以发布】_by_${release_user}_${today}"
mail_report_ops_log=$log_path${today}_mail_report_ops_${project_name}.log
###生成发布报告的头部信息
echo 发布项目名:$project_name                |tee     $mail_report_ops_log
echo 源svn路径 :$svn_server$svn_code_path    |tee -a  $mail_report_ops_log
echo 运维执行人:$release_user                >> $mail_report_ops_log
echo 操作时间:$log_time                      >> $mail_report_ops_log
echo                                         >> $mail_report_ops_log
echo "hi,Hogwarts
         运维同事($release_user)已经提供了$project_name项目可以回滚的release版本号，请登录发布系统执行发布，本次发布详情如下："  >> $mail_report_ops_log
echo                                         >> $mail_report_ops_log



##########################################设置代码回滚操作
##获取用户输入
echo -en "\033[31m\033[01m 1、是否要设置代码的回滚版本号(yes/no):\033[0m"
read input_code_rollback_or_no
##判断输入是否合法
until [ "$input_code_rollback_or_no" = "yes" ] || [ "$input_code_rollback_or_no" = "no" ];do
         echo -en "\033[31m\033[01m请输入yes或者no:\033[0m"
         read input_code_rollback_or_no
done

if [ "$input_code_rollback_or_no" = "yes" ];then
	     last_release_revision=`tail -n 1 $history_release_revision_log|awk '{print $2}'`
	last_last_release_revision=`tail -n 2 $history_release_revision_log|head -n 1|awk '{print $2}'`

	echo  -e "!!!\033[31m\033[01m你已进入回滚设置流程，本流程只能执行一次，操作成功后千万不要重复执行\033[0m!!!"
	echo

	echo "最近一次发布版本号(有问题的版本)是:$last_release_revision"            |tee -a $mail_report_ops_log
	echo "最近一次的上次发布版本号(历史正确版本)是:$last_last_release_revision" |tee -a $mail_report_ops_log

	echo "要回滚到最近一次的上次发布版本号(历史正确版本)是:$last_last_release_revision" |tee -a $mail_report_ops_log
	echo |tee -a $mail_report_ops_log


	echo "一、本次要回滚的code版本号(历史正确版本)和最近一次发布版本号(有问题的版本)($last_last_release_revision:$last_release_revision)之间的jira问题:" |tee -a $mail_report_ops_log
	jira_issue_id_set=`svn log -r $last_last_release_revision:$last_release_revision  $svn_server$svn_code_path|grep -v ^r|grep -v ^-|grep -v ^$|grep -v ^Merged|awk '{print $1}'|sort|uniq`
	issue_conuter=0
	for jira_issue_id in $jira_issue_id_set;do
		issue_conuter=$[$issue_conuter+1]
		echo -n "$issue_conuter、"|tee -a $mail_report_ops_log
		jira_info=`mysql -uproxy -p'test' -P12106 -h12.65.148.6 jira  -e "select pkey,REPORTER,ASSIGNEE,SUMMARY,DESCRIPTION  from jiraissue where pkey='$jira_issue_id'  limit 1;"`
		issue_info_sum=`echo $jira_info|awk '{print "问题号:http://192.168.1.121:8085/browse/"$6 "\n";print "报告人:"$7;print "经办人:"$8 ;print "问题摘要:"$9 ;print "问题描述:"$10}'`
		echo $issue_info_sum |tee -a $mail_report_ops_log
	done

	echo |tee -a $mail_report_ops_log
	echo "二、本次回滚的code版本号(历史正确版本)和最近一次发布版本号(有问题的版本)($last_last_release_revision:$last_release_revision)之间svn log信息:"|tee -a $mail_report_ops_log
	svn log -r $last_last_release_revision:$last_release_revision  $svn_server$svn_code_path    |tee -a $mail_report_ops_log

	echo  -en "\033[31m\033[01m你确定向发布人员提供$project_name项目的Release回滚版本号$last_last_release_revision(yes/no):\033[0m"
	read input_rollback_revision_or_not
	##判断输入是否合法
	until [ "$input_rollback_revision_or_not" = "yes" ] || [ "$input_rollback_revision_or_not" = "no" ];do
        	echo -en "\033[31m\033[01m请输入yes或者no:\033[0m"
         	read input_rollback_revision_or_not
	done

	if [ "$input_rollback_revision_or_not" = "no" ];then
		echo  你没有确认回滚的版本号
	else
		echo  你已确认提供$project_name项目的Release的回滚版本号$last_last_release_revision
		echo  通知邮件已发送到$receipt_user,请等待hogwarts开发人员执行发布上线!
		###更新上次发布版本号为回滚版本号
		echo $last_last_release_revision >  $last_revision_code_log 
		###更新测试提供版本号为回滚版本号
		echo $last_last_release_revision >  $tmp_current_revision_code_log
		cat   $mail_report_ops_log |/usr/local/mutt/bin/mutt -s $mail_tittle $receipt_user
	fi
else
	echo 你选择不进行代码回滚版本号重置操作，检查是否需要对redis进行操作...
fi

##########################################redis操作
##获取用户输入
echo -en "\033[31m\033[01m 2、此次发布是否要执行redis操作(yes/no):\033[0m"
read input_redis_or_no
##判断输入是否合法
until [ "$input_redis_or_no" = "yes" ] || [ "$input_redis_or_no" = "no" ];do
         echo -en "\033[31m\033[01m请输入yes或者no:\033[0m"
         read input_redis_or_no
done


###redis操作子程序
function sub_redis_operation()
{
        echo "请从下表选择要连接redis端口实例的编号"
        echo "[1] > 192.168.0.19:6379 数据"
        echo "[2] > 192.168.0.19:6380 sessionA"
        echo "[3] > 192.168.0.19:6381 sessionC"
        echo -en "\033[31m\033[01m请输入要连接redis端口编号(quit为退出redis命令行):\033[0m"
        read input_redis_select
        ##判断输入是否合法
        until [ "$input_redis_select" = "1" ] || [ "$input_redis_select" = "2" ] || [ "$input_redis_select" = "3" ];do
        echo -en "\033[31m\033[01m  输入不合法,请重新输入:\033[0m"
        read input_redis_select
        done
        ##连接相应redis
        if   [ "$input_redis_select" = "1" ] ;then
               $redis_cmd_6379
        elif [ "$input_redis_select" = "2" ] ;then
               $redis_cmd_6380
        elif [ "$input_redis_select" = "3" ] ;then
               $redis_cmd_6381
        fi

        ##判断用户是否继续执行其他redis操作
        echo -en "\033[32m\033[01m是否要继续执行其他redis实例操作(yes/no):\033[0m"
        read input_redis_continue
        ##判断输入是否合法
        until [ "$input_redis_continue" = "yes" ] || [ "$input_redis_continue" = "no" ];do
                echo -en "\033[31m\033[01m请输入yes或者no:\033[0m"
        read input_redis_continue
        done
}

###发布是否要执行redis操作处理
if [ "$input_redis_or_no" = "yes" ];then
        sub_redis_operation
        while [ "$input_redis_continue" = "yes" ];do
                sub_redis_operation
        done
else
        echo "没有redis操作要执行..."
fi

echo 运维操作流程结束，退出系统...
exit


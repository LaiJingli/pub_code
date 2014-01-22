#!/bin/sh

######################
#测试人员填写发布版本号
#
######################

release_user=`echo $1`

###定义项目名称(目标服务器/var/www下的web发布项目名称)
project_name=Hogwarts

###svn服务器路径
svn_server=http://svn.github.com
##svn服务器发布源
svn_code_path=/hogwarts.new/release/


log_time="$(date +%Y'年'%m'月'%d'日'%H':'%M':'%S)"
today=$(date +%Y%m%d)
log_path=/backup/autoshell/chroot/$project_name/logs/
last_revision_code_log=${log_path}last_revision_code_${project_name}.log
tmp_current_revision_code_log=${log_path}tmp_current_revision_code_${project_name}.log
receipt_user=362560701@qq.com
#mail_tittle="测试搜狐邮箱是否能收到邮件"
mail_tittle="【通知:线上${project_name}有新版本可以发布】_by_${release_user}_${today}"
mail_report_tester_log=$log_path${today}_mail_report_tester_${project_name}.log
###生成发布报告的头部信息
echo 发布项目名:$project_name                |tee     $mail_report_tester_log
echo 源svn路径 :$svn_server$svn_code_path    |tee -a  $mail_report_tester_log
echo 测试人:$release_user                    >> $mail_report_tester_log
echo 操作时间:$log_time                      >> $mail_report_tester_log
echo                                         >> $mail_report_tester_log
echo "hi,Hogwarts
         测试同事($release_user)已经提供了$project_name项目可以线上发布的release版本号，请登录发布系统执行发布，本次发布详情如下："  >> $mail_report_tester_log
echo                                         >> $mail_report_tester_log

##查询svn版本库该项目的最高版本号
biggest_revision_code=`/usr/bin/svn info $svn_server$svn_code_path|grep "Revision:"|awk '{print $2}'`
##查询上次发布版本号
last_revision_code=`cat   $last_revision_code_log`
#向用户提示上次发布和当前最高版本号
echo $project_name上次发布code版本号: $last_revision_code    |tee -a $mail_report_tester_log
echo $project_name当前最高code版本号: $biggest_revision_code |tee -a $mail_report_tester_log
##获取用户输入
echo  -en "\033[31m\033[01m请输入要发布$project_name项目的Release版本号: \033[0m"
read input_revison_code
##判断输入是否合法
until [ "$input_revison_code" -ge "$last_revision_code" ] && [ "$input_revison_code" -le "$biggest_revision_code" ];do 
	echo -en "\033[31m\033[01m只有版本号大于等于上次发布版本号且小于等于版本库最高版本号时才执行发布,请重新输入：\033[0m"
	read input_revison_code
done

current_revision_code=`echo $input_revison_code`
##绿色提示
echo -e "\033[32m\033[01m你要发布的code版本号是:$current_revision_code \033[0m"


echo $project_name可以发布的测试通过的版本号: $current_revision_code >> $mail_report_tester_log
echo |tee -a $mail_report_tester_log
last_revision_code=`expr $last_revision_code + 1`
echo "一、本次可以发布的code版本号和上次发布版本号($last_revision_code:$current_revision_code)之间将要解决如下jira中的问题:" |tee -a $mail_report_tester_log
echo $last_revision_code
#jira_issue_id_set=`svn log -r $last_revision_code:$current_revision_code  $svn_server$svn_code_path|grep -v ^r|grep -v ^-|grep -v ^$|grep -v ^.|grep -v ^.|grep -v ^Merged|awk '{print $1}'|sort|uniq`
pkey=`mysql -uproxy18 -p'test' -P22 -h12.65.148.6 --disable-column-names   jira_5 -e "select pkey from  project;"|awk '{printf "^"$1"|"}'|sed 's/|$//'`
jira_issue_id_set=`svn log -r $last_revision_code:$current_revision_code  $svn_server$svn_code_path|grep -iE "$pkey"|awk '{print $1}'|sort|uniq`
issue_conuter=0
for jira_issue_id in $jira_issue_id_set;do
	issue_conuter=$[$issue_conuter+1]
	echo -n "$issue_conuter、"|tee -a $mail_report_tester_log
	jira_info=`mysql -uproxy18 -p'test' -P22 -h12.65.148.6 jira  -e "select pkey,REPORTER,ASSIGNEE,SUMMARY,DESCRIPTION  from jiraissue where pkey='$jira_issue_id'  limit 1;"`
	issue_info_sum=`echo $jira_info|awk '{print "问题号:http://192.168.1.121:8085/browse/"$6 "\n";print "报告人:"$7;print "经办人:"$8 ;print "问题摘要:"$9 ;print "问题描述:"$10}'`
	echo $issue_info_sum |tee -a $mail_report_tester_log
done

echo |tee -a $mail_report_tester_log
echo "二、本次可以发布的code发布和上次发布版本号($last_revision_code:$current_revision_code)之间svn log信息:"|tee -a $mail_report_tester_log
svn log -r $last_revision_code:$current_revision_code  $svn_server$svn_code_path    |tee -a $mail_report_tester_log

echo  -en "\033[31m\033[01m你确定向发布人员提供测试通过的可以在线发布$project_name项目的Release版本号$current_revision_code(yes/no):\033[0m"
read input_pre_revision_or_not
##判断输入是否合法
until [ "$input_pre_revision_or_not" = "yes" ] || [ "$input_pre_revision_or_not" = "no" ];do
         echo -en "\033[31m\033[01m请输入yes或者no:\033[0m"
         read input_pre_revision_or_not
done

if [ "$input_pre_revision_or_not" = "no" ];then
	echo  你没有确认测试通过的版本号
else
	echo  你已确认提供$project_name项目的Release版本号$current_revision_code
	echo  通知邮件已发送到$receipt_user,请等待hogwarts执行发布上线!
	echo  $current_revision_code > $tmp_current_revision_code_log 
	cat   $mail_report_tester_log |/usr/local/mutt/bin/mutt -s $mail_tittle $receipt_user
fi



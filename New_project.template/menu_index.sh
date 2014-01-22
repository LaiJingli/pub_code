echo "你已进入线上发布系统..."
passwd_file_tester=/backup/autoshell/chroot/passwd_tester.txt
passwd_file_dev=/backup/autoshell/chroot/passwd_dev.txt 
passwd_file_ops=/backup/autoshell/chroot/passwd_ops.txt


###add by lai for test script
##screen store dir
year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)
screen_dir=/backup/autoshell/chroot/log/$year/$month/

if [ ! -d "$screen_dir" ];then
        mkdir -p $screen_dir
#        chmod 777 -R $screen_dir
fi
### for screen record and broadcast share desktop 
login_time=$(date +%Y%m%d%H%M)



###查询用户名子程序($1:username)
function sub_user_select()
{
	user_select=`cat $passwd_file|awk -F: '{print $1}'| grep ^$1$`
	#判断用户是否存在,0为存在，1为不存在
	if [ "$user_select" = "" ];then
		return 1	
	else
		return 0
	fi
}


###查询密码子程序($1:username,$2:newpasswd)
function sub_passwd_select()
{
        if [ "$2" != "" ];then
                input_passwd_md5=`echo $2|md5sum|awk '{print $1}'`
                passwd_select=`cat $passwd_file|grep ^$1|awk -F: '{print $2}'`
                #判断密码是否一致,0为一致，1为不一致
                if [ "$passwd_select" = "$input_passwd_md5" ];then
                        return 0
                else
                        return 1
                fi
        else
                echo passwd null
                return 1
        fi
}


###修改密码子程序($1:username,$2:passwd)
function sub_passwd_change()
{
	input_new_passwd_md5=`echo $2|md5sum|awk '{print $1}'`
	old_passwd_md5_select=`cat $passwd_file|grep ^$1|awk -F: '{print $2}'`
	sed -i s/$1:$old_passwd_md5_select/$1:$input_new_passwd_md5/ $passwd_file                
	echo $1 passwd change ok
	return 0
}




###发布子程序($1:username,$2:usertype)
function sub_release()
{

	##project list
	#以下为需要测试、开发配合完成发布的项目
	p[1]=Hogwarts_online_test
	p[2]=Notify_ops_to_excute_release_doc
	p[3]=192.168.10.18_DB_release
	p[4]=192.168.10.12_DB_release
	p[5]=Sphin
	p[6]=Hogwa
	p[7]=BabySi
	p[8]=Bod
	p[9]=Workf
	p[10]=Report

	project_total_num=10

	####判断是否有配置文件需要发布
	root_dir=/backup/autoshell/chroot
	###svn服务器路径
	svn_server=http://svn.github.com
	##svn服务器发布源
	svn_conf_path=/wei-doc/平台组/系统文档/发布文档/平台配置文件/production
        ##查询svn版本库该项目的最高版本号
        biggest_revision_conf=`/usr/bin/svn info $svn_server$svn_conf_path|grep "Revision:"|awk '{print $2}'`
	
	echo 正在查询是否有配置文件更新,请稍后...
	for ((i=6;i<=$project_total_num;i++)) do
		##查询上次发布版本号
		last_revision_conf=`cat  $root_dir/${p[$i]}/logs/last_revision_conf_${p[$i]}.log`
		##将配置文件最高版本号和上次发布版本号的diff信息保存到文件
		svn diff -r $last_revision_conf:$biggest_revision_conf 	$svn_server$svn_conf_path/${p[$i]} > $root_dir/${p[$i]}/logs/tmp_conf_diff_${p[$i]}.log
	done



        echo    "----------------------------------------------"
        echo    "---     请从下表选择要发布项目的编号      ----"
	echo -e "--- (1)\033[33m\033[05m棕色闪烁\033[0m表示该项目该版本号可发布   ----"
	echo -e "--- (2)\033[32m\033[05m绿色闪烁\033[0m表示有配置文件更新可发布   ----"
	echo    "--- (3)无闪烁提示表示当前没有发布         ----"
        echo    "----------------------------------------------"

		echo -e "[1] > ${p[1]} (线上A端测试环境，不需要测试填写版本号，自动按当前最高版本号发布，公网IP 210.14.134.101，只能在公司通过ip访问该测试环境)"
		echo -e "\033[32m\033[01m========================================= 以上为A端线上测试环境A16================================================\033[0m"
		echo 
		echo -e "[2] > ${p[2]} (通知运维手工执行发布文档:如修改crontab、NFS mount、修改nginx配置文件、手工执行脚本等)"
		echo -e "[3] > ${p[3]} (只能执行平台Babysitter,cpcv2,workflow库的sql发布)"
		echo -e "[4] > ${p[4]} (只能执行平台cpcbi,dingshi库的sql发布)"
		echo -e "[5] > ${p[5]} (只发conf文件、重建索引)"
		echo -e "\033[32m\033[01m-------------------------- 以上4个项目仅需开发童鞋执行，不需要测试、运维童鞋操作 ------------------------\033[0m"
		echo
	for ((i=6;i<=$project_total_num;i++)) do
		##显示项目列表
	        echo -ne "[$i] > ${p[$i]} "
		##显示该项目是否测试通过的代码可以发布，棕色闪烁
		echo -ne "\033[33m\033[05m `cat $root_dir/${p[$i]}/logs/tmp_current_revision_code_${p[$i]}.log`\033[0m"
		##显示该项目是否有配置文件可以发布，绿色闪烁
		if [ -s $root_dir/${p[$i]}/logs/tmp_conf_diff_${p[$i]}.log ];then 
			echo -e "\033[32m\033[05m 有配置文件[$biggest_revision_conf]可发布\033[0m"
		else
			echo
		fi
	done       
 
	echo -en "\033[31m\033[01m请输入要发布的项目编号(输入exit退出发布系统):\033[0m"
        read input_project
        ##判断输入是否合法,控制菜单选项
        until [ "$input_project" -ge "1" ] && [ "$input_project" -le "$project_total_num" ] || [ "$input_project" = "exit" ];do
                echo -en "\033[31m\033[01m  输入不合法,请重新输入:\033[0m"
                read input_project
        done

	if [ "$input_project" = "exit" ];then
		echo 2秒后退出发布系统...
		sleep 2
		exit
	fi	

	##根据用户输入确定相应项目的发布脚本
	project_name=${p[$input_project]}
	##发布脚本类型
	release_script_tmplate_tester=/backup/autoshell/chroot/$project_name/auto_shell/auto_release_${project_name}_tester.sh
	   release_script_tmplate_dev=/backup/autoshell/chroot/$project_name/auto_shell/auto_release_${project_name}_dev.sh
	   release_script_tmplate_ops=/backup/autoshell/chroot/$project_name/auto_shell/auto_release_${project_name}_ops.sh

	##根据用户类型(开发、测试、运维)选择相应的执行脚本
        if   [ $2 = "1" ] ;then  /usr/bin/script -q -a -f -c "$release_script_tmplate_tester $1" -t 2>$timing_log $screnn_log
        elif [ $2 = "2" ] ;then  /usr/bin/script -q -a -f -c "$release_script_tmplate_dev    $1" -t 2>$timing_log $screnn_log
	elif [ $2 = "3" ] ;then  /usr/bin/script -q -a -f -c "$release_script_tmplate_ops    $1" -t 2>$timing_log $screnn_log
	fi


        ##判断用户是否继续发布项目\033[32m\033[01m
        echo -en "\033[32m\033[01m是否要继续其他项目操作(yes/no):\033[0m"
        read input_release_continue
        ##判断输入是否合法
        until [ "$input_release_continue" = "yes" ] || [ "$input_release_continue" = "no" ];do
                echo -en "\033[31m\033[01m  请输入yes或者no:\033[0m"
                read input_release_continue
        done
        return
}


######################################################################################################
echo "注意：在使用本系统之前请务必熟悉本系统的使用，本系统使用说明文档:http://192.168.1.121:8095/pages/viewpage.action?pageId=7864527"

echo
echo -e "!!!\033[31m\033[01m重要:进入本系统后，请严格按照屏幕提示操作，任何时候都不能按ctrl+d强行终止，强行终止可能会引发不可预知的严重问题,谨记\033[0m!!!"

echo
echo "---------------------------------------"
echo "---  请从下表选择要发布执行人类型  ----"
echo "---------------------------------------"
echo "[1] > 测试人员（填写测试通过可以发布的release版本号）"
echo "[2] > 开发人员（执行发布操作）"
echo "[3] > 运维人员（代码回滚、及发布异常处理）"

##防止用户ctrl+c 中断程序
trap 'echo;echo -e "\033[31m\033[01m警告:用户不能通过 Ctrl-C 强制终止程序的运行!请严格按照系统提示操作\033[0m"' INT
###输入
echo -en "\033[31m\033[01m请选择发布执行人类型(输入exit退出发布系统):\033[0m"
read  input_user_type
##判断输入是否合法
until [ "$input_user_type" = "1" ] || [ "$input_user_type" = "2" ] || [ "$input_user_type" = "3" ] || [ "$input_user_type" = "exit" ];do
	echo -en "\033[31m\033[01m  输入不合法,请重新输入:\033[0m"
	read input_user_type
done
if    [ "$input_user_type" = "1" ];then
	passwd_file=$passwd_file_tester
elif  [ "$input_user_type" = "2" ];then
	passwd_file=$passwd_file_dev
elif  [ "$input_user_type" = "3" ];then
	passwd_file=$passwd_file_ops
else
	echo 2秒后退出发布系统...
	sleep 2
	exit
fi


###输入发布人用户名
echo -en "\033[31m\033[01m请输入发布人用户名(输入exit退出发布系统):\033[0m"
read input_user
sub_user_select $input_user
result=$?
##判断输入是否合法
until [ "$result" = "0" ] || [ "$input_user" = "exit" ] ;do
        echo -en "\033[31m\033[01m用户不存在:\033[0m"
        read input_user
        sub_user_select $input_user
        result=$?
done
if [ "$input_user" = "exit" ];then 
	echo 2秒后退出发布系统...
	sleep 2
	exit
fi



###输入密码
echo -en "\033[31m\033[01m请输入密码:\033[0m"
read -s input_passwd
echo
sub_passwd_select $input_user $input_passwd
passwd_result=$?
##判断输入是否合法
until [ "$passwd_result" = "0" ] || [ "$input_passwd" = "exit" ];do
        echo -en "\033[31m\033[01m密码不正确:\033[0m"
        read -s input_passwd
        echo
        sub_passwd_select $input_user $input_passwd
        passwd_result=$?
done

if [ "$input_passwd" = "exit" ];then
	echo 2秒后退出发布系统...
	sleep 2
	exit
fi


####判断是否修改密码(yes修改，no直接发布)
#echo -en "\033[32m\033[01m是否要修改密码(yes修改，no直接进入发布系统):\033[0m"
#read input_change_passwd_or_not
###判断输入是否合法
#until [ "$input_change_passwd_or_not" = "yes" ] || [ "$input_change_passwd_or_not" = "no" ];do
#	echo -en "\033[31m\033[01m  请输入yes或者no:\033[0m"
#	read input_change_passwd_or_not
#done
#if [ "$input_change_passwd_or_not" = "yes" ];then
#	echo -en "\033[32m\033[01m请输入新密码:\033[0m"	
#	read -s input_newpasswd
#	echo
#	echo -en "\033[32m\033[01m请再次输入新密码:\033[0m"
#	read -s input_newpasswd_confirm
#	##判断输入是否一致,不为空
#	until [ -n "$input_newpasswd" ] && [ "$input_newpasswd" = "$input_newpasswd_confirm" ];do
#		echo 
#		echo 2次密码输入不一致或者为空密码,请重新输入!
#		echo -en "\033[32m\033[01m请输入新密码:\033[0m" 
#		read -s input_newpasswd
#		echo
#		echo -en "\033[32m\033[01m请再次输入新密码:\033[0m"
#		read -s input_newpasswd_confirm
#		echo 
#	done 
#	sub_passwd_change $input_user $input_newpasswd
#fi

#echo "在确认所有人员的账号均为复杂密码后，再开启发布系统，exit..."
#exit

###########################################执行部分
##发布过程及发布录屏参数
release_user=`echo $input_user`
screnn_log=${screen_dir}${release_user}_screen_${login_time}.log
timing_log=${screen_dir}${release_user}_screen_${login_time}.date
###重复执行发布过程
sub_release $release_user $input_user_type
while [ "$input_release_continue" = "yes" ];do
	sub_release $release_user $input_user_type
done

echo "操作完成,2秒后退出系统..."
sleep 2
echo "Bye!"



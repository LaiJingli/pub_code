Open source code publish system for php coede & configre file & mysql in small and midiem company.
注：本项目路径为生产环境路径，可根据实际情况情况自定义。

一、功能：通本本发布脚本可以完成所有发布操作。Edit

二、本发布脚本使用标准要求：Edit
1、需要手工执行的发布文档：

（1）必须放在http://svn.github.com/wei-doc/平台组/系统文档/发布文档/$(date +%Y)/

（2）必须为UTF8或者GBK编码

（3）必须写明要执行的具体操作

 

2、sql脚本：

（1）必须放在http://svn.github.com/wei-doc/平台组/系统文档/发布文档/$(date +%Y)/

（2）sql脚本名必须以.sql为后缀

（3）sql脚本名必须为UTF8或者GBK编码

（4）sql脚本开始中必须使用use db

（5）每条sql语句后必须加分号(;)

（6）sql脚本不能含有drop语句

（7）sql脚本不能含有select * 语句

（8）一个sql脚本只能存放一个db的sql语句

（9）注释行必须以井号（#）开头

（10）sql脚本在主库执行

 

3、配置文件：

（1）必须放在http://svn.github.com/wei-doc/平台组/系统文档/发布文档/平台配置文件/  相应环境目录下

（2）所有环境的配置文件修改必须只能在svn上修改，然后通过发布程序同步到服务器

 

4、code发布：

（1）code必须存在svn上

（2）每次发布必须填写版本号

 

5、发布人执行人：一般为project leader或由其指定

三、进入发布系统的方法Edit
1、线上：ssh堡垒机-->选择192.168.0.188  (平台发布专用机)设备-->选择以www用户-->输入用户名密码-->执行发布流程

2、线下：公司内网直接用自己的账号ssh连接192.168.100.146，即可进入线下发布系统，执行发布

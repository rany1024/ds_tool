# ds_tool
这是一个基于shell的路径管理/快速切换工具

## 1. 简易的入门手册

step 1. 通过**source ds.sh install**安装它(其实就是在/home/your_user/.bashrc中加载ds.sh)

step 2. 创建一个路径表
```sh
ds -a first_list    #创建并进入first_list表
ds -s               #列出所有路径表
ds -s 1             #进入序号为1的路径表
```

step 3. 在表中添加一条路径
```sh
da               #添加当前路径(pwd)
da  /tmp         #添加/tmp路径
da  /home /mnt   #同时添加多个路径
```

step 4. 进入表中的某个路径
```
ds      #列出当前表中所有路径
ds 1    #cd到序号为1的路径中
```

step 5. 管理表中的路径
```
dd 2      #删除表中序号为2的路径
dd 4 5 1  #删除多条路径
dd all    #清空表中的路径

di 2 1    #将序号2的路径移动到序号1之前
di 1 5    #将序号1的路径移动到序号5之前
```

# 大概就这些啦, 具体参数格式可以参考help.txt

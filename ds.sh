#!bash
# 


ds_path="`cd $(dirname $BASH_SOURCE);pwd;cd - > /dev/null`"
conf="$ds_path/.dir.list0"
conf_path=$ds_path/list


function get_conf_file()
{
    conf_file=`readlink $conf`
    echo "${conf_file:-$conf_path/default.list}"
}

function get_conf_name()
{
    echo "$(get_conf_file)" |  sed 's|^.*/\(.*\)\.list$|\1|'
}

function set_conf()
{
    if [ ! -d $conf_path ]; then
        mkdir -p $conf_path
    fi

    if [ ! "a$1" = "a" ]; then
        rm -f $conf 2>/dev/null
        ln -s "$conf_path/$1.list" $conf
        if [ ! -f $(get_conf_file) ]; then
            touch $(get_conf_file)
        fi
        ds_into -s
    fi
}

function create_conf()
{
    num=$(get_conf_list | awk "\"$1\"==\$3 {print \$2}")
    if [ "a$num" = "a" ]; then
        set_conf $1
    else
        echo "[$1] existed, enter in!"
        select_conf $num
    fi
}

function select_conf()
{
    conf_name=$(get_conf_list | awk "\$2==\"$1\" || \$3==\"$1\" {print \$3}")
    if [ "a$conf_name" = "a" ]; then
        echo "index [$1] not find!"
    else
        set_conf $conf_name
    fi

}

function get_conf_list()
{
    find $conf_path -name "*.list" | sort | sed 's|^.*/\(.*\)\.list$|\1|' | awk "{if(\$1==\"$(get_conf_name)\") printf(\"> %2d  %s\n\", NR, \$1); else printf(\"- %2d  %s\n\", NR, \$1);}"
}

function del_conf()
{
    conf_name=$(get_conf_list | awk "\$2==\"$1\" {print \$3}")
    if [ ! "a$conf_name" = "a" ]; then
        tmp_conf_name=$(get_conf_name)
        /bin/rm "$conf_path/$conf_name.list"
        /bin/rm $conf 2>/dev/null
        if [ "a$conf_name" = "a$tmp_conf_name" ]; then
            new_conf=`get_conf_list | head -1 | awk '{print $3}'`
        else
            new_conf=$tmp_conf_name
        fi
        if [ ! "a$new_conf" = "a" ]; then
            set_conf $new_conf
        fi
    else
        echo "no such conf index: $1"
        ds_into -s
    fi
}

function guide_ds_help()
{
   cat $ds_path/help.txt 
}

function guide_ds_into()
{
    guide_ds_help
}

function ds_into()
{
    if [ "a$1" = "a" ]; then
        #ret=`awk '{printf("%3d   %s\n", NR, $1)}' $conf`
        now_dir=`pwd`
        ret=$(awk "{if(\$1==\"$now_dir\") printf(\"> %2d  %s\n\", NR, \$1); else printf(\"- %2d  %s\n\", NR, \$1);}" $conf)
        #ret=`echo "$ret" | sed -e "s|^ \(.*\)   \($now_dir\)$|\*\1\   \2|g"`
        echo "[ $(get_conf_name) ]"
        echo "$ret"
    elif [[ $1 = *-* ]]; then
        if [ "a$1" = "a-a" ]; then
            if [ "a$2" = "a" ]; then
                guide_ds_into
            else
                create_conf $2
            fi
        elif [ "a$1" = "a-s" ]; then
            if [ "a$2" = "a" ]; then
                get_conf_list
            else
                select_conf $2
            fi
        elif [ "a$1" = "a-d" ]; then
            if [ "a$2" = "a" ]; then
                echo "ds -d <index | -all>"
                get_conf_list
            else
                if [ "a$2" = "a-all" ]; then
                    find $conf_path -name "*.list" | xargs rm -f
                    rm -f $conf
                else
                    del_conf $2
                fi
            fi
        elif [ "a$1" = "a-help" ]; then
            guide_ds_help
        else
            guide_ds_into
        fi
    else
        dir=`awk 'NR=='$1'' $conf`
        if [ "a$dir" = "a" ]; then
            guide_ds_into
        else
            cd $dir
        fi
        ds_into
    fi
}

function ds_add()
{
    dir="$*"
    if [ "a$dir" = "a" ]; then
        dir=`pwd`
    fi

    list=`echo "$dir" | awk '{for(i=1;i<=NF;i++) print $i}' | uniq`
    for i in $list; do
        dir=""
        if [ ! -d $i ]; then
            echo "Not dir [$i] !"
        else
            dir=`cd $i; pwd; cd - > /dev/null`
            #num=`grep -n "^$dir$" "$conf" | awk '{print $1}'`
            num=$(awk "\"$dir\"==\$1 {print FNR}" "$conf")
            if [ "a$num" = "a" ]; then
                echo "$dir" >> $(get_conf_file)
            else
                echo "[$dir] existed in $num!"
            fi
        fi
    done
    ds_into
} 

function ds_insert()
{
    if [ "$1" -gt 0 -a "$2" -gt 0 ]; then
        if [ ! "a$1" = "a$2" ]; then
            new_line="$(($1<$2?$2-1:$2))"
            src=`awk "NR==$1" $conf`
            sed -i "$1 d" $(get_conf_file)
            sed -i ''$new_line'i'$src'' $(get_conf_file)
            ds_into
        fi
    else
        echo "da <src_index> <dst_index>"
    fi
}

function ds_delete()
{
    if [ "a$1" = "a" ]; then
        echo "dd <index | all>"
    elif [ "a$1" = "aall" ]; then
        echo -e '\c' > $(get_conf_file)
    else
        list=`echo "$*" | awk '{for(i=1;i<=NF;i++) print $i}' | sort -unr`
        echo removed $list
        for i in $list; do
            sed -i "$i d" $(get_conf_file)
        done
    fi
    ds_into
}

# start__________________________________________
tmp=$(awk "/source .*ds\.sh/ {print FNR}" ~/.bashrc)
if [ "a$1" = "ainstall" ];  then
    if [ "a$tmp" = "a" ]; then
        echo "source $ds_path/ds.sh" >> ~/.bashrc
        echo "ds tool install success!"
        source ~/.bashrc
    else
        echo "ds tool has been installed!"
    fi
elif [ "a$1" = "auninstall" ];then
    if [ "a$tmp" = "a" ]; then
        echo "Can't find ds tool!"
    else
        sed -i "$tmp d" ~/.bashrc
        echo "ds tool has been uninstalled!"
        alias ds='ds'
        alias da='da'
        alias di='di'
        alias dd='dd'
        source ~/.bashrc
    fi
elif [ "a$1" = "a" ]; then
    alias ds='ds_into'     #dir list ls (dirs)
    alias da='ds_add'    #dir list add
    alias di='ds_insert'    #dir list insert 
    alias dd='ds_delete' #dir list add

    #echo conf: $conf
    #echo conf_name: $(get_conf_name)
    #echo -------------------------
    ds_into -a $(get_conf_name)
else
    echo "ds.sh [install | uninstall]"
fi


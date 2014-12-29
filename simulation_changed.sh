#! /bin/bash
#author: Atsuhiko Murakami

# ### シミュレーションは以下の4種類行う ###
# 1, UPPERのみ
# 2, LOWERのみ
# 3, UPPER -> LOWER
# 4 LOWER -> UPPER
#
# 1,2はsomaでの脱分極が2mV以上というヒューリスティックスの条件を調べるため


#引数 1: 形態.hoc
#    2: シナプス.hoc 
#    3: UPPER -> LOWER データ出力ファイル名
#    4: LOWER -> UPPER データ出力ファイル名
#    5: UPPERのみのテストデータ出力ファイル名
#    6: LOWERのみのテストデータ出力ファイ名ル
#    7: FIRST_ACTIVATE_TIME,
#    8: DELTA_T,
#    9: SIM_TIME,
#   10: V_INIT

MORPHO_FILE=$1
SYNAPSE_FILE=$2
#NEURONは実行するhocがあるディレクトリをワーキングディレクトリにするらしいので、この相対的なパス"../"を付けている
UP_LW_FILE="../"$3
LW_UP_FILE="../"$4
UP_TEST_FILE="../"$5
LW_TEST_FILE="../"$6
FIRST_ACTIVATE_TIME=$7
DELTA_T=$8
SIM_TIME=$9
V_INIT=${10} #$10だと、{$1}0に解釈されるので注意
ID_IND=${11}

ECHO_FLAG=false #引数を表示するか
SIMUL_HOC_DIR="./SimHoc/"

if $ECHO_FLAG
then
    echo MORPHO_FILE	      is $MORPHO_FILE
    echo SYNAPSE_FILE	      is $SYNAPSE_FILE
    echo UP_LW_FILE	      is $UP_LW_FILE
    echo LW_UP_FILE	      is $LW_UP_FILE
    echo UP_TEST_FILE	      is $UP_TEST_FILE
    echo LW_TEST_FILE	      is $LW_TEST_FILE
    echo FIRST_ACTIVATE_TIME  is $FIRST_ACTIVATE_TIME
    echo DELTA_T	      is $DELTA_T
    echo SIM_TIME	      is $SIM_TIME
    echo V_INIT	      is $V_INIT
    echo ID_IND	      is $ID_IND
fi

SIM_TEMPLATE="./sim_template.hoc" #シミュレーションのひな形ファイル、このパスの指定のルールがよくわからん

SIM_UPPER_LOWER_HOC=${SIMUL_HOC_DIR}"simulation"${ID_IND}"_ul.hoc"
SIM_LOWER_UPPER_HOC=${SIMUL_HOC_DIR}"simulation"${ID_IND}"_lu.hoc"
SIM_UPPER_TEST_HOC=${SIMUL_HOC_DIR}"simulation"${ID_IND}"_test_u.hoc"
SIM_LOWER_TEST_HOC=${SIMUL_HOC_DIR}"simulation"${ID_IND}"_test_l.hoc"

IMPLEMENT_HOC=${SIMUL_HOC_DIR}"simulation"${ID_IND}"_implement_.hoc"

for file in $SIM_UPPER_LOWER_HOC $SIM_LOWER_UPPER_HOC $SIM_UPPER_TEST_HOC $SIM_LOWER_TEST_HOC $IMPLEMENT_HOC
do
    if [ -e $file ]
    then
	rm $file
    fi
done

SECOND_ACTIVATE_TIME=`expr $FIRST_ACTIVATE_TIME + $DELTA_T`
if [ $SECOND_ACTIVATE_TIME -gt $SIM_TIME ]
then
    echo "WORNING: SECOND_ACTIVATE_TIME(${SECOND_ACTIVATE_TIME}ms) is over SIM_TIME(${SIM_TIME}ms)"
fi

NOT_ACTIVATE=-100 #片方のシナプスのみをテストする場合に設定する"ありえない"時間

function simulation(){
    ###### simulationを行うファイル($hoc_file_name)を作成する関数 ######

    #引数 1, hoc_file_name
    #    2, UPPER_SYN_ACTIVATE_TIME
    #    3, LOWER_SYN_ACTIVATE_TIME
    #    4, OUTPUT_FILE

    FUNC_hoc_file_name=$1
    FUNC_upper_act_time=$2
    FUNC_lower_act_time=$3
    FUNC_output_file=$4

    echo UPPER_SYN_ACTIVATE_TIME = $FUNC_upper_act_time >> $FUNC_hoc_file_name
    echo LOWER_SYN_ACTIVATE_TIME = $FUNC_lower_act_time >> $FUNC_hoc_file_name
    echo "" >> $FUNC_hoc_file_name

#    echo "load_file(\"$MORPHO_FILE\")" >> $FUNC_hoc_file_name
#    echo "load_file(\"$SYNAPSE_FILE\")" >> $FUNC_hoc_file_name
#    echo "" >> $FUNC_hoc_file_name

    echo "strdef output_file" >> $FUNC_hoc_file_name
    echo "output_file = \"$FUNC_output_file\"" >> $FUNC_hoc_file_name
    echo "" >> $FUNC_hoc_file_name

    echo "tstop = " $SIM_TIME >> $FUNC_hoc_file_name
    echo "V_INIT = "$V_INIT >> $FUNC_hoc_file_name
    echo "" >> $FUNC_hoc_file_name

    cat $SIM_TEMPLATE >> $FUNC_hoc_file_name

#    nrniv $FUNC_hoc_file_name  1> /dev/null 2> /dev/null #NEURONからの出力を捨てているので、もしエラーになってたら困る
}

# _____ _____ ____ _____ 
#|_   _| ____/ ___|_   _|
#  | | |  _| \___ \ | |  
#  | | | |___ ___) || |  
#  |_| |_____|____/ |_|  
#                        
#  ____ ___ __  __ _   _ _        _  _____ ___ ___  _   _ 
#/ ___|_ _|  \/  | | | | |      / \|_   _|_ _/ _ \| \ | |
#\___ \| || |\/| | | | | |     / _ \ | |  | | | | |  \| |
# ___) | || |  | | |_| | |___ / ___ \| |  | | |_| | |\  |
#|____/___|_|  |_|\___/|_____/_/   \_\_| |___\___/|_| \_|
#
########## UPPER のみ活性化させるシミュレーションをする ##########
simulation $SIM_UPPER_TEST_HOC $FIRST_ACTIVATE_TIME $NOT_ACTIVATE $UP_TEST_FILE

########## LOWERのみ活性化させるシミュレーションをする ##########
simulation $SIM_LOWER_TEST_HOC $NOT_ACTIVATE $FIRST_ACTIVATE_TIME $LW_TEST_FILE

#引数 1, hoc_file_name
#    2, UPPER_SYN_ACTIVATE_TIME
#    3, LOWER_SYN_ACTIVATE_TIME
#    4, OUTPUT_FILE


# __  __    _    ___ _   _ 
#|  \/  |  / \  |_ _| \ | |
#| |\/| | / _ \  | ||  \| |
#| |  | |/ ___ \ | || |\  |
#|_|  |_/_/   \_\___|_| \_|
#                          
# ____ ___ __  __ _   _ _        _  _____ ___ ___  _   _ 
#/ ___|_ _|  \/  | | | | |      / \|_   _|_ _/ _ \| \ | |
#\___ \| || |\/| | | | | |     / _ \ | |  | | | | |  \| |
# ___) | || |  | | |_| | |___ / ___ \| |  | | |_| | |\  |
#|____/___|_|  |_|\___/|_____/_/   \_\_| |___\___/|_| \_|
#
########### UPPER -> LOWERのシミュレーションをする ##########
simulation $SIM_UPPER_LOWER_HOC $FIRST_ACTIVATE_TIME $SECOND_ACTIVATE_TIME $UP_LW_FILE

########## LOWER -> UPPERのシミュレーションをする ##########
simulation $SIM_LOWER_UPPER_HOC $SECOND_ACTIVATE_TIME $FIRST_ACTIVATE_TIME $LW_UP_FILE

# IMPLEMENT FILE

echo "load_file(\"${MORPHO_FILE}\")" >> $IMPLEMENT_HOC
echo "printf(\"end load morpho\\n\")" >> $IMPLEMENT_HOC
echo "load_file(\"${SYNAPSE_FILE}\")" >> $IMPLEMENT_HOC
echo "printf(\"end load synapse\\n\")" >> $IMPLEMENT_HOC

echo "load_file(\"${SIM_UPPER_TEST_HOC}\")" >> $IMPLEMENT_HOC
echo "printf(\"end load upper test\\n\")" >> $IMPLEMENT_HOC
echo "load_file(\"${SIM_LOWER_TEST_HOC}\")" >> $IMPLEMENT_HOC
echo "printf(\"end load lower test\\n\")" >> $IMPLEMENT_HOC

echo "load_file(\"${SIM_UPPER_LOWER_HOC}\")" >> $IMPLEMENT_HOC
echo "printf(\"end load upper-lower\\n\")" >> $IMPLEMENT_HOC
echo "load_file(\"${SIM_LOWER_UPPER_HOC}\")" >> $IMPLEMENT_HOC
echo "printf(\"end load lower-upper\\n\")" >> $IMPLEMENT_HOC

nrniv $IMPLEMENT_HOC 1> /dev/null 2> /dev/null #NEURONからの出力を捨てているので、もしエラーになってたら困る


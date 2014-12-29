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
#   12: 個体の識別ID
#   10: celsiusなどのパラメータ

MORPHO_FILE=$1
SYNAPSE_FILE=$2
UP_LW_FILE=$3
LW_UP_FILE=$4
UP_TEST_FILE=$5
LW_TEST_FILE=$6
FIRST_ACTIVATE_TIME=$7
DELTA_T=$8
SIM_TIME=$9
V_INIT=${10} #$10だと、{$1}0に解釈されるので注意
ID_IND=${11}
SIM_PARAMETER=${12}
DIR_SIMHOC=${13}

ECHO_FLAG=false #引数を表示するか

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
    echo DIR_SIMHOC   is $DIR_SIMHOC
fi

SIM_TEMPLATE="sim_template.hoc" #シミュレーションのひな形ファイル

SIM_HOC=${DIR_SIMHOC}"simulation"${ID_IND}".hoc"

for file in ${SIM_HOC}
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

echo "objref UPPER_SYN_ACTIVATE_TIME" >> ${SIM_HOC}
echo "objref LOWER_SYN_ACTIVATE_TIME" >> ${SIM_HOC}

echo "UPPER_SYN_ACTIVATE_TIME = new Vector()" >> ${SIM_HOC}
echo "LOWER_SYN_ACTIVATE_TIME = new Vector()" >> ${SIM_HOC}

#シミュレーションはupper_test lower_test upper_lower lower_upperの順に行う
echo "UPPER_SYN_ACTIVATE_TIME.append(${FIRST_ACTIVATE_TIME},${NOT_ACTIVATE},${FIRST_ACTIVATE_TIME},${SECOND_ACTIVATE_TIME})" >> ${SIM_HOC}
echo "LOWER_SYN_ACTIVATE_TIME.append(${NOT_ACTIVATE},${FIRST_ACTIVATE_TIME},${SECOND_ACTIVATE_TIME},${FIRST_ACTIVATE_TIME})" >> ${SIM_HOC}

echo "" >> ${SIM_HOC}

echo "load_file(\"$SIM_PARAMETER\")" >> ${SIM_HOC}

echo "load_file(\"$MORPHO_FILE\")" >> ${SIM_HOC}
echo "load_file(\"$SYNAPSE_FILE\")" >> ${SIM_HOC}
echo "" >> ${SIM_HOC}

echo "strdef output_file_u" >> ${SIM_HOC}
echo "strdef output_file_l" >> ${SIM_HOC}
echo "strdef output_file_ul" >> ${SIM_HOC}
echo "strdef output_file_lu" >> ${SIM_HOC}

echo "output_file_u = \"${UP_TEST_FILE}\"" >> ${SIM_HOC}
echo "output_file_l = \"${LW_TEST_FILE}\"" >> ${SIM_HOC}
echo "output_file_ul = \"${UP_LW_FILE}\"" >> ${SIM_HOC}
echo "output_file_lu = \"${LW_UP_FILE}\"" >> ${SIM_HOC}
echo "" >> ${SIM_HOC}

echo "tstop = " $SIM_TIME >> ${SIM_HOC}
echo "" >> ${SIM_HOC}

echo "V_INIT = "$V_INIT >> ${SIM_HOC}

echo "load_file(\"$SIM_TEMPLATE\")" >> ${SIM_HOC}

nrniv ${SIM_HOC} 1> /dev/null 2> /dev/null #NEURONからの出力を捨てているので、もしエラーになってたら困る

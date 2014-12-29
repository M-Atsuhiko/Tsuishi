#! /bin/bash
#author: Atsuhiko Murakami

IS_TEST="TRUE"
se=1
dt=10
CONTAIN_CONDUCTANCES="passive"

R --vanilla --slave --args ${IS_TEST} ${se} ${dt} ${CONTAIN_CONDUCTANCES} < TREE_simulation.R

#open test.eps





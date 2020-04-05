#!/bin/bash

# Usage
# ./launch_training.sh N kimg model loss tx eval dir pt idx

if (( $# < 7 )); then
    echo "Usage: ./launch_training.sh N kimg model loss tx eval dir (kw_num) (pt) (idx)"
    exit 1
fi

N=$1
kimg=$2
model=$3 # r, t, s, a
lr=0.002
loss=$4 #'G_logistic_ns_gsreg'
tx=$5
ev=$6
dir=$7
kwn=$8 #'{"epsilon":0.01,"lambda_min":1.5,"lambda_max":1.7}'  #$8
#pt=$9
#i=$10


echo $1 $2 $3 $4 $5 $6 $7 $8 #$9 $10
echo $(hostname)
echo $CUDA_VISIBLE_DEVICES
source activate py3tf115


kw=""
if [[ $loss == "pr" ]];
then
loss='G_logistic_ns_pathreg'
elif [[ $loss == "gs" ]];
then
loss='G_logistic_ns_gsreg'
if [[ $kwn == 0 ]]; then kw='{"gs_weight":5.0}'
elif [[ $kwn == 1 ]]; then kw='{"gs_weight":10.0}'
elif [[ $kwn == 2 ]]; then kw='{"gs_weight":3.0}'
fi

elif [[ $loss == "jc" ]];
then
loss='G_logistic_ns_pathreg_jc'
if [[ $kwn == 0 ]]; then kw='{"epsilon":0.01,"lambda_min":1.5,"lambda_max":1.7}'
elif [[ $kwn == 1 ]]; then kw='{"epsilon":0.1,"lambda_min":1.5,"lambda_max":1.7}'
elif [[ $kwn == 2 ]]; then  kw='{"epsilon":0.01,"lambda_min":1.55,"lambda_max":1.65}'
elif [[ $kwn == 3 ]]; then  kw='{"epsilon":0.01,"lambda_min":1.2,"lambda_max":2.0}'
fi

elif [[ $loss == "div" ]];
then
loss='G_logistic_ns_pathreg_div'
fi

echo $loss

if [[ $(hostname) == "jb"* ]]; # RTX
then
ddir='/work/erobb/datasets/'
rdir="/work/erobb/results/$dir"
else # ARC
ddir='/work/newriver/erobb/datasets'
rdir="/work/newriver/erobb/results/$dir"
fi

pt=""
if [[ $pt == "" ]]
then
i=0
echo "automatically choosing pretrain"
if [[ $tx == "kannada"* ]]
then
pt='./pickles/eng-config-f-10M.pkl'
elif [[ $tx == "tower"* ]]
then
pt='./pickles/church-config-f.pkl'
elif [[ $tx == "bus"* ]]
then
pt='./pickles/car-config-f.pkl'
elif [[ $tx == "dog"* ]]
then
pt='./pickles/cat-config-f.pkl'
elif [[ $tx == "danbooru"* ]] || [[ $tx == "anime"* ]] || [[ $tx == "rei"* ]] || [[ $tx == "obama"* ]]
then
pt='./pickles/ffhq-config-f.pkl'
fi
fi

echo $i $pt


# Vanilla GAN baseline
if [[ $model == "v" ]]
then
cfg="config-f"
pt=""
# TGAN baseline
elif [[ $model == "t" ]]
then
cfg="config-f"
# Shift+scale baseline
elif [[ $model == "s" ]]
then
cfg="config-ss"
# Residual adapters
elif [[ $model == "r" ]]
then
cfg="config-ra"
fi


python run_training.py \
--num-gpus=1 \
--data-dir=$ddir \
--config=$cfg \
--g-loss=$loss \
--g-loss-kwargs=$kw \
--dataset-train=$tx \
--dataset-eval=$ev \
--total-kimg=$kimg \
--max-images=$N \
--resume-pkl=$pt \
--resume-kimg=$i \
--lrate-base=$lr \
--result-dir=$rdir/$tx

echo "done."

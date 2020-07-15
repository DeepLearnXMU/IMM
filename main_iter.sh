#! /bin/bash
export FLAGS_enable_parallel_graph=1
export FLAGS_sync_nccl_allreduce=1
BERT_BASE_PATH=../uncased_L-12_H-768_A-12
CHECKPOINT_PATH=./squad/checkpoints/
DATA_PATH=../data

GPU=(1 2 3 4 5)

base_train() {
    python -u base_squad.py --use_cuda true\
                       --batch_size 12 \
                       --init_pretraining_params ${BERT_BASE_PATH}/params \
                       --in_tokens false\
                       --checkpoints ${CHECKPOINT_PATH} \
                       --vocab_path ${BERT_BASE_PATH}/vocab.txt \
                       --do_train True \
                       --do_predict True \
                       --save_steps 2000 \
                       --warmup_proportion 0.1 \
                       --weight_decay  0.01 \
                       --epoch 2 \
                       --max_seq_len 512 \
                       --bert_config_path ${BERT_BASE_PATH}/bert_config.json \
                       --predict_file ${DATA_PATH}/$1_dev.raw.json \
                       --do_lower_case True \
                       --doc_stride 128 \
                       --train_file ${DATA_PATH}/$1.raw.json \
                       --learning_rate 3e-5\
                       --lr_scheduler linear_warmup_decay \
                       --skip_steps 10
    mkdir finish_base_train
}

python ./upsample.py --path ./data --domains SQuAD NewsQA TriviaQA HotpotQA NaturalQuestions
#python ./upsample.py --path ./data --domains SQuAD_small NewsQA_small TriviaQA_small HotpotQA_small NaturalQuestions_small
ALL_DOMAIN=$@

domain_num=0
for dm in $ALL_DOMAIN
do
    now_path=./$dm
    let domain_num=domain_num+1
done

idx=0
for dm in $ALL_DOMAIN
do
    DOMAIN_RAW_FILE[$idx]=./data/${dm}.4cb.raw.json
    DOMAIN_DEV_FILE[$idx]=./data/${dm}_dev.raw.json
    let idx=idx+1
done

RAW_FILE=`echo ${DOMAIN_RAW_FILE[*]}`
DEV_FILE=`echo ${DOMAIN_DEV_FILE[*]}`

echo python ./data/combine_mrc_data.py --filepaths $RAW_FILE
python ./data/combine_mrc_data.py --filepaths $RAW_FILE
mv combined_dataset ./data/All_domain.raw.json
python ./data/combine_mrc_data.py --filepaths $DEV_FILE
mv combined_dataset ./data/All_domain_dev.raw.json
python ./data/get4weight_set.py --filepaths $DEV_FILE

python split_data.py --path ./data --domains All_domain

PWD=`pwd`
saved_path=$PWD
idx=0

for dm in $ALL_DOMAIN
do
    cd $saved_path/$dm
    export CUDA_VISIBLE_DEVICES=${GPU[$idx]}
    let equal_num=domain_num-1
    base_train $dm > base_train.log &
    let idx=idx+1
done

idx=0
for dm in $ALL_DOMAIN
do
    echo $saved_path
    cd $saved_path/$dm
    while [ ! -d "./finish_base_train" ]
        do
            sleep 30
        done
    sh ./multi_iter.sh ${GPU[$idx]} $dm $idx $ALL_DOMAIN > ./iter.log &
    let idx=idx+1
done
for dm in $ALL_DOMAIN
do
    cd $saved_path/$dm
    while [ ! -d "./train_finished" ]
        do
            echo sleep!
            sleep 30
        done
done


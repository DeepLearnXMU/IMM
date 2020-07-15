#! /bin/bash
export FLAGS_enable_parallel_graph=1
export FLAGS_sync_nccl_allreduce=1
export CUDA_VISIBLE_DEVICES=$1

BERT_BASE_PATH=../uncased_L-12_H-768_A-12
CHECKPOINT_PATH=./squad/checkpoints/
DATA_PATH=../data

finetune() {
    python -u run_squad.py --use_cuda true\
                       --batch_size 12 \
                       --init_pretraining_params ${BERT_BASE_PATH}/params \
                       --in_tokens false\
                       --init_checkpoint ./squad/checkpoints/pretrain_best \
                       --checkpoints ${CHECKPOINT_PATH} \
                       --vocab_path ${BERT_BASE_PATH}/vocab.txt \
                       --do_train True \
                       --do_predict True \
                       --save_steps 4000 \
                       --warmup_proportion 0.1 \
                       --weight_decay  0.01 \
                       --epoch 2 \
                       --max_seq_len 512 \
                       --bert_config_path ${BERT_BASE_PATH}/bert_config.json \
                       --predict_file ${DATA_PATH}/$1_dev.raw.json \
                       --do_lower_case True \
                       --doc_stride 128 \
                       --train_file ${DATA_PATH}/$1.raw.json \
                       --learning_rate 1.5e-5\
                       --lr_scheduler linear_warmup_decay \
                       --skip_steps 10 \
                       --now_best_score $2
}

pretrain() {
    python -u run_squad.py --use_cuda true\
                       --batch_size 12 \
                       --init_pretraining_params ${BERT_BASE_PATH}/params \
                       --in_tokens false\
                       --checkpoints ${CHECKPOINT_PATH} \
                       --vocab_path ${BERT_BASE_PATH}/vocab.txt \
                       --do_train True \
                       --do_predict True \
                       --save_steps 500000 \
                       --warmup_proportion 0.1 \
                       --weight_decay  0.01 \
                       --epoch 1 \
                       --max_seq_len 512 \
                       --bert_config_path ${BERT_BASE_PATH}/bert_config.json \
                       --predict_file ${DATA_PATH}/All_domain_dev.raw.json \
                       --do_lower_case True \
                       --doc_stride 128 \
                       --train_file ${DATA_PATH}/All_domain.raw.json \
                       --learning_rate 1.5e-5\
                       --lr_scheduler linear_warmup_decay \
                       --skip_steps 10 \
                       --all_domain_and_weight $@
}

gen_logits() {
    python -u gen_logits.py --use_cuda true\
                       --batch_size 40 \
                       --init_pretraining_params ${BERT_BASE_PATH}/params \
                       --in_tokens false\
                       --init_checkpoint ./squad/checkpoints/step_best \
                       --checkpoints ${CHECKPOINT_PATH} \
                       --vocab_path ${BERT_BASE_PATH}/vocab.txt \
                       --do_train False \
                       --do_predict True \
                       --save_steps 1000 \
                       --warmup_proportion 0.1 \
                       --weight_decay  0.01 \
                       --epoch 1 \
                       --max_seq_len 512 \
                       --bert_config_path ${BERT_BASE_PATH}/bert_config.json \
                       --predict_file ${DATA_PATH}/$1.raw.json \
                       --do_lower_case True \
                       --doc_stride 128 \
                       --train_file ${DATA_PATH}/$1.raw.json \
                       --learning_rate 1.5e-5\
                       --lr_scheduler linear_warmup_decay \
                       --skip_steps 10
}

compute_weight() {
    python -u run_squad.py --use_cuda true\
                       --batch_size 12 \
                       --init_pretraining_params ${BERT_BASE_PATH}/params \
                       --in_tokens false\
                       --init_checkpoint ./squad/checkpoints/step_best \
                       --checkpoints ${CHECKPOINT_PATH} \
                       --vocab_path ${BERT_BASE_PATH}/vocab.txt \
                       --do_train False \
                       --do_predict True \
                       --save_steps 50000 \
                       --warmup_proportion 0.1 \
                       --weight_decay  0.01 \
                       --epoch 2 \
                       --max_seq_len 512 \
                       --bert_config_path ${BERT_BASE_PATH}/bert_config.json \
                       --predict_file ${DATA_PATH}/$1_dev.4weight.json \
                       --do_lower_case True \
                       --doc_stride 128 \
                       --train_file ${DATA_PATH}/$1.raw.json \
                       --learning_rate 1.5e-5\
                       --lr_scheduler linear_warmup_decay \
                       --skip_steps 10
}


NOW_DOMAIN=$2
NEED_ALIGN=$3
shift 3
ALL_DOMAIN=$@
BEST_SCORE=0

echo ${NOW_DOMAIN}
echo ${NEED_ALIGN}
echo ${ALL_DOMAIN}

if [[ ${NOW_DOMAIN} == SQuAD* ]]; then
WEIGHTS='0 0.46 0.26 0.01 0.27'
fi
if [[ ${NOW_DOMAIN} == NewsQA* ]]; then
WEIGHTS='0.5 0 0.24 0.01 0.25'
fi
if [[ ${NOW_DOMAIN} == HotpotQA* ]]; then
WEIGHTS='0.34 0.29 0 0.03 0.35'
fi
if [[ ${NOW_DOMAIN} == NaturalQuestions* ]]; then
WEIGHTS='0.22 0.12 0.35 0 0.31'
fi
if [[ ${NOW_DOMAIN} == TriviaQA* ]]; then
WEIGHTS='0.34 0.30 0.34 0.02 0'
fi

for idx in $(seq 1 10)
do

    echo Now in iteration ${idx}
    echo gen_logits $NOW_DOMAIN
    gen_logits $NOW_DOMAIN
    echo gen_finished!
    mkdir gen_finished${idx}
    for dm in $ALL_DOMAIN
    do
        while [ ! -d "../$dm/gen_finished$idx" ]
        do
            sleep 30
        done
    done
    if [ $NEED_ALIGN -eq 0 ]; then
        cd ..
        echo python logits_example_aligner.py --domains $ALL_DOMAIN
        python logits_example_aligner.py --domains $ALL_DOMAIN
        mkdir align_finish_$idx
        cd -
    fi
    while [ ! -d "../align_finish_$idx" ]
    do
        sleep 30
    done
    echo pretrain $ALL_DOMAIN $WEIGHTS
    pretrain $ALL_DOMAIN $WEIGHTS > log/pretrain_${idx}.log
    echo finetune
    finetune $NOW_DOMAIN $BEST_SCORE > log/finetune_${idx}.log
    SCORE_NOW=`tail -n 1 log/finetune_${idx}.log`
    if [ `echo "${SCORE_NOW} > ${BEST_SCORE}" | bc` -eq 1 ]; then
        BEST_SCORE=${SCORE_NOW}
    fi
    echo $NOW_DOMAIN best score $BEST_SCORE
done
mkdir train_finished

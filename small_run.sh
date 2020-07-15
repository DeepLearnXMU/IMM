#! /bin/bash
bash small_prepare_dir.sh
nohup bash main_iter.sh SQuAD_small NewsQA_small HotpotQA_small NaturalQuestions_small TriviaQA_small > test.log & 
#bash main_iter.sh SQuAD_small NewsQA_small

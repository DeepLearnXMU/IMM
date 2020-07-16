# An Iterative Multi-Source Mutual Knowledge Transfer Frameworkfor Machine Reading Comprehension
* The instructions below are still work in progress.
* This project is modified on the basis of https://github.com/PaddlePaddle/models/tree/release/1.8/PaddleNLP/pretrain_language_models/BERT
* The commands we list below do not include all optional arguments. 
If you want to change some of the optional arguments such as converting model output directories, please change the settings in ```main_iter.sh``` and ```single_domain/multi_iter.sh```.

## Data Format
The ```data``` directory should contain train, dev, test sets of five domains: **SQuAD**, **NewsQA**, **HotpotQA**, **NaturalQuestions** and **TriviaQA**. ```DOMAINNAME.raw.json``` are the training sets, ```DOMAINNAME_dev.raw.json``` and ```DOMAINNAME_test.raw.json``` are the validation sets and test sets. These json files need to be converted to SQuAD format.

## Running Command
* This project needs 5 GPUs (one GPU per each domain), please change the GPU configure in file ```main_iter.sh```.
  
Before start training, you need to download the pretrained BERT_base checkpoint.
```
wget https://bert-models.bj.bcebos.com/uncased_L-12_H-768_A-12.tar.gz
tar -zvxf uncased_L-12_H-768_A-12.tar.gz
```
After unzip the checkpoint file, you can start training by running:
```
bash run.sh
```
## Dependencies
* Python=2.7
* PaddlePaddle>=1.4.0
#   -*- coding: utf-8 -*-

import json
import sys
import argparse
import os

reload(sys)
sys.setdefaultencoding('utf8')

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--path', type=str, help='file path of processed file')
    parser.add_argument('--domains', nargs='+', type=str, help='file path of processed file')
    args = parser.parse_args()
    return args

dev_size = 500

if __name__ == '__main__':
    args = parse_args()
    file_nums = args.domains.__len__()
    max_len = -9999
    for i in range(0, file_nums):
        now_data_list = []
        file_name = os.path.join(args.path, (args.domains[i]+'.raw.json'))
        now_dataset = json.load(open(file_name,'r'))
        article_list = now_dataset['data']
        for article in article_list:
            title = article['title']
            for paragraph in article['paragraphs']:
                context = paragraph['context']
                for qas in paragraph['qas']:
                    gen_paragraph = {'context': context, 'qas':[qas]}
                    data_item = {'title': title, 'paragraphs':[gen_paragraph]}
                    now_data_list.append(data_item)
        # dev_set = now_data_list[:dev_size]
        # train_set = now_data_list[dev_size:]
        split_len = now_data_list.__len__() / 5
        now_idx = split_len
        before_idx = 0
        for i in range(5):
            if i == 4:
                now_idx = now_data_list.__len__()
            set = now_data_list[before_idx:now_idx]
            before_idx += split_len
            now_idx += split_len
            json.dump({"data":set}, open(file_name + "_" + str(i), 'w'), indent=4, ensure_ascii=False)


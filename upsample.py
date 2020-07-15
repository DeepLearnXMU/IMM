#   -*- coding: utf-8 -*-

import json
import sys
import argparse
import random
import os

reload(sys)
sys.setdefaultencoding('utf8')

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--path', type=str, help='file path of processed file')
    parser.add_argument('--domains', nargs='+', type=str, help='file path of processed file')
    args = parser.parse_args()
    return args

if __name__ == '__main__':
    args = parse_args()
    file_nums = args.domains.__len__()
    max_len = -9999
    for i in range(file_nums):
        now_len = 0
        file_name = os.path.join(args.path, (args.domains[i]+'.raw.json'))
        now_dataset = json.load(open(file_name,'r'))
        article_list = now_dataset['data']
        for article in article_list:
            for paragraph in article['paragraphs']:
                for qas in paragraph['qas']:
                    now_len += 1
        if now_len > max_len:
            max_len = now_len
    
    # total_data_list = []

    for i in range(0, file_nums):
        now_data_list = []

        file_name = os.path.join(args.path, (args.domains[i]+'.raw.json'))
        now_dataset = json.load(open(file_name,'r'))
        article_list = now_dataset['data']
        for batch_idx in range(2):
            one_batch = []
            for article in article_list:
                title = article['title']
                for paragraph in article['paragraphs']:
                    context = paragraph['context']
                    for qas in paragraph['qas']:
                        gen_paragraph = {'context': context, 'qas':[qas]}
                        data_item = {'title': title, 'paragraphs':[gen_paragraph]}
                        one_batch.append(data_item)
            random.shuffle(one_batch)
            if one_batch.__len__() < max_len:
                times = max_len/(one_batch.__len__())
                extends = max_len%(one_batch.__len__())
                append_data = []
                for t in range(times - 1):
                    append_data = append_data + one_batch
                append_data = append_data + one_batch[:extends]
                one_batch = one_batch + append_data
            random.shuffle(one_batch)
            now_data_list = now_data_list + one_batch
        file_name = file_name.replace('.raw.json','.4cb.raw.json')
        json.dump({"data":now_data_list}, open(file_name, 'w'), indent=4, ensure_ascii=False)

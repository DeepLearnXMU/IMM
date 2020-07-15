import argparse # option parsing
import json

parser = argparse.ArgumentParser(description='usage') # add description
parser.add_argument('--domains', nargs='+', type=str, help='file path of processed file')

args = parser.parse_args()

# domain_nums = args.domains.__len__()
logits_file_name = ["./" + x + '/logits_file' for x in args.domains]
qas2startlogits = {}
qas2endlogits = {}
qas2name = {}

for idx, file_name in enumerate(logits_file_name):
    logits_file = open(file_name, 'r')
    cnt = 0
    for item in logits_file.read().split('\n\n'):
        if item == "":
            continue
        lines = item.split('\n')
        qas2name[lines[0].split('_')[0]] = args.domains[idx]
        if lines[0].split('_')[0] not in qas2startlogits:
            qas2startlogits[lines[0].split('_')[0]] = {}
            qas2endlogits[lines[0].split('_')[0]] = {}

            pa_idx = int(lines[0].split('_')[1])
            qas2startlogits[lines[0].split('_')[0]][pa_idx] = [float(x) for x in lines[1].split(' ')]
            qas2endlogits[lines[0].split('_')[0]][pa_idx] = [float(x) for x in lines[2].split(' ')]
        else:
            pa_idx = int(lines[0].split('_')[1])
            qas2startlogits[lines[0].split('_')[0]][pa_idx] = [float(x) for x in lines[1].split(' ')]
            qas2endlogits[lines[0].split('_')[0]][pa_idx] = [float(x) for x in lines[2].split(' ')]
    logits_file.close()

qas_list = []
domain_data_name = './data/All_domain.raw.json'
file = open(domain_data_name, 'r')
filecontext = file.read()
file.close()
json_to_dict=json.loads(filecontext)
articleList = json_to_dict["data"]

for article in articleList:
    for paragraph in article['paragraphs']:
        context = paragraph['context']
        for qas in paragraph['qas']:
            qas_list.append(qas['id'])

qas_num = qas_list.__len__()
epoch_idx = 0
file_idx = 0

out_file = open('./total_logits/logits_0', 'w')
id_map_file = open('id_map', 'w')
for idx, id in enumerate(qas_list):
    epoch_idx += 1
    if epoch_idx >= int(qas_num / 100):
        out_file.close()
        epoch_idx = 0
        file_idx += 1
        out_file = open('./total_logits/logits_'+str(file_idx), 'w')
    logits_num = qas2startlogits[id].__len__()
    for pa_idx in range(1, logits_num + 1):
        out_file.write(id + '_' + str(pa_idx))
        out_file.write('\n')
        out_file.write(' '.join([str(x) for x in qas2startlogits[id][pa_idx]]))
        out_file.write('\n')
        out_file.write(' '.join([str(x) for x in qas2endlogits[id][pa_idx]]))
        out_file.write('\n')
        out_file.write(qas2name[id])
        out_file.write('\n\n')
        id_map_file.write(id + '_' + str(pa_idx) + '\t' + '../total_logits/logits_' + str(file_idx))
        id_map_file.write('\n')

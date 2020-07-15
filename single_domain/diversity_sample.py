import argparse
import numpy as np
import tokenization
from utils.args import ArgumentGroup

parser = argparse.ArgumentParser(__doc__)
g = ArgumentGroup(parser, "model", "model configuration and paths.")
g.add_arg("sample_strategy",         str,  'max_sample',           "Sample strategy.")
g.add_arg("weights_path",         str,  None,           "Path to the weights file.")
g.add_arg("adv_text_path",         str,  None,           "Path to save the generated adversarial sentences.")
g.add_arg("bert_vocab_file",         str,  None,           "Path to the bert vocab file.")
args = parser.parse_args()

adv_seq_len = -1
do_lower_case = True
tokenizer = tokenization.FullTokenizer(
    vocab_file=args.bert_vocab_file, do_lower_case=do_lower_case)
if args.sample_strategy == 'max_sample':
    with open(args.weights_path, 'r') as fin, open(args.adv_text_path, 'w') as fout:
        items = fin.read().split('\n\n')
        for idx, item in enumerate(items):
            if item == "":
                continue
            lines = item.split('\n')
            if idx == 0:
                adv_seq_len = int(lines[0])
                del lines[0]
            assert lines.__len__()  == adv_seq_len + 2
            qas_id = lines[0]
            # seq_weights = np.array([float(item) for item in [x for x in [l.split(' ') for l in lines[1: 1 + adv_seq_len]]]])
            seq_weights = np.array([[float(x) for x in l.split(' ')] for l in lines[1: 1 + adv_seq_len]])
            vocab_id = np.array([int(x) for x in lines[-1].split(' ')])

            ids = vocab_id[np.array([np.argmax(seq_weights[i]) for i in range(adv_seq_len)])]
            tokens = tokenizer.convert_ids_to_tokens(ids)

            fout.write(qas_id)
            fout.write('\t')
            fout.write(" ".join(tokens))
            fout.write('\n')






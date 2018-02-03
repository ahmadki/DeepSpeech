#!/bin/bash
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/local/cuda-9.0/extras/CUPTI/lib64/:/usr/local/cuda-9.0/lib64/:$LD_LIBRARY_PATH

export LM_DIR=/data/speech/LM
export COMPUTE_DATA_DIR=/data/speech/WSJ
# Warn if we can't find the train files
if [ ! -f "${COMPUTE_DATA_DIR}/wsj-train.csv" ]; then
    echo "Warning: It looks like you don't have the Switchboard corpus"       \
         "downloaded and preprocessed. Make sure \$COMPUTE_DATA_DIR points to the" \
         "folder where the Switchboard data is located, and that you ran the" \
         "importer script before running this script."
fi;

export EXPERIMENT=DS2-WSJ-64SL
export LOG_DIR=/ds2/experiments/${EXPERIMENT}
export CHECKPOINT_DIR=${LOG_DIR}/checkpoints
export SUMMARY_DIR=${LOG_DIR}/summary

if [ ! -d "$LOG_DIR" ]; then
  mkdir  ${LOG_DIR}
fi
if [ ! -d "$CHECKPOINT_DIR" ]; then
  mkdir  ${CHECKPOINT_DIR}
fi
if [ ! -d "$SUMMARY_DIR" ]; then
  mkdir  ${SUMMARY_DIR}
fi

LOG_FILE=${LOG_DIR}/${EXPERIMENT}_$(date +%Y%m%d_%H%M).txt

echo Logging the experiment to $LOG_FILE


CONFIG="\
  --train_files data/wsj-sample/wsj-train-64sl.csv \
  --dev_files data/wsj-sample/wsj-train-64sl.csv \
  --test_files data/wsj-sample/wsj-train-64sl.csv \
  --input_type spectrogram \
  --num_audio_features 161 \
  --num_conv_layers 2 \
  --num_rnn_layers 1 \
  --rnn_cell_dim 256 \
  --rnn_type gru \
  --n_hidden 256 \
  --train_batch_size 16 \
  --dev_batch_size  16 \
  --test_batch_size 16 \
  --epoch 100 \
  --early_stop 0 \
  --optimizer adam \
  --learning_rate 0.0002 \
  --decay_steps 3000 \
  --decay_rate 0.9 \
  --display_step 40 \
  --validation_step 20 \
  --dropout_keep_prob 0.9 \
  --weight_decay 0.0005 \
  --checkpoint_dir ${CHECKPOINT_DIR} \
  --checkpoint_secs 18000 \
  --summary_dir ${SUMMARY_DIR} \
  --summary_secs 600 \
  --lm_binary_path $LM_DIR/wsj-lm.binary \
  --lm_trie_path $LM_DIR/wsj-lm.trie \
  --beam_width 64 \
  --word_count_weight 1.5 \
  --valid_word_count_weight 2.5 \
"

echo VERSION: $(git rev-parse --short HEAD) | tee $LOG_FILE
echo CONFIG: | tee -a $LOG_FILE
echo $CONFIG | tee -a $LOG_FILE

time python -u DeepSpeech2.py $CONFIG \
  --wer_log_pattern "GLOBAL LOG: logwer('${COMPUTE_ID}', '%s', '%s', %f)" \
  --decoder_library_path /opt/tensorflow/bazel-bin/native_client/libctc_decoder_with_kenlm.so \
  "$@" 2>&1 | tee -a $LOG_FILE

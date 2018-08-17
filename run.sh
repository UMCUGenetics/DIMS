#! /bin/bash
sh ./scripts/pipeline.2.0.sh | tee submit_log.txt
#qsub -l h_rt=00:05:00 -l h_vmem=1G -N "mail_negative" -hold_jid "collect3_negative" ./scripts/mail.sh "negative"

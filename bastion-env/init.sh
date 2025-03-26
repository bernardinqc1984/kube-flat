#source S3.config

#unset TF_LOG
#unset TF_LOG_PATH
#export TF_LOG="TRACE"
#export TF_LOG_PATH="terraform.log"
INIT_ARGS=$@

tofu init $INIT_ARGS \
    -backend-config="bucket=$BUCKET" \
    -backend-config="key=$KEY" \
    -backend-config="endpoint=$AWS_S3_ENDPOINT" \
    -backend-config="region=$AWS_REGION" \
    -backend-config="access_key=$AWS_ACCESS_KEY_ID" \
    -backend-config="secret_key=$AWS_SECRET_ACCESS_KEY"

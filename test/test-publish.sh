# #!/usr/bin/env bash
# based on https://stackoverflow.com/questions/59002949/how-to-create-a-json-web-token-jwt-using-openssl-shell-commands 
MERCURE_JWT_ALGORITHM=$1

MERCURE_JWT_ALGORITHM=${MERCURE_JWT_ALGORITHM:-HS256}

JWT_SECRET="bc022c5c08160cdbad976a49c2944f0a76f5ae85e6f84444ae72cc6de3556238402aa8ca5218459af248bc0255b48f22f4938734ffea1d47aa82420153dbd516"

HEX_SECRET=$(echo -n "$JWT_SECRET" | xxd -p | paste -sd "")
JWT_HEADER="{\"alg\": \"${MERCURE_JWT_ALGORITHM}\", \"typ\": \"JWT\"}"
echo "header: $JWT_HEADER"
JWT_HEADER_B64=$(echo -n $JWT_HEADER | base64 | sed s/\+/-/g | sed 's/\//_/g' | sed -E s/=+$//)
JWT_PAYLOAD='{"mercure": {"publish": ["*"]}}'
echo "payload: $JWT_PAYLOAD"
JWT_PAYLOAD_B64=$(echo -n $JWT_PAYLOAD | base64 | sed s/\+/-/g | sed 's/\//_/g' | sed -E s/=+$//)

if [ "$MERCURE_JWT_ALGORITHM" == 'HS256' ]; then
  SHA_ALG="sha256"
elif [ "$MERCURE_JWT_ALGORITHM" == "HS512" ]; then
  SHA_ALG="sha512"
fi

SIGNATURE=$(echo -n "${JWT_HEADER_B64}.${JWT_PAYLOAD}" | openssl dgst -binary -${SHA_ALG} -mac HMAC -macopt hexkey:"$HEX_SECRET" | base64 | sed s/\+/-/g | sed 's/\//_/g' | sed -E s/=+$//)

JWT_TOKEN="${JWT_HEADER_B64}.${JWT_PAYLOAD_B64}.${SIGNATURE}"
echo "token_C: $JWT_TOKEN"
JWT_TOKEN_1=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJtZXJjdXJlIjp7InB1Ymxpc2giOlsiKiJdfX0.MbLRBli1HCMU2qsYTlHY_mQV_7N6MxCIMlVuQ6uNY44
echo "token_M: $JWT_TOKEN_1"
echo "Calculated token:"
curl --request POST \
   --url http://127.0.0.1:3333/.well-known/mercure \
   --header "Authorization: Bearer ${JWT_TOKEN}" \
   --header 'content-type: application/x-www-form-urlencoded' \
   --data topic=recipes \
   --data "data=data=my+message+is+getting+published"
echo "Manual token:"
curl --request POST \
   --url http://127.0.0.1:3333/.well-known/mercure \
   --header "Authorization: Bearer ${JWT_TOKEN_1}" \
   --header 'content-type: application/x-www-form-urlencoded' \
   --data topic=recipes \
   --data "data=data=my+message+is+getting+published"
   #--data "data={'mercure': {'subscribe': ['*'], 'publish': ['*']}}"


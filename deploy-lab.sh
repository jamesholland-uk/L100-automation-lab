printf "\n"
date
printf "\n"

for i in {1..12}; do

    terraform workspace new student$i
    terraform workspace select student$i
    terraform init
    terraform apply --auto-approve

done

printf "\n"
date
printf "\n"

for i in {1..12}; do

    terraform workspace select student$i
    terraform output fw_mgmt_public_ip
    terraform output fw_mgmt_private_ip
    terraform output mgmt_host_public_ip
    terraform output username
    terraform output password

done
printf "\n"
date
printf "\n"

for i in {1..12}; do

    terraform workspace new student$i
    terraform workspace select student$i
    terraform destroy --auto-approve

done

printf "\n"
date
printf "\n"
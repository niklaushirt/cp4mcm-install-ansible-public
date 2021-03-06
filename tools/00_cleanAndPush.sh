echo "***************************************************************************************************************************************************"
echo " 🚀  Clean for GIT Push"
echo "***************************************************************************************************************************************************"


export gitCommitMessage=$(date +%Y%m%d-%H%M)

echo "--------------------------------------------------------------------------------------------------------------------------------"
echo "    🗄️  Make local copy ../ARCHIVE/aiops-ansible-$gitCommitMessage"
echo "--------------------------------------------------------------------------------------------------------------------------------"

mkdir -p ../ARCHIVE/aiops-ansible-$gitCommitMessage

cp -r * ../ARCHIVE/aiops-ansible-$gitCommitMessage
cp .gitignore ../ARCHIVE/aiops-ansible-$gitCommitMessage


echo "--------------------------------------------------------------------------------------------------------------------------------"
echo "    🚀  Find File Copies"
echo "--------------------------------------------------------------------------------------------------------------------------------"
find . -name '*copy*' -type f | grep -v DO_NOT_DELIVER


echo "--------------------------------------------------------------------------------------------------------------------------------"
echo "    🚀  Deleting large and sensitive files"
echo "--------------------------------------------------------------------------------------------------------------------------------"
echo "      ❎  Deleting DS_Store"
find . -name '.DS_Store' -type f -delete
echo "      ❎  Deleting Certificate Files"
find . -name 'cert.*' -type f -delete
echo "      ❎  Deleting Certificate Authority Files"
find . -name 'ca.*' -type f -delete
echo "      ❎  Deleting TLS Secrets"
find . -name 'openshift-tls-secret*' -type f -delete
echo "      ❎  Deleting JSON Log Files Kafka"
find . -name '*.json' -type f -size +1000000k -delete
echo "      ❎  Deleting JSON Log Files Elastic"
find . -name '*-logtrain.json' -type f -size +10000k -delete
echo "      ❎  Deleting Conflict Files"
find . -name '*2021_Conflict*' -type f -delete
echo "      ❎  Deleting node_modules"
find . -name 'node_modules' -type d  -exec rm -rf {} \;
echo "      ❎  Deleting files > 250MB"
find . -type f -size +250M -delete



echo "--------------------------------------------------------------------------------------------------------------------------------"
echo "    🚀  Remove Temp Files"
echo "--------------------------------------------------------------------------------------------------------------------------------"
rm -f ./reset/tmp_connection.json
rm -f ./reset/test.json
rm -f ./demo/external-tls-secret.yaml
rm -f ./demo/iaf-system-backup.yaml
rm -f ./external-tls-secret.yaml
rm -f ./iaf-system-backup.yaml

export actBranch=$(git branch | tr -d '* ')
echo "--------------------------------------------------------------------------------------------------------------------------------"
echo "    🚀  Update Branch to $actBranch"
echo "--------------------------------------------------------------------------------------------------------------------------------"



read -p " ❗❓ do you want to check-in the GitHub branch $actBranch with message $gitCommitMessage? [y,N] " DO_COMM
if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
    echo "   ✅ Ok, checking in..."
    git add . && git commit -m $gitCommitMessage && git push
else
    echo "    ⚠️  Skipping"
fi





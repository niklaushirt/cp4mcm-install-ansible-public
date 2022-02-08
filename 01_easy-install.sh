#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------"
#  CP4MCM 3.2 - CP4MCM Installation
#
#
#  ©2022 nikh@ch.ibm.com
# ---------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------"
clear

echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "  "
echo "  🐥 CloudPak for MultiCloud Management 3.2 - Easy Install"
echo "  "
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "  "
echo "  "





while getopts "t:v:r:hc:" opt
do
    case "$opt" in
        t ) INPUT_TOKEN="$OPTARG" ;;
        v ) VERBOSE="$OPTARG" ;;
        r ) REPLACE_INDEX="$OPTARG" ;;
        h ) HELP_USAGE=true ;;

    esac
done


    
if [[ $HELP_USAGE ]];
then
    echo " USAGE: $0 [-t <REGISTRY_TOKEN>] [-v true] [-r true]"
    echo "  "
    echo "     -t  Provide registry pull token              <REGISTRY_TOKEN> "
    echo "     -v  Verbose mode                             true/false"
    echo "     -r  Replace indexes if they already exist    true/false"

    exit 1
fi



if [[ $INPUT_TOKEN == "" ]];
then
    echo " 🔐  Token                               Not Provided (will be asked during installation)"
else
    echo " 🔐  Token                               Provided"
    export ENTITLED_REGISTRY_KEY=$INPUT_TOKEN
fi


if [[ $VERBOSE ]];
then
    echo " ✅  Verbose Mode                        On"
    export ANSIBLE_DISPLAY_SKIPPED_HOSTS=true
    export VERBOSE="-v"
else
    echo " ❎  Verbose Mode                        Off          (enable it by appending '-v true')"
    export ANSIBLE_DISPLAY_SKIPPED_HOSTS=false
    export VERBOSE=""
fi


if [[ $REPLACE_INDEX ]];
then
    echo " ❌  Replace existing Indexes            On ❗         (existing training indexes will be replaced/reloaded)"
    export SILENT_SKIP=false
else
    echo " ✅  Replace existing Indexes            Off          (default - enable it by appending '-r true')"
    export SILENT_SKIP=true

fi
echo ""
echo ""


export TEMP_PATH=~/aiops-install

# ---------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------"
# Do Not Edit Below
# ---------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------"

echo ""
echo ""
echo ""
echo ""
echo "--------------------------------------------------------------------------------------------"
echo " 🐥  Initializing..." 
echo "--------------------------------------------------------------------------------------------"
echo ""

printf "\r  🥚🥚🥚🥚🥚🥚🥚🥚🥚🥚🥚🥚🥚 - Checking Command Line Tools                                  "

if [ ! -x "$(command -v oc)" ]; then
      echo "❌ Openshift Client not installed."
      echo "   🚀 Install prerequisites with ./ansible/scripts/02-prerequisites-mac.sh or ./ansible/scripts/03-prerequisites-ubuntu.sh"
      echo "❌ Aborting...."
      exit 1
fi
if [ ! -x "$(command -v jq)" ]; then
      echo "❌ jq not installed."
      echo "   🚀 Install prerequisites with ./ansible/scripts/02-prerequisites-mac.sh or ./ansible/scripts/03-prerequisites-ubuntu.sh"
      echo "❌ Aborting...."
      exit 1
fi
if [ ! -x "$(command -v ansible-playbook)" ]; then
      echo "❌ Ansible not installed."
      echo "   🚀 Install prerequisites with ./ansible/scripts/02-prerequisites-mac.sh or ./ansible/scripts/03-prerequisites-ubuntu.sh"
      echo "❌ Aborting...."
      exit 1
fi
if [ ! -x "$(command -v cloudctl)" ]; then
      echo "❌ cloudctl not installed."
      echo "   🚀 Install prerequisites with ./ansible/scripts/02-prerequisites-mac.sh or ./ansible/scripts/03-prerequisites-ubuntu.sh"
      echo "❌ Aborting...."
      exit 1
fi

printf "\r  🐣🥚🥚🥚🥚🥚🥚🥚🥚🥚🥚🥚🥚🥚 - Getting Cluster Status                                       "
export CLUSTER_STATUS=$(oc status | grep "In project")
printf "\r  🐥🐣🥚🥚🥚🥚🥚🥚🥚🥚🥚🥚🥚🥚 - Getting Cluster User                                         "

export CLUSTER_WHOAMI=$(oc whoami)

if [[ ! $CLUSTER_STATUS =~ "In project" ]]; then
      echo "❌ You are not logged into a Openshift Cluster."
      echo "❌ Aborting...."
      exit 1
else
      printf "\r ✅ $CLUSTER_STATUS as user $CLUSTER_WHOAMI\n\n"

fi


printf "  🐥🐥🐣🥚🥚🥚🥚🥚🥚🥚🥚🥚🥚 - Checking CP4MCM Base Install                                    "
export MCM_READY=$(oc get po -A|grep multicluster-hub-console-mcmui |awk '{print$1}')
printf "\r  🐥🐥🐥🐣🥚🥚🥚🥚🥚🥚🥚🥚🥚 -  Checking RHACM                               "
export RHACM_READY=$(oc get po -n open-cluster-management|grep management-ingress |awk '{print$1}')
printf "\r  🐥🐥🐥🐥🐣🥚🥚🥚🥚🥚🥚🥚🥚 - Checking Infrastructure Management                                 "
export IM_READY=$(oc get po -n management-infrastructure-management|grep web-service |awk '{print$1}')
printf "\r  🐥🐥🐥🐥🐥🐣🥚🥚🥚🥚🥚🥚🥚 - Checking Service Management                                 "
export CAM_READY=$(oc get po -n management-infrastructure-management|grep cam |awk '{print$1}')

printf "\r  🐥🐥🐥🐥🐥🐥🐥🐥🐥🐥🐣🥚🥚 - Getting RobotShop Status                                      "
export RS_READY=$(oc get ns robot-shop  --ignore-not-found|awk '{print$1}')
printf "\r  🐥🐥🐥🐥🐥🐥🐥🐥🐥🐥🐥🐣🥚 - Getting LDAP Status                                           "
export LDAP_READY=$(oc get po -n default --ignore-not-found| grep ldap |awk '{print$1}')
printf "\r  🐥🐥🐥🐥🐥🐥🐥🐥🐥🐥🐥🐥🐥 - Done ✅                                                        "





# ------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------
# Patch IAF Resources for ROKS
# ------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------
menu_INSTALL_CP4MCM_ALL () {
      echo "--------------------------------------------------------------------------------------------"
      echo " 🚀  Install CP4MCM ALL" 
      echo "--------------------------------------------------------------------------------------------"
      echo ""

      # Check if already installed
      if [[  $MCM_READY == "" ]]; then
            echo "⚠️  CP4MCM seems to be installed already"

            read -p "   Are you sure you want to continue❓ [y,N] " DO_COMM
            if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
                  echo ""
                  echo "   ✅ Ok, continuing..."
                  echo ""
            else
                  echo ""
                  echo "    ❌  Aborting"
                  echo "--------------------------------------------------------------------------------------------"
                  echo  ""    
                  echo  ""
                  return
            fi
      fi

      #Get Pull Token
      if [[ $ENTITLED_REGISTRY_KEY == "" ]];
      then
            echo ""
            echo ""
            echo "  Enter CP4MCM Pull token: "
            read TOKEN
      else
            TOKEN=$ENTITLED_REGISTRY_KEY
      fi

      echo ""
      echo "  🔐 You have provided the following Token:"
      echo "    "$TOKEN
      echo ""

      # Install
      read -p "  Are you sure that this is correct❓ [y,N] " DO_COMM
      if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
          
            cd ansible
            ansible-playbook -e ENTITLED_REGISTRY_KEY=$TOKEN 10_install-cp4mcm-all.yaml
            cd -

            echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
            echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
            echo "    🚀 MultiCloud Management"
            echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
            echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
            echo "    "
            echo "      📥 MultiCloud Management"
            echo ""
            appURL=$(oc get routes -n ibm-common-services cp-console  -o jsonpath="{['spec']['host']}")|| true
            echo "                🌏 URL:      https://$appURL"

            echo ""
            echo "                🧑 User:     $(oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_username}' | base64 --decode && echo)"
            echo "                🔐 Password: $(oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 --decode)"

      else
            echo "    ⚠️  Skipping"
            echo "--------------------------------------------------------------------------------------------"
            echo  ""    
            echo  ""
      fi
}





menu_INSTALL_CP4MCM () {
      echo "--------------------------------------------------------------------------------------------"
      echo " 🚀  Install CP4MCM " 
      echo "--------------------------------------------------------------------------------------------"
      echo ""

      # Check if already installed
      if [[  ! $MCM_READY == "" ]]; then
            echo "⚠️  CP4MCM seems to be installed already"

            read -p "   Are you sure you want to continue❓ [y,N] " DO_COMM
            if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
                  echo ""
                  echo "   ✅ Ok, continuing..."
                  echo ""
            else
                  echo ""
                  echo "    ❌  Aborting"
                  echo "--------------------------------------------------------------------------------------------"
                  echo  ""    
                  echo  ""
                  return
            fi
      fi


      if [[  $RHACM_READY == "" ]]; then
            echo "❗  RHACM doesn't seem to be installed. This might create problems!"

            read -p "   Are you sure you want to continue❓ [y,N] " DO_COMM
            if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
                  echo ""
                  echo "   ✅ Ok, continuing..."
                  echo ""
            else
                  echo ""
                  echo "    ❌  Aborting"
                  echo "--------------------------------------------------------------------------------------------"
                  echo  ""    
                  echo  ""
                  return
            fi
      fi



      #Get Pull Token
      if [[ $ENTITLED_REGISTRY_KEY == "" ]];
      then
            echo ""
            echo ""
            echo "  Enter CP4MCM Pull token: "
            read TOKEN
      else
            TOKEN=$ENTITLED_REGISTRY_KEY
      fi

      echo ""
      echo "  🔐 You have provided the following Token:"
      echo "    "$TOKEN
      echo ""

      # Install
      read -p "  Are you sure that this is correct❓ [y,N] " DO_COMM
      if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then

            cd ansible
            ansible-playbook -e ENTITLED_REGISTRY_KEY=$TOKEN 12_install-cp4mcm.yaml
            cd -


            echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
            echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
            echo "    🚀 MultiCloud Management"
            echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
            echo "    -----------------------------------------------------------------------------------------------------------------------------------------------"
            echo "    "
            echo "      📥 MultiCloud Management"
            echo ""
            appURL=$(oc get routes -n ibm-common-services cp-console  -o jsonpath="{['spec']['host']}")|| true
            echo "                🌏 URL:      https://$appURL"

            echo ""
            echo "                🧑 User:     $(oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_username}' | base64 --decode && echo)"
            echo "                🔐 Password: $(oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 --decode)"

      else
            echo "    ⚠️  Skipping"
            echo "--------------------------------------------------------------------------------------------"
            echo  ""    
            echo  ""
      fi
}




menu_INSTALL_INFRA () {
      echo "--------------------------------------------------------------------------------------------"
      echo " 🚀  Install CP4MCM Infrastructure Management Module" 
      echo "--------------------------------------------------------------------------------------------"
      echo ""


            # Check if already installed
      if [[  $LDAP_READY == "" ]]; then
            echo "⚠️  LDAP doesn't seem to be installed. This might cause problems!"

            read -p "   Are you sure you want to continue❓ [y,N] " DO_COMM
            if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
                  echo ""
                  echo "   ✅ Ok, continuing..."
                  echo ""
            else
                  echo ""
                  echo "    ❌  Aborting"
                  echo "--------------------------------------------------------------------------------------------"
                  echo  ""    
                  echo  ""
                  return
            fi
      fi


      # Check if already installed
      if [[ ! $IM_READY == "" ]]; then
            echo "⚠️  Infrastructure Management Module seems to be installed already"

            read -p "   Are you sure you want to continue❓ [y,N] " DO_COMM
            if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
                  echo ""
                  echo "   ✅ Ok, continuing..."
                  echo ""
            else
                  echo ""
                  echo "    ❌  Aborting"
                  echo "--------------------------------------------------------------------------------------------"
                  echo  ""    
                  echo  ""
                  return
            fi

      fi

      # Install
      cd ansible
      ansible-playbook 15_install-cp4mcm-infra.yaml
      cd -

    


}



menu_INSTALL_RHACM () {
      echo "--------------------------------------------------------------------------------------------"
      echo " 🚀  Install RHACM" 
      echo "--------------------------------------------------------------------------------------------"
      echo ""



      if [[  ! $RHACM_READY == "" ]]; then
            echo "❗  RHACM seems to be installed. This might create problems!"

            read -p "   Are you sure you want to continue❓ [y,N] " DO_COMM
            if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
                  echo ""
                  echo "   ✅ Ok, continuing..."
                  echo ""
            else
                  echo ""
                  echo "    ❌  Aborting"
                  echo "--------------------------------------------------------------------------------------------"
                  echo  ""    
                  echo  ""
                  return
            fi
      fi



      cd ansible
      ansible-playbook 11_install-rhacm.yaml
      cd -
}


menu_INSTALL_ROBOTSHOP () {
      echo "--------------------------------------------------------------------------------------------"
      echo " 🚀  Install RobotShop" 
      echo "--------------------------------------------------------------------------------------------"
      echo ""

      cd ansible
      ansible-playbook 18_install-robot-shop.yaml
      cd -
}


menu_INSTALL_LDAP () {
      echo "--------------------------------------------------------------------------------------------"
      echo " 🚀  Install LDAP" 
      echo "--------------------------------------------------------------------------------------------"
      echo ""

      cd ansible
      ansible-playbook 18_install-ldap.yaml
      cd -
}



incorrect_selection() {
      echo "--------------------------------------------------------------------------------------------"
      echo " ❗ This option does not exist!" 
      echo "--------------------------------------------------------------------------------------------"
}


clear

echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo " 🐥 CloudPak for MultiCloud Management - EASY INSTALL"
echo "*****************************************************************************************************************************"
echo "  "
echo "  ℹ️  This script provides different options to install CP4MCM demo environments through Ansible"
echo ""
echo "   ------------------------------------------------------------------------------------------------------------------------------"
echo "   🗄️  Using Parameters"
echo "   ------------------------------------------------------------------------------------------------------------------------------"


if [[ $ENTITLED_REGISTRY_KEY == "" ]];
then
echo "      🔐 Image Pull Token:          Not Provided (will be asked during installation)"
else
echo "      🔐 Image Pull Token:          Provided"
fi

echo "      🌏 Namespace:                 $MCM_NAMESPACE"	
echo "      💾 Skip Data Load if exists:  $SILENT_SKIP"	
echo "      🔎 Verbose Mode:              $ANSIBLE_DISPLAY_SKIPPED_HOSTS"


echo "  "
echo "*****************************************************************************************************************************"
echo "*****************************************************************************************************************************"
echo "  "




until [ "$selection" = "0" ]; do
  

      echo "  🐥 CP4MCM - Easy Install"
      if [[ $MCM_READY == "" ]]; then
            echo "      10  - Install Base Configuration                              - Install RHACM, CP4MCM Base, Infrastructure Mgt, LDAP, User Registration, RobotShop"
      else
            echo "      ✅  - Install Base Configuration                                    "
      fi


      echo "  "
      echo "  "
      echo "  🐥 CP4MCM - Base Install"
      if [[ $RHACM_READY == "" ]]; then
            echo "      11  - Install RHACM                                           - Install RedHat Advanced Cluster Management"
      else
            echo "      ✅  - Install RHACM                                   "
      fi

      if [[ $MCM_READY == "" ]]; then
            echo "      12  - Install CloudPak for Multicloud Management              - Install CP4MCM"
      else
            echo "      ✅  - Install CloudPak for Multicloud Management                                     "
      fi




      echo "  "
      echo "  "
      echo "  🐥 CP4MCM - Modules"

      if [[  $IM_READY == "" ]]; then
            echo "      21  - Install Infrastructure Management                       - Install Infrastructure Management Module"
      else
            echo "      ✅  - Install Infrastructure Management                                              "
      fi
      echo "      xx  - Install Service Management                                    - Install Service Management Module (has to be enabled manually in the Installation CR)"
      echo "      xx  - Install Monitoring                                            - Install Monitoring Module (has to be enabled manually in the Installation CR)"





      echo "  "
      echo "  "
      echo "  🐥 CP4MCM Addons"

      if [[  $LDAP_READY == "" ]]; then
            echo "      31  - Install OpenLdap                                        - Install OpenLDAP for CP4MCM (should be installed by option 10)"
      else
            echo "      ✅  - Install OpenLdap                                        "
      fi

      if [[  $RS_READY == "" ]]; then
            echo "      32  - Install RobotShop                                       - Install RobotShop for CP4MCM (should be installed by option 10)"
      else
            echo "      ✅  - Install RobotShop                                       "
      fi


      
      echo "  "

      echo "  "
      echo "  🐥 Prerequisites Install"
      echo "      81  - Install Prerequisites Mac                                - Install Prerequisites for Mac"
      echo "      82  - Install Prerequisites Ubuntu                             - Install Prerequisites for Ubuntu"
      echo "  "

      echo "  "
      echo "  🐥 Infos"
      echo "      91  - Get logins                                               - Get logins for all installed components"
      echo "      92  - Write logins to file                                     - Write logins for all installed components to file LOGIN.txt"
      echo "  "

  echo "      "
  echo "      "
  echo "      "
  echo "    	0  -  Exit"
  echo ""
  echo ""
  echo "  Enter selection: "
  read selection
  echo ""
  case $selection in
    10 ) clear ; menu_INSTALL_CP4MCM_ALL  ;;
    12 ) clear ; menu_INSTALL_CP4MCM  ;;
    11 ) clear ; menu_INSTALL_RHACM  ;;

    21 ) clear ; menu_INSTALL_INFRA  ;;

    31 ) clear ; menu_INSTALL_LDAP  ;;
    32 ) clear ; menu_INSTALL_ROBOTSHOP  ;;



    51 ) clear ; menuLOAD_TOPOLOGY  ;;
    52 ) clear ; menuLOAD_TOPOLOGYNOI  ;;
    55 ) clear ; menuTRAIN_AIOPSDEMO  ;;


    81 ) clear ; ./13_prerequisites-mac.sh  ;;
    82 ) clear ; ./14_prerequisites-ubuntu.sh  ;;

    91 ) clear ; ./tools/20_get_logins.sh  ;;
    92 ) clear ; ./tools/20_get_logins.sh > LOGINS.txt  ;;


    0 ) clear ; exit ;;
    * ) clear ; incorrect_selection  ;;
  esac
  read -p "Press Enter to continue..."
  clear 
done



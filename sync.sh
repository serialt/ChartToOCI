# ***********************************************************************
# Description   : Blue Planet
# Author        : serialt
# Email         : tserialt@gmail.com
# Created Time  : 2023-09-24 00:27:26
# Last modified : 2023-09-24 09:31:39
# FilePath      : /migrate-chart/sync.sh
# Other         : 
#               : 
# 
# 
# 
# ***********************************************************************

chart_repo=(
bitnami="https://charts.bitnami.com/bitnami"
istio="https://istio-release.storage.googleapis.com/charts"
grafana="https://grafana.github.io/helm-charts"
bitnami="https://charts.bitnami.com/bitnami"
bitnami_chart="nginx "
)

charts=(
bitnami,gitea
bitnami,nginx
bitmani,minio
bitmani,redis
bitmani,mysql
bitmani,keycloak
bitmani,rabbitmq
bitmani,mongodb
bitmani,mariadb
bitmani,elasticsearch
bitmani,etcd
bitmani,influxdb
bitmani,harbor
bitmani,cert-manager
bitmani,sonarqube
bitmani,postgresql
grafana,grafana
grafana,loki-stack
istio,base
istio,istiod
istio,gateway
)

# workspace
workspace=`pwd`


# get oci_repo
OCI_REPO="oci://${OCI_REPO_DOMAIN}"
OCI_USERNAME="${OCI_USERNAME}"
OCI_PASSWORD="${OCI_PASSWORD}"

# add repo 
AddRepo(){
    for _repo in ${chart_repo} 
        do 
            echo ${_repo}
            repo_name=`echo ${_repo} | awk -F'=' '{print $1}'`
            repo_url=`echo ${_repo} | awk -F'=' '{print $2}'`
            helm repo add ${repo_name} ${repo_url}
        done 
}

# Download chart 
DownloadChart(){
    chartRepo=$1
    chartName=$2
    
    mkdir -p ${workspace}/charts
    cd ${workspace}/charts
    results=`helm search repo ${chartRepo}/${chartName} -l | sed '1d' | awk '{print $1"="$2}'`
    echo ${results}
    for i in ${results} 
        do 
            repo_chart=`echo $i | awk -F '=' '{print $1}'`
            repo_chart_version=`echo $i | awk -F '=' '{print $2}'`
            grep ${chartName}-${repo_chart_version} ${workspace}/charts.txt
            if [ $? != 0 ] ;then 
                helm fetch ${repo_chart} --version ${repo_chart_version}
            fi
        done
}

# push chart to oci
pushChart(){
    oci_url=$1

    cd ${workspace}/charts
    chart_list=`ls ./ | grep tgz`
    for i in ${chart_list}
        do 
            grep ${i} ${workspace}/charts.txt
            # 如果chart不存在于charts.txt文件中，这进行推送oci
            if [ $? != 0 ] ;then 
                helm push ${i} ${OCI_REPO}/${OCI_USERNAME}
                if [ $? == 0 ] ;then
                    echo ${i} >> ${workspace}/charts.txt
                    echo "SET_COMMIT=sugar" >> $GITHUB_OUTPUT
                fi
            fi

        done
}


## main
echo ${OCI_PASSWORD} | helm registry login -u ${OCI_USERNAME}  ${OCI_REPO_DOMAIN} --password-stdin 
AddRepo

for aobj in ${charts[@]}
    do
        arr=(${aobj//,/ })
        repo_name=${arr[0]}
        chart_name=${arr[1]}
        # echo ${repo_name} ${chart_name}
        DownloadChart ${repo_name} ${chart_name}
        
    done
pushChart ${OCI_REPO}
#
echo "" >> ${workspace}/charts.txt
helm registry logout ${OCI_REPO_DOMAIN}
unset OCI_PASSWORD
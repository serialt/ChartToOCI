# ***********************************************************************
# Description   : Blue Planet
# Author        : serialt
# Email         : tserialt@gmail.com
# Created Time  : 2023-09-24 00:27:26
# Last modified : 2024-02-06 22:22:50
# FilePath      : /ChartToOCI/sync.sh
# Other         : 
#               : 
# 
# 
# 
# ***********************************************************************

chart_repo=(
bitnami,"https://charts.bitnami.com/bitnami"
istio,"https://istio-release.storage.googleapis.com/charts"
grafana,"https://grafana.github.io/helm-charts"
hashicorp,"https://helm.releases.hashicorp.com"
ingress-nginx,"https://kubernetes.github.io/ingress-nginx"
metallb,"https://metallb.github.io/metallb"
metrics-server,"https://kubernetes-sigs.github.io/metrics-server"
openebs,"https://openebs.github.io/charts"
openebs-jiva,"https://openebs.github.io/jiva-operator"
runix,"https://helm.runix.net"
harbor,"https://helm.goharbor.io"
longhorn,"https://charts.okteto.com"
csi-driver-nfs,"https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
)

charts=(
hashicorp,vault
bitnami,gitea
bitnami,nginx
bitnami,minio
bitnami,redis
bitnami,mysql
bitnami,keycloak
bitnami,rabbitmq
bitnami,mongodb
bitnami,mariadb
bitnami,elasticsearch
bitnami,etcd
bitnami,influxdb
bitnami,harbor
bitnami,cert-manager
bitnami,sonarqube
bitnami,postgresql
grafana,grafana
grafana,loki-stack
istio,base
istio,istiod
istio,gateway
ingress-nginx,ingress-nginx
csi-driver-nfs,csi-driver-nfs
harbor,harbor
openebs,openebs
)

# workspace
workspace=`pwd`


# get oci_repo
OCI_REPO="oci://${OCI_REPO_DOMAIN}"
OCI_USERNAME="${OCI_USERNAME}"
OCI_PASSWORD="${OCI_PASSWORD}"

SET_COMMIT=""

# add repo 
AddRepo(){
    for aobj in ${chart_repo[@]}
    do
        repo_=(${aobj//,/ })
        repo_name=${repo_[0]}
        repo_url=${repo_[1]}
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
                    SET_COMMIT=sugar
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
        DownloadChart ${repo_name} ${chart_name}
        
    done
pushChart ${OCI_REPO}
#
[ ${SET_COMMIT} != '' ] && echo "" >> ${workspace}/charts.txt

helm registry logout ${OCI_REPO_DOMAIN}
unset OCI_PASSWORD
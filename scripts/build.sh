#!/bin/bash

echo "Check shell."
echo $SHELL

os=$(uname | sed -n '/^Linux/p')
if [ -z "$os" ]; then
    echo "ERROR: This script is only supported by Linux systems. Actual: $(uname)"
    exit 1
fi

if [ -z "$1" ]; then
    echo "ERROR: No environment supplied"
    exit 1
fi
branchenv="$1"

node_version=$(node -v | sed -En '/^v([1-9][8-9]|[2-9][[:digit:]])[[:digit:]]*.[[:digit:]]+.[[:digit:]]+$/p')
if [ -z "$node_version" ]; then
    echo "ERROR: Node 18 or posterior is missing. Actual: $(node -v)"
    exit 1
fi

if ! which yq > /dev/null; then
    echo "ERROR: yq command line tool is missing"
    exit 1
fi

if ! which zip > /dev/null; then
    echo "ERROR: zip command line tool is missing"
    exit 1
fi

echo "Retrieving values from deploymentValues.yaml..."
get_version=$(yq '.version' deploymentValues.yaml)
version="${2:-$get_version}"
if [ -z "$version" ]; then
    echo "ERROR: No version provided in the deploymentValues.yaml nor in the script arguments"
    exit 1
fi

sns_success_topic_name=$(yq '.snsSuccessTopicName' deploymentValues.yaml)
sns_failure_topic_name=$(yq '.snsFailureTopicName' deploymentValues.yaml)
cfn_codebase_bucket=$(myenv=$branchenv yq '.[env(myenv)].codeBaseBucket' deploymentValues.yaml)

if [ -z "$cfn_codebase_bucket" ]; then
    echo "ERROR: No codebase bucket provided in the deploymentValues.yaml for $branchenv env"
    exit 1
fi

cfn_codebase_bucket_region=$(myenv=$branchenv yq '.[env(myenv)].codeBaseBucketRegion' deploymentValues.yaml)

if [ -z "$cfn_codebase_bucket_region" ]; then
    echo "ERROR: No codebase bucket region provided in the deploymentValues.yaml for $branchenv env"
    exit 1
fi

echo "Installing applications and zipping it..."
cd applications || exit 1
pwd
#npm ci
#echo "Bundling..."
#npm run bundle
echo "installing..."
cd src/iotcore-to-dynamodb_"$branchenv"
pwd
#python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
echo "Zipping..."
#npm run zip:all
rm -rf package/
mkdir package
pip install --target package -r requirements.txt
deactivate
cd package
zip -r ../iotcore-to-dynamodb_"$branchenv".zip .
cd ..
zip -g iotcore-to-dynamodb_"$branchenv".zip lambda_function.py
rm -rf ../../dist/
mkdir ../../dist
mv iotcore-to-dynamodb_"$branchenv".zip ../../dist/

echo "Moving files to build folder..."
cd ../../../
rm -rf build/
mkdir build
cp -r templates/*.yaml build/
mkdir build/lambda
#cp -r applications/dist/**/*.zip build/lambda/
cp -r applications/dist/*.zip build/lambda/

echo "Replacing values in the amplifyapp-vue-rest-hkt-annexed-main.yaml template..."
sed -i s,replace_with_version,"$version",g build/amplifyapp-vue-rest-hkt-annexed-main.yaml
sed -i s,replace_with_code_bucket_name,"$cfn_codebase_bucket",g build/amplifyapp-vue-rest-hkt-annexed-main.yaml
sed -i s,replace_with_code_bucket_region_name,"$cfn_codebase_bucket_region",g build/amplifyapp-vue-rest-hkt-annexed-main.yaml
sed -i s,replace_with_sns_success_topic_name,"$sns_success_topic_name",g build/amplifyapp-vue-rest-hkt-annexed-main.yaml
sed -i s,replace_with_sns_failure_topic_name,"$sns_failure_topic_name",g build/amplifyapp-vue-rest-hkt-annexed-main.yaml

echo "Build complete"

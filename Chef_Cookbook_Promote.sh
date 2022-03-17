#!/bin/bash -ex

chef_environment=$1
cookbook_name=$2
cookbook_version=$3
workspace=$4

set -ex

if [[ $chef_environment == "uat" ]]
then
  declare -a chef_environment=(uat htw)
  CHEF_DIR="$workspace/HST"
elif [[ $chef_environment == "test" ]] || [[ $chef_environment == "rg" ]]
then
  declare -a chef_environment=($chef_environment)
  CHEF_DIR="$workspace/HST"
elif [[ $chef_environment == "dr" ]] 
then
  declare -a chef_environment=($chef_environment)
  CHEF_DIR="$workspace/DR"
  repository___ssh_url="git@ghe.hedgeserv.net:chef-cookbooks/$cookbook_name.git"
  rm -rf $CHEF_DIR/cookbooks
  rm -rf $CHEF_DIR/environments
  mkdir $CHEF_DIR/cookbooks
  cd $CHEF_DIR/cookbooks
  git clone $repository___ssh_url $repository___name
  cd $CHEF_DIR
  knife cookbook upload --all --config $CHEF_DIR/.chef/knife.rb
  knife cookbook list --config $CHEF_DIR/.chef/knife.rb
  knife cookbook show $cookbook_name --config $CHEF_DIR/.chef/knife.rb
  knife cookbook show $cookbook_name --config $CHEF_DIR/.chef/knife.rb | grep $cookbook_version
elif [[ $chef_environment == "prod" ]] 
then
  declare -a chef_environment=(prod hsw)
  CHEF_DIR="$workspace/PROD"
  # pushing the cookbook to the prod chef server (PROD is not included in the
  # cookbook build job)
  repository___ssh_url="git@ghe.hedgeserv.net:chef-cookbooks/$cookbook_name.git"
  rm -rf $CHEF_DIR/cookbooks
  rm -rf $CHEF_DIR/environments
  mkdir $CHEF_DIR/cookbooks
  cd $CHEF_DIR/cookbooks
  git clone $repository___ssh_url $repository___name
  cd $CHEF_DIR
  knife cookbook upload --all --config $CHEF_DIR/.chef/knife.rb
  knife cookbook list --config $CHEF_DIR/.chef/knife.rb
  knife cookbook show $cookbook_name --config $CHEF_DIR/.chef/knife.rb
  knife cookbook show $cookbook_name --config $CHEF_DIR/.chef/knife.rb | grep $cookbook_version
fi

chmod 775 $CHEF_DIR

rm -rf $CHEF_DIR/cookbooks
rm -rf $CHEF_DIR/environments

cd $CHEF_DIR

git clone git@ghe.hedgeserv.net:chef-cookbooks/environments.git environments

mkdir $CHEF_DIR/cookbooks

cd $CHEF_DIR/cookbooks

knife download cookbook $cookbook_name

cd $CHEF_DIR/environments

for i in "${!chef_environment[@]}"; do

knife spork promote ${chef_environment[$i]} $cookbook_name --version $cookbook_version --config $CHEF_DIR/.chef/knife.rb --version $cookbook_version -y

knife spork promote ${chef_environment[$i]} $cookbook_name --version $cookbook_version --config $CHEF_DIR/.chef/knife.rb --version $cookbook_version --remote -y

done

git commit -a -m "committing $cookbook_name version $cookbook_version"

git push origin master





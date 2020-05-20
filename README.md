[![jpsalado92](https://circleci.com/gh/jpsalado92/DeployKubernetesMLApp/tree/circleci-project-setup.svg?style=svg)](https://app.circleci.com/pipelines/github/jpsalado92/DeployKubernetesMLApp)
# DeployKubernetesMLApp
This project will guide the reader on setting up a AWS environment in order to operationalize a **Flask** application containing a **Machine Learning model** using **AWS**.<br/>
The app is containerized with **Docker** & **Kubernetes** making it a scalable solution and it consists on a pre-trained sklearn model based on the data from the [Boston Housing challenge](https://www.kaggle.com/c/boston-housing). <br/>

## 1. Getting the project environment ready
### Launch a Cloud9 environment 
In order to run this project on AWS, we must first set up a Cloud9 environment, which works as a powerful IDE with many useful resources.
The selected EC2 instance type should be ```m5.large ```, running the *Amazon Linux* platform and it must belong to a public subnet of a VPC.

### Fetch the model and the Flask implementation
The EC2 instance in which we are working has GIT already installed, so in order to get the flask application containing the trained ML model and the rest of the files required for this project, we can easily clone the source code repository in our file system.
```bash
git clone https://github.com/jpsalado92/ML-Microservice-API-Operationalization.git
``` 
The files related to the ML model are placed in the ```/model_data```, and the flask implementation is described in ```app.py```
### Add extra space to the instance
The default size for our EC2 instance is 10GiB, which is not enough for this project. To solve this problem, ```resize_ec2.sh``` contains all the necesary commands to resize the EBS partition associated to our EC2 instance up to 20GB. We must simply make it executable and run it.
```bash
chmod +x resize_ec2.sh
./resize_ec2.sh
``` 
### Create and activate a python3 virtual environment
The following code creates and activates a python3 virtual environment in the user's home directory.
<br/>**TODO WHY**
```bash
python3 -m venv ~/.devops
source ~/.devops/bin/activate
``` 
### Install hadolint
Hadolint is a useful tool to lint Dockerfiles, which we are using in this project.
``` bash 
sudo wget -O /bin/hadolint https://github.com/hadolint/hadolint/releases/download/v1.17.5/hadolint-Linux-x86_64
sudo chmod +x /bin/hadolint
```
### Install minikube & kubectl
These files allow us to use Kubernetes for our deployment. We will get the latests releases and place them in our PATH.
<br/><br/>&nbsp;&nbsp;minikube:
``` bash
sudo curl -Lo /bin/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo chmod +x /bin/minikube
minikube version
```
>minikube version: v1.10.1<br/>
commit: 63ab801ac27e5742ae442ce36dff7877dcccb278

&nbsp;&nbsp;kubectl:
``` bash
sudo curl -Lo /bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.18.2/bin/linux/amd64/kubectl
sudo chmod +x /bin/kubectl
kubectl version --client
```
> Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.2", GitCommit:"52c56ce7a8272c798dbc29846288d7cd9fbae032", GitTreeState:"clean", BuildDate:"2020-04-16T11:56:40Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}

### Create a Docker account
Docker is already installed in our EC2 instance by default, but in order to be able to push our containers to Dockerhub we will need to create a [free docker account](https://hub.docker.com/signup)

## 2. Build the flask app in a new docker container
We must create a ```Dockerfile``` containing all the steps that will be performed when building the image.
``` Dockerfile
# Start building from a base python image. 
FROM python:3.7.3-stretch

# Create a working directory in the Docker container
WORKDIR /app

# Copy source code to working directory
COPY . app.py /app/
COPY . model_data /app/

# Install packages from requirements.txt
# hadolint ignore=DL3013
RUN pip install --upgrade pip &&\
    pip install --trusted-host pypi.python.org -r requirements.txt
    
# Expose containers port 80 
EXPOSE 80

# Run app.py at container launch
CMD ["python", "app.py"]
```
Once the ```Dockerfile``` is created, use the following command to build it as *ml_app*. 
 ```
docker build -t ml_app .
```
>...<br/>
Successfully built 53015318b353 <br/>
Successfully tagged ml_app:latest

Check that the new image has been created by listing the available docker images:
```
docker image ls
```
## 3. Push the image to Docker HUB
Our docker image was built at the previous step, and now we are going to upload it to Docker HUB.
The shell script ```upload_docker.sh``` can perform this action for us, but first, we must create our repository at [hub.docker.com](https://hub.docker.com/). <br/>
```
#!/usr/bin/env bash
# This file tags and uploads an image to Docker Hub
# Assumes that an image is built via `run_docker.sh`

# Step 1:
# Authenticate
username=<USERNAME>
cat token.txt | docker login --username=$username --password-stdin

# Step 2:  
# Tag
docker_image_id=<DOCKER_IMAGE_ID>
repo=<REPO_NAME>
docker tag $docker_image_id $username/$repo:price_predictor

# Step 3:
# Push image to a docker repository
docker push $username/$repo
```
After creating the repository, we must request a **new token access token** at ```Account Settings > Security > New Access Token```. Make sure to copy the token to a file called ```token.txt``` in our working directory.<br/>
Now, after including our *username*, *docker_image_id* and *repo_name* at ```upload_docker.sh``` we are ready to execute it.
```bash
chmod +x upload_docker.sh
./upload_docker.sh
```


## 4. Deploy the app wth Kubernetes
First, we must start the minikube service.
```bash
minikube start
```
As in the previous step, all the commands required to perform this step are described in the shell script ```run_kubernetes.sh```
```bash
#!/usr/bin/env bash

# Step 1:
# Authenticate
username=<USERNAME>
cat token.txt | docker login --username=$username --password-stdin

# Step 2
# Run the Docker Hub container with kubernetes
repo=<REPO_NAME>:<TAG>
app_name=ml_app
kubectl run $app_name\
    --image=$username/$repo\
    --port=80 --labels app=$app_name

# Step 3:
# List kubernetes pods
kubectl get pods

# Step 4:
# Forward the container port to a host
kubectl port-forward $app_name 8000:80
kubectl describe pod $app_name
```
Running the script will get our Kubernetes app deployed.
```bash
chmod +x run_kubernetes.sh
./run_kubernetes.sh
```
Make sure to stop the minikube service after using the container.
```bash
minikube delete
```

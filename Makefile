setup:
	# Create python virtualenv & source it
	python3 -m venv ~/.devops
	source ~/.devops/bin/activate

install:
	# Install dependencies in requirements.txt
	pip install --upgrade pip &&\
		pip install -r requirements.txt

lint:
	# Dockerfile should pass hadolint
	hadolint Dockerfile
	# app.py should pass hadolint
	pylint --disable=R,C,W1203 app.py

all: install lint test

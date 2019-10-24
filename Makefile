VIRTUAL_ENV ?= venv
ACTIVATE_PATH=$(VIRTUAL_ENV)/bin/activate
PIP=$(VIRTUAL_ENV)/bin/pip
TOX=`which tox`
PYTHON_MAJOR_VERSION=3
PYTHON_MINOR_VERSION=7
PYTHON_VERSION=$(PYTHON_MAJOR_VERSION).$(PYTHON_MINOR_VERSION)
PYTHON_MAJOR_MINOR=$(PYTHON_MAJOR_VERSION)$(PYTHON_MINOR_VERSION)
PYTHON_WITH_VERSION=python$(PYTHON_VERSION)
PYTHON=$(VIRTUAL_ENV)/bin/python
ISORT=$(VIRTUAL_ENV)/bin/isort
FLAKE8=$(VIRTUAL_ENV)/bin/flake8
PYTEST=$(VIRTUAL_ENV)/bin/pytest
MYPY=$(VIRTUAL_ENV)/bin/mypy
TWINE=`which twine`
SOURCES=src/ setup.py
DOCKER_IMAGE_LINUX=andremiras/etherollapp-linux
DOCKER_IMAGE_ANDROID=andremiras/etherollapp-android
DOCKER_VOLUME=/tmp/.X11-unix:/tmp/.X11-unix
SYSTEM_DEPENDENCIES_BASE= \
	git \
	libffi-dev \
    libpython$(PYTHON_VERSION)-dev \
	pkg-config \
	python$(PYTHON_VERSION)
SYSTEM_DEPENDENCIES_LINUX= \
	build-essential \
	libgmp3-dev \
	libsdl2-dev \
	libsdl2-image-dev \
	libsdl2-mixer-dev \
	libsdl2-ttf-dev \
	libssl-dev \
	tox \
	virtualenv \
	xclip \
	xsel \
	libzbar-dev
SYSTEM_DEPENDENCIES_ANDROID= \
    autoconf \
    autogen \
    automake \
    bsdtar \
    ca-certificates \
    cmake \
    curl \
    gettext \
    libltdl-dev \
    libtool \
    openjdk-8-jdk \
    python2.7 \
    python3-pip \
    python3-setuptools \
    unzip \
    xz-utils \
    zip \
	zlib1g-dev
ifndef CI
DOCKER_DEVICE=--device=/dev/video0:/dev/video0
endif

all: virtualenv

system_dependencies:
	sudo apt update -qq > /dev/null && sudo apt -qq install --yes --no-install-recommends $(SYSTEM_DEPENDENCIES_BASE)

system_dependencies/linux: system_dependencies
	sudo apt update -qq > /dev/null && sudo apt -qq install --yes --no-install-recommends $(SYSTEM_DEPENDENCIES_LINUX)

system_dependencies/android: system_dependencies
	sudo apt update -qq > /dev/null && sudo apt -qq install --yes --no-install-recommends $(SYSTEM_DEPENDENCIES_ANDROID)

$(VIRTUAL_ENV):
	virtualenv --python $(PYTHON_WITH_VERSION) $(VIRTUAL_ENV)
	$(PIP) install Cython==0.28.6
	$(PIP) install --timeout 120 --requirement requirements.txt

virtualenv: $(VIRTUAL_ENV)

run: virtualenv
	$(PYTHON) src/main.py

pytest: virtualenv
	PYTHONPATH=src $(PYTEST) --ignore src/etherollapp/tests/ui/ src/etherollapp/tests/

test: pytest lint
	@if test -n "$$CI"; then make uitest; fi; \

uitest: virtualenv
	$(PYTHON) -m unittest discover --top-level-directory=src/ --start-directory=src/etherollapp/tests/ui/

lint/isort-check: virtualenv
	$(ISORT) --check-only --recursive --diff $(SOURCES)

lint/isort-fix: virtualenv
	$(ISORT) --recursive $(SOURCES)

lint/flake8: virtualenv
	$(FLAKE8) $(SOURCES)

lint/mypy: virtualenv
	@$(MYPY) --ignore-missing-imports $(shell find src/etherollapp/ -name "*.py")

lint: lint/isort-check lint/flake8 lint/mypy

release/clean:
	rm -rf dist/ build/

release/build: release/clean clean
	$(PYTHON) setup.py sdist bdist_wheel
	$(TWINE) check dist/*

release/upload:
	$(TWINE) upload dist/*

clean:
	py3clean .
	rm -rf .pytest_cache/
	find . -type d -name "__pycache__" -exec rm -r {} +
	find . -type d -name "*.egg-info" -exec rm -r {} +

clean/venv: clean
	rm -rf $(VIRTUAL_ENV) .tox/

buildozer/android/debug:
	@if test -n "$$CI"; then sed 's/log_level = [0-9]/log_level = 1/' -i buildozer.spec; fi; \
	buildozer android debug

docker/pull/linux:
	docker pull $(DOCKER_IMAGE_LINUX):latest

docker/pull/android:
	docker pull $(DOCKER_IMAGE_ANDROID):latest

docker/build/linux:
	docker build --cache-from=$(DOCKER_IMAGE_LINUX) --tag=$(DOCKER_IMAGE_LINUX) --file=dockerfiles/Dockerfile-linux .

docker/build/android:
	docker build --cache-from=$(DOCKER_IMAGE_ANDROID) --tag=$(DOCKER_IMAGE_ANDROID) --file=dockerfiles/Dockerfile-android .

docker/push/linux:
	docker push $(DOCKER_IMAGE_LINUX)

docker/push/android:
	docker push $(DOCKER_IMAGE_ANDROID)

docker/push: docker/push/linux docker/push/android

docker/run/test/linux:
	docker run --env-file dockerfiles/env.list -v $(DOCKER_VOLUME) $(DOCKER_DEVICE) $(DOCKER_IMAGE_LINUX) 'make test'

docker/run/test/android:
	docker run --env-file dockerfiles/env.list $(DOCKER_IMAGE_ANDROID) 'make buildozer/android/debug'

docker/run/app:
	docker run --env-file dockerfiles/env.list -v $(DOCKER_VOLUME) $(DOCKER_DEVICE) $(DOCKER_IMAGE_LINUX) 'make run'

docker/run/shell/linux:
	docker run --env-file dockerfiles/env.list -v $(DOCKER_VOLUME) $(DOCKER_DEVICE) -it --rm $(DOCKER_IMAGE_LINUX)

docker/run/shell/android:
	docker run --env-file dockerfiles/env.list -v $(DOCKER_VOLUME) $(DOCKER_DEVICE) -it --rm $(DOCKER_IMAGE_ANDROID)

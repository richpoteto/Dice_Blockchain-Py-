# EtherollApp
Cross platform Etheroll app built with Python and Kivy.

<img src="https://i.imgur.com/gwrIMX0.png" alt="Screenshot mainscreen" width="200">

## Run
```
. venv/bin/activate
./src/main.py
```

## Install
```
make
```

## Test
```
make test
```

## Docker
There's a [Dockerfile](Dockerfile) to build Linux dependencies and run tests.
```
docker build --tag=etheroll .
docker run etheroll /bin/sh -c '. venv/bin/activate && make test'
```

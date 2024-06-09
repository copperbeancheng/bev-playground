#arg_dockerfile=docker/Dockerfile
arg_dockerfile=./Dockerfile
arg_imagename=bev-playground

docker_args="-f $arg_dockerfile --build-arg uid=$(id -u) --build-arg gid=$(id -g) --tag=$arg_imagename ."

echo "Building container:"
echo "> docker build $docker_args"
docker build $docker_args
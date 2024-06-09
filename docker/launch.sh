
arg_tag=bevdet
arg_gpus=all

extra_args=""
if [ "$arg_gpus" != "none" ]; then
    extra_args="$extra_args --gpus $arg_gpus"
fi

docker_args="$extra_args -v /home/wlin/workspace/bev-playground/BEVDet:/workspace --rm -it $arg_tag:latest"

echo "Launching container:"
echo "> docker run $docker_args"
docker run $docker_args

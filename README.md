# Accumulo Docker Build

This project helps create and run a Docker image that can build Accumulo and
run Accumulo test.  It mounts your local Accumulo source directoy into
Accumulo.  To use it run the following command.

```bash
./accumulo-docker-build.sh <your accumulo src dir>
```

If the above command completes it will drop you into a shell inside a docker
container.  From there you can run `mvn compile` to compile accumulo.  Could
also run `runIT <IT name>` to run an Accumulo integration test.  The `runIT`
script is a simple script this project adds to the docker image.

Ensure Docker has at least 4G when running ITs.  For desktop docker, the memory
can be adjusted in the UI.  On Mac it defaults to 2G.


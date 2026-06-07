# Drupal Template

## Docker
Build the docker image for *development*:
``` shell
docker build --build-arg DEV=1 -t drupal_template:dev .
```

Run Docker in *development*:

``` shell
docker run -it --rm \
  --user $(id -u):$(id -g) \
  -p 8088:80 \
  -v "$(pwd):/var/www/drupal" \
  -v "$(pwd)/web/sites/default/files:/var/www/drupal/web/sites/default/files" \
  -v "$(pwd)/private/files:/var/www/drupal/private/files" \
  --name drupal_template
  drupal_template:dev
```

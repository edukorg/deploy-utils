# deploy-util

Helper script to be used on the tsuru deploy and start events.

## Usage
To have the deploy-util script deployed with the app image add the following line to the `tsuru.yml` `hooks:build` hook:
```
- curl -L https://gist.github.com/Posytron/c8837b9bbf24dcca83e4aece58aa456a/raw/f6bc3fa0b41be11e449f61bb1f328f177f0400bb/deploy-util.sh -o deploy-util.sh && chmod +x deploy-util.sh
```

To run the default actions for the deploy event (including generate the `APP_EXTRA_ENV` file with the `APP_CURRENT_VERSION`) add the following line:
```
- ./deploy-util.sh run_on_tsuru_deploy
```

To run the default actions for the start event (including configure the `APP_CURRENT_VERSION` and `TSURU_NONE` internal env vars`) configure the Procfile processes like this:
```
web: ./deploy-util.sh run_tsuru_app npm start
```
The `run_tsuru_app` action will run the default actions to configure the environment and then will run the command as specifiec (`npm start` in this example).

The script is supposed to be executed with an action as it's first argument. It run that action with using the remaining arguments (options) as the action options.

## Modifying the script
To create new action just create a function and add it name to the `ACTIONS` array. This is enough to make a new action avaiable. Any additional parameters used in the command line will be sent to the function (they can be accessed normaly with `$1`, `$2`, `$@`, `shift`, etc)

This is a bash script and it has some limitations, so it's important to remember:
- always add a final `\` after adding a new action to the `ACTIONS` array
- you can't call functions defined after your function
- use the `set -e` in the beggining of your function if you want it to stop on every unexpected error



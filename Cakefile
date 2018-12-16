util = require 'util'
_exec = util.promisify require('child_process').exec
pkg = require './package.json'
assert = require 'assert'

LAYER_NAME = 'coffeescript'
NODE_VERSION = '8.10.0'
COFFEESCRIPT_VERSION = pkg.dependencies.coffeescript.replace /[^\d\.]/, ''
IMAGE_FILE = "node-provided-lambda-v#{NODE_VERSION.split('.')[0]}.x"
OUTPUT_DIR = 'build'
OUTPUT_FILE = "#{pkg.name}_#{pkg.version}"

exec = (command) ->
    try
        _exec command, maxBuffer: 1024 * 1000
    catch e
        throw new Error e

task 'build', 'builds and packages the runtime layer',
(options) ->
    console.log """
        ===========================================================
        runtime:        #{OUTPUT_FILE}
        CoffeeScript:   v#{COFFEESCRIPT_VERSION}
        NodeJs:         v#{NODE_VERSION}
        ===========================================================
    """

    await exec "
        docker build
            --build-arg NODE_VERSION=#{NODE_VERSION}
            -t #{IMAGE_FILE}
            .
    "
    console.log "building image... ok"

    await exec "
        if [ ! -d build ]; then mkdir build; fi;
        docker run --rm #{IMAGE_FILE}
            cat /tmp/node-v#{NODE_VERSION}.zip > #{OUTPUT_DIR}/#{OUTPUT_FILE}.zip
    "
    console.log "packaging image... ok"

    console.log """
        build completed successfully!
            output:     #{OUTPUT_DIR}/#{OUTPUT_FILE}.zip
    """

task 'publish', 'uploads packaged runtime layer to AWS',
(option) ->
    await invoke 'build'
    await invoke 'test'

    { stdout, stderr } = await exec "
        aws lambda publish-layer-version
            --layer-name #{LAYER_NAME}
            --zip-file fileb://#{OUTPUT_DIR}/#{OUTPUT_FILE}.zip
            --description \"A CoffeeScript v#{COFFEESCRIPT_VERSION} custom runtime\"
            --license-info MIT
            --query Version
            --output text
    "
    console.log 'publishing layer... ok'

    [ LAYER_VERSION ] = stdout.split(/\n/)
    await exec "
        aws lambda add-layer-version-permission
            --layer-name #{LAYER_NAME}
            --version-number #{LAYER_VERSION}
            --statement-id sid1
            --action lambda:GetLayerVersion
            --principal '*'
    "
    console.log 'publishing layer permissions... ok'

    console.log """
        publish completed successfully!
            name:       #{LAYER_NAME}
            version:    #{LAYER_VERSION}
    """

task 'test', 'runs test',
(option) ->
    await exec "
        rm -rf test/layer;
        unzip #{OUTPUT_DIR}/#{OUTPUT_FILE}.zip -d test/layer;
        
        cd test/lambda && npm ci && cd -;
        rm -f test/lambda/lambda.zip;
        zip -qyr test/lambda/lambda.zip test/lambda/index.coffee test/lambda/node_modules
    "
    console.log 'packaging test... ok'

    console.log 'running test...'
    { stdout, stderr } = await exec "
	    docker run
            --rm
            -v $(PWD)/test/lambda:/var/task
            -v $(PWD)/test/layer:/opt
            lambci/lambda:provided
            index.handler
    "

    [ result ] = stdout.split(/\n/)
    expected = '{"statusCode":200,"body":"{\\"message\\":\\"CoffeeScript Serverless v1.0! Your function executed successfully!\\",\\"input\\":{}}"}'

    passed = result is expected
    console.log "running test... #{if passed then 'PASS' else 'FAIL'}"

    if not passed
        console.log stderr
        process.exit 1

    await exec "
        rm -rf test/layer;
        rm -f test/lambda/lambda.zip;
    "
    console.log 'cleaning up... ok'
